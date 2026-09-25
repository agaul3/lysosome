extends "res://tests/campus_test.gd"
## Milestone 11, University Hospital: the shadowing script and its data, the
## walk from campus across the street to the hospital, and the whole guided
## session with real movement: meeting Dr. Okafor (too early, then on time),
## following her (including falling behind), the elevator ride, the charge
## nurse, the EHR close-up, hand hygiene, standing at the foot of the bed,
## the etiquette questions, completion and notes. Then first person, a free
## elevator ride back down, leaving for campus and saving in the hospital.
const ShadowingScript = preload("res://education/shadowing/shadowing_script.gd")
const SCRIPT_PATH := "res://education/shadowing/hospital_orientation_01.json"
var hospital: Node3D
var session: Node
var reached: Array = []
var ehr_views: Array = []
var ehr_zoomed := false
var saw_lagging := false
var prompts := {}

func _run() -> void:
	state = root.get_node("AppState")
	script_tests()
	await campus_crossing()
	await hospital_arrival()
	await session_flow()
	await after_session()
	print("HOSPITAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

# --- Data ------------------------------------------------------------------------------

func script_tests() -> void:
	var flow := ShadowingScript.new()
	check(flow.load_file(SCRIPT_PATH), "Shadowing script loads: " + flow.last_error)
	var ids: Array = flow.stops().map(func(stop): return stop.id)
	check(ids == ["meet", "elevators", "unit", "station", "workroom", "room_412", "bedside", "isolation", "wrap_up"], "Arrive, meet, follow, logistics, workflow, rounds, etiquette, wrap-up in order")
	var bank := root.get_node("QuestionBank")
	var questions: Array = flow.question_ids()
	check(questions.size() == 7, "Seven etiquette checks (%d)" % questions.size())
	var complete := true
	for id in questions:
		var q: Dictionary = bank.get_question(id)
		complete = complete and not q.is_empty() and q.discipline == "Clinical Skills" and q.lecture_id == "hospital_orientation_01" and not q.explanation.is_empty()
	check(complete, "Every check is a bank question with an explanation, under Clinical Skills")
	var kinds := {}
	for stop in flow.stops():
		check(not String(stop.takeaway).is_empty(), "Stop %s has a takeaway for the notes" % stop.id)
		for step in stop.steps:
			for kind in ShadowingScript.STEP_KINDS:
				if step.has(kind):
					kinds[kind + (":" + String(step[kind]) if kind in ["action", "ehr"] else "")] = true
	for expected in ["say", "question", "action:board", "action:talk", "action:sanitize", "action:stand", "ehr:open", "ehr:vitals", "ehr:results", "ehr:close"]:
		check(kinds.has(expected), "Script uses " + expected)
	for broken in [
		"{}",
		'{"version":1,"id":"x","title":"t","unit":"u","speakers":{"okafor":"O"},"lines":{},"stops":[]}',
		'{"version":2,"id":"x","title":"t","unit":"u","speakers":{"okafor":"O"},"lines":{"too_early":"a","on_time":"a","late":"a","after":"a","wait":"a"},"stops":[]}',
		'{"version":1,"id":"x","title":"t","unit":"u","speakers":{"okafor":"O"},"lines":{"too_early":"a","on_time":"a","late":"a","after":"a","wait":"a"},"stops":[{"id":"a","at":"b","route":[],"topic":"t","objective":"o","takeaway":"k","steps":[{"say":"hi","question":"q"}]}]}',
		'{"version":1,"id":"x","title":"t","unit":"u","speakers":{"okafor":"O"},"lines":{"too_early":"a","on_time":"a","late":"a","after":"a","wait":"a"},"stops":[{"id":"a","at":"b","route":[],"topic":"t","objective":"o","takeaway":"k","steps":[{"action":"fly","target":"x","objective":"o"}]}]}',
		'{"version":1,"id":"x","title":"t","unit":"u","speakers":{"okafor":"O"},"lines":{"too_early":"a","on_time":"a","late":"a","after":"a","wait":"a"},"stops":[{"id":"a","at":"b","route":[],"topic":"t","objective":"o","takeaway":"k","steps":[{"action":"talk","target":"x","objective":"o"}]}]}',
		'{"version":1,"id":"x","title":"t","unit":"u","speakers":{"okafor":"O"},"lines":{"too_early":"a","on_time":"a","late":"a","after":"a","wait":"a"},"stops":[{"id":"a","at":"b","route":[],"topic":"t","objective":"o","takeaway":"k","steps":[{"say":"hi","speaker":"ghost"}]}]}',
	]:
		check(not ShadowingScript.validate(JSON.parse_string(broken)).is_empty(), "Malformed shadowing script rejected: " + broken.left(60))

# --- Campus to hospital ----------------------------------------------------------------

func campus_crossing() -> void:
	state.start_new_game()
	state.phase = state.Phase.CAMPUS
	state.campus_entry = "dorm"
	change_scene_to_file("res://world/campus/campus.tscn")
	await acquire_world()
	check(dorm.hospital_door != null, "Campus has a hospital entrance")
	# The south edge still holds away from the crossing.
	await reset_position(Vector3(10, 0, 25.4))
	drive(Vector3.BACK)
	await ticks(50)
	release_movement()
	check(player.position.z < 26.0, "The street stays closed away from the crossing")
	# From the sidewalk east of the parking lot: south along the path, over the crossing, into the plaza.
	await reset_position(Vector3(29.0, 0, 12.4))
	for point in [Vector3(29.0, 0, 20), Vector3(29.0, 0, 28), Vector3(29.0, 0, 35), Vector3(29.0, 0, 42), Vector3(29.4, 0, 48.6), Vector3(28.9, 0, 50)]:
		await walk_to(point)
	check(player.position.z > 45.0, "Crossed the street on foot to the hospital plaza (%s)" % player.position)
	var tracked: Vector3 = dorm.camera.tracked_point
	check(tracked.z > 30.0 and tracked.z <= Config.CAMERA_MAX.y + 0.01, "The camera follows across the street")
	check(player.interaction.target == dorm.hospital_door, "Hospital entrance reachable")
	check(dorm.hud.prompt.text == "Enter University Hospital", "Entrance prompt shown")
	# The plaza is closed to the south and along the building.
	var inside := player.position
	drive(Vector3.LEFT)
	await ticks(40)
	release_movement()
	check(player.position.x > 27.4, "The hospital facade is solid")
	# The walkway carries on south along the building to the Emergency
	# Department; the street behind the hospital closes it.
	await reset_position(Vector3(30, 0, 73.0))
	drive(Vector3.BACK)
	await ticks(50)
	release_movement()
	check(player.position.z < 75.0, "The walkway's far edge holds at the street behind the hospital")
	await reset_position(inside)
	await capture("hospital-exterior")
	use_endpoint()
	await acquire_world()
	hospital = dorm
	check(state.phase == state.Phase.HOSPITAL and hospital.name == "Hospital", "Campus-to-hospital transition")

# --- Arrival -----------------------------------------------------------------------------

func hospital_arrival() -> void:
	session = hospital.session
	check(hospital.player.position.distance_to(hospital.anchor("entrance")) < 0.3, "Arrive at the main entrance, inside the doors")
	check(hospital.hud.location_label.text.contains("LEVEL 1"), "Location shows the lobby")
	check(hospital.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Overhead camera in the lobby")
	var flow := ShadowingScript.new()
	flow.load_file(SCRIPT_PATH)
	var missing := flow.anchors().filter(func(id): return hospital.anchor(id) == Vector3.INF)
	for target in flow.action_targets():
		if target not in ["unit", "observer_412"] and not hospital.targets.has(target):
			missing.append(target)
	check(missing.is_empty(), "Every anchor and action target in the script exists %s" % str(missing))
	check(hospital.anchor("observer_412") != Vector3.INF, "The observer mark exists")
	check(hospital.layers.size() == 4 and not hospital.layers[0][0].visible and hospital.layers[0][1].visible, "Third person shows the cutaway")
	# The entrance doors part as the student walks up to them.
	await reset_position(hospital.anchor("entrance") + Vector3(0, 0, -0.5))
	await ticks(40)
	check(hospital.entrance_doors.open_amount > 0.5, "Automatic entrance doors open for the student")
	await capture("hospital-lobby")
	# Too early: before 9:00 with class still to attend, Dr. Okafor sends the student to class.
	check(session.state == session.State.WAITING and session.too_early(), "Session waits at the Information desk")
	check(hospital.hud.objective_label.text.begins_with("Pharmacodynamics first"), "Objective sends the student to class first")
	for point in [Vector3(1.8, 0, 4.2), Vector3(3.4, 0, 1.9)]:
		await walk_to(point)
	check(player.interaction.target == session.endpoint, "Dr. Okafor can be talked to")
	check(hospital.hud.prompt.text == "Talk to Dr. Okafor", "Talk prompt shown")
	await press_interact()
	check(session.state == session.State.TALKING and hospital.lecture_ui.text.text.contains("after your Pharmacodynamics lecture"), "Too early: she explains the session starts after class")
	await finish_line()
	check(session.state == session.State.WAITING and player.movement_enabled, "Back to waiting; the student can move")
	# NPCs are solid: walking into her stops short.
	drive((hospital.physician.global_position - player.global_position).normalized())
	await ticks(40)
	release_movement()
	var gap: Vector3 = player.global_position - hospital.physician.global_position
	check(Vector2(gap.x, gap.z).length() > 0.4, "The physician is solid to the player")
	# Class done, just before 9:00: the session begins on time.
	var academics := root.get_node("AcademicSession")
	var clock := root.get_node("GameClock")
	academics.lectures_completed["pharmacodynamics_01"] = {"correct": 12, "attempted": 12, "xp": 190, "accuracy": 1.0}
	var remaining: float = session.start_time() - clock.now_seconds() - 120.0
	clock.advance(remaining / float(clock.config.time_scale))
	await walk_to(Vector3(3.4, 0, 1.9))

# --- The session ----------------------------------------------------------------------------

func session_flow() -> void:
	var academics := root.get_node("AcademicSession")
	var xp_before: int = academics.xp_balance
	session.stop_reached.connect(func(index: int) -> void: reached.append(index))
	check(player.interaction.target == session.endpoint, "Dr. Okafor can be talked to again")
	await press_interact()
	await ticks(3)
	check(session.state == session.State.TALKING and hospital.lecture_ui.text.text.contains("Right on time"), "On time: she greets the student")
	var attendance: Dictionary = academics.attendance.get("2026-09-21:hospital_orientation_01", {})
	check(not attendance.is_empty() and not attendance.late, "Arrival recorded on time")
	var guard := 0
	while session.state != session.State.SUMMARY and guard < 400:
		guard += 1
		match session.state:
			session.State.TALKING:
				await finish_line()
			session.State.QUESTION:
				await answer_question()
			session.State.FOLLOWING:
				await follow()
			session.State.ACTION:
				await perform_action()
			_:
				await ticks(2)
		if hospital.ehr_view_ready():
			ehr_zoomed = true
		if hospital.ehr_chart != null and hospital.ehr_chart.focus not in ehr_views:
			ehr_views.append(hospital.ehr_chart.focus)
	check(session.state == session.State.SUMMARY, "The session reaches its summary (%d steps)" % guard)
	check(reached == range(9), "Every stop is reached in order %s" % str(reached))
	check(saw_lagging, "Falling behind makes her wait and say so")
	check(ehr_zoomed, "The EHR close-up settles on the workstation")
	for view in ["banner", "vitals", "results", "notes"]:
		check(view in ehr_views, "The EHR shows its " + view)
	check(hospital.physician.distance_walked > 60.0, "She walks the student through the hospital (%.0f m)" % hospital.physician.distance_walked)
	for prompt in ["Take the elevator", "Talk to Priya (charge nurse)", "Clean your hands"]:
		check(prompts.has(prompt), "Prompt shown: " + prompt)
	check(hospital.lecture_ui.speaker.text.begins_with("SHADOWING COMPLETE"), "Summary card shown")
	await press_interact()
	await ticks(2)
	check(session.state == session.State.COMPLETE and player.movement_enabled and player.interaction.enabled, "Summary closes and the student is free")
	check(academics.lectures_completed.has("hospital_orientation_01"), "Completion recorded")
	check(int(academics.notes_progress.get("hospital_orientation_01", 0)) == 9, "All takeaways reach the notes")
	var summary: Dictionary = academics.lectures_completed.hospital_orientation_01
	check(summary.attempted == 7 and summary.correct == 7, "Seven etiquette checks scored (%d/%d)" % [summary.correct, summary.attempted])
	check(academics.xp_balance > xp_before and summary.xp > 0, "Etiquette checks award XP")
	check(academics.question_history.has("hospital_orientation_01:ho_hand_hygiene_01"), "Attempts use stable session ids")
	check(int(academics.topic_statistics.get("Clinical Skills", {}).get("attempted", 0)) == 7, "Knowledge statistics under Clinical Skills")
	check(hospital.hud.objective_label.text.begins_with("Shadowing complete"), "Objective reflects completion")
	check(hospital.hud.location_label.text.contains("4 WEST"), "Location shows 4 West")
	# After the session she has a word, and the day's objective moves on.
	var objectives: Script = load("res://data/objectives.gd")
	check(objectives.current("campus").begins_with("Day complete"), "The day's objective is complete")

## Presses E until the current line is done and the session moves on.
func finish_line() -> void:
	var before: String = hospital.lecture_ui.text.text
	await press_interact()
	await ticks(1)
	if session.state == session.State.TALKING and hospital.lecture_ui.text.text == before:
		await press_interact()
		await ticks(2)

func answer_question() -> void:
	var bank := root.get_node("QuestionBank")
	var id: String = session.question.current_id
	var q: Dictionary = bank.get_question(id)
	var keys: Array = q.choices.keys()
	keys.sort()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1 + keys.find(q.correct_answer)
	key.pressed = true
	Input.parse_input_event(key)
	await ticks(1)
	key.pressed = false
	Input.parse_input_event(key)
	await press_interact()
	check(session.question.last_result.get("correct", false), "Answered %s" % id)
	await press_interact()
	await ticks(1)

## Walks after the physician in her footsteps (a breadcrumb trail of where
## she has walked), keeping a polite distance and stepping out of her lane
## when she comes toward the student.
func follow() -> void:
	var stop: Dictionary = session.flow.stops()[session.stop_index]
	# At the nurses station, lag behind first to see her wait.
	if stop.id == "station":
		for index in range(400):
			await ticks(1)
			if hospital.physician.lagging:
				saw_lagging = hospital.physician.speech.visible and hospital.physician.speech.text == "Stay with me."
				break
	var trail: Array[Vector3] = [hospital.physician.global_position]
	for tick in range(2400):
		if session.state != session.State.FOLLOWING:
			release_movement()
			return
		var her: Vector3 = hospital.physician.global_position
		if her.distance_to(trail.back()) > 0.3:
			trail.append(her)
		while trail.size() > 1 and Vector2(trail[0].x - player.position.x, trail[0].z - player.position.z).length() < 0.35:
			trail.pop_front()
		var gap: Vector3 = her - player.global_position
		gap.y = 0.0
		var goal: Vector3 = trail[0]
		var offset := goal - player.position
		offset.y = 0.0
		if gap.length() < 1.0 and hospital.physician.walking and not hospital.physician.path.is_empty():
			# Step aside, out of her lane.
			var heading: Vector3 = hospital.physician.path[0] - her
			heading.y = 0.0
			var side := Vector3(-heading.z, 0, heading.x).normalized()
			if side.dot(-gap) < 0.0:
				side = -side
			drive((side - gap.normalized()).normalized())
			trail = [her]
		elif gap.length() < 1.6 or offset.length() < 0.3:
			release_movement()
		else:
			drive(offset.normalized())
		await ticks(1)
	release_movement()
	check(false, "Following stalled at stop %s (player %s, physician %s)" % [stop.id, player.position, hospital.physician.global_position])

func perform_action() -> void:
	var action: Dictionary = session.action
	match String(action.action):
		"board":
			for tick in range(200):
				if hospital.lobby_elevator.is_open():
					break
				await ticks(1)
			check(hospital.lobby_elevator.is_open(), "The elevator doors open for the student")
			await walk_to(hospital.anchor("elevator_l1") + Vector3(0.9, 0, -1.6))
			prompts[String(hospital.hud.prompt.text).left(17)] = true
			await walk_to(Vector3(1.5, 0, -13.3))
			await walk_to(hospital.cab_centre("lobby") + Vector3(0.45, 0, 0.2))
			for tick in range(300):
				if hospital.zone == "unit" and not hospital.riding:
					break
				await ticks(1)
			check(hospital.zone == "unit" and hospital.in_cab(player, "unit"), "The elevator takes the student to 4 West")
			check(hospital.in_cab(hospital.physician, "unit"), "Dr. Okafor rides along")
			await ticks(2)
		"talk":
			await walk_to(Vector3(140 + 20.2, 0, 1.2))
			check(player.interaction.target == hospital.targets.charge_nurse, "Priya can be talked to")
			prompts[hospital.hud.prompt.text] = true
			await press_interact()
			check(session.state == session.State.TALKING and hospital.lecture_ui.speaker.text.contains("PRIYA"), "Priya replies")
		"sanitize":
			var target: Node3D = hospital.targets[action.target]
			var spot := target.global_position + Vector3(0, 0, 0.5) if action.target == "dispenser_412" else target.global_position + Vector3(-0.5, 0, -0.5)
			if action.target == "dispenser_412_in":
				await walk_to(hospital.anchor("room412_inside"))
			await walk_to(Vector3(spot.x, 0, spot.z))
			check(player.interaction.target == target, "The dispenser is in reach: " + action.target)
			prompts[hospital.hud.prompt.text] = true
			await press_interact()
			for tick in range(30):
				if session.state != session.State.ACTION:
					break
				await ticks(1)
			check(session.state != session.State.ACTION, "Cleaning hands continues the session")
		"stand":
			check(hospital.marker.visible, "A mark shows where to stand")
			await walk_to(hospital.anchor("room412_inside"))
			await walk_until(hospital.anchor("observer_412"), func() -> bool: return not hospital.marker.visible)
			check(not hospital.marker.visible, "Standing on the mark continues the session")
			check(not player.movement_enabled, "The student holds still at the foot of the bed while the team talks")
			await capture("hospital-bedside")
		_:
			await ticks(2)

# --- Afterwards ---------------------------------------------------------------------------

func after_session() -> void:
	# First person: the unit is whole (ceilings and full walls) and walkable.
	state.set_first_person(true)
	await ticks(3)
	check(hospital.layers[1][0].visible and not hospital.layers[1][1].visible, "First person shows the whole unit")
	check(player.first_person.camera.current, "First-person camera active")
	await walk_fp(Vector3(140 + 18.0, 0, 0.3))
	await walk_fp(Vector3(140 + 8.0, 0, 0.3))
	await capture("hospital-unit-first-person")
	check(player.global_position.distance_to(Vector3(148, player.global_position.y, 0.3)) < 0.4, "First-person walk along the corridor")
	await walk_fp(Vector3(140 - 4.2, 0, 1.2))
	state.set_first_person(false)
	await ticks(3)
	# A free ride back down.
	await walk_to(hospital.anchor("unit_lobby") + Vector3(-0.8, 0, -0.5))
	check(player.interaction.target == hospital.elevator_calls.unit[0], "Unit elevator call in reach")
	await press_interact()
	for tick in range(100):
		if hospital.unit_elevator.is_open():
			break
		await ticks(1)
	await walk_to(hospital.anchor("unit_car_door") + Vector3(0.2, 0, 0))
	await walk_until(hospital.cab_centre("unit"), func() -> bool: return hospital.riding)
	for tick in range(300):
		if hospital.zone == "lobby" and not hospital.riding:
			break
		await ticks(1)
	check(hospital.zone == "lobby" and hospital.hud.location_label.text.contains("LEVEL 1"), "Free ride back to the lobby after the session")
	await ticks(10)
	# First person in the lobby too.
	state.set_first_person(true)
	await ticks(3)
	await walk_fp(hospital.anchor("elevator_l1"))
	await walk_fp(hospital.anchor("lobby_mid"))
	await capture("hospital-lobby-first-person")
	await walk_fp(Vector3(3.8, 0, 3.2))
	await walk_fp(Vector3(0.6, 0, 7.6))
	check(player.global_position.z > 7.0, "First-person walk back to the entrance")
	state.set_first_person(false)
	await ticks(3)
	# Saving in the hospital.
	var save := root.get_node("SaveGame")
	check(save.save(), "Save in the hospital: " + save.last_error)
	var data: Dictionary = save.read()
	check(data.location.scene == "hospital" and save.summary(data).location == "University Hospital", "Save records the hospital")
	# Leave for campus through the main doors.
	await walk_to(Vector3(0, 0, 8.5))
	check(player.interaction.target == hospital.exit_door, "Exit in reach at the doors")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.CAMPUS and player.position.distance_to(Config.SPAWNS.hospital) < 0.2, "Back on campus at the hospital entrance")

## Walks toward a point until `done` holds (the game takes over, e.g. a ride starts).
func walk_until(destination: Vector3, done: Callable) -> void:
	for index in range(240):
		if done.call():
			release_movement()
			return
		var offset := destination - player.position
		offset.y = 0
		drive(offset.normalized() if offset.length() > 0.05 else Vector3.ZERO)
		await ticks(1)
	release_movement()
	check(false, "Walked to %s but the game never took over" % destination)

## First-person walking: face the destination and hold forward.
func walk_fp(destination: Vector3) -> void:
	for index in range(400):
		var offset := destination - player.global_position
		offset.y = 0.0
		if offset.length() < 0.15:
			release_movement()
			await ticks(2)
			return
		player.first_person.yaw = atan2(-offset.x, -offset.z)
		release_movement()
		Input.action_press("move_up")
		await ticks(1)
	release_movement()
	check(false, "First-person route blocked at %s toward %s" % [player.global_position, destination])

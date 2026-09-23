extends "res://tests/campus_test.gd"
const Schedule = preload("res://autoload/npc_schedule.gd")
const Route = preload("res://data/npc_route.gd")
var schedule: Node
var stages: Array[int] = []
var speakers: Array[String] = []

func _run() -> void:
	schedule = root.get_node("NPCSchedule")
	await model_tests()
	state = root.get_node("AppState")
	state.start_new_game()
	check(not schedule.started, "NPC sequence is idle before campus")
	state.enter_campus()
	await acquire_world()
	check(schedule.started, "Campus starts sequence without interaction")
	check_route("campus")
	# The player cannot walk through an NPC: approach Sam and push into him.
	var sam: Node3D
	for node in dorm.find_children("*", "Node3D", true, false):
		if node.get_script() == load("res://npc/student.gd") and node.actor_id == "sam":
			sam = node
	var spawn := player.global_position
	player.global_position = sam.global_position + Vector3(1.4, 0.05, 0)
	await ticks(3)
	var closest := 9.0
	drive(Vector3.LEFT)
	for index in range(90):
		await ticks(1)
		closest = minf(closest, Vector2(player.global_position.x - sam.global_position.x, player.global_position.z - sam.global_position.z).length())
	release_movement()
	check(closest > 0.45, "Player is blocked by an NPC instead of passing through (closest %.2f m)" % closest)
	check(player.interaction.enabled, "NPC blockers do not disable interaction")
	player.global_position = spawn
	await ticks(3)
	var initial_position: Vector3 = schedule.actor_position
	dorm.hud.set_settings_open(true)
	await ticks(180)
	check(schedule.actor_position.distance_to(initial_position) > 0.5, "NPC moves while settings is open")
	check(not paused, "Settings leaves simulation running")
	dorm.hud.set_settings_open(false)
	# Follow the autonomous actor, without activating it.
	await walk_to(Vector3(-12, 0, 1))
	await walk_to(Vector3(-8, 0, 1))
	for index in range(600):
		if schedule.stage == schedule.Stage.CONVERSATION:
			break
		await ticks(1)
	check(schedule.stage == schedule.Stage.CONVERSATION, "Autonomous encounter begins")
	await capture("npc-conversation")
	var views := dorm.find_children("*", "Node3D", true, false)
	var alex: Node3D
	for node in views:
		if node.get_script() == load("res://npc/student.gd") and node.actor_id == "alex":
			alex = node
	check(is_instance_valid(alex) and alex.speech.visible and alex.speech.text.contains("Hey"), "In-world conversation visible")
	# Leave while talking: the event must continue in the persistent model.
	state.enter_dorm()
	await acquire_world()
	var previous_count: int = schedule.spoken_count
	await ticks(240)
	check(schedule.spoken_count > previous_count, "Conversation advances offscreen")
	state.enter_campus()
	await acquire_world()
	check(schedule.spoken_count >= 2, "Scene re-entry does not restart dialogue")
	state.enter_lecture_building()
	await acquire_world()
	check_route("lecture_building")
	state.enter_lecture_hall()
	await acquire_world()
	check_route("lecture_hall")
	for index in range(2400):
		if schedule.stage == schedule.Stage.SEATED:
			break
		await ticks(1)
	await ticks(3)
	check(dorm.actor.sit_sequence != null and dorm.actor.sit_approach == "front", "Watched NPC turns and sits from the row walkway")
	for index in range(360):
		if dorm.actor.sit_sequence == null:
			break
		await ticks(1)
	check(dorm.actor.global_position.distance_to(dorm.alex_seat.point(dorm.alex_seat.SIT_POINT)) < 0.01, "NPC sit animation ends on the cushion")
	check(schedule.stage == schedule.Stage.SEATED, "NPC completes building/seat route autonomously")
	check(schedule.spoken_count == 3 and schedule.seated_count == 1, "Three lines and one seating event")
	check(dorm.actor.visible and dorm.actor.was_seated, "Seated NPC view visible in Hall A")
	check(is_equal_approx(dorm.actor.appearance.hips[0].rotation.x, PI / 2), "Seated pose bends the legs")
	await capture("npc-seated")
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	check(dorm.actor.was_seated and schedule.seated_count == 1, "Seated pose survives leave/re-entry without replay")
	state.return_to_title()
	await scene_changed
	await ticks(2)
	state.start_new_game()
	check(schedule.stage == schedule.Stage.IDLE and schedule.spoken_count == 0 and not schedule.started, "New Game resets NPC event")
	print("NPC: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func model_tests() -> void:
	var baseline: Vector3
	for rate in [30, 60, 120]:
		var model := Schedule.new()
		root.add_child(model)
		model.set_process(false)
		model.start()
		for index in range(rate * 5):
			model.advance(1.0 / rate)
		if rate == 30:
			baseline = model.actor_position
		check(model.actor_position.distance_to(baseline) < 0.001, "NPC movement independent of frame rate: %s" % rate)
		model.advance(90)
		check(model.stage == model.Stage.SEATED and model.spoken_count == 3, "Large delta safely crosses stages")
		model.advance(90)
		check(model.seated_count == 1, "Finished sequence cannot replay")
		model.queue_free()
	await ticks(1)
	var model := Schedule.new()
	root.add_child(model)
	model.set_process(false)
	model.stage_changed.connect(func(stage: int) -> void: stages.append(stage))
	model.line_spoken.connect(func(speaker: String, _text: String) -> void: speakers.append(speaker))
	model.start()
	model.start()
	model.advance(100)
	check(stages == [1, 2, 3, 4, 5, 6], "Ordered autonomous state transitions")
	check(speakers == ["alex", "sam", "alex"], "Conversation alternates speakers correctly")
	check(model.zone == "lecture_hall" and model.actor_position.is_equal_approx(Route.HALL_SEAT), "Actor reaches its reserved seat")
	model.reset()
	check(model.stage == model.Stage.IDLE and model.seated_count == 0, "Reset clears event completion")
	model.queue_free()
	await ticks(1)
	for zone in Route.GRAPHS:
		var points: Array = Route.GRAPHS[zone].points
		var path_points := Route.find_path(zone, 0, points.size() - 1)
		check(path_points.size() == points.size(), "Connected AStar navigation graph: " + zone)

func check_route(zone: String) -> void:
	var points := Route.find_path(zone, 0, Route.GRAPHS[zone].points.size() - 1)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.55
	var clear := true
	for index in range(points.size() - 1):
		var samples := ceili(points[index].distance_to(points[index + 1]) / 0.2)
		for sample in range(samples + 1):
			var point := points[index].lerp(points[index + 1], float(sample) / samples)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0, 0.84, 0))
			query.collision_mask = 1
			if not dorm.get_world_3d().direct_space_state.intersect_shape(query).is_empty():
				clear = false
				print("Blocked authored route: ", zone, " ", point)
	check(clear, "Authored NPC path clears world geometry: " + zone)

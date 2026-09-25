extends "res://tests/campus_test.gd"
## The Emergency Department: the campus side (the ED entrance behind the
## hospital, the ambulance that pulls in and backs into the bay about every
## five minutes, its crew and the bay's automatic doors) and the department
## itself, with real movement: the walk-in's two sets of automatic doors,
## security, triage and the ESI board, the doors into the treatment area,
## the automatic doors of the treatment rooms and trauma bays (which stay
## shut as you walk past, and when locked), the EMS vestibule doors, an EMS
## arrival wheeled through the doors to a bay, walk-ins, the elevator up to
## Emergency Radiology, the link to the main atrium, first person, saving,
## and leaving for campus.
var hospital: Node3D
var life: Node

## World position of an ED zone-local point (the ED is 140 m west of the atrium).
static func ed(x: float, z: float) -> Vector3:
	return Vector3(x - 140.0, 0, z)

func _run() -> void:
	state = root.get_node("AppState")
	await campus_side()
	await entrance_and_triage()
	await treatment_doors()
	await ems_arrival()
	await life_and_imaging()
	await links_and_leaving()
	Engine.time_scale = 1.0
	print("EMERGENCY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

# --- Campus: the ED entrance and the ambulance ----------------------------------------------------

func campus_side() -> void:
	state.start_new_game()
	state.phase = state.Phase.CAMPUS
	state.campus_entry = "hospital"
	change_scene_to_file("res://world/campus/campus.tscn")
	await acquire_world()
	var ems: Node3D = dorm.ems
	check(ems != null and ems.period == 300.0, "An ambulance comes about every five real minutes (%s s)" % ems.period)
	check(ems.timer <= 30.0, "The first ambulance comes soon after you arrive (%.0f s)" % ems.timer)
	check(is_instance_valid(ems.parked) and Rect2(-9, 58, 18, 12).has_point(Vector2(ems.parked.global_position.x, ems.parked.global_position.z)), "An ambulance stands parked in the AMBULANCE ONLY bay")
	# On foot from the entrance plaza, south along the building to the ED doors.
	for point in [Vector3(30.0, 0, 58), Vector3(30.0, 0, 66), Vector3(29.0, 0, 72.0), Vector3(20.0, 0, 72.0), Vector3(15.0, 0, 71.4)]:
		await walk_to(point)
	check(player.interaction.target == dorm.ed_door and dorm.hud.prompt.text == "Enter the Emergency Department", "The ED walk-in entrance is reachable behind the hospital")
	var tracked: Vector3 = dorm.camera.tracked_point
	check(tracked.z > 60.0, "The camera follows round to the ED (%.1f)" % tracked.z)
	# The street stays closed: the sidewalk's edge holds.
	var spot := player.position
	drive(Vector3.BACK)
	await ticks(40)
	release_movement()
	check(player.position.z < 75.0, "The ED sidewalk's edge holds at the street")
	await reset_position(spot)
	# The ambulance: along the street with its lights on, backs into the bay,
	# the crew wheels the patient through the automatic doors and comes back.
	Engine.time_scale = 4.0
	ems.arrive()
	check(ems.ambulance.lights_on, "The ambulance arrives with its lights on")
	var seen := {}
	var doors_opened_for_crew := false
	for tick in range(6000):
		await ticks(1)
		seen[ems.state] = true
		if ems.state == "wheeling_in" and is_instance_valid(ems.crew) and ems.crew.global_position.distance_to(ems.doors.global_position) < 2.0 and ems.doors.open_amount > 0.5:
			doors_opened_for_crew = true
		if ems.state == "inside":
			break
	check(seen.has("backing") and seen.has("unloading") and seen.has("wheeling_in"), "It backs into the bay and the crew unloads %s" % str(seen.keys()))
	check(doors_opened_for_crew, "The bay's automatic doors open for the crew and their stretcher")
	check(ems.state == "inside" and not ems.crew.visible, "The crew wheels the patient inside")
	var parked_rear: Vector3 = ems.ambulance.to_local(ems.doors.global_position)
	check(parked_rear.z > 0.0, "It is backed in: the rear faces the doors")
	await capture("ed-ambulance-bay")
	ems.timer = 0.1
	for tick in range(6000):
		await ticks(1)
		seen[ems.state] = true
		if ems.state == "idle":
			break
	check(ems.cycles == 1 and seen.has("wheeling_out") and seen.has("departing"), "The crew brings the empty cot back and the ambulance leaves")
	check(ems.timer > 20.0 and ems.timer < 300.0, "The next ambulance is due within five minutes (%.0f s)" % ems.timer)
	Engine.time_scale = 1.0
	use_endpoint()
	await acquire_world()
	hospital = dorm
	life = hospital.ed_life
	check(state.phase == state.Phase.HOSPITAL and hospital.zone == "ed", "Arrive in the Emergency Department")
	check(hospital.hud.location_label.text.contains("EMERGENCY DEPARTMENT"), "Location shows the Emergency Department")

# --- Walk-in: doors, security, triage -------------------------------------------------------------

## Holds the department's own EMS arrivals so a test can send one when it wants.
func hold_ems() -> void:
	if life.ems_state == "inbound":
		life.ems_bay.reserved = false
		life.ems_bay = {}
		life.ems_call = {}
		life.ems_state = "idle"
	life.next_ems = 1.0e6

func entrance_and_triage() -> void:
	hold_ems()
	var doors: Dictionary = hospital.ed_layout.doors
	var inner: Node3D = doors.walkin_inner
	var outer: Node3D = doors.walkin_outer
	check(player.global_position.distance_to(hospital.anchor("ed_entrance")) < 0.3, "Arrive inside the walk-in doors")
	# Out through both sets of doors to the exit, then back in.
	await walk_to(ed(30.0, 16.9))
	check(inner.open_amount > 0.9 and outer.open_amount > 0.5, "The walk-in's automatic doors open as you walk up")
	check(player.interaction.target == hospital.ed_exit, "The exit is at the outer doors")
	await walk_to(ed(30.0, 14.9))
	await walk_to(ed(30.0, 12.0))
	check(player.global_position.z < 12.4, "Walked through the security screening arch")
	await ticks(150)
	check(inner.is_closed() and outer.is_closed(), "The walk-in doors close behind you")
	# Shut doors block: with the sensor off, walking into them stops you.
	inner.auto_target = null
	inner.auto_group = ""
	await reset_position(ed(30.0, 14.6))
	drive(Vector3.BACK)
	await ticks(50)
	release_movement()
	check(player.global_position.z < 15.7 and inner.is_closed(), "Closed automatic doors are solid")
	inner.auto_target = player
	inner.auto_group = "door_openers"
	await ticks(40)
	check(inner.open_amount > 0.5, "They open again when you step up to them")
	# Triage information.
	for point in [ed(30.0, 12.0), ed(29.6, 11.0), ed(25.4, 10.9), ed(24.4, 13.3)]:
		await walk_to(point)
	check(player.interaction.target != null and player.interaction.target.name == "ESIBoard", "The triage board can be read")
	await press_interact()
	check(hospital.hud.message.text.contains("Level 1 · Resuscitation") and hospital.hud.message.text.contains("most critical"), "ESI: Level 1 is the most critical")
	var levels := {}
	for row in life.tracking_rows():
		levels[int(row.esi)] = true
	check(levels.has(1) and (levels.has(4) or levels.has(5)) and (levels.has(2) or levels.has(3)), "The tracking board lists patients across the ESI levels %s" % str(levels.keys()))
	check(hospital.displays.tracking.source == life and hospital.displays.trauma.source == life, "The boards show the department's live state")
	# Into the treatment area through the automatic doors.
	var super_track: Node3D = doors.super_track
	for point in [ed(24.4, 10.3), ed(30.8, 9.8), ed(31.5, 6.2), ed(31.5, 2.4), ed(31.5, 0.4)]:
		await walk_to(point)
	check(player.global_position.z < 2.0, "Through the automatic doors into Super Track (ESI 4–5)")
	check(super_track.open_amount > 0.3, "The treatment-area doors opened")
	await capture("ed-super-track")

# --- Treatment rooms and trauma bays -----------------------------------------------------------

func treatment_doors() -> void:
	var doors: Dictionary = hospital.ed_layout.doors
	# Along the corridor to Room 1, past the other rooms' doors.
	for point in [ed(31.5, -8.0), ed(24.0, -8.0), ed(16.0, -8.0), ed(8.0, -8.0), ed(0.0, -8.0), ed(-8.0, -8.0), ed(-11.25, -8.0)]:
		await walk_to(point)
	var room3: Node3D = doors.room_3
	check(room3.is_closed(), "Room doors stay shut as you walk past along the corridor")
	var room1: Node3D = doors.room_1
	await walk_to(ed(-11.25, -10.2))
	await walk_to(ed(-11.25, -12.4))
	check(player.global_position.z < -11.8, "Into Room 1 through its automatic sliding doors")
	check(room1.open_amount > 0.8, "Room 1's doors opened")
	await walk_to(ed(-11.25, -8.0))
	await ticks(120)
	check(room1.is_closed(), "Room 1's doors close again")
	# Room 11 is being cleaned: its doors stay locked.
	var room11: Node3D = doors.room_11
	for point in [ed(-3.0, -8.0), ed(5.0, -8.0), ed(13.0, -8.0), ed(21.0, -8.0), ed(28.75, -8.0), ed(28.75, -9.6)]:
		await walk_to(point)
	drive(Vector3.FORWARD)
	await ticks(50)
	release_movement()
	check(room11.is_closed() and player.global_position.z > -10.95, "A locked room's doors stay shut")
	# Trauma 4.
	var trauma4: Node3D = doors.T4
	for point in [ed(28.75, -8.0), ed(21.0, -8.0), ed(13.0, -8.0), ed(5.0, -8.0), ed(-3.0, -8.0), ed(-11.0, -8.0), ed(-16.5, -8.0), ed(-16.5, -10.4), ed(-16.5, -12.6)]:
		await walk_to(point)
	check(player.global_position.z < -12.0 and trauma4.open_amount > 0.8, "Into Trauma 4 through its automatic doors")
	await walk_to(ed(-16.5, -8.0))
	# The EMS vestibule: both sets of doors, out into the ambulance garage.
	var amb_inner: Node3D = doors.ambulance_inner
	var amb_outer: Node3D = doors.ambulance_outer
	for point in [ed(-21.0, -7.0), ed(-21.0, 0.0), ed(-21.0, 8.0), ed(-21.0, 12.6), ed(-22.0, 16.0)]:
		await walk_to(point)
	check(amb_inner.open_amount > 0.5, "The EMS vestibule's inner doors open for you")
	await walk_to(ed(-22.0, 19.8))
	check(player.global_position.z > 18.8 and amb_outer.open_amount > 0.5, "Through the outer doors into the ambulance garage")
	check(is_instance_valid(life.parked), "An ambulance is parked in the ED garage")
	# The medication room's badge-reader door.
	var med_doors: Node3D = doors.med_room
	for point in [ed(-22.0, 16.0), ed(-21.0, 11.0), ed(-21.0, 1.0)]:
		await walk_to(point)
	check(med_doors.is_closed(), "The medication room's door is shut")
	await walk_to(ed(-24.9, 1.0))
	await ticks(20)
	check(med_doors.open_amount > 0.9, "It opens as you walk up (badge reader)")
	await walk_to(ed(-28.2, 1.0))
	check(player.interaction.target != null and player.interaction.target.name == "MedRoom", "Inside the medication room at the dispensing cabinets")
	for point in [ed(-24.0, 1.0), ed(-21.0, 1.0), ed(-21.0, 5.0), ed(-14.0, 4.0)]:
		await walk_to(point)

# --- An EMS arrival wheeled through the doors -------------------------------------------------------

func ems_arrival() -> void:
	var doors: Dictionary = hospital.ed_layout.doors
	var outer: Node3D = doors.ambulance_outer
	# Stand well away from the doors, so only the crew can open them.
	await walk_to(ed(-4.0, 1.0))
	Engine.time_scale = 4.0
	for tick in range(9000):
		if life.ems_state == "idle":
			break
		await ticks(1)
	life.dispatch_now()
	var info: Dictionary = life.status_info()
	check(not info.next_ems.is_empty(), "The trauma board shows the unit inbound")
	var bay: Dictionary = life.ems_bay
	var opened_for_crew := false
	var bay_doors_opened := false
	for tick in range(9000):
		await ticks(1)
		if is_instance_valid(life.crew):
			if life.crew.global_position.distance_to(outer.global_position) < 1.2 and outer.open_amount > 0.5:
				opened_for_crew = true
			for key in doors:
				var door: Node3D = doors[key]
				if key.begins_with("T") or key.begins_with("room"):
					if life.crew.global_position.distance_to(door.global_position) < 1.2 and door.open_amount > 0.5:
						bay_doors_opened = true
		if life.ems_state == "handoff" and not life.crew.has_patient():
			break
	check(life.arrivals >= 1, "An EMS crew wheeled a patient in")
	check(opened_for_crew, "The ambulance entrance doors open for the crew and stretcher")
	check(bay_doors_opened, "The bay's automatic doors open for the stretcher")
	check(bay.occupied and bay.patient.visible and life.beds.has(bay.id), "Handed over: the patient is in %s and on the board" % bay.bed)
	await capture("ed-ems-handover")
	life.crew.set_present(false)
	var shapes: Array = life.crew.find_children("*", "CollisionShape3D", true, false)
	check(not shapes.is_empty() and shapes.all(func(shape: Node) -> bool: return shape.disabled), "A crew gone through a door leaves nothing solid behind")
	life.crew.set_present(true)
	# The empty cot is backed out of the bay, not turned round between the bed
	# and the wall. The next unit may already be inbound once this one has gone.
	var seen := {}
	var room_heading := NAN
	var turned_in_room := false
	for tick in range(9000):
		await ticks(1)
		seen[life.ems_state] = true
		if life.ems_state == "returning" and is_instance_valid(life.crew) and life.crew.global_position.z < -11.3:
			if is_nan(room_heading):
				room_heading = life.crew.heading
			elif absf(angle_difference(room_heading, life.crew.heading)) > 0.6:
				turned_in_room = true
		if seen.has("departing") and life.ems_state in ["idle", "inbound"]:
			break
	check(not is_nan(room_heading) and not turned_in_room, "The crew backs the empty cot out of the bay")
	check(seen.has("returning") and seen.has("departing") and life.ambulance == null and life.crew == null, "The crew takes the cot back out and the ambulance leaves %s" % str(seen.keys()))
	Engine.time_scale = 1.0
	hold_ems()

# --- Walk-ins, transport and radiology ------------------------------------------------------------

func life_and_imaging() -> void:
	var walkins_before: int = life.walkins
	var doors: Dictionary = hospital.ed_layout.doors
	var outer: Node3D = doors.walkin_outer
	var opened := false
	life.timers.walkin = 0.0
	for tick in range(1200):
		await ticks(1)
		if outer.open_amount > 0.5 and player.global_position.distance_to(outer.global_position) > 6.0:
			opened = true
		if opened and life.walkins > walkins_before:
			break
	check(life.walkins > walkins_before, "A walk-in patient comes in off the street")
	check(opened, "The walk-in doors open for patients too")
	check(life.staff.size() >= 5 and life.walkers.size() >= 8, "Staff and patients move around the department")
	# Up to Emergency Radiology.
	for point in [ed(-6.0, 1.0), ed(-12.0, 5.5), ed(-12.4, 12.2)]:
		await walk_to(point)
	check(player.interaction.target == hospital.elevator_calls.ed[0], "The elevator to radiology can be called")
	check(hospital.hud.prompt.text.contains("Emergency Radiology"), "It goes to Level 2 · Emergency Radiology")
	await press_interact()
	for tick in range(120):
		if hospital.ed_elevator.is_open():
			break
		await ticks(1)
	await walk_until(hospital.cab_centre("ed"), func() -> bool: return hospital.riding)
	for tick in range(300):
		if hospital.zone == "imaging" and not hospital.riding:
			break
		await ticks(1)
	check(hospital.zone == "imaging" and hospital.hud.location_label.text.contains("EMERGENCY RADIOLOGY"), "Up to Emergency Radiology")
	var table: Node3D = hospital.imaging_layout.tables[0].node
	life.table_clock = 0.0
	await ticks(2)
	var start := table.global_position
	await ticks(120)
	check(table.global_position.distance_to(start) > 0.05, "The CT table slides the patient in and out")
	check(hospital.imaging_layout.tables.size() == 3, "CT 1, CT 2 and MRI tables")
	await walk_to(hospital.imaging_layout.points.elevator_front + Vector3(0, 0, -0.4))
	await walk_to(hospital.anchor("imaging_corridor") + Vector3(-4, 0, 0))
	await capture("ed-radiology")
	# Back down.
	await walk_to(hospital.imaging_layout.points.elevator_front + Vector3(0, 0, -0.4))
	await walk_to(hospital.imaging_layout.points.elevator_front + Vector3(-0.97, 0, 0.5))
	check(player.interaction.target == hospital.elevator_calls.imaging[0], "The elevator back to the ED can be called")
	await press_interact()
	for tick in range(120):
		if hospital.imaging_elevator.is_open():
			break
		await ticks(1)
	await walk_until(hospital.cab_centre("imaging"), func() -> bool: return hospital.riding)
	for tick in range(300):
		if hospital.zone == "ed" and not hospital.riding:
			break
		await ticks(1)
	check(hospital.zone == "ed", "Back down to the Emergency Department")
	await ticks(10)

# --- The atrium link, first person, saving, leaving ------------------------------------------------

func links_and_leaving() -> void:
	# First person: the department is whole and walkable, and doors open for you.
	state.set_first_person(true)
	await ticks(3)
	var ed_layers: Array = hospital.layers[2]
	check(ed_layers[0].visible and not ed_layers[1].visible, "First person shows the whole ED")
	await walk_fp(ed(-12.0, 4.0))
	await walk_fp(ed(-7.4, -1.0))
	await walk_fp(ed(-7.4, -8.0))
	await walk_fp(ed(-3.25, -8.2))
	await walk_fp(ed(-3.25, -12.6))
	check(player.global_position.z < -12.0, "First person: into Room 3 through its automatic doors")
	await capture("ed-room-first-person")
	await walk_fp(ed(-3.25, -8.0))
	await walk_fp(ed(12.0, -8.0))
	await walk_fp(ed(26.0, -8.0))
	await walk_fp(ed(31.2, -8.0))
	state.set_first_person(false)
	await ticks(3)
	# The staff door to the main atrium and back.
	await walk_to(ed(32.4, -9.0))
	check(player.interaction.target == hospital.ed_to_lobby, "The door to the main hospital")
	await press_interact()
	await ticks(20)
	check(hospital.zone == "lobby" and hospital.hud.location_label.text.contains("LEVEL 1"), "Through to the main atrium")
	await ticks(5)
	check(player.interaction.target == hospital.lobby_to_ed, "The atrium's staff door back to the ED")
	await press_interact()
	await ticks(20)
	check(hospital.zone == "ed", "Back in the Emergency Department")
	# Saving here resumes here.
	var save := root.get_node("SaveGame")
	check(save.save(), "Save in the ED: " + save.last_error)
	var data: Dictionary = save.read()
	check(String(data.location.get("hospital_entry", "")) == "ed", "The save remembers the ED")
	# Out through the walk-in doors to campus, by the exit lane beside the security arch.
	for point in [ed(31.2, -2.6), ed(31.5, 2.4), ed(31.5, 6.2), ed(31.2, 11.0), ed(31.2, 14.3), ed(30.0, 14.9), ed(30.0, 16.9)]:
		await walk_to(point)
	check(player.interaction.target == hospital.ed_exit, "Exit in reach at the outer doors")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.CAMPUS and player.position.distance_to(Config.SPAWNS.ed) < 0.2, "Back on campus outside the ED")

## The shared walk, but it steps round people: the department is busy, and
## staff and stretchers stop for you rather than walk through you.
func walk_to(destination: Vector3) -> void:
	var last := player.position
	var stalled := 0
	var dodge := 0
	var side := 1.0
	for index in range(700):
		var offset := destination - player.position
		offset.y = 0
		if offset.length() < 0.12:
			release_movement()
			await ticks(2)
			return
		var direction := offset.normalized()
		if dodge > 0:
			dodge -= 1
			direction = (direction.cross(Vector3.UP) * side + direction * 0.3).normalized()
		drive(direction)
		await ticks(1)
		stalled = stalled + 1 if player.position.distance_to(last) < 0.004 else 0
		last = player.position
		if stalled > 25:
			stalled = 0
			dodge = 25
			side = -side
	release_movement()
	check(false, "Walking route blocked at %s toward %s" % [player.position, destination])

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

## First-person walking, stepping round people like walk_to.
func walk_fp(destination: Vector3) -> void:
	var last := player.global_position
	var stalled := 0
	var dodge := 0
	var side := 1.0
	for index in range(700):
		var offset := destination - player.global_position
		offset.y = 0.0
		if offset.length() < 0.15:
			release_movement()
			await ticks(2)
			return
		var direction := offset.normalized()
		if dodge > 0:
			dodge -= 1
			direction = (direction.cross(Vector3.UP) * side + direction * 0.3).normalized()
		player.first_person.yaw = atan2(-direction.x, -direction.z)
		release_movement()
		Input.action_press("move_up")
		await ticks(1)
		stalled = stalled + 1 if player.global_position.distance_to(last) < 0.004 else 0
		last = player.global_position
		if stalled > 25:
			stalled = 0
			dodge = 25
			side = -side
	release_movement()
	check(false, "First-person route blocked at %s toward %s" % [player.global_position, destination])

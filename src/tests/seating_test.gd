extends "res://tests/campus_test.gd"
## Hall A seating: row-seat routes through the walkway graph, free-standing
## chair approaches, the kinematic sit/stand, the lecture camera hand-off, and
## that the body never passes through a seat or overlaps solid geometry.
const Seat = preload("res://world/seat.gd")
var clipping_ticks := 0
var overlap_ticks := 0
var hall: Node3D

func _run() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	state.enter_campus("dorm")
	await acquire_world()
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	hall = dorm
	check(hall.seats.size() == 65, "Five tiers of auditorium seating (%d seats)" % hall.seats.size())
	var free := 0
	for seat in hall.seats:
		if seat.is_free():
			free += 1
		check((seat.interactable != null) == seat.is_free(), "Interaction only on free seats: " + seat.name)
	check(free == 50, "Fifty open seats (%d)" % free)
	check(hall.find_children("*", "Node3D", true, false).filter(func(n): return n.get("seated_pose") == true).size() >= 14, "Several seated classmates")
	check(is_instance_valid(hall.professor) and hall.has_node("Podium"), "Professor at the podium")
	var rows := {}
	for seat in hall.seats:
		rows[snappedf(seat.position.y, 0.01)] = true
	check(rows.size() == 5, "Seats rise over five distinct tier heights")
	var target: Node3D = hall.get_node("Seat_R2_C4") # x 0.92, row 2
	var front: Vector3 = target.point(Seat.FRONT_POINT)
	await sit_from(target, "front", front + Vector3(0.12, 0, 0))
	await sit_from(target, "row_left", hall.get_node("Seat_R2_C2").point(Seat.FRONT_POINT))
	await sit_from(target, "row_right", hall.get_node("Seat_R2_C6").point(Seat.FRONT_POINT))
	await sit_from(target, "back", hall.get_node("Seat_R3_C4").point(Seat.FRONT_POINT))
	await sit_from(hall.get_node("Seat_R0_C3"), "front", Vector3(0.0, 0.0, -3.1))
	await sit_from(hall.get_node("Seat_R0_C1"), "row_left", Vector3(-3.9, 0.0, -4.3))
	# Free-standing table chairs keep their side approaches.
	var chair: Node3D = hall.table_chairs[0]
	await sit_from(chair, "left", chair.point(Vector3(-0.95, 0, 0.05)))
	for rate in [30, 120]:
		Engine.physics_ticks_per_second = rate
		await sit_from(target, "row_left", hall.get_node("Seat_R2_C2").point(Seat.FRONT_POINT))
	Engine.physics_ticks_per_second = 60
	await camera_checks(target)
	# Blocked: the table blocks one chair's front and left, a solid blocks its right.
	var blocked: Node3D = hall.table_chairs[1]
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.5, 2.0, 1.4)
	shape.position = Vector3(0, 1, 0)
	blocker.add_child(shape)
	hall.add_child(blocker)
	blocker.global_position = blocked.point(Vector3(0.75, 0, -0.1))
	await place(blocked.point(Vector3(0.0, 0, 0.95)))
	player.seating.request(blocked)
	check(player.seating.state == player.seating.State.FREE and hall.hud.message.text.contains("no room"), "Unreachable chair is refused with feedback")
	blocker.queue_free()
	check(clipping_ticks == 0, "Body never entered a seat outside the sit motion (%d ticks)" % clipping_ticks)
	check(overlap_ticks == 0, "Walking never overlapped solid geometry (%d ticks)" % overlap_ticks)
	await capture("seating")
	print("SEATING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func camera_checks(target: Node3D) -> void:
	var front: Vector3 = target.point(Seat.FRONT_POINT)
	await place(front)
	await ticks(4)
	check(player.interaction.target == target.interactable and hall.hud.prompt.text == "Sit down", "Sit prompt shown in front of a free seat")
	var probe: Vector3 = target.point(Vector3(0, 1.0, 0))
	press_interact()
	await wait_state(player.seating.State.SEATED)
	var lecture: Camera3D = hall.lecture_camera
	check(lecture.current, "Lecture camera takes over once seated")
	check(lecture.projection == Camera3D.PROJECTION_PERSPECTIVE, "Lecture view is perspective")
	# The first blended frame matches the orthographic framing.
	var drift: float = hall.camera.unproject_position(probe).distance_to(lecture.unproject_position(probe))
	check(drift < 4.0, "Hand-off starts from the same framing (%.1f px)" % drift)
	await ticks(130)
	check(lecture.in_lecture_view(), "Transition settles into the lecture view")
	var pose: Transform3D = hall.lecture_pose(target)
	check(lecture.global_position.distance_to(pose.origin) < 0.01 and absf(lecture.fov - lecture.LECTURE_FOV) < 0.01, "Lecture pose reached exactly")
	check(lecture.global_position.distance_to(target.point(Seat.SIT_POINT)) < 2.5, "Lecture view sits just behind the student")
	Input.action_press("move_up")
	await ticks(20)
	Input.action_release("move_up")
	check(player.global_position.distance_to(target.point(Seat.SIT_POINT)) < 0.01, "Movement input is ignored while seated")
	await ticks(3)
	check(hall.hud.prompt.text == "Stand up", "Seated prompt offers standing")
	press_interact()
	await wait_state(player.seating.State.FREE)
	await ticks(120)
	check(hall.camera.current and not lecture.current, "Exploration camera returns after standing")
	var exit: Vector3 = player.global_position
	await walk_to(exit + Vector3(-0.3, 0, -0.2))
	check(player.global_position.distance_to(exit) > 0.2, "Normal movement resumes after standing")

func sit_from(seat: Node3D, expected: String, from: Vector3) -> void:
	await place(from)
	player.seating.request(seat)
	check(player.seating.approach == expected, "Approach %s (got %s) for %s" % [expected, player.seating.approach, seat.name])
	await wait_state(player.seating.State.SEATED, seat)
	check(player.global_position.distance_to(seat.point(Seat.SIT_POINT)) < 0.01, "Seated on the cushion via " + expected)
	check(is_equal_approx(player.appearance.sit_blend, 1.0) and is_equal_approx(player.appearance.hips[0].rotation.x, PI / 2), "Seated pose complete via " + expected)
	check(absf(wrapf(player.appearance.rotation.y - seat.seated_yaw(), -PI, PI)) < 0.01, "Facing the front after sitting via " + expected)
	await ticks(2)
	check(player.interaction.target == seat.interactable, "Own seat targeted for standing")
	player.seating.request(seat)
	await wait_state(player.seating.State.FREE, seat)
	check(player.seating._is_clear(player.global_position) and player.appearance.sit_blend == 0.0, "Stands up clear of furniture after " + expected)
	check(not player.external_control and seat.is_free(), "Control and seat released after " + expected)
	await ticks(100) # Let the camera finish returning before the next case.

func wait_state(target: int, seat: Node3D = null) -> void:
	for index in range(1500):
		if seat != null:
			audit(seat)
		if player.seating.state == target:
			return
		await ticks(1)
	check(false, "Timed out waiting for seating state %d" % target)

## Outside the sit/rise itself, the body origin must stay out of every nearby
## seat's footprint, and walking must never overlap world colliders.
func audit(own: Node3D) -> void:
	var sequence = player.seating.sequence
	var kind: String = sequence.current_kind() if sequence != null else ""
	var settled: bool = player.seating.state == player.seating.State.SEATED
	for seat in hall.seats + hall.table_chairs:
		if seat.global_position.distance_to(player.global_position) > 1.6:
			continue
		if seat == own and (kind in ["sit", "rise"] or settled):
			continue
		var local: Vector3 = seat.to_local(player.global_position)
		if absf(local.y) < 0.5 and absf(local.x) < seat.width / 2 + 0.05 and local.z > -Seat.DEPTH / 2 - 0.05 and local.z < Seat.DEPTH / 2 + 0.15:
			clipping_ticks += 1
	if kind == "walk":
		var shape: CollisionShape3D = player.get_node("CollisionShape3D")
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape.shape
		query.transform = Transform3D(Basis.IDENTITY, player.global_position + shape.position + Vector3(0, 0.06, 0))
		query.collision_mask = 1
		query.margin = -0.02
		if not player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			overlap_ticks += 1

func place(point: Vector3) -> void:
	player.global_position = point + Vector3(0, 0.04, 0)
	player.velocity = Vector3.ZERO
	await ticks(4)

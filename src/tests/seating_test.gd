extends "res://tests/campus_test.gd"
## Hall A seating: approach side selection, collision-safe walking, the
## kinematic sit/stand, and that the body never passes through a chair.
const Seat = preload("res://world/seat.gd")
var clipping_ticks := 0
var overlap_ticks := 0

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
	var hall := dorm
	check(hall.seats.size() == 18, "Hall A has rows of seats")
	var free := 0
	for seat in hall.seats:
		if seat.is_free():
			free += 1
			check(is_instance_valid(seat.interactable), "Free seat offers an interaction: " + seat.name)
		else:
			check(seat.interactable == null, "Taken seat offers no interaction: " + seat.name)
	check(free == 11, "Eleven open seats for the player")
	check(hall.find_children("*", "Node3D", true, false).filter(func(n): return n.get("seated_pose") == true).size() >= 6, "Several seated classmates")
	check(is_instance_valid(hall.professor), "Professor present at the lectern")
	var seat: Node3D = hall.get_node("Seat_R1_C0")
	# Start points in seat-local space; the seat is unrotated, so these are world offsets.
	var cases := [
		["left", Vector3(-0.9, 0, 0.1)],
		["right", Vector3(0.9, 0, -0.1)],
		["front", Vector3(0, 0, -1.2)],
		["back_right", Vector3(0.2, 0, 0.95)],
		["back_left", Vector3(-0.2, 0, 0.95)],
	]
	for entry in cases:
		await sit_from(seat, entry[0], entry[1])
	# Physics-rate independence of the sit.
	for rate in [30, 120]:
		Engine.physics_ticks_per_second = rate
		await sit_from(seat, "left", Vector3(-0.9, 0, 0.1))
	Engine.physics_ticks_per_second = 60
	# Real keyboard input from the front of a second chair.
	var other: Node3D = hall.get_node("Seat_R1_C1")
	await place(other.point(Vector3(0, 0, -1.1)))
	await ticks(4)
	check(player.interaction.target == other.interactable and hall.hud.prompt.text == "Sit down", "Sit prompt shown near a free seat")
	press_interact()
	await wait_seated(true)
	check(player.seating.seat == other and player.seating.approach == "front", "Interact key sits from the front")
	await ticks(3)
	check(hall.hud.prompt.text == "Stand up", "Seated prompt offers standing")
	Input.action_press("move_up")
	await ticks(20)
	Input.action_release("move_up")
	check(player.global_position.distance_to(other.point(Seat.SIT_POINT)) < 0.01, "Movement input is ignored while seated")
	press_interact()
	await wait_seated(false)
	var exit: Vector3 = player.global_position
	await walk_to(exit + Vector3(0.7, 0, 0))
	check(player.global_position.distance_to(exit) > 0.5, "Normal movement resumes after standing")
	# Blocked approach: occupy the side points with a solid, then request.
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(3.0, 2.0, 0.4)
	shape.position = Vector3(0, 1, 0)
	blocker.add_child(shape)
	hall.add_child(blocker)
	blocker.global_position = seat.point(Vector3(0, 0, -0.9))
	await place(seat.point(Vector3(0, 0, 0.95)))
	await ticks(2)
	player.seating.request(seat)
	check(player.seating.state == player.seating.State.FREE and hall.hud.message.text.contains("no room"), "Unreachable seat is refused with feedback")
	blocker.queue_free()
	check(clipping_ticks == 0, "Body never entered a chair outside the sit motion (%d ticks)" % clipping_ticks)
	check(overlap_ticks == 0, "Walking approach never overlapped solid geometry (%d ticks)" % overlap_ticks)
	await capture("seating")
	print("SEATING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func sit_from(seat: Node3D, expected: String, offset: Vector3) -> void:
	await place(seat.point(offset))
	player.seating.request(seat)
	check(player.seating.approach == expected, "Approach from %s chooses %s (got %s)" % [expected, expected, player.seating.approach])
	await wait_seated(true, seat)
	check(player.global_position.distance_to(seat.point(Seat.SIT_POINT)) < 0.01, "Seated on the cushion from " + expected)
	check(is_equal_approx(player.appearance.sit_blend, 1.0) and is_equal_approx(player.appearance.hips[0].rotation.x, PI / 2), "Seated pose complete from " + expected)
	check(absf(wrapf(player.appearance.rotation.y - seat.seated_yaw(), -PI, PI)) < 0.01, "Facing the front after sitting from " + expected)
	await ticks(2)
	check(player.interaction.target == seat.interactable, "Own seat targeted for standing")
	player.seating.request(seat)
	await wait_seated(false, seat)
	check(player.global_position.distance_to(seat.point(Seat.EXIT_POINT)) < 0.01 and player.appearance.sit_blend == 0.0, "Stands up clear of the chair after " + expected)
	check(not player.external_control and seat.is_free(), "Control and seat released after " + expected)

func wait_seated(target: bool, seat: Node3D = null) -> void:
	for index in range(900):
		if seat != null:
			audit(seat)
		if (player.seating.state == player.seating.State.SEATED) == target and not (not target and player.seating.busy()):
			return
		await ticks(1)
	check(false, "Timed out waiting for seated=%s" % target)

## Outside the sit/rise itself, the body origin must stay out of the chair's
## footprint (padded), and walking must never overlap world colliders.
func audit(seat: Node3D) -> void:
	var sequence = player.seating.sequence
	var kind: String = sequence.current_kind() if sequence != null else ""
	if kind in ["sit", "rise"] or player.seating.state == player.seating.State.SEATED:
		return
	var local: Vector3 = seat.to_local(player.global_position)
	if absf(local.x) < Seat.WIDTH / 2 + 0.1 and local.z > -Seat.DEPTH / 2 - 0.1 and local.z < Seat.DEPTH / 2 + 0.2:
		clipping_ticks += 1
	if kind == "walk":
		var shape: CollisionShape3D = player.get_node("CollisionShape3D")
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape.shape
		query.transform = Transform3D(Basis.IDENTITY, player.global_position + shape.position + Vector3(0, 0.04, 0))
		query.collision_mask = 1
		query.margin = -0.01
		if not player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			overlap_ticks += 1

func place(point: Vector3) -> void:
	player.global_position = point + Vector3(0, 0.02, 0)
	player.velocity = Vector3.ZERO
	await ticks(3)

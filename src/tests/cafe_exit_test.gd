extends "res://tests/campus_test.gd"
const Seat = preload("res://world/seat.gd")
const Geometry = preload("res://world/geometry.gd")

func _run() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.enter_dorm()
	await acquire_world()
	state.enter_campus("dorm")
	await acquire_world()
	root.get_node("GameClock").running = false
	for first_person in [false, true]:
		state.set_first_person(first_person)
		for name in ["CafeStudySeat1", "CafeStudySeat-1"]:
			var seat: Node3D = dorm.get_node(name)
			check(seat.global_position.z < -7.0, "Study seats are off the entrance walkway")
			player.global_position = seat.point(Vector3(1.02, 0.05, 0.05))
			player.velocity = Vector3.ZERO
			await ticks(3)
			player.seating.request(seat)
			await settle(player.seating.State.SEATED)
			check(player.seating.state == player.seating.State.SEATED, "Can sit in %s (first person %s)" % [name, first_person])
			if player.seating.state != player.seating.State.SEATED:
				continue
			check(not player.seating._is_clear(seat.point(Seat.EXIT_POINT)), "Regression geometry: the old forward exit intersects the table")
			# Both sides blocked: retain the seated pose instead of placing the body in furniture.
			var blocks: Array[Node3D] = []
			for side in [-1, 1]:
				blocks.append(Geometry.box(dorm, "ExitBlocker", Vector3(0.3, 1.8, 0.3), seat.point(Vector3(side * 0.82, 0.9, Seat.PRE_SIT.z)), Color.BLACK, true))
			await ticks(2)
			player.seating.stand_up()
			check(player.seating.state == player.seating.State.SEATED, "Blocked exits leave the player safely seated")
			# Unblock the opposite side, so the planner must also support its fallback.
			blocks[0].queue_free()
			await ticks(2)
			player.seating.stand_up()
			await settle(player.seating.State.FREE)
			blocks[1].queue_free()
			await ticks(3)
			check(player.seating.state == player.seating.State.FREE and not player.external_control, "Rise returns movement control")
			check(player.seating._is_clear(player.global_position), "Exit capsule does not overlap table or chair")
			var exited := player.global_position
			# Continue in the chosen side's direction, then around the back of the chair.
			var side := signf(seat.to_local(exited).x)
			await walk_to(seat.point(Vector3(side * 1.35, 0, -0.45)))
			await walk_to(seat.point(Vector3(side * 1.35, 0, 0.7)))
			check(player.global_position.distance_to(exited) > 0.9, "Real movement leaves the table area after standing")
			check(player.seating._is_clear(player.global_position), "Player remains clear of furniture after walking away")
	state.set_first_person(false)
	# Walk all the way across the café's former obstructed approach.
	player.global_position = Vector3(15.5, 0.05, -2)
	await ticks(3)
	await walk_to(Vector3(19.2, 0, -2))
	check(player.global_position.x > 19.0, "The café entrance walkway is unobstructed")
	print("CAFE EXIT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func settle(target: int) -> void:
	for index in range(500):
		if player.seating.state == target:
			return
		await ticks(1)

func drive(direction: Vector3) -> void:
	release_movement()
	var basis: Basis = player.first_person.view_basis() if player.first_person.active else dorm.camera.global_basis
	var right := basis.x
	var backward := basis.z
	right.y = 0
	backward.y = 0
	var x := direction.dot(right.normalized())
	var y := direction.dot(backward.normalized())
	Input.action_press("move_right" if x >= 0 else "move_left", absf(x))
	Input.action_press("move_down" if y >= 0 else "move_up", absf(y))

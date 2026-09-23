extends "res://tests/campus_test.gd"

func _run() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	var visual: Node3D = player.appearance
	var original := player.position
	drive(Vector3(0, 0, 1))
	await ticks(12)
	check(player.position.distance_to(original) > 0.1, "Player moves during gait")
	check(absf(visual.hips[0].rotation.x) > 0.01, "Walking moves feet")
	check(is_equal_approx(visual.hips[0].rotation.x, -visual.hips[1].rotation.x), "Legs alternate")
	check(visual.body.position.y > 0.0, "Walking adds body bounce")
	release_movement()
	await ticks(20)
	check(is_zero_approx(visual.gait_weight), "Idle settles to neutral")
	# A blocked player must not walk in place merely because input is held.
	player.position = Vector3(4.65, 0.05, 0)
	drive(Vector3.RIGHT)
	await ticks(35)
	check(visual.gait_weight < 0.05, "Wall blocking stops gait")
	release_movement()
	await capture("visual-dorm")
	state.enter_campus("dorm")
	await acquire_world()
	await sprint_checks()
	var schedule := root.get_node("NPCSchedule")
	schedule.set_process(false)
	schedule.reset()
	schedule.start()
	schedule.advance(3)
	await ticks(2)
	var actor: Node3D
	for child in dorm.get_children():
		if child.get("actor_id") == "alex":
			actor = child
	actor.set_process(false)
	actor._sync()
	for index in range(12):
		schedule.advance(1.0 / 60)
		actor._process(1.0 / 60)
	check(actor.appearance.gait_weight > 0, "NPC displacement animates gait")
	await capture("visual-campus")
	actor.appearance.set_seated(true)
	actor.appearance.animate_motion(0.1, 0.016)
	check(is_equal_approx(actor.appearance.hips[0].rotation.x, PI / 2), "Seated pose excludes walking")
	visual = actor.appearance
	var baseline := 0.0
	for rate in [30, 60, 120]:
		visual.apply_preset("indigo")
		for index in range(rate):
			visual.animate_motion(2.0 / rate, 1.0 / rate)
		if rate == 30:
			baseline = visual.hips[0].rotation.x
		check(absf(visual.hips[0].rotation.x - baseline) < 0.0001, "Distance-driven gait independent of frame rate: %d" % rate)
	print("VISUAL MOTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func sprint_checks() -> void:
	var visual: Node3D = player.appearance
	var bindings := InputMap.action_get_events("sprint")
	check(bindings.any(func(e): return e is InputEventKey) and bindings.any(func(e): return e is InputEventJoypadButton), "Sprint bound to keyboard and controller")
	player.position = Vector3(6, 0.05, 2)
	await ticks(3)
	drive(Vector3.LEFT)
	await ticks(30)
	var walk_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	check(visual.run_weight < 0.01, "Walking keeps the walk gait")
	Input.action_press("sprint")
	await ticks(45)
	var run_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	check(run_speed > walk_speed * 1.6, "Sprint is substantially faster (%.1f vs %.1f m/s)" % [run_speed, walk_speed])
	check(visual.run_weight > 0.9, "Sprint blends into the run gait")
	var strides := []
	var bends := []
	for index in range(40):
		await ticks(1)
		strides.append(absf(visual.hips[0].rotation.x))
		bends.append(-visual.knees[0].rotation.x)
	check(strides.max() > 0.75, "Run stride is longer than a walk stride")
	check(bends.max() > 1.0, "Recovering leg folds high behind while running")
	check(visual.spine.rotation.x < -0.15, "Torso leans forward into the sprint")
	Input.action_release("sprint")
	await ticks(45)
	check(visual.run_weight < 0.05 and Vector2(player.velocity.x, player.velocity.z).length() < walk_speed + 0.05, "Releasing sprint returns to walking")
	release_movement()
	await ticks(10)

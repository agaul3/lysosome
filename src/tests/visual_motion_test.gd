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

func tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await ticks(1)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await ticks(1)

func hold(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)

func speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()

## Minecraft-style sprint: double-tap a movement key and hold it.
func sprint_checks() -> void:
	var visual: Node3D = player.appearance
	var bindings := InputMap.action_get_events("sprint")
	check(bindings.any(func(e): return e is InputEventJoypadButton) and not bindings.any(func(e): return e is InputEventKey), "Keyboard sprint is double-tap; controller keeps L3")
	player.position = Vector3(6, 0.05, 2)
	await ticks(3)
	hold("move_left")
	await ticks(40)
	var walk_speed := speed()
	check(visual.run_weight < 0.01 and walk_speed > 2.5, "Holding a direction walks")
	release_movement()
	await ticks(10)
	# A slow second tap is not a double tap.
	await tap("move_left")
	await create_timer(0.45).timeout
	hold("move_left")
	await ticks(40)
	check(speed() < walk_speed + 0.05, "Two slow taps do not sprint")
	release_movement()
	await ticks(10)
	player.position = Vector3(6, 0.05, 2)
	await ticks(3)
	await tap("move_left")
	hold("move_left")
	await ticks(45)
	var run_speed := speed()
	check(run_speed > walk_speed * 1.6, "Double-tap and hold sprints (%.1f vs %.1f m/s)" % [run_speed, walk_speed])
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
	var facing_left: float = visual.rotation.y
	# Double-tapping the opposite key turns around and sprints the other way.
	release_movement()
	await ticks(2)
	await tap("move_right")
	hold("move_right")
	await ticks(60)
	check(speed() > walk_speed * 1.6 and player.velocity.dot(player.world_direction(Vector2(1, 0))) > 0.0, "Double-tapping the opposite key sprints back the other way")
	check(absf(wrapf(visual.rotation.y - facing_left, -PI, PI)) > 2.8, "Character turns around to face the new sprint direction")
	release_movement()
	await ticks(45)
	check(not player.sprint_latched and visual.run_weight < 0.05, "Letting go ends the sprint")
	hold("move_left")
	await ticks(45)
	check(speed() < walk_speed + 0.05, "Moving again without a double tap walks")
	release_movement()
	await ticks(10)

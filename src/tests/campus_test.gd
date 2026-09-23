extends "res://tests/dorm_test.gd"
## Full traversal uses real movement and interaction; no teleporting along the route.
const Config = preload("res://data/campus_config.gd")

func use_endpoint() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	var released := event.duplicate()
	released.pressed = false
	Input.parse_input_event(released)

func acquire_world() -> void:
	await scene_changed
	await ticks(3)
	dorm = current_scene
	player = dorm.player

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			await RenderingServer.frame_post_draw
			var path := argument.trim_prefix("--capture-dir=").path_join(label + ".png")
			check(root.get_texture().get_image().save_png(path) == OK, "Save graphical evidence: " + label)

func _run() -> void:
	state = root.get_node("AppState")
	change_scene_to_file("res://ui/start_screen.tscn")
	await scene_changed
	await ticks(2)
	current_scene.new_game_button.pressed.emit()
	current_scene.selection_panel.select_preset("indigo")
	current_scene.selection_panel.enter_button.pressed.emit()
	await acquire_world()
	await walk_to(Vector3(3.8, 0, 2.5))
	check(player.interaction.target == dorm.exit_door, "Dorm exit reachable")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.CAMPUS and dorm.name == "Campus", "Dorm-to-campus transition")
	check(player.position.distance_to(Config.SPAWNS.dorm) < 0.1, "Spawn at residence entrance")
	check(player.appearance.preset_id == "indigo", "Appearance preserved on campus")
	check(dorm.hud.location_title.contains("COMMONS"), "Campus location shown")
	check(dorm.sun.light_color.is_equal_approx(Config.MORNING.sun_color), "Configured morning lighting")
	check(dorm.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Campus orthographic camera")
	var original_basis: Basis = dorm.camera.global_basis
	var original_camera: Vector3 = dorm.camera.position
	await walk_to(Vector3(-3.5, 0, 5.5))
	check(player.interaction.target == dorm.noticeboard, "Directory reachable")
	await press_interact()
	check(dorm.hud.message.text.contains("Lecture Hall A"), "Directory provides directions")
	await capture("campus-directory")
	await walk_to(Vector3(-1, 0, 3))
	check(dorm.hud.prompt.text.is_empty(), "Directory prompt clears out of range")
	await walk_to(Vector3(3.5, 0, 1.3))
	check(player.interaction.target == dorm.student, "Static student interaction reachable")
	await press_interact()
	check(dorm.hud.message.text.contains("glass doors"), "Student gives directions")
	await walk_to(Vector3(8, 0, 1.3))
	await walk_to(Vector3(8, 0, -3.8))
	check(player.interaction.target == dorm.lecture_door, "Lecture building reached on foot")
	check(dorm.camera.position.distance_to(original_camera) > 4, "Camera follows traversal")
	check(dorm.camera.global_basis.is_equal_approx(original_basis), "Camera follow preserves orientation")
	check(absf(dorm.camera.tracked_point.x) <= 6.01 and absf(dorm.camera.tracked_point.z) <= 5.01, "Camera stays within bounds")
	await capture("learning-center")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.LECTURE_BUILDING, "Enter lecture building")
	check(player.appearance.preset_id == "indigo", "Appearance preserved in lobby")
	await walk_to(Vector3(0, 0, -2.2))
	check(player.interaction.target == dorm.hall_door, "Hall A reached inside lobby")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.LECTURE_HALL, "Hall A is accessible")
	check(dorm.hud.objective_text.contains("open seat"), "Hall A invites the player to sit")
	await capture("lecture-hall")
	await walk_to(Vector3(-6.9, 0, -6.2))
	use_endpoint()
	await acquire_world()
	await walk_to(Vector3(0, 0, 2.6))
	check(player.interaction.target == dorm.exit_door, "Lobby exit reachable")
	use_endpoint()
	await acquire_world()
	check(player.position.distance_to(Config.SPAWNS.lecture_building) < 0.1, "Campus return uses lecture entrance spawn")
	await walk_to(Vector3(8, 0, 2.5))
	await walk_to(Vector3(1, 0, 2.5))
	await walk_to(Vector3(-5.5, 0, 2.5))
	await walk_to(Vector3(-6.5, 0, 5))
	check(player.interaction.target == dorm.dorm_door, "Return route reaches residence")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.DORM and player.appearance.preset_id == "indigo", "Round trip preserves character")
	check(not dorm.hud.settings_open and player.movement_enabled, "Round trip has clean UI/input state")
	# Repeat transition requests should not duplicate worlds or alter spawn during a load.
	state.leave_dorm()
	state.enter_campus("lecture_building")
	await acquire_world()
	check(player.position.distance_to(Config.SPAWNS.dorm) < 0.1, "Repeated transition request cannot override pending spawn")
	check(dorm.find_children("Player", "CharacterBody3D", true, false).size() == 1, "Exactly one player after re-entry")
	await campus_collisions()
	await reset_position(Vector3(8, 0, 1))
	dorm.hud.set_settings_open(true)
	var start := player.position
	drive(Vector3.RIGHT)
	await ticks(10)
	release_movement()
	check(player.position.distance_to(start) < 0.02 and not paused, "Campus settings blocks movement without pausing")
	dorm.hud.set_settings_open(false)
	check(player.movement_enabled, "Campus settings restores movement")
	state.return_to_title()
	await scene_changed
	await ticks(2)
	check(current_scene.title_panel.visible, "Title available after campus")
	current_scene.new_game_button.pressed.emit()
	check(state.selected_character == Presets.DEFAULT_ID and state.campus_entry == "dorm", "New Game resets character and arrival state")
	print("CAMPUS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func campus_collisions() -> void:
	for probe in [
		[Vector3(0, 0, 10.5), Vector3.BACK],
		[Vector3(12.5, 0, 1), Vector3.RIGHT],
		[Vector3(-12.5, 0, -3), Vector3.LEFT],
		[Vector3(-3, 0, -10.5), Vector3.FORWARD],
	]:
		await reset_position(probe[0])
		drive(probe[1])
		await ticks(50)
		release_movement()
		check(absf(player.position.x) < 13.6 and absf(player.position.z) < 11.6, "Campus boundary blocks traversal")
	for probe in [
		[Vector3(8, 0, -4), Vector3.FORWARD, "LearningCenter", -5.76],
		[Vector3(-1.8, 0, -0.8), Vector3.FORWARD, "Planter", -1.36],
	]:
		await reset_position(probe[0])
		drive(probe[1])
		await ticks(50)
		release_movement()
		check(player.position.z > probe[3], "Solid obstacle blocks player: " + probe[2])

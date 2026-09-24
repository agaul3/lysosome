extends "res://tests/campus_test.gd"
## First-person view: toggling (Cmd+F / Ctrl+F, the controller's View button
## and Settings, kept in sync), the camera at the eyes with the player's head
## hidden, mouse and stick look, view-relative movement and sprint, the body
## facing the view, interaction preferring what you look at, the mouse released
## by the menu, and every location: dorm and lobby shown whole, the campus sky,
## and Hall A's seated first-person view, including switching mid-lecture.

func _run() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	await ticks(3)
	await check_toggle()
	await check_look_and_move()
	await check_menu_and_settings()
	await check_scenes()
	print("FIRST PERSON: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func key_f(command: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F
	event.command_or_control_autoremap = command
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	var release := event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await ticks(2)

func mouse(motion: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = motion
	event.screen_relative = motion
	Input.parse_input_event(event)
	await ticks(1)

func rig() -> Node3D:
	return player.first_person

func eye_height() -> float:
	return rig().camera.global_position.y - player.global_position.y

func check_toggle() -> void:
	check(not state.first_person and not rig().active and dorm.camera.current, "Third person is the default")
	await key_f(false)
	check(not state.first_person, "Plain F does not switch the view")
	await key_f(true)
	check(state.first_person and rig().active, "Cmd+F (Ctrl+F elsewhere) switches to first person")
	check(rig().camera.current and not dorm.camera.current, "The first-person camera takes over")
	check(dorm.hud.message.text == "First-person view", "A short notice confirms the view")
	check(rig().wants_capture(), "The mouse is captured for looking")
	var shadow_only := true
	for part in player.appearance.head_parts:
		shadow_only = shadow_only and part.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	check(not player.appearance.head_parts.is_empty() and shadow_only, "Your own head is hidden but still casts its shadow")
	var torso: MeshInstance3D = player.appearance.spine.get_node("Torso").get_child(0)
	check(torso.layers & rig().camera.cull_mask != 0, "Looking down shows your body")
	var no_xray := true
	for material in player.silhouette_materials:
		no_xray = no_xray and material.stencil_mode == BaseMaterial3D.STENCIL_MODE_DISABLED
	check(no_xray, "The see-through silhouette is off in first person")
	check(absf(eye_height() - 1.5) < 0.1, "Eyes at standing eye height (%.2f m)" % eye_height())
	await ticks(2)
	check(dorm.hud.crosshair.visible, "A small centre dot appears")
	var whole := true
	for mesh in dorm.cutaway:
		whole = whole and is_equal_approx(mesh.scale.y, 1.0)
	check(whole and dorm.get_node("Ceiling").visible and dorm.get_node("RoomLight").visible, "The dorm is shown whole: all four walls, ceiling and room light")
	await key_f(true)
	check(not state.first_person and dorm.camera.current and not rig().wants_capture(), "Cmd+F again returns to third person")
	var cut := true
	for mesh in dorm.cutaway:
		cut = cut and mesh.scale.y < 0.1
	check(cut and not dorm.get_node("Ceiling").visible, "The overhead cutaway returns")
	check(player.silhouette_materials[0].stencil_mode == BaseMaterial3D.STENCIL_MODE_XRAY, "The silhouette returns in third person")
	check(player.appearance.head_parts[0].cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "The head is drawn again in third person")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_BACK
	pad.pressed = true
	Input.parse_input_event(pad)
	await ticks(1)
	var pad_release := pad.duplicate()
	pad_release.pressed = false
	Input.parse_input_event(pad_release)
	await ticks(2)
	check(state.first_person, "The controller's View button switches views too")

func check_look_and_move() -> void:
	var fp := rig()
	fp.yaw = 0.0
	fp.pitch = 0.0
	await mouse(Vector2(100, 0))
	check(is_equal_approx(fp.yaw, -100 * fp.MOUSE_RADIANS), "Moving the mouse right turns the view right")
	await mouse(Vector2(0, -5000))
	check(is_equal_approx(fp.pitch, fp.PITCH_MAX), "Looking up is clamped")
	fp.pitch = 0.0
	state.look_sensitivity = 2.0
	var before: float = fp.yaw
	await mouse(Vector2(50, 0))
	check(is_equal_approx(before - fp.yaw, 100 * fp.MOUSE_RADIANS), "Look sensitivity scales the turn")
	state.look_sensitivity = 1.0
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = 1.0
	Input.parse_input_event(stick)
	before = fp.yaw
	await ticks(20)
	var centred := stick.duplicate()
	centred.axis_value = 0.0
	Input.parse_input_event(centred)
	await ticks(1)
	check(before - fp.yaw > 0.3, "The right stick looks around")
	# Face −X and walk: movement follows the view and the body faces it.
	fp.yaw = PI / 2
	fp.pitch = 0.0
	player.global_position = Vector3(0, 0.05, 1.5)
	await ticks(2)
	var start := player.global_position
	Input.action_press("move_up")
	await ticks(30)
	Input.action_release("move_up")
	var walked := player.global_position - start
	check(walked.x < -1.0 and absf(walked.z) < 0.1, "W walks where you look (%.2f, %.2f)" % [walked.x, walked.z])
	check(absf(wrapf(player.appearance.rotation.y - fp.yaw, -PI, PI)) < 0.01, "The body faces the view")
	await ticks(10)
	start = player.global_position
	Input.action_press("move_right")
	await ticks(30)
	Input.action_release("move_right")
	walked = player.global_position - start
	check(walked.z < -1.0 and absf(walked.x) < 0.1 and is_equal_approx(fp.yaw, PI / 2), "D strafes right without turning the view")
	await ticks(10)
	player.global_position = Vector3(3.0, 0.05, 1.5)
	fp.yaw = PI / 2
	await ticks(3)
	var tap := InputEventAction.new()
	tap.action = "move_up"
	tap.pressed = true
	Input.parse_input_event(tap)
	await ticks(1)
	var up := tap.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await ticks(1)
	Input.parse_input_event(tap)
	await ticks(40)
	var sprint := Vector2(player.velocity.x, player.velocity.z).length()
	Input.parse_input_event(up)
	release_movement()
	check(sprint > 5.0, "Double-tap W sprints in first person (%.1f m/s)" % sprint)
	await ticks(10)
	# Interaction prefers what you look at and ignores what is behind you.
	player.global_position = Vector3(3.1, 0.05, 2.5)
	fp.yaw = -PI / 2
	await ticks(4)
	check(player.interaction.target == dorm.exit_door, "Looking at the door targets it")
	fp.yaw = PI / 2
	await ticks(4)
	check(player.interaction.target != dorm.exit_door, "The door behind you is not targeted")

func check_menu_and_settings() -> void:
	var hud: CanvasLayer = dorm.hud
	hud.set_settings_open(true)
	await ticks(2)
	check(not rig().wants_capture() and not hud.crosshair.visible, "Opening the menu frees the mouse and hides the dot")
	var yaw: float = rig().yaw
	await mouse(Vector2(200, 0))
	check(is_equal_approx(rig().yaw, yaw), "The mouse does not turn the view while the menu is open")
	var toggle: CheckButton = hud.settings.first_person_toggle
	check(toggle.button_pressed, "The Settings switch reflects first person")
	toggle.button_pressed = false
	await ticks(2)
	check(not state.first_person and dorm.camera.current, "Turning the Settings switch off returns to third person")
	hud.set_settings_open(false)
	await ticks(1)
	await key_f(true)
	check(toggle.button_pressed and state.first_person, "Cmd+F keeps the Settings switch in sync")
	check(rig().wants_capture(), "Closing the menu captures the mouse again")
	hud.settings.sensitivity_slider.value = 150
	check(is_equal_approx(state.look_sensitivity, 1.5), "The sensitivity slider sets look speed")
	hud.settings.sensitivity_slider.value = 100

func check_scenes() -> void:
	# The preference carries into every location.
	state.enter_campus("dorm")
	await acquire_world()
	await ticks(3)
	check(rig().active and rig().camera.current, "First person carries onto the campus")
	check(dorm.campus_environment.background_mode == Environment.BG_SKY, "The campus shows a sky from eye level")
	check(absf(wrapf(rig().yaw + PI / 2, -PI, PI)) < 0.05, "Arriving from the residence, you face out across the quad")
	check(dorm.campus_environment.fog_enabled, "Distance haze hides the edge of the world")
	# World details seen at eye level.
	check(dorm.noticeboard.global_position.z < 3.0, "The campus directory faces the residence entrance and path")
	check(is_equal_approx(dorm.get_script().BENCHES[6][1], 0.0), "The bench beside it faces the same way")
	player.global_position = Vector3(-29.0, 0.05, -18.6)
	rig().yaw = 0.0
	await ticks(3)
	Input.action_press("move_up")
	await ticks(90)
	Input.action_release("move_up")
	await ticks(5)
	check(player.global_position.y > 0.55 and player.global_position.z < -22.0, "The Anatomy Hall's steps lead up to its doors (%.2f m up)" % player.global_position.y)
	await key_f(true)
	check(dorm.camera.current and dorm.campus_environment.background_mode == Environment.BG_COLOR and not dorm.campus_environment.fog_enabled, "Third person on campus restores the overhead camera and backdrop")
	await key_f(true)
	state.enter_lecture_building()
	await acquire_world()
	await ticks(3)
	var whole := true
	for mesh in dorm.cutaway:
		whole = whole and is_equal_approx(mesh.scale.y, 1.0)
	check(rig().active and whole and dorm.get_node("Ceiling").visible and dorm.get_node("ExitDaylight").visible, "The lobby is whole, with glazed doors out to the campus")
	check(dorm.flyer.title_label.text.contains("On-Chip Neural Induction") and dorm.flyer.photo.texture != null, "The lobby display shows the seminar flyer with the speaker's headshot")
	var clear_bay := true
	for node in dorm.get_children():
		if str(node.name).begins_with("Slat"):
			clear_bay = clear_bay and absf(node.position.z - dorm.DISPLAY_Z) > dorm.DISPLAY_SIZE.x / 2.0
	check(clear_bay, "No wall slats cross the display")
	check(dorm.has_node("LoungeBookshelf") and dorm.has_node("LoungeBookshelfEast"), "Two double-sided bookcases in the lobby")
	check(dorm.get_node("MonitorScreen").position.z < dorm.get_node("MonitorBack").position.z, "The reception screen faces the staff side of the desk")
	state.enter_lecture_hall()
	await acquire_world()
	await ticks(3)
	var hall := dorm
	check(rig().active and rig().camera.current, "First person in Hall A")
	var solid := true
	for mesh in hall.interior_meshes:
		solid = solid and mesh.visible and is_equal_approx((mesh.material_override as StandardMaterial3D).albedo_color.a, 1.0)
	check(solid, "Hall A's ceiling and near walls are solid")
	var standing := eye_height()
	player.seating.request(hall.get_node("Seat_R2_C4"))
	for index in range(1200):
		await ticks(1)
		if player.seating.state == player.seating.State.SEATED:
			break
	await ticks(90)
	check(player.seating.state == player.seating.State.SEATED, "Sits down in first person")
	check(rig().camera.current and not hall.lecture_camera.current, "Seated, the view stays first person")
	check(eye_height() < standing - 0.2, "Sitting lowers the eyes (%.2f → %.2f m)" % [standing, eye_height()])
	var to_screen: Vector3 = (hall.screen_focus() - rig().camera.global_position).normalized()
	check((-rig().camera.global_basis.z).dot(to_screen) > 0.97, "The view settles on the lecture screen")
	check(hall.lecture_view_ready(), "Class can begin from the first-person seat")
	rig().look(Vector2(-4.0, 0))
	check(absf(wrapf(rig().yaw - rig().body_yaw(), -PI, PI)) <= rig().SEATED_YAW_RANGE + 0.001, "Seated, you can look around within reach")
	if not hall.session.class_has_started():
		await press_action("confirm")
	for index in range(600):
		await ticks(1)
		if hall.session.state == hall.session.State.PRESENTING:
			break
	check(hall.session.state == hall.session.State.PRESENTING, "The lecture begins in first person")
	await key_f(true)
	await ticks(2)
	check(hall.lecture_camera.current and hall.lecture_camera.in_lecture_view(), "Switching to third person mid-lecture shows the lecture camera")
	await key_f(true)
	await ticks(2)
	check(rig().camera.current and not hall.lecture_camera.current and hall.session.state == hall.session.State.PRESENTING, "Switching back keeps the lecture going in first person")

func press_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await ticks(1)

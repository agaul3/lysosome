extends SceneTree
## Integration tests run the actual scenes, input map, physics, and scene transitions.
const Presets = preload("res://data/character_presets.gd")
var checks := 0
var failures := 0
var state: Node
var dorm: Node3D
var player: CharacterBody3D
var activations := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func ticks(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func release_movement() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func drive(direction: Vector3) -> void:
	release_movement()
	var right: Vector3 = dorm.camera.global_basis.x
	var backward: Vector3 = dorm.camera.global_basis.z
	right.y = 0
	backward.y = 0
	var x := direction.dot(right.normalized())
	var y := direction.dot(backward.normalized())
	Input.action_press("move_right" if x >= 0 else "move_left", absf(x))
	Input.action_press("move_down" if y >= 0 else "move_up", absf(y))

func walk_to(destination: Vector3) -> void:
	for index in range(240):
		var offset := destination - player.position
		offset.y = 0
		if offset.length() < 0.12:
			release_movement()
			await ticks(2)
			return
		drive(offset.normalized())
		await ticks(1)
	release_movement()
	check(false, "Walking route blocked at %s toward %s" % [player.position, destination])

func press_interact(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await ticks(1)
	if not echo:
		event.pressed = false
		Input.parse_input_event(event)

func acquire_dorm() -> void:
	await scene_changed
	await ticks(3)
	dorm = current_scene
	player = dorm.player

func _run() -> void:
	state = root.get_node("AppState")
	change_scene_to_file("res://ui/start_screen.tscn")
	await scene_changed
	await ticks(2)
	# Test every preset through selection UI and actual scene replacement.
	for preset in Presets.PRESETS:
		current_scene.new_game_button.pressed.emit()
		current_scene.selection_panel.select_preset(preset.id)
		check(state.selected_character == preset.id, "Preset selection: " + preset.id)
		check(not state.select_character("missing"), "Invalid preset rejected")
		check(state.selected_character == preset.id, "Invalid preset preserves selection")
		current_scene.selection_panel.enter_button.pressed.emit()
		await acquire_dorm()
		check(player.appearance.preset_id == preset.id, "Appearance reaches gameplay: " + preset.id)
		var torso: MeshInstance3D = player.appearance.get_node("Torso").get_child(0)
		check(torso.material_override.albedo_color.is_equal_approx(Color(preset.shirt)), "Preset material applied")
		state.return_to_title()
		await scene_changed
		await ticks(2)
	# Fresh end-to-end route; no teleporting along this acceptance path.
	current_scene.new_game_button.pressed.emit()
	current_scene.selection_panel.enter_button.pressed.emit()
	await acquire_dorm()
	check(dorm.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthographic 3D camera")
	check(dorm.hud.prompt.text.is_empty(), "No prompt outside interaction range")
	await walk_to(Vector3(2.3, 0, 0.5))
	await walk_to(Vector3(2.3, 0, -1.8))
	check(player.interaction.target == dorm.desk, "Desk selected in range")
	check(dorm.hud.prompt.text.contains("study desk"), "Desk prompt visible")
	dorm.desk.activated.connect(func() -> void: activations += 1)
	await press_interact()
	await press_interact(true)
	await ticks(15)
	check(activations == 1, "One press activates once; echo and holding do not repeat")
	check(dorm.hud.message.text.contains("pharmacodynamics"), "Desk response displayed")
	await walk_to(Vector3(2.3, 0, 0.8))
	check(dorm.hud.prompt.text.is_empty(), "Prompt disappears outside range")
	await walk_to(Vector3(-1.2, 0, 0.8))
	await walk_to(Vector3(-1.2, 0, -0.5))
	check(player.interaction.target == dorm.bed, "Second object selected")
	await press_interact()
	check(dorm.hud.message.text.contains("freshly made bed"), "Bed response displayed")
	await walk_to(Vector3(-1.2, 0, 1.5))
	await walk_to(Vector3(3.3, 0, 1.5))
	await walk_to(Vector3(3.8, 0, 2.5))
	check(player.interaction.target == dorm.exit_door, "Exit prompt reached by walking")
	# Do not await a physics tick in press_interact: scene_changed could fire during it.
	var exit_event := InputEventAction.new()
	exit_event.action = "interact"
	exit_event.pressed = true
	Input.parse_input_event(exit_event)
	await scene_changed
	await ticks(3)
	check(state.phase == state.Phase.EXIT, "Exit transitions to temporary destination")
	check(current_scene.name == "ExitDestination", "Temporary destination loaded")
	current_scene.return_button.pressed.emit()
	await acquire_dorm()
	check(player.position.distance_to(Vector3(0, 0, 1.5)) < 0.1, "Restart has clean spawn")
	check(player.movement_enabled and player.interaction.target == null, "Restart clears interaction/movement state")
	await movement_tests()
	await collision_tests()
	await interaction_tests()
	dorm.hud.set_settings_open(true)
	check(not paused and not player.movement_enabled, "Settings blocks player input without pausing simulation")
	dorm.hud.settings.volume_slider.value = 43
	check(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.43), "Dorm settings apply volume")
	dorm.hud.set_settings_open(false)
	check(player.movement_enabled, "Closing settings restores movement")
	state.return_to_title()
	await scene_changed
	await ticks(2)
	check(current_scene.title_panel.visible, "Return to title after gameplay")
	print("DORM: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func reset_position(position: Vector3) -> void:
	release_movement()
	player.position = position + Vector3(0, 0.02, 0)
	player.velocity = Vector3.ZERO
	await ticks(3)

func movement_tests() -> void:
	# Real physics integration at multiple tick rates for a half-second movement.
	var distances: Array[float] = []
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		await reset_position(Vector3(0, 0, 1))
		var start := player.position
		drive(Vector3.RIGHT)
		await ticks(rate / 2)
		release_movement()
		distances.append(Vector2(player.position.x - start.x, player.position.z - start.z).length())
		check(absf(distances[-1] - player.speed * 0.5) < 0.15, "Frame-independent movement at %s Hz: %s" % [rate, distances[-1]])
	Engine.physics_ticks_per_second = 60
	check(absf(distances.max() - distances.min()) < 0.15, "Consistent movement across physics rates")
	await reset_position(Vector3(0, 0, 1.2))
	Input.action_press("move_right")
	Input.action_press("move_down")
	await ticks(20)
	check(Vector2(player.velocity.x, player.velocity.z).length() <= player.speed + 0.001, "Diagonal speed normalized")
	release_movement()
	for key in [KEY_W, KEY_S, KEY_A, KEY_D]:
		await reset_position(Vector3(0, 0, 1.2))
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = true
		Input.parse_input_event(event)
		var start := player.position
		await ticks(10)
		check(player.position.distance_to(start) > 0.3, "Physical keyboard movement: %s" % key)
		event.pressed = false
		Input.parse_input_event(event)
	await reset_position(Vector3(0, 0, 1.2))
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 1.0
	Input.parse_input_event(stick)
	await ticks(10)
	check(Vector2(player.velocity.x, player.velocity.z).length() > 3, "Controller stick moves player")
	check(player.interaction.using_controller, "Controller prompt mode")
	stick.axis_value = 0
	Input.parse_input_event(stick)
	await ticks(3)
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "Stick neutral stops player")

func collision_tests() -> void:
	# Probe each major solid from four sides; CharacterBody must stop before its face.
	for name in ["Bed", "Desk", "Chair", "Bookshelf", "Storage"]:
		var body: StaticBody3D = dorm.get_node(name)
		var shape: BoxShape3D = body.get_child(1).shape
		for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			var extent := absf(direction.x) * shape.size.x / 2 + absf(direction.z) * shape.size.z / 2
			var start: Vector3 = body.position + direction * (extent + 0.65)
			start.y = 0
			# Rear probes against boundary-adjacent shelves cannot fit outside the room.
			if absf(start.x) > 4.65 or absf(start.z) > 4.15:
				continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = player.get_node("CollisionShape3D").shape
			query.transform = Transform3D(Basis.IDENTITY, start + Vector3(0, 0.87, 0))
			query.collision_mask = 1
			if not dorm.get_world_3d().direct_space_state.intersect_shape(query).is_empty():
				continue # Do not start probes embedded in adjacent furniture.
			await reset_position(start)
			drive(-direction)
			await ticks(35)
			release_movement()
			var separation := (player.position - body.position).dot(direction)
			check(separation >= extent + 0.24, "%s blocks %s approach (%s)" % [name, direction, separation])
	for probe in [[Vector3(0, 0, 3), Vector3.BACK], [Vector3(3.8, 0, 0), Vector3.RIGHT], [Vector3(-4.2, 0, 2.7), Vector3.LEFT], [Vector3(-1.5, 0, -3.5), Vector3.FORWARD]]:
		await reset_position(probe[0])
		drive(probe[1])
		await ticks(90)
		release_movement()
		check(absf(player.position.x) <= 4.65 and absf(player.position.z) <= 4.15, "Room boundary blocks movement: %s" % probe[1])

func interaction_tests() -> void:
	await reset_position(Vector3(0, 0, 1.5))
	var endpoint_script = load("res://world/interactable.gd")
	var near: Node3D = endpoint_script.new()
	near.position = Vector3(0.4, 1, 1.5)
	dorm.add_child(near)
	var far: Node3D = endpoint_script.new()
	far.position = Vector3(0.9, 1, 1.5)
	dorm.add_child(far)
	await ticks(3)
	check(player.interaction.target == near and near.marker.visible and not far.marker.visible, "Overlapping ranges show one nearest target")
	near.queue_free()
	far.queue_free()
	await ticks(3)
	check(player.interaction.target == null and dorm.hud.prompt.text.is_empty(), "Freed interaction target clears UI safely")
	var hidden: Node3D = endpoint_script.new()
	hidden.position = Vector3(0, 1, 2.4)
	dorm.add_child(hidden)
	var geometry = load("res://world/geometry.gd")
	var blocker: Node3D = geometry.box(dorm, "TestOccluder", Vector3(1, 2, 0.1), Vector3(0, 1, 2), Color.WHITE, true)
	await ticks(3)
	check(player.interaction.target == null, "Interaction cannot pass through a solid")
	hidden.queue_free()
	blocker.queue_free()
	await ticks(3)

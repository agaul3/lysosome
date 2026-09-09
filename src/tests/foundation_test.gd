extends SceneTree
## Execute with --headless --path . --script res://tests/foundation_test.gd
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "interact", "open_menu", "confirm", "cancel"]:
		_check(InputMap.has_action(action), "Input action: " + action)
		var keyboard := false
		var controller := false
		for event in InputMap.action_get_events(action):
			keyboard = keyboard or event is InputEventKey
			controller = controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
		_check(keyboard and controller, "Keyboard/controller bindings: " + action)
	for directory in ["autoload", "player", "npc", "world/dorm", "world/campus", "world/lecture_building", "world/lecture_hall", "education/questions", "education/lectures", "education/models", "ui", "audio", "assets", "data", "tests", "docs"]:
		_check(DirAccess.dir_exists_absolute("res://" + directory), "Directory: " + directory)
	for document in ["README.md", "PROJECT_SPEC.md", "docs/architecture/ARCHITECTURE.md", "docs/development/CHANGELOG.md", "docs/development/KNOWN_ISSUES.md", "docs/development/MEDICAL_CONTENT_REVIEW.md"]:
		_check(FileAccess.file_exists("res://" + document), "Document: " + document)
	_check(FileAccess.get_file_as_bytes("res://PROJECT_SPEC.md") == FileAccess.get_file_as_bytes("res://docs/design/medical_school_rpg_spec.md"), "Product requirements preserved byte-for-byte")
	var state := root.get_node("AppState")
	var screen = load("res://ui/start_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.title_panel.visible, "Title visible at startup")
	_check(screen.new_game_button.has_focus(), "Initial keyboard/controller focus")
	_check(screen.continue_button.disabled, "Continue unavailable without save support")
	screen.new_game_button.pressed.emit()
	_check(state.phase == state.Phase.CHARACTER_SELECT and screen.selection_panel.visible, "New Game enters character selection")
	_check(screen.selection_panel.preset_buttons[0].has_focus(), "Selection focuses first preset")
	screen.return_button.pressed.emit()
	_check(screen.title_panel.visible, "Back returns to title")
	screen.settings_button.pressed.emit()
	_check(screen.settings_panel.visible and not screen.title_panel.visible, "Settings opens")
	var original_volume := AudioServer.get_bus_volume_linear(0)
	screen.settings_panel.volume_slider.value = 37
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.37), "Volume updates audio bus")
	screen.settings_panel.volume_slider.value = 0
	_check(is_zero_approx(AudioServer.get_bus_volume_linear(0)), "Volume zero mutes")
	AudioServer.set_bus_volume_linear(0, original_volume)
	_check(not paused, "Settings does not pause tree")
	var cancel_event := InputEventAction.new()
	cancel_event.action = "cancel"
	cancel_event.pressed = true
	Input.parse_input_event(cancel_event)
	await process_frame
	_check(screen.title_panel.visible and screen.settings_button.has_focus(), "Cancel closes settings and restores focus")
	screen.settings_button.pressed.emit()
	screen.settings_panel.back_button.pressed.emit()
	_check(screen.title_panel.visible, "Settings Back works")
	# Use real controller and physical keyboard events through the viewport.
	screen.new_game_button.grab_focus()
	var controller_confirm := InputEventJoypadButton.new()
	controller_confirm.button_index = JOY_BUTTON_A
	controller_confirm.pressed = true
	Input.parse_input_event(controller_confirm)
	await process_frame
	_check(screen.selection_panel.visible, "Controller A starts New Game")
	controller_confirm.pressed = false
	Input.parse_input_event(controller_confirm)
	var keyboard_cancel := InputEventKey.new()
	keyboard_cancel.physical_keycode = KEY_ESCAPE
	keyboard_cancel.pressed = true
	Input.parse_input_event(keyboard_cancel)
	await process_frame
	_check(screen.title_panel.visible, "Escape returns to title")
	keyboard_cancel.pressed = false
	Input.parse_input_event(keyboard_cancel)
	for iteration in range(10):
		screen.new_game_button.pressed.emit()
		screen.return_button.pressed.emit()
	_check(screen.title_panel.visible and not paused, "Repeated flow remains valid")
	print("FOUNDATION: %d checks, %d failures" % [checks, failures])
	if failures > 0:
		quit(1)
	else:
		print("Testing actual Quit button; process must exit successfully.")
		screen.quit_button.pressed.emit()

extends VBoxContainer
## Settings, shared by the title screen and the player menu: audio, display,
## a controls reference and (in game) save / return to title.
signal closed
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const KeyPrompt = preload("res://ui/key_prompt.gd")
## In the player menu the page header replaces the title and Back button.
var in_menu := false
var volume_slider: HSlider
var volume_value: Label
var fullscreen_toggle: CheckButton
var first_person_toggle: CheckButton
var sensitivity_slider: HSlider
var sensitivity_value: Label
var back_button: Button
var save_button: Button
var title_button: Button
var status: Label

func _init(menu_mode := false) -> void:
	in_menu = menu_mode

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	if not in_menu:
		add_child(UI.label("Settings", UI.SIZE_HEADING, UI.TEXT, 600))
		add_child(UI.label("Changes apply immediately.", UI.SIZE_LABEL, UI.TEXT_MUTED, 400))
	# Audio.
	var audio := _section("Audio", "play")
	var volume_row := HBoxContainer.new()
	var volume_label := UI.label("Master volume", UI.SIZE_BODY, UI.TEXT, 500)
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(volume_label)
	volume_value = UI.label("", UI.SIZE_BODY, UI.TEXT_MUTED, 500)
	volume_row.add_child(volume_value)
	audio.add_child(volume_row)
	volume_slider = HSlider.new()
	volume_slider.name = "MasterVolume"
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = AudioServer.get_bus_volume_linear(0) * 100.0
	volume_slider.custom_minimum_size.y = 24
	volume_slider.value_changed.connect(_set_volume)
	audio.add_child(volume_slider)
	_show_volume()
	# Display.
	var display := _section("Display", "overview")
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	display.add_child(fullscreen_toggle)
	# Camera: third person by default; first person here or with Cmd+F (Ctrl+F).
	first_person_toggle = CheckButton.new()
	first_person_toggle.name = "FirstPersonView"
	first_person_toggle.text = "First-person view"
	first_person_toggle.button_pressed = AppState.first_person
	first_person_toggle.toggled.connect(AppState.set_first_person)
	display.add_child(first_person_toggle)
	AppState.view_changed.connect(first_person_toggle.set_pressed_no_signal)
	var sensitivity_row := HBoxContainer.new()
	var sensitivity_label := UI.label("Look sensitivity (first person)", UI.SIZE_BODY, UI.TEXT, 500)
	sensitivity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_row.add_child(sensitivity_label)
	sensitivity_value = UI.label("", UI.SIZE_BODY, UI.TEXT_MUTED, 500)
	sensitivity_row.add_child(sensitivity_value)
	display.add_child(sensitivity_row)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.name = "LookSensitivity"
	sensitivity_slider.min_value = 25.0
	sensitivity_slider.max_value = 250.0
	sensitivity_slider.step = 5.0
	sensitivity_slider.value = AppState.look_sensitivity * 100.0
	sensitivity_slider.custom_minimum_size.y = 24
	sensitivity_slider.value_changed.connect(_set_sensitivity)
	display.add_child(sensitivity_slider)
	_show_sensitivity()
	# Controls reference.
	var controls := _section("Controls", "settings")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	var view_key := "⌘F" if OS.get_name() == "macOS" else "Ctrl+F"
	for entry in [["Move", "WASD", "Left stick"], ["Sprint", "×2", "Double-tap and hold, or L3"], ["Interact", "E", "X"], ["Menu", "Tab", "Start"], ["Confirm", "Enter", "A"], ["Back", "Esc", "B"], ["Camera view", view_key, "View button"], ["Look (first person)", "Mouse", "Right stick"]]:
		grid.add_child(UI.label(entry[0], UI.SIZE_BODY, UI.TEXT, 500))
		var key := KeyPrompt.new()
		key.key = entry[1]
		grid.add_child(key)
		grid.add_child(UI.label(entry[2], UI.SIZE_LABEL, UI.TEXT_FAINT, 400))
	controls.add_child(grid)
	if in_menu:
		var game := _section("Game", "save")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		save_button = Button.new()
		save_button.text = "Save now"
		save_button.pressed.connect(func() -> void:
			Sfx.play("ui_confirm")
			status.text = "Saved at %s." % GameClock.display_time() if SaveGame.save() else SaveGame.last_error)
		row.add_child(save_button)
		title_button = Button.new()
		title_button.text = "Save and return to title"
		title_button.pressed.connect(func() -> void:
			SaveGame.save()
			AppState.return_to_title())
		row.add_child(title_button)
		game.add_child(row)
		status = UI.label("Progress also autosaves when you arrive somewhere new.", UI.SIZE_LABEL, UI.TEXT_MUTED, 400)
		game.add_child(status)
	else:
		back_button = Button.new()
		back_button.text = "Back"
		back_button.custom_minimum_size.y = 44
		back_button.pressed.connect(func() -> void: closed.emit())
		add_child(back_button)
	if in_menu:
		# Menu pages share the back action through the menu itself.
		back_button = Button.new()
		back_button.visible = false
		add_child(back_button)

func _section(title: String, icon: String) -> VBoxContainer:
	var card := UI.card(Vector4(16, 12, 16, 14))
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	heading.add_child(Icon.new(icon, 14, UI.ACCENT))
	heading.add_child(UI.label(title, UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	column.add_child(heading)
	return column

func _set_volume(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value / 100.0)
	_show_volume()

func _show_volume() -> void:
	volume_value.text = "%d%%" % int(round(volume_slider.value))

func _set_sensitivity(value: float) -> void:
	AppState.look_sensitivity = value / 100.0
	_show_sensitivity()

func _show_sensitivity() -> void:
	sensitivity_value.text = "%d%%" % int(round(sensitivity_slider.value))

func _set_fullscreen(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

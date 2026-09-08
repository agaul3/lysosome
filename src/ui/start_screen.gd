extends Control
## Title shell only. The New Game destination is an explicit milestone boundary.
const SettingsPanel = preload("res://ui/settings_panel.gd")
var title_panel: VBoxContainer
var foundation_panel: VBoxContainer
var settings_panel: VBoxContainer
var new_game_button: Button
var continue_button: Button
var settings_button: Button
var quit_button: Button
var return_button: Button

func _ready() -> void:
	_build_ui()
	AppState.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(AppState.phase)

func _build_ui() -> void:
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 20
	theme = theme_resource
	var background := ColorRect.new()
	background.color = Color("101f2c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 48)
	add_child(margin)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 56)
	margin.add_child(layout)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 24)
	layout.add_child(identity)
	_add_label(identity, "MEDICAL SCHOOL RPG", 18, Color("74d7c0"))
	_add_label(identity, "Your education.
Your next chapter.", 44)
	_add_label(identity, "Real medical learning.
Visible RPG progression.", 23, Color("b7cbd7"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	identity.add_child(spacer)
	_add_label(identity, "VERTICAL SLICE v0.1  /  FOUNDATION", 15, Color("74d7c0"))
	_add_label(identity, "Milestone 1 • Local desktop prototype
Keyboard, mouse & controller", 16, Color("b7cbd7"))
	var panel_center := CenterContainer.new()
	panel_center.custom_minimum_size.x = 370
	layout.add_child(panel_center)
	title_panel = _make_panel(panel_center)
	_add_label(title_panel, "Welcome", 32)
	new_game_button = _add_button(title_panel, "New Game", AppState.start_new_game)
	continue_button = _add_button(title_panel, "Continue — unavailable", func() -> void: pass)
	continue_button.disabled = true
	continue_button.tooltip_text = "Save/load will be added in a later milestone."
	settings_button = _add_button(title_panel, "Settings", _open_settings)
	quit_button = _add_button(title_panel, "Quit", _quit)
	_add_label(title_panel, "No save data in this foundation build.", 16, Color("b7cbd7"))
	foundation_panel = _make_panel(panel_center)
	_add_label(foundation_panel, "Foundation ready", 30)
	_add_label(foundation_panel, "New Game flow is connected.

Character selection and the dorm
arrive in Milestone 2.", 20)
	return_button = _add_button(foundation_panel, "Back to title", AppState.return_to_title)
	settings_panel = SettingsPanel.new()
	settings_panel.custom_minimum_size.x = 370
	panel_center.add_child(settings_panel)
	settings_panel.closed.connect(_close_settings)

func _make_panel(parent: Node) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 370
	panel.add_theme_constant_override("separation", 16)
	parent.add_child(panel)
	return panel

func _add_label(parent: Node, text: String, font_size: int, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _add_button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _on_phase_changed(phase: AppState.Phase) -> void:
	settings_panel.hide()
	title_panel.visible = phase == AppState.Phase.TITLE
	foundation_panel.visible = phase == AppState.Phase.FOUNDATION
	if title_panel.visible:
		new_game_button.grab_focus()
	else:
		return_button.grab_focus()

func _open_settings() -> void:
	title_panel.hide()
	settings_panel.show()
	settings_panel.volume_slider.grab_focus()

func _close_settings() -> void:
	settings_panel.hide()
	title_panel.show()
	settings_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if settings_panel.visible:
			_close_settings()
		elif foundation_panel.visible:
			AppState.return_to_title()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and not event.is_echo():
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and not focused.disabled:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()

func _quit() -> void:
	get_tree().quit()

extends CanvasLayer
## Context prompts and a small settings overlay; no progression HUD or future menu pages.
const SettingsPanel = preload("res://ui/settings_panel.gd")
var player: CharacterBody3D
var prompt: Label
var message: Label
var message_timer: Timer
var settings: VBoxContainer
var settings_backdrop: PanelContainer
var settings_open := false
var current_target: Node3D

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var heading := Label.new()
	heading.text = "CEDAR RESIDENCE  /  YOUR DORM"
	heading.position = Vector2(30, 22)
	heading.add_theme_font_size_override("font_size", 20)
	root.add_child(heading)
	var help := Label.new()
	help.text = "WASD / Left stick — Move    E / X — Interact    Tab / Start — Settings"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(30, -38)
	help.add_theme_font_size_override("font_size", 16)
	root.add_child(help)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	stack.position = Vector2(-350, -150)
	stack.size = Vector2(700, 100)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stack)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 23)
	prompt.add_theme_color_override("font_color", Color("a3ffe1"))
	stack.add_child(prompt)
	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 19)
	stack.add_child(message)
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 6.0
	message_timer.timeout.connect(func() -> void: message.text = "")
	add_child(message_timer)
	settings_backdrop = PanelContainer.new()
	settings_backdrop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_backdrop.position = Vector2(-215, -210)
	settings_backdrop.size = Vector2(430, 420)
	root.add_child(settings_backdrop)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	settings_backdrop.add_child(margin)
	settings = SettingsPanel.new()
	margin.add_child(settings)
	settings.closed.connect(func() -> void: set_settings_open(false))
	var title_button := Button.new()
	title_button.text = "Return to title"
	title_button.pressed.connect(AppState.return_to_title)
	settings.add_child(title_button)
	settings_backdrop.hide()

func bind_player(value: CharacterBody3D) -> void:
	player = value
	player.interaction.target_changed.connect(_show_target)
	player.interaction.device_changed.connect(func(_controller: bool) -> void: _show_target(current_target if is_instance_valid(current_target) else null))
	player.interaction.interacted.connect(_show_response)

func _show_target(target: Node3D) -> void:
	current_target = target
	prompt.text = ""
	if is_instance_valid(target) and not settings_open:
		var key: String = "X / West" if player.interaction.using_controller else "E"
		prompt.text = "%s — %s" % [key, target.display_name]

func _show_response(target: Node3D) -> void:
	message.text = target.response
	if not message.text.is_empty():
		message_timer.start()

func set_settings_open(value: bool) -> void:
	settings_open = value
	settings_backdrop.visible = value
	player.movement_enabled = not value
	player.interaction.enabled = not value
	_show_target(current_target if is_instance_valid(current_target) else null)
	if value:
		settings.volume_slider.grab_focus()
	else:
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_menu") or event.is_action_pressed("cancel"):
		if not event.is_echo():
			set_settings_open(not settings_open)
		get_viewport().set_input_as_handled()

extends CanvasLayer
## Context prompts and a small settings overlay; no progression HUD or future menu pages.
@export var location_title := "CEDAR RESIDENCE  /  YOUR DORM"
@export var objective_text := ""
const SettingsPanel = preload("res://ui/settings_panel.gd")
var player: CharacterBody3D
var prompt: Label
var message: Label
var message_timer: Timer
var settings: VBoxContainer
var settings_backdrop: PanelContainer
var settings_open := false
var current_target: Node3D
var context_backdrop: ColorRect
var context_stack: VBoxContainer
var clock_label: Label
var key_prompts: Array[Control] = []
var menu_tabs: TabContainer
var schedule_panel: VBoxContainer
var calendar_panel: VBoxContainer

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme := Theme.new()
	theme.default_font = preload("res://assets/outfit_medium.tres")
	theme.default_font_size = 18
	root.theme = theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var heading_backdrop := Panel.new()
	heading_backdrop.add_theme_stylebox_override("panel", _panel_style())
	heading_backdrop.position = Vector2(16, 12)
	heading_backdrop.size = Vector2(740, 74 if not objective_text.is_empty() else 46)
	heading_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heading_backdrop)
	var clock_backdrop := Panel.new()
	clock_backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_backdrop.position = Vector2(-316, 12)
	clock_backdrop.size = Vector2(300, 78)
	clock_backdrop.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(clock_backdrop)
	clock_label = Label.new()
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_label.position = Vector2(-300, 20)
	clock_label.custom_minimum_size = Vector2(278, 64)
	clock_label.add_theme_color_override("font_outline_color", Color("172d36"))
	clock_label.add_theme_constant_override("outline_size", 0)
	clock_label.add_theme_font_size_override("font_size", 20)
	root.add_child(clock_label)
	GameClock.minute_changed.connect(_refresh_clock)
	AcademicSession.attendance_recorded.connect(_arrival_feedback)
	_refresh_clock()
	var heading := Label.new()
	heading.text = location_title
	heading.position = Vector2(30, 22)
	heading.add_theme_font_size_override("font_size", 20)
	root.add_child(heading)
	if not objective_text.is_empty():
		var objective := Label.new()
		objective.text = objective_text
		objective.position = Vector2(30, 50)
		objective.add_theme_font_size_override("font_size", 17)
		root.add_child(objective)
	var help := PanelContainer.new()
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(16, -65)
	help.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(help)
	var help_row := HBoxContainer.new()
	help_row.add_theme_constant_override("separation", 12)
	help.add_child(help_row)
	for pair in [["WASD", "Move"], ["E", "Interact"], ["Tab", "Menu"]]:
		var icon := preload("res://ui/key_prompt.gd").new()
		icon.key = pair[0]
		help_row.add_child(icon)
		key_prompts.append(icon)
		var action := Label.new()
		action.text = pair[1]
		help_row.add_child(action)
	context_backdrop = ColorRect.new()
	context_backdrop.color = Color(0.035, 0.075, 0.10, 0.9)
	context_backdrop.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	context_backdrop.position = Vector2(-365, -205)
	context_backdrop.size = Vector2(730, 120)
	context_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	context_backdrop.hide()
	root.add_child(context_backdrop)
	var stack := VBoxContainer.new()
	context_stack = stack
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	stack.position = Vector2(-350, -195)
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
	message_timer.timeout.connect(_clear_message)
	add_child(message_timer)
	settings_backdrop = PanelContainer.new()
	settings_backdrop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_backdrop.position = Vector2(-285, -240)
	settings_backdrop.size = Vector2(570, 480)
	root.add_child(settings_backdrop)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	settings_backdrop.add_child(margin)
	menu_tabs = TabContainer.new()
	margin.add_child(menu_tabs)
	schedule_panel = preload("res://ui/schedule_panel.gd").new()
	schedule_panel.name = "Today"
	menu_tabs.add_child(schedule_panel)
	schedule_panel.closed.connect(func() -> void: set_settings_open(false))
	calendar_panel = preload("res://ui/schedule_panel.gd").new()
	calendar_panel.calendar = true
	calendar_panel.name = "Calendar"
	menu_tabs.add_child(calendar_panel)
	calendar_panel.closed.connect(func() -> void: set_settings_open(false))
	settings = SettingsPanel.new()
	settings.name = "Settings"
	menu_tabs.add_child(settings)
	settings.closed.connect(func() -> void: set_settings_open(false))
	var title_button := Button.new()
	title_button.text = "Return to title"
	title_button.pressed.connect(AppState.return_to_title)
	settings.add_child(title_button)
	settings_backdrop.hide()

func bind_player(value: CharacterBody3D) -> void:
	player = value
	player.interaction.target_changed.connect(_show_target)
	player.interaction.device_changed.connect(_device_changed)
	player.interaction.interacted.connect(_show_response)

func _show_target(target: Node3D) -> void:
	current_target = target
	prompt.text = ""
	if is_instance_valid(target) and not settings_open:
		var key: String = "X / West" if player.interaction.using_controller else "E"
		prompt.text = "%s — %s" % [key, target.display_name]
	_refresh_context()

func _show_response(target: Node3D) -> void:
	message.text = target.response
	if not message.text.is_empty():
		message_timer.start()
	_refresh_context()

func _clear_message() -> void:
	message.text = ""
	_refresh_context()

func _refresh_context() -> void:
	var expanded := not message.text.is_empty()
	context_backdrop.position.y = -205 if expanded else -143
	context_backdrop.size.y = 120 if expanded else 54
	context_stack.position.y = -195 if expanded else -136
	message.visible = expanded
	context_backdrop.visible = not settings_open and (not prompt.text.is_empty() or not message.text.is_empty())

func set_settings_open(value: bool) -> void:
	settings_open = value
	settings_backdrop.visible = value
	player.movement_enabled = not value
	player.interaction.enabled = not value
	_show_target(current_target if is_instance_valid(current_target) else null)
	if value:
		menu_tabs.current_tab = 0
		schedule_panel.refresh()
		schedule_panel.back_button.grab_focus()
	else:
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_menu") or event.is_action_pressed("cancel"):
		if not event.is_echo():
			set_settings_open(not settings_open)
		get_viewport().set_input_as_handled()

func _refresh_clock() -> void:
	clock_label.text = GameClock.display_time() + "\n" + GameClock.display_date()
	clock_label.text = clock_label.text.replace("\n", "
")

func _arrival_feedback(record: Dictionary) -> void:
	var arrival := Time.get_datetime_dict_from_unix_time(int(record.arrival_time))
	var time := "%02d:%02d:%02d" % [arrival.hour, arrival.minute, arrival.second]
	message.text = "Late arrival at %s — −%d XP. Penalty recorded once." % [time, absi(record.xp_delta)] if record.late else "Arrived on time for Pharmacodynamics."
	message_timer.start(10.0)
	schedule_panel.refresh()
	calendar_panel.refresh()
	_refresh_context()

func _device_changed(controller: bool) -> void:
	var keys := ["LS", "X", "Start"] if controller else ["WASD", "E", "Tab"]
	for index in range(key_prompts.size()):
		key_prompts[index].key = keys[index]
	_show_target(current_target if is_instance_valid(current_target) else null)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142e39")
	style.border_color = Color("3d6770")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 16
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

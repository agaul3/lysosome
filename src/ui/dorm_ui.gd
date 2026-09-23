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
var message_card: PanelContainer
var prompt_row: HBoxContainer
var context_key: Control
var context_stack: VBoxContainer
var clock_label: Label
var key_prompts: Array[Control] = []
var menu_tabs: TabContainer
var schedule_panel: VBoxContainer
var calendar_panel: VBoxContainer
var objective_label: Label
var progression: VBoxContainer
var help_row: HBoxContainer
## Set while another overlay (the lecture) owns the bottom of the screen.
var suppress_context := false:
	set(value):
		suppress_context = value
		if is_instance_valid(prompt_row):
			_refresh_context()

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme := Theme.new()
	theme.default_font = preload("res://assets/outfit_medium.tres")
	theme.default_font_size = 15
	root.theme = theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Compact translucent corner cards; everything else floats directly over the world.
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 12
	top_bar.offset_right = -12
	top_bar.offset_top = 10
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bar)
	var heading_card := _card(top_bar)
	heading_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var heading_stack := VBoxContainer.new()
	heading_stack.add_theme_constant_override("separation", 0)
	heading_card.add_child(heading_stack)
	var heading := _hud_label(location_title, 14, 0)
	heading_stack.add_child(heading)
	if not objective_text.is_empty():
		objective_label = _hud_label(objective_text, 12, 0)
		objective_label.add_theme_color_override("font_color", Color("b9d3cf"))
		heading_stack.add_child(objective_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(spacer)
	progression = preload("res://ui/progression_hud.gd").new()
	top_bar.add_child(progression)
	var clock_gap := Control.new()
	clock_gap.custom_minimum_size.x = 8
	clock_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(clock_gap)
	var clock_card := _card(top_bar)
	clock_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	clock_label = _hud_label("", 14, 0)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_card.add_child(clock_label)
	GameClock.minute_changed.connect(_refresh_clock)
	AcademicSession.attendance_recorded.connect(_arrival_feedback)
	_refresh_clock()
	help_row = HBoxContainer.new()
	help_row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help_row.offset_left = 14
	help_row.offset_bottom = -10
	help_row.add_theme_constant_override("separation", 6)
	help_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(help_row)
	for pair in [["WASD", "Move"], ["E", "Interact"], ["Tab", "Menu"], ["×2", "Sprint"]]:
		var icon := preload("res://ui/key_prompt.gd").new()
		icon.key = pair[0]
		help_row.add_child(icon)
		key_prompts.append(icon)
		var action := _hud_label(pair[1], 13)
		action.custom_minimum_size.x = 0
		help_row.add_child(action)
		var gap := Control.new()
		gap.custom_minimum_size.x = 8
		help_row.add_child(gap)
	var stack := VBoxContainer.new()
	context_stack = stack
	stack.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	stack.grow_horizontal = Control.GROW_DIRECTION_BOTH
	stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	stack.offset_left = -240
	stack.offset_right = 240
	stack.offset_bottom = -54
	stack.alignment = BoxContainer.ALIGNMENT_END
	stack.add_theme_constant_override("separation", 6)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stack)
	message_card = _card(stack)
	message_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	message = _hud_label("", 14, 0)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 440
	message_card.add_child(message)
	prompt_row = HBoxContainer.new()
	prompt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_row.add_theme_constant_override("separation", 8)
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(prompt_row)
	context_key = preload("res://ui/key_prompt.gd").new()
	prompt_row.add_child(context_key)
	prompt = _hud_label("", 16)
	prompt.add_theme_color_override("font_color", Color("c9fff0"))
	prompt_row.add_child(prompt)
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 6.0
	message_timer.timeout.connect(_clear_message)
	add_child(message_timer)
	settings_backdrop = PanelContainer.new()
	settings_backdrop.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_backdrop.position = Vector2(-250, -215)
	settings_backdrop.size = Vector2(500, 430)
	root.add_child(settings_backdrop)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
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
	_refresh_context()

func bind_player(value: CharacterBody3D) -> void:
	player = value
	player.interaction.target_changed.connect(_show_target)
	player.interaction.device_changed.connect(_device_changed)
	player.interaction.interacted.connect(_show_response)
	player.seating.notice.connect(show_message)

func _show_target(target: Node3D) -> void:
	current_target = target
	prompt.text = ""
	if is_instance_valid(target) and not settings_open:
		context_key.key = "X" if player.interaction.using_controller else "E"
		prompt.text = target.display_name
	_refresh_context()

func _show_response(target: Node3D) -> void:
	message.text = target.response
	if not message.text.is_empty():
		message_timer.start()
	_refresh_context()

func set_objective(text: String) -> void:
	objective_text = text
	if is_instance_valid(objective_label):
		objective_label.text = text

## The controls hint is hidden while seated in a lecture.
func set_help_visible(value: bool) -> void:
	help_row.visible = value

func show_message(text: String, seconds := 4.0) -> void:
	message.text = text
	message_timer.start(seconds)
	_refresh_context()

func _clear_message() -> void:
	message.text = ""
	_refresh_context()

func _refresh_context() -> void:
	message_card.visible = not settings_open and not suppress_context and not message.text.is_empty()
	prompt_row.visible = not settings_open and not suppress_context and not prompt.text.is_empty()

func set_settings_open(value: bool) -> void:
	settings_open = value
	settings_backdrop.visible = value
	player.movement_enabled = not value
	player.interaction.enabled = not value and not player.seating.stand_locked and not (player.seating.busy() and player.seating.state != player.seating.State.SEATED)
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
	var keys := ["LS", "X", "Start", "L3"] if controller else ["WASD", "E", "Tab", "×2"]
	for index in range(key_prompts.size()):
		key_prompts[index].key = keys[index]
	_show_target(current_target if is_instance_valid(current_target) else null)

func _card(parent: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.15, 0.19, 0.72)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 5
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	return card

func _hud_label(text: String, font_size: int, outline: int = 5) -> Label:
	# Unboxed labels rely on a dark outline for contrast against bright scenery.
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f1f6f2"))
	label.add_theme_color_override("font_outline_color", Color("10252d"))
	label.add_theme_constant_override("outline_size", outline)
	return label

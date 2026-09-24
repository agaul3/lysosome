extends CanvasLayer
## Exploration HUD shared by every world scene. Deliberately restrained:
## - top left: where you are and what to do next,
## - top right: level/XP and the date and time,
## - bottom: a contextual interaction prompt, short messages and a controls hint,
## plus the player menu (Tab), which leaves the world running.
@export var location_title := ""
@export var objective_text := ""
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const KeyPrompt = preload("res://ui/key_prompt.gd")
const Objectives = preload("res://data/objectives.gd")
const PlayerMenu = preload("res://ui/menu/player_menu.gd")
const SettingsPanel = preload("res://ui/settings_panel.gd")
var player: CharacterBody3D
var root: Control
var prompt: Label
var message: Label
var message_timer: Timer
var settings: VBoxContainer
var settings_open := false
var current_target: Node3D
var message_card: PanelContainer
var prompt_row: HBoxContainer
var context_key: Control
var context_stack: VBoxContainer
## Date line of the clock card (the time is on its own line below).
var clock_label: Label
var time_label: Label
var key_prompts: Array[Control] = []
var menu: Control
var menu_tabs: TabContainer
var schedule_panel: Control
var calendar_panel: Control
var knowledge_panel: Control
var location_label: Label
var objective_label: Label
var progression: VBoxContainer
var help_row: HBoxContainer
## Small centre dot in the first-person view.
var crosshair: Control
## False once a scene sets its own objective (e.g. during the lecture).
var auto_objective := true
## Set while another overlay (the lecture) owns the bottom of the screen.
var suppress_context := false:
	set(value):
		suppress_context = value
		if is_instance_valid(prompt_row):
			_refresh_context()

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	if location_title.is_empty():
		location_title = Objectives.location(AppState.location_key())
	if objective_text.is_empty():
		objective_text = Objectives.current(AppState.location_key())
	else:
		auto_objective = false
	_build_top_bar()
	_build_bottom()
	_build_menu()
	_build_crosshair()
	GameClock.minute_changed.connect(_refresh_clock)
	AcademicSession.attendance_recorded.connect(_arrival_feedback)
	AppState.view_changed.connect(_on_view_changed)
	_refresh_clock()
	_refresh_context()

## The view toggle's keys: Cmd+F on macOS, Ctrl+F elsewhere.
static func view_key() -> String:
	return "⌘F" if OS.get_name() == "macOS" else "Ctrl+F"

func _build_crosshair() -> void:
	crosshair = Control.new()
	crosshair.name = "Crosshair"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.custom_minimum_size = Vector2(8, 8)
	crosshair.size = Vector2(8, 8)
	crosshair.position -= Vector2(4, 4)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.draw.connect(func() -> void:
		crosshair.draw_circle(Vector2(4, 4), 3.2, Color(UI.INK, 0.55))
		crosshair.draw_circle(Vector2(4, 4), 2.0, Color(UI.TEXT, 0.9)))
	crosshair.visible = false
	root.add_child(crosshair)

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		crosshair.visible = AppState.first_person and not settings_open and not suppress_context and player.seating.state == player.seating.State.FREE

func _on_view_changed(first_person: bool) -> void:
	show_message("First-person view" if first_person else "Third-person view", 2.5)

func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 14
	bar.offset_right = -14
	bar.offset_top = 12
	bar.add_theme_constant_override("separation", 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	# Location and objective.
	var where := UI.hud_card()
	where.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.add_child(where)
	var where_row := HBoxContainer.new()
	where_row.add_theme_constant_override("separation", 9)
	where.add_child(where_row)
	where_row.add_child(Icon.new("pin", 15, UI.ACCENT))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	where_row.add_child(stack)
	location_label = UI.label(location_title, 11, Color("b6c9ca"), 600, true)
	stack.add_child(location_label)
	objective_label = UI.label(objective_text, UI.SIZE_LABEL + 1, UI.TEXT, 500)
	stack.add_child(objective_label)
	objective_label.visible = not objective_text.is_empty()
	bar.add_child(UI.spacer(0, 0, true))
	progression = preload("res://ui/progression_hud.gd").new()
	bar.add_child(progression)
	# Date above time.
	var clock_card := UI.hud_card()
	clock_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.add_child(clock_card)
	var clock_row := HBoxContainer.new()
	clock_row.add_theme_constant_override("separation", 9)
	clock_card.add_child(clock_row)
	clock_row.add_child(Icon.new("clock", 15, UI.TEXT_MUTED))
	var clock_stack := VBoxContainer.new()
	clock_stack.add_theme_constant_override("separation", -2)
	clock_row.add_child(clock_stack)
	clock_label = UI.label("", UI.SIZE_CAPTION, UI.TEXT_MUTED, 500)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_stack.add_child(clock_label)
	time_label = UI.label("", UI.SIZE_TITLE, UI.TEXT, 600)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_stack.add_child(time_label)

func _build_bottom() -> void:
	help_row = HBoxContainer.new()
	help_row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help_row.offset_left = 16
	help_row.offset_bottom = -12
	help_row.add_theme_constant_override("separation", 6)
	help_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(help_row)
	for pair in [["WASD", "Move"], ["E", "Interact"], ["Tab", "Menu"], ["×2", "Sprint"], [view_key(), "Camera"]]:
		var key := KeyPrompt.new()
		key.key = pair[0]
		help_row.add_child(key)
		key_prompts.append(key)
		help_row.add_child(_outlined(pair[1], UI.SIZE_LABEL, UI.TEXT))
		help_row.add_child(UI.spacer(0, 8))
	context_stack = VBoxContainer.new()
	context_stack.anchor_left = 0.5
	context_stack.anchor_right = 0.5
	context_stack.anchor_top = 1.0
	context_stack.anchor_bottom = 1.0
	context_stack.offset_left = -250
	context_stack.offset_right = 250
	context_stack.offset_bottom = -58
	context_stack.offset_top = -58
	context_stack.grow_horizontal = Control.GROW_DIRECTION_BOTH
	context_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	context_stack.alignment = BoxContainer.ALIGNMENT_END
	context_stack.add_theme_constant_override("separation", 8)
	context_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(context_stack)
	message_card = UI.hud_card()
	message_card.add_theme_stylebox_override("panel", UI.box(Color(UI.SURFACE, 0.9), 10, Color(1, 1, 1, 0.07), 1, Vector4(16, 10, 16, 11)))
	message_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	context_stack.add_child(message_card)
	message = UI.label("", UI.SIZE_BODY - 1, UI.TEXT, 400)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 440
	message_card.add_child(message)
	prompt_row = HBoxContainer.new()
	prompt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_row.add_theme_constant_override("separation", 9)
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	context_stack.add_child(prompt_row)
	context_key = KeyPrompt.new()
	prompt_row.add_child(context_key)
	prompt = _outlined("", UI.SIZE_BODY + 1, UI.TEXT)
	prompt_row.add_child(prompt)
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 6.0
	message_timer.timeout.connect(_clear_message)
	add_child(message_timer)

func _build_menu() -> void:
	menu = PlayerMenu.new(self)
	root.add_child(menu)
	menu.close_requested.connect(func() -> void: set_settings_open(false))
	menu_tabs = menu.pages
	var overview := preload("res://ui/menu/overview_page.gd").new()
	overview.open_page.connect(func(index: int) -> void: menu.step_page(index - menu.pages.current_tab))
	menu.add_page(overview)
	schedule_panel = preload("res://ui/menu/schedule_page.gd").new()
	menu.add_page(schedule_panel)
	calendar_panel = preload("res://ui/menu/calendar_page.gd").new()
	menu.add_page(calendar_panel)
	menu.add_page(preload("res://ui/menu/map_page.gd").new(self))
	knowledge_panel = preload("res://ui/menu/knowledge_page.gd").new()
	menu.add_page(knowledge_panel)
	menu.add_page(preload("res://ui/menu/notes_page.gd").new())
	menu.add_page(preload("res://ui/menu/achievements_page.gd").new())
	menu.add_page(preload("res://ui/menu/inventory_page.gd").new())
	var settings_scroll := ScrollContainer.new()
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings = SettingsPanel.new(true)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings)
	menu.add_page(settings_scroll)

## Unboxed HUD text: a dark outline keeps it readable over bright scenery.
func _outlined(text: String, size: int, color: Color) -> Label:
	var label := UI.label(text, size, color, 500)
	label.add_theme_color_override("font_outline_color", Color(UI.INK, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	return label

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
	auto_objective = false
	objective_text = text
	if is_instance_valid(objective_label):
		objective_label.text = text
		objective_label.visible = not text.is_empty()

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

## Opens or closes the player menu. The world keeps running either way.
func set_settings_open(value: bool) -> void:
	settings_open = value
	player.movement_enabled = not value
	player.interaction.enabled = not value and not player.seating.stand_locked and not (player.seating.busy() and player.seating.state != player.seating.State.SEATED)
	_show_target(current_target if is_instance_valid(current_target) else null)
	if value:
		menu.open(0)
	else:
		menu.close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_menu") or event.is_action_pressed("cancel"):
		if not event.is_echo():
			set_settings_open(not settings_open)
		get_viewport().set_input_as_handled()

func _refresh_clock() -> void:
	clock_label.text = GameClock.display_date()
	time_label.text = GameClock.display_time()
	if auto_objective and is_instance_valid(objective_label):
		objective_text = Objectives.current(AppState.location_key())
		objective_label.text = objective_text
		objective_label.visible = not objective_text.is_empty()

func _arrival_feedback(record: Dictionary) -> void:
	var arrival := Time.get_datetime_dict_from_unix_time(int(record.arrival_time))
	var time := "%d:%02d %s" % [12 if arrival.hour % 12 == 0 else arrival.hour % 12, arrival.minute, "AM" if arrival.hour < 12 else "PM"]
	message.text = ("Late arrival at %s — −%d XP. Penalty recorded once." % [time, absi(record.xp_delta)]) if record.late else "Arrived on time for Pharmacodynamics."
	message_timer.start(10.0)
	schedule_panel.refresh()
	calendar_panel.refresh()
	_refresh_context()

func _device_changed(controller: bool) -> void:
	var keys := ["LS", "X", "Start", "L3", "View"] if controller else ["WASD", "E", "Tab", "×2", view_key()]
	for index in range(key_prompts.size()):
		key_prompts[index].key = keys[index]
	_show_target(current_target if is_instance_valid(current_target) else null)

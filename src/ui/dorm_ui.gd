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
const WardrobePanel = preload("res://ui/wardrobe_panel.gd")
const Clothing = preload("res://data/clothing.gd")
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
## The closet overlay (dorm), built on first use.
var closet: Control
var closet_open := false
var computer: CanvasLayer
var computer_open := false
var laptop_model: Node3D
var laptop_hint: Button
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
	laptop_hint = Button.new()
	laptop_hint.custom_minimum_size = Vector2(164, 32)
	for style in ["normal", "hover", "pressed"]:
		laptop_hint.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	var laptop_row := HBoxContainer.new()
	laptop_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laptop_row.add_theme_constant_override("separation", 8)
	laptop_hint.add_child(laptop_row)
	var laptop_key := KeyPrompt.new()
	laptop_key.key = "L"
	laptop_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laptop_row.add_child(laptop_key)
	laptop_row.add_child(_outlined("Open laptop", UI.SIZE_BODY, UI.TEXT))
	laptop_hint.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	laptop_hint.position = Vector2(-188, -90)
	laptop_hint.visible = false
	laptop_hint.pressed.connect(open_laptop)
	root.add_child(laptop_hint)
	GameClock.minute_changed.connect(_refresh_clock)
	AcademicSession.attendance_recorded.connect(_arrival_feedback)
	AppState.view_changed.connect(_on_view_changed)
	AcademicSession.level_up.connect(_announce_unlocks)
	AcademicSession.lecture_completed.connect(func(id: String) -> void:
		if id == Clothing.FIRST_LECTURE:
			show_message("Unlocked in your closet: %s (Legendary)" % ", ".join(Clothing.legendary_names()), 8.0))
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
		laptop_hint.visible = can_use_laptop() and not computer_open and not settings_open and not closet_open
		if computer_open and is_instance_valid(laptop_model) and not can_use_laptop():
			computer.close()
		crosshair.visible = AppState.first_person and not settings_open and not closet_open and not computer_open and not suppress_context and player.seating.state == player.seating.State.FREE

## Levelling up can unlock rarer clothes; say which.
func _announce_unlocks(from_level: int, to_level: int) -> void:
	var names := Clothing.unlocked_by_level(from_level, to_level)
	if not names.is_empty():
		show_message("New in your closet: %s" % ", ".join(names.slice(0, 4)) + (" and %d more" % (names.size() - 4) if names.size() > 4 else ""), 8.0)

## Opens the closet (clothes and mirror). Movement pauses while it is open.
func open_closet(tab := 0) -> void:
	if not is_instance_valid(closet):
		closet = WardrobePanel.new()
		closet.name = "Closet"
		root.add_child(closet)
		closet.closed.connect(close_closet)
	closet_open = true
	player.movement_enabled = false
	player.interaction.enabled = false
	_show_target(current_target if is_instance_valid(current_target) else null)
	closet.open(tab)

func close_closet() -> void:
	if not closet_open:
		return
	closet_open = false
	if is_instance_valid(closet) and closet.visible:
		closet.close()
	player.movement_enabled = true
	player.interaction.enabled = not player.seating.stand_locked
	_show_target(current_target if is_instance_valid(current_target) else null)

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
	var inventory := preload("res://ui/menu/inventory_page.gd").new()
	inventory.laptop_requested.connect(open_laptop)
	menu.add_page(inventory)
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
	if is_instance_valid(target) and not settings_open and not closet_open and not computer_open:
		context_key.key = "X" if player.interaction.using_controller else "E"
		prompt.text = target.display_name
	_refresh_context()

func _show_response(target: Node3D) -> void:
	message.text = target.response
	if not message.text.is_empty():
		message_timer.start()
	_refresh_context()

## Scenes with several areas (the hospital's floors) update the location line.
func set_location(text: String) -> void:
	location_title = text
	if is_instance_valid(location_label):
		location_label.text = text.to_upper()

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
	message_card.visible = not settings_open and not closet_open and not computer_open and not suppress_context and not message.text.is_empty()
	prompt_row.visible = not settings_open and not closet_open and not computer_open and not suppress_context and not prompt.text.is_empty()

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
	if computer_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L and not closet_open:
		open_laptop()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("open_menu") or event.is_action_pressed("cancel"):
		if closet_open:
			close_closet()
		elif not event.is_echo():
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
	var title := "class"
	for event in GameClock.config.events:
		if event.id == record.event_id:
			title = String(event.title).capitalize()
	message.text = ("Late arrival at %s — −%d XP. Penalty recorded once." % [time, absi(record.xp_delta)]) if record.late else "Arrived on time for %s." % title
	message_timer.start(10.0)
	schedule_panel.refresh()
	calendar_panel.refresh()
	_refresh_context()

func _device_changed(controller: bool) -> void:
	var keys := ["LS", "X", "Start", "L3", "View"] if controller else ["WASD", "E", "Tab", "×2", view_key()]
	for index in range(key_prompts.size()):
		key_prompts[index].key = keys[index]
	_show_target(current_target if is_instance_valid(current_target) else null)

## Backpack availability is derived from equipment, so it cannot drift from the outfit.
func can_use_laptop() -> bool:
	if not is_instance_valid(player) or not Flashcards.has_laptop() or player.seating.state != player.seating.State.SEATED:
		return false
	var seat: Node3D = player.seating.seat
	return is_instance_valid(seat) and (seat.style == "auditorium" or seat.laptop_surface != Vector3.INF)

func open_laptop() -> void:
	if computer_open or closet_open:
		return
	if not can_use_laptop():
		if settings_open:
			set_settings_open(false)
		show_message("Wear a backpack and sit at a study table or in a lecture seat to use your laptop.", 6.0)
		return
	if settings_open:
		set_settings_open(false)
	var seat: Node3D = player.seating.seat
	laptop_model = preload("res://world/laptop.gd").new()
	laptop_model.name = "StudentLaptop"
	laptop_model.with_tray = seat.style == "auditorium"
	laptop_model.position = Vector3(0, 0.68, -0.62) if seat.style == "auditorium" else seat.laptop_surface
	seat.add_child(laptop_model)
	open_computer("macos", laptop_model.screen)

## Opens a computer on `screen` (the world display it draws onto).
func open_computer(os_style := "windows", screen: MeshInstance3D = null) -> void:
	if computer_open or closet_open:
		return
	if settings_open:
		set_settings_open(false)
	computer_open = true
	player.movement_enabled = false
	player.interaction.enabled = false
	computer = preload("res://ui/computer/desktop.gd").new()
	computer.os_style = os_style
	computer.player = player
	computer.screen_mesh = screen
	computer.closed.connect(close_computer)
	add_child(computer)
	# The computer shows its own "step away" hint; the walking controls (and
	# the lecture's Space/E prompts, whose keys now go to the computer) don't apply.
	help_row.visible = false
	var lecture_overlay: Variant = get_parent().get("lecture_ui")
	if lecture_overlay is CanvasLayer:
		lecture_overlay.visible = false
	_show_target(null)

func close_computer() -> void:
	computer_open = false
	help_row.visible = not player.seating.stand_locked
	var lecture_overlay: Variant = get_parent().get("lecture_ui")
	if lecture_overlay is CanvasLayer:
		lecture_overlay.visible = true
	if is_instance_valid(laptop_model):
		# The laptop is packed away once the camera has eased back out.
		var model := laptop_model
		laptop_model = null
		var view: Camera3D = computer.camera if is_instance_valid(computer) else null
		if is_instance_valid(view) and not view.is_queued_for_deletion():
			view.tree_exited.connect(model.queue_free)
		else:
			model.queue_free()
	player.movement_enabled = true
	player.interaction.enabled = not player.seating.stand_locked and player.seating.state in [player.seating.State.FREE, player.seating.State.SEATED]
	_show_target(player.interaction.target if is_instance_valid(player.interaction.target) else null)

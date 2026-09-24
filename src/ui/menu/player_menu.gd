extends Control
## The player menu (spec §32): a centred panel with a sidebar — student
## identity, level and navigation — and a content area hosting nine pages.
## The world keeps running behind it (time and NPCs never pause).
signal close_requested
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Presets = preload("res://data/character_presets.gd")
const PANEL_SIZE := Vector2(904, 584)
const SIDEBAR_WIDTH := 232.0
## [node name, sidebar label, icon, page title, page subtitle]
const PAGES := [
	["Overview", "Overview", "overview", "Overview", "Your day at a glance"],
	["Today", "Today", "schedule", "Today's Schedule", "Classes and commitments for today"],
	["Calendar", "Calendar", "calendar", "Academic Calendar", "Fall 1 term"],
	["Map", "Campus Map", "map", "Campus Map", "Where you are and where you're going"],
	["Knowledge", "Knowledge", "knowledge", "Knowledge", "Accuracy = correct answers ÷ attempted questions"],
	["Notes", "Lecture Notes", "notes", "Lecture Notes", "Key points from the lectures you've attended"],
	["Achievements", "Achievements", "achievements", "Achievements", "Milestones in your first year"],
	["Inventory", "Inventory", "inventory", "Inventory", "What you're carrying"],
	["Settings", "Settings", "settings", "Settings", "Audio, display and controls"],
]
var hud: CanvasLayer
var pages: TabContainer
var nav_buttons: Array[Button] = []
var page_title: Label
var page_subtitle: Label
var panel: PanelContainer
var level_label: Label
var xp_label: Label
var xp_bar: Control
var identity_name: Label
var backdrop: ColorRect
var open_tween: Tween

func _init(owner_hud: CanvasLayer) -> void:
	hud = owner_hud

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	backdrop = ColorRect.new()
	backdrop.color = Color(UI.INK, 0.55)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style())
	panel.custom_minimum_size = PANEL_SIZE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -PANEL_SIZE.x / 2.0
	panel.offset_right = PANEL_SIZE.x / 2.0
	panel.offset_top = -PANEL_SIZE.y / 2.0
	panel.offset_bottom = PANEL_SIZE.y / 2.0
	add_child(panel)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	panel.add_child(layout)
	layout.add_child(_sidebar())
	layout.add_child(UI.hairline(true))
	layout.add_child(_content())
	AcademicSession.xp_changed.connect(func(_a, _b, _c, _d) -> void: _refresh_identity())
	_refresh_identity()
	hide()

func _sidebar() -> Control:
	var side := PanelContainer.new()
	side.custom_minimum_size.x = SIDEBAR_WIDTH
	var style := UI.box(Color(UI.INK, 0.55), 0, Color.TRANSPARENT, 0, Vector4(18, 20, 18, 18))
	style.corner_radius_top_left = 14
	style.corner_radius_bottom_left = 14
	side.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	side.add_child(column)
	# Identity: monogram, student name, year, level and XP.
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 10)
	column.add_child(identity)
	var monogram := PanelContainer.new()
	monogram.add_theme_stylebox_override("panel", UI.box(Color(UI.ACCENT, 0.14), 10, Color(UI.ACCENT, 0.5), 1, Vector4(8, 8, 8, 8)))
	monogram.add_child(Icon.new("person", 20, UI.ACCENT))
	identity.add_child(monogram)
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 0)
	identity.add_child(who)
	identity_name = UI.label("", UI.SIZE_TITLE, UI.TEXT, 600)
	who.add_child(identity_name)
	who.add_child(UI.label("First-year · Fall 1", UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
	column.add_child(UI.spacer(12))
	var level_row := HBoxContainer.new()
	column.add_child(level_row)
	level_label = UI.label("", UI.SIZE_LABEL, UI.REWARD, 600)
	level_row.add_child(level_label)
	level_row.add_child(UI.spacer(0, 0, true))
	xp_label = UI.label("", UI.SIZE_CAPTION, UI.TEXT_MUTED, 500)
	level_row.add_child(xp_label)
	xp_bar = Control.new()
	xp_bar.custom_minimum_size = Vector2(0, 5)
	xp_bar.draw.connect(func() -> void:
		var fraction: float = AcademicSession.level_progress().fraction
		xp_bar.draw_rect(Rect2(Vector2.ZERO, xp_bar.size), Color(1, 1, 1, 0.08))
		xp_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(xp_bar.size.x * fraction, xp_bar.size.y)), UI.REWARD))
	column.add_child(xp_bar)
	column.add_child(UI.spacer(16))
	column.add_child(UI.hairline())
	column.add_child(UI.spacer(10))
	for index in range(PAGES.size()):
		var entry: Array = PAGES[index]
		var button := Button.new()
		button.theme_type_variation = "NavButton"
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 36)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 12
		var icon := Icon.new(entry[2], 17, UI.TEXT_MUTED)
		icon.name = "Icon"
		row.add_child(icon)
		var text := UI.label(entry[1], UI.SIZE_BODY, UI.TEXT_MUTED, 500)
		text.name = "Text"
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(text)
		button.add_child(row)
		button.pressed.connect(show_page.bind(index))
		button.focus_entered.connect(func() -> void:
			if pages.current_tab != index:
				show_page(index)
				Sfx.play("ui_move"))
		column.add_child(button)
		nav_buttons.append(button)
	column.add_child(UI.spacer(0, 0, true))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	footer.add_child(Icon.new("clock", 14, UI.TEXT_FAINT))
	footer.add_child(UI.label("Time keeps moving while you read", UI.SIZE_CAPTION, UI.TEXT_FAINT, 400))
	column.add_child(footer)
	return side

func _content() -> Control:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	page_title = UI.label("", UI.SIZE_HEADING, UI.TEXT, 600)
	titles.add_child(page_title)
	page_subtitle = UI.label("", UI.SIZE_LABEL, UI.TEXT_MUTED, 400)
	titles.add_child(page_subtitle)
	var close := Button.new()
	close.theme_type_variation = "GhostButton"
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(func() -> void: close_requested.emit())
	var close_row := HBoxContainer.new()
	close_row.add_theme_constant_override("separation", 6)
	close_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var key := preload("res://ui/key_prompt.gd").new()
	key.key = "Tab"
	close_row.add_child(key)
	close_row.add_child(close)
	header.add_child(close_row)
	column.add_child(UI.hairline())
	pages = TabContainer.new()
	pages.tabs_visible = false
	pages.clip_contents = true
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column.add_child(pages)
	return margin

## Adds a page (in PAGES order) under its node name.
func add_page(page: Control) -> void:
	page.name = PAGES[pages.get_child_count()][0]
	pages.add_child(page)

func show_page(index: int) -> void:
	pages.current_tab = index
	var entry: Array = PAGES[index]
	page_title.text = entry[3]
	page_subtitle.text = entry[4]
	for i in range(nav_buttons.size()):
		var selected := i == index
		nav_buttons[i].set_pressed_no_signal(selected)
		var row := nav_buttons[i].get_child(0)
		row.get_node("Icon").color = UI.ACCENT if selected else UI.TEXT_MUTED
		row.get_node("Text").add_theme_color_override("font_color", UI.TEXT if selected else UI.TEXT_MUTED)
	var page := pages.get_child(index)
	if page.has_method("refresh"):
		page.refresh()

func open(index := 0) -> void:
	_refresh_identity()
	show()
	show_page(index)
	nav_buttons[index].grab_focus()
	modulate.a = 0.0
	panel.scale = Vector2(0.98, 0.98)
	panel.pivot_offset = PANEL_SIZE / 2.0
	if open_tween:
		open_tween.kill()
	open_tween = create_tween().set_parallel(true)
	open_tween.tween_property(self, "modulate:a", 1.0, 0.16)
	open_tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Sfx.play("ui_open")

func close() -> void:
	if not visible:
		return
	Sfx.play("ui_close")
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	hide()

func _refresh_identity() -> void:
	if not is_instance_valid(level_label):
		return
	var data := Presets.get_preset(AppState.selected_character)
	identity_name.text = data.name
	var progress: Dictionary = AcademicSession.level_progress()
	level_label.text = "Lvl %d" % progress.level
	xp_label.text = "%d / %d XP" % [progress.into, progress.needed]
	xp_bar.queue_redraw()

## Unhandled Q/E-style page stepping for controllers (shoulder buttons are not
## bound, so up/down on the sidebar is the primary navigation).
func step_page(delta: int) -> void:
	var index := posmod(pages.current_tab + delta, PAGES.size())
	show_page(index)
	nav_buttons[index].grab_focus()

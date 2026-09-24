extends PanelContainer
## An application window inside the in-game desktop, with native-looking
## chrome for each OS: Windows 10 (icon and title left; minimise, maximise
## and a red-on-hover close at the right) or macOS (traffic lights at the
## left, centred title, rounded corners). Drag by the title bar; double-click
## it (or the maximise / green button) to fill the desktop.
signal close_requested
signal minimize_requested
const Kit = preload("res://ui/computer/os_kit.gd")
var os_style := "windows"
var title := ""
var icon_name := "anki"
var content: MarginContainer
var title_bar: Control
var maximized := false
var restore_rect := Rect2()
## Area the window may fill when maximised (parent coordinates).
var work_area := Rect2()
var _dragging := false
var _drag_offset := Vector2.ZERO

func _init(style: String, window_title: String, icon := "anki") -> void:
	os_style = style
	title = window_title
	icon_name = icon

func _ready() -> void:
	var mac := os_style == "macos"
	var frame := Kit.box(Color("ececec") if mac else Color("ffffff"), 11 if mac else 0, Color(0, 0, 0, 0.35) if mac else Color("6f8fb8"), 1)
	frame.shadow_color = Color(0, 0, 0, 0.35 if mac else 0.28)
	frame.shadow_size = 26 if mac else 14
	frame.shadow_offset = Vector2(0, 8 if mac else 4)
	add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	title_bar = _mac_bar() if mac else _windows_bar()
	column.add_child(title_bar)
	title_bar.gui_input.connect(_title_input)
	content = MarginContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.clip_contents = true
	column.add_child(content)

func _windows_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 32
	bar.add_theme_stylebox_override("panel", Kit.box(Color("ffffff"), 0, Color.TRANSPARENT, 0, Vector4(8, 0, 0, 0)))
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	var glyph := Kit.icon_rect(icon_name, 16)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	var caption := Kit.label(title, os_style, 12, Color("1b1b1b"))
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	for entry in [["min", Color(0, 0, 0, 0.06)], ["max", Color(0, 0, 0, 0.06)], ["close", Color("e81123")]]:
		var button := Button.new()
		button.name = "Caption_" + entry[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(46, 32)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", Kit.box(entry[1]))
		button.add_theme_stylebox_override("pressed", Kit.box(Color(entry[1], entry[1].a + 0.1)))
		var kind: String = entry[0]
		button.draw.connect(_draw_caption.bind(button, kind))
		button.mouse_entered.connect(button.queue_redraw)
		button.mouse_exited.connect(button.queue_redraw)
		button.pressed.connect(_caption_pressed.bind(kind))
		row.add_child(button)
	return bar

func _mac_bar() -> Control:
	var bar := Control.new()
	bar.custom_minimum_size.y = 30
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	var caption := Kit.label(title, os_style, 13, Color("3b3b3b"), 600)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(caption)
	var lights := HBoxContainer.new()
	lights.add_theme_constant_override("separation", 8)
	lights.position = Vector2(12, 9)
	bar.add_child(lights)
	for entry in [["close", Color("ff5f57")], ["min", Color("febc2e")], ["max", Color("28c840")]]:
		var button := Button.new()
		button.name = "Light_" + entry[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(12, 12)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var color: Color = entry[1]
		var kind: String = entry[0]
		button.draw.connect(_draw_light.bind(button, kind, color, lights))
		button.pressed.connect(_caption_pressed.bind(kind))
		lights.add_child(button)
	lights.mouse_entered.connect(func() -> void:
		for light in lights.get_children():
			light.queue_redraw())
	lights.mouse_exited.connect(func() -> void:
		for light in lights.get_children():
			light.queue_redraw())
	lights.mouse_filter = Control.MOUSE_FILTER_PASS
	return bar

func _caption_pressed(kind: String) -> void:
	if kind == "close":
		close_requested.emit()
	elif kind == "min":
		minimize_requested.emit()
	else:
		toggle_maximized()

## Windows caption glyphs: ─ □ ✕ (the close button turns red with a white ✕).
func _draw_caption(button: Button, kind: String) -> void:
	var c := Vector2(23, 16)
	var ink := Color.WHITE if kind == "close" and button.is_hovered() else Color("1b1b1b")
	if kind == "min":
		button.draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), ink, 1.0)
	elif kind == "max":
		button.draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), ink, false, 1.0)
	else:
		button.draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), ink, 1.2, true)
		button.draw_line(c + Vector2(5, -5), c + Vector2(-5, 5), ink, 1.2, true)

## macOS traffic lights; their glyphs appear while the pointer is over the group.
func _draw_light(button: Button, kind: String, color: Color, lights: Control) -> void:
	button.draw_circle(Vector2(6, 6), 6, color.darkened(0.12))
	button.draw_circle(Vector2(6, 6), 5.3, color)
	if not lights.get_global_rect().has_point(button.get_global_mouse_position()):
		return
	var ink := Color(0, 0, 0, 0.55)
	if kind == "close":
		button.draw_line(Vector2(3.5, 3.5), Vector2(8.5, 8.5), ink, 1.2, true)
		button.draw_line(Vector2(8.5, 3.5), Vector2(3.5, 8.5), ink, 1.2, true)
	elif kind == "min":
		button.draw_line(Vector2(3, 6), Vector2(9, 6), ink, 1.2)
	else:
		button.draw_colored_polygon(PackedVector2Array([Vector2(3.5, 3.5), Vector2(7.5, 3.5), Vector2(3.5, 7.5)]), ink)
		button.draw_colored_polygon(PackedVector2Array([Vector2(8.5, 8.5), Vector2(4.5, 8.5), Vector2(8.5, 4.5)]), ink)

## Places the window, remembering the rect for un-maximising.
func place(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	restore_rect = rect

func toggle_maximized() -> void:
	maximized = not maximized
	if maximized:
		restore_rect = Rect2(position, size)
		position = work_area.position
		size = work_area.size
	else:
		position = restore_rect.position
		size = restore_rect.size

func _title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			toggle_maximized()
			_dragging = false
		else:
			_dragging = event.pressed and not maximized
			_drag_offset = event.global_position - global_position
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var parent_rect := work_area if work_area.size != Vector2.ZERO else Rect2(Vector2.ZERO, get_parent_area_size())
		var target: Vector2 = event.global_position - _drag_offset - (get_parent() as Control).global_position
		target.x = clampf(target.x, parent_rect.position.x - size.x + 80, parent_rect.end.x - 80)
		target.y = clampf(target.y, parent_rect.position.y, parent_rect.end.y - 32)
		position = target
		accept_event()

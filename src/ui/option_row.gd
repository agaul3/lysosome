extends Button
## One appearance option: a focusable row showing its title and current value.
## Left/right (keys, d-pad or the arrow buttons) step through the choices;
## pressing the row steps forward. Colour options show their swatches, and
## clicking a swatch picks it directly.
signal changed(value: String)
const UI = preload("res://ui/style/ui_style.gd")
var key := ""
var title := ""
## [[value, label]] for named choices; [[label, hex]] for swatches.
var options: Array = []
var swatches := false
var index := 0
var value_label: Label
var strip: Control
var title_label: Label

func _init(option_key: String, option_title: String, choices: Array, as_swatches := false) -> void:
	key = option_key
	title = option_title
	options = choices
	swatches = as_swatches

func _ready() -> void:
	theme_type_variation = "CardButton"
	custom_minimum_size = Vector2(0, 42)
	focus_mode = Control.FOCUS_ALL
	text = ""
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -8
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	title_label = UI.label(title, UI.SIZE_LABEL, UI.TEXT_MUTED, 500)
	title_label.custom_minimum_size.x = 104
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title_label)
	row.add_child(_arrow("‹", -1))
	if swatches:
		strip = Control.new()
		strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		strip.custom_minimum_size = Vector2(0, 26)
		strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		strip.mouse_filter = Control.MOUSE_FILTER_PASS
		strip.draw.connect(_draw_strip)
		strip.gui_input.connect(_strip_input)
		row.add_child(strip)
	else:
		value_label = UI.label("", UI.SIZE_BODY, UI.TEXT, 600)
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(value_label)
	row.add_child(_arrow("›", 1))
	pressed.connect(step.bind(1))
	_refresh()

func _arrow(glyph: String, direction: int) -> Button:
	var arrow := Button.new()
	arrow.text = glyph
	arrow.theme_type_variation = "GhostButton"
	arrow.focus_mode = Control.FOCUS_NONE
	arrow.custom_minimum_size = Vector2(28, 28)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrow.pressed.connect(step.bind(direction))
	return arrow

func value() -> String:
	if options.is_empty():
		return ""
	return String(options[index][1] if swatches else options[index][0])

## Selects a value without emitting `changed`.
func set_value(target: String) -> void:
	for i in range(options.size()):
		var candidate := String(options[i][1] if swatches else options[i][0])
		if candidate.to_lower() == target.trim_prefix("#").to_lower():
			index = i
			_refresh()
			return

func step(direction: int) -> void:
	if options.is_empty():
		return
	index = posmod(index + direction, options.size())
	_refresh()
	Sfx.play("ui_move")
	changed.emit(value())

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		step(-1)
		accept_event()
	elif event.is_action_pressed("ui_right"):
		step(1)
		accept_event()

func _refresh() -> void:
	if is_instance_valid(value_label):
		value_label.text = String(options[index][1]) if not options.is_empty() else ""
	if is_instance_valid(strip):
		strip.queue_redraw()
		tooltip_text = String(options[index][0]) if not options.is_empty() else ""

func _swatch_pitch() -> float:
	return minf(24.0, strip.size.x / maxf(1.0, options.size()))

func _draw_strip() -> void:
	var pitch := _swatch_pitch()
	var start := (strip.size.x - pitch * options.size()) / 2.0
	for i in range(options.size()):
		var centre := Vector2(start + pitch * (i + 0.5), strip.size.y / 2.0)
		var radius := pitch * 0.34
		if i == index:
			strip.draw_circle(centre, radius + 3.0, UI.ACCENT)
		strip.draw_circle(centre, radius + 1.0, Color(UI.INK, 0.8))
		strip.draw_circle(centre, radius, Color(String(options[i][1])))

func _strip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pitch := _swatch_pitch()
		var start := (strip.size.x - pitch * options.size()) / 2.0
		var picked := int(floor((event.position.x - start) / pitch))
		if picked >= 0 and picked < options.size():
			index = picked
			_refresh()
			Sfx.play("ui_move")
			changed.emit(value())
		grab_focus()
		strip.accept_event()

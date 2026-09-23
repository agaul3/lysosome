extends CanvasLayer
## Compact lecture overlay: a subtitle card for the professor (typewriter
## reveal), a small topic chip, and the pre-class waiting prompt. Input is
## handled by the lecture session; this node only presents.
signal typing_changed(typing: bool)
const KeyPrompt = preload("res://ui/key_prompt.gd")
const CHARACTERS_PER_SECOND := 55.0
var root: Control
var card: PanelContainer
var speaker: Label
var text: Label
var continue_row: HBoxContainer
var continue_key: Control
var topic_chip: PanelContainer
var topic_label: Label
var waiting_card: PanelContainer
var waiting_label: Label
var wait_key: Control
var stand_key: Control
var typing := false
var shown := 0.0

func _ready() -> void:
	layer = 2
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = preload("res://assets/outfit_medium.tres")
	theme.default_font_size = 15
	root.theme = theme
	add_child(root)
	card = _card(Vector2(620, 0))
	_pin_bottom(card, 620)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	card.add_child(stack)
	speaker = _label(12, Color("f0a36f"))
	stack.add_child(speaker)
	text = _label(16, Color("f1f6f2"))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(596, 44)
	stack.add_child(text)
	continue_row = HBoxContainer.new()
	continue_row.alignment = BoxContainer.ALIGNMENT_END
	continue_row.add_theme_constant_override("separation", 6)
	stack.add_child(continue_row)
	continue_key = KeyPrompt.new()
	continue_key.key = "E"
	continue_row.add_child(continue_key)
	continue_row.add_child(_label(12, Color("b9d3cf"), "Continue"))
	topic_chip = _card(Vector2.ZERO)
	_pin(topic_chip, 0.5, 0.0, 0.0, 12.0, Control.GROW_DIRECTION_END)
	topic_label = _label(12, Color("d9e6e2"))
	topic_chip.add_child(topic_label)
	waiting_card = _card(Vector2.ZERO)
	_pin_bottom(waiting_card, 0.0)
	var waiting_stack := VBoxContainer.new()
	waiting_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	waiting_card.add_child(waiting_stack)
	waiting_label = _label(15, Color("f1f6f2"))
	waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_stack.add_child(waiting_label)
	var keys := HBoxContainer.new()
	keys.alignment = BoxContainer.ALIGNMENT_CENTER
	keys.add_theme_constant_override("separation", 6)
	waiting_stack.add_child(keys)
	wait_key = KeyPrompt.new()
	wait_key.key = "Space"
	keys.add_child(wait_key)
	keys.add_child(_label(13, Color("d9e6e2"), "Wait for class"))
	var gap := Control.new()
	gap.custom_minimum_size.x = 12
	keys.add_child(gap)
	stand_key = KeyPrompt.new()
	stand_key.key = "E"
	keys.add_child(stand_key)
	keys.add_child(_label(13, Color("d9e6e2"), "Stand up"))
	hide_all()

## Anchors a panel to one point of the screen with explicit anchors and
## offsets, letting it grow from that point to fit its content.
static func _pin(control: Control, anchor_x: float, anchor_y: float, width: float, y: float, grow_y: int) -> void:
	control.anchor_left = anchor_x
	control.anchor_right = anchor_x
	control.anchor_top = anchor_y
	control.anchor_bottom = anchor_y
	control.offset_left = -width / 2.0
	control.offset_right = width / 2.0
	control.offset_top = y
	control.offset_bottom = y
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = grow_y

static func _pin_bottom(control: Control, width: float) -> void:
	_pin(control, 0.5, 1.0, width, -16.0, Control.GROW_DIRECTION_BEGIN)

func _card(minimum: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.12, 0.16, 0.82)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	return panel

func _label(size: int, color: Color, value := "") -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func hide_all() -> void:
	card.hide()
	topic_chip.hide()
	waiting_card.hide()
	_set_typing(false)

func show_waiting(message: String) -> void:
	card.hide()
	topic_chip.hide()
	waiting_label.text = message
	waiting_card.show()

func show_topic(value: String) -> void:
	topic_label.text = value
	topic_chip.show()

func show_line(name: String, line: String) -> void:
	waiting_card.hide()
	speaker.text = name.to_upper()
	text.text = line
	text.visible_characters = 0
	shown = 0.0
	continue_row.modulate.a = 0.0
	card.show()
	_set_typing(true)

func show_notice(message: String) -> void:
	speaker.text = ""
	text.text = message
	text.visible_characters = -1
	continue_row.modulate.a = 0.0
	topic_chip.hide()
	card.show()
	_set_typing(false)

func finish_typing() -> void:
	text.visible_characters = -1
	continue_row.modulate.a = 1.0
	_set_typing(false)

func set_controller(controller: bool) -> void:
	continue_key.key = "X" if controller else "E"
	stand_key.key = "X" if controller else "E"
	wait_key.key = "A" if controller else "Space"

func _set_typing(value: bool) -> void:
	if typing != value:
		typing = value
		typing_changed.emit(value)

func _process(delta: float) -> void:
	if not typing:
		return
	shown += delta * CHARACTERS_PER_SECOND
	text.visible_characters = int(shown)
	if shown >= text.get_total_character_count():
		finish_typing()

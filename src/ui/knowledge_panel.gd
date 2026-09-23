extends VBoxContainer
## Knowledge page of the player menu: accuracy by discipline, topic and
## subtopic (correct / attempted, with a bar), and the most recent answers.
## Everything is derived from the question bank's taxonomy and the recorded
## statistics each time the page refreshes; nothing is stored here.
signal closed
const Knowledge = preload("res://education/knowledge/knowledge.gd")
const BAR := Vector2(74, 6)
var summary: Label
var rows_box: VBoxContainer
var recent_box: VBoxContainer
var back_button: Button
## path -> the value label shown for that row (read by tests).
var value_labels := {}

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var title := _label("Knowledge", 19, Color("f1f6f2"))
	add_child(title)
	summary = _label("", 13, Color("b9d3cf"))
	add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	scroll.add_child(content)
	rows_box = VBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 4)
	content.add_child(rows_box)
	content.add_child(_label("Recent answers", 14, Color("f0a36f")))
	recent_box = VBoxContainer.new()
	recent_box.add_theme_constant_override("separation", 2)
	content.add_child(recent_box)
	back_button = Button.new()
	back_button.text = "Back to exploration"
	back_button.custom_minimum_size.y = 40
	back_button.pressed.connect(func() -> void: closed.emit())
	add_child(back_button)
	AcademicSession.answer_recorded.connect(func(_result: Dictionary) -> void: refresh())
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func refresh() -> void:
	var roots := Knowledge.tree(QuestionBank.records.values(), AcademicSession.topic_statistics)
	for child in rows_box.get_children() + recent_box.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	value_labels.clear()
	var attempted := 0
	var correct := 0
	for root in roots:
		attempted += root.attempted
		correct += root.correct
		_add_rows(root)
	summary.text = "Accuracy = correct answers ÷ attempted questions" if attempted == 0 else "Overall: %d of %d correct (%d%%)" % [correct, attempted, int(round(Knowledge.accuracy(correct, attempted) * 100.0))]
	var recent := Knowledge.recent(AcademicSession.question_history, QuestionBank)
	if recent.is_empty():
		recent_box.add_child(_label("No questions answered yet.", 13, Color("9fb3b3")))
	for entry in recent:
		var prompt: String = entry.prompt
		if prompt.length() > 58:
			prompt = prompt.left(55) + "…"
		var mark := "Correct  " if entry.correct else "Missed   "
		recent_box.add_child(_label(mark + prompt, 12, Color("bff0cc") if entry.correct else Color("f6c1b8")))

func _add_rows(node: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var indent := Control.new()
	indent.custom_minimum_size.x = 16 * node.depth
	row.add_child(indent)
	var name_label := _label(node.name, [16, 15, 13][mini(node.depth, 2)], Color("f1f6f2") if node.depth < 2 else Color("d9e6e2"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	row.add_child(name_label)
	var bar := Control.new()
	bar.custom_minimum_size = BAR
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fraction: float = node.accuracy
	var empty: bool = node.attempted == 0
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, BAR), Color(1, 1, 1, 0.12))
		if not empty:
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(BAR.x * fraction, BAR.y)), Color("8fe0a8").lerp(Color("f0a36f"), 1.0 - fraction)))
	row.add_child(bar)
	var value := _label(Knowledge.accuracy_text(node) + "   " + ("—" if empty else "%d/%d" % [node.correct, node.attempted]), 13, Color("b9d3cf"))
	value.custom_minimum_size.x = 86
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	value_labels[node.path] = value
	rows_box.add_child(row)
	for child in node.children:
		_add_rows(child)

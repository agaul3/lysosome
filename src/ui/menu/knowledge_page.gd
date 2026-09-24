extends "res://ui/menu/menu_page.gd"
## Knowledge (fully functional): overall accuracy, an accuracy row for every
## discipline, topic and subtopic (correct ÷ attempted, with a bar), and the
## most recent answers. Rebuilt from the question bank's taxonomy and the
## recorded statistics on every refresh; nothing is stored here.
const Knowledge = preload("res://education/knowledge/knowledge.gd")
var summary: Label
var rows_box: VBoxContainer
var recent_box: VBoxContainer
## path -> the value label shown for that row (read by tests).
var value_labels := {}

func _ready() -> void:
	AcademicSession.answer_recorded.connect(func(_result: Dictionary) -> void: refresh())
	refresh()

func refresh() -> void:
	clear()
	value_labels.clear()
	var roots := Knowledge.tree(QuestionBank.records.values(), AcademicSession.topic_statistics)
	var attempted := 0
	var correct := 0
	for root in roots:
		attempted += root.attempted
		correct += root.correct
	# Headline figures.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	content.add_child(head)
	head.add_child(_stat("Overall accuracy", "—" if attempted == 0 else "%d%%" % int(round(Knowledge.accuracy(correct, attempted) * 100.0)), UI.TEXT))
	head.add_child(_stat("Questions attempted", str(attempted), UI.TEXT))
	head.add_child(_stat("Correct answers", str(correct), UI.SUCCESS))
	summary = UI.label("Accuracy = correct answers ÷ attempted questions" if attempted == 0 else "Overall: %d of %d correct (%d%%)" % [correct, attempted, int(round(Knowledge.accuracy(correct, attempted) * 100.0))], UI.SIZE_LABEL, UI.TEXT_MUTED, 500)
	content.add_child(summary)
	var tree := section("By subject", "knowledge")
	rows_box = VBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 3)
	tree.add_child(rows_box)
	for root in roots:
		_add_rows(root)
	var recent_column := section("Recent answers", "clock")
	recent_box = VBoxContainer.new()
	recent_box.add_theme_constant_override("separation", 5)
	recent_column.add_child(recent_box)
	var recent := Knowledge.recent(AcademicSession.question_history, QuestionBank)
	if recent.is_empty():
		recent_box.add_child(UI.label("No questions answered yet. Lecture questions appear here as you answer them.", UI.SIZE_LABEL, UI.TEXT_FAINT, 400))
	for entry in recent:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(Icon.new("check" if entry.correct else "plus", 13, UI.SUCCESS if entry.correct else UI.DANGER))
		var prompt: String = entry.prompt
		if prompt.length() > 64:
			prompt = prompt.left(61) + "…"
		var text := UI.label(("Correct  " if entry.correct else "Missed   ") + prompt, UI.SIZE_LABEL, UI.TEXT if entry.correct else UI.TEXT_MUTED, 400)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.clip_text = true
		row.add_child(text)
		row.add_child(UI.label(entry.subtopic, UI.SIZE_CAPTION, UI.TEXT_FAINT, 500))
		recent_box.add_child(row)
		# Rotate the miss icon into an ×.
		if not entry.correct:
			row.get_child(0).rotation = PI / 4
			row.get_child(0).pivot_offset = Vector2(6.5, 6.5)

func _stat(title: String, value: String, color: Color) -> Control:
	var card := UI.card(Vector4(16, 12, 16, 12))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	card.add_child(column)
	column.add_child(UI.label(title, UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	column.add_child(UI.label(value, 28, color, 600))
	return card

func _add_rows(node: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size.y = 26
	row.add_child(UI.spacer(0, 18 * node.depth))
	var sizes := [UI.SIZE_BODY + 1, UI.SIZE_BODY, UI.SIZE_LABEL + 1]
	var name_label := UI.label(node.name, sizes[mini(node.depth, 2)], UI.TEXT if node.depth < 2 else UI.TEXT_MUTED, 600 if node.depth < 2 else 500)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	row.add_child(name_label)
	var empty: bool = node.attempted == 0
	var colour := UI.SUCCESS.lerp(UI.REWARD, clampf((0.8 - node.accuracy) / 0.4, 0.0, 1.0))
	row.add_child(bar(0.0 if empty else node.accuracy, colour, 120))
	var value := UI.label(Knowledge.accuracy_text(node) + "   " + ("—" if empty else "%d/%d" % [node.correct, node.attempted]), UI.SIZE_LABEL, UI.TEXT if not empty else UI.TEXT_FAINT, 500)
	value.custom_minimum_size.x = 92
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	value_labels[node.path] = value
	rows_box.add_child(row)
	for child in node.children:
		_add_rows(child)

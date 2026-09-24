extends "res://ui/menu/menu_page.gd"
## Lecture Notes (representative): the key points of each lecture section the
## student has reached, taken from the lecture script's slides.
const LectureRunner = preload("res://education/lectures/lecture_runner.gd")
const LECTURE_PATH := "res://education/lectures/pharmacodynamics_01.json"
var runner := LectureRunner.new()

func _ready() -> void:
	runner.load_file(LECTURE_PATH)
	refresh()

func refresh() -> void:
	clear()
	var lecture_id: String = runner.script_data.get("id", "")
	var reached := int(AcademicSession.notes_progress.get(lecture_id, 0))
	var segments: Array = runner.segments()
	if reached == 0:
		empty_state("notes", "No notes yet", "Notes fill in section by section as you attend lectures. Pharmacodynamics is at 8:00 AM in Lecture Hall A.")
		return
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var title := UI.label(runner.script_data.title, UI.SIZE_TITLE, UI.TEXT, 600)
	header.add_child(title)
	header.add_child(UI.label(runner.script_data.professor, UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	header.add_child(UI.spacer(0, 0, true))
	var complete := AcademicSession.lectures_completed.has(lecture_id)
	header.add_child(UI.chip("Complete" if complete else "%d of %d sections" % [mini(reached, segments.size()), segments.size()], UI.SUCCESS if complete else UI.INFO))
	content.add_child(header)
	for index in range(mini(reached, segments.size())):
		var segment: Dictionary = segments[index]
		var bullets: Array = segment.slide.bullets
		var column := section("%02d · %s" % [index + 1, segment.topic], "book")
		if bullets.is_empty():
			var sub: String = segment.slide.get("subheading", "")
			column.add_child(UI.paragraph(sub if not sub.is_empty() else segment.slide.heading, WIDTH - 40, UI.SIZE_BODY, UI.TEXT))
		for bullet in bullets:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var dot := Control.new()
			dot.custom_minimum_size = Vector2(6, 18)
			dot.draw.connect(func() -> void: dot.draw_circle(Vector2(3, 10), 2.5, UI.ACCENT))
			row.add_child(dot)
			row.add_child(UI.paragraph(bullet, WIDTH - 60, UI.SIZE_BODY, UI.TEXT))
			column.add_child(row)
	if not complete and reached < segments.size():
		content.add_child(UI.label("%d more section(s) unlock as the lecture continues." % (segments.size() - reached), UI.SIZE_LABEL, UI.TEXT_FAINT, 400))

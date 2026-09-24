extends "res://ui/menu/menu_page.gd"
## Lecture Notes (representative): the key points of each lecture section the
## student has reached, taken from the lecture script's slides, and the
## takeaways from each stop of the physician shadowing session.
const LectureRunner = preload("res://education/lectures/lecture_runner.gd")
const ShadowingScript = preload("res://education/shadowing/shadowing_script.gd")
const LECTURE_PATH := "res://education/lectures/pharmacodynamics_01.json"
const SHADOWING_PATH := "res://education/shadowing/hospital_orientation_01.json"
var runner := LectureRunner.new()
var shadowing := ShadowingScript.new()

func _ready() -> void:
	runner.load_file(LECTURE_PATH)
	shadowing.load_file(SHADOWING_PATH)
	refresh()

func refresh() -> void:
	clear()
	var lecture_id: String = runner.script_data.get("id", "")
	var reached := int(AcademicSession.notes_progress.get(lecture_id, 0))
	var shadow_reached := int(AcademicSession.notes_progress.get(String(shadowing.data.get("id", "")), 0))
	if reached == 0 and shadow_reached == 0:
		empty_state("notes", "No notes yet", "Notes fill in section by section as you attend lectures. Pharmacodynamics is at 8:00 AM in Lecture Hall A.")
		return
	if reached > 0:
		_lecture_notes(lecture_id, reached)
	if shadow_reached > 0:
		_shadowing_notes(shadow_reached)

func _header(title_text: String, subtitle: String, chip_text: String, done: bool) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.add_child(UI.label(title_text, UI.SIZE_TITLE, UI.TEXT, 600))
	header.add_child(UI.label(subtitle, UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	header.add_child(UI.spacer(0, 0, true))
	header.add_child(UI.chip(chip_text, UI.SUCCESS if done else UI.INFO))
	content.add_child(header)

func _bullet(column: Control, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var dot := Control.new()
	dot.custom_minimum_size = Vector2(6, 18)
	dot.draw.connect(func() -> void: dot.draw_circle(Vector2(3, 10), 2.5, UI.ACCENT))
	row.add_child(dot)
	row.add_child(UI.paragraph(text, WIDTH - 60, UI.SIZE_BODY, UI.TEXT))
	column.add_child(row)

func _lecture_notes(lecture_id: String, reached: int) -> void:
	var segments: Array = runner.segments()
	var complete := AcademicSession.lectures_completed.has(lecture_id)
	_header(runner.script_data.title, runner.script_data.professor, "Complete" if complete else "%d of %d sections" % [mini(reached, segments.size()), segments.size()], complete)
	for index in range(mini(reached, segments.size())):
		var segment: Dictionary = segments[index]
		var bullets: Array = segment.slide.bullets
		var column := section("%02d · %s" % [index + 1, segment.topic], "book")
		if bullets.is_empty():
			var sub: String = segment.slide.get("subheading", "")
			column.add_child(UI.paragraph(sub if not sub.is_empty() else segment.slide.heading, WIDTH - 40, UI.SIZE_BODY, UI.TEXT))
		for bullet in bullets:
			_bullet(column, bullet)
	if not complete and reached < segments.size():
		content.add_child(UI.label("%d more section(s) unlock as the lecture continues." % (segments.size() - reached), UI.SIZE_LABEL, UI.TEXT_FAINT, 400))

## One takeaway per stop reached while shadowing Dr. Okafor.
func _shadowing_notes(reached: int) -> void:
	var stops: Array = shadowing.stops()
	var complete := AcademicSession.lectures_completed.has(String(shadowing.data.id))
	_header("Shadowing · " + String(shadowing.data.title), "%s · %s" % [shadowing.speaker_name("okafor"), shadowing.data.unit], "Complete" if complete else "%d of %d stops" % [mini(reached, stops.size()), stops.size()], complete)
	var column := section("Key takeaways", "notes")
	for index in range(mini(reached, stops.size())):
		var stop: Dictionary = stops[index]
		_bullet(column, "%s: %s" % [stop.topic, stop.takeaway])

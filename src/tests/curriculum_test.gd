extends "res://tests/campus_test.gd"
## The first-year curriculum content:
## - every lecture script validates, its question beats and remediations
##   exist in the bank, and every bank question for a lecture is asked;
## - every figure in slides and questions validates;
## - the schedule's lecture events on ready story days have their scripts;
## - each new lecture plays in its hall on its day, with every question
##   answered correctly, and is recorded;
## - a lecture's flashcards arrive on the day it's taught.
const LectureRunner = preload("res://education/lectures/lecture_runner.gd")
const Catalog = preload("res://education/lectures/lecture_catalog.gd")
const FigureArt = preload("res://ui/figure_art.gd")
const Seat = preload("res://world/seat.gd")
## Lectures after day 1 that are built, in schedule order.
const NEW_LECTURES := ["pharmacokinetics_01", "enzymes_01", "upper_limb_01", "muscle_bone_01", "cardiac_cycle_01", "blood_pressure_01", "respiratory_01", "renal_01", "diabetes_01", "gi_liver_01", "motor_pathways_01", "stroke_01"]
var bank: Node
var academics: Node
var clock: Node
var calendar: Node

func _run() -> void:
	state = root.get_node("AppState")
	bank = root.get_node("QuestionBank")
	academics = root.get_node("AcademicSession")
	clock = root.get_node("GameClock")
	calendar = root.get_node("YearCalendar")
	validate_content()
	for lecture_id in NEW_LECTURES:
		await play_lecture(lecture_id)
	print("CURRICULUM: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func validate_content() -> void:
	var files: Array = Array(DirAccess.get_files_at("res://education/lectures")).filter(func(name: String) -> bool: return name.ends_with(".json"))
	check(files.size() >= 1 + NEW_LECTURES.size(), "Lecture scripts present (%d)" % files.size())
	for file in files:
		var runner := LectureRunner.new()
		var loaded := runner.load_file("res://education/lectures/" + file)
		check(loaded, "Lecture validates: %s %s" % [file, runner.last_error])
		if not loaded:
			continue
		var asked := {}
		var missing: Array = []
		for segment in runner.script_data.segments:
			for line in segment.lines:
				for key in ["question", "remediation"]:
					if line.has(key):
						asked[line[key]] = true
						if bank.get_question(line[key]).is_empty():
							missing.append(line[key])
				if line.has("activity") and line.activity.has("question"):
					asked[line.activity.question] = true
		check(missing.is_empty(), "Every question beat in %s is in the bank %s" % [file, str(missing)])
		var orphans: Array = bank.for_lecture(runner.script_data.id).filter(func(q: Dictionary) -> bool: return not asked.has(q.id)).map(func(q: Dictionary) -> String: return q.id)
		check(orphans.is_empty(), "Every bank question for %s is asked %s" % [runner.script_data.id, str(orphans)])
	var bad_figures: Array = []
	for q in bank.records.values():
		if q.has("figure") and not FigureArt.validate(q.figure).is_empty():
			bad_figures.append(q.id)
	check(bad_figures.is_empty(), "Question figures validate %s" % str(bad_figures))
	# Ready story days have their lecture scripts.
	var missing_scripts: Array = []
	for day in calendar.days:
		if not day.get("ready", false):
			continue
		for event in calendar.events_on(day.date):
			if Catalog.is_lecture(event) and not Catalog.exists(Catalog.lecture_id(event)):
				missing_scripts.append(event.id)
	check(missing_scripts.is_empty(), "Every lecture on a ready day has a script %s" % str(missing_scripts))
	check(not FigureArt.validate({"type": "curves", "series": [{"fn": "nonsense"}]}).is_empty() and not FigureArt.validate({"type": "flow", "nodes": [{"id": "a"}], "edges": [{"from": "a", "to": "b"}]}).is_empty(), "Broken figures are rejected")
	check(is_equal_approx(FigureArt.evaluate("exponential_decay", {"c0": 80, "half_life": 6}, 18), 10.0) and is_equal_approx(FigureArt.evaluate("michaelis_menten", {"vmax": 100, "km": 2}, 2), 50.0), "Figure curves are quantitatively right")

## Plays a lecture on its scheduled day: jump to ten minutes before, sit in
## its hall, wait for class, answer every question correctly.
func play_lecture(lecture_id: String) -> void:
	var event: Dictionary = calendar.event(lecture_id)
	check(not event.is_empty(), "%s is on the schedule" % lecture_id)
	state.start_new_game()
	state.select_character("indigo")
	var start: float = calendar.start_of(event)
	clock.elapsed_seconds = start - 10 * 60 - clock.start_timestamp
	var hall_id: String = Catalog.hall_of(event)
	var flashcards := root.get_node("Flashcards")
	var sources: Array = bank.for_lecture(lecture_id).map(func(q: Dictionary) -> String: return q.id)
	check(flashcards.cards().any(func(card: Dictionary) -> bool: return String(card.source) in sources), "%s: flashcards are available on its day" % lecture_id)
	clock.elapsed_seconds -= 86400.0
	check(not flashcards.cards().any(func(card: Dictionary) -> bool: return String(card.source) in sources), "%s: …and not the day before" % lecture_id)
	clock.elapsed_seconds += 86400.0
	state.current_hall = hall_id
	# Through the building's doors, so arrival is recorded like any visit:
	# Hall A from the Learning Center, Hall B from the Medical Education Center.
	if hall_id == "hall_b":
		state.phase = state.Phase.MED_ED
		state.enter_lecture_hall_b()
	else:
		state.phase = state.Phase.LECTURE_BUILDING
		state.enter_lecture_hall()
	await acquire_world()
	var hall := dorm
	var session: Node = hall.session
	check(session.runner.script_data.id == lecture_id and not session.no_class, "%s runs in %s today" % [lecture_id, hall_id])
	check(hall.slide.heading.text == session.runner.script_data.segments[0].slide.heading, "Its title slide is on the screen")
	var seat: Node3D = hall.get_node("Seat_R2_C4")
	player.global_position = seat.point(Seat.FRONT_POINT) + Vector3(0, 0.04, 0)
	await ticks(4)
	player.seating.request(seat)
	for index in range(900):
		if player.seating.state == player.seating.State.SEATED:
			break
		await ticks(1)
	await ticks(2)
	session.wait_for_class()
	for index in range(900):
		if session.state == session.State.PRESENTING:
			break
		await ticks(1)
	check(session.state == session.State.PRESENTING, "%s begins at class time" % lecture_id)
	var asked := 0
	var guard := 0
	while session.state == session.State.PRESENTING and guard < 600:
		guard += 1
		if session.question.running():
			var id: String = session.question.current_id
			var question: Dictionary = bank.get_question(id)
			session.question.answer(question.correct_answer)
			asked += 1
			await ticks(1)
			session.question._continue()
			await ticks(1)
			continue
		if session.activity.running():
			check(false, "No interactive activity expected in %s" % lecture_id)
			break
		session.advance()
		session.advance()
		await ticks(1)
	var expected: int = bank.for_lecture(lecture_id).filter(func(q: Dictionary) -> bool: return not q.get("is_remediation", false)).size()
	check(asked == expected, "%s asks all %d questions (%d)" % [lecture_id, expected, asked])
	check(session.state == session.State.SUMMARY and session.summary.correct == expected and session.summary.attempted == expected, "%s: %d of %d correct" % [lecture_id, session.summary.get("correct", 0), expected])
	session._finish_lecture()
	await ticks(2)
	check(academics.lectures_completed.has(lecture_id) and int(academics.notes_progress.get(lecture_id, 0)) == session.runner.script_data.segments.size(), "%s is recorded, with notes for every section" % lecture_id)
	check(academics.attendance.has(event.date + ":" + event.id) and not academics.attendance[event.date + ":" + event.id].late, "%s: on-time attendance recorded" % lecture_id)

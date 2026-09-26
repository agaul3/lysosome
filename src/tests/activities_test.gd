extends "res://tests/student_life_test.gd"
## The year's scheduled activities (education/activities/, played through
## world/activity_station.gd):
## - every activity file validates: its steps, questions, figures, choices,
##   history and examination boards, exams' marks and awards;
## - every non-lecture event on the calendar has its activity (or is one of
##   the open social events), and every activity is on the calendar;
## - every activity event has a station in its building, in its room;
## - played through: a histology lab, a standardized patient, a block exam
##   in date order (the clock only runs forward): a histology lab, a
##   standardized patient, the White Coat Ceremony, a block exam with Honors,
##   the donor dedication and the anatomy practical, an Emergency Department
##   shift, a block exam below the pass mark, a small-group case answered
##   badly, Research Day, the OSCE and the end of the year, which rolls into
##   summer mornings.
const Catalog = preload("res://education/lectures/lecture_catalog.gd")
const FigureArt = preload("res://ui/figure_art.gd")
const STATION_SCRIPT := "res://world/activity_station.gd"
const KINDS := ["lab", "encounter", "immersion", "ceremony", "case", "event", "exam"]
## Calendar events that aren't activities: the fair's tables and the Community
## Kitchen's holiday serving line open for them.
const OPEN_EVENTS := ["club_fair", "thanksgiving_meal"]
var academics: Node
## "place:room" -> true, for every station found in the world.
var station_rooms := {}

func _run() -> void:
	create_timer(600.0).timeout.connect(func() -> void:
		push_error("Activities test timed out")
		quit(2))
	state = root.get_node("AppState")
	clubs = root.get_node("Clubs")
	wallet = root.get_node("Wallet")
	wellbeing = root.get_node("Wellbeing")
	achievements = root.get_node("Achievements")
	clock = root.get_node("GameClock")
	calendar = root.get_node("YearCalendar")
	bank = root.get_node("QuestionBank")
	academics = root.get_node("AcademicSession")
	print("- content")
	validate_activities()
	validate_calendar()
	state.start_new_game()
	state.phase = state.Phase.CAMPUS
	state.campus_entry = "med_ed"
	change_scene_to_file("res://world/campus/campus.tscn")
	await acquire_world()
	await ticks(3)
	print("- september")
	await first_weeks()
	print("- white coat")
	await lecture_building()
	print("- block 1 exam")
	await block_one_exam()
	print("- anatomy hall")
	await anatomy_hall()
	print("- emergency department")
	await hospital()
	print("- spring")
	await spring()
	print("- the last day")
	await the_last_day()
	check_stations()
	print("ACTIVITIES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

# --- Content -------------------------------------------------------------------------------------

static func load_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func activity_files() -> Array:
	return Array(DirAccess.get_files_at("res://education/activities")).filter(func(name: String) -> bool: return name.ends_with(".json"))

func validate_activities() -> void:
	var files := activity_files()
	check(files.size() >= 27, "Activity files present (%d)" % files.size())
	for file in files:
		var data: Variant = load_json("res://education/activities/" + file)
		if not data is Dictionary:
			check(false, "Activity parses: " + file)
			continue
		var problems := activity_problems(data, file.get_basename())
		check(problems.is_empty(), "Activity validates: %s %s" % [file, str(problems)])

## What's wrong with an activity (empty when it's usable).
func activity_problems(data: Dictionary, id: String) -> Array:
	var problems: Array = []
	if String(data.get("id", "")) != id:
		problems.append("id doesn't match the file name")
	if not KINDS.has(String(data.get("kind", ""))):
		problems.append("unknown kind")
	for key in ["title", "eyebrow", "intro"]:
		if String(data.get(key, "")).is_empty():
			problems.append("no " + key)
	if int(data.get("minutes", 0)) <= 0:
		problems.append("no minutes")
	if String(data.get("kind", "")) == "exam":
		var questions: Array = data.get("questions", [])
		if questions.size() < 8:
			problems.append("an exam needs at least eight questions")
		for question in questions:
			if bank.get_question(String(question)).is_empty():
				problems.append("unknown question " + String(question))
		if float(data.get("pass", 0)) <= 0.0 or float(data.get("honors", 0)) <= float(data.get("pass", 0)) or float(data.get("honors", 0)) > 1.0:
			problems.append("pass and Honors marks")
		var merit: Dictionary = data.get("merit", {})
		if int(merit.get("pass", 0)) <= 0 or int(merit.get("honors", 0)) <= int(merit.get("pass", 0)):
			problems.append("merit awards")
		return problems
	var steps: Array = data.get("steps", [])
	if steps.size() < 3:
		problems.append("too few steps")
	for step_index in range(steps.size()):
		var step: Dictionary = steps[step_index]
		var kinds := ["say", "figure", "question", "choice", "history", "exam", "recap", "reward"].filter(func(key: String) -> bool: return step.has(key))
		if kinds.size() != 1:
			problems.append("step %d needs exactly one kind" % step_index)
			continue
		match String(kinds[0]):
			"say":
				if String(step.say).is_empty():
					problems.append("step %d says nothing" % step_index)
			"figure":
				var error := FigureArt.validate(step.figure)
				if not error.is_empty():
					problems.append("step %d figure: %s" % [step_index, error])
			"question":
				var question: Dictionary = bank.get_question(String(step.question))
				if question.is_empty():
					problems.append("unknown question " + String(step.question))
				elif question.has("figure") and not FigureArt.validate(question.figure).is_empty():
					problems.append("question figure " + String(step.question))
			"choice":
				var options: Array = step.choice.get("options", [])
				if options.size() < 2 or String(step.choice.get("prompt", "")).is_empty():
					problems.append("step %d choice needs a prompt and options" % step_index)
				for option in options:
					if String(option.get("text", "")).is_empty() or String(option.get("reply", "")).is_empty() or typeof(option.get("score")) not in [TYPE_INT, TYPE_FLOAT]:
						problems.append("step %d option needs text, a reply and a score" % step_index)
			"history", "exam":
				var board: Dictionary = step[kinds[0]]
				var items: Array = board.get("items" if kinds[0] == "history" else "maneuvers", [])
				var keys := items.filter(func(item: Dictionary) -> bool: return item.get("key", false)).size()
				if items.size() < 4 or keys == 0 or keys > int(board.get("limit", 0)) or int(board.get("limit", 0)) >= items.size():
					problems.append("step %d board: %d items, %d key, limit %d" % [step_index, items.size(), keys, int(board.get("limit", 0))])
			"reward":
				if step.reward.has("item") and not preload("res://data/clothing.gd").exists(String(step.reward.item)):
					problems.append("reward item " + String(step.reward.item))
	var feedback: Array = data.get("feedback", [])
	for index in range(1, feedback.size()):
		if float(feedback[index][0]) >= float(feedback[index - 1][0]):
			problems.append("feedback thresholds must fall")
	return problems

func validate_calendar() -> void:
	var files := activity_files().map(func(name: String) -> String: return name.get_basename())
	var used := {}
	var missing: Array = []
	for event in calendar.data.events:
		if Catalog.is_lecture(event):
			continue
		var content := String(event.get("content", event.id))
		if OPEN_EVENTS.has(content):
			continue
		used[content] = true
		if not files.has(content):
			missing.append(event.id)
	check(missing.is_empty(), "Every scheduled activity has its content %s" % str(missing))
	var unused := files.filter(func(name: String) -> bool: return not used.has(name))
	check(unused.is_empty(), "Every activity is on the calendar %s" % str(unused))
	check(calendar.ready_days().size() == calendar.days.size(), "Every story day of the year is playable")
	# An activity's questions belong to its calendar event (so its cards
	# arrive on that day).
	var orphans: Array = []
	for question in bank.records.values():
		if calendar.event(String(question.lecture_id)).is_empty() and not String(question.lecture_id).begins_with("club_") and not Catalog.exists(String(question.lecture_id)):
			orphans.append(question.id)
	check(orphans.is_empty(), "Every question belongs to a lecture, a club or a calendar event %s" % str(orphans))

# --- Stations ------------------------------------------------------------------------------------

func stations_here() -> Array:
	return dorm.find_children("*", "", true, false).filter(func(node: Node) -> bool: return node.get_script() != null and node.get_script().resource_path == STATION_SCRIPT)

func note_stations() -> void:
	for station in stations_here():
		for room in String(station.room).split(",", false):
			station_rooms["%s:%s" % [station.place, room]] = true

func check_stations() -> void:
	var missing: Array = []
	for event in calendar.data.events:
		if Catalog.is_lecture(event) or OPEN_EVENTS.has(String(event.get("content", event.id))):
			continue
		var key := "%s:%s" % [String(event.get("place", "")), String(event.get("room", ""))]
		if not station_rooms.has(key):
			missing.append("%s (%s)" % [event.id, key])
	check(missing.is_empty(), "Every activity event has a station in its room %s" % str(missing))

func station(room: String) -> Node3D:
	for candidate in stations_here():
		if String(candidate.room).split(",", false).has(room):
			return candidate
	return null

## Opens the station's activity at `stamp` and returns its panel (or null).
func open_at(room: String, stamp: String, label: String) -> Control:
	await at_time(stamp)
	wellbeing.energy = 100.0
	var spot := station(room)
	if spot == null:
		check(false, label + ": no station for " + room)
		return null
	spot.refresh()
	check(String(spot.display_name).begins_with("Begin:") and spot.is_in_group("interactables"), "%s: the station offers it (%s)" % [label, spot.display_name])
	spot.activated.emit()
	await ticks(2)
	var panel := modal()
	check(panel != null, label + ": its panel opens")
	return panel

## Plays an activity panel to its debrief: the right answers, the best
## options and every key question and maneuver, or (best = false) the
## opposite.
func play(panel: Control, best := true) -> void:
	await press(panel, "BeginActivity")
	for guard in range(80):
		if panel.stage != "steps":
			break
		var step: Dictionary = panel.steps[panel.index]
		if step.has("question"):
			var right := String(bank.get_question(String(step.question)).correct_answer)
			var key: String = right if best else ["a", "b", "c", "d"].filter(func(candidate: String) -> bool: return candidate != right)[0]
			await press(panel, "Choice_" + key)
		elif step.has("choice"):
			var options: Array = step.choice.options
			var pick := 0
			for option_index in range(options.size()):
				var score := float(options[option_index].score)
				if (best and score > float(options[pick].score)) or (not best and score < float(options[pick].score)):
					pick = option_index
			await press(panel, "Choice_%d" % pick)
		elif best and (step.has("history") or step.has("exam")):
			var items: Array = step.history.items if step.has("history") else step.exam.maneuvers
			for item_index in range(items.size()):
				if items[item_index].get("key", false):
					await press(panel, "Item_%d" % item_index)
		if not await press(panel, "NextStep"):
			await ticks(1)
	check(panel.stage == "results", "The activity reaches its debrief (%s)" % panel.data.get("id", ""))

func finish(panel: Control) -> void:
	await press(panel, "FinishActivity")
	await ticks(2)

## Sits an exam: every answer right, or every answer wrong.
func sit_exam(panel: Control, right := true) -> void:
	await press(panel, "StartQuiz")
	for guard in range(40):
		if panel.screen != "question":
			break
		var answer := String(bank.get_question(String(panel.questions[panel.index])).correct_answer)
		if not right:
			answer = "a" if answer != "a" else "b"
		panel.choose(answer)
		panel.advance()
		await ticks(1)
	check(panel.screen == "summary", "The exam is submitted (%s)" % panel.exam.get("id", ""))

func done(event_id: String) -> bool:
	return calendar.completed(calendar.event(event_id))

# --- Playthroughs --------------------------------------------------------------------------------

## Enters the Medical Education Center (from campus), quiets it and notes its stations.
func enter_med_ed() -> bool:
	if not await go(func() -> void: state.enter_med_ed(), "Enter the Medical Education Center"):
		return false
	await quiet_walkers()
	note_stations()
	return true

func leave_to_campus(entry: String) -> void:
	await go(func() -> void: state.enter_campus(entry), "Back out to campus")

## September: a histology lab and the first standardized patient.
func first_weeks() -> void:
	if not await enter_med_ed():
		return
	# Between events a station only describes the room.
	await at_time("2026-09-28T12:00:00")
	var bench := station("histology")
	check(bench != null and bench.current_event().is_empty() and bench.display_name == "Histology Lab", "Before the lab, the benches are just benches")
	check(not stations_here().filter(func(node: Node3D) -> bool: return node.room == "atrium").front().is_in_group("interactables"), "The atrium's station stays out of the way between events")
	# A histology lab.
	var xp: int = academics.xp_balance
	var panel := await open_at("histology", "2026-09-28T13:20:00", "Histology lab")
	if panel:
		await play(panel)
		check(is_equal_approx(float(panel.summary.score), 1.0) and panel.missed.is_empty(), "Every slide identified")
		check(academics.xp_balance > xp and int(panel.summary.xp) > 0, "The lab's questions earn XP")
		await finish(panel)
	check(done("histology_lab_01") and achievements.stat("labs_completed") == 1, "The lab is done and counted")
	check(clock.now_seconds() >= calendar.end_of(calendar.event("histology_lab_01")), "The clock moves past the end of the lab")
	check(wellbeing.energy < 100.0, "The lab takes energy")
	check(bench.current_event().is_empty(), "A finished lab isn't offered again")
	# A standardized patient.
	panel = await open_at("sim", "2026-10-01T08:55:00", "Standardized patient")
	if panel:
		await play(panel)
		check(panel.scores.has("History") and panel.scores.has("Communication"), "The encounter scores the history and communication")
		await finish(panel)
	check(done("sp_interview_01") and achievements.stat("sp_encounters") == 1 and achievements.has_flag("communication_full"), "The encounter counts, with full marks for communication")
	await leave_to_campus("med_ed")

## October 23: the Block 1 exam, with Honors.
func block_one_exam() -> void:
	if not await enter_med_ed():
		return
	var balance: int = wallet.balance
	var panel := await open_at("testing", "2026-10-23T08:55:00", "Block 1 exam")
	if panel:
		check(panel.questions.size() == 16 and panel.mode() == "exam", "Sixteen questions, in exam mode")
		await sit_exam(panel, true)
		check(panel.outcome == "Honors" and panel.award == 20000, "Honors, and the $200 merit award")
		check(panel.body.find_child("Verdict", true, false) != null, "The verdict heads the results")
		await press(panel, "FinishQuiz")
	check(done("exam_b1") and achievements.stat("exams_passed") == 1 and achievements.stat("exams_honors") == 1, "The exam is done; a pass with Honors is counted")
	check(wallet.balance >= balance + 20000, "The merit award is paid")
	await leave_to_campus("med_ed")

## Spring: the Block 4 exam failed, a small-group case answered badly,
## Research Day and the OSCE.
func spring() -> void:
	if not await enter_med_ed():
		return
	var passed: int = achievements.stat("exams_passed")
	var balance: int = wallet.balance
	var panel := await open_at("testing", "2027-03-26T08:55:00", "Block 4 exam")
	if panel:
		await sit_exam(panel, false)
		check(panel.outcome == "Below the pass mark" and panel.award == 0, "Below the pass mark: no award")
		await press(panel, "FinishQuiz")
	check(done("exam_b4") and achievements.stat("exams_passed") == passed and wallet.balance == balance, "A failed exam is sat but not passed")
	# The nutrition case, answered badly.
	panel = await open_at("pbl", "2027-03-29T13:20:00", "Nutrition case")
	if panel:
		await play(panel, false)
		check(float(panel.summary.score) < 0.3 and not panel.missed.is_empty(), "A poor case scores low and lists what to work on")
		check(panel.body.find_children("*", "Label", true, false).any(func(label: Label) -> bool: return label.text.contains("social determinants")), "The facilitator's comment matches the score")
		await finish(panel)
	check(done("nutrition_case_01"), "The case is done")
	# Research Day in the atrium.
	panel = await open_at("atrium", "2027-04-15T08:55:00", "Research Day")
	if panel:
		await play(panel)
		await finish(panel)
	check(achievements.has_flag("research_day") and done("research_day"), "Research Day is remembered")
	# The OSCE.
	panel = await open_at("sim", "2027-05-20T08:55:00", "OSCE")
	if panel:
		await play(panel)
		await finish(panel)
	check(achievements.has_flag("osce_passed") and achievements.is_unlocked("osce_ready"), "Passing the OSCE unlocks OSCE Ready")
	await leave_to_campus("med_ed")

func anatomy_hall() -> void:
	await at_time("2026-11-02T08:20:00")
	if not await go(func() -> void: state.enter_anatomy(), "Enter Anatomy Hall"):
		return
	await quiet_walkers()
	note_stations()
	var panel := await open_at("theatre", "2026-11-02T08:25:00", "Donor dedication")
	if panel:
		await play(panel)
		await finish(panel)
	check(achievements.has_flag("donor_dedication") and achievements.is_unlocked("gratitude"), "The dedication is remembered")
	# The practical is an exam at your group's table.
	panel = await open_at("lab", "2026-12-10T08:55:00", "Anatomy practical")
	if panel:
		check(panel.get("exam") != null, "The practical is sat as an exam")
		await sit_exam(panel, true)
		await press(panel, "FinishQuiz")
	check(done("anatomy_practical_b2") and achievements.stat("exams_passed") == 2, "The practical is passed")
	await leave_to_campus("anatomy")

func lecture_building() -> void:
	await at_time("2026-10-10T10:40:00")
	if not await go(func() -> void: state.enter_lecture_building(), "Enter the Learning Center"):
		return
	note_stations()
	var panel := await open_at("hall_a", "2026-10-10T10:50:00", "White Coat Ceremony")
	if panel:
		await play(panel)
		await finish(panel)
	check(achievements.has_flag("white_coat") and state.player_look.outfit.get("outerwear", "") == "short_white_coat", "The coat is given and worn")
	await leave_to_campus("lecture_building")

func hospital() -> void:
	await at_time("2027-01-23T17:40:00")
	if not await go(func() -> void: state.enter_hospital(), "Enter University Hospital"):
		return
	note_stations()
	var panel := await open_at("ed", "2027-01-23T17:55:00", "Emergency Department shift")
	if panel:
		await play(panel)
		await finish(panel)
	check(achievements.stat("immersion_shifts") >= 1 and done("immersion_ed_01"), "The immersion shift counts")
	await leave_to_campus("hospital")

func the_last_day() -> void:
	note_stations()
	var panel := await open_at("quad", "2027-05-28T17:55:00", "End-of-year celebration")
	if panel:
		await press(panel, "BeginActivity")
		for guard in range(20):
			if panel.stage != "steps" or panel.steps[panel.index].has("recap"):
				break
			await press(panel, "NextStep")
		var labels: Array = panel.body.find_children("*", "Label", true, false)
		check(labels.any(func(label: Label) -> bool: return label.text == "Block exams passed"), "The recap shows the year in numbers")
		await play(panel)
		await finish(panel)
	check(achievements.has_flag("year_end_celebration"), "The celebration is remembered")
	# The last night: the year is complete, and summer mornings follow.
	await at_time("2027-05-28T22:30:00")
	var summary: Dictionary = calendar.sleep()
	check(achievements.has_flag("year_complete") and achievements.is_unlocked("m1_complete"), "Finishing the last day completes M1")
	check(summary.get("summer", false) and calendar.year_over(), "The year is over: summer break")
	check(calendar.today_date() == "2027-05-29" and clock.snapshot().hour == 7 and clock.snapshot().minute == 30, "The next morning is a free summer day")
	check(String(load("res://data/objectives.gd").current("campus")).begins_with("Summer break"), "The objective says it's the summer break")
	var days: int = achievements.stat("days_completed")
	await at_time("2027-05-29T21:00:00")
	summary = calendar.sleep()
	check(calendar.today_date() == "2027-05-30" and String(summary.title) == "Summer break" and achievements.stat("days_completed") == days, "Summer days follow one another without counting as story days")

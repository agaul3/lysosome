extends "res://ui/quiz_panel.gd"
## The class study group in the library's Room 2: classmates quiz each other
## on the lectures you have attended, the questions you missed first. Once a
## day; it takes an hour of game time and some energy, and leaves a "Study
## Group" boost (+10% learning XP for two hours). The answers themselves earn
## XP like any other practice question (context "flashcard").
const SIZE := 5
const MINUTES := 60
const ENERGY := 8.0
const BOOST_XP := 0.10
const BOOST_MINUTES := 120.0

func _init() -> void:
	var date := YearCalendar.today_date()
	var ran := Achievements.has_flag("study_group:" + date)
	super({
		"eyebrow": "Study group · Room 2",
		"title": "Review with your classmates",
		"intro": "Four classmates are working through practice questions from this block's lectures. They take turns asking; you answer. An hour together, then a two-hour Study Group boost (+10% learning XP)." if not ran else "The group has already met today. They meet again tomorrow.",
		"questions": [] if ran else pick_questions(date),
		"context": "flashcard",
		"prefix": "study:" + date,
		"mode": "practice",
		"start_text": "Join in",
		"done_title": "Good session",
	}, 620.0)

## Up to SIZE questions from the lectures you've completed (no figures, which
## need the slide), the ones you've missed most often first; the rest in a
## daily shuffle.
static func pick_questions(date: String) -> Array:
	var lectures: Array = AcademicSession.lectures_completed.keys().filter(func(id: String) -> bool: return not id.begins_with("hospital_") and not id.begins_with("immersion_"))
	if lectures.is_empty():
		return []
	var missed := {}
	for attempt in AcademicSession.question_history.values():
		var id := String(attempt.get("question_id", ""))
		missed[id] = int(missed.get(id, 0)) + (0 if attempt.get("correct", false) else 2) - (1 if attempt.get("correct", false) else 0)
	var pool: Array = []
	for lecture in lectures:
		for question in QuestionBank.for_lecture(String(lecture)):
			if QuestionBank.standalone(question):
				pool.append(String(question.id))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(date)
	var order := {}
	for id in pool:
		order[id] = rng.randf()
	pool.sort_custom(func(a: String, b: String) -> bool:
		if int(missed.get(a, 0)) != int(missed.get(b, 0)):
			return int(missed.get(a, 0)) > int(missed.get(b, 0))
		return float(order[a]) < float(order[b]))
	return pool.slice(0, SIZE)

func build() -> void:
	super()
	if not questions.is_empty():
		return
	for child in body.get_children():
		if child is Label and (child as Label).text == "There is nothing to review yet.":
			child.text = "" if Achievements.has_flag("study_group:" + YearCalendar.today_date()) else "The group reviews lectures you have attended. Come back after your first lecture."

func show_summary() -> void:
	var date := YearCalendar.today_date()
	if not Achievements.has_flag("study_group:" + date):
		Achievements.set_flag("study_group:" + date)
		Achievements.bump("study_groups")
		Wellbeing.spend(ENERGY, "study group")
		YearCalendar.pass_time(MINUTES)
		Wellbeing.add_boost("social", "Study Group", BOOST_XP, BOOST_MINUTES, "users", "study_group")
		if int(GameClock.snapshot().hour) >= 22 or int(GameClock.snapshot().hour) < 5:
			Achievements.set_flag("library_late")
	super()

func completion_text(_summary: Dictionary) -> String:
	return "An hour well spent. Study Group boost: +%d%% learning XP for %d minutes." % [int(BOOST_XP * 100), int(BOOST_MINUTES)]

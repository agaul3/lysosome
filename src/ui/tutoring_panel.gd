extends "res://ui/quiz_panel.gd"
## A paid shift at the Student Center's Peer Tutoring desk: pre-med and
## post-baccalaureate students bring questions from subjects you've already
## had, and you work through them together. The pay is per question you get
## right (so it reflects what you know), plus a small base; the Tutor perk
## raises it. One shift a day, an hour of game time, open 10 AM to 8 PM.
const SIZE := 6
const MINUTES := 60
const ENERGY := 10.0
const BASE_PAY := 1000
const PAY_PER_CORRECT := 1200
const OPEN_HOUR := 10
const CLOSE_HOUR := 20
var paid := 0

func _init() -> void:
	var date := YearCalendar.today_date()
	var hour := int(GameClock.snapshot().hour)
	var worked := Achievements.has_flag("tutoring:" + date)
	var intro := "Pre-med students from the post-bacc program come with questions from your first-year subjects. Answer well and explain it: $%d for each question you get right, plus $%d for the shift. About an hour." % [PAY_PER_CORRECT / 100, BASE_PAY / 100]
	var questions: Array = []
	if worked:
		intro = "You've already worked today's shift. Come back tomorrow."
	elif hour < OPEN_HOUR or hour >= CLOSE_HOUR:
		intro = "The Peer Tutoring desk is open from 10 AM to 8 PM."
	else:
		questions = pick_questions(date)
	super({
		"eyebrow": "Peer Tutoring",
		"title": "Tutoring shift",
		"intro": intro,
		"questions": questions,
		"context": "tutoring",
		"prefix": "tutor:" + date,
		"mode": "practice",
		"start_text": "Start the shift",
		"done_title": "Shift complete",
	}, 620.0)

## Questions from lectures you've completed, a different daily mix from the
## study group's (no figures).
static func pick_questions(date: String) -> Array:
	var pool: Array = []
	for lecture in AcademicSession.lectures_completed:
		if String(lecture).begins_with("hospital_") or String(lecture).begins_with("immersion_"):
			continue
		for question in QuestionBank.for_lecture(String(lecture)):
			if QuestionBank.standalone(question):
				pool.append(String(question.id))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("tutor:" + date)
	for index in range(pool.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: String = pool[index]
		pool[index] = pool[other]
		pool[other] = swap
	return pool.slice(0, SIZE)

func build() -> void:
	super()
	if questions.is_empty():
		for child in body.get_children():
			if child is Label and (child as Label).text == "There is nothing to review yet.":
				child.text = "" if not String(config.intro).begins_with("Pre-med") else "You can tutor subjects once you've had their lectures."

func show_question() -> void:
	super()
	var prompt := body.get_node_or_null("Prompt") as Label
	if prompt:
		prompt.text = "Your student asks: " + prompt.text

func show_summary() -> void:
	var date := YearCalendar.today_date()
	if not Achievements.has_flag("tutoring:" + date):
		Achievements.set_flag("tutoring:" + date)
		var correct := results.filter(func(result: Dictionary) -> bool: return result.get("correct", false)).size()
		Wellbeing.spend(ENERGY, "tutoring")
		YearCalendar.pass_time(MINUTES)
		paid = Wallet.earn(BASE_PAY + PAY_PER_CORRECT * correct, "Peer Tutoring · shift pay", "tutoring")
		Achievements.bump("tutoring_shifts")
	super()

func completion_text(summary_data: Dictionary) -> String:
	return "Paid %s for the shift (%d of %d explained correctly)." % [preload("res://data/items.gd").format_money(paid), int(summary_data.correct), int(summary_data.total)]

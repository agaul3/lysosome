extends "res://ui/quiz_panel.gd"
## A block exam (or the anatomy practical) in the Testing Center:
## education/activities/<id>.json of kind "exam" gives the questions, the time
## (per question, stretched by Test-Taking Strategy and the question bank
## subscription), the pass mark and Honors, and the merit awards. Answers can
## be changed until you submit; unanswered questions count as wrong. The
## result: Pass (with Honors at 90%) or a fail with a plan to review, the
## discipline breakdown, the award, and the exam marked done on the calendar.
var exam := {}
var entry := {}
var outcome := ""
var award := 0

func _init(activity: Dictionary, event: Dictionary = {}) -> void:
	exam = activity
	entry = event
	var questions: Array = activity.get("questions", [])
	var seconds := float(activity.get("seconds_per_question", 75)) * questions.size() * (1.0 + Skills.effect("exam:time"))
	super({
		"eyebrow": String(activity.get("eyebrow", "Testing Center")),
		"title": String(activity.get("title", "Examination")),
		"intro": String(activity.get("intro", "")),
		"questions": questions,
		"context": "exam",
		"prefix": "exam:%s:%s" % [String(activity.get("id", "")), String(event.get("date", YearCalendar.today_date()))],
		"mode": "exam",
		"time_limit": seconds,
		"start_text": "Begin the exam",
		"done_title": String(activity.get("title", "Examination")),
	}, 720.0)

func begin() -> void:
	if not entry.is_empty():
		AcademicSession.record_arrival(String(entry.id))
	super()

func show_summary() -> void:
	# Grade first (the base class builds the summary), then add the verdict.
	super()
	var percent := float(summary.percent) / 100.0
	var pass_mark := float(exam.get("pass", 0.7))
	var honors_mark := float(exam.get("honors", 0.9))
	var merit: Dictionary = exam.get("merit", {})
	if percent >= honors_mark:
		outcome = "Honors"
		award = Wallet.earn(int(merit.get("honors", 0)), "Merit award · %s (Honors)" % exam.get("title", "exam"), "award")
		Achievements.bump("exams_passed")
		Achievements.bump("exams_honors")
	elif percent >= pass_mark:
		outcome = "Pass"
		award = Wallet.earn(int(merit.get("pass", 0)), "Merit award · %s" % exam.get("title", "exam"), "award")
		Achievements.bump("exams_passed")
	else:
		outcome = "Below the pass mark"
	if exam.has("pass_flag") and percent >= pass_mark:
		Achievements.set_flag(String(exam.pass_flag))
	Wellbeing.spend(float(exam.get("energy", 15)), "exam")
	var end := GameClock.now_seconds() + float(exam.get("minutes", 60)) * 60.0
	if not entry.is_empty():
		YearCalendar.mark_completed(String(entry.id))
		end = maxf(end, YearCalendar.end_of(entry))
	YearCalendar.advance_to(end)
	var verdict := UI.label(outcome, UI.SIZE_HEADING, UI.SUCCESS if outcome != "Below the pass mark" else UI.DANGER, 600)
	verdict.name = "Verdict"
	body.add_child(verdict)
	body.move_child(verdict, 0)
	if award > 0:
		var money := UI.label("Merit award  +" + preload("res://data/items.gd").format_money(award), UI.SIZE_BODY, UI.SUCCESS, 600)
		body.add_child(money)
		body.move_child(money, 1)

func completion_text(result: Dictionary) -> String:
	var percent := float(result.percent)
	if percent >= float(exam.get("honors", 0.9)) * 100.0:
		return String(exam.get("honors_text", "Honors. The course director emails the class: the top of the distribution was yours."))
	if percent >= float(exam.get("pass", 0.7)) * 100.0:
		return String(exam.get("pass_text", "Pass. Block done: time to breathe, then start the next one."))
	return String(exam.get("fail_text", "Below the pass mark. The course director will meet with you to plan your review. Every question from this exam is now in your flashcards: work through them before the next block."))

extends "res://ui/modal_panel.gd"
## A run of bank questions in a dialog: study groups, tutoring shifts, club
## quizzes and block exams all use it.
##   practice  each answer is graded at once, with the explanation
##   exam      answers are chosen (and can be changed) with no feedback,
##             then submitted together; the results come at the end
## Answers go through QuestionBank.submit() with this run's context (so XP,
## boosts and perks work as everywhere else) and attempt IDs from `prefix`,
## so a run can never be scored twice. Figures come from ui/figure_art.gd.
## Keys 1–5 (or A–E) choose; Enter moves on.
signal finished(summary: Dictionary)
const FigureArt = preload("res://ui/figure_art.gd")
var config := {}
var questions: Array = []
var index := 0
var answers := {}
var results: Array = []
var summary := {}
var screen := "intro"
var time_left := 0.0
var timer_label: Label
var choice_buttons: Array[Button] = []
var next_button: Button
var feedback: Label
var graded := false

## config: {eyebrow, title, intro, questions (ids), context, prefix,
## mode ("practice" | "exam"), time_limit (seconds, 0 for none),
## start_text, minutes (clock time the whole run takes)}
func _init(run: Dictionary = {}, panel_width := 640.0) -> void:
	super(panel_width)
	config = run

func build() -> void:
	questions = config.get("questions", []).filter(func(id: String) -> bool: return not QuestionBank.get_question(id).is_empty())
	dismissible = mode() == "practice"
	show_intro()

func mode() -> String:
	return String(config.get("mode", "practice"))

func _clear() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	choice_buttons.clear()

# --- Intro ------------------------------------------------------------------------------------

func show_intro() -> void:
	screen = "intro"
	_clear()
	set_heading(String(config.get("eyebrow", "Review")), String(config.get("title", "Questions")))
	add_text(String(config.get("intro", "")))
	if questions.is_empty():
		add_text("There is nothing to review yet.", UI.TEXT_FAINT, UI.SIZE_LABEL)
		add_button("Close", close, true)
		return
	var facts := "%d questions" % questions.size()
	if float(config.get("time_limit", 0.0)) > 0.0:
		facts += " · %d minutes" % int(round(float(config.time_limit) / 60.0))
	add_text(facts, UI.TEXT_FAINT, UI.SIZE_LABEL)
	if dismissible:
		add_button("Not now", close)
	var start := add_button(String(config.get("start_text", "Start")), begin, true)
	start.name = "StartQuiz"

func begin() -> void:
	index = 0
	time_left = float(config.get("time_limit", 0.0))
	dismissible = false
	show_question()

# --- Questions --------------------------------------------------------------------------------

func show_question() -> void:
	screen = "question"
	graded = false
	_clear()
	var question := QuestionBank.get_question(String(questions[index]))
	set_heading("%s · Question %d of %d" % [String(config.get("eyebrow", "Review")), index + 1, questions.size()], String(question.get("topic", "")))
	if time_left > 0.0:
		timer_label = UI.label("", UI.SIZE_LABEL, UI.REWARD, 600)
		body.add_child(timer_label)
		_update_timer()
	var prompt := add_text(String(question.prompt), UI.TEXT, UI.SIZE_BODY)
	prompt.name = "Prompt"
	if question.has("figure") and FigureArt.validate(question.figure).is_empty():
		var figure := Control.new()
		figure.name = "Figure"
		figure.custom_minimum_size = Vector2(width - 52, 210)
		var data: Dictionary = question.figure
		figure.draw.connect(func() -> void:
			figure.draw_rect(Rect2(Vector2.ZERO, figure.size), Color(UI.INK, 0.7))
			FigureArt.draw(figure, data, Rect2(Vector2(10, 8), figure.size - Vector2(20, 16)), 0.8))
		body.add_child(figure)
	var keys: Array = question.choices.keys()
	keys.sort()
	for key in keys:
		var button := Button.new()
		button.name = "Choice_" + String(key)
		button.text = "%s.  %s" % [key, question.choices[key]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(width - 52, 36)
		button.toggle_mode = mode() == "exam"
		button.set_meta("key", key)
		button.pressed.connect(choose.bind(String(key)))
		body.add_child(button)
		choice_buttons.append(button)
		if answers.get(index, "") == key:
			button.button_pressed = true
	feedback = UI.paragraph("", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	feedback.name = "Feedback"
	body.add_child(feedback)
	if mode() == "exam":
		if index > 0:
			add_button("Back", func() -> void:
				index -= 1
				show_question())
		next_button = add_button("Submit exam" if index == questions.size() - 1 else "Next", advance, true)
		next_button.name = "NextQuestion"
		next_button.disabled = not answers.has(index)
	else:
		next_button = add_button("Finish" if index == questions.size() - 1 else "Next", advance, true)
		next_button.name = "NextQuestion"
		next_button.disabled = true
	_focus_first.call_deferred()

## Picks an answer: graded now in practice, remembered in an exam.
func choose(key: String) -> void:
	if screen != "question" or graded:
		return
	if mode() == "exam":
		answers[index] = key
		for button in choice_buttons:
			button.set_pressed_no_signal(String(button.get_meta("key")) == key)
		next_button.disabled = false
		return
	var id := String(questions[index])
	var result := QuestionBank.submit(id, key, "%s:%d:%s" % [String(config.get("prefix", "quiz")), index, id], String(config.get("context", "flashcard")))
	if not result.get("valid", false):
		return
	graded = true
	results.append(result)
	for button in choice_buttons:
		var this_key := String(button.get_meta("key"))
		button.disabled = true
		if this_key == String(result.correct_answer):
			button.add_theme_color_override("font_disabled_color", UI.SUCCESS)
		elif this_key == key:
			button.add_theme_color_override("font_disabled_color", UI.DANGER)
	feedback.add_theme_color_override("font_color", UI.SUCCESS if result.correct else UI.DANGER)
	feedback.text = ("Correct. +%d XP. " % int(result.xp_reward) if result.correct else "Not quite: the answer is %s. " % result.correct_answer) + String(result.explanation)
	Sfx.play("correct" if result.correct else "incorrect")
	next_button.disabled = false
	next_button.grab_focus()

func advance() -> void:
	if screen != "question":
		return
	if mode() == "practice" and not graded:
		return
	if mode() == "exam" and not answers.has(index):
		return
	if index < questions.size() - 1:
		index += 1
		show_question()
	else:
		submit_all() if mode() == "exam" else show_summary()

## Exam: grade every answer at once (unanswered questions count as wrong).
func submit_all() -> void:
	for position in range(questions.size()):
		var id := String(questions[position])
		var key: String = answers.get(position, "")
		if key.is_empty():
			var question := QuestionBank.get_question(id)
			results.append({"valid": true, "question_id": id, "correct": false, "correct_answer": question.correct_answer, "explanation": question.explanation, "xp_reward": 0, "unanswered": true})
			continue
		var result := QuestionBank.submit(id, key, "%s:%d:%s" % [String(config.get("prefix", "exam")), position, id], String(config.get("context", "exam")))
		if result.get("valid", false):
			results.append(result)
	show_summary()

# --- Results ----------------------------------------------------------------------------------

func show_summary() -> void:
	screen = "summary"
	_clear()
	var correct := 0
	var xp := 0
	var by_discipline := {}
	for result in results:
		var question := QuestionBank.get_question(String(result.question_id))
		var discipline := String(question.get("discipline", "General"))
		if not by_discipline.has(discipline):
			by_discipline[discipline] = [0, 0]
		by_discipline[discipline][1] += 1
		if result.correct:
			correct += 1
			by_discipline[discipline][0] += 1
		xp += int(result.get("xp_reward", 0))
	var total := maxi(1, results.size())
	summary = {"answered": results.size(), "correct": correct, "total": questions.size(), "xp": xp, "percent": float(correct) / float(total) * 100.0, "by_discipline": by_discipline, "results": results.duplicate(true)}
	set_heading(String(config.get("eyebrow", "Review")), String(config.get("done_title", "Session complete")))
	var score := UI.label("%d / %d correct" % [correct, questions.size()], UI.SIZE_HEADING, UI.TEXT, 600)
	score.name = "Score"
	body.add_child(score)
	if xp > 0:
		body.add_child(UI.label("+%d XP" % xp, UI.SIZE_TITLE, UI.REWARD, 600))
	for discipline in by_discipline:
		var pair: Array = by_discipline[discipline]
		body.add_child(UI.label("%s   %d / %d" % [discipline, pair[0], pair[1]], UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	var extra := completion_text(summary)
	if not extra.is_empty():
		add_text(extra, UI.TEXT, UI.SIZE_BODY)
	var done := add_button("Continue", func() -> void:
		finished.emit(summary)
		close(), true)
	done.name = "FinishQuiz"
	dismissible = false

## What the run gave beyond XP (boosts, pay, results); subclasses fill it in.
func completion_text(_summary: Dictionary) -> String:
	return ""

func _process(delta: float) -> void:
	if screen != "question" or float(config.get("time_limit", 0.0)) <= 0.0:
		return
	time_left -= delta
	_update_timer()
	if time_left <= 0.0:
		time_left = 0.0
		submit_all() if mode() == "exam" else show_summary()

func _update_timer() -> void:
	if is_instance_valid(timer_label):
		var seconds := int(ceil(maxf(0.0, time_left)))
		timer_label.text = "Time left  %d:%02d" % [seconds / 60, seconds % 60]

func _unhandled_input(event: InputEvent) -> void:
	if screen == "question" and event is InputEventKey and event.pressed and not event.echo:
		var number: int = event.keycode - KEY_1
		var letter: int = event.keycode - KEY_A
		var pick := number if number >= 0 and number < choice_buttons.size() else (letter if letter >= 0 and letter < choice_buttons.size() else -1)
		if pick >= 0 and not choice_buttons[pick].disabled:
			choose(String(choice_buttons[pick].get_meta("key")))
			get_viewport().set_input_as_handled()
			return
	super(event)

extends "res://ui/modal_panel.gd"
## Runs a scheduled activity from education/activities/<id>.json: a lab, a
## standardized-patient encounter, a small-group case, a ceremony or a
## Clinical Immersion shift. An activity is a list of steps:
##   {"say": text, "speaker": name}           narration or dialogue
##   {"figure": {...}, "caption": text}       a figure (ui/figure_art.gd):
##                                            a micrograph, an ECG strip…
##   {"question": bank id, "lead": text}      a graded question (XP in the
##                                            activity's context)
##   {"choice": {prompt, options: [{text,     a decision, often how you speak
##     reply, score}], category}}             to a patient; scored 0–2
##   {"history": {patient, limit, items:      take a history: ask up to
##     [{category, ask, answer, key}]}}       `limit` questions; key ones count
##   {"exam": {limit, maneuvers: [{name,      examine: up to `limit`
##     finding, key}]}}                       maneuvers; key ones count
##   {"reward": {flag, item, wear}}           marks a moment (a flag for an
##                                            achievement, clothing given)
##   {"recap": true}                          the student's year in numbers
## The debrief scores each part, lists what was missed, and the faculty
## comment for the score. XP comes only from the questions; a scheduled
## activity is marked done on the calendar. Time and energy pass at the end.
signal finished(summary: Dictionary)
const FigureArt = preload("res://ui/figure_art.gd")
var data := {}
var entry := {}
var steps: Array = []
var index := 0
var stage := "intro"
## Parts scored: category -> [earned, possible].
var scores := {}
var question_results: Array = []
var missed: Array = []
var asked := {}
var examined := {}
var transcript: VBoxContainer
var feedback: Label
var next_button: Button
var choice_buttons: Array[Button] = []
var graded := false
var summary := {}

## `activity` is the parsed JSON; `event` the calendar entry it's for ({} if none).
func _init(activity: Dictionary, event: Dictionary = {}) -> void:
	super(700.0)
	data = activity
	entry = event
	steps = data.get("steps", [])

static func load_activity(id: String) -> Dictionary:
	var path := "res://education/activities/%s.json" % id
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func context() -> String:
	return String(data.get("context", "lecture"))

func build() -> void:
	set_heading(String(data.get("eyebrow", "Activity")), String(data.get("title", "")))
	add_text(String(data.get("intro", "")), UI.TEXT, UI.SIZE_BODY)
	var facts: Array = []
	if data.has("minutes"):
		facts.append("About %d minutes" % int(data.minutes))
	if data.has("energy"):
		facts.append("Energy −%d" % int(data.energy))
	if not facts.is_empty():
		add_text(" · ".join(facts), UI.TEXT_FAINT, UI.SIZE_LABEL)
	add_button("Not now", close)
	var start := add_button(String(data.get("start_text", "Begin")), begin, true)
	start.name = "BeginActivity"

func begin() -> void:
	dismissible = false
	stage = "steps"
	if not entry.is_empty():
		# Arriving counts as attending (late if after the start).
		AcademicSession.record_arrival(String(entry.id))
	index = 0
	show_step()

func _clear() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	choice_buttons.clear()

func _score(category: String, earned: float, possible: float) -> void:
	var pair: Array = scores.get(category, [0.0, 0.0])
	scores[category] = [float(pair[0]) + earned, float(pair[1]) + possible]

func show_step() -> void:
	if index >= steps.size():
		finish()
		return
	_clear()
	graded = false
	var step: Dictionary = steps[index]
	set_heading("%s · %d of %d" % [String(data.get("eyebrow", "Activity")), index + 1, steps.size()], String(step.get("heading", data.get("title", ""))))
	if step.has("say"):
		if step.has("speaker"):
			body.add_child(UI.label(String(step.speaker), UI.SIZE_LABEL, UI.ACCENT, 600))
		add_text(String(step.say), UI.TEXT, UI.SIZE_BODY)
		_next("Continue")
	elif step.has("figure"):
		_figure(step.figure, 300)
		if step.has("caption"):
			add_text(String(step.caption), UI.TEXT_MUTED, UI.SIZE_LABEL)
		_next("Continue")
	elif step.has("question"):
		_question(step)
	elif step.has("choice"):
		_choice(step.choice)
	elif step.has("history"):
		_history(step.history)
	elif step.has("exam"):
		_exam(step.exam)
	elif step.has("recap"):
		_recap()
		_next("Continue")
	elif step.has("reward"):
		_reward(step.reward)
		index += 1
		show_step()
		return
	else:
		index += 1
		show_step()
		return
	_focus_first.call_deferred()

func _next(text: String) -> void:
	next_button = add_button(text, advance, true)
	next_button.name = "NextStep"

func advance() -> void:
	if stage != "steps":
		return
	var step: Dictionary = steps[index]
	if (step.has("question") or step.has("choice")) and not graded:
		return
	if step.has("history"):
		_score_history(step.history)
	elif step.has("exam"):
		_score_exam(step.exam)
	index += 1
	show_step()

func _figure(figure: Dictionary, height: float) -> void:
	var canvas := Control.new()
	canvas.name = "Figure"
	canvas.custom_minimum_size = Vector2(width - 52, height)
	canvas.draw.connect(func() -> void:
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(UI.INK, 0.7))
		FigureArt.draw(canvas, figure, Rect2(Vector2(10, 8), canvas.size - Vector2(20, 16)), 0.8))
	body.add_child(canvas)

# --- Questions -----------------------------------------------------------------------------------

func _question(step: Dictionary) -> void:
	var question := QuestionBank.get_question(String(step.question))
	if question.is_empty():
		index += 1
		show_step.call_deferred()
		return
	if step.has("lead"):
		body.add_child(UI.label(String(step.lead), UI.SIZE_LABEL, UI.ACCENT, 600))
	if question.has("figure") and FigureArt.validate(question.figure).is_empty():
		_figure(question.figure, 230)
	var prompt := add_text(String(question.prompt), UI.TEXT, UI.SIZE_BODY)
	prompt.name = "Prompt"
	var keys: Array = question.choices.keys()
	keys.sort()
	for key in keys:
		_choice_button("%s.  %s" % [key, question.choices[key]], String(key), _answer)
	feedback = UI.paragraph("", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	feedback.name = "Feedback"
	body.add_child(feedback)
	_next("Continue")
	next_button.disabled = true

func _choice_button(text: String, key: String, action: Callable) -> void:
	var button := Button.new()
	button.name = "Choice_" + key
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(width - 52, 34)
	button.set_meta("key", key)
	button.pressed.connect(action.bind(key))
	body.add_child(button)
	choice_buttons.append(button)

## Answers the current question step.
func _answer(key: String) -> void:
	if graded:
		return
	var step: Dictionary = steps[index]
	var id := String(step.question)
	var attempt := "activity:%s:%s:%d:%s" % [String(data.get("id", "")), String(entry.get("date", YearCalendar.today_date())), index, id]
	var result := QuestionBank.submit(id, key, attempt, context())
	if not result.get("valid", false):
		return
	graded = true
	question_results.append(result)
	_score(String(step.get("category", "Questions")), 1.0 if result.correct else 0.0, 1.0)
	if not result.correct:
		missed.append(String(QuestionBank.get_question(id).get("learning_objective", "")))
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

# --- Choices -------------------------------------------------------------------------------------

func _choice(choice: Dictionary) -> void:
	add_text(String(choice.get("prompt", "")), UI.TEXT, UI.SIZE_BODY)
	var options: Array = choice.get("options", [])
	for option_index in range(options.size()):
		_choice_button(String(options[option_index].text), str(option_index), _pick)
	feedback = UI.paragraph("", width - 52, UI.SIZE_BODY, UI.TEXT)
	feedback.name = "Feedback"
	body.add_child(feedback)
	_next("Continue")
	next_button.disabled = true

func _pick(key: String) -> void:
	if graded:
		return
	graded = true
	var choice: Dictionary = steps[index].choice
	var options: Array = choice.options
	var option: Dictionary = options[int(key)]
	var best := 0.0
	for candidate in options:
		best = maxf(best, float(candidate.get("score", 0)))
	var earned := float(option.get("score", 0))
	_score(String(choice.get("category", "Communication")), earned, best)
	if earned < best and choice.has("lesson"):
		missed.append(String(choice.lesson))
	for button in choice_buttons:
		button.disabled = true
		if button.get_meta("key") == key:
			button.add_theme_color_override("font_disabled_color", UI.SUCCESS if earned >= best else (UI.REWARD if earned > 0.0 else UI.DANGER))
	feedback.text = String(option.get("reply", ""))
	next_button.disabled = false
	next_button.grab_focus()

# --- History and examination ---------------------------------------------------------------------

func _history(history: Dictionary) -> void:
	var limit := int(history.get("limit", 10))
	add_text("%s  ·  Ask up to %d questions, then move on." % [String(history.get("patient", "The patient")), limit], UI.TEXT_MUTED, UI.SIZE_LABEL)
	if history.has("opening"):
		add_text(String(history.opening), UI.TEXT, UI.SIZE_BODY)
	var hints := int(Skills.effect("clinical:hints"))
	_board(history.get("items", []), "ask", "answer", limit, asked, hints)
	_next("Done asking")

func _exam(exam: Dictionary) -> void:
	var limit := int(exam.get("limit", 5))
	add_text("Choose up to %d parts of the examination." % limit, UI.TEXT_MUTED, UI.SIZE_LABEL)
	_board(exam.get("maneuvers", []), "name", "finding", limit, examined, 0)
	_next("Done examining")

## Buttons for the questions (or maneuvers), grouped by category, and a
## transcript of what the patient says (or what you find).
func _board(items: Array, label_key: String, reply_key: String, limit: int, taken: Dictionary, hints: int) -> void:
	taken.clear()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width - 52, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var category := ""
	var hinted := 0
	for item_index in range(items.size()):
		var item: Dictionary = items[item_index]
		if String(item.get("category", "")) != category:
			category = String(item.get("category", ""))
			if not category.is_empty():
				column.add_child(UI.label(category.to_upper(), UI.SIZE_CAPTION, UI.TEXT_FAINT, 600, true))
		var button := Button.new()
		button.name = "Item_%d" % item_index
		var hint: bool = item.get("key", false) and hinted < hints
		if hint:
			hinted += 1
		button.text = ("★ " if hint else "") + String(item[label_key])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(width - 80, 30)
		button.pressed.connect(func() -> void:
			if taken.size() >= limit or taken.has(item_index):
				return
			taken[item_index] = true
			button.disabled = true
			var line := UI.paragraph("%s  —  %s" % [String(item[label_key]), String(item[reply_key])], width - 60, UI.SIZE_LABEL, UI.TEXT)
			transcript.add_child(line)
			transcript.move_child(line, 0)
			if taken.size() >= limit:
				for other in column.get_children():
					if other is Button:
						(other as Button).disabled = true)
		column.add_child(button)
	transcript = VBoxContainer.new()
	transcript.name = "Transcript"
	transcript.add_theme_constant_override("separation", 4)
	body.add_child(transcript)

func _score_history(history: Dictionary) -> void:
	var items: Array = history.get("items", [])
	var keys := 0
	var got := 0
	for item_index in range(items.size()):
		if items[item_index].get("key", false):
			keys += 1
			if asked.has(item_index):
				got += 1
			else:
				missed.append("Ask: " + String(items[item_index].ask))
	_score("History", got, keys)

func _score_exam(exam: Dictionary) -> void:
	var maneuvers: Array = exam.get("maneuvers", [])
	var keys := 0
	var got := 0
	for item_index in range(maneuvers.size()):
		if maneuvers[item_index].get("key", false):
			keys += 1
			if examined.has(item_index):
				got += 1
			else:
				missed.append("Examine: " + String(maneuvers[item_index].name))
	_score("Examination", got, keys)

## The year in numbers: lectures, questions, level, exams, clubs, service.
func _recap() -> void:
	var lectures := Achievements.stat("lectures_completed")
	var accuracy := 0 if AcademicSession.attempted == 0 else int(round(100.0 * AcademicSession.correct / AcademicSession.attempted))
	var rows := [
		["Level", "%d · %s" % [AcademicSession.level, Skills.title()]],
		["Lectures completed", str(lectures)],
		["Questions answered", "%d (%d%% correct)" % [AcademicSession.attempted, accuracy]],
		["Flashcards reviewed", str(Achievements.stat("flashcards_reviewed"))],
		["Block exams passed", "%d (%d with Honors)" % [Achievements.stat("exams_passed"), Achievements.stat("exams_honors")]],
		["Patient encounters", str(Achievements.stat("sp_encounters"))],
		["Club meetings", str(Achievements.stat("club_events"))],
		["Meals served on Harbor Street", str(Achievements.stat("meals_served"))],
		["Achievements", "%d of %d" % [Achievements.unlocked_count(), preload("res://data/achievements.gd").ACHIEVEMENTS.size()]],
	]
	for row in rows:
		var line := HBoxContainer.new()
		var label := UI.label(String(row[0]), UI.SIZE_BODY, UI.TEXT_MUTED, 500)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		line.add_child(UI.label(String(row[1]), UI.SIZE_BODY, UI.TEXT, 600))
		body.add_child(line)

func _reward(reward: Dictionary) -> void:
	if reward.has("flag"):
		Achievements.set_flag(String(reward.flag))
	if reward.has("item"):
		Wallet.grant_clothing(String(reward.item))
		if reward.get("wear", false):
			var slot := preload("res://data/clothing.gd").slot_of(String(reward.item))
			AppState.equip(slot, String(reward.item))

# --- Debrief -------------------------------------------------------------------------------------

func overall() -> float:
	var earned := 0.0
	var possible := 0.0
	for category in scores:
		earned += float(scores[category][0])
		possible += float(scores[category][1])
	return earned / possible if possible > 0.0 else 1.0

func finish() -> void:
	stage = "results"
	_clear()
	var score := overall()
	var xp := 0
	for result in question_results:
		xp += int(result.get("xp_reward", 0))
	# Time and energy for the whole activity.
	Wellbeing.spend(float(data.get("energy", 0)), "activity")
	var end := GameClock.now_seconds() + float(data.get("minutes", 30)) * 60.0
	if not entry.is_empty():
		end = maxf(end, YearCalendar.end_of(entry))
		YearCalendar.mark_completed(String(entry.id))
	YearCalendar.advance_to(end)
	var kind := String(data.get("kind", ""))
	match kind:
		"encounter":
			Achievements.bump("sp_encounters")
			if scores.has("Communication") and float(scores.Communication[0]) >= float(scores.Communication[1]) and float(scores.Communication[1]) > 0.0:
				Achievements.set_flag("communication_full")
		"immersion":
			Achievements.bump("immersion_shifts")
		"lab":
			Achievements.bump("labs_completed")
	if data.has("pass_flag") and score >= float(data.get("pass_score", 0.7)):
		Achievements.set_flag(String(data.pass_flag))
	summary = {"score": score, "scores": scores.duplicate(true), "xp": xp, "missed": missed.duplicate()}
	set_heading(String(data.get("eyebrow", "Activity")), String(data.get("done_title", "Debrief")))
	if not scores.is_empty():
		body.add_child(UI.label("Overall  %d%%" % int(round(score * 100.0)), UI.SIZE_HEADING, UI.TEXT, 600))
		for category in scores:
			var pair: Array = scores[category]
			body.add_child(UI.label("%s   %d / %d" % [category, int(pair[0]), int(pair[1])], UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	if xp > 0:
		body.add_child(UI.label("+%d XP" % xp, UI.SIZE_TITLE, UI.REWARD, 600))
	var comments: Array = data.get("feedback", [])
	var comment := ""
	for pair in comments:
		if score >= float(pair[0]):
			comment = String(pair[1])
			break
	if not comment.is_empty():
		add_text(comment, UI.TEXT, UI.SIZE_BODY)
	if not missed.is_empty():
		add_text("To work on: " + "; ".join(missed.slice(0, 4)) + ".", UI.TEXT_MUTED, UI.SIZE_LABEL)
	var done := add_button("Done", func() -> void:
		finished.emit(summary)
		close(), true)
	done.name = "FinishActivity"
	dismissible = true
	_focus_first.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if stage == "steps" and event is InputEventKey and event.pressed and not event.echo and not choice_buttons.is_empty():
		var pick: int = event.keycode - KEY_1 if event.keycode >= KEY_1 and event.keycode <= KEY_5 else -1
		if pick >= 0 and pick < choice_buttons.size() and not choice_buttons[pick].disabled:
			choice_buttons[pick].pressed.emit()
			get_viewport().set_input_as_handled()
			return
	super(event)

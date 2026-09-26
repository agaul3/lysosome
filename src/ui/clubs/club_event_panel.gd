extends "res://ui/modal_panel.gd"
## A club meeting (data/clubs.gd): an introduction, the club's hands-on
## activity (a subclass: serving supper, taking blood pressures, suturing,
## CPR, penalty kicks…), then a few questions from the club's part of the
## question bank (context "club": the only XP a meeting gives, so XP still
## measures what you know), and the results: reputation, level and rewards
## (Clubs.record). The meeting takes its time (to the end of the meeting,
## at least half an hour) and energy.
const Data = preload("res://data/clubs.gd")
const Items = preload("res://data/items.gd")
var club_id := ""
var club := {}
var stage := "intro"
## The activity's score, 0–1, and a line describing how it went.
var activity_score := 0.0
var activity_summary := ""
var questions: Array = []
var question_index := 0
var question_results: Array = []
var choice_buttons: Array[Button] = []
var next_button: Button
var feedback: Label
var graded := false
var result := {}
## Set for an open volunteer event on the calendar (the Thanksgiving supper):
## anyone can take part, it's marked done on the calendar, and there's no
## club reputation.
var event_id := ""

func _init(id: String) -> void:
	super(660.0)
	club_id = id
	club = Data.get_club(id)

# --- For subclasses ------------------------------------------------------------------------------

func activity_title() -> String:
	return String(club.get("name", "Club meeting"))

func activity_intro() -> String:
	return String(club.get("pitch", ""))

## Energy the meeting costs.
func energy_cost() -> float:
	return 8.0

## Bank question ids asked after the activity (a few, by date).
func question_pool() -> Array:
	return QuestionBank.for_lecture("club_" + club_id).map(func(question: Dictionary) -> String: return String(question.id))

func questions_per_meeting() -> int:
	return 2

## Builds the activity in `body`; call activity_done(score, summary) at the end.
func start_activity() -> void:
	activity_done(1.0, "")

## Anything extra once the meeting is recorded (a boost, meals served…).
func on_recorded(_record: Dictionary) -> void:
	pass

# --- Flow ----------------------------------------------------------------------------------------

func build() -> void:
	show_intro()

func _clear() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	choice_buttons.clear()

func show_intro() -> void:
	stage = "intro"
	_clear()
	set_heading(String(club.get("short", "Club")), activity_title())
	add_text(activity_intro(), UI.TEXT, UI.SIZE_BODY)
	var end := _end_time()
	add_text("Energy −%d · %s%s" % [int(energy_cost()), "the rest of the meeting" if event_id.is_empty() else "the rest of the evening", "" if end <= 0.0 else ", until " + Clubs._clock(end)], UI.TEXT_FAINT, UI.SIZE_LABEL)
	add_button("Not now", close)
	var start := add_button("Start", begin, true)
	start.name = "StartEvent"

func begin() -> void:
	stage = "activity"
	dismissible = false
	_clear()
	set_heading(String(club.get("short", "Club")), activity_title())
	start_activity()

func activity_done(score: float, summary := "") -> void:
	if stage != "activity":
		return
	activity_score = clampf(score, 0.0, 1.0)
	activity_summary = summary
	var pool := question_pool()
	if pool.is_empty():
		finish()
		return
	# A different few each meeting, the same few if you reload the day.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%s" % [club_id, YearCalendar.today_date()])
	for index in range(pool.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: String = pool[index]
		pool[index] = pool[other]
		pool[other] = swap
	questions = pool.slice(0, questions_per_meeting())
	question_index = 0
	show_question()

func show_question() -> void:
	stage = "questions"
	graded = false
	_clear()
	var question := QuestionBank.get_question(String(questions[question_index]))
	set_heading("%s · Question %d of %d" % [String(club.get("short", "Club")), question_index + 1, questions.size()], String(question.get("subtopic", "")))
	var prompt := add_text(String(question.prompt), UI.TEXT, UI.SIZE_BODY)
	prompt.name = "Prompt"
	var keys: Array = question.choices.keys()
	keys.sort()
	for key in keys:
		var button := Button.new()
		button.name = "Choice_" + String(key)
		button.text = "%s.  %s" % [key, question.choices[key]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(width - 52, 34)
		button.set_meta("key", key)
		button.pressed.connect(choose.bind(String(key)))
		body.add_child(button)
		choice_buttons.append(button)
	feedback = UI.paragraph("", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	feedback.name = "Feedback"
	body.add_child(feedback)
	next_button = add_button("Next" if question_index < questions.size() - 1 else "See how it went", advance, true)
	next_button.name = "NextQuestion"
	next_button.disabled = true
	_focus_first.call_deferred()

func choose(key: String) -> void:
	if stage != "questions" or graded:
		return
	var id := String(questions[question_index])
	var graded_result := QuestionBank.submit(id, key, "club:%s:%s:%d:%s" % [club_id, YearCalendar.today_date(), question_index, id], "club")
	if not graded_result.get("valid", false):
		return
	graded = true
	question_results.append(graded_result)
	for button in choice_buttons:
		var this_key := String(button.get_meta("key"))
		button.disabled = true
		if this_key == String(graded_result.correct_answer):
			button.add_theme_color_override("font_disabled_color", UI.SUCCESS)
		elif this_key == key:
			button.add_theme_color_override("font_disabled_color", UI.DANGER)
	feedback.add_theme_color_override("font_color", UI.SUCCESS if graded_result.correct else UI.DANGER)
	feedback.text = ("Correct. +%d XP. " % int(graded_result.xp_reward) if graded_result.correct else "Not quite: the answer is %s. " % graded_result.correct_answer) + String(graded_result.explanation)
	Sfx.play("correct" if graded_result.correct else "incorrect")
	next_button.disabled = false
	next_button.grab_focus()

func advance() -> void:
	if stage != "questions" or not graded:
		return
	if question_index < questions.size() - 1:
		question_index += 1
		show_question()
	else:
		finish()

## Records the meeting and shows what it earned.
func finish() -> void:
	stage = "results"
	_clear()
	var correct := question_results.filter(func(entry: Dictionary) -> bool: return entry.get("correct", false)).size()
	var xp := 0
	for entry in question_results:
		xp += int(entry.get("xp_reward", 0))
	var score := activity_score if question_results.is_empty() else activity_score * 0.7 + 0.3 * float(correct) / float(question_results.size())
	Wellbeing.spend(energy_cost(), "club")
	YearCalendar.advance_to(maxf(GameClock.now_seconds() + 30.0 * 60.0, _end_time()))
	if event_id.is_empty():
		result = Clubs.record(club_id, score)
	else:
		YearCalendar.mark_completed(event_id)
		Achievements.bump("volunteer_events")
		result = {"event": event_id, "score": score}
	on_recorded(result)
	set_heading(String(club.get("short", "Club")), "Meeting over")
	if not activity_summary.is_empty():
		add_text(activity_summary, UI.TEXT, UI.SIZE_BODY)
	if not question_results.is_empty():
		body.add_child(UI.label("Questions  %d / %d%s" % [correct, question_results.size(), ("   +%d XP" % xp) if xp > 0 else ""], UI.SIZE_BODY, UI.REWARD if xp > 0 else UI.TEXT_MUTED, 600))
	if result.has("level"):
		var level := int(result.level)
		var line := "+%d reputation · Level %d, %s" % [int(result.get("points", 0)), level, Data.LEVEL_NAMES[level - 1]]
		body.add_child(UI.label(line, UI.SIZE_BODY, UI.ACCENT, 600))
		if level > int(result.get("level_before", 1)) and not String(result.get("reward", "")).is_empty():
			body.add_child(UI.label("Level up! " + String(result.reward), UI.SIZE_TITLE, UI.REWARD, 600))
	var extra := completion_text()
	if not extra.is_empty():
		add_text(extra, UI.TEXT_MUTED, UI.SIZE_LABEL)
	var done := add_button("Done", close, true)
	done.name = "FinishEvent"
	dismissible = true
	_focus_first.call_deferred()

## What else the meeting gave (subclasses).
func completion_text() -> String:
	return ""

## When the meeting (or the volunteer event) ends; 0 if unknown.
func _end_time() -> float:
	if not event_id.is_empty():
		var entry := YearCalendar.event(event_id)
		return YearCalendar.end_of(entry) if not entry.is_empty() else 0.0
	var meeting := Clubs.meeting_today(club_id)
	return float(meeting.end) if not meeting.is_empty() else 0.0

func _unhandled_input(event: InputEvent) -> void:
	if stage == "questions" and event is InputEventKey and event.pressed and not event.echo:
		var pick: int = event.keycode - KEY_1 if event.keycode >= KEY_1 and event.keycode <= KEY_5 else (event.keycode - KEY_A if event.keycode >= KEY_A and event.keycode <= KEY_E else -1)
		if pick >= 0 and pick < choice_buttons.size() and not choice_buttons[pick].disabled:
			choose(String(choice_buttons[pick].get_meta("key")))
			get_viewport().set_input_as_handled()
			return
	super(event)

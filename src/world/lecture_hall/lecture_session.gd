extends Node
## Runs the Pharmacodynamics lecture in Hall A. Sitting down before 8:00 shows
## a waiting prompt (the player may wait out the clock); once class time has
## come and the lecture camera has settled, the student is kept seated and the
## professor presents slide by slide. Afterwards the student may stand.
signal state_changed(state: int)
const LectureRunner = preload("res://education/lectures/lecture_runner.gd")
const CompetitiveActivity = preload("res://world/lecture_hall/competitive_activity.gd")
const QuestionBeat = preload("res://world/lecture_hall/question_beat.gd")
const SCRIPT_PATH := "res://education/lectures/pharmacodynamics_01.json"
enum State { IDLE, WAITING, STARTING, PRESENTING, SUMMARY, COMPLETE }
var state := State.IDLE
var runner := LectureRunner.new()
var hall: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var slide: Control
var slide_viewport: SubViewport
var professor: Node3D
var event: Dictionary = {}
var activity: Node
var question: Node
var summary: Dictionary = {}

func setup(target_hall: Node3D, target_ui: CanvasLayer, target_slide: Control, viewport: SubViewport, target_professor: Node3D) -> void:
	hall = target_hall
	player = hall.player
	ui = target_ui
	slide = target_slide
	slide_viewport = viewport
	professor = target_professor
	var loaded := runner.load_file(SCRIPT_PATH)
	assert(loaded, runner.last_error)
	for candidate in GameClock.config.events:
		if candidate.id == runner.script_data.id:
			event = candidate
	runner.segment_started.connect(_on_segment)
	runner.line_started.connect(_on_line)
	runner.finished.connect(_on_finished)
	ui.typing_changed.connect(professor.set_speaking)
	player.seating.state_changed.connect(_on_seating)
	player.interaction.device_changed.connect(ui.set_controller)
	hall.view_settled.connect(_on_view_settled)
	activity = CompetitiveActivity.new()
	activity.name = "CompetitiveActivity"
	add_child(activity)
	activity.finished.connect(_on_activity_finished)
	question = QuestionBeat.new()
	question.name = "QuestionBeat"
	add_child(question)
	question.finished.connect(func() -> void: runner.advance())
	_show_title_slide()

func completed() -> bool:
	return AcademicSession.lectures_completed.has(runner.script_data.id)

## Unix time at which class begins, from data/academic_config.json.
func start_time() -> float:
	return Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [event.date, int(event.hour), int(event.minute)])

func class_has_started() -> bool:
	return GameClock.now_seconds() >= start_time()

func _set_state(next: State) -> void:
	state = next
	# The lecture overlay owns the bottom of the screen while it is showing.
	hall.hud.suppress_context = state in [State.WAITING, State.STARTING, State.PRESENTING, State.SUMMARY]
	state_changed.emit(state)

func _on_seating(seating_state: int) -> void:
	if seating_state == player.seating.State.SEATED:
		if completed():
			return
		if class_has_started():
			_set_state(State.STARTING)
			if hall.lecture_view_ready():
				_begin()
		else:
			_set_state(State.WAITING)
			ui.show_waiting("Class begins at %s" % _clock_text(start_time()))
	elif state == State.WAITING or state == State.STARTING:
		ui.hide_all()
		_set_state(State.IDLE)
	elif state == State.COMPLETE and seating_state != player.seating.State.SEATED:
		ui.hide_all()

func _on_view_settled() -> void:
	if state == State.STARTING:
		_begin()

func _process(_delta: float) -> void:
	if state == State.WAITING and class_has_started():
		_set_state(State.STARTING)
		if hall.lecture_view_ready():
			_begin()

## Fast-forwards the academic clock (and the autonomous NPC event, by the
## equivalent real time) to the start of class.
func wait_for_class() -> void:
	var remaining := start_time() - GameClock.now_seconds()
	if remaining > 0.0:
		GameClock.advance(remaining / float(GameClock.config.time_scale))
		NPCSchedule.advance(remaining / float(GameClock.config.time_scale))

func _begin() -> void:
	player.seating.stand_locked = true
	player.interaction.enabled = false
	hall.hud.set_help_visible(false)
	_set_state(State.PRESENTING)
	runner.start()

func advance() -> void:
	if state != State.PRESENTING or activity.running() or question.running():
		return
	if ui.typing:
		ui.finish_typing()
	else:
		runner.advance()

func _unhandled_input(event_input: InputEvent) -> void:
	if event_input.is_echo() or hall.hud.settings_open:
		return
	if state == State.WAITING and event_input.is_action_pressed("confirm"):
		wait_for_class()
		get_viewport().set_input_as_handled()
	elif state == State.PRESENTING and activity.running():
		if activity.handle_input(event_input):
			get_viewport().set_input_as_handled()
	elif state == State.PRESENTING and question.running():
		if question.handle_input(event_input):
			get_viewport().set_input_as_handled()
	elif state == State.SUMMARY and (event_input.is_action_pressed("interact") or event_input.is_action_pressed("confirm")):
		_finish_lecture()
		get_viewport().set_input_as_handled()
	elif state == State.PRESENTING and (event_input.is_action_pressed("interact") or event_input.is_action_pressed("confirm")):
		advance()
		get_viewport().set_input_as_handled()

func _on_segment(segment: Dictionary, index: int) -> void:
	var lecture: String = runner.script_data.id
	AcademicSession.notes_progress[lecture] = maxi(int(AcademicSession.notes_progress.get(lecture, 0)), index + 1)
	slide.show_slide(segment.slide, 0)
	ui.show_topic(runner.progress_label())
	hall.hud.set_objective("Pharmacodynamics  ·  " + segment.topic)

func _on_line(line: Dictionary) -> void:
	if line.has("activity"):
		activity.begin(line.activity, runner.script_data.id, runner.script_data.professor, ui, slide, professor)
		return
	if line.has("question"):
		question.begin(line, runner.script_data.id, runner.script_data.professor, ui, professor)
		return
	slide.set_revealed(runner.revealed_bullets())
	professor.set_line(line.get("gesture", "none"))
	ui.show_line(runner.script_data.professor, line.text)

func _on_activity_finished() -> void:
	slide.show_slide(runner.current_segment().slide, runner.revealed_bullets())
	runner.advance()

## End of the script: tally the lecture's questions (remediation follow-ups
## add XP but are not scored), record the result and show the summary.
func _on_finished() -> void:
	summary = tally()
	AcademicSession.lectures_completed[runner.script_data.id] = summary.duplicate()
	professor.set_line("audience")
	professor.set_speaking(false)
	ui.show_summary("Lecture complete  ·  " + runner.script_data.title, [
		"Questions correct: %d of %d  (%d%%)" % [summary.correct, summary.attempted, int(round(summary.accuracy * 100.0))],
		"XP earned this lecture: %d  ·  Level %d" % [summary.xp, AcademicSession.level],
		"%s accuracy overall: %d%%" % [runner.script_data.title, int(round(AcademicSession.accuracy("Pharmacology/Pharmacodynamics") * 100.0))],
	])
	_set_state(State.SUMMARY)

func tally() -> Dictionary:
	var remediation := {}
	for segment in runner.segments():
		for line in segment.lines:
			if line.has("remediation"):
				remediation[line.remediation] = true
	var result := {"correct": 0, "attempted": 0, "xp": 0, "accuracy": 0.0}
	for id in runner.question_ids():
		var attempt: Dictionary = AcademicSession.question_history.get("%s:%s" % [runner.script_data.id, id], {})
		if attempt.is_empty():
			continue
		result.xp += int(attempt.xp_reward)
		if remediation.has(id):
			continue
		result.attempted += 1
		result.correct += 1 if attempt.correct else 0
	result.accuracy = float(result.correct) / result.attempted if result.attempted > 0 else 0.0
	return result

## Leaving the summary: unlock the seat and resume exploration.
func _finish_lecture() -> void:
	ui.hide_all()
	player.seating.stand_locked = false
	player.interaction.enabled = true
	hall.hud.set_help_visible(true)
	hall.hud.set_objective("Pharmacodynamics complete  ·  %d/%d correct" % [summary.correct, summary.attempted])
	_set_state(State.COMPLETE)
	hall.hud.show_message("Class dismissed. Your results are in the schedule menu.", 6.0)
	hall.hud.schedule_panel.refresh()
	hall.hud.calendar_panel.refresh()
	SaveGame.autosave()

func _show_title_slide() -> void:
	var first: Dictionary = runner.segments()[0]
	slide.show_slide(first.slide, 0)

static func _clock_text(unix_time: float) -> String:
	var value := Time.get_datetime_dict_from_unix_time(int(unix_time))
	var hour: int = value.hour % 12
	return "%d:%02d %s" % [12 if hour == 0 else hour, value.minute, "AM" if value.hour < 12 else "PM"]

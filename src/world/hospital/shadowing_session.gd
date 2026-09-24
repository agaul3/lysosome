extends Node
## Runs a shadowing script (education/shadowing/) in the hospital: Dr. Okafor
## waits at the Information desk, greets the student (on time or late, which
## is recorded like class attendance), then walks stop to stop. At each stop
## she turns to the student and the stop's steps play in order: lines in the
## dialogue card, graded bank questions, things the student does themselves
## (ride the elevator, introduce themselves, clean their hands, stand at the
## foot of the bed) and the EHR close-up. The student is free to walk while
## following and during actions, and holds still while she talks.
signal state_changed(state: int)
signal stop_reached(index: int)
const ShadowingScript = preload("res://education/shadowing/shadowing_script.gd")
const QuestionBeat = preload("res://world/lecture_hall/question_beat.gd")
const SCRIPT_PATH := "res://education/shadowing/hospital_orientation_01.json"
const LECTURE_ID := "pharmacodynamics_01"
## The student counts as keeping up within this distance of the physician.
const WITH_YOU := 3.4
## How close to a floor marker counts as standing on it.
const ON_MARK := 0.5
enum State { WAITING, FOLLOWING, TALKING, QUESTION, ACTION, EHR, SUMMARY, COMPLETE }
var state := State.WAITING
var flow := ShadowingScript.new()
var hospital: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var physician: Node3D
var question: Node
var endpoint: Node3D
var guide: MeshInstance3D
var event: Dictionary = {}
var stop_index := -1
var step_index := -1
var action: Dictionary = {}
var action_target: Node3D
var saved_response := ""
## What E does when the current line is done.
var after_line: Callable
var speaker := "okafor"
## State to return to after a standalone line (greeting refusal, post-session chat).
var resume_state := State.WAITING
var greeting := ""
var turn_time := 0.0
var summary: Dictionary = {}
## Where the student looks instead of the physician (the charge nurse, the patient).
var focus_override := Vector3.INF

func setup(target: Node3D, target_ui: CanvasLayer, target_physician: Node3D) -> void:
	hospital = target
	player = hospital.player
	ui = target_ui
	physician = target_physician
	var loaded := flow.load_file(SCRIPT_PATH)
	assert(loaded, flow.last_error)
	physician.wait_line = flow.line("wait")
	for candidate in GameClock.config.events:
		if candidate.id == flow.data.id:
			event = candidate
	question = QuestionBeat.new()
	question.name = "QuestionBeat"
	add_child(question)
	question.finished.connect(_next_step)
	ui.typing_changed.connect(func(typing: bool) -> void: physician.set_speaking(typing and speaker == "okafor"))
	player.interaction.device_changed.connect(ui.set_controller)
	hospital.ride_finished.connect(_on_ride_finished)
	hospital.ehr_ready.connect(_on_ehr_ready)
	endpoint = hospital.add_endpoint("TalkToOkafor", "Talk to Dr. Okafor", "", Vector3.ZERO, 2.2)
	endpoint.reparent(physician, false)
	endpoint.position = Vector3(0, 1.2, 0)
	endpoint.activated.connect(_on_physician_talk)
	guide = hospital.ring(0.5, Color(0.37, 0.78, 0.71, 0.9))
	guide.name = "GuideRing"
	guide.visible = false
	physician.add_child(guide)
	if completed():
		_set_state(State.COMPLETE)
		hospital.hud.set_objective("Shadowing complete · Explore the hospital or head back to campus")
	else:
		_set_state(State.WAITING)
		hospital.hud.set_objective(_waiting_objective())

func id() -> String:
	return String(flow.data.id)

func completed() -> bool:
	return AcademicSession.lectures_completed.has(id())

func start_time() -> float:
	return Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [event.date, int(event.hour), int(event.minute)])

## Before 9:00 with Pharmacodynamics still to attend, the physician sends the student to class.
func too_early() -> bool:
	return not AcademicSession.lectures_completed.has(LECTURE_ID) and GameClock.now_seconds() < start_time()

func active() -> bool:
	return state not in [State.WAITING, State.COMPLETE]

func allows_free_ride() -> bool:
	return not active()

func _waiting_objective() -> String:
	return "Meet Dr. Okafor at the Information desk" if not too_early() else "Pharmacodynamics first (Learning Center, 8:00)"

func _set_state(next: State) -> void:
	state = next
	endpoint.reach = 2.2 if state in [State.WAITING, State.COMPLETE] else 0.0
	guide.visible = state == State.FOLLOWING or (state == State.ACTION and action.get("action", "") == "board")
	state_changed.emit(state)

# --- Holding and releasing the student ---------------------------------------------------

func _hold() -> void:
	player.movement_enabled = false
	player.interaction.enabled = false
	hospital.hud.suppress_context = true
	hospital.hud.set_help_visible(false)
	turn_time = 0.7

func _release() -> void:
	player.movement_enabled = true
	player.interaction.enabled = true
	hospital.hud.suppress_context = false
	hospital.hud.set_help_visible(true)

func _holding() -> bool:
	return state in [State.TALKING, State.QUESTION, State.EHR, State.SUMMARY]

# --- Flow ------------------------------------------------------------------------------

func _on_physician_talk() -> void:
	if state == State.COMPLETE:
		_line("okafor", flow.line("after"), _back_to_rest)
	elif state == State.WAITING:
		if too_early():
			_line("okafor", flow.line("too_early"), _back_to_rest)
		else:
			begin()

## Starts the session (the student has met the physician).
func begin() -> void:
	if state != State.WAITING:
		return
	var record := AcademicSession.record_arrival(id())
	greeting = flow.line("late") if record.get("late", false) else flow.line("on_time")
	hospital.hud.schedule_panel.refresh()
	hospital.hud.calendar_panel.refresh()
	_start_stop(0)

func _back_to_rest() -> void:
	ui.hide_all()
	_release()
	_set_state(resume_state)

func _line(who: String, text: String, then: Callable) -> void:
	if state in [State.WAITING, State.COMPLETE]:
		resume_state = state
	speaker = who
	after_line = then
	_hold()
	_set_state(State.TALKING)
	physician.set_line("audience")
	ui.show_line(flow.speaker_name(who), text)

func _stops() -> Array:
	return flow.stops()

func _start_stop(index: int) -> void:
	stop_index = index
	step_index = -1
	var stop: Dictionary = _stops()[index]
	ui.hide_all()
	ui.show_topic("%s  ·  %d/%d  ·  %s" % [flow.data.title, index + 1, _stops().size(), stop.topic])
	hospital.hud.set_objective(stop.objective)
	_release()
	var points: Array = []
	for id_value in stop.route + [stop.at]:
		points.append(hospital.anchor(id_value))
	_set_state(State.FOLLOWING)
	physician.walk(points)

func _process(delta: float) -> void:
	match state:
		State.FOLLOWING:
			if not physician.walking and _with_physician():
				_arrive()
		State.ACTION:
			if action.action == "stand":
				var mark: Vector3 = hospital.anchor(action.target)
				var offset := player.global_position - mark
				if Vector2(offset.x, offset.z).length() < ON_MARK:
					hospital.hide_marker()
					turn_time = 0.8
					_face_bed_after_stand()
					_next_step()
	if _holding() and not hospital.hud.settings_open:
		player.movement_enabled = false
	if state in [State.TALKING, State.QUESTION, State.SUMMARY, State.ACTION] and not physician.walking and action.get("action", "") != "board":
		physician.face(player.global_position)
	if turn_time > 0.0:
		turn_time -= delta
		_turn_student(delta)

func _with_physician() -> bool:
	if hospital.zone_of(player.global_position) != hospital.zone_of(physician.global_position):
		return false
	var offset := player.global_position - physician.global_position
	return Vector2(offset.x, offset.z).length() < WITH_YOU

## The student turns to whoever is talking (or to the patient after taking their place).
func _turn_student(delta: float) -> void:
	var look_at := _focus_point()
	var to := look_at - player.global_position
	if Vector2(to.x, to.z).length() < 0.3:
		return
	var weight := 1.0 - exp(-6.0 * delta)
	if player.first_person.active:
		player.first_person.turn_toward(look_at + Vector3(0, 1.45, 0), weight)
	else:
		player.appearance.rotation.y = lerp_angle(player.appearance.rotation.y, atan2(-to.x, -to.z), weight)

func _focus_point() -> Vector3:
	return focus_override if focus_override != Vector3.INF else physician.global_position

func _face_bed_after_stand() -> void:
	focus_override = hospital.anchor("bed_412")

func _arrive() -> void:
	var stop: Dictionary = _stops()[stop_index]
	AcademicSession.notes_progress[id()] = maxi(int(AcademicSession.notes_progress.get(id(), 0)), stop_index + 1)
	stop_reached.emit(stop_index)
	focus_override = Vector3.INF
	if not greeting.is_empty():
		var text := greeting
		greeting = ""
		_line("okafor", text, _next_step)
	else:
		_next_step()

func _next_step() -> void:
	action = {}
	step_index += 1
	var steps: Array = _stops()[stop_index].steps
	if step_index >= steps.size():
		if stop_index + 1 < _stops().size():
			_start_stop(stop_index + 1)
		else:
			_finish()
		return
	var step: Dictionary = steps[step_index]
	if step.has("say"):
		_line(String(step.get("speaker", "okafor")), step.say, _next_step)
	elif step.has("question"):
		speaker = "okafor"
		_hold()
		_set_state(State.QUESTION)
		question.begin(step, id(), flow.speaker_name("okafor"), ui, physician)
	elif step.has("action"):
		_begin_action(step)
	elif step.has("ehr"):
		_ehr(String(step.ehr))

func _ehr(view: String) -> void:
	match view:
		"open":
			_hold()
			ui.hide_all()
			_set_state(State.EHR)
			hospital.open_ehr()
		"close":
			hospital.close_ehr()
			_next_step()
		_:
			hospital.ehr_chart.show_view(view)
			_next_step()

func _on_ehr_ready() -> void:
	if state == State.EHR:
		_next_step()

# --- Actions ---------------------------------------------------------------------------

func _begin_action(step: Dictionary) -> void:
	action = step
	ui.hide_all()
	_set_state(State.ACTION)
	hospital.hud.set_objective(step.objective)
	_release()
	match String(step.action):
		"board":
			hospital.call_elevator(String(step.target), physician)
			physician.walk([hospital.anchor("cab_l1" if hospital.zone == "lobby" else "cab_u")])
		"talk", "sanitize":
			action_target = hospital.targets.get(String(step.target))
			saved_response = action_target.response
			action_target.response = ""
			action_target.activated.connect(_on_action_target, CONNECT_ONE_SHOT)
		"stand":
			hospital.show_marker(hospital.anchor(String(step.target)))

func _on_action_target() -> void:
	if state != State.ACTION:
		return
	action_target.response = saved_response
	match String(action.action):
		"talk":
			focus_override = action_target.global_position
			var figure: Node3D = hospital.charge_nurse
			if is_instance_valid(figure) and action.target == "charge_nurse":
				var to := player.global_position - figure.global_position
				figure.rotation.y = atan2(-to.x, -to.z)
			_line("priya", String(action.reply), func() -> void:
				focus_override = Vector3.INF
				_next_step())
		"sanitize":
			hospital.hud.show_message("Hands cleaned: alcohol foam, rubbed in until dry.", 3.0)
			# A moment to read it before the physician goes on.
			await get_tree().create_timer(0.01 if DisplayServer.get_name() == "headless" else 1.1).timeout
			_next_step()

func _on_ride_finished(_zone: String) -> void:
	if state == State.ACTION and action.get("action", "") == "board":
		_next_step()

# --- End of the session ----------------------------------------------------------------

func _finish() -> void:
	summary = tally()
	var first_time := not completed()
	AcademicSession.lectures_completed[id()] = summary.duplicate()
	AcademicSession.notes_progress[id()] = _stops().size()
	if first_time:
		AcademicSession.lecture_completed.emit(id())
	speaker = "okafor"
	physician.set_speaking(false)
	_hold()
	ui.show_summary("Shadowing complete  ·  " + String(flow.data.title), [
		"Etiquette checks correct: %d of %d  (%d%%)" % [summary.correct, summary.attempted, int(round(summary.accuracy * 100.0))],
		"XP earned: %d  ·  Level %d" % [summary.xp, AcademicSession.level],
		"Key takeaways saved to Lecture Notes (Tab)",
	])
	_set_state(State.SUMMARY)

func tally() -> Dictionary:
	var result := {"correct": 0, "attempted": 0, "xp": 0, "accuracy": 0.0}
	for question_id in flow.question_ids():
		var attempt: Dictionary = AcademicSession.question_history.get("%s:%s" % [id(), question_id], {})
		if attempt.is_empty():
			continue
		result.xp += int(attempt.xp_reward)
		result.attempted += 1
		result.correct += 1 if attempt.correct else 0
	result.accuracy = float(result.correct) / result.attempted if result.attempted > 0 else 0.0
	return result

func _close_summary() -> void:
	ui.hide_all()
	_release()
	resume_state = State.COMPLETE
	_set_state(State.COMPLETE)
	hospital.hud.set_objective("Shadowing complete · Takeaways are in Lecture Notes (Tab)")
	hospital.hud.show_message("Dr. Okafor heads back to her patients. The elevator will take you down to the lobby.", 6.0)
	hospital.hud.schedule_panel.refresh()
	hospital.hud.calendar_panel.refresh()
	SaveGame.autosave()

# --- Input -------------------------------------------------------------------------------

func advance() -> void:
	if state != State.TALKING:
		return
	if ui.typing:
		ui.finish_typing()
	else:
		var then := after_line
		after_line = Callable()
		if then.is_valid():
			then.call()

func _unhandled_input(event_input: InputEvent) -> void:
	if event_input.is_echo() or hospital.hud.settings_open or hospital.hud.computer_open:
		return
	var pressed := event_input.is_action_pressed("interact") or event_input.is_action_pressed("confirm")
	match state:
		State.TALKING:
			if pressed:
				advance()
				get_viewport().set_input_as_handled()
		State.QUESTION:
			if question.handle_input(event_input):
				get_viewport().set_input_as_handled()
		State.SUMMARY:
			if pressed:
				_close_summary()
				get_viewport().set_input_as_handled()

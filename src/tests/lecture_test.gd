extends "res://tests/campus_test.gd"
## Pharmacodynamics presentation: script validation, runner stepping, the
## dose-response model, and the in-hall flow (wait for class, locked seat,
## professor lines and slides, completion, standing afterwards).
const LectureRunner = preload("res://education/lectures/lecture_runner.gd")
const DoseResponse = preload("res://education/models/dose_response.gd")
const Seat = preload("res://world/seat.gd")
const CompetitiveModel = preload("res://education/models/competitive_antagonism.gd")
const SPEC_TOPICS := ["receptors", "agonists", "antagonists", "competitive", "noncompetitive", "potency", "efficacy", "dose_response", "clinical"]

func _run() -> void:
	runner_tests()
	model_tests()
	await hall_tests()
	print("LECTURE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func runner_tests() -> void:
	var runner := LectureRunner.new()
	check(runner.load_file("res://education/lectures/pharmacodynamics_01.json"), "Lecture script loads: " + runner.last_error)
	var ids: Array = runner.segments().map(func(s): return s.id)
	var positions: Array = SPEC_TOPICS.map(func(id): return ids.find(id))
	check(not positions.has(-1), "Covers every suggested pharmacodynamics topic")
	var ordered := positions.duplicate()
	ordered.sort()
	check(positions == ordered, "Topics follow a coherent order")
	var raw := FileAccess.get_file_as_string("res://education/lectures/pharmacodynamics_01.json")
	check(not raw.contains("correct_answer") and not raw.contains("choices"), "No question content hard-coded in the lecture script")
	var total := 0
	for segment in runner.segments():
		total += segment.lines.size()
	var started := []
	var finished := [0]
	var reveals_monotonic := [true]
	var last_reveal := [0]
	runner.segment_started.connect(func(segment, _i): started.append(segment.id); last_reveal[0] = 0)
	runner.line_started.connect(func(_line):
		if runner.revealed_bullets() < last_reveal[0]:
			reveals_monotonic[0] = false
		last_reveal[0] = runner.revealed_bullets())
	runner.finished.connect(func(): finished[0] += 1)
	runner.start()
	var lines := 1
	while not runner.done:
		runner.advance()
		if not runner.done:
			lines += 1
	runner.advance()
	check(lines == total, "Every professor line is delivered once (%d)" % lines)
	check(started == ids, "Segments start in order")
	check(finished[0] == 1, "Finished fires exactly once")
	check(reveals_monotonic[0], "Bullets are revealed progressively, never hidden")
	# The lambdas above capture the runner; disconnect them to break the cycle.
	for signal_name in ["segment_started", "line_started", "finished"]:
		for connection in runner.get_signal_connection_list(signal_name):
			runner.disconnect(signal_name, connection.callable)
	var bank := root.get_node("QuestionBank")
	var referenced: Array = runner.question_ids()
	var missing := referenced.filter(func(id): return bank.get_question(id).is_empty())
	check(missing.is_empty(), "Every referenced question exists in the shared bank %s" % str(missing))
	var scored := referenced.filter(func(id): return not bank.get_question(id).get("is_remediation", false))
	var remedial := referenced.filter(func(id): return bank.get_question(id).get("is_remediation", false))
	check(scored.size() == 12, "About twelve lecture questions (%d)" % scored.size())
	check(remedial.size() == 2, "Remediation is selective (%d follow-ups)" % remedial.size())
	var types := {}
	var complete := true
	for id in referenced:
		var q: Dictionary = bank.get_question(id)
		types[q.question_type] = true
		complete = complete and q.lecture_id == "pharmacodynamics_01" and not q.explanation.is_empty() and not q.learning_objective.is_empty()
	check(complete, "Each question has an explanation, objective and the lecture id")
	check(types.has("Recall") and types.has("Conceptual") and types.has("Application") and types.has("Clinical Application"), "Recall, conceptual, application and clinical application questions")
	for broken in [
		"{}",
		'{"version":1,"id":"x","title":"t","professor":"p","segments":[]}',
		'{"version":1,"id":"x","title":"t","professor":"p","segments":[{"id":"a","slide":{"heading":"h","bullets":[],"diagram":"nope"},"lines":[{"text":"hi"}]}]}',
		'{"version":1,"id":"x","title":"t","professor":"p","segments":[{"id":"a","slide":{"heading":"h","bullets":["b"],"diagram":"title"},"lines":[{"text":"hi","reveal":2}]}]}',
		'{"version":1,"id":"x","title":"t","professor":"p","segments":[{"id":"a","slide":{"heading":"h","bullets":[],"diagram":"title"},"lines":[{"text":"  "}]}]}',
		'{"version":1,"id":"x","title":"t","professor":"p","segments":[{"id":"a","slide":{"heading":"h","bullets":[],"diagram":"title"},"lines":[{"text":"hi"}]},{"id":"a","slide":{"heading":"h","bullets":[],"diagram":"title"},"lines":[{"text":"hi"}]}]}',
	]:
		var probe := LectureRunner.new()
		check(not probe.load_json(broken), "Rejects malformed script: " + probe.last_error)

func model_tests() -> void:
	check(is_equal_approx(DoseResponse.response(2.0, 80.0, 2.0), 40.0), "Response at EC50 is half of Emax")
	check(DoseResponse.response(1000.0, 80.0, 2.0) > 79.0, "Response approaches Emax")
	check(is_equal_approx(DoseResponse.competitive_ec50(1.0, 3.0, 1.0), 4.0), "Competitive antagonist dose ratio 1 + B/Kb")
	check(is_equal_approx(DoseResponse.noncompetitive_emax(100.0, 0.4), 60.0), "Noncompetitive antagonism lowers Emax")
	check(is_equal_approx(DoseResponse.occupancy(3.0, 3.0), 0.5), "Half occupancy at Kd")
	var model := CompetitiveModel.new()
	model.log_agonist = 1.0
	model.antagonist = true
	model.advance(5.0)
	check(is_equal_approx(model.response(), 50.0) and is_equal_approx(model.apparent_ec50(), 10.0), "With B/KB = 9, half response needs 10× agonist")
	check(is_equal_approx(model.agonist_occupancy() + model.antagonist_occupancy() + 1.0 / (1.0 + 10.0 + 9.0), 1.0), "Occupancy fractions sum to one")
	model.log_agonist = 3.0
	check(model.response() > 98.0, "Surmountable: enough agonist restores the maximum")

func hall_tests() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	state.enter_campus("dorm")
	await acquire_world()
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	var hall := dorm
	var session: Node = hall.session
	var ui: CanvasLayer = hall.lecture_ui
	var clock := root.get_node("GameClock")
	check(hall.slide.heading.text == "Pharmacodynamics", "Title slide shown before class")
	check(hall.get_node("LectureDisplay").material_override.albedo_texture != null, "Screen displays the slide viewport")
	var seat: Node3D = hall.get_node("Seat_R2_C4")
	player.global_position = seat.point(Seat.FRONT_POINT) + Vector3(0, 0.04, 0)
	await ticks(4)
	player.seating.request(seat)
	await wait_for(func(): return player.seating.state == player.seating.State.SEATED)
	await ticks(2)
	check(not session.class_has_started() and session.state == session.State.WAITING, "Seated early: waiting for class")
	check(ui.waiting_card.visible and ui.waiting_label.text.contains("8:00 AM"), "Waiting prompt shows the start time")
	check(not player.seating.stand_locked, "Student may still stand before class")
	check(hall.hud.suppress_context and not hall.hud.prompt_row.visible and not hall.hud.message_card.visible, "HUD prompt and toasts yield to the waiting card")
	press_confirm()
	await ticks(2)
	check(session.class_has_started() and clock.display_time() == "8:00 AM", "Waiting advances the clock to class time")
	await wait_for(func(): return session.state == session.State.PRESENTING)
	check(session.state == session.State.PRESENTING, "Lecture begins once the camera settles")
	check(player.seating.stand_locked and not player.interaction.enabled, "Seat is locked during the lecture")
	check(not hall.hud.help_row.visible, "Exploration controls hint hidden during the lecture")
	check(ui.card.visible and ui.speaker.text == "DR. LENA PARK", "Professor subtitle card shown")
	check(ui.topic_label.text.begins_with("1 / 11"), "Topic chip shows progress")
	check(ui.typing, "Line types out progressively")
	press_interact()
	await ticks(1)
	check(not ui.typing and ui.text.visible_characters == -1, "First press completes the line")
	var first_line: String = ui.text.text
	press_interact()
	await ticks(1)
	check(ui.text.text != first_line, "Second press advances to the next line")
	player.seating.request(seat)
	await ticks(2)
	check(player.seating.state == player.seating.State.SEATED, "Cannot stand up mid-lecture")
	# Step to a screen-gesture line and let the professor turn and point.
	var guard := 0
	while session.runner.current_line().get("gesture", "") != "screen" and guard < 20:
		session.advance()
		session.advance()
		guard += 1
	await ticks(60)
	check(hall.professor.turn > 0.3 and hall.professor.point > 0.3, "Professor turns and points at the screen")
	var headings := {}
	guard = 0
	var academics := root.get_node("AcademicSession")
	var xp_before_lecture: int = academics.xp_balance
	var asked: Array = []
	while session.state == session.State.PRESENTING and guard < 300:
		if session.activity.running():
			await activity_checks(hall, session)
			continue
		if session.question.running():
			asked.append(session.question.current_id)
			await question_checks(hall, session)
			continue
		headings[hall.slide.heading.text] = true
		var visible := 0
		for row in hall.slide.bullet_box.get_children():
			if row.modulate.a > 0.5:
				visible += 1
		if visible != session.runner.revealed_bullets():
			check(false, "Slide shows the revealed bullet count")
		session.advance()
		session.advance()
		guard += 1
	await ticks(2)
	check(headings.size() >= 10, "Slides change with each segment (%d)" % headings.size())
	check(asked.size() == 11, "Every question beat is asked (%d, plus the activity prediction)" % asked.size())
	check(session.state == session.State.SUMMARY and ui.card.visible and ui.speaker.text.begins_with("LECTURE COMPLETE"), "Lecture completion summary shown")
	var summary: Dictionary = session.summary
	# All answered correctly except the deliberate noncompetitive miss and the
	# deliberate wrong prediction in the activity: 10 of 12 scored questions.
	check(summary.attempted == 12 and summary.correct == 10, "Summary counts lecture questions, not remediation (%d/%d)" % [summary.correct, summary.attempted])
	check(summary.xp == academics.xp_balance - xp_before_lecture and summary.xp > 0, "Summary XP matches the XP actually earned (%d)" % summary.xp)
	check(ui.text.text.contains("10 of 12") and ui.text.text.contains("XP earned this lecture: %d" % summary.xp), "Summary card shows score and XP")
	check(player.seating.stand_locked, "Seat stays locked until the summary is dismissed")
	await press_action("interact")
	await ticks(2)
	check(session.state == session.State.COMPLETE and academics.lectures_completed.has("pharmacodynamics_01"), "Lecture completion is recorded")
	check(not player.seating.stand_locked and hall.hud.help_row.visible and not ui.card.visible, "Seat unlocks and exploration resumes after the summary")
	check(hall.hud.schedule_panel.body.text.contains("Lecture complete • 10/12 correct"), "Schedule shows the lecture result")
	check(hall.hud.objective_text.contains("10/12"), "HUD objective shows the result")
	await ticks(3)
	check(hall.hud.message.text.contains("Class dismissed") and hall.hud.prompt.text == "Stand up" and hall.hud.prompt_row.visible, "Closing message with a visible stand-up prompt")
	player.seating.request(seat)
	await wait_for(func(): return player.seating.state == player.seating.State.FREE)
	check(player.seating.state == player.seating.State.FREE and not ui.card.visible, "Student stands after the lecture")
	await ticks(60)
	player.seating.request(seat)
	await wait_for(func(): return player.seating.state == player.seating.State.SEATED)
	await ticks(3)
	check(session.state == session.State.COMPLETE and not ui.waiting_card.visible and not player.seating.stand_locked, "Sitting again does not replay the lecture")

func wait_for(condition: Callable) -> void:
	for index in range(900):
		if condition.call():
			return
		await ticks(1)

func press_confirm() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func press_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await ticks(1)

## Plays the competitive-antagonism activity through real input, answering
## the prediction wrongly to check incorrect-answer handling.
func activity_checks(hall: Node3D, session: Node) -> void:
	var activity: Node = session.activity
	var model = activity.model
	var ui: CanvasLayer = hall.lecture_ui
	var academics := root.get_node("AcademicSession")
	check(hall.slide.model_canvas.visible and hall.slide.heading.text.contains("Try it"), "Live model replaces the slide")
	check(ui.activity_row.get_child_count() > 0 and not ui.continue_row.visible, "Activity shows agonist controls")
	var start_log: float = model.log_agonist
	Input.action_press("move_right")
	await ticks(30)
	Input.action_release("move_right")
	check(model.log_agonist > start_log + 0.3, "Holding right raises agonist concentration")
	check(activity.phase == activity.Phase.INTRO, "Goal not yet reached")
	Input.action_press("move_right")
	for index in range(400):
		if activity.phase != activity.Phase.INTRO:
			break
		await ticks(1)
	Input.action_release("move_right")
	check(activity.phase == activity.Phase.ANTAGONIST, "Reaching ~90% response brings in the antagonist")
	var before: float = model.response()
	await ticks(150)
	check(model.antagonist_level > 0.99 and model.response() < before - 30.0, "Antagonist lowers the response at the same agonist level")
	var bound_antagonist := 0
	for index in range(model.RECEPTORS):
		if model.receptor_state(index) == 2:
			bound_antagonist += 1
	check(bound_antagonist > 0, "Antagonist molecules occupy receptors on screen")
	await press_action("interact")
	if activity.phase == activity.Phase.ANTAGONIST:
		await press_action("interact")
	check(activity.phase == activity.Phase.PREDICT and ui.question_card.visible, "Prediction question shown")
	var attempted_before: int = academics.attempted
	var xp_before: int = academics.xp_balance
	await press_action("move_down") # a -> b
	await press_action("move_down") # b -> c (a wrong answer)
	check(ui.selected_key() == "c", "Arrow keys move the choice")
	await press_action("interact")
	check(activity.phase == activity.Phase.FEEDBACK and ui.feedback.text.begins_with("Not quite"), "Incorrect prediction is clearly marked")
	check(academics.attempted == attempted_before + 1 and academics.xp_balance == xp_before, "Incorrect answer updates stats and awards no XP")
	await press_action("interact")
	check(activity.phase == activity.Phase.TEST, "Player tests the prediction")
	Input.action_press("move_right")
	for index in range(400):
		if activity.phase != activity.Phase.TEST:
			break
		await ticks(1)
	Input.action_release("move_right")
	check(activity.phase == activity.Phase.WRAP and model.response() >= 90.0 and model.log_agonist > 1.8, "Full response returns only at ~10× higher agonist")
	await press_action("interact")
	if activity.phase == activity.Phase.WRAP:
		await press_action("interact")
	check(not activity.running() and not hall.slide.model_canvas.visible, "Activity ends and the slide returns")

## Answers a question beat through real input. Every question is answered
## correctly except the noncompetitive one, which is missed on purpose to
## exercise its simpler remediation follow-up.
func question_checks(hall: Node3D, session: Node) -> void:
	var beat: Node = session.question
	var ui: CanvasLayer = hall.lecture_ui
	var academics := root.get_node("AcademicSession")
	var id: String = beat.current_id
	var question: Dictionary = root.get_node("QuestionBank").get_question(id)
	check(ui.question_card.visible and ui.question_prompt.text == question.prompt, "Question shown from the bank: " + id)
	var keys: Array = question.choices.keys()
	keys.sort()
	var wrong_on_purpose := id == "pd_noncompetitive_01"
	var target: String = question.correct_answer
	if wrong_on_purpose:
		target = keys[1] if keys[0] == question.correct_answer else keys[0]
	var xp_before: int = academics.xp_balance
	var attempted_before: int = academics.attempted
	for step in range(keys.find(target)):
		await press_action("move_down")
	await press_action("interact")
	check(academics.attempted == attempted_before + 1, "Answer recorded in performance stats: " + id)
	if wrong_on_purpose:
		check(ui.feedback.text.begins_with("Not quite") and academics.xp_balance == xp_before, "Incorrect answer: clear failure, explanation, no XP")
		await press_action("interact")
		check(beat.current_id == "pd_noncompetitive_remedial_01" and ui.question_card.visible, "Selected wrong answers get a simpler follow-up")
		var remedial: Dictionary = root.get_node("QuestionBank").get_question(beat.current_id)
		var remedial_keys: Array = remedial.choices.keys()
		remedial_keys.sort()
		for step in range(remedial_keys.find(remedial.correct_answer)):
			await press_action("move_down")
		await press_action("interact")
		check(ui.feedback.text.begins_with("Correct"), "Remediation answered correctly")
	else:
		check(ui.feedback.text.begins_with("Correct") and academics.xp_balance > xp_before, "Correct answer: confirmation and XP: " + id)
	await press_action("interact")
	check(not beat.running(), "Question beat hands back to the lecture: " + id)

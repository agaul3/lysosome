extends "res://tests/campus_test.gd"
## Pharmacodynamics presentation: script validation, runner stepping, the
## dose-response model, and the in-hall flow (wait for class, locked seat,
## professor lines and slides, completion, standing afterwards).
const LectureRunner = preload("res://education/lectures/lecture_runner.gd")
const DoseResponse = preload("res://education/models/dose_response.gd")
const Seat = preload("res://world/seat.gd")
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
	while session.state == session.State.PRESENTING and guard < 200:
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
	check(session.state == session.State.COMPLETE and root.get_node("AcademicSession").presentations_completed.has("pharmacodynamics_01"), "Presentation completes and is recorded")
	check(not player.seating.stand_locked and hall.hud.help_row.visible, "Seat unlocks after the lecture")
	await ticks(3)
	check(hall.hud.message.text.contains("end of today's presentation") and hall.hud.prompt.text == "Stand up" and hall.hud.prompt_row.visible, "Closing message with a visible stand-up prompt")
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

extends "res://tests/campus_test.gd"
var clock: Node
var academics: Node
var bank: Node

func _run() -> void:
	clock = root.get_node("GameClock")
	academics = root.get_node("AcademicSession")
	bank = root.get_node("QuestionBank")
	clock_tests()
	attendance_tests()
	question_tests()
	state = root.get_node("AppState")
	state.start_new_game()
	state.enter_dorm()
	await acquire_world()
	check(clock.running, "Exploration starts game clock")
	dorm.hud.set_settings_open(true)
	var before: float = clock.now_seconds()
	await ticks(60)
	check(clock.now_seconds() - before > 4.5 and clock.now_seconds() - before < 6.5, "Live clock advances at 5x with menu open")
	check(dorm.hud.schedule_panel.body.text.contains("PHARMACODYNAMICS"), "Today's Schedule displays event")
	check(dorm.hud.calendar_panel.body.text.contains("MANDATORY"), "Calendar shows mandatory event")
	dorm.hud.menu_tabs.current_tab = 2
	check(dorm.hud.settings.is_visible_in_tree(), "Settings remains accessible in menu")
	dorm.hud.menu_tabs.current_tab = 1
	check(dorm.hud.calendar_panel.is_visible_in_tree(), "Calendar tab accessible")
	dorm.hud.menu_tabs.current_tab = 0
	await capture("milestone-5-schedule")
	state.leave_dorm()
	await acquire_world()
	var morning_light: float = dorm.sun.light_energy
	var saved_elapsed: float = clock.elapsed_seconds
	clock.advance(12 * 3600 / 5.0)
	check(dorm.sun.light_energy < morning_light, "Campus light follows time into night")
	clock.elapsed_seconds = saved_elapsed
	clock.minute_changed.emit()
	dorm.hud.set_settings_open(true)
	var npc := root.get_node("NPCSchedule")
	var npc_before: Vector3 = npc.actor_position
	await ticks(180)
	check(npc.actor_position.distance_to(npc_before) > 0.3 and not paused, "Schedule menu does not stop NPCs")
	state.enter_lecture_building()
	await acquire_world()
	clock.elapsed_seconds = 25 * 60 + 1 # 08:00:01 game time, no five-minute real wait.
	state.enter_lecture_hall()
	await acquire_world()
	check(academics.xp_balance == -5, "Actual late Hall A entry deducts five at zero XP")
	check(dorm.hud.message.text.contains("−5 XP"), "Visible late-entry feedback")
	check(dorm.hud.schedule_panel.body.text.contains("Late"), "Schedule retains lateness")
	await capture("milestone-5-lateness")
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	check(academics.xp_balance == -5 and academics.attendance.size() == 1, "Scene re-entry does not duplicate penalty")
	state.return_to_title()
	await scene_changed
	await ticks(2)
	check(not clock.running, "Title stops academic clock")
	state.start_new_game()
	check(academics.attendance.is_empty() and academics.question_history.is_empty() and academics.xp_balance == 0, "New Game resets academic session")
	state.enter_dorm()
	await acquire_world()
	state.leave_dorm()
	await acquire_world()
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	check(academics.xp_balance == 0 and dorm.hud.message.text.contains("on time"), "Fresh on-time route has no penalty")
	state.return_to_title()
	await scene_changed
	await ticks(2)
	print("ACADEMIC: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func clock_tests() -> void:
	clock.reset()
	check(clock.display_time() == "7:35 AM", "Configured starting time")
	var start: float = clock.now_seconds()
	clock.advance(60)
	check(is_equal_approx(clock.now_seconds() - start, 300), "60 real seconds advances 300 game seconds")
	check(clock.display_time() == "7:40 AM", "Clock minute display")
	for hz in [30, 60, 120]:
		clock.reset()
		for index in range(hz * 2):
			clock.advance(1.0 / hz)
		check(absf(clock.elapsed_seconds - 10.0) < 0.001, "Clock frame-rate independent at %d Hz" % hz)
	clock.reset()
	clock.advance((24 * 3600 - 7 * 3600 - 35 * 60) / 5.0)
	var snapshot: Dictionary = clock.snapshot()
	check(snapshot.date == "2026-09-22" and snapshot.day == 2 and snapshot.weekday == 2, "Midnight rolls date/day/weekday")
	clock.advance(7 * 86400 / 5.0)
	check(clock.snapshot().academic_week == 2 and clock.snapshot().semester == "Fall 1", "Academic week/semester state")
	var original_start: String = clock.config.start_datetime
	clock.config.start_datetime = "2028-02-28T23:59:00"
	clock.reset()
	clock.advance(12)
	check(clock.snapshot().date == "2028-02-29", "Leap-day rollover")
	clock.config.start_datetime = original_start
	clock.reset()
	clock.advance(-1)
	clock.advance(INF)
	check(clock.elapsed_seconds == 0, "Invalid deltas ignored")

func attendance_tests() -> void:
	var event: Dictionary = clock.config.events[0]
	var start := Time.get_unix_time_from_datetime_string(event.date + "T08:00:00")
	for offset in [-60, 0, 1]:
		academics.reset()
		var record: Dictionary = academics.record_arrival(event.id, start + offset)
		check(record.late == (offset > 0), "Attendance boundary %d seconds" % offset)
		check(academics.xp_balance == (-5 if offset > 0 else 0), "Correct boundary penalty")
		academics.record_arrival(event.id, start + 1000)
		check(academics.attendance.size() == 1 and academics.xp_balance == (-5 if offset > 0 else 0), "First arrival is immutable")
	academics.reset()
	check(academics.record_arrival("unknown", start).is_empty(), "Unknown event rejected")
	check(academics.record_arrival(event.id, start + 86400).is_empty(), "No penalty on another date")
	check(academics.events_for_date("2026-09-22").is_empty(), "No phantom recurring event")
	event.late_grace_seconds = 60
	var record: Dictionary = academics.record_arrival(event.id, start + 60)
	check(not record.late, "Configurable grace boundary")
	academics.reset()
	record = academics.record_arrival(event.id, start + 61)
	check(record.late, "Late after configured grace")
	event.late_grace_seconds = 0
	academics.reset()
	event.mandatory = false
	record = academics.record_arrival(event.id, start + 1)
	check(record.late and record.xp_delta == 0, "Optional event never penalizes")
	event.mandatory = true
	academics.reset()

func question_tests() -> void:
	check(bank.records.size() == 14, "Pharmacodynamics bank loaded (12 lecture questions + 2 remediation follow-ups)")
	check(bank.for_lecture("pharmacodynamics_01").size() == 14, "Shared lecture filter")
	var q: Dictionary = bank.get_question("pd_potency_01")
	var outcome: Dictionary = bank.grade(q.id, "a")
	check(outcome.valid and outcome.correct and outcome.xp_reward == 20, "Correct answer gets tier-two reward")
	check(not outcome.explanation.is_empty() and outcome.learning_objective == q.learning_objective, "Explanation and objective returned")
	check(bank.grade(q.id, "b").xp_reward == 0, "Wrong answer gives zero XP")
	check(not bank.grade(q.id, "z").valid and not bank.grade("missing", "a").valid, "Unknown question/choice rejected")
	check(not bank.grade(q.id, "").valid and not bank.grade(q.id, 0).valid, "Empty/non-string answer rejected")
	check(academics.attempted == 0, "Pure grading has no performance side effects")
	check(academics.accuracy("Pharmacology") == 0, "Zero-attempt accuracy safe")
	bank.submit(q.id, "a", "attempt-1")
	bank.submit(q.id, "a", "attempt-1")
	check(academics.attempted == 1 and academics.correct == 1 and academics.xp_balance == 20, "Duplicate submission awards/counts once")
	check(not bank.submit(q.id, "b", "attempt-1").valid, "Attempt ID conflict rejected")
	bank.submit(q.id, "b", "attempt-2")
	check(academics.attempted == 2 and academics.correct == 1 and academics.xp_balance == 20, "Incorrect answer records attempt without XP")
	check(is_equal_approx(academics.accuracy("Pharmacology/Pharmacodynamics"), 0.5), "Topic performance hooks update")
	check(not bank.submit(q.id, "a", "").valid, "Empty attempt ID rejected")
	var copy: Dictionary = bank.get_question(q.id)
	copy.choices.a = "changed"
	check(bank.get_question(q.id).choices.a != "changed", "Question access returns independent data")
	var valid_json := JSON.stringify({"version":1,"questions":[q]})
	check(not bank.load_json("{"), "Malformed JSON rejected")
	check(bank.records.size() == 14, "Malformed import preserves old bank")
	for field in ["prompt", "correct_answer", "learning_objective", "choices", "xp_reward"]:
		var bad := q.duplicate(true)
		bad.erase(field)
		check(not bank.load_json(JSON.stringify({"version":1,"questions":[bad]})), "Missing field rejected: " + field)
	var invalid_records: Array = []
	for patch in [{"difficulty_tier":1.5},{"xp_reward":-5},{"xp_reward":1e20},{"xp_reward":"20"},{"correct_answer":"unknown"},{"question_type":"invalid"},{"choices":{"a":"same","b":"same"}},{"format":"ai"}]:
		var bad := q.duplicate(true)
		bad.merge(patch, true)
		invalid_records.append(bad)
	for bad in invalid_records:
		check(not bank.validate(bad).is_empty(), "Invalid metadata/format rejected")
	check(not bank.load_json(JSON.stringify({"version":1,"questions":[q,q]})), "Duplicate question IDs rejected")
	q.format = "short_answer"
	q.choices = {}
	q.correct_answer = "efficacy"
	q.accepted_short_answers = ["efficacy", "maximal efficacy"]
	q.xp_reward = 30
	check(bank.load_json(JSON.stringify({"version":1,"questions":[q]})), "Predefined short answer supported")
	check(bank.grade(q.id, "  MAXIMAL   EFFICACY ").correct, "Short answer normalizes case/spacing")
	check(not bank.grade(q.id, "efficacyish").correct, "No fuzzy/AI grading")
	check(bank.grade(q.id, "efficacy").xp_reward == 30, "Explicit reward override")
	check(bank.load_file(bank.DEFAULT_PATH), "Restore production bank")
	academics.reset()
	var start := Time.get_unix_time_from_datetime_string("2026-09-21T08:00:01")
	academics.record_arrival("pharmacodynamics_01", start)
	bank.submit("pd_efficacy_01", "b", "after-penalty")
	check(academics.xp_balance == 5, "Ten XP answer repays five XP penalty without corruption")
	academics.reset()

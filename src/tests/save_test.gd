extends "res://tests/campus_test.gd"
## Save/load (spec §35, §41): progression, knowledge, time, location, lecture
## state and lateness survive a reload exactly; damaged saves are rejected
## without touching the game; Continue resumes where the save was made.
var save: Node
var academics: Node
var bank: Node
var clock: Node
var npc: Node

func _run() -> void:
	save = root.get_node("SaveGame")
	academics = root.get_node("AcademicSession")
	bank = root.get_node("QuestionBank")
	clock = root.get_node("GameClock")
	npc = root.get_node("NPCSchedule")
	state = root.get_node("AppState")
	check(save.path == "user://savegame_test.json" and not save.has_save(), "Tests use their own, initially empty save slot")
	await round_trip()
	await corruption()
	await resume_from_title()
	print("SAVE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func answer(id: String, correct: bool, attempt: String) -> void:
	var question: Dictionary = bank.get_question(id)
	var key: String = question.correct_answer
	if not correct:
		for choice in question.choices:
			if choice != key:
				key = choice
				break
	bank.submit(id, key, attempt)

func round_trip() -> void:
	state.start_new_game()
	state.select_character("clay")
	state.enter_dorm()
	await acquire_world()
	check(save.has_save(), "Arriving in the world autosaves")
	# Build up distinctive state: late arrival, answers, streak, notes, completion.
	clock.elapsed_seconds = 27 * 60 + 13.5
	academics.record_arrival("pharmacodynamics_01")
	for index in range(11):
		answer("pd_efficacy_01", true, "save-test:%d" % index)
	answer("pd_naloxone_01", false, "save-test:miss")
	answer("pd_affinity_01", true, "save-test:last")
	academics.notes_progress["pharmacodynamics_01"] = 7
	academics.lectures_completed["pharmacodynamics_01"] = {"correct": 10, "attempted": 12, "xp": 190, "accuracy": 10.0 / 12.0}
	npc.advance(40.0)
	state.enter_campus("dorm")
	await acquire_world()
	check(save.save(), "Manual save succeeds")
	check(not FileAccess.file_exists(save.path + ".tmp"), "No temporary file left behind")
	var expected := {
		"xp": academics.xp_balance, "level": academics.level, "streak": academics.streak, "best": academics.best_streak,
		"attempted": academics.attempted, "correct": academics.correct,
		"history": academics.question_history.duplicate(true), "stats": academics.topic_statistics.duplicate(true),
		"attendance": academics.attendance.duplicate(true), "lectures": academics.lectures_completed.duplicate(true),
		"notes": academics.notes_progress.duplicate(true), "elapsed": clock.elapsed_seconds,
		"npc_stage": npc.stage, "npc_position": npc.actor_position, "npc_spoken": npc.spoken_count,
	}
	check(expected.xp == 11 * 10 + 10 - 5 and expected.streak == 1 and expected.best == 11, "Distinct state prepared (XP %d)" % expected.xp)
	# Wipe everything, then load.
	state.return_to_title()
	await scene_changed
	await ticks(2)
	state.start_new_game()
	check(academics.xp_balance == 0 and academics.question_history.is_empty() and clock.elapsed_seconds == 0.0, "New game state is blank before loading")
	state.phase = state.Phase.TITLE
	var resumed: bool = state.continue_game()
	check(resumed, "Continue loads the save " + save.last_error)
	if not resumed:
		return
	await acquire_world()
	check(state.phase == state.Phase.CAMPUS and state.selected_character == "clay", "Location and character restored")
	check(player.appearance.preset_id == "clay", "Player spawns with the saved look")
	check(academics.xp_balance == expected.xp and academics.level == expected.level, "Progression survives reload (XP %d, Lvl %d)" % [academics.xp_balance, academics.level])
	check(academics.streak == expected.streak and academics.best_streak == expected.best, "Streaks survive reload")
	check(academics.attempted == expected.attempted and academics.correct == expected.correct, "Attempt and correct counts survive reload")
	check(academics.question_history == expected.history, "Question history survives reload exactly")
	check(academics.topic_statistics == expected.stats, "Knowledge statistics survive reload exactly")
	check(academics.attendance == expected.attendance and academics.attendance.values()[0].late, "Lateness survives reload")
	check(academics.lectures_completed == expected.lectures and academics.notes_progress == expected.notes, "Lecture completion and notes survive reload")
	check(absf(clock.elapsed_seconds - expected.elapsed) < 1.0, "Game time survives reload (%.2f vs %.2f)" % [clock.elapsed_seconds, expected.elapsed])
	check(npc.stage == expected.npc_stage and npc.actor_position.distance_to(expected.npc_position) < 0.01 and npc.spoken_count == expected.npc_spoken, "Autonomous NPC event resumes where it was")
	# Idempotent XP across the reload: repeating a saved attempt changes nothing.
	var before: int = academics.xp_balance
	answer("pd_efficacy_01", true, "save-test:3")
	check(academics.xp_balance == before, "Repeated attempt after reload awards no duplicate XP")
	# Late penalty is not re-applied by re-entering the hall after loading.
	academics.record_arrival("pharmacodynamics_01")
	check(academics.xp_balance == before, "Lateness is not charged again after reload")

func corruption() -> void:
	var good := FileAccess.get_file_as_string(save.path)
	var xp_before: int = academics.xp_balance
	var cases := {
		"garbage": "not json at all {",
		"truncated": good.left(good.length() / 2),
		"wrong version": good.replace("\"version\": 1", "\"version\": 99"),
		"negative time": JSON.stringify(_edited(good, func(d): d.clock.elapsed_seconds = -10)),
		"unknown location": JSON.stringify(_edited(good, func(d): d.location.scene = "moon")),
		"inconsistent counts": JSON.stringify(_edited(good, func(d): d.academic.correct = d.academic.attempted + 3)),
		"unknown character": JSON.stringify(_edited(good, func(d): d.selected_character = "nobody")),
	}
	for name in cases:
		var file := FileAccess.open(save.path, FileAccess.WRITE)
		file.store_string(cases[name])
		file.close()
		check(save.read().is_empty() and not save.last_error.is_empty(), "Rejects a damaged save: " + name)
	check(not state.continue_game() and academics.xp_balance == xp_before, "Continue refuses a damaged save and leaves the game untouched")
	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_string(good)
	file.close()
	check(not save.read().is_empty(), "A valid save reads again after repair")

static func _edited(text: String, edit: Callable) -> Dictionary:
	var data: Dictionary = JSON.parse_string(text)
	edit.call(data)
	return data

func resume_from_title() -> void:
	# Save inside Lecture Hall A, then continue from the real title screen.
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	check(save.save(), "Save inside the lecture hall")
	state.return_to_title()
	await scene_changed
	await ticks(3)
	var screen: Control = current_scene
	check(screen.continue_button.visible and not screen.continue_button.disabled, "Title offers Continue when a save exists")
	check(screen.continue_detail.text.contains("Lecture Hall A") and screen.continue_detail.text.contains("Clay"), "Continue shows what will be resumed: " + screen.continue_detail.text)
	check(screen.continue_button.has_focus(), "Continue is focused first")
	screen.continue_button.pressed.emit()
	await acquire_world()
	check(state.phase == state.Phase.LECTURE_HALL and dorm.name == "LectureHall", "Continue resumes in Lecture Hall A")
	check(player.global_position.distance_to(Vector3(-7.0, 0.05, -6.2)) < 0.6, "Player resumes at the hall entrance")
	state.return_to_title()
	await scene_changed
	await ticks(2)
	current_scene.new_game_button.pressed.emit()
	check(current_scene.confirm_panel.visible, "New Game confirms before replacing the save")
	current_scene.confirm_cancel.pressed.emit()
	check(state.phase == state.Phase.TITLE and save.has_save(), "Cancelling keeps the save")

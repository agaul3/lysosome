extends "res://tests/campus_test.gd"
## Full vertical-slice acceptance (spec §46), end to end with real inputs:
## launch → new game → preset → dorm → campus (NPC encounter) → Learning
## Center → Hall A → seat → lecture (explanations, visualization, 12
## questions, feedback, XP, streak, level-up) → results → exploration →
## save and reload. Each numbered check matches a step of §46.
const Seat = preload("res://world/seat.gd")
var academics: Node
var schedule: Node
var sfx: Node

func _run() -> void:
	academics = root.get_node("AcademicSession")
	schedule = root.get_node("NPCSchedule")
	sfx = root.get_node("Sfx")
	state = root.get_node("AppState")
	await play_slice()
	print("ACCEPTANCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

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

func wait_for(condition: Callable, limit := 1200) -> void:
	for index in range(limit):
		if condition.call():
			return
		await ticks(1)

func play_slice() -> void:
	# 1–3: launch, new game, preset.
	change_scene_to_file("res://ui/start_screen.tscn")
	await scene_changed
	await ticks(3)
	check(current_scene.title_panel.visible, "1 · Game launches to the title")
	await press_action("confirm")
	check(state.phase == state.Phase.CHARACTER_SELECT, "2 · New Game starts character setup")
	current_scene.selection_panel.preset_buttons[1].grab_focus()
	check(state.selected_character == "indigo", "3 · A preset appearance is chosen")
	current_scene.selection_panel.enter_button.pressed.emit()
	await acquire_world()
	# 4–6: dorm, movement, interaction.
	check(state.phase == state.Phase.DORM and player.appearance.preset_id == "indigo", "4 · Spawns in the dorm as the chosen student")
	var start := player.position
	await walk_to(Vector3(2.3, 0, 0.5))
	check(player.position.distance_to(start) > 1.0, "5 · Moves with WASD")
	await walk_to(Vector3(2.3, 0, -1.8))
	await press_interact()
	check(dorm.hud.message.text.length() > 0, "6 · Interacts with a dorm object")
	# 7–9: menu, schedule, time keeps moving.
	var clock := root.get_node("GameClock")
	var before: float = clock.now_seconds()
	await press_action("open_menu")
	check(dorm.hud.menu.visible, "7 · Opens the player menu")
	dorm.hud.menu.show_page(1)
	check(dorm.hud.schedule_panel.summary_text().contains("Pharmacodynamics"), "8 · Views today's schedule")
	await ticks(60)
	check(clock.now_seconds() - before > 4.0, "9 · Time continues while the menu is open")
	await press_action("open_menu")
	# 10–14: campus, optional interaction, the NPC event.
	await walk_to(Vector3(2.3, 0, 0.8))
	await walk_to(Vector3(3.3, 0, 1.5))
	await walk_to(Vector3(3.8, 0, 2.5))
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.CAMPUS, "10 · Leaves the dorm")
	await walk_to(Vector3(-15.4, 0, 1.5))
	await walk_to(Vector3(-17, 0, 1.6))
	await press_interact()
	check(dorm.hud.message.text.contains("Lecture Hall A"), "12 · Uses an optional campus interaction")
	await wait_for(func(): return schedule.stage == schedule.Stage.CONVERSATION)
	check(schedule.stage == schedule.Stage.CONVERSATION, "13 · Witnesses the autonomous NPC conversation")
	await wait_for(func(): return schedule.stage == schedule.Stage.TO_BUILDING)
	check(schedule.stage == schedule.Stage.TO_BUILDING, "14 · The NPC continues toward the lecture")
	await walk_to(Vector3(-9, 0, 1.5))
	await walk_to(Vector3(-9, 0, -2))
	await walk_to(Vector3(-4.6, 0, -3.8))
	await walk_to(Vector3(-1.5, 0, -9))
	await walk_to(Vector3(0, 0, -15))
	await walk_to(Vector3(0, 0, -22.2))
	check(player.interaction.target == dorm.lecture_door, "11 · Traverses the campus on foot")
	use_endpoint()
	await acquire_world()
	check(state.phase == state.Phase.LECTURE_BUILDING, "15 · Enters the lecture building")
	await walk_to(Vector3(0, 0, -2.2))
	use_endpoint()
	await acquire_world()
	# 16–18: arrival classification, penalty rule, hall.
	var arrival: Dictionary = academics.attendance.values()[0] if not academics.attendance.is_empty() else {}
	check(not arrival.is_empty(), "16 · Classified on arrival (%s)" % ("late" if arrival.get("late", false) else "on time"))
	check(academics.xp_balance == (-5 if arrival.get("late", false) else 0), "17 · Late costs exactly 5 XP, on time costs nothing")
	check(state.phase == state.Phase.LECTURE_HALL, "18 · Enters the lecture hall")
	# 19–21: seat, camera, lecture begins.
	var hall := dorm
	var seat: Node3D = hall.get_node("Seat_R2_C4")
	await walk_to(Vector3(-3.9, 0, -4.3))
	player.seating.request(seat) # Walks up the aisle and along the row by itself.
	await wait_for(func(): return player.seating.state == player.seating.State.SEATED)
	check(player.seating.state == player.seating.State.SEATED, "19 · Selects a seat and sits")
	await ticks(2)
	check(hall.lecture_camera.current, "20 · Camera transitions to the lecture view")
	if not hall.session.class_has_started():
		await press_action("confirm") # Wait for class.
	await wait_for(func(): return hall.session.state == hall.session.State.PRESENTING)
	check(hall.session.state == hall.session.State.PRESENTING, "21 · The pharmacodynamics lecture begins")
	# 22–33: the lecture itself.
	var ui: CanvasLayer = hall.lecture_ui
	check(ui.card.visible and ui.speaker.text == "DR. LENA PARK", "22 · Receives professor explanations")
	var used_model := false
	var answered := 0
	var saw_floating := false
	var saw_bar_move := false
	var saw_streak := false
	var saw_level_up := false
	var guard := 0
	var hud: CanvasLayer = hall.hud
	while hall.session.state == hall.session.State.PRESENTING and guard < 400:
		guard += 1
		var session: Node = hall.session
		if session.activity.running():
			used_model = true
			var activity: Node = session.activity
			Input.action_press("move_right")
			await wait_for(func(): return activity.phase != activity.Phase.INTRO, 600)
			Input.action_release("move_right")
			await ticks(100)
			await press_action("interact")
			if activity.phase == activity.Phase.ANTAGONIST:
				await press_action("interact")
			await press_action("move_down") # a -> b, the correct prediction
			await press_action("interact")
			answered += 1
			await press_action("interact")
			Input.action_press("move_right")
			await wait_for(func(): return activity.phase != activity.Phase.TEST, 600)
			Input.action_release("move_right")
			await press_action("interact")
			if activity.phase == activity.Phase.WRAP:
				await press_action("interact")
			continue
		if session.question.running():
			var beat: Node = session.question
			var question: Dictionary = root.get_node("QuestionBank").get_question(beat.current_id)
			var keys: Array = question.choices.keys()
			keys.sort()
			var bar_before: float = hud.progression.shown_fraction
			for step in range(keys.find(question.correct_answer)):
				await press_action("move_down")
			await press_action("interact")
			answered += 1
			check(ui.feedback.text.begins_with("Correct"), "25 · Feedback after answering: " + beat.current_id)
			saw_floating = saw_floating or hud.progression.float_layer.get_child_count() > 0
			await ticks(20)
			saw_bar_move = saw_bar_move or absf(hud.progression.shown_fraction - bar_before) > 0.01
			saw_streak = saw_streak or hud.progression.streak_chip.visible
			saw_level_up = saw_level_up or hud.progression.banner.visible
			await press_action("interact")
			continue
		await press_action("interact")
	check(used_model, "23 · Uses the interactive visualization")
	check(answered == 12, "24 · Answers the lecture's original questions (%d)" % answered)
	check(academics.xp_balance >= 190 and academics.level >= 2, "26 · Gains XP from correct answers (%d XP)" % academics.xp_balance)
	check(academics.topic_statistics["Pharmacology/Pharmacodynamics"].attempted == 12, "27 · Knowledge statistics update")
	check(saw_floating, "28 · Sees floating XP")
	check(saw_bar_move, "29 · Sees the XP bar animate")
	check(saw_streak and academics.best_streak >= 10, "30 · Streak display activates at 10 in a row")
	check(academics.level >= 2, "31 · A level-up is triggered (Lvl %d)" % academics.level)
	check(saw_level_up and sfx.history.has("level_up"), "32 · Level-up feedback is larger, with its own sound")
	check(hall.session.state == hall.session.State.SUMMARY, "33 · Completes the lecture")
	await press_action("interact")
	# 34–35: results and exploration.
	await press_action("open_menu")
	hud.menu.show_page(4)
	check(hud.knowledge_panel.value_labels["Pharmacology/Pharmacodynamics"].text == "100%   12/12", "34 · Inspects updated Pharmacodynamics performance")
	await press_action("open_menu")
	player.seating.request(seat)
	await wait_for(func(): return player.seating.state == player.seating.State.FREE)
	check(player.seating.state == player.seating.State.FREE and player.movement_enabled, "35 · Returns to exploration")
	# 36: save and reload.
	var saved := {"xp": academics.xp_balance, "level": academics.level, "stats": academics.topic_statistics.duplicate(true), "history": academics.question_history.size()}
	check(root.get_node("SaveGame").save(), "36a · Saves progress")
	state.return_to_title()
	await scene_changed
	await ticks(3)
	current_scene.continue_button.pressed.emit()
	await acquire_world()
	check(academics.xp_balance == saved.xp and academics.level == saved.level and academics.topic_statistics == saved.stats and academics.question_history.size() == saved.history, "36b · Reloads progress without corruption")
	await capture("acceptance")

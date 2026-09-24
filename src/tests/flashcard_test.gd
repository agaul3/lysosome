extends "res://tests/campus_test.gd"
const Scheduler = preload("res://education/flashcards/scheduler.gd")
var collection: Node
var save: Node
var academic: Node
var captures := false

func _run() -> void:
	state = root.get_node("AppState")
	collection = root.get_node("Flashcards")
	save = root.get_node("SaveGame")
	academic = root.get_node("AcademicSession")
	captures = DisplayServer.get_name() != "headless"
	scheduler_checks()
	collection_checks()
	await integration_checks()
	print("FLASHCARDS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func scheduler_checks() -> void:
	var s := Scheduler.fresh()
	var again := Scheduler.next(s, 1, 1000)
	var hard := Scheduler.next(s, 2, 1000)
	var good := Scheduler.next(s, 3, 1000)
	var easy := Scheduler.next(s, 4, 1000)
	check(again.phase == "learning" and again.due == 1060, "New Again returns after one minute")
	check(hard.due == 1330 and hard.ease == 2.5, "New Hard: average of learning steps, no ease penalty")
	check(good.due == 1600 and good.step == 1, "New Good advances to ten-minute step")
	check(easy.phase == "review" and easy.interval == 4, "New Easy graduates at four days")
	s = Scheduler.next(good, 3, 1600)
	check(s.phase == "review" and s.interval == 1 and s.due == 88000, "Final Good graduates at one day")
	var failed := Scheduler.next(s, 1, s.due)
	check(failed.phase == "relearning" and failed.lapses == 1 and is_equal_approx(failed.ease, 2.3), "Review lapse records forgetting and lowers ease")
	check(Scheduler.next(failed, 1, failed.due).ease == failed.ease, "Failures in relearning do not further punish ease")
	check(Scheduler.next(failed, 3, failed.due).phase == "review", "Good completes relearning")
	s.interval = 10
	s.due = 1000
	check(Scheduler.next(s, 2, 1000).interval == 12, "Review Hard uses 1.2 multiplier")
	check(Scheduler.next(s, 3, 1000).interval == 25, "Review Good uses ease")
	check(Scheduler.next(s, 4, 1000).interval > 25, "Review Easy adds bonus")
	check(Scheduler.next(s, 3, 1000 + 4 * Scheduler.DAY).interval > 25, "Overdue successful review gets interval bonus")
	s.ease = 1.3
	s.lapses = 7
	failed = Scheduler.next(s, 1, 1000)
	check(failed.ease == 1.3 and failed.suspended, "Ease floor and leech suspension")
	check(Scheduler.next(s, 0, 1000) == s, "Invalid rating does not schedule")

func collection_checks() -> void:
	state.start_new_game()
	check(collection.cards().size() == root.get_node("QuestionBank").records.size() - 1, "Standalone bank questions become cards; graph-only prompt excluded")
	var id: String = collection.cards()[0].id
	check(collection.begin_review(id), "Due new card can start")
	check(collection.rate(3).is_empty(), "Rating before revealing is rejected")
	collection.reveal()
	collection.shown_at -= 3500
	var result: Dictionary = collection.rate(1)
	check(result.xp == 2 and academic.xp_balance == 2, "Honest Again earns same study effort XP")
	check(academic.attempted == 0 and academic.streak == 0, "Self-rating cannot inflate graded accuracy or lecture streaks")
	check(collection.rate(1).is_empty(), "Double submission rejected")
	check(not collection.begin_review(id), "Future card cannot be reviewed early")
	var s: Dictionary = collection.status(id)
	s.due = collection.now() - 1
	collection.states[id] = s
	collection.begin_review(id)
	collection.reveal()
	collection.shown_at -= 3500
	check(collection.rate(3).xp == 0, "Same-day repetition earns no duplicate XP")
	var due_before: int = collection.status(id).due
	root.get_node("GameClock").advance(86400.0)
	check(collection.status(id).due == due_before and not collection.available(id, collection.now()), "Advancing academic time does not accelerate real-world review schedule")
	var second: String = collection.cards()[1].id
	collection.begin_review(second)
	collection.reveal()
	check(collection.rate(4).xp == 0, "Instant reveal and rate does not award study XP")
	var third: String = collection.cards()[2].id
	var day := str(int(collection.now() / Scheduler.DAY))
	collection.day_counts[day].xp = 100
	collection.begin_review(third)
	collection.reveal()
	collection.shown_at -= 3500
	check(collection.rate(4).xp == 0, "Daily study XP cap enforced")
	var note := {"type": "Cloze", "deck": "Personal::Physiology", "front": "{{c1::A::letter}} and {{c2::B}} then {{c1::C}}.", "back": "", "extra": "Explain why.", "tags": "test"}
	var note_id: String = collection.save_note(note)
	check(not note_id.is_empty(), "Cloze note saved")
	var c1: Dictionary = collection.card(note_id + ":c1")
	check(c1.front == "[letter] and B then […]." and c1.back == "A and B then C.", "Cloze hints, same-number deletions and sibling visibility")
	collection.begin_review(c1.id)
	collection.reveal()
	collection.rate(3)
	check(not collection.available(note_id + ":c2", collection.now()), "Cloze siblings buried until tomorrow")
	note.front = "No deletion"
	check(collection.save_note(note).is_empty(), "Invalid cloze rejected")
	collection.set_suspended(id, true)
	check(collection.status(id).suspended and not collection.begin_review(id), "Suspension removes cards from study")
	collection.set_suspended(id, false)
	collection.new_limit = 0
	check(collection.queue("Personal").is_empty(), "New-card limit enforced across collection")
	var snapshot: Dictionary = collection.snapshot()
	check(collection.validate(snapshot).is_empty(), "Collection snapshot passes validation")
	collection.reset()
	collection.restore(snapshot)
	check(collection.snapshot() == snapshot, "Collection round-trip restores schedules, notes, history and limits")
	var broken := snapshot.duplicate(true)
	broken.states[id].due = "tomorrow"
	check(not collection.validate(broken).is_empty(), "Malformed schedule rejected")
	broken = snapshot.duplicate(true)
	broken.notes[note_id].front = []
	check(not collection.validate(broken).is_empty(), "Malformed note rejected")
	state.start_new_game()
	check(collection.states.is_empty() and collection.notes.is_empty(), "New game clears all study progress")

func capture(name: String) -> void:
	if not captures:
		return
	await ticks(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/rpg_flashcards_" + name + ".png")

func integration_checks() -> void:
	state.select_character("clay")
	state.enter_dorm()
	await acquire_world()
	dorm.desk.activated.emit()
	await ticks(3)
	var pc: CanvasLayer = dorm.hud.computer
	check(dorm.hud.computer_open and pc.os_style == "windows" and not player.movement_enabled and not player.interaction.enabled, "Dorm desk opens Windows login and blocks world controls")
	check(pc.screen == "lock" and pc.wallpaper.texture == pc.WINDOWS_LOCK, "Windows opens on supplied lock image")
	check(pc.wallpaper.material is ShaderMaterial and pc.wallpaper.material.shader == preload("res://assets/pixel_wallpaper.gdshader"), "The lock photo is drawn as pixel art")
	check(dorm.pc_screen.material_override.albedo_texture == pc.viewport.get_texture(), "The OS is drawn on the monitor in the world, not over the whole view")
	await ticks(3)
	var view := root.get_viewport().get_camera_3d()
	check(view == pc.camera, "The camera moves in to the monitor")
	var quad: Vector2 = dorm.pc_screen.mesh.size
	var top_left := view.unproject_position(dorm.pc_screen.to_global(Vector3(-quad.x / 2, quad.y / 2, 0)))
	var bottom_right := view.unproject_position(dorm.pc_screen.to_global(Vector3(quad.x / 2, -quad.y / 2, 0)))
	var window := Vector2(root.get_viewport().get_visible_rect().size)
	var fraction := (bottom_right.y - top_left.y) / window.y
	check(fraction > 0.45 and fraction < 0.8 and top_left.x > 0.0 and bottom_right.x < window.x, "The screen fills most of the view with the room still visible (%d%% tall)" % int(fraction * 100))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	# Input events arrive in window pixels (the root viewport's stretch maps them to game coordinates).
	click.position = root.get_viewport().get_final_transform() * view.unproject_position(dorm.pc_screen.global_position)
	click.pressed = true
	Input.parse_input_event(click)
	await ticks(1)
	var release := click.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await ticks(3)
	check(pc.screen == "login", "Clicking the monitor in the world reaches the lock screen")
	pc.show_lock()
	await capture("windows_lock")
	await send_key(KEY_ENTER)
	check(pc.screen == "login", "Enter opens sign-in from lock screen")
	await capture("windows_login")
	pc.username.text = "player1"
	pc.password.text = "wrong"
	check(not pc.sign_in() and not pc.logged_in and not pc.login_error.text.is_empty(), "Wrong login rejected with feedback")
	pc.username.text = "another_student"
	pc.password.text = "122333"
	check(not pc.sign_in(), "Correct password with wrong username is rejected")
	pc.username.text = "player1"
	pc.password.text = "122333"
	check(pc.sign_in() and pc.logged_in, "Demo credentials log in")
	check(pc.wallpaper.texture == pc.WINDOWS_HOME, "Windows desktop uses supplied home image")
	await capture("windows_desktop")
	pc.show_lock()
	pc.open_anki()
	check(not pc.logged_in and pc.app == null, "Locking removes authentication and blocks app launch")
	pc.show_login()
	pc.password.text = "122333"
	pc.sign_in()
	pc.open_anki()
	await ticks(3)
	check(pc.app.page == "decks", "Anki opens on Decks")
	await capture("decks")
	pc.app.show_overview(collection.DEFAULT_DECK)
	pc.app.study_next()
	check(not pc.app.current.is_empty() and not collection.revealed, "Review begins with answer hidden")
	var current_id: String = pc.app.current.id
	pc.app.show_answer()
	check(collection.revealed and pc.app.rating_buttons.size() == 4, "Reveal displays four recall ratings")
	await capture("answer")
	collection.shown_at -= 3500
	pc.app.rate(3)
	check(collection.status(current_id).reps == 1, "UI rating schedules card")
	pc.app.show_editor()
	await capture("editor")
	pc.app.editor_fields.front.text = "What does a flashcard ask you to do?"
	pc.app.editor_fields.back.text = "Recall before revealing."
	pc.app._save_editor()
	check(collection.notes.size() == 1 and pc.app.page == "editor" and pc.app.editor_fields.front.text.is_empty(), "Add saves a usable note and stays open for the next, as in Anki")
	pc.app.show_browser()
	pc.app.search.text = "Recall before revealing"
	pc.app._browser_results()
	check(pc.app.browser_list.get_child_count() == 1, "Browse searches card answers")
	await capture("browse")
	pc.app.show_stats()
	await capture("stats")
	pc.app.show_options()
	await capture("options")
	check(save.save(), "Save persists the study collection")
	var data: Dictionary = save.read()
	var snapshot: Dictionary = collection.snapshot()
	collection.reset()
	check(save.apply(data) and collection.snapshot() == snapshot, "Game save restores identical collection")
	var old := data.duplicate(true)
	old.erase("flashcards")
	check(save.validate(old).is_empty(), "Pre-flashcard saves remain valid")
	var broken := data.duplicate(true)
	broken.flashcards.log = "bad"
	check(not save.validate(broken).is_empty(), "Save validation rejects corrupt review history")
	pc.close()
	await ticks(3)
	check(not dorm.hud.computer_open and player.movement_enabled and player.interaction.enabled, "Closing restores exploration")
	check(not dorm.hud.can_use_laptop(), "Laptop cannot open while standing")
	state.enter_campus("dorm")
	await acquire_world()
	state.equip("back", "slate_backpack")
	var seat: Node3D = dorm.get_node("CafeStudySeat1")
	player.global_position = seat.point(Vector3(1.0, 0.05, 0.05))
	player.seating.request(seat)
	for index in range(650):
		await ticks(1)
		if player.seating.state == player.seating.State.SEATED:
			break
	check(player.seating.state == player.seating.State.SEATED, "Player can sit at café study table using collision-aware approach")
	if player.seating.state != player.seating.State.SEATED:
		return
	check(dorm.hud.can_use_laptop(), "Backpack and study table enable laptop")
	state.equip("back", "")
	check(not dorm.hud.can_use_laptop(), "Removing backpack removes carried laptop access")
	state.equip("back", "slate_backpack")
	dorm.hud.open_laptop()
	await ticks(3)
	var laptop: CanvasLayer = dorm.hud.computer
	check(laptop.os_style == "macos" and is_instance_valid(dorm.hud.laptop_model), "Laptop opens macOS and deploys model on table")
	check(laptop.screen == "lock" and laptop.mac_wallpaper.visible, "MacBook uses its own lock screen and wallpaper")
	await capture("mac_lock")
	laptop.show_login()
	await capture("mac_login")
	laptop.username.text = "player1"
	laptop.password.text = "122333"
	laptop.sign_in()
	await capture("mac_desktop")
	laptop.open_anki()
	check(collection.status(current_id).reps == 1 and collection.notes.size() == 1, "Laptop sees PC review state and personal note")
	laptop.root.hide()
	await capture("cafe_model")
	await closeup("cafe_close", seat)
	laptop.root.show()
	laptop.close()
	await ticks(3)
	check(not is_instance_valid(dorm.hud.laptop_model), "Closing laptop removes world prop")
	player.seating.stand_up()
	await ticks(160)
	check(player.seating.state == player.seating.State.FREE, "Player can stand after packing laptop")
	state.enter_lecture_building()
	await acquire_world()
	state.enter_lecture_hall()
	await acquire_world()
	seat = dorm.get_node("Seat_R2_C4")
	player.global_position = seat.point(Vector3(0, 0.05, -0.92))
	player.seating.request(seat)
	for index in range(650):
		await ticks(1)
		if player.seating.state == player.seating.State.SEATED:
			break
	check(dorm.hud.can_use_laptop(), "Lecture seating permits carried laptop")
	if not dorm.hud.can_use_laptop():
		return
	dorm.session.wait_for_class()
	for index in range(180):
		await ticks(1)
		if dorm.session.state == dorm.session.State.PRESENTING:
			break
	check(dorm.session.state == dorm.session.State.PRESENTING and player.seating.stand_locked, "Lecture has actually started and locked the seat")
	await send_key(KEY_L)
	await ticks(2)
	check(dorm.hud.computer_open and dorm.hud.laptop_model.with_tray, "Laptop can open during locked lecture with writing tray")
	dorm.hud.computer.root.hide()
	await capture("lecture_model")
	await closeup("lecture_close", seat)
	dorm.hud.computer.root.show()
	laptop = dorm.hud.computer
	laptop.show_login()
	laptop.username.text = "player1"
	laptop.password.text = "122333"
	laptop.sign_in()
	laptop.open_anki()
	laptop.app.show_overview(collection.DEFAULT_DECK)
	laptop.app.study_next()
	var lecture_line: int = dorm.session.runner.line_index
	var lecture_card: String = laptop.app.current.id
	var reps_before: int = collection.status(lecture_card).reps
	await send_key(KEY_1)
	check(collection.status(lecture_card).reps == reps_before, "Number shortcut cannot rate an unrevealed card")
	await send_key(KEY_SPACE)
	check(collection.revealed and dorm.session.runner.line_index == lecture_line, "Space reveals the card without advancing the active lecture")
	await send_key(KEY_3)
	check(collection.status(lecture_card).reps == reps_before + 1 and dorm.session.runner.line_index == lecture_line, "Rating shortcut schedules only the card, not a lecture response")
	await send_key(KEY_TAB)
	check(not dorm.hud.settings_open and dorm.hud.computer_open, "Computer input does not open the exploration menu")
	state.set_first_person(true)
	await ticks(3)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "First-person mouse stays free during computer use")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await ticks(3)
	check(not dorm.hud.computer_open and not player.interaction.enabled and player.seating.stand_locked, "Escape closes computer without unlocking lecture seat")
	state.set_first_person(false)
	state.return_to_title()
	await scene_changed

func closeup(label: String, seat: Node3D) -> void:
	if not captures:
		return
	var view := Camera3D.new()
	current_scene.add_child(view)
	view.global_position = seat.to_global(Vector3(1.6, 1.6, -1.6))
	view.look_at(seat.to_global(Vector3(0, 0.6, -0.25)))
	view.current = true
	await capture(label)
	view.queue_free()
	dorm.camera.current = true

func send_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(2)
	event.pressed = false
	Input.parse_input_event(event)
	await ticks(1)

extends "res://tests/campus_test.gd"
## East Campus: the district's doors, the campus shuttle, the Biomedical
## Library (its PCs, a study seat and the laptop, the café, the study group,
## Level 2 and a save made there) and the Medical Education Center (the
## Testing Center's entrance, Level 2's Skills Lab door). The last few metres
## to every door and desk are walked, and the interaction checked.

func _run() -> void:
	# A failed step would leave the run waiting forever; give up instead.
	create_timer(480.0).timeout.connect(func() -> void:
		push_error("East campus test timed out")
		quit(2))
	state = root.get_node("AppState")
	state.start_new_game()
	state.equip("back", "slate_backpack")
	state.phase = state.Phase.CAMPUS
	state.campus_entry = "med_ed"
	change_scene_to_file("res://world/campus/campus.tscn")
	await acquire_world()
	await ticks(3)
	print("- district")
	await district()
	print("- shuttle")
	await shuttle()
	print("- library")
	await library()
	print("- med_ed")
	await med_ed()
	print("EAST CAMPUS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

## Runs `action` (a door, a lift, Continue) and waits, a bounded time, for
## the scene it leads to. False (and a failed check) if it never comes.
func go(action: Callable, label: String) -> bool:
	var before := current_scene
	action.call()
	for index in range(400):
		await ticks(1)
		if current_scene != before and current_scene != null and not state.transitioning:
			await ticks(3)
			if current_scene is Node3D:
				dorm = current_scene
				player = dorm.get("player")
			return true
	check(false, label + ": the scene never changed")
	return false

## Parks a building's passers-by out of the way, so scripted walks are
## repeatable (they're solid, and pause on their paths).
func quiet_walkers() -> void:
	for walker in dorm.get("walkers") if dorm.get("walkers") != null else []:
		walker.process_mode = Node.PROCESS_MODE_DISABLED
		walker.figure.position = Vector3(0, -60, 0)
	await ticks(2)

func place(at: Vector3, yaw := 0.0) -> void:
	player.global_position = at + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.appearance.rotation.y = yaw
	player.first_person.yaw = yaw
	dorm.camera.follow(player)
	await ticks(3)

func reach(point: Vector3, target: Node3D, label: String) -> void:
	await walk_to(point)
	await ticks(2)
	check(player.interaction.target == target, "%s is in reach (target: %s)" % [label, player.interaction.target.name if is_instance_valid(player.interaction.target) else "none"])

func district() -> void:
	var campus := dorm
	check(player.global_position.distance_to(Config.SPAWNS.med_ed) < 0.2, "Arrive outside the Medical Education Center")
	await reach(Vector3(68, 0, -20.2), campus.med_ed_door, "Medical Education Center door")
	await place(Config.SPAWNS.library)
	await reach(Vector3(118, 0, -19.6), campus.library_door, "Biomedical Library door")
	await place(Config.SPAWNS.student_center, PI)
	await reach(Vector3(112, 0, 19.6), campus.student_center_door, "Student Center door")
	await place(Vector3(26, 0, -19.4), PI)
	await reach(Vector3(26, 0, -20.2), campus.research_door, "Research tower door")
	await press_interact()
	check(campus.hud.message.text.contains("Badge access"), "The research tower is locked to first-years")
	await place(Config.SPAWNS.anatomy, PI)
	await walk_to(Vector3(-29, 0, -21.4))
	await reach(Vector3(-29, 0, -22.6), campus.anatomy_door, "Anatomy Hall door, up the portico steps")

func shuttle() -> void:
	var campus := dorm
	var stop: Node3D = campus.shuttle_stops.east
	await place(Config.SPAWNS.shuttle_east)
	await reach(Vector3(90.2, 0, 23.4), stop, "East shuttle stop")
	var before: float = root.get_node("GameClock").now_seconds()
	await press_interact()
	await ticks(2)
	var panel: Control = campus.hud.modal
	check(is_instance_valid(panel) and panel.find_child("Ride_quad", true, false) != null and panel.find_child("Ride_east", true, false) == null, "The route card lists the other stops")
	(panel.find_child("Ride_quad", true, false) as Button).pressed.emit()
	for index in range(120):
		await ticks(1)
		if player.global_position.distance_to(Config.SPAWNS.shuttle_quad) < 0.3 and player.movement_enabled:
			break
	check(player.global_position.distance_to(Config.SPAWNS.shuttle_quad) < 0.3, "The shuttle drops you at the quad stop")
	check(root.get_node("GameClock").now_seconds() - before >= 180.0, "The ride takes game time")
	check(state.campus_entry == "shuttle_quad" and root.get_node("Achievements").stat("shuttle_rides") == 1, "The ride is remembered for the save and counted")
	check(player.movement_enabled and not campus.hud.modal_open(), "Free to walk after the ride")

func library() -> void:
	await place(Config.SPAWNS.library)
	if not await go(dorm.library_door.activated.emit, "Enter the library"):
		return
	var building := dorm
	await quiet_walkers()
	check(state.phase == state.Phase.LIBRARY and building.zone == "ground", "Into the Biomedical Library")
	check(player.global_position.distance_to(building.anchor("entrance")) < 0.3, "Arrive inside the entrance")
	check(building.hud.location_title.contains("Biomedical Library"), "Location shows the library")
	# Through the gates to the librarian.
	await walk_to(Vector3(0, 0, 11.0))
	await reach(Vector3(-6.5, 0, 10.7), building.get_node("GroundZone/Librarian"), "Librarian")
	# A free PC in the Computer Commons.
	var pc: Node3D = building.get_node("GroundZone/LibraryPC10")
	await walk_to(Vector3(-2.6, 0, 10.7))
	await walk_to(Vector3(-2.6, 0, 4.6))
	await walk_to(Vector3(-10.0, 0, 3.1))
	await reach(Vector3(-10.0, 0, 2.95), pc, "A library PC")
	await press_interact()
	await ticks(3)
	check(building.hud.computer_open and not player.movement_enabled, "The PC opens the computer")
	building.hud.computer.close()
	await ticks(3)
	check(not building.hud.computer_open and player.movement_enabled, "Stepping away from the PC")
	# A seat at a laptop table, and the laptop.
	var seat: Node3D = building.study_seats[0]
	player.global_position = seat.point(Vector3(1.02, 0.05, 0.05))
	player.velocity = Vector3.ZERO
	await ticks(2)
	player.seating.request(seat)
	for index in range(650):
		await ticks(1)
		if player.seating.state == player.seating.State.SEATED:
			break
	check(player.seating.state == player.seating.State.SEATED, "Sit at a laptop table")
	check(building.hud.can_use_laptop(), "The laptop can come out at a library table")
	building.hud.open_laptop()
	await ticks(3)
	check(building.hud.computer_open and building.hud.computer.os_style == "macos", "The laptop opens")
	building.hud.computer.close()
	await ticks(3)
	player.seating.stand_up()
	for index in range(400):
		await ticks(1)
		if player.seating.state == player.seating.State.FREE:
			break
	check(player.seating.state == player.seating.State.FREE, "Stand up again")
	# Stacks Café.
	await place(Vector3(8.6, 0, 6.8), PI)
	await reach(Vector3(9.4, 0, 10.2), building.cafe, "Stacks Café counter")
	var wallet: Node = root.get_node("Wallet")
	var balance: int = wallet.balance
	await press_interact()
	await ticks(2)
	var shop: Control = building.hud.modal
	(shop.find_child("Buy_drip_coffee", true, false) as Button).pressed.emit()
	await ticks(2)
	check(wallet.balance < balance and root.get_node("Wellbeing").boosts.has("drink"), "Buy a coffee: money spent, boost started")
	building.hud.close_modal()
	await ticks(2)
	# The study group: nothing to review before the first lecture, then a real session.
	await place(Vector3(-1.4, 0, -8.2), PI)
	await walk_to(Vector3(-1.4, 0, -10.3))
	await reach(Vector3(-1.5, 0, -10.4), building.study_group, "Study group in Room 2")
	await press_interact()
	await ticks(2)
	var group: Control = building.hud.modal
	check(is_instance_valid(group) and group.questions.is_empty(), "No review before any lecture")
	building.hud.close_modal()
	await ticks(1)
	root.get_node("AcademicSession").lectures_completed["pharmacodynamics_01"] = {"correct": 10, "attempted": 12, "xp": 190, "accuracy": 10.0 / 12.0}
	await press_interact()
	await ticks(2)
	group = building.hud.modal
	check(group.questions.size() == 5, "Five questions from the lectures you've had")
	var xp_before: int = root.get_node("AcademicSession").xp_balance
	var clock_before: float = root.get_node("GameClock").now_seconds()
	(group.find_child("StartQuiz", true, false) as Button).pressed.emit()
	await ticks(1)
	for index in range(group.questions.size()):
		var question: Dictionary = root.get_node("QuestionBank").get_question(String(group.questions[index]))
		group.choose(String(question.correct_answer))
		group.advance()
		await ticks(1)
	check(group.screen == "summary" and int(group.summary.correct) == 5, "Answer them all")
	check(root.get_node("AcademicSession").xp_balance > xp_before, "Correct answers earn XP")
	check(root.get_node("Wellbeing").boosts.has("social") and root.get_node("GameClock").now_seconds() - clock_before >= 3500.0, "The hour passes and the Study Group boost starts")
	(group.find_child("FinishQuiz", true, false) as Button).pressed.emit()
	await ticks(2)
	await press_interact()
	await ticks(2)
	check(building.hud.modal.questions.is_empty(), "The group meets once a day")
	building.hud.close_modal()
	await ticks(1)
	# Upstairs to the quiet floor.
	await place(Vector3(10.5, 0, -6.6), PI)
	await reach(Vector3(10.5, 0, -7.6), building.get_node("GroundZone/ElevatorUp"), "The elevator")
	await press_interact()
	for index in range(60):
		await ticks(1)
		if building.zone == "level2" and player.movement_enabled:
			break
	check(building.zone == "level2" and state.interior_entry == "level2", "Level 2, the quiet floor")
	await reach(Vector3(9.0, 0, -145.9), building.get_node("Level2Zone/Exhibit1"), "The stethoscope exhibit")
	await press_interact()
	check(building.hud.message.text.contains("Laennec"), "Read the exhibit")
	# Saved on Level 2, resumed on Level 2.
	check(root.get_node("SaveGame").save(), "Save on Level 2")
	await go(state.return_to_title, "Back to the title screen")
	if not await go(func() -> void: check(state.continue_game(), "Continue the saved game"), "Continue"):
		return
	building = dorm
	await quiet_walkers()
	check(state.phase == state.Phase.LIBRARY and building.zone == "level2", "Resume on Level 2")
	await place(Vector3(10.5, 0, -146.8), PI)
	await reach(Vector3(10.5, 0, -147.6), building.get_node("Level2Zone/ElevatorDown"), "The elevator down")
	await press_interact()
	for index in range(60):
		await ticks(1)
		if building.zone == "ground" and player.movement_enabled:
			break
	check(building.zone == "ground" and state.interior_entry == "main", "Back down to Level 1")
	await place(Vector3(0, 0, 11.4), 0.0)
	await reach(Vector3(0, 0, 13.9), building.campus_exit, "The way out")
	if not await go(press_interact, "Leave the library"):
		return
	check(state.phase == state.Phase.CAMPUS and player.global_position.distance_to(Config.SPAWNS.library) < 0.3, "Out onto the Health Sciences Walk")

func med_ed() -> void:
	if state.phase != state.Phase.CAMPUS or not await go(dorm.med_ed_door.activated.emit, "Enter the Medical Education Center"):
		return
	var building := dorm
	await quiet_walkers()
	check(state.phase == state.Phase.MED_ED and building.zone == "ground", "Into the Medical Education Center")
	# The Testing Center, through its doors off the hall west of the lifts.
	await place(Vector3(-8.0, 0, -9.0), -PI / 2)
	await walk_to(Vector3(-11.0, 0, -9.0))
	var doors: Node3D = building.testing_doors
	for index in range(40):
		await ticks(1)
		if doors.is_open():
			break
	check(doors.is_open(), "The Testing Center doors open")
	await walk_to(Vector3(-13.6, 0, -9.0))
	check(player.global_position.x < -12.5, "Into the Testing Center")
	await walk_to(Vector3(-15.0, 0, -9.9))
	check(Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(building.testing_desk.x, building.testing_desk.z)) < 1.8, "At the check-in desk")
	# Level 2: the Skills Lab through its new door.
	await place(Vector3(0, 0, -14.6), PI)
	await reach(Vector3(0, 0, -15.2), building.get_node("GroundZone/ElevatorUp"), "MEC elevator")
	await press_interact()
	for index in range(60):
		await ticks(1)
		if building.zone == "level2" and player.movement_enabled:
			break
	check(building.zone == "level2", "MEC Level 2")
	for point in [Vector3(0, 0, -146.8), Vector3(9.0, 0, -145.0), Vector3(9.0, 0, -137.0), Vector3(6.2, 0, -137.0), Vector3(6.2, 0, -134.2)]:
		await walk_to(point)
	check(player.global_position.z > -134.8, "Into the Skills Lab through its door")
	await place(Vector3(9.0, 0, -142.0))
	await walk_to(Vector3(9.0, 0, -137.0))
	await walk_to(Vector3(20.0, 0, -137.0))
	check(player.global_position.x > 19.5, "Along the exam-room corridor")

extends "res://tests/east_campus_test.gd"
## Student life outside class, over the first week and into November:
## - the Student Center: joining clubs (three at most), the Campus Store
##   (clothing to wear, a study aid's bonus), the juice bar, a paid tutoring
##   shift, a break in the lounge, a workout (and its cool-down), a club room;
## - Monday evening: the shuttle to the Harbor Street Community Center, serving
##   supper with the Community Kitchen (meals served, reputation, the shirt at
##   level 2 after enough meetings), the vitals station, the shuttle home;
## - Tuesday: Medical Spanish in Club Room A;
## - Wednesday: the Club Fair on the quad, then intramural soccer;
## - Thursday: blood pressures at the free clinic;
## - the club mini-games' scoring rules, and clubs surviving a save;
## - November: Anatomy Hall, closed below until the donor dedication, then
##   the lab, its PPE room, Table 7 and the model room.
var clubs: Node
var wallet: Node
var wellbeing: Node
var achievements: Node
var clock: Node
var calendar: Node
var bank: Node

func _run() -> void:
	create_timer(900.0).timeout.connect(func() -> void:
		push_error("Student life test timed out")
		quit(2))
	state = root.get_node("AppState")
	clubs = root.get_node("Clubs")
	wallet = root.get_node("Wallet")
	wellbeing = root.get_node("Wellbeing")
	achievements = root.get_node("Achievements")
	clock = root.get_node("GameClock")
	calendar = root.get_node("YearCalendar")
	bank = root.get_node("QuestionBank")
	state.start_new_game()
	state.phase = state.Phase.CAMPUS
	state.campus_entry = "student_center"
	change_scene_to_file("res://world/campus/campus.tscn")
	await acquire_world()
	await ticks(3)
	print("- student center")
	await student_center()
	print("- community center")
	await community_evening()
	print("- medical spanish")
	await spanish_tuesday()
	print("- club fair")
	await fair_wednesday()
	print("- free clinic")
	await clinic_thursday()
	print("- rules")
	mini_game_rules()
	await save_round_trip()
	print("- anatomy")
	await anatomy_november()
	print("STUDENT LIFE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

## Moves the clock forward to a date and time.
func at_time(stamp: String) -> void:
	calendar.advance_to(Time.get_unix_time_from_datetime_string(stamp))
	await ticks(2)

func modal() -> Control:
	return dorm.hud.modal if is_instance_valid(dorm.hud.modal) else null

func press(control: Control, name_pattern: String) -> bool:
	var button := control.find_child(name_pattern, true, false) as Button
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	await ticks(1)
	return true

## Answers a club meeting's questions correctly.
func answer_all(panel: Control) -> void:
	for index in range(20):
		if panel.stage != "questions":
			return
		var question: Dictionary = bank.get_question(String(panel.questions[panel.question_index]))
		panel.choose(String(question.correct_answer))
		panel.advance()
		await ticks(1)

func student_center() -> void:
	await place(Config.SPAWNS.student_center, PI)
	if not await go(dorm.student_center_door.activated.emit, "Enter the Student Center"):
		return
	var building := dorm
	await quiet_walkers()
	check(state.phase == state.Phase.STUDENT_CENTER and building.zone == "ground", "Into the Student Center")
	check(building.hud.location_title.contains("Student Center"), "Location shows the Student Center")
	# The Office of Student Life: join three clubs, no more.
	await reach(Vector3(-9.3, 0, 6.0), building.student_life, "Office of Student Life")
	await press_interact()
	await ticks(2)
	var panel := modal()
	check(panel != null and panel.find_child("Join_community_kitchen", true, false) != null, "The club list opens")
	for id in ["community_kitchen", "free_clinic", "spanish"]:
		check(await press(panel, "Join_" + id), "Join " + id)
	check(clubs.memberships.size() == 3 and achievements.stat("clubs_joined") == 3, "Three memberships")
	var fourth := panel.find_child("Join_surgery", true, false) as Button
	check(fourth != null and fourth.disabled, "A fourth club has to wait")
	check(achievements.is_unlocked("joiner") and achievements.is_unlocked("well_rounded"), "Joiner and Well-Rounded")
	building.hud.close_modal()
	await ticks(1)
	# The Campus Store: a stethoscope to wear, a review book's bonus.
	await place(Vector3(3.0, 0, 4.0), -PI / 2)
	await walk_to(Vector3(3.8, 0, 3.2))
	await reach(Vector3(4.6, 0, 3.0), building.store, "Campus Store checkout")
	await press_interact()
	await ticks(2)
	panel = modal()
	var before: int = wallet.balance
	check(await press(panel, "Buy_stethoscope"), "Buy a stethoscope")
	check(wallet.owns_clothing("stethoscope") and wallet.balance == before - 8900, "It's yours ($89)")
	check(await press(panel, "Wear_stethoscope"), "Wear it")
	check(String(state.player_look.outfit.neck) == "stethoscope", "Wearing the stethoscope")
	panel.find_child("Tab_aids", true, false).pressed.emit()
	await ticks(1)
	var bonus_before: float = root.get_node("Skills").effect("xp:lecture")
	check(await press(panel, "Buy_review_book"), "Buy the review book")
	check(is_equal_approx(root.get_node("Skills").effect("xp:lecture"), bonus_before + 0.05), "The review book adds 5% lecture XP")
	building.hud.close_modal()
	await ticks(1)
	# Fuel Juice Bar.
	await place(Vector3(2.0, 0, -4.4), -PI / 2)
	await reach(Vector3(2.6, 0, -6.0), building.juice_bar, "Fuel Juice Bar")
	await press_interact()
	await ticks(2)
	check(await press(modal(), "Buy_green_smoothie") and wellbeing.boosts.has("drink"), "A smoothie and its boost")
	building.hud.close_modal()
	await ticks(1)
	# Peer Tutoring: nothing to teach before a lecture; then a paid shift.
	await place(Vector3(5.6, 0, -2.0), -PI / 2)
	await walk_to(Vector3(7.6, 0, -2.0))
	await reach(Vector3(7.7, 0, -2.6), building.tutoring, "Peer Tutoring desk")
	clock.elapsed_seconds += 3.0 * 3600.0 # 10:35, the desk is open
	clock.minute_changed.emit()
	await press_interact()
	await ticks(2)
	check(modal().questions.is_empty(), "No subjects to tutor before your first lecture")
	building.hud.close_modal()
	await ticks(1)
	root.get_node("AcademicSession").lectures_completed["pharmacodynamics_01"] = {"correct": 12, "attempted": 12, "xp": 190, "accuracy": 1.0}
	await press_interact()
	await ticks(2)
	panel = modal()
	check(panel.questions.size() == 6, "A shift of six questions")
	before = wallet.balance
	panel.find_child("StartQuiz", true, false).pressed.emit()
	await ticks(1)
	for index in range(panel.questions.size()):
		panel.choose(String(bank.get_question(String(panel.questions[index])).correct_answer))
		panel.advance()
		await ticks(1)
	check(panel.paid == 1000 + 1200 * 6 and wallet.balance - before >= panel.paid and achievements.stat("tutoring_shifts") == 1, "Paid for six right answers ($82)")
	check(achievements.is_unlocked("paying_it_forward"), "Paying It Forward")
	building.hud.close_modal()
	await ticks(1)
	# A break in the lounge.
	wellbeing.spend(20.0)
	var energy: float = wellbeing.energy
	await place(Vector3(-10.0, 0, -5.6), 0.0)
	await reach(Vector3(-10.0, 0, -6.4), building.lounge_break, "The lounge sofa")
	await press_interact()
	check(wellbeing.energy > energy and building.hud.message.text.contains("feet up"), "A break restores a little energy")
	await press_interact()
	check(building.hud.message.text.contains("not long ago"), "Only every couple of hours")
	# Upstairs: the Fitness Center.
	await place(Vector3(-1.0, 0, -7.6), PI)
	await reach(Vector3(-1.0, 0, -8.2), building.get_node("GroundZone/ElevatorUp"), "Student Center elevator")
	await press_interact()
	for index in range(60):
		await ticks(1)
		if building.zone == "level2" and player.movement_enabled:
			break
	check(building.zone == "level2", "Level 2")
	await walk_to(Vector3(-1.0, 0, -146.5))
	await walk_to(Vector3(-2.6, 0, -146.5))
	await walk_to(Vector3(-4.0, 0, -146.5))
	await reach(Vector3(-4.0, 0, -148.1), building.fitness, "Fitness Center desk")
	var time_before: float = clock.now_seconds()
	energy = wellbeing.energy
	await press_interact()
	await ticks(2)
	check(await press(modal(), "Workout_cardio"), "A cardio workout")
	check(wellbeing.boosts.has("exercise") and clock.now_seconds() - time_before >= 35 * 60 and wellbeing.energy < energy, "Time, energy, and an Endorphins boost")
	check(achievements.stat("workouts") == 1, "Counted toward Gym Regular")
	building.hud.close_modal()
	await ticks(1)
	await press_interact()
	await ticks(2)
	var cardio := modal().find_child("Workout_cardio", true, false) as Button
	check(cardio.disabled, "Rest before the next workout")
	building.hud.close_modal()
	await ticks(1)
	# Club Room A: Medical Spanish isn't meeting on a Monday morning.
	await place(Vector3(3.0, 0, -150.2), -PI / 2)
	await reach(Vector3(4.6, 0, -150.2), building.club_rooms.club_a, "Club Room A")
	await press_interact()
	check(building.hud.message.text.contains("Medical Spanish"), "Club Room A says who meets there")
	# Down and out.
	await place(Vector3(-1.0, 0, -147.6), PI)
	await reach(Vector3(-1.0, 0, -148.2), building.get_node("Level2Zone/ElevatorDown"), "Elevator down")
	await press_interact()
	for index in range(60):
		await ticks(1)
		if building.zone == "ground" and player.movement_enabled:
			break
	await place(Vector3(-5.0, 0, 9.2), 0.0)
	await reach(Vector3(-5.0, 0, 11.0), building.campus_exit, "Student Center exit")
	await go(press_interact, "Leave the Student Center")
	check(state.phase == state.Phase.CAMPUS, "Back outside")

func community_evening() -> void:
	await at_time("2026-09-21T17:32:00")
	await place(Config.SPAWNS.shuttle_east)
	await reach(Vector3(90.2, 0, 23.4), dorm.shuttle_stops.east, "East shuttle stop")
	await press_interact()
	await ticks(2)
	if not await go(func() -> void: modal().find_child("Ride_community", true, false).pressed.emit(), "Shuttle to Harbor Street"):
		return
	var center := dorm
	await quiet_walkers()
	check(state.phase == state.Phase.COMMUNITY and center.hud.location_title.contains("Harbor Street"), "At the Community Center")
	await walk_to(Vector3(-6.0, 0, 6.0))
	await walk_to(Vector3(-8.7, 0, 4.4))
	await walk_to(Vector3(-8.7, 0, 0.3))
	await walk_to(Vector3(-8.7, 0, -3.6))
	await walk_to(Vector3(-8.0, 0, -4.4))
	await reach(Vector3(-8.0, 0, -4.6), center.serving_line, "The serving line")
	check(center.serving_line.display_name == "Serve supper", "Supper is on, and you're a volunteer")
	await press_interact()
	await ticks(2)
	var panel := modal()
	check(panel != null and panel.get_script().resource_path.ends_with("kitchen_panel.gd"), "The kitchen's serving line")
	panel.find_child("StartEvent", true, false).pressed.emit()
	await ticks(1)
	for index in range(panel.order.size()):
		var request: Array = panel.REQUESTS[panel.order[panel.guest_index]]
		var picked := false
		for main in panel.MAINS:
			for side in panel.SIDES:
				if not picked and panel.suits(request, main, side):
					panel._pick_main(main)
					panel._pick_side(side)
					picked = true
		panel.serve()
		await ticks(1)
	check(panel.served == panel.GUESTS, "Every plate right")
	await answer_all(panel)
	check(panel.stage == "results" and achievements.stat("meals_served") == 10 and achievements.stat("club_events") == 1, "Ten meals served; a club event")
	check(clubs.points("community_kitchen") >= 29 and clubs.attended_today("community_kitchen"), "Reputation earned")
	check(wellbeing.boosts.has("meal") and String(wellbeing.boosts.meal.name) == "Shared Table", "Supper with the guests")
	panel.find_child("FinishEvent", true, false).pressed.emit()
	await ticks(2)
	await press_interact()
	await ticks(1)
	check(not center.hud.modal_open() and center.serving_line.display_name == "The serving line", "One service per meeting")
	# The free clinic meets on Thursdays and Saturdays.
	await walk_to(Vector3(-8.7, 0, -3.6))
	await walk_to(Vector3(-8.7, 0, 0.3))
	await walk_to(Vector3(-4.1, 0, 0.3))
	await walk_to(Vector3(4.6, 0, 0.3))
	await walk_to(Vector3(4.8, 0, 6.2))
	await walk_to(Vector3(7.4, 0, 6.2))
	await walk_to(Vector3(9.6, 0, 1.0))
	await reach(Vector3(9.6, 0, 0.3), center.vitals, "The vitals station")
	await press_interact()
	check(center.hud.message.text.contains("Thursdays"), "The clinic's hours")
	# Home on the shuttle.
	await place(Vector3(-6.0, 0, 8.4), PI)
	await reach(Vector3(-6.0, 0, 8.8), center.shuttle_stop, "The shuttle stop at Harbor Street")
	await press_interact()
	await ticks(2)
	if not await go(func() -> void: modal().find_child("Ride_east", true, false).pressed.emit(), "Shuttle home"):
		return
	check(state.phase == state.Phase.CAMPUS and player.global_position.distance_to(Config.SPAWNS.shuttle_east) < 0.3, "Back at the East Campus stop")

func spanish_tuesday() -> void:
	await at_time("2026-09-22T17:40:00")
	await place(Config.SPAWNS.student_center, PI)
	if not await go(dorm.student_center_door.activated.emit, "Into the Student Center"):
		return
	var building := dorm
	await quiet_walkers()
	building.transfer(building.anchor("arrival"), PI)
	for index in range(40):
		await ticks(1)
		if building.zone == "level2" and not building.riding:
			break
	await place(Vector3(3.0, 0, -150.2), -PI / 2)
	await reach(Vector3(4.6, 0, -150.2), building.club_rooms.club_a, "Club Room A")
	check(building.club_rooms.club_a.display_name.contains("Medical Spanish"), "Medical Spanish is meeting")
	await press_interact()
	await ticks(2)
	var panel := modal()
	panel.find_child("StartEvent", true, false).pressed.emit()
	await ticks(1)
	panel.find_child("ToQuestions", true, false).pressed.emit()
	await ticks(1)
	check(panel.questions.size() == 6, "Six phrases")
	await answer_all(panel)
	check(panel.stage == "results" and float(panel.result.score) == 1.0, "All six right")
	panel.find_child("FinishEvent", true, false).pressed.emit()
	await ticks(1)
	check(root.get_node("Flashcards").cards().any(func(card: Dictionary) -> bool: return String(card.id).begins_with("bank:club_spanish")), "Members get the club's flashcards")
	building.transfer(building.anchor("elevator"), PI)
	await ticks(10)
	await place(Vector3(-5.0, 0, 9.2), 0.0)
	await reach(Vector3(-5.0, 0, 11.0), building.campus_exit, "Student Center exit")
	await go(press_interact, "Leave the Student Center")

func fair_wednesday() -> void:
	await at_time("2026-09-23T13:30:00")
	var events: Node3D = dorm.campus_events
	check(is_instance_valid(events.fair_root) and events.fair_tables.size() == 7, "The Club Fair is set up on the quad")
	await place(Vector3(0, 0, -6.0), PI)
	await walk_to(Vector3(0, 0, -11.0))
	await reach(Vector3(-1.1, 0, -11.0), events.fair_tables.surgery, "The Surgery Interest Group's table")
	await press_interact()
	await ticks(2)
	var panel := modal()
	check(panel != null and panel.focus == "surgery" and calendar.completed(calendar.event("club_fair")), "Its pitch, and the fair counts as attended")
	check(await press(panel, "Leave_spanish") and await press(panel, "Join_intramurals"), "Swap Medical Spanish for intramurals")
	check(clubs.is_member("intramurals") and not clubs.is_member("spanish") and clubs.points("spanish") > 0, "Reputation kept for a club you leave")
	dorm.hud.close_modal()
	await ticks(1)
	# After the fair: pick-up soccer on the south-west lawn.
	await at_time("2026-09-23T16:25:00")
	check(not is_instance_valid(events.fair_root), "The fair is packed away")
	check(is_instance_valid(events.pitch_root), "A game on the lawn")
	await place(Vector3(-0.8, 0, 1.4), PI / 2)
	await reach(Vector3(-1.1, 0, 1.4), events.pitch_endpoint, "The pick-up game")
	await press_interact()
	await ticks(2)
	panel = modal()
	panel.find_child("StartEvent", true, false).pressed.emit()
	await ticks(1)
	for kick in range(5):
		panel.aim = [0.1, 0.5, 0.9][(panel.keeper + 1) % 3]
		panel.press()
		panel.power = 0.7
		panel.press()
		await ticks(1)
	check(panel.stage == "results" and panel.goals == 5, "Five penalties scored")
	check(wellbeing.boosts.has("exercise") and String(wellbeing.boosts.exercise.name) == "Team Spirit", "Team Spirit")
	panel.find_child("FinishEvent", true, false).pressed.emit()
	await ticks(1)

func clinic_thursday() -> void:
	await at_time("2026-09-24T17:35:00")
	await place(Config.SPAWNS.shuttle_east)
	await reach(Vector3(90.2, 0, 23.4), dorm.shuttle_stops.east, "East shuttle stop")
	await press_interact()
	await ticks(2)
	if not await go(func() -> void: modal().find_child("Ride_community", true, false).pressed.emit(), "Shuttle to Harbor Street"):
		return
	var center := dorm
	await quiet_walkers()
	await place(Vector3(9.6, 0, 0.6), 0.0)
	await reach(Vector3(9.6, 0, 0.3), center.vitals, "The vitals station")
	check(center.vitals.display_name.contains("Take vitals"), "The clinic is seeing patients")
	await press_interact()
	await ticks(2)
	var panel := modal()
	panel.find_child("StartEvent", true, false).pressed.emit()
	await ticks(1)
	for patient in range(3):
		var data: Array = panel.PATIENTS[panel.order[panel.patient]]
		# Let the cuff down to just under the systolic, record; then the diastolic.
		panel.pressure = float(data[3]) - 1.0
		panel.record()
		panel.pressure = float(data[4]) + 1.0
		panel.record()
		for wait in range(10):
			await ticks(1)
			if panel.running or panel.stage != "activity":
				break
	check(panel.stage == "questions" and is_equal_approx(panel.activity_score, 1.0), "Three blood pressures within 4 mmHg")
	await answer_all(panel)
	check(panel.stage == "results", "The clinic's questions")
	panel.find_child("FinishEvent", true, false).pressed.emit()
	await ticks(1)
	await place(Vector3(-6.0, 0, 8.4), PI)
	await reach(Vector3(-6.0, 0, 8.8), center.shuttle_stop, "The shuttle stop at Harbor Street")
	await press_interact()
	await ticks(2)
	await go(func() -> void: modal().find_child("Ride_quad", true, false).pressed.emit(), "Shuttle to the quad")
	check(player.global_position.distance_to(Config.SPAWNS.shuttle_quad) < 0.3, "Off at the quad")

func mini_game_rules() -> void:
	var Kitchen = load("res://ui/clubs/kitchen_panel.gd")
	check(Kitchen.suits(["Grace", "", ["soft"], ["dairy"], []], "soup", "squash") and not Kitchen.suits(["Grace", "", ["soft"], ["dairy"], []], "pasta", "squash"), "Soft and dairy-free: soup and squash, not the cheesy pasta")
	check(Kitchen.suits(["Dev", "", [], [], ["meat"]], "chicken", "salad") and not Kitchen.suits(["Dev", "", [], [], ["meat"]], "curry", "salad"), "\"Any meat\" means the chicken")
	var Penalties = load("res://ui/clubs/intramurals_panel.gd")
	check(Penalties.scores(0.1, 0.7, 2) and not Penalties.scores(0.1, 0.7, 0) and not Penalties.scores(0.9, 0.95, 0), "Penalties: away from the keeper, in the power band")
	var cpr = load("res://ui/clubs/cpr_panel.gd").new("emig")
	cpr.intervals = [0.52, 0.55, 0.58, 0.45, 0.7]
	check(is_equal_approx(cpr.rate_score(), 0.6), "CPR: the share of compressions at 100–120 a minute")
	cpr.free()
	var suture = load("res://ui/clubs/suturing_panel.gd").new("surgery")
	check(is_equal_approx(suture.stitch_score(suture.ideal(0), 0.0, 0), 1.0) and suture.stitch_score(suture.ideal(0) + 0.1, 30.0, 0) < 0.4, "Suturing: spacing and a square entry")
	suture.free()
	# Enough meetings bring the club's shirt at level 2.
	var shirt_before: bool = wallet.owns_clothing("kitchen_tee")
	clubs.reputation["community_kitchen"] = 39
	clubs.record("community_kitchen", 0.5)
	check(not shirt_before and clubs.level("community_kitchen") == 2 and wallet.owns_clothing("kitchen_tee"), "Level 2 in the Community Kitchen: the volunteer tee")
	var Clothing = load("res://data/clothing.gd")
	check(Clothing.unlocked("kitchen_tee") and not Clothing.unlocked("surgery_tee"), "Club shirts only come from their clubs")

func save_round_trip() -> void:
	var snapshot: Dictionary = clubs.snapshot()
	var aids: Array = wallet.owned_aids.duplicate()
	check(root.get_node("SaveGame").save(), "Save")
	clubs.reset()
	wallet.owned_aids.clear()
	check(root.get_node("SaveGame").apply(root.get_node("SaveGame").read()), "Load")
	check(clubs.snapshot() == snapshot and wallet.owned_aids == aids, "Clubs and study aids survive a save")

func anatomy_november() -> void:
	await place(Config.SPAWNS.anatomy, PI)
	await walk_to(Vector3(-29, 0, -21.4))
	await reach(Vector3(-29, 0, -22.6), dorm.anatomy_door, "Anatomy Hall door")
	if not await go(press_interact, "Enter Anatomy Hall"):
		return
	var hall := dorm
	await quiet_walkers()
	check(state.phase == state.Phase.ANATOMY and hall.zone == "ground", "Into Anatomy Hall")
	await walk_to(Vector3(4.0, 0, 3.2))
	await reach(Vector3(6.6, 0, 3.2), hall.memorial, "The donor memorial")
	await press_interact()
	check(hall.hud.message.text.contains("first patients"), "The memorial's words")
	await walk_to(Vector3(6.4, 0, 0.4))
	await reach(Vector3(6.4, 0, -0.6), hall.stairs_down, "The stair down")
	await press_interact()
	await ticks(3)
	check(hall.zone == "ground" and hall.hud.message.text.contains("November 2"), "The lab isn't open to first-years yet")
	await at_time("2026-11-02T13:00:00")
	await press_interact()
	for index in range(60):
		await ticks(1)
		if hall.zone == "lab" and player.movement_enabled:
			break
	check(hall.zone == "lab" and state.interior_entry == "lab", "Down to the Gross Anatomy Laboratory")
	await reach(Vector3(10.9, 0, -148.2), hall.ppe, "The PPE shelves")
	await press_interact()
	check(hall.hud.message.text.contains("Gown on"), "Gowned and gloved")
	await walk_to(Vector3(10.4, 0, -145.6))
	await walk_to(Vector3(12.0, 0, -142.4))
	var doors: Node3D = hall.lab_doors
	await walk_to(Vector3(12.0, 0, -141.6))
	for index in range(30):
		await ticks(1)
		if doors.is_open():
			break
	check(doors.is_open(), "The lab's doors open")
	await walk_to(Vector3(12.0, 0, -139.4))
	await walk_to(Vector3(11.6, 0, -137.0))
	await walk_to(Vector3(1.5, 0, -137.0))
	await reach(Vector3(1.5, 0, -136.7), hall.table, "Table 7")
	await press_interact()
	check(hall.hud.message.text.contains("drape"), "Your group's table")
	# Save in the lab; Continue brings you back down there.
	check(root.get_node("SaveGame").save(), "Save in the lab")
	await go(state.return_to_title, "Back to the title screen")
	if not await go(func() -> void: check(state.continue_game(), "Continue"), "Continue"):
		return
	check(state.phase == state.Phase.ANATOMY and dorm.zone == "lab", "Resume in the lab")

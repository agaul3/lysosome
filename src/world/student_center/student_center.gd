extends "res://world/interior/interior_scene.gd"
## The Student Center, at the east end of the Health Sciences Walk: where the
## first year goes when it isn't studying.
##   Level 1: the Office of Student Life (join clubs), the Campus Store, the
##            lounge (take a break, the piano), Fuel Juice Bar and Peer
##            Tutoring (a paid job) (student_center_ground.gd)
##   Level 2: the Fitness Center (work out for an Endorphins boost) and the
##            club rooms, where Medical Spanish and Journal Club meet
##            (student_center_level2.gd)
const Ground = preload("res://world/student_center/student_center_ground.gd")
const Level2 = preload("res://world/student_center/student_center_level2.gd")
const Looks = preload("res://data/looks.gd")
const ShopPanel = preload("res://ui/shop_panel.gd")
const ClubPanel = preload("res://ui/club_panel.gd")
const StorePanel = preload("res://ui/store_panel.gd")
const WorkoutPanel = preload("res://ui/workout_panel.gd")
const TutoringPanel = preload("res://ui/tutoring_panel.gd")
const ClubEvents = preload("res://ui/clubs/club_events.gd")
const LEVEL2_OFFSET := Vector3(0, 0, -140)
## Minutes between breaks in the lounge that restore energy.
const BREAK_EVERY := 120.0
## Filled in by the builders.
var entrance_doors: Array = []
var store_doors: Node3D
var tutoring_doors: Node3D
var fitness_doors: Node3D
var elevator_point: Vector3
var elevator_point_2: Vector3
var student_life_point: Vector3
var club_board_point: Vector3
var store_point: Vector3
var break_point: Vector3
var piano_point: Vector3
var juice_point: Vector3
var tutoring_point: Vector3
var fitness_point: Vector3
var club_room_points := {}
## The interactions, for tests.
var student_life: Node3D
var club_board: Node3D
var store: Node3D
var lounge_break: Node3D
var piano: Node3D
var juice_bar: Node3D
var tutoring: Node3D
var fitness: Node3D
var club_rooms := {}
var campus_exit: Node3D

func zones() -> Dictionary:
	return {
		"ground": {"title": "Student Center · Level 1", "origin": Vector3.ZERO, "min": Vector2(-8.0, -6.0), "max": Vector2(8.0, 7.0), "view": 20.0},
		"level2": {"title": "Student Center · Level 2", "origin": LEVEL2_OFFSET, "min": Vector2(-8.0, -146.0), "max": Vector2(8.0, -133.0), "view": 20.0},
	}

func builders() -> Dictionary:
	return {"ground": Ground, "level2": Level2}

func scene_key() -> String:
	return "student_center"

func arrival() -> Vector3:
	return anchor("arrival") if AppState.interior_entry == "level2" else anchor("entrance")

func arrival_yaw() -> float:
	return PI if AppState.interior_entry == "level2" else 0.0

## A student's look from a seed: a different face for every seat.
func student_look(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 43
	return Looks.random(rng)

func populate() -> void:
	build_root = zone_roots.ground
	campus_exit = add_exit("CampusExit", "Leave for the Health Sciences Walk", anchor("entrance") + Vector3(0, 1.0, 1.0), "student_center", 1.8)
	add_transfer("ElevatorUp", "Take the elevator to Level 2", elevator_point, anchor("arrival"), PI)
	student_life = add_endpoint("StudentLife", "Office of Student Life · clubs", "", student_life_point, 1.8)
	student_life.activated.connect(func() -> void: hud.open_modal(ClubPanel.new()))
	club_board = add_endpoint("ClubBoard", "Read the club board", "", club_board_point, 1.7)
	club_board.activated.connect(func() -> void: hud.open_modal(ClubPanel.new()))
	store = add_endpoint("CampusStore", "Shop at the Campus Store", "", store_point, 1.8)
	store.activated.connect(func() -> void: hud.open_modal(StorePanel.new()))
	juice_bar = add_endpoint("FuelJuiceBar", "Order at Fuel Juice Bar", "", juice_point, 1.8)
	juice_bar.activated.connect(func() -> void: hud.open_modal(ShopPanel.new("student_center_juice")))
	tutoring = add_endpoint("TutoringDesk", "Peer Tutoring · work a shift", "", tutoring_point, 1.7)
	tutoring.activated.connect(func() -> void: hud.open_modal(TutoringPanel.new()))
	lounge_break = add_endpoint("LoungeBreak", "Take a break on the sofa", "", break_point, 1.7)
	lounge_break.activated.connect(take_break)
	piano = add_endpoint("Piano", "Play the piano", "", piano_point, 1.6)
	piano.activated.connect(play_piano)
	# The lobby, past the store's glass, round the lounge between the pool
	# and ping-pong tables, and along to the tutoring door.
	add_walkers("ground", [Vector2(-5.0, 9.0), Vector2(-5.0, 4.0), Vector2(0.2, 4.0), Vector2(0.2, -2.0), Vector2(-9.3, 0.6), Vector2(-9.3, -5.2), Vector2(-3.0, -5.6), Vector2(5.4, -2.0)],
		[[0, 1], [1, 2], [2, 3], [1, 4], [4, 5], [5, 6], [6, 3], [3, 7]], 4,
		[[Vector2(-10.6, 6.0), 1.6], [Vector2(-11.6, -2.6), 1.9], [Vector2(-6.0, -2.6), 2.0], [Vector2(-1.6, 8.4), 1.0]])
	add_fill("ground", [Vector3(-9, 3.6, 5), Vector3(8, 3.6, 6), Vector3(-9, 3.6, -6), Vector3(10, 3.6, -6)], 0.3, 12.0, Color("fff0dc"))
	build_root = zone_roots.level2
	add_transfer("ElevatorDown", "Take the elevator to Level 1", elevator_point_2, anchor("elevator"), PI)
	fitness = add_endpoint("FitnessDesk", "Fitness Center · work out", "", fitness_point, 1.7)
	fitness.activated.connect(func() -> void: hud.open_modal(WorkoutPanel.new()))
	for room in club_room_points:
		var endpoint := add_endpoint("ClubRoom_" + String(room), "Club room", "", club_room_points[room], 1.6)
		endpoint.activated.connect(enter_club_room.bind(String(room)))
		club_rooms[room] = endpoint
	add_walkers("level2", [Vector2(-1.0, -146.0), Vector2(1.0, -141.0), Vector2(1.0, -132.0), Vector2(1.6, -129.4)],
		[[0, 1], [1, 2], [2, 3]], 2, [[Vector2(-1.2, -136.2), 1.8]])
	add_fill("level2", [Vector3(-9, 3.0, 0), Vector3(9, 3.0, -8), Vector3(9, 3.0, 0), Vector3(9, 3.0, 8)], 0.3, 12.0)
	build_root = self
	_refresh_rooms()
	GameClock.minute_changed.connect(_refresh_rooms)

func zone_changed(zone_name: String) -> void:
	AppState.interior_entry = "level2" if zone_name == "level2" else "main"

## A club room's prompt shows what meets there now.
func _refresh_rooms() -> void:
	for room in club_rooms:
		var meeting: Array = Clubs.meetings_at("student_center", String(room))
		var endpoint: Node3D = club_rooms[room]
		endpoint.display_name = ("Join %s" % preload("res://data/clubs.gd").get_club(String(meeting[0])).short) if not meeting.is_empty() and Clubs.is_member(String(meeting[0])) else "Club Room " + String(room).right(1).to_upper()

func enter_club_room(room: String) -> void:
	var meeting: Array = Clubs.meetings_at("student_center", room)
	if meeting.is_empty():
		var who := ""
		for id in preload("res://data/clubs.gd").CLUBS:
			var club: Dictionary = preload("res://data/clubs.gd").CLUBS[id]
			if String(club.place) == "student_center" and String(club.room) == room:
				who = "%s meets here: %s." % [club.name, Clubs.when_text(String(id))]
		hud.show_message(who if not who.is_empty() else "An empty club room: a long table, a screen and a whiteboard.", 5.0)
		return
	var id := String(meeting[0])
	if not Clubs.is_member(id):
		hud.show_message("%s is meeting. Join it at the Office of Student Life downstairs to take part." % preload("res://data/clubs.gd").get_club(id).name, 5.0)
		return
	hud.open_modal(ClubEvents.panel_for(id))

## The lounge: twenty minutes on the sofa restores a little energy, every
## couple of hours.
func take_break() -> void:
	var last := float(Achievements.stat("last_break_at"))
	var wait := last + BREAK_EVERY * 60.0 - GameClock.now_seconds()
	if wait > 0.0:
		hud.show_message("You had a break not long ago. Another in %d minutes." % int(ceil(wait / 60.0)), 4.0)
		return
	YearCalendar.pass_time(20.0)
	var gained := Wellbeing.restore(8.0)
	Achievements.set_stat("last_break_at", int(GameClock.now_seconds()))
	hud.show_message("Twenty minutes with your feet up and the game on the big screen. +%d energy." % int(round(gained)), 5.0)

func play_piano() -> void:
	YearCalendar.pass_time(10.0)
	var gained := Wellbeing.restore(3.0)
	hud.show_message("You play the one piece you still know by heart. A few people clap. +%d energy." % int(round(gained)), 5.0)

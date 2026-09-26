extends "res://world/interior/interior_scene.gd"
## The Medical Education Center, north of the Learning Center: where the
## first year is taught.
##   Level 1: the atrium and welcome desk, the Commons food court (four
##            vendors), Lecture Hall B, the Testing Center, the student
##            lounge and the elevators (med_ed_ground.gd)
##   Level 2: the Clinical Skills & Simulation Center, small-group rooms,
##            the histology lab and the skills lab (med_ed_level2.gd)
## Activities attach to the rooms (exams at the carrels, encounters in the
## exam rooms, labs at the benches); the food court's vendors sell food and
## drink through the shop panel.
const Ground = preload("res://world/med_ed/med_ed_ground.gd")
const Level2 = preload("res://world/med_ed/med_ed_level2.gd")
const Looks = preload("res://data/looks.gd")
const ShopPanel = preload("res://ui/shop_panel.gd")
const ClubEvents = preload("res://ui/clubs/club_events.gd")
const LEVEL2_OFFSET := Vector3(0, 0, -140)
## Filled in by the builders.
var entrance_doors: Array = []
var testing_doors: Node3D
var testing_desk: Vector3
## [{seat, yaw, screen}] for block exams.
var exam_carrels: Array = []
var elevator_point: Vector3
var elevator_point_2: Vector3
var exam_rooms: Array = []
var pbl_rooms: Array = []
var histology_benches: Array = []
var histology_screen: Vector3
var campus_exit: Node3D
var hall_b_doors: Array = []
var shops: Dictionary = {}
## Club rooms on Level 2: club id -> endpoint.
var club_rooms := {}
## Where scheduled activities start: room -> station (world/activity_station.gd).
var stations := {}

func zones() -> Dictionary:
	return {
		"ground": {"title": "Medical Education Center · Level 1", "origin": Vector3.ZERO, "min": Vector2(-22.0, -11.0), "max": Vector2(22.0, 12.0), "view": 22.0},
		"level2": {"title": "Medical Education Center · Level 2", "origin": LEVEL2_OFFSET, "min": Vector2(-22.0, -151.0), "max": Vector2(22.0, -128.0), "view": 22.0},
	}

func builders() -> Dictionary:
	return {"ground": Ground, "level2": Level2}

func scene_key() -> String:
	return "med_ed"

func arrival() -> Vector3:
	match AppState.med_ed_entry:
		"hall_b":
			return anchor("hall_b_doors")
		"level2":
			return anchor("arrival")
	return anchor("entrance")

func arrival_yaw() -> float:
	return -PI / 2 if AppState.med_ed_entry == "hall_b" else 0.0

## A student's look from a seed: a different face for every seat.
func student_look(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 17
	return Looks.random(rng)

func populate() -> void:
	build_root = zone_roots.ground
	campus_exit = add_exit("CampusExit", "Leave for campus", anchor("entrance") + Vector3(0, 1.0, 2.6), "med_ed", 1.8)
	for z in [4.0, 12.4]:
		var door := add_endpoint("HallBDoors", "Enter Lecture Hall B", "", Vector3(-11.4, 1.0, z), 1.7)
		door.activated.connect(AppState.enter_lecture_hall_b)
		hall_b_doors.append(door)
	add_transfer("ElevatorUp", "Take the elevator to Level 2", elevator_point, anchor("arrival"), PI)
	for vendor in Ground.VENDORS:
		var pos: Vector3 = vendor[2]
		var shop := add_endpoint("Shop_" + String(vendor[0]), "Order at %s" % vendor[1], "", pos + Vector3(-1.5, 1.0, 0), 1.8)
		shop.activated.connect(open_shop.bind(String(vendor[0])))
		shops[vendor[0]] = shop
	get_node("GroundZone/CommonsVending").activated.connect(open_shop.bind("vending"))
	# Scheduled activities: block exams at the Testing Center desk, Research Day in the atrium.
	stations["testing"] = add_station("TestingStation", "testing", testing_desk, "Testing Center check-in", "The proctor looks up. \"No exams scheduled for you today. Block exams are on the calendar in your journal.\"", 1.8)
	stations["atrium"] = add_station("AtriumStation", "atrium", Vector3(0, 1.0, 3.6), "The atrium", "", 2.0)
	stations.atrium.hide_when_idle = true
	stations.atrium.refresh()
	# Round the welcome desk to the hub, then Hall B's doors, the Commons
	# (through the low wall, down the aisle in front of the counters and into
	# the lounge) and the elevator lobby and Testing Center hall.
	add_walkers("ground", [Vector2(0, 13.0), Vector2(-4.0, 11.0), Vector2(-4.0, 5.0), Vector2(0, 1.2), Vector2(4.0, 11.0), Vector2(4.0, 5.0),
		Vector2(-9.4, 1.2), Vector2(-9.4, 7.8), Vector2(10.0, 1.2), Vector2(10.0, 4.0), Vector2(13.16, 4.0), Vector2(13.16, 6.0),
		Vector2(25.9, 6.0), Vector2(25.9, -6.0), Vector2(25.9, 15.0), Vector2(25.9, -10.6), Vector2(-1.8, -9.0), Vector2(-1.8, -12.5), Vector2(-9.8, -9.0)],
		[[0, 1], [1, 2], [2, 3], [0, 4], [4, 5], [5, 3], [3, 6], [6, 7], [3, 8], [8, 9], [9, 10], [10, 11], [11, 12], [12, 13], [12, 14], [13, 15], [3, 16], [16, 17], [16, 18]], 5,
		[[Vector2(0, 7.6), 2.8], [Vector2(-5.0, 12.2), 1.2], [Vector2(-10.4, 11.3), 2.2], [Vector2(6.5, 15.0), 1.2], [Vector2(-6.5, 15.0), 1.2]])
	add_fill("ground", [Vector3(0, 3.6, 6), Vector3(18, 3.2, 4), Vector3(18, 3.2, -12), Vector3(-21, 3.2, -13)], 0.3, 14.0)
	build_root = zone_roots.level2
	add_transfer("ElevatorDown", "Take the elevator to Level 1", elevator_point_2, anchor("elevators"), PI)
	get_node("Level2Zone/Level2Vending").activated.connect(open_shop.bind("vending"))
	# Labs, encounters and small groups on Level 2.
	stations["histology"] = add_station("HistologyStation", "histology", LEVEL2_OFFSET + Vector3(-19.0, 1.0, -3.8), "Histology Lab", "Twelve microscope benches and a projection screen. Your histology labs meet here.", 1.8)
	stations["sim"] = add_station("SimStation", "sim", LEVEL2_OFFSET + Vector3(5.8, 1.0, -2.3), "Clinical Skills Center check-in", "\"Standardized-patient encounters check in here. You're not on today's list.\"", 1.8)
	stations["skills_lab"] = add_station("SkillsLabStation", "skills_lab", LEVEL2_OFFSET + Vector3(6.0, 1.0, 11.8), "Skills Lab bench", "An ECG cart and a spirometer, set up for the physiology labs.", 1.7)
	stations["pbl"] = add_station("PBLStation", "pbl", LEVEL2_OFFSET + Vector3(-21.56, 1.0, -9.6), "Room 202", "A small-group room: eight chairs round a table, a screen and a whiteboard.", 1.7)
	# Club nights: suturing in the Skills Lab, CPR in the Simulation Suite.
	club_rooms["surgery"] = add_endpoint("SkillsLabClub", "Skills Lab", "", anchor("skills_lab") + Vector3(0.2, 1.0, 0.8), 1.7)
	club_rooms["emig"] = add_endpoint("SimSuiteClub", "Simulation Suite", "", LEVEL2_OFFSET + Vector3(12.4, 1.0, 14.5), 1.7)
	for club in club_rooms:
		club_rooms[club].activated.connect(use_club_room.bind(String(club)))
	# Along the main corridor, into the lift lobby, and round the Clinical
	# Skills check-in desk to the exam-room corridor.
	add_walkers("level2", [Vector2(-26.0, -147.0), Vector2(-19.0, -147.0), Vector2(-4.0, -147.0), Vector2(0.0, -147.0), Vector2(-3.5, -153.0),
		Vector2(6.0, -147.0), Vector2(9.0, -145.0), Vector2(9.0, -137.0), Vector2(13.0, -137.0), Vector2(28.0, -137.0)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [3, 5], [5, 6], [6, 7], [7, 8], [8, 9]], 3, [[Vector2(5.8, -143.2), 2.2]])
	add_fill("level2", [Vector3(-20, 2.9, -13), Vector3(-19, 2.9, 5), Vector3(6, 2.9, -2), Vector3(20, 2.9, 3), Vector3(20, 2.9, 14), Vector3(6, 2.9, 11)], 0.3, 13.0, Color("f6f8f6"))
	build_root = self
	_refresh_clubs()
	GameClock.minute_changed.connect(_refresh_clubs)

func zone_changed(zone_name: String) -> void:
	AppState.med_ed_entry = "level2" if zone_name == "level2" else "main"

## A room's prompt says so when its club is meeting and you're a member.
func _refresh_clubs() -> void:
	for club in club_rooms:
		var endpoint: Node3D = club_rooms[club]
		var base := "Skills Lab" if club == "surgery" else "Simulation Suite"
		endpoint.display_name = ("Join %s" % preload("res://data/clubs.gd").get_club(String(club)).short) if Clubs.meeting_on(String(club)) and Clubs.is_member(String(club)) else base

func use_club_room(club: String) -> void:
	var data: Dictionary = preload("res://data/clubs.gd").get_club(club)
	if Clubs.meeting_on(club) and Clubs.is_member(club):
		hud.open_modal(ClubEvents.panel_for(club))
	elif Clubs.meeting_on(club):
		hud.show_message("%s is meeting here. Join it at the Office of Student Life in the Student Center to take part." % data.name, 5.0)
	else:
		var about := "Task trainers, an ECG cart, a spirometer and skin pads for suturing." if club == "surgery" else "A high-fidelity manikin in a hospital bed, a crash cart, and a control room behind one-way glass."
		hud.show_message("%s %s meets here: %s." % [about, data.name, Clubs.when_text(club)], 5.0)

## Opens a vendor's menu (data/items.gd VENDORS).
func open_shop(vendor: String) -> void:
	hud.open_modal(ShopPanel.new(vendor))

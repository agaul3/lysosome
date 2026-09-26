extends RefCounted
## Medical Education Center, Level 1 (zone-local: x east, z south; the glass
## entrance on the south face, toward the overhead camera):
##   Atrium          entrance vestibule (two sets of automatic doors), the
##                   welcome desk, the building directory, a feature stair
##   The Commons     the food court along the east wing: four vendors
##                   (Pulse Coffee, Commons Grill, Harvest Bowls, Noodle
##                   Bar), tables and a student lounge behind it
##   Lecture Hall B  the west wing, with doors from the atrium
##   Testing Center  north-west: check-in, lockers, carrels for block exams
##   Elevators       north: up to Level 2 (Clinical Skills Center, small
##                   groups, histology lab)
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -30.0
const X1 := 30.0
const Z0 := -18.0
const Z1 := 18.0
const HEIGHT := 4.2
const FLOOR := Color("c9c6bf")
const COMMONS_FLOOR := Color("b9ada0")
const WALL := Color("e6e3dc")
const TERRACOTTA := Color("b8694a")
const NAVY := Color("2f4a6b")
## Where each vendor's counter is (zone-local), for the scene's shops.
const VENDORS := [
	["med_ed_coffee", "Pulse Coffee", Vector3(28.0, 0, 13.5), Color("2f8f82")],
	["med_ed_grill", "Commons Grill", Vector3(28.0, 0, 6.5), Color("c2452d")],
	["med_ed_bowls", "Harvest Bowls", Vector3(28.0, 0, -0.5), Color("4f8a3c")],
	["med_ed_noodle", "Noodle Bar", Vector3(28.0, 0, -7.5), Color("c8a24a")],
]
const ANCHORS := {
	"entrance": Vector3(0, 0, 14.6),
	"hall_b_doors": Vector3(-10.9, 0, 4.0),
	"elevators": Vector3(0, 0, -9.0),
	"testing": Vector3(-21.0, 0, -9.2),
	"commons": Vector3(19.5, 0, 4.0),
	"welcome_desk": Vector3(0, 0, 7.6),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_atrium(scene, k, at)
	_commons(scene, k, at)
	_hall_b(scene, k, at)
	_testing_center(scene, k, at)
	_north(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(12.2, -8.0, X1, Z1, COMMONS_FLOOR, 0.004)
	# North and west walls stand full height; south and east are cutaways.
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [[0.0, 3.2, 3.0]], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	# South façade glazing (first person): the campus beyond.
	for span in [[-26.0, -4.0], [4.0, 26.0]]:
		k.box("clear", Vector3((span[0] + span[1]) / 2.0, 2.2, Z1 - 0.2), Vector3(span[1] - span[0], 2.6, 0.04), Color(0.8, 0.9, 0.95, 0.35), "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 20.0), Vector3(90, 12, 0.1), Color("cfe6f1"), "fp")
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f2f1ed"))
	for x in range(-24, 30, 6):
		for z in [-13.0, -3.0, 7.0, 15.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.4, 1.4))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))

static func _atrium(scene: Node3D, k, at: Callable) -> void:
	# Entrance vestibule: two sets of automatic glass doors.
	k.wall(true, -1.8, 15.6, Z1, HEIGHT, WALL, true)
	k.wall(true, 1.8, 15.6, Z1, HEIGHT, WALL, true)
	k.wall(false, 15.6, -1.8, 1.8, HEIGHT, WALL, true, [[0.0, 3.2, 3.0]])
	var outer: Node3D = scene.add_auto_doors("EntranceOuterDoors", at.call(Vector3(0, 0, Z1)), 0.0, 3.0, true, 2.4)
	var inner: Node3D = scene.add_auto_doors("EntranceInnerDoors", at.call(Vector3(0, 0, 15.6)), 0.0, 3.0, true, 2.4)
	scene.entrance_doors = [outer, inner]
	k.box("facade", Vector3(0, 0.01, 16.8), Vector3(3.4, 0.02, 2.2), Color("4a5156"))
	# Welcome desk: curved in walnut, a staffer behind.
	k.box("walnut", Vector3(0, 0.55, 8.2), Vector3(4.2, 1.1, 0.5), Color.WHITE, "always", true)
	for side in [-1, 1]:
		k.box("walnut", Vector3(side * 2.35, 0.55, 7.4), Vector3(0.5, 1.1, 1.6), Color.WHITE, "always", true)
	k.box("facade", Vector3(0, 1.12, 8.1), Vector3(4.4, 0.05, 0.7), Color("f4f2ec"))
	Props.monitor(k, Vector3(-0.8, 1.14, 8.1), PI, 0.46)
	scene.add_figure("security", at.call(Vector3(0.6, 0, 7.0)), PI, "stand")
	scene.add_sign("Welcome · Information", at.call(Vector3(0, 1.38, 8.47)), 0.0, 18, 0.0045, "always")
	scene.add_endpoint("WelcomeDesk", "Ask at the welcome desk", "\"Morning! Lecture Hall B is through the doors on your left, the Commons on your right, and the Testing Center and the elevators are straight back. Clinical Skills and the histology lab are on Level 2.\"", at.call(Vector3(0, 1.0, 9.4)), 1.8)
	# Building directory totem.
	k.box("facade", Vector3(-5.0, 1.1, 12.2), Vector3(0.9, 2.2, 0.2), NAVY, "always", true)
	scene.add_sign("MEDICAL EDUCATION CENTER\nLevel 2  Clinical Skills Center · Small Groups\n           Histology Lab · Skills Lab\nLevel 1  Lecture Hall B · Testing Center\n           The Commons · Student Lounge", at.call(Vector3(-5.0, 1.3, 12.31)), 0.0, 16, 0.0034, "always", NAVY, Color.WHITE)
	# Feature stair up the west side of the atrium (to the Level 2 bridge).
	for step in range(12):
		k.box("walnut", Vector3(-10.4, 0.1 + step * 0.18, 13.0 - step * 0.3), Vector3(2.0, 0.2, 0.34), Color.WHITE)
	k.box("clear", Vector3(-9.35, 1.6, 11.3), Vector3(0.03, 1.0, 3.6), Color(0.84, 0.92, 0.95, 0.3), "fp")
	k.solid(Vector3(-10.4, 1.1, 11.3), Vector3(2.1, 2.2, 3.8))
	scene.add_sign("Level 2 by elevator  →", at.call(Vector3(-9.33, 2.4, 11.3)), PI / 2, 18, 0.0045, "fp")
	# Benches and planters.
	for x in [-6.5, 6.5]:
		Props.planter(k, Vector3(x, 0, 15.0), Vector3(1.4, 0.6, 1.4))
		scene.add_tree(at.call(Vector3(x, 0.6, 15.0)), 1.0)
	for x in [-7.2, 7.2]:
		Campus.sofa(k, Vector3(x, 0, 3.0), PI if x < 0 else PI, Color("5f7d8c"), 1.9)
	# Hanging banner (first person) and the zone labels on the floor.
	k.box("facade", Vector3(0, HEIGHT - 0.9, 2.0), Vector3(6.0, 0.9, 0.06), TERRACOTTA, "fp")
	scene.add_sign("Welcome, Class of 2030", at.call(Vector3(0, HEIGHT - 0.9, 2.04)), 0.0, 30, 0.009, "fp", TERRACOTTA, Color.WHITE)
	scene.add_floor_label("ATRIUM", at.call(Vector3(0, 0.012, 4.6)), 0.006)

static func _commons(scene: Node3D, k, at: Callable) -> void:
	# The food court: a low wall with an opening from the atrium.
	k.wall(true, 12.0, -8.0, Z1, 1.05, Color("b8b2a8"), false, [[4.0, 4.0, 1.05], [12.5, 3.0, 1.05]], 0.2)
	for vendor in VENDORS:
		var pos: Vector3 = vendor[2]
		Campus.vendor_stall(k, pos, -PI / 2, 4.4, vendor[3])
		scene.add_sign(String(vendor[1]), at.call(pos + Vector3(1.84, 2.72, 0)), -PI / 2, 26, 0.008, "always", Color(vendor[3]).darkened(0.1), Color.WHITE)
		scene.add_figure(_server_look(vendor[0]), at.call(pos + Vector3(1.0, 0, 0.4)), PI / 2, "stand")
	scene.add_floor_label("THE COMMONS", at.call(Vector3(19.0, 0.012, -6.4)), 0.006)
	# Tables: three columns, five rows, some with students eating.
	var eaters := 0
	for column in range(3):
		for row in range(5):
			var pos := Vector3(15.2 + column * 4.0, 0, -4.0 + row * 4.0)
			var chairs: Array = Campus.dining_set(k, pos, 0.0, 4, true)
			if (column * 5 + row) % 3 == 1:
				for pick in [0, 1]:
					var seat: Array = chairs[pick]
					scene.add_figure(scene.student_look(40 + eaters), seat[0], float(seat[1]) + PI, "seated", Campus.CHAIR_SEAT)
					eaters += 1
				k.box("facade", pos + Vector3(0, 0.66, 0.2), Vector3(0.36, 0.03, 0.26), Color("c8a24a"))
				k.box("facade", pos + Vector3(0.1, 0.66, -0.22), Vector3(0.36, 0.03, 0.26), Color("5b8fa8"))
	Campus.bins(k, Vector3(13.2, 0, 16.6), 0.0)
	# Student lounge behind the food court (north-east).
	k.wall(false, -8.4, 12.0, X1, HEIGHT, WALL, true, [[16.0, 3.0, 2.6], [26.0, 3.0, 2.6]])
	for x in [16.5, 22.5]:
		var seats: Array = Campus.sofa(k, Vector3(x, 0, -16.6), 0.0, Color("7d5a86"), 2.2)
		scene.add_figure(scene.student_look(70 + int(x)), seats[0], PI, "seated", Props.SOFA_SEAT)
	Props.round_table(k, Vector3(19.5, 0, -13.8), 0.5, 0.45)
	Campus.lockers(k, Vector3(28.5, 0, -13.0), -PI / 2, 8)
	k.box("metal", Vector3(19.5, 2.0, Z0 + 0.2), Vector3(2.6, 1.46, 0.06), Color("16202a"))
	scene.add_sign("Student Lounge", at.call(Vector3(21.0, 2.72, -8.3)), 0.0, 20, 0.005, "fp")
	for z in [-10.4, -11.4]:
		Props.vending(k, Vector3(29.4, 0, z), -PI / 2, z < -11.0)
	scene.add_endpoint("CommonsVending", "Vending machine", "", at.call(Vector3(28.4, 1.0, -10.9)), 1.5)

static func _hall_b(scene: Node3D, k, at: Callable) -> void:
	# The hall's wall with two sets of double doors, and its tiered seating
	# visible from above.
	k.wall(true, -12.0, -8.0, Z1, HEIGHT, WALL, true, [[4.0, 2.4, 2.5], [12.4, 2.4, 2.5]])
	k.wall(false, -8.0, X0, -12.0, HEIGHT, WALL, true)
	for z in [4.0, 12.4]:
		for side in [-1, 1]:
			k.box("walnut", Vector3(-12.02, 1.25, z + side * 0.6), Vector3(0.08, 2.5, 1.16), Color.WHITE, "fp")
			k.box("light", Vector3(-11.96, 1.7, z + side * 0.6), Vector3(0.02, 0.5, 0.2), Color("e8f1f5"), "fp")
		k.box("walnut", Vector3(-12.02, 0.52, z), Vector3(0.08, 1.04, 2.36), Color.WHITE, "tp")
		k.solid(Vector3(-12.0, 1.25, z), Vector3(0.2, 2.5, 2.4))
	scene.add_sign("Lecture Hall B", at.call(Vector3(-11.92, 2.95, 8.2)), PI / 2, 30, 0.008, "fp", NAVY, Color.WHITE)
	scene.add_floor_label("LECTURE HALL B", at.call(Vector3(-9.4, 0.012, 8.2)), 0.0055)
	k.floor_rect(X0 + 0.2, -7.8, -12.2, Z1 - 0.2, Color("5f6368"), 0.004)
	for tier in range(6):
		var x := -14.5 - tier * 2.4
		k.box("facade", Vector3(x, 0.19 + tier * 0.38, 5.0), Vector3(2.4, 0.38 + tier * 0.76, 22.0), Color("6a6d70"))
		for seat in range(10):
			k.box("facade", Vector3(x - 0.3, 0.55 + tier * 0.76, -5.0 + seat * 2.2), Vector3(0.6, 0.5, 1.6), Color("3f6fb0"))
	k.box("facade", Vector3(X0 + 1.0, 2.2, 5.0), Vector3(0.1, 2.6, 7.0), Color("f4f4f1"))

static func _testing_center(scene: Node3D, k, at: Callable) -> void:
	# North-west, entered from the short hall west of the elevator lobby
	# through automatic glass doors; a check-in desk just inside.
	k.wall(true, -12.0, Z0, -10.0, HEIGHT, WALL, true)
	var doors: Node3D = Campus.glass_front(scene, k, "TestingDoors", true, -12.0, -10.0, -8.0, -9.0, 1.6, false, Color("9aa2a7"), HEIGHT, WALL)
	scene.testing_doors = doors
	k.floor_rect(X0 + 0.2, Z0 + 0.2, -12.2, -8.2, Color("aeb4b6"), 0.004)
	# Check-in desk: the proctor behind it (north), facing the doors' side.
	k.box("walnut", Vector3(-15.4, 0.55, -11.0), Vector3(3.0, 1.1, 0.5), Color.WHITE, "always", true)
	k.box("facade", Vector3(-15.4, 1.12, -11.05), Vector3(3.2, 0.05, 0.64), Color("f4f2ec"))
	Props.monitor(k, Vector3(-15.9, 1.14, -11.1), PI, 0.46)
	scene.add_figure("reception", at.call(Vector3(-15.0, 0, -11.9)), PI, "stand")
	scene.testing_desk = at.call(Vector3(-15.2, 1.0, -10.1))
	Campus.lockers(k, Vector3(-27.0, 0, -9.0), PI, 8, Color("7a8d99"))
	scene.add_sign("Lockers · Phones and bags only", at.call(Vector3(-27.0, 2.0, -8.1)), PI, 16, 0.004, "fp")
	# Two rows of carrels for block exams: the north row faces the wall, the
	# south row faces north across the aisle, back to back with it.
	var carrels: Array = []
	for row in range(2):
		for index in range(6):
			var pos := Vector3(-27.4 + index * 2.4, 0, -16.8 + row * 3.6)
			Campus.carrel(k, pos, 0.0 if row == 0 else PI)
			carrels.append({"seat": at.call(pos + Vector3(0, 0, 0.62 if row == 0 else -0.62)), "yaw": 0.0 if row == 0 else PI, "screen": at.call(pos + Vector3(0, 1.08, -0.155 if row == 0 else 0.155))})
	scene.exam_carrels = carrels
	scene.add_sign("Testing Center\nQuiet please · Exams in progress", at.call(Vector3(-11.92, 2.72, -9.0)), PI / 2, 20, 0.005, "fp")
	scene.add_floor_label("TESTING CENTER", at.call(Vector3(-20.0, 0.012, -10.6)), 0.0055)

static func _north(scene: Node3D, k, at: Callable) -> void:
	# Corridor walls and the elevator lobby.
	k.wall(false, -10.0, -12.0, -7.5, HEIGHT, WALL, true)
	k.wall(false, -10.0, 7.5, 12.0, HEIGHT, WALL, true)
	k.wall(true, -7.5, Z0, -10.0, HEIGHT, WALL, true)
	k.wall(true, 7.5, Z0, -10.0, HEIGHT, WALL, true)
	for x in [-2.2, 2.2]:
		Props.elevator_frame(k, Vector3(x, 0, Z0 + 0.3), 0.0, 1.3, true)
		scene.add_indicator(at.call(Vector3(x, 2.72, Z0 + 0.38)), "1", 0.0)
	k.box("walnut", Vector3(0, 1.8, Z0 + 0.17), Vector3(8.0, 3.6, 0.04), Color.WHITE)
	scene.add_sign("Elevators · Level 2 Clinical Skills Center", at.call(Vector3(0, 3.1, Z0 + 0.2)), 0.0, 20, 0.0055, "always")
	scene.elevator_point = at.call(Vector3(0, 1.1, -16.4))
	scene.add_floor_label("ELEVATORS", at.call(Vector3(0, 0.012, -12.0)), 0.0055)
	# Restrooms (closed doors) and a water fountain.
	for x in [9.0, 11.0]:
		k.box("walnut", Vector3(x, 1.1, -10.02), Vector3(0.9, 2.2, 0.06), Color.WHITE)
	scene.add_sign("Restrooms", at.call(Vector3(10.0, 2.5, -9.96)), 0.0, 18, 0.0045, "fp")
	Props.dispenser(k, Vector3(-6.8, 1.1, -10.1), PI)

## Food-court servers in aprons over a varied base look.
static func _server_look(vendor: String) -> Variant:
	return {"med_ed_coffee": "barista", "med_ed_grill": "barista", "med_ed_bowls": "barista", "med_ed_noodle": "barista"}.get(vendor, "barista")

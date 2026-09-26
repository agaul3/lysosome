extends RefCounted
## Student Center, Level 1 (zone-local: x east, z south; the entrance on the
## south face at x −5, like the building outside):
##   Lobby                 the Office of Student Life (clubs and
##                         organizations) and the club board (west)
##   Campus Store          clothing, scrubs, stethoscopes and study aids,
##                         behind a glass front (south-east)
##   Lounge                sofas and the big screen, pool, ping-pong and a
##                         piano (north-west)
##   Fuel Juice Bar        smoothies and bowls (north, by the lifts)
##   Peer Tutoring         the tutoring center, behind glass (north-east)
##   Lifts and stairs      north, up to the Fitness Center and club rooms
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -15.0
const X1 := 15.0
const Z0 := -12.0
const Z1 := 12.0
const HEIGHT := 4.4
const FLOOR := Color("c7c2b8")
const WALL := Color("e8e4dc")
const TIMBER := Color("8a6446")
const STORE_FLOOR := Color("b9b4ab")
const LOUNGE_FLOOR := Color("7b8783")
const NAVY := Color("2f4a6b")
const STORE_RED := Color("a8322d")
const ANCHORS := {
	"entrance": Vector3(-5.0, 0, 11.0),
	"student_life": Vector3(-9.6, 0, 6.0),
	"store": Vector3(4.6, 0, 2.4),
	"lounge": Vector3(-9.0, 0, -5.0),
	"juice": Vector3(3.2, 0, -6.0),
	"tutoring": Vector3(8.2, 0, -2.4),
	"elevator": Vector3(-1.0, 0, -8.2),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_entrance(scene, k, at)
	_student_life(scene, k, at)
	_store(scene, k, at)
	_lounge(scene, k, at)
	_juice_bar(scene, k, at)
	_tutoring(scene, k, at)
	_core(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(2.2, 0.2, X1 - 0.2, Z1 - 0.2, STORE_FLOOR, 0.004)
	k.floor_rect(X0 + 0.2, Z0 + 0.2, -3.6, 1.6, LOUNGE_FLOOR, 0.004)
	# North and west walls stand full height; south and east are cutaways.
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [[-5.0, 3.2, 3.0]], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	# Storefront glazing along the south façade (first person).
	for span in [[-13.4, -7.0], [-3.0, 1.6], [2.6, 14.2]]:
		k.box("clear", Vector3((span[0] + span[1]) / 2.0, 2.2, Z1 - 0.2), Vector3(span[1] - span[0], 3.0, 0.04), Color(0.8, 0.9, 0.95, 0.35), "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 18.0), Vector3(70, 12, 0.1), Color("cfe6f1"), "fp")
	# A timber ceiling with light slots, warmer than the teaching buildings.
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("b89a78"))
	for x in [-11.0, -5.0, 1.0, 7.0, 13.0]:
		for z in [-8.0, -2.0, 4.0, 9.5]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.6, 0.3))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))

static func _entrance(scene: Node3D, k, at: Callable) -> void:
	# Vestibule: automatic doors at the façade and again inside.
	k.wall(true, -6.9, 10.2, Z1, HEIGHT, WALL, true)
	k.wall(true, -3.1, 10.2, Z1, HEIGHT, WALL, true)
	k.wall(false, 10.2, -6.9, -3.1, HEIGHT, WALL, true, [[-5.0, 3.2, 3.0]])
	var outer: Node3D = scene.add_auto_doors("EntranceOuterDoors", at.call(Vector3(-5.0, 0, Z1)), 0.0, 3.0, true, 2.4)
	var inner: Node3D = scene.add_auto_doors("EntranceInnerDoors", at.call(Vector3(-5.0, 0, 10.2)), 0.0, 3.0, true, 2.4)
	scene.entrance_doors = [outer, inner]
	k.box("facade", Vector3(-5.0, 0.01, 11.1), Vector3(3.4, 0.02, 1.6), Color("4a5156"))
	# Directory totem inside the doors.
	k.box("facade", Vector3(-1.6, 1.1, 8.4), Vector3(0.9, 2.2, 0.2), NAVY, "always", true)
	scene.add_sign("STUDENT CENTER\nLevel 2  Fitness Center · Club Rooms A–C\nLevel 1  Office of Student Life\n           Campus Store · Peer Tutoring\n           Lounge · Fuel Juice Bar", at.call(Vector3(-1.6, 1.3, 8.51)), 0.0, 16, 0.0034, "always", NAVY, Color.WHITE)
	# Lobby seating by the windows.
	for x in [-12.6, -9.4]:
		Props.armchair(k, Vector3(x, 0, 10.4), PI, Color("7d5a86"))
	Props.round_table(k, Vector3(-11.0, 0, 10.6), 0.4, 0.45)
	scene.add_figure(scene.student_look(510), at.call(Vector3(-12.6, 0, 10.4)), 0.0, "seated", Props.ARMCHAIR_SEAT)
	for x in [-13.8, 0.4]:
		Props.planter(k, Vector3(x, 0, 11.0), Vector3(1.0, 0.6, 1.0))
		scene.add_tree(at.call(Vector3(x, 0.6, 11.0)), 0.8)

static func _student_life(scene: Node3D, k, at: Callable) -> void:
	# The Office of Student Life: a desk facing the lobby, the staffer behind it.
	k.box("walnut", Vector3(-10.8, 0.55, 6.0), Vector3(0.6, 1.1, 3.4), Color.WHITE, "always", true)
	k.box("facade", Vector3(-10.8, 1.12, 6.0), Vector3(0.72, 0.05, 3.6), Color("f4f2ec"))
	Props.monitor(k, Vector3(-10.9, 1.14, 5.2), -PI / 2, 0.44)
	scene.add_figure("reception", at.call(Vector3(-11.8, 0, 6.3)), -PI / 2, "stand")
	k.box("facade", Vector3(X0 + 0.17, 2.7, 6.0), Vector3(0.03, 0.9, 4.2), NAVY, "fp")
	scene.add_sign("Office of Student Life · Clubs & Organizations", at.call(Vector3(X0 + 0.19, 2.7, 6.0)), PI / 2, 22, 0.0052, "fp", NAVY, Color.WHITE)
	scene.student_life_point = at.call(Vector3(-9.9, 1.0, 6.0))
	# The club board on the west wall, south of the lounge.
	Campus.bulletin_board(k, Vector3(X0 + 0.2, 1.55, 1.6), PI / 2, 3.0, 1.2)
	scene.add_sign("Student Organizations", at.call(Vector3(X0 + 0.22, 2.42, 1.6)), PI / 2, 18, 0.0045, "fp")
	scene.club_board_point = at.call(Vector3(X0 + 0.9, 1.2, 1.6))
	scene.add_floor_label("STUDENT LIFE", at.call(Vector3(-8.2, 0.012, 3.8)), 0.005)

static func _store(scene: Node3D, k, at: Callable) -> void:
	# Glass front on the lobby with automatic doors.
	var doors: Node3D = Campus.glass_front(scene, k, "StoreDoors", true, 2.0, 0.0, 10.2, 4.0, 1.8, false, Color("9aa2a7"), HEIGHT, WALL)
	scene.store_doors = doors
	k.wall(false, 0.0, 2.0, X1, HEIGHT, WALL, true)
	k.wall(true, 2.0, 10.2, Z1, HEIGHT, WALL, true)
	k.box("facade", Vector3(1.9, 3.1, 4.0), Vector3(0.05, 0.6, 4.4), STORE_RED, "fp")
	scene.add_sign("CAMPUS STORE", at.call(Vector3(1.87, 3.1, 4.0)), -PI / 2, 32, 0.0075, "fp", STORE_RED, Color.WHITE)
	# Checkout by the door; the clerk behind it.
	Campus.checkout(k, Vector3(4.6, 0, 1.6), 0.0, 2.4)
	scene.add_figure("barista", at.call(Vector3(4.2, 0, 0.75)), PI, "stand")
	scene.store_point = at.call(Vector3(4.6, 1.0, 2.4))
	# Racks: scrubs, club and class wear, jackets.
	var palettes := [["7fa7c9", "667fab", "7fa7c9", "343d5c"], ["2f4a6b", "e9e4da", "8c2f32", "2f4a6b"], ["26282b", "1f3558", "3a424b", "5d6b43"]]
	var index := 0
	for z in [4.4, 7.0, 9.4]:
		for x in [7.6, 11.6]:
			Campus.clothing_rack(k, Vector3(x, 0, z), 0.0, palettes[index % palettes.size()], 2.2)
			index += 1
	# Scrubs wall and the study-aid shelves.
	for z in [3.0, 7.2]:
		Props.shelving(k, Vector3(X1 - 0.45, 0, z), -PI / 2, 3.6, 5)
	scene.add_sign("Scrubs · Shoes · Stethoscopes", at.call(Vector3(X1 - 0.17, 2.6, 5.1)), -PI / 2, 18, 0.0045, "fp")
	Campus.book_stack(k, Vector3(9.4, 0, 0.55), 0.0, 5.0, 1.6)
	scene.add_sign("Study Aids · Review Books", at.call(Vector3(9.4, 2.15, 0.1)), 0.0, 16, 0.004, "fp")
	# Stethoscopes in a glass case.
	Campus.display_case(k, Vector3(5.2, 0, 7.4), -PI / 2, Color("2a2d31"))
	scene.add_figure(scene.student_look(520), at.call(Vector3(11.6, 0, 5.7)), PI, "stand")
	scene.add_floor_label("CAMPUS STORE", at.call(Vector3(8.6, 0.012, 11.0)), 0.005)

static func _lounge(scene: Node3D, k, at: Callable) -> void:
	# The big screen on the north wall, sofas facing it.
	k.box("metal", Vector3(-10.0, 1.9, Z0 + 0.19), Vector3(3.4, 1.9, 0.06), Color("16202a"))
	k.box("light", Vector3(-10.0, 1.9, Z0 + 0.225), Vector3(3.24, 1.76, 0.005), Color("2d5a73"))
	var sofa: Array = Campus.sofa(k, Vector3(-10.0, 0, -8.0), PI, Color("4f6f86"), 2.4)
	scene.add_figure(scene.student_look(530), at.call(sofa[0]), 0.0, "seated", Props.SOFA_SEAT)
	for side in [-1, 1]:
		Props.armchair(k, Vector3(-10.0 + side * 2.4, 0, -9.2), PI + side * 0.5, Color("5f7d8c"))
	Props.round_table(k, Vector3(-10.0, 0, -9.6), 0.45, 0.4)
	scene.break_point = at.call(Vector3(-10.0, 1.0, -7.0))
	# Pool and ping-pong, with players.
	Campus.pool_table(k, Vector3(-11.6, 0, -2.6), 0.0)
	scene.add_figure(scene.student_look(531), at.call(Vector3(-11.6, 0, -1.3)), 0.0, "stand")
	Campus.ping_pong(k, Vector3(-6.0, 0, -2.6), 0.0)
	for side in [-1, 1]:
		scene.add_figure(scene.student_look(532 + side), at.call(Vector3(-6.0 + side * 1.9, 0, -2.6)), side * PI / 2, "stand")
	# The piano against the west wall.
	Campus.piano(k, Vector3(X0 + 0.45, 0, -6.4), PI / 2)
	scene.piano_point = at.call(Vector3(X0 + 1.4, 1.0, -6.4))
	scene.add_floor_label("LOUNGE", at.call(Vector3(-8.4, 0.012, 0.4)), 0.006)

static func _juice_bar(scene: Node3D, k, at: Callable) -> void:
	Campus.vendor_stall(k, Vector3(4.8, 0, -6.0), -PI / 2, 4.0, Color("e98a4f"))
	scene.add_sign("Fuel Juice Bar", at.call(Vector3(6.64, 2.72, -6.0)), -PI / 2, 26, 0.008, "always", Color("c8742f"), Color.WHITE)
	scene.add_figure("barista", at.call(Vector3(5.8, 0, -5.6)), PI / 2, "stand")
	scene.juice_point = at.call(Vector3(3.3, 1.0, -6.0))
	for z in [-10.6, -8.4]:
		Campus.high_table(k, Vector3(2.4, 0, z), PI / 2)

static func _tutoring(scene: Node3D, k, at: Callable) -> void:
	# A glass-fronted room off the lounge side, entered by its door at z −2.
	k.wall(true, 7.0, Z0, -4.0, HEIGHT, WALL, true)
	var doors: Node3D = Campus.glass_front(scene, k, "TutoringDoors", true, 7.0, -4.0, 0.0, -2.0, 1.6, false, Color("9aa2a7"), HEIGHT, WALL)
	scene.tutoring_doors = doors
	k.floor_rect(7.2, Z0 + 0.2, X1 - 0.2, -0.2, Color("c9ccc6"), 0.004)
	k.box("walnut", Vector3(8.6, 0.55, -4.6), Vector3(0.6, 1.1, 2.4), Color.WHITE, "always", true)
	Props.monitor(k, Vector3(8.7, 1.1, -4.2), PI / 2, 0.42)
	scene.add_figure("coordinator", at.call(Vector3(9.5, 0, -4.9)), PI / 2, "stand")
	scene.tutoring_point = at.call(Vector3(7.9, 1.0, -3.4))
	for spot in [Vector3(12.0, 0, -2.8), Vector3(12.0, 0, -8.4)]:
		var chairs: Array = Campus.group_table(k, spot, PI / 2, 6)
		for pick in [0, 3]:
			var chair: Array = chairs[pick]
			scene.add_figure(scene.student_look(540 + int(spot.z) + pick), at.call(chair[0]), float(chair[1]) + PI, "seated", Props.OFFICE_SEAT)
	Campus.whiteboard(k, Vector3(11.0, 0, Z0 + 0.17), 0.0, 3.0)
	scene.add_sign("Peer Tutoring · Learning Specialists", at.call(Vector3(6.93, 2.72, -2.0)), -PI / 2, 20, 0.005, "fp")
	scene.add_floor_label("PEER TUTORING", at.call(Vector3(10.4, 0.012, -0.9)), 0.0045)

static func _core(scene: Node3D, k, at: Callable) -> void:
	# Lifts and stairs in the middle of the north wall.
	k.wall(true, -3.4, Z0, -9.5, HEIGHT, WALL, true)
	k.wall(true, 1.4, Z0, -9.5, HEIGHT, WALL, true)
	k.wall(false, -9.5, -3.4, 1.4, HEIGHT, WALL, true)
	Props.elevator_frame(k, Vector3(-1.0, 0, -9.42), 0.0, 1.3, true)
	scene.add_indicator(at.call(Vector3(-1.0, 2.72, -9.38)), "1", 0.0)
	k.box("walnut", Vector3(0.7, 1.1, -9.38), Vector3(0.9, 2.2, 0.06), Color.WHITE)
	scene.add_sign("Stairs", at.call(Vector3(0.7, 2.45, -9.4)), 0.0, 14, 0.0035, "fp")
	scene.add_sign("Level 2 · Fitness Center · Club Rooms", at.call(Vector3(-1.0, 3.3, -9.4)), 0.0, 18, 0.0045, "fp")
	scene.elevator_point = at.call(Vector3(-1.0, 1.1, -8.8))

extends RefCounted
## Biomedical Library, Level 1 (zone-local: x east, z south; the entrance on
## the south face, toward the overhead camera). Laid out like a health
## sciences library's main floor:
##   Entrance          vestibule with two sets of automatic doors, then the
##                     book-security gates
##   Circulation       the circulation and reference desk (the librarian)
##   Computer Commons  the west side: twelve PCs (the in-game computer, with
##                     the flashcard app) and a print station
##   Reading area      laptop tables down the middle (sit, then open the laptop)
##   Group study       three glass study rooms along the north wall
##   Stacks Café       coffee and snacks in the south-east corner
##   Stair and lift    north-east, up to the quiet floor (Level 2)
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -14.0
const X1 := 14.0
const Z0 := -15.0
const Z1 := 15.0
const HEIGHT := 4.6
const FLOOR := Color("c9c3b8")
const WALL := Color("ebe6dc")
const CARPET := Color("7f8b87")
const CAFE_FLOOR := Color("b9a58c")
const NAVY := Color("2f4a6b")
const BRONZE := Color("7d6146")
## Group study rooms: [name, x0, x1].
const STUDY_ROOMS := [["Study Room 1 · Galen", -14.0, -7.0], ["Study Room 2 · Vesalius", -7.0, 0.0], ["Study Room 3 · Harvey", 0.0, 7.0]]
const ANCHORS := {
	"entrance": Vector3(0, 0, 13.9),
	"elevator": Vector3(10.5, 0, -8.4),
	"circulation": Vector3(-6.5, 0, 10.0),
	"cafe": Vector3(10.2, 0, 10.2),
	"study_room": Vector3(-3.5, 0, -11.0),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_entrance(scene, k, at)
	_computer_commons(scene, k, at)
	_reading_area(scene, k, at)
	_study_rooms(scene, k, at)
	_cafe(scene, k, at)
	_core(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(-13.8, -8.8, -4.2, 5.2, CARPET, 0.004)
	k.floor_rect(-0.6, -8.8, 12.6, 5.2, CARPET, 0.004)
	k.floor_rect(5.6, 6.2, X1, Z1, CAFE_FLOOR, 0.004)
	# North and west walls stand full height; south and east are cutaways.
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [[0.0, 3.2, 3.0]], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	# The glazed bays either side of the portal (first person): the walk beyond.
	for span in [[-12.4, -3.6], [3.6, 12.4]]:
		k.box("clear", Vector3((span[0] + span[1]) / 2.0, 2.3, Z1 - 0.2), Vector3(span[1] - span[0], 3.0, 0.04), Color(0.8, 0.9, 0.95, 0.35), "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 18.0), Vector3(70, 12, 0.1), Color("cfe6f1"), "fp")
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f2efe8"))
	for x in [-10.0, -4.0, 2.0, 8.0]:
		for z in [-12.0, -5.0, 1.0, 8.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.4, 1.4))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))

static func _entrance(scene: Node3D, k, at: Callable) -> void:
	# Vestibule: automatic doors at the façade and again inside.
	k.wall(true, -1.9, 12.8, Z1, HEIGHT, WALL, true)
	k.wall(true, 1.9, 12.8, Z1, HEIGHT, WALL, true)
	k.wall(false, 12.8, -1.9, 1.9, HEIGHT, WALL, true, [[0.0, 3.2, 3.0]])
	var outer: Node3D = scene.add_auto_doors("EntranceOuterDoors", at.call(Vector3(0, 0, Z1)), 0.0, 3.0, true, 2.4)
	var inner: Node3D = scene.add_auto_doors("EntranceInnerDoors", at.call(Vector3(0, 0, 12.8)), 0.0, 3.0, true, 2.4)
	scene.entrance_doors = [outer, inner]
	k.box("facade", Vector3(0, 0.01, 13.9), Vector3(3.4, 0.02, 2.0), Color("4a5156"))
	for x in [-1.2, 1.2]:
		Campus.security_gate(k, Vector3(x, 0, 11.6), 0.0)
	# Circulation and reference desk, west of the gates.
	k.box("walnut", Vector3(-6.5, 0.53, 8.9), Vector3(4.6, 1.06, 0.55), Color.WHITE, "always", true)
	for x in [-8.95, -4.05]:
		k.box("walnut", Vector3(x, 0.53, 8.1), Vector3(0.5, 1.06, 1.5), Color.WHITE, "always", true)
	k.box("facade", Vector3(-6.5, 1.08, 8.85), Vector3(4.8, 0.05, 0.7), Color("f4f2ec"))
	Props.monitor(k, Vector3(-7.6, 1.1, 8.8), PI, 0.44)
	Props.monitor(k, Vector3(-5.2, 1.1, 8.8), PI, 0.44)
	k.box("facade", Vector3(-3.6, 0.5, 9.9), Vector3(0.6, 1.0, 0.5), BRONZE, "always", true)
	scene.add_sign("Book return", at.call(Vector3(-3.6, 0.82, 10.16)), 0.0, 14, 0.0035, "always")
	scene.add_figure("librarian", at.call(Vector3(-6.0, 0, 7.9)), PI, "stand")
	scene.add_sign("Circulation · Reference", at.call(Vector3(-6.5, 0.72, 9.18)), 0.0, 18, 0.0045, "always", NAVY, Color.WHITE)
	scene.add_endpoint("Librarian", "Talk to the librarian", "\"Welcome to the Biomedical Library! The PCs in the Computer Commons have the flashcard software, and every table has power for your laptop. The group study rooms are along the north wall, and upstairs is the quiet floor: the reading room, the stacks and our history-of-medicine exhibit. Open seven in the morning until two.\"", at.call(Vector3(-6.5, 1.0, 9.9)), 1.7)
	# Directory and hours by the gates.
	k.box("facade", Vector3(4.2, 1.1, 12.2), Vector3(0.9, 2.2, 0.2), NAVY, "always", true)
	scene.add_sign("BIOMEDICAL LIBRARY\nLevel 2  Quiet Reading Room · Stacks\n           Special Collections\nLevel 1  Circulation · Computer Commons\n           Group Study · Stacks Café\nOpen 7 AM – 2 AM", at.call(Vector3(4.2, 1.3, 12.31)), 0.0, 16, 0.0034, "always", NAVY, Color.WHITE)
	for x in [-4.6, 7.6]:
		Props.planter(k, Vector3(x, 0, 13.8), Vector3(1.2, 0.6, 1.2))
		scene.add_tree(at.call(Vector3(x, 0.6, 13.8)), 0.9)
	scene.add_floor_label("CIRCULATION", at.call(Vector3(-6.5, 0.012, 11.2)), 0.005)

static func _computer_commons(scene: Node3D, k, at: Callable) -> void:
	scene.add_sign("Computer Commons", at.call(Vector3(X0 + 0.17, 2.9, -1.5)), PI / 2, 26, 0.007, "fp", NAVY, Color.WHITE)
	scene.add_floor_label("COMPUTER COMMONS", at.call(Vector3(-9.0, 0.012, 4.2)), 0.005)
	var occupied := [1, 6, 8, 11]
	var index := 0
	for z in [-6.5, -2.5, 1.5]:
		for x in [-12.2, -10.0, -7.8, -5.6]:
			var pos := Vector3(x, 0, z)
			var screen: Vector3 = Campus.pc_desk(k, pos, 0.0)
			if occupied.has(index):
				scene.add_figure(scene.student_look(300 + index), at.call(pos + Vector3(0, 0, 0.62)), 0.0, "seated", Props.OFFICE_SEAT)
				k.box("light", screen + Vector3(0, 0, 0.004), Vector3(0.5, 0.28, 0.004), Color("3d6f8f"))
			else:
				var pc: Node3D = scene.add_pc("LibraryPC%d" % (index + 1), at.call(screen), 0.0, at.call(pos + Vector3(0, 1.15, 0.28)), "Use a library PC", Vector2(0.5, 0.281))
				scene.library_pcs.append(pc)
			index += 1
	# Print station against the west wall.
	k.box("facade", Vector3(-13.3, 0.45, 4.2), Vector3(0.8, 0.9, 1.4), Color("d9dcde"), "always", true)
	k.box("facade", Vector3(-13.3, 1.02, 4.2), Vector3(0.7, 0.24, 1.1), Color("3a4045"))
	scene.add_sign("Print · Copy · Scan", at.call(Vector3(X0 + 0.17, 1.9, 4.2)), PI / 2, 16, 0.0042, "fp")

static func _reading_area(scene: Node3D, k, at: Callable) -> void:
	scene.add_floor_label("READING AREA", at.call(Vector3(4.6, 0.012, 5.0)), 0.005)
	var tables := [Vector3(2.6, 0, -6.2), Vector3(2.6, 0, -1.8), Vector3(2.6, 0, 2.6), Vector3(7.8, 0, -6.2), Vector3(7.8, 0, -1.8), Vector3(7.8, 0, 2.6)]
	var number := 0
	for table in tables:
		var seats: Array = Campus.study_table(k, table, 0.0, 2.8, 2, false)
		for seat in seats:
			var occupant := {}
			if number % 5 == 2 or number % 7 == 4:
				occupant = scene.student_look(340 + number)
			var chair: Node3D = scene.add_seat("StudySeat%d" % (number + 1), at.call(seat[0]), seat[1], Campus.STUDY_LAPTOP, Color("4f6f86"), occupant)
			if occupant.is_empty():
				scene.study_seats.append(chair)
			number += 1
	# New books along the east wall.
	Campus.book_stack(k, Vector3(13.4, 0, -2.0), PI / 2, 9.0, 1.7)
	scene.add_sign("New & Noteworthy", at.call(Vector3(13.19, 1.95, -2.0)), -PI / 2, 18, 0.0045, "fp")

static func _study_rooms(scene: Node3D, k, at: Callable) -> void:
	# Glass fronts on the corridor at z = −9.5, each with a door; a table and a screen inside.
	for index in range(STUDY_ROOMS.size()):
		var room: Array = STUDY_ROOMS[index]
		var x0: float = room[1]
		var x1: float = room[2]
		var door_x := x1 - 1.4
		if index > 0:
			k.wall(true, x0, Z0, -9.5, HEIGHT, WALL, true, [], 0.14)
		k.wall(false, -9.5, x0, x1, 0.9, WALL, true, [[door_x, 1.2, 0.9]], 0.12)
		k.box("clear", Vector3((x0 + door_x - 0.6) / 2.0, 1.9, -9.5), Vector3(door_x - 0.6 - x0, 2.0, 0.04), Color(0.82, 0.92, 0.95, 0.3), "fp")
		k.box("clear", Vector3((door_x + 0.6 + x1) / 2.0, 1.9, -9.5), Vector3(x1 - door_x - 0.6, 2.0, 0.04), Color(0.82, 0.92, 0.95, 0.3), "fp")
		k.box("facade", Vector3((x0 + x1) / 2.0, 3.6, -9.5), Vector3(x1 - x0, 1.99, 0.14), WALL, "fp")
		k.solid(Vector3((x0 + door_x - 0.6) / 2.0, 1.5, -9.5), Vector3(door_x - 0.6 - x0, 3.0, 0.14))
		k.solid(Vector3((door_x + 0.6 + x1) / 2.0, 1.5, -9.5), Vector3(x1 - door_x - 0.6, 3.0, 0.14))
		var doors: Node3D = scene.add_doors("StudyRoomDoor%d" % (index + 1), at.call(Vector3(door_x, 0, -9.5)), 0.0, 1.1, 2.3, true, Color("9aa2a7"), Color("b9a88f"))
		doors.auto_target = scene.player_target()
		doors.auto_group = "door_openers"
		doors.auto_depth = 1.4
		doors.speed = 2.4
		scene.add_fp_node(doors)
		var centre := Vector3((x0 + x1) / 2.0 - 0.4, 0, -12.6)
		var chairs: Array = Campus.group_table(k, centre, 0.0, 6)
		if index == 1:
			# Room 2 is where the class study group meets.
			for pick in [0, 3, 4]:
				var chair: Array = chairs[pick]
				scene.add_figure(scene.student_look(360 + pick), at.call(chair[0]), float(chair[1]) + PI, "seated", Props.OFFICE_SEAT)
		Campus.whiteboard(k, Vector3((x0 + x1) / 2.0 - 0.4, 0, Z0 + 0.17), 0.0, 2.6, index != 1)
		k.box("metal", Vector3(x0 + 0.2, 1.8, -12.4), Vector3(0.06, 0.9, 1.5), Color("16202a"))
		scene.add_sign(String(room[0]), at.call(Vector3(door_x - 1.4, 2.35, -9.42)), 0.0, 16, 0.004, "fp")
	scene.study_group = scene.add_endpoint("StudyGroup", "Join the study group", "", at.call(Vector3(-2.2, 1.0, -10.8)), 1.8)
	scene.add_floor_label("GROUP STUDY", at.call(Vector3(-3.5, 0.012, -8.4)), 0.005)

static func _cafe(scene: Node3D, k, at: Callable) -> void:
	Campus.vendor_stall(k, Vector3(11.9, 0, 10.2), -PI / 2, 3.6, Color("7d6146"))
	scene.add_sign("Stacks Café", at.call(Vector3(13.72, 2.72, 10.2)), -PI / 2, 26, 0.008, "always", Color("6a5139"), Color.WHITE)
	scene.add_figure("barista", at.call(Vector3(12.9, 0, 10.4)), PI / 2, "stand")
	scene.cafe = scene.add_endpoint("StacksCafe", "Order at Stacks Café", "", at.call(Vector3(10.4, 1.0, 10.2)), 1.8)
	for z in [8.1, 12.0]:
		var chairs: Array = Campus.dining_set(k, Vector3(7.4, 0, z), 0.0, 4, true, Color("e9e4da"), Color("7d6146"))
		if z > 10.0:
			var seat: Array = chairs[2]
			scene.add_figure(scene.student_look(380), seat[0], float(seat[1]) + PI, "seated", Campus.CHAIR_SEAT)
	Campus.bins(k, Vector3(5.9, 0, 14.4), 0.0)
	scene.add_floor_label("STACKS CAFÉ", at.call(Vector3(9.4, 0.012, 13.8)), 0.005)

static func _core(scene: Node3D, k, at: Callable) -> void:
	# Stair and elevator core in the north-east corner.
	k.wall(true, 7.0, Z0, -9.5, HEIGHT, WALL, true)
	k.wall(false, -9.5, 7.0, X1, HEIGHT, WALL, true)
	Props.elevator_frame(k, Vector3(10.5, 0, -9.42), 0.0, 1.3, true)
	scene.add_indicator(at.call(Vector3(10.5, 2.72, -9.38)), "1", 0.0)
	k.box("walnut", Vector3(8.3, 1.1, -9.38), Vector3(1.0, 2.2, 0.06), Color.WHITE)
	scene.add_sign("Stairs", at.call(Vector3(8.3, 2.45, -9.4)), 0.0, 14, 0.0035, "fp")
	scene.add_sign("Level 2 · Quiet Floor", at.call(Vector3(11.9, 2.9, -9.4)), 0.0, 18, 0.0045, "fp")
	scene.elevator_point = at.call(Vector3(10.5, 1.1, -8.8))
	scene.add_floor_label("ELEVATOR", at.call(Vector3(10.5, 0.012, -7.2)), 0.005)

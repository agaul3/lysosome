extends RefCounted
## Medical Education Center, Level 2 (zone-local: x east, z south):
##   Clinical Skills & Simulation Center (east): check-in, six standardized-
##     patient exam rooms along a corridor, the faculty observation room with
##     camera feeds, the Skills Lab (ECG, spirometry) and a simulation suite
##   Small-group rooms 201–204 (north-west), glass fronts, for case-based learning
##   Histology Lab (south-west): microscope benches and a projection screen
##   Elevator lobby (north), a study lounge with vending machines
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -30.0
const X1 := 30.0
const Z0 := -18.0
const Z1 := 18.0
const HEIGHT := 3.4
const FLOOR := Color("c8c9c6")
const CLINIC_FLOOR := Color("c3cbc9")
const WALL := Color("e6e5e0")
const NAVY := Color("2f4a6b")
const TEAL := Color("2f8f82")
## Standardized-patient exam rooms: [name, door x] along the corridor (z = 3).
const EXAM_ROOMS := [["Room 1", 11.8], ["Room 2", 15.1], ["Room 3", 18.4], ["Room 4", 21.7], ["Room 5", 25.0], ["Room 6", 28.3]]
const ANCHORS := {
	"arrival": Vector3(0, 0, -8.6),
	"sim_checkin": Vector3(5.8, 0, -1.4),
	"exam_corridor": Vector3(12.0, 0, 3.0),
	"histology": Vector3(-19.0, 0, -4.4),
	"pbl": Vector3(-19.0, 0, -7.6),
	"skills_lab": Vector3(5.8, 0, 6.2),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_elevator_lobby(scene, k, at)
	_skills_center(scene, k, at)
	_small_groups(scene, k, at)
	_histology(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(2.0, -6.0, X1, Z1, CLINIC_FLOOR, 0.004)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f2f2ef"))
	for x in range(-26, 30, 6):
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, -7.0), Vector2(2.4, 0.22))
		for z in [-13.0, 3.0, 12.0]:
			k.ceiling_light(Vector3(x + 3, HEIGHT - 0.02, z), Vector2(1.2, 1.2))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))
	# The main corridor runs east-west at z −7; walls either side.
	k.wall(false, -8.4, X0, -7.5, HEIGHT, WALL, true)
	k.wall(false, -8.4, 7.5, X1, HEIGHT, WALL, true)
	# Faculty offices lie beyond a closed door off the east corridor.
	k.box("walnut", Vector3(16.0, 1.1, -8.3), Vector3(1.0, 2.2, 0.05), Color.WHITE)
	scene.add_sign("Faculty Offices", at.call(Vector3(16.0, 2.45, -8.3)), 0.0, 16, 0.004, "fp")
	k.wall(false, -5.6, X0, 2.0, HEIGHT, WALL, true, [[-19.0, 1.6, 2.4], [-4.0, 2.4, 2.6]])

static func _elevator_lobby(scene: Node3D, k, at: Callable) -> void:
	k.wall(true, -7.5, Z0, -8.4, HEIGHT, WALL, true)
	k.wall(true, 7.5, Z0, -8.4, HEIGHT, WALL, true)
	for x in [-2.2, 2.2]:
		Props.elevator_frame(k, Vector3(x, 0, Z0 + 0.3), 0.0, 1.3, true)
		scene.add_indicator(at.call(Vector3(x, 2.72, Z0 + 0.38)), "2", 0.0)
	k.box("walnut", Vector3(0, 1.7, Z0 + 0.17), Vector3(8.0, 3.4, 0.04), Color.WHITE)
	scene.add_sign("Level 2 · Clinical Skills Center →   ← Small Groups · Histology", at.call(Vector3(0, 3.0, Z0 + 0.2)), 0.0, 18, 0.0048, "always")
	scene.elevator_point_2 = at.call(Vector3(0, 1.1, -16.4))
	scene.add_floor_label("LEVEL 2", at.call(Vector3(0, 0.012, -12.0)), 0.006)
	# Study lounge by the lifts (south of the corridor).
	for x in [-4.8, -1.6]:
		Campus.sofa(k, Vector3(x, 0, 16.4), PI, Color("5f7d8c"), 1.8)
	Props.vending(k, Vector3(1.4, 0, 1.0), -PI / 2, true)
	Props.vending(k, Vector3(1.4, 0, 2.0), -PI / 2, false)
	scene.add_endpoint("Level2Vending", "Vending machine", "", at.call(Vector3(0.4, 1.0, 1.5)), 1.5)
	k.wall(true, 2.0, -5.6, Z1, HEIGHT, WALL, true, [[-1.4, 2.4, 2.6], [6.2, 1.6, 2.4]])

static func _skills_center(scene: Node3D, k, at: Callable) -> void:
	scene.add_sign("Clinical Skills & Simulation Center", at.call(Vector3(5.2, 2.9, -5.52)), PI, 22, 0.0055, "fp", TEAL, Color.WHITE)
	# Check-in desk and waiting chairs.
	k.box("walnut", Vector3(5.8, 0.55, -3.2), Vector3(4.0, 1.1, 0.5), Color.WHITE, "always", true)
	k.box("facade", Vector3(5.8, 1.12, -3.3), Vector3(4.2, 0.05, 0.7), Color("f4f2ec"))
	Props.monitor(k, Vector3(5.0, 1.14, -3.2), PI, 0.46)
	scene.add_figure("coordinator", at.call(Vector3(6.4, 0, -4.2)), PI, "stand")
	Props.seat_row(k, Vector3(5.8, 0, 1.2), PI, 5)
	scene.add_floor_label("CHECK-IN", at.call(Vector3(5.8, 0.012, -1.6)), 0.0045)
	# Exam-room corridor at z = 3: rooms south, the observation room north.
	k.wall(false, 1.6, 10.2, X1, HEIGHT, WALL, true, [[16.0, 1.2, 2.3]])
	k.wall(true, 10.2, -5.6, 1.6, HEIGHT, WALL, true, [[-2.4, 1.4, 2.3]])
	# The observation room's corridor wall (its door is off the exam corridor).
	k.wall(false, -5.6, 10.2, X1, HEIGHT, WALL, true)
	var rooms: Array = []
	for index in range(EXAM_ROOMS.size()):
		var entry: Array = EXAM_ROOMS[index]
		var door_x: float = entry[1]
		var x0 := 10.2 + index * 3.3
		var x1 := x0 + 3.3
		k.wall(true, x0, 4.4, 11.0, HEIGHT, WALL, true)
		# Solid door with a window, into the room.
		var doors: Node3D = scene.add_doors("ExamRoomDoor%d" % (index + 1), at.call(Vector3(door_x, 0, 4.4)), 0.0, 1.1, 2.3, false, Color("9aa2a7"), Color("b9a88f"))
		doors.auto_target = scene.player_target()
		doors.auto_group = "door_openers"
		doors.auto_depth = 1.4
		doors.speed = 2.4
		scene.add_fp_node(doors)
		# Room: exam table, sink, stool, chair, computer, camera.
		Campus.exam_table(k, Vector3(x0 + 1.9, 0, 8.6), PI / 2)
		Campus.sink(k, Vector3(x0 + 0.5, 0, 5.2), PI / 2)
		Props.office_chair(k, Vector3(x0 + 2.8, 0, 6.0), -PI / 2, Color("5b6c74"))
		k.box("facade", Vector3(x0 + 0.7, 0.23, 9.8), Vector3(0.36, 0.46, 0.36), Color("39464d"))
		Props.monitor(k, Vector3(x1 - 0.2, 1.3, 7.2), -PI / 2, 0.42)
		k.box("metal", Vector3(x0 + 1.65, HEIGHT - 0.1, 7.6), Vector3(0.14, 0.12, 0.14), Color("20252a"), "fp")
		scene.add_sign(String(entry[0]), at.call(Vector3(door_x + 0.95, 2.1, 4.34)), PI, 18, 0.0045, "fp")
		rooms.append({"name": entry[0], "door": at.call(Vector3(door_x, 0, 3.4)), "inside": at.call(Vector3(door_x, 0, 5.6)), "patient_seat": at.call(Vector3(x0 + 1.9, 0, 8.6)), "chair": at.call(Vector3(x0 + 2.8, 0, 6.0)), "sink": at.call(Vector3(x0 + 0.5, 1.0, 5.6)), "doors": doors})
	k.wall(false, 4.4, 10.2, X1, HEIGHT, WALL, true, EXAM_ROOMS.map(func(entry: Array) -> Array: return [entry[1], 1.1, 2.3]))
	k.wall(false, 11.0, 10.2, X1, HEIGHT, WALL, true)
	scene.exam_rooms = rooms
	scene.add_floor_label("EXAM ROOMS", at.call(Vector3(20.0, 0.012, 3.0)), 0.0045)
	# Faculty observation room (north of the corridor): camera feeds.
	k.floor_rect(10.4, -5.4, X1 - 0.2, 1.4, Color("4a5156"), 0.006)
	k.box("walnut", Vector3(20.0, 0.38, -3.9), Vector3(16.0, 0.76, 0.8), Color.WHITE, "always", true)
	for index in range(6):
		var x := 13.0 + index * 2.8
		Props.monitor(k, Vector3(x, 0.78, -4.1), 0.0, 0.6, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, -2.9), PI)
	scene.add_figure("coordinator", at.call(Vector3(15.8, 0, -2.9)), 0.0, "seated", Props.OFFICE_SEAT)
	scene.add_sign("Observation · Faculty only", at.call(Vector3(16.0, 2.5, 1.66)), 0.0, 18, 0.0045, "fp")
	# Skills Lab (south-west of the center): task trainers, ECG cart,
	# spirometer. Doors from the check-in area and the study lounge; the
	# simulation suite opens off its east wall.
	k.wall(false, 4.4, 2.0, 10.2, HEIGHT, WALL, true, [[6.2, 1.6, 2.4]])
	k.wall(true, 10.2, 11.0, Z1, HEIGHT, WALL, true, [[14.5, 1.6, 2.4]])
	k.floor_rect(2.2, 4.6, 10.0, 17.8, Color("b9c3c5"), 0.006)
	for z in [8.0, 13.0]:
		k.box("facade", Vector3(6.0, 0.45, z), Vector3(5.0, 0.9, 1.1), Color("e3e6e8"), "always", true)
		k.box("facade", Vector3(6.0, 0.915, z), Vector3(5.04, 0.03, 1.14), Color("2f3437"))
	k.box("facade", Vector3(4.4, 1.0, 8.0), Vector3(0.7, 0.14, 0.3), Color("e3b08c"))
	k.box("facade", Vector3(7.6, 0.98, 8.0), Vector3(0.5, 0.08, 0.4), Color("d9d4ca"))
	Props.vitals_stand(k, Vector3(9.2, 0, 13.0), -PI / 2)
	k.box("facade", Vector3(4.6, 1.02, 13.0), Vector3(0.5, 0.18, 0.36), Color("f1f1ee"))
	k.box("facade", Vector3(4.6, 1.12, 13.14), Vector3(0.44, 0.02, 0.02), Color("22303a"))
	Campus.whiteboard(k, Vector3(6.0, 0, 17.66), PI, 3.0)
	scene.add_sign("Skills Lab", at.call(Vector3(6.2, 2.62, 4.31)), PI, 18, 0.0045, "fp")
	scene.add_floor_label("SKILLS LAB", at.call(Vector3(6.0, 0.012, 5.4)), 0.0045)
	# Simulation suite (south-east): a manikin in a hospital bed.
	k.floor_rect(10.4, 11.2, X1 - 0.2, Z1 - 0.2, Color("aeb8ba"), 0.006)
	Props.bed(k, Vector3(20.0, 0, 15.2), PI / 2, true)
	Props.vitals_stand(k, Vector3(21.8, 0, 13.6), PI)
	Props.crash_cart(k, Vector3(17.2, 0, 16.6), 0.0)
	k.box("clear", Vector3(26.2, 1.4, 14.6), Vector3(0.04, 1.2, 4.6), Color(0.3, 0.4, 0.45, 0.45), "fp")
	scene.add_sign("Simulation Suite", at.call(Vector3(10.11, 2.62, 14.5)), -PI / 2, 18, 0.0045, "fp")

static func _small_groups(scene: Node3D, k, at: Callable) -> void:
	var rooms: Array = []
	for index in range(4):
		var x0 := X0 + index * 5.625
		var x1 := x0 + 5.625
		var center := Vector3((x0 + x1) / 2.0, 0, -13.2)
		if index > 0:
			k.wall(true, x0, Z0, -8.4, HEIGHT, WALL, true)
		var name := "Room %d" % (201 + index)
		var doors: Node3D = Campus.glass_front(scene, k, "PBLDoors%d" % (201 + index), false, -8.4, x0, x1, center.x, 1.4, false, Color("9aa2a7"), HEIGHT, WALL)
		var seats: Array = Campus.group_table(k, center, 0.0, 8)
		k.box("metal", Vector3(center.x, 1.9, Z0 + 0.19), Vector3(2.2, 1.24, 0.05), Color("16202a"))
		Campus.whiteboard(k, Vector3(x0 + 0.2, 0, -13.2), PI / 2, 2.0, true, "always" if index == 0 else "fp")
		scene.add_sign(name, at.call(Vector3(center.x, 2.72, -8.32)), 0.0, 20, 0.005, "fp")
		scene.add_floor_label(str(201 + index), at.call(Vector3(center.x, 0.012, -7.0)))
		rooms.append({"name": name, "center": at.call(center), "seats": seats.map(func(seat: Array) -> Array: return [at.call(seat[0]), seat[1]]), "screen": at.call(Vector3(center.x, 1.9, Z0 + 0.22)), "doors": doors})
	scene.pbl_rooms = rooms

static func _histology(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0 + 0.2, -5.4, -7.7, Z1 - 0.2, Color("b7bdbf"), 0.006)
	k.wall(true, -7.5, -5.6, Z1, HEIGHT, WALL, true)
	var benches: Array = []
	for row in range(3):
		for column in range(4):
			var pos := Vector3(-26.5 + column * 4.6, 0, -1.0 + row * 4.2)
			Campus.microscope_bench(k, pos, PI)
			benches.append(at.call(pos + Vector3(-0.2, 0, -0.62)))
	scene.histology_benches = benches
	# Instructor station and projection screen on the south wall.
	k.box("facade", Vector3(-19.0, 0.45, 15.4), Vector3(2.4, 0.9, 0.8), Color("e3e6e8"), "always", true)
	Props.monitor(k, Vector3(-19.0, 0.92, 15.6), PI, 0.5)
	k.box("facade", Vector3(-19.0, 2.1, Z1 - 0.2), Vector3(4.4, 2.2, 0.04), Color("f4f4f1"))
	scene.histology_screen = at.call(Vector3(-19.0, 2.1, Z1 - 0.24))
	for x in [-28.5, -9.5]:
		Campus.sink(k, Vector3(x, 0, 16.9), PI)
	Props.shelving(k, Vector3(X0 + 0.34, 0, 8.0), PI / 2, 3.6, 5)
	scene.add_sign("Histology Lab", at.call(Vector3(-19.0, 2.72, -5.52)), PI, 22, 0.0055, "fp", NAVY, Color.WHITE)
	scene.add_floor_label("HISTOLOGY LAB", at.call(Vector3(-19.0, 0.012, -3.8)), 0.0055)

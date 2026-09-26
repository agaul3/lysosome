extends RefCounted
## Student Center, Level 2 (zone-local, as Level 1):
##   Fitness Center   west, behind glass: the front desk, treadmills and bikes
##                    along the south windows, racks and dumbbells, a
##                    stretching corner with mats
##   Club Rooms A–C   east, glass-fronted meeting rooms (Medical Spanish in A,
##                    Journal Club in B)
##   Landing          between them by the lifts: seats, lockers, a fountain
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -15.0
const X1 := 15.0
const Z0 := -12.0
const Z1 := 12.0
const HEIGHT := 3.6
const FLOOR := Color("c7c2b8")
const GYM_FLOOR := Color("4a5054")
const WALL := Color("e8e4dc")
const NAVY := Color("2f4a6b")
const GYM := Color("c2452d")
## Club rooms: [id, name, z0, z1].
const CLUB_ROOMS := [["club_a", "Club Room A", -12.0, -4.0], ["club_b", "Club Room B", -4.0, 4.0], ["club_c", "Club Room C", 4.0, 12.0]]
const ANCHORS := {
	"arrival": Vector3(-1.0, 0, -8.4),
	"fitness": Vector3(-4.4, 0, -8.2),
	"club_a": Vector3(5.0, 0, -8.0),
	"club_b": Vector3(5.0, 0, 0.0),
	"club_c": Vector3(5.0, 0, 8.0),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_fitness(scene, k, at)
	_club_rooms(scene, k, at)
	_landing(scene, k, at)
	_core(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(X0 + 0.2, Z0 + 0.2, -3.6, Z1 - 0.2, GYM_FLOOR, 0.004)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	for span in [[-14.2, -3.8], [-3.0, 3.6], [4.4, 14.2]]:
		k.box("clear", Vector3((span[0] + span[1]) / 2.0, 1.9, Z1 - 0.2), Vector3(span[1] - span[0], 2.4, 0.04), Color(0.8, 0.9, 0.95, 0.35), "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 18.0), Vector3(70, 12, 0.1), Color("cfe6f1"), "fp")
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f2f0ea"))
	for x in [-11.0, -5.0, 1.0, 7.0, 13.0]:
		for z in [-8.0, -2.0, 4.0, 9.5]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.2, 1.2))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))

static func _fitness(scene: Node3D, k, at: Callable) -> void:
	# The glass front on the landing, its door at z −6.5.
	var doors: Node3D = Campus.glass_front(scene, k, "FitnessDoors", true, -3.4, -9.5, Z1, -6.5, 1.8, false, Color("9aa2a7"), HEIGHT, WALL)
	scene.fitness_doors = doors
	k.box("facade", Vector3(-3.3, 2.9, -6.5), Vector3(0.05, 0.5, 3.6), GYM, "fp")
	scene.add_sign("FITNESS CENTER", at.call(Vector3(-3.27, 2.9, -6.5)), PI / 2, 30, 0.0068, "fp", GYM, Color.WHITE)
	# Front desk just inside, north of the door; the attendant behind it.
	k.box("walnut", Vector3(-4.9, 0.55, -8.9), Vector3(0.6, 1.1, 2.0), Color.WHITE, "always", true)
	Props.monitor(k, Vector3(-5.0, 1.12, -8.6), -PI / 2, 0.4)
	scene.add_figure(scene.student_look(560), at.call(Vector3(-5.9, 0, -9.0)), -PI / 2, "stand")
	scene.fitness_point = at.call(Vector3(-4.2, 1.0, -8.3))
	# Cardio along the south windows: treadmills and bikes facing out.
	for x in [-13.6, -12.2, -10.8, -9.4]:
		Campus.treadmill(k, Vector3(x, 0, 10.4), 0.0)
	for x in [-7.8, -6.6, -5.4]:
		Campus.exercise_bike(k, Vector3(x, 0, 10.6), 0.0)
	scene.add_figure(scene.student_look(561), at.call(Vector3(-12.2, 0.24, 10.2)), PI, "stand")
	scene.add_figure(scene.student_look(562), at.call(Vector3(-9.4, 0.24, 10.2)), PI, "stand")
	# Strength: two racks against the west wall, dumbbells, mirrors.
	for z in [0.6, 4.4]:
		Campus.squat_rack(k, Vector3(-14.0, 0, z), PI / 2)
	Campus.dumbbell_rack(k, Vector3(-11.0, 0, -2.4), 0.0, 3.0)
	k.box("clear", Vector3(X0 + 0.18, 1.5, 2.5), Vector3(0.02, 1.8, 7.0), Color(0.86, 0.92, 0.95, 0.5), "fp")
	scene.add_figure(scene.student_look(563), at.call(Vector3(-11.0, 0, -1.4)), 0.0, "stand")
	# Stretching corner with mats; lockers on the north wall.
	var mats := [Color("7d5a86"), Color("2f8f82"), Color("c8742f"), Color("3d6fc4")]
	for index in range(4):
		Campus.yoga_mat(k, Vector3(-13.4 + index * 1.2, 0, -7.4), 0.0, mats[index])
	scene.add_figure(scene.student_look(564), at.call(Vector3(-12.2, 0.02, -7.4)), 0.0, "stand")
	Campus.lockers(k, Vector3(-9.4, 0, Z0 + 0.4), 0.0, 8, Color("5b6c74"))
	scene.add_floor_label("FITNESS CENTER", at.call(Vector3(-8.0, 0.012, 7.0)), 0.006)

static func _club_rooms(scene: Node3D, k, at: Callable) -> void:
	var points := {}
	for index in range(CLUB_ROOMS.size()):
		var room: Array = CLUB_ROOMS[index]
		var z0: float = room[2]
		var z1: float = room[3]
		var centre := (z0 + z1) / 2.0
		Campus.glass_front(scene, k, "ClubDoors%d" % (index + 1), true, 4.0, z0, z1, centre - 2.2, 1.4, false, Color("9aa2a7"), HEIGHT, WALL)
		if index > 0:
			k.wall(false, z0, 4.0, X1, HEIGHT, WALL, true, [], 0.14)
		var chairs: Array = Campus.group_table(k, Vector3(10.2, 0, centre), 0.0, 8)
		Campus.whiteboard(k, Vector3(X1 - 0.17, 0, centre), -PI / 2, 3.0, index != 2, "fp")
		k.box("metal", Vector3(10.2, 1.9, z0 + 0.1 if index > 0 else Z0 + 0.19), Vector3(2.4, 1.3, 0.05), Color("16202a"), "fp" if index > 0 else "always")
		scene.add_sign(String(room[1]), at.call(Vector3(3.93, 2.62, centre - 2.2)), -PI / 2, 18, 0.0045, "fp")
		if index == 2:
			for pick in [1, 4, 6]:
				var chair: Array = chairs[pick]
				scene.add_figure(scene.student_look(570 + pick), at.call(chair[0]), float(chair[1]) + PI, "seated", Props.OFFICE_SEAT)
		points[room[0]] = at.call(Vector3(5.0, 1.0, centre - 2.2))
	scene.club_room_points = points

static func _landing(scene: Node3D, k, at: Callable) -> void:
	for z in [2.0, 5.6]:
		Props.armchair(k, Vector3(-1.2, 0, z), -PI / 2, Color("5f7d8c"))
	Props.round_table(k, Vector3(-1.2, 0, 3.8), 0.4, 0.45)
	Campus.lockers(k, Vector3(2.9, 0, -11.6), 0.0, 5, Color("7a8d99"))
	scene.add_floor_label("LEVEL 2", at.call(Vector3(0.3, 0.012, -5.6)), 0.006)

static func _core(scene: Node3D, k, at: Callable) -> void:
	k.wall(true, -3.4, Z0, -9.5, HEIGHT, WALL, true)
	k.wall(true, 1.4, Z0, -9.5, HEIGHT, WALL, true)
	k.wall(false, -9.5, -3.4, 1.4, HEIGHT, WALL, true)
	Props.elevator_frame(k, Vector3(-1.0, 0, -9.42), 0.0, 1.3, true)
	scene.add_indicator(at.call(Vector3(-1.0, 2.72, -9.38)), "2", 0.0)
	k.box("walnut", Vector3(0.7, 1.1, -9.38), Vector3(0.9, 2.2, 0.06), Color.WHITE)
	scene.add_sign("Stairs", at.call(Vector3(0.7, 2.45, -9.4)), 0.0, 14, 0.0035, "fp")
	scene.elevator_point_2 = at.call(Vector3(-1.0, 1.1, -8.8))

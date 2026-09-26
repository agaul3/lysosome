extends RefCounted
## Anatomy Hall, the lower level: the Gross Anatomy Laboratory (zone-local).
##   Stair landing and PPE room   north-east: the stair and lift, lockers,
##                                gowns and gloves, sinks, an eyewash station
##   Study area                   north: bone boxes and study tables
##   Model room                   north-west, behind glass: skeletons and
##                                bench models, for open study
##   The dissection lab           south, through automatic doors from the PPE
##                                room: twelve downdraft tables in three rows,
##                                each with a donor under a drape, X-ray
##                                viewboxes and sinks; students at some tables
## Donors are only ever shown draped: the lab is a place of respect.
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -15.0
const X1 := 15.0
const Z0 := -10.0
const Z1 := 10.0
const HEIGHT := 3.6
const FLOOR := Color("c4c8c6")
const WALL := Color("e4e8e6")
const TEAL := Color("2f8f82")
const NAVY := Color("2f4a6b")
## Dissection tables (zone-local centres), row by row.
const TABLES := [
	Vector3(-10.5, 0, 1.2), Vector3(-4.5, 0, 1.2), Vector3(1.5, 0, 1.2), Vector3(7.5, 0, 1.2),
	Vector3(-10.5, 0, 4.8), Vector3(-4.5, 0, 4.8), Vector3(1.5, 0, 4.8), Vector3(7.5, 0, 4.8),
	Vector3(-10.5, 0, 8.4), Vector3(-4.5, 0, 8.4), Vector3(1.5, 0, 8.4), Vector3(7.5, 0, 8.4),
]
## Your group's table (Table 7) and the tables where another group is at work.
const YOUR_TABLE := 6
const BUSY_TABLES := [1, 2, 5, 9, 10]
## What everyone wears in the lab: scrubs and clogs, nothing on the head or
## back, no jacket.
const SCRUBS := {"top": "ceil_scrub_top", "bottom": "ceil_scrub_pants", "shoes": "hospital_clogs", "outerwear": "", "head": "", "back": "", "neck": ""}
const ANCHORS := {
	"arrival": Vector3(11.6, 0, -8.6),
	"ppe": Vector3(12.0, 0, -4.4),
	"lab": Vector3(12.0, 0, 0.2),
	"your_table": Vector3(1.5, 0, 3.6),
	"models": Vector3(-9.0, 0, -5.2),
	"study": Vector3(2.5, 0, -4.0),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_ppe(scene, k, at)
	_study(scene, k, at)
	_models(scene, k, at)
	_lab(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f2f4f3"))
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		for z in [-7.0, -3.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.2, 1.2))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))
	# The lab's north wall (z −1.2), with its doors from the PPE room at x 12;
	# the PPE room's west wall, open to the study area at z −6.2.
	k.wall(false, -1.2, X0, 11.1, HEIGHT, WALL, true)
	k.wall(false, -1.2, 12.9, X1, HEIGHT, WALL, true)
	k.box("facade", Vector3(12.0, (2.4 + HEIGHT) / 2.0, -1.2), Vector3(1.8, HEIGHT - 2.4, 0.16), WALL, "fp")
	k.wall(true, 9.0, Z0, -1.2, HEIGHT, WALL, true, [[-6.2, 1.6, 2.4]])

static func _ppe(scene: Node3D, k, at: Callable) -> void:
	# The foot of the stair (rising east) and the lift.
	for step in range(4):
		var top := 0.18 * (step + 1)
		k.box("facade", Vector3(13.1 + step * 0.36, top / 2.0, -8.6), Vector3(0.36, top, 2.2), Color("cfc6b4"), "always", true)
	k.box("metal", Vector3(13.6, 0.5, -7.46), Vector3(1.6, 1.0, 0.05), Color("3a4045"), "always", true)
	Props.elevator_frame(k, Vector3(10.4, 0, Z0 + 0.4), 0.0, 1.2, true)
	scene.stairs_up_point = at.call(Vector3(12.5, 1.0, -8.6))
	# Lockers, gowns and gloves, sinks and an eyewash station.
	Campus.lockers(k, Vector3(X1 - 0.4, 0, -4.8), -PI / 2, 8, Color("5b6c74"))
	Props.shelving(k, Vector3(9.5, 0, -8.2), PI / 2, 1.6, 5)
	for z in [-3.2, -2.2]:
		Campus.sink(k, Vector3(9.4, 0, z), PI / 2)
	k.box("facade", Vector3(X1 - 0.2, 1.4, -1.9), Vector3(0.04, 0.5, 0.7), Color("2f7a4a"), "fp")
	scene.add_sign("EYEWASH", at.call(Vector3(X1 - 0.17, 1.8, -1.9)), -PI / 2, 14, 0.0035, "fp", Color("2f7a4a"), Color.WHITE)
	scene.add_sign("GROSS ANATOMY LABORATORY", at.call(Vector3(12.0, 3.0, -1.3)), PI, 20, 0.005, "fp", NAVY, Color.WHITE)
	scene.add_sign("PPE required beyond this point\nGown · gloves · eye protection · closed shoes", at.call(Vector3(13.95, 1.75, -1.3)), PI, 16, 0.0038, "fp", TEAL, Color.WHITE)
	scene.ppe_point = at.call(Vector3(10.3, 1.0, -8.2))
	scene.add_floor_label("PPE", at.call(Vector3(12.0, 0.012, -5.0)), 0.005)

static func _study(scene: Node3D, k, at: Callable) -> void:
	# Bone boxes on shelves along the north wall; two study tables.
	for x in [-1.0, 1.6, 4.2]:
		Props.shelving(k, Vector3(x, 0, Z0 + 0.45), 0.0, 2.4, 4)
	scene.add_sign("Bone boxes · sign out at the desk", at.call(Vector3(1.6, 2.2, Z0 + 0.17)), 0.0, 16, 0.004, "fp")
	var number := 0
	for x in [0.0, 5.0]:
		var seats: Array = Campus.study_table(k, Vector3(x, 0, -6.6), 0.0, 2.8, 2, false)
		k.box("facade", Vector3(x - 0.5, 0.86, -6.6), Vector3(0.6, 0.14, 0.34), Color("ece4cf"))
		for seat in seats:
			var occupant: Dictionary = scene.dressed(scene.student_look(660 + number), SCRUBS) if number in [1, 6] else {}
			var chair: Node3D = scene.add_seat("StudySeat%d" % (number + 1), at.call(seat[0]), seat[1], Campus.STUDY_LAPTOP, Color("5b6c74"), occupant)
			if occupant.is_empty():
				scene.study_seats.append(chair)
			number += 1
	scene.add_floor_label("STUDY", at.call(Vector3(2.5, 0.012, -3.2)), 0.005)

static func _models(scene: Node3D, k, at: Callable) -> void:
	# The model room behind glass on the study corridor.
	Campus.glass_front(scene, k, "ModelRoomDoors", false, -4.4, X0, -3.0, -9.0, 1.4, false, Color("9aa2a7"), HEIGHT, WALL)
	k.wall(true, -3.0, Z0, -4.4, HEIGHT, WALL, true)
	for x in [-13.6, -12.2]:
		Campus.skeleton_model(k, Vector3(x, 0, -8.8), 0.0)
	var models := [[["b8452d", "e8708a"], Vector3(0.3, 0.26, 0.24)], [["e8b0a0", "c9a6a0"], Vector3(0.32, 0.24, 0.28)], [["ece4cf", "cfc6b4"], Vector3(0.26, 0.24, 0.3)], [["ece4cf", "b8452d"], Vector3(0.4, 0.2, 0.2)]]
	for index in range(models.size()):
		var bench := Vector3(-9.6 + (index % 2) * 3.2, 0, -8.6 + int(index / 2) * 2.4)
		Campus.lab_bench(k, bench, 0.0, 2.4)
		Campus.bench_model(k, bench + Vector3(-0.4, 0.93, 0), 0.0, models[index][0], models[index][1])
	scene.add_sign("Model Room · Open study", at.call(Vector3(-9.0, 2.72, -4.32)), 0.0, 18, 0.0045, "fp")
	scene.models_point = at.call(Vector3(-9.0, 1.0, -5.2))
	scene.add_floor_label("MODEL ROOM", at.call(Vector3(-9.0, 0.012, -3.0)), 0.0045)

static func _lab(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0 + 0.2, -1.0, X1 - 0.2, Z1 - 0.2, Color("b9c1c0"), 0.004)
	var doors: Node3D = scene.add_auto_doors("LabDoors", at.call(Vector3(12.0, 0, -1.2)), 0.0, 1.8, false, 1.8)
	scene.lab_doors = doors
	for index in range(TABLES.size()):
		var pos: Vector3 = TABLES[index]
		Campus.dissection_table(k, pos, 0.0, true, HEIGHT)
		scene.add_sign(str(index + 1), at.call(pos + Vector3(-1.13, 0.72, 0)), -PI / 2, 22, 0.004, "always")
	# Students at work in scrubs; the instructor between the rows.
	for table in BUSY_TABLES:
		var pos: Vector3 = TABLES[table]
		for spot in [Vector3(-0.5, 0, -0.75), Vector3(0.5, 0, 0.75), Vector3(0.6, 0, -0.75)]:
			var look: Dictionary = scene.dressed(scene.student_look(620 + table * 5 + int(spot.x * 10.0)), SCRUBS)
			scene.add_figure(look, at.call(pos + spot), 0.0 if spot.z > 0.0 else PI, "stand")
	scene.add_figure("coordinator", at.call(Vector3(-14.1, 0, 5.8)), PI / 2, "stand")
	# Your group waits at Table 7, across the table from where you'll stand.
	var yours: Vector3 = TABLES[YOUR_TABLE]
	for spot in [Vector3(-0.6, 0, 0.75), Vector3(0.6, 0, 0.75)]:
		scene.add_figure(scene.dressed(scene.student_look(700 + int(spot.x * 10.0)), SCRUBS), at.call(yours + spot), 0.0, "stand")
	scene.table_point = at.call(yours + Vector3(0, 1.0, -0.95))
	# X-ray viewboxes on the west wall; sinks on the east wall.
	for z in [2.4, 5.8]:
		k.box("light", Vector3(X0 + 0.19, 1.7, z), Vector3(0.02, 0.9, 2.4), Color("eef6fb"))
		for film in range(3):
			k.box("facade", Vector3(X0 + 0.2, 1.7, z - 0.8 + film * 0.8), Vector3(0.01, 0.8, 0.7), Color("1d2a33"))
	for z in [3.0, 6.6]:
		Campus.sink(k, Vector3(X1 - 0.45, 0, z), -PI / 2)
	scene.add_floor_label("GROSS ANATOMY LAB", at.call(Vector3(-1.5, 0.012, -0.3)), 0.006)

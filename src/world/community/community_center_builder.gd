extends RefCounted
## The Harbor Street Community Center, off campus (zone-local: x east, z
## south; the street doors on the south face, where the shuttle stops):
##   Lobby                     reception, community notices, waiting chairs
##   Dining hall and kitchen   supper at long tables; the serving line on
##                             the kitchen's pass, where the Community Kitchen
##                             volunteers serve
##   Food pantry               client-choice shelves
##   Student-Run Free Clinic   the east wing, behind glass: check-in, the
##                             vitals station, two curtained exam bays
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -14.0
const X1 := 14.0
const Z0 := -10.0
const Z1 := 10.0
const HEIGHT := 3.6
const FLOOR := Color("c9c2b3")
const WALL := Color("ece3d3")
const BRICK := Color("a8674f")
const TEAL := Color("2f8f82")
const TOMATO := Color("c2452d")
const ANCHORS := {
	"entrance": Vector3(-6.0, 0, 8.8),
	"reception": Vector3(-10.4, 0, 6.4),
	"serving_line": Vector3(-8.0, 0, -4.6),
	"dining": Vector3(-4.0, 0, 0.0),
	"pantry": Vector3(2.0, 0, -6.0),
	"clinic": Vector3(9.0, 0, 6.4),
	"vitals": Vector3(9.6, 0, -1.0),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_lobby(scene, k, at)
	_dining(scene, k, at)
	_kitchen(scene, k, at)
	_pantry(scene, k, at)
	_clinic(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.wall(false, Z0, X0, X1, HEIGHT, BRICK, false, [], 0.3, "facade")
	k.wall(true, X0, Z0, Z1, HEIGHT, BRICK, false, [], 0.3, "facade")
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [[-6.0, 2.4, 2.6]], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	for span in [[-12.6, -8.0], [-4.0, 4.4], [6.8, 12.8]]:
		k.box("clear", Vector3((span[0] + span[1]) / 2.0, 1.9, Z1 - 0.2), Vector3(span[1] - span[0], 1.8, 0.04), Color(0.8, 0.9, 0.95, 0.35), "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 14.0), Vector3(60, 12, 0.1), Color("cfe0e8"), "fp")
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f3efe6"))
	for x in [-11.0, -5.0, 1.0, 7.0, 12.0]:
		for z in [-6.0, 0.0, 6.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.6, 0.3))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))
	# A painted mural on the north wall of the dining hall (first person).
	var mural := [Color("f2c46d"), Color("2f8f82"), Color("c2452d"), Color("3d6fc4"), Color("7fd6a0")]
	for index in range(10):
		k.box("facade", Vector3(-3.4 + index * 0.62, 2.7, Z0 + 0.17), Vector3(0.6, 0.9 + float(index % 3) * 0.2, 0.02), mural[index % mural.size()], "fp")

static func _lobby(scene: Node3D, k, at: Callable) -> void:
	var doors: Node3D = scene.add_auto_doors("StreetDoors", at.call(Vector3(-6.0, 0, Z1)), 0.0, 2.4, true, 2.2)
	scene.entrance_doors = [doors]
	k.box("facade", Vector3(-6.0, 0.01, 9.0), Vector3(2.8, 0.02, 1.6), Color("4a5156"))
	# Reception, facing the doors.
	k.box("walnut", Vector3(-10.4, 0.55, 5.6), Vector3(2.6, 1.1, 0.6), Color.WHITE, "always", true)
	Props.monitor(k, Vector3(-10.9, 1.12, 5.4), PI, 0.42)
	scene.add_figure("reception", at.call(Vector3(-10.4, 0, 4.7)), PI, "stand")
	scene.reception_point = at.call(Vector3(-10.4, 1.0, 6.5))
	scene.add_sign("WELCOME · BIENVENIDOS", at.call(Vector3(-6.0, 3.05, Z1 - 0.19)), PI, 26, 0.006, "fp")
	# Community notices on the west wall.
	Campus.bulletin_board(k, Vector3(X0 + 0.2, 1.55, 7.2), PI / 2, 2.6, 1.2)
	scene.add_sign("Community Notices", at.call(Vector3(X0 + 0.22, 2.4, 7.2)), PI / 2, 16, 0.004, "fp")
	scene.notices_point = at.call(Vector3(X0 + 0.9, 1.2, 7.2))
	Props.seat_row(k, Vector3(-2.2, 0, 8.9), PI, 4)
	scene.add_figure(scene.guest_look(800), at.call(Vector3(-2.51, 0, 8.9)), 0.0, "seated", Campus.CHAIR_SEAT)
	scene.add_floor_label("HARBOR STREET COMMUNITY CENTER", at.call(Vector3(-6.0, 0.012, 7.0)), 0.004)

static func _dining(scene: Node3D, k, at: Callable) -> void:
	var tables := [Vector3(-11.0, 0, -1.6), Vector3(-6.4, 0, -1.6), Vector3(-1.8, 0, -1.6), Vector3(-11.0, 0, 2.2), Vector3(-6.4, 0, 2.2), Vector3(-1.8, 0, 2.2)]
	var guest := 0
	for index in range(tables.size()):
		var seats: Array = Campus.banquet_table(k, tables[index], 0.0, 2.4, 3, Color("f4f4f1"))
		for pick in range(seats.size()):
			if (index * 7 + pick * 3) % 5 < 2:
				var seat: Array = seats[pick]
				scene.add_figure(scene.guest_look(810 + guest), at.call(seat[0]), float(seat[1]) + PI, "seated", Campus.CHAIR_SEAT)
				var chair_yaw: float = seat[1]
				k.box("facade", seat[0] + Vector3(sin(chair_yaw), 0, cos(chair_yaw)) * 0.45 + Vector3(0, 0.755, 0), Vector3(0.3, 0.03, 0.24), Color("e9e4da"))
				guest += 1
	scene.add_floor_label("DINING HALL", at.call(Vector3(-6.4, 0.012, 4.6)), 0.005)

static func _kitchen(scene: Node3D, k, at: Callable) -> void:
	# The pass: a wall with a wide serving opening; the line in front of it.
	k.wall(false, -6.4, X0, -2.0, HEIGHT, WALL, true, [[-8.0, 4.8, 2.2]])
	Campus.serving_line(k, Vector3(-8.0, 0, -6.4), 0.0, 4.8)
	scene.add_sign("SUPPER · 5:30–7:30 · ALL WELCOME", at.call(Vector3(-8.0, 2.8, -6.31)), 0.0, 20, 0.005, "fp", TOMATO, Color.WHITE)
	# Volunteers on the line (in aprons over their own clothes) and cooks behind.
	for x in [-9.6, -6.6]:
		scene.add_figure("barista", at.call(Vector3(x, 0, -7.3)), PI, "stand")
	Campus.range_hood(k, Vector3(-11.0, 0, -9.4), 0.0, 2.4, HEIGHT)
	k.box("metal", Vector3(-6.0, 0.45, -9.4), Vector3(3.0, 0.9, 0.8), Color("c9ced2"), "always", true)
	k.box("metal", Vector3(-6.0, 0.91, -9.4), Vector3(3.0, 0.02, 0.8), Color("aeb5ba"))
	k.box("metal", Vector3(-3.0, 1.1, -9.62), Vector3(1.4, 2.2, 0.06), Color("aeb5ba"))
	scene.add_sign("Walk-in cooler", at.call(Vector3(-3.0, 2.4, -9.58)), 0.0, 14, 0.0035, "fp")
	scene.add_figure(scene.guest_look(870), at.call(Vector3(-11.0, 0, -8.5)), 0.0, "stand")
	scene.serving_point = at.call(Vector3(-8.0, 1.0, -5.1))
	scene.add_floor_label("KITCHEN", at.call(Vector3(-8.0, 0.012, -8.2)), 0.0045)

static func _pantry(scene: Node3D, k, at: Callable) -> void:
	# Client-choice pantry: shelves you shop from, not a bag handed over.
	k.wall(true, -2.0, Z0, -6.4, HEIGHT, WALL, true)
	k.wall(false, -6.4, -2.0, 4.6, HEIGHT, WALL, true, [[1.3, 1.6, 2.4]])
	k.wall(true, 4.6, Z0, -6.4, HEIGHT, WALL, true)
	for x in [-0.6, 3.2]:
		Campus.pantry_shelf(k, Vector3(x, 0, -9.5), 0.0, 2.4)
	Campus.pantry_shelf(k, Vector3(1.3, 0, -8.0), 0.0, 2.4)
	scene.add_sign("Food Pantry · Client choice", at.call(Vector3(1.3, 2.62, -6.32)), 0.0, 18, 0.0045, "fp")
	scene.pantry_point = at.call(Vector3(1.3, 1.0, -5.6))

static func _clinic(scene: Node3D, k, at: Callable) -> void:
	# The east wing, behind glass from the corridor at x 6.
	Campus.glass_front(scene, k, "ClinicDoors", true, 6.0, -10.0, Z1, 6.2, 1.6, false, Color("9aa2a7"), HEIGHT, WALL)
	k.floor_rect(6.2, Z0 + 0.2, X1 - 0.2, Z1 - 0.2, Color("d3d8d6"), 0.004)
	scene.add_sign("STUDENT-RUN FREE CLINIC", at.call(Vector3(5.93, 2.95, 6.2)), -PI / 2, 24, 0.0055, "fp", TEAL, Color.WHITE)
	# Check-in and waiting.
	k.box("walnut", Vector3(9.4, 0.55, 8.4), Vector3(2.2, 1.1, 0.6), Color.WHITE, "always", true)
	Props.monitor(k, Vector3(9.0, 1.12, 8.6), 0.0, 0.42)
	scene.add_figure(scene.dressed(scene.guest_look(880), {"top": "clinic_tee"}), at.call(Vector3(9.4, 0, 9.3)), 0.0, "stand")
	Props.seat_row(k, Vector3(12.8, 0, 5.0), -PI / 2, 4)
	for index in [0, 2]:
		scene.add_figure(scene.guest_look(882 + index), at.call(Vector3(12.8, 0, 5.0 + (index - 1.5) * 0.62)), PI / 2, "seated", Campus.CHAIR_SEAT)
	# The vitals station: a chair, the vitals stand and a manual cuff on the wall.
	Props.office_chair(k, Vector3(9.6, 0, -1.8), 0.0, Color("41596a"))
	Props.vitals_stand(k, Vector3(10.6, 0, -2.2), -PI / 2)
	k.box("facade", Vector3(X1 - 0.2, 1.4, -1.6), Vector3(0.05, 0.3, 0.3), Color("2a3238"), "fp")
	scene.add_figure(scene.guest_look(886), at.call(Vector3(9.6, 0, -1.8)), PI, "seated", Props.OFFICE_SEAT)
	scene.vitals_point = at.call(Vector3(9.6, 1.0, -0.6))
	scene.add_floor_label("VITALS", at.call(Vector3(9.6, 0.012, 0.6)), 0.0045)
	# Two curtained exam bays at the north end.
	for index in range(2):
		var x := 8.0 + index * 3.8
		Campus.exam_table(k, Vector3(x, 0, -8.4), 0.0)
		k.box("facade", Vector3(x + 1.8, 1.1, -7.8), Vector3(0.04, 2.0, 4.0), Color("b9d3d8"), "fp")
		k.box("facade", Vector3(x, 1.1, -5.84), Vector3(2.2, 2.0, 0.04), Color("b9d3d8"), "fp")
	Props.shelving(k, Vector3(X1 - 0.45, 0, 2.6), -PI / 2, 1.6, 4)
	scene.add_sign("Supervised by volunteer physicians · Thursdays 5:30 PM · Saturdays 9 AM", at.call(Vector3(X1 - 0.17, 2.4, 5.0)), -PI / 2, 14, 0.0035, "fp")

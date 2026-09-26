extends RefCounted
## Anatomy Hall, the ground floor (zone-local: x east, z south; the portico
## doors on the south face, as outside). A classical hall:
##   Lobby         stone floor, benches, and the donor memorial: a plaque, the
##                 book of remembrance and flowers
##   The Theatre   the old anatomical theatre: three tiers of benches round a
##                 central table, used now for the donor dedication
##   Stair hall    the stair and lift down to the Gross Anatomy Laboratory,
##                 and the department office
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -9.0
const X1 := 9.0
const Z0 := -6.5
const Z1 := 6.5
const HEIGHT := 5.0
const STONE := Color("d9d3c6")
const WALL := Color("ece6da")
const TRIM := Color("cfc6b4")
const OAK := Color("8a6446")
const NAVY := Color("2f4a6b")
## The theatre room and its tiers (three bands inset from the west, north
## and east walls, highest against the wall).
const THEATRE := Rect2(-8.8, -6.3, 11.1, 7.6)
const TIER_DEPTH := 0.95
const TIER_RISE := 0.42
const ANCHORS := {
	"entrance": Vector3(0, 0, 5.4),
	"memorial": Vector3(7.2, 0, 4.0),
	"theatre": Vector3(-3.25, 0, 0.2),
	"theatre_table": Vector3(-3.25, 0, -2.3),
	"stairs": Vector3(6.4, 0, -0.8),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_lobby(scene, k, at)
	_theatre(scene, k, at)
	_stair_hall(scene, k, at)

## The stairwell down to the lab: an opening in the floor, railed round.
const WELL := Rect2(4.9, -6.1, 3.0, 4.4)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	# The floor, leaving the stairwell open.
	k.floor_rect(X0, Z0, WELL.position.x, Z1, STONE)
	k.floor_rect(WELL.end.x, Z0, X1, Z1, STONE)
	k.floor_rect(WELL.position.x, WELL.end.y, WELL.end.x, Z1, STONE)
	k.floor_rect(WELL.position.x, Z0, WELL.end.x, WELL.position.y, STONE)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.4)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.4)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [[0.0, 2.0, 3.0]], 0.4)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.4)
	# Tall sash windows on the south wall (first person), and the coffered ceiling.
	for x in [-6.4, -3.8, 3.8, 6.4]:
		k.box("clear", Vector3(x, 2.6, Z1 - 0.21), Vector3(1.1, 2.3, 0.04), Color(0.82, 0.9, 0.95, 0.4), "fp")
		k.box("facade", Vector3(x, 1.4, Z1 - 0.26), Vector3(1.4, 0.1, 0.14), TRIM, "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 16.0), Vector3(60, 12, 0.1), Color("cfe6f1"), "fp")
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("efe9dd"))
	for x in [-6.0, 0.0, 6.0]:
		k.box("facade", Vector3(x, HEIGHT - 0.12, 0), Vector3(0.3, 0.24, Z1 - Z0), TRIM, "fp")
	for x in [-6.0, -0.5, 5.5]:
		for z in [-3.5, 3.5]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.0, 1.0))
	# A stone skirting all round.
	k.box("facade", Vector3(0, 0.12, Z0 + 0.21), Vector3(X1 - X0, 0.24, 0.03), TRIM)
	k.box("facade", Vector3(X0 + 0.21, 0.12, 0), Vector3(0.03, 0.24, Z1 - Z0), TRIM)

static func _lobby(scene: Node3D, k, at: Callable) -> void:
	# The portico doors: oak, opening as you come up to them.
	var doors: Node3D = scene.add_doors("EntranceDoors", at.call(Vector3(0, 0, Z1)), 0.0, 2.0, 3.0, false, OAK.darkened(0.3), OAK)
	doors.auto_target = scene.player_target()
	doors.auto_depth = 2.0
	doors.speed = 2.0
	scene.entrance_doors = [doors]
	k.box("facade", Vector3(0, 0.01, 5.6), Vector3(2.4, 0.02, 1.4), Color("7a2f32"))
	# The donor memorial on the east wall.
	k.box("walnut", Vector3(X1 - 0.24, 1.9, 4.0), Vector3(0.06, 1.5, 2.6), Color.WHITE, "fp")
	k.box("facade", Vector3(X1 - 0.2, 1.9, 4.0), Vector3(0.03, 1.3, 2.4), Color("b89a5a"), "fp")
	scene.add_sign("IN GRATITUDE\nTo those who gave their bodies\nso that we might learn to heal.\nThey are our first patients.", at.call(Vector3(X1 - 0.18, 1.95, 4.0)), -PI / 2, 22, 0.0048, "fp", Color("b89a5a"), Color("2a2522"))
	k.box("walnut", Vector3(X1 - 0.9, 0.55, 2.2), Vector3(0.5, 1.1, 0.5), Color.WHITE, "always", true)
	k.box("facade", Vector3(X1 - 0.9, 1.14, 2.2), Vector3(0.44, 0.06, 0.34), Color("e9e2d3"))
	k.box("facade", Vector3(X1 - 0.9, 1.18, 2.2), Vector3(0.38, 0.03, 0.28), Color("7a2f32"))
	for index in range(5):
		k.box("facade", Vector3(X1 - 0.5, 0.2 + index * 0.02, 5.7 - index * 0.12), Vector3(0.16, 0.4 + index * 0.05, 0.16), [Color("f2f2ee"), Color("f2c46d"), Color("e8708a"), Color("f2f2ee"), Color("c7a4e0")][index])
	k.box("facade", Vector3(X1 - 0.5, 0.18, 5.45), Vector3(0.3, 0.36, 0.3), Color("3a4045"), "always", true)
	scene.memorial_point = at.call(Vector3(X1 - 1.5, 1.0, 3.2))
	# Benches along the west wall of the lobby.
	for z in [3.0, 5.2]:
		k.box("walnut", Vector3(X0 + 0.7, 0.24, z), Vector3(0.5, 0.06, 1.8), Color.WHITE, "always", true)
		for dz in [-0.8, 0.8]:
			k.box("walnut", Vector3(X0 + 0.7, 0.11, z + dz), Vector3(0.44, 0.22, 0.1), Color.WHITE)
	scene.add_figure(scene.student_look(610), at.call(Vector3(X0 + 0.72, 0, 3.0)), -PI / 2, "seated", 0.3)
	scene.add_floor_label("ANATOMY HALL", at.call(Vector3(0, 0.012, 3.4)), 0.006)

static func _theatre(scene: Node3D, k, at: Callable) -> void:
	# Its wall on the lobby, with an arched doorway.
	k.wall(false, 1.5, X0, 2.5, HEIGHT, WALL, true, [[-3.25, 1.8, 2.8]], 0.3)
	k.wall(true, 2.5, Z0, 1.5, HEIGHT, WALL, true, [], 0.3)
	scene.add_sign("THE ANATOMICAL THEATRE · 1911", at.call(Vector3(-3.25, 3.2, 1.67)), 0.0, 22, 0.006, "fp")
	var r := THEATRE
	var seats: Array = []
	for tier in range(3):
		var inset := tier * TIER_DEPTH
		var height := (3 - tier) * TIER_RISE
		var color := OAK.darkened(0.06 * tier)
		# West, north and east bands, each a step up toward the wall.
		var west := Rect2(r.position.x + inset, r.position.y + inset, TIER_DEPTH, r.size.y - inset)
		var north := Rect2(r.position.x + inset, r.position.y + inset, r.size.x - 2.0 * inset, TIER_DEPTH)
		var east := Rect2(r.end.x - inset - TIER_DEPTH, r.position.y + inset, TIER_DEPTH, r.size.y - inset)
		for band in [west, north, east]:
			k.box("walnut", Vector3(band.get_center().x, height / 2.0, band.get_center().y), Vector3(band.size.x, height, band.size.y), color, "always", true)
		# Places to sit on each tier's front edge, feet on the tier below
		# ([point on the tier below, the yaw a sitter faces]; seat height TIER_RISE).
		var y := height - TIER_RISE
		for index in range(int((north.size.x - 1.0) / 1.1)):
			var x := north.position.x + 0.9 + index * 1.1
			seats.append([Vector3(x, y, north.end.y - 0.3), PI])
		for index in range(int((west.size.y - TIER_DEPTH - 0.6) / 1.1)):
			var z := west.position.y + TIER_DEPTH + 0.5 + index * 1.1
			seats.append([Vector3(west.end.x - 0.3, y, z), -PI / 2])
			seats.append([Vector3(east.position.x + 0.3, y, z), PI / 2])
		# A brass rail along the top tier's edge.
		if tier == 0:
			k.box("metal", Vector3(north.get_center().x, height + 0.9, north.end.y - 0.05), Vector3(north.size.x, 0.04, 0.04), Color("b8a06a"), "fp")
	scene.theatre_seats = seats.map(func(seat: Array) -> Array: return [at.call(seat[0]), seat[1]])
	# The central table (draped; the dedication's flowers go on it) and a lectern.
	k.box("walnut", Vector3(-3.25, 0.45, -2.3), Vector3(2.2, 0.9, 0.9), OAK.darkened(0.2), "always", true)
	k.box("facade", Vector3(-3.25, 0.93, -2.3), Vector3(2.3, 0.06, 1.0), Color("f2f2ee"))
	k.box("walnut", Vector3(-0.9, 0.6, -0.6), Vector3(0.5, 1.2, 0.4), OAK, "always", true)
	scene.lectern_point = at.call(Vector3(-0.9, 1.2, -0.6))
	k.box("facade", Vector3(-3.25, 0.01, -1.6), Vector3(5.0, 0.02, 5.0), Color("c9bea6"))
	# Portraits of the old professors (first person), high on the north wall.
	for x in [-6.6, -3.25, 0.1]:
		k.box("walnut", Vector3(x, 3.9, Z0 + 0.23), Vector3(1.0, 1.2, 0.05), Color.WHITE, "fp")
		k.box("facade", Vector3(x, 3.9, Z0 + 0.26), Vector3(0.84, 1.04, 0.01), Color("5b4a3a"), "fp")

static func _stair_hall(scene: Node3D, k, at: Callable) -> void:
	# The stair down in its railed well (the well's walls, six stone steps
	# descending north and a landing), the lift beside it.
	var w := WELL
	for side in [[Vector3(w.position.x + 0.02, -0.6, w.get_center().y), Vector3(0.04, 1.2, w.size.y)], [Vector3(w.end.x - 0.02, -0.6, w.get_center().y), Vector3(0.04, 1.2, w.size.y)], [Vector3(w.get_center().x, -0.6, w.end.y - 0.02), Vector3(w.size.x, 1.2, 0.04)], [Vector3(w.get_center().x, -0.6, w.position.y + 0.02), Vector3(w.size.x, 1.2, 0.04)]]:
		k.box("facade", side[0], side[1], TRIM.darkened(0.15))
	for step in range(6):
		var top := -0.18 * (step + 1)
		k.box("facade", Vector3(w.get_center().x, top - 0.09, w.end.y - 0.18 - step * 0.36), Vector3(w.size.x - 0.08, 0.18, 0.36), TRIM)
	var landing := w.end.y - 6 * 0.36
	k.box("facade", Vector3(w.get_center().x, -1.17, (landing + w.position.y) / 2.0), Vector3(w.size.x - 0.08, 0.06, landing - w.position.y), Color("5d6468"))
	# Glass balustrades with a bronze handrail round the well.
	for rail in [[Vector3(w.position.x - 0.03, 0, w.get_center().y), Vector3(0.05, 0, w.size.y)], [Vector3(w.end.x + 0.03, 0, w.get_center().y), Vector3(0.05, 0, w.size.y)], [Vector3(w.get_center().x, 0, w.end.y + 0.03), Vector3(w.size.x + 0.1, 0, 0.05)]]:
		var at_rail: Vector3 = rail[0]
		var size: Vector3 = rail[1]
		k.box("clear", at_rail + Vector3(0, 0.5, 0), size + Vector3(0, 0.96, 0), Color(0.84, 0.92, 0.95, 0.3))
		k.box("metal", at_rail + Vector3(0, 1.0, 0), size + Vector3(0.03, 0.05, 0.03), Color("8a6a3a"))
		k.solid(at_rail + Vector3(0, 0.5, 0), size + Vector3(0, 1.0, 0))
	Props.elevator_frame(k, Vector3(3.4, 0, Z0 + 0.4), 0.0, 1.2, true)
	scene.add_sign("GROSS ANATOMY LABORATORY · LOWER LEVEL\nStudents of the current course only", at.call(Vector3(6.4, 2.9, Z0 + 0.22)), 0.0, 20, 0.005, "always", NAVY, Color.WHITE)
	scene.stairs_point = at.call(Vector3(w.get_center().x, 1.0, w.end.y + 0.5))
	# The department office door on the east wall.
	k.box("walnut", Vector3(X1 - 0.22, 1.1, 0.4), Vector3(0.06, 2.2, 1.0), Color.WHITE, "fp")
	k.box("walnut", Vector3(X1 - 0.22, 0.52, 0.4), Vector3(0.06, 1.04, 1.0), Color.WHITE, "tp")
	scene.add_sign("Department of Anatomy", at.call(Vector3(X1 - 0.19, 2.45, 0.4)), -PI / 2, 16, 0.004, "fp")

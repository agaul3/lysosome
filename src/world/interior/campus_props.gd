extends RefCounted
## Furniture for the campus buildings (food courts, the library, teaching
## rooms, the Clinical Skills Center, the Student Center), built into a
## HospitalKit like the hospital's props: merged meshes, simple colliders,
## zone-local positions, and `yaw` turning an item so its front faces +Z.
## Seats stay low (about 0.36 m) to suit the figures' seated hips.
const Props = preload("res://world/hospital/hospital_props.gd")
const DARK := Color("3a4045")
const METAL := Color("c9ced2")
const WHITE := Color("f4f4f1")
const SCREEN := Color("16202a")
const CHAIR_SEAT := 0.36

static func _at(pos: Vector3, yaw: float, local: Vector3) -> Vector3:
	return pos + Basis(Vector3.UP, yaw) * local

static func _box(k, kind: String, pos: Vector3, yaw: float, local: Vector3, size: Vector3, color: Color, layer := "always") -> void:
	k.box(kind, _at(pos, yaw, local), size, color, layer, false, Basis(Vector3.UP, yaw))

static func _solid(k, pos: Vector3, yaw: float, local: Vector3, size: Vector3) -> void:
	k.solid(_at(pos, yaw, local), (Basis(Vector3.UP, yaw) * size).abs())

## A café chair; its seat front faces +Z rotated by yaw. Returns the seat point.
static func cafe_chair(k, pos: Vector3, yaw: float, color := Color("d9824a")) -> Vector3:
	_box(k, "facade", pos, yaw, Vector3(0, CHAIR_SEAT - 0.03, 0), Vector3(0.44, 0.06, 0.42), color)
	_box(k, "facade", pos, yaw, Vector3(0, CHAIR_SEAT + 0.24, -0.2), Vector3(0.42, 0.44, 0.05), color)
	for side in [Vector2(-0.18, -0.17), Vector2(0.18, -0.17), Vector2(-0.18, 0.17), Vector2(0.18, 0.17)]:
		_box(k, "metal", pos, yaw, Vector3(side.x, (CHAIR_SEAT - 0.06) / 2.0, side.y), Vector3(0.03, CHAIR_SEAT - 0.06, 0.03), DARK)
	return pos

## A café table with chairs round it. Returns the chair positions (seat centres) and their yaws.
static func dining_set(k, pos: Vector3, yaw: float, chairs := 4, square := true, top := Color("e9e4da"), chair_color := Color("d9824a")) -> Array:
	var size := Vector3(0.9, 0.04, 0.9) if square else Vector3(1.5, 0.04, 0.8)
	_box(k, "facade", pos, yaw, Vector3(0, 0.62, 0), size, top)
	_box(k, "metal", pos, yaw, Vector3(0, 0.31, 0), Vector3(0.08, 0.6, 0.08), DARK)
	_box(k, "metal", pos, yaw, Vector3(0, 0.02, 0), Vector3(0.5, 0.03, 0.5), DARK)
	_solid(k, pos, yaw, Vector3(0, 0.34, 0), Vector3(size.x, 0.68, size.z))
	var result: Array = []
	var spots: Array = [Vector3(0, 0, 0.72), Vector3(0, 0, -0.72), Vector3(0.78, 0, 0), Vector3(-0.78, 0, 0)] if square else [Vector3(-0.38, 0, 0.72), Vector3(0.38, 0, 0.72), Vector3(-0.38, 0, -0.72), Vector3(0.38, 0, -0.72)]
	for index in range(mini(chairs, spots.size())):
		var local: Vector3 = spots[index]
		var chair_yaw := yaw + atan2(local.x, local.z)
		var at := _at(pos, yaw, local)
		cafe_chair(k, at, chair_yaw + PI, chair_color)
		result.append([at, chair_yaw + PI])
	return result

## A food-court stall: counter with a register and a lit menu board above,
## front facing +Z rotated by yaw. `accent` colours the fascia.
static func vendor_stall(k, pos: Vector3, yaw: float, width: float, accent: Color) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.5, 0), Vector3(width, 1.0, 0.7), Color("e9e4da"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.08, 0.36), Vector3(width, 0.16, 0.04), DARK)
	_box(k, "walnut", pos, yaw, Vector3(0, 1.03, 0.02), Vector3(width + 0.04, 0.06, 0.78), Color.WHITE)
	_box(k, "clear", pos, yaw, Vector3(width * 0.2, 1.25, 0.1), Vector3(width * 0.45, 0.4, 0.36), Color(0.85, 0.93, 0.95, 0.25))
	_box(k, "metal", pos, yaw, Vector3(-width * 0.32, 1.16, 0.0), Vector3(0.34, 0.2, 0.3), DARK)
	# Back counter and fascia.
	_box(k, "metal", pos, yaw, Vector3(0, 0.46, -1.6), Vector3(width, 0.92, 0.6), METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 2.72, -1.9), Vector3(width + 0.2, 0.7, 0.12), accent)
	_box(k, "light", pos, yaw, Vector3(0, 2.1, -1.93), Vector3(width * 0.8, 0.62, 0.02), Color("22303a"))
	_solid(k, pos, yaw, Vector3(0, 0.55, 0), Vector3(width, 1.1, 0.8))
	_solid(k, pos, yaw, Vector3(0, 0.5, -1.6), Vector3(width, 1.0, 0.7))

## A double-sided run of library shelving, `length` long along local X.
static func book_stack(k, pos: Vector3, yaw: float, length := 4.0, height := 2.1) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, height / 2.0, 0), Vector3(length, height, 0.06), Color.WHITE)
	var colors := [Color("7a4b3a"), Color("35557a"), Color("4f6b44"), Color("8c6d3f"), Color("5d4a6e"), Color("9a3f3a"), Color("2f5d62"), Color("b58a54")]
	var shelves := int(height / 0.42)
	for shelf in range(shelves):
		var y := 0.1 + shelf * 0.42
		for side in [-1, 1]:
			_box(k, "walnut", pos, yaw, Vector3(0, y, side * 0.16), Vector3(length, 0.03, 0.3), Color.WHITE)
			var x := -length / 2.0 + 0.08
			var index := shelf * 5 + (0 if side < 0 else 3)
			while x < length / 2.0 - 0.12:
				var width := 0.05 + float((index * 7) % 5) * 0.012
				var tall := 0.24 + float((index * 3) % 4) * 0.025
				_box(k, "facade", pos, yaw, Vector3(x + width / 2.0, y + 0.015 + tall / 2.0, side * 0.15), Vector3(width, tall, 0.2), colors[index % colors.size()])
				x += width + 0.008
				index += 1
	for end in [-1, 1]:
		_box(k, "walnut", pos, yaw, Vector3(end * length / 2.0, height / 2.0, 0), Vector3(0.05, height, 0.36), Color.WHITE)
	_solid(k, pos, yaw, Vector3(0, height / 2.0, 0), Vector3(length, height, 0.38))

## A study carrel: desk with side and back panels, a PC if `pc`. Front faces +Z.
static func carrel(k, pos: Vector3, yaw: float, pc := true, panel := Color("5b6c74")) -> void:
	_box(k, "wood", pos, yaw, Vector3(0, 0.72, 0), Vector3(1.1, 0.04, 0.62), Color.WHITE)
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.57, 0.62, -0.02), Vector3(0.04, 1.24, 0.66), panel)
	_box(k, "facade", pos, yaw, Vector3(0, 0.95, -0.33), Vector3(1.14, 0.46, 0.04), panel)
	_box(k, "metal", pos, yaw, Vector3(0, 0.36, -0.28), Vector3(1.0, 0.7, 0.03), DARK)
	if pc:
		Props.monitor(k, _at(pos, yaw, Vector3(0, 0.74, -0.18)), yaw, 0.5)
		_box(k, "facade", pos, yaw, Vector3(0, 0.75, 0.05), Vector3(0.42, 0.02, 0.14), DARK)
	_solid(k, pos, yaw, Vector3(0, 0.62, -0.05), Vector3(1.2, 1.24, 0.7))

## A long reading table with green-shaded lamps and chairs on both sides.
## Returns [seat point, yaw] pairs.
static func reading_table(k, pos: Vector3, yaw: float, length := 3.6, chairs_per_side := 3) -> Array:
	_box(k, "walnut", pos, yaw, Vector3(0, 0.74, 0), Vector3(length, 0.05, 1.1), Color.WHITE)
	for end in [-1, 1]:
		_box(k, "walnut", pos, yaw, Vector3(end * (length / 2.0 - 0.15), 0.36, 0), Vector3(0.08, 0.72, 0.9), Color.WHITE)
	var lamps := int(length / 1.2)
	for index in range(lamps):
		var x := -length / 2.0 + (index + 0.5) * length / lamps
		_box(k, "metal", pos, yaw, Vector3(x, 0.94, 0), Vector3(0.03, 0.36, 0.03), Color("b8a06a"))
		_box(k, "facade", pos, yaw, Vector3(x, 1.12, 0), Vector3(0.34, 0.1, 0.16), Color("2e6b4f"))
		_box(k, "light", pos, yaw, Vector3(x, 1.065, 0), Vector3(0.3, 0.01, 0.12), Color("fff1c8"))
	_solid(k, pos, yaw, Vector3(0, 0.4, 0), Vector3(length, 0.8, 1.1))
	var seats: Array = []
	for index in range(chairs_per_side):
		var x := -length / 2.0 + (index + 0.5) * length / chairs_per_side
		for side in [-1, 1]:
			var at := _at(pos, yaw, Vector3(x, 0, side * 0.86))
			var chair_yaw := yaw + (0.0 if side < 0 else PI)
			cafe_chair(k, at, chair_yaw, Color("6d4c36"))
			seats.append([at, chair_yaw])
	return seats

## A lab bench with a microscope, slide box and stool, front facing +Z.
static func microscope_bench(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.45, 0), Vector3(1.2, 0.9, 0.7), Color("e3e6e8"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.915, 0), Vector3(1.24, 0.03, 0.74), Color("2f3437"))
	# Microscope: base, arm, stage and eyepieces.
	_box(k, "metal", pos, yaw, Vector3(0, 0.95, -0.05), Vector3(0.2, 0.04, 0.26), Color("f1f1ee"))
	_box(k, "metal", pos, yaw, Vector3(0, 1.1, -0.14), Vector3(0.08, 0.28, 0.07), Color("f1f1ee"))
	_box(k, "metal", pos, yaw, Vector3(0, 1.03, -0.03), Vector3(0.16, 0.02, 0.14), DARK)
	_box(k, "metal", pos, yaw, Vector3(0, 1.24, -0.06), Vector3(0.1, 0.06, 0.16), DARK)
	for side in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(side * 0.025, 1.3, 0.01), Vector3(0.025, 0.08, 0.025), DARK)
	_box(k, "facade", pos, yaw, Vector3(0.38, 0.95, 0.05), Vector3(0.26, 0.05, 0.16), Color("7a4b3a"))
	_box(k, "facade", pos, yaw, Vector3(-0.2, 0.34, 0.62), Vector3(0.36, 0.05, 0.36), DARK)
	_box(k, "metal", pos, yaw, Vector3(-0.2, 0.17, 0.62), Vector3(0.05, 0.32, 0.05), METAL)
	_solid(k, pos, yaw, Vector3(0, 0.46, 0), Vector3(1.24, 0.92, 0.74))

## An examination table (padded, with a paper roll and a step), head at −X.
static func exam_table(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.36, 0), Vector3(1.8, 0.72, 0.62), Color("d9dee1"))
	_box(k, "facade", pos, yaw, Vector3(0.12, 0.78, 0), Vector3(1.5, 0.12, 0.64), Color("5d7a88"))
	_box(k, "facade", pos, yaw, Vector3(-0.72, 0.93, 0), Vector3(0.5, 0.12, 0.64), Color("5d7a88"), "always")
	_box(k, "facade", pos, yaw, Vector3(0.12, 0.845, 0), Vector3(1.9, 0.01, 0.5), Color("f7f5ee"))
	_box(k, "metal", pos, yaw, Vector3(1.05, 0.2, 0), Vector3(0.3, 0.12, 0.5), METAL)
	_solid(k, pos, yaw, Vector3(0, 0.45, 0), Vector3(1.9, 0.9, 0.66))

## A handwashing sink on a cabinet, front facing +Z.
static func sink(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.44, 0), Vector3(0.9, 0.88, 0.56), Color("e3e6e8"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.9, 0), Vector3(0.94, 0.04, 0.6), Color("f4f4f1"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.88, 0.02), Vector3(0.44, 0.06, 0.34), METAL)
	_box(k, "metal", pos, yaw, Vector3(0, 1.08, -0.18), Vector3(0.04, 0.3, 0.04), METAL)
	_solid(k, pos, yaw, Vector3(0, 0.45, 0), Vector3(0.94, 0.9, 0.6))

## A wall-mounted whiteboard (front faces +Z).
## `layer` "fp" for a board on a wall the overhead view cuts away.
static func whiteboard(k, pos: Vector3, yaw: float, width := 2.4, notes := true, layer := "always") -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 1.45, 0), Vector3(width + 0.08, 1.08, 0.03), METAL, layer)
	_box(k, "facade", pos, yaw, Vector3(0, 1.45, 0.018), Vector3(width, 1.0, 0.01), Color("f7f8f6"), layer)
	_box(k, "metal", pos, yaw, Vector3(0, 0.92, 0.05), Vector3(width * 0.6, 0.03, 0.08), METAL, layer)
	if notes:
		var colors := [Color("2f5fa8"), Color("c2452d"), Color("2f7a4a")]
		for line in range(5):
			_box(k, "facade", pos, yaw, Vector3(-width * 0.3 + (line % 2) * 0.1, 1.78 - line * 0.14, 0.025), Vector3(width * (0.3 + float(line % 3) * 0.1), 0.02, 0.005), colors[line % 3], layer)

## An oval conference/small-group table with chairs; returns [seat, yaw] pairs.
static func group_table(k, pos: Vector3, yaw: float, chairs := 8) -> Array:
	_box(k, "wood", pos, yaw, Vector3(0, 0.74, 0), Vector3(3.2, 0.05, 1.3), Color.WHITE)
	for end in [-1, 1]:
		_box(k, "wood", pos, yaw, Vector3(end * 1.6, 0.74, 0), Vector3(0.3, 0.05, 1.0), Color.WHITE)
	for end in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(end * 1.0, 0.36, 0), Vector3(0.1, 0.72, 0.5), DARK)
	_solid(k, pos, yaw, Vector3(0, 0.4, 0), Vector3(3.6, 0.8, 1.3))
	var seats: Array = []
	var per_side := chairs / 2
	for index in range(per_side):
		var x := -1.2 + index * 2.4 / maxf(1.0, per_side - 1.0)
		for side in [-1, 1]:
			var at := _at(pos, yaw, Vector3(x, 0, side * 1.0))
			var chair_yaw := yaw + (0.0 if side < 0 else PI)
			Props.office_chair(k, at, chair_yaw, Color("39464d"))
			seats.append([at, chair_yaw])
	return seats

## A bank of lockers along local X.
static func lockers(k, pos: Vector3, yaw: float, count := 6, color := Color("5b7fa1")) -> void:
	for index in range(count):
		var x := (index - (count - 1) / 2.0) * 0.46
		_box(k, "metal", pos, yaw, Vector3(x, 0.95, 0), Vector3(0.44, 1.9, 0.5), color)
		_box(k, "metal", pos, yaw, Vector3(x + 0.14, 1.1, 0.26), Vector3(0.03, 0.12, 0.02), DARK)
		for vent in range(3):
			_box(k, "metal", pos, yaw, Vector3(x, 1.7 - vent * 0.06, 0.255), Vector3(0.24, 0.015, 0.01), color.darkened(0.3))
	_solid(k, pos, yaw, Vector3(0, 0.95, 0), Vector3(count * 0.46, 1.9, 0.5))

## A pool table (the Student Center lounge).
static func pool_table(k, pos: Vector3, yaw: float) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, 0.7, 0), Vector3(2.4, 0.14, 1.36), Color.WHITE)
	_box(k, "facade", pos, yaw, Vector3(0, 0.78, 0), Vector3(2.16, 0.02, 1.12), Color("2f6b45"))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_box(k, "walnut", pos, yaw, Vector3(corner.x * 1.0, 0.32, corner.y * 0.52), Vector3(0.14, 0.64, 0.14), Color.WHITE)
	for ball in range(6):
		_box(k, "facade", pos, yaw, Vector3(0.4 + (ball % 3) * 0.08, 0.81, -0.1 + int(ball / 3) * 0.08), Vector3(0.05, 0.05, 0.05), [Color("f2c230"), Color("c2452d"), Color("2f5fa8"), Color("2f7a4a"), Color("1b1b1b"), Color("e98a4f")][ball])
	_solid(k, pos, yaw, Vector3(0, 0.4, 0), Vector3(2.4, 0.8, 1.36))

## Book-security gates at a library entrance (pairs of pillars).
static func security_gate(k, pos: Vector3, yaw: float) -> void:
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.5, 0.75, 0), Vector3(0.12, 1.5, 0.5), Color("d9dee1"))
		_box(k, "light", pos, yaw, Vector3(side * 0.5, 1.4, 0.26), Vector3(0.08, 0.1, 0.01), Color("7fd6a0"))
		_solid(k, pos, yaw, Vector3(side * 0.5, 0.75, 0), Vector3(0.12, 1.5, 0.5))

## A low sofa (lounges), front facing +Z. Returns [seat points] (two places).
static func sofa(k, pos: Vector3, yaw: float, color := Color("4f6f86"), width := 1.9) -> Array:
	_box(k, "facade", pos, yaw, Vector3(0, 0.2, 0), Vector3(width, 0.3, 0.8), color.darkened(0.15))
	_box(k, "facade", pos, yaw, Vector3(0, 0.34, 0.04), Vector3(width - 0.2, 0.08, 0.66), color)
	_box(k, "facade", pos, yaw, Vector3(0, 0.62, -0.32), Vector3(width, 0.52, 0.18), color)
	for end in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(end * (width / 2.0 - 0.09), 0.48, 0), Vector3(0.18, 0.28, 0.8), color.darkened(0.1))
	_solid(k, pos, yaw, Vector3(0, 0.4, 0), Vector3(width, 0.8, 0.8))
	return [_at(pos, yaw, Vector3(-width * 0.24, 0, 0.06)), _at(pos, yaw, Vector3(width * 0.24, 0, 0.06))]

## A trash-and-recycling station.
static func bins(k, pos: Vector3, yaw: float) -> void:
	var colors := [Color("3a4045"), Color("2f5fa8"), Color("4f8a3c")]
	for index in range(3):
		_box(k, "facade", pos, yaw, Vector3((index - 1) * 0.42, 0.45, 0), Vector3(0.38, 0.9, 0.42), colors[index])
		_box(k, "facade", pos, yaw, Vector3((index - 1) * 0.42, 0.91, 0.08), Vector3(0.28, 0.02, 0.12), DARK)
	_solid(k, pos, yaw, Vector3(0, 0.45, 0), Vector3(1.3, 0.9, 0.44))

## A glazed room front along X (at z = `line`) or along Z (at x = `line`)
## from `from` to `to`, with automatic sliding glass doors centred at
## `door_center`. Returns the doors. The glass is first-person height; the
## overhead cutaway keeps it waist-high. `scene` is the building (add_doors).
static func glass_front(scene: Node3D, k, name: String, along_z: bool, line: float, from: float, to: float, door_center: float, door_width := 1.6, locked := false, frame := Color("9aa2a7"), header := 0.0, header_color := Color("e6e3dc")) -> Node3D:
	var glass := Color(0.84, 0.92, 0.95, 0.22)
	# A plastered header from the top of the glass to the ceiling (first
	# person), where the room's sign goes.
	if header > 2.55:
		var header_center := Vector3(line, (2.5 + header) / 2.0, (from + to) / 2.0) if along_z else Vector3((from + to) / 2.0, (2.5 + header) / 2.0, line)
		var header_size := Vector3(0.14, header - 2.5, to - from) if along_z else Vector3(to - from, header - 2.5, 0.14)
		k.box("facade", header_center, header_size, header_color, "fp")
	var d0 := door_center - door_width / 2.0
	var d1 := door_center + door_width / 2.0
	for span in [[from, d0], [d1, to]]:
		var a: float = span[0] + 0.04
		var b: float = span[1] - 0.04
		if b - a < 0.05:
			continue
		var mid := (a + b) / 2.0
		var length := b - a
		var center := Vector3(line, 0, mid) if along_z else Vector3(mid, 0, line)
		var size := Vector3(0.04, 0, length) if along_z else Vector3(length, 0, 0.04)
		k.box("clear", center + Vector3(0, 1.25, 0), size + Vector3(0, 2.5, 0), glass, "fp")
		k.box("clear", center + Vector3(0, 0.525, 0), size + Vector3(0, 1.05, 0), glass, "tp")
		k.box("metal", center + Vector3(0, 0.05, 0), (Vector3(0.1, 0.1, length) if along_z else Vector3(length, 0.1, 0.1)), frame)
		k.box("metal", center + Vector3(0, 1.07, 0), (Vector3(0.1, 0.04, length) if along_z else Vector3(length, 0.04, 0.1)), frame, "tp")
		k.solid(center + Vector3(0, 1.3, 0), (Vector3(0.16, 2.6, length) if along_z else Vector3(length, 2.6, 0.16)))
		var count := int(length / 1.3)
		for index in range(1, count + 1):
			var along := a + index * length / (count + 1)
			var post := Vector3(line, 1.25, along) if along_z else Vector3(along, 1.25, line)
			k.box("metal", post, Vector3(0.07, 2.5, 0.04) if along_z else Vector3(0.04, 2.5, 0.07), frame, "fp")
	for edge in [from, d0, d1, to]:
		var post := Vector3(line, 1.25, edge) if along_z else Vector3(edge, 1.25, line)
		k.box("metal", post, Vector3(0.1, 2.5, 0.08) if along_z else Vector3(0.08, 2.5, 0.1), frame, "fp")
	var doors: Node3D = scene.add_doors(name, k.offset + (Vector3(line, 0, door_center) if along_z else Vector3(door_center, 0, line)), PI / 2 if along_z else 0.0, door_width, 2.4, true, frame)
	doors.auto_target = scene.player_target()
	doors.auto_group = "door_openers"
	doors.auto_depth = 1.7
	doors.speed = 2.6
	doors.locked = locked
	scene.add_fp_node(doors)
	return doors

## Study-table geometry shared with the café's study nook: the top at 0.79 m,
## 0.8 m deep, with seats 1.15 m from its centre line so a sitter's side
## approach clears the edge.
const STUDY_TOP := 0.79
const STUDY_SEAT_OFFSET := 1.15
## Where a laptop sits in a study seat's own frame (world/seat.gd laptop_surface).
const STUDY_LAPTOP := Vector3(0, 0.795, -0.98)

## A table for laptops: only the table; the scene places world/seat.gd chairs
## at the returned [seat point, seat yaw] pairs (a seat faces its −Z, toward
## the table). Length runs along local X; green-shaded lamps if `lamps`.
static func study_table(k, pos: Vector3, yaw: float, length := 2.8, seats_per_side := 2, lamps := false) -> Array:
	_box(k, "walnut", pos, yaw, Vector3(0, STUDY_TOP - 0.03, 0), Vector3(length, 0.06, 0.8), Color.WHITE)
	for x in [-length / 2.0 + 0.12, length / 2.0 - 0.12]:
		_box(k, "metal", pos, yaw, Vector3(x, (STUDY_TOP - 0.06) / 2.0, 0), Vector3(0.06, STUDY_TOP - 0.06, 0.64), DARK)
		_solid(k, pos, yaw, Vector3(x, (STUDY_TOP - 0.06) / 2.0, 0), Vector3(0.06, STUDY_TOP - 0.06, 0.64))
	_box(k, "metal", pos, yaw, Vector3(0, STUDY_TOP + 0.025, 0), Vector3(length - 0.5, 0.05, 0.1), Color("5b6469"))
	if lamps:
		var count := maxi(1, int(length / 1.4))
		for index in range(count):
			var x := -length / 2.0 + (index + 0.5) * length / count
			_box(k, "metal", pos, yaw, Vector3(x, STUDY_TOP + 0.2, 0), Vector3(0.03, 0.36, 0.03), Color("b8a06a"))
			_box(k, "facade", pos, yaw, Vector3(x, STUDY_TOP + 0.38, 0), Vector3(0.34, 0.1, 0.16), Color("2e6b4f"))
			_box(k, "light", pos, yaw, Vector3(x, STUDY_TOP + 0.325, 0), Vector3(0.3, 0.01, 0.12), Color("fff1c8"))
	_solid(k, pos, yaw, Vector3(0, STUDY_TOP - 0.03, 0), Vector3(length, 0.06, 0.8))
	var seats: Array = []
	for index in range(seats_per_side):
		var x := -length / 2.0 + (index + 0.5) * length / seats_per_side
		for side in [-1.0, 1.0]:
			seats.append([_at(pos, yaw, Vector3(x, 0, side * STUDY_SEAT_OFFSET)), yaw + (0.0 if side > 0 else PI)])
	return seats

## A computer desk (the library's Computer Commons): desk, monitor, keyboard,
## mouse and an office chair; the user stands or sits on the +Z side.
## Returns the screen's centre (its quad faces +Z turned by yaw).
static func pc_desk(k, pos: Vector3, yaw: float, chair := Color("39464d")) -> Vector3:
	_box(k, "wood", pos, yaw, Vector3(0, 0.74, 0), Vector3(1.2, 0.04, 0.7), Color.WHITE)
	for x in [-0.56, 0.56]:
		_box(k, "metal", pos, yaw, Vector3(x, 0.36, 0), Vector3(0.05, 0.72, 0.6), DARK)
	_box(k, "facade", pos, yaw, Vector3(0, 0.46, -0.32), Vector3(1.1, 0.5, 0.03), Color("5b6c74"))
	Props.monitor(k, _at(pos, yaw, Vector3(0, 0.76, -0.14)), yaw, 0.56)
	_box(k, "facade", pos, yaw, Vector3(0, 0.77, 0.14), Vector3(0.44, 0.02, 0.15), DARK)
	_box(k, "facade", pos, yaw, Vector3(0.34, 0.775, 0.14), Vector3(0.06, 0.025, 0.1), Color("667184"))
	_box(k, "metal", pos, yaw, Vector3(-0.42, 0.24, -0.1), Vector3(0.2, 0.44, 0.42), Color("334153"))
	_solid(k, pos, yaw, Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 0.7))
	Props.office_chair(k, _at(pos, yaw, Vector3(0, 0, 0.62)), yaw + PI, chair)
	_solid(k, pos, yaw, Vector3(0, 0.45, 0.66), Vector3(0.5, 0.9, 0.5))
	return _at(pos, yaw, Vector3(0, 1.1, -0.118))

## A glass museum case on a plinth (the library's history-of-medicine
## exhibit); `item` colours what is on show.
static func display_case(k, pos: Vector3, yaw: float, item := Color("b08d57")) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, 0.45, 0), Vector3(1.2, 0.9, 0.7), Color.WHITE)
	_box(k, "facade", pos, yaw, Vector3(0, 0.915, 0), Vector3(1.1, 0.03, 0.6), Color("e9e2d3"))
	_box(k, "facade", pos, yaw, Vector3(0, 1.0, 0), Vector3(0.5, 0.14, 0.16), item)
	_box(k, "clear", pos, yaw, Vector3(0, 1.22, 0), Vector3(1.16, 0.6, 0.66), Color(0.86, 0.93, 0.96, 0.22))
	_box(k, "light", pos, yaw, Vector3(0, 1.53, 0), Vector3(1.0, 0.02, 0.5), Color("fff6e0"))
	_solid(k, pos, yaw, Vector3(0, 0.77, 0), Vector3(1.2, 1.54, 0.7))

# --- The Student Center ------------------------------------------------------------------------

## A chrome clothing rail along local X with garments hanging from it
## (`colors` cycles through them); front faces +Z.
static func clothing_rack(k, pos: Vector3, yaw: float, colors: Array, length := 2.0) -> void:
	for end in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(end * length / 2.0, 0.72, 0), Vector3(0.04, 1.44, 0.04), METAL)
		_box(k, "metal", pos, yaw, Vector3(end * length / 2.0, 0.02, 0), Vector3(0.06, 0.04, 0.5), METAL)
	_box(k, "metal", pos, yaw, Vector3(0, 1.44, 0), Vector3(length + 0.04, 0.03, 0.03), METAL)
	var count := int(length / 0.16)
	for index in range(count):
		var x := -length / 2.0 + 0.12 + index * (length - 0.24) / maxf(1.0, count - 1.0)
		var color: Color = Color(colors[index % colors.size()])
		_box(k, "facade", pos, yaw, Vector3(x, 1.02, 0), Vector3(0.05, 0.78, 0.46), color)
		_box(k, "facade", pos, yaw, Vector3(x, 1.43, 0), Vector3(0.02, 0.05, 0.2), Color("d8dadb"))
	_solid(k, pos, yaw, Vector3(0, 0.75, 0), Vector3(length, 1.5, 0.5))

## A store checkout: counter with a register and a card reader; the clerk
## stands on the −Z side, customers on +Z.
static func checkout(k, pos: Vector3, yaw: float, length := 2.2) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, 0.5, 0), Vector3(length, 1.0, 0.6), Color.WHITE)
	_box(k, "facade", pos, yaw, Vector3(0, 1.02, 0), Vector3(length + 0.04, 0.04, 0.66), Color("e9e4da"))
	Props.monitor(k, _at(pos, yaw, Vector3(-length * 0.25, 1.04, -0.12)), yaw + PI, 0.36)
	_box(k, "metal", pos, yaw, Vector3(length * 0.1, 1.1, 0.12), Vector3(0.1, 0.12, 0.14), DARK)
	_box(k, "facade", pos, yaw, Vector3(length * 0.32, 1.08, 0.05), Vector3(0.4, 0.08, 0.3), Color("c9b48c"))
	_solid(k, pos, yaw, Vector3(0, 0.5, 0), Vector3(length, 1.0, 0.6))

## A treadmill facing +Z (the runner looks along +Z).
static func treadmill(k, pos: Vector3, yaw: float) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.12, 0), Vector3(0.8, 0.2, 1.9), Color("2a2f33"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.23, -0.1), Vector3(0.56, 0.02, 1.5), Color("15181b"))
	for side in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(side * 0.36, 0.72, 0.78), Vector3(0.05, 1.0, 0.05), METAL)
		_box(k, "metal", pos, yaw, Vector3(side * 0.36, 1.02, 0.52), Vector3(0.04, 0.04, 0.5), METAL)
	_box(k, "metal", pos, yaw, Vector3(0, 1.26, 0.8), Vector3(0.7, 0.3, 0.1), Color("2a2f33"))
	_box(k, "light", pos, yaw, Vector3(0, 1.28, 0.748), Vector3(0.46, 0.18, 0.005), Color("3d6f8f"))
	_solid(k, pos, yaw, Vector3(0, 0.6, 0), Vector3(0.84, 1.2, 1.95))

## An upright exercise bike facing +Z.
static func exercise_bike(k, pos: Vector3, yaw: float) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.05, 0), Vector3(0.5, 0.08, 1.1), Color("2a2f33"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.45, 0.28), Vector3(0.1, 0.8, 0.12), Color("c2452d"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.62, -0.28), Vector3(0.1, 0.5, 0.1), METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 0.9, -0.3), Vector3(0.28, 0.08, 0.34), Color("15181b"))
	_box(k, "metal", pos, yaw, Vector3(0, 1.05, 0.38), Vector3(0.5, 0.04, 0.06), METAL)
	_box(k, "light", pos, yaw, Vector3(0, 1.08, 0.44), Vector3(0.18, 0.1, 0.02), Color("3d6f8f"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.3, 0.05), Vector3(0.08, 0.4, 0.4), Color("3a4045"))
	_solid(k, pos, yaw, Vector3(0, 0.55, 0), Vector3(0.56, 1.1, 1.15))

## A dumbbell rack along local X (two tiers) facing +Z.
static func dumbbell_rack(k, pos: Vector3, yaw: float, length := 2.4) -> void:
	for tier in range(2):
		var y := 0.45 + tier * 0.35
		var z := 0.08 - tier * 0.16
		_box(k, "metal", pos, yaw, Vector3(0, y, z), Vector3(length, 0.04, 0.3), Color("2a2f33"))
		var count := int(length / 0.3)
		for index in range(count):
			var x := -length / 2.0 + 0.18 + index * 0.3
			var weight := 0.1 + float(index % 5) * 0.012
			_box(k, "facade", pos, yaw, Vector3(x, y + 0.07, z), Vector3(0.24, weight, weight), Color("1b1d20"))
	for end in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(end * length / 2.0, 0.4, 0), Vector3(0.05, 0.8, 0.45), Color("2a2f33"))
	_solid(k, pos, yaw, Vector3(0, 0.42, 0), Vector3(length, 0.84, 0.5))

## A squat rack with a loaded bar and a flat bench in front (+Z).
static func squat_rack(k, pos: Vector3, yaw: float) -> void:
	for x in [-0.6, 0.6]:
		for z in [-0.5, 0.5]:
			_box(k, "metal", pos, yaw, Vector3(x, 1.1, z), Vector3(0.07, 2.2, 0.07), Color("2a2f33"))
	_box(k, "metal", pos, yaw, Vector3(0, 2.18, 0), Vector3(1.28, 0.06, 1.06), Color("2a2f33"))
	_box(k, "metal", pos, yaw, Vector3(0, 1.3, 0.1), Vector3(2.0, 0.04, 0.04), METAL)
	for end in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(end * 0.85, 1.3, 0.1), Vector3(0.06, 0.44, 0.44), Color("1b1d20"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.44, 1.1), Vector3(0.32, 0.08, 1.2), Color("1b1d20"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.2, 1.1), Vector3(0.08, 0.4, 0.9), METAL)
	_solid(k, pos, yaw, Vector3(0, 1.1, 0), Vector3(1.3, 2.2, 1.1))
	_solid(k, pos, yaw, Vector3(0, 0.24, 1.1), Vector3(0.34, 0.48, 1.2))

## A yoga mat (flat on the floor), rolled out along local Z.
static func yoga_mat(k, pos: Vector3, yaw: float, color := Color("7d5a86")) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.008, 0), Vector3(0.62, 0.012, 1.8), color)

## A ping-pong table (2.74 × 1.525 m) with its net across local X.
static func ping_pong(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.74, 0), Vector3(2.74, 0.04, 1.525), Color("1f4f7a"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.761, 0), Vector3(2.74, 0.002, 0.02), Color("f2f2ef"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.84, 0), Vector3(0.02, 0.15, 1.68), Color("e8e8e2"))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_box(k, "metal", pos, yaw, Vector3(corner.x * 1.1, 0.36, corner.y * 0.6), Vector3(0.05, 0.72, 0.05), DARK)
	_box(k, "facade", pos, yaw, Vector3(0.5, 0.78, 0.2), Vector3(0.04, 0.04, 0.04), Color("f2f2ef"))
	_solid(k, pos, yaw, Vector3(0, 0.4, 0), Vector3(2.74, 0.8, 1.525))

## An upright piano against a wall, keyboard facing +Z, with its bench.
static func piano(k, pos: Vector3, yaw: float) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, 0.62, -0.1), Vector3(1.5, 1.24, 0.5), Color("3a2a22"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.74, 0.2), Vector3(1.36, 0.05, 0.2), Color("f2f0ea"))
	for key in range(18):
		if key % 7 in [2, 6]:
			continue
		_box(k, "facade", pos, yaw, Vector3(-0.6 + key * 0.07, 0.78, 0.16), Vector3(0.03, 0.03, 0.1), Color("15181b"))
	_box(k, "walnut", pos, yaw, Vector3(0, 0.46, 0.72), Vector3(0.8, 0.06, 0.34), Color("3a2a22"))
	for x in [-0.34, 0.34]:
		_box(k, "walnut", pos, yaw, Vector3(x, 0.22, 0.72), Vector3(0.05, 0.44, 0.3), Color("3a2a22"))
	_solid(k, pos, yaw, Vector3(0, 0.62, -0.05), Vector3(1.5, 1.24, 0.6))
	_solid(k, pos, yaw, Vector3(0, 0.25, 0.72), Vector3(0.8, 0.5, 0.34))

## A corkboard of flyers on a wall (flat, facing +Z).
static func bulletin_board(k, pos: Vector3, yaw: float, width := 2.4, height := 1.2) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, 0, 0), Vector3(width + 0.08, height + 0.08, 0.03), Color.WHITE)
	_box(k, "facade", pos, yaw, Vector3(0, 0, 0.018), Vector3(width, height, 0.01), Color("b58a54"))
	var colors := [Color("f2c46d"), Color("f4f4f1"), Color("8fb5e8"), Color("e8708a"), Color("7fd6a0"), Color("c7a4e0")]
	for index in range(10):
		var x := -width / 2.0 + 0.3 + (index % 5) * (width - 0.6) / 4.0 + float((index * 7) % 3) * 0.04
		var y := 0.24 - int(index / 5) * 0.46 + float((index * 5) % 3) * 0.04
		_box(k, "facade", pos, yaw, Vector3(x, y, 0.026), Vector3(0.3, 0.38, 0.004), colors[index % colors.size()])

## A tall bar table and two stools (the juice bar).
static func high_table(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 1.04, 0), Vector3(0.7, 0.04, 0.7), Color("e9e4da"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.52, 0), Vector3(0.07, 1.02, 0.07), DARK)
	_box(k, "metal", pos, yaw, Vector3(0, 0.02, 0), Vector3(0.46, 0.03, 0.46), DARK)
	_solid(k, pos, yaw, Vector3(0, 0.53, 0), Vector3(0.7, 1.06, 0.7))
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.62, 0.72, 0), Vector3(0.36, 0.05, 0.36), Color("2f8f82"))
		_box(k, "metal", pos, yaw, Vector3(side * 0.62, 0.36, 0), Vector3(0.05, 0.72, 0.05), DARK)
		_solid(k, pos, yaw, Vector3(side * 0.62, 0.37, 0), Vector3(0.36, 0.74, 0.36))

# --- Anatomy Hall ------------------------------------------------------------------------------

## A downdraft dissection table (stainless, along local X) with the donor
## under a white drape (the donor's form is only suggested by the drape), a
## headrest block and the ventilation hood's duct above (first person).
static func dissection_table(k, pos: Vector3, yaw: float, covered := true, ceiling := 3.6) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.84, 0), Vector3(2.2, 0.06, 0.8), Color("c9ced2"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.62, 0), Vector3(2.1, 0.4, 0.7), Color("aeb5ba"))
	for x in [-0.9, 0.9]:
		_box(k, "metal", pos, yaw, Vector3(x, 0.22, 0), Vector3(0.1, 0.44, 0.5), Color("8d969b"))
	if covered:
		_box(k, "facade", pos, yaw, Vector3(0.02, 0.97, 0), Vector3(1.86, 0.2, 0.56), Color("f2f2ee"))
		_box(k, "facade", pos, yaw, Vector3(-0.78, 1.06, 0), Vector3(0.34, 0.14, 0.34), Color("f2f2ee"))
		_box(k, "facade", pos, yaw, Vector3(0.12, 1.08, 0), Vector3(0.9, 0.08, 0.46), Color("eeeeea"))
		_box(k, "facade", pos, yaw, Vector3(0.9, 1.02, 0), Vector3(0.18, 0.1, 0.4), Color("eeeeea"))
	_box(k, "metal", pos, yaw, Vector3(0, ceiling - 0.25, 0), Vector3(1.6, 0.5, 0.6), Color("d8dcdf"), "fp")
	_solid(k, pos, yaw, Vector3(0, 0.55, 0), Vector3(2.2, 1.1, 0.8))

## An articulated skeleton on a rolling stand, facing +Z (a teaching model).
static func skeleton_model(k, pos: Vector3, yaw: float) -> void:
	var bone := Color("ece4cf")
	_box(k, "metal", pos, yaw, Vector3(0, 0.03, 0), Vector3(0.6, 0.05, 0.6), DARK)
	_box(k, "metal", pos, yaw, Vector3(0, 0.95, -0.14), Vector3(0.03, 1.9, 0.03), METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 1.62, 0), Vector3(0.18, 0.22, 0.2), bone)
	_box(k, "facade", pos, yaw, Vector3(0, 1.36, 0), Vector3(0.06, 0.24, 0.06), bone)
	for rib in range(6):
		_box(k, "facade", pos, yaw, Vector3(0, 1.3 - rib * 0.06, 0.02), Vector3(0.32 - rib * 0.012, 0.025, 0.2), bone)
	_box(k, "facade", pos, yaw, Vector3(0, 0.98, 0), Vector3(0.05, 0.36, 0.05), bone)
	_box(k, "facade", pos, yaw, Vector3(0, 0.86, 0), Vector3(0.3, 0.12, 0.14), bone)
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.22, 1.12, 0), Vector3(0.04, 0.34, 0.04), bone)
		_box(k, "facade", pos, yaw, Vector3(side * 0.24, 0.8, 0.02), Vector3(0.035, 0.3, 0.035), bone)
		_box(k, "facade", pos, yaw, Vector3(side * 0.1, 0.56, 0), Vector3(0.05, 0.42, 0.05), bone)
		_box(k, "facade", pos, yaw, Vector3(side * 0.1, 0.17, 0), Vector3(0.04, 0.36, 0.04), bone)
		_box(k, "facade", pos, yaw, Vector3(side * 0.1, 0.02, 0.06), Vector3(0.07, 0.03, 0.14), bone)
	_solid(k, pos, yaw, Vector3(0, 0.9, 0), Vector3(0.6, 1.8, 0.6))

## A bench-top teaching model on a small plinth (a heart, a brain, a
## joint…): `colors` [main, detail].
static func bench_model(k, pos: Vector3, yaw: float, colors: Array, size := Vector3(0.3, 0.26, 0.24)) -> void:
	_box(k, "walnut", pos, yaw, Vector3(0, 0.02, 0), Vector3(size.x + 0.12, 0.04, size.z + 0.12), Color.WHITE)
	_box(k, "facade", pos, yaw, Vector3(0, 0.04 + size.y / 2.0, 0), size, Color(colors[0]))
	_box(k, "facade", pos, yaw, Vector3(size.x * 0.2, 0.06 + size.y * 0.8, size.z * 0.3), size * Vector3(0.4, 0.3, 0.4), Color(colors[1]))

## A long lab bench along local X with a sink at one end (+Z front).
static func lab_bench(k, pos: Vector3, yaw: float, length := 3.0) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.45, 0), Vector3(length, 0.9, 0.75), Color("e3e6e8"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.915, 0), Vector3(length + 0.04, 0.03, 0.79), Color("2f3437"))
	_box(k, "metal", pos, yaw, Vector3(length / 2.0 - 0.4, 0.92, 0), Vector3(0.44, 0.02, 0.36), Color("aeb5ba"))
	_box(k, "metal", pos, yaw, Vector3(length / 2.0 - 0.4, 1.1, -0.28), Vector3(0.03, 0.36, 0.03), METAL)
	_solid(k, pos, yaw, Vector3(0, 0.46, 0), Vector3(length, 0.92, 0.75))

# --- The Community Center ----------------------------------------------------------------------

## A serving line along local X: a steam table with food pans under a
## sneeze guard; servers stand on −Z, guests pass on +Z along a tray rail.
static func serving_line(k, pos: Vector3, yaw: float, length := 4.8) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.45, 0), Vector3(length, 0.9, 0.8), Color("c9ced2"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.91, 0), Vector3(length, 0.02, 0.8), Color("aeb5ba"))
	var foods := [Color("c8873a"), Color("e8d9a8"), Color("5f8f3c"), Color("b8452d"), Color("e9d7b0"), Color("7a5a3a"), Color("d9a441"), Color("8fa65a")]
	var pans := int(length / 0.6)
	for index in range(pans):
		var x := -length / 2.0 + 0.35 + index * (length - 0.7) / maxf(1.0, pans - 1.0)
		_box(k, "metal", pos, yaw, Vector3(x, 0.93, -0.05), Vector3(0.5, 0.03, 0.34), Color("d8dcdf"))
		_box(k, "facade", pos, yaw, Vector3(x, 0.945, -0.05), Vector3(0.44, 0.02, 0.28), foods[index % foods.size()])
	_box(k, "clear", pos, yaw, Vector3(0, 1.28, 0.12), Vector3(length, 0.03, 0.46), Color(0.86, 0.93, 0.96, 0.35))
	for x in [-length / 2.0 + 0.05, length / 2.0 - 0.05]:
		_box(k, "metal", pos, yaw, Vector3(x, 1.1, 0.12), Vector3(0.03, 0.36, 0.03), METAL)
	_box(k, "metal", pos, yaw, Vector3(0, 0.84, 0.52), Vector3(length, 0.03, 0.3), METAL)
	_solid(k, pos, yaw, Vector3(0, 0.46, 0.08), Vector3(length, 0.92, 0.96))

## A folding banquet table along local X with folding chairs on both sides;
## returns [seat point, yaw] pairs (seat fronts facing the table).
static func banquet_table(k, pos: Vector3, yaw: float, length := 2.4, per_side := 3, cloth := Color("f4f4f1")) -> Array:
	_box(k, "facade", pos, yaw, Vector3(0, 0.72, 0), Vector3(length, 0.04, 0.76), cloth)
	for x in [-length / 2.0 + 0.2, length / 2.0 - 0.2]:
		_box(k, "metal", pos, yaw, Vector3(x, 0.36, 0), Vector3(0.04, 0.72, 0.6), DARK)
	_solid(k, pos, yaw, Vector3(0, 0.37, 0), Vector3(length, 0.74, 0.76))
	var seats: Array = []
	for index in range(per_side):
		var x := -length / 2.0 + (index + 0.5) * length / per_side
		for side in [-1.0, 1.0]:
			var at := _at(pos, yaw, Vector3(x, 0, side * 0.72))
			# The chair's front faces the table.
			var chair_yaw := yaw + (PI if side > 0 else 0.0)
			cafe_chair(k, at, chair_yaw, Color("6d767c"))
			seats.append([at, chair_yaw])
	return seats

## Pantry shelving stocked with cans, jars and boxes, along local X.
static func pantry_shelf(k, pos: Vector3, yaw: float, width := 2.4) -> void:
	for x in [-width / 2.0 + 0.02, width / 2.0 - 0.02]:
		_box(k, "metal", pos, yaw, Vector3(x, 0.95, 0), Vector3(0.04, 1.9, 0.5), METAL)
	var stock := [Color("c2452d"), Color("e8b923"), Color("2f7a4a"), Color("c8873a"), Color("3d6fc4"), Color("e9e4da")]
	for level in range(4):
		var y := 0.2 + level * 0.46
		_box(k, "metal", pos, yaw, Vector3(0, y, 0), Vector3(width, 0.02, 0.5), METAL)
		var count := int(width / 0.14)
		for index in range(count):
			var tall := 0.12 + float((index * 3 + level) % 4) * 0.03
			_box(k, "facade", pos, yaw, Vector3(-width / 2.0 + 0.1 + index * 0.14, y + 0.01 + tall / 2.0, 0.04), Vector3(0.1, tall, 0.1 + float(index % 2) * 0.1), stock[(index + level * 2) % stock.size()])
	_solid(k, pos, yaw, Vector3(0, 0.95, 0), Vector3(width, 1.9, 0.5))

## A commercial range with a hood (first person) and pots, along local X.
static func range_hood(k, pos: Vector3, yaw: float, width := 2.0, ceiling := 3.2) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.45, 0), Vector3(width, 0.9, 0.8), Color("aeb5ba"))
	_box(k, "metal", pos, yaw, Vector3(0, 0.915, 0), Vector3(width, 0.03, 0.8), Color("2a2f33"))
	for index in range(3):
		var x := -width / 2.0 + 0.35 + index * (width - 0.7) / 2.0
		_box(k, "metal", pos, yaw, Vector3(x, 1.06, -0.05), Vector3(0.36, 0.26, 0.36), Color("c9ced2"))
	_box(k, "metal", pos, yaw, Vector3(0, ceiling - 0.5, -0.1), Vector3(width + 0.2, 0.5, 1.0), Color("c9ced2"), "fp")
	_solid(k, pos, yaw, Vector3(0, 0.46, 0), Vector3(width, 0.92, 0.8))

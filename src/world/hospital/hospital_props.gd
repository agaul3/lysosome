extends RefCounted
## Furniture and fittings shared by the hospital's lobby and inpatient unit,
## built into a HospitalKit (merged meshes, simple box colliders). Positions
## are zone-local; `yaw` turns an item so its front faces +Z rotated by yaw.
const WHITE := Color("f4f4f1")
const METAL := Color("c9ced2")
const DARK := Color("3a4045")
const UPHOLSTERY := Color("5f7d8c")
const SCREEN := Color("16202a")

static func _at(pos: Vector3, yaw: float, local: Vector3) -> Vector3:
	return pos + Basis(Vector3.UP, yaw) * local

static func _box(k, kind: String, pos: Vector3, yaw: float, local: Vector3, size: Vector3, color: Color, layer := "always") -> void:
	k.box(kind, _at(pos, yaw, local), size, color, layer, false, Basis(Vector3.UP, yaw))

## Upholstered lounge armchair on slim dark legs. Seats in this world are
## low (about 0.34 m) to suit the stylised figures, as in the lecture hall.
const ARMCHAIR_SEAT := 0.34
const SOFA_SEAT := 0.36
const OFFICE_SEAT := 0.38
static func armchair(k, pos: Vector3, yaw: float, color := UPHOLSTERY) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.26, 0), Vector3(0.74, 0.16, 0.7), color)
	_box(k, "facade", pos, yaw, Vector3(0, 0.58, -0.31), Vector3(0.74, 0.5, 0.12), color)
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.34, 0.44, 0.0), Vector3(0.07, 0.2, 0.62), DARK)
		for end in [-1, 1]:
			_box(k, "metal", pos, yaw, Vector3(side * 0.32, 0.09, end * 0.28), Vector3(0.04, 0.18, 0.04), DARK)
	k.solid(pos + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8))

## A curved lounge sofa: `count` segments on an arc of `radius` around `centre`, seats facing the centre.
static func curved_sofa(k, centre: Vector3, radius: float, from_angle: float, to_angle: float, count: int, color := Color("7e878c")) -> void:
	for index in range(count):
		var angle := lerpf(from_angle, to_angle, (index + 0.5) / count)
		var dir := Vector3(sin(angle), 0, cos(angle))
		var pos := centre + dir * radius
		var yaw := atan2(dir.x, dir.z) + PI
		var width := radius * absf(to_angle - from_angle) / count + 0.04
		_box(k, "facade", pos, yaw, Vector3(0, 0.18, 0), Vector3(width, 0.36, 0.72), color)
		_box(k, "facade", pos, yaw, Vector3(0, 0.56, -0.3), Vector3(width, 0.4, 0.14), color.darkened(0.08))
		k.solid(pos + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8))

static func round_table(k, pos: Vector3, radius := 0.35, height := 0.5) -> void:
	k.cylinder("facade", pos + Vector3(0, height - 0.03, 0), pos + Vector3(0, height, 0), radius, WHITE, "always", 20)
	k.cylinder("metal", pos, pos + Vector3(0, height - 0.03, 0), 0.03, METAL)
	k.cylinder("metal", pos, pos + Vector3(0, 0.02, 0), radius * 0.55, METAL, "always", 14)
	k.solid(pos + Vector3(0, height / 2.0, 0), Vector3(radius * 1.6, height, radius * 1.6))

## A black planter box; returns the point where a tree or shrub stands.
static func planter(k, pos: Vector3, size := Vector3(1.4, 0.7, 1.4)) -> Vector3:
	k.box("facade", pos + Vector3(0, size.y / 2.0, 0), size, Color("2b2f33"), "always", true)
	k.box("facade", pos + Vector3(0, size.y + 0.01, 0), Vector3(size.x - 0.12, 0.02, size.z - 0.12), Color("4a3b2e"))
	return pos + Vector3(0, size.y, 0)

## A flat monitor on a stand; the screen faces +Z rotated by yaw.
static func monitor(k, pos: Vector3, yaw: float, width := 0.52, screen := SCREEN) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.012, 0.02), Vector3(0.2, 0.02, 0.16), DARK)
	_box(k, "metal", pos, yaw, Vector3(0, 0.16, -0.02), Vector3(0.04, 0.28, 0.03), DARK)
	_box(k, "metal", pos, yaw, Vector3(0, 0.34, 0.0), Vector3(width, width * 0.6, 0.03), Color("20252a"))
	_box(k, "light", pos, yaw, Vector3(0, 0.34, 0.017), Vector3(width - 0.04, width * 0.6 - 0.04, 0.004), screen)
	_box(k, "facade", pos, yaw, Vector3(0, 0.01, 0.22), Vector3(0.42, 0.02, 0.14), Color("2a2f33"))

static func office_chair(k, pos: Vector3, yaw: float, color := Color("39464d")) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.34, 0), Vector3(0.48, 0.08, 0.46), color)
	_box(k, "facade", pos, yaw, Vector3(0, 0.68, -0.22), Vector3(0.44, 0.5, 0.06), color)
	k.cylinder("metal", pos + Vector3(0, 0.06, 0), pos + Vector3(0, 0.3, 0), 0.025, DARK)
	for angle in [0.4, 1.97, 3.54, 5.11]:
		_box(k, "metal", pos, yaw + angle, Vector3(0, 0.05, 0.16), Vector3(0.05, 0.04, 0.32), DARK)
	k.solid(pos + Vector3(0, 0.45, 0), Vector3(0.55, 0.9, 0.55))

## Where the raised head section hinges off the flat foot section (bed-local
## z from the headboard) and how steeply it is raised. A patient lies with
## the hips just past the hinge, the back on the raised section.
const BED_HINGE := 0.9
const BED_TILT := 0.8
const BED_TOP := 0.62

## An adjustable hospital bed. `pos` is the centre of the headboard end on the
## floor; the bed runs along +Z rotated by `yaw` (head at the headboard).
## Occupied beds get a blanket drawn up over the legs. Returns the mattress top.
static func bed(k, pos: Vector3, yaw: float, occupied := false) -> float:
	var top := BED_TOP
	_box(k, "metal", pos, yaw, Vector3(0, 0.22, 1.1), Vector3(0.96, 0.12, 2.1), Color("b8bfc4"))
	for end in [0.25, 1.95]:
		for side in [-1, 1]:
			_box(k, "metal", pos, yaw, Vector3(side * 0.4, 0.12, end), Vector3(0.06, 0.2, 0.06), DARK)
	# Flat foot section, then the head section rising from the hinge.
	_box(k, "facade", pos, yaw, Vector3(0, top - 0.08, (BED_HINGE + 2.1) / 2.0), Vector3(0.92, 0.16, 2.1 - BED_HINGE), Color("dfe6ea"))
	var length := 0.95
	var rise := Vector3(0, sin(BED_TILT), -cos(BED_TILT))
	var normal := Vector3(0, cos(BED_TILT), sin(BED_TILT))
	var hinge := Vector3(0, top, BED_HINGE)
	var tilt := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, BED_TILT)
	k.box("facade", _at(pos, yaw, hinge + rise * (length / 2.0) - normal * 0.07), Vector3(0.92, 0.14, length), Color("dfe6ea"), "always", false, tilt)
	k.box("facade", _at(pos, yaw, hinge + rise * (length - 0.18) + normal * 0.05), Vector3(0.62, 0.1, 0.3), WHITE, "always", false, tilt)
	_box(k, "facade", pos, yaw, Vector3(0, 0.55, 0.04), Vector3(1.0, 0.7, 0.06), Color("8a9aa3"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.4, 2.16), Vector3(1.0, 0.44, 0.05), Color("8a9aa3"))
	for side in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(side * 0.5, top + 0.12, 0.9), Vector3(0.03, 0.2, 0.9), METAL)
	if occupied:
		_box(k, "facade", pos, yaw, Vector3(0, top + 0.12, (BED_HINGE + 2.08) / 2.0 - 0.02), Vector3(0.96, 0.24, 2.08 - BED_HINGE + 0.04), Color("b9cbd6"))
	else:
		_box(k, "facade", pos, yaw, Vector3(0, top + 0.01, 1.5), Vector3(0.94, 0.04, 1.2), Color("b9cbd6"))
	k.solid(_at(pos, yaw, Vector3(0, 0.4, 1.1)), (Basis(Vector3.UP, yaw) * Vector3(1.05, 0.8, 2.2)).abs())
	return top

## Where a patient's hip joint rests in the bed (bed-local).
static func patient_hip() -> Vector3:
	return Vector3(0, BED_TOP + 0.1, BED_HINGE + 0.04)

## Wall-mounted hand-sanitizer dispenser; its face points +Z rotated by yaw.
static func dispenser(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0, 0.05), Vector3(0.14, 0.24, 0.1), WHITE)
	_box(k, "facade", pos, yaw, Vector3(0, -0.08, 0.1), Vector3(0.1, 0.05, 0.02), Color("5aa9d6"))
	_box(k, "facade", pos, yaw, Vector3(0, -0.14, 0.08), Vector3(0.04, 0.03, 0.06), DARK)

## Brushed-steel elevator doors in a dark frame, in a wall facing +Z rotated by
## yaw. `pos` is the door centre on the wall face at floor level. The leaves
## themselves are separate nodes when the car is used (see sliding_doors.gd).
static func elevator_frame(k, pos: Vector3, yaw: float, width := 1.3, with_leaves := true, layer := "always") -> void:
	for side in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(side * (width / 2.0 + 0.06), 1.2, 0.04), Vector3(0.12, 2.4, 0.08), DARK, layer)
	_box(k, "metal", pos, yaw, Vector3(0, 2.45, 0.04), Vector3(width + 0.24, 0.12, 0.08), DARK, layer)
	if with_leaves:
		for side in [-1, 1]:
			_box(k, "metal", pos, yaw, Vector3(side * width / 4.0, 1.18, -0.02), Vector3(width / 2.0 - 0.01, 2.36, 0.04), METAL, layer)
	# Indicator screen and call buttons.
	_box(k, "facade", pos, yaw, Vector3(0, 2.72, 0.02), Vector3(0.36, 0.16, 0.03), SCREEN, layer)
	_box(k, "facade", pos, yaw, Vector3(width / 2.0 + 0.32, 1.12, 0.02), Vector3(0.1, 0.22, 0.03), METAL, layer)
	_box(k, "light", pos, yaw, Vector3(width / 2.0 + 0.32, 1.17, 0.036), Vector3(0.04, 0.04, 0.005), Color("f6d98a"), layer)
	_box(k, "light", pos, yaw, Vector3(width / 2.0 + 0.32, 1.07, 0.036), Vector3(0.04, 0.04, 0.005), Color("dfe6ea"), layer)

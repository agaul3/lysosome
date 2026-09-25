extends RefCounted
## Furniture, fittings and medical equipment shared by the hospital's floors,
## built into a HospitalKit (merged meshes, simple box colliders). Positions
## are zone-local; `yaw` turns an item so its front faces +Z rotated by yaw.
## Moving things (a stretcher an EMS crew pushes, the CT table) are built the
## same way into a NodeKit and committed under their own node.
const MeshKit = preload("res://world/campus/mesh_kit.gd")

## HospitalKit's drawing calls over a plain MeshKit, for props built as their
## own moving node. Layers are ignored (a moving prop is always whole) and
## there are no static colliders (movers carry their own blockers).
class NodeKit:
	var kit := MeshKit.new()
	var offset := Vector3.ZERO

	func box(kind: String, center: Vector3, size: Vector3, color: Color, _layer := "always", _solid := false, basis := Basis.IDENTITY) -> void:
		kit.box(kind, center, size, color, basis)

	func solid(_center: Vector3, _size: Vector3) -> void:
		pass

	func cylinder(kind: String, a: Vector3, b: Vector3, radius: float, color: Color, _layer := "always", segments := 12) -> void:
		kit.cylinder(kind, a, b, radius, color, segments)

	func commit(parent: Node3D, label: String) -> MeshInstance3D:
		return kit.commit(parent, label)
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

## Poses a figure lying on its back with the torso raised `tilt` radians
## from horizontal (0 = flat). The figure's origin is the hip pivot; `look` is
## its Appearance, lowered so the hip joint sits on the pivot.
static func lay(figure: Node3D, look: Node3D, tilt: float, yaw: float) -> void:
	figure.rotation = Vector3(PI / 2.0 - tilt, yaw, 0)
	look.position.y = -look.HIP_HEIGHT * look.height_scale
	for index in range(2):
		look.hips[index].rotation.x = tilt
		look.knees[index].rotation.x = 0.0
		look.shoulders[index].rotation = Vector3(0.25, 0, 0.12 * (1 if index else -1))

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
		# A car that isn't in service: its closed doors are solid.
		k.solid(_at(pos, yaw, Vector3(0, 1.18, -0.02)), (Basis(Vector3.UP, yaw) * Vector3(width, 2.36, 0.12)).abs())
	# Indicator screen and call buttons.
	_box(k, "facade", pos, yaw, Vector3(0, 2.72, 0.02), Vector3(0.36, 0.16, 0.03), SCREEN, layer)
	_box(k, "facade", pos, yaw, Vector3(width / 2.0 + 0.32, 1.12, 0.02), Vector3(0.1, 0.22, 0.03), METAL, layer)
	_box(k, "light", pos, yaw, Vector3(width / 2.0 + 0.32, 1.17, 0.036), Vector3(0.04, 0.04, 0.005), Color("f6d98a"), layer)
	_box(k, "light", pos, yaw, Vector3(width / 2.0 + 0.32, 1.07, 0.036), Vector3(0.04, 0.04, 0.005), Color("dfe6ea"), layer)

# --- Emergency Department and radiology equipment ------------------------------------------

## Where the head section of a stretcher hinges (stretcher-local z; the head is at −Z).
const STRETCHER_HINGE := -0.2

## A wheeled stretcher (ED stretcher or EMS cot). Local +Z is the foot end,
## which leads when it is pushed; the push handle is at the head end.
## Returns the hip pivot for a patient lying on it (stretcher-local; lay the
## figure with yaw PI and this tilt).
static func stretcher(k, pos: Vector3, yaw: float, frame := Color("c9ced2"), pad := Color("35557a"), height := 0.74, tilt := 0.5, occupied := false, layer := "always") -> Vector3:
	_box(k, "metal", pos, yaw, Vector3(0, 0.17, 0), Vector3(0.56, 0.08, 1.5), DARK, layer)
	for end in [-0.66, 0.66]:
		for side in [-1, 1]:
			_box(k, "metal", pos, yaw, Vector3(side * 0.24, 0.07, end), Vector3(0.07, 0.14, 0.12), Color("222629"), layer)
	_box(k, "metal", pos, yaw, Vector3(0, (0.21 + height - 0.12) / 2.0, 0), Vector3(0.16, height - 0.33, 0.34), frame, layer)
	_box(k, "metal", pos, yaw, Vector3(0, height - 0.1, 0), Vector3(0.64, 0.05, 1.98), frame, layer)
	# Mattress: flat under the legs, the head section raised from the hinge.
	_box(k, "facade", pos, yaw, Vector3(0, height - 0.02, (STRETCHER_HINGE + 0.99) / 2.0), Vector3(0.6, 0.12, 0.99 - STRETCHER_HINGE), pad, layer)
	var length := 0.76
	var rise := Vector3(0, sin(tilt), -cos(tilt))
	var normal := Vector3(0, cos(tilt), sin(tilt))
	var hinge := Vector3(0, height + 0.04, STRETCHER_HINGE)
	var raised := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt)
	k.box("facade", _at(pos, yaw, hinge + rise * (length / 2.0) - normal * 0.06), Vector3(0.6, 0.12, length), pad, layer, false, raised)
	k.box("facade", _at(pos, yaw, hinge + rise * (length - 0.16) + normal * 0.04), Vector3(0.44, 0.08, 0.26), WHITE, layer, false, raised)
	for side in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(side * 0.34, height + 0.07, 0.25), Vector3(0.03, 0.12, 0.95), frame, layer)
	# Push handle at the head end.
	_box(k, "metal", pos, yaw, Vector3(0, height + 0.3, -1.04), Vector3(0.56, 0.04, 0.04), frame.darkened(0.25), layer)
	for side in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(side * 0.28, height + 0.13, -1.02), Vector3(0.04, 0.34, 0.04), frame.darkened(0.25), layer)
	if occupied:
		_box(k, "facade", pos, yaw, Vector3(0, height + 0.12, (STRETCHER_HINGE + 0.97) / 2.0), Vector3(0.64, 0.22, 0.97 - STRETCHER_HINGE + 0.02), Color("d9e2e7"), layer)
	else:
		_box(k, "facade", pos, yaw, Vector3(0, height + 0.05, 0.62), Vector3(0.6, 0.03, 0.5), Color("eef1f2"), layer)
	return Vector3(0, height + 0.1, STRETCHER_HINGE + 0.04)

## A treatment recliner (Super Track), seat top 0.36 m.
## A treatment recliner, upright with its leg rest folded away. The cushion
## ends where a seated figure's knees bend, so the shins hang clear of it.
static func recliner(k, pos: Vector3, yaw: float, color := Color("4f6f86")) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.08, -0.06), Vector3(0.5, 0.16, 0.38), DARK)
	_box(k, "facade", pos, yaw, Vector3(0, 0.26, -0.03), Vector3(0.66, 0.2, 0.54), color)
	k.box("facade", _at(pos, yaw, Vector3(0, 0.72, -0.36)), Vector3(0.66, 0.84, 0.14), color, "always", false, Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -0.22))
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.37, 0.46, -0.04), Vector3(0.08, 0.16, 0.52), color.darkened(0.2))
	k.solid(pos + Vector3(0, 0.45, 0), Vector3(0.8, 0.9, 0.8))

## A row of linked waiting-room seats (seat top 0.36 m) centred on `pos`.
static func seat_row(k, pos: Vector3, yaw: float, count: int, color := Color("41596a")) -> Array:
	var seats: Array = []
	var pitch := 0.62
	for index in range(count):
		var x := (index - (count - 1) / 2.0) * pitch
		_box(k, "facade", pos, yaw, Vector3(x, 0.32, 0.02), Vector3(0.52, 0.08, 0.48), color)
		_box(k, "facade", pos, yaw, Vector3(x, 0.62, -0.22), Vector3(0.52, 0.48, 0.06), color)
		seats.append(_at(pos, yaw, Vector3(x, 0, 0)))
	_box(k, "metal", pos, yaw, Vector3(0, 0.22, -0.05), Vector3(count * pitch, 0.06, 0.08), DARK)
	for end in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(end * (count * pitch / 2.0 - 0.1), 0.11, 0), Vector3(0.06, 0.22, 0.44), DARK)
	k.solid(_at(pos, yaw, Vector3(0, 0.4, -0.02)), (Basis(Vector3.UP, yaw) * Vector3(count * pitch, 0.8, 0.62)).abs())
	return seats

## A wheelchair; its seat top is 0.46 m. Local +Z is forward.
static func wheelchair(k, pos: Vector3, yaw: float, frame := Color("3c4247")) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.44, 0.02), Vector3(0.44, 0.05, 0.42), Color("22272b"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.72, -0.2), Vector3(0.42, 0.44, 0.04), Color("22272b"))
	for side in [-1, 1]:
		k.cylinder("metal", _at(pos, yaw, Vector3(side * 0.27, 0.3, -0.08)), _at(pos, yaw, Vector3(side * 0.3, 0.3, -0.08)), 0.3, Color("2a2e31"), "always", 16)
		k.cylinder("metal", _at(pos, yaw, Vector3(side * 0.26, 0.3, -0.08)), _at(pos, yaw, Vector3(side * 0.31, 0.3, -0.08)), 0.06, frame.lightened(0.3), "always", 8)
		_box(k, "metal", pos, yaw, Vector3(side * 0.2, 0.06, 0.3), Vector3(0.04, 0.1, 0.08), Color("222629"))
		_box(k, "metal", pos, yaw, Vector3(side * 0.22, 0.62, -0.24), Vector3(0.03, 0.62, 0.03), frame)
		_box(k, "metal", pos, yaw, Vector3(side * 0.22, 0.94, -0.3), Vector3(0.03, 0.03, 0.14), frame)
		_box(k, "metal", pos, yaw, Vector3(side * 0.1, 0.1, 0.4), Vector3(0.14, 0.02, 0.1), frame)
	_box(k, "metal", pos, yaw, Vector3(0, 0.36, 0.02), Vector3(0.46, 0.04, 0.44), frame)

## Red crash cart with drawers and a defibrillator on top.
static func crash_cart(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.52, 0), Vector3(0.64, 0.96, 0.5), Color("b3342f"))
	for row in range(5):
		_box(k, "facade", pos, yaw, Vector3(0, 0.2 + row * 0.17, 0.252), Vector3(0.58, 0.012, 0.01), Color("7e211d"))
	_box(k, "facade", pos, yaw, Vector3(0, 1.08, 0.02), Vector3(0.44, 0.16, 0.34), Color("2f3437"))
	_box(k, "light", pos, yaw, Vector3(0, 1.1, 0.19), Vector3(0.18, 0.1, 0.01), Color("3fd28a"))
	for end in [-1, 1]:
		_box(k, "metal", pos, yaw, Vector3(end * 0.24, 0.05, end * 0.18), Vector3(0.06, 0.1, 0.06), Color("222629"))
	k.solid(pos + Vector3(0, 0.55, 0), Vector3(0.7, 1.1, 0.6))

## Automated medication dispensing cabinet: drawer tower with a touchscreen.
static func dispensing_cabinet(k, pos: Vector3, yaw: float) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.95, 0), Vector3(0.8, 1.9, 0.62), Color("cfd4d8"))
	for row in range(8):
		_box(k, "facade", pos, yaw, Vector3(0, 0.2 + row * 0.13, 0.312), Vector3(0.72, 0.1, 0.01), Color("b8bfc4") if row % 2 else Color("c3c9cd"))
	_box(k, "facade", pos, yaw, Vector3(0, 1.42, 0.315), Vector3(0.5, 0.34, 0.02), Color("20252a"))
	_box(k, "light", pos, yaw, Vector3(0, 1.42, 0.327), Vector3(0.44, 0.28, 0.005), Color("7fb8d6"))
	_box(k, "facade", pos, yaw, Vector3(0, 1.18, 0.38), Vector3(0.5, 0.03, 0.14), Color("2a2f33"))
	_box(k, "light", pos, yaw, Vector3(0.3, 1.72, 0.315), Vector3(0.06, 0.06, 0.01), Color("3fd28a"))
	k.solid(pos + Vector3(0, 0.95, 0), Vector3(0.84, 1.9, 0.66))

## Medication refrigerator with a glass door.
static func med_fridge(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.9, 0), Vector3(0.7, 1.8, 0.64), WHITE)
	_box(k, "tinted", pos, yaw, Vector3(0, 0.95, 0.325), Vector3(0.6, 1.5, 0.02), Color("cfe0e6"))
	for row in range(4):
		for item in range(4):
			_box(k, "facade", pos, yaw, Vector3(-0.2 + item * 0.13, 0.42 + row * 0.34, 0.2), Vector3(0.1, 0.14, 0.16), [Color("f2f2f0"), Color("7fb8d6"), Color("f2c46d"), Color("e8708a")][(row + item) % 4])
	k.solid(pos + Vector3(0, 0.9, 0), Vector3(0.74, 1.8, 0.68))

## Wire supply shelving with coloured bins.
static func shelving(k, pos: Vector3, yaw: float, width := 1.8, levels := 5) -> void:
	for x in [-width / 2.0 + 0.02, width / 2.0 - 0.02]:
		for z in [-0.22, 0.22]:
			_box(k, "metal", pos, yaw, Vector3(x, 0.95, z), Vector3(0.03, 1.9, 0.03), METAL)
	var palette := [Color("5aa9d6"), Color("e8e8e2"), Color("7fd6a0"), Color("f2c46d"), Color("e8708a")]
	for level in range(levels):
		var y := 0.18 + level * 0.4
		_box(k, "metal", pos, yaw, Vector3(0, y, 0), Vector3(width, 0.02, 0.46), METAL)
		var count := int(width / 0.36)
		for index in range(count):
			_box(k, "facade", pos, yaw, Vector3(-width / 2.0 + 0.2 + index * 0.36, y + 0.09, 0.02), Vector3(0.3, 0.16, 0.4), palette[(index + level) % palette.size()])
	k.solid(pos + Vector3(0, 0.95, 0), (Basis(Vector3.UP, yaw) * Vector3(width, 1.9, 0.5)).abs())

## Ceiling-mounted surgical light over a trauma stretcher (first person only).
static func surgical_light(k, pos: Vector3, ceiling: float) -> void:
	k.cylinder("metal", pos + Vector3(0, ceiling, 0), pos + Vector3(0, ceiling - 0.5, 0), 0.06, WHITE, "fp")
	k.box("metal", pos + Vector3(0.3, ceiling - 0.52, 0), Vector3(0.7, 0.07, 0.07), WHITE, "fp")
	k.cylinder("metal", pos + Vector3(0.6, ceiling - 0.52, 0), pos + Vector3(0.6, 2.3, 0), 0.04, WHITE, "fp")
	k.cylinder("facade", pos + Vector3(0.6, 2.3, 0), pos + Vector3(0.6, 2.18, 0), 0.36, Color("eef1f2"), "fp", 18)
	k.cylinder("light", pos + Vector3(0.6, 2.179, 0), pos + Vector3(0.6, 2.17, 0), 0.26, Color("fffbea"), "fp", 18)

## Ceiling boom with gas outlets and a monitor arm (first person only).
static func boom(k, pos: Vector3, ceiling: float) -> void:
	k.box("metal", pos + Vector3(0, ceiling - 0.45, 0), Vector3(0.28, 0.9, 0.28), Color("dfe3e6"), "fp")
	k.box("metal", pos + Vector3(0, 1.75, 0), Vector3(0.34, 0.9, 0.34), Color("dfe3e6"), "fp")
	for index in range(3):
		k.box("facade", pos + Vector3(0.175, 1.55 + index * 0.18, 0), Vector3(0.01, 0.07, 0.07), [Color("2e7d4f"), Color("f2f2f0"), Color("f2c230")][index], "fp")
	k.cylinder("metal", pos + Vector3(0, ceiling - 0.9, 0), pos + Vector3(0, 2.2, 0), 0.05, Color("dfe3e6"), "fp")

## Vitals monitor on a rolling stand.
static func vitals_stand(k, pos: Vector3, yaw: float) -> void:
	for angle in [0.3, 1.55, 2.8, 4.05, 5.3]:
		_box(k, "metal", pos, yaw + angle, Vector3(0, 0.05, 0.14), Vector3(0.04, 0.03, 0.28), DARK)
	k.cylinder("metal", pos + Vector3(0, 0.05, 0), pos + Vector3(0, 1.05, 0), 0.02, METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 1.18, 0), Vector3(0.3, 0.24, 0.14), Color("dfe3e6"))
	_box(k, "light", pos, yaw, Vector3(0, 1.19, 0.071), Vector3(0.22, 0.14, 0.005), Color("0b2a22"))

## Workstation on wheels (a laptop cart); its screen faces +Z rotated by yaw.
static func wow(k, pos: Vector3, yaw: float) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 0.05, 0), Vector3(0.5, 0.06, 0.46), DARK)
	k.cylinder("metal", pos + Vector3(0, 0.08, 0), pos + Vector3(0, 0.95, 0), 0.035, METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 0.98, 0.02), Vector3(0.56, 0.04, 0.42), Color("dfe3e6"))
	_box(k, "metal", pos, yaw, Vector3(0, 1.22, -0.12), Vector3(0.42, 0.28, 0.03), Color("20252a"))
	_box(k, "light", pos, yaw, Vector3(0, 1.22, -0.104), Vector3(0.38, 0.24, 0.004), Color("24424a"))
	k.solid(pos + Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.46))

static func iv_pole(k, pos: Vector3) -> void:
	for angle in [0.0, 1.26, 2.51, 3.77, 5.03]:
		_box(k, "metal", pos, angle, Vector3(0, 0.04, 0.13), Vector3(0.03, 0.03, 0.26), DARK)
	k.cylinder("metal", pos + Vector3(0, 0.04, 0), pos + Vector3(0, 1.95, 0), 0.015, Color("c9ced2"))
	k.box("tinted", pos + Vector3(0.08, 1.72, 0), Vector3(0.12, 0.2, 0.04), Color("e6f0f2"))
	k.box("facade", pos + Vector3(0, 1.1, 0.06), Vector3(0.16, 0.2, 0.12), Color("dfe6ea"))

## Walk-through metal detector at a screening point; people walk along ±Z through it.
## A walk-through metal detector, wide enough for the figures' arm span.
static func metal_detector(k, pos: Vector3, yaw: float) -> void:
	for side in [-1, 1]:
		_box(k, "facade", pos, yaw, Vector3(side * 0.55, 1.05, 0), Vector3(0.14, 2.1, 0.62), Color("8b949a"))
		_box(k, "light", pos, yaw, Vector3(side * 0.55, 1.9, 0.312), Vector3(0.06, 0.12, 0.005), Color("3fd28a"))
		k.solid(_at(pos, yaw, Vector3(side * 0.55, 1.05, 0)), (Basis(Vector3.UP, yaw) * Vector3(0.14, 2.1, 0.62)).abs())
	_box(k, "facade", pos, yaw, Vector3(0, 2.16, 0), Vector3(1.24, 0.14, 0.64), Color("6d767c"))

## A drinks/snacks vending machine.
static func vending(k, pos: Vector3, yaw: float, snacks := false) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.95, 0), Vector3(0.9, 1.9, 0.78), Color("2d4d63") if snacks else Color("b3342f"))
	_box(k, "light", pos, yaw, Vector3(-0.1, 1.08, 0.392), Vector3(0.6, 1.3, 0.005), Color("d7ebf3"))
	for row in range(5):
		for item in range(4):
			_box(k, "facade", pos, yaw, Vector3(-0.32 + item * 0.15, 0.6 + row * 0.24, 0.35), Vector3(0.1, 0.14, 0.05), [Color("e8708a"), Color("5aa9d6"), Color("f2c46d"), Color("7fd6a0")][(row + item) % 4])
	_box(k, "facade", pos, yaw, Vector3(0.33, 1.2, 0.395), Vector3(0.14, 0.4, 0.01), Color("20252a"))
	k.solid(pos + Vector3(0, 0.95, 0), (Basis(Vector3.UP, yaw) * Vector3(0.92, 1.9, 0.8)).abs())

static func bollard(k, pos: Vector3, color := Color("e0b93a")) -> void:
	k.cylinder("facade", pos, pos + Vector3(0, 1.0, 0), 0.11, color, "always", 12)
	k.cylinder("facade", pos + Vector3(0, 1.0, 0), pos + Vector3(0, 1.04, 0), 0.08, color.darkened(0.2), "always", 12)
	k.solid(pos + Vector3(0, 0.5, 0), Vector3(0.24, 1.0, 0.24))

## CT scanner gantry (a ring with a dark bore) facing +Z rotated by yaw, the
## patient table sliding out toward +Z. `pos` is the gantry centre on the floor.
static func ct_gantry(k, pos: Vector3, yaw: float) -> void:
	var axis := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	var centre := pos + Vector3(0, 1.1, 0)
	k.cylinder("facade", centre - axis * 0.42, centre + axis * 0.42, 1.0, Color("eef0f0"), "always", 28)
	k.cylinder("facade", centre + axis * 0.42, centre + axis * 0.46, 0.94, Color("d9dfe2"), "always", 28)
	k.cylinder("facade", centre - axis * 0.47, centre + axis * 0.47, 0.37, Color("30383d"), "always", 24)
	k.cylinder("light", centre + axis * 0.465, centre + axis * 0.47, 0.44, Color("5ec8b5"), "always", 24)
	_box(k, "facade", pos, yaw, Vector3(0, 0.22, 0), Vector3(1.6, 0.44, 0.84), Color("dfe3e6"))
	k.solid(pos + Vector3(0, 1.0, 0), (Basis(Vector3.UP, yaw) * Vector3(2.1, 2.1, 0.9)).abs())

## Table pedestal in front of a CT or MRI bore (the sliding top is its own node).
static func scanner_table_base(k, pos: Vector3, yaw: float, length := 1.6) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.45, length / 2.0 + 0.5), Vector3(0.5, 0.9, length), Color("dfe3e6"))
	k.solid(_at(pos, yaw, Vector3(0, 0.45, length / 2.0 + 0.5)), (Basis(Vector3.UP, yaw) * Vector3(0.6, 0.9, length)).abs())

## MRI magnet: a big rounded housing with a deep bore, facing +Z rotated by yaw.
static func mri_magnet(k, pos: Vector3, yaw: float) -> void:
	var axis := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	var centre := pos + Vector3(0, 1.15, 0)
	_box(k, "facade", pos, yaw, Vector3(0, 1.05, -0.2), Vector3(2.1, 2.1, 1.6), Color("eef0f0"))
	k.cylinder("facade", centre + axis * 0.6, centre + axis * 0.72, 1.06, Color("e3e8ea"), "always", 32)
	k.cylinder("facade", centre - axis * 1.02, centre + axis * 0.73, 0.34, Color("2a3136"), "always", 24)
	k.cylinder("light", centre + axis * 0.72, centre + axis * 0.73, 0.42, Color("8fb5e8"), "always", 24)
	k.solid(pos + Vector3(0, 1.05, 0) - axis * 0.2, (Basis(Vector3.UP, yaw) * Vector3(2.2, 2.2, 1.8)).abs())

## Radiography room: a floor-mounted tube column over the table and a wall detector stand.
static func xray(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.38, 0), Vector3(0.8, 0.76, 2.1), Color("dfe3e6"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.78, 0), Vector3(0.84, 0.06, 2.2), Color("eef0f0"))
	_box(k, "metal", pos, yaw, Vector3(-0.9, 1.05, 0), Vector3(0.14, 2.1, 0.14), METAL)
	_box(k, "metal", pos, yaw, Vector3(-0.5, 1.9, 0), Vector3(0.8, 0.1, 0.12), METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 1.72, 0), Vector3(0.36, 0.3, 0.4), Color("dfe3e6"))
	_box(k, "facade", pos, yaw, Vector3(0, 1.55, 0), Vector3(0.3, 0.06, 0.3), Color("30383d"))
	k.solid(pos + Vector3(0, 0.4, 0), (Basis(Vector3.UP, yaw) * Vector3(0.9, 0.8, 2.2)).abs())

## Upright detector stand for chest X-rays, against a wall facing +Z.
static func bucky_stand(k, pos: Vector3, yaw: float) -> void:
	_box(k, "metal", pos, yaw, Vector3(0, 1.0, -0.05), Vector3(0.14, 2.0, 0.1), METAL)
	_box(k, "facade", pos, yaw, Vector3(0, 1.3, 0.06), Vector3(0.5, 0.56, 0.1), Color("eef0f0"))
	_box(k, "facade", pos, yaw, Vector3(0, 1.3, 0.115), Vector3(0.4, 0.44, 0.005), Color("c3c9cd"))

## Ultrasound machine on its cart; the screen faces +Z rotated by yaw.
static func ultrasound(k, pos: Vector3, yaw: float) -> void:
	_box(k, "facade", pos, yaw, Vector3(0, 0.42, 0), Vector3(0.5, 0.84, 0.56), Color("e3e8ea"))
	_box(k, "facade", pos, yaw, Vector3(0, 0.9, 0.12), Vector3(0.52, 0.06, 0.36), Color("2f3437"))
	_box(k, "metal", pos, yaw, Vector3(0, 1.28, -0.12), Vector3(0.42, 0.3, 0.04), Color("20252a"))
	_box(k, "light", pos, yaw, Vector3(0, 1.28, -0.098), Vector3(0.38, 0.26, 0.004), Color("26282a"))
	k.solid(pos + Vector3(0, 0.5, 0), Vector3(0.56, 1.0, 0.6))

## An elevator car behind a door whose opening is centred on `door` (the wall's
## centre line, at floor level); the car extends back along the door frame's −Z.
## `cut`: behind a cutaway wall, so the car's walls are cut for the overhead view too.
static func elevator_cab(k, door: Vector3, yaw: float, cut := false) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var place := func(local: Vector3) -> Vector3: return door + basis * local
	var metal := Color("aeb5ba")
	k.box("paving", place.call(Vector3(0, 0.0, -1.2)), (basis * Vector3(2.2, 0.02, 2.4)).abs(), Color("6e757a"))
	var walls := [[Vector3(0, 1.3, -2.45), Vector3(2.3, 2.6, 0.1)], [Vector3(-1.12, 1.3, -1.25), Vector3(0.1, 2.6, 2.4)], [Vector3(1.12, 1.3, -1.25), Vector3(0.1, 2.6, 2.4)]]
	for wall in walls:
		var size: Vector3 = (basis * wall[1]).abs()
		k.solid(place.call(wall[0]), size)
		if cut:
			k.box("metal", place.call(wall[0]), size, metal, "fp")
			k.box("metal", place.call(Vector3(wall[0].x, 0.525, wall[0].z)), Vector3(size.x, 1.05, size.z), metal, "tp")
		else:
			k.box("metal", place.call(wall[0]), size, metal)
	k.box("facade", place.call(Vector3(0, 2.62, -1.25)), (basis * Vector3(2.3, 0.1, 2.4)).abs(), Color("d9dcde"), "fp")
	k.box("light", place.call(Vector3(0, 2.56, -1.25)), (basis * Vector3(1.4, 0.02, 1.2)).abs(), Color("fffaf0"), "fp")
	k.box("metal", place.call(Vector3(-0.95, 1.2, -0.3)), (basis * Vector3(0.05, 0.5, 0.2)).abs(), Color("2a2f33"))
	k.box("metal", place.call(Vector3(0, 0.95, -2.38)), (basis * Vector3(2.0, 0.05, 0.05)).abs(), Color("d9dcde"))

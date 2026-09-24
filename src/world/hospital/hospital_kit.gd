extends RefCounted
## Builds hospital interiors for both camera modes at once.
##
## Geometry goes into one of three merged layers (MeshKit):
##   always — floors, furniture, anything low, and walls that never block the
##            overhead camera (the far north and west walls);
##   fp     — the first-person-only parts: full-height versions of cutaway
##            walls, ceilings, ceiling lights and anything mounted high on them;
##   tp     — the overhead camera's cutaway: the same walls cut to waist height
##            so the floor behind them stays visible.
## Colliders always use the full wall, so both views walk the same building.
## The hospital scene shows `fp` or `tp` to match AppState.first_person.
const MeshKit = preload("res://world/campus/mesh_kit.gd")
const THICKNESS := 0.16
## Height walls are cut to for the overhead camera.
const CUT := 1.05
var layers := {"always": MeshKit.new(), "fp": MeshKit.new(), "tp": MeshKit.new()}
var offset := Vector3.ZERO

func _init(origin := Vector3.ZERO) -> void:
	offset = origin

func kit(layer := "always") -> MeshKit:
	return layers[layer]

func box(kind: String, center: Vector3, size: Vector3, color: Color, layer := "always", solid := false, basis := Basis.IDENTITY) -> void:
	layers[layer].box(kind, offset + center, size, color, basis)
	if solid:
		layers.always.solid(offset + center, size, basis)

func solid(center: Vector3, size: Vector3) -> void:
	layers.always.solid(offset + center, size)

func cylinder(kind: String, a: Vector3, b: Vector3, radius: float, color: Color, layer := "always", segments := 12) -> void:
	layers[layer].cylinder(kind, offset + a, offset + b, radius, color, segments)

## A wall along x at `z` from x0 to x1 (or along z at `x` when `along_z`).
## `openings`: [[centre, width, top]] measured along the wall; doorways leave
## a lintel above `top`. `cut` true builds it as a cutaway wall.
func wall(along_z: bool, at: float, from: float, to: float, height: float, color: Color, cut := true, openings: Array = [], thickness := THICKNESS, kind := "facade", collide := true) -> void:
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var cursor := from
	for opening in sorted:
		var start: float = opening[0] - opening[1] / 2.0
		var end: float = opening[0] + opening[1] / 2.0
		_segment(along_z, at, cursor, start, 0.0, height, color, cut, thickness, collide, kind)
		_segment(along_z, at, start, end, opening[2], height, color, cut, thickness, false, kind)
		cursor = end
	_segment(along_z, at, cursor, to, 0.0, height, color, cut, thickness, collide, kind)

func _segment(along_z: bool, at: float, a: float, b: float, bottom: float, top: float, color: Color, cut: bool, thickness: float, collide: bool, kind: String) -> void:
	if b - a < 0.005 or top - bottom < 0.005:
		return
	var length := b - a
	var mid := (a + b) / 2.0
	var center := Vector3(at, (bottom + top) / 2.0, mid) if along_z else Vector3(mid, (bottom + top) / 2.0, at)
	var size := Vector3(thickness, top - bottom, length) if along_z else Vector3(length, top - bottom, thickness)
	if collide:
		layers.always.solid(offset + center, size)
	if not cut:
		layers.always.box(kind, offset + center, size, color)
		return
	layers.fp.box(kind, offset + center, size, color)
	if bottom < CUT:
		var low := minf(top, CUT)
		var low_center := Vector3(center.x, (bottom + low) / 2.0, center.z)
		var low_size := Vector3(size.x, low - bottom, size.z)
		layers.tp.box(kind, offset + low_center, low_size, color)
		# A darker cap marks the cut edge, like an architectural section.
		var cap := Vector3(size.x + 0.01, 0.03, size.z + 0.01)
		layers.tp.box("facade", offset + Vector3(center.x, low + 0.015, center.z), cap, color.darkened(0.35))

## Floor slab whose top is at y = top.
func floor_rect(x0: float, z0: float, x1: float, z1: float, color: Color, top := 0.0, kind := "paving") -> void:
	layers.always.box(kind, offset + Vector3((x0 + x1) / 2.0, top - 0.05, (z0 + z1) / 2.0), Vector3(x1 - x0, 0.1, z1 - z0), color)

## Ceiling (first person only) with its underside at `height`.
func ceiling(x0: float, z0: float, x1: float, z1: float, height: float, color: Color) -> void:
	layers.fp.box("facade", offset + Vector3((x0 + x1) / 2.0, height + 0.06, (z0 + z1) / 2.0), Vector3(x1 - x0, 0.12, z1 - z0), color)

## A recessed ceiling light (first person only).
func ceiling_light(center: Vector3, size: Vector2) -> void:
	layers.fp.box("light", offset + center, Vector3(size.x, 0.03, size.y), Color("fffaf0"))

## Commits the three layers under `parent`; returns [fp, tp] instances for view toggling.
func commit(parent: Node3D, label: String) -> Array:
	layers.always.commit(parent, label)
	var fp: MeshInstance3D = layers.fp.commit(parent, label + "FirstPerson", false)
	var tp: MeshInstance3D = layers.tp.commit(parent, label + "Cutaway", false)
	return [fp, tp]

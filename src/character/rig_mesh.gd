extends RefCounted
## Box meshes for the Minecraft-style rig, UV-mapped onto the 64×64 skin
## atlas (see skin_layout.gd for the face orientation both sides share).
## Each part is one mesh holding its base box and, just outside it, the
## overlay shell (its empty pixels are cut away by alpha scissor). Legs are
## split at the knee — thigh and shin each take half of the leg's texture —
## so the seated pose can bend them. Meshes depend only on the part and the
## build, so they are built once and shared by every character.
const Layout = preload("res://character/skin_layout.gd")
const P := Layout.PIXEL
static var _cache := {}

## Mesh for a rig part: head, torso, right_arm, left_arm, right_thigh,
## right_shin, left_thigh, left_shin, bun, ponytail, brim.
static func part(key: String, slim := false) -> ArrayMesh:
	var cache_key := key + (":slim" if slim else "")
	if _cache.has(cache_key):
		return _cache[cache_key]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arm := 3.0 if slim else 4.0
	match key:
		"head":
			_box(tool, Vector3(8, 8, 8), Vector3(0, 4, 0), Layout.faces_of("head"), 0.0)
			_box(tool, Vector3(8, 8, 8), Vector3(0, 4, 0), Layout.faces_of("head_overlay"), 0.5)
		"torso":
			_box(tool, Vector3(8, 12, 4), Vector3(0, 6, 0), Layout.faces_of("body"), 0.0)
			_box(tool, Vector3(8, 12, 4), Vector3(0, 6, 0), Layout.faces_of("body_overlay"), 0.25)
		"right_arm", "left_arm":
			_box(tool, Vector3(arm, 12, 4), Vector3(0, -4, 0), Layout.faces_of(key, slim), 0.0)
			_box(tool, Vector3(arm, 12, 4), Vector3(0, -4, 0), Layout.faces_of(key + "_overlay", slim), 0.25)
		"right_thigh", "left_thigh", "right_shin", "left_shin":
			var leg := key.replace("_thigh", "_leg").replace("_shin", "_leg")
			var upper := key.ends_with("_thigh")
			_box(tool, Vector3(4, 6, 4), Vector3(0, -3, 0), _half(Layout.faces_of(leg), upper), 0.0)
			_box(tool, Vector3(4, 6, 4), Vector3(0, -3, 0), _half(Layout.faces_of(leg + "_overlay"), upper), 0.25)
		"bun":
			_box(tool, Vector3(4, 3, 4), Vector3(0, 9.3, 2.1), Layout.faces_of("bun"), 0.0)
		"ponytail":
			_box(tool, Vector3(2, 6, 2), Vector3(0, 2.8, 5.3), Layout.faces_of("ponytail"), 0.0)
		"brim":
			_box(tool, Vector3(8, 1, 3), Vector3(0, 6.2, -5.9), Layout.faces_of("brim"), 0.0)
	var mesh := tool.commit()
	_cache[cache_key] = mesh
	return mesh

## The backpack: an 8×10×4 box on its own 24×14 texture, hung on the spine.
static func backpack() -> ArrayMesh:
	if _cache.has("backpack"):
		return _cache["backpack"]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := Layout.faces([0, 0, 8, 10, 4])
	_box(tool, Vector3(8, 10, 4), Vector3.ZERO, faces, 0.0, Vector2(24, 14))
	var mesh := tool.commit()
	_cache["backpack"] = mesh
	return mesh

## Upper (rows 0–5) or lower (rows 6–11) half of a leg's faces. The joint
## faces take one texture row from the front at the knee.
static func _half(faces: Dictionary, upper: bool) -> Dictionary:
	var result := {}
	for face in ["front", "back", "right", "left"]:
		var r: Rect2i = faces[face]
		result[face] = Rect2i(r.position.x, r.position.y + (0 if upper else 6), r.size.x, 6)
	var front: Rect2i = faces.front
	if upper:
		result.top = faces.top
		result.bottom = Rect2i(front.position.x, front.position.y + 5, front.size.x, 1)
	else:
		result.top = Rect2i(front.position.x, front.position.y + 6, front.size.x, 1)
		result.bottom = faces.bottom
	return result

## Adds a textured box. Sizes and centre are in skin pixels; `inflate` grows
## it by that many pixels on every side. Faces wind clockwise seen from
## outside (Godot's front faces) with flat normals.
static func _box(tool: SurfaceTool, size_px: Vector3, center_px: Vector3, rects: Dictionary, inflate: float, atlas := Vector2(64, 64)) -> void:
	var h := (size_px / 2.0 + Vector3.ONE * inflate) * P
	var c := center_px * P
	# Corners per face, as seen from outside: top-left, top-right, bottom-right, bottom-left.
	var corners := {
		"front": [Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z)],
		"back": [Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
		"right": [Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z)],
		"left": [Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, -h.z)],
		"top": [Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
		"bottom": [Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z)],
	}
	var normals := {"front": Vector3.FORWARD, "back": Vector3.BACK, "right": Vector3.RIGHT, "left": Vector3.LEFT, "top": Vector3.UP, "bottom": Vector3.DOWN}
	for face in corners:
		var r: Rect2i = rects[face]
		# Inset a hair so nearest sampling never reaches a neighbouring face.
		var u0 := (r.position.x + 0.01) / atlas.x
		var u1 := (r.position.x + r.size.x - 0.01) / atlas.x
		var v0 := (r.position.y + 0.01) / atlas.y
		var v1 := (r.position.y + r.size.y - 0.01) / atlas.y
		var uv := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
		var points: Array = corners[face]
		for index in [0, 1, 2, 0, 2, 3]:
			tool.set_normal(normals[face])
			tool.set_uv(uv[index])
			tool.add_vertex(c + points[index])

extends RefCounted
## Collects many boxes/cylinders into one mesh per material, so a detailed
## building (fins, frames, slabs, railings) costs a handful of draw calls.
## Colour is carried per vertex; materials are shared across the campus.
## Collision is collected separately as simple boxes on one StaticBody.
##
## Material kinds:
##   facade — matte painted/rendered surfaces (grounded with a soft base gradient)
##   glass  — curtain-wall shader (mullion grid, sky reflection, varied panes)
##   wood   — warm timber soffits and cladding (wood grain shader)
##   metal  — satin metal panels, frames and fittings
##   paving — ground surfaces (plazas, paths, parking)
##   tinted — plain tinted, reflective glass for doors (no curtain-wall grid)
##   light  — unshaded colour: daylight in windows, light fixtures, screens
##   wood / walnut — oak or darker walnut grain (vertex colour ignored)
static var _materials := {}
var tools := {}
var solids: Array = []

static func material(kind: String) -> Material:
	if _materials.has(kind):
		return _materials[kind]
	var result: Material
	match kind:
		"glass":
			var glass := ShaderMaterial.new()
			glass.shader = preload("res://assets/glass.gdshader")
			result = glass
		"light":
			var light := StandardMaterial3D.new()
			light.vertex_color_use_as_albedo = true
			light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			result = light
		"tinted":
			var tinted := StandardMaterial3D.new()
			tinted.vertex_color_use_as_albedo = true
			tinted.metallic = 0.55
			tinted.metallic_specular = 0.9
			tinted.roughness = 0.07
			result = tinted
		"wood", "walnut":
			var wood := ShaderMaterial.new()
			wood.shader = preload("res://assets/wood.gdshader")
			# "walnut": the darker veneer of the hospital's feature walls and desks.
			wood.set_shader_parameter("wood_color", Color(0.74, 0.52, 0.32) if kind == "wood" else Color(0.42, 0.27, 0.16))
			result = wood
		_:
			var facade := ShaderMaterial.new()
			facade.shader = preload("res://assets/facade.gdshader")
			facade.set_shader_parameter("roughness", {"metal": 0.42, "paving": 0.95}.get(kind, 0.82))
			facade.set_shader_parameter("metallic", 0.35 if kind == "metal" else 0.0)
			facade.set_shader_parameter("base_shade", 0.0 if kind == "paving" else 0.12)
			result = facade
	_materials[kind] = result
	return result

func _tool(kind: String) -> SurfaceTool:
	if not tools.has(kind):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools[kind] = tool
	return tools[kind]

## Axis-aligned (or rotated by `basis`) box centred at `center`.
func box(kind: String, center: Vector3, size: Vector3, color: Color, basis := Basis.IDENTITY) -> void:
	var tool := _tool(kind)
	var h := size / 2.0
	var faces := [
		[Vector3.RIGHT, [Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)]],
		[Vector3.LEFT, [Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)]],
		[Vector3.UP, [Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)]],
		[Vector3.DOWN, [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)]],
		[Vector3.BACK, [Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]],
		[Vector3.FORWARD, [Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)]],
	]
	for face in faces:
		var normal: Vector3 = basis * face[0]
		var corners: Array = face[1]
		for index in [0, 2, 1, 0, 3, 2]:
			tool.set_color(color)
			tool.set_normal(normal)
			tool.add_vertex(center + basis * corners[index])

## Box plus a collider of the same size.
func solid_box(kind: String, center: Vector3, size: Vector3, color: Color) -> void:
	box(kind, center, size, color)
	solid(center, size)

func solid(center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	solids.append([center, size, basis])

## Cylinder between two points (columns, posts, lamp poles, trunks).
func cylinder(kind: String, a: Vector3, b: Vector3, radius: float, color: Color, segments := 10) -> void:
	var tool := _tool(kind)
	var axis := (b - a).normalized()
	var reference := Vector3.FORWARD if absf(axis.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var side := reference.cross(axis).normalized()
	var front := side.cross(axis)
	for index in range(segments):
		var t0 := TAU * index / segments
		var t1 := TAU * (index + 1) / segments
		var n0 := side * cos(t0) + front * sin(t0)
		var n1 := side * cos(t1) + front * sin(t1)
		var quad := [[a + n0 * radius, n0], [a + n1 * radius, n1], [b + n1 * radius, n1], [b + n0 * radius, n0]]
		for corner in [0, 1, 2, 0, 2, 3]:
			tool.set_color(color)
			tool.set_normal(quad[corner][1])
			tool.add_vertex(quad[corner][0])
		for cap in [[a, -axis, n1, n0], [b, axis, n0, n1]]:
			for point in [cap[0], cap[0] + cap[2] * radius, cap[0] + cap[3] * radius]:
				tool.set_color(color)
				tool.set_normal(cap[1])
				tool.add_vertex(point)

## Builds the mesh (one surface per material) and the collision body.
func commit(parent: Node3D, label: String, shadows := true) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	for kind in tools:
		var tool: SurfaceTool = tools[kind]
		tool.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, material(kind))
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	if not solids.is_empty():
		var body := StaticBody3D.new()
		body.name = label + "Collision"
		for entry in solids:
			var shape := CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			shape.shape.size = entry[1]
			shape.position = entry[0]
			shape.basis = entry[2] if entry.size() > 2 else Basis.IDENTITY
			body.add_child(shape)
		parent.add_child(body)
	return instance

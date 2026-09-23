extends RefCounted
## Procedural planting. Each species is one cached mesh (trunk, branches and a
## crown of leaf clusters whose normals point out from the crown centre, so the
## crown shades as one soft volume) drawn with MultiMesh instancing: dozens of
## trees cost one draw call per species. Trunks can get simple colliders.
static var _meshes := {}
static var _material: ShaderMaterial

## species -> [trunk_height, crown_center_y, crown_radii, clusters, cluster_radius, colours, trunk_radius]
const SPECIES := {
	"shade": [2.5, 4.4, Vector3(2.3, 1.7, 2.3), 30, [0.55, 0.9], ["6a9a45", "7aab50", "5b8a3d", "8cb85c"], 0.2],
	"flowering": [1.9, 3.3, Vector3(1.8, 1.25, 1.8), 26, [0.45, 0.7], ["f2b3c8", "f7c9d7", "e89ab5", "fbe0e8"], 0.15],
	"columnar": [0.9, 3.4, Vector3(0.85, 2.7, 0.85), 18, [0.4, 0.6], ["557f42", "5f8b48", "4c7439"], 0.14],
	"ornamental": [1.5, 2.6, Vector3(1.2, 0.95, 1.2), 16, [0.35, 0.55], ["93bb62", "a3c86e", "86ad58"], 0.11],
	"shrub": [0.0, 0.45, Vector3(0.75, 0.42, 0.75), 9, [0.26, 0.4], ["628f4a", "6f9d53", "587f43"], 0.0],
	"hedge": [0.0, 0.5, Vector3(1.05, 0.45, 0.42), 12, [0.26, 0.38], ["567f45", "618c4c", "4d743f"], 0.0],
	"blossom": [0.0, 0.1, Vector3(0.16, 0.07, 0.16), 5, [0.045, 0.07], ["ffffff"], 0.0],
}

static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://assets/foliage.gdshader")
	return _material

static func mesh(species: String) -> ArrayMesh:
	if _meshes.has(species):
		return _meshes[species]
	var spec: Array = SPECIES[species]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(species)
	var trunk_height: float = spec[0]
	var crown := Vector3(0, spec[1], 0)
	var radii: Vector3 = spec[2]
	if trunk_height > 0.0:
		var bark := Color("6b5a4a")
		_cylinder(tool, Vector3.ZERO, Vector3(0, trunk_height + radii.y * 0.4, 0), spec[6], spec[6] * 0.6, bark)
		for branch in range(3):
			var angle := branch * TAU / 3.0 + 0.4
			var start := Vector3(0, trunk_height * 0.85, 0)
			var end := start + Vector3(cos(angle) * radii.x * 0.55, radii.y * 0.7, sin(angle) * radii.z * 0.55)
			_cylinder(tool, start, end, spec[6] * 0.5, spec[6] * 0.25, bark)
	var colours: Array = spec[5]
	for index in range(int(spec[3])):
		# Clusters fill an ellipsoid, weighted toward its surface.
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.7, 1), rng.randf_range(-1, 1)).normalized()
		var reach := sqrt(rng.randf_range(0.35, 1.0))
		var center := crown + direction * radii * reach * 0.78
		var radius := rng.randf_range(spec[4][0], spec[4][1])
		var colour := Color(colours[rng.randi() % colours.size()])
		# Lower and inner clusters are a little darker, as if self-shadowed.
		colour = colour.darkened(0.18 * (1.0 - clampf((center.y - crown.y + radii.y) / (2.0 * radii.y), 0.0, 1.0)))
		_cluster(tool, center, radius, colour, crown, rng)
	var result := tool.commit()
	_meshes[species] = result
	return result

## A lumpy leaf cluster; normals blend its own roundness with the crown's.
static func _cluster(tool: SurfaceTool, center: Vector3, radius: float, colour: Color, crown: Vector3, rng: RandomNumberGenerator) -> void:
	var rings := 6
	var segments := 9
	var grid: Array = []
	for ring in range(rings + 1):
		var row: Array = []
		var phi := PI * ring / rings
		for segment in range(segments + 1):
			var theta := TAU * (segment % segments) / segments
			var unit := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			var bump := 1.0 + 0.14 * sin(theta * 3.0 + phi * 2.0 + center.x * 5.0)
			row.append(center + unit * radius * bump)
		grid.append(row)
	for ring in range(rings):
		for segment in range(segments):
			var quad := [grid[ring][segment], grid[ring][segment + 1], grid[ring + 1][segment + 1], grid[ring + 1][segment]]
			for corner in [0, 2, 1, 0, 3, 2]:
				var point: Vector3 = quad[corner]
				var normal := ((point - center).normalized() * 0.2 + (point - crown).normalized() * 0.8).normalized()
				var shade := 0.9 + 0.2 * clampf((point.y - center.y) / radius, -1.0, 1.0) * 0.5
				tool.set_color(colour * shade)
				tool.set_normal(normal)
				tool.add_vertex(point)

static func _cylinder(tool: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, colour: Color) -> void:
	var axis := (b - a).normalized()
	var reference := Vector3.FORWARD if absf(axis.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var side := reference.cross(axis).normalized()
	var front := side.cross(axis)
	var segments := 7
	for index in range(segments):
		var t0 := TAU * index / segments
		var t1 := TAU * (index + 1) / segments
		var n0 := side * cos(t0) + front * sin(t0)
		var n1 := side * cos(t1) + front * sin(t1)
		var quad := [[a + n0 * ra, n0], [a + n1 * ra, n1], [b + n1 * rb, n1], [b + n0 * rb, n0]]
		for corner in [0, 1, 2, 0, 2, 3]:
			tool.set_color(colour)
			tool.set_normal(quad[corner][1])
			tool.add_vertex(quad[corner][0])

## Places many plants of one species. `placements`: Array of [position, scale, yaw].
## Trunked species get cylinder colliders (on one StaticBody) when `collide`.
static func plant(parent: Node3D, species: String, placements: Array, collide := true, tints: Array = []) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh(species)
	multimesh.instance_count = placements.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(species) + placements.size()
	for index in range(placements.size()):
		var entry: Array = placements[index]
		var size: float = entry[1]
		var basis := Basis(Vector3.UP, entry[2]).scaled(Vector3(size, size * rng.randf_range(0.92, 1.08), size))
		multimesh.set_instance_transform(index, Transform3D(basis, entry[0]))
		var tint: Color = tints[index] if index < tints.size() else Color.WHITE.darkened(rng.randf_range(0.0, 0.1))
		multimesh.set_instance_color(index, tint)
	var instance := MultiMeshInstance3D.new()
	instance.name = species.capitalize() + "Plants"
	instance.multimesh = multimesh
	instance.material_override = material()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if species not in ["blossom"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	var spec: Array = SPECIES[species]
	if collide and (spec[0] > 0.0 or species == "hedge"):
		var body := StaticBody3D.new()
		body.name = species.capitalize() + "Colliders"
		for entry in placements:
			var shape := CollisionShape3D.new()
			if species == "hedge":
				shape.shape = BoxShape3D.new()
				shape.shape.size = Vector3(2.1, 1.0, 0.85) * float(entry[1])
				shape.rotation.y = entry[2]
			else:
				shape.shape = CylinderShape3D.new()
				shape.shape.radius = maxf(0.2, spec[6] * float(entry[1]) * 1.2)
				shape.shape.height = 2.0
			shape.position = entry[0] + Vector3(0, 1.0 if species != "hedge" else 0.5, 0)
			body.add_child(shape)
		parent.add_child(body)
	return instance

extends RefCounted
## Small shared factory for original low-poly meshes. World collision is layer 1.
static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	return result

static func box(parent: Node3D, label: String, size: Vector3, position: Vector3, color: Color, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = label
	node.position = position
	parent.add_child(node)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	node.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collider.shape = box_shape
		node.add_child(collider)
	return node

static func sphere(parent: Node3D, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = 12
	sphere_mesh.rings = 6
	mesh.mesh = sphere_mesh
	mesh.scale = size
	mesh.position = position
	mesh.material_override = material(color)
	parent.add_child(mesh)
	return mesh

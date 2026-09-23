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
	node.set_meta("geometry_label", label)
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

## A cylinder spanning two points (used for stands, necks, gooseneck segments).
static func cylinder_between(parent: Node3D, label: String, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = a.distance_to(b)
	shape.radial_segments = 10
	shape.rings = 1
	mesh.mesh = shape
	mesh.material_override = material(color)
	var axis := (b - a).normalized()
	var reference := Vector3.FORWARD if absf(axis.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x := reference.cross(axis).normalized()
	mesh.transform = Transform3D(Basis(x, axis, x.cross(axis)), (a + b) / 2.0)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh

static func accent_light(parent: Node3D, position: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	parent.add_child(light)

static func potted_plant(parent: Node3D, position: Vector3) -> void:
	box(parent, "TerracottaPot", Vector3(0.5, 0.5, 0.5), position + Vector3(0, 0.25, 0), Color("cf7955"))
	for index in range(5):
		var angle := index * TAU / 5
		var leaf := sphere(parent, Vector3(0.3, 0.8, 0.3), position + Vector3(cos(angle) * 0.18, 0.8, sin(angle) * 0.18), Color("388967") if index % 2 else Color("64b379"))
		leaf.rotation.z = cos(angle) * 0.4

static func nameplate(parent: Node3D, text: String, position: Vector3, font_size: int = 28, pixel_size: float = 0.01) -> Label3D:
	var label := preload("res://ui/world_nameplate.gd").new()
	label.text = text
	label.position = position
	label.font_size = font_size
	label.pixel_size = pixel_size
	parent.add_child(label)
	return label

## A sign mounted flat on a surface. `yaw` turns the sign's face (+Z) to the
## surface normal; position is the face centre, just proud of the surface.
static func wall_sign(parent: Node3D, text: String, position: Vector3, yaw: float, font_size: int = 28, pixel_size: float = 0.01) -> Label3D:
	var label := preload("res://ui/world_nameplate.gd").new()
	label.mounted = true
	label.text = text
	label.position = position
	label.rotation.y = yaw
	label.font_size = font_size
	label.pixel_size = pixel_size
	parent.add_child(label)
	return label

static func configure_shadows(light: DirectionalLight3D) -> void:
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 40.0
	light.shadow_bias = 0.15
	light.shadow_normal_bias = 2.0

static func bookshelf(parent: Node3D, origin: Vector3) -> void:
	box(parent, "LoungeBookshelf", Vector3(1.8, 2.0, 0.55), origin + Vector3(0, 1, 0), Color("71533f"), true)
	for row in range(3):
		box(parent, "Shelf", Vector3(1.85, 0.07, 0.65), origin + Vector3(0, 0.25 + row * 0.55, 0.04), Color("c69d72"))
		for index in range(7):
			box(parent, "Book", Vector3(0.15, 0.33 + (index % 3) * 0.045, 0.3), origin + Vector3(-0.7 + index * 0.23, 0.46 + row * 0.55, 0.32), Color(["55948c", "d5ad70", "ac6d60", "778bad"][index % 4]))

static func vending_machine(parent: Node3D, origin: Vector3, snacks: bool) -> void:
	box(parent, "VendingMachineSnacks" if snacks else "VendingMachineDrinks", Vector3(1.15, 2.15, 0.85), origin + Vector3(0, 1.075, 0), Color("b06746") if snacks else Color("336d82"), true)
	box(parent, "VendingGlass", Vector3(0.75, 1.35, 0.04), origin + Vector3(-0.1, 1.23, 0.44), Color("182f3b"))
	for row in range(3):
		for column in range(3):
			box(parent, "Product", Vector3(0.14, 0.24, 0.05), origin + Vector3(-0.34 + column * 0.23, 0.8 + row * 0.35, 0.48), Color(["e4b85e", "72b6aa", "da8778"][column]))
	box(parent, "Payment", Vector3(0.12, 0.3, 0.05), origin + Vector3(0.43, 1.3, 0.45), Color("93d0cb"))
	box(parent, "CollectionSlot", Vector3(0.75, 0.18, 0.05), origin + Vector3(0, 0.25, 0.45), Color("132b35"))
	wall_sign(parent, "SNACKS" if snacks else "DRINKS", origin + Vector3(0, 1.98, 0.44), 0.0, 24, 0.007)

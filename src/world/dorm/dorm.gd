extends Node3D
## Intentional small room assembled from original geometry, in metres.
const Geometry = preload("res://world/geometry.gd")
const Interactable = preload("res://world/interactable.gd")
const ExplorationCamera = preload("res://world/exploration_camera.gd")
const PlayerScene = preload("res://player/player.tscn")
const DormUI = preload("res://ui/dorm_ui.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var desk: Node3D
var bed: Node3D
var exit_door: Node3D

func _ready() -> void:
	_build_room()
	_build_furniture()
	_apply_wood()
	Geometry.potted_plant(self, Vector3(-4.1, 0, 3.5))
	Geometry.accent_light(self, Vector3(0.4, 1.75, -3.6), Color("ffcb7d"), 0.25, 3.5)
	Geometry.box(self, "WindowSill", Vector3(2.8, 0.12, 0.4), Vector3(0, 1.04, -4.15), Color("fff1d7"))
	_build_lighting()
	camera = ExplorationCamera.new()
	add_child(camera)
	player = PlayerScene.instantiate()
	player.position = Vector3(0, 0.05, 1.5)
	add_child(player)
	player.movement_camera = camera
	hud = DormUI.new()
	add_child(hud)
	hud.bind_player(player)

func _build_room() -> void:
	Geometry.box(self, "Floor", Vector3(10, 0.2, 9), Vector3(0, -0.1, 0), Color("c7b291"), true)
	# Full-height colliders on every edge; near walls are visually cut away.
	for wall in [
		["NorthWall", Vector3(10, 2.8, 0.2), Vector3(0, 1.4, -4.5)],
		["WestWall", Vector3(0.2, 2.8, 9), Vector3(-5, 1.4, 0)],
		["SouthWall", Vector3(10, 2.8, 0.2), Vector3(0, 1.4, 4.5)],
		["EastWall", Vector3(0.2, 2.8, 9), Vector3(5, 1.4, 0)],
	]:
		var node := Geometry.box(self, wall[0], wall[1], wall[2], Color("f0e4cf"), true)
		node.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if wall[0] in ["SouthWall", "EastWall"]:
			node.get_child(0).scale.y = 0.07
			node.get_child(0).position.y = -1.3
	Geometry.box(self, "Rug", Vector3(4.2, 0.02, 3.4), Vector3(0, 0.015, 1), Color("327f88"))
	Geometry.box(self, "WindowFrame", Vector3(2.6, 1.55, 0.09), Vector3(0, 1.8, -4.35), Color("fff2d6"))
	Geometry.box(self, "MorningGlass", Vector3(2.35, 1.3, 0.06), Vector3(0, 1.8, -4.28), Color("a4cbd1"))
	Geometry.box(self, "WindowDivider", Vector3(0.07, 1.4, 0.08), Vector3(0, 1.8, -4.21), Color("f3ead7"))
	Geometry.box(self, "Door", Vector3(0.12, 2.25, 1.35), Vector3(4.85, 1.13, 2.5), Color("597b74"))
	Geometry.sphere(self, Vector3(0.12, 0.12, 0.12), Vector3(4.71, 1, 2.02), Color("d6b56e"))
	_label("EXIT", Vector3(4.65, 2.55, 2.5), 28)
	exit_door = _interaction("DormExit", "Leave dorm", "", Vector3(4.05, 1, 2.5))
	exit_door.activated.connect(AppState.leave_dorm)

func _build_furniture() -> void:
	Geometry.box(self, "Bed", Vector3(1.85, 0.48, 3.1), Vector3(-3.45, 0.24, -0.8), Color("806e5c"), true)
	Geometry.box(self, "Mattress", Vector3(1.82, 0.18, 3), Vector3(-3.45, 0.56, -0.8), Color("f0e5ce"))
	Geometry.box(self, "Duvet", Vector3(1.85, 0.14, 2.15), Vector3(-3.45, 0.7, -0.35), Color("4b9f94"))
	Geometry.box(self, "Pillow", Vector3(1.3, 0.16, 0.58), Vector3(-3.45, 0.72, -1.98), Color("f8edda"))
	bed = _interaction("BedInteraction", "Inspect bed", "A freshly made bed. A quiet place to recharge after class.", Vector3(-2.15, 1, -0.5))
	Geometry.box(self, "Desk", Vector3(3.0, 0.1, 1.1), Vector3(1.65, 0.89, -3.55), Color("a98760"), true)
	for x in [0.35, 2.95]:
		for z in [-3.98, -3.12]:
			Geometry.box(self, "DeskLeg", Vector3(0.12, 0.86, 0.12), Vector3(x, 0.43, z), Color("715e4f"), true)
	Geometry.box(self, "Desktop", Vector3(3.12, 0.08, 1.2), Vector3(1.65, 0.94, -3.55), Color("dec39a"))
	Geometry.box(self, "Chair", Vector3(0.7, 0.6, 0.7), Vector3(1.65, 0.3, -2.45), Color("475e65"), true)
	Geometry.box(self, "ChairBack", Vector3(0.7, 0.65, 0.12), Vector3(1.65, 0.8, -2.16), Color("475e65"))
	Geometry.box(self, "LaptopBase", Vector3(0.65, 0.05, 0.44), Vector3(1.65, 1.01, -3.45), Color("465563"))
	Geometry.box(self, "LaptopScreen", Vector3(0.65, 0.45, 0.05), Vector3(1.65, 1.23, -3.68), Color("314959"))
	Geometry.box(self, "ScreenGlow", Vector3(0.55, 0.34, 0.02), Vector3(1.65, 1.23, -3.645), Color("9abbb2"))
	for book_index in range(3):
		Geometry.box(self, "MedicalTextbook", Vector3(0.46, 0.09, 0.58), Vector3(2.55, 1.03 + book_index * 0.09, -3.5), Color(["827c9b", "b7775d", "647b72"][book_index]))
	_label("PHARMACOLOGY", Vector3(2.55, 1.55, -3.5), 17)
	Geometry.box(self, "LampBase", Vector3(0.25, 0.07, 0.25), Vector3(0.4, 1.01, -3.7), Color("d9b971"))
	Geometry.box(self, "LampStem", Vector3(0.045, 0.5, 0.045), Vector3(0.4, 1.26, -3.7), Color("d9b971"))
	Geometry.sphere(self, Vector3(0.34, 0.22, 0.34), Vector3(0.4, 1.55, -3.7), Color("f1d4a0"))
	desk = _interaction("DeskInteraction", "Use study desk", "Your pharmacology notes are open to pharmacodynamics.\nStudy sessions will be available in a later milestone.", Vector3(2.3, 1.05, -2.78))
	Geometry.box(self, "Bookshelf", Vector3(1.4, 1.8, 0.65), Vector3(-3.55, 0.9, -3.96), Color("957959"), true)
	for row in range(3):
		for index in range(5):
			Geometry.box(self, "BookSpine", Vector3(0.17, 0.36, 0.36), Vector3(-4.02 + index * 0.23, 0.35 + row * 0.54, -3.57), Color(["597d7c", "b98c65", "e3cba4", "777b94", "9ba48a"][index]))
	Geometry.box(self, "Noticeboard", Vector3(1.65, 0.88, 0.08), Vector3(2.65, 2.05, -4.33), Color("ab8c68"))
	_label("FIRST YEAR", Vector3(2.65, 2.2, -4.22), 24)

func _interaction(node_name: String, title: String, response: String, position: Vector3) -> Node3D:
	var endpoint := Interactable.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response.replace("\n", "
")
	endpoint.position = position
	add_child(endpoint)
	return endpoint

func _label(text: String, position: Vector3, font_size: int) -> void:
	Geometry.nameplate(self, text, position, font_size, 0.01)

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("263c47")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d4dfdd")
	environment.ambient_light_energy = 0.45
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("fff0d9")
	sun.light_energy = 0.65
	Geometry.configure_shadows(sun)
	add_child(sun)

func _apply_wood() -> void:
	# Restrained grain on the floor and furniture, with no decorative floor pattern.
	for child in get_children():
		if not child is Node3D:
			continue
		var label := str(child.get_meta("geometry_label", child.name))
		if label not in ["Floor", "Bed", "Desk", "Desktop", "Bookshelf", "Noticeboard"] and not label.begins_with("DeskLeg"):
			continue
		var mesh := child.get_child(0) as MeshInstance3D
		if mesh == null:
			continue
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/wood.gdshader")
		material.set_shader_parameter("wood_color", Color("a9845e") if label == "Floor" else Color("ad8054"))
		material.set_shader_parameter("floor_planks", label == "Floor")
		mesh.material_override = material

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
var closet: Node3D
## The desk PC's display surface.
var pc_screen: MeshInstance3D
## Walls cut away for the overhead camera, and the ceiling: first person shows the whole room.
var cutaway: Array[MeshInstance3D] = []
var first_person_only: Array[Node3D] = []

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
	AppState.view_changed.connect(apply_view)
	apply_view(AppState.first_person)

func apply_view(first_person: bool) -> void:
	for mesh in cutaway:
		mesh.scale.y = 1.0 if first_person else 0.07
		mesh.position.y = 0.0 if first_person else -1.3
	for node in first_person_only:
		node.visible = first_person

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
			cutaway.append(node.get_child(0))
	# Ceiling with a flush light, seen only from the first-person view (no shadows,
	# so the room is lit the same in both views).
	for piece in [["Ceiling", Vector3(10, 0.12, 9), Vector3(0, 2.86, 0), Color("f3ede2")], ["CeilingLight", Vector3(0.7, 0.03, 0.7), Vector3(0, 2.785, 0.6), Color("fff8e8")]]:
		var ceiling := Geometry.box(self, piece[0], piece[1], piece[2], piece[3])
		ceiling.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		first_person_only.append(ceiling)
	# The south wall only exists in first person: a framed print and a clock on it.
	var decor := [
		["PrintFrame", Vector3(1.3, 0.9, 0.04), Vector3(-1.4, 1.65, 4.37), Color("3b3f42")],
		["PrintMat", Vector3(1.18, 0.78, 0.02), Vector3(-1.4, 1.65, 4.345), Color("f4efe4")],
		["PrintField", Vector3(0.5, 0.56, 0.01), Vector3(-1.62, 1.65, 4.33), Color("5f8f88")],
		["PrintField", Vector3(0.34, 0.3, 0.01), Vector3(-1.12, 1.78, 4.33), Color("d49a6a")],
		["PrintField", Vector3(0.34, 0.2, 0.01), Vector3(-1.12, 1.47, 4.33), Color("2f4b5a")],
		["ClockHand", Vector3(0.02, 0.12, 0.01), Vector3(1.9, 2.1, 4.345), Color("24313a")],
		["ClockHand", Vector3(0.09, 0.02, 0.01), Vector3(1.935, 2.05, 4.345), Color("24313a")],
	]
	for piece in decor:
		first_person_only.append(Geometry.box(self, piece[0], piece[1], piece[2], piece[3]))
	for ring in [[0.19, Color("3b3f42"), 4.39, 4.37], [0.165, Color("f6f2ea"), 4.37, 4.355]]:
		first_person_only.append(Geometry.cylinder_between(self, "Clock", Vector3(1.9, 2.05, ring[2]), Vector3(1.9, 2.05, ring[3]), ring[0], ring[1]))
	# A soft room light for the enclosed view (the ceiling and the wall facing away from the sun).
	var fill := OmniLight3D.new()
	fill.name = "RoomLight"
	fill.position = Vector3(0, 2.45, 0.6)
	fill.omni_range = 7.5
	fill.light_energy = 0.55
	fill.light_color = Color("fff1dc")
	add_child(fill)
	first_person_only.append(fill)
	Geometry.box(self, "Rug", Vector3(4.2, 0.02, 3.4), Vector3(0, 0.015, 1), Color("327f88"))
	Geometry.box(self, "WindowFrame", Vector3(2.6, 1.55, 0.09), Vector3(0, 1.8, -4.35), Color("fff2d6"))
	Geometry.box(self, "MorningGlass", Vector3(2.35, 1.3, 0.06), Vector3(0, 1.8, -4.28), Color("a4cbd1"))
	Geometry.box(self, "WindowDivider", Vector3(0.07, 1.4, 0.08), Vector3(0, 1.8, -4.21), Color("f3ead7"))
	Geometry.box(self, "Door", Vector3(0.12, 2.25, 1.35), Vector3(4.85, 1.13, 2.5), Color("597b74"))
	Geometry.sphere(self, Vector3(0.12, 0.12, 0.12), Vector3(4.71, 1, 2.02), Color("d6b56e"))
	_label("EXIT", Vector3(4.65, 2.75, 2.5), 24, 0.0075) # Above the door frame, not over it.
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
	Geometry.box(self, "PCBase", Vector3(0.42, 0.035, 0.26), Vector3(1.65, 0.995, -3.72), Color("424953"))
	Geometry.box(self, "PCStand", Vector3(0.07, 0.3, 0.05), Vector3(1.65, 1.15, -3.775), Color("656e7b"))
	Geometry.box(self, "PCMonitor", Vector3(0.96, 0.56, 0.045), Vector3(1.65, 1.47, -3.72), Color("252f3f"))
	# The display is a flat quad the computer draws into (idle: the pixel lock screen).
	pc_screen = MeshInstance3D.new()
	pc_screen.name = "PCScreen"
	pc_screen.mesh = QuadMesh.new()
	pc_screen.mesh.size = Vector2(0.89, 0.5)
	pc_screen.position = Vector3(1.65, 1.47, -3.6955)
	pc_screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var idle := ShaderMaterial.new()
	idle.shader = preload("res://assets/pixel_screen.gdshader")
	idle.set_shader_parameter("image", preload("res://assets/windows_lock.png"))
	pc_screen.material_override = idle
	add_child(pc_screen)
	Geometry.box(self, "PCPowerLight", Vector3(0.012, 0.006, 0.004), Vector3(2.07, 1.205, -3.695), Color("7fe0a8"))
	Geometry.box(self, "PCKeyboard", Vector3(0.64, 0.025, 0.21), Vector3(1.65, 0.994, -3.22), Color("434f62"))
	Geometry.box(self, "PCMouse", Vector3(0.07, 0.03, 0.12), Vector3(2.1, 1.0, -3.22), Color("667184"))
	Geometry.box(self, "PCTower", Vector3(0.26, 0.45, 0.48), Vector3(0.78, 1.205, -3.64), Color("334153"))
	for book_index in range(3):
		Geometry.box(self, "MedicalTextbook", Vector3(0.46, 0.09, 0.58), Vector3(2.55, 1.03 + book_index * 0.09, -3.5), Color(["827c9b", "b7775d", "647b72"][book_index]))
	Geometry.box(self, "LampBase", Vector3(0.25, 0.07, 0.25), Vector3(0.4, 1.01, -3.7), Color("d9b971"))
	Geometry.box(self, "LampStem", Vector3(0.045, 0.5, 0.045), Vector3(0.4, 1.26, -3.7), Color("d9b971"))
	Geometry.sphere(self, Vector3(0.34, 0.22, 0.34), Vector3(0.4, 1.55, -3.7), Color("f1d4a0"))
	desk = _interaction("DeskInteraction", "Use study desk PC", "", Vector3(2.3, 1.05, -2.78))
	desk.activated.connect(func() -> void: hud.open_computer("windows", pc_screen))
	Geometry.box(self, "Bookshelf", Vector3(1.4, 1.8, 0.65), Vector3(-3.55, 0.9, -3.96), Color("957959"), true)
	for row in range(3):
		for index in range(5):
			Geometry.box(self, "BookSpine", Vector3(0.17, 0.36, 0.36), Vector3(-4.02 + index * 0.23, 0.35 + row * 0.54, -3.57), Color(["597d7c", "b98c65", "e3cba4", "777b94", "9ba48a"][index]))
	_build_wardrobe()
	Geometry.box(self, "Noticeboard", Vector3(1.65, 0.88, 0.08), Vector3(2.65, 2.05, -4.33), Color("ab8c68"))
	# Lettering pinned flat to the board, so it follows the board's perspective.
	Geometry.wall_sign(self, "FIRST YEAR", Vector3(2.65, 2.3, -4.285), 0.0, 26, 0.009)

## Oak wardrobe on the west wall: two doors (the left one mirrored), long
## handles, a crown and plinth. Interacting opens the closet (clothes and mirror).
func _build_wardrobe() -> void:
	var front := -4.9 + 0.62
	Geometry.box(self, "Wardrobe", Vector3(0.62, 2.1, 1.36), Vector3(-4.9 + 0.31, 1.05, 2.05), Color("a9845e"), true)
	Geometry.box(self, "WardrobeCrown", Vector3(0.68, 0.06, 1.44), Vector3(-4.9 + 0.34, 2.13, 2.05), Color("8a6a4f"))
	Geometry.box(self, "WardrobePlinth", Vector3(0.6, 0.08, 1.3), Vector3(-4.9 + 0.3, 0.04, 2.05), Color("4a3a2e"))
	for side in [-1, 1]:
		var z: float = 2.05 + side * 0.335
		Geometry.box(self, "WardrobeDoor", Vector3(0.02, 1.9, 0.64), Vector3(front + 0.01, 1.08, z), Color("b99268"))
		Geometry.box(self, "WardrobeHandle", Vector3(0.03, 0.34, 0.025), Vector3(front + 0.035, 1.12, 2.05 + side * 0.06), Color("3a3f44"))
	# A stylised mirror (no real reflections in this renderer): pale silvered
	# glass with two diagonal shine streaks.
	var mirror := Geometry.box(self, "WardrobeMirror", Vector3(0.012, 1.5, 0.48), Vector3(front + 0.025, 1.12, 2.05 - 0.335), Color.WHITE)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("cfdde2")
	glass.roughness = 0.35
	glass.emission_enabled = true
	glass.emission = Color("9fb3ba")
	glass.emission_energy_multiplier = 0.25
	mirror.get_child(0).material_override = glass
	for streak in [[0.2, 0.05], [0.45, 0.025]]:
		var shine := Geometry.box(self, "MirrorShine", Vector3(0.004, 0.46, streak[1]), Vector3(front + 0.033, 1.12 + streak[0], 2.05 - 0.335 - 0.06 + streak[0] * 0.2), Color("f4f8f9"))
		shine.rotation.x = 0.7
	closet = _interaction("ClosetInteraction", "Open closet", "", Vector3(front + 0.5, 1, 2.05))
	closet.activated.connect(func() -> void: hud.open_closet())

func _interaction(node_name: String, title: String, response: String, position: Vector3) -> Node3D:
	var endpoint := Interactable.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response.replace("\n", "
")
	endpoint.position = position
	add_child(endpoint)
	return endpoint

func _label(text: String, position: Vector3, font_size: int, pixel_size := 0.01) -> void:
	Geometry.nameplate(self, text, position, font_size, pixel_size)

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
		if label not in ["Floor", "Bed", "Desk", "Desktop", "Bookshelf", "Noticeboard", "Wardrobe", "WardrobeDoor"] and not label.begins_with("DeskLeg"):
			continue
		var mesh := child.get_child(0) as MeshInstance3D
		if mesh == null:
			continue
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/wood.gdshader")
		material.set_shader_parameter("wood_color", Color("a9845e") if label == "Floor" else Color("ad8054"))
		material.set_shader_parameter("floor_planks", label == "Floor")
		mesh.material_override = material

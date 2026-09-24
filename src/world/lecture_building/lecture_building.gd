extends Node3D
## Learning Center lobby: the route from the campus doors to Lecture Hall A.
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const MeshKit = preload("res://world/campus/mesh_kit.gd")
const SeminarFlyer = preload("res://ui/seminar_flyer.gd")
const FLOOR := Color("5d6468")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var exit_door: Node3D
var hall_door: Node3D
## Walls cut away for the overhead camera; the ceiling and south doors seen only in first person.
var cutaway: Array[MeshInstance3D] = []
var first_person_only: Array[Node3D] = []

func _ready() -> void:
	# Modern lobby matching the Learning Center exterior: polished slate floor,
	# warm white walls, a timber feature wall, glazed doors in dark frames.
	Geometry.box(self, "Floor", Vector3(10, 0.2, 8), Vector3(0, -0.1, 0), FLOOR, true)
	for wall in [[Vector3(10, 3, 0.2), Vector3(0, 1.5, -4)], [Vector3(0.2, 3, 8), Vector3(-5, 1.5, 0)], [Vector3(0.2, 3, 8), Vector3(5, 1.5, 0)], [Vector3(10, 3, 0.2), Vector3(0, 1.5, 4)]]:
		var body := Geometry.box(self, "Wall", wall[0], wall[1], Color("eeede8"), true)
		body.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if wall[1].x > 0 or wall[1].z > 0:
			cutaway.append(body.get_child(0))
	_build_hall_entrance()
	_build_first_person_shell()
	_build_feature_wall()
	# Exit: glazed doors in the (cut-away) south wall.
	Geometry.box(self, "ExitDoor", Vector3(1.9, 0.14, 0.14), Vector3(0, 0.07, 3.8), Color("3f464b"))
	# Reception: white counter with a timber front and a monitor.
	Geometry.box(self, "Reception", Vector3(2.4, 1.05, 1.0), Vector3(-3.1, 0.525, -1.6), Color("f1efea"), true)
	var front := Geometry.box(self, "ReceptionFront", Vector3(2.44, 0.8, 0.04), Vector3(-3.1, 0.5, -1.08), Color("b58558"))
	_wood(front.get_child(0))
	Geometry.box(self, "ReceptionTop", Vector3(2.5, 0.05, 1.08), Vector3(-3.1, 1.075, -1.6), Color("d9d6cf"))
	_build_reception_workstation()
	# Central corridor stays open for both player and scheduled NPC navigation.
	Geometry.vending_machine(self, Vector3(2.35, 0, -3.35), false)
	Geometry.vending_machine(self, Vector3(3.75, 0, -3.35), true)
	# Reading corner: two free-standing, double-sided bookcases.
	_double_bookcase("LoungeBookshelf", Vector3(-3.95, 0, 2.85), PI / 2, 11)
	_double_bookcase("LoungeBookshelfEast", Vector3(-2.35, 0, 2.85), PI / 2, 29)
	# Lounge: charcoal upholstered sofa on a slim base.
	Geometry.box(self, "SofaBase", Vector3(1.15, 0.4, 2.7), Vector3(3.65, 0.25, 0.4), Color("3a474d"), true)
	Geometry.box(self, "SofaBack", Vector3(0.25, 0.95, 2.7), Vector3(4.15, 0.75, 0.4), Color("46565c"))
	for z in [-0.5, 0.4, 1.3]:
		Geometry.box(self, "SeatCushion", Vector3(0.92, 0.25, 0.82), Vector3(3.57, 0.57, z), Color("5d7076"))
		Geometry.box(self, "BackCushion", Vector3(0.22, 0.55, 0.82), Vector3(3.95, 0.98, z), Color("56696f"))
	for z in [-1.02, 1.82]:
		Geometry.box(self, "SofaArm", Vector3(1.2, 0.55, 0.18), Vector3(3.65, 0.72, z), Color("46565c"))
	Geometry.box(self, "CoffeeTable", Vector3(0.7, 0.04, 1.2), Vector3(2.45, 0.42, 0.4), Color("6e4c33"))
	for dz in [-0.5, 0.5]:
		Geometry.box(self, "TableLeg", Vector3(0.04, 0.4, 0.04), Vector3(2.45, 0.2, 0.4 + dz), Color("3f464b"))
	exit_door = _endpoint("CampusExit", "Return to campus", "", Vector3(0, 1, 3))
	exit_door.activated.connect(AppState.enter_campus.bind("lecture_building"))
	hall_door = _endpoint("HallA", "Enter Hall A", "", Vector3(0, 1, -3))
	hall_door.activated.connect(AppState.enter_lecture_hall)
	var actor := preload("res://npc/student.tscn").instantiate()
	actor.world_zone = "lecture_building"
	add_child(actor)
	Geometry.potted_plant(self, Vector3(-4.3, 0, -3.2))
	Geometry.potted_plant(self, Vector3(4.3, 0, 3.2))
	Geometry.accent_light(self, Vector3(0, 2.7, -2), Color("fff1dc"), 0.25, 7.0)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("263c47")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e2e0da")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.08
	environment_node.environment = environment
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 0.6
	light.light_color = Color("ffe4bd")
	Geometry.configure_shadows(light)
	add_child(light)
	player = Player.instantiate()
	player.position = Vector3(0, 0.05, 1.8)
	add_child(player)
	camera = Camera.new()
	add_child(camera)
	player.movement_camera = camera
	hud = HUD.new()
	add_child(hud)
	hud.bind_player(player)
	AppState.view_changed.connect(apply_view)
	apply_view(AppState.first_person)

func apply_view(first_person: bool) -> void:
	for mesh in cutaway:
		mesh.scale.y = 1.0 if first_person else 0.05
		mesh.position.y = 0.0 if first_person else -1.4
	for node in first_person_only:
		node.visible = first_person

## Ceiling with light panels, and glazed exit doors in the south wall with
## daylight beyond. None cast shadows, so the lobby is lit the same either way.
func _build_first_person_shell() -> void:
	var pieces := [["Ceiling", Vector3(10, 0.12, 8), Vector3(0, 3.06, 0), Color("f2f0eb")]]
	for x in [-2.5, 2.5]:
		for z in [-1.8, 1.8]:
			pieces.append(["CeilingLight", Vector3(1.3, 0.03, 0.45), Vector3(x, 2.985, z), Color("fff7e6")])
	var frame := Color("3f464b")
	pieces.append_array([
		["ExitDoorHead", Vector3(2.5, 0.12, 0.1), Vector3(0, 2.6, 3.86), frame],
		["ExitDoorJamb", Vector3(0.1, 2.6, 0.1), Vector3(-1.2, 1.3, 3.86), frame],
		["ExitDoorJamb", Vector3(0.1, 2.6, 0.1), Vector3(1.2, 1.3, 3.86), frame],
		["ExitDoorStile", Vector3(0.06, 2.5, 0.06), Vector3(0, 1.25, 3.84), frame],
	])
	for x in [-0.56, 0.56]:
		pieces.append(["ExitPushBar", Vector3(0.05, 0.8, 0.04), Vector3(x + (0.4 if x < 0 else -0.4), 1.1, 3.8), Color("c9d0d3")])
	for piece in pieces:
		var node := Geometry.box(self, piece[0], piece[1], piece[2], piece[3])
		node.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		first_person_only.append(node)
	var fill := OmniLight3D.new()
	fill.name = "LobbyLight"
	fill.position = Vector3(0, 2.7, 0.3)
	fill.omni_range = 8.0
	fill.light_energy = 0.4
	fill.light_color = Color("fff3e2")
	add_child(fill)
	first_person_only.append(fill)
	# Bright, unshaded daylight behind tinted glass reads as the campus outside.
	var daylight := Geometry.box(self, "ExitDaylight", Vector3(2.3, 2.5, 0.02), Vector3(0, 1.25, 3.885), Color.WHITE)
	var outside := StandardMaterial3D.new()
	outside.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outside.albedo_color = Color("d7e8ed")
	daylight.get_child(0).material_override = outside
	first_person_only.append(daylight)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.72, 0.78, 0.45)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.08
	glass.metallic_specular = 0.9
	for x in [-0.56, 0.56]:
		var leaf := Geometry.box(self, "ExitDoorGlass", Vector3(1.04, 2.36, 0.03), Vector3(x, 1.24, 3.84), Color.WHITE)
		leaf.get_child(0).material_override = glass
		leaf.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		first_person_only.append(leaf)

## Glazed double doors to Hall A in a dark frame, with relief lettering above.
func _build_hall_entrance() -> void:
	var frame := Color("3f464b")
	Geometry.box(self, "HallDoor", Vector3(2.4, 2.6, 0.08), Vector3(0, 1.3, -3.86), frame)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.72, 0.78, 0.55)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.08
	glass.metallic_specular = 0.9
	for x in [-0.56, 0.56]:
		var leaf := Geometry.box(self, "HallDoorGlass", Vector3(1.04, 2.36, 0.03), Vector3(x, 1.24, -3.8), Color.WHITE)
		leaf.get_child(0).material_override = glass
		Geometry.box(self, "PushBar", Vector3(0.05, 0.8, 0.04), Vector3(x + (0.4 if x < 0 else -0.4), 1.1, -3.76), Color("c9d0d3"))
	Geometry.box(self, "HallDoorStile", Vector3(0.06, 2.4, 0.06), Vector3(0, 1.24, -3.79), frame)
	Buildings.letters(self, "LECTURE HALL A", Vector3(0, 2.86, -3.9), 0.0, 0.2, Color("3a4247"), 0.03)

## Timber-slat feature wall on the west side with the building name and an
## information screen showing today's class.
func _build_feature_wall() -> void:
	var wall_x := -4.9
	for index in range(24):
		var z := -3.3 + index * 0.28
		if absf(z + 1.6) < 1.2:
			continue # Behind the reception counter the wall stays plain.
		if absf(z - DISPLAY_Z) < 0.85:
			continue # A clean bay for the display: no slats cross the screen.
		var slat := Geometry.box(self, "Slat", Vector3(0.05, 2.7, 0.09), Vector3(wall_x + 0.03, 1.35, z), Color("b58558"))
		_wood(slat.get_child(0))
	Buildings.letters(self, "LEARNING CENTER", Vector3(wall_x + 0.01, 2.2, -1.6), PI / 2, 0.24, Color("3a4247"), 0.03)
	_build_display(wall_x)

const DISPLAY_Z := 1.0
const DISPLAY_SIZE := Vector2(1.32, 0.9)
var flyer_viewport: SubViewport
var flyer: Control

## Wall-mounted display (slim bezel on a bracket) showing the research seminar flyer.
func _build_display(wall_x: float) -> void:
	Geometry.box(self, "DisplayBracket", Vector3(0.03, 0.3, 0.4), Vector3(wall_x + 0.015, 1.5, DISPLAY_Z), Color("2b3034"))
	Geometry.box(self, "InfoScreen", Vector3(0.04, DISPLAY_SIZE.y + 0.05, DISPLAY_SIZE.x + 0.05), Vector3(wall_x + 0.05, 1.5, DISPLAY_Z), Color("121619"))
	flyer_viewport = SubViewport.new()
	flyer_viewport.name = "FlyerViewport"
	flyer_viewport.size = Vector2i(SeminarFlyer.SIZE)
	flyer_viewport.disable_3d = true
	flyer_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(flyer_viewport)
	flyer = SeminarFlyer.new()
	flyer_viewport.add_child(flyer)
	var screen := MeshInstance3D.new()
	screen.name = "SeminarDisplay"
	screen.mesh = QuadMesh.new()
	screen.mesh.size = DISPLAY_SIZE
	screen.position = Vector3(wall_x + 0.072, 1.5, DISPLAY_Z)
	screen.rotation.y = PI / 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = flyer_viewport.get_texture()
	material.albedo_color = Color(0.94, 0.94, 0.94)
	screen.material_override = material
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(screen)

## Reception workstation: the monitor faces the staff side (north) of the
## counter, with its lit screen, a keyboard and mouse in front of it, and an
## office chair behind the desk. Visitors see the monitor's back.
func _build_reception_workstation() -> void:
	var x := -3.35
	Geometry.box(self, "MonitorFoot", Vector3(0.22, 0.012, 0.16), Vector3(x, 1.106, -1.47), Color("33393e"))
	Geometry.box(self, "MonitorStand", Vector3(0.05, 0.2, 0.03), Vector3(x, 1.2, -1.45), Color("33393e"))
	Geometry.box(self, "MonitorBack", Vector3(0.5, 0.29, 0.03), Vector3(x, 1.39, -1.49), Color("3b4247"))
	Geometry.box(self, "ReceptionMonitor", Vector3(0.56, 0.34, 0.02), Vector3(x, 1.39, -1.515), Color("15191c"))
	var screen := Geometry.box(self, "MonitorScreen", Vector3(0.52, 0.3, 0.004), Vector3(x, 1.39, -1.527), Color.WHITE)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("cfe1e7")
	screen.get_child(0).material_override = glow
	Geometry.box(self, "ScreenHeader", Vector3(0.52, 0.04, 0.002), Vector3(x, 1.52, -1.53), Color("2f8f82"))
	for row in range(4):
		Geometry.box(self, "ScreenRow", Vector3(0.36 - row % 2 * 0.1, 0.018, 0.002), Vector3(x - 0.06 - row % 2 * 0.05, 1.46 - row * 0.05, -1.53), Color("7f969e"))
	Geometry.box(self, "Keyboard", Vector3(0.42, 0.02, 0.14), Vector3(x, 1.11, -1.86), Color("2a2f33"))
	Geometry.box(self, "KeyboardKeys", Vector3(0.39, 0.004, 0.11), Vector3(x, 1.122, -1.86), Color("41474c"))
	Geometry.box(self, "Mouse", Vector3(0.06, 0.025, 0.1), Vector3(x + 0.34, 1.112, -1.86), Color("2a2f33"))
	# Office chair behind the counter, turned toward the desk.
	var chair := Vector3(-3.3, 0, -2.78)
	Geometry.box(self, "ChairSeat", Vector3(0.5, 0.08, 0.48), chair + Vector3(0, 0.56, 0), Color("39464d"), true)
	Geometry.box(self, "ChairBack", Vector3(0.46, 0.52, 0.07), chair + Vector3(0, 0.95, -0.24), Color("39464d"))
	Geometry.box(self, "ChairColumn", Vector3(0.05, 0.44, 0.05), chair + Vector3(0, 0.3, 0), Color("22282c"))
	for angle in [0.0, PI / 2]:
		var leg := Geometry.box(self, "ChairBase", Vector3(0.62, 0.04, 0.06), chair + Vector3(0, 0.07, 0), Color("22282c"))
		leg.rotation.y = angle + 0.4

## A free-standing library bookcase with books on both faces: end panels, a
## top with a small overhang, a recessed plinth, a central back panel and five
## shelves per side, filled with books of varied size and colour: runs with
## gaps, the odd leaning volume, lying stacks and title bands on some spines.
## Deterministic per `seed`. `yaw` turns its length (local X) about the origin.
func _double_bookcase(label: String, origin: Vector3, yaw: float, seed: int) -> void:
	var kit := MeshKit.new()
	var basis := Basis(Vector3.UP, yaw)
	var at := func(local: Vector3) -> Vector3: return origin + basis * local
	var length := 1.7
	var depth := 0.64
	var height := 1.95
	# Oak carcass (wood grain), a darker recessed plinth and back panel.
	for side in [-1, 1]:
		kit.box("wood", at.call(Vector3(side * (length / 2.0 - 0.02), height / 2.0, 0)), Vector3(0.04, height, depth), Color.WHITE, basis)
	kit.box("wood", at.call(Vector3(0, height + 0.02, 0)), Vector3(length + 0.04, 0.04, depth + 0.04), Color.WHITE, basis)
	kit.box("paving", at.call(Vector3(0, 0.045, 0)), Vector3(length - 0.1, 0.09, depth - 0.1), Color("4a3a2e"), basis)
	kit.box("paving", at.call(Vector3(0, height / 2.0 + 0.05, 0)), Vector3(length - 0.08, height - 0.1, 0.018), Color("9c7d5e"), basis)
	var levels := [0.12, 0.49, 0.86, 1.23, 1.6]
	for level in levels:
		kit.box("wood", at.call(Vector3(0, level - 0.0125, 0)), Vector3(length - 0.08, 0.025, depth - 0.02), Color.WHITE, basis)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var palette := [Color("a04545"), Color("3f6690"), Color("4d7a58"), Color("c99f4e"), Color("e6dcc4"), Color("7b8088"), Color("8f6445"), Color("9a7ca6"), Color("4f8d90"), Color("d8b98a"), Color("b85a45"), Color("3a4d63"), Color("e2cf9a")]
	for face in [-1.0, 1.0]:
		for level in levels:
			var x: float = -length / 2.0 + 0.06
			var limit := length / 2.0 - 0.06
			while x < limit - 0.03:
				var roll := rng.randf()
				if roll < 0.07:
					x += rng.randf_range(0.05, 0.12) # A gap in the run.
					continue
				var color: Color = palette[rng.randi() % palette.size()].darkened(rng.randf_range(0.0, 0.12))
				if roll < 0.13 and x < limit - 0.26:
					# A small stack of books lying flat.
					var stack_y: float = level
					for index in range(rng.randi_range(2, 4)):
						var thick := rng.randf_range(0.03, 0.05)
						var w := rng.randf_range(0.2, 0.24)
						var d := rng.randf_range(0.15, 0.2)
						kit.box("paving", at.call(Vector3(x + w / 2.0, stack_y + thick / 2.0, face * (depth / 2.0 - d / 2.0 - 0.02))), Vector3(w, thick, d), palette[rng.randi() % palette.size()], basis)
						stack_y += thick
					x += 0.26
					continue
				var width := rng.randf_range(0.022, 0.055)
				var tall := rng.randf_range(0.2, 0.31)
				var book_depth := rng.randf_range(0.15, 0.22)
				var z: float = face * (depth / 2.0 - book_depth / 2.0 - 0.015)
				if roll > 0.96 and x > -limit + 0.1:
					# A volume leaning against its neighbour.
					var lean := 0.28
					kit.box("paving", at.call(Vector3(x + tall * sin(lean) / 2.0 + width / 2.0, level + tall * cos(lean) / 2.0, z)), Vector3(width, tall, book_depth), color, basis * Basis(Vector3.BACK, -lean))
					x += tall * sin(lean) + width + 0.02
					continue
				kit.box("paving", at.call(Vector3(x + width / 2.0, level + tall / 2.0, z)), Vector3(width, tall, book_depth), color, basis)
				if rng.randf() < 0.45:
					# Title band on the spine.
					kit.box("paving", at.call(Vector3(x + width / 2.0, level + tall * 0.72, z + face * (book_depth / 2.0 + 0.002))), Vector3(width * 0.8, 0.03, 0.004), color.lightened(0.45), basis)
				x += width + 0.002
	kit.solid(at.call(Vector3(0, height / 2.0, 0)), Vector3(length + 0.04, height, depth + 0.04), basis)
	kit.commit(self, label)

func _wood(mesh: MeshInstance3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/wood.gdshader")
	material.set_shader_parameter("wood_color", Color(0.5, 0.33, 0.2))
	mesh.material_override = material

func _endpoint(node_name: String, title: String, response: String, position: Vector3) -> Node3D:
	var endpoint := Endpoint.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response
	endpoint.position = position
	add_child(endpoint)
	return endpoint

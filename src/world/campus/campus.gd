extends Node3D
## Compact Southern California-inspired academic courtyard; all geometry is original.
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
const StudentScene = preload("res://npc/student.tscn")
const Config = preload("res://data/campus_config.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var dorm_door: Node3D
var lecture_door: Node3D
var noticeboard: Node3D
var student: Node3D
var sun: DirectionalLight3D
var campus_environment: Environment

func _ready() -> void:
	_build_ground()
	_build_grass()
	_build_buildings()
	_build_courtyard()
	_build_details()
	_build_interactions()
	_build_lighting()
	player = Player.instantiate()
	player.position = Config.SPAWNS.get(AppState.campus_entry, Config.SPAWNS.dorm)
	add_child(player)
	camera = Camera.new()
	camera.view_size = 19.5
	camera.follow_min = Vector2(-6, -5)
	camera.follow_max = Vector2(6, 5)
	add_child(camera)
	camera.follow(player)
	player.movement_camera = camera
	hud = HUD.new()
	hud.location_title = "MEDICAL SCHOOL  /  STUDENT COMMONS"
	hud.objective_text = "Morning • Follow the path to the Learning Center / Lecture Hall A"
	add_child(hud)
	hud.bind_player(player)

func _build_ground() -> void:
	var ground := Geometry.box(self, "Ground", Vector3(28, 0.3, 24), Vector3(0, -0.15, 0), Color("70ab75"), true)
	var lawn := ShaderMaterial.new()
	lawn.shader = preload("res://assets/grass.gdshader")
	ground.get_child(0).material_override = lawn
	Geometry.box(self, "MainWalk", Vector3(23, 0.03, 4), Vector3(0, 0.02, 2), Color("eedbb8"))
	Geometry.box(self, "ResidenceWalk", Vector3(5, 0.035, 4), Vector3(-5.8, 0.025, 5), Color("eedbb8"))
	Geometry.box(self, "LectureWalk", Vector3(4, 0.035, 10), Vector3(8, 0.025, -1), Color("eedbb8"))
	for boundary in [
		["NorthBoundary", Vector3(28, 1.0, 0.3), Vector3(0, 0.5, -12)],
		["SouthBoundary", Vector3(28, 1.0, 0.3), Vector3(0, 0.5, 12)],
		["WestBoundary", Vector3(0.3, 1.0, 24), Vector3(-14, 0.5, 0)],
		["EastBoundary", Vector3(0.3, 1.0, 24), Vector3(14, 0.5, 0)],
	]:
		Geometry.box(self, boundary[0], boundary[1], boundary[2], Color("3f725e"), true)

## Areas without lawn: paths, building footprints, planter, directory, bench,
## boundary walls and palm trunks (x0, z0, x1, z1).
const NO_GRASS := [
	[-11.6, -0.1, 11.6, 4.1], [-8.4, 2.9, -3.2, 7.1], [5.9, -6.1, 10.1, 4.1],
	[-13.2, 0.8, -7.7, 8.2], [1.8, -11.2, 12.2, -5.3], [-4.3, -5.0, 0.7, -1.4],
	[-4.5, 3.6, -2.5, 4.9], [0.2, -1.4, 3.2, -0.3], [3.0, -1.0, 4.0, 0.0],
]
const PALMS := [Vector3(-3, 0, -3.3), Vector3(-0.8, 0, -3), Vector3(11.7, 0, 6.8), Vector3(-5.8, 0, -8.3)]

func _grass_allowed(x: float, z: float) -> bool:
	if absf(x) > 13.6 or absf(z) > 11.6:
		return false
	for area in NO_GRASS:
		if x > area[0] and x < area[2] and z > area[1] and z < area[3]:
			return false
	for palm in PALMS:
		if Vector2(x - palm.x, z - palm.z).length() < 0.3:
			return false
	return true

## Dense, short turf tufts over the lawn, tinted in the same vivid greens as
## the ground shader so they add pile depth rather than separate clumps.
func _build_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260921 # Deterministic layout between runs and captures.
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var attempts := 0
	while transforms.size() < 18000 and attempts < 60000:
		attempts += 1
		var x := rng.randf_range(-13.6, 13.6)
		var z := rng.randf_range(-11.6, 11.6)
		if not _grass_allowed(x, z):
			continue
		var size := rng.randf_range(0.5, 0.8)
		var tuft_basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.28, 0.4), size))
		transforms.append(Transform3D(tuft_basis, Vector3(x, 0.0, z)))
		var tone := rng.randf()
		colors.append(Color("2f7a1f").lerp(Color("6db43a"), tone))
	var tufts := MultiMesh.new()
	tufts.transform_format = MultiMesh.TRANSFORM_3D
	tufts.use_colors = true
	tufts.mesh = _tuft_mesh()
	tufts.instance_count = transforms.size()
	for index in range(transforms.size()):
		tufts.set_instance_transform(index, transforms[index])
		tufts.set_instance_color(index, colors[index])
	var tuft_instance := MultiMeshInstance3D.new()
	tuft_instance.name = "GrassTufts"
	tuft_instance.multimesh = tufts
	tuft_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var blade_material := ShaderMaterial.new()
	blade_material.shader = preload("res://assets/grass_blades.gdshader")
	tuft_instance.material_override = blade_material
	add_child(tuft_instance)

## One tuft: five tapered blades leaning out from a shared root.
static func _tuft_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(Color.WHITE)
	for blade in range(5):
		var angle := blade * TAU / 5.0 + 0.4 * sin(blade * 2.3)
		var out := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-out.z, 0, out.x) * 0.022
		var height := 0.2 + 0.12 * fmod(blade * 0.618, 1.0)
		var root := out * 0.03
		var tip_point := out * (0.07 + (0.03 if blade % 2 else 0.0)) + Vector3(0, height, 0)
		var normal := (out + Vector3.UP).normalized()
		tool.set_normal(normal)
		tool.add_vertex(root - side)
		tool.add_vertex(root + side)
		tool.add_vertex(tip_point)
	return tool.commit()

func _build_buildings() -> void:
	Geometry.box(self, "Residence", Vector3(5, 3.7, 7), Vector3(-10.5, 1.85, 4.5), Color("efc998"), true)
	Geometry.box(self, "ResidenceRoof", Vector3(5.2, 0.16, 7.2), Vector3(-10.5, 3.78, 4.5), Color("bd6949"))
	_build_residence_facade()
	Geometry.box(self, "LearningCenter", Vector3(10, 4.5, 5), Vector3(7, 2.25, -8.5), Color("e5ddca"), true)
	Geometry.box(self, "CenterRoof", Vector3(10.4, 0.2, 5.4), Vector3(7, 4.58, -8.5), Color("b2b6ad"))
	_build_learning_center_facade()
	Geometry.box(self, "EntryCanopy", Vector3(4, 0.16, 2.1), Vector3(8, 3.15, -5.35), Color("c6ae88"))
	# Signs are mounted on the building: name above the glazing, hall name on the canopy fascia.
	Geometry.wall_sign(self, "LEARNING CENTER", Vector3(7, 3.72, -5.93), 0.0, 36, 0.013)
	Geometry.box(self, "CanopyFascia", Vector3(2.4, 0.34, 0.06), Vector3(8, 3.4, -4.33), Color("365d65"))
	Geometry.wall_sign(self, "LECTURE HALL A", Vector3(8, 3.4, -4.295), 0.0, 26, 0.009)

## East face of Cedar Residence (x = -8). Trim frames the openings instead of
## running across them; every layer sits at its own depth to avoid z-fighting.
func _build_residence_facade() -> void:
	var face := -8.0
	var trim := Color("fff0d2")
	Geometry.box(self, "ResidencePlinth", Vector3(0.08, 0.34, 7.0), Vector3(face + 0.04, 0.17, 4.5), Color("c9a57c"))
	Geometry.box(self, "ResidenceCornice", Vector3(0.1, 0.18, 7.0), Vector3(face + 0.05, 3.55, 4.5), trim)
	for z in [1.06, 7.94]:
		Geometry.box(self, "ResidenceCorner", Vector3(0.09, 3.2, 0.12), Vector3(face + 0.045, 1.94, z), trim)
	# Door: recessed leaf inside a proud frame, with a small canopy and step.
	Geometry.box(self, "ResidenceDoor", Vector3(0.04, 2.2, 1.2), Vector3(face + 0.02, 1.1, 5), Color("537b76"))
	Geometry.box(self, "ResidenceDoorGlass", Vector3(0.02, 0.9, 0.5), Vector3(face + 0.05, 1.55, 5), Color("8ba9b1"))
	Geometry.box(self, "ResidenceDoorHandle", Vector3(0.05, 0.05, 0.16), Vector3(face + 0.07, 1.05, 5.38), Color("d8c9a8"))
	for z in [4.33, 5.67]:
		Geometry.box(self, "ResidenceDoorJamb", Vector3(0.1, 2.35, 0.14), Vector3(face + 0.05, 1.175, z), trim)
	Geometry.box(self, "ResidenceDoorHead", Vector3(0.1, 0.14, 1.48), Vector3(face + 0.05, 2.35, 5), trim)
	Geometry.box(self, "ResidenceAwning", Vector3(0.7, 0.08, 1.9), Vector3(face + 0.35, 2.62, 5), Color("bd6949"))
	# Building name mounted on the wall between the awning and the cornice.
	Geometry.wall_sign(self, "CEDAR RESIDENCE", Vector3(face + 0.012, 3.05, 5), PI / 2, 30, 0.01)
	for z in [2.2, 7.0]:
		Geometry.box(self, "ResidenceWindow", Vector3(0.03, 1.1, 1.1), Vector3(face + 0.015, 2, z), Color("8ba9b1"))
		Geometry.box(self, "WindowMuntin", Vector3(0.02, 1.1, 0.05), Vector3(face + 0.04, 2, z), trim)
		Geometry.box(self, "WindowMuntin", Vector3(0.02, 0.05, 1.1), Vector3(face + 0.04, 2, z), trim)
		for offset in [-0.6, 0.6]:
			Geometry.box(self, "WindowFrame", Vector3(0.08, 1.3, 0.1), Vector3(face + 0.04, 2, z + offset), trim)
		Geometry.box(self, "WindowHead", Vector3(0.08, 0.1, 1.3), Vector3(face + 0.04, 2.6, z), trim)
		Geometry.box(self, "WindowSill", Vector3(0.16, 0.08, 1.4), Vector3(face + 0.08, 1.4, z), trim)

## South face of the Learning Center (z = -6): glazed bays, a framed double
## door in its own bay, and sills that stop at the door frame.
func _build_learning_center_facade() -> void:
	var face := -6.0
	Geometry.box(self, "GlassFacade", Vector3(8.9, 2.5, 0.04), Vector3(7, 1.75, face + 0.03), Color("4c9db1"))
	for x in [2.55, 4.25, 5.75, 10.25, 11.45]:
		Geometry.box(self, "Mullion", Vector3(0.08, 2.55, 0.08), Vector3(x, 1.75, face + 0.08), Color("ede9db"))
	for bay in [[2.55, 7.05], [8.95, 11.45]]:
		var width: float = bay[1] - bay[0]
		var center: float = (bay[0] + bay[1]) / 2.0
		Geometry.box(self, "FacadeSill", Vector3(width, 0.1, 0.16), Vector3(center, 0.45, face + 0.1), Color("faf0d8"))
		Geometry.box(self, "GlassReflection", Vector3(0.13, 2.1, 0.01), Vector3(center - width * 0.2, 1.85, face + 0.055), Color("92d1dc"))
	# Door bay: frame proud of the glass, two tinted leaves with push bars.
	for x in [7.1, 8.9]:
		Geometry.box(self, "EntryJamb", Vector3(0.12, 2.6, 0.16), Vector3(x, 1.3, face + 0.1), Color("ede9db"))
	Geometry.box(self, "EntryHeader", Vector3(1.92, 0.16, 0.16), Vector3(8, 2.62, face + 0.1), Color("ede9db"))
	for x in [7.58, 8.42]:
		Geometry.box(self, "LectureEntry", Vector3(0.78, 2.46, 0.05), Vector3(x, 1.25, face + 0.09), Color("365d65"))
		Geometry.box(self, "EntryPushBar", Vector3(0.5, 0.05, 0.04), Vector3(x, 1.05, face + 0.14), Color("c9d4cf"))
	Geometry.box(self, "EntryStile", Vector3(0.06, 2.46, 0.07), Vector3(8, 1.25, face + 0.1), Color("ede9db"))

func _build_courtyard() -> void:
	Geometry.box(self, "Planter", Vector3(4.6, 0.65, 3.2), Vector3(-1.8, 0.325, -3.2), Color("cf8967"), true)
	Geometry.box(self, "PlanterSoil", Vector3(4.3, 0.05, 2.9), Vector3(-1.8, 0.68, -3.2), Color("385c42"))
	for point in PALMS:
		_palm(point)
	Geometry.box(self, "Bench", Vector3(2.6, 0.5, 0.75), Vector3(1.7, 0.25, -0.8), Color("b87743"), true)
	Geometry.box(self, "BenchBack", Vector3(2.6, 0.55, 0.12), Vector3(1.7, 0.7, -1.1), Color("b87743"))
	Geometry.box(self, "Noticeboard", Vector3(1.6, 1.85, 0.2), Vector3(-3.5, 0.925, 4), Color("496d6b"), true)
	Geometry.box(self, "NoticePaper", Vector3(1.35, 1.12, 0.03), Vector3(-3.5, 1.12, 4.12), Color("ece1c7"))
	# Header plate on top of the directory board, above the map.
	Geometry.box(self, "DirectoryHeader", Vector3(1.9, 0.34, 0.2), Vector3(-3.5, 2.02, 4), Color("3d5c5a"))
	Geometry.wall_sign(self, "CAMPUS DIRECTORY", Vector3(-3.5, 2.02, 4.105), 0.0, 26, 0.0095)
	for id in ["alex", "sam"]:
		var actor := StudentScene.instantiate()
		actor.actor_id = id
		actor.world_zone = "campus"
		add_child(actor)
	NPCSchedule.start()
	# Wayfinding post at the edge of the walk instead of a label over the path.
	for x in [0.15, 2.25]:
		Geometry.box(self, "SignPost", Vector3(0.08, 1.45, 0.08), Vector3(x, 0.725, 4.55), Color("4a5a5f"), true)
	Geometry.box(self, "SignPanel", Vector3(2.3, 0.44, 0.05), Vector3(1.2, 1.3, 4.55), Color("2c4a50"))
	Geometry.wall_sign(self, "LEARNING CENTER  →", Vector3(1.2, 1.3, 4.578), 0.0, 28, 0.0105)

func _palm(position: Vector3) -> void:
	Geometry.box(self, "PalmTrunk", Vector3(0.32, 3.3, 0.32), position + Vector3(0, 1.65, 0), Color("9f8056"), true)
	for index in range(6):
		var angle := index * TAU / 6
		var frond := Geometry.sphere(self, Vector3(2.7, 0.14, 0.7), position + Vector3(cos(angle) * 0.65, 3.3, sin(angle) * 0.65), Color("368b63"))
		frond.rotation.y = -angle
		frond.rotation.z = 0.16

func _build_interactions() -> void:
	dorm_door = _endpoint("ResidenceInteraction", "Enter dorm", "", Vector3(-7.15, 1, 5))
	dorm_door.activated.connect(AppState.enter_dorm)
	lecture_door = _endpoint("LectureEntryInteraction", "Enter Learning Center", "", Vector3(8, 1, -4.8))
	lecture_door.activated.connect(AppState.enter_lecture_building)
	noticeboard = _endpoint("DirectoryInteraction", "Read campus directory", "Learning Center / Lecture Hall A: follow the main walk east, then turn toward the glass entrance. Cedar Residence is to the west.", Vector3(-3.5, 1, 4.65))
	student = _endpoint("StudentInteraction", "Talk to student", "Morning! Hall A is inside the Learning Center. Follow this path, then look for the glass doors.", Vector3(3.5, 1, 0.15))

func _endpoint(node_name: String, title: String, response: String, position: Vector3) -> Node3D:
	var endpoint := Endpoint.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response
	endpoint.position = position
	add_child(endpoint)
	return endpoint

func _build_lighting() -> void:
	var sky := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("91b8c6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Config.MORNING.ambient_color
	environment.ambient_light_energy = Config.MORNING.ambient_energy
	campus_environment = environment
	sky.environment = environment
	add_child(sky)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Config.MORNING.sun_rotation
	sun.light_color = Config.MORNING.sun_color
	sun.light_energy = Config.MORNING.sun_energy
	Geometry.configure_shadows(sun)
	add_child(sun)
	GameClock.minute_changed.connect(_update_daylight)
	_update_daylight()

func _update_daylight() -> void:
	var time := GameClock.snapshot()
	var hour := float(time.hour) + float(time.minute) / 60.0
	var daylight := maxf(0.0, sin((hour - 6.0) / 12.0 * PI))
	sun.light_energy = Config.MORNING.sun_energy * (0.06 + 0.94 * sqrt(daylight))
	sun.rotation_degrees.x = -10.0 - 60.0 * daylight
	campus_environment.ambient_light_energy = 0.18 + 0.38 * sqrt(daylight)
	campus_environment.background_color = Color("172a46").lerp(Color("75bfdf"), sqrt(daylight))

func _build_details() -> void:
	# Visual-only details preserve established collision and walking routes.
	for index in range(16):
		var x := -3.8 + (index % 8) * 0.55
		var z := -4.2 + (index / 8) * 1.8
		Geometry.sphere(self, Vector3(0.6, 0.5, 0.55), Vector3(x, 0.83, z), Color("3c986b") if index % 2 else Color("69b66b"))
		Geometry.sphere(self, Vector3(0.14, 0.15, 0.14), Vector3(x, 1.08, z), Color("f8ca65") if index % 3 else Color("de7898"))
	for z in [-0.03, 4.03]:
		Geometry.box(self, "WalkBorder", Vector3(23, 0.05, 0.12), Vector3(0, 0.04, z), Color("faf0d4"))
	for x in [5.2, 10.8]:
		Geometry.potted_plant(self, Vector3(x, 0, -5.1))

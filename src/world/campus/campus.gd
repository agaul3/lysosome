extends Node3D
## Compact Southern California-inspired academic courtyard; all geometry is original.
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
const Appearance = preload("res://player/appearance.gd")
const Config = preload("res://data/campus_config.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var dorm_door: Node3D
var lecture_door: Node3D
var noticeboard: Node3D
var student: Node3D
var sun: DirectionalLight3D

func _ready() -> void:
	_build_ground()
	_build_buildings()
	_build_courtyard()
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
	Geometry.box(self, "Ground", Vector3(28, 0.3, 24), Vector3(0, -0.15, 0), Color("a0aa78"), true)
	Geometry.box(self, "MainWalk", Vector3(23, 0.03, 4), Vector3(0, 0.02, 2), Color("d9cdb7"))
	Geometry.box(self, "ResidenceWalk", Vector3(5, 0.035, 4), Vector3(-5.8, 0.025, 5), Color("d9cdb7"))
	Geometry.box(self, "LectureWalk", Vector3(4, 0.035, 10), Vector3(8, 0.025, -1), Color("d9cdb7"))
	for index in range(12):
		Geometry.box(self, "PavingSeam", Vector3(0.025, 0.006, 3.9), Vector3(-11 + index * 2, 0.042, 2), Color("c1b69f"))
	for boundary in [
		["NorthBoundary", Vector3(28, 1.0, 0.3), Vector3(0, 0.5, -12)],
		["SouthBoundary", Vector3(28, 1.0, 0.3), Vector3(0, 0.5, 12)],
		["WestBoundary", Vector3(0.3, 1.0, 24), Vector3(-14, 0.5, 0)],
		["EastBoundary", Vector3(0.3, 1.0, 24), Vector3(14, 0.5, 0)],
	]:
		Geometry.box(self, boundary[0], boundary[1], boundary[2], Color("76866c"), true)

func _build_buildings() -> void:
	Geometry.box(self, "Residence", Vector3(5, 3.7, 7), Vector3(-10.5, 1.85, 4.5), Color("d3bea0"), true)
	Geometry.box(self, "ResidenceRoof", Vector3(5.2, 0.16, 7.2), Vector3(-10.5, 3.78, 4.5), Color("c38b67"))
	Geometry.box(self, "ResidenceDoor", Vector3(0.05, 2.3, 1.4), Vector3(-7.96, 1.15, 5), Color("537b76"))
	_label("CEDAR RESIDENCE", Vector3(-7.7, 3, 5), 25)
	for z in [2.2, 7.0]:
		Geometry.box(self, "ResidenceWindow", Vector3(0.04, 1.1, 1.1), Vector3(-7.95, 2, z), Color("8ba9b1"))
	Geometry.box(self, "LearningCenter", Vector3(10, 4.5, 5), Vector3(7, 2.25, -8.5), Color("e5ddca"), true)
	Geometry.box(self, "CenterRoof", Vector3(10.4, 0.2, 5.4), Vector3(7, 4.58, -8.5), Color("b2b6ad"))
	Geometry.box(self, "GlassFacade", Vector3(8.9, 2.5, 0.06), Vector3(7, 1.75, -5.96), Color("719ca8"))
	for x in [3.0, 5.5, 8.0, 10.5]:
		Geometry.box(self, "Mullion", Vector3(0.07, 2.55, 0.08), Vector3(x, 1.75, -5.89), Color("ede9db"))
	Geometry.box(self, "LectureEntry", Vector3(1.65, 2.4, 0.1), Vector3(8, 1.2, -5.8), Color("365d65"))
	Geometry.box(self, "EntryCanopy", Vector3(4, 0.16, 2.1), Vector3(8, 3.15, -5.35), Color("c6ae88"))
	_label("LEARNING CENTER", Vector3(7, 4.05, -5.8), 32)
	_label("LECTURE HALL A", Vector3(8, 2.75, -4.4), 24)

func _build_courtyard() -> void:
	Geometry.box(self, "Planter", Vector3(4.6, 0.65, 3.2), Vector3(-1.8, 0.325, -3.2), Color("baa080"), true)
	Geometry.box(self, "PlanterSoil", Vector3(4.3, 0.05, 2.9), Vector3(-1.8, 0.68, -3.2), Color("5d7052"))
	for point in [Vector3(-3, 0, -3.3), Vector3(-0.8, 0, -3), Vector3(11.7, 0, 6.8), Vector3(-5.8, 0, -8.3)]:
		_palm(point)
	Geometry.box(self, "Bench", Vector3(2.6, 0.5, 0.75), Vector3(1.7, 0.25, -0.8), Color("a88360"), true)
	Geometry.box(self, "BenchBack", Vector3(2.6, 0.55, 0.12), Vector3(1.7, 0.7, -1.1), Color("a88360"))
	Geometry.box(self, "Noticeboard", Vector3(1.6, 1.85, 0.2), Vector3(-3.5, 0.925, 4), Color("496d6b"), true)
	Geometry.box(self, "NoticePaper", Vector3(1.35, 1.12, 0.03), Vector3(-3.5, 1.12, 4.12), Color("ece1c7"))
	_label("CAMPUS DIRECTORY", Vector3(-3.5, 2.15, 4), 22)
	# Static students establish scale and basic interaction, not Milestone 4 autonomy.
	for person in [[Vector3(3.5, 0, -0.5), "indigo"], [Vector3(-0.3, 0, -0.9), "clay"]]:
		var body := Geometry.box(self, "Student", Vector3(0.55, 1.7, 0.55), person[0] + Vector3(0, 0.85, 0), Color.WHITE, true)
		body.get_child(0).hide()
		var visual := Appearance.new()
		visual.position.y = -0.85
		body.add_child(visual)
		visual.apply_preset(person[1])
		visual.rotation.y = PI
	_label("LEARNING CENTER  →", Vector3(1, 0.16, 3), 23)

func _palm(position: Vector3) -> void:
	Geometry.box(self, "PalmTrunk", Vector3(0.32, 3.3, 0.32), position + Vector3(0, 1.65, 0), Color("9f8056"), true)
	for index in range(6):
		var angle := index * TAU / 6
		var frond := Geometry.box(self, "PalmFrond", Vector3(2.5, 0.12, 0.52), position + Vector3(cos(angle) * 0.65, 3.3, sin(angle) * 0.65), Color("5f8664"))
		frond.rotation.y = -angle

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

func _label(text: String, position: Vector3, font_size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.font_size = font_size
	label.pixel_size = 0.015
	label.no_depth_test = true
	label.outline_size = 4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _build_lighting() -> void:
	var sky := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("91b8c6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Config.MORNING.ambient_color
	environment.ambient_light_energy = Config.MORNING.ambient_energy
	sky.environment = environment
	add_child(sky)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Config.MORNING.sun_rotation
	sun.light_color = Config.MORNING.sun_color
	sun.light_energy = Config.MORNING.sun_energy
	sun.shadow_enabled = true
	add_child(sun)

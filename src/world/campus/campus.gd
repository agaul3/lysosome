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
	Geometry.box(self, "Ground", Vector3(28, 0.3, 24), Vector3(0, -0.15, 0), Color("70ab75"), true)
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

func _build_buildings() -> void:
	Geometry.box(self, "Residence", Vector3(5, 3.7, 7), Vector3(-10.5, 1.85, 4.5), Color("efc998"), true)
	Geometry.box(self, "ResidenceRoof", Vector3(5.2, 0.16, 7.2), Vector3(-10.5, 3.78, 4.5), Color("bd6949"))
	Geometry.box(self, "ResidenceDoor", Vector3(0.05, 2.3, 1.4), Vector3(-7.96, 1.15, 5), Color("537b76"))
	_label("CEDAR RESIDENCE", Vector3(-7.7, 3, 5), 25)
	for z in [2.2, 7.0]:
		Geometry.box(self, "ResidenceWindow", Vector3(0.04, 1.1, 1.1), Vector3(-7.95, 2, z), Color("8ba9b1"))
	Geometry.box(self, "LearningCenter", Vector3(10, 4.5, 5), Vector3(7, 2.25, -8.5), Color("e5ddca"), true)
	Geometry.box(self, "CenterRoof", Vector3(10.4, 0.2, 5.4), Vector3(7, 4.58, -8.5), Color("b2b6ad"))
	Geometry.box(self, "GlassFacade", Vector3(8.9, 2.5, 0.06), Vector3(7, 1.75, -5.96), Color("4c9db1"))
	for x in [3.0, 5.5, 8.0, 10.5]:
		Geometry.box(self, "Mullion", Vector3(0.07, 2.55, 0.08), Vector3(x, 1.75, -5.89), Color("ede9db"))
	Geometry.box(self, "LectureEntry", Vector3(1.65, 2.4, 0.1), Vector3(8, 1.2, -5.8), Color("365d65"))
	Geometry.box(self, "EntryCanopy", Vector3(4, 0.16, 2.1), Vector3(8, 3.15, -5.35), Color("c6ae88"))
	_label("LEARNING CENTER", Vector3(7, 4.05, -5.8), 32)
	_label("LECTURE HALL A", Vector3(8, 2.75, -4.4), 24)

func _build_courtyard() -> void:
	Geometry.box(self, "Planter", Vector3(4.6, 0.65, 3.2), Vector3(-1.8, 0.325, -3.2), Color("cf8967"), true)
	Geometry.box(self, "PlanterSoil", Vector3(4.3, 0.05, 2.9), Vector3(-1.8, 0.68, -3.2), Color("385c42"))
	for point in [Vector3(-3, 0, -3.3), Vector3(-0.8, 0, -3), Vector3(11.7, 0, 6.8), Vector3(-5.8, 0, -8.3)]:
		_palm(point)
	Geometry.box(self, "Bench", Vector3(2.6, 0.5, 0.75), Vector3(1.7, 0.25, -0.8), Color("b87743"), true)
	Geometry.box(self, "BenchBack", Vector3(2.6, 0.55, 0.12), Vector3(1.7, 0.7, -1.1), Color("b87743"))
	Geometry.box(self, "Noticeboard", Vector3(1.6, 1.85, 0.2), Vector3(-3.5, 0.925, 4), Color("496d6b"), true)
	Geometry.box(self, "NoticePaper", Vector3(1.35, 1.12, 0.03), Vector3(-3.5, 1.12, 4.12), Color("ece1c7"))
	_label("CAMPUS DIRECTORY", Vector3(-3.5, 2.15, 4), 22)
	for id in ["alex", "sam"]:
		var actor := StudentScene.instantiate()
		actor.actor_id = id
		actor.world_zone = "campus"
		add_child(actor)
	NPCSchedule.start()
	_label("LEARNING CENTER  →", Vector3(1, 0.16, 3), 23)

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

func _label(text: String, position: Vector3, font_size: int) -> void:
	Geometry.nameplate(self, text, position, maxi(font_size, 28), 0.013)

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
	for x in [3.0, 5.5, 8.0, 10.5]:
		Geometry.box(self, "FacadeSill", Vector3(2.3, 0.1, 0.18), Vector3(x, 0.5, -5.84), Color("faf0d8"))
		Geometry.box(self, "GlassReflection", Vector3(0.13, 2.2, 0.02), Vector3(x + 0.5, 1.8, -5.91), Color("92d1dc"))
	for z in [1.4, 2.8, 4.2, 5.6, 7.0]:
		Geometry.box(self, "ResidenceTrim", Vector3(0.06, 0.06, 6.8), Vector3(-7.94, z * 0.4, 4.5), Color("ffe2b3"))
	for index in range(16):
		var x := -3.8 + (index % 8) * 0.55
		var z := -4.2 + (index / 8) * 1.8
		Geometry.sphere(self, Vector3(0.6, 0.5, 0.55), Vector3(x, 0.83, z), Color("3c986b") if index % 2 else Color("69b66b"))
		Geometry.sphere(self, Vector3(0.14, 0.15, 0.14), Vector3(x, 1.08, z), Color("f8ca65") if index % 3 else Color("de7898"))
	for z in [-0.03, 4.03]:
		Geometry.box(self, "WalkBorder", Vector3(23, 0.05, 0.12), Vector3(0, 0.04, z), Color("faf0d4"))
	for x in [5.2, 10.8]:
		Geometry.potted_plant(self, Vector3(x, 0, -5.1))

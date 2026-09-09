extends Node3D
## Small entry lobby proves campus-to-building traversal; lecture hall comes later.
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var exit_door: Node3D
var hall_door: Node3D

func _ready() -> void:
	Geometry.box(self, "Floor", Vector3(10, 0.2, 8), Vector3(0, -0.1, 0), Color("d5d2c4"), true)
	for wall in [[Vector3(10, 3, 0.2), Vector3(0, 1.5, -4)], [Vector3(0.2, 3, 8), Vector3(-5, 1.5, 0)], [Vector3(0.2, 3, 8), Vector3(5, 1.5, 0)], [Vector3(10, 3, 0.2), Vector3(0, 1.5, 4)]]:
		var body := Geometry.box(self, "Wall", wall[0], wall[1], Color("dce2d9"), true)
		if wall[1].x > 0 or wall[1].z > 0:
			body.get_child(0).scale.y = 0.05
			body.get_child(0).position.y = -1.4
	Geometry.box(self, "HallDoor", Vector3(2.2, 2.5, 0.12), Vector3(0, 1.25, -3.8), Color("577d78"))
	Geometry.box(self, "ExitDoor", Vector3(1.9, 2.5, 0.12), Vector3(0, 1.25, 3.8), Color("719ca8"))
	Geometry.box(self, "Reception", Vector3(2.4, 1.1, 1.0), Vector3(-3.1, 0.55, -1.6), Color("bc9e79"), true)
	Geometry.box(self, "WaitingBench", Vector3(0.8, 0.55, 2.6), Vector3(3.5, 0.275, -0.3), Color("56757b"), true)
	var label := Label3D.new()
	label.text = "LECTURE HALL A"
	label.position = Vector3(0, 2.85, -3.6)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.pixel_size = 0.012
	label.no_depth_test = true
	add_child(label)
	exit_door = _endpoint("CampusExit", "Return to campus", "", Vector3(0, 1, 3))
	exit_door.activated.connect(AppState.enter_campus.bind("lecture_building"))
	hall_door = _endpoint("HallA", "Inspect Hall A", "You found Lecture Hall A. Seating and the pharmacodynamics lecture will arrive in a later milestone.", Vector3(0, 1, -3))
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("263c47")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7e2e0")
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 0.8
	add_child(light)
	player = Player.instantiate()
	player.position = Vector3(0, 0.05, 1.8)
	add_child(player)
	camera = Camera.new()
	add_child(camera)
	player.movement_camera = camera
	hud = HUD.new()
	hud.location_title = "LEARNING CENTER  /  GROUND FLOOR"
	hud.objective_text = "You reached the lecture building • Hall A is straight ahead"
	add_child(hud)
	hud.bind_player(player)

func _endpoint(node_name: String, title: String, response: String, position: Vector3) -> Node3D:
	var endpoint := Endpoint.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response
	endpoint.position = position
	add_child(endpoint)
	return endpoint

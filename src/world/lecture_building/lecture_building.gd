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
	Geometry.box(self, "Floor", Vector3(10, 0.2, 8), Vector3(0, -0.1, 0), Color("526571"), true)
	for wall in [[Vector3(10, 3, 0.2), Vector3(0, 1.5, -4)], [Vector3(0.2, 3, 8), Vector3(-5, 1.5, 0)], [Vector3(0.2, 3, 8), Vector3(5, 1.5, 0)], [Vector3(10, 3, 0.2), Vector3(0, 1.5, 4)]]:
		var body := Geometry.box(self, "Wall", wall[0], wall[1], Color("e7eee5"), true)
		body.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if wall[1].x > 0 or wall[1].z > 0:
			body.get_child(0).scale.y = 0.05
			body.get_child(0).position.y = -1.4
	Geometry.box(self, "HallDoor", Vector3(2.2, 2.5, 0.12), Vector3(0, 1.25, -3.8), Color("268b86"))
	Geometry.box(self, "ExitDoor", Vector3(1.9, 2.5, 0.12), Vector3(0, 1.25, 3.8), Color("4c9db1"))
	Geometry.box(self, "Reception", Vector3(2.4, 1.1, 1.0), Vector3(-3.1, 0.55, -1.6), Color("bc9e79"), true)
	# Central corridor stays open for both player and scheduled NPC navigation.
	Geometry.vending_machine(self, Vector3(2.35, 0, -3.35), false)
	Geometry.vending_machine(self, Vector3(3.75, 0, -3.35), true)
	Geometry.bookshelf(self, Vector3(-3.5, 0, 2.7))
	Geometry.box(self, "SofaBase", Vector3(1.15, 0.4, 2.7), Vector3(3.65, 0.25, 0.4), Color("3c676a"), true)
	Geometry.box(self, "SofaBack", Vector3(0.25, 0.95, 2.7), Vector3(4.15, 0.75, 0.4), Color("578b88"))
	for z in [-0.5, 0.4, 1.3]:
		Geometry.box(self, "SeatCushion", Vector3(0.92, 0.25, 0.82), Vector3(3.57, 0.57, z), Color("75a39a"))
		Geometry.box(self, "BackCushion", Vector3(0.22, 0.55, 0.82), Vector3(3.95, 0.98, z), Color("69998f"))
	for z in [-1.02, 1.82]:
		Geometry.box(self, "SofaArm", Vector3(1.2, 0.55, 0.18), Vector3(3.65, 0.72, z), Color("578b88"))
	Geometry.wall_sign(self, "LECTURE HALL A", Vector3(0, 2.8, -3.885), 0.0, 28, 0.01)
	exit_door = _endpoint("CampusExit", "Return to campus", "", Vector3(0, 1, 3))
	exit_door.activated.connect(AppState.enter_campus.bind("lecture_building"))
	hall_door = _endpoint("HallA", "Enter Hall A", "", Vector3(0, 1, -3))
	hall_door.activated.connect(AppState.enter_lecture_hall)
	var actor := preload("res://npc/student.tscn").instantiate()
	actor.world_zone = "lecture_building"
	add_child(actor)
	Geometry.potted_plant(self, Vector3(-4.3, 0, -3.2))
	Geometry.box(self, "WallAccent", Vector3(0.08, 0.8, 7.5), Vector3(-4.86 if name == "LectureBuilding" else -5.86, 0.8, 0), Color("388f8b"))
	Geometry.accent_light(self, Vector3(0, 2.7, -2), Color("b7e5ed"), 0.2, 7.0)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("263c47")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7e2e0")
	environment.ambient_light_energy = 0.42
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

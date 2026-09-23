extends Node3D
## Only the geometry needed to witness NPC arrival/seating. No player seating or lecture.
const Geometry = preload("res://world/geometry.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var exit_door: Node3D
var actor: Node3D

func _ready() -> void:
	Geometry.box(self, "Floor", Vector3(12, 0.2, 10), Vector3(0, -0.1, 0), Color("c8d5cc"), true)
	for wall in [[Vector3(12, 3, 0.2), Vector3(0, 1.5, -5)], [Vector3(0.2, 3, 10), Vector3(-6, 1.5, 0)], [Vector3(0.2, 3, 10), Vector3(6, 1.5, 0)], [Vector3(12, 3, 0.2), Vector3(0, 1.5, 5)]]:
		var body := Geometry.box(self, "Wall", wall[0], wall[1], Color("e7eee5"), true)
		body.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if wall[1].x > 0 or wall[1].z > 0:
			body.get_child(0).scale.y = 0.05
			body.get_child(0).position.y = -1.4
	Geometry.box(self, "LectureDisplay", Vector3(5, 1.8, 0.1), Vector3(0, 1.9, -4.8), Color("34535c"))
	for x in [-3.5, -2.0, 2.0, 3.5]:
		for z in [-2.0, 1.0]:
			Geometry.box(self, "Seat", Vector3(0.8, 0.5, 0.7), Vector3(x, 0.25, z), Color("387e92"), true)
			Geometry.box(self, "SeatBack", Vector3(0.8, 0.65, 0.12), Vector3(x, 0.85, z + 0.3), Color("387e92"))
	exit_door = preload("res://world/interactable.gd").new()
	exit_door.display_name = "Return to lobby"
	exit_door.position = Vector3(0, 1, 4.2)
	exit_door.activated.connect(AppState.enter_lecture_building)
	add_child(exit_door)
	Geometry.potted_plant(self, Vector3(-4.3, 0, -3.2))
	Geometry.box(self, "WallAccent", Vector3(0.08, 0.8, 7.5), Vector3(-4.86 if name == "LectureBuilding" else -5.86, 0.8, 0), Color("388f8b"))
	Geometry.accent_light(self, Vector3(0, 2.7, -2), Color("b7e5ed"), 0.45, 7.0)
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
	light.light_energy = 0.65
	light.light_color = Color("ffe4bd")
	Geometry.configure_shadows(light)
	add_child(light)
	actor = preload("res://npc/student.tscn").instantiate()
	actor.world_zone = "lecture_hall"
	add_child(actor)
	player = preload("res://player/player.tscn").instantiate()
	player.position = Vector3(-0.7, 0.05, 3.3)
	add_child(player)
	camera = preload("res://world/exploration_camera.gd").new()
	camera.view_size = 18
	add_child(camera)
	player.movement_camera = camera
	hud = preload("res://ui/dorm_ui.gd").new()
	hud.location_title = "LECTURE HALL A  /  NPC SEATING PROTOTYPE"
	hud.objective_text = "Observe the arriving student • Lecture gameplay arrives in a later milestone"
	add_child(hud)
	hud.bind_player(player)

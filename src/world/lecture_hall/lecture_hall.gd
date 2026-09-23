extends Node3D
## Hall A: rows of solid chairs, seated classmates, the professor's lectern and Alex's saved seat.
## Any free chair can be used by the player; the lecture itself arrives later in Milestone 7.
const Geometry = preload("res://world/geometry.gd")
const Appearance = preload("res://player/appearance.gd")
const Seat = preload("res://world/seat.gd")
const ROW_Z := [-2.0, 0.0, 2.0]
const SEAT_X := [-4.5, -3.0, -1.5, 1.5, 3.0, 4.5]
const ALEX_SEAT := Vector2(1.5, -2.0)
const CLASSMATES := {
	Vector2(-3.0, -2.0): "teal",
	Vector2(4.5, -2.0): "plum",
	Vector2(-1.5, 0.0): "clay",
	Vector2(3.0, 0.0): "sage",
	Vector2(-4.5, 2.0): "plum",
	Vector2(1.5, 2.0): "teal",
}
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var exit_door: Node3D
var actor: Node3D
var professor: Node3D
var seats: Array[Node3D] = []
var alex_seat: Node3D

func _ready() -> void:
	Geometry.box(self, "Floor", Vector3(12, 0.2, 10), Vector3(0, -0.1, 0), Color("c8d5cc"), true)
	for wall in [[Vector3(12, 3, 0.2), Vector3(0, 1.5, -5)], [Vector3(0.2, 3, 10), Vector3(-6, 1.5, 0)], [Vector3(0.2, 3, 10), Vector3(6, 1.5, 0)], [Vector3(12, 3, 0.2), Vector3(0, 1.5, 5)]]:
		var body := Geometry.box(self, "Wall", wall[0], wall[1], Color("e7eee5"), true)
		body.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if wall[1].x > 0 or wall[1].z > 0:
			body.get_child(0).scale.y = 0.05
			body.get_child(0).position.y = -1.4
	Geometry.box(self, "LectureDisplay", Vector3(5, 1.8, 0.1), Vector3(0.6, 1.9, -4.84), Color("34535c"))
	Geometry.box(self, "DisplayFrame", Vector3(5.2, 0.08, 0.14), Vector3(0.6, 0.97, -4.82), Color("22363d"))
	Geometry.nameplate(self, "PHARMACODYNAMICS", Vector3(0.6, 2.45, -4.7), 26, 0.01)
	Geometry.box(self, "Lectern", Vector3(0.7, 1.1, 0.5), Vector3(-3.4, 0.55, -3.7), Color("71533f"), true)
	Geometry.box(self, "LecternTop", Vector3(0.8, 0.06, 0.6), Vector3(-3.4, 1.12, -3.72), Color("c69d72"))
	professor = Appearance.new()
	professor.name = "Professor"
	professor.position = Vector3(-3.4, 0, -4.3)
	professor.rotation.y = PI
	add_child(professor)
	professor.apply_preset("professor")
	for row in ROW_Z:
		for x in SEAT_X:
			var seat = Seat.new()
			var key := Vector2(x, row)
			seat.name = "Seat_R%d_C%d" % [ROW_Z.find(row), SEAT_X.find(x)]
			seat.position = Vector3(x, 0, row)
			seat.occupied = CLASSMATES.has(key) or key == ALEX_SEAT
			seat.occupant_preset = CLASSMATES.get(key, "")
			add_child(seat)
			seats.append(seat)
			if key == ALEX_SEAT:
				alex_seat = seat
				# A jacket over the backrest marks the seat Alex has saved.
				Geometry.box(seat, "SavedJacket", Vector3(0.5, 0.1, 0.14), Vector3(0, 0.93, 0.3), Color("a8584e"))
			else:
				seat.sit_requested.connect(_on_sit_requested)
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
	actor.seat = alex_seat
	add_child(actor)
	player = preload("res://player/player.tscn").instantiate()
	player.position = Vector3(-0.7, 0.05, 3.3)
	add_child(player)
	camera = preload("res://world/exploration_camera.gd").new()
	camera.view_size = 16
	add_child(camera)
	player.movement_camera = camera
	hud = preload("res://ui/dorm_ui.gd").new()
	hud.location_title = "LECTURE HALL A"
	hud.objective_text = "Find an open seat for Pharmacodynamics"
	add_child(hud)
	hud.bind_player(player)

func _on_sit_requested(seat: Node3D) -> void:
	player.seating.request(seat)

extends Node3D
## Shared distance-driven procedural gait; only visuals move, never collision.
const Geometry = preload("res://world/geometry.gd")
const Presets = preload("res://data/character_presets.gd")
var preset_id: String
var hips: Array[Node3D] = []
var shoulders: Array[Node3D] = []
var body: Node3D
var gait_phase := 0.0
var gait_weight := 0.0
var seated_pose := false

func apply_preset(id: String) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	hips.clear()
	shoulders.clear()
	gait_weight = 0.0
	gait_phase = 0.0
	seated_pose = false
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var data := Presets.get_preset(id)
	preset_id = data.id
	var skin := Color(data.skin)
	var hair := Color(data.hair)
	var shirt := Color(data.shirt)
	var pants := Color(data.pants)
	Geometry.box(body, "Torso", Vector3(0.51, 0.57, 0.3), Vector3(0, 0.94, 0), shirt)
	for side in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(side * 0.14, 0.64, 0)
		body.add_child(hip)
		hips.append(hip)
		Geometry.box(hip, "Leg", Vector3(0.19, 0.54, 0.23), Vector3(0, -0.27, 0), pants)
		Geometry.box(hip, "Shoe", Vector3(0.22, 0.12, 0.33), Vector3(0, -0.55, -0.045), Color("efe7d5"))
		var shoulder := Node3D.new()
		shoulder.position = Vector3(side * 0.34, 1.17, 0)
		body.add_child(shoulder)
		shoulders.append(shoulder)
		Geometry.box(shoulder, "Sleeve", Vector3(0.17, 0.37, 0.25), Vector3(0, -0.19, 0), shirt)
		Geometry.sphere(shoulder, Vector3(0.16, 0.24, 0.17), Vector3(0, -0.44, 0), skin)
	Geometry.sphere(body, Vector3(0.43, 0.48, 0.4), Vector3(0, 1.46, 0), skin)
	Geometry.sphere(body, Vector3(0.46, 0.25, 0.43), Vector3(0, 1.65, 0.035), hair)
	if data.hair_style == 0:
		for side in [-1, 1]:
			Geometry.sphere(body, Vector3(0.22, 0.24, 0.3), Vector3(side * 0.18, 1.6, 0.07), hair)
	elif data.hair_style == 2:
		Geometry.box(body, "Bob", Vector3(0.46, 0.38, 0.19), Vector3(0, 1.44, 0.17), hair)
	elif data.hair_style == 3:
		Geometry.sphere(body, Vector3(0.25, 0.25, 0.25), Vector3(0, 1.76, 0.15), hair)
	Geometry.box(body, "Backpack", Vector3(0.35, 0.42, 0.17), Vector3(0, 0.99, 0.23), Color("384f59"))
	Geometry.box(body, "StudentBadge", Vector3(0.1, 0.15, 0.025), Vector3(-0.12, 1.07, -0.17), Color("eee9d9"))

func set_seated(seated: bool) -> void:
	apply_preset(preset_id)
	seated_pose = seated
	if seated:
		for hip in hips:
			hip.rotation.x = PI / 2
			# Thigh projects toward the desk; lower leg hangs from the knee.
			var leg := hip.get_node("Leg")
			leg.scale.y = 0.6
			leg.position.y = -0.16
			var shoe := hip.get_node("Shoe")
			shoe.position = Vector3(0, -0.34, 0.4)
			shoe.rotation.x = -PI / 2
			var shin := Geometry.box(hip, "Shin", Vector3(0.19, 0.4, 0.21), Vector3(0, -0.34, 0.2), Color(Presets.get_preset(preset_id).pants))
			shin.rotation.x = PI / 2

func animate_motion(distance: float, delta: float) -> void:
	if seated_pose or not is_instance_valid(body) or delta <= 0:
		return
	var speed := distance / delta
	var target := clampf(speed / 1.8, 0.0, 1.0)
	gait_weight = move_toward(gait_weight, target, delta * 8.0)
	gait_phase = fmod(gait_phase + distance * TAU / 1.65, TAU)
	for index in range(2):
		var stride := sin(gait_phase + index * PI) * gait_weight
		hips[index].rotation.x = stride * 0.58
		shoulders[index].rotation.x = -stride * 0.42
	body.position.y = absf(cos(gait_phase)) * 0.035 * gait_weight
	body.rotation.z = sin(gait_phase) * 0.025 * gait_weight
	body.rotation.x = -0.035 * gait_weight

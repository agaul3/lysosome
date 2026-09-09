extends Node3D
## Visual child can later host an AnimationTree without changing locomotion.
const Geometry = preload("res://world/geometry.gd")
const Presets = preload("res://data/character_presets.gd")
var preset_id: String

func apply_preset(id: String) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var data := Presets.get_preset(id)
	preset_id = data.id
	var skin := Color(data.skin)
	var hair := Color(data.hair)
	var shirt := Color(data.shirt)
	var pants := Color(data.pants)
	Geometry.box(self, "Torso", Vector3(0.51, 0.57, 0.3), Vector3(0, 0.94, 0), shirt)
	for side in [-1, 1]:
		Geometry.box(self, "Leg", Vector3(0.19, 0.54, 0.23), Vector3(side * 0.14, 0.37, 0), pants)
		Geometry.box(self, "Shoe", Vector3(0.22, 0.12, 0.33), Vector3(side * 0.14, 0.09, -0.045), Color("efe7d5"))
		Geometry.box(self, "Sleeve", Vector3(0.17, 0.37, 0.25), Vector3(side * 0.34, 0.98, 0), shirt)
		Geometry.sphere(self, Vector3(0.16, 0.24, 0.17), Vector3(side * 0.34, 0.73, 0), skin)
	Geometry.sphere(self, Vector3(0.43, 0.48, 0.4), Vector3(0, 1.46, 0), skin)
	Geometry.sphere(self, Vector3(0.46, 0.25, 0.43), Vector3(0, 1.65, 0.035), hair)
	if data.hair_style == 0:
		for side in [-1, 1]:
			Geometry.sphere(self, Vector3(0.22, 0.24, 0.3), Vector3(side * 0.18, 1.6, 0.07), hair)
	elif data.hair_style == 2:
		Geometry.box(self, "Bob", Vector3(0.46, 0.38, 0.19), Vector3(0, 1.44, 0.17), hair)
	elif data.hair_style == 3:
		Geometry.sphere(self, Vector3(0.25, 0.25, 0.25), Vector3(0, 1.76, 0.15), hair)
	Geometry.box(self, "Backpack", Vector3(0.35, 0.42, 0.17), Vector3(0, 0.99, 0.23), Color("384f59"))
	Geometry.box(self, "StudentBadge", Vector3(0.1, 0.15, 0.025), Vector3(-0.12, 1.07, -0.17), Color("eee9d9"))

extends Node3D
## A pair of sliding door leaves that part to the sides: the hospital's
## automatic entrance and its elevator cars. The doorway's collider is solid
## only while the doors are closed. With `auto_target` set, the doors open
## whenever that node comes within `auto_radius` (the automatic entrance).
## Local frame: the doorway spans x ±width/2 in the plane z = 0.
signal opened
signal closed
const Geometry = preload("res://world/geometry.gd")
var width := 1.3
var height := 2.36
var leaf_color := Color("a3aaaf")
var glass := false
var auto_target: Node3D
var auto_radius := 3.4
var open_amount := 0.0
var target_open := 0.0
var speed := 1.8
var leaves: Array[Node3D] = []
var blocker: CollisionShape3D

func _init(door_width := 1.3, door_height := 2.36, glazed := false) -> void:
	width = door_width
	height = door_height
	glass = glazed

func _ready() -> void:
	for side in [-1, 1]:
		var leaf := Node3D.new()
		leaf.name = "Leaf"
		add_child(leaf)
		var frame := Geometry.box(leaf, "LeafFrame", Vector3(width / 2.0 - 0.01, height, 0.05), Vector3.ZERO, Color("3a4045") if glass else leaf_color)
		if glass:
			var pane := Geometry.box(leaf, "LeafGlass", Vector3(width / 2.0 - 0.1, height - 0.16, 0.052), Vector3.ZERO, Color.WHITE)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.72, 0.84, 0.88, 0.32)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.1
			material.metallic_specular = 0.9
			pane.get_child(0).material_override = material
			pane.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			frame.get_child(0).scale = Vector3(1, 1, 0.6)
		if not glass:
			var steel := StandardMaterial3D.new()
			steel.albedo_color = leaf_color
			steel.metallic = 0.55
			steel.roughness = 0.38
			frame.get_child(0).material_override = steel
			# The seam where the leaves meet.
			Geometry.box(leaf, "LeafEdge", Vector3(0.012, height, 0.052), Vector3(-side * (width / 4.0 - 0.006), 0, 0), Color("6d7479"))
		leaves.append(leaf)
	var body := StaticBody3D.new()
	body.name = "DoorwayBlocker"
	blocker = CollisionShape3D.new()
	blocker.shape = BoxShape3D.new()
	blocker.shape.size = Vector3(width, height, 0.2)
	blocker.position.y = height / 2.0
	body.add_child(blocker)
	add_child(body)
	_apply()

func open() -> void:
	target_open = 1.0

func close() -> void:
	target_open = 0.0

func is_open() -> bool:
	return open_amount >= 0.99

func is_closed() -> bool:
	return open_amount <= 0.01

## Snaps to a state without animating (scene load, elevator arrival).
func set_open_now(value: bool) -> void:
	target_open = 1.0 if value else 0.0
	open_amount = target_open
	_apply()

func _process(delta: float) -> void:
	if is_instance_valid(auto_target):
		var local := to_local(auto_target.global_position)
		target_open = 1.0 if Vector2(local.x, local.z).length() < auto_radius else 0.0
	if is_equal_approx(open_amount, target_open):
		return
	var was_open := is_open()
	var was_closed := is_closed()
	open_amount = move_toward(open_amount, target_open, delta * speed)
	_apply()
	if is_open() and not was_open:
		opened.emit()
	elif is_closed() and not was_closed:
		closed.emit()

func _apply() -> void:
	var eased := open_amount * open_amount * (3.0 - 2.0 * open_amount)
	for index in range(leaves.size()):
		var side := -1.0 if index == 0 else 1.0
		leaves[index].position = Vector3(side * (width / 4.0 + eased * (width / 2.0 - 0.04)), height / 2.0, 0)
	if is_instance_valid(blocker):
		blocker.disabled = open_amount > 0.6

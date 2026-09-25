extends Node3D
## A box ambulance (the Type III ambulances of city EMS): a van cab and a
## raised patient module, white with a red stripe, the six-armed Star of Life,
## a roof light bar and corner warning lights, and rear doors that swing open
## for the stretcher. Used on the campus street and in the ED's ambulance bay.
##
## It drives along a route of waypoints with rounded corners: accelerating to
## a cruise speed, braking to stop at the end (or for the student standing in
## its way), turning its wheels as it rolls. Local forward is −Z, like every
## figure; the rear doors are at +Z. Solid to the player (NPC layer).
signal arrived
const Props = preload("res://world/hospital/hospital_props.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const LENGTH := 6.9
const WIDTH := 2.36
const RED := Color("c3302b")
const BODY := Color("f4f5f2")
## Where the stretcher comes out: just behind the rear bumper (local).
const REAR := Vector3(0, 0, 3.55)
@export var unit_label := "EMS 7"
var cruise := 8.0
var accel := 3.0
var brake := 3.2
var speed := 0.0
var driving := false
## Backing up (into the ambulance bay): it moves along the route rear first.
var reversing := false
var route := PackedVector3Array()
var lengths := PackedFloat32Array()
var travel := 0.0
var total := 0.0
var lights_on := false
var light_time := 0.0
var flashers: Array[MeshInstance3D] = []
var flash_materials: Array[StandardMaterial3D] = []
var wheels: Array[Node3D] = []
var rear_doors: Array[Node3D] = []
var door_open := 0.0
var door_target := 0.0
var blocker: AnimatableBody3D
## Who it will not drive into (the player); it stops short instead.
var watch: Node3D
var blocked := false
## Metres driven (tests confirm it really moves).
var distance_driven := 0.0

func _ready() -> void:
	var kit := Props.NodeKit.new()
	_body(kit)
	kit.commit(self, "AmbulanceBody")
	for side in [-1, 1]:
		# Star of Life and unit number on both sides of the module.
		_star(Vector3(side * (WIDTH / 2.0 + 0.012), 1.95, 0.9), side)
		Buildings.letters(self, unit_label, Vector3(side * (WIDTH / 2.0 + 0.004), 1.62, 2.35), side * PI / 2, 0.2, RED, 0.02)
		Buildings.letters(self, "AMBULANCE", Vector3(side * (WIDTH / 2.0 + 0.004), 2.45, 1.05), side * PI / 2, 0.24, RED, 0.02)
	_build_wheels()
	_build_doors()
	_build_lights()
	blocker = AnimatableBody3D.new()
	blocker.name = "Blocker"
	blocker.collision_layer = 4
	blocker.collision_mask = 0
	blocker.sync_to_physics = false
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(WIDTH, 2.8, LENGTH)
	shape.position.y = 1.4
	blocker.add_child(shape)
	add_child(blocker)

func _body(k) -> void:
	var dark := Color("2b2f33")
	# Cab: hood, doors and windscreen.
	k.box("facade", Vector3(0, 0.95, -2.5), Vector3(2.2, 1.1, 1.8), BODY)
	k.box("facade", Vector3(0, 1.85, -2.05), Vector3(2.12, 0.9, 1.1), BODY)
	k.box("tinted", Vector3(0, 1.82, -2.62), Vector3(1.96, 0.66, 0.04), Color("30414a"), "always", false, Basis(Vector3.RIGHT, -0.22))
	for side in [-1, 1]:
		k.box("tinted", Vector3(side * 1.065, 1.86, -2.0), Vector3(0.02, 0.56, 0.84), Color("30414a"))
		k.box("facade", Vector3(side * 1.2, 1.9, -2.55), Vector3(0.14, 0.22, 0.08), dark)
	k.box("facade", Vector3(0, 0.78, -3.42), Vector3(1.9, 0.5, 0.06), dark)
	for side in [-1, 1]:
		k.box("light", Vector3(side * 0.74, 1.02, -3.42), Vector3(0.3, 0.16, 0.04), Color("f6f1dc"))
	k.box("metal", Vector3(0, 0.46, -3.45), Vector3(2.24, 0.22, 0.14), Color("9aa2a7"))
	# Patient module.
	k.box("facade", Vector3(0, 1.7, 1.18), Vector3(WIDTH, 2.3, 4.34), BODY)
	k.box("facade", Vector3(0, 2.87, 1.18), Vector3(WIDTH + 0.02, 0.04, 4.36), Color("dfe2e0"))
	# Red stripes along the sides and across the rear.
	for side in [-1, 1]:
		k.box("facade", Vector3(side * (WIDTH / 2.0 + 0.005), 1.18, 0.1), Vector3(0.012, 0.26, 6.5), RED)
		k.box("facade", Vector3(side * (WIDTH / 2.0 + 0.005), 2.68, 1.18), Vector3(0.012, 0.08, 4.3), RED)
		# Compartment doors and the side entry door.
		k.box("facade", Vector3(side * (WIDTH / 2.0 + 0.004), 1.35, 2.35), Vector3(0.008, 1.3, 1.1), Color("e6e8e5"))
		k.box("tinted", Vector3(side * (WIDTH / 2.0 + 0.006), 2.05, -0.35), Vector3(0.008, 0.4, 0.5), Color("30414a"))
	k.box("facade", Vector3(0, 1.18, LENGTH / 2.0 - 0.1), Vector3(WIDTH - 0.02, 0.26, 0.012), RED)
	# Chassis, bumpers and the rear step.
	k.box("metal", Vector3(0, 0.45, 0.4), Vector3(2.0, 0.3, 6.0), dark)
	k.box("metal", Vector3(0, 0.42, LENGTH / 2.0 - 0.02), Vector3(2.1, 0.18, 0.34), Color("6d767c"))

## The Star of Life: a blue six-armed star with a white staff, flat on a side panel.
func _star(center: Vector3, side: int) -> void:
	var kit := Props.NodeKit.new()
	var facing := Basis(Vector3.UP, side * PI / 2)
	for index in range(3):
		var arm := facing * Basis(Vector3.BACK, index * PI / 3.0)
		kit.box("facade", center, Vector3(0.1, 0.5, 0.01), Color("2c5fb3"), "always", false, arm)
	kit.box("facade", center + facing * Vector3(0, 0, 0.004), Vector3(0.02, 0.3, 0.01), Color.WHITE, "always", false, facing)
	kit.commit(self, "StarOfLife")

func _build_wheels() -> void:
	for spot in [Vector3(-1.02, 0.42, -2.4), Vector3(1.02, 0.42, -2.4), Vector3(-1.02, 0.42, 1.85), Vector3(1.02, 0.42, 1.85)]:
		var wheel := Node3D.new()
		wheel.name = "Wheel"
		wheel.position = spot
		add_child(wheel)
		var kit := Props.NodeKit.new()
		kit.cylinder("metal", Vector3(-0.15, 0, 0), Vector3(0.15, 0, 0), 0.42, Color("1b1d1f"), "always", 16)
		kit.cylinder("metal", Vector3(-0.16, 0, 0), Vector3(0.16, 0, 0), 0.2, Color("a3aaaf"), "always", 10)
		kit.box("metal", Vector3(0.161 * sign(spot.x), 0.1, 0), Vector3(0.01, 0.06, 0.06), Color("6d767c"))
		kit.commit(wheel, "Tyre")
		wheels.append(wheel)

func _build_doors() -> void:
	for side in [-1, 1]:
		var hinge := Node3D.new()
		hinge.name = "RearDoor"
		hinge.position = Vector3(side * (WIDTH / 2.0 - 0.02), 0, LENGTH / 2.0 - 0.1)
		add_child(hinge)
		var kit := Props.NodeKit.new()
		var middle: float = -side * 0.56
		kit.box("facade", Vector3(middle, 1.62, 0.03), Vector3(1.1, 1.9, 0.05), BODY)
		kit.box("tinted", Vector3(middle, 2.12, 0.06), Vector3(0.62, 0.5, 0.01), Color("30414a"))
		kit.box("facade", Vector3(middle, 1.18, 0.061), Vector3(1.08, 0.26, 0.01), RED)
		kit.box("metal", Vector3(-side * 1.02, 1.5, 0.08), Vector3(0.04, 0.28, 0.04), Color("6d767c"))
		kit.commit(hinge, "Leaf")
		rear_doors.append(hinge)

func _build_lights() -> void:
	var spots := [
		[Vector3(-0.55, 2.36, -2.15), Vector3(0.5, 0.12, 0.24), Color("ff3b30")], [Vector3(0.0, 2.36, -2.15), Vector3(0.4, 0.12, 0.24), Color("f5f7fa")],
		[Vector3(0.55, 2.36, -2.15), Vector3(0.5, 0.12, 0.24), Color("ff3b30")],
		[Vector3(-1.05, 2.74, -0.98), Vector3(0.2, 0.16, 0.06), Color("ff3b30")], [Vector3(1.05, 2.74, -0.98), Vector3(0.2, 0.16, 0.06), Color("ff3b30")],
		[Vector3(-1.05, 2.74, LENGTH / 2.0 - 0.08), Vector3(0.2, 0.16, 0.06), Color("ff3b30")], [Vector3(1.05, 2.74, LENGTH / 2.0 - 0.08), Vector3(0.2, 0.16, 0.06), Color("ff3b30")],
		[Vector3(0.0, 2.74, LENGTH / 2.0 - 0.08), Vector3(0.36, 0.14, 0.06), Color("ffb020")],
	]
	for spot in spots:
		var lamp := MeshInstance3D.new()
		lamp.name = "WarningLight"
		lamp.mesh = BoxMesh.new()
		lamp.mesh.size = spot[1]
		lamp.position = spot[0]
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(spot[2]).darkened(0.6)
		material.set_meta("lit", spot[2])
		lamp.material_override = material
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lamp)
		flashers.append(lamp)
		flash_materials.append(material)

func set_lights(on: bool) -> void:
	lights_on = on
	if not on:
		for material in flash_materials:
			material.albedo_color = Color(material.get_meta("lit")).darkened(0.6)

func open_rear(open: bool) -> void:
	door_target = 1.0 if open else 0.0

func rear_open() -> bool:
	return door_open > 0.95

func rear_closed() -> bool:
	return door_open < 0.05

## World point just behind the rear doors, where a stretcher is pulled out.
func rear_point(extra := 0.0) -> Vector3:
	return to_global(REAR + Vector3(0, 0, extra))

## Heading (yaw) from a direction, for local forward −Z.
static func yaw_of(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)

func place(point: Vector3, yaw: float) -> void:
	driving = false
	speed = 0.0
	global_position = point
	rotation.y = yaw

## Drives through `points` (world, on the ground) with rounded corners and
## stops at the last one; `arrived` fires there.
func drive(points: Array, cruise_speed := 8.0, corner := 5.0, reverse := false) -> void:
	reversing = reverse
	route = smooth(points, corner)
	lengths = PackedFloat32Array([0.0])
	for index in range(1, route.size()):
		lengths.append(lengths[index - 1] + route[index].distance_to(route[index - 1]))
	total = lengths[lengths.size() - 1]
	travel = 0.0
	cruise = cruise_speed
	driving = total > 0.01
	if not driving:
		arrived.emit()

## Waypoints with each inner corner replaced by a quadratic curve.
static func smooth(points: Array, corner: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	if points.size() < 3:
		for point in points:
			result.append(point)
		return result
	result.append(points[0])
	for index in range(1, points.size() - 1):
		var previous: Vector3 = points[index - 1]
		var here: Vector3 = points[index]
		var following: Vector3 = points[index + 1]
		var cut := minf(corner, minf(here.distance_to(previous), here.distance_to(following)) * 0.45)
		var start := here + (previous - here).normalized() * cut
		var finish := here + (following - here).normalized() * cut
		for step in range(9):
			var t := step / 8.0
			result.append(start.lerp(here, t).lerp(here.lerp(finish, t), t))
	result.append(points[points.size() - 1])
	return result

func sample(distance: float) -> Vector3:
	distance = clampf(distance, 0.0, total)
	var index := lengths.bsearch(distance)
	if index <= 0:
		return route[0]
	if index >= route.size():
		return route[route.size() - 1]
	var span := lengths[index] - lengths[index - 1]
	var t := 0.0 if span <= 0.0001 else (distance - lengths[index - 1]) / span
	return route[index - 1].lerp(route[index], t)

func _process(delta: float) -> void:
	if lights_on:
		light_time += delta
		var phase := int(light_time / 0.18) % 2
		for index in range(flash_materials.size()):
			var lit := (index % 2 == phase) or index == 7 and phase == 0
			var color: Color = flash_materials[index].get_meta("lit")
			flash_materials[index].albedo_color = color if lit else color.darkened(0.7)
	if door_open != door_target:
		door_open = move_toward(door_open, door_target, delta * 1.4)
		for index in range(rear_doors.size()):
			var side := -1.0 if index == 0 else 1.0
			var eased := door_open * door_open * (3.0 - 2.0 * door_open)
			rear_doors[index].rotation.y = side * -eased * 1.9
	if not driving:
		return
	var remaining := total - travel
	blocked = _someone_ahead()
	var wanted := 0.0 if blocked else minf(cruise, sqrt(maxf(0.0, 2.0 * brake * remaining)))
	speed = move_toward(speed, wanted, (accel if wanted > speed else brake * 2.0) * delta)
	if remaining < 0.03 or (speed < 0.05 and remaining < 0.25 and not blocked):
		travel = total
		global_position = sample(total)
		driving = false
		speed = 0.0
		arrived.emit()
		return
	var step := speed * delta
	travel = minf(total, travel + step)
	distance_driven += step
	var here := sample(travel)
	var ahead := sample(travel + 1.6) - sample(travel - 1.6)
	global_position = here
	if Vector2(ahead.x, ahead.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, yaw_of(-ahead if reversing else ahead), 1.0 - exp(-10.0 * delta))
	for wheel in wheels:
		wheel.rotation.x += (step if reversing else -step) / 0.42

## Someone standing in the lane just ahead (it stops rather than hit them).
func _someone_ahead() -> bool:
	if not is_instance_valid(watch) or not watch.is_inside_tree():
		return false
	var local := to_local(watch.global_position)
	if reversing:
		return absf(local.x) < WIDTH / 2.0 + 0.7 and local.z > LENGTH / 2.0 - 0.4 and local.z < LENGTH / 2.0 + 3.0
	return absf(local.x) < WIDTH / 2.0 + 0.7 and local.z < -LENGTH / 2.0 + 0.4 and local.z > -LENGTH / 2.0 - 4.0

extends Node3D
## People moving a patient: an EMS crew with their cot, or a hospital
## transporter with an ED stretcher or a wheelchair. The stretcher travels
## foot first with the lead crew member at the head end leaning on the push
## handle and the partner at the foot guiding it; a wheelchair has one pusher
## behind. The patient lies on the stretcher (head raised) under a blanket,
## or sits in the chair. The group follows a route of points, turns smoothly,
## pauses rather than run into the student, opens automatic doors as it comes
## (the `door_openers` group) and is solid to the player.
signal arrived
const Props = preload("res://world/hospital/hospital_props.gd")
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
const SPEED := 1.2
const TILT := 0.5
## "cot" (EMS), "stretcher" (ED) or "wheelchair".
var kind := "cot"
var cart: Node3D
var patient: Node3D
var patient_look: Node3D
var blanket: MeshInstance3D
var crew: Array[Node3D] = []
var looks: Array[Node3D] = []
var path: Array[Vector3] = []
var moving := false
var heading := 0.0
var speed := SPEED
## Which side of the cart the partner walks on (+1 its right-hand side of travel, −1 the left).
var partner_side := 1.0
## The student: the group waits rather than walk into them.
var watch: Node3D
var distance_walked := 0.0
var cart_blocker: AnimatableBody3D
## Path points still to walk backwards (see walk()).
var backing := 0

## `crew_who`: one or two presets or looks (lead first); `patient_who`: the
## patient's look (or null for an empty cart).
func setup(crew_who: Array, cart_kind := "cot", patient_who: Variant = null) -> void:
	kind = cart_kind
	add_to_group("door_openers")
	# Staff walking the department step aside for the cart and its crew.
	add_to_group("make_way")
	cart = Node3D.new()
	cart.name = "Cart"
	add_child(cart)
	var kit := Props.NodeKit.new()
	var hip := Vector3.ZERO
	match kind:
		"wheelchair":
			Props.wheelchair(kit, Vector3.ZERO, 0.0)
		"cot":
			hip = Props.stretcher(kit, Vector3.ZERO, 0.0, Color("30353a"), Color("2c4f86"), 0.8, TILT)
		_:
			hip = Props.stretcher(kit, Vector3.ZERO, 0.0, Color("c9ced2"), Color("35557a"), 0.74, TILT)
	kit.commit(cart, "CartBody")
	if kind != "wheelchair":
		blanket = MeshInstance3D.new()
		blanket.name = "Blanket"
		blanket.mesh = BoxMesh.new()
		blanket.mesh.size = Vector3(0.64, 0.2, 1.18)
		blanket.position = Vector3(0, hip.y + 0.01, 0.39)
		var sheet := StandardMaterial3D.new()
		sheet.albedo_color = Color("d9e2e7") if kind == "stretcher" else Color("c7d3e6")
		blanket.material_override = sheet
		cart.add_child(blanket)
	patient = Node3D.new()
	patient.name = "Patient"
	cart.add_child(patient)
	patient_look = Appearance.new()
	patient.add_child(patient_look)
	if typeof(patient_who) == TYPE_DICTIONARY:
		patient_look.apply_look(patient_who)
	elif typeof(patient_who) == TYPE_STRING:
		patient_look.apply_preset(patient_who)
	else:
		patient_look.apply_preset("patient")
	if kind == "wheelchair":
		patient_look.set_seated(true)
		patient.position = Vector3(0, 0.46 - 0.28, 0.02)
		patient.rotation.y = PI
	else:
		patient.position = hip
		Props.lay(patient, patient_look, TILT, PI)
	set_patient(patient_who != null)
	for who in crew_who:
		var figure := Node3D.new()
		figure.name = "Crew"
		var look := Appearance.new()
		figure.add_child(look)
		add_child(figure)
		if typeof(who) == TYPE_DICTIONARY:
			look.apply_look(who)
		else:
			look.apply_preset(String(who))
		Student.make_blocker(figure)
		crew.append(figure)
		looks.append(look)
	cart_blocker = AnimatableBody3D.new()
	cart_blocker.collision_layer = 4
	cart_blocker.collision_mask = 0
	cart_blocker.sync_to_physics = false
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.7, 1.0, 2.1) if kind != "wheelchair" else Vector3(0.66, 1.0, 0.8)
	shape.position.y = 0.5
	cart_blocker.add_child(shape)
	cart.add_child(cart_blocker)
	_arrange(0.0, 0.0)

func set_patient(present: bool) -> void:
	patient.visible = present
	if is_instance_valid(blanket):
		blanket.visible = present

func has_patient() -> bool:
	return patient.visible

## Length of the cart along its direction of travel.
func cart_length() -> float:
	return 0.8 if kind == "wheelchair" else 2.08

## Instant placement; `yaw` points the cart's leading end (foot end) away.
func place(point: Vector3, yaw: float) -> void:
	moving = false
	path.clear()
	global_position = Vector3(point.x, global_position.y if is_inside_tree() else 0.0, point.z)
	heading = yaw
	_arrange(0.0, 0.0)

## Cart heading (leading end first) toward a direction.
static func heading_of(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)

## `back_out` is how many of the first points to walk backwards: the crew
## pulls the cart out of a room head end first instead of turning it round
## between the bed and the wall, then turns it in the corridor.
func walk(points: Array, back_out := 0) -> void:
	path.clear()
	for point in points:
		path.append(Vector3(point.x, 0.0, point.z))
	backing = back_out
	moving = not path.is_empty()
	if not moving:
		arrived.emit()

func stop() -> void:
	path.clear()
	moving = false

## Gone through a door (inside, upstairs) or back again: nothing solid stays behind.
func set_present(present: bool) -> void:
	visible = present
	for shape in find_children("*", "CollisionShape3D", true, false):
		(shape as CollisionShape3D).disabled = not present

func _process(delta: float) -> void:
	var moved := 0.0
	if moving:
		moved = _advance(delta)
	_arrange(moved, delta)

func _advance(delta: float) -> float:
	var target := path[0]
	var to := target - global_position
	to.y = 0.0
	var length := to.length()
	if length < 0.05:
		path.pop_front()
		backing = maxi(0, backing - 1)
		if path.is_empty():
			moving = false
			arrived.emit()
		return 0.0
	var direction := to / length
	if _someone_ahead(direction):
		return 0.0
	var step := minf(length, speed * delta)
	global_position += direction * step
	distance_walked += step
	var facing := -direction if backing > 0 else direction
	heading = lerp_angle(heading, heading_of(facing), 1.0 - exp(-6.0 * delta))
	return step

## The student standing just ahead of the leading end.
func _someone_ahead(direction: Vector3) -> bool:
	if not is_instance_valid(watch) or not watch.is_inside_tree():
		return false
	# Backing out, the crew member at the head end walks first.
	var lead := global_position + direction * (cart_length() / 2.0 + (0.7 if backing > 0 else 0.2))
	var offset := watch.global_position - lead
	offset.y = 0.0
	return offset.length() < 0.9 and offset.dot(direction) > -0.3

## Places the cart and the crew around it and poses the pushing arms.
func _arrange(moved: float, delta: float) -> void:
	cart.rotation.y = heading
	var basis := Basis(Vector3.UP, heading)
	for index in range(crew.size()):
		# The lead pushes at the head end; the partner guides at the foot end,
		# just off the centre line, so the pair fits through a doorway.
		var spot := Vector3(0, 0, -(cart_length() / 2.0 + 0.5)) if index == 0 else Vector3(0.12 * partner_side, 0, cart_length() / 2.0 + 0.42)
		crew[index].position = basis * spot
		# Backing out, the partner turns to face the cart and follows it.
		var facing := heading if index == 1 and backing > 0 else heading + PI
		crew[index].rotation.y = facing if delta <= 0.0 else lerp_angle(crew[index].rotation.y, facing, 1.0 - exp(-8.0 * delta))
		var look: Node3D = looks[index]
		look.animate_motion(moved, delta)
		if not is_instance_valid(look.body):
			continue
		if index == 0:
			# Leaning into the push handle, both hands on it.
			look.shoulders[0].rotation = Vector3(1.15, 0, 0.08)
			look.shoulders[1].rotation = Vector3(1.15, 0, -0.08)
			look.spine.rotation.x = -0.08
		elif backing > 0:
			# Following the cart out: both hands forward on the foot rail.
			look.shoulders[0].rotation = Vector3(0.75, 0, 0.1)
			look.shoulders[1].rotation = Vector3(0.75, 0, -0.1)
		else:
			# Guiding from the front: the hand on the cart's side back on the foot rail.
			if partner_side > 0.0:
				look.shoulders[1].rotation = Vector3(-0.5, 0, -0.12)
			else:
				look.shoulders[0].rotation = Vector3(-0.5, 0, 0.12)

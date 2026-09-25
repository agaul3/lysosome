extends Node3D
## Someone following a short script in the Emergency Department: a walk-in
## patient coming through the doors, security and registration to a seat in
## the waiting room; a patient called to triage; a discharged patient walking
## out. Steps run in order:
##   {"to": point}                          walk there (pausing for the student)
##   {"wait": seconds}                       stand for a while
##   {"face": point}                         turn toward a point
##   {"sit": point, "yaw": y, "seat": h, "for": s}
##       sit down on a seat whose top is h (s ≤ 0: until `release()`): turn
##       round stepping back to the seat's edge, then lower onto it (the
##       rig's sit blend); "instant": true starts already seated
## Standing up is the reverse, before the next walking step.
##   {"hide": true}                          leave (out of a door, into a room)
## Solid to the player while standing; opens automatic doors as they come.
signal finished
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
var figure: Node3D
var blocker: AnimatableBody3D
var steps: Array = []
var index := -1
var timer := 0.0
var speed := 1.15
var seated := false
var waiting_release := false
## The student: walkers wait rather than walk into them.
var watch: Node3D
var distance_walked := 0.0
const TURN_TIME := 0.35
const SIT_TIME := 0.8
const RISE_TIME := 0.7
## "", "sitting" or "rising", with where it goes from and to.
var motion := ""
var motion_time := 0.0
var motion_from := Vector3.ZERO
var motion_edge := Vector3.ZERO
var motion_to := Vector3.ZERO
var motion_yaw := 0.0

func setup(who: Variant) -> void:
	add_to_group("door_openers")
	add_to_group("make_way")
	figure = Appearance.new()
	figure.name = "Appearance"
	add_child(figure)
	if typeof(who) == TYPE_DICTIONARY:
		figure.apply_look(who)
	else:
		figure.apply_preset(String(who))
	blocker = Student.make_blocker(self)
	speed = randf_range(1.0, 1.3)

func run(route: Array) -> void:
	steps = route
	index = -1
	visible = true
	_next()

## Lets a walker who sat down "until released" carry on.
func release() -> void:
	if waiting_release:
		waiting_release = false
		_next()

func is_sitting() -> bool:
	return seated and motion.is_empty()

func _next() -> void:
	index += 1
	timer = 0.0
	if index >= steps.size():
		finished.emit()
		return
	var step: Dictionary = steps[index]
	if step.has("sit"):
		_sit(step)
	elif step.has("hide"):
		motion = ""
		if seated:
			seated = false
			figure.set_seated(false)
		visible = false
		blocker.get_child(0).disabled = true
		finished.emit()
	elif step.has("to") and seated:
		_stand()

func _sit(step: Dictionary) -> void:
	var seat: Vector3 = step.sit
	var yaw: float = step.get("yaw", 0.0)
	var seated_at: Vector3 = seat + Vector3(0, float(step.get("seat", 0.36)) - 0.28, 0) + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.06)
	seated = true
	waiting_release = float(step.get("for", 0.0)) <= 0.0
	if step.get("instant", false):
		global_position = seated_at
		figure.rotation.y = yaw
		figure.set_seated(true)
		blocker.get_child(0).disabled = true
		return
	motion = "sitting"
	motion_time = 0.0
	motion_from = global_position
	# Stand with the backs of the legs at the seat's front edge.
	motion_edge = Vector3(seat.x, 0.0, seat.z) + Basis(Vector3.UP, yaw) * Vector3(0, 0, -0.42)
	motion_to = seated_at
	motion_yaw = yaw

func _stand() -> void:
	if not seated or motion == "rising":
		return
	motion = "rising"
	motion_time = 0.0
	motion_from = global_position
	motion_to = Vector3(global_position.x, 0.0, global_position.z) + Basis(Vector3.UP, figure.rotation.y) * Vector3(0, 0, -0.49)

## Sitting down and getting up, eased like the student's own sit.
func _seat_motion(delta: float) -> void:
	motion_time += delta
	if motion == "sitting":
		if motion_time < TURN_TIME:
			var before := global_position
			global_position = motion_from.lerp(motion_edge, motion_time / TURN_TIME)
			figure.rotation.y = lerp_angle(figure.rotation.y, motion_yaw, 1.0 - exp(-14.0 * delta))
			figure.animate_motion(before.distance_to(global_position), delta)
			return
		figure.rotation.y = motion_yaw
		var t := clampf((motion_time - TURN_TIME) / SIT_TIME, 0.0, 1.0)
		global_position = motion_edge.lerp(motion_to, t * t * (3.0 - 2.0 * t))
		figure.set_sit_blend(t)
		if t >= 1.0:
			motion = ""
			blocker.get_child(0).disabled = true
		return
	var rise := clampf(motion_time / RISE_TIME, 0.0, 1.0)
	global_position = motion_from.lerp(motion_to, rise * rise * (3.0 - 2.0 * rise))
	figure.set_sit_blend(1.0 - rise)
	if rise >= 1.0:
		motion = ""
		seated = false
		blocker.get_child(0).disabled = false

func _process(delta: float) -> void:
	if not motion.is_empty() and visible:
		_seat_motion(delta)
		return
	if index < 0 or index >= steps.size() or not visible:
		figure.animate_motion(0.0, delta)
		return
	var step: Dictionary = steps[index]
	var moved := 0.0
	if step.has("to"):
		moved = _walk(step.to, delta)
	elif step.has("wait"):
		timer += delta
		if timer >= float(step.wait):
			_next()
	elif step.has("face"):
		var to: Vector3 = step.face - global_position
		figure.rotation.y = lerp_angle(figure.rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-8.0 * delta))
		timer += delta
		if timer > 0.5:
			_next()
	elif step.has("sit") and not waiting_release:
		timer += delta
		if timer >= float(step.get("for", 0.0)):
			_next()
	if not seated:
		figure.animate_motion(moved, delta)

func _walk(point: Vector3, delta: float) -> float:
	var to := Vector3(point.x, 0.0, point.z) - Vector3(global_position.x, 0.0, global_position.z)
	var length := to.length()
	if length < 0.06:
		_next()
		return 0.0
	var direction := to / length
	figure.rotation.y = lerp_angle(figure.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-10.0 * delta))
	if is_instance_valid(watch) and watch.is_inside_tree():
		var offset := watch.global_position - global_position
		offset.y = 0.0
		if offset.length() < 0.85 and offset.normalized().dot(direction) > 0.5:
			return 0.0
	var step := minf(length, speed * delta)
	global_position += direction * step
	distance_walked += step
	return step

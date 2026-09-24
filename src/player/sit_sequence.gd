extends RefCounted
## Plans and plays the choreography for sitting down in, or standing up from,
## a world/seat.gd chair. Used by the player and by NPC views.
##
## Plans are lists of steps in world space:
##   walk  — travel to a point, facing the direction of travel
##   turn  — rotate in place to a yaw, shuffling the feet
##   step  — short kinematic step (side-step or back-step) keeping a yaw
##   sit   — lower from PRE_SIT onto the cushion while blending the pose
##   rise  — the reverse of sit
##   pause — hold still briefly so the gait settles before the next move
## Walking can be delegated to a Callable so a CharacterBody3D keeps real
## collision; every other step is kinematic and stays out of solid geometry
## because the plan's waypoints are placed around the chair.
const Seat = preload("res://world/seat.gd")
const WALK_SPEED := 1.4
const STEP_SPEED := 0.75
const TURN_SPEED := 5.0
const SIT_SECONDS := 1.1
const RISE_SECONDS := 0.95

var mover: Node3D
var appearance: Node3D
var steps: Array = []
var index := 0
var elapsed := 0.0
var step_from := Vector3.ZERO
## Optional: func(target: Vector3, delta: float) -> bool (true when arrived).
var walk_handler: Callable
var approach := ""

func _init(target_mover: Node3D, target_appearance: Node3D) -> void:
	mover = target_mover
	appearance = target_appearance

## Which side of the chair a point is on, from the sitter's perspective.
static func classify(seat: Node3D, from: Vector3) -> String:
	var local: Vector3 = seat.to_local(from)
	if local.z < 0 and -local.z >= absf(local.x):
		return "front"
	if absf(local.x) >= 0.55 or local.z <= 0.0:
		return "left" if local.x < 0 else "right"
	return "back_left" if local.x < 0 else "back_right"

## is_clear: func(point: Vector3) -> bool, used to reject blocked approach points.
static func plan_sit(seat: Node3D, from: Vector3, is_clear: Callable = Callable()) -> Dictionary:
	var side := classify(seat, from)
	var local: Vector3 = seat.to_local(from)
	var order: Array = []
	match side:
		"front": order = ["front", "left" if local.x < 0 else "right", "right" if local.x < 0 else "left"]
		"left": order = ["left", "front", "right"]
		"right": order = ["right", "front", "left"]
		"back_left": order = ["back_left", "back_right"]
		"back_right": order = ["back_right", "back_left"]
	for option in order:
		var waypoints := _approach_points(option, local)
		var blocked := false
		if is_clear.is_valid():
			for waypoint in waypoints:
				if not is_clear.call(seat.point(waypoint)):
					blocked = true
		if blocked:
			continue
		var result: Array = []
		for waypoint in waypoints:
			result.append({"kind": "walk", "to": seat.point(waypoint)})
		result.append({"kind": "turn", "yaw": seat.seated_yaw()})
		result.append({"kind": "step", "to": seat.point(Seat.PRE_SIT), "lateral": option != "front"})
		result.append({"kind": "pause", "seconds": 0.12})
		result.append({"kind": "sit", "from": seat.point(Seat.PRE_SIT), "to": seat.point(Seat.SIT_POINT)})
		return {"approach": option, "steps": result}
	return {"approach": "", "steps": []}

## Row seats (auditoriums) can only be entered from the walkway in front of
## them. `path` comes from the room's walkway graph and ends at FRONT_POINT;
## the label says where the player came from: front (already standing there),
## row_left / row_right (along the row from the sitter's left or right), or
## back (from behind the backrest, detouring through an aisle).
static func plan_row_sit(seat: Node3D, from: Vector3, path: PackedVector3Array) -> Dictionary:
	if path.is_empty():
		return {"approach": "", "steps": []}
	var local: Vector3 = seat.to_local(from)
	var front: Vector3 = seat.point(Seat.FRONT_POINT)
	var approach := ""
	var flat := Vector2(from.x - front.x, from.z - front.z)
	if flat.length() < 0.45 and absf(from.y - front.y) < 0.2:
		approach = "front"
	elif local.z > 0.3 or local.y > 0.2:
		approach = "back"
	else:
		var previous: Vector3 = path[path.size() - 2] if path.size() > 1 else from
		approach = "row_left" if seat.to_local(previous).x < 0.0 else "row_right"
	var result: Array = []
	if approach != "front":
		for waypoint in path:
			result.append({"kind": "walk", "to": waypoint})
	result.append({"kind": "turn", "yaw": seat.seated_yaw()})
	result.append({"kind": "step", "to": seat.point(Seat.PRE_SIT), "lateral": false})
	result.append({"kind": "pause", "seconds": 0.12})
	result.append({"kind": "sit", "from": seat.point(Seat.PRE_SIT), "to": seat.point(Seat.SIT_POINT)})
	return {"approach": approach, "steps": result}

static func _approach_points(option: String, local: Vector3) -> Array:
	var side := -1.0 if option.ends_with("left") else 1.0
	var side_point := Vector3(Seat.SIDE_POINT.x * side, 0, Seat.SIDE_POINT.z)
	match option:
		"front":
			# Already standing close in front: just turn around and back up.
			if local.z > Seat.FRONT_POINT.z and absf(local.x) < 0.3:
				return []
			return [Seat.FRONT_POINT]
		"left", "right":
			return [side_point]
		_:
			return [Vector3(Seat.BACK_CORNER.x * side, 0, Seat.BACK_CORNER.z), side_point]

## Prefer the usual forward exit, but a table may require stepping sideways.
## The player supplies a capsule sweep that ignores only the chair being left.
static func plan_rise(seat: Node3D, exit_clear: Callable = Callable(), approach := "") -> Array:
	var side := -1.0 if approach.ends_with("left") else 1.0
	var exits := [Seat.EXIT_POINT, Vector3(side * 0.82, 0, Seat.PRE_SIT.z), Vector3(-side * 0.82, 0, Seat.PRE_SIT.z)]
	for point in exits:
		var target: Vector3 = seat.point(point)
		if exit_clear.is_valid() and not exit_clear.call(target):
			continue
		return [
			{"kind": "rise", "from": seat.point(Seat.SIT_POINT), "to": seat.point(Seat.PRE_SIT)},
			{"kind": "step", "to": target, "lateral": point != Seat.EXIT_POINT},
		]
	return []

func start(plan: Array) -> void:
	steps = plan
	index = 0
	_begin_step()

func finished() -> bool:
	return index >= steps.size()

func current_kind() -> String:
	return "" if finished() else steps[index].kind

## Returns true once every step has completed.
func advance(delta: float) -> bool:
	while not finished() and delta > 0.0:
		var step: Dictionary = steps[index]
		var done := false
		match step.kind:
			"walk":
				done = _walk(step.to, delta)
				delta = 0.0
			"turn":
				var difference := wrapf(step.yaw - appearance.rotation.y, -PI, PI)
				var amount := clampf(difference, -TURN_SPEED * delta, TURN_SPEED * delta)
				appearance.rotation.y += amount
				appearance.animate_motion(absf(amount) * 0.22, delta)
				done = absf(difference - amount) < 0.001
				if done:
					appearance.rotation.y = step.yaw
				delta = 0.0
			"step":
				var duration := maxf(step_from.distance_to(step.to) / STEP_SPEED, 0.3)
				done = _timed(delta, duration, func(t: float) -> void:
					var previous := mover.global_position
					mover.global_position = step_from.lerp(step.to, _ease(t))
					appearance.animate_motion(previous.distance_to(mover.global_position), delta, step.lateral))
				delta = 0.0
			"pause":
				appearance.animate_motion(0.0, delta)
				done = _timed(delta, step.seconds, func(_t: float) -> void: pass)
				delta = 0.0
			"sit", "rise":
				var sitting: bool = step.kind == "sit"
				done = _timed(delta, SIT_SECONDS if sitting else RISE_SECONDS, func(t: float) -> void:
					mover.global_position = step.from.lerp(step.to, _ease(t))
					appearance.set_sit_blend(t if sitting else 1.0 - t))
				delta = 0.0
		if done:
			index += 1
			_begin_step()
	return finished()

func _begin_step() -> void:
	elapsed = 0.0
	if is_instance_valid(mover):
		step_from = mover.global_position

func _timed(delta: float, duration: float, apply: Callable) -> bool:
	elapsed = minf(elapsed + delta, duration)
	apply.call(elapsed / duration)
	return elapsed >= duration

func _walk(target: Vector3, delta: float) -> bool:
	if walk_handler.is_valid():
		return walk_handler.call(target, delta)
	var offset := target - mover.global_position
	offset.y = 0
	var travel := minf(offset.length(), WALK_SPEED * delta)
	if offset.length() > 0.0001:
		mover.global_position += offset.normalized() * travel
		appearance.rotation.y = lerp_angle(appearance.rotation.y, atan2(-offset.x, -offset.z), 1.0 - exp(-14.0 * delta))
	appearance.animate_motion(travel, delta)
	return offset.length() - travel < 0.001

static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

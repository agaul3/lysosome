extends Node3D
## A student strolling the campus paths: walks a graph of path waypoints,
## picking a random next junction at each (rarely turning straight back),
## sometimes pausing to check their phone. When the player is in the way they
## step to the side of the path (away from the player, never into a bench or
## the planter) and walk on in that lane, drifting back to the centre once
## clear; with no clear side they wait. Solid to the player.
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
## Waypoints on the quad paths (x, z) and their connections.
const NODES := [
	Vector2(-12.6, -12.6), Vector2(0, -12.6), Vector2(12.6, -12.6),
	Vector2(12.6, -2), Vector2(12.6, 9.5), Vector2(0, 9.5), Vector2(-12.6, 9.5), Vector2(-12.6, -2),
	Vector2(0, -5.3), Vector2(3.3, -2), Vector2(0, 1.3), Vector2(-3.3, -2),
]
const EDGES := [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 0], [1, 8], [8, 9], [9, 10], [10, 11], [11, 8], [3, 9], [5, 10], [7, 11]]
## The graph this walker uses: the quad by default; another scene (the
## hospital lobby) sets its own before adding the walker.
var nodes: Array = NODES
var edges: Array = EDGES
var figure: Node3D
var rng := RandomNumberGenerator.new()
var speed := 1.3
var from_node := 0
var to_node := 1
var pause := 0.0
var phone := 0.0
var player: Node3D
var distance_walked := 0.0
## Position on the path graph; the figure stands `aside` metres to one side.
var path_point := Vector2.ZERO
var aside := 0.0
var aside_side := 1.0
var yielding := false
## [centre (Vector2), radius] areas a sidestep must not enter (benches, planter).
var obstacles: Array = []
const ASIDE := 0.8
const YIELD_RANGE := 2.2

func _ready() -> void:
	rng.randomize()
	figure = Appearance.new()
	figure.name = "Figure"
	add_child(figure)
	speed = rng.randf_range(1.15, 1.45)
	from_node = rng.randi() % nodes.size()
	to_node = _next(from_node, -1)
	path_point = nodes[from_node].lerp(nodes[to_node], rng.randf())
	figure.position = Vector3(path_point.x, 0, path_point.y)

## `preset` names a look; empty dresses the passer-by in a random one.
func setup(preset: String, target_player: Node3D, keep_clear: Array = []) -> void:
	if preset.is_empty():
		figure.apply_look(preload("res://data/looks.gd").random(rng))
	else:
		figure.apply_preset(preset)
	# After the preset: apply_preset rebuilds the figure's children.
	Student.make_blocker(figure)
	player = target_player
	obstacles = keep_clear

func lane_clear(point: Vector2) -> bool:
	for entry in obstacles:
		if point.distance_to(entry[0]) < entry[1]:
			return false
	return true

func neighbours(node: int) -> Array:
	var result: Array = []
	for edge in edges:
		if edge[0] == node:
			result.append(edge[1])
		elif edge[1] == node:
			result.append(edge[0])
	return result

func _next(node: int, came_from: int) -> int:
	var options := neighbours(node)
	if options.size() > 1 and rng.randf() < 0.92:
		options.erase(came_from)
	return options[rng.randi() % options.size()]

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var before := Vector2(figure.position.x, figure.position.z)
	var moved := 0.0
	phone = move_toward(phone, 1.0 if pause > 0.0 else 0.0, delta * 3.0)
	var target: Vector2 = nodes[to_node]
	var offset := target - path_point
	var forward := offset.normalized() if offset.length() > 0.01 else Vector2(-sin(figure.rotation.y), -cos(figure.rotation.y))
	var side := Vector2(-forward.y, forward.x)
	# Make way for the player: step to a clear side (away from them if both are
	# clear), then walk on in that lane unless they are standing in it.
	var ahead := INF
	var lateral := 0.0
	var near := false
	if is_instance_valid(player):
		var relative := Vector2(player.global_position.x, player.global_position.z) - path_point
		ahead = relative.dot(forward)
		lateral = relative.dot(side)
		near = relative.length() < YIELD_RANGE and ahead > -0.4
		if near and not yielding:
			var away := -1.0 if lateral > 0.0 else 1.0
			if lane_clear(path_point + side * away * ASIDE):
				aside_side = away
			elif lane_clear(path_point - side * away * ASIDE):
				aside_side = -away
			else:
				aside_side = 0.0
	yielding = near
	var aside_goal := aside_side * ASIDE if yielding else 0.0
	aside = move_toward(aside, aside_goal, delta * (1.8 if yielding else 0.7))
	var in_lane := ahead > -0.1 and ahead < 1.3 and absf(lateral - aside) < 0.62
	var hold := yielding and (in_lane or absf(aside) > 0.05 and not lane_clear(path_point + forward * 0.6 + side * aside))
	if pause > 0.0:
		pause -= delta
	elif not hold:
		if offset.length() < 0.05:
			var previous := from_node
			from_node = to_node
			to_node = _next(from_node, previous)
			if rng.randf() < 0.25:
				pause = rng.randf_range(1.5, 4.0)
		else:
			var step := minf(offset.length(), speed * delta * (0.75 if yielding else 1.0))
			path_point += forward * step
			distance_walked += step
	# Rate-limited so turning a corner while stepped aside is a short step, not a jump.
	var here := before.move_toward(path_point + side * aside, delta * 3.0)
	figure.position = Vector3(here.x, 0, here.y)
	moved = here.distance_to(before)
	if moved > 0.002:
		var heading := (here - before).lerp(forward * moved, 0.5)
		figure.rotation.y = lerp_angle(figure.rotation.y, atan2(-heading.x, -heading.y), 1.0 - exp(-8.0 * delta))
	figure.animate_motion(moved, delta)
	# Phone check: right hand raised in front of the chest, head tipped down.
	if phone > 0.0:
		figure.shoulders[1].rotation = Vector3(lerpf(figure.shoulders[1].rotation.x, 1.35, phone), 0, -0.3 * phone)
		figure.spine.rotation.x = -0.12 * phone

## Distance from a point to the nearest segment of the quad paths (tests use it).
static func distance_to_paths(point: Vector2) -> float:
	var best := INF
	for edge in EDGES:
		var a: Vector2 = NODES[edge[0]]
		var b: Vector2 = NODES[edge[1]]
		var t := clampf((point - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		best = minf(best, point.distance_to(a.lerp(b, t)))
	return best

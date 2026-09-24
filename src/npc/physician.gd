extends Node3D
## Dr. Maya Okafor, the attending the student shadows. She walks the hospital
## on routes of named anchors (straight legs the scene keeps clear), checks
## over her shoulder and waits when the student falls behind, pauses instead
## of walking through them, and turns to whoever she is talking to. While a
## line is typing she talks with small hand gestures, like the lecturer.
## Solid to the player (NPC layer). Local forward is −Z, as for every figure.
signal arrived
signal lagging_changed(lagging: bool)
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
const Nameplate = preload("res://ui/world_nameplate.gd")
const WALK_SPEED := 1.35
## Farther than this and she stops to wait; she walks on once the student is within RESUME_DISTANCE.
const LAG_DISTANCE := 6.5
const RESUME_DISTANCE := 3.2
## She will not step closer than this to the student standing in her way.
const PERSONAL_SPACE := 0.7
@export var preset := "okafor"
## What she says when the student falls behind (set from the shadowing script).
var wait_line := "Stay with me."
var appearance: Node3D
var blocker: AnimatableBody3D
var speech: Label3D
## The figure to keep with (the player) and to face while talking.
var companion: Node3D
var path: Array[Vector3] = []
var walking := false
var lagging := false
var face_target := Vector3.INF
var speaking := false
var gesture := "none"
var time := 0.0
var talk := 0.0
var speech_timer := 0.0
## Seconds spent waiting for the student to step out of the way.
var blocked_time := 0.0
## Distance walked (tests confirm that she really moves).
var distance_walked := 0.0

func _ready() -> void:
	appearance = Appearance.new()
	appearance.name = "Appearance"
	add_child(appearance)
	appearance.apply_preset(preset)
	blocker = Student.make_blocker(self)
	speech = Nameplate.new()
	speech.name = "Speech"
	speech.position = Vector3(0, 2.25, 0)
	speech.font_size = 26
	speech.pixel_size = 0.0065
	speech.visible = false
	add_child(speech)

## Walks through `points` in order (world positions on the floor).
func walk(points: Array) -> void:
	path.clear()
	for point in points:
		path.append(Vector3(point.x, global_position.y, point.z))
	walking = not path.is_empty()
	face_target = Vector3.INF
	if not walking:
		arrived.emit()

## Instant move (scene load, elevator arrival).
func place(point: Vector3, yaw: float) -> void:
	path.clear()
	walking = false
	global_position = point
	appearance.rotation.y = yaw

func stop() -> void:
	path.clear()
	walking = false

## Turns to face a point (or the companion when `point` is INF and `at_companion`).
func face(point: Vector3) -> void:
	face_target = point

func set_line(line_gesture: String) -> void:
	gesture = line_gesture

func set_speaking(value: bool) -> void:
	speaking = value

## A short line in a speech bubble (the only kind of label that floats).
func say(text: String, seconds := 3.0) -> void:
	speech.text = text
	speech.visible = not text.is_empty()
	speech_timer = seconds

func companion_distance() -> float:
	if not is_instance_valid(companion) or not companion.is_inside_tree():
		return 0.0
	var offset := companion.global_position - global_position
	return Vector2(offset.x, offset.z).length()

func _process(delta: float) -> void:
	time += delta
	if speech_timer > 0.0:
		speech_timer -= delta
		if speech_timer <= 0.0:
			speech.visible = false
	var moved := 0.0
	if walking:
		moved = _walk(delta)
	elif face_target != Vector3.INF:
		_turn_toward(face_target, delta)
	appearance.animate_motion(moved, delta)
	_gesture(delta)

func _walk(delta: float) -> float:
	var distance := companion_distance()
	if lagging and distance < RESUME_DISTANCE:
		_set_lagging(false)
	elif not lagging and distance > LAG_DISTANCE:
		_set_lagging(true)
		say(wait_line, 2.5)
	if lagging:
		_turn_toward(companion.global_position, delta)
		return 0.0
	var target := path[0]
	var to := target - global_position
	to.y = 0.0
	var length := to.length()
	if length < 0.04:
		path.pop_front()
		if path.is_empty():
			walking = false
			arrived.emit()
		return 0.0
	var direction := to / length
	# Pause rather than walk into the student standing in the way.
	if is_instance_valid(companion) and distance < PERSONAL_SPACE + 0.4:
		var to_companion := companion.global_position - global_position
		to_companion.y = 0.0
		if to_companion.length() < PERSONAL_SPACE and direction.dot(to_companion.normalized()) > 0.75:
			_turn_toward(target, delta)
			return 0.0
	var step := minf(length, WALK_SPEED * delta)
	global_position += direction * step
	distance_walked += step
	_turn_toward(global_position + direction, delta)
	return step

func _set_lagging(value: bool) -> void:
	lagging = value
	lagging_changed.emit(value)

func _turn_toward(point: Vector3, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	appearance.rotation.y = lerp_angle(appearance.rotation.y, atan2(-to.x, -to.z), 1.0 - exp(-8.0 * delta))

## Talking hands while a line types; still otherwise.
func _gesture(delta: float) -> void:
	var body: Node3D = appearance.body
	if walking or not is_instance_valid(body):
		talk = 0.0
		return
	talk = lerpf(talk, 1.0 if speaking else 0.0, 1.0 - exp(-5.0 * delta))
	var spine: Node3D = appearance.spine
	spine.rotation.x = 0.025 * sin(time * 1.6) - 0.04 * talk * (0.5 + 0.5 * sin(time * 2.3))
	spine.rotation.y = 0.1 * talk * sin(time * 1.1)
	for index in range(2):
		var beat := talk * (0.4 + 0.22 * sin(time * 3.1 + index * 1.9))
		appearance.shoulders[index].rotation = Vector3(beat, 0, 0.08 * talk * (1 if index else -1))

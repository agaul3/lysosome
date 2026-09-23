extends Node3D
## The lecturer at the podium. Idles with slight breathing and weight shifts,
## gestures with alternating hands while speaking, and half-turns to point at
## the screen for "screen" lines. All changes are smoothed so poses blend.
const Appearance = preload("res://player/appearance.gd")
@export var preset := "professor"
## World point the professor points toward for "screen" gestures.
var screen_point := Vector3.ZERO
var audience_yaw := PI
var appearance: Node3D
var speaking := false
var gesture := "audience"
var time := 0.0
var turn := 0.0 # 0 = facing the audience, 1 = turned toward the screen
var point := 0.0 # right-arm pointing weight
var talk := 0.0 # talking-gesture weight

func _ready() -> void:
	appearance = Appearance.new()
	appearance.name = "Appearance"
	add_child(appearance)
	appearance.apply_preset(preset)
	appearance.rotation.y = audience_yaw

func set_line(line_gesture: String) -> void:
	gesture = line_gesture

func set_speaking(value: bool) -> void:
	speaking = value

func screen_yaw() -> float:
	var to_screen := screen_point - global_position
	return atan2(-to_screen.x, -to_screen.z)

func _process(delta: float) -> void:
	time += delta
	var rate := 1.0 - exp(-5.0 * delta)
	var wants_screen := gesture == "screen"
	turn = lerpf(turn, 0.55 if wants_screen else 0.0, rate)
	point = lerpf(point, 1.0 if wants_screen and speaking else (0.35 if wants_screen else 0.0), rate)
	talk = lerpf(talk, 1.0 if speaking else 0.0, rate)
	appearance.rotation.y = lerp_angle(audience_yaw, screen_yaw(), turn)
	var body: Node3D = appearance.body
	var spine: Node3D = appearance.spine
	if not is_instance_valid(body):
		return
	# Breathing and a slow weight shift.
	spine.rotation.x = 0.03 * sin(time * 1.6) - 0.05 * talk * (0.5 + 0.5 * sin(time * 2.3))
	body.rotation.z = 0.02 * sin(time * 0.5)
	spine.rotation.y = 0.12 * talk * sin(time * 1.1) * (1.0 - point)
	# Point with whichever arm is on the screen's side.
	var screen_on_right: bool = appearance.to_local(screen_point).x > 0.0
	var pointing_arm: Node3D = appearance.shoulders[1] if screen_on_right else appearance.shoulders[0]
	var free_arm: Node3D = appearance.shoulders[0] if screen_on_right else appearance.shoulders[1]
	var outward := 1.0 if screen_on_right else -1.0
	# Talking: hands come forward and move in small alternating beats.
	var beat_free := talk * (0.45 + 0.25 * sin(time * 3.1))
	var beat_point := talk * (0.45 + 0.25 * sin(time * 3.1 + 1.9))
	free_arm.rotation = Vector3(beat_free, 0, 0.1 * talk * -outward)
	# Pointing: arm raised forward-up toward the screen.
	pointing_arm.rotation = Vector3(lerpf(beat_point, 1.35, point), 0, lerpf(0.1 * talk, 0.25, point) * outward)

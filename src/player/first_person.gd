extends Node3D
## First-person view: a camera at the student's eyes.
##
## The mouse (or the right stick) looks around; walking is relative to where
## you look, and the body turns with the view. The player's own head renders
## as shadow only while this view is on, so looking down shows your body and
## your whole shadow, head included. The eyes follow the body (softened walk
## bob, the lean of a sprint, the lowering as you sit). Sitting and standing turn the view with
## the body; once seated you can look around the room, and a scene can give a
## point to settle the view on (the lecture screen). Physics-rate eye positions
## are interpolated per frame so motion stays smooth at any refresh rate.
signal activated(enabled: bool)
const MOUSE_RADIANS := 0.0022 # per screen pixel at look sensitivity 1
const STICK_SPEED := 2.6 # radians per second at full deflection
const PITCH_MIN := -1.4
const PITCH_MAX := 1.3
## Seated, the view can turn this far either side of the way the seat faces.
const SEATED_YAW_RANGE := 1.9
## Share of the walk cycle's head motion that reaches the eyes (0 steady, 1 full).
const BOB := 0.45
const FOV := 74.0
var camera: Camera3D
var player: CharacterBody3D
var active := false
## World yaw of the view (0 looks toward −Z, like the body) and pitch (up +).
var yaw := 0.0
var pitch := 0.0
## Where the view settles while sitting down and seated, until you look around.
var focus_point := Vector3.INF
var previous_eye := Vector3.ZERO
var current_eye := Vector3.ZERO
var captured := false

func _ready() -> void:
	player = get_parent()
	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.top_level = true
	camera.fov = FOV
	camera.near = 0.04
	camera.far = 320.0
	add_child(camera)
	yaw = body_yaw()
	current_eye = eye_target()
	previous_eye = current_eye
	AppState.view_changed.connect(set_active)
	# Deferred: the scene's own camera makes itself current while the scene loads.
	set_active.call_deferred(AppState.first_person)

func set_active(enabled: bool) -> void:
	if enabled == active:
		return
	active = enabled
	if enabled:
		yaw = body_yaw()
		pitch = -0.08
		if is_seated() and focus_point != Vector3.INF:
			_face(focus_point, 1.0)
		current_eye = eye_target()
		previous_eye = current_eye
		_place_camera(current_eye)
		camera.current = true
	elif camera.current and is_instance_valid(player.movement_camera):
		player.movement_camera.current = true
	player.interaction.view_forward = Vector3.ZERO
	set_head_hidden(enabled)
	player.set_silhouette(not enabled and player.seating.state == player.seating.State.FREE)
	_update_mouse()
	activated.emit(enabled)

## The head is drawn as shadow only in first person: invisible to every camera,
## but its shadow still falls with the body's.
func set_head_hidden(hidden: bool) -> void:
	for part in player.appearance.head_parts:
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if hidden else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func body_yaw() -> float:
	return player.appearance.global_rotation.y

func is_seated() -> bool:
	return player.seating.state == player.seating.State.SEATED

## Sitting and standing move the body on a script; the view goes with it.
func is_body_driven() -> bool:
	return player.seating.state in [player.seating.State.SITTING, player.seating.State.RISING]

## Settles the view on a point while seated (cleared as soon as you look around).
func focus(point: Vector3) -> void:
	focus_point = point

## The mouse is captured for looking whenever first person is on and no menu is open.
func wants_capture() -> bool:
	return active and player.movement_enabled and is_inside_tree()

func _update_mouse() -> void:
	var want := wants_capture()
	if want == captured:
		return
	captured = want
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if want else Input.MOUSE_MODE_VISIBLE

func _exit_tree() -> void:
	if captured:
		captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and wants_capture():
		look((event as InputEventMouseMotion).screen_relative * MOUSE_RADIANS * AppState.look_sensitivity)

## Turns the view by (yaw, pitch) radians, as the mouse or stick does.
func look(amount: Vector2) -> void:
	if not active or is_body_driven():
		return
	focus_point = Vector3.INF
	yaw = wrapf(yaw - amount.x, -PI, PI)
	pitch = clampf(pitch - amount.y, PITCH_MIN, PITCH_MAX)
	if is_seated():
		var around := clampf(wrapf(yaw - body_yaw(), -PI, PI), -SEATED_YAW_RANGE, SEATED_YAW_RANGE)
		yaw = wrapf(body_yaw() + around, -PI, PI)

## Eases the view toward a point (a scene turning the student to a speaker).
func turn_toward(point: Vector3, weight: float) -> void:
	if active and not is_body_driven():
		_face(point, weight)

func _face(point: Vector3, weight: float) -> void:
	var to := point - camera.global_position if camera.is_inside_tree() else point - current_eye
	if to.length() < 0.01:
		return
	var goal_yaw := atan2(-to.x, -to.z)
	var goal_pitch := clampf(atan2(to.y, Vector2(to.x, to.z).length()), PITCH_MIN, PITCH_MAX)
	yaw = lerp_angle(yaw, goal_yaw, weight)
	pitch = lerpf(pitch, goal_pitch, weight)

## Eye position from the head bone, with the walk cycle softened.
func eye_target() -> Vector3:
	var appearance: Node3D = player.appearance
	var bone: Vector3 = appearance.spine.to_global(appearance.EYE)
	if appearance.seated_pose:
		return bone
	var steady: Vector3 = appearance.to_global(Vector3(0, appearance.HIP_HEIGHT + appearance.EYE.y, appearance.EYE.z))
	return steady.lerp(bone, BOB)

func _physics_process(_delta: float) -> void:
	# Runs after the player and seating have moved and posed the body this tick.
	previous_eye = current_eye
	current_eye = eye_target()

func _process(delta: float) -> void:
	if not active:
		return
	_update_mouse()
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick != Vector2.ZERO and wants_capture():
		look(stick * STICK_SPEED * AppState.look_sensitivity * delta)
	var ease := 1.0 - exp(-7.0 * delta)
	if is_body_driven():
		# Turn with the body; look toward the focus as you settle, otherwise ahead.
		yaw = lerp_angle(yaw, body_yaw(), ease)
		pitch = lerpf(pitch, -0.08, ease)
		if player.seating.state == player.seating.State.SITTING and focus_point != Vector3.INF and player.appearance.sit_blend > 0.3:
			_face(focus_point, ease)
	elif is_seated() and focus_point != Vector3.INF:
		_face(focus_point, ease)
	var eye := previous_eye.lerp(current_eye, Engine.get_physics_interpolation_fraction())
	_place_camera(eye)
	var forward := -camera.global_basis.z
	player.interaction.view_forward = Vector3(forward.x, 0, forward.z).normalized()

func _place_camera(eye: Vector3) -> void:
	camera.global_transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch), eye)

func view_basis() -> Basis:
	return Basis(Vector3.UP, yaw)

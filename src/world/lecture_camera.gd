extends Camera3D
## Seated lecture view with a smooth hand-off from the orthographic
## exploration camera. An orthographic view is matched by a perspective camera
## with a very narrow field of view placed far back along the same ray, framing
## the same height at the focal point. The blend then interpolates the focal
## point, view direction, framed height and field of view together (distance is
## derived from the last two), so the picture changes continuously from the
## isometric view to the over-the-shoulder view with no cut or pop.
signal transition_finished(entered: bool)
const START_FOV := 5.0
const LECTURE_FOV := 52.0
const DURATION := 1.7
const ARC_HEIGHT := 1.4

var exploration: Camera3D
## Blend parameter: 0 = exploration framing, 1 = lecture pose.
var blend := 0.0
var direction := 0 # +1 entering, -1 leaving, 0 idle.
var from_focal := Vector3.ZERO
var from_forward := Vector3.FORWARD
var from_height := 10.0
var pose := Transform3D.IDENTITY
var pose_distance := 5.0

func _ready() -> void:
	projection = Camera3D.PROJECTION_PERSPECTIVE
	near = 0.05
	far = 400.0
	current = false

func active() -> bool:
	return current

func in_lecture_view() -> bool:
	return current and direction == 0 and blend >= 1.0

func enter(from_camera: Camera3D, lecture_pose: Transform3D) -> void:
	exploration = from_camera
	pose = lecture_pose
	pose_distance = 6.0
	_capture_exploration()
	if not current:
		blend = 0.0
	direction = 1
	current = true
	_apply()

func leave() -> void:
	if not current:
		return
	_capture_exploration()
	direction = -1

## Framing of the exploration camera: the point it looks at, its view
## direction and the vertical extent it shows.
func _capture_exploration() -> void:
	if not is_instance_valid(exploration):
		return
	from_forward = -exploration.global_basis.z
	from_height = exploration.size
	var look: Vector3 = exploration.tracked_point if "tracked_point" in exploration else exploration.global_position + from_forward * 20.0
	from_focal = look

func _process(delta: float) -> void:
	if direction == 0:
		return
	blend = clampf(blend + direction * delta / DURATION, 0.0, 1.0)
	_apply()
	if direction > 0 and blend >= 1.0:
		direction = 0
		transition_finished.emit(true)
	elif direction < 0 and blend <= 0.0:
		direction = 0
		current = false
		if is_instance_valid(exploration):
			exploration.current = true
		transition_finished.emit(false)

func _apply() -> void:
	var t := blend * blend * blend * (blend * (blend * 6.0 - 15.0) + 10.0) # smootherstep
	var to_forward := -pose.basis.z
	var to_focal := pose.origin + to_forward * pose_distance
	var to_half_tan := tan(deg_to_rad(LECTURE_FOV) / 2.0)
	var to_height := 2.0 * pose_distance * to_half_tan
	var from_half_tan := tan(deg_to_rad(START_FOV) / 2.0)
	# Interpolate in log space so the zoom feels even across the large range.
	var half_tan := exp(lerpf(log(from_half_tan), log(to_half_tan), t))
	var height := exp(lerpf(log(from_height), log(to_height), t))
	var forward := Quaternion(Basis.looking_at(from_forward, Vector3.UP)).slerp(Quaternion(pose.basis.orthonormalized()), t)
	var basis_now := Basis(forward)
	var focal := from_focal.lerp(to_focal, t)
	var distance := height / (2.0 * half_tan)
	fov = rad_to_deg(2.0 * atan(half_tan))
	# A far-away camera needs a far-away near plane for depth precision.
	near = maxf(0.05, lerpf(distance * 0.15, 0.05, t))
	far = distance + 120.0
	# Arc over the audience: lift along the view's up axis mid-blend so the
	# final approach settles down from above rather than skimming past heads.
	var lift := basis_now.y * ARC_HEIGHT * sin(PI * t)
	global_transform = Transform3D(basis_now, focal + basis_now.z * distance + lift)

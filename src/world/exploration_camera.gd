extends Camera3D
## Fixed dorm framing; optional bounded follow for larger exploration spaces.
@export var focal_point := Vector3.ZERO
@export var view_size := 15.5
@export var offset := Vector3(11, 14, 14)
@export var follow_speed := 5.0
@export var follow_min := Vector2(-6, -5)
@export var follow_max := Vector2(6, 5)
var follow_target: Node3D
var tracked_point := Vector3.ZERO

func _ready() -> void:
	far = 80.0
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = view_size
	tracked_point = focal_point
	position = tracked_point + offset
	look_at(tracked_point)
	current = true

func follow(target: Node3D) -> void:
	follow_target = target
	tracked_point = _bounded_target()
	global_position = tracked_point + offset
	look_at(tracked_point)

func _bounded_target() -> Vector3:
	return Vector3(clampf(follow_target.global_position.x, follow_min.x, follow_max.x), focal_point.y, clampf(follow_target.global_position.z, follow_min.y, follow_max.y))

func _process(delta: float) -> void:
	if not is_instance_valid(follow_target):
		return
	tracked_point = tracked_point.lerp(_bounded_target(), 1.0 - exp(-follow_speed * delta))
	global_position = tracked_point + offset
	# Translation-only follow preserves the movement basis and isometric angle.

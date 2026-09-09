extends Camera3D
## Fixed room framing prevents camera jitter and keeps every doorway visible.
## A separate component lets future scenes substitute follow/lecture cameras.
@export var focal_point := Vector3(0, 0, 0)

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = 15.5
	position = Vector3(11, 14, 14)
	look_at(focal_point)
	current = true

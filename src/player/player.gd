extends CharacterBody3D
const Presets = preload("res://data/character_presets.gd")
@export var speed: float = 3.2
@export var gravity: float = 18.0
@export var movement_enabled := true
var movement_camera: Camera3D
@onready var appearance: Node3D = $Appearance
@onready var interaction: Node3D = $Interaction

func _ready() -> void:
	appearance.apply_preset(AppState.selected_character)

func world_direction(input_vector: Vector2) -> Vector3:
	var direction := Vector3(input_vector.x, 0, input_vector.y)
	if is_instance_valid(movement_camera):
		var right := movement_camera.global_basis.x
		var backward := movement_camera.global_basis.z
		right.y = 0
		backward.y = 0
		direction = right.normalized() * input_vector.x + backward.normalized() * input_vector.y
	return direction.limit_length(1.0)

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down") if movement_enabled else Vector2.ZERO
	var direction := world_direction(input_vector)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	var previous_position := global_position
	move_and_slide() # Velocity is units/second; Godot integrates using the physics delta.
	var travelled := global_position - previous_position
	appearance.animate_motion(Vector2(travelled.x, travelled.z).length(), delta)
	if direction.length_squared() > 0.01:
		appearance.rotation.y = lerp_angle(appearance.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-16.0 * delta))

extends CharacterBody3D
const Presets = preload("res://data/character_presets.gd")
@export var speed: float = 3.2
@export var sprint_speed: float = 5.8
## Seconds to reach full sprint speed or settle back to a walk.
@export var sprint_ramp: float = 0.25
var current_speed := 3.2
## Minecraft-style sprint: tap a movement key twice within this window and
## keep holding to sprint in that direction. Sprint ends when movement stops.
const DOUBLE_TAP_WINDOW := 0.3
const MOVE_ACTIONS := ["move_up", "move_down", "move_left", "move_right"]
var sprint_latched := false
var last_tap := {}
@export var gravity: float = 18.0
@export var movement_enabled := true
## Set while a scripted motion (sitting, standing) drives the body instead of input.
var external_control := false
var seating: Node
var movement_camera: Camera3D
@onready var appearance: Node3D = $Appearance
@onready var interaction: Node3D = $Interaction

func _ready() -> void:
	appearance.apply_preset(AppState.selected_character)
	current_speed = speed
	collision_mask |= 4 # Also collide with NPCs (layer 3); interaction rays stay world-only.
	seating = preload("res://player/seating.gd").new()
	seating.name = "Seating"
	add_child(seating)

func world_direction(input_vector: Vector2) -> Vector3:
	var direction := Vector3(input_vector.x, 0, input_vector.y)
	if is_instance_valid(movement_camera):
		var right := movement_camera.global_basis.x
		var backward := movement_camera.global_basis.z
		right.y = 0
		backward.y = 0
		direction = right.normalized() * input_vector.x + backward.normalized() * input_vector.y
	return direction.limit_length(1.0)

func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled or external_control or event.is_echo():
		return
	for action in MOVE_ACTIONS:
		if event.is_action_pressed(action):
			var now := Time.get_ticks_msec() / 1000.0
			if now - float(last_tap.get(action, -10.0)) <= DOUBLE_TAP_WINDOW:
				sprint_latched = true
			last_tap[action] = now

func _physics_process(delta: float) -> void:
	if external_control:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down") if movement_enabled else Vector2.ZERO
	var direction := world_direction(input_vector)
	var moving := direction.length_squared() > 0.25
	if not moving or not movement_enabled:
		sprint_latched = false
	var sprinting := movement_enabled and moving and (sprint_latched or Input.is_action_pressed("sprint"))
	var target_speed := sprint_speed if sprinting else speed
	current_speed = move_toward(current_speed, target_speed, (sprint_speed - speed) / sprint_ramp * delta)
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	var previous_position := global_position
	move_and_slide() # Velocity is units/second; Godot integrates using the physics delta.
	var travelled := global_position - previous_position
	appearance.animate_motion(Vector2(travelled.x, travelled.z).length(), delta)
	if direction.length_squared() > 0.01:
		appearance.rotation.y = lerp_angle(appearance.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-16.0 * delta))

extends Node
## Player-side seat use: plans an approach from the side the player is on,
## walks there with real collision, then plays the kinematic sit. Interacting
## with the same seat while seated stands back up.
signal seated_changed(seated: bool)
signal notice(text: String)
signal state_changed(state: int)
const SitSequence = preload("res://player/sit_sequence.gd")
const STUCK_SECONDS := 0.8
enum State { FREE, SITTING, SEATED, RISING }
var state := State.FREE
var seat: Node3D
var approach := ""
var sequence: SitSequence
var player: CharacterBody3D
var stuck_time := 0.0
var best_distance := INF
var walk_target := Vector3.INF
## The lecture can lock the player in the seat once class begins.
var stand_locked := false

func _ready() -> void:
	player = get_parent()

func busy() -> bool:
	return state != State.FREE

func request(target: Node3D) -> void:
	if state == State.SEATED and target == seat:
		stand_up()
		return
	if state != State.FREE or not target.is_free():
		return
	var plan: Dictionary
	if target.navigator.is_valid():
		plan = SitSequence.plan_row_sit(target, player.global_position, target.navigator.call(player.global_position, target))
	else:
		plan = SitSequence.plan_sit(target, player.global_position, _is_clear)
	if plan.steps.is_empty():
		notice.emit("There's no room to get into that seat.")
		return
	seat = target
	seat.occupant = player
	approach = plan.approach
	_begin(State.SITTING, plan.steps)

func stand_up() -> void:
	if state != State.SEATED or stand_locked:
		return
	_begin(State.RISING, SitSequence.plan_rise(seat))

func _begin(next: State, steps: Array) -> void:
	state = next
	state_changed.emit(state)
	player.external_control = true
	player.velocity = Vector3.ZERO
	player.interaction.enabled = false
	sequence = SitSequence.new(player, player.appearance)
	sequence.walk_handler = _walk
	stuck_time = 0.0
	best_distance = INF
	walk_target = Vector3.INF
	sequence.start(steps)

func _physics_process(delta: float) -> void:
	if state in [State.FREE, State.SEATED] or sequence == null:
		return
	if not sequence.advance(delta):
		return
	if state == State.SITTING:
		state = State.SEATED
		seat.interactable.display_name = "Stand up"
		seat.interactable.marker_enabled = false
		player.interaction.enabled = true
		# Listeners (e.g. a lecture locking the seat) run after seating settles.
		state_changed.emit(state)
		seated_changed.emit(true)
	else:
		_release()
		seated_changed.emit(false)

func _release() -> void:
	if is_instance_valid(seat):
		seat.interactable.display_name = "Sit down"
		seat.interactable.marker_enabled = true
		seat.occupant = null
	seat = null
	state = State.FREE
	player.external_control = false
	player.interaction.enabled = true
	state_changed.emit(state)

## Walking uses the body's own collision so the approach can never pass through furniture.
func _walk(target: Vector3, delta: float) -> bool:
	if not target.is_equal_approx(walk_target):
		walk_target = target
		best_distance = INF
		stuck_time = 0.0
	var offset := target - player.global_position
	offset.y = 0
	var distance := offset.length()
	if distance < 0.04:
		# Sub-4 cm correction so the kinematic steps start from the exact waypoint.
		player.global_position = Vector3(target.x, player.global_position.y, target.z)
		player.velocity = Vector3.ZERO
		player.appearance.animate_motion(distance, delta)
		return true
	var speed := clampf(distance * 5.0, 0.45, SitSequence.WALK_SPEED)
	var direction := offset / distance
	player.velocity = Vector3(direction.x * speed, 0.0 if player.is_on_floor() else player.velocity.y - player.gravity * delta, direction.z * speed)
	var previous := player.global_position
	player.move_and_slide()
	var travelled := player.global_position - previous
	player.appearance.animate_motion(Vector2(travelled.x, travelled.z).length(), delta)
	player.appearance.rotation.y = lerp_angle(player.appearance.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-14.0 * delta))
	if distance < best_distance - 0.01:
		best_distance = distance
		stuck_time = 0.0
	else:
		stuck_time += delta
		if stuck_time > STUCK_SECONDS:
			_abort()
	return false

func _abort() -> void:
	sequence = null
	_release()
	notice.emit("Something is in the way of that seat.")

func _is_clear(point: Vector3) -> bool:
	var shape: CollisionShape3D = player.get_node("CollisionShape3D")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.transform = Transform3D(Basis.IDENTITY, point + shape.position + Vector3(0, 0.05, 0))
	query.collision_mask = player.collision_mask
	query.margin = 0.02
	return player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

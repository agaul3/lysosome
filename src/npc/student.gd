extends Node3D
## Scene-local view of persistent NPC state. Does not own the schedule or reset it.
const SitSequence = preload("res://player/sit_sequence.gd")
const Seat = preload("res://world/seat.gd")
@export var actor_id := "alex"
@export var world_zone := "campus"
## Optional chair the actor sits in when the schedule reaches SEATED.
var seat: Node3D
@onready var appearance: Node3D = $Appearance
@onready var speech: Label3D = $Speech
var was_seated := false
var sit_sequence: SitSequence
var sit_approach := ""

func _ready() -> void:
	appearance.apply_preset("ochre" if actor_id == "alex" else "indigo")
	_sync(false)

func _process(delta: float) -> void:
	if sit_sequence != null:
		if sit_sequence.advance(delta):
			sit_sequence = null
		_sync_speech()
		return
	var previous := position
	var was_visible := visible
	_sync(was_visible)
	var distance := position.distance_to(previous) if was_visible and visible else 0.0
	# Zone transitions are teleports, not walking strides.
	appearance.animate_motion(distance if distance < 1.0 else 0.0, delta)

func _sync(on_screen := false) -> void:
	visible = NPCSchedule.zone == world_zone if actor_id == "alex" else world_zone == "campus"
	if not visible:
		return
	var seated := actor_id == "alex" and NPCSchedule.stage == NPCSchedule.Stage.SEATED
	if seated and is_instance_valid(seat):
		# Animate only when actually watched arriving at the seat; after a time
		# skip or a scene load, appear already seated.
		if not was_seated and on_screen and global_position.distance_to(seat.point(Seat.FRONT_POINT)) < 0.3:
			# Watched arriving: turn, side-step in front of the chair and sit down.
			was_seated = true
			var plan: Dictionary
			if seat.navigator.is_valid():
				# Row seat: the route already ends at the seat's front point.
				plan = SitSequence.plan_row_sit(seat, global_position, PackedVector3Array([seat.point(Seat.FRONT_POINT)]))
			else:
				plan = SitSequence.plan_sit(seat, global_position)
			sit_approach = plan.approach
			sit_sequence = SitSequence.new(self, appearance)
			sit_sequence.start(plan.steps)
			_sync_speech()
			return
		global_position = seat.point(Seat.SIT_POINT)
		appearance.rotation.y = seat.seated_yaw()
	else:
		position = NPCSchedule.actor_position if actor_id == "alex" else Vector3(3.5, 0, -0.5)
		var direction := NPCSchedule.facing if actor_id == "alex" else Vector3.BACK
		appearance.rotation.y = atan2(-direction.x, -direction.z)
	if seated != was_seated:
		appearance.set_seated(seated)
		was_seated = seated
	_sync_speech()

func _sync_speech() -> void:
	speech.text = ("Alex: " if actor_id == "alex" else "Sam: ") + NPCSchedule.dialogue_text
	speech.visible = NPCSchedule.dialogue_speaker == actor_id and not NPCSchedule.dialogue_text.is_empty()

extends Node3D
## Scene-local view of persistent NPC state. Does not own the schedule or reset it.
@export var actor_id := "alex"
@export var world_zone := "campus"
@onready var appearance: Node3D = $Appearance
@onready var speech: Label3D = $Speech
var was_seated := false

func _ready() -> void:
	appearance.apply_preset("ochre" if actor_id == "alex" else "indigo")
	_sync()

func _process(delta: float) -> void:
	var previous := position
	var was_visible := visible
	_sync()
	var distance := position.distance_to(previous) if was_visible and visible else 0.0
	# Zone transitions are teleports, not walking strides.
	appearance.animate_motion(distance if distance < 1.0 else 0.0, delta)

func _sync() -> void:
	visible = NPCSchedule.zone == world_zone if actor_id == "alex" else world_zone == "campus"
	if not visible:
		return
	position = NPCSchedule.actor_position if actor_id == "alex" else Vector3(3.5, 0, -0.5)
	var direction := NPCSchedule.facing if actor_id == "alex" else Vector3.BACK
	appearance.rotation.y = atan2(-direction.x, -direction.z)
	var seated := actor_id == "alex" and NPCSchedule.stage == NPCSchedule.Stage.SEATED
	if seated != was_seated:
		appearance.set_seated(seated)
		was_seated = seated
	speech.text = ("Alex: " if actor_id == "alex" else "Sam: ") + NPCSchedule.dialogue_text
	speech.visible = NPCSchedule.dialogue_speaker == actor_id and not NPCSchedule.dialogue_text.is_empty()

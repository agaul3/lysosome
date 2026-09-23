extends Node3D
## A solid chair the player or an NPC can sit in. Local -Z is the direction a
## seated person faces; the backrest is on +Z. Approach points are local and
## sized for the player's 0.27 m capsule so every walking leg stays clear of
## the chair's colliders. Only the final side-step/back-step and the sit
## itself enter the chair's footprint, and those are animated kinematically.
signal sit_requested(seat: Node3D)
const Geometry = preload("res://world/geometry.gd")
const Appearance = preload("res://player/appearance.gd")
const SEAT_TOP := 0.3
const WIDTH := 0.55
const DEPTH := 0.5
## Where the body origin rests when fully seated: hips on the cushion, backpack against the rest.
const SIT_POINT := Vector3(0, 0, -0.08)
## Standing just in front of the cushion, facing forward, ready to lower.
const PRE_SIT := Vector3(0, 0, -0.45)
## Walking target for a front approach; far enough out to turn around freely.
const FRONT_POINT := Vector3(0, 0, -0.95)
## Walking target beside the chair's front half; x sign selects the side.
const SIDE_POINT := Vector3(0.68, 0, -0.45)
## Detour corner used when arriving from behind the backrest.
const BACK_CORNER := Vector3(0.68, 0, 0.72)
## Where the player steps to after standing, clear of the chair collider.
const EXIT_POINT := Vector3(0, 0, -0.72)

@export var color := Color("387e92")
## Someone else's seat: no interaction, and a collider covers the seated legs.
@export var occupied := false
@export var occupant_preset := ""
var interactable: Node3D
var occupant: Node3D
var seated_figure: Node3D

func _ready() -> void:
	Geometry.box(self, "SeatBase", Vector3(WIDTH, SEAT_TOP, DEPTH), Vector3(0, SEAT_TOP / 2, 0), color.darkened(0.55), true).get_child(0).visible = false
	Geometry.box(self, "Cushion", Vector3(WIDTH, 0.08, DEPTH), Vector3(0, SEAT_TOP - 0.04, 0), color)
	for x in [-1, 1]:
		# Front legs stop under the cushion; rear legs rise to carry the backrest.
		Geometry.box(self, "ChairLeg", Vector3(0.05, SEAT_TOP - 0.08, 0.05), Vector3(x * (WIDTH / 2 - 0.04), (SEAT_TOP - 0.08) / 2, -(DEPTH / 2 - 0.04)), Color("2d3b40"))
		Geometry.box(self, "RearPost", Vector3(0.05, SEAT_TOP + 0.56, 0.05), Vector3(x * (WIDTH / 2 - 0.04), (SEAT_TOP + 0.56) / 2, DEPTH / 2 + 0.05), Color("2d3b40"))
		Geometry.box(self, "SideRail", Vector3(0.04, 0.04, 0.1), Vector3(x * (WIDTH / 2 - 0.04), SEAT_TOP - 0.06, DEPTH / 2), Color("2d3b40"))
	Geometry.box(self, "Backrest", Vector3(WIDTH, 0.42, 0.06), Vector3(0, SEAT_TOP + 0.36, DEPTH / 2 + 0.05), color, true)
	if occupied:
		# Seated knees and feet project past the cushion; keep walkers out of them.
		var legs := Geometry.box(self, "SeatedLegs", Vector3(0.48, 0.5, 0.32), Vector3(0, 0.25, -0.42), Color.BLACK, true)
		legs.get_child(0).visible = false
		if not occupant_preset.is_empty():
			seated_figure = Appearance.new()
			seated_figure.position = SIT_POINT
			add_child(seated_figure)
			seated_figure.apply_preset(occupant_preset)
			seated_figure.set_seated(true)
	else:
		interactable = preload("res://world/interactable.gd").new()
		interactable.display_name = "Sit down"
		interactable.reach = 1.6
		interactable.position = Vector3(0, 0.75, 0)
		interactable.activated.connect(func() -> void: sit_requested.emit(self))
		add_child(interactable)

func point(local_point: Vector3) -> Vector3:
	return to_global(local_point)

## World-space yaw that makes an Appearance face the seated direction.
func seated_yaw() -> float:
	var forward := -global_basis.z
	return atan2(-forward.x, -forward.z)

func is_free() -> bool:
	return not occupied and not is_instance_valid(occupant)

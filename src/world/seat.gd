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
const FRONT_POINT := Vector3(0, 0, -0.92)
## Walking target beside the chair's front half; x sign selects the side.
const SIDE_POINT := Vector3(0.68, 0, -0.45)
## Detour corner used when arriving from behind the backrest.
const BACK_CORNER := Vector3(0.68, 0, 0.72)
## Where the player steps to after standing, clear of the chair collider.
const EXIT_POINT := Vector3(0, 0, -0.72)

## "chair": free-standing, approachable from any clear side.
## "auditorium": fixed row seat with armrests; approached along the row walkway.
@export var style := "chair"
@export var color := Color("387e92")
## Someone else's seat: no interaction, and a collider covers the seated legs.
@export var occupied := false
@export var occupant_preset := ""
var interactable: Node3D
var occupant: Node3D
var seated_figure: Node3D
## Cushion width. Auditorium seats are wider so the stylized, broad-shouldered
## figures sit between the armrests without their arms passing through them.
var width := WIDTH
const AUDITORIUM_WIDTH := 0.8
## Centre-to-centre spacing for auditorium rows; armrests sit on the shared boundary.
const AUDITORIUM_PITCH := 0.92
## Row seats: func(from: Vector3, seat: Node3D) -> PackedVector3Array, ending at
## this seat's FRONT_POINT. Supplied by the room, which owns the walkway graph.
var navigator: Callable

func _ready() -> void:
	if style == "auditorium":
		_build_auditorium()
	else:
		_build_chair()
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

## Upholstered lecture-hall seat on a central pedestal with a tall padded back.
## The seat carries its left armrest; the room adds the last one at a row end.
func _build_auditorium() -> void:
	width = AUDITORIUM_WIDTH
	var frame := color.darkened(0.45)
	Geometry.box(self, "SeatBase", Vector3(width, SEAT_TOP, DEPTH), Vector3(0, SEAT_TOP / 2, 0), frame, true).get_child(0).visible = false
	_quiet(Geometry.box(self, "Pedestal", Vector3(0.12, SEAT_TOP - 0.08, 0.12), Vector3(0, (SEAT_TOP - 0.08) / 2, 0.02), Color("30292a")))
	Geometry.box(self, "Cushion", Vector3(width - 0.02, 0.1, DEPTH), Vector3(0, SEAT_TOP - 0.05, -0.01), color)
	Geometry.box(self, "Backrest", Vector3(width, 0.62, 0.07), Vector3(0, SEAT_TOP + 0.4, DEPTH / 2 + 0.05), frame, true).get_child(0).visible = false
	var back := Geometry.box(self, "BackPad", Vector3(width - 0.02, 0.62, 0.1), Vector3(0, SEAT_TOP + 0.4, DEPTH / 2 + 0.06), color)
	back.rotation.x = 0.06
	_quiet(Geometry.box(self, "BackShell", Vector3(width - 0.04, 0.56, 0.02), Vector3(0, SEAT_TOP + 0.38, DEPTH / 2 + 0.125), frame))
	add_armrest(-AUDITORIUM_PITCH / 2)

func add_armrest(x: float) -> void:
	var frame := color.darkened(0.45)
	_quiet(Geometry.box(self, "ArmPost", Vector3(0.05, 0.62, 0.08), Vector3(x, 0.31, 0.12), Color("30292a")))
	_quiet(Geometry.box(self, "Armrest", Vector3(0.05, 0.05, 0.46), Vector3(x, 0.63, 0.02), frame))

static func _quiet(node: Node3D) -> void:
	# Small parts skip shadow casting; a hall has many seats.
	(node.get_child(0) as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_chair() -> void:
	Geometry.box(self, "SeatBase", Vector3(WIDTH, SEAT_TOP, DEPTH), Vector3(0, SEAT_TOP / 2, 0), color.darkened(0.55), true).get_child(0).visible = false
	Geometry.box(self, "Cushion", Vector3(WIDTH, 0.08, DEPTH), Vector3(0, SEAT_TOP - 0.04, 0), color)
	for x in [-1, 1]:
		# Front legs stop under the cushion; rear legs rise to carry the backrest.
		Geometry.box(self, "ChairLeg", Vector3(0.05, SEAT_TOP - 0.08, 0.05), Vector3(x * (WIDTH / 2 - 0.04), (SEAT_TOP - 0.08) / 2, -(DEPTH / 2 - 0.04)), Color("2d3b40"))
		Geometry.box(self, "RearPost", Vector3(0.05, SEAT_TOP + 0.56, 0.05), Vector3(x * (WIDTH / 2 - 0.04), (SEAT_TOP + 0.56) / 2, DEPTH / 2 + 0.05), Color("2d3b40"))
		Geometry.box(self, "SideRail", Vector3(0.04, 0.04, 0.1), Vector3(x * (WIDTH / 2 - 0.04), SEAT_TOP - 0.06, DEPTH / 2), Color("2d3b40"))
	Geometry.box(self, "Backrest", Vector3(WIDTH, 0.42, 0.06), Vector3(0, SEAT_TOP + 0.36, DEPTH / 2 + 0.05), color, true)

func point(local_point: Vector3) -> Vector3:
	return to_global(local_point)

## World-space yaw that makes an Appearance face the seated direction.
func seated_yaw() -> float:
	var forward := -global_basis.z
	return atan2(-forward.x, -forward.z)

func is_free() -> bool:
	return not occupied and not is_instance_valid(occupant)

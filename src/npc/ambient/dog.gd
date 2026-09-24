extends Node3D
## A small procedural dog in the same low-poly style as the students: body,
## head with snout and floppy ears, collar, tail and four legs. Motion is
## driven by its owner (dog_walker.gd); this node only poses itself:
## a diagonal trot scaled by speed, tail wag, head up/down, sit and play bow.
const Geometry = preload("res://world/geometry.gd")
const COATS := [
	[Color("c8943e"), Color("e6c28a")], # golden
	[Color("3b3230"), Color("8a7a70")], # black with grey muzzle
	[Color("f1ebe0"), Color("d8c7b0")], # cream
	[Color("8a5a36"), Color("d8b48a")], # brown
]
## Overall size; the rig is scaled so the dog reads at the campus camera distance.
const SIZE := 1.2
var rig: Node3D
var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
## Pose inputs, set by the owner each frame.
var speed := 0.0
var sniffing := 0.0 # 0..1 head lowered to the ground
var sitting := 0.0 # 0..1
var bowing := 0.0 # 0..1 play bow
var wag_rate := 6.0
var gait := 0.0
var time := 0.0
## Point at the collar in world space (where the leash attaches).
var collar: Node3D

func build(coat_index: int) -> void:
	var coat: Array = COATS[coat_index % COATS.size()]
	var fur: Color = coat[0]
	var light: Color = coat[1]
	rig = Node3D.new()
	rig.name = "Rig"
	rig.scale = Vector3.ONE * SIZE
	add_child(rig)
	body = Node3D.new()
	body.name = "Body"
	body.position.y = 0.42
	rig.add_child(body)
	Geometry.box(body, "Torso", Vector3(0.26, 0.24, 0.58), Vector3(0, 0, 0.02), fur)
	Geometry.box(body, "Belly", Vector3(0.2, 0.06, 0.4), Vector3(0, -0.12, 0.02), light)
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.13, -0.3)
	body.add_child(head)
	Geometry.box(head, "Skull", Vector3(0.2, 0.19, 0.2), Vector3(0, 0.05, -0.06), fur)
	Geometry.box(head, "Snout", Vector3(0.12, 0.1, 0.13), Vector3(0, 0.0, -0.21), light)
	Geometry.box(head, "Nose", Vector3(0.05, 0.04, 0.03), Vector3(0, 0.035, -0.285), Color("1a1818"))
	for side in [-1, 1]:
		Geometry.box(head, "Eye", Vector3(0.03, 0.03, 0.01), Vector3(side * 0.055, 0.09, -0.165), Color("141212"))
		var ear := Geometry.box(head, "Ear", Vector3(0.05, 0.13, 0.08), Vector3(side * 0.11, 0.06, -0.03), fur.darkened(0.2))
		ear.rotation.z = side * 0.35
	collar = Node3D.new()
	collar.name = "Collar"
	collar.position = Vector3(0, -0.02, 0.02)
	head.add_child(collar)
	Geometry.box(head, "CollarBand", Vector3(0.22, 0.05, 0.08), Vector3(0, -0.04, 0.03), Color("c2452d"))
	tail = Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.08, 0.3)
	body.add_child(tail)
	Geometry.box(tail, "TailMesh", Vector3(0.05, 0.05, 0.24), Vector3(0, 0, 0.11), fur)
	tail.rotation.x = -0.7
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var hip := Node3D.new()
		hip.name = "Leg"
		hip.position = Vector3(corner.x * 0.085, -0.08, corner.y * 0.2)
		body.add_child(hip)
		Geometry.box(hip, "LegMesh", Vector3(0.07, 0.34, 0.07), Vector3(0, -0.17, 0), fur)
		Geometry.box(hip, "Paw", Vector3(0.08, 0.04, 0.1), Vector3(0, -0.33, -0.015), light)
		legs.append(hip)

## Poses the dog; call once per frame after moving it. `distance` is the
## ground distance travelled this frame.
func animate(distance: float, delta: float) -> void:
	time += delta
	if delta <= 0.0:
		return
	var moving := clampf(speed / 1.2, 0.0, 1.0) * (1.0 - sitting) * (1.0 - bowing)
	gait = fmod(gait + distance * TAU / (0.55 + 0.25 * clampf(speed / 3.0, 0.0, 1.0)), TAU)
	var run := clampf((speed - 1.6) / 1.4, 0.0, 1.0)
	for index in range(4):
		# Trot: diagonal pairs (front-left with back-right) move together.
		var pair := 0.0 if index in [0, 3] else PI
		var swing := sin(gait + pair) * lerpf(0.45, 0.8, run) * moving
		legs[index].rotation.x = swing
	# Sit folds the rear legs and lifts the chest; a play bow drops the chest.
	var rear_fold := sitting * 1.2
	legs[2].rotation.x += -rear_fold
	legs[3].rotation.x += -rear_fold
	legs[0].rotation.x += bowing * 0.9
	legs[1].rotation.x += bowing * 0.9
	body.rotation.x = sitting * 0.45 - bowing * 0.3
	body.position.y = 0.42 - sitting * 0.1 - bowing * 0.08 + absf(sin(gait)) * 0.03 * moving * (1.0 + run)
	head.rotation.x = -0.1 - sniffing * 0.75 - sitting * 0.35 + bowing * 0.25
	head.rotation.y = sin(time * 0.7) * 0.25 * (1.0 - moving)
	var wag := sin(time * wag_rate) * (0.35 + 0.35 * bowing)
	tail.rotation = Vector3(-0.7 + sitting * 0.9, wag, 0)

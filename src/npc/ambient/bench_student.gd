extends Node3D
## A student sitting on a campus bench, busy with one of three activities:
##   lunch   — sandwich in hand, taking the occasional bite; lunch box beside them
##   reading — holding an open book, turning a page now and then
##   notes   — notebook on the lap, writing in bursts, looking up to think
## Timing is randomised per student so the courtyard never moves in lockstep.
## The node sits at the bench's local seat position, facing the bench's front.
const Appearance = preload("res://player/appearance.gd")
const Geometry = preload("res://world/geometry.gd")
const ACTIVITIES := ["lunch", "reading", "notes"]
@export var activity := "reading"
@export var preset := "teal"
var figure: Node3D
var rng := RandomNumberGenerator.new()
var time := 0.0
var timer := 0.0
## 0..1 blend of the current gesture (a bite, a page turn, looking up).
var gesture := 0.0
var gesturing := false
var hand_prop: Node3D
var page: Node3D
## Count of completed gestures (tests read it to confirm the animation runs).
var gestures_done := 0

func _ready() -> void:
	rng.randomize()
	figure = Appearance.new()
	figure.name = "Figure"
	add_child(figure)
	figure.apply_preset(preset)
	figure.set_seated(true)
	time = rng.randf() * 10.0
	timer = rng.randf_range(1.0, 4.0)
	match activity:
		"lunch": _build_lunch()
		"reading": _build_reading()
		"notes": _build_notes()

func _build_lunch() -> void:
	# Sandwich in the right hand, lunch box and a drink on the bench beside.
	hand_prop = Node3D.new()
	hand_prop.position = Vector3(0, -0.46, -0.04)
	figure.shoulders[1].add_child(hand_prop)
	Geometry.box(hand_prop, "Bread", Vector3(0.12, 0.035, 0.1), Vector3(0, 0.03, 0), Color("e3c28c"))
	Geometry.box(hand_prop, "Filling", Vector3(0.125, 0.02, 0.105), Vector3(0, 0.0, 0), Color("6aa84f"))
	Geometry.box(hand_prop, "Bread2", Vector3(0.12, 0.035, 0.1), Vector3(0, -0.03, 0), Color("e3c28c"))
	Geometry.box(self, "LunchBox", Vector3(0.22, 0.08, 0.16), Vector3(-0.45, 0.33, 0.02), Color("5b8fb9"))
	Geometry.box(self, "LunchLid", Vector3(0.23, 0.02, 0.17), Vector3(-0.45, 0.38, 0.02), Color("3f6f96"))
	Geometry.box(self, "Drink", Vector3(0.07, 0.14, 0.07), Vector3(-0.3, 0.36, -0.06), Color("f1efe9"))
	Geometry.box(self, "DrinkLid", Vector3(0.075, 0.02, 0.075), Vector3(-0.3, 0.44, -0.06), Color("c2452d"))

func _build_reading() -> void:
	# An open book held in both hands in front of the chest.
	var book := Node3D.new()
	book.name = "Book"
	# Between the hands (arms raised ~1.1 rad), tilted up toward the face.
	book.position = Vector3(0, 0.34, -0.38)
	book.rotation.x = -1.05
	figure.spine.add_child(book)
	var cover := Color(["8b3a3a", "2f5d7c", "5c6b3a", "6b4f7d"][rng.randi() % 4])
	for side in [-1, 1]:
		var half := Geometry.box(book, "Cover", Vector3(0.16, 0.012, 0.22), Vector3(side * 0.08, 0, 0), cover)
		half.rotation.z = side * -0.22
		var pages := Geometry.box(book, "Pages", Vector3(0.15, 0.02, 0.21), Vector3(side * 0.078, 0.014, 0), Color("f4efe2"))
		pages.rotation.z = side * -0.22
	page = Node3D.new()
	page.name = "TurningPage"
	book.add_child(page)
	Geometry.box(page, "Page", Vector3(0.15, 0.004, 0.2), Vector3(0.075, 0.03, 0), Color("fbf7ec"))
	page.visible = false

func _build_notes() -> void:
	# Notebook on the lap, pen in the right hand.
	Geometry.box(figure.pelvis, "Notebook", Vector3(0.22, 0.015, 0.28), Vector3(0.02, 0.1, -0.22), Color("f4efe2"))
	Geometry.box(figure.pelvis, "NotebookCover", Vector3(0.23, 0.01, 0.29), Vector3(0.02, 0.09, -0.22), Color("2f5d7c"))
	hand_prop = Node3D.new()
	hand_prop.position = Vector3(0, -0.45, -0.02)
	figure.shoulders[1].add_child(hand_prop)
	var pen := Geometry.box(hand_prop, "Pen", Vector3(0.012, 0.012, 0.14), Vector3(0, 0.02, -0.03), Color("1d3557"))
	pen.rotation.x = 0.6

func _process(delta: float) -> void:
	time += delta
	timer -= delta
	if timer <= 0.0:
		gesturing = not gesturing
		if gesturing:
			timer = {"lunch": 2.2, "reading": 0.7, "notes": 1.6}[activity]
		else:
			gestures_done += 1
			timer = {"lunch": rng.randf_range(3.0, 7.0), "reading": rng.randf_range(5.0, 11.0), "notes": rng.randf_range(4.0, 8.0)}[activity]
	gesture = move_toward(gesture, 1.0 if gesturing else 0.0, delta * 2.5)
	var ease := gesture * gesture * (3.0 - 2.0 * gesture)
	var left: Node3D = figure.shoulders[0]
	var right: Node3D = figure.shoulders[1]
	var spine: Node3D = figure.spine
	# A slow, individual glance keeps each student subtly alive.
	var glance := sin(time * 0.37) * 0.12 + sin(time * 0.91) * 0.05
	match activity:
		"lunch":
			# Rest the sandwich near the lap, lift it to the mouth for a bite.
			right.rotation = Vector3(lerpf(0.75, 2.55, ease), 0, lerpf(0.0, -0.5, ease))
			left.rotation = Vector3(0.55, 0, 0.05)
			spine.rotation = Vector3(-0.04 - 0.05 * ease + sin(time * 9.0) * 0.012 * ease, glance * (1.0 - ease), 0)
		"reading":
			left.rotation = Vector3(1.1, 0, -0.05)
			right.rotation = Vector3(1.1 + 0.25 * ease, 0, 0.05 + 0.15 * ease)
			spine.rotation = Vector3(-0.14, glance * 0.3, 0)
			# Page turn: a page sweeps from right to left while the right hand lifts.
			page.visible = gesture > 0.01
			page.rotation.z = lerpf(0.2, PI - 0.2, ease)
		"notes":
			# Writing: small, quick pen movements; a pause to look up and think.
			var writing := 1.0 - ease
			right.rotation = Vector3(0.78 + sin(time * 5.3) * 0.05 * writing, 0, -0.42 + sin(time * 11.0) * 0.06 * writing)
			left.rotation = Vector3(0.6, 0, 0.05)
			spine.rotation = Vector3(lerpf(-0.2, 0.02, ease), lerpf(glance * 0.2, 0.25, ease), 0)

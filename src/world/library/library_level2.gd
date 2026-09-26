extends RefCounted
## Biomedical Library, Level 2: the quiet floor (zone-local, as Level 1).
##   Reading Room         the south half, under the great window: long tables
##                        with green-shaded lamps (sit, then open the laptop)
##                        and study carrels down the west wall
##   Stacks               five double-sided ranges of shelving (north-west)
##   Special Collections  a small history-of-medicine exhibit by the lift
##   Stair and lift       north-east, back down to Level 1
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const X0 := -14.0
const X1 := 14.0
const Z0 := -15.0
const Z1 := 15.0
const HEIGHT := 4.6
const FLOOR := Color("c3bcb0")
const CARPET := Color("6f7e7a")
const WALL := Color("ebe6dc")
const NAVY := Color("2f4a6b")
## The exhibit: [title, what the plaque says, item colour]. Original summaries
## of well-documented history (flagged in MEDICAL_CONTENT_REVIEW.md).
const EXHIBITS := [
	["A wooden monaural stethoscope", "In 1816 René Laennec rolled a paper tube to listen to a patient's chest, then made wooden cylinders like this one. He called it the stethoscope and published a treatise on listening to the heart and lungs in 1819.", Color("a0764a")],
	["Anesthesia, 1846", "On 16 October 1846 William Morton gave ether by inhaler for a public operation in a Boston hospital's operating theatre, the demonstration that made surgical anesthesia known across the world.", Color("b8a888")],
	["Handwashing and childbed fever", "In 1847 Ignaz Semmelweis showed that doctors washing their hands in chlorinated lime cut deaths from puerperal fever on the Vienna maternity wards, decades before germ theory explained why.", Color("c9d2d6")],
	["Penicillin, 1928", "Alexander Fleming noticed that a Penicillium mould killed the staphylococci around it. Florey, Chain and their Oxford team purified penicillin and showed in 1940–41 that it cured infections.", Color("7f9e6a")],
]
const ANCHORS := {
	"arrival": Vector3(10.5, 0, -8.4),
	"reading_room": Vector3(0, 0, 6.0),
	"stacks": Vector3(-4.0, 0, -7.0),
	"exhibit": Vector3(10.5, 0, -4.0),
}

static func build(scene: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		scene.set_anchor(id, at.call(ANCHORS[id]))
	_shell(scene, k, at)
	_reading_room(scene, k, at)
	_stacks(scene, k, at)
	_exhibit(scene, k, at)
	_core(scene, k, at)

static func _shell(scene: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(X0 + 0.2, -0.6, X1 - 0.2, Z1 - 0.2, CARPET, 0.004)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	# The great window (first person): stone fins against the sky.
	k.box("clear", Vector3(0, 2.5, Z1 - 0.2), Vector3(22.0, 3.8, 0.04), Color(0.82, 0.91, 0.96, 0.32), "fp")
	for index in range(11):
		k.box("facade", Vector3(-11.0 + index * 2.2, 2.5, Z1 - 0.35), Vector3(0.3, 3.8, 0.3), Color("e6e1d6"), "fp")
	k.box("light", Vector3(0, 6.0, Z1 + 18.0), Vector3(70, 12, 0.1), Color("cfe6f1"), "fp")
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f2efe8"))
	for x in [-10.0, -4.0, 2.0, 8.0]:
		for z in [-12.0, -5.0, 2.0, 9.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(1.4, 1.4))
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))
	scene.add_sign("Quiet Floor · Silent study", at.call(Vector3(X0 + 0.17, 2.9, 7.0)), PI / 2, 24, 0.0065, "fp", NAVY, Color.WHITE)

static func _reading_room(scene: Node3D, k, at: Callable) -> void:
	scene.add_floor_label("READING ROOM", at.call(Vector3(0, 0.012, 13.6)), 0.006)
	var number := 0
	for table in [Vector3(-5.8, 0, 3.6), Vector3(-5.8, 0, 9.6), Vector3(5.4, 0, 3.6), Vector3(5.4, 0, 9.6)]:
		var seats: Array = Campus.study_table(k, table, 0.0, 4.2, 3, true)
		for seat in seats:
			var occupant := {}
			if number % 4 == 1 or number == 14:
				occupant = scene.student_look(420 + number)
			var chair: Node3D = scene.add_seat("ReadingSeat%d" % (number + 1), at.call(seat[0]), seat[1], Campus.STUDY_LAPTOP, Color("6d4c36"), occupant)
			if occupant.is_empty():
				scene.study_seats.append(chair)
			number += 1
	# Carrels down the west wall, each with a chair set back from the desk.
	for index in range(8):
		var z := 1.4 + index * 1.6
		var carrel := Vector3(-13.3, 0, z)
		Campus.carrel(k, carrel, PI / 2, false, Color("6a5139"))
		var occupant: Dictionary = scene.student_look(460 + index) if index % 3 == 1 else {}
		var chair: Node3D = scene.add_seat("CarrelSeat%d" % (index + 1), at.call(carrel + Vector3(1.06, 0, 0)), PI / 2, Campus.STUDY_LAPTOP + Vector3(0, -0.05, 0), Color("6d4c36"), occupant)
		if occupant.is_empty():
			scene.study_seats.append(chair)

static func _stacks(scene: Node3D, k, at: Callable) -> void:
	scene.add_floor_label("STACKS", at.call(Vector3(4.3, 0.012, -6.0)), 0.005)
	for index in range(5):
		var z := -13.2 + index * 2.6
		Campus.book_stack(k, Vector3(-4.6, 0, z), 0.0, 14.0, 2.1)
		var labels := ["QS–QT  Anatomy · Physiology", "QU–QV  Biochemistry · Pharmacology", "QW–QZ  Microbiology · Pathology", "W–WG  Medicine · Cardiology", "WH–WZ  Specialties · History of Medicine"]
		scene.add_sign(labels[index], at.call(Vector3(2.44, 1.9, z)), PI / 2, 14, 0.0034, "fp")
	scene.add_endpoint("Stacks", "Browse the stacks", "The stacks are shelved by the NLM classification used in medical libraries: QS–QZ for the preclinical sciences, W for clinical medicine. Most students read the e-books, but the atlases still get borrowed.", at.call(Vector3(3.2, 1.0, -7.0)), 1.8)

static func _exhibit(scene: Node3D, k, at: Callable) -> void:
	scene.add_sign("Special Collections · The History of Medicine", at.call(Vector3(7.17, 2.9, -5.0)), PI / 2, 18, 0.0048, "fp", NAVY, Color.WHITE)
	k.wall(true, 7.0, -9.5, -1.4, HEIGHT, WALL, true, [[-5.0, 1.8, 2.5]], 0.16)
	for index in range(EXHIBITS.size()):
		var entry: Array = EXHIBITS[index]
		var pos := Vector3(9.0 + (index % 2) * 3.4, 0, -7.4 + int(index / 2) * 3.6)
		Campus.display_case(k, pos, 0.0, entry[2])
		scene.add_endpoint("Exhibit%d" % (index + 1), "Read: " + String(entry[0]), String(entry[1]), at.call(pos + Vector3(0, 1.1, 0.7)), 1.4)
	scene.add_floor_label("SPECIAL COLLECTIONS", at.call(Vector3(10.5, 0.012, -2.0)), 0.0042)

static func _core(scene: Node3D, k, at: Callable) -> void:
	k.wall(true, 7.0, Z0, -9.5, HEIGHT, WALL, true)
	k.wall(false, -9.5, 7.0, X1, HEIGHT, WALL, true)
	Props.elevator_frame(k, Vector3(10.5, 0, -9.42), 0.0, 1.3, true)
	scene.add_indicator(at.call(Vector3(10.5, 2.72, -9.38)), "2", 0.0)
	k.box("walnut", Vector3(8.3, 1.1, -9.38), Vector3(1.0, 2.2, 0.06), Color.WHITE)
	scene.add_sign("Stairs", at.call(Vector3(8.3, 2.45, -9.4)), 0.0, 14, 0.0035, "fp")
	scene.elevator_point_2 = at.call(Vector3(10.5, 1.1, -8.8))

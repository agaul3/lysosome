extends RefCounted
## The East Campus: the health-sciences district east of the quad, laid out
## like the teaching blocks of an academic medical center. Every entrance
## faces south, toward the overhead camera.
##   Health Sciences Walk      a tree-lined promenade (z −22…−15) from the
##                             research tower's forecourt east to the library
##   Medical Education Center  x[38,98] z[−58,−22], the interior's own
##                             footprint: terracotta wings either side of a
##                             full-height glass atrium under a cantilevered
##                             canopy. Lecture Hall B is the windowless west
##                             volume; the Commons food court is glazed in the east.
##   Biomedical Library        x[104,132] z[−52,−22]: limestone, a two-storey
##                             reading-room window and a glass roof lantern
##   East Green                four lawns, cross paths and a fountain (the
##                             club fair pitches its tents here)
##   Student Center            x[102,132] z[−6,18]: timber and glass under a
##                             deep roof; entrance and terrace face the street
##   Shuttle stops             by the residence, by the hospital crossing and
##                             in front of the Student Center
##   Across the street         an outpatient pavilion and a parking garage (backdrop)
## Geometry is merged per material (mesh_kit.gd); colliders are simple boxes.
const MeshKit = preload("res://world/campus/mesh_kit.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const Flora = preload("res://world/campus/flora.gd")
const Geometry = preload("res://world/geometry.gd")

const PATH := Color("dcd6c9")
const PLAZA := Color("e4dfd3")
const ASPHALT := Color("7c8084")
const CURB := Color("c9c4b8")
const POST := Color("4a5156")
const WHITE := Color("f3f2ee")
const TERRACOTTA := Color("b8694a")
const TERRACOTTA_DARK := Color("9f5a3f")
const LIMESTONE := Color("e6e1d6")
const LIMESTONE_TRIM := Color("d3cdbf")
const BRONZE := Color("7d6146")
const INK := Color("3a4247")

## Door endpoints (just in front of each door, at hand height).
const MEC_DOOR := Vector3(68, 1, -21.2)
const LIBRARY_DOOR := Vector3(118, 1, -20.3)
const STUDENT_CENTER_DOOR := Vector3(112, 1, 18.8)
const RESEARCH_DOOR := Vector3(26, 1, -21.2)
const ANATOMY_DOOR := Vector3(-29, 1.6, -23.1)
## Fountain at the heart of the East Green.
const FOUNTAIN := Vector3(68, 0, 5)
const FOUNTAIN_PLAZA := 6.5
## Lawn panels of the East Green (x0, z0, x1, z1), also used for grass tufts.
const LAWNS := [[42.0, -12.0, 66.5, 3.5], [69.5, -12.0, 96.0, 3.5], [42.0, 6.5, 66.5, 19.5], [69.5, 6.5, 96.0, 19.5]]
## Shuttle stops: id -> [name, pole position, where riders step off, the yaw they face].
const SHUTTLE_STOPS := {
	"quad": ["Cedar Residence · Quad", Vector3(-18.6, 0, 13.5), Vector3(-18.6, 0.05, 12.3), 0.0],
	"hospital": ["University Hospital", Vector3(33.6, 0, 24.4), Vector3(32.4, 0.05, 23.2), PI / 2],
	"east": ["East Campus · Student Center", Vector3(89.6, 0, 24.4), Vector3(92.0, 0.05, 22.6), 0.0],
}
## Benches: [position, yaw] (the seat faces −Z turned by yaw), as on the quad.
static var BENCHES := [
	[FOUNTAIN + Vector3(3.7, 0, -3.7), atan2(1.0, -1.0)], [FOUNTAIN + Vector3(-3.7, 0, -3.7), atan2(-1.0, -1.0)],
	[FOUNTAIN + Vector3(3.7, 0, 3.7), atan2(1.0, 1.0)], [FOUNTAIN + Vector3(-3.7, 0, 3.7), atan2(-1.0, 1.0)],
	[Vector3(46, 0, -14.1), PI], [Vector3(53, 0, -14.1), PI], [Vector3(83, 0, -14.1), PI], [Vector3(90, 0, -14.1), PI],
	[Vector3(110, 0, -14.1), PI], [Vector3(126, 0, -14.1), PI],
]
## Who sits where on the East Campus: [bench index, seat offset, activity, look].
const BENCH_STUDENTS := [
	[0, 0.0, "reading", "plum"], [3, -0.45, "lunch", "sage"], [3, 0.45, "notes", "teal"],
	[5, 0.0, "notes", "ochre"], [7, -0.45, "lunch", "indigo"], [8, 0.3, "reading", "clay"],
]
## Walking graph for passers-by in the district (x, z) and its edges.
const WALK_NODES := [
	Vector2(37.0, -18.5), Vector2(58.0, -18.5), Vector2(68.0, -18.5), Vector2(78.0, -18.5), Vector2(101.0, -18.5), Vector2(118.0, -18.5), Vector2(131.0, -18.5),
	Vector2(68.0, -1.8), Vector2(61.2, 5.0), Vector2(74.8, 5.0), Vector2(68.0, 11.8), Vector2(68.0, 22.5),
	Vector2(40.0, 5.0), Vector2(98.5, 5.0), Vector2(98.5, 22.5), Vector2(112.0, 22.5), Vector2(40.0, 22.5),
]
const WALK_EDGES := [
	[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [2, 7], [7, 8], [7, 9], [8, 10], [9, 10], [10, 11],
	[8, 12], [9, 13], [13, 14], [14, 15], [11, 14], [11, 16],
]

## Everything for the district, called from campus.gd.
static func build(parent: Node3D) -> void:
	paving(parent)
	medical_education_center(parent)
	library(parent)
	student_center(parent)
	street(parent)
	props(parent)
	planting(parent)
	letters(parent)

# --- Ground ------------------------------------------------------------------------------------------

## Paths, plazas and the street edge. Each layer sits a few millimetres above
## the one below so overlaps never z-fight (as on the quad).
static func paving(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var slab := func(x0: float, z0: float, x1: float, z1: float, top: float, color: Color) -> void:
		kit.box("paving", Vector3((x0 + x1) / 2.0, top / 2.0, (z0 + z1) / 2.0), Vector3(x1 - x0, top, z1 - z0), color)
	# The Health Sciences Walk, and aprons to the three entrances.
	slab.call(36, -22, 134.5, -15, 0.03, PLAZA)
	slab.call(56, -15, 80, -12, 0.032, PLAZA)
	slab.call(98, -30, 104, -22, 0.03, PLAZA) # Bike court between the MEC and the library.
	# East Green: a north–south spine, an east–west cross path from the café,
	# the fountain plaza, and a path down the Student Center's west side.
	slab.call(66.5, -12, 69.5, 20, 0.035, PATH)
	slab.call(20.5, 3.5, 100, 6.5, 0.036, PATH)
	slab.call(97, 6.5, 100, 20, 0.035, PATH)
	slab.call(40, -15, 42, 20, 0.034, PATH)
	kit.cylinder("paving", FOUNTAIN, FOUNTAIN + Vector3(0, 0.045, 0), FOUNTAIN_PLAZA, PLAZA, 40)
	kit.cylinder("paving", FOUNTAIN + Vector3(0, 0.045, 0), FOUNTAIN + Vector3(0, 0.05, 0), FOUNTAIN_PLAZA - 0.3, PLAZA.darkened(0.04), 40)
	# South sidewalk along the street, joined to the quad's sidewalk at the
	# crossing, and the Student Center's terrace.
	slab.call(30.5, 20, 134.5, 25, 0.03, PATH)
	slab.call(30.5, 14, 34, 20, 0.03, PATH)
	slab.call(100, 18, 134.5, 21.5, 0.034, PLAZA)
	# Across from the district, on the far side of the street: a sidewalk.
	slab.call(40, 37, 140, 40, 0.03, PATH)
	# The avenue along the east edge of campus.
	slab.call(137, -90, 145, 37, 0.02, ASPHALT.darkened(0.15))
	slab.call(135.5, -90, 137, 37, 0.05, CURB)
	slab.call(145, -90, 146.5, 37, 0.05, CURB)
	for index in range(12):
		var z := -86.0 + index * 10.0
		slab.call(140.9, z, 141.1, z + 2.4, 0.025, Color("d8d3c2"))
	kit.commit(parent, "EastPaving", false)

## The street east of the crossing, past the district (the quad's street stops at x 40).
static func street(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var slab := func(x0: float, z0: float, x1: float, z1: float, top: float, color: Color) -> void:
		kit.box("paving", Vector3((x0 + x1) / 2.0, top / 2.0, (z0 + z1) / 2.0), Vector3(x1 - x0, top, z1 - z0), color)
	slab.call(40, 27, 145, 35, 0.02, ASPHALT.darkened(0.15))
	slab.call(40, 26, 135.5, 27, 0.05, CURB)
	slab.call(40, 35, 145, 37, 0.05, CURB)
	for index in range(20):
		var x := 42.5 + index * 5.0
		slab.call(x, 30.9, x + 2.4, 31.1, 0.025, Color("d8d3c2"))
	# The campus shuttle waits at the East Campus stop.
	_shuttle_bus(kit, Vector3(92.0, 0, 28.9))
	kit.commit(parent, "EastStreet")
	# Backdrop across the street: an outpatient pavilion and a parking garage,
	# set back and held low so they never hide the sidewalk.
	var far := MeshKit.new()
	far.box("glass", Vector3(65, 6.3, 55), Vector3(38, 12.6, 22), Color.WHITE)
	for level in range(4):
		far.box("facade", Vector3(65, 0.2 + level * 4.2, 55), Vector3(38.4, 0.4, 22.4), WHITE)
	far.box("facade", Vector3(65, 12.9, 55), Vector3(38.6, 0.6, 22.6), WHITE)
	far.box("wood", Vector3(65, 3.4, 43.6), Vector3(14, 0.3, 1.4), Color.WHITE)
	far.box("facade", Vector3(112, 5, 52), Vector3(36, 10, 20), Color("8f959a"))
	for level in range(4):
		far.box("facade", Vector3(112, 0.9 + level * 2.5, 52), Vector3(36.4, 0.8, 20.4), Color("cfcbc2"))
	far.box("facade", Vector3(112, 10.2, 52), Vector3(36.6, 0.4, 20.6), Color("c2beb5"))
	far.commit(parent, "EastBackdrop")
	var signs := [["OUTPATIENT PAVILION", Vector3(65, 10.4, 43.98)], ["PARKING", Vector3(112, 8.2, 41.98)]]
	for sign in signs:
		Buildings.letters(parent, sign[0], sign[1], PI, 0.7, Color("2c4f86"), 0.05)

## Box-built shuttle bus (white with a blue band), facing west in the near lane.
static func _shuttle_bus(kit: MeshKit, at: Vector3) -> void:
	var body := Color("f2f2f0")
	var band := Color("2c5a8f")
	kit.box("metal", at + Vector3(0, 1.75, 0), Vector3(10.4, 2.6, 2.5), body)
	kit.box("metal", at + Vector3(0, 0.95, 0), Vector3(10.42, 0.36, 2.52), band)
	kit.box("glass", at + Vector3(0.4, 2.15, 0), Vector3(8.4, 0.95, 2.54), Color.WHITE)
	kit.box("tinted", at + Vector3(-5.21, 2.0, 0), Vector3(0.04, 1.5, 2.2), Color("30414a"))
	kit.box("light", at + Vector3(-5.23, 2.95, 0), Vector3(0.02, 0.28, 1.6), Color("ffb347"))
	kit.box("metal", at + Vector3(0, 3.12, 0), Vector3(9.6, 0.16, 2.2), Color("d8dcde"))
	for x in [-3.4, 3.2]:
		for z in [-1.2, 1.2]:
			kit.cylinder("metal", at + Vector3(x, 0.48, z - 0.12 * signf(z)), at + Vector3(x, 0.48, z + 0.06 * signf(z)), 0.48, Color("1b1d1f"), 12)
	kit.solid(at + Vector3(0, 1.6, 0), Vector3(10.4, 3.2, 2.5))

# --- Medical Education Center -----------------------------------------------------------------------

static func medical_education_center(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var x0 := 38.0
	var x1 := 98.0
	var z0 := -58.0
	var front := -22.0
	var top := 17.6
	var levels := [5.0, 9.2, 13.4]
	var cx := (x0 + x1) / 2.0
	kit.solid(Vector3(cx, top / 2.0, (z0 + front) / 2.0), Vector3(x1 - x0, top, front - z0))
	kit.box("facade", Vector3(cx, top / 2.0, (z0 + front - 0.4) / 2.0), Vector3(x1 - x0, top, front - z0 - 0.4), Color("d9d5cc"))
	# West wing, Lecture Hall B: a windowless terracotta volume for two storeys
	# (fine horizontal joints), with glazing behind terracotta baguettes above.
	kit.box("facade", Vector3(47.5, 4.6, front - 0.2), Vector3(19.0, 9.2, 0.4), TERRACOTTA)
	for index in range(7):
		kit.box("facade", Vector3(47.5, 1.15 + index * 1.15, front + 0.005), Vector3(19.0, 0.03, 0.01), TERRACOTTA_DARK)
	kit.box("facade", Vector3(47.5, 9.4, front - 0.1), Vector3(19.2, 0.4, 0.6), WHITE)
	kit.box("glass", Vector3(47.5, 13.6, front - 0.3), Vector3(19.0, 8.0, 0.1), Color.WHITE)
	for index in range(21):
		var x := 38.5 + index * 0.86
		kit.box("facade", Vector3(x, 13.6, front - 0.02), Vector3(0.16, 8.0, 0.5), TERRACOTTA)
	# The west face (seen from the alley and the forecourt) repeats the wing.
	kit.box("facade", Vector3(x0 - 0.2, 4.6, (z0 + front) / 2.0), Vector3(0.4, 9.2, front - z0), TERRACOTTA)
	kit.box("glass", Vector3(x0 - 0.1, 13.6, (z0 + front) / 2.0), Vector3(0.1, 8.0, front - z0 - 0.4), Color.WHITE)
	for index in range(40):
		var z := z0 + 0.5 + index * 0.9
		kit.box("facade", Vector3(x0 - 0.3, 13.6, z), Vector3(0.5, 8.0, 0.16), TERRACOTTA)
	# Atrium: a full-height glass wall in a deep white portal, cut around the doors.
	for side in [56.7, 79.3]:
		kit.box("facade", Vector3(side, (top + 0.8) / 2.0, front + 0.2), Vector3(1.0, top + 0.8, 1.2), WHITE)
		kit.solid(Vector3(side, 1.5, front + 0.2), Vector3(1.0, 3.0, 1.2))
	kit.box("facade", Vector3(68, top + 0.2, front + 0.2), Vector3(23.6, 1.2, 1.2), WHITE)
	kit.box("glass", Vector3(61.5, top / 2.0, front), Vector3(8.6, top, 0.1), Color.WHITE)
	kit.box("glass", Vector3(74.5, top / 2.0, front), Vector3(8.6, top, 0.1), Color.WHITE)
	kit.box("glass", Vector3(68, (3.05 + top) / 2.0, front), Vector3(4.4, top - 3.05, 0.1), Color.WHITE)
	Buildings.door(kit, Vector3(68, 0, front), 4.0)
	# Cantilevered canopy with a timber soffit, hung from the portal on tie rods.
	kit.box("facade", Vector3(68, 5.6, front + 3.0), Vector3(16.0, 0.4, 6.0), WHITE)
	kit.box("wood", Vector3(68, 5.37, front + 3.0), Vector3(15.8, 0.06, 5.9), Color.WHITE)
	for x in [61.0, 68.0, 75.0]:
		kit.cylinder("metal", Vector3(x, 5.8, front + 5.8), Vector3(x, 10.4, front + 0.2), 0.05, Color("c9d0d3"))
	# East wing, the Commons: storefront glazing on the ground floor, then ribbon
	# windows between terracotta spandrels, with deep fins for rhythm.
	kit.box("glass", Vector3(88.9, 2.5, front - 0.1), Vector3(18.2, 5.0, 0.1), Color.WHITE)
	for index in range(10):
		kit.box("metal", Vector3(80.0 + index * 2.0, 2.5, front + 0.0), Vector3(0.08, 5.0, 0.12), Color("5b6469"))
	kit.box("glass", Vector3(88.9, 11.3, front - 0.3), Vector3(18.2, 12.6, 0.1), Color.WHITE)
	for level in levels:
		kit.box("facade", Vector3(88.9, level + 0.55, front - 0.1), Vector3(18.4, 1.1, 0.5), TERRACOTTA)
	for index in range(7):
		kit.box("facade", Vector3(80.6 + index * 2.85, 11.3, front + 0.1), Vector3(0.22, 12.6, 0.8), TERRACOTTA)
	# The east face: kitchens behind terracotta, ribbons above, a service door.
	kit.box("facade", Vector3(x1 + 0.2, 2.5, (z0 + front) / 2.0), Vector3(0.4, 5.0, front - z0), TERRACOTTA)
	kit.box("glass", Vector3(x1 + 0.1, 11.3, (z0 + front) / 2.0), Vector3(0.1, 12.6, front - z0 - 0.4), Color.WHITE)
	for level in levels:
		kit.box("facade", Vector3(x1 + 0.2, level + 0.55, (z0 + front) / 2.0), Vector3(0.5, 1.1, front - z0), TERRACOTTA)
	kit.box("metal", Vector3(x1 + 0.42, 1.3, -30.0), Vector3(0.06, 2.6, 1.8), Color("5b6469"))
	# Slab edges across both wings, the parapet, a green roof over the hall and
	# the mechanical penthouse.
	for level in levels:
		kit.box("facade", Vector3(88.9, level - 0.05, front + 0.02), Vector3(18.4, 0.12, 0.2), WHITE)
	kit.box("facade", Vector3(cx, top + 0.4, front + 0.05), Vector3(x1 - x0 + 0.6, 0.8, 0.5), WHITE)
	kit.box("facade", Vector3(cx, top + 0.4, z0 - 0.05), Vector3(x1 - x0 + 0.6, 0.8, 0.5), WHITE)
	for x in [x0, x1]:
		kit.box("facade", Vector3(x, top + 0.4, (z0 + front) / 2.0), Vector3(0.6, 0.8, front - z0 + 0.6), WHITE)
	kit.box("facade", Vector3(47.5, top + 0.05, -40), Vector3(17.6, 0.1, 34.4), Color("5d8a45"))
	kit.box("metal", Vector3(76, top + 1.3, -44), Vector3(18, 2.6, 10), Color("c9cdd0"))
	kit.box("metal", Vector3(88, top + 0.9, -36), Vector3(4, 1.8, 4), Color("b9bec2"))
	kit.commit(parent, "MedicalEducationCenter")

# --- Biomedical Library -----------------------------------------------------------------------------

static func library(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var x0 := 104.0
	var x1 := 132.0
	var z0 := -52.0
	var front := -22.0
	var top := 14.0
	var cx := (x0 + x1) / 2.0
	kit.solid(Vector3(cx, top / 2.0, (z0 + front) / 2.0), Vector3(x1 - x0, top, front - z0))
	kit.box("facade", Vector3(cx, top / 2.0, (z0 + front) / 2.0), Vector3(x1 - x0, top, front - z0), LIMESTONE)
	# Ground floor: a plinth, glazed bays either side of a projecting portal.
	kit.box("facade", Vector3(cx, 0.3, front + 0.08), Vector3(x1 - x0 + 0.2, 0.6, 0.16), LIMESTONE_TRIM)
	for bay in [[105.6, 114.4], [121.6, 130.4]]:
		var mid: float = (bay[0] + bay[1]) / 2.0
		kit.box("glass", Vector3(mid, 2.6, front + 0.03), Vector3(bay[1] - bay[0], 3.4, 0.04), Color.WHITE)
		var count := int(round((bay[1] - bay[0]) / 2.2))
		for index in range(count + 1):
			var x: float = bay[0] + index * (bay[1] - bay[0]) / count
			kit.box("facade", Vector3(x, 2.6, front + 0.12), Vector3(0.3, 3.4, 0.24), LIMESTONE_TRIM)
		kit.box("facade", Vector3(mid, 0.82, front + 0.14), Vector3(bay[1] - bay[0] + 0.3, 0.12, 0.28), LIMESTONE_TRIM)
	for side in [-1.0, 1.0]:
		kit.box("facade", Vector3(118 + side * 3.0, 2.4, front + 0.5), Vector3(0.8, 4.8, 1.0), LIMESTONE_TRIM)
		kit.solid(Vector3(118 + side * 3.0, 2.4, front + 0.5), Vector3(0.8, 4.8, 1.0))
	kit.box("facade", Vector3(118, 4.4, front + 0.5), Vector3(6.8, 0.8, 1.0), LIMESTONE_TRIM)
	kit.box("facade", Vector3(118, 3.45, front + 0.02), Vector3(5.2, 1.1, 0.04), Color("20272b"))
	Buildings.door(kit, Vector3(118, 0, front), 3.2)
	# String course, then the great reading-room window: stone fins and a transom.
	kit.box("facade", Vector3(cx, 5.2, front + 0.15), Vector3(x1 - x0 + 0.2, 0.4, 0.3), LIMESTONE_TRIM)
	kit.box("glass", Vector3(118, 9.2, front + 0.03), Vector3(22.0, 6.8, 0.04), Color.WHITE)
	for index in range(11):
		kit.box("facade", Vector3(107.0 + index * 2.2, 9.2, front + 0.45), Vector3(0.3, 6.8, 0.9), LIMESTONE)
	kit.box("facade", Vector3(118, 9.4, front + 0.12), Vector3(22.0, 0.18, 0.2), LIMESTONE_TRIM)
	kit.box("facade", Vector3(118, 5.72, front + 0.3), Vector3(22.4, 0.14, 0.6), LIMESTONE_TRIM)
	# Bronze cornice and a glazed roof lantern over the reading room.
	kit.box("metal", Vector3(cx, top - 0.4, (z0 + front) / 2.0), Vector3(x1 - x0 + 0.5, 0.8, front - z0 + 0.5), BRONZE)
	kit.box("glass", Vector3(118, top + 0.9, -36), Vector3(16.0, 1.8, 12.0), Color.WHITE)
	kit.box("metal", Vector3(118, top + 1.95, -36), Vector3(16.6, 0.3, 12.6), BRONZE)
	# East face: tall slit windows above ground-floor glazing.
	for index in range(6):
		var z := -48.0 + index * 4.4
		kit.box("glass", Vector3(x1 + 0.03, 9.2, z), Vector3(0.04, 6.8, 1.2), Color.WHITE)
		kit.box("facade", Vector3(x1 + 0.1, 5.72, z), Vector3(0.2, 0.14, 1.6), LIMESTONE_TRIM)
		kit.box("glass", Vector3(x1 + 0.03, 2.6, z), Vector3(0.04, 3.4, 2.4), Color.WHITE)
	kit.commit(parent, "BiomedicalLibrary")

# --- Student Center ---------------------------------------------------------------------------------

## Club colours on the banners down the west face.
const CLUB_COLORS := [Color("c2452d"), Color("2f8f82"), Color("e0a93e"), Color("3f6fb0"), Color("7d4f9e")]

static func student_center(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var x0 := 102.0
	var x1 := 132.0
	var z0 := -6.0
	var front := 18.0
	var top := 9.5
	var cx := (x0 + x1) / 2.0
	kit.solid(Vector3(cx, top / 2.0, (z0 + front) / 2.0), Vector3(x1 - x0, top, front - z0))
	kit.box("facade", Vector3(cx, top / 2.0, (z0 + front) / 2.0 - 0.1), Vector3(x1 - x0, top, front - z0 - 0.2), Color("e9e4da"))
	# Ground floor: storefront glazing on timber mullions, cut around the doors.
	kit.box("glass", Vector3((x0 + 109.9) / 2.0, 2.5, front), Vector3(109.9 - x0, 5.0, 0.1), Color.WHITE)
	kit.box("glass", Vector3((114.1 + x1) / 2.0, 2.5, front), Vector3(x1 - 114.1, 5.0, 0.1), Color.WHITE)
	kit.box("glass", Vector3(112, 4.05, front), Vector3(4.2, 2.0, 0.1), Color.WHITE)
	for index in range(13):
		var x := x0 + 0.1 + index * 2.48
		if absf(x - 112.0) < 2.3:
			continue
		kit.box("wood", Vector3(x, 2.5, front + 0.1), Vector3(0.14, 5.0, 0.24), Color.WHITE)
	Buildings.door(kit, Vector3(112, 0, front), 3.6)
	# A dark fascia band carries the signs; timber cladding with glass slots above.
	kit.box("facade", Vector3(cx, 5.3, front + 0.1), Vector3(x1 - x0 + 0.2, 0.6, 0.6), Color("343b40"))
	kit.box("wood", Vector3(cx, 7.55, front + 0.05), Vector3(x1 - x0, 3.9, 0.2), Color.WHITE)
	for index in range(9):
		kit.box("glass", Vector3(104.0 + index * 3.25, 7.6, front + 0.17), Vector3(1.3, 3.1, 0.04), Color.WHITE)
	# Deep roof with a timber soffit over the terrace.
	kit.box("facade", Vector3(cx, top + 0.2, (z0 + front) / 2.0 + 1.0), Vector3(x1 - x0 + 2.0, 0.4, front - z0 + 4.0), WHITE)
	kit.box("wood", Vector3(cx, top - 0.03, front + 1.5), Vector3(x1 - x0 + 1.8, 0.06, 2.9), Color.WHITE)
	# West face on the green: glazing below, timber above, club banners.
	kit.box("glass", Vector3(x0 - 0.05, 2.5, (z0 + front) / 2.0), Vector3(0.1, 5.0, front - z0 - 0.4), Color.WHITE)
	kit.box("wood", Vector3(x0 - 0.1, 7.55, (z0 + front) / 2.0), Vector3(0.2, 3.9, front - z0), Color.WHITE)
	for index in range(5):
		var z := -2.0 + index * 4.2
		kit.box("facade", Vector3(x0 - 0.26, 7.4, z), Vector3(0.04, 3.4, 1.0), CLUB_COLORS[index])
		kit.box("metal", Vector3(x0 - 0.3, 9.15, z), Vector3(0.06, 0.06, 1.2), POST)
	# East face: timber with glass slots.
	kit.box("wood", Vector3(x1 + 0.1, 4.75, (z0 + front) / 2.0), Vector3(0.2, 9.5, front - z0), Color.WHITE)
	for index in range(6):
		kit.box("glass", Vector3(x1 + 0.22, 4.9, -3.0 + index * 4.0), Vector3(0.04, 6.4, 1.3), Color.WHITE)
	# Terrace: café tables with umbrellas, clear of the doors.
	for point in [Vector3(104.8, 0, 20.1), Vector3(119.4, 0, 20.1), Vector3(129.4, 0, 20.1)]:
		kit.cylinder("metal", point, point + Vector3(0, 0.74, 0), 0.04, POST)
		kit.cylinder("facade", point + Vector3(0, 0.74, 0), point + Vector3(0, 0.77, 0), 0.45, Color("f1efe9"), 14)
		kit.cylinder("metal", point, point + Vector3(0, 2.3, 0), 0.025, Color("d8dcde"))
		kit.cylinder("facade", point + Vector3(0, 2.2, 0), point + Vector3(0, 2.35, 0), 1.3, Color("2f8f82"), 12)
		kit.solid(point + Vector3(0, 0.5, 0), Vector3(0.9, 1.0, 0.9))
	kit.commit(parent, "StudentCenter")

# --- Street furniture --------------------------------------------------------------------------------

static func props(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var stone := Color("cfc9bc")
	# Fountain: a stone basin with a sculpted centre and a plume of water.
	kit.cylinder("facade", FOUNTAIN, FOUNTAIN + Vector3(0, 0.5, 0), 3.2, stone, 36)
	kit.cylinder("facade", FOUNTAIN + Vector3(0, 0.5, 0), FOUNTAIN + Vector3(0, 0.56, 0), 3.3, stone.lightened(0.06), 36)
	kit.cylinder("tinted", FOUNTAIN + Vector3(0, 0.5, 0), FOUNTAIN + Vector3(0, 0.505, 0), 2.95, Color("4f86a0"), 36)
	kit.cylinder("facade", FOUNTAIN, FOUNTAIN + Vector3(0, 1.1, 0), 0.55, stone, 16)
	kit.cylinder("facade", FOUNTAIN + Vector3(0, 1.1, 0), FOUNTAIN + Vector3(0, 1.2, 0), 1.0, stone, 20)
	kit.cylinder("light", FOUNTAIN + Vector3(0, 1.2, 0), FOUNTAIN + Vector3(0, 2.7, 0), 0.07, Color("e4f3f8"), 8)
	kit.cylinder("light", FOUNTAIN + Vector3(0, 1.21, 0), FOUNTAIN + Vector3(0, 1.26, 0), 0.9, Color("cfe8f0"), 20)
	var basin := StaticBody3D.new()
	basin.name = "FountainCollision"
	var shape := CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = 3.3
	shape.shape.height = 1.2
	shape.position = FOUNTAIN + Vector3(0, 0.6, 0)
	basin.add_child(shape)
	parent.add_child(basin)
	for bench in BENCHES:
		_bench(kit, bench[0], bench[1])
	# Lamp posts along the walk and the green's paths.
	var lamps := []
	for x in [44.0, 56.0, 80.0, 92.0, 108.0, 128.0]:
		lamps.append(Vector3(x, 0, -15.3))
	lamps.append_array([Vector3(66.2, 0, -6), Vector3(69.8, 0, 15), Vector3(50, 0, 6.8), Vector3(86, 0, 3.2), Vector3(100.3, 0, 12)])
	for point in lamps:
		kit.cylinder("metal", point, point + Vector3(0, 4.2, 0), 0.06, POST)
		kit.box("metal", point + Vector3(0, 4.3, 0), Vector3(0.5, 0.12, 0.22), POST)
		kit.box("facade", point + Vector3(0, 4.22, 0), Vector3(0.42, 0.03, 0.16), Color("fffbe8"))
		kit.solid(point + Vector3(0, 1, 0), Vector3(0.14, 2, 0.14))
	# Bike court: racks, two bikes, and a fence closing the service lane behind.
	for index in range(4):
		var x := 99.2 + index * 1.2
		for side in [-0.3, 0.3]:
			kit.cylinder("metal", Vector3(x + side, 0, -27.5), Vector3(x + side, 0.8, -27.5), 0.03, Color("9aa3a8"))
		kit.box("metal", Vector3(x, 0.8, -27.5), Vector3(0.66, 0.05, 0.05), Color("9aa3a8"))
	kit.solid(Vector3(101, 0.45, -27.5), Vector3(4.4, 0.9, 0.3))
	for bike in [[Vector3(99.2, 0, -27.0), Color("c2452d")], [Vector3(101.6, 0, -27.0), Color("3f6fb0")]]:
		var at: Vector3 = bike[0]
		for dz in [-0.55, 0.55]:
			kit.cylinder("metal", at + Vector3(-0.03, 0.34, dz), at + Vector3(0.03, 0.34, dz), 0.34, Color("1b1d1f"), 14)
		kit.box("metal", at + Vector3(0, 0.55, 0), Vector3(0.05, 0.05, 1.0), bike[1])
		kit.box("metal", at + Vector3(0, 0.75, -0.3), Vector3(0.05, 0.4, 0.05), bike[1])
		kit.box("metal", at + Vector3(0, 0.95, -0.3), Vector3(0.5, 0.04, 0.04), Color("2a2a2a"))
	for index in range(7):
		kit.cylinder("metal", Vector3(98.2 + index * 0.95, 0, -30), Vector3(98.2 + index * 0.95, 1.6, -30), 0.04, POST)
	for y in [0.3, 1.5]:
		kit.box("metal", Vector3(101, y, -30), Vector3(5.9, 0.06, 0.06), POST)
	kit.solid(Vector3(101, 1, -30), Vector3(6.0, 2, 0.3))
	# Wayfinding pylon where the forecourt meets the walk.
	var pylon := Vector3(37.4, 0, -14.2)
	kit.solid_box("metal", pylon + Vector3(0, 1.1, 0), Vector3(0.2, 2.2, 1.1), Color("2f3d44"))
	kit.box("metal", pylon + Vector3(0, 0.05, 0), Vector3(0.34, 0.1, 1.25), Color("262f34"))
	for face in [-1.0, 1.0]:
		Geometry.wall_sign(parent, "East Campus →\nMedical Education Center\nBiomedical Library\nStudent Center", pylon + Vector3(face * 0.105, 1.45, 0), face * PI / 2, 22, 0.0048)
	# Shuttle stops: a pole with the route sign, plus a shelter at the East stop.
	for id in SHUTTLE_STOPS:
		var pole: Vector3 = SHUTTLE_STOPS[id][1]
		kit.cylinder("metal", pole, pole + Vector3(0, 2.9, 0), 0.05, Color("9aa3a8"))
		kit.box("metal", pole + Vector3(0, 2.55, 0), Vector3(0.62, 0.62, 0.04), Color("2c5a8f"))
		kit.solid(pole + Vector3(0, 1, 0), Vector3(0.14, 2, 0.14))
		for face in [-1.0, 1.0]:
			Geometry.wall_sign(parent, "CAMPUS\nSHUTTLE", pole + Vector3(0, 2.55, face * 0.03), 0.0 if face > 0 else PI, 22, 0.0042)
	var shelter := Vector3(92.0, 0, 24.3)
	kit.box("clear", shelter + Vector3(0, 1.25, 0.55), Vector3(3.4, 2.3, 0.04), Color(0.85, 0.92, 0.95, 0.35))
	for side in [-1.0, 1.0]:
		kit.box("clear", shelter + Vector3(side * 1.7, 1.25, 0.1), Vector3(0.04, 2.3, 0.9), Color(0.85, 0.92, 0.95, 0.35))
		kit.cylinder("metal", shelter + Vector3(side * 1.7, 0, 0.55), shelter + Vector3(side * 1.7, 2.45, 0.55), 0.05, POST)
	kit.box("metal", shelter + Vector3(0, 2.5, 0.15), Vector3(3.6, 0.1, 1.2), Color("2f3d44"))
	kit.box("wood", shelter + Vector3(0, 0.42, 0.35), Vector3(2.6, 0.06, 0.36), Color.WHITE)
	kit.solid(shelter + Vector3(0, 1.2, 0.55), Vector3(3.5, 2.4, 0.12))
	for side in [-1.0, 1.0]:
		kit.solid(shelter + Vector3(side * 1.7, 1.2, 0.1), Vector3(0.12, 2.4, 0.9))
	kit.solid(shelter + Vector3(0, 0.25, 0.35), Vector3(2.6, 0.5, 0.4))
	# A low wall with a hedge closes the gap between the research tower and the MEC.
	kit.solid_box("facade", Vector3(36, 0.3, -22.6), Vector3(4.2, 0.6, 0.4), stone)
	kit.commit(parent, "EastFurniture")

## Park bench as on the quad (timber slats, steel frame, 0.30 m seat).
static func _bench(kit: MeshKit, position: Vector3, yaw: float) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var wood := Color.WHITE
	for index in range(4):
		kit.box("wood", position + basis * Vector3(0, 0.275, -0.18 + index * 0.12), Vector3(1.8, 0.05, 0.1), wood, basis)
	for side in [-1, 1]:
		kit.box("metal", position + basis * Vector3(side * 0.75, 0.13, 0), Vector3(0.06, 0.26, 0.5), POST, basis)
		kit.box("metal", position + basis * Vector3(side * 0.75, 0.45, 0.23), Vector3(0.06, 0.5, 0.05), POST, basis)
	kit.box("wood", position + basis * Vector3(0, 0.56, 0.24), Vector3(1.8, 0.28, 0.05), wood, basis)
	kit.solid(position + basis * Vector3(0, 0.35, 0.02), Vector3(1.9, 0.7, 0.56), basis)

# --- Planting ----------------------------------------------------------------------------------------

static func planting(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301
	var place := func(points: Array, low: float, high: float) -> Array:
		return points.map(func(p: Vector3) -> Array: return [p, rng.randf_range(low, high), rng.randf() * TAU])
	# An allée along the walk, flanking (never blocking) each entrance, and
	# shade trees framing the green.
	var shade := []
	for x in [44.0, 50.0, 86.0, 92.0, 106.0, 112.5, 123.5, 130.0]:
		shade.append(Vector3(x, 0, -13.4))
	for z in [-8.0, 0.0, 10.0, 17.0]:
		shade.append(Vector3(38.5, 0, z))
	shade.append_array([Vector3(95.5, 0, 17.5), Vector3(95.5, 0, -9.5), Vector3(134, 0, 10)])
	Flora.plant(parent, "shade", place.call(shade, 0.95, 1.2))
	Flora.plant(parent, "flowering", place.call([Vector3(57.5, 0, -13.2), Vector3(78.5, 0, -13.2), Vector3(61, 0, 13), Vector3(75, 0, -3)], 0.9, 1.1))
	Flora.plant(parent, "ornamental", place.call([Vector3(52, 0, -3), Vector3(84, 0, 12), Vector3(47, 0, 14), Vector3(89, 0, -5)], 0.9, 1.15))
	Flora.plant(parent, "columnar", place.call([Vector3(102.6, 0, -21.4), Vector3(133.4, 0, -21.4), Vector3(101.2, 0, 19.4)], 0.95, 1.1))
	# Foundation shrubs along the terracotta wings, hedges on the Student
	# Center's west side and at the tower/MEC gap.
	var shrubs := []
	for x in range(39, 56, 2):
		shrubs.append(Vector3(x + 0.5, 0, -21.3))
	for x in range(81, 97, 2):
		shrubs.append(Vector3(x + 0.5, 0, -21.3))
	for x in range(105, 114, 2):
		shrubs.append(Vector3(x + 0.5, 0, -21.3))
	for x in range(122, 131, 2):
		shrubs.append(Vector3(x + 0.5, 0, -21.3))
	Flora.plant(parent, "shrub", place.call(shrubs, 0.7, 1.1), false)
	var hedges := []
	for index in range(10):
		hedges.append(Vector3(101.0, 0, -4.0 + index * 2.1))
	hedges.append_array([Vector3(35.0, 0, -22.2), Vector3(37.0, 0, -22.2)])
	Flora.plant(parent, "hedge", hedges.map(func(p: Vector3) -> Array: return [p, 1.0, PI / 2 if p.x > 100.0 else 0.0]))
	# Street trees on the far side of the street and along the east avenue.
	var trees := []
	for index in range(14):
		trees.append([Vector3(44.0 + index * 7.0, 0, 38.2), 1.0, float(index)])
	for index in range(12):
		trees.append([Vector3(135.6 + 0.0, 0, -60.0 + index * 8.0), 0.95, float(index) * 0.7])
	Flora.plant(parent, "shade", trees, false)

# --- Lettering ---------------------------------------------------------------------------------------

static func letters(parent: Node3D) -> void:
	Buildings.letters(parent, "MEDICAL EDUCATION CENTER", Vector3(47.5, 6.2, -22.0), 0.0, 0.55, Color("f1ebe2"), 0.05)
	Buildings.letters(parent, "BIOMEDICAL LIBRARY", Vector3(118, 4.3, -21.0), 0.0, 0.34, Color("4a3a2a"), 0.04)
	Buildings.letters(parent, "STUDENT CENTER", Vector3(112, 5.22, 18.4), 0.0, 0.34, Color("f3f2ee"), 0.03)
	Buildings.letters(parent, "CAMPUS STORE", Vector3(125.5, 5.22, 18.4), 0.0, 0.28, Color("e0c27a"), 0.03)

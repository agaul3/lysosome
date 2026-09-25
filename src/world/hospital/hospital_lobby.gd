extends RefCounted
## University Hospital, Level 1: the welcome atrium. Zone-local coordinates:
## x east, z south; the glass entrance front is at z = +10, the wood-clad
## elevator bank on the north wall at z = -14.
##   entrance + security desk (south-east), Information desk (centre, the
##   shadowing meeting point), lounge with indoor trees (west), elevator bank
##   (north), café and gift shop (east), and corridors that end at staff-only
##   doors (Emergency Department to the west, Outpatient Clinics to the north)
##   so the building reads as much larger than the playable slice. A mezzanine
##   and grand stair to Level 2 appear in first person (the stair is roped off).
const Props = preload("res://world/hospital/hospital_props.gd")
const FLOOR := Color("c5c3bc")
const WALL := Color("dedcd5")
const CARPET := Color("8c9296")
const TRIM := Color("3a4045")
const HEIGHT := 9.0
const X0 := -18.0
const X1 := 18.0
const Z0 := -14.0
const Z1 := 10.0
## Elevator car used by the shadowing session (door centre x on the north wall).
const ACTIVE_ELEVATOR := 1.5
const ANCHORS := {
	"entrance": Vector3(0, 0, 7.6),
	"info_desk": Vector3(2.7, 0, 0.4),
	"lobby_mid": Vector3(3.4, 0, -5.8),
	"elevator_l1": Vector3(ACTIVE_ELEVATOR, 0, -11.0),
	"cab_l1": Vector3(ACTIVE_ELEVATOR - 0.35, 0, -15.5),
}
## Inside the car (zone-local): x and z ranges.
const CAB := Rect2(ACTIVE_ELEVATOR - 1.05, -16.35, 2.1, 2.25)

static func build(hospital: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		hospital.set_anchor(id, at.call(ANCHORS[id]))
	_shell(hospital, k, at)
	_elevators(hospital, k, at)
	_information(hospital, k, at)
	_lounge(hospital, k, at)
	_cafe_and_shop(hospital, k, at)
	_corridors(hospital, k, at)
	_mezzanine(hospital, k, at)
	_wayfinding(hospital, k, at)

# --- Shell: floor, walls, glass front, ceiling -----------------------------------

static func _shell(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	# A soft darker band leads from the doors to the elevators (not a pattern).
	k.floor_rect(-1.2, -11.8, 1.2, 6.6, FLOOR.darkened(0.05), 0.004)
	k.floor_rect(-2.2, 7.0, 2.2, 9.9, Color("5d6265"), 0.008)
	# Far walls stand full height in both views; the near (east) wall is a cutaway.
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [[-4.5, 1.3, 2.36], [-1.5, 1.3, 2.36], [ACTIVE_ELEVATOR, 1.3, 2.36], [4.5, 1.3, 2.36], [9.0, 1.8, 2.36], [12.0, 1.8, 2.36], [15.5, 3.0, 3.0]], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [[-10.5, 3.0, 3.0]], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	# Skirting along the far walls.
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), TRIM)
	k.box("facade", Vector3(X0 + 0.16, 0.06, -2.0), Vector3(0.03, 0.12, 24.0), TRIM)
	_glass_front(hospital, k, at)
	# Ceiling with a long skylight and linear lights (first person).
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f4f4f1"))
	k.box("light", Vector3(0, HEIGHT - 0.02, -3.0), Vector3(10.0, 0.03, 9.0), Color("eef6fb"), "fp")
	for x in [-13.0, -9.0, 9.0, 13.0]:
		for z in [-10.0, -4.0, 2.0, 7.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(2.4, 0.3))
	# Round columns frame the elevator lobby and the open floor.
	for point in [Vector3(-6.5, 0, -8.5), Vector3(6.5, 0, -8.5), Vector3(-10.5, 0, 2.0), Vector3(10.5, 0, 2.0)]:
		# Full height in first person; cut like the walls for the overhead view.
		k.cylinder("facade", point, point + Vector3(0, HEIGHT, 0), 0.34, Color("e8e6e0"), "fp", 18)
		k.cylinder("facade", point, point + Vector3(0, 1.05, 0), 0.34, Color("e8e6e0"), "tp", 18)
		k.cylinder("facade", point + Vector3(0, 1.05, 0), point + Vector3(0, 1.08, 0), 0.35, Color("8f8d88"), "tp", 18)
		k.solid(point + Vector3(0, 1.5, 0), Vector3(0.62, 3.0, 0.62))
	# A round bench wraps the lounge column.
	k.cylinder("facade", Vector3(-10.5, 0, 2.0), Vector3(-10.5, 0.44, 2.0), 1.0, Color("6c767c"), "always", 24)
	k.solid(Vector3(-10.5, 0.22, 2.0), Vector3(1.9, 0.44, 1.9))

## Floor-to-ceiling glass along the entrance front with automatic doors.
## Overhead, only the sill shows; the daylight panes and mullions are first person.
static func _glass_front(hospital: Node3D, k, at: Callable) -> void:
	var z := Z1
	for x0 in range(-18, 18, 2):
		var x := float(x0) + 1.0
		if absf(x) < 2.0:
			continue
		k.box("light", Vector3(x, HEIGHT / 2.0, z + 0.05), Vector3(1.96, HEIGHT - 0.4, 0.04), Color("dcecf3").lerp(Color("f4f9fb"), 0.5), "fp")
	for x in range(-18, 19, 2):
		if absf(x) < 1.5:
			continue
		k.box("metal", Vector3(x, HEIGHT / 2.0, z), Vector3(0.08, HEIGHT, 0.14), TRIM, "fp")
	for y in [0.15, 2.9, HEIGHT - 0.15]:
		k.box("metal", Vector3(0, y, z), Vector3(X1 - X0, 0.12, 0.14), TRIM, "fp")
	k.box("facade", Vector3(-10.0, 0.18, z), Vector3(16.0, 0.36, 0.2), TRIM, "tp")
	k.box("facade", Vector3(10.0, 0.18, z), Vector3(16.0, 0.36, 0.2), TRIM, "tp")
	for side in [-1, 1]:
		k.solid(Vector3(side * 10.0, HEIGHT / 2.0, z), Vector3(16.0, HEIGHT, 0.2))
	# Door surround and transom over the entrance.
	k.box("metal", Vector3(0, 2.7, z), Vector3(4.0, 0.3, 0.2), TRIM, "fp")
	for side in [-1, 1]:
		k.box("metal", Vector3(side * 1.75, 1.3, z), Vector3(0.12, 2.6, 0.2), TRIM, "fp")
	var doors: Node3D = hospital.add_doors("EntranceDoors", at.call(Vector3(0, 0, z)), 0.0, 3.3, 2.55, true)
	doors.auto_target = hospital.player_target()
	hospital.entrance_doors = doors
	hospital.add_fp_node(doors)
	# Outside: a canopy strip and daylight so the open doors look onto the street.
	k.floor_rect(X0, Z1, X1, Z1 + 8.0, Color("8f8d86"))
	k.box("light", Vector3(0, 6.0, Z1 + 8.0), Vector3(40.0, 12.0, 0.1), Color("cfe6f1"), "fp")
	k.box("facade", Vector3(0, 4.2, Z1 + 2.2), Vector3(8.0, 0.25, 4.4), Color("f1f0ec"), "fp")
	# Hand sanitizer on a stand just inside the doors.
	k.box("metal", Vector3(3.0, 0.55, 7.4), Vector3(0.06, 1.1, 0.06), TRIM)
	k.box("metal", Vector3(3.0, 0.02, 7.4), Vector3(0.36, 0.03, 0.36), TRIM)
	Props.dispenser(k, Vector3(3.0, 1.2, 7.43), 0.0)
	k.solid(Vector3(3.0, 0.6, 7.4), Vector3(0.36, 1.2, 0.36))
	hospital.add_dispenser("lobby_sanitizer", at.call(Vector3(3.0, 1.1, 7.55)))
	hospital.add_sign("Clean your hands", at.call(Vector3(3.0, 1.55, 7.44)), 0.0, 22, 0.005, false)

# --- Elevator bank ---------------------------------------------------------------

static func _elevators(hospital: Node3D, k, at: Callable) -> void:
	var face := Z0 + 0.16
	# Walnut cladding around the visitor cars, between the door openings.
	k.wall(false, face + 0.03, -7.2, 7.2, 4.4, Color.WHITE, false, [[-4.5, 1.54, 2.5], [-1.5, 1.54, 2.5], [ACTIVE_ELEVATOR, 1.54, 2.5], [4.5, 1.54, 2.5]], 0.06, "walnut", false)
	k.box("facade", Vector3(0, 4.5, face + 0.06), Vector3(14.6, 0.2, 0.12), TRIM)
	for x in [-4.5, -1.5, ACTIVE_ELEVATOR, 4.5]:
		Props.elevator_frame(k, Vector3(x, 0, face + 0.06), 0.0, 1.3, x != ACTIVE_ELEVATOR)
	for x in [9.0, 12.0]:
		Props.elevator_frame(k, Vector3(x, 0, face), 0.0, 1.8, true)
	hospital.add_sign("Staff & patient transport · Badge access", at.call(Vector3(10.5, 3.0, face)), 0.0, 22, 0.006, false)
	hospital.add_sign("Elevators · Floors 1–8", at.call(Vector3(0, 3.35, face + 0.1)), 0.0, 26, 0.009, false)
	hospital.add_letters("UNIVERSITY HOSPITAL", at.call(Vector3(0, 6.2, face)), 0.0, 0.62)
	for x in [-4.5, -1.5, ACTIVE_ELEVATOR, 4.5]:
		hospital.add_indicator(at.call(Vector3(x, 2.72, face + 0.1)), "1")
	# The working car: doors, cab and the elevator interaction.
	var doors: Node3D = hospital.add_doors("LobbyElevatorDoors", at.call(Vector3(ACTIVE_ELEVATOR, 0, face + 0.02)), 0.0, 1.3, 2.36, false)
	hospital.lobby_elevator = doors
	Props.elevator_cab(k, Vector3(ACTIVE_ELEVATOR, 0, Z0), 0.0)
	hospital.add_elevator_call("LobbyElevator", at.call(Vector3(ACTIVE_ELEVATOR + 0.97, 1.15, face + 0.25)), "unit")
	# Floor directory beside the cars.
	hospital.add_sign("Floor directory\n8  Rehabilitation\n7  Oncology\n6  Cardiology\n5  Surgery · Recovery\n4  4 West · Internal Medicine\n3  Operating rooms\n2  Imaging · Laboratory\n1  Lobby · Café · Pharmacy", at.call(Vector3(-6.2, 1.6, face + 0.1)), 0.0, 24, 0.0055, false)

# --- Information and security -----------------------------------------------------

static func _information(hospital: Node3D, k, at: Callable) -> void:
	# Curved Information desk: white top, walnut front, facing the entrance.
	var centre := Vector3(0, 0, -2.6)
	var radius := 2.2
	for index in range(9):
		var angle := lerpf(-1.25, 1.25, (index + 0.5) / 9.0)
		var dir := Vector3(sin(angle), 0, cos(angle))
		var yaw := atan2(dir.x, dir.z)
		var pos := centre + dir * radius
		var seg := radius * 2.5 / 9.0 + 0.05
		k.box("walnut", pos + Vector3(0, 0.5, 0), Vector3(seg, 1.0, 0.1), Color.WHITE, "always", false, Basis(Vector3.UP, yaw))
		k.box("facade", pos + Vector3(0, 1.04, 0) - dir * 0.2, Vector3(seg, 0.06, 0.56), Color("f7f7f4"), "always", false, Basis(Vector3.UP, yaw))
		k.box("facade", pos + Vector3(0, 0.74, 0) - dir * 0.62, Vector3(seg, 0.04, 0.5), Color("e4e1da"), "always", false, Basis(Vector3.UP, yaw))
	k.solid(centre + Vector3(0, 0.55, 1.4), Vector3(3.6, 1.1, 1.6))
	k.solid(centre + Vector3(0, 0.55, 0.3), Vector3(4.2, 1.1, 0.8))
	Props.monitor(k, centre + Vector3(-0.6, 0.76, 1.1), PI)
	Props.monitor(k, centre + Vector3(0.7, 0.76, 1.1), PI)
	Props.office_chair(k, centre + Vector3(0.7, 0, 0.1), 0.0)
	hospital.add_sign("Information", at.call(centre + Vector3(0, 0.66, radius + 0.06)), 0.0, 28, 0.007, false)
	hospital.add_figure("reception", at.call(centre + Vector3(-0.6, 0, 0.2)), PI, "stand")
	hospital.add_endpoint("InformationDesk", "Ask at the Information desk", "\"Good morning! Medical students meet their physicians right here. 4 West is on Level 4, through the elevators behind me.\"", at.call(centre + Vector3(-0.9, 1.0, radius + 0.3)), 1.9)
	# A ring pendant hangs over the desk (first person).
	for index in range(28):
		var angle := TAU * index / 28.0
		var pos := centre + Vector3(sin(angle), 0, cos(angle)) * 2.6 + Vector3(0, 4.8, 0)
		k.box("light", pos, Vector3(0.62, 0.05, 0.08), Color("fff4dc"), "fp", false, Basis(Vector3.UP, angle + PI / 2.0))
	for side in [-1, 1]:
		k.box("metal", centre + Vector3(side * 1.8, 6.9, 1.8), Vector3(0.015, 4.2, 0.015), TRIM, "fp")
	# Security podium beside the entrance, facing the path in.
	var desk := Vector3(5.6, 0, 5.8)
	k.box("facade", desk + Vector3(0, 0.55, 0), Vector3(0.8, 1.1, 3.0), Color("f7f7f4"), "always", true)
	k.box("walnut", desk + Vector3(-0.42, 0.5, 0), Vector3(0.04, 0.9, 2.9), Color.WHITE)
	k.box("facade", desk + Vector3(0, 1.12, 0), Vector3(0.9, 0.05, 3.1), Color("e4e1da"))
	Props.monitor(k, desk + Vector3(0.1, 1.14, -0.6), PI / 2, 0.4) # Faces the guard.
	k.box("facade", desk + Vector3(0.05, 1.18, 0.7), Vector3(0.24, 0.1, 0.3), Color("2a2f33"))
	hospital.add_sign("Security · Visitor badges", at.call(desk + Vector3(-0.44, 0.78, 0)), -PI / 2, 22, 0.006, false)
	hospital.add_figure("security", at.call(desk + Vector3(1.0, 0, 0)), PI / 2, "stand")
	hospital.add_endpoint("SecurityDesk", "Talk to security", "\"Morning. Student badge? You're all set. Staff areas upstairs need your badge; visitors check in here.\"", at.call(desk + Vector3(-0.8, 1.0, 0)), 1.9)

# --- Lounge ------------------------------------------------------------------------

static func _lounge(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(-14.0, -4.5, -4.0, 7.5, CARPET, 0.012)
	k.floor_rect(-13.7, -4.2, -4.3, -4.0, CARPET.darkened(0.12), 0.014)
	# Armchairs around low tables, and a curved sofa facing the atrium.
	for cluster in [[Vector3(-7.4, 0, -1.6), 4], [Vector3(-12.6, 0, -1.8), 3]]:
		var middle: Vector3 = cluster[0]
		Props.round_table(k, middle, 0.36, 0.46)
		for index in range(cluster[1]):
			var angle := TAU * index / float(cluster[1]) + 0.4
			var pos := middle + Vector3(sin(angle), 0, cos(angle)) * 1.15
			Props.armchair(k, pos, angle + PI) # Facing the table.
	Props.curved_sofa(k, Vector3(-7.6, 0, 3.4), 2.4, PI - 1.1, PI + 1.1, 6)
	Props.round_table(k, Vector3(-7.6, 0, 3.4), 0.5, 0.42)
	# Visitors waiting.
	hospital.add_figure("coral", at.call(Vector3(-7.4, 0, -1.6) + Vector3(sin(0.4), 0, cos(0.4)) * 1.15), 0.4, "seated")
	hospital.add_figure("sand", at.call(Vector3(-12.6, 0, -1.8) + Vector3(sin(0.4 + TAU / 3.0), 0, cos(0.4 + TAU / 3.0)) * 1.15), 0.4 + TAU / 3.0, "seated")
	# Indoor trees in black planters.
	for point in [Vector3(-12.6, 0, 5.6), Vector3(-4.6, 0, 6.4), Vector3(-15.8, 0, -6.4), Vector3(8.4, 0, 7.6)]:
		var top: Vector3 = Props.planter(k, point, Vector3(1.5, 0.75, 1.5))
		hospital.add_tree(at.call(top), 0.62)
		hospital.add_shrubs(at.call(top), 1.5)

# --- Café and gift shop ----------------------------------------------------------------

static func _cafe_and_shop(hospital: Node3D, k, at: Callable) -> void:
	# Café alcove on the east side: counter, back bar, menu board.
	k.wall(false, -4.0, 14.0, X1, 4.2, WALL, true)
	k.box("facade", Vector3(14.2, 0.53, -7.5), Vector3(0.8, 1.06, 6.4), Color("f7f7f4"), "always", true)
	k.box("walnut", Vector3(13.78, 0.5, -7.5), Vector3(0.04, 0.9, 6.3), Color.WHITE)
	k.box("facade", Vector3(14.2, 1.08, -7.5), Vector3(0.9, 0.05, 6.5), Color("ded9cf"))
	k.box("facade", Vector3(17.5, 0.5, -8.0), Vector3(0.7, 1.0, 7.0), Color("5b4a3d"), "always", true)
	k.box("metal", Vector3(17.5, 1.25, -9.5), Vector3(0.5, 0.45, 0.7), Color("b8bfc4"))
	k.box("tinted", Vector3(14.2, 1.3, -6.0), Vector3(0.6, 0.4, 1.4), Color("c9dde4"))
	for index in range(5):
		k.box("facade", Vector3(14.2, 1.18, -6.6 + index * 0.3), Vector3(0.18, 0.08, 0.18), [Color("d9a15a"), Color("c7784a"), Color("f1d9a6")][index % 3])
	hospital.add_sign("Atrium Café", at.call(Vector3(13.76, 0.7, -7.5)), -PI / 2, 26, 0.007, false)
	hospital.add_sign("Coffee · Tea · Pastries · Sandwiches", at.call(Vector3(17.84, 2.4, -8.0)), -PI / 2, 22, 0.007, true)
	hospital.add_figure("mint", at.call(Vector3(15.6, 0, -8.4)), PI / 2, "stand")
	hospital.add_endpoint("CafeCounter", "Order a coffee", "\"Medical students get a free refill. Come back after rounds!\"", at.call(Vector3(13.4, 1.0, -7.5)), 1.8)
	for point in [Vector3(10.6, 0, -6.2), Vector3(11.4, 0, -10.6)]:
		Props.round_table(k, point, 0.4, 0.74)
		for side in [-1, 1]:
			Props.office_chair(k, point + Vector3(side * 0.85, 0, 0), -side * PI / 2, Color("5b4a3d"))
	# Gift shop: glass storefront, closed until 10:00.
	var front := 14.0
	k.wall(false, 5.0, front, X1, 4.2, WALL, true)
	k.wall(false, -3.0, front, X1, 4.2, WALL, true)
	k.box("facade", Vector3(front, 0.15, 1.0), Vector3(0.2, 0.3, 8.0), TRIM)
	k.box("tinted", Vector3(front, 1.75, 1.0), Vector3(0.05, 2.9, 8.0), Color("cfe0e6"), "fp")
	k.box("facade", Vector3(front, 3.3, 1.0), Vector3(0.24, 0.2, 8.0), TRIM, "fp")
	k.solid(Vector3(front, 1.5, 1.0), Vector3(0.2, 3.0, 8.0))
	for z in [-1.8, 0.2, 2.2, 4.0]:
		k.box("facade", Vector3(16.8, 0.8, z), Vector3(1.4, 1.6, 0.4), Color("d9d2c4"))
		for row in range(3):
			for item in range(4):
				k.box("facade", Vector3(16.3 + item * 0.32, 0.35 + row * 0.5, z + 0.22), Vector3(0.22, 0.26, 0.06), [Color("e8708a"), Color("5aa9d6"), Color("f2c46d"), Color("7fd6a0")][(item + row) % 4])
	hospital.add_sign("Gift Shop · Opens 10:00", at.call(Vector3(front - 0.04, 2.2, 1.0)), -PI / 2, 24, 0.007, true)

# --- Corridors beyond the atrium -----------------------------------------------------

static func _corridors(hospital: Node3D, k, at: Callable) -> void:
	# West: toward the Emergency Department and Imaging (staff access beyond).
	k.floor_rect(-30.0, -12.0, X0, -9.0, FLOOR.darkened(0.03))
	k.wall(false, -12.0, -30.0, X0, 3.0, WALL, true)
	k.wall(false, -9.0, -30.0, X0, 3.0, WALL, true)
	k.ceiling(-30.0, -12.0, X0, -9.0, 3.0, Color("f4f4f1"))
	for x in [-27.0, -22.0]:
		k.ceiling_light(Vector3(x, 2.98, -10.5), Vector2(0.4, 1.8))
	k.wall(true, -29.9, -12.0, -9.0, 3.0, WALL, false)
	for side in [-1, 1]:
		k.box("walnut", Vector3(-29.75, 1.15, -10.5 + side * 0.7), Vector3(0.06, 2.3, 1.36), Color.WHITE)
		k.box("light", Vector3(-29.71, 1.55, -10.5 + side * 0.7), Vector3(0.02, 0.5, 0.3), Color("cfe6f1"))
	hospital.add_sign("Emergency Department", at.call(Vector3(-29.72, 2.55, -10.5)), PI / 2, 22, 0.006, true)
	hospital.add_sign("← Emergency Department · Imaging", at.call(Vector3(X0 + 0.16, 3.4, -10.5)), PI / 2, 24, 0.008, false)
	# North-east: toward Outpatient Clinics and the Pharmacy.
	k.floor_rect(14.0, -26.0, 17.0, Z0, FLOOR.darkened(0.03))
	k.wall(true, 14.0, -26.0, Z0, 3.0, WALL, true)
	k.wall(true, 17.0, -26.0, Z0, 3.0, WALL, true)
	k.ceiling(14.0, -26.0, 17.0, Z0, 3.0, Color("f4f4f1"))
	k.ceiling_light(Vector3(15.5, 2.98, -20.0), Vector2(1.8, 0.4))
	k.wall(false, -25.9, 14.0, 17.0, 3.0, WALL, false)
	for side in [-1, 1]:
		k.box("walnut", Vector3(15.5 + side * 0.7, 1.15, -25.75), Vector3(1.36, 2.3, 0.06), Color.WHITE)
	hospital.add_sign("Outpatient Clinics · Pharmacy", at.call(Vector3(15.5, 3.4, Z0 + 0.16)), 0.0, 22, 0.007, false)

# --- Mezzanine (Level 2) and grand stair -------------------------------------------------

static func _mezzanine(hospital: Node3D, k, at: Callable) -> void:
	var level := 4.8
	k.box("facade", Vector3(-15.25, level - 0.2, -9.75), Vector3(5.5, 0.4, 8.5), Color("f4f4f1"), "fp")
	k.box("paving", Vector3(-15.25, level + 0.01, -9.75), Vector3(5.5, 0.02, 8.5), FLOOR)
	k.box("tinted", Vector3(-12.5, level + 0.55, -9.75), Vector3(0.04, 1.1, 8.5), Color("d7e6ea"), "fp")
	k.box("metal", Vector3(-12.5, level + 1.12, -9.75), Vector3(0.08, 0.05, 8.5), Color("b8bfc4"), "fp")
	k.box("tinted", Vector3(-14.0, level + 0.55, -5.5), Vector3(3.0, 1.1, 0.04), Color("d7e6ea"), "fp")
	hospital.add_sign("Level 2 · Imaging · Laboratory", at.call(Vector3(X0 + 0.16, level + 2.0, -9.8)), PI / 2, 24, 0.008, true)
	# Grand stair along the west wall, rising north to the mezzanine.
	var steps := 26
	var rise := level / steps
	var run := 9.5 / steps
	for index in range(steps):
		var top := rise * (index + 1)
		var z := 4.0 - run * (index + 0.5)
		var layer := "always" if top <= 1.05 else "fp"
		k.box("facade", Vector3(-16.8, top / 2.0, z), Vector3(2.0, top, run), Color("ecebe6") if index % 2 == 0 else Color("e5e3dd"), layer)
		if top > 1.05:
			k.box("facade", Vector3(-16.8, 0.525, z), Vector3(2.0, 1.05, run), Color("e5e3dd"), "tp")
	k.box("tinted", Vector3(-15.78, 2.9, -0.75), Vector3(0.04, 1.0, 9.5), Color("d7e6ea"), "fp")
	k.solid(Vector3(-16.8, 0.8, -0.75), Vector3(2.0, 1.6, 9.5))
	# Roped off at the bottom: Level 2 is by elevator.
	for x in [-17.6, -16.0]:
		k.cylinder("metal", Vector3(x, 0, 4.5), Vector3(x, 0.95, 4.5), 0.03, Color("b8bfc4"))
		k.cylinder("metal", Vector3(x, 0, 4.5), Vector3(x, 0.02, 4.5), 0.16, Color("b8bfc4"))
	k.box("facade", Vector3(-16.8, 0.86, 4.5), Vector3(1.6, 0.04, 0.04), Color("7a2e3a"))
	k.solid(Vector3(-16.8, 0.5, 4.5), Vector3(1.8, 1.0, 0.3))
	hospital.add_sign("Level 2 by elevator", at.call(Vector3(-16.8, 0.62, 4.52)), 0.0, 22, 0.005, false)

# --- Wayfinding --------------------------------------------------------------------------

static func _wayfinding(hospital: Node3D, k, at: Callable) -> void:
	var totem := Vector3(-3.6, 0, 6.4)
	k.box("facade", totem + Vector3(0, 1.1, 0), Vector3(1.3, 2.2, 0.2), Color("24343c"), "always", true)
	k.box("walnut", totem + Vector3(0, 2.25, 0), Vector3(1.34, 0.12, 0.24), Color.WHITE)
	hospital.add_sign("Welcome · Directory\nInformation desk · ahead\nElevators · all floors\nAtrium Café · east\nEmergency Dept · west corridor\n4 West Internal Medicine · Level 4", at.call(totem + Vector3(0, 1.35, 0.1)), 0.0, 24, 0.0048, false)
	hospital.add_endpoint("Directory", "Read the hospital directory", "Level 1: Information, Café, Gift Shop, Pharmacy. Level 2: Imaging and Laboratory. Level 3: Operating rooms. Level 4: 4 West, Internal Medicine. Emergency Department: west corridor, with its own street entrance.", at.call(totem + Vector3(0, 1.0, 0.45)), 1.8)

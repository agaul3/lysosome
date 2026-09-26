extends RefCounted
## University Hospital, Level 1: the Food Court, through the glass doors off
## the corridor to the Outpatient Clinics. Zone-local coordinates: x east,
## z south; the doors are on the east wall, the servery along the north wall
## and a window wall onto the courtyard garden on the south side.
##   servery    three counters: Grill 24 (open all night for the night
##              shift), Fresh Market (salads, soups, sushi) and Rounds Coffee
##   drinks     glass-fronted coolers and the condiment and cutlery station
##              along the west wall
##   dining     two long communal tables with real seats (and charging
##              strips), four-tops with staff and visitors eating, and a
##              window counter onto the garden
## The north and west walls stand full height in both views; the east wall
## and the window wall are cut away for the overhead camera.
const Props = preload("res://world/hospital/hospital_props.gd")
const Campus = preload("res://world/interior/campus_props.gd")
const ED = preload("res://world/hospital/hospital_ed.gd")
const FLOOR := Color("cdc8bf")
const WALL := Color("e2dfd8")
const TRIM := Color("3a4045")
const HEIGHT := 4.2
const X0 := -14.0
const X1 := 14.0
const Z0 := -10.0
const Z1 := 10.0
## Vendor id (data/items.gd VENDORS), name, counter centre, fascia colour.
const VENDORS := [
	["hospital_grill", "Grill 24", Vector3(-8.5, 0, -6.6), Color("b5462f")],
	["hospital_market", "Fresh Market", Vector3(0.0, 0, -6.6), Color("4f8a3c")],
	["hospital_coffee", "Rounds Coffee", Vector3(8.5, 0, -6.6), Color("2f6f8f")],
]
const ANCHORS := {
	"food_court_entrance": Vector3(12.4, 0, 0.0),
	"food_court_door": Vector3(13.45, 1.0, 0.0),
}
## Four-top tables (centres): columns east of the communal tables.
const TABLES := [Vector3(0.0, 0, -1.6), Vector3(4.5, 0, -1.6), Vector3(9.0, 0, -1.6), Vector3(0.0, 0, 2.4), Vector3(4.5, 0, 2.4), Vector3(9.0, 0, 2.4), Vector3(0.0, 0, 6.4), Vector3(4.5, 0, 6.4)]
## Communal tables with seats the student can use.
const COMMUNAL := [Vector3(-7.4, 0, 0.6), Vector3(-7.4, 0, 5.0)]
## Passers-by walk this loop (zone-local x, z): in at the doors, along the
## counters and back between the tables.
const WALK_NODES := [Vector2(11.6, 0.4), Vector2(11.6, -4.4), Vector2(-2.2, -4.4), Vector2(-2.2, 0.4)]
const WALK_EDGES := [[0, 1], [1, 2], [2, 3], [3, 0]]

static func build(hospital: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		hospital.set_anchor(id, at.call(ANCHORS[id]))
	_shell(hospital, k, at)
	_servery(hospital, k, at)
	_drinks(hospital, k, at)
	_dining(hospital, k, at)
	_windows(hospital, k, at)

# --- Shell -------------------------------------------------------------------------------

static func _shell(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [[0.0, 2.4, 2.5]], 0.3)
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), TRIM)
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), TRIM)
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f4f4f1"))
	for x in [-9.0, -3.0, 3.0, 9.0]:
		for z in [-4.0, 1.0, 6.0]:
			k.ceiling_light(Vector3(x, HEIGHT - 0.02, z), Vector2(2.2, 0.3))
	# Warm pendants over the communal tables (first person).
	for table in COMMUNAL:
		for dx in [-1.4, 0.0, 1.4]:
			k.box("metal", table + Vector3(dx, HEIGHT - 0.55, 0), Vector3(0.012, 1.1, 0.012), TRIM, "fp")
			k.cylinder("light", table + Vector3(dx, HEIGHT - 1.2, 0), table + Vector3(dx, HEIGHT - 1.08, 0), 0.2, Color("ffe7b8"), "fp", 14)
	# The entrance: glass double doors (closed; the endpoint walks you through).
	for side in [-1, 1]:
		k.box("clear", Vector3(X1, 0.525, side * 0.6), Vector3(0.05, 1.05, 1.16), Color(0.82, 0.9, 0.93, 0.3))
		k.box("clear", Vector3(X1, 1.72, side * 0.6), Vector3(0.05, 1.34, 1.16), Color(0.82, 0.9, 0.93, 0.3), "fp")
		k.box("metal", Vector3(X1, 1.25, side * 1.17), Vector3(0.1, 2.5, 0.06), TRIM, "fp")
		k.box("metal", Vector3(X1 - 0.08, 1.05, side * 0.3), Vector3(0.04, 0.04, 0.5), Color("b8bfc4"))
	k.box("facade", Vector3(X1, 1.2, 0), Vector3(0.1, 2.4, 0.06), TRIM, "fp")
	k.box("facade", Vector3(X1, 0.525, 0), Vector3(0.1, 1.05, 0.06), TRIM, "tp")
	k.solid(Vector3(X1, 1.25, 0), Vector3(0.3, 2.5, 2.4))
	# The corridor beyond the glass (first person), back toward the clinics and the lobby.
	k.box("paving", Vector3(X1 + 1.5, -0.04, 0), Vector3(2.8, 0.08, 4.0), FLOOR.darkened(0.04), "fp")
	for z in [-2.0, 2.0]:
		k.box("facade", Vector3(X1 + 1.5, 1.5, z), Vector3(2.8, 3.0, 0.2), WALL, "fp")
	k.box("facade", Vector3(X1 + 2.9, 1.5, 0), Vector3(0.2, 3.0, 4.0), WALL, "fp")
	k.box("facade", Vector3(X1 + 1.5, 3.06, 0), Vector3(2.8, 0.12, 4.0), Color("f4f4f1"), "fp")
	k.box("light", Vector3(X1 + 1.5, 2.99, 0), Vector3(1.6, 0.02, 0.4), Color("eef6fb"), "fp")
	hospital.add_sign("To the Lobby · Outpatient Clinics", at.call(Vector3(X1 - 0.16, 2.75, 0)), -PI / 2, 20, 0.006, "fp")
	hospital.add_floor_label("FOOD COURT", at.call(Vector3(11.2, 0.012, 2.6)), 0.005)
	# Hours by the doors, and the big name over the servery.
	hospital.add_sign("Food Court · Open 24 hours\nGrill 24 · all night\nFresh Market · 7 AM – 8 PM\nRounds Coffee · 6 AM – 10 PM", at.call(Vector3(X1 - 0.16, 1.55, -2.2)), -PI / 2, 18, 0.0045, "fp")
	hospital.add_sign("FOOD COURT", at.call(Vector3(0, 3.62, Z0 + 0.16)), 0.0, 34, 0.012, "always", Color("24343c"), Color.WHITE)

# --- Servery -----------------------------------------------------------------------------

static func _servery(hospital: Node3D, k, at: Callable) -> void:
	for index in range(VENDORS.size()):
		var vendor: Array = VENDORS[index]
		var pos: Vector3 = vendor[2]
		Campus.vendor_stall(k, pos, 0.0, 5.0, vendor[3])
		hospital.add_sign(String(vendor[1]), at.call(pos + Vector3(0, 2.72, -1.84)), 0.0, 30, 0.011, "always", Color(vendor[3]).darkened(0.1), Color.WHITE)
		hospital.add_figure(ED.staff_look("barista", 800 + index), at.call(pos + Vector3(0.9, 0, -0.85)), PI, "stand")
		hospital.add_shop(String(vendor[0]), "Order at " + String(vendor[1]), at.call(pos + Vector3(0, 1.0, 1.25)))
	# Food on show: the grill's hot plates, the market's salads, the café's pastries.
	for slot in range(4):
		var x := -10.0 + slot * 0.8
		k.box("metal", Vector3(x, 1.08, -6.62), Vector3(0.6, 0.04, 0.36), Color("c9ced1"))
		k.box("facade", Vector3(x, 1.12, -6.62), Vector3(0.5, 0.05, 0.28), [Color("b7773d"), Color("d9b25a"), Color("8a4f2f"), Color("e0c07a")][slot])
	for slot in range(5):
		k.box("facade", Vector3(-1.8 + slot * 0.55, 1.1, -6.6), Vector3(0.42, 0.06, 0.3), [Color("6fae5a"), Color("d8483b"), Color("e8c34a"), Color("8cc26a"), Color("f0e6d0")][slot])
	for slot in range(4):
		k.box("facade", Vector3(7.2 + slot * 0.4, 1.12, -6.55), Vector3(0.22, 0.08, 0.2), [Color("d9a15a"), Color("c7784a"), Color("f1d9a6"), Color("b5673a")][slot])
	# A soup well on the market's back counter, an espresso machine at the café.
	k.cylinder("metal", Vector3(1.4, 0.92, -8.2), Vector3(1.4, 1.14, -8.2), 0.18, Color("c9ced1"))
	k.cylinder("metal", Vector3(2.0, 0.92, -8.2), Vector3(2.0, 1.14, -8.2), 0.18, Color("c9ced1"))
	k.box("metal", Vector3(8.5, 1.2, -8.1), Vector3(0.9, 0.55, 0.5), Color("aeb4b8"))
	k.box("facade", Vector3(8.5, 1.5, -8.1), Vector3(0.92, 0.06, 0.52), Color("2a2f33"))

# --- Drinks and the condiment station ----------------------------------------------------

static func _drinks(hospital: Node3D, k, at: Callable) -> void:
	var bottles := [Color("5aa9d6"), Color("e8708a"), Color("f2c46d"), Color("7fd6a0"), Color("f4f5f2"), Color("e98a4f")]
	for index in range(3):
		var z := -6.4 + index * 1.2
		# An open, lit cabinet behind a glass door: back, sides, top and plinth.
		k.box("facade", Vector3(X0 + 0.22, 1.0, z), Vector3(0.1, 2.0, 1.12), Color("3a4045"))
		k.box("light", Vector3(X0 + 0.28, 1.1, z), Vector3(0.02, 1.5, 0.96), Color("f2f7fa"))
		for side in [-1, 1]:
			k.box("facade", Vector3(X0 + 0.57, 1.0, z + side * 0.53), Vector3(0.8, 2.0, 0.06), Color("3a4045"))
		k.box("facade", Vector3(X0 + 0.57, 1.95, z), Vector3(0.8, 0.1, 1.12), Color("3a4045"))
		k.box("facade", Vector3(X0 + 0.57, 0.1, z), Vector3(0.8, 0.2, 1.12), Color("3a4045"))
		for shelf in range(5):
			var y := 0.24 + shelf * 0.33
			k.box("metal", Vector3(X0 + 0.6, y, z), Vector3(0.66, 0.02, 1.0), Color("c9ced1"))
			for slot in range(5):
				k.box("facade", Vector3(X0 + 0.62, y + 0.11, z - 0.38 + slot * 0.19), Vector3(0.1, 0.2, 0.08), bottles[(index + shelf + slot) % bottles.size()])
		k.box("clear", Vector3(X0 + 0.96, 1.05, z), Vector3(0.03, 1.7, 1.0), Color(0.85, 0.93, 0.95, 0.2))
		k.box("metal", Vector3(X0 + 1.0, 1.1, z + 0.42), Vector3(0.04, 0.6, 0.04), Color("b8bfc4"))
		k.solid(Vector3(X0 + 0.57, 1.0, z), Vector3(0.8, 2.0, 1.12))
	hospital.add_sign("Cold drinks", at.call(Vector3(X0 + 0.16, 2.45, -5.2)), PI / 2, 20, 0.006, "always")
	# Condiments, cutlery and a microwave.
	k.box("facade", Vector3(X0 + 0.5, 0.47, -1.6), Vector3(0.7, 0.94, 2.4), Color("e9e4da"), "always", true)
	k.box("walnut", Vector3(X0 + 0.5, 0.96, -1.6), Vector3(0.74, 0.05, 2.44), Color.WHITE)
	for slot in range(4):
		k.box("metal", Vector3(X0 + 0.45, 1.07, -2.5 + slot * 0.35), Vector3(0.14, 0.18, 0.14), Color("b8bfc4"))
	k.box("metal", Vector3(X0 + 0.5, 1.15, -0.8), Vector3(0.45, 0.32, 0.55), Color("2a2f33"))
	k.box("facade", Vector3(X0 + 0.76, 1.15, -0.85), Vector3(0.02, 0.22, 0.34), Color("3d4b52"))
	hospital.add_sign("Cutlery · Condiments", at.call(Vector3(X0 + 0.16, 1.7, -1.6)), PI / 2, 18, 0.005, "always")
	# Tray return and bins by the doors.
	Campus.bins(k, Vector3(12.9, 0, 5.4), -PI / 2)
	k.box("metal", Vector3(13.4, 0.6, 7.6), Vector3(0.7, 1.2, 1.6), Color("aeb4b8"), "always", true)
	for shelf in range(3):
		k.box("facade", Vector3(13.35, 0.35 + shelf * 0.34, 7.6), Vector3(0.6, 0.03, 1.4), Color("5b6469"))
	hospital.add_sign("Trays here · thank you", at.call(Vector3(X1 - 0.16, 1.55, 7.6)), -PI / 2, 18, 0.005, "fp")

# --- Dining ------------------------------------------------------------------------------

static func _dining(hospital: Node3D, k, at: Callable) -> void:
	# Communal tables: real seats, some taken by staff on their break.
	var number := 0
	for table in COMMUNAL:
		var seats: Array = Campus.study_table(k, table, 0.0, 4.2, 3, false)
		for seat in seats:
			var occupant := {}
			if number in [1, 4, 6, 9]:
				occupant = ED.staff_look(["nurse", "resident", "rad_tech", "ed_nurse"][number % 4], 820 + number)
			hospital.add_seat("FoodCourtSeat%d" % (number + 1), at.call(seat[0]), seat[1], Campus.STUDY_LAPTOP, Color("4f6f86"), occupant)
			if not occupant.is_empty():
				_meal(k, seat[0] + Basis(Vector3.UP, float(seat[1])) * Vector3(0, 0, -0.95), number, Campus.STUDY_TOP)
			number += 1
	# Four-tops with prop chairs: visitors and staff eating.
	var visitors := ["coral", "sand", "plum", "teal", "slate", "ochre"]
	var eaters := 0
	for index in range(TABLES.size()):
		var pos: Vector3 = TABLES[index]
		var chairs: Array = Campus.dining_set(k, pos, 0.0, 4, true, Color("e9e4da"), Color("4f6f86"))
		if index % 3 != 2:
			for pick in ([0, 1] if index % 2 == 0 else [2]):
				var chair: Array = chairs[pick]
				var who: Variant = ED.staff_look(["transporter", "evs", "nurse"][eaters % 3], 840 + eaters) if eaters % 2 == 0 else visitors[eaters % visitors.size()]
				hospital.add_figure(who, at.call(chair[0]), float(chair[1]) + PI, "seated", Campus.CHAIR_SEAT)
				_meal(k, pos + (chair[0] - pos) * 0.35, eaters, 0.64)
				eaters += 1

## A tray with a plate and a cup on a table top at height `top`, in front of a diner.
static func _meal(k, spot: Vector3, seed: int, top: float) -> void:
	var place := Vector3(spot.x, 0, spot.z)
	k.box("facade", place + Vector3(0, top + 0.01, 0), Vector3(0.36, 0.02, 0.26), [Color("c8a24a"), Color("5b8fa8"), Color("7a8a5a")][seed % 3])
	k.box("facade", place + Vector3(-0.04, top + 0.03, 0), Vector3(0.18, 0.02, 0.18), Color("f4f5f2"))
	k.box("facade", place + Vector3(-0.04, top + 0.05, 0), Vector3(0.12, 0.03, 0.12), [Color("b7773d"), Color("6fae5a"), Color("d8483b"), Color("e0c07a")][seed % 4])
	k.cylinder("facade", place + Vector3(0.12, top + 0.02, 0.06), place + Vector3(0.12, top + 0.14, 0.06), 0.035, Color("f4f5f2"), "always", 10)

# --- The window wall and the courtyard garden -----------------------------------------------

static func _windows(hospital: Node3D, k, at: Callable) -> void:
	# A sill in both views; the tall panes and mullions in first person.
	k.box("facade", Vector3(0, 0.3, Z1), Vector3(X1 - X0, 0.6, 0.3), WALL)
	k.box("clear", Vector3(0, 2.4, Z1), Vector3(X1 - X0, 3.6, 0.05), Color(0.84, 0.92, 0.95, 0.16), "fp")
	k.box("facade", Vector3(0, HEIGHT - 0.1, Z1), Vector3(X1 - X0, 0.2, 0.3), WALL, "fp")
	for index in range(15):
		var x := X0 + 0.1 + index * (X1 - X0 - 0.2) / 14.0
		k.box("facade", Vector3(x, 2.4, Z1), Vector3(0.08, 3.6, 0.12), TRIM, "fp")
	k.solid(Vector3(0, HEIGHT / 2.0, Z1), Vector3(X1 - X0, HEIGHT, 0.3))
	# A counter along the glass (west half) with stools, planters on the east half.
	k.box("walnut", Vector3(-7.5, 1.04, 9.45), Vector3(11.0, 0.05, 0.5), Color.WHITE)
	for x in [-12.6, -2.4]:
		k.box("metal", Vector3(x, 0.52, 9.45), Vector3(0.06, 1.04, 0.4), TRIM)
	k.solid(Vector3(-7.5, 0.55, 9.45), Vector3(11.0, 1.1, 0.5))
	for index in range(7):
		var stool := Vector3(-12.0 + index * 1.55, 0, 8.85)
		k.cylinder("metal", stool, stool + Vector3(0, 0.72, 0), 0.03, TRIM, "always", 8)
		k.cylinder("facade", stool + Vector3(0, 0.72, 0), stool + Vector3(0, 0.78, 0), 0.19, Color("4f6f86"), "always", 14)
		k.solid(stool + Vector3(0, 0.39, 0), Vector3(0.4, 0.78, 0.4))
	for point in [Vector3(1.2, 0, 9.2), Vector3(6.6, 0, 9.2), Vector3(12.6, 0, 9.2)]:
		var top: Vector3 = Props.planter(k, point, Vector3(1.1, 0.6, 1.1))
		hospital.add_shrubs(at.call(top), 1.1)
	# Outside: the courtyard garden, lawn and trees against a low wall.
	k.floor_rect(X0, Z1 + 0.15, X1, Z1 + 9.0, Color("5f9a45"), -0.02)
	k.floor_rect(-1.2, Z1 + 0.15, 1.2, Z1 + 9.0, Color("b9b2a3"), -0.01)
	k.box("facade", Vector3(0, 0.45, Z1 + 9.2), Vector3(X1 - X0, 0.9, 0.4), Color("a39d90"))
	# Daylight beyond the garden wall (first person), as outside the lobby's doors.
	k.box("light", Vector3(0, 6.0, Z1 + 11.0), Vector3(48.0, 12.0, 0.1), Color("cfe6f1"), "fp")
	for side in [-1, 1]:
		k.box("light", Vector3(side * 20.0, 6.0, Z1 + 5.5), Vector3(0.1, 12.0, 11.0), Color("cfe6f1"), "fp")
	for point in [Vector3(-10.0, 0, 14.0), Vector3(-4.5, 0, 16.5), Vector3(4.0, 0, 14.5), Vector3(10.5, 0, 16.0)]:
		hospital.add_tree(at.call(point), 1.0)
	for x in [-6.0, 6.0]:
		k.box("walnut", Vector3(x, 0.44, Z1 + 3.2), Vector3(1.8, 0.08, 0.5), Color.WHITE)
		k.box("metal", Vector3(x, 0.2, Z1 + 3.2), Vector3(1.6, 0.4, 0.06), TRIM)

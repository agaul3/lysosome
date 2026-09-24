extends RefCounted
## University Hospital, Level 4: 4 West, Internal Medicine. Zone-local
## coordinates (x east, z south): the elevator lobby at the west end
## (x -6..0), then the unit corridor (z -1.6..1.6) running east to closed
## double doors onto 4 East (x 36), whose corridor continues out of reach.
##   North side: patient rooms 410–415, six metres square, each with a
##   bathroom, bed and headwall, window, chair and whiteboard. 412 and 413 are
##   open; 414 is on contact precautions; the others have curtains drawn.
##   South side: clean supply, the nurses station (open to the corridor), the
##   team workroom with the EHR workstation, and a family lounge.
const Props = preload("res://world/hospital/hospital_props.gd")
const Looks = preload("res://data/looks.gd")
const FLOOR := Color("c3c6c4")
const ROOM_FLOOR := Color("bab2a3")
const WALL := Color("e0ded8")
const ACCENT := Color("c8ac66")
const TRIM := Color("3a4045")
const HEIGHT := 3.0
const ROOMS := [[410, 0.0], [411, 6.0], [412, 12.0], [413, 18.0], [414, 24.0], [415, 30.0]]
const OPEN_ROOMS := [412, 413]
const ISOLATION_ROOM := 414
const DOOR_OFFSET := 4.8 # door centre from a room's west wall
const ANCHORS := {
	"cab_u": Vector3(-7.6, 0, 1.4),
	"unit_car_door": Vector3(-5.1, 0, 1.8),
	"unit_lobby": Vector3(-4.2, 0, 1.2),
	"unit_doors": Vector3(1.2, 0, 0.0),
	"corridor_west": Vector3(8.0, 0, 0.3),
	"station": Vector3(18.6, 0, 0.8),
	"corridor_mid": Vector3(21.5, 0, 0.2),
	"workroom_door": Vector3(23.8, 0, 0.8),
	"workroom_in": Vector3(23.8, 0, 2.6),
	"workroom_desk": Vector3(25.5, 0, 3.0),
	"corridor_rooms": Vector3(18.8, 0, 0.0),
	"room412_door": Vector3(16.8, 0, -0.9),
	"room412_inside": Vector3(16.1, 0, -4.4),
	"room412_bedside": Vector3(13.4, 0, -4.85),
	"bed_412": Vector3(13.0, 0, -6.0),
	"observer_412": Vector3(15.3, 0, -6.0),
	"corridor_east": Vector3(26.0, 0, 0.3),
	"isolation_414": Vector3(27.6, 0, 0.7),
	"door_414": Vector3(28.8, 0, -1.6),
	"corridor_east_back": Vector3(24.6, 0, 0.3),
	"wrap_up": Vector3(22.4, 0, 0.7),
	"ehr_monitor": Vector3(26.3, 0.76, 3.85),
}
## Inside the unit's elevator car (zone-local x and z ranges).
const CAB := Rect2(-8.35, 0.75, 2.2, 2.1)

static func build(hospital: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		hospital.set_anchor(id, at.call(ANCHORS[id]))
	_shell(hospital, k, at)
	_elevator_lobby(hospital, k, at)
	for room in ROOMS:
		_patient_room(hospital, k, at, room[0], room[1])
	_supply(hospital, k, at)
	_station(hospital, k, at)
	_workroom(hospital, k, at)
	_lounge(hospital, k, at)
	_corridor_details(hospital, k, at)

# --- Shell ---------------------------------------------------------------------------

static func _shell(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(-9.0, -7.8, 46.0, 8.2, FLOOR)
	k.floor_rect(0.0, -0.45, 46.0, 0.45, FLOOR.darkened(0.07), 0.004)
	# Exterior walls: the north and west stand full height; the south and east are cutaways.
	k.wall(false, -7.8, -9.0, 46.0, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, -9.0, -7.8, 8.2, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, 8.2, -9.0, 46.0, HEIGHT, WALL, true, [], 0.3)
	k.wall(true, 46.0, -7.8, 8.2, HEIGHT, WALL, true, [], 0.3)
	# Corridor walls: room fronts to the north, the station alcove open to the south.
	var doors: Array = []
	for room in ROOMS:
		doors.append([room[1] + DOOR_OFFSET, 1.6, 2.3])
	k.wall(false, -1.6, 0.0, 36.0, HEIGHT, WALL, true, doors)
	k.wall(false, 1.6, 0.0, 9.5, HEIGHT, WALL, true, [[4.7, 1.4, 2.3]])
	k.wall(false, 1.6, 22.0, 36.0, HEIGHT, WALL, true, [[23.8, 1.4, 2.3], [32.8, 1.4, 2.3]])
	for x in [0.0, 6.0, 12.0, 18.0, 24.0, 30.0, 36.0]:
		k.wall(true, x, -7.8, -1.6, HEIGHT, WALL, true)
	for x in [0.0, 9.5, 22.0, 30.0, 36.0]:
		k.wall(true, x, 1.6, 8.2, HEIGHT, WALL, true)
	# Ceiling and lights (first person).
	k.ceiling(-9.0, -7.8, 46.0, 8.2, HEIGHT, Color("f5f5f2"))
	for x in range(2, 46, 4):
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, 0.0), Vector2(1.6, 0.34))
	# 4 East: closed double doors with vision panels; its corridor runs on beyond.
	k.wall(true, 36.0, -1.6, 1.6, HEIGHT, WALL, true, [[0.0, 2.4, 2.4]])
	for side in [-1, 1]:
		k.box("walnut", Vector3(36.0, 1.15, side * 0.6), Vector3(0.08, 2.3, 1.18), Color.WHITE, "fp")
		k.box("light", Vector3(35.95, 1.55, side * 0.6), Vector3(0.02, 0.62, 0.34), Color("e8f1f5"), "fp")
		k.box("metal", Vector3(35.93, 1.0, side * 0.2), Vector3(0.04, 0.05, 0.3), Color("c9ced2"), "fp")
	k.box("walnut", Vector3(36.0, 0.5, 0.0), Vector3(0.08, 1.0, 2.36), Color.WHITE, "tp")
	k.solid(Vector3(36.0, 1.2, 0.0), Vector3(0.2, 2.4, 2.4))
	hospital.add_sign("4 East →", hospital_offset(k, Vector3(35.9, 2.6, 0.0)), -PI / 2, 24, 0.007, "fp")
	# 4 East's corridor continues past the doors, lined with more rooms.
	k.wall(false, -1.6, 36.0, 46.0, HEIGHT, WALL, true)
	k.wall(false, 1.6, 36.0, 46.0, HEIGHT, WALL, true)
	for x in [40.8, 44.4]:
		for side in [-1, 1]:
			k.box("tinted", Vector3(x, 1.15, side * 1.54), Vector3(1.5, 2.3, 0.04), Color("b9cbd6"), "fp")
	k.box("light", Vector3(45.8, 1.6, 0.0), Vector3(0.04, 2.2, 3.0), Color("cfe6f1"), "fp")

static func hospital_offset(k, local: Vector3) -> Vector3:
	return local + k.offset

# --- Elevator lobby -----------------------------------------------------------------------

static func _elevator_lobby(hospital: Node3D, k, at: Callable) -> void:
	# West wall with two cars; the one at z = +1.8 is the working car.
	k.wall(true, -6.0, -4.0, 4.0, HEIGHT, WALL, false, [[-1.8, 1.3, 2.36], [1.8, 1.3, 2.36]], 0.3)
	k.wall(false, -4.0, -9.0, 0.0, HEIGHT, WALL, false)
	k.wall(false, 4.0, -9.0, 0.0, HEIGHT, WALL, true, [[-3.0, 1.6, 2.3]])
	for z in [-1.8, 1.8]:
		Props.elevator_frame(k, Vector3(-5.84, 0, z), PI / 2, 1.3, z < 0.0)
		hospital.add_indicator(at.call(Vector3(-5.74, 2.72, z)), "4", PI / 2)
	var doors: Node3D = hospital.add_doors("UnitElevatorDoors", at.call(Vector3(-5.86, 0, 1.8)), PI / 2, 1.3, 2.36, false)
	hospital.unit_elevator = doors
	# The car behind the west wall.
	var metal := Color("aeb5ba")
	k.box("paving", Vector3(-7.25, 0.0, 1.8), Vector3(2.4, 0.02, 2.2), Color("6e757a"))
	k.box("metal", Vector3(-8.5, 1.3, 1.8), Vector3(0.1, 2.6, 2.3), metal, "always", true)
	for side in [-1, 1]:
		k.box("metal", Vector3(-7.25, 1.3, 1.8 + side * 1.12), Vector3(2.4, 2.6, 0.1), metal, "always", true)
	k.box("facade", Vector3(-7.25, 2.62, 1.8), Vector3(2.4, 0.1, 2.3), Color("d9dcde"), "fp")
	k.box("light", Vector3(-7.25, 2.56, 1.8), Vector3(1.2, 0.02, 1.4), Color("fffaf0"), "fp")
	k.box("metal", Vector3(-8.43, 0.95, 1.8), Vector3(0.05, 0.05, 2.0), Color("d9dcde"))
	k.box("metal", Vector3(-6.4, 1.2, 2.845), Vector3(0.2, 0.5, 0.05), Color("2a2f33"))
	hospital.add_elevator_call("UnitElevator", at.call(Vector3(-5.6, 1.15, 1.8 - 0.97)), "lobby")
	# Wayfinding and a floor directory.
	hospital.add_sign("4 West · Internal Medicine\nRooms 410–432 →", at.call(Vector3(-3.0, 1.55, -3.84)), 0.0, 26, 0.0065, "always")
	# A staff door (closed) in the south wall.
	k.box("walnut", Vector3(-3.0, 1.15, 4.0), Vector3(1.5, 2.3, 0.06), Color.WHITE, "fp")
	k.box("walnut", Vector3(-3.0, 0.525, 4.0), Vector3(1.5, 1.05, 0.06), Color.WHITE, "tp")
	k.box("metal", Vector3(-2.5, 1.05, 3.95), Vector3(0.05, 0.3, 0.04), TRIM, "fp")
	k.solid(Vector3(-3.0, 1.15, 4.0), Vector3(1.6, 2.3, 0.2))
	hospital.add_sign("Staff only", at.call(Vector3(-3.0, 2.0, 3.97)), PI, 22, 0.006, "fp")
	# Double doors onto the unit, held open against the walls.
	for side in [-1, 1]:
		k.box("walnut", Vector3(0.6, 1.15, side * 1.52), Vector3(1.18, 2.3, 0.06), Color.WHITE, "fp")

# --- Patient rooms ------------------------------------------------------------------------

static func _patient_room(hospital: Node3D, k, at: Callable, number: int, x0: float) -> void:
	var open := number in OPEN_ROOMS
	var door := x0 + DOOR_OFFSET
	k.floor_rect(x0 + 0.08, -7.65, x0 + 5.92, -1.68, ROOM_FLOOR, 0.006)
	# Bathroom in the corner by the door.
	k.wall(true, x0 + 2.2, -4.2, -1.6, HEIGHT, WALL, true, [[-2.9, 0.9, 2.2]], 0.12)
	k.wall(false, -4.2, x0, x0 + 2.2, HEIGHT, WALL, true, [], 0.12)
	k.box("walnut", Vector3(x0 + 2.26, 1.1, -2.9), Vector3(0.04, 2.2, 0.9), Color.WHITE, "fp")
	k.box("walnut", Vector3(x0 + 2.26, 0.525, -2.9), Vector3(0.04, 1.05, 0.9), Color.WHITE, "tp")
	k.solid(Vector3(x0 + 2.2, 1.1, -2.9), Vector3(0.12, 2.2, 0.9))
	# Headwall, bed and the patient's side of the room.
	k.box("facade", Vector3(x0 + 0.1, 1.4, -6.0), Vector3(0.05, 0.9, 1.7), Color("d8dde0"))
	for index in range(4):
		k.box("facade", Vector3(x0 + 0.13, 1.15 + (index % 2) * 0.28, -6.5 + index * 0.33), Vector3(0.02, 0.08, 0.12), Color("8a9aa3"))
	Props.monitor(k, Vector3(x0 + 0.12, 1.55, -6.55), PI / 2, 0.42, Color("0f2a24"))
	Props.bed(k, Vector3(x0 + 0.15, 0, -6.0), PI / 2, number != 413)
	# Overbed table (window side; in 412 pushed aside for the team), IV pole, visitor chair.
	var table := Vector3(x0 + 3.5, 0, -7.1) if number == 412 else Vector3(x0 + 1.3, 0, -6.75)
	k.box("facade", table + Vector3(0, 0.95, 0), Vector3(0.9, 0.04, 0.42), Color("d9d2c4"))
	k.box("metal", table + Vector3(0, 0.48, -0.25), Vector3(0.05, 0.94, 0.05), TRIM)
	k.box("metal", table + Vector3(0, 0.03, -0.25), Vector3(0.6, 0.05, 0.3), TRIM)
	if number != 413:
		k.cylinder("metal", Vector3(x0 + 0.6, 0, -5.15), Vector3(x0 + 0.6, 1.9, -5.15), 0.02, Color("c9ced2"))
		k.box("tinted", Vector3(x0 + 0.6, 1.72, -5.1), Vector3(0.14, 0.24, 0.05), Color("e6f0f2"))
		k.box("facade", Vector3(x0 + 0.6, 1.2, -5.1), Vector3(0.18, 0.22, 0.14), Color("dfe6ea"))
	Props.armchair(k, Vector3(x0 + 4.9, 0, -6.8), -1.15, Color("6f8a80")) # Turned toward the bed.
	# Window with daylight, sill and a privacy curtain track.
	k.box("light", Vector3(x0 + 4.1, 1.65, -7.64), Vector3(3.0, 1.5, 0.02), Color("d7ebf3"))
	k.box("facade", Vector3(x0 + 4.1, 0.86, -7.58), Vector3(3.2, 0.06, 0.2), Color("f7f7f4"))
	for x in [x0 + 2.6, x0 + 4.1, x0 + 5.6]:
		k.box("metal", Vector3(x, 1.65, -7.62), Vector3(0.05, 1.5, 0.04), Color("c9ced2"))
	k.box("facade", Vector3(x0 + 2.55, 1.55, -7.55), Vector3(0.3, 2.1, 0.1), Color("9fb8b0"), "fp")
	# Sliding glass door: parked open, or closed with the curtain drawn.
	if open:
		k.box("tinted", Vector3(door - 1.62, 1.15, -1.72), Vector3(1.5, 2.3, 0.04), Color("d7e6ea"), "fp")
		k.box("facade", Vector3(door - 0.9, 1.3, -1.9), Vector3(0.5, 2.3, 0.05), Color("9fb8b0"), "fp")
	else:
		k.box("tinted", Vector3(door, 1.15, -1.6), Vector3(1.6, 2.3, 0.04), Color("d7e6ea"), "fp")
		k.box("facade", Vector3(door, 1.2, -1.72), Vector3(1.56, 2.2, 0.05), Color("9fb8b0"), "fp")
		k.box("facade", Vector3(door, 0.525, -1.66), Vector3(1.6, 1.05, 0.08), Color("9fb8b0"), "tp")
		k.solid(Vector3(door, 1.15, -1.6), Vector3(1.6, 2.3, 0.16))
	# Door frame, room number and hand-hygiene dispensers inside and out.
	k.box("metal", Vector3(door, 2.34, -1.6), Vector3(1.8, 0.08, 0.2), Color("9aa2a7"), "fp")
	hospital.add_sign(str(number), at.call(Vector3(door + 1.05, 1.55, -1.52)), 0.0, 30, 0.006, "fp")
	hospital.add_floor_label(str(number), at.call(Vector3(door, 0.012, -0.95)))
	Props.dispenser(k, Vector3(door - 1.05, 0.98, -1.53), 0.0)
	hospital.add_dispenser("dispenser_%d" % number, at.call(Vector3(door - 1.05, 0.98, -1.2)))
	if open:
		Props.dispenser(k, Vector3(door + 1.0, 0.98, -1.67), PI)
		hospital.add_dispenser("dispenser_%d_in" % number, at.call(Vector3(door + 1.0, 0.98, -2.0)))
	# Room lights and whiteboard (first person).
	k.ceiling_light(Vector3(x0 + 3.0, HEIGHT - 0.02, -4.8), Vector2(1.2, 1.2))
	var board := "Room %d · Monday, Sept 21\nNurse: Priya · Team: Dr. Okafor\nToday's goal: walk twice" % number
	if number == 413:
		board = "Room 413 · Ready for admission\nCleaned 8:40 AM"
	hospital.add_sign(board, at.call(Vector3(x0 + 5.92, 1.55, -4.6)), -PI / 2, 24, 0.0048, "fp", Color("f7f7f4"), Color("24343c"))
	# Who is in the room.
	var hip: Vector3 = Vector3(x0 + 0.15, 0, -6.0) + Basis(Vector3.UP, PI / 2) * Props.patient_hip()
	if number == 412:
		hospital.add_figure("patient", at.call(hip), -PI / 2, "bed")
		# The resident presents from the window side of the bed.
		hospital.add_figure("resident", at.call(Vector3(x0 + 2.0, 0, -7.12)), PI, "stand")
	elif number != 413:
		var rng := RandomNumberGenerator.new()
		rng.seed = number
		var look: Dictionary = Looks.random(rng)
		look.outfit.outerwear = ""
		look.outfit.head = ""
		look.outfit.back = ""
		look.outfit.neck = ""
		hospital.add_figure(look, at.call(hip), -PI / 2, "bed")
	if number == 413:
		hospital.add_endpoint("Room413Bed", "Look around room 413", "An empty room, cleaned and ready. The bed tilts and rises, the rails fold down, and the call button sits by the pillow. The headwall has oxygen, suction and the monitor; the whiteboard tells patients who is caring for them today.", at.call(Vector3(x0 + 3.2, 1.0, -5.0)), 2.2)
	if number == ISOLATION_ROOM:
		hospital.add_sign("CONTACT PRECAUTIONS\nGown and gloves to enter\nClean hands in and out", at.call(Vector3(door, 1.5, -1.56)), 0.0, 28, 0.0045, "fp", Color("f2c230"), Color("1d1d1d"))
		hospital.add_sign("CONTACT PRECAUTIONS", at.call(Vector3(door, 0.78, -1.58)), 0.0, 24, 0.0045, "tp", Color("f2c230"), Color("1d1d1d"))
		hospital.add_endpoint("IsolationSign", "Read the door sign", "Contact Precautions: clean your hands, then put on a gown and gloves before entering. Take them off at the door and clean your hands again as you leave.", at.call(Vector3(door, 1.0, -1.1)), 1.8)

# --- South side --------------------------------------------------------------------------

static func _supply(hospital: Node3D, k, at: Callable) -> void:
	for z in [7.8]:
		k.box("metal", Vector3(4.5, 0.9, z), Vector3(7.8, 1.8, 0.5), Color("c9ced2"), "always", true)
		for row in range(4):
			for bin in range(12):
				k.box("facade", Vector3(1.2 + bin * 0.6, 0.3 + row * 0.42, z - 0.28), Vector3(0.45, 0.2, 0.06), [Color("5aa9d6"), Color("e8e8e2"), Color("7fd6a0"), Color("f2c46d")][(bin + row) % 4])
	k.box("metal", Vector3(0.45, 0.9, 5.0), Vector3(0.5, 1.8, 4.6), Color("c9ced2"), "always", true)
	hospital.add_sign("Clean Supply", at.call(Vector3(3.1, 1.55, 1.52)), PI, 24, 0.006, "fp")
	hospital.add_floor_label("SUPPLY", at.call(Vector3(4.7, 0.012, 0.95)))

static func _station(hospital: Node3D, k, at: Callable) -> void:
	# Back wall in warm yellow, as on the reference unit.
	k.wall(false, 6.2, 9.5, 22.0, HEIGHT, ACCENT, true)
	# Counter: walnut front to the corridor, white top, a lower desk behind.
	k.box("walnut", Vector3(15.25, 0.53, 2.0), Vector3(10.5, 1.06, 0.08), Color.WHITE, "always")
	k.box("facade", Vector3(15.25, 1.08, 2.25), Vector3(10.6, 0.05, 0.56), Color("f7f7f4"))
	k.box("facade", Vector3(15.25, 0.76, 3.0), Vector3(10.4, 0.04, 0.8), Color("e4e1da"))
	k.box("facade", Vector3(15.25, 0.38, 3.35), Vector3(10.4, 0.76, 0.06), Color("d9d4ca"))
	k.solid(Vector3(15.25, 0.55, 2.6), Vector3(10.6, 1.1, 1.4))
	for x in [11.2, 13.8, 16.4, 19.0]:
		Props.monitor(k, Vector3(x, 0.78, 2.9), 0.0, 0.5, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, 4.1), PI)
	# Central telemetry on the back wall, where the nurses at the desk can see it (first person).
	k.box("facade", Vector3(12.0, 1.9, 6.1), Vector3(2.0, 1.1, 0.06), Color("0b1a18"), "fp")
	for row in range(4):
		for column in range(2):
			var cell := Vector3(11.5 + column * 1.0, 2.25 - row * 0.24, 6.06)
			k.box("light", cell, Vector3(0.8, 0.012, 0.01), Color("62d69a"), "fp")
			k.box("light", cell + Vector3(-0.2, 0.05, 0), Vector3(0.05, 0.1, 0.01), Color("62d69a"), "fp")
	hospital.add_sign("Nurses Station · 4 West", at.call(Vector3(15.25, 0.72, 1.94)), PI, 26, 0.007, "always")
	# Census board on the back wall (first person).
	k.box("facade", Vector3(15.8, 1.9, 6.1), Vector3(2.2, 1.3, 0.06), Color("16202a"), "fp")
	for row in range(7):
		k.box("light", Vector3(15.8, 2.4 - row * 0.15, 6.06), Vector3(1.9, 0.05, 0.01), Color("5ec8b5") if row == 0 else Color("7d9aa3"), "fp")
	# Wood slat ceiling over the station (first person).
	for index in range(22):
		k.box("wood", Vector3(9.8 + index * 0.56, HEIGHT - 0.12, 3.9), Vector3(0.12, 0.08, 4.4), Color.WHITE, "fp")
	# Nurses at work, and the charge nurse at the open end of the counter.
	hospital.add_figure("nurse", at.call(Vector3(13.8, 0, 4.1)), 0.0, "seated", Props.OFFICE_SEAT)
	hospital.add_figure("teal", at.call(Vector3(19.0, 0, 4.1)), 0.0, "seated", Props.OFFICE_SEAT)
	var nurse: Node3D = hospital.add_figure("charge_nurse", at.call(Vector3(21.1, 0, 2.7)), 0.55, "stand")
	hospital.charge_nurse = nurse
	hospital.targets["charge_nurse"] = hospital.add_endpoint("ChargeNurse", "Talk to Priya (charge nurse)", "\"Morning! Your team's rooms are on the board. Ask me if you can't find someone.\"", at.call(Vector3(21.1, 1.1, 2.2)), 2.3)

static func _workroom(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(22.08, 1.68, 29.92, 8.12, Color("d1d4d3"), 0.006)
	# Glass door slid open beside the doorway.
	k.box("tinted", Vector3(25.25, 1.15, 1.72), Vector3(1.4, 2.3, 0.04), Color("d7e6ea"), "fp")
	hospital.add_sign("Team Workroom\nStaff only", at.call(Vector3(22.55, 1.55, 1.52)), PI, 22, 0.005, "fp")
	hospital.add_floor_label("WORKROOM", at.call(Vector3(23.8, 0.012, 0.95)))
	# Island of workstations.
	k.box("facade", Vector3(26.6, 0.74, 4.8), Vector3(4.0, 0.05, 2.2), Color("f7f7f4"))
	k.box("facade", Vector3(26.6, 0.36, 4.8), Vector3(3.8, 0.72, 2.0), Color("c9c4b8"))
	k.solid(Vector3(26.6, 0.4, 4.8), Vector3(4.0, 0.8, 2.2))
	for x in [25.4, 27.8]:
		Props.monitor(k, Vector3(x, 0.765, 5.75), 0.0, 0.5, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, 6.6), PI)
	Props.monitor(k, Vector3(27.6, 0.765, 3.85), PI, 0.5, Color("24424a"))
	# The EHR workstation (its screen is drawn live by the hospital scene).
	k.box("metal", Vector3(26.3, 0.78, 3.87), Vector3(0.2, 0.02, 0.16), TRIM)
	k.box("metal", Vector3(26.3, 0.92, 3.9), Vector3(0.04, 0.28, 0.03), TRIM)
	k.box("metal", Vector3(26.3, 1.1, 3.87), Vector3(0.58, 0.36, 0.03), Color("20252a"))
	k.box("facade", Vector3(26.3, 0.775, 3.62), Vector3(0.42, 0.02, 0.14), Color("2a2f33"))
	hospital.add_ehr_screen(at.call(Vector3(26.3, 1.1, 3.852)), PI, Vector2(0.54, 0.3375))
	hospital.add_endpoint("EHRWorkstation", "Use the EHR workstation", "Student access is view-only and logged. Chart review happens with your team, for the patients you are involved with.", at.call(Vector3(26.3, 1.0, 3.3)), 1.6)
	# Whiteboard and the student orientation board (first person).
	hospital.add_sign("Team B · Internal Medicine\nAttending: Dr. Okafor\nResident: Dr. Martin\nRounds 9:30 · Discharges before noon", at.call(Vector3(29.92, 1.6, 4.8)), -PI / 2, 24, 0.0048, "fp", Color("f7f7f4"), Color("24343c"))
	hospital.add_sign("Welcome, students!\nBadge visible · phone on silent\nFoam in, foam out\nAsk the charge nurse", at.call(Vector3(25.6, 1.6, 8.08)), PI, 24, 0.0048, "fp", Color("e8f1ec"), Color("24343c"))
	k.box("facade", Vector3(22.4, 0.46, 6.5), Vector3(0.6, 0.92, 2.4), Color("5b4a3d"), "always", true)
	k.box("metal", Vector3(22.4, 1.1, 7.2), Vector3(0.36, 0.36, 0.3), Color("2a2f33"))
	hospital.add_figure("indigo", at.call(Vector3(27.8, 0, 6.6)), 0.0, "seated", Props.OFFICE_SEAT)

static func _lounge(hospital: Node3D, k, at: Callable) -> void:
	Props.curved_sofa(k, Vector3(33.0, 0, 4.2), 1.9, PI * 0.5 - 0.9, PI * 0.5 + 0.9, 4, Color("6f8a80"))
	Props.round_table(k, Vector3(33.0, 0, 4.4), 0.4, 0.46)
	k.box("facade", Vector3(33.0, 1.6, 8.06), Vector3(1.6, 0.9, 0.05), Color("16202a"), "fp")
	hospital.add_sign("Family Lounge", at.call(Vector3(34.5, 1.55, 1.52)), PI, 22, 0.006, "fp")
	hospital.add_floor_label("LOUNGE", at.call(Vector3(32.8, 0.012, 0.95)))
	var angle := PI * 0.5 - 0.45
	hospital.add_figure("plum", at.call(Vector3(33.0, 0, 4.2) + Vector3(sin(angle), 0, cos(angle)) * 1.9), angle, "seated", Props.SOFA_SEAT)

static func _corridor_details(hospital: Node3D, k, at: Callable) -> void:
	# Handrails along the corridor between doorways.
	var north_gaps: Array = []
	for room in ROOMS:
		north_gaps.append(room[1] + DOOR_OFFSET)
	_rail(k, -1.5, 0.3, 35.8, north_gaps, 1.0)
	_rail(k, 1.5, 0.3, 9.4, [4.7], 0.9)
	_rail(k, 1.5, 22.2, 35.8, [23.8, 32.8], 0.9)
	# Workstation on wheels, vitals monitor, linen and isolation carts.
	k.box("metal", Vector3(21.2, 0.5, -1.15), Vector3(0.6, 1.0, 0.5), Color("dfe6ea"), "always", true)
	Props.monitor(k, Vector3(21.2, 1.0, -1.25), 0.0, 0.4, Color("24424a"))
	k.box("metal", Vector3(8.6, 0.6, -1.2), Vector3(0.4, 1.2, 0.4), Color("c9ced2"), "always", true)
	k.box("light", Vector3(8.6, 1.3, -1.02), Vector3(0.3, 0.2, 0.02), Color("0b2a22"))
	k.box("facade", Vector3(34.8, 0.55, 1.15), Vector3(1.0, 1.1, 0.5), Color("e8e8e2"), "always", true)
	var cart := Vector3(27.2, 0, -1.28)
	k.box("facade", cart + Vector3(0, 0.5, 0), Vector3(0.8, 1.0, 0.44), Color("d9b84a"), "always", true)
	for row in range(3):
		k.box("facade", cart + Vector3(0, 0.2 + row * 0.28, 0.23), Vector3(0.7, 0.2, 0.02), Color("bf9d3a"))
	for item in range(3):
		k.box("facade", cart + Vector3(-0.25 + item * 0.25, 1.08, 0), Vector3(0.2, 0.14, 0.3), [Color("5aa9d6"), Color("e8e8e2"), Color("7fb8e8")][item])
	# A call light above room 411's door.
	k.box("light", Vector3(6.0 + DOOR_OFFSET, 2.55, -1.5), Vector3(0.3, 0.1, 0.06), Color("f6d98a"), "fp")

static func _rail(k, z: float, from: float, to: float, gaps: Array, width: float) -> void:
	var cursor := from
	var sorted := gaps.duplicate()
	sorted.sort()
	for gap in sorted:
		var start: float = gap - width / 2.0 - 0.1
		if start - cursor > 0.3:
			k.box("wood", Vector3((cursor + start) / 2.0, 0.9, z), Vector3(start - cursor, 0.06, 0.06), Color.WHITE)
		cursor = gap + width / 2.0 + 0.1
	if to - cursor > 0.3:
		k.box("wood", Vector3((cursor + to) / 2.0, 0.9, z), Vector3(to - cursor, 0.06, 0.06), Color.WHITE)

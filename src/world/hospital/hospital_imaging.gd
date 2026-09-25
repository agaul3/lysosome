extends RefCounted
## Emergency Radiology on the Emergency Department's second level: the
## imaging ED patients need quickly. Zone-local coordinates, x east, z south;
## the ED elevators arrive at the south-west.
##   North: CT 1 and CT 2, each with its control room behind lead glass; the
##          MRI suite (Zone III control room, Zone IV magnet room with the
##          RF-shielded door and a ferromagnetic detector); an X-ray room.
##   South: the elevator lobby, patient holding bays, the radiologists'
##          reading room, ultrasound, and MRI safety screening and changing.
## The CT and MRI tables slide in and out with patients on them
## (world/hospital/ed_life.gd runs them and a transport crew).
const Props = preload("res://world/hospital/hospital_props.gd")
const ED = preload("res://world/hospital/hospital_ed.gd")
const RadiologyImages = preload("res://ui/radiology_images.gd")
const X0 := -23.0
const X1 := 23.0
const Z0 := -13.0
const Z1 := 13.0
const HEIGHT := 3.2
const CORRIDOR_N := -1.5
const CORRIDOR_S := 2.5
const FLOOR := Color("c9c8c3")
const WALL := Color("e3e2dc")
const FRAME := Color("9aa2a7")
const COPPER := Color("b87a4b")
const ELEVATOR_X := -16.0
const CAB := Rect2(ELEVATOR_X - 1.05, 10.75, 2.1, 2.25)
const ANCHORS := {
	"imaging_arrival": Vector3(ELEVATOR_X, 0, 8.4),
	"imaging_corridor": Vector3(-6.0, 0, 0.5),
	"imaging_ct1": Vector3(-18.5, 0, 0.5),
	"imaging_mri": Vector3(10.5, 0, 0.5),
}
const YELLOW := Color("f2c230")

static func build(hospital: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		hospital.set_anchor(id, at.call(ANCHORS[id]))
	var layout := {"tables": [], "holding": [], "points": {}}
	hospital.imaging_layout = layout
	_shell(hospital, k, at)
	_ct_rooms(hospital, k, at, layout)
	_mri(hospital, k, at, layout)
	_xray(hospital, k, at)
	_elevators(hospital, k, at)
	_holding(hospital, k, at, layout)
	_reading_room(hospital, k, at)
	_ultrasound_and_screening(hospital, k, at)
	layout.points["elevator_front"] = at.call(Vector3(ELEVATOR_X, 0, 8.9))
	layout.points["corridor_west"] = at.call(Vector3(-16.0, 0, 0.5))
	layout.points["corridor_holding"] = at.call(Vector3(-6.0, 0, 0.5))

# --- Shell -------------------------------------------------------------------------------------

static func _shell(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(X0, CORRIDOR_N, X1, CORRIDOR_S, FLOOR.darkened(0.06), 0.004)
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [], 0.3)
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f1f1ee"))
	for x in range(-20, 23, 5):
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, 0.5), Vector2(2.2, 0.22))
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, -7.0), Vector2(1.2, 1.2))
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, 8.0), Vector2(1.2, 1.2))
	# Corridor walls with the room doors.
	k.wall(false, CORRIDOR_N, X0, X1, HEIGHT, WALL, true, [[-18.5, 1.8, 2.4], [-12.5, 0.9, 2.2], [-6.5, 1.8, 2.4], [-0.5, 0.9, 2.2], [3.0, 0.9, 2.2], [10.5, 1.6, 2.4], [19.5, 1.6, 2.4]])
	k.wall(false, CORRIDOR_S, 1.0, X1, HEIGHT, WALL, true, [[4.0, 1.0, 2.2], [15.5, 1.2, 2.2], [20.5, 0.9, 2.2]])
	for x in [-11.0, 16.0]:
		k.wall(true, x, Z0, CORRIDOR_N, HEIGHT, WALL, true)
	for x in [1.0, 13.0, 18.0]:
		k.wall(true, x, CORRIDOR_S, Z1, HEIGHT, WALL, true)
	k.wall(true, -13.0, 6.0, Z1, HEIGHT, WALL, true)
	hospital.add_sign("Emergency Radiology · Level 2", at.call(Vector3(-6.0, 2.5, CORRIDOR_N + 0.08)), 0.0, 24, 0.0065, "fp")
	hospital.add_floor_label("EMERGENCY RADIOLOGY · L2", at.call(Vector3(-2.0, 0.012, 0.6)), 0.0055)

## A partition along z at x with a lead-glass viewing window (sill 0.95 m).
static func _window_wall(k, x: float, z0: float, z1: float, window_z: float, window_w: float) -> void:
	k.wall(true, x, z0, z1, HEIGHT, WALL, true, [[window_z, window_w, 2.15]])
	k.box("facade", Vector3(x, 0.475, window_z), Vector3(0.16, 0.95, window_w), WALL)
	k.solid(Vector3(x, 1.1, window_z), Vector3(0.16, 2.2, window_w))
	k.box("tinted", Vector3(x, 1.55, window_z), Vector3(0.04, 1.2, window_w - 0.1), Color("9fb8bf"), "fp")
	k.box("metal", Vector3(x, 0.97, window_z), Vector3(0.2, 0.04, window_w), FRAME)

## A sliding scanner tabletop with an optional patient lying on it, as its own node.
static func _table(hospital: Node3D, at: Callable, name: String, base: Vector3, occupied: bool, seed: int) -> Node3D:
	var node: Node3D = hospital.add_prop_node(name, at.call(base))
	var kit := Props.NodeKit.new()
	kit.box("facade", Vector3(0, 0.94, 0), Vector3(0.52, 0.06, 2.3), Color("eef0f0"))
	kit.box("facade", Vector3(0, 0.99, 0.1), Vector3(0.46, 0.05, 2.0), Color("35557a"))
	kit.commit(node, "Tabletop")
	if occupied:
		var patient := Node3D.new()
		patient.name = "Patient"
		patient.position = Vector3(0, 1.1, -0.05)
		node.add_child(patient)
		var look := preload("res://player/appearance.gd").new()
		patient.add_child(look)
		look.apply_look(ED.patient_look(seed))
		Props.lay(patient, look, 0.0, PI)
	return node

# --- CT --------------------------------------------------------------------------------------------

static func _ct_rooms(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	for room in [["CT 1", -18.5, -14.0, 0, true], ["CT 2", -6.5, -2.0, 2, false]]:
		var name: String = room[0]
		var x: float = room[1]
		var control: float = room[2]
		_window_wall(k, control, Z0, CORRIDOR_N, -6.8, 2.4)
		Props.ct_gantry(k, Vector3(x, 0, -9.6), 0.0)
		Props.scanner_table_base(k, Vector3(x, 0, -9.6), 0.0, 1.8)
		k.box("light", Vector3(x, 2.12, -9.12), Vector3(0.3, 0.02, 0.01), Color("ff3b30"))
		var table: Node3D = _table(hospital, at, name.replace(" ", "") + "Table", Vector3(x, 0, -6.9), room[4], 30 + int(x))
		layout.tables.append({"node": table, "out": at.call(Vector3(x, 0, -6.9)), "in": at.call(Vector3(x, 0, -8.7)), "occupied": room[4], "name": name})
		hospital.add_floor_label(name, at.call(Vector3(x, 0.012, -3.2)), 0.007)
		hospital.add_sign("%s\nCAUTION · RADIATION AREA" % name, at.call(Vector3(x - 1.6, 1.55, CORRIDOR_N + 0.08)), 0.0, 20, 0.0048, "fp", YELLOW, Color("1d1d1d"))
		# Control room: technologist, scanner console and image monitors.
		var cx := control + 1.5
		k.box("facade", Vector3(control + 0.55, 0.74, -6.8), Vector3(0.9, 0.05, 2.6), Color("f7f7f4"))
		k.box("facade", Vector3(control + 0.55, 0.37, -6.8), Vector3(0.8, 0.74, 2.5), Color("d9d4ca"), "always", true)
		for index in range(3):
			var z := -7.7 + index * 0.9
			Props.monitor(k, Vector3(control + 0.35, 0.765, z), PI / 2, 0.5, Color("24424a"))
			if index == 1:
				hospital.add_screen(hospital.radiology_texture(), at.call(Vector3(control + 0.37, 1.105, z)), PI / 2, Vector2(0.44, 0.26), RadiologyImages.tile_rect(0 if control < -5.0 else 2))
		Props.office_chair(k, Vector3(cx, 0, -6.8), -PI / 2)
		hospital.add_figure(ED.staff_look("rad_tech", 400 + int(x)), at.call(Vector3(cx, 0, -6.8)), PI / 2, "seated", Props.OFFICE_SEAT)
		hospital.add_sign("%s Control" % name, at.call(Vector3(control + 1.5, 2.3, CORRIDOR_N + 0.08)), 0.0, 20, 0.005, "fp")
		# Supply counter along the scanner room's side wall and a contrast injector.
		var wall_x := control - 8.6
		k.box("facade", Vector3(wall_x + 0.35, 0.45, -8.0), Vector3(0.6, 0.9, 3.0), Color("dfe3e6"), "always", true)
		k.box("facade", Vector3(wall_x + 0.35, 0.92, -8.0), Vector3(0.64, 0.04, 3.1), Color("f7f7f4"))
		k.cylinder("metal", Vector3(x + 1.5, 0, -8.2), Vector3(x + 1.5, 1.3, -8.2), 0.03, Props.METAL)
		k.box("facade", Vector3(x + 1.5, 1.4, -8.2), Vector3(0.3, 0.26, 0.24), Color("e3e8ea"))
		k.box("light", Vector3(x + 1.5, 1.42, -8.07), Vector3(0.16, 0.1, 0.005), Color("3fd28a"))
	hospital.add_endpoint("CTScanner", "Look at the CT scanner", "A CT scanner: the X-ray tube spins around the ring while the table slides the patient through, building cross-sections in seconds. Trauma and stroke patients come straight here from the ED; the technologist runs the scan from behind the lead-glass window.", at.call(Vector3(-18.5, 1.0, -2.3)), 1.9)

# --- MRI ---------------------------------------------------------------------------------------------

static func _mri(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	_window_wall(k, 5.0, Z0, CORRIDOR_N, -6.8, 2.2)
	k.wall(true, 1.0, Z0, CORRIDOR_N, HEIGHT, WALL, true)
	k.floor_rect(5.1, Z0 + 0.1, 15.9, CORRIDOR_N - 0.1, Color("d6d3cc"), 0.006)
	Props.mri_magnet(k, Vector3(10.5, 0, -9.6), 0.0)
	Props.scanner_table_base(k, Vector3(10.5, 0, -8.6), 0.0, 1.8)
	var table: Node3D = _table(hospital, at, "MRITable", Vector3(10.5, 0, -6.2), true, 88)
	layout.tables.append({"node": table, "out": at.call(Vector3(10.5, 0, -6.2)), "in": at.call(Vector3(10.5, 0, -8.0)), "occupied": true, "name": "MRI"})
	# The RF-shielded door (copper frame) and ferromagnetic detector posts.
	for side in [-1, 1]:
		k.box("metal", Vector3(10.5 + side * 0.86, 1.2, CORRIDOR_N), Vector3(0.12, 2.4, 0.22), COPPER)
		k.box("facade", Vector3(10.5 + side * 1.2, 0.9, CORRIDOR_N + 0.35), Vector3(0.12, 1.8, 0.12), Color("8b949a"), "always", true)
		k.box("light", Vector3(10.5 + side * 1.2, 1.7, CORRIDOR_N + 0.42), Vector3(0.08, 0.06, 0.01), Color("3fd28a"))
	k.box("metal", Vector3(10.5, 2.44, CORRIDOR_N), Vector3(1.84, 0.1, 0.22), COPPER)
	k.box("facade", Vector3(10.5, 0.007, CORRIDOR_N + 0.35), Vector3(1.6, 0.012, 0.12), Color("c3302b"))
	hospital.add_sign("MRI · ZONE IV\nStrong magnetic field\nThe magnet is always on", at.call(Vector3(13.2, 1.6, CORRIDOR_N + 0.08)), 0.0, 20, 0.0048, "fp", Color("c3302b"), Color.WHITE)
	hospital.add_floor_label("MRI · ZONE IV", at.call(Vector3(10.5, 0.012, -3.4)), 0.007)
	# Zone III control room.
	k.box("facade", Vector3(4.45, 0.74, -6.8), Vector3(0.9, 0.05, 2.4), Color("f7f7f4"))
	k.box("facade", Vector3(4.45, 0.37, -6.8), Vector3(0.8, 0.74, 2.3), Color("d9d4ca"), "always", true)
	for index in range(2):
		Props.monitor(k, Vector3(4.65, 0.765, -7.3 + index * 1.0), -PI / 2, 0.5, Color("24424a"))
	hospital.add_screen(hospital.radiology_texture(), at.call(Vector3(4.63, 1.105, -6.3)), -PI / 2, Vector2(0.44, 0.26), RadiologyImages.tile_rect(3))
	Props.office_chair(k, Vector3(3.0, 0, -6.8), PI / 2)
	hospital.add_figure(ED.staff_look("rad_tech", 431), at.call(Vector3(3.0, 0, -6.8)), -PI / 2, "seated", Props.OFFICE_SEAT)
	hospital.add_sign("ZONE III\nScreened patients and staff only", at.call(Vector3(3.0, 2.3, CORRIDOR_N + 0.08)), 0.0, 20, 0.0048, "fp", YELLOW, Color("1d1d1d"))
	hospital.add_floor_label("ZONE III", at.call(Vector3(3.0, 0.012, -3.4)))
	hospital.add_endpoint("MRISuite", "Read the MRI safety signs", "MRI safety zones: Zone III is the control area for screened people only; Zone IV is the magnet room. The magnet is always on, strong enough to pull oxygen tanks and scissors into the bore, so everyone is screened for metal and implants before entering, and the detector at the door alarms on ferromagnetic objects.", at.call(Vector3(10.5, 1.0, 1.0)), 2.0)

# --- X-ray ---------------------------------------------------------------------------------------------

static func _xray(hospital: Node3D, k, at: Callable) -> void:
	Props.xray(k, Vector3(19.5, 0, -8.0), 0.0)
	Props.bucky_stand(k, Vector3(21.9, 0, Z0 + 0.3), 0.0)
	for index in range(3):
		k.box("facade", Vector3(17.0 + index * 0.4, 1.1, Z0 + 0.25), Vector3(0.32, 1.0, 0.08), [Color("2f5fa0"), Color("7d5a86"), Color("3aa76d")][index])
	hospital.add_sign("X-RAY\nCAUTION · RADIATION AREA", at.call(Vector3(21.3, 1.6, CORRIDOR_N + 0.08)), 0.0, 20, 0.0048, "fp", YELLOW, Color("1d1d1d"))
	hospital.add_floor_label("X-RAY", at.call(Vector3(19.5, 0.012, -3.4)), 0.007)
	hospital.add_figure(ED.staff_look("rad_tech", 451), at.call(Vector3(18.1, 0, -6.2)), -PI / 2 + 0.4, "stand")

# --- Elevators, holding and reading ----------------------------------------------------------------------

static func _elevators(hospital: Node3D, k, at: Callable) -> void:
	var wall_z := 10.6
	k.wall(false, wall_z, X0, -13.0, HEIGHT, WALL, true, [[-20.0, 1.3, 2.36], [ELEVATOR_X, 1.3, 2.36]])
	for x in [-20.0, ELEVATOR_X]:
		Props.elevator_frame(k, Vector3(x, 0, wall_z - 0.08), PI, 1.3, x != ELEVATOR_X)
		hospital.add_indicator(at.call(Vector3(x, 2.72, wall_z - 0.16)), "2", PI)
	var doors: Node3D = hospital.add_doors("ImagingElevatorDoors", at.call(Vector3(ELEVATOR_X, 0, wall_z - 0.1)), PI, 1.3, 2.36, false)
	hospital.imaging_elevator = doors
	Props.elevator_cab(k, Vector3(ELEVATOR_X, 0, wall_z), PI, true)
	hospital.add_elevator_call("ImagingElevator", at.call(Vector3(ELEVATOR_X - 0.97, 1.15, wall_z - 0.4)), "ed")
	hospital.add_sign("Emergency Department · Level 1", at.call(Vector3(-18.0, 2.9, wall_z - 0.08)), PI, 20, 0.0055, "fp")
	hospital.add_floor_label("ELEVATORS · ED LEVEL 1", at.call(Vector3(-18.0, 0.012, 7.6)), 0.0048)

static func _holding(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	var xs := [-10.5, -6.5, -2.5]
	for index in range(xs.size()):
		var x: float = xs[index]
		var hip: Vector3 = Props.stretcher(k, Vector3(x, 0, 9.6), PI, Color("c9ced2"), Color("35557a"), 0.74, 0.5, index != 1)
		if index != 1:
			hospital.add_figure(ED.patient_look(460 + index), at.call(Vector3(x, 0, 9.6) + Basis(Vector3.UP, PI) * hip), 0.0, "bed", Props.ARMCHAIR_SEAT, 0.5)
		layout.holding.append({"center": at.call(Vector3(x, 0, 9.6)), "front": at.call(Vector3(x, 0, 6.2)), "occupied": index != 1})
		if index < xs.size() - 1:
			k.box("facade", Vector3(x + 2.0, 0.65, 10.4), Vector3(0.06, 1.3, 2.8), Color("b8c7cc"), "always", true)
		k.box("metal", Vector3(x, HEIGHT - 0.12, 7.6), Vector3(3.6, 0.03, 0.03), FRAME, "fp")
	Props.vitals_stand(k, Vector3(-8.6, 0, 11.6), PI)
	hospital.add_figure(ED.staff_look("ed_nurse", 470), at.call(Vector3(-4.6, 0, 7.2)), PI + 0.5, "stand")
	hospital.add_floor_label("PATIENT HOLDING", at.call(Vector3(-6.5, 0.012, 5.0)), 0.0055)

static func _reading_room(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(1.1, CORRIDOR_S + 0.1, 12.9, Z1 - 0.1, Color("4a5156"), 0.006)
	for index in range(4):
		var x := 2.6 + index * 2.8
		k.box("facade", Vector3(x, 0.72, 11.9), Vector3(2.4, 0.05, 0.9), Color("3a4045"))
		k.box("facade", Vector3(x, 0.36, 12.3), Vector3(2.3, 0.72, 0.06), Color("2b2f33"), "always", true)
		for screen in range(3):
			var offset := (screen - 1) * 0.72
			Props.monitor(k, Vector3(x + offset, 0.745, 11.8), PI, 0.62, Color("10161a"))
			hospital.add_screen(hospital.radiology_texture(), at.call(Vector3(x + offset, 1.085, 11.765)), PI, Vector2(0.56, 0.33), RadiologyImages.tile_rect((index + screen) % 4))
		Props.office_chair(k, Vector3(x, 0, 10.8), 0.0)
		if index != 2:
			hospital.add_figure(ED.staff_look("radiologist", 480 + index), at.call(Vector3(x, 0, 10.8)), PI, "seated", Props.OFFICE_SEAT)
	hospital.add_sign("Reading Room · Radiologists", at.call(Vector3(6.5, 2.3, CORRIDOR_S - 0.08)), PI, 20, 0.005, "fp")
	hospital.add_floor_label("READING ROOM", at.call(Vector3(7.0, 0.012, 5.0)), 0.0055)
	hospital.add_endpoint("ReadingRoom", "Look into the reading room", "The radiologists' reading room is kept dim so subtle findings on the screens are easier to see. Every ED scan is read here; critical findings are phoned straight to the treating team.", at.call(Vector3(4.0, 1.0, 3.4)), 1.8)

static func _ultrasound_and_screening(hospital: Node3D, k, at: Callable) -> void:
	Props.bed(k, Vector3(14.3, 0, 12.6), PI, false)
	Props.ultrasound(k, Vector3(16.8, 0, 11.0), -PI / 2 - 0.4)
	hospital.add_floor_label("ULTRASOUND", at.call(Vector3(15.5, 0.012, 4.2)), 0.0048)
	hospital.add_sign("Ultrasound", at.call(Vector3(15.5, 2.3, CORRIDOR_S - 0.08)), PI, 20, 0.005, "fp")
	for index in range(4):
		k.box("metal", Vector3(19.0 + index * 0.62, 0.95, 12.6), Vector3(0.58, 1.9, 0.5), Color("8b949a"), "always", true)
	k.box("wood", Vector3(20.5, 0.23, 9.8), Vector3(2.4, 0.06, 0.5), Color.WHITE, "always", true)
	hospital.add_sign("MRI safety screening\nRemove all metal · lockers here", at.call(Vector3(20.5, 2.3, CORRIDOR_S - 0.08)), PI, 20, 0.0048, "fp")
	hospital.add_floor_label("MRI SCREENING", at.call(Vector3(20.5, 0.012, 4.2)), 0.0048)

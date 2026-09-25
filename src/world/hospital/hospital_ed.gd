extends RefCounted
## University Hospital Emergency Department, Level 1: an adult Level I trauma
## center modelled on large urban academic EDs (see docs for sources). Zone-
## local coordinates, x east, z south; the exterior front (ambulance garage and
## walk-in entrance) is along z = +18, facing the overhead camera.
##
## Areas are organised by acuity using the Emergency Severity Index (ESI),
## the five-level triage scale used across US EDs, where Level 1 is the most
## critical:
##   Trauma & Resuscitation (ESI 1)  T1–T4 along the north-west, by the
##                                   ambulance entrance ("the trauma half")
##   Acute Care (ESI 2–3)            Rooms 1–12 along the north, around the
##                                   central nurses station
##   Super Track (ESI 4–5)           recliners by the waiting room, the
##                                   split-flow track for low-complexity care
## plus triage, registration, security screening and the waiting room at the
## walk-in (south-east), the EMS vestibule with two sets of automatic doors
## (south-west), the medication room, clean supply and decontamination, the
## elevators up to Emergency Radiology (Level 2), results waiting, physician
## workstations, and doors onward to the Boarder Care Unit and the main
## hospital. `layout` hands ed_life.gd what it needs to bring the department
## to life (bays, seats, doors, routes).
const Props = preload("res://world/hospital/hospital_props.gd")
const Looks = preload("res://data/looks.gd")
const VitalsAtlas = preload("res://ui/vitals_atlas.gd")
## Where the Emergency Department floor sits in the hospital scene.
const ORIGIN := Vector3(-140, 0, 0)
const X0 := -34.0
const X1 := 34.0
const Z0 := -18.0
const Z1 := 18.0
const HEIGHT := 3.4
const FLOOR := Color("c2c5c4")
const POD_FLOOR := Color("9d8e80")
const TRAUMA_FLOOR := Color("c3c9cb")
const WAIT_FLOOR := Color("8f969a")
const WALL := Color("e2e4e1")
const NAVY := Color("2f4a6b")
const GLASS := Color(0.84, 0.92, 0.95, 0.22)
const FRAME := Color("9aa2a7")
const RED := Color("c3302b")
## Front of the treatment rooms (glass, with sliding doors) and the corridor.
const ROOM_FRONT := -11.0
const CORRIDOR_Z := -9.0
## The working elevator car up to Emergency Radiology (zone-local).
const ELEVATOR_X := -11.5
const CAB := Rect2(ELEVATOR_X - 1.05, 14.15, 2.1, 2.25)
## Ambulance lane through the garage: it stops with its rear to the doors.
const LANE_Z := 24.5
const AMBULANCE_STOP := Vector3(-22.0, 0, LANE_Z)
const ANCHORS := {
	"ed_entrance": Vector3(30.0, 0, 15.0),
	"ed_exit": Vector3(30.0, 1.0, 17.3),
	"ed_link_door": Vector3(33.3, 1.0, -9.0),
	"ed_from_lobby": Vector3(32.2, 0, -9.0),
	"ed_triage": Vector3(18.5, 0, 8.0),
	"ed_trauma": Vector3(-29.0, 0, CORRIDOR_Z),
	"ed_station": Vector3(2.0, 0, 0.6),
	"ed_elevators": Vector3(ELEVATOR_X, 0, 11.5),
	"ed_meds": Vector3(-29.5, 0, 1.0),
	"ed_ems": Vector3(-22.0, 0, 8.0),
	"ed_super_track": Vector3(23.0, 0, -2.4),
}

static func build(hospital: Node3D, k) -> void:
	var at := func(local: Vector3) -> Vector3: return local + k.offset
	for id in ANCHORS:
		hospital.set_anchor(id, at.call(ANCHORS[id]))
	var layout := {"bays": [], "recliners": [], "waiting_seats": [], "results_seats": [], "triage": [], "points": {}, "doors": {}}
	hospital.ed_layout = layout
	_shell(hospital, k, at)
	_trauma(hospital, k, at, layout)
	_acute_rooms(hospital, k, at, layout)
	_station(hospital, k, at)
	_support_rooms(hospital, k, at, layout)
	_ems_entrance(hospital, k, at, layout)
	_elevators(hospital, k, at)
	_results_and_physicians(hospital, k, at, layout)
	_super_track(hospital, k, at, layout)
	_front_of_house(hospital, k, at, layout)
	_exterior(hospital, k, at, layout)
	_signage(hospital, k, at)
	var points: Dictionary = layout.points
	for id in ROUTE_POINTS:
		points[id] = at.call(ROUTE_POINTS[id])

## Named points for the life simulation's routes (zone-local).
const ROUTE_POINTS := {
	"walkin_outside": Vector3(30.0, 0, 20.4),
	"walkin_vestibule": Vector3(30.0, 0, 16.9),
	"walkin_inside": Vector3(30.0, 0, 14.9),
	"screening": Vector3(30.0, 0, 13.4),
	"after_screening": Vector3(30.0, 0, 11.8),
	"registration": Vector3(26.9, 0, 10.1),
	"registration_desk": Vector3(26.9, 0, 8.7),
	"st_doors_south": Vector3(31.5, 0, 5.8),
	"st_doors_north": Vector3(31.5, 0, 2.2),
	"st_aisle": Vector3(31.5, 0, -2.6),
	"corridor_east": Vector3(31.5, 0, CORRIDOR_Z),
	"corridor_mid": Vector3(2.0, 0, CORRIDOR_Z),
	"corridor_ems": Vector3(-22.0, 0, CORRIDOR_Z),
	"ems_mid": Vector3(-22.0, 0, 4.0),
	"ems_inner": Vector3(-22.0, 0, 13.0),
	"ems_vestibule": Vector3(-22.0, 0, 16.0),
	"ems_outer": Vector3(-22.0, 0, 19.2),
	"ems_curb": Vector3(-22.0, 0, 21.4),
	"elevator_front": Vector3(ELEVATOR_X, 0, 12.6),
	# Transports use the other car, leaving the working one clear.
	"service_elevator_front": Vector3(-15.5, 0, 12.6),
	"elevator_approach": Vector3(-14.0, 0, 5.0),
}

# --- Shell -------------------------------------------------------------------------------------

static func _shell(hospital: Node3D, k, at: Callable) -> void:
	k.floor_rect(X0, Z0, X1, Z1, FLOOR)
	k.floor_rect(-8.0, -7.0, 12.0, 6.0, POD_FLOOR, 0.004)
	k.floor_rect(X0, Z0, -14.0, ROOM_FRONT, TRAUMA_FLOOR, 0.004)
	k.floor_rect(12.4, 8.4, 25.2, 17.8, WAIT_FLOOR, 0.004)
	# Exterior walls: north and west stand full height, south and east are cutaways.
	k.wall(false, Z0, X0, X1, HEIGHT, WALL, false, [], 0.3)
	k.wall(true, X0, Z0, Z1, HEIGHT, WALL, false, [[CORRIDOR_Z, 2.4, 2.4]], 0.3)
	k.wall(false, Z1, X0, X1, HEIGHT, WALL, true, [[-30.0, 1.6, 2.3], [-22.0, 2.6, 2.6], [30.0, 3.0, 2.7]], 0.3)
	k.wall(true, X1, Z0, Z1, HEIGHT, WALL, true, [[CORRIDOR_Z, 2.4, 2.4]], 0.3)
	# Skirting on the far walls.
	k.box("facade", Vector3(0, 0.06, Z0 + 0.16), Vector3(X1 - X0, 0.12, 0.03), Color("5d6468"))
	k.box("facade", Vector3(X0 + 0.16, 0.06, 0), Vector3(0.03, 0.12, Z1 - Z0), Color("5d6468"))
	# Ceiling with linear lights (first person).
	k.ceiling(X0, Z0, X1, Z1, HEIGHT, Color("f1f1ee"))
	for x in range(-30, 34, 6):
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, CORRIDOR_Z), Vector2(2.4, 0.22))
		k.ceiling_light(Vector3(x, HEIGHT - 0.02, -14.5), Vector2(1.2, 1.2))
		for z in [-2.0, 6.0, 13.0]:
			k.ceiling_light(Vector3(x + 3, HEIGHT - 0.02, z), Vector2(1.2, 1.2))
	# Boarder Care Unit (west) and the main-hospital link (east): closed double doors.
	for spot in [[X0 + 0.16, 1.0], [X1 - 0.16, -1.0]]:
		for side in [-1, 1]:
			k.box("walnut", Vector3(spot[0], 1.15, CORRIDOR_Z + side * 0.6), Vector3(0.06, 2.3, 1.18), Color.WHITE, "fp" if spot[1] < 0 else "always")
			k.box("light", Vector3(spot[0] + spot[1] * 0.04, 1.55, CORRIDOR_Z + side * 0.6), Vector3(0.02, 0.6, 0.32), Color("e8f1f5"), "fp" if spot[1] < 0 else "always")
		k.solid(Vector3(spot[0], 1.2, CORRIDOR_Z), Vector3(0.2, 2.4, 2.4))
	k.box("walnut", Vector3(X1 - 0.16, 0.525, CORRIDOR_Z), Vector3(0.06, 1.05, 2.36), Color.WHITE, "tp")
	hospital.add_sign("Boarder Care Unit · Pods C–F\nAdmitted patients awaiting beds", at.call(Vector3(X0 + 0.16, 2.72, CORRIDOR_Z)), PI / 2, 22, 0.005, "always")
	hospital.add_sign("Main Hospital · Atrium →", at.call(Vector3(X1 - 0.16, 2.72, CORRIDOR_Z)), -PI / 2, 22, 0.006, "fp")

## A glass room front along x (at z) from x0 to x1, with automatic sliding
## glass doors that open for whoever walks up to them (the student, staff,
## patients, EMS crews). `locked` keeps them shut.
static func _glass_front(hospital: Node3D, k, at: Callable, name: String, z: float, x0: float, x1: float, door_x: float, door_w: float, locked := false) -> Node3D:
	var d0 := door_x - door_w / 2.0
	var d1 := door_x + door_w / 2.0
	for span in [[x0, d0], [d1, x1]]:
		var a: float = span[0] + 0.04
		var b: float = span[1] - 0.04
		if b - a < 0.05:
			continue
		var mid := (a + b) / 2.0
		var length := b - a
		k.box("clear", Vector3(mid, 1.25, z), Vector3(length, 2.5, 0.04), GLASS, "fp")
		k.box("clear", Vector3(mid, 0.525, z), Vector3(length, 1.05, 0.04), GLASS, "tp")
		k.box("metal", Vector3(mid, 1.07, z), Vector3(length, 0.04, 0.1), FRAME, "tp")
		k.box("metal", Vector3(mid, 0.05, z), Vector3(length, 0.1, 0.1), FRAME)
		k.solid(Vector3(mid, 1.3, z), Vector3(length, 2.6, 0.16))
		var count := int(length / 1.3)
		for index in range(1, count + 1):
			var x := a + index * length / (count + 1)
			k.box("metal", Vector3(x, 1.25, z), Vector3(0.04, 2.5, 0.07), FRAME, "fp")
			k.box("metal", Vector3(x, 0.525, z), Vector3(0.04, 1.05, 0.07), FRAME, "tp")
	for x in [x0, d0, d1, x1]:
		k.box("metal", Vector3(x, 1.25, z), Vector3(0.08, 2.5, 0.1), FRAME, "fp")
		k.box("metal", Vector3(x, 0.525, z), Vector3(0.08, 1.05, 0.1), FRAME, "tp")
	k.box("facade", Vector3((x0 + x1) / 2.0, (2.5 + HEIGHT) / 2.0, z), Vector3(x1 - x0, HEIGHT - 2.5, 0.16), WALL, "fp")
	k.box("facade", Vector3((x0 + x1) / 2.0, 2.53, z + 0.085), Vector3(x1 - x0, 0.06, 0.01), NAVY, "fp")
	k.box("metal", Vector3(door_x, 2.47, z), Vector3(door_w + 0.1, 0.06, 0.16), FRAME, "fp")
	var doors: Node3D = hospital.add_doors(name, at.call(Vector3(door_x, 0, z)), 0.0, door_w, 2.4, true, FRAME)
	doors.auto_target = hospital.player_target()
	doors.auto_group = "door_openers"
	doors.auto_depth = 1.7
	doors.speed = 2.6
	doors.locked = locked
	# In the overhead cutaway the doorway reads as open; the doors still block when shut.
	hospital.add_fp_node(doors)
	return doors

## Headwall with gas outlets and the bedside monitor (a vitals atlas tile).
static func _headwall(hospital: Node3D, k, at: Callable, x: float, tile: int, wide := false) -> void:
	var width := 1.9 if wide else 1.5
	k.box("facade", Vector3(x, 1.45, Z0 + 0.18), Vector3(width, 0.9, 0.05), Color("d6dde1"))
	for index in range(4):
		k.box("facade", Vector3(x - width / 2.0 + 0.2 + index * 0.16, 1.2, Z0 + 0.21), Vector3(0.1, 0.1, 0.02), [Color("2e7d4f"), Color("f2f2f0"), Color("f2c230"), Color("5aa9d6")][index])
	k.box("metal", Vector3(x + 0.35, 1.72, Z0 + 0.22), Vector3(0.66, 0.44, 0.04), Color("20252a"))
	hospital.add_screen(hospital.vitals_texture(), at.call(Vector3(x + 0.35, 1.72, Z0 + 0.24)), 0.0, Vector2(0.62, 0.39), VitalsAtlas.tile_rect(tile))

## A bay's stretcher, blanket and (optional) patient, recorded for ed_life.
static func _bay(hospital: Node3D, k, at: Callable, layout: Dictionary, bay: Dictionary, occupied: bool, look: Variant) -> void:
	var center: Vector3 = bay.center
	var hip_local: Vector3 = Props.stretcher(k, center, 0.0, Color("c9ced2"), Color("35557a"), 0.74, 0.5, false)
	var hip: Vector3 = at.call(center + hip_local)
	var patient: Node3D = hospital.add_figure(look, hip, PI, "bed", Props.ARMCHAIR_SEAT, 0.5)
	var blanket: MeshInstance3D = hospital.add_box_node("Blanket", at.call(center + Vector3(0, hip_local.y + 0.01, 0.39)), Vector3(0.64, 0.2, 1.18), Color("d9e2e7"))
	patient.visible = occupied
	blanket.visible = occupied
	bay["patient"] = patient
	bay["blanket"] = blanket
	bay["occupied"] = occupied
	bay["center"] = at.call(center)
	bay["door"] = at.call(bay.door)
	bay["inside"] = at.call(bay.inside)
	bay["park"] = at.call(bay.park)
	layout.bays.append(bay)

static func patient_look(seed: int, gown := true) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var look: Dictionary = Looks.random(rng)
	look.outfit.outerwear = ""
	look.outfit.head = ""
	look.outfit.back = ""
	look.outfit.neck = ""
	if gown:
		look.outfit.top = "ceil_scrub_top" if seed % 3 == 0 else "grey_henley"
	return look

## Staff with a base outfit and a varied face, skin and hair.
static func staff_look(preset: String, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var varied: Dictionary = Looks.random(rng)
	var look: Dictionary = preload("res://data/character_presets.gd").look_of(preset)
	for key in ["skin", "hair_style", "hair_color", "eye_style", "eye_color", "brows", "build", "height"]:
		look[key] = varied[key]
	look.preset = preset
	return look

# --- Trauma & Resuscitation (ESI 1) ------------------------------------------------------

static func _trauma(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	for x in [-24.0, -19.0, -14.0]:
		k.wall(true, x, Z0, ROOM_FRONT, HEIGHT, WALL, true)
	layout.doors["T1"] = _glass_front(hospital, k, at, "TraumaDoors1", ROOM_FRONT, X0, -24.0, -27.9, 2.4)
	layout.doors["T3"] = _glass_front(hospital, k, at, "TraumaDoors3", ROOM_FRONT, -24.0, -19.0, -21.5, 1.6)
	layout.doors["T4"] = _glass_front(hospital, k, at, "TraumaDoors4", ROOM_FRONT, -19.0, -14.0, -16.5, 1.6)
	var bays := [
		{"id": "T1", "label": "TRAUMA 1", "bed": "Trauma 1", "kind": "trauma", "tile": 0, "center": Vector3(-31.5, 0, -15.6), "door": Vector3(-27.9, 0, -9.6), "inside": Vector3(-27.9, 0, -13.0), "park": Vector3(-30.3, 0, -15.0), "side": -1.0},
		{"id": "T2", "label": "TRAUMA 2", "bed": "Trauma 2", "kind": "trauma", "tile": 1, "center": Vector3(-26.5, 0, -15.6), "door": Vector3(-27.9, 0, -9.6), "inside": Vector3(-27.9, 0, -13.0), "park": Vector3(-27.7, 0, -14.8), "side": 1.0},
		{"id": "T3", "label": "TRAUMA 3", "bed": "Trauma 3", "kind": "trauma", "tile": 2, "center": Vector3(-22.2, 0, -15.6), "door": Vector3(-21.5, 0, -9.6), "inside": Vector3(-21.5, 0, -13.0), "park": Vector3(-20.9, 0, -15.0), "side": -1.0},
		{"id": "T4", "label": "TRAUMA 4", "bed": "Trauma 4", "kind": "trauma", "tile": 3, "center": Vector3(-17.2, 0, -15.6), "door": Vector3(-16.5, 0, -9.6), "inside": Vector3(-16.5, 0, -13.0), "park": Vector3(-15.9, 0, -15.0), "side": -1.0},
	]
	for index in range(bays.size()):
		var bay: Dictionary = bays[index]
		var center: Vector3 = bay.center
		_headwall(hospital, k, at, center.x, bay.tile, true)
		Props.surgical_light(k, center + Vector3(-0.6, 0, 0.2), HEIGHT)
		Props.boom(k, center + Vector3(-1.05, 0, -1.2), HEIGHT)
		_bay(hospital, k, at, layout, bay, index in [0, 2], patient_look(900 + index))
	# Trauma 1 & 2 is one large room: supply wall, crash cart, portable X-ray, ultrasound.
	Props.shelving(k, Vector3(-29.0, 0, Z0 + 0.32), 0.0, 2.2, 5)
	Props.crash_cart(k, Vector3(X0 + 0.5, 0, -13.2), PI / 2)
	Props.ultrasound(k, Vector3(-24.8, 0, -13.2), -PI / 2)
	k.box("facade", Vector3(-33.2, 0.5, -11.9), Vector3(0.7, 1.0, 0.8), Color("e3e8ea"), "always", true)
	k.box("metal", Vector3(-33.2, 1.45, -11.9), Vector3(0.12, 0.9, 0.12), Props.METAL)
	k.box("facade", Vector3(-33.2, 1.95, -12.25), Vector3(0.36, 0.26, 0.4), Color("e3e8ea"))
	Props.crash_cart(k, Vector3(-14.55, 0, -12.2), -PI / 2)
	Props.iv_pole(k, Vector3(-23.3, 0, -16.6))
	# The trauma team working on the patient in Trauma 1; a nurse with the patient in Trauma 3.
	var team := [
		["ed_doctor", Vector3(-31.5, 0, -17.35), PI, 11], ["ed_nurse", Vector3(-30.55, 0, -15.1), PI / 2, 12],
		["ed_nurse", Vector3(-32.45, 0, -15.9), -PI / 2, 13], ["resident", Vector3(-31.2, 0, -13.7), PI + 0.3, 14],
		["ed_nurse", Vector3(-21.1, 0, -15.0), PI / 2, 15],
	]
	for member in team:
		hospital.add_figure(staff_look(member[0], member[3]), at.call(member[1]), member[2], "stand")
	hospital.add_endpoint("TraumaBay", "Look into Trauma 1", "A Level I trauma activation: the trauma team leader at the head of the bed, nurses either side. Resuscitation bays have overhead lights, gases on booms, a crash cart and portable X-ray, because ESI Level 1 patients need life-saving care immediately.", at.call(Vector3(-29.0, 1.0, -10.2)), 1.8)
	# Trauma station, facing the bays, with the EMS/trauma board on the far wall.
	k.box("walnut", Vector3(-30.25, 0.53, -5.9), Vector3(6.5, 1.06, 0.08), Color.WHITE)
	k.box("facade", Vector3(-30.25, 1.08, -5.6), Vector3(6.6, 0.05, 0.62), Color("f7f7f4"))
	k.box("facade", Vector3(-30.25, 0.76, -4.9), Vector3(6.4, 0.04, 0.8), Color("e4e1da"))
	k.box("facade", Vector3(-30.25, 0.38, -4.55), Vector3(6.4, 0.76, 0.06), Color("d9d4ca"))
	k.solid(Vector3(-30.25, 0.55, -5.2), Vector3(6.6, 1.1, 1.5))
	for x in [-32.5, -30.2, -27.9]:
		Props.monitor(k, Vector3(x, 0.78, -5.1), 0.0, 0.5, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, -3.9), PI)
	hospital.add_figure(staff_look("ed_nurse", 21), at.call(Vector3(-32.5, 0, -3.9)), 0.0, "seated", Props.OFFICE_SEAT)
	hospital.add_figure(staff_look("ed_doctor", 22), at.call(Vector3(-27.9, 0, -3.9)), 0.0, "seated", Props.OFFICE_SEAT)
	# On the trauma area's west wall, clear of the medication room's wall at z = -2.
	k.box("facade", Vector3(X0 + 0.19, 1.9, -3.7), Vector3(0.06, 1.46, 2.56), Color("16202a"))
	hospital.add_screen(hospital.board_texture("trauma"), at.call(Vector3(X0 + 0.22, 1.9, -3.7)), PI / 2, Vector2(2.4, 1.35))
	hospital.add_endpoint("TraumaBoard", "Read the trauma board", "The trauma board shows EMS units on their way in: who they are bringing, the mechanism, the triage level and the ETA, so the team and the bay are ready before the ambulance arrives.", at.call(Vector3(X0 + 1.4, 1.0, -3.7)), 2.0)

# --- Acute Care (ESI 2–3) ------------------------------------------------------------------

static func _acute_rooms(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	var vacant := [4, 8]
	for index in range(12):
		var x0 := -14.0 + index * 4.0
		var x1 := x0 + 4.0
		if index > 0:
			k.wall(true, x0, Z0, ROOM_FRONT, HEIGHT, WALL, true)
		# Room 12 is at the corridor's end: its door sits away from the corner so a
		# stretcher can turn out of it.
		var door_x := x0 + (1.9 if index == 11 else 2.75)
		layout.doors["room_%d" % (index + 1)] = _glass_front(hospital, k, at, "RoomDoors%d" % (index + 1), ROOM_FRONT, x0, x1, door_x, 1.4, index == 10)
		var center := Vector3(x0 + 1.7, 0, -16.2)
		_headwall(hospital, k, at, center.x, 4 + index)
		var number := index + 1
		var bay := {"id": str(number), "label": "ROOM %d" % number, "bed": "Room %d" % number, "kind": "acute", "tile": 4 + index, "center": center,
			"door": Vector3(door_x, 0, -9.6), "inside": Vector3(door_x, 0, -13.0), "park": Vector3(x0 + (2.6 if index == 11 else 2.95), 0, -15.2), "side": 1.0}
		_bay(hospital, k, at, layout, bay, not (index in vacant), patient_look(700 + index))
		# Room fittings: visitor chair, IV pole, computer on wheels, curtain.
		Props.office_chair(k, Vector3(x0 + 3.3, 0, -17.2), -1.99, Color("5b6c74"))
		if not (index in vacant):
			Props.iv_pole(k, Vector3(x0 + 0.75, 0, -17.2))
		if index % 3 == 1:
			Props.wow(k, Vector3(x0 + 0.55, 0, -13.2), PI / 2)
		k.box("facade", Vector3(x0 + (3.15 if index == 11 else 0.9), 1.35, -11.7), Vector3(1.4, 2.3, 0.05), Color("9fb2b8"), "fp")
		k.box("metal", Vector3(x0 + 2.0, HEIGHT - 0.12, -11.7), Vector3(3.8, 0.03, 0.03), FRAME, "fp")
		hospital.add_sign(str(number), at.call(Vector3(door_x, 2.85, ROOM_FRONT + 0.08)), 0.0, 30, 0.0075, "fp")
		hospital.add_floor_label(str(number), at.call(Vector3(door_x, 0.012, -10.35)))
		hospital.add_dispenser("ed_room_%d" % number, at.call(Vector3(x0 + 0.45, 1.0, ROOM_FRONT + 0.36)))
		Props.dispenser(k, Vector3(x0 + 0.45, 1.0, ROOM_FRONT + 0.08), 0.0)
		if index in [0, 5, 9]:
			# A family member at the bedside.
			hospital.add_figure(patient_look(750 + index, false), at.call(Vector3(x0 + 3.3, 0, -17.2)), 1.15, "seated", Props.OFFICE_SEAT)
	# Room 11: being cleaned between patients (door closed, housekeeping cart outside).
	k.box("facade", Vector3(27.2, 0.6, -10.1), Vector3(0.6, 1.2, 1.0), Color("3f6f96"), "always", true)
	k.box("facade", Vector3(27.2, 1.25, -10.1), Vector3(0.56, 0.1, 0.96), Color("f2c230"))
	hospital.add_figure(staff_look("evs", 31), at.call(Vector3(27.0, 0, -13.8)), 0.4, "stand")

# --- Central nurses station ------------------------------------------------------------------

static func _station(hospital: Node3D, k, at: Callable) -> void:
	var x0 := -6.0
	var x1 := 10.0
	var mid := (x0 + x1) / 2.0
	var length := x1 - x0
	# North counter: walnut front toward the rooms, white transaction top, desk behind.
	k.box("walnut", Vector3(mid, 0.53, -5.9), Vector3(length, 1.06, 0.08), Color.WHITE)
	k.box("facade", Vector3(mid, 1.08, -5.62), Vector3(length + 0.1, 0.05, 0.62), Color("f7f7f4"))
	k.box("facade", Vector3(mid, 0.76, -4.9), Vector3(length - 0.2, 0.04, 0.8), Color("e4e1da"))
	k.box("facade", Vector3(mid, 0.38, -4.55), Vector3(length - 0.2, 0.76, 0.06), Color("d9d4ca"))
	k.solid(Vector3(mid, 0.55, -5.2), Vector3(length + 0.1, 1.1, 1.5))
	# Ends and the back cabinet (with a gap for staff) facing the physician desks.
	for x in [x0, x1]:
		k.box("walnut", Vector3(x, 0.53, -3.7), Vector3(0.08, 1.06, 4.4), Color.WHITE)
		k.solid(Vector3(x, 0.55, -3.7), Vector3(0.2, 1.1, 4.4))
	for span in [[x0, 1.2], [2.6, x1]]:
		var a: float = span[0]
		var b: float = span[1]
		k.box("walnut", Vector3((a + b) / 2.0, 0.5, -1.55), Vector3(b - a, 1.0, 0.08), Color.WHITE)
		k.box("facade", Vector3((a + b) / 2.0, 1.03, -1.75), Vector3(b - a, 0.05, 0.5), Color("f7f7f4"))
		k.solid(Vector3((a + b) / 2.0, 0.52, -1.75), Vector3(b - a, 1.05, 0.5))
	for x in [-4.4, -1.6, 4.4, 7.4]:
		Props.monitor(k, Vector3(x, 0.78, -5.1), 0.0, 0.5, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, -3.9), PI)
	for member in [["ed_nurse", -4.4, 41], ["ed_nurse", -1.6, 42], ["ed_doctor", 7.4, 43]]:
		hospital.add_figure(staff_look(member[0], member[2]), at.call(Vector3(member[1], 0, -3.9)), 0.0, "seated", Props.OFFICE_SEAT)
	hospital.add_figure(staff_look("ed_nurse", 44), at.call(Vector3(4.4, 0, -3.3)), -0.5, "stand")
	# Tracking boards: on the back cabinet for the physicians, and hung above (first person).
	for x in [-1.8, 5.4]:
		k.box("metal", Vector3(x, 1.28, -1.75), Vector3(0.08, 0.5, 0.08), Color("2a2f33"))
		k.box("metal", Vector3(x, 1.66, -1.72), Vector3(1.02, 0.6, 0.05), Color("20252a"))
		hospital.add_screen(hospital.board_texture("tracking"), at.call(Vector3(x, 1.66, -1.69)), 0.0, Vector2(0.96, 0.54))
	for face in [[0.0, -1.2], [PI, -6.1]]:
		k.box("metal", Vector3(2.0, 2.45, face[1]), Vector3(2.3, 1.32, 0.06), Color("20252a"), "fp")
		hospital.add_screen(hospital.board_texture("tracking"), at.call(Vector3(2.0, 2.45, face[1] + (0.035 if face[0] == 0.0 else -0.035))), face[0], Vector2(2.2, 1.24), Rect2(0, 0, 1, 1), "fp")
	for z in [-1.2, -6.1]:
		for x in [1.2, 2.8]:
			k.box("metal", Vector3(x, (3.1 + HEIGHT) / 2.0, z), Vector3(0.03, HEIGHT - 3.1, 0.03), FRAME, "fp")
	hospital.add_endpoint("TrackingBoard", "Read the tracking board", "The tracking board lists every patient in the department: bed, ESI triage level (1 most critical to 5 least), complaint, nurse, physician, status and time in the department. Initials only: the board is visible to passers-by.", at.call(Vector3(2.0, 1.0, -0.6)), 1.8)

# --- Medication, supply and decontamination ---------------------------------------------------

static func _support_rooms(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	k.wall(true, -26.0, -2.0, 14.0, HEIGHT, WALL, true, [[1.0, 1.2, 2.3], [7.0, 1.2, 2.3], [12.4, 1.4, 2.3]])
	for z in [-2.0, 4.0, 10.0]:
		k.wall(false, z, X0, -26.0, HEIGHT, WALL, true)
	# Medication room: automated dispensing cabinets, fridge, counter with sink.
	for z in [-0.9, 0.2, 1.3]:
		Props.dispensing_cabinet(k, Vector3(X0 + 0.5, 0, z), PI / 2)
	Props.med_fridge(k, Vector3(X0 + 0.5, 0, 2.9), PI / 2)
	k.box("facade", Vector3(-29.5, 0.45, -1.6), Vector3(4.0, 0.9, 0.62), Color("dfe3e6"), "always", true)
	k.box("facade", Vector3(-29.5, 0.92, -1.6), Vector3(4.1, 0.04, 0.66), Color("f7f7f4"))
	k.box("metal", Vector3(-28.4, 0.9, -1.55), Vector3(0.5, 0.04, 0.4), Props.METAL)
	k.box("facade", Vector3(-30.8, 1.0, -1.7), Vector3(0.24, 0.3, 0.2), Color("d33a33"))
	hospital.add_figure(staff_look("ed_nurse", 51), at.call(Vector3(-32.6, 0, 0.2)), PI / 2, "stand")
	hospital.add_sign("Medication Room\nStaff only · badge access", at.call(Vector3(-25.92, 1.6, 2.2)), PI / 2, 20, 0.005, "fp")
	# A solid automatic door with a badge reader (a student badge opens it too).
	var med_doors: Node3D = hospital.add_doors("MedRoomDoors", at.call(Vector3(-26.0, 0, 1.0)), PI / 2, 1.2, 2.3, false, FRAME)
	med_doors.auto_target = hospital.player_target()
	med_doors.auto_group = "door_openers"
	med_doors.auto_depth = 1.4
	med_doors.speed = 2.6
	hospital.add_fp_node(med_doors)
	layout.doors["med_room"] = med_doors
	k.box("metal", Vector3(-25.905, 1.2, 1.78), Vector3(0.03, 0.14, 0.09), Color("2b2f33"))
	k.box("light", Vector3(-25.885, 1.24, 1.78), Vector3(0.01, 0.02, 0.05), Color("5fd18a"))
	hospital.add_floor_label("MEDS", at.call(Vector3(-24.8, 0.012, 1.0)))
	hospital.add_endpoint("MedRoom", "Look at the medication cabinets", "Automated dispensing cabinets: the nurse badges in, picks the patient and the ordered medication, and only that drawer opens. Every removal is logged, controlled substances are counted, and high-alert drugs need a second nurse to check.", at.call(Vector3(-29.8, 1.0, 1.0)), 2.0)
	# Clean supply.
	Props.shelving(k, Vector3(X0 + 0.34, 0, 7.0), PI / 2, 4.6, 5)
	Props.shelving(k, Vector3(-30.0, 0, 9.66), PI, 3.4, 5)
	hospital.add_sign("Clean Supply", at.call(Vector3(-25.92, 1.6, 8.3)), PI / 2, 20, 0.005, "fp")
	# Decontamination room: tiled, ceiling showers, a drainage table; doors to the garage.
	k.floor_rect(X0 + 0.1, 10.1, -26.1, Z1 - 0.1, Color("b9cfd6"), 0.006)
	k.box("metal", Vector3(-30.0, 0.45, 14.0), Vector3(0.9, 0.9, 2.2), Color("c9ced2"), "always", true)
	k.box("metal", Vector3(-30.0, 0.92, 14.0), Vector3(1.0, 0.04, 2.3), Color("dfe3e6"))
	for z in [12.0, 14.0, 16.0]:
		k.cylinder("metal", Vector3(-30.0, HEIGHT, z), Vector3(-30.0, 2.5, z), 0.03, Props.METAL, "fp")
		k.cylinder("metal", Vector3(-30.0, 2.5, z), Vector3(-30.0, 2.45, z), 0.16, Props.METAL, "fp")
	k.box("facade", Vector3(-32.8, 0.3, 11.0), Vector3(0.5, 0.6, 0.5), Color("f2c230"), "always", true)
	k.box("metal", Vector3(-30.0, 1.15, Z1 - 0.12), Vector3(1.5, 2.3, 0.06), Color("c3c9cd"), "fp")
	k.box("metal", Vector3(-30.0, 0.525, Z1 - 0.12), Vector3(1.5, 1.05, 0.06), Color("c3c9cd"), "tp")
	k.solid(Vector3(-30.0, 1.15, Z1), Vector3(1.6, 2.3, 0.3))
	k.box("metal", Vector3(-26.0, 1.15, 12.4), Vector3(0.06, 2.3, 1.3), Color("c3c9cd"), "fp")
	k.box("metal", Vector3(-26.0, 0.525, 12.4), Vector3(0.06, 1.05, 1.3), Color("c3c9cd"), "tp")
	k.solid(Vector3(-26.0, 1.15, 12.4), Vector3(0.2, 2.3, 1.4))
	hospital.add_sign("DECONTAMINATION", at.call(Vector3(-25.92, 2.0, 12.4)), PI / 2, 22, 0.006, "fp", Color("f2c230"), Color("1d1d1d"))
	hospital.add_floor_label("DECON", at.call(Vector3(-30.0, 0.012, 11.2)))

# --- EMS entrance ------------------------------------------------------------------------------

static func _ems_entrance(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	k.wall(false, 14.0, -26.0, -18.0, HEIGHT, WALL, true, [[-22.0, 2.6, 2.6]])
	k.wall(true, -26.0, 14.0, Z1, HEIGHT, WALL, true)
	k.wall(true, -18.0, 14.0, Z1, HEIGHT, WALL, true)
	var outer: Node3D = hospital.add_doors("AmbulanceOuterDoors", at.call(Vector3(-22.0, 0, Z1)), 0.0, 2.6, 2.5, true)
	var inner: Node3D = hospital.add_doors("AmbulanceInnerDoors", at.call(Vector3(-22.0, 0, 14.0)), 0.0, 2.6, 2.5, true)
	for doors in [outer, inner]:
		doors.auto_target = hospital.player_target()
		doors.auto_group = "door_openers"
		doors.auto_radius = 3.0
	layout.doors["ambulance_outer"] = outer
	layout.doors["ambulance_inner"] = inner
	hospital.add_sign("AMBULANCE ENTRANCE · EMS ONLY", at.call(Vector3(-22.0, 2.95, Z1 + 0.16)), 0.0, 22, 0.006, "fp", RED, Color.WHITE)
	hospital.add_sign("EMS · Trauma & Resuscitation ↑", at.call(Vector3(-22.0, 2.9, 13.92)), PI, 22, 0.006, "fp")
	hospital.add_floor_label("EMS", at.call(Vector3(-22.0, 0.012, 9.0)), 0.006)
	# EMS check-in with the charge nurse.
	k.box("walnut", Vector3(-16.8, 0.53, 2.0), Vector3(0.08, 1.06, 2.2), Color.WHITE)
	k.box("facade", Vector3(-16.55, 1.08, 2.0), Vector3(0.62, 0.05, 2.3), Color("f7f7f4"))
	k.solid(Vector3(-16.4, 0.55, 2.0), Vector3(0.9, 1.1, 2.3))
	Props.monitor(k, Vector3(-16.2, 1.1, 2.4), PI / 2, 0.4)
	hospital.add_figure(staff_look("ed_nurse", 61), at.call(Vector3(-15.6, 0, 1.6)), PI / 2, "stand")
	hospital.add_sign("EMS check-in", at.call(Vector3(-16.86, 0.7, 2.0)), -PI / 2, 20, 0.005, "always")
	# Spare stretchers, wheelchairs and a portable X-ray parked along the wall.
	Props.stretcher(k, Vector3(-25.3, 0, 4.4), PI, Color("c9ced2"), Color("35557a"), 0.74, 0.3)
	for z in [9.3, 10.1]:
		Props.wheelchair(k, Vector3(-25.45, 0, z), PI / 2)
	k.box("facade", Vector3(-19.2, 0.5, 7.4), Vector3(0.7, 1.0, 0.9), Color("e3e8ea"), "always", true)
	k.box("metal", Vector3(-19.2, 1.45, 7.4), Vector3(0.12, 0.9, 0.12), Props.METAL)
	k.box("facade", Vector3(-19.2, 1.95, 7.05), Vector3(0.36, 0.26, 0.4), Color("e3e8ea"))
	hospital.add_floor_label("PORTABLE X-RAY", at.call(Vector3(-19.2, 0.012, 8.4)), 0.003)

# --- Elevators to Emergency Radiology ------------------------------------------------------------

static func _elevators(hospital: Node3D, k, at: Callable) -> void:
	k.wall(false, 14.0, -18.0, -9.0, HEIGHT, WALL, true, [[-15.5, 1.3, 2.36], [ELEVATOR_X, 1.3, 2.36]])
	k.wall(true, -9.0, 7.0, Z1, HEIGHT, WALL, true)
	for x in [-15.5, ELEVATOR_X]:
		Props.elevator_frame(k, Vector3(x, 0, 13.92), PI, 1.3, x != ELEVATOR_X)
		hospital.add_indicator(at.call(Vector3(x, 2.72, 13.84)), "1", PI)
	var doors: Node3D = hospital.add_doors("EDElevatorDoors", at.call(Vector3(ELEVATOR_X, 0, 13.9)), PI, 1.3, 2.36, false)
	hospital.ed_elevator = doors
	Props.elevator_cab(k, Vector3(ELEVATOR_X, 0, 14.0), PI, true)
	hospital.add_elevator_call("EDElevator", at.call(Vector3(ELEVATOR_X - 0.97, 1.15, 13.6)), "imaging")
	hospital.add_sign("Emergency Radiology · Level 2\nCT · MRI · X-ray · Ultrasound", at.call(Vector3(-13.5, 2.9, 13.92)), PI, 20, 0.0055, "fp")
	hospital.add_floor_label("ELEVATORS · RADIOLOGY L2", at.call(Vector3(-13.5, 0.012, 11.0)), 0.0048)

# --- Results waiting and physician workstations -------------------------------------------------

static func _results_and_physicians(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	# Physicians' workstation bank facing the station.
	k.box("facade", Vector3(0, 0.74, 3.4), Vector3(12.4, 0.05, 0.8), Color("f7f7f4"))
	k.box("facade", Vector3(0, 0.37, 3.05), Vector3(12.2, 0.74, 0.06), Color("d9d4ca"))
	k.solid(Vector3(0, 0.4, 3.4), Vector3(12.4, 0.8, 0.8))
	for x in [-5.0, -2.5, 0.0, 2.5, 5.0]:
		Props.monitor(k, Vector3(x, 0.765, 3.25), 0.0, 0.5, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, 4.45), PI)
	for member in [[-5.0, "ed_doctor", 71], [0.0, "resident", 72], [5.0, "ed_doctor", 73]]:
		hospital.add_figure(staff_look(member[1], member[2]), at.call(Vector3(member[0], 0, 4.45)), 0.0, "seated", Props.OFFICE_SEAT)
	hospital.add_floor_label("PHYSICIANS", at.call(Vector3(0, 0.012, 5.6)), 0.0042)
	# Results waiting: patients waiting for tests or results, sitting up in gowns.
	var seats: Array = []
	for row in [[Vector3(-3.0, 0, 9.2), 7], [Vector3(-3.0, 0, 12.4), 7], [Vector3(6.0, 0, 9.2), 5]]:
		seats.append_array(Props.seat_row(k, row[0], PI, row[1], Color("5b6c74")))
	for index in range(seats.size()):
		var seat: Vector3 = seats[index]
		layout.results_seats.append([at.call(seat), 0.0])
		if index % 3 == 0:
			hospital.add_figure(patient_look(800 + index), at.call(seat), 0.0, "seated", 0.36)
	k.box("metal", Vector3(-8.84, 1.9, 12.0), Vector3(0.05, 0.76, 1.3), Color("20252a"), "fp")
	hospital.add_screen(hospital.board_texture("waiting"), at.call(Vector3(-8.82, 1.9, 12.0)), PI / 2, Vector2(1.24, 0.7), Rect2(0, 0, 1, 1), "fp")
	hospital.add_floor_label("RESULTS WAITING", at.call(Vector3(1.5, 0.012, 15.8)), 0.0048)

# --- Super Track (ESI 4–5) ---------------------------------------------------------------------

static func _super_track(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	k.wall(false, 4.0, 12.0, X1, HEIGHT, WALL, true, [[31.5, 2.4, 2.4]])
	k.wall(true, 12.0, 4.0, Z1, HEIGHT, WALL, true)
	var doors: Node3D = hospital.add_doors("SuperTrackDoors", at.call(Vector3(31.5, 0, 4.0)), 0.0, 2.4, 2.4, true)
	doors.auto_target = hospital.player_target()
	doors.auto_group = "door_openers"
	doors.auto_radius = 2.6
	layout.doors["super_track"] = doors
	hospital.add_sign("Treatment area · staff and escorted patients", at.call(Vector3(27.6, 2.9, 4.08)), 0.0, 20, 0.005, "fp")
	hospital.add_sign("Exit · Waiting room ↓", at.call(Vector3(31.5, 2.75, 3.92)), PI, 20, 0.005, "fp")
	# Recliner bays with low screens between them and curtain tracks above.
	var xs := [15.5, 18.5, 21.5, 24.5, 27.5]
	for index in range(xs.size()):
		var x: float = xs[index]
		Props.recliner(k, Vector3(x, 0, -5.0), 0.0)
		layout.recliners.append({"pos": at.call(Vector3(x, 0, -5.0)), "yaw": PI, "front": at.call(Vector3(x, 0, -4.25)), "occupant": null})
		if index < xs.size() - 1:
			k.box("facade", Vector3(x + 1.5, 0.65, -5.3), Vector3(0.06, 1.3, 2.6), Color("b8c7cc"), "always", true)
		k.box("metal", Vector3(x, HEIGHT - 0.12, -3.9), Vector3(2.9, 0.03, 0.03), FRAME, "fp")
		hospital.add_floor_label("ST %d" % (index + 1), at.call(Vector3(x, 0.012, -3.2)))
	Props.vitals_stand(k, Vector3(29.4, 0, -4.4), -PI / 2)
	# Super Track desk: a nurse practitioner and a nurse.
	k.box("facade", Vector3(23.0, 0.74, 0.8), Vector3(5.0, 0.05, 0.8), Color("f7f7f4"))
	k.box("walnut", Vector3(23.0, 0.37, 0.42), Vector3(5.0, 0.74, 0.06), Color.WHITE)
	k.solid(Vector3(23.0, 0.4, 0.8), Vector3(5.0, 0.8, 0.8))
	for x in [21.5, 24.5]:
		Props.monitor(k, Vector3(x, 0.765, 0.95), PI, 0.5, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, -0.3), 0.0)
	hospital.add_figure(staff_look("ed_doctor", 81), at.call(Vector3(21.5, 0, -0.3)), PI, "seated", Props.OFFICE_SEAT)
	hospital.add_figure(staff_look("ed_nurse", 82), at.call(Vector3(24.5, 0, -0.3)), PI, "seated", Props.OFFICE_SEAT)
	hospital.add_floor_label("SUPER TRACK · ESI 4–5", at.call(Vector3(23.0, 0.012, -2.4)), 0.006)
	hospital.add_endpoint("SuperTrack", "Ask about Super Track", "Super Track is the fast lane for stable, low-complexity problems (ESI 4–5): sprains, small cuts, earaches, prescriptions. They're treated in chairs rather than beds, so they don't wait behind the sickest patients and the rooms stay free for them.", at.call(Vector3(23.0, 1.0, 1.8)), 1.8)

# --- Walk-in entrance: security, registration, triage, waiting -----------------------------------

static func _front_of_house(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	# Vestibule with two sets of automatic doors.
	k.wall(true, 28.3, 15.8, Z1, HEIGHT, WALL, true)
	k.wall(true, 31.7, 15.8, Z1, HEIGHT, WALL, true)
	k.wall(false, 15.8, 28.3, 31.7, HEIGHT, WALL, true, [[30.0, 3.0, 2.6]])
	var outer: Node3D = hospital.add_doors("WalkInOuterDoors", at.call(Vector3(30.0, 0, Z1)), 0.0, 3.0, 2.6, true)
	var inner: Node3D = hospital.add_doors("WalkInInnerDoors", at.call(Vector3(30.0, 0, 15.8)), 0.0, 3.0, 2.6, true)
	for doors in [outer, inner]:
		doors.auto_target = hospital.player_target()
		doors.auto_group = "door_openers"
		doors.auto_radius = 2.6
	layout.doors["walkin_outer"] = outer
	layout.doors["walkin_inner"] = inner
	# Security screening: walk-through detector, bag table, desk, officers.
	Props.metal_detector(k, Vector3(30.0, 0, 13.4), 0.0)
	k.box("metal", Vector3(28.3, 0.45, 13.6), Vector3(0.7, 0.9, 1.4), Color("c3c9cd"), "always", true)
	k.box("facade", Vector3(32.8, 0.55, 13.5), Vector3(0.8, 1.1, 2.0), Color("f7f7f4"), "always", true)
	k.box("walnut", Vector3(32.38, 0.5, 13.5), Vector3(0.04, 0.9, 1.9), Color.WHITE)
	Props.monitor(k, Vector3(32.9, 1.1, 13.2), PI / 2, 0.4)
	hospital.add_figure("security", at.call(Vector3(33.45, 0, 13.9)), PI / 2, "stand")
	hospital.add_figure(staff_look("security", 91), at.call(Vector3(27.35, 0, 13.9)), -PI / 2, "stand")
	hospital.add_sign("All visitors are screened\nWeapons are not permitted", at.call(Vector3(32.36, 0.8, 13.5)), -PI / 2, 20, 0.005, "always")
	hospital.add_endpoint("EDSecurity", "Talk to security", "\"Morning. Everyone walks through the detector here, patients and visitors alike. Student badge? Go ahead; triage is on your left, the treatment area through the doors.\"", at.call(Vector3(32.0, 1.0, 12.4)), 1.8)
	# Registration.
	k.box("walnut", Vector3(26.9, 0.53, 9.25), Vector3(4.8, 1.06, 0.08), Color.WHITE)
	k.box("facade", Vector3(26.9, 1.08, 8.98), Vector3(4.9, 0.05, 0.62), Color("f7f7f4"))
	k.box("facade", Vector3(26.9, 0.76, 8.3), Vector3(4.7, 0.04, 0.8), Color("e4e1da"))
	k.solid(Vector3(26.9, 0.55, 8.7), Vector3(4.9, 1.1, 1.3))
	for x in [25.6, 28.2]:
		Props.monitor(k, Vector3(x, 0.78, 8.5), PI, 0.46, Color("24424a"))
		Props.office_chair(k, Vector3(x, 0, 7.5), 0.0)
		hospital.add_figure(staff_look("registrar", int(x * 10)), at.call(Vector3(x, 0, 7.5)), PI, "seated", Props.OFFICE_SEAT)
	hospital.add_sign("Registration", at.call(Vector3(26.9, 0.72, 9.29)), 0.0, 22, 0.006, "always")
	# Triage bays: a nurse, a patient chair, vitals on a stand and a computer cart.
	for x in [16.5, 20.5]:
		k.box("facade", Vector3(x, 0.7, 5.5), Vector3(0.06, 1.4, 3.0), Color("b8c7cc"), "always", true)
	var bays := [14.5, 18.5, 22.5]
	for index in range(bays.size()):
		var x: float = bays[index]
		Props.office_chair(k, Vector3(x - 0.6, 0, 5.1), 0.0)
		Props.armchair(k, Vector3(x + 0.3, 0, 6.7), PI, Color("5b6c74"))
		Props.vitals_stand(k, Vector3(x + 1.25, 0, 4.9), PI)
		Props.wow(k, Vector3(x - 1.35, 0, 5.3), PI / 2)
		hospital.add_figure(staff_look("ed_nurse", 100 + index), at.call(Vector3(x - 0.6, 0, 5.1)), PI, "seated", Props.OFFICE_SEAT)
		layout.triage.append({"seat": at.call(Vector3(x + 0.3, 0, 6.7)), "front": at.call(Vector3(x + 0.3, 0, 7.8)), "occupant": null})
		if index < 2:
			hospital.add_figure(patient_look(600 + index, false), at.call(Vector3(x + 0.3, 0, 6.7)), 0.0, "seated")
		hospital.add_sign("Triage %d" % (index + 1), at.call(Vector3(x, 2.4, 4.08)), 0.0, 22, 0.006, "fp")
		hospital.add_floor_label("TRIAGE %d" % (index + 1), at.call(Vector3(x, 0.012, 7.9)))
	# Waiting room: rows of seats facing the triage bays.
	var seats: Array = []
	for row in [[Vector3(16.0, 0, 11.4), 6], [Vector3(21.2, 0, 11.4), 6], [Vector3(16.0, 0, 14.4), 6], [Vector3(21.2, 0, 14.4), 6]]:
		seats.append_array(Props.seat_row(k, row[0], PI, row[1]))
	for index in range(seats.size()):
		var seat: Vector3 = seats[index]
		var taken := index in [1, 4, 7, 9, 14, 16, 20, 22]
		var figure: Node3D = null
		if taken:
			figure = hospital.add_figure(patient_look(500 + index, false), at.call(seat), 0.0, "seated", 0.36)
		# "lane": the aisle in front of the row, clear of seated knees.
		layout.waiting_seats.append({"pos": at.call(seat), "yaw": 0.0, "front": at.call(seat + Vector3(0, 0, -0.62)), "lane": at.call(seat + Vector3(0, 0, -1.15)), "occupant": figure})
	for z in [12.6, 13.6]:
		Props.vending(k, Vector3(12.55, 0, z), PI / 2, z > 13.0)
	# Waiting-room display on a kiosk, and one on the wall (first person).
	k.box("metal", Vector3(26.0, 0.6, 12.4), Vector3(0.5, 1.2, 0.1), Color("2a2f33"), "always", true)
	k.box("metal", Vector3(26.0, 1.55, 12.4), Vector3(1.3, 0.76, 0.08), Color("20252a"))
	for face in [0.0, PI]:
		hospital.add_screen(hospital.board_texture("waiting"), at.call(Vector3(26.0, 1.55, 12.4) + Basis(Vector3.UP, face) * Vector3(0, 0, 0.041)), face, Vector2(1.24, 0.7))
	k.box("metal", Vector3(X1 - 0.19, 2.0, 10.5), Vector3(0.05, 0.76, 1.3), Color("20252a"), "fp")
	hospital.add_screen(hospital.board_texture("waiting"), at.call(Vector3(X1 - 0.22, 2.0, 10.5)), -PI / 2, Vector2(1.24, 0.7), Rect2(0, 0, 1, 1), "fp")
	hospital.add_endpoint("ESIBoard", "Read how triage works", "Emergency Severity Index (ESI), the five-level triage scale:\nLevel 1 · Resuscitation: needs immediate life-saving care.\nLevel 2 · Emergent: high risk or severe pain; seen right away.\nLevel 3 · Urgent: stable, needs two or more resources (labs, imaging, IV).\nLevel 4 · Less urgent: stable, needs one resource.\nLevel 5 · Non-urgent: stable, no resources.\nLevel 1 is the most critical.", at.call(Vector3(24.9, 1.0, 12.6)), 1.8)
	hospital.add_floor_label("WAITING", at.call(Vector3(18.6, 0.012, 17.2)), 0.006)

# --- Outside: ambulance garage and walk-in entrance ---------------------------------------------

static func _exterior(hospital: Node3D, k, at: Callable, layout: Dictionary) -> void:
	k.floor_rect(-60.0, Z1, 60.0, 38.0, Color("7a7e81"))
	k.floor_rect(-9.6, Z1, 40.0, 21.2, Color("b9b6ae"), 0.03)
	k.floor_rect(X0, Z1, -10.0, 31.8, Color("8a8d8f"), 0.012)
	# The garage: the building above on columns, red-painted walls, lane markings.
	for x in [X0, -28.0, -16.0, -10.0]:
		k.cylinder("facade", Vector3(x, 0, 31.6), Vector3(x, 4.6, 31.6), 0.32, Color("d8d0c0"), "fp", 14)
		k.cylinder("facade", Vector3(x, 0, 31.6), Vector3(x, 1.05, 31.6), 0.32, Color("d8d0c0"), "tp", 14)
		k.solid(Vector3(x, 1.5, 31.6), Vector3(0.6, 3.0, 0.6))
	k.ceiling(X0, Z1, -10.0, 31.8, 4.6, Color("d9dcde"))
	for x in [-31.0, -25.0, -19.0, -13.0]:
		k.ceiling_light(Vector3(x, 4.58, 24.5), Vector2(1.6, 0.4))
	k.box("facade", Vector3((X0 - 10.0) / 2.0, 5.4, 31.7), Vector3(24.4, 1.6, 0.5), Color("d8d0c0"), "fp")
	k.box("facade", Vector3((X0 - 10.0) / 2.0, 4.72, 31.96), Vector3(12.0, 0.46, 0.04), Color("20262b"), "fp")
	hospital.add_sign("+  AMBULANCE ONLY  +", at.call(Vector3(-22.0, 4.72, 31.98)), 0.0, 30, 0.012, "fp", Color("20262b"), Color.WHITE)
	# Red-painted wall either side of the EMS doors.
	for x in [-24.2, -19.8]:
		k.box("facade", Vector3(x, 1.3, Z1 + 0.18), Vector3(1.6, 2.6, 0.04), Color("a8322c"), "fp")
		k.box("facade", Vector3(x, 0.52, Z1 + 0.18), Vector3(1.6, 1.04, 0.04), Color("a8322c"), "tp")
	hospital.add_floor_label("AMBULANCE ONLY", at.call(Vector3(-22.0, 0.024, 28.6)), 0.009)
	for x in [-25.5, -18.5]:
		Props.bollard(k, Vector3(x, 0, 20.6))
	# Walk-in entrance canopy: the red EMERGENCY band and a red pylon sign.
	k.box("facade", Vector3(30.0, 3.35, 19.6), Vector3(7.2, 0.3, 3.4), Color("e8e6e0"), "fp")
	k.box("facade", Vector3(30.0, 3.1, 21.32), Vector3(7.2, 0.5, 0.06), RED, "fp")
	hospital.add_sign("+  EMERGENCY", at.call(Vector3(30.0, 3.1, 21.36)), 0.0, 34, 0.01, "fp", RED, Color.WHITE)
	for x in [26.7, 33.3]:
		k.cylinder("metal", Vector3(x, 0, 21.1), Vector3(x, 3.2, 21.1), 0.09, Color("d8dcde"), "fp")
		k.cylinder("metal", Vector3(x, 0, 21.1), Vector3(x, 1.05, 21.1), 0.09, Color("d8dcde"), "tp")
		k.solid(Vector3(x, 1.5, 21.1), Vector3(0.2, 3.0, 0.2))
	k.floor_rect(26.6, 19.2, 33.4, 20.4, RED, 0.04)
	hospital.add_floor_label("+  EMERGENCY", at.call(Vector3(30.0, 0.045, 19.8)), 0.007).modulate = Color.WHITE
	k.box("facade", Vector3(36.4, 0.3, 20.3), Vector3(2.4, 0.6, 1.4), Color("5b5752"), "always", true)
	k.box("facade", Vector3(36.4, 1.55, 20.3), Vector3(0.9, 2.5, 0.35), RED, "always", true)
	hospital.add_sign("EMERGENCY\n←  +", at.call(Vector3(36.4, 1.9, 20.48)), 0.0, 30, 0.008, "always", RED, Color.WHITE)
	hospital.add_shrubs(at.call(Vector3(36.4, 0.6, 20.3)), 2.4)
	# Globe lamps on the sidewalk.
	for x in [-6.0, 12.0, 24.0]:
		k.cylinder("metal", Vector3(x, 0, 20.8), Vector3(x, 3.6, 20.8), 0.07, Color("1f2326"))
		k.cylinder("light", Vector3(x, 3.6, 20.8), Vector3(x, 4.1, 20.8), 0.24, Color("fbf6e8"), "always", 12)
		k.solid(Vector3(x, 1.5, 20.8), Vector3(0.2, 3.0, 0.2))
	# Daylight beyond the street (first person).
	k.box("light", Vector3(0, 7.0, 44.0), Vector3(130.0, 14.0, 0.1), Color("cfe6f1"), "fp")
	k.box("light", Vector3(-62.0, 7.0, 28.0), Vector3(0.1, 14.0, 32.0), Color("cfe6f1"), "fp")
	# Keep the student to the garage and the entrance sidewalk.
	for bound in [[Vector3(15.0, 1.5, 21.6), Vector3(50.0, 3.0, 0.4)], [Vector3(40.0, 1.5, 19.8), Vector3(0.4, 3.0, 3.6)], [Vector3(-9.6, 1.5, 25.0), Vector3(0.4, 3.0, 13.6)], [Vector3(-22.0, 1.5, 31.9), Vector3(24.8, 3.0, 0.4)], [Vector3(X0 - 0.3, 1.5, 25.0), Vector3(0.4, 3.0, 14.0)]]:
		k.solid(bound[0], bound[1])
	layout["garage"] = {
		"spawn": at.call(Vector3(-64.0, 0, LANE_Z)), "stop": at.call(AMBULANCE_STOP), "exit": at.call(Vector3(64.0, 0, LANE_Z)),
		"parked": at.call(Vector3(-28.0, 0, 28.8)),
	}

# --- Overhead wayfinding (first person) and zone labels (overhead) --------------------------------

static func _hanging_sign(hospital: Node3D, k, at: Callable, text: String, center: Vector3, along_x := true) -> void:
	var yaw := 0.0 if along_x else PI / 2
	for face in [yaw, yaw + PI]:
		hospital.add_sign(text, at.call(center + Basis(Vector3.UP, face) * Vector3(0, 0, 0.03)), face, 22, 0.0062, "fp", Color("f7f7f4"), Color("24343c"))
	var span := Basis(Vector3.UP, yaw) * Vector3(0.9, 0, 0)
	for side in [-1, 1]:
		k.cylinder("metal", center + span * side + Vector3(0, 0.2, 0), center + span * side + Vector3(0, HEIGHT - center.y, 0), 0.012, FRAME, "fp")

static func _signage(hospital: Node3D, k, at: Callable) -> void:
	_hanging_sign(hospital, k, at, "TRAUMA & RESUSCITATION · ESI 1\nTrauma 1 – 4", Vector3(-24.0, 2.55, CORRIDOR_Z))
	_hanging_sign(hospital, k, at, "ACUTE CARE · ESI 2 – 3\nRooms 1 – 12", Vector3(8.0, 2.55, CORRIDOR_Z))
	_hanging_sign(hospital, k, at, "SUPER TRACK · ESI 4 – 5\nTriage · Waiting ↓", Vector3(26.0, 2.55, CORRIDOR_Z))
	_hanging_sign(hospital, k, at, "Ambulance Entrance ↓\nElevators · Radiology L2", Vector3(-22.0, 2.55, 0.0))
	hospital.add_floor_label("TRAUMA · ESI 1", at.call(Vector3(-24.0, 0.012, CORRIDOR_Z - 0.2)), 0.007)
	hospital.add_floor_label("ACUTE CARE · ESI 2–3", at.call(Vector3(8.0, 0.012, CORRIDOR_Z - 0.2)), 0.007)
	hospital.add_floor_label("TRAUMA 1 · 2", at.call(Vector3(-27.9, 0.012, -10.35)))
	hospital.add_floor_label("T3", at.call(Vector3(-21.5, 0.012, -10.35)))
	hospital.add_floor_label("T4", at.call(Vector3(-16.5, 0.012, -10.35)))
	for bay in [["TRAUMA 1 & 2", -27.9], ["TRAUMA 3", -21.5], ["TRAUMA 4", -16.5]]:
		hospital.add_sign(bay[0], at.call(Vector3(bay[1], 2.85, ROOM_FRONT + 0.08)), 0.0, 24, 0.0065, "fp", RED, Color.WHITE)

extends Node
## Keeps the Emergency Department (and Emergency Radiology upstairs) busy:
##   EMS      every couple of minutes a unit calls in (the trauma board shows
##            it inbound with a live ETA), the ambulance pulls into the garage
##            with its lights on, the crew wheels the patient through both sets
##            of automatic doors to a trauma bay or an acute room, hands over,
##            and takes the empty cot back out before the ambulance leaves;
##   walk-ins patients come in off the street, through security and
##            registration, and sit in the waiting room; the triage nurse
##            calls them through to Super Track, and discharged patients walk
##            back out;
##   transport a transporter wheels patients up to radiology and back;
##   staff    nurses, physicians and techs walk the corridors;
##   imaging  the CT and MRI tables slide patients in and out.
## It also owns the fictional patient list the tracking board, trauma board
## and bedside monitors show. Everything runs on real time; tests speed it
## up with `time_scale`.
const CartCrew = preload("res://npc/cart_crew.gd")
const RouteWalker = preload("res://npc/route_walker.gd")
const Ambulance = preload("res://world/hospital/ambulance.gd")
const Pedestrian = preload("res://npc/ambient/pedestrian.gd")
const ED = preload("res://world/hospital/hospital_ed.gd")
const Props = preload("res://world/hospital/hospital_props.gd")
const EMS_INTERVAL := Vector2(120.0, 160.0)
## The trauma board shows the unit inbound this long before it arrives.
const ETA_WINDOW := 150.0
const WALKIN_INTERVAL := Vector2(32.0, 50.0)
const CALL_INTERVAL := Vector2(38.0, 60.0)
const DISCHARGE_INTERVAL := Vector2(50.0, 80.0)
const TRANSPORT_INTERVAL := Vector2(80.0, 110.0)
const UNITS := ["EMS 7", "EMS 12", "Medic 4", "EMS 31", "Medic 9"]
const CALLS := {
	1: ["Pedestrian struck · GCS 9", "Motor vehicle crash · rollover", "Fall from height · 20 ft", "Cardiac arrest · ROSC in field", "Respiratory failure"],
	2: ["Chest pain · STEMI alert", "Stroke alert · onset 40 min", "Short of breath · SpO₂ 86%", "Sepsis alert · BP 84/50", "Head injury on blood thinners"],
	3: ["Abdominal pain · vomiting", "Fall at home · hip pain", "Fever and confusion", "Kidney stone pain", "Syncope · now alert"],
}
const COMPLAINTS := {
	1: ["Trauma · MVC", "Pedestrian struck", "Cardiac arrest", "Resp. failure"],
	2: ["Chest pain", "Stroke symptoms", "Shortness of breath", "Sepsis", "Head injury", "GI bleed"],
	3: ["Abdominal pain", "Fever", "Kidney stone", "Fall · hip pain", "Dizziness", "Vomiting"],
	4: ["Ankle injury", "Laceration", "Ear pain", "Back strain", "Rash"],
	5: ["Rx refill", "Sore throat", "Wound check", "Minor burn"],
}
const NURSES := ["PS", "JR", "MT", "KL", "AD", "RB"]
const PHYSICIANS := ["AL", "RK", "MN", "TO", "JC"]
var hospital: Node3D
var layout: Dictionary
var imaging: Dictionary
var rng := RandomNumberGenerator.new()
## Speeds up the department's timers (tests); movement stays real-time.
var time_scale := 1.0
## Bed id -> fictional record for the tracking board.
var beds := {}
var patient_seed := 1000
# EMS.
var ambulance: Node3D
var parked: Node3D
var crew: Node3D
var ems_state := "idle"
var ems_timer := 0.0
var next_ems := 45.0
var ems_call: Dictionary = {}
var ems_bay: Dictionary = {}
var activations := 3
var arrivals := 0
# Walk-ins, calls and discharges.
var walkers: Array[Node3D] = []
var timers := {"walkin": 12.0, "call": 30.0, "discharge": 40.0, "transport": 55.0}
var discharges := 0
var walkins := 0
# Transport to radiology.
var transport: Node3D
var transport_state := "idle"
var transport_bay: Dictionary = {}
var transport_timer := 0.0
var transports := 0
# Radiology.
var table_clock := 0.0
var imaging_crew: Node3D
var imaging_state := "idle"
var imaging_timer := 20.0
var staff: Array[Node3D] = []

func setup(target: Node3D) -> void:
	hospital = target
	layout = hospital.ed_layout
	imaging = hospital.imaging_layout
	rng.seed = 20260921
	for mode in hospital.displays:
		var display: Control = hospital.displays[mode]
		if "source" in display:
			display.source = self
	for bay in layout.bays:
		if bay.occupied:
			beds[bay.id] = _record(bay, 1 if bay.kind == "trauma" else rng.randi_range(2, 3), rng.randf_range(20.0, 240.0))
	if beds.has("T1"):
		beds.T1.status = "Trauma team at bedside"
	_convert_seated_waiting()
	_seed_super_track()
	var garage: Dictionary = layout.garage
	parked = Ambulance.new()
	parked.name = "ParkedAmbulance"
	parked.unit_label = "EMS 12"
	hospital.zone_roots.ed.add_child(parked)
	parked.place(garage.parked, Ambulance.yaw_of(Vector3.RIGHT))
	_spawn_staff()

## A fictional record for a bed: initials, age and sex, complaint, team, status.
func _record(bay: Dictionary, esi: int, minutes_ago: float) -> Dictionary:
	var letters := "ABCDEFGHJKLMNPRSTW"
	var initials := "%s.%s." % [letters[rng.randi() % letters.length()], letters[rng.randi() % letters.length()]]
	var complaints: Array = COMPLAINTS[esi]
	var statuses := {1: ["Resus in progress", "Trauma team at bedside", "Awaiting CT"], 2: ["Awaiting CT", "Awaiting labs", "Consult pending", "Admit · boarding"], 3: ["Awaiting labs", "Awaiting results", "In X-ray", "Ready for discharge", "Awaiting MD"], 4: ["In Super Track", "Awaiting X-ray", "Ready for discharge"], 5: ["In Super Track", "Ready for discharge"]}
	var options: Array = statuses[esi]
	return {
		"bed": String(bay.get("bed", bay.get("id", ""))), "esi": esi, "initials": initials,
		"age": "%d%s" % [rng.randi_range(19, 88), "F" if rng.randf() < 0.5 else "M"],
		"complaint": complaints[rng.randi() % complaints.size()],
		"rn": NURSES[rng.randi() % NURSES.size()], "md": PHYSICIANS[rng.randi() % PHYSICIANS.size()],
		"status": options[rng.randi() % options.size()],
		"since": GameClock.now_seconds() - minutes_ago * 60.0,
		"vitals": _vitals_for(esi),
	}

func _vitals_for(esi: int) -> Dictionary:
	var sick := esi <= 2
	return {
		"hr": rng.randi_range(104, 128) if sick else rng.randi_range(64, 96),
		"spo2": rng.randi_range(88, 94) if sick else rng.randi_range(95, 99),
		"sbp": rng.randi_range(88, 104) if esi == 1 else rng.randi_range(112, 148),
		"dbp": rng.randi_range(50, 64) if esi == 1 else rng.randi_range(66, 90),
		"rr": rng.randi_range(22, 30) if sick else rng.randi_range(12, 18),
	}

# --- Board data ------------------------------------------------------------------------------

func tracking_rows() -> Array:
	var rows: Array = []
	var order: Array = []
	for bay in layout.bays:
		order.append(bay.id)
	for index in range(layout.recliners.size()):
		order.append("ST%d" % (index + 1))
	for id in order:
		if not beds.has(id):
			continue
		var record: Dictionary = beds[id]
		var minutes := int(maxf(0.0, GameClock.now_seconds() - float(record.since)) / 60.0)
		var row := record.duplicate()
		row.bed = id if id.begins_with("T") or id.begins_with("ST") else "Rm %s" % id
		row.time = "%d:%02d" % [floori(minutes / 60.0), minutes % 60]
		rows.append(row)
	return rows

func status_info() -> Dictionary:
	var waiting := 0
	for seat in layout.waiting_seats:
		if seat.occupant != null:
			waiting += 1
	var inbound := ems_state == "inbound" or ems_state == "arriving"
	var shown: Dictionary = ems_call if ems_state != "idle" else {}
	return {
		"waiting": waiting, "inbound": 1 if inbound else 0,
		"next_ems": shown, "eta": next_ems if ems_state == "inbound" else -1.0,
		"activations": activations, "wait": 12 + waiting * 4,
	}

func bay_rows() -> Array:
	var rows: Array = []
	for bay in layout.bays:
		if bay.kind != "trauma":
			continue
		if beds.has(bay.id):
			var record: Dictionary = beds[bay.id]
			rows.append({"bed": bay.bed, "esi": record.esi, "status": "%s · %s · %s" % [record.initials, record.age, record.status]})
		elif not ems_bay.is_empty() and ems_bay.id == bay.id:
			rows.append({"bed": bay.bed, "esi": ems_call.get("esi", 0), "status": "Prepared for %s" % ems_call.get("unit", "EMS")})
		else:
			rows.append({"bed": bay.bed, "esi": 0, "status": "Ready · stocked and checked"})
	return rows

func monitor_data() -> Array:
	var data: Array = []
	data.resize(16)
	for bay in layout.bays:
		var entry := {"label": bay.label, "active": false}
		if beds.has(bay.id):
			var record: Dictionary = beds[bay.id]
			var vitals: Dictionary = record.vitals
			entry = {"label": bay.label, "active": true, "name": "%s %s" % [record.initials, record.age], "hr": vitals.hr, "spo2": vitals.spo2, "sbp": vitals.sbp, "dbp": vitals.dbp, "rr": vitals.rr}
		data[int(bay.tile)] = entry
	return data

# --- Simulation ------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var step := delta * time_scale
	_ems(step)
	for key in timers:
		timers[key] -= step
	if timers.walkin <= 0.0:
		timers.walkin = rng.randf_range(WALKIN_INTERVAL.x, WALKIN_INTERVAL.y)
		spawn_walkin()
	if timers.call <= 0.0:
		timers.call = rng.randf_range(CALL_INTERVAL.x, CALL_INTERVAL.y)
		call_from_waiting()
	if timers.discharge <= 0.0:
		timers.discharge = rng.randf_range(DISCHARGE_INTERVAL.x, DISCHARGE_INTERVAL.y)
		discharge()
	if timers.transport <= 0.0 and transport_state == "idle":
		timers.transport = rng.randf_range(TRANSPORT_INTERVAL.x, TRANSPORT_INTERVAL.y)
		start_transport()
	_transport(step)
	_imaging(delta, step)
	_drift_vitals(delta)
	for walker in walkers.duplicate():
		if not is_instance_valid(walker):
			walkers.erase(walker)

func _drift_vitals(delta: float) -> void:
	if rng.randf() > delta * 0.5:
		return
	for id in beds:
		var vitals: Dictionary = beds[id].vitals
		vitals.hr = clampi(int(vitals.hr) + rng.randi_range(-2, 2), 50, 140)
		vitals.spo2 = clampi(int(vitals.spo2) + rng.randi_range(-1, 1), 85, 100)

# --- EMS -------------------------------------------------------------------------------------------

func _ems(step: float) -> void:
	match ems_state:
		"idle":
			next_ems -= step
			if next_ems <= ETA_WINDOW:
				_dispatch()
		"inbound":
			next_ems -= step
			if next_ems <= 0.0:
				_arrive()
		"handoff", "loading":
			ems_timer -= step
			if ems_timer <= 0.0:
				if ems_state == "handoff":
					_return_crew()
				else:
					_depart()

## A unit calls in: choose a free bay for its patient and show it inbound.
func _dispatch() -> void:
	var esi := 1 if rng.randf() < 0.5 else rng.randi_range(2, 3)
	var bay := _free_bay(esi)
	if bay.is_empty():
		next_ems = ETA_WINDOW + 30.0
		return
	var summaries: Array = CALLS[esi]
	ems_bay = bay
	ems_call = {"unit": UNITS[rng.randi() % UNITS.size()], "summary": summaries[rng.randi() % summaries.size()], "esi": esi, "bed": bay.bed}
	ems_state = "inbound"

func _free_bay(esi: int) -> Dictionary:
	var candidates: Array = []
	for bay in layout.bays:
		if bay.occupied or bay.get("reserved", false):
			continue
		if (esi == 1) == (bay.kind == "trauma"):
			candidates.append(bay)
	if candidates.is_empty():
		for bay in layout.bays:
			if not bay.occupied and not bay.get("reserved", false):
				candidates.append(bay)
	if candidates.is_empty():
		return {}
	var bay: Dictionary = candidates[rng.randi() % candidates.size()]
	bay["reserved"] = true
	return bay

## Sends the next unit in now (tests, and the student waiting at the doors).
func dispatch_now() -> void:
	if ems_state == "idle":
		next_ems = 0.0
		_dispatch()
	if ems_state == "inbound":
		next_ems = 0.0

func _arrive() -> void:
	var garage: Dictionary = layout.garage
	ambulance = Ambulance.new()
	ambulance.name = "Ambulance"
	ambulance.unit_label = String(ems_call.unit)
	ambulance.watch = hospital.player
	hospital.zone_roots.ed.add_child(ambulance)
	ambulance.place(garage.spawn, Ambulance.yaw_of(Vector3.RIGHT))
	ambulance.set_lights(true)
	ambulance.arrived.connect(_on_ambulance_stopped, CONNECT_ONE_SHOT)
	ambulance.drive([garage.spawn, garage.stop], 7.0)
	ems_state = "arriving"

func _on_ambulance_stopped() -> void:
	ems_state = "unloading"
	ambulance.set_lights(false)
	ambulance.open_rear(true)
	await get_tree().create_timer(_seconds(1.3)).timeout
	if not is_instance_valid(ambulance):
		return
	crew = CartCrew.new()
	crew.name = "EMSCrew"
	hospital.zone_roots.ed.add_child(crew)
	crew.setup([ED.staff_look("paramedic", rng.randi()), ED.staff_look("emt", rng.randi())], "cot", ED.patient_look(_next_seed()))
	crew.watch = hospital.player
	crew.place(ambulance.rear_point(1.6), CartCrew.heading_of(Vector3.LEFT))
	crew.partner_side = -signf(float(ems_bay.park.x) - float(ems_bay.center.x))
	crew.arrived.connect(_on_crew_at_bay, CONNECT_ONE_SHOT)
	crew.walk(route_to_bay(ems_bay))
	ems_state = "to_bay"

## An EMS crew's way from the ambulance's rear doors to a bay (the
## ambulance must be stopped in the garage).
func route_to_bay(bay: Dictionary) -> Array:
	var points: Dictionary = layout.points
	var rear: Vector3 = ambulance.rear_point(2.4)
	var door: Vector3 = bay.door
	return [rear, rear + Vector3(0.6, 0, -2.2), points.ems_curb, points.ems_outer, points.ems_vestibule, points.ems_inner, points.ems_mid, points.corridor_ems, Vector3(door.x, 0, points.corridor_ems.z), door, bay.inside, bay.park]

func _on_crew_at_bay() -> void:
	ems_state = "handoff"
	ems_timer = 6.0
	arrivals += 1
	await get_tree().create_timer(_seconds(3.0)).timeout
	if not is_instance_valid(crew):
		return
	# Handover: the patient moves over to the department's stretcher.
	crew.set_patient(false)
	_occupy(ems_bay, int(ems_call.esi))
	beds[ems_bay.id].complaint = String(ems_call.summary).get_slice(" · ", 0)
	beds[ems_bay.id].status = "Trauma team at bedside" if int(ems_call.esi) == 1 else "Awaiting MD"
	if int(ems_call.esi) == 1:
		activations += 1

func _occupy(bay: Dictionary, esi: int) -> void:
	bay.occupied = true
	bay.reserved = false
	var patient: Node3D = bay.patient
	var look: Node3D = patient.get_child(0)
	look.apply_look(ED.patient_look(_next_seed()))
	Props.lay(patient, look, 0.5, patient.rotation.y)
	patient.visible = true
	bay.blanket.visible = true
	beds[bay.id] = _record(bay, esi, 0.0)

func _return_crew() -> void:
	ems_state = "returning"
	var route := route_to_bay(ems_bay)
	route.reverse()
	crew.arrived.connect(_on_crew_back, CONNECT_ONE_SHOT)
	# Back the empty cot out of the bay (inside, door, corridor), then push on.
	crew.walk(route.slice(1), 3)
	ems_bay = {}

func _on_crew_back() -> void:
	ems_state = "loading"
	ems_timer = 2.0
	if is_instance_valid(crew):
		crew.queue_free()
	crew = null
	ambulance.open_rear(false)

func _depart() -> void:
	ems_state = "departing"
	var garage: Dictionary = layout.garage
	ambulance.arrived.connect(_on_ambulance_gone, CONNECT_ONE_SHOT)
	ambulance.drive([ambulance.global_position, garage.exit], 8.0)

func _on_ambulance_gone() -> void:
	if is_instance_valid(ambulance):
		ambulance.queue_free()
	ambulance = null
	ems_state = "idle"
	ems_call = {}
	next_ems = rng.randf_range(EMS_INTERVAL.x, EMS_INTERVAL.y)

func _seconds(value: float) -> float:
	return maxf(0.01, value / time_scale)

func _next_seed() -> int:
	patient_seed += 1
	return patient_seed

# --- Walk-ins, triage calls, discharges ------------------------------------------------------------

## Existing waiting-room patients become walkers who can be called back.
func _convert_seated_waiting() -> void:
	for seat in layout.waiting_seats:
		var figure: Node3D = seat.occupant
		if figure == null:
			continue
		var look: Dictionary = figure.get_child(0).look
		figure.queue_free()
		var walker := _walker(look)
		walker.global_position = seat.pos
		walker.run([{"sit": seat.pos, "yaw": 0.0, "seat": 0.36, "for": 0.0, "instant": true}])
		seat.occupant = walker

func _seed_super_track() -> void:
	for index in [0, 2, 3]:
		var recliner: Dictionary = layout.recliners[index]
		var walker := _walker(ED.patient_look(_next_seed(), false))
		walker.global_position = recliner.pos
		walker.run([{"sit": recliner.pos, "yaw": recliner.yaw, "seat": 0.36, "for": 0.0, "instant": true}])
		recliner.occupant = walker
		beds["ST%d" % (index + 1)] = _record({"bed": "ST%d" % (index + 1)}, rng.randi_range(4, 5), rng.randf_range(10.0, 90.0))

func _walker(look: Variant) -> Node3D:
	var walker := RouteWalker.new()
	walker.name = "EDWalker"
	hospital.zone_roots.ed.add_child(walker)
	walker.setup(look)
	walker.watch = hospital.player
	walkers.append(walker)
	return walker

func _free_seat(seats: Array) -> Dictionary:
	var free: Array = seats.filter(func(seat: Dictionary) -> bool: return seat.occupant == null)
	return {} if free.is_empty() else free[rng.randi() % free.size()]

func spawn_walkin() -> void:
	var seat := _free_seat(layout.waiting_seats)
	if seat.is_empty():
		return
	var points: Dictionary = layout.points
	var walker := _walker(ED.patient_look(_next_seed(), false))
	walker.global_position = points.walkin_outside
	var route: Array = [{"to": points.walkin_vestibule}, {"to": points.walkin_inside}, {"to": points.screening}, {"wait": 1.2}, {"to": points.after_screening}, {"to": points.registration}, {"face": points.registration_desk}, {"wait": 2.5}]
	var front: Vector3 = seat.front
	var lane: Vector3 = seat.lane
	if front.z > points.registration.z + 2.0:
		# Round the check-in kiosk: along the front of the room, then down the aisle.
		route.append({"to": Vector3(points.registration.x - 2.6, 0, points.registration.z + 0.5)})
	# Along the row's aisle, clear of seated knees, then in to the seat.
	route.append_array([{"to": Vector3(points.registration.x - 2.6, 0, lane.z)}, {"to": lane}, {"to": front}, {"sit": seat.pos, "yaw": 0.0, "seat": 0.36, "for": 0.0}])
	walker.run(route)
	seat.occupant = walker
	walkins += 1

## The triage nurse calls a waiting patient through to Super Track.
func call_from_waiting() -> void:
	var recliner := _free_seat(layout.recliners)
	if recliner.is_empty():
		return
	var seated: Array = layout.waiting_seats.filter(func(seat: Dictionary) -> bool: return seat.occupant != null and is_instance_valid(seat.occupant) and seat.occupant.is_sitting())
	if seated.is_empty():
		return
	var seat: Dictionary = seated[rng.randi() % seated.size()]
	var walker: Node3D = seat.occupant
	seat.occupant = null
	var points: Dictionary = layout.points
	var route: Array = [{"to": seat.front}, {"to": seat.lane}, {"to": Vector3(points.registration.x - 2.6, 0, seat.lane.z)}]
	if seat.front.z > points.registration.z + 2.0:
		route.append({"to": Vector3(points.registration.x - 2.6, 0, points.registration.z + 0.5)})
	route.append_array([{"to": Vector3(points.st_doors_south.x - 1.4, 0, 10.2)}, {"to": points.st_doors_south}, {"to": points.st_doors_north}, {"to": points.st_aisle}, {"to": Vector3(recliner.front.x, 0, points.st_aisle.z)}, {"to": recliner.front}, {"sit": recliner.pos, "yaw": recliner.yaw, "seat": 0.36, "for": 0.0}])
	walker.run(route)
	recliner.occupant = walker
	var index: int = layout.recliners.find(recliner)
	beds["ST%d" % (index + 1)] = _record({"bed": "ST%d" % (index + 1)}, rng.randi_range(4, 5), 0.0)

## The way home from Super Track: back through its doors, up the exit lane
## beside the security arch and out through both sets of walk-in doors.
func exit_route() -> Array:
	var points: Dictionary = layout.points
	return [{"to": points.st_doors_north}, {"to": points.st_doors_south}, {"to": Vector3(points.after_screening.x + 1.2, 0, 10.2)}, {"to": Vector3(points.after_screening.x + 1.2, 0, 14.3)}, {"to": points.walkin_inside}, {"to": points.walkin_vestibule}, {"to": points.walkin_outside}, {"hide": true}]

## A Super Track patient going home from their recliner.
func recliner_discharge_route(recliner: Dictionary) -> Array:
	var points: Dictionary = layout.points
	return [{"to": recliner.front}, {"to": Vector3(recliner.front.x, 0, points.st_aisle.z)}, {"to": points.st_aisle}] + exit_route()

## A patient walking out of an acute room (starting at its `inside` point).
func room_discharge_route(bay: Dictionary) -> Array:
	var points: Dictionary = layout.points
	var door: Vector3 = bay.door
	return [{"to": door}, {"to": Vector3(door.x, 0, points.corridor_east.z)}, {"to": points.corridor_east}, {"to": points.st_aisle}] + exit_route()

## A patient goes home: from a Super Track recliner or an acute room, out through the waiting room.
func discharge() -> void:
	var seated: Array = layout.recliners.filter(func(recliner: Dictionary) -> bool: return recliner.occupant != null and is_instance_valid(recliner.occupant) and recliner.occupant.is_sitting())
	if not seated.is_empty() and rng.randf() < 0.55:
		var recliner: Dictionary = seated[rng.randi() % seated.size()]
		var walker: Node3D = recliner.occupant
		recliner.occupant = null
		beds.erase("ST%d" % (layout.recliners.find(recliner) + 1))
		walker.run(recliner_discharge_route(recliner))
		discharges += 1
		return
	var rooms: Array = layout.bays.filter(func(bay: Dictionary) -> bool: return bay.kind == "acute" and bay.occupied and not bay.get("away", false) and beds.has(bay.id) and GameClock.now_seconds() - float(beds[bay.id].since) > 120.0)
	if rooms.is_empty():
		return
	var bay: Dictionary = rooms[rng.randi() % rooms.size()]
	var look: Dictionary = bay.patient.get_child(0).look
	_vacate(bay)
	var walker := _walker(look)
	walker.global_position = bay.inside
	walker.run(room_discharge_route(bay))
	discharges += 1

func _vacate(bay: Dictionary) -> void:
	bay.occupied = false
	bay.patient.visible = false
	bay.blanket.visible = false
	beds.erase(bay.id)

# --- Transport to radiology --------------------------------------------------------------------

func start_transport() -> void:
	var rooms: Array = layout.bays.filter(func(bay: Dictionary) -> bool: return bay.kind == "acute" and bay.occupied and not bay.get("away", false))
	if rooms.is_empty():
		return
	transport_bay = rooms[rng.randi() % rooms.size()]
	transport_bay["away"] = true
	var look: Dictionary = transport_bay.patient.get_child(0).look
	transport_bay.patient.visible = false
	transport_bay.blanket.visible = false
	if beds.has(transport_bay.id):
		beds[transport_bay.id].status = "In CT"
	transport = CartCrew.new()
	transport.name = "Transport"
	hospital.zone_roots.ed.add_child(transport)
	transport.setup([ED.staff_look("transporter", rng.randi())], "wheelchair", look)
	transport.watch = hospital.player
	transport.place(transport_bay.inside, CartCrew.heading_of(Vector3.BACK))
	transport.walk(transport_route())
	transport_state = "out"
	transports += 1

## The wheelchair transport's way from `transport_bay` to the service elevator.
func transport_route() -> Array:
	var points: Dictionary = layout.points
	var door: Vector3 = transport_bay.door
	return [door, Vector3(door.x, 0, points.corridor_ems.z), Vector3(-14.0 + ED.ORIGIN.x, 0, points.corridor_ems.z), points.elevator_approach, points.service_elevator_front]

func _transport(step: float) -> void:
	match transport_state:
		"out":
			if not transport.moving:
				transport.set_present(false)
				transport_state = "upstairs"
				transport_timer = 40.0
		"upstairs":
			transport_timer -= step
			if transport_timer <= 0.0:
				transport.set_present(true)
				var route := transport_route()
				route.reverse()
				transport.walk(route.slice(1) + [transport_bay.inside])
				transport_state = "back"
		"back":
			if not transport.moving:
				transport.queue_free()
				transport = null
				transport_bay.erase("away")
				transport_bay.patient.visible = transport_bay.occupied
				transport_bay.blanket.visible = transport_bay.occupied
				if beds.has(transport_bay.id):
					beds[transport_bay.id].status = "Awaiting results"
				transport_bay = {}
				transport_state = "idle"

# --- Radiology -------------------------------------------------------------------------------------

func _imaging(delta: float, step: float) -> void:
	table_clock += delta
	for index in range(imaging.tables.size()):
		var table: Dictionary = imaging.tables[index]
		var period := 70.0 if table.name == "MRI" else 34.0
		var phase := fposmod(table_clock + index * 11.0, period) / period
		# In over a few seconds, hold for the scan, back out, then wait.
		var amount := 0.0
		if phase < 0.12:
			amount = phase / 0.12
		elif phase < 0.55:
			amount = 1.0
		elif phase < 0.67:
			amount = 1.0 - (phase - 0.55) / 0.12
		var node: Node3D = table.node
		node.global_position = Vector3(table.out).lerp(table["in"], amount * amount * (3.0 - 2.0 * amount)) if table.occupied else table.out
	imaging_timer -= step
	match imaging_state:
		"idle":
			if imaging_timer <= 0.0:
				_imaging_arrival()
		"parked":
			if imaging_timer <= 0.0:
				imaging_state = "leaving"
				imaging_crew.walk([imaging.points.corridor_holding, imaging.points.corridor_west, imaging.points.elevator_front])
		"arriving", "leaving":
			if not imaging_crew.moving:
				if imaging_state == "arriving":
					imaging_state = "parked"
					imaging_timer = 25.0
				else:
					imaging_crew.queue_free()
					imaging_crew = null
					imaging_state = "idle"
					imaging_timer = rng.randf_range(60.0, 90.0)

func _imaging_arrival() -> void:
	var holding: Array = imaging.holding.filter(func(bay: Dictionary) -> bool: return not bay.occupied)
	if holding.is_empty():
		imaging_timer = 30.0
		return
	var bay: Dictionary = holding[0]
	imaging_crew = CartCrew.new()
	imaging_crew.name = "ImagingTransport"
	hospital.zone_roots.imaging.add_child(imaging_crew)
	imaging_crew.setup([ED.staff_look("transporter", rng.randi())], "stretcher", ED.patient_look(_next_seed()))
	imaging_crew.watch = hospital.player
	imaging_crew.place(imaging.points.elevator_front, PI)
	imaging_crew.walk([imaging.points.corridor_west, imaging.points.corridor_holding, bay.front])
	imaging_state = "arriving"

# --- Staff walking the department --------------------------------------------------------------

func _spawn_staff() -> void:
	var o: Vector3 = ED.ORIGIN
	# The corridor, the EMS hallway, and round the central station (by its
	# outside corners, clear of the counters and the physicians' desk).
	var nodes := [
		Vector2(-30, -9), Vector2(-22, -9), Vector2(-10, -9), Vector2(2, -9), Vector2(14, -9), Vector2(28, -9),
		Vector2(-22, 2), Vector2(-22, 10), Vector2(-7.4, -3.4), Vector2(11.4, -3.4), Vector2(2, 0.8), Vector2(-14, 5),
		Vector2(-7.4, 0.9), Vector2(11.4, 0.9),
	]
	var edges := [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [1, 6], [6, 7], [2, 8], [8, 12], [12, 10], [10, 13], [13, 9], [9, 4], [6, 11], [11, 12]]
	var shifted: Array = nodes.map(func(point: Vector2) -> Vector2: return point + Vector2(o.x, o.z))
	# Where a step aside may not go: the station, the physicians' desk, the EMS
	# check-in desk and the housekeeping cart outside Room 11.
	var keep_clear := []
	for zone in [[Vector2(2, -3.5), 4.0], [Vector2(-3.5, -3.7), 2.8], [Vector2(7.5, -3.7), 2.8], [Vector2(-6.0, -3.7), 2.6], [Vector2(10.0, -3.7), 2.6], [Vector2(0, 3.4), 3.0], [Vector2(-4.6, 3.4), 1.9], [Vector2(4.6, 3.4), 1.9], [Vector2(-16.4, 2.0), 1.7], [Vector2(27.2, -10.1), 1.1]]:
		keep_clear.append([zone[0] + Vector2(o.x, o.z), zone[1]])
	var roles := ["ed_nurse", "ed_doctor", "ed_nurse", "resident", "transporter", "ed_nurse"]
	for index in range(roles.size()):
		var walker := Pedestrian.new()
		walker.name = "EDStaff"
		walker.nodes = shifted
		walker.edges = edges
		hospital.zone_roots.ed.add_child(walker)
		walker.setup(ED.staff_look(roles[index], 300 + index), hospital.player, keep_clear)
		staff.append(walker)

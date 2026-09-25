extends Node3D
## The Emergency Department seen from the campus: about every five real
## minutes an ambulance comes along the street behind the hospital with its
## lights on, pulls past the AMBULANCE ONLY bay and backs in, rear to the
## automatic doors. The crew pulls out the cot and wheels the patient inside;
## a while later they bring the empty cot back, load it, and the ambulance
## pulls out and drives off. A second ambulance stays parked in the bay.
## The first arrival comes shortly after you reach the campus.
const Ambulance = preload("res://world/hospital/ambulance.gd")
const CartCrew = preload("res://npc/cart_crew.gd")
const SlidingDoors = preload("res://world/hospital/sliding_doors.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const ED = preload("res://world/hospital/hospital_ed.gd")
const PERIOD := 300.0
const FIRST_ARRIVAL := 25.0
## How long the crew stays inside with the patient.
const DWELL := 90.0
## Westbound lane of the street along the hospital's south side.
const LANE_Z := 77.2
## Where the ambulance stops in the bay (backed in, facing the street).
const BAY_STOP := Vector3(0.0, 0, 66.3)
const PARKED := Vector3(-5.6, 0, 66.3)
## Where the crew is out of sight behind the open doors (the building has no
## interior at campus scale; a dark backdrop sits just inside the doors).
const INSIDE := Vector3(0.0, 0, 56.2)
var period := PERIOD
## Speeds up the schedule (tests); driving and walking stay real-time.
var time_scale := 1.0
var ambulance: Node3D
var parked: Node3D
var crew: Node3D
var doors: Node3D
var state := "idle"
var timer := FIRST_ARRIVAL
var cycle_clock := 0.0
var cycles := 0
var watch: Node3D
var rng := RandomNumberGenerator.new()

func setup(player: Node3D) -> void:
	watch = player
	rng.randomize()
	doors = SlidingDoors.new(2.6, 2.5, true)
	doors.name = "AmbulanceBayDoors"
	doors.position = Buildings.AMBULANCE_DOORS
	doors.auto_group = "door_openers"
	doors.auto_radius = 3.0
	add_child(doors)
	parked = Ambulance.new()
	parked.name = "ParkedAmbulance"
	parked.unit_label = "EMS 12"
	add_child(parked)
	parked.place(PARKED, Ambulance.yaw_of(Vector3.BACK))

func _process(delta: float) -> void:
	var step := delta * time_scale
	cycle_clock += step
	match state:
		"idle":
			timer -= step
			if timer <= 0.0:
				arrive()
		"inside":
			timer -= step
			if timer <= 0.0:
				_bring_cot_back()

## Sends the next ambulance in now.
func arrive() -> void:
	if state != "idle":
		return
	state = "arriving"
	cycle_clock = 0.0
	ambulance = Ambulance.new()
	ambulance.name = "Ambulance"
	ambulance.unit_label = ["EMS 7", "Medic 4", "EMS 31"][rng.randi() % 3]
	ambulance.watch = watch
	add_child(ambulance)
	ambulance.place(Vector3(96.0, 0, LANE_Z), Ambulance.yaw_of(Vector3.LEFT))
	ambulance.set_lights(true)
	ambulance.arrived.connect(_back_in, CONNECT_ONE_SHOT)
	ambulance.drive([Vector3(96.0, 0, LANE_Z), Vector3(-7.0, 0, LANE_Z)], 9.0)

## Stopped just past the bay: back in, rear to the doors.
func _back_in() -> void:
	state = "backing"
	ambulance.set_lights(false)
	ambulance.arrived.connect(_unload, CONNECT_ONE_SHOT)
	ambulance.drive([Vector3(-7.0, 0, LANE_Z), Vector3(0.0, 0, 74.4), BAY_STOP], 2.4, 4.0, true)

func _unload() -> void:
	state = "unloading"
	ambulance.open_rear(true)
	await get_tree().create_timer(_seconds(1.3)).timeout
	if not is_instance_valid(ambulance):
		return
	crew = CartCrew.new()
	crew.name = "EMSCrew"
	add_child(crew)
	crew.setup([ED.staff_look("paramedic", rng.randi()), ED.staff_look("emt", rng.randi())], "cot", ED.patient_look(rng.randi()))
	crew.watch = watch
	crew.place(ambulance.rear_point(1.6), CartCrew.heading_of(Vector3.FORWARD))
	crew.arrived.connect(_crew_inside, CONNECT_ONE_SHOT)
	crew.walk([ambulance.rear_point(2.4), Vector3(0, 0, 59.4), INSIDE])
	state = "wheeling_in"

func _crew_inside() -> void:
	crew.set_present(false)
	state = "inside"
	timer = DWELL

func _bring_cot_back() -> void:
	state = "wheeling_out"
	crew.set_patient(false)
	crew.set_present(true)
	crew.place(INSIDE, CartCrew.heading_of(Vector3.BACK))
	crew.arrived.connect(_load, CONNECT_ONE_SHOT)
	crew.walk([Vector3(0, 0, 59.4), ambulance.rear_point(2.2), ambulance.rear_point(1.5)])

func _load() -> void:
	state = "loading"
	crew.queue_free()
	crew = null
	ambulance.open_rear(false)
	await get_tree().create_timer(_seconds(1.6)).timeout
	if not is_instance_valid(ambulance):
		return
	state = "departing"
	ambulance.arrived.connect(_gone, CONNECT_ONE_SHOT)
	ambulance.drive([BAY_STOP, Vector3(0.0, 0, 73.6), Vector3(-9.0, 0, LANE_Z), Vector3(-96.0, 0, LANE_Z)], 9.0)

func _gone() -> void:
	ambulance.queue_free()
	ambulance = null
	cycles += 1
	state = "idle"
	# The next one comes about five minutes after this one arrived.
	timer = maxf(20.0, period - cycle_clock + rng.randf_range(-15.0, 15.0))

func _seconds(value: float) -> float:
	return maxf(0.01, value / time_scale)

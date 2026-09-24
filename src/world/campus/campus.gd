extends Node3D
## Medical-school campus: a Harvard-style central quad (lawn panels, cross
## paths, round plaza, tree rows) framed by a modern stacked Learning Center
## (north), Cedar Residence (west), a café pavilion (east), a classical
## Anatomy Hall and a medical-centre tower in the background, and parking to
## the south. Buildings live in buildings.gd, planting in flora.gd; geometry
## is merged per material (mesh_kit.gd) so the larger map stays fast.
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
const StudentScene = preload("res://npc/student.tscn")
const Config = preload("res://data/campus_config.gd")
const MeshKit = preload("res://world/campus/mesh_kit.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const Flora = preload("res://world/campus/flora.gd")

const PATH := Color("dcd6c9")
const PLAZA := Color("e4dfd3")
const COURT := Color("d6d0c3")
const ASPHALT := Color("7c8084")
const CURB := Color("c9c4b8")
const WOOD := Color("a57a52")
const POST := Color("4a5156")
## Lawn panels of the quad (x0, z0, x1, z1), also used for grass tufts.
const LAWNS := [[-12.0, -12.0, -1.5, -3.5], [1.5, -12.0, 12.0, -3.5], [-12.0, -0.5, -1.5, 8.0], [1.5, -0.5, 12.0, 8.0]]
const PLAZA_CENTER := Vector3(0, 0, -2)
const PLAZA_RADIUS := 4.5
## Benches: [position, yaw]. Yaw turns the seat to face -Z rotated by yaw.
## The four plaza benches sit on the diagonals, facing the planter.
static var BENCHES := [
	[Vector3(-6, 0, -5.8), 0.0], [Vector3(6, 0, -5.8), 0.0], [Vector3(-6, 0, 1.8), PI], [Vector3(6, 0, 1.8), PI],
	[Vector3(-13.5, 0, -8), PI / 2], [Vector3(13.5, 0, 4), -PI / 2], [Vector3(-19.5, 0, 2.6), 0.0],
	[Vector3(8, 0, -13.9), PI], [Vector3(-8, 0, -13.9), PI],
	[PLAZA_CENTER + Vector3(2.4, 0, -2.4), atan2(1.0, -1.0)], [PLAZA_CENTER + Vector3(-2.4, 0, -2.4), atan2(-1.0, -1.0)],
	[PLAZA_CENTER + Vector3(2.4, 0, 2.4), atan2(1.0, 1.0)], [PLAZA_CENTER + Vector3(-2.4, 0, 2.4), atan2(-1.0, 1.0)],
]
## Who sits where: [bench index, seat offset along the bench, activity, look].
const BENCH_STUDENTS := [
	[1, -0.45, "lunch", "teal"], [1, 0.45, "reading", "plum"],
	[3, 0.0, "notes", "sage"],
	[2, -0.45, "lunch", "clay"], [2, 0.45, "notes", "ochre"],
	[5, 0.0, "reading", "indigo"],
	[7, 0.2, "notes", "plum"],
	[9, 0.0, "lunch", "sage"], [12, 0.0, "reading", "teal"],
]
## Lawn where the dog walker roams (x, z, width, depth): the quad's south-east panel.
const DOG_LAWN := Rect2(2.2, 0.2, 9.1, 7.1)

var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var dorm_door: Node3D
var lecture_door: Node3D
var noticeboard: Node3D
var student: Node3D
var sun: DirectionalLight3D
var campus_environment: Environment
var sky_material: ProceduralSkyMaterial

func _ready() -> void:
	_build_ground()
	_build_paving()
	Buildings.learning_center(self)
	Buildings.residence(self)
	Buildings.medical_center(self)
	Buildings.anatomy_hall(self)
	Buildings.pavilion(self)
	_build_signs()
	_build_props()
	_build_parking()
	_build_planting()
	_build_grass()
	_build_context()
	_build_bounds()
	_build_people()
	_build_interactions()
	_build_lighting()
	player = Player.instantiate()
	player.position = Config.SPAWNS.get(AppState.campus_entry, Config.SPAWNS.dorm)
	add_child(player)
	player.appearance.rotation.y = Config.SPAWN_YAWS.get(AppState.campus_entry, Config.SPAWN_YAWS.dorm)
	camera = Camera.new()
	camera.view_size = Config.CAMERA_VIEW
	camera.follow_min = Config.CAMERA_MIN
	camera.follow_max = Config.CAMERA_MAX
	add_child(camera)
	camera.follow(player)
	player.movement_camera = camera
	_build_ambient_life()
	hud = HUD.new()
	add_child(hud)
	hud.bind_player(player)
	AppState.view_changed.connect(apply_view)
	apply_view(AppState.first_person)

## From eye level the flat backdrop reads as empty, so first person shows a
## daylight sky gradient. Ambient light stays the configured colour either way.
func apply_view(first_person: bool) -> void:
	campus_environment.background_mode = Environment.BG_SKY if first_person else Environment.BG_COLOR
	# Distance haze melts the far ground into the horizon; eye-level shadows get
	# a shorter range (more resolution near you) and soft edges.
	campus_environment.fog_enabled = first_person
	sun.directional_shadow_max_distance = 42.0 if first_person else 70.0
	sun.shadow_blur = 1.6 if first_person else 1.0

# --- Ground ---------------------------------------------------------------------------

func _build_ground() -> void:
	var ground := Geometry.box(self, "Ground", Vector3(560, 0.3, 560), Vector3(0, -0.15, 0), Color("5f9a3f"), true)
	var lawn := ShaderMaterial.new()
	lawn.shader = preload("res://assets/grass.gdshader")
	ground.get_child(0).material_override = lawn

## Paths, plazas, forecourts and parking surfaces. Each layer sits a few
## millimetres above the one below so overlaps never z-fight.
func _build_paving() -> void:
	var kit := MeshKit.new()
	var slab := func(x0: float, z0: float, x1: float, z1: float, top: float, color: Color) -> void:
		kit.box("paving", Vector3((x0 + x1) / 2.0, top / 2.0, (z0 + z1) / 2.0), Vector3(x1 - x0, top, z1 - z0), color)
	# Quad: perimeter walk, cross axes, round plaza.
	slab.call(-15, -15, 15, -12, 0.03, PATH)
	slab.call(-15, 8, 15, 11, 0.03, PATH)
	slab.call(-15, -12, -12, 8, 0.03, PATH)
	slab.call(12, -12, 15, 8, 0.03, PATH)
	slab.call(-1.5, -12, 1.5, 8, 0.035, PATH)
	slab.call(-1.5, 11, 1.5, 14, 0.035, PATH)
	slab.call(-12, -3.5, 12, -0.5, 0.04, PATH)
	slab.call(-22, -3.5, -15, -0.5, 0.04, PATH)
	slab.call(15, -3.5, 20.5, -0.5, 0.04, PATH)
	kit.cylinder("paving", PLAZA_CENTER, PLAZA_CENTER + Vector3(0, 0.05, 0), PLAZA_RADIUS, PLAZA, 40)
	kit.cylinder("paving", PLAZA_CENTER + Vector3(0, 0.05, 0), PLAZA_CENTER + Vector3(0, 0.055, 0), PLAZA_RADIUS - 0.25, PLAZA.darkened(0.04), 40)
	# Learning Center plaza, residence forecourt, medical forecourt, café terrace.
	slab.call(-17, -24.7, 17, -15, 0.03, PLAZA) # Runs under the facade: no grass gap.
	slab.call(-22, -7, -15, 4, 0.032, COURT)
	slab.call(17, -22, 36, -14, 0.03, PLAZA)
	slab.call(15, -11, 20.5, 5, 0.034, Color("cfc6b5"))
	slab.call(-20, -24, -15, -15, 0.03, PLAZA)
	slab.call(-34.4, -21.0, -20, -18.4, 0.03, PLAZA) # Apron to the Anatomy Hall steps.
	# Sidewalk and parking to the south, street beyond.
	slab.call(-26, 11, 26, 14, 0.03, PATH)
	slab.call(-25, 14, 25, 26, 0.02, ASPHALT)
	slab.call(-40, 27, 40, 35, 0.02, ASPHALT.darkened(0.15))
	slab.call(-40, 26, 40, 27, 0.05, CURB)
	slab.call(-40, 35, 40, 37, 0.05, CURB)
	for index in range(16):
		var x := -37.5 + index * 5.0
		slab.call(x, 30.9, x + 2.4, 31.1, 0.025, Color("d8d3c2"))
	# Parking bays: low-contrast stall lines.
	for row in [[14.8, 19.0], [21.6, 25.8]]:
		for index in range(19):
			var x := -22.5 + index * 2.6
			slab.call(x - 0.05, row[0], x + 0.05, row[1], 0.024, Color("b3b6b7"))
	kit.commit(self, "Paving", false)

# --- Signage ----------------------------------------------------------------------------

func _build_signs() -> void:
	Buildings.letters(self, "LEARNING CENTER", Vector3(8, 0.42, -17.0), 0.0, 0.5, Color("3a4247"))
	Buildings.letters(self, "SCHOOL OF MEDICINE", Vector3(-8, 0.42, -17.0), 0.0, 0.42, Color("3a4247"))
	Buildings.letters(self, "LECTURE HALL A", Vector3(0, 4.25, -19.8), 0.0, 0.22, Color("3a4247"), 0.03)
	Buildings.letters(self, "CEDAR RESIDENCE", Vector3(-18.8, 3.3, -2), PI / 2, 0.22, Color("3a4247"), 0.03)
	Buildings.letters(self, "UNIVERSITY MEDICAL CENTER", Vector3(26, 5.3, -18.7), 0.0, 0.26, Color("3a4247"), 0.03)
	Buildings.letters(self, "CAFÉ", Vector3(19.0, 3.95, -3), -PI / 2, 0.3, Color("3a4247"), 0.03)

# --- Street furniture, planters and the directory -------------------------------------

func _build_props() -> void:
	var kit := MeshKit.new()
	var stone := Color("cfc9bc")
	var soil := Color("7a6450") # Light bark mulch.
	# Learning Center plaza planters (raised, seat-height walls).
	for x0 in [-12.0, 4.0]:
		kit.solid_box("facade", Vector3(x0 + 4, 0.38, -19), Vector3(8, 0.76, 4), stone)
		kit.box("facade", Vector3(x0 + 4, 0.77, -19), Vector3(7.6, 0.04, 3.6), soil)
		kit.box("wood", Vector3(x0 + 4, 0.8, -16.85), Vector3(7.2, 0.08, 0.34), Color.WHITE)
	# Round planter at the heart of the quad.
	kit.cylinder("facade", PLAZA_CENTER, PLAZA_CENTER + Vector3(0, 0.55, 0), 1.9, stone, 28)
	kit.cylinder("facade", PLAZA_CENTER + Vector3(0, 0.55, 0), PLAZA_CENTER + Vector3(0, 0.58, 0), 1.75, soil, 28)
	var plaza_collider := StaticBody3D.new()
	plaza_collider.name = "PlazaPlanterCollision"
	var round_shape := CollisionShape3D.new()
	round_shape.shape = CylinderShape3D.new()
	round_shape.shape.radius = 1.9
	round_shape.shape.height = 1.2
	round_shape.position = PLAZA_CENTER + Vector3(0, 0.6, 0)
	plaza_collider.add_child(round_shape)
	add_child(plaza_collider)
	# Benches around the quad (timber slats on dark steel frames).
	for bench in BENCHES:
		_bench(kit, bench[0], bench[1])
	# Lamp posts along the perimeter walk.
	for point in [Vector3(-15.3, 0, -9), Vector3(-15.3, 0, 5), Vector3(15.3, 0, -9), Vector3(15.3, 0, 5), Vector3(-6, 0, 11.3), Vector3(6, 0, 11.3), Vector3(-6, 0, -15.3), Vector3(6, 0, -15.3)]:
		kit.cylinder("metal", point, point + Vector3(0, 4.2, 0), 0.06, POST)
		kit.box("metal", point + Vector3(0, 4.3, 0), Vector3(0.5, 0.12, 0.22), POST)
		kit.box("facade", point + Vector3(0, 4.22, 0), Vector3(0.42, 0.03, 0.16), Color("fffbe8"))
		kit.solid(point + Vector3(0, 1, 0), Vector3(0.14, 2, 0.14))
	# Raised planter for the medical-centre forecourt flowers.
	kit.solid_box("facade", Vector3(26, 0.2, -15.2), Vector3(14.4, 0.4, 1.2), Color("d3cdbf"))
	kit.box("facade", Vector3(26, 0.39, -15.2), Vector3(14.0, 0.04, 0.9), Color("4a3b2e"))
	# Campus directory outside the residence: a double-sided pylon with a plan of
	# the campus on both faces, turned toward the residence door and the path.
	var kiosk := Vector3(-17, 0, 3)
	kit.solid_box("metal", kiosk + Vector3(0, 1.15, 0), Vector3(1.6, 2.3, 0.2), Color("2f3d44"))
	kit.box("metal", kiosk + Vector3(0, 0.06, 0), Vector3(1.75, 0.12, 0.34), Color("262f34"))
	for face in [-1.0, 1.0]:
		var z: float = face * 0.105
		kit.box("facade", kiosk + Vector3(0, 1.16, z), Vector3(1.38, 1.26, 0.012), Color("efeadf"))
		# Plan (north up for whoever reads this face): the quad's four lawns and
		# paths, the buildings around it, a "you are here" dot, and a legend.
		var plan := func(u: float, v: float, w: float, h: float, color: Color, lift := 1.07) -> void:
			kit.box("facade", kiosk + Vector3(u * face, v, z * lift), Vector3(w, h, 0.004), color)
		for lawn in [[-0.12, -0.09], [0.12, -0.09], [-0.12, 0.09], [0.12, 0.09]]:
			plan.call(0.1 + lawn[0], 1.36 + lawn[1], 0.2, 0.14, Color("8fbf73"))
		plan.call(0.1, 1.62, 0.5, 0.1, Color("c3cacd")) # Learning Center
		plan.call(-0.36, 1.62, 0.22, 0.1, Color("d8d1c2")) # Anatomy Hall
		plan.call(-0.33, 1.34, 0.12, 0.36, Color("e3d4ad")) # Cedar Residence
		plan.call(0.5, 1.33, 0.1, 0.22, Color("b8c6cf")) # Café
		plan.call(0.5, 1.62, 0.16, 0.12, Color("aab8c2")) # Medical Center
		plan.call(-0.2, 1.36, 0.045, 0.045, Color("d9483b"), 1.1) # You are here
		for row in range(4):
			plan.call(-0.3 + (row % 2) * 0.62, 0.92 - (row / 2) * 0.12, 0.5, 0.035, Color("7d8a90"))
			plan.call(-0.58 + (row % 2) * 0.62, 0.92 - (row / 2) * 0.12, 0.05, 0.05, [Color("c3cacd"), Color("e3d4ad"), Color("d8d1c2"), Color("b8c6cf")][row])
		Geometry.wall_sign(self, "CAMPUS DIRECTORY", kiosk + Vector3(0, 2.05, face * 0.105), 0.0 if face > 0 else PI, 22, 0.0058)
	# Café terrace tables with umbrellas.
	for point in [Vector3(17, 0, -8), Vector3(17, 0, -4.8), Vector3(17, 0, 1.2), Vector3(18.6, 0, 3.4)]:
		kit.cylinder("metal", point, point + Vector3(0, 0.74, 0), 0.04, POST)
		kit.cylinder("facade", point + Vector3(0, 0.74, 0), point + Vector3(0, 0.77, 0), 0.45, Color("f1efe9"), 14)
		kit.cylinder("metal", point, point + Vector3(0, 2.3, 0), 0.025, Color("d8dcde"))
		kit.cylinder("facade", point + Vector3(0, 2.2, 0), point + Vector3(0, 2.35, 0), 1.3, Color("f4efe4"), 12)
		kit.solid(point + Vector3(0, 0.5, 0), Vector3(0.9, 1.0, 0.9))
	kit.commit(self, "StreetFurniture")

## Park bench: timber slats on dark steel frames. The seat top is at 0.30 m to
## match the stylised figures (the same height as the lecture-hall chairs).
func _bench(kit: MeshKit, position: Vector3, yaw: float) -> void:
	var basis := Basis(Vector3.UP, yaw)
	for index in range(4):
		kit.box("wood", position + basis * Vector3(0, 0.275, -0.18 + index * 0.12), Vector3(1.8, 0.05, 0.1), Color.WHITE, basis)
	for side in [-1, 1]:
		kit.box("metal", position + basis * Vector3(side * 0.75, 0.13, 0), Vector3(0.06, 0.26, 0.5), POST, basis)
		kit.box("metal", position + basis * Vector3(side * 0.75, 0.45, 0.23), Vector3(0.06, 0.5, 0.05), POST, basis)
	kit.box("wood", position + basis * Vector3(0, 0.56, 0.24), Vector3(1.8, 0.28, 0.05), Color.WHITE, basis)
	kit.solid(position + basis * Vector3(0, 0.35, 0.02), Vector3(1.9, 0.7, 0.56), basis)

# --- Parking -----------------------------------------------------------------------------

func _build_parking() -> void:
	var kit := MeshKit.new()
	var colours := [Color("f2f2f0"), Color("c3c8cc"), Color("4a6484"), Color("b8443c"), Color("4b5156"), Color("8a979d")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for row in [[16.9, 0.0], [23.7, PI]]:
		for index in range(18):
			if rng.randf() < 0.35 or absf(-21.2 + index * 2.6) < 2.5:
				continue
			_car(kit, Vector3(-21.2 + index * 2.6, 0, row[0]), row[1] + rng.randf_range(-0.04, 0.04), colours[rng.randi() % colours.size()])
	# Planted islands between the bays.
	for x in [-24.3, 24.3]:
		kit.solid_box("facade", Vector3(x, 0.1, 20), Vector3(1.2, 0.2, 11.5), CURB)
	kit.commit(self, "Parking")

func _car(kit: MeshKit, position: Vector3, yaw: float, colour: Color) -> void:
	var basis := Basis(Vector3.UP, yaw)
	kit.box("metal", position + basis * Vector3(0, 0.55, 0), Vector3(1.8, 0.6, 4.3), colour, basis)
	kit.box("metal", position + basis * Vector3(0, 1.05, 0.25), Vector3(1.6, 0.5, 2.2), colour, basis)
	kit.box("glass", position + basis * Vector3(0, 1.06, 0.25), Vector3(1.62, 0.4, 2.0), Color.WHITE, basis)
	for side in [-1, 1]:
		for end in [-1, 1]:
			kit.cylinder("metal", position + basis * Vector3(side * 0.8, 0.33, end * 1.35), position + basis * Vector3(side * 0.92, 0.33, end * 1.35), 0.33, Color("1b1d1f"), 10)
	kit.solid(position + Vector3(0, 0.7, 0), (basis * Vector3(1.9, 1.4, 4.4)).abs())

# --- Planting ----------------------------------------------------------------------------

func _build_planting() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var place := func(points: Array, low: float, high: float) -> Array:
		return points.map(func(p: Vector3) -> Array: return [p, rng.randf_range(low, high), rng.randf() * TAU])
	# Shade-tree rows along the quad, and trees at the plaza corners.
	var shade := []
	for z in [-12.0, -7.0, 3.0, 8.0]:
		# The west row keeps clear of the sightline from the camera to the residence door.
		shade.append(Vector3(-17, 0, 6.0 if z == 3.0 else z))
		shade.append(Vector3(17, 0, z))
	shade.append_array([Vector3(-19, 0, -19), Vector3(-27, 0, 12.5), Vector3(-33, 0, 12.5), Vector3(30, 0, 9), Vector3(34, 0, -10)])
	Flora.plant(self, "shade", place.call(shade, 0.95, 1.2))
	# Flowering trees: medical-centre frontage, residence forecourt, plaza centre.
	var flowering := [Vector3(19, 0, -16.5), Vector3(23.5, 0, -16.5), Vector3(28.5, 0, -16.5), Vector3(33, 0, -16.5), Vector3(-20, 0, -6.2), Vector3(-20, 0, 3.4), PLAZA_CENTER + Vector3(0, 0.55, 0)]
	Flora.plant(self, "flowering", place.call(flowering, 0.9, 1.1))
	# Ornamentals in the plaza planters and the parking islands.
	var ornamental := [Vector3(-10, 0.76, -19), Vector3(-6, 0.76, -19), Vector3(6, 0.76, -19), Vector3(10, 0.76, -19), Vector3(-24.3, 0.2, 16.5), Vector3(-24.3, 0.2, 23.5), Vector3(24.3, 0.2, 16.5), Vector3(24.3, 0.2, 23.5)]
	Flora.plant(self, "ornamental", place.call(ornamental, 0.9, 1.15))
	# Columnar trees framing the Anatomy Hall portico and the residence corners.
	Flora.plant(self, "columnar", place.call([Vector3(-35, 0, -22.6), Vector3(-23, 0, -22.6), Vector3(-21.2, 0, 10.2), Vector3(-21.2, 0, -13.2), Vector3(16.2, 0, -14.4), Vector3(-16.2, 0, -14.4)], 0.95, 1.1))
	# Foundation shrubs, bed edges and planter fill.
	var shrubs := []
	for x in range(-13, 14, 2):
		if absf(x) > 3:
			shrubs.append(Vector3(x, 0, -23.4))
	for z in range(-11, 9, 2):
		if z < -6 or z > 2:
			shrubs.append(Vector3(-21.4, 0, z))
	for angle in range(0, 360, 40):
		shrubs.append(PLAZA_CENTER + Vector3(cos(deg_to_rad(angle)) * 1.25, 0.55, sin(deg_to_rad(angle)) * 1.25))
	for x in [-11.0, -8.5, -3.5, 3.5, 8.5, 11.0]:
		shrubs.append(Vector3(x, 0.76, -20.4))
	for x in range(18, 35, 3):
		if absf(x - 26) > 2.4: # Keep the Medical Center doors clear.
			shrubs.append(Vector3(x, 0, -21.4))
	# Fill the plaza planters and the pavilion's green roof with low planting.
	for planter_x in [-8.0, 8.0]:
		for index in range(10):
			shrubs.append(Vector3(planter_x + rng.randf_range(-3.3, 3.3), 0.76, -19 + rng.randf_range(-1.4, 1.4)))
	for index in range(14):
		shrubs.append(Vector3(rng.randf_range(20.5, 29.5), 4.12, rng.randf_range(-9.2, 3.2)))
	Flora.plant(self, "shrub", place.call(shrubs, 0.7, 1.15), false)
	# Low hedges edging the parking lot (gap at the central axis).
	var hedges := []
	for index in range(11):
		hedges.append(Vector3(-23.5 + index * 2.05, 0, 14.1))
		hedges.append(Vector3(2.9 + index * 2.05, 0, 14.1))
	Flora.plant(self, "hedge", hedges.map(func(p: Vector3) -> Array: return [p, 1.0, 0.0]))
	# Flower beds: blossoms in the planters and around the plaza.
	var blossoms := []
	var tints := []
	var palette := [Color("f6e6ef"), Color("f5c542"), Color("e8708a"), Color("c9a4e8"), Color("ffffff")]
	var beds := [[Vector3(-8, 0.77, -19), Vector2(3.6, 1.6)], [Vector3(8, 0.77, -19), Vector2(3.6, 1.6)], [PLAZA_CENTER + Vector3(0, 0.58, 0), Vector2(1.5, 1.5)], [Vector3(26, 0.4, -15.2), Vector2(6.8, 0.4)]]
	for bed in beds:
		for index in range(70):
			var offset := Vector3(rng.randf_range(-bed[1].x, bed[1].x), 0, rng.randf_range(-bed[1].y, bed[1].y))
			if bed[0] == PLAZA_CENTER + Vector3(0, 0.58, 0) and offset.length() > 1.6:
				continue
			blossoms.append([bed[0] + offset, rng.randf_range(0.8, 1.4), rng.randf() * TAU])
			tints.append(palette[rng.randi() % palette.size()])
	Flora.plant(self, "blossom", blossoms, false, tints)

## Dense short turf tufts on the lawn panels only.
func _build_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260921
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for lawn in LAWNS:
		var area: float = (lawn[2] - lawn[0]) * (lawn[3] - lawn[1])
		for index in range(int(area * 42)):
			var x := rng.randf_range(lawn[0] + 0.1, lawn[2] - 0.1)
			var z := rng.randf_range(lawn[1] + 0.1, lawn[3] - 0.1)
			if Vector2(x - PLAZA_CENTER.x, z - PLAZA_CENTER.z).length() < PLAZA_RADIUS + 0.1:
				continue
			var size := rng.randf_range(0.5, 0.8)
			transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.28, 0.4), size)), Vector3(x, 0, z)))
			colors.append(Color("2f7a1f").lerp(Color("6db43a"), rng.randf()))
	var tufts := MultiMesh.new()
	tufts.transform_format = MultiMesh.TRANSFORM_3D
	tufts.use_colors = true
	tufts.mesh = _tuft_mesh()
	tufts.instance_count = transforms.size()
	for index in range(transforms.size()):
		tufts.set_instance_transform(index, transforms[index])
		tufts.set_instance_color(index, colors[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = "GrassTufts"
	instance.multimesh = tufts
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var blades := ShaderMaterial.new()
	blades.shader = preload("res://assets/grass_blades.gdshader")
	instance.material_override = blades
	add_child(instance)

## One tuft: five tapered blades leaning out from a shared root.
static func _tuft_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(Color.WHITE)
	for blade in range(5):
		var angle := blade * TAU / 5.0 + 0.4 * sin(blade * 2.3)
		var out := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-out.z, 0, out.x) * 0.022
		var height := 0.2 + 0.12 * fmod(blade * 0.618, 1.0)
		var root := out * 0.03
		var tip_point := out * (0.07 + (0.03 if blade % 2 else 0.0)) + Vector3(0, height, 0)
		tool.set_normal((out + Vector3.UP).normalized())
		tool.add_vertex(root - side)
		tool.add_vertex(root + side)
		tool.add_vertex(tip_point)
	return tool.commit()

# --- Surroundings ------------------------------------------------------------------------

## Distant city blocks beyond the campus edge so the view never ends in void.
func _build_context() -> void:
	var kit := MeshKit.new()
	var blocks := [
		[Vector3(-30, 0, -52), Vector3(22, 28, 14)], [Vector3(-4, 0, -54), Vector3(18, 40, 16)], [Vector3(20, 0, -50), Vector3(20, 22, 12)],
		[Vector3(44, 0, -38), Vector3(12, 30, 18)], [Vector3(-54, 0, -30), Vector3(14, 24, 22)], [Vector3(-56, 0, 2), Vector3(12, 16, 26)],
		[Vector3(-20, 0, 48), Vector3(24, 10, 12)], [Vector3(12, 0, 48), Vector3(20, 12, 12)],
	]
	for block in blocks:
		var center: Vector3 = block[0] + Vector3(0, block[1].y / 2.0, 0)
		kit.box("glass", center, block[1], Color.WHITE)
		kit.box("facade", center + Vector3(0, block[1].y / 2.0 + 0.3, 0), block[1] + Vector3(0.4, 0.6, 0.4), Color("e9e7e1"))
	kit.commit(self, "Skyline")
	# A line of street trees along the far side of the road.
	var trees := []
	for index in range(12):
		trees.append([Vector3(-36 + index * 6.5, 0, 36.2), 1.0, float(index)])
	Flora.plant(self, "shade", trees, false)

## Invisible edges of the walkable campus.
func _build_bounds() -> void:
	var body := StaticBody3D.new()
	body.name = "CampusBounds"
	for bound in [[Vector3(0, 1.5, -37.5), Vector3(80, 3, 1)], [Vector3(0, 1.5, 26.5), Vector3(80, 3, 1)], [Vector3(-39.5, 1.5, -5), Vector3(1, 3, 66)], [Vector3(36.5, 1.5, -5), Vector3(1, 3, 66)]]:
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.shape.size = bound[1]
		shape.position = bound[0]
		body.add_child(shape)
	add_child(body)

# --- People and interactions -------------------------------------------------------------

func _build_people() -> void:
	for id in ["alex", "sam"]:
		var actor := StudentScene.instantiate()
		actor.actor_id = id
		actor.world_zone = "campus"
		add_child(actor)
	NPCSchedule.start()

## Students on benches (lunch, reading, notes), a dog walker on the south-east
## lawn and a few students strolling the paths, all with randomised timing.
var bench_students: Array[Node3D] = []
var dog_walker: Node3D
var pedestrians: Array[Node3D] = []

func _build_ambient_life() -> void:
	var feet := StaticBody3D.new()
	feet.name = "SeatedFeetColliders"
	add_child(feet)
	var occupied := {}
	for entry in BENCH_STUDENTS:
		var bench: Array = BENCHES[entry[0]]
		var basis := Basis(Vector3.UP, bench[1])
		var student := preload("res://npc/ambient/bench_student.gd").new()
		student.activity = entry[2]
		student.preset = entry[3]
		student.name = "BenchStudent"
		# Seated origin: hips over the slats, backpack against the backrest.
		student.position = bench[0] + basis * Vector3(entry[1], 0.02, -0.12)
		student.rotation.y = bench[1]
		add_child(student)
		bench_students.append(student)
		occupied[entry[0]] = true
	for index in occupied:
		# Seated knees and feet reach past the slats; keep walkers out of them.
		var bench: Array = BENCHES[index]
		var basis := Basis(Vector3.UP, bench[1])
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.shape.size = Vector3(1.8, 0.5, 0.34)
		shape.position = bench[0] + basis * Vector3(0, 0.25, -0.44)
		shape.basis = basis
		feet.add_child(shape)
	dog_walker = preload("res://npc/ambient/dog_walker.gd").new()
	dog_walker.name = "DogWalker"
	dog_walker.region = DOG_LAWN
	dog_walker.avoid = [[Vector2(6, 1.8), 1.7]]
	add_child(dog_walker)
	# Places a pedestrian may not sidestep into: benches (and seated knees), the planter.
	var keep_clear: Array = [[Vector2(PLAZA_CENTER.x, PLAZA_CENTER.z), 2.25]]
	for bench in BENCHES:
		var front: Vector3 = bench[0] + Basis(Vector3.UP, bench[1]) * Vector3(0, 0, -0.2)
		keep_clear.append([Vector2(front.x, front.z), 1.15])
	for preset in ["clay", "sage", "ochre"]:
		var walker := preload("res://npc/ambient/pedestrian.gd").new()
		walker.name = "Pedestrian"
		add_child(walker)
		walker.setup(preset, player, keep_clear)
		pedestrians.append(walker)

func _build_interactions() -> void:
	dorm_door = _endpoint("ResidenceInteraction", "Enter Cedar Residence", "", Config.RESIDENCE_DOOR)
	dorm_door.activated.connect(AppState.enter_dorm)
	lecture_door = _endpoint("LectureEntryInteraction", "Enter Learning Center", "", Config.LEARNING_CENTER_DOOR)
	lecture_door.activated.connect(AppState.enter_lecture_building)
	noticeboard = _endpoint("DirectoryInteraction", "Read campus directory", "Learning Center / Lecture Hall A: cross the quad to the north, past the round plaza. Cedar Residence faces the quad on the west side; the café is to the east.", Vector3(-17, 1, 2.3))
	student = _endpoint("StudentInteraction", "Talk to student", "Morning! Hall A is in the Learning Center, the white building at the top of the quad. Head through the glass doors under the canopy.", Config.SAM_POSITION + Vector3(0, 1, 0.75))

func _endpoint(node_name: String, title: String, response: String, position: Vector3) -> Node3D:
	var endpoint := Endpoint.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response
	endpoint.position = position
	add_child(endpoint)
	return endpoint

# --- Lighting ---------------------------------------------------------------------------

func _build_lighting() -> void:
	var sky := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("91b8c6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Config.MORNING.ambient_color
	environment.ambient_light_energy = Config.MORNING.ambient_energy
	# Filmic tone mapping keeps white facades bright without clipping, as in renders.
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.25
	environment.glow_bloom = 0.04
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = 70.0
	environment.fog_depth_end = 190.0
	environment.fog_sky_affect = 0.0
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sun_angle_max = 20.0
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_material
	campus_environment = environment
	sky.environment = environment
	add_child(sky)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Config.MORNING.sun_rotation
	sun.light_color = Config.MORNING.sun_color
	sun.light_energy = Config.MORNING.sun_energy
	Geometry.configure_shadows(sun)
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	GameClock.minute_changed.connect(_update_daylight)
	_update_daylight()

func _update_daylight() -> void:
	var time := GameClock.snapshot()
	var hour := float(time.hour) + float(time.minute) / 60.0
	var daylight := maxf(0.0, sin((hour - 6.0) / 12.0 * PI))
	sun.light_energy = Config.MORNING.sun_energy * (0.06 + 0.94 * sqrt(daylight))
	sun.rotation_degrees.x = -10.0 - 60.0 * daylight
	campus_environment.ambient_light_energy = 0.18 + 0.38 * sqrt(daylight)
	campus_environment.background_color = Color("172a46").lerp(Color("75bfdf"), sqrt(daylight))
	var day := sqrt(daylight)
	sky_material.sky_top_color = Color("0e1c33").lerp(Color("4f9fd0"), day)
	sky_material.sky_horizon_color = Color("2a3d5c").lerp(Color("c9e3ee"), day)
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = Color("1d2a2e").lerp(Color("6f8a78"), day)
	sky_material.sky_energy_multiplier = 0.55 + 0.45 * day
	campus_environment.fog_light_color = sky_material.sky_horizon_color

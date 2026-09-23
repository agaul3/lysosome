extends Node3D
## Lecture Hall A: a raked auditorium. The front (−Z) is a floor-level teaching
## area with the projection screen, podium and a side table; five tiers of
## upholstered seats rise toward the back in three sections split by two
## stepped aisles. The entrance is on the left wall at the front, as in many
## medical-school lecture halls. Every free seat can be used; walking routes
## between rows follow a small walkway graph so the player enters a row from
## an aisle instead of climbing over seats.
const Geometry = preload("res://world/geometry.gd")
const Appearance = preload("res://player/appearance.gd")
const Seat = preload("res://world/seat.gd")
const LectureCamera = preload("res://world/lecture_camera.gd")
const LectureSession = preload("res://world/lecture_hall/lecture_session.gd")
const LectureSlide = preload("res://ui/lecture_slide.gd")
const Professor = preload("res://npc/professor.gd")
const SCREEN_CENTER := Vector3(0.8, 2.75, FRONT_WALL_Z + 0.075)
const SCREEN_SIZE := Vector2(6.2, 3.1)
const PODIUM := Vector3(-2.4, 0, -5.4)

const TIERS := 5
## Steep rake, as in teaching auditoria, so each row sees over the one in front.
const RISE := 0.38
const TIER_DEPTH := 1.6
const FIRST_TIER_Z := -3.4
const FRONT_WALL_Z := -8.0
const BACK_WALL_Z := 5.4
const HALF_WIDTH := 8.0
const WALL_HEIGHT := 4.6
## Aisle centre lines; each aisle is AISLE_WIDTH wide.
const AISLES := [-3.9, 3.9]
const AISLE_WIDTH := 1.2
## Seat x positions per section (left, centre, right).
const SECTIONS := {
	"left": [-6.8, -5.88, -4.96],
	"centre": [-2.76, -1.84, -0.92, 0.0, 0.92, 1.84, 2.76],
	"right": [4.96, 5.88, 6.8],
}
const SEAT_COLOR := Color("d45a2e")
## Modern, muted palette: slate carpet, warm greige walls, walnut panelling.
const STEP_COLOR := Color("5f6368")
const FLOOR_COLOR := Color("6a6d70")
const WALL_COLOR := Color("9c968c")
const TRIM_COLOR := Color("7d786f")
const WOOD_COLOR := Color(0.52, 0.35, 0.21)
## Seat key "row:x" -> classmate look. Alex's saved seat is separate.
const CLASSMATES := {
	"0:-0.92": "teal", "0:1.84": "plum", "0:5.88": "sage",
	"1:-2.76": "clay", "1:0.92": "sage", "1:-5.88": "plum",
	"2:0.00": "teal", "2:2.76": "clay", "2:4.96": "plum",
	"3:-1.84": "sage", "3:1.84": "teal", "3:-6.80": "clay",
	"4:0.92": "plum", "4:5.88": "teal",
}
const ALEX_SEAT := "2:-1.84"
const DOOR_Z := -6.2

var player: CharacterBody3D
var camera: Camera3D
var lecture_camera: Camera3D
var hud: CanvasLayer
var exit_door: Node3D
var actor: Node3D
var professor: Node3D
var seats: Array[Node3D] = []
var alex_seat: Node3D
var table_chairs: Array[Node3D] = []
var nav := AStar3D.new()
var slide_viewport: SubViewport
var slide: Control
var lecture_ui: CanvasLayer
var session: Node
## Ceiling and full-height near walls, only needed from the seated viewpoint.
## They fade in as the lecture camera settles so the isometric view keeps its
## cutaway and the hand-off never shows them popping in.
var interior_material: StandardMaterial3D
var interior_meshes: Array[MeshInstance3D] = []
var seat_nodes := {}

static func tier_front(row: int) -> float:
	return FIRST_TIER_Z + TIER_DEPTH * row

static func tier_height(row: int) -> float:
	return RISE * row

## Seat origin z for a row: seats sit at the back of their tier.
static func seat_z(row: int) -> float:
	return tier_front(row) + TIER_DEPTH - 0.36

static func walkway_z(row: int) -> float:
	return seat_z(row) + Seat.FRONT_POINT.z

func _ready() -> void:
	_build_room()
	_build_tiers()
	_build_aisles()
	_build_front()
	_build_seats()
	_build_navigation()
	_build_lighting()
	exit_door = preload("res://world/interactable.gd").new()
	exit_door.display_name = "Return to lobby"
	exit_door.position = Vector3(-HALF_WIDTH + 0.6, 1, DOOR_Z)
	exit_door.activated.connect(AppState.enter_lecture_building)
	add_child(exit_door)
	actor = preload("res://npc/student.tscn").instantiate()
	actor.world_zone = "lecture_hall"
	actor.seat = alex_seat
	add_child(actor)
	player = preload("res://player/player.tscn").instantiate()
	player.position = Vector3(-HALF_WIDTH + 1.0, 0.05, DOOR_Z)
	add_child(player)
	camera = preload("res://world/exploration_camera.gd").new()
	camera.view_size = 14.5
	camera.focal_point = Vector3(0, 0.6, -1.5)
	camera.follow_min = Vector2(-3.5, -4.0)
	camera.follow_max = Vector2(3.5, 1.5)
	add_child(camera)
	camera.follow(player)
	player.movement_camera = camera
	lecture_camera = LectureCamera.new()
	lecture_camera.name = "LectureCamera"
	add_child(lecture_camera)
	player.seating.state_changed.connect(_on_seating_state)
	hud = preload("res://ui/dorm_ui.gd").new()
	hud.location_title = "LECTURE HALL A"
	hud.objective_text = "Find an open seat for Pharmacodynamics"
	add_child(hud)
	hud.bind_player(player)
	lecture_ui = preload("res://ui/lecture_ui.gd").new()
	add_child(lecture_ui)
	session = LectureSession.new()
	session.name = "LectureSession"
	add_child(session)
	session.setup(self, lecture_ui, slide, slide_viewport, professor)

func _build_room() -> void:
	var depth := BACK_WALL_Z - FRONT_WALL_Z
	var mid_z := (BACK_WALL_Z + FRONT_WALL_Z) / 2.0
	Geometry.box(self, "Floor", Vector3(HALF_WIDTH * 2, 0.2, depth), Vector3(0, -0.1, mid_z), FLOOR_COLOR, true)
	# Far walls stand full height; the two walls nearest the camera are cut away
	# but keep full-height colliders.
	var walls := [
		["FrontWall", Vector3(HALF_WIDTH * 2 + 0.4, WALL_HEIGHT, 0.2), Vector3(0, WALL_HEIGHT / 2, FRONT_WALL_Z - 0.1), false, WALL_COLOR],
		["LeftWall", Vector3(0.2, WALL_HEIGHT, depth), Vector3(-HALF_WIDTH - 0.1, WALL_HEIGHT / 2, mid_z), false, WALL_COLOR],
		["RightWall", Vector3(0.2, WALL_HEIGHT, depth), Vector3(HALF_WIDTH + 0.1, WALL_HEIGHT / 2, mid_z), true, WALL_COLOR],
		["BackWall", Vector3(HALF_WIDTH * 2 + 0.4, WALL_HEIGHT, 0.2), Vector3(0, WALL_HEIGHT / 2, BACK_WALL_Z + 0.1), true, WALL_COLOR],
	]
	for wall in walls:
		var body := Geometry.box(self, wall[0], wall[1], wall[2], wall[4], true)
		var mesh: MeshInstance3D = body.get_child(0)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if wall[3]:
			mesh.scale.y = 0.03
			mesh.position.y = -WALL_HEIGHT / 2 + 0.07
	_build_interior_shell(depth, mid_z)
	# Warm wood panelling on the long left wall, with slim vertical reveals.
	var panel := Geometry.box(self, "WoodPanelling", Vector3(0.04, 3.4, depth - 3.2), Vector3(-HALF_WIDTH + 0.02, 1.9, mid_z + 1.6), Color("c08d5e"))
	_wood(panel.get_child(0), WOOD_COLOR)
	for index in range(12):
		var z := FRONT_WALL_Z + 3.2 + index * (depth - 3.2) / 12.0
		Geometry.box(self, "PanelReveal", Vector3(0.05, 3.4, 0.03), Vector3(-HALF_WIDTH + 0.03, 1.9, z), Color("5a3c26"))
	Geometry.box(self, "PanelCap", Vector3(0.08, 0.08, depth - 3.2), Vector3(-HALF_WIDTH + 0.04, 3.62, mid_z + 1.6), Color("5a3c26"))
	# Front-left entrance: blue double doors in a frame, exit sign above.
	for z in [DOOR_Z - 0.48, DOOR_Z + 0.48]:
		Geometry.box(self, "HallDoorLeaf", Vector3(0.05, 2.25, 0.9), Vector3(-HALF_WIDTH + 0.03, 1.125, z), Color("365d78"))
		Geometry.box(self, "DoorPushPlate", Vector3(0.03, 0.3, 0.1), Vector3(-HALF_WIDTH + 0.07, 1.1, z + (0.3 if z > DOOR_Z else -0.3)), Color("c9d2d6"))
	for z in [DOOR_Z - 1.0, DOOR_Z + 1.0]:
		Geometry.box(self, "HallDoorJamb", Vector3(0.1, 2.4, 0.1), Vector3(-HALF_WIDTH + 0.05, 1.2, z), TRIM_COLOR)
	Geometry.box(self, "HallDoorHead", Vector3(0.1, 0.12, 2.1), Vector3(-HALF_WIDTH + 0.05, 2.4, DOOR_Z), TRIM_COLOR)
	Geometry.box(self, "ExitSign", Vector3(0.06, 0.18, 0.44), Vector3(-HALF_WIDTH + 0.06, 2.72, DOOR_Z), Color("c8433a"))
	Geometry.box(self, "WallClock", Vector3(0.05, 0.36, 0.36), Vector3(-HALF_WIDTH + 0.04, 2.9, DOOR_Z + 1.9), Color("d6d3cc"))

func _build_interior_shell(depth: float, mid_z: float) -> void:
	interior_material = StandardMaterial3D.new()
	interior_material.albedo_color = Color(0.55, 0.53, 0.5, 0.0)
	interior_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	interior_material.roughness = 0.9
	var pieces := [
		["Ceiling", Vector3(HALF_WIDTH * 2 + 0.4, 0.12, depth + 0.4), Vector3(0, WALL_HEIGHT + 0.06, mid_z)],
		["RightWallInterior", Vector3(0.12, WALL_HEIGHT, depth), Vector3(HALF_WIDTH + 0.06, WALL_HEIGHT / 2, mid_z)],
		["BackWallInterior", Vector3(HALF_WIDTH * 2, WALL_HEIGHT, 0.12), Vector3(0, WALL_HEIGHT / 2, BACK_WALL_Z + 0.06)],
	]
	for piece in pieces:
		var mesh := MeshInstance3D.new()
		mesh.name = piece[0]
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = piece[1]
		mesh.position = piece[2]
		mesh.material_override = interior_material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.visible = false
		add_child(mesh)
		interior_meshes.append(mesh)
	# Recessed light panels in the ceiling.
	for x in [-5.0, 0.0, 5.0]:
		for z in [-5.5, -1.5, 2.5]:
			var fixture := MeshInstance3D.new()
			fixture.name = "CeilingLight"
			fixture.mesh = BoxMesh.new()
			fixture.mesh.size = Vector3(1.4, 0.03, 0.5)
			fixture.position = Vector3(x, WALL_HEIGHT - 0.01, z)
			var glow := StandardMaterial3D.new()
			glow.albedo_color = Color(1.0, 0.98, 0.92, 0.0)
			glow.emission_enabled = true
			glow.emission = Color("fff6e0")
			glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			fixture.material_override = glow
			fixture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fixture.visible = false
			add_child(fixture)
			interior_meshes.append(fixture)

func _process(_delta: float) -> void:
	var fade := 0.0
	if is_instance_valid(lecture_camera) and lecture_camera.current:
		fade = clampf((lecture_camera.blend - 0.6) / 0.3, 0.0, 1.0)
	for mesh in interior_meshes:
		mesh.visible = fade > 0.0
		var material := mesh.material_override as StandardMaterial3D
		material.albedo_color.a = fade

## Solid tier blocks for the three seating sections. Tier 0 is on the floor.
func _build_tiers() -> void:
	for row in range(1, TIERS):
		var z0 := tier_front(row)
		var z1 := tier_front(row + 1) if row < TIERS - 1 else BACK_WALL_Z
		var height := tier_height(row)
		for span in _section_spans():
			var width: float = span[1] - span[0]
			var block := Geometry.box(self, "Tier%d" % row, Vector3(width, height, z1 - z0), Vector3((span[0] + span[1]) / 2.0, height / 2.0, (z0 + z1) / 2.0), STEP_COLOR, true)
			block.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# A slightly darker riser strip marks each step edge without patterning the floor.
			Geometry.box(self, "TierNosing", Vector3(width, 0.03, 0.05), Vector3((span[0] + span[1]) / 2.0, height + 0.012, z0 + 0.025), Color("4a4e53"))

func _section_spans() -> Array:
	var left_aisle: float = AISLES[0]
	var right_aisle: float = AISLES[1]
	return [
		[-HALF_WIDTH, left_aisle - AISLE_WIDTH / 2],
		[left_aisle + AISLE_WIDTH / 2, right_aisle - AISLE_WIDTH / 2],
		[right_aisle + AISLE_WIDTH / 2, HALF_WIDTH],
	]

## Stepped aisles: a landing level with each tier's walkway, then two steps up.
## Collision is a smooth ramp through the step nosings so walking is continuous;
## the visible steps sit within a few centimetres of it.
func _build_aisles() -> void:
	for x in AISLES:
		for row in range(TIERS):
			var z0 := tier_front(row)
			var level := tier_height(row)
			var landing_start := z0 - 0.4 if row > 0 else z0 - 0.4
			var landing_end := z0 + 0.8 if row < TIERS - 1 else BACK_WALL_Z
			if row > 0:
				var landing := Geometry.box(self, "AisleLanding", Vector3(AISLE_WIDTH, level, landing_end - landing_start), Vector3(x, level / 2.0, (landing_start + landing_end) / 2.0), STEP_COLOR)
				landing.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if row == TIERS - 1:
				_collider_box(Vector3(x, level / 2.0, (z0 - 0.35 + BACK_WALL_Z) / 2.0), Vector3(AISLE_WIDTH, level, BACK_WALL_Z - z0 + 0.35))
				continue
			if row > 0:
				_collider_box(Vector3(x, level / 2.0, z0 + 0.15), Vector3(AISLE_WIDTH, level, 1.0))
			var step := Geometry.box(self, "AisleStep", Vector3(AISLE_WIDTH, level + RISE / 2, 0.4), Vector3(x, (level + RISE / 2) / 2.0, z0 + 1.0), STEP_COLOR)
			step.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for nose_z in [z0 + 0.8, z0 + 1.2]:
				var nose_y := level + (RISE / 2 if nose_z < z0 + 1.0 else RISE)
				Geometry.box(self, "StepNosing", Vector3(AISLE_WIDTH, 0.03, 0.05), Vector3(x, nose_y + 0.012, nose_z + 0.025), Color("44484d"))
			_ramp(x, z0 + 0.65, z0 + 1.25, level, level + RISE)

func _collider_box(center: Vector3, size: Vector3) -> void:
	if size.y <= 0.001:
		return
	var body := StaticBody3D.new()
	body.name = "AisleCollider"
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	body.position = center
	add_child(body)

func _ramp(x: float, z0: float, z1: float, y0: float, y1: float) -> void:
	var body := StaticBody3D.new()
	body.name = "AisleRamp"
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	var half := AISLE_WIDTH / 2
	hull.points = PackedVector3Array([
		Vector3(x - half, y0, z0), Vector3(x + half, y0, z0), Vector3(x - half, y1, z1), Vector3(x + half, y1, z1),
		Vector3(x - half, 0, z0), Vector3(x + half, 0, z0), Vector3(x - half, 0, z1), Vector3(x + half, 0, z1),
	])
	shape.shape = hull
	body.add_child(shape)
	add_child(body)

func _build_front() -> void:
	# Projection screen with a slim frame and the lecture title.
	Geometry.box(self, "ScreenFrame", Vector3(6.4, 3.3, 0.06), Vector3(0.8, 2.75, FRONT_WALL_Z + 0.03), Color("2f3438"))
	_build_screen()
	Geometry.box(self, "Whiteboard", Vector3(3.2, 1.3, 0.04), Vector3(-5.6, 1.75, FRONT_WALL_Z + 0.03), Color("cfd1cd"))
	Geometry.box(self, "WhiteboardTray", Vector3(3.2, 0.05, 0.1), Vector3(-5.6, 1.08, FRONT_WALL_Z + 0.07), Color("b9bcb8"))
	_build_podium(PODIUM)
	professor = Professor.new()
	professor.name = "Professor"
	professor.position = PODIUM + Vector3(0, 0, -0.75)
	professor.screen_point = SCREEN_CENTER
	add_child(professor)
	preload("res://npc/student.gd").make_blocker(professor)
	# Side table with two loose chairs near the entrance.
	Geometry.box(self, "SideTable", Vector3(1.5, 0.06, 0.75), Vector3(-5.8, 0.74, -4.95), Color("b3aea4"), true)
	for x in [-6.45, -5.15]:
		for z in [-5.25, -4.65]:
			Geometry.box(self, "TableLeg", Vector3(0.05, 0.72, 0.05), Vector3(x, 0.36, z), Color("8d9196"))
	for x in [-6.3, -5.3]:
		var chair := Seat.new()
		chair.name = "TableChair"
		chair.color = Color("5a6f7d")
		chair.position = Vector3(x, 0, -4.15)
		add_child(chair)
		chair.sit_requested.connect(_on_sit_requested)
		table_chairs.append(chair)

## The projection screen shows a live 2D slide rendered in a SubViewport.
func _build_screen() -> void:
	slide_viewport = SubViewport.new()
	slide_viewport.name = "SlideViewport"
	slide_viewport.size = Vector2i(1200, 600)
	slide_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	slide_viewport.disable_3d = true
	add_child(slide_viewport)
	slide = LectureSlide.new()
	slide.size = Vector2(1200, 600)
	slide_viewport.add_child(slide)
	var screen := MeshInstance3D.new()
	screen.name = "LectureDisplay"
	screen.mesh = QuadMesh.new()
	screen.mesh.size = SCREEN_SIZE
	screen.position = SCREEN_CENTER
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = slide_viewport.get_texture()
	screen.material_override = material
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(screen)

## Teaching podium. The professor stands on its −Z side facing the students.
## Monitors sit toward the audience edge with their screens facing the
## professor; keyboard and mouse are at the professor's edge, and a gooseneck
## microphone rises from the professor's right to just below mouth height.
func _build_podium(origin: Vector3) -> void:
	var top_y := 1.05
	Geometry.box(self, "Podium", Vector3(1.2, 1.0, 0.7), origin + Vector3(0, 0.5, 0), Color("3b3f45"), true)
	Geometry.box(self, "PodiumTop", Vector3(1.3, 0.05, 0.8), origin + Vector3(0, top_y - 0.025, 0), Color("c9cbc8"))
	Geometry.box(self, "PodiumPanel", Vector3(1.0, 0.7, 0.02), origin + Vector3(0, 0.5, 0.36), Color("4a4f56"))
	for offset in [-0.29, 0.29]:
		var base := origin + Vector3(offset, top_y, 0.2)
		Geometry.box(self, "MonitorBase", Vector3(0.24, 0.014, 0.17), base + Vector3(0, 0.007, 0), Color("25282c"))
		Geometry.box(self, "MonitorNeck", Vector3(0.05, 0.26, 0.03), base + Vector3(0, 0.14, 0.05), Color("2c3035"))
		Geometry.box(self, "MonitorHinge", Vector3(0.09, 0.05, 0.05), base + Vector3(0, 0.27, 0.03), Color("2c3035"))
		var monitor := Node3D.new()
		monitor.name = "PodiumMonitor"
		monitor.position = base + Vector3(0, 0.36, 0.0)
		monitor.rotation.x = -0.12 # Tilted back, away from the professor.
		add_child(monitor)
		Geometry.box(monitor, "MonitorBezel", Vector3(0.52, 0.32, 0.022), Vector3.ZERO, Color("15181b"))
		Geometry.box(monitor, "MonitorBack", Vector3(0.4, 0.22, 0.03), Vector3(0, -0.01, 0.024), Color("1f2226"))
		var screen := Geometry.box(monitor, "MonitorScreen", Vector3(0.49, 0.28, 0.004), Vector3(0, 0.005, -0.012), Color("2a4f63"))
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color("2a4f63")
		glow.emission_enabled = true
		glow.emission = Color("315f78")
		glow.emission_energy_multiplier = 0.6
		screen.get_child(0).material_override = glow
		Geometry.box(monitor, "SlideThumb", Vector3(0.3, 0.14, 0.002), Vector3(-0.04, 0.02, -0.0145), Color("d98a57"))
	# Keyboard with individual keycaps, and a mouse on a pad.
	var keyboard := origin + Vector3(-0.08, top_y, -0.17)
	Geometry.box(self, "Keyboard", Vector3(0.44, 0.018, 0.15), keyboard + Vector3(0, 0.009, 0), Color("2a2d31"))
	for row in range(4):
		for column in range(13):
			Geometry.box(self, "Key", Vector3(0.026, 0.008, 0.026), keyboard + Vector3(-0.192 + column * 0.032, 0.022, -0.05 + row * 0.032), Color("454a50"))
	Geometry.box(self, "SpaceBar", Vector3(0.18, 0.008, 0.024), keyboard + Vector3(0, 0.022, 0.078), Color("454a50"))
	var pad := origin + Vector3(0.3, top_y, -0.17)
	Geometry.box(self, "MousePad", Vector3(0.21, 0.004, 0.18), pad + Vector3(0, 0.002, 0), Color("1d2024"))
	var mouse := Geometry.sphere(self, Vector3(0.06, 0.035, 0.1), pad + Vector3(0.02, 0.02, 0.01), Color("2e3237"))
	mouse.name = "Mouse"
	Geometry.box(self, "MouseCable", Vector3(0.006, 0.006, 0.12), pad + Vector3(0.02, 0.006, 0.12), Color("1b1d20"))
	# Gooseneck microphone: weighted base, curved neck, capsule with windscreen.
	var mic_base := origin + Vector3(-0.47, top_y, -0.28)
	var puck := Geometry.cylinder_between(self, "MicBase", mic_base, mic_base + Vector3(0, 0.03, 0), 0.04, Color("1f2226"))
	puck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var start := mic_base + Vector3(0, 0.03, 0)
	var control := start + Vector3(0, 0.34, 0.02)
	var tip := start + Vector3(0.05, 0.34, -0.16)
	var previous := start
	for step in range(1, 13):
		var t := step / 12.0
		var point := start.lerp(control, t).lerp(control.lerp(tip, t), t)
		Geometry.cylinder_between(self, "Gooseneck", previous, point, 0.007, Color("2a2d31"))
		previous = point
	var direction := (tip - control).normalized()
	Geometry.cylinder_between(self, "MicCapsule", tip, tip + direction * 0.07, 0.011, Color("33373c"))
	Geometry.cylinder_between(self, "MicRing", tip + direction * 0.005, tip + direction * 0.012, 0.0125, Color("c8433a"))
	var foam := Geometry.sphere(self, Vector3(0.042, 0.05, 0.042), tip + direction * 0.09, Color("202225"))
	foam.name = "MicWindscreen"

func _build_seats() -> void:
	for row in range(TIERS):
		for section in SECTIONS:
			var xs: Array = SECTIONS[section]
			for index in range(xs.size()):
				var x: float = xs[index]
				var key := "%d:%s" % [row, _fmt(x)]
				var seat := Seat.new()
				seat.style = "auditorium"
				seat.color = SEAT_COLOR
				seat.name = "Seat_R%d_%s%d" % [row, section.left(1).to_upper(), index]
				seat.position = Vector3(x, tier_height(row), seat_z(row))
				seat.occupied = CLASSMATES.has(key) or key == ALEX_SEAT
				seat.occupant_preset = CLASSMATES.get(key, "")
				seat.navigator = route_to_seat
				add_child(seat)
				if index == xs.size() - 1:
					seat.add_armrest(Seat.AUDITORIUM_PITCH / 2)
				seats.append(seat)
				if key == ALEX_SEAT:
					alex_seat = seat
					# A jacket over the backrest marks the seat Alex has saved.
					Geometry.box(seat, "SavedJacket", Vector3(0.6, 0.1, 0.16), Vector3(0, 1.0, 0.32), Color("3e5a8a"))
				else:
					seat.sit_requested.connect(_on_sit_requested)
			# Row-end standards, as on fixed auditorium seating.
			for end_x in [xs[0] - Seat.AUDITORIUM_PITCH / 2, xs[xs.size() - 1] + Seat.AUDITORIUM_PITCH / 2]:
				if absf(end_x) > HALF_WIDTH - 0.3:
					continue
				Geometry.box(self, "RowEndPanel", Vector3(0.06, 0.7, 0.62), Vector3(end_x, tier_height(row) + 0.35, seat_z(row) + 0.02), SEAT_COLOR.darkened(0.35))

static func _fmt(value: float) -> String:
	return "%.2f" % value

## Walkway graph: a node in front of every seat, aisle nodes at each landing
## and at both ends of each flight, and a few floor nodes near the entrance.
func _build_navigation() -> void:
	var add := func(point: Vector3) -> int:
		var id := nav.get_available_point_id()
		nav.add_point(id, point)
		return id
	var aisle_nodes := {}
	for aisle in AISLES:
		var previous := -1
		for row in range(TIERS):
			var landing: int = add.call(Vector3(aisle, tier_height(row), walkway_z(row)))
			aisle_nodes["%s:%d" % [aisle, row]] = landing
			if previous >= 0:
				nav.connect_points(previous, landing)
			if row < TIERS - 1:
				var foot: int = add.call(Vector3(aisle, tier_height(row), tier_front(row) + 0.65))
				var head: int = add.call(Vector3(aisle, tier_height(row + 1), tier_front(row) + 1.25))
				nav.connect_points(landing, foot)
				nav.connect_points(foot, head)
				previous = head
		# Floor approach to the bottom of each aisle.
		var bottom: int = add.call(Vector3(aisle, 0, FIRST_TIER_Z - 0.9))
		nav.connect_points(bottom, aisle_nodes["%s:0" % aisle])
		aisle_nodes["%s:bottom" % aisle] = bottom
	var door: int = add.call(Vector3(-HALF_WIDTH + 1.0, 0, DOOR_Z))
	var front_left: int = add.call(Vector3(AISLES[0], 0, DOOR_Z))
	var front_right: int = add.call(Vector3(AISLES[1], 0, -4.4))
	nav.connect_points(door, front_left)
	nav.connect_points(front_left, aisle_nodes["%s:bottom" % AISLES[0]])
	nav.connect_points(aisle_nodes["%s:bottom" % AISLES[0]], front_right)
	nav.connect_points(front_right, aisle_nodes["%s:bottom" % AISLES[1]])
	for row in range(TIERS):
		for section in SECTIONS:
			var row_seats := seats.filter(func(s: Node3D) -> bool: return s.name.begins_with("Seat_R%d_%s" % [row, section.left(1).to_upper()]))
			var previous := -1
			for seat in row_seats:
				var node: int = add.call(seat.point(Seat.FRONT_POINT))
				seat_nodes[seat] = node
				if previous >= 0:
					nav.connect_points(previous, node)
				previous = node
			# Connect section ends to the adjacent aisle landings.
			var first: Node3D = row_seats[0]
			var last: Node3D = row_seats[row_seats.size() - 1]
			for aisle in AISLES:
				var landing: int = aisle_nodes["%s:%d" % [aisle, row]]
				if absf(first.position.x - aisle) < 1.6:
					nav.connect_points(seat_nodes[first], landing)
				if absf(last.position.x - aisle) < 1.6:
					nav.connect_points(seat_nodes[last], landing)

## Path from any standing position to a seat's front point. The first node is
## the nearest graph node on the player's level; nodes already passed are
## dropped so the player never doubles back.
func route_to_seat(from: Vector3, seat: Node3D) -> PackedVector3Array:
	if not seat_nodes.has(seat):
		return PackedVector3Array()
	var best := -1
	var best_distance := INF
	for point_id in nav.get_point_ids():
		var point := nav.get_point_position(point_id)
		if absf(point.y - from.y) > 0.25:
			continue
		var distance := Vector2(point.x - from.x, point.z - from.z).length()
		if distance < best_distance:
			best_distance = distance
			best = point_id
	if best < 0:
		return PackedVector3Array()
	var path := nav.get_point_path(best, seat_nodes[seat])
	while path.size() > 1:
		var ahead := path[1] - path[0]
		var behind := path[0] - from
		ahead.y = 0
		behind.y = 0
		if behind.dot(ahead) < 0.0:
			path.remove_at(0)
		else:
			break
	return path

func _build_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("263c47")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d8d2c6")
	environment.ambient_light_energy = 0.42
	environment_node.environment = environment
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58, -30, 0)
	light.light_energy = 0.5
	light.light_color = Color("ffe9cf")
	Geometry.configure_shadows(light)
	add_child(light)
	for x in [-4.5, 0.8, 5.0]:
		Geometry.accent_light(self, Vector3(x, 3.6, -5.5), Color("fff3dc"), 0.35, 7.0)

func _wood(mesh: MeshInstance3D, color: Color) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/wood.gdshader")
	material.set_shader_parameter("wood_color", color)
	mesh.material_override = material

func _on_sit_requested(seat: Node3D) -> void:
	player.seating.request(seat)

func _on_seating_state(state: int) -> void:
	if state == player.seating.State.SEATED:
		lecture_camera.enter(camera, lecture_pose(player.seating.seat))
	elif state == player.seating.State.RISING:
		lecture_camera.leave()

## Over-the-shoulder view from a seat toward the screen and podium.
func lecture_pose(seat: Node3D) -> Transform3D:
	# Above and behind the student's head, but in front of the heads in the row
	# behind (which start about 1.3 m back), so the view never clips anyone.
	var eye: Vector3 = seat.point(Vector3(0.35, 1.85, 1.15))
	var target := Vector3(0.3, eye.y - 0.35, FRONT_WALL_Z)
	return Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)

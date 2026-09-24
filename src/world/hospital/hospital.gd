extends Node3D
## University Hospital (Milestone 11): the Level 1 atrium and the 4 West
## inpatient unit. Both floors are built in this one scene, side by side
## (the unit 140 m east of the lobby), and a working elevator car carries the
## student between them behind a short fade, so riding up is continuous
## with the shadowing session instead of a scene change.
##
## The builders (hospital_lobby.gd, hospital_unit.gd) lay out geometry in a
## HospitalKit and call back into this scene for everything that is a node:
## doors, signs, people, interactions and named anchors. The shadowing
## session (shadowing_session.gd) drives the physician through the anchors.
signal ride_finished(zone: String)
signal ehr_ready
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const LectureCamera = preload("res://world/lecture_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
const LectureUI = preload("res://ui/lecture_ui.gd")
const Kit = preload("res://world/hospital/hospital_kit.gd")
const Lobby = preload("res://world/hospital/hospital_lobby.gd")
const Unit = preload("res://world/hospital/hospital_unit.gd")
const Props = preload("res://world/hospital/hospital_props.gd")
const SlidingDoors = preload("res://world/hospital/sliding_doors.gd")
const Physician = preload("res://npc/physician.gd")
const Session = preload("res://world/hospital/shadowing_session.gd")
const EHRChart = preload("res://ui/ehr_chart.gd")
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
const Nameplate = preload("res://ui/world_nameplate.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const Flora = preload("res://world/campus/flora.gd")
const Pedestrian = preload("res://npc/ambient/pedestrian.gd")
const UNIT_OFFSET := Vector3(140, 0, 0)
## Per floor: HUD location, camera framing and follow bounds (world x, z).
const ZONES := {
	"lobby": {"title": "University Hospital · Level 1 Lobby", "min": Vector2(-11, -9.5), "max": Vector2(11, 6.5), "view": 19.5},
	"unit": {"title": "University Hospital · Level 4 · 4 West", "min": Vector2(137, -2.5), "max": Vector2(172, 3.0), "view": 15.5},
}
## Lobby visitors stroll this graph (x, z): around the Information desk, to the lifts and the café.
const VISITOR_NODES := [Vector2(0, 7.0), Vector2(3.8, 3.2), Vector2(3.8, -5.0), Vector2(0, -9.5), Vector2(-3.8, -5.6), Vector2(-3.4, 1.8), Vector2(8.2, -2.0), Vector2(8.5, -9.5)]
const VISITOR_EDGES := [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0], [1, 6], [6, 2], [6, 7], [7, 3]]
const EHR_FOV := 40.0
## Share of the view's height the EHR screen fills when zoomed in.
const EHR_FILL := 0.6
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var lecture_ui: CanvasLayer
var session: Node
var physician: Node3D
var zone := "lobby"
## Named points (world positions) used by the shadowing script.
var anchors := {}
## Interactions the script can name as action targets (dispensers, people).
var targets := {}
var fp_nodes: Array[Node3D] = []
var tp_nodes: Array[Node3D] = []
## [first-person mesh, cutaway mesh] per floor.
var layers: Array = []
var entrance_doors: Node3D
var lobby_elevator: Node3D
var unit_elevator: Node3D
var charge_nurse: Node3D
var exit_door: Node3D
var elevator_calls := {}
var figures: Array[Node3D] = []
var visitors: Array[Node3D] = []
## Elevator state: a pending destination while the doors wait for the student.
var ride_to := ""
var ride_companion: Node3D
var ride_timer := 0.0
var riding := false
var close_timers := {"lobby": 0.0, "unit": 0.0}
var marker: MeshInstance3D
## The workroom's EHR workstation screen and the close-up camera.
var ehr_screen: MeshInstance3D
var ehr_viewport: SubViewport
var ehr_chart: Control
var ehr_camera: Camera3D
var ehr_open := false

func _ready() -> void:
	player = Player.instantiate()
	var lobby := Kit.new(Vector3.ZERO)
	Lobby.build(self, lobby)
	layers.append(lobby.commit(self, "Lobby"))
	var unit := Kit.new(UNIT_OFFSET)
	Unit.build(self, unit)
	layers.append(unit.commit(self, "Unit"))
	_build_lighting()
	# One slab under both floors: the floor finishes are visual only.
	var ground := StaticBody3D.new()
	ground.name = "FloorCollision"
	var slab := CollisionShape3D.new()
	slab.shape = BoxShape3D.new()
	slab.shape.size = Vector3(260, 1, 120)
	slab.position = Vector3(UNIT_OFFSET.x / 2.0, -0.5, 0)
	ground.add_child(slab)
	add_child(ground)
	marker = ring(0.42, Color("5ec8b5"))
	marker.name = "StandMarker"
	marker.visible = false
	add_child(marker)
	exit_door = add_endpoint("CampusExit", "Leave for campus", "", Vector3(0, 1.0, 9.1), 1.7)
	exit_door.activated.connect(AppState.enter_campus.bind("hospital"))
	player.position = anchors.entrance + Vector3(0, 0.05, 0)
	add_child(player)
	camera = Camera.new()
	camera.view_size = ZONES.lobby.view
	camera.follow_min = ZONES.lobby.min
	camera.follow_max = ZONES.lobby.max
	add_child(camera)
	camera.follow(player)
	player.movement_camera = camera
	_build_visitors()
	hud = HUD.new()
	add_child(hud)
	hud.bind_player(player)
	lecture_ui = LectureUI.new()
	add_child(lecture_ui)
	physician = Physician.new()
	physician.name = "DrOkafor"
	add_child(physician)
	physician.companion = player
	physician.place(anchors.info_desk, PI)
	session = Session.new()
	session.name = "ShadowingSession"
	add_child(session)
	session.setup(self, lecture_ui, physician)
	AppState.view_changed.connect(apply_view)
	apply_view(AppState.first_person)
	_update_zone(true)

## First person shows the whole building (ceilings, full-height walls, high
## signs); the overhead view shows the cutaway.
func apply_view(first_person: bool) -> void:
	for pair in layers:
		pair[0].visible = first_person
		pair[1].visible = not first_person
	for node in fp_nodes:
		node.visible = first_person
	for node in tp_nodes:
		node.visible = not first_person

func anchor(id: String) -> Vector3:
	return anchors.get(id, Vector3.INF)

func zone_of(point: Vector3) -> String:
	return "unit" if point.x > UNIT_OFFSET.x / 2.0 else "lobby"

func _process(delta: float) -> void:
	_update_zone()
	_update_elevators(delta)

func _update_zone(force := false) -> void:
	var now := zone_of(player.global_position)
	if now == zone and not force:
		return
	zone = now
	var framing: Dictionary = ZONES[zone]
	camera.size = framing.view
	camera.view_size = framing.view
	camera.follow_min = framing.min
	camera.follow_max = framing.max
	camera.follow(player)
	hud.set_location(framing.title)

# --- Builder API --------------------------------------------------------------------------

func set_anchor(id: String, point: Vector3) -> void:
	anchors[id] = point

func player_target() -> Node3D:
	return player

func add_fp_node(node: Node3D) -> void:
	fp_nodes.append(node)

func _layered(node: Node3D, layer: Variant) -> void:
	if typeof(layer) == TYPE_BOOL:
		layer = "fp" if layer else "always"
	if layer == "fp":
		fp_nodes.append(node)
	elif layer == "tp":
		tp_nodes.append(node)

## Sliding door pair; `pos` is the doorway centre on the floor, the leaves slide along local X.
func add_doors(node_name: String, pos: Vector3, yaw: float, width: float, height: float, glazed: bool) -> Node3D:
	var doors := SlidingDoors.new(width, height, glazed)
	doors.name = node_name
	doors.position = pos
	doors.rotation.y = yaw
	add_child(doors)
	return doors

## A sign mounted flat on a surface (see Geometry.wall_sign). `layer`: "always",
## "fp" (first person only, e.g. on a cutaway wall) or "tp"; true/false mean fp/always.
func add_sign(text: String, pos: Vector3, yaw: float, font_size := 24, pixel := 0.006, layer: Variant = "always", plate := Color.TRANSPARENT, ink := Color.TRANSPARENT) -> Label3D:
	var sign := Nameplate.new()
	sign.mounted = true
	sign.text = text
	sign.font_size = font_size
	sign.pixel_size = pixel
	sign.rotation.y = yaw
	sign.position = pos + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.02)
	if plate.a > 0.0:
		sign.plate_color = plate
	if ink.a > 0.0:
		sign.text_color = ink
	add_child(sign)
	_layered(sign, layer)
	return sign

## Wayfinding text on the floor in front of a door, readable from the corridor.
func add_floor_label(text: String, pos: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = Nameplate.FONT
	label.font_size = 64
	label.pixel_size = 0.0036
	label.modulate = Color(0.36, 0.42, 0.45, 0.75)
	label.outline_size = 0
	label.rotation = Vector3(-PI / 2, 0, 0)
	label.position = pos
	label.shaded = false
	add_child(label)
	return label

func add_letters(text: String, pos: Vector3, yaw: float, height: float) -> void:
	Buildings.letters(self, text, pos, yaw, height, Color("3a4247"), 0.05)

## Floor number on an elevator's indicator screen (amber, no plate).
func add_indicator(pos: Vector3, text: String, yaw := 0.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = Nameplate.FONT
	label.font_size = 48
	label.pixel_size = 0.0022
	label.modulate = Color("f6c65b")
	label.outline_size = 0
	label.shaded = false
	label.rotation.y = yaw
	label.position = pos + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.02)
	add_child(label)

## The call point for the working car on a floor: rides to `to_zone`. A panel
## inside the car does the same, so the student can also ride from inside.
func add_elevator_call(node_name: String, pos: Vector3, to_zone: String) -> void:
	var here := zone_of(pos)
	var title := "Take the elevator to Level 4 · 4 West" if to_zone == "unit" else "Take the elevator to Level 1 · Lobby"
	var call_point := add_endpoint(node_name, title, "", pos, 2.0)
	call_point.activated.connect(_on_elevator_requested.bind(to_zone))
	var panel := add_endpoint(node_name + "Panel", title, "", cab_centre(here) + cab_basis(here) * Vector3(-0.85, 1.2, 0.85), 1.5)
	panel.activated.connect(_on_elevator_requested.bind(to_zone))
	elevator_calls[here] = [call_point, panel]

## A standing, seated or bedbound figure. `who` is a preset id or a full look.
## Seated figures take the seat height; bedbound ones are placed by the hip.
func add_figure(who: Variant, pos: Vector3, yaw: float, pose := "stand", seat_top := Props.ARMCHAIR_SEAT) -> Node3D:
	var figure := Node3D.new()
	figure.name = "Figure"
	var look := Appearance.new()
	look.name = "Appearance"
	figure.add_child(look)
	add_child(figure)
	if typeof(who) == TYPE_STRING:
		look.apply_preset(who)
	else:
		look.apply_look(who)
	match pose:
		"seated":
			look.set_seated(true)
			# Hips on the cushion, a little back toward the backrest (as on the campus benches).
			figure.position = pos + Vector3(0, seat_top - 0.28, 0) + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.06)
			figure.rotation.y = yaw
		"bed":
			# Pivot at the hip: recline the torso onto the raised head section
			# and bend at the hips so the legs lie flat under the blanket.
			figure.position = pos
			figure.rotation = Vector3(PI / 2.0 - Props.BED_TILT, yaw, 0)
			look.position.y = -Appearance.HIP_HEIGHT * look.height_scale
			for index in range(2):
				look.hips[index].rotation.x = Props.BED_TILT
				look.knees[index].rotation.x = 0.0
				look.shoulders[index].rotation = Vector3(0.25, 0, 0.12 * (1 if index else -1))
		_:
			figure.position = pos
			figure.rotation.y = yaw
			Student.make_blocker(figure)
	figures.append(figure)
	return figure

func add_endpoint(node_name: String, title: String, response: String, pos: Vector3, reach := 1.55) -> Node3D:
	var endpoint := Endpoint.new()
	endpoint.name = node_name
	endpoint.display_name = title
	endpoint.response = response
	endpoint.reach = reach
	endpoint.position = pos
	add_child(endpoint)
	return endpoint

## A hand-sanitizer dispenser the student can use; `id` names it for the script.
func add_dispenser(id: String, pos: Vector3) -> Node3D:
	var endpoint := add_endpoint("Dispenser_" + id, "Clean your hands", "Alcohol foam, rubbed in until your hands are dry.", pos, 1.6)
	targets[id] = endpoint
	return endpoint

func add_tree(pos: Vector3, scale: float) -> void:
	Flora.plant(self, "ornamental", [[pos, scale, pos.x * 1.7]], false)

func add_shrubs(pos: Vector3, size: float) -> void:
	var placements := []
	for index in range(4):
		var angle := TAU * index / 4.0 + 0.6
		placements.append([pos + Vector3(cos(angle), 0, sin(angle)) * size * 0.26, 0.42, angle])
	Flora.plant(self, "shrub", placements, false)

## The EHR workstation's screen: a quad showing the chart drawn in a viewport.
func add_ehr_screen(pos: Vector3, yaw: float, screen_size: Vector2) -> void:
	ehr_viewport = SubViewport.new()
	ehr_viewport.name = "EHRViewport"
	ehr_viewport.size = Vector2i(EHRChart.SIZE)
	ehr_viewport.disable_3d = true
	ehr_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(ehr_viewport)
	ehr_chart = EHRChart.new()
	ehr_viewport.add_child(ehr_chart)
	ehr_screen = MeshInstance3D.new()
	ehr_screen.name = "EHRScreen"
	ehr_screen.mesh = QuadMesh.new()
	ehr_screen.mesh.size = screen_size
	ehr_screen.position = pos
	ehr_screen.rotation.y = yaw
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = ehr_viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ehr_screen.material_override = material
	ehr_screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ehr_screen)

## A flat ring on the floor: the physician's guide ring and the "stand here" marker.
static func ring(radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.05
	mesh.outer_radius = radius
	mesh.rings = 32
	mesh.ring_segments = 6
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.scale = Vector3(1, 0.15, 1)
	instance.position.y = 0.02
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

func show_marker(point: Vector3) -> void:
	marker.position = Vector3(point.x, 0.02, point.z)
	marker.visible = true

func hide_marker() -> void:
	marker.visible = false

# --- Elevators ----------------------------------------------------------------------------

func elevator_doors(zone_name: String) -> Node3D:
	return lobby_elevator if zone_name == "lobby" else unit_elevator

func cab_rect(zone_name: String) -> Rect2:
	if zone_name == "lobby":
		return Lobby.CAB
	return Rect2(Unit.CAB.position + Vector2(UNIT_OFFSET.x, UNIT_OFFSET.z), Unit.CAB.size)

func cab_centre(zone_name: String) -> Vector3:
	var rect := cab_rect(zone_name)
	return Vector3(rect.get_center().x, 0, rect.get_center().y)

## The car's frame: local +Z points out through its doors.
func cab_basis(zone_name: String) -> Basis:
	return Basis.IDENTITY if zone_name == "lobby" else Basis(Vector3.UP, PI / 2)

func in_cab(node: Node3D, zone_name := "") -> bool:
	var point := node.global_position
	return cab_rect(zone_of(point) if zone_name.is_empty() else zone_name).has_point(Vector2(point.x, point.z))

## Free rides are allowed except while the session is guiding the student.
func _on_elevator_requested(to_zone: String) -> void:
	if riding or not ride_to.is_empty():
		return
	if not session.allows_free_ride():
		hud.show_message("Stay with Dr. Okafor; she'll take you up.", 4.0)
		return
	call_elevator(to_zone)
	hud.show_message("Step into the elevator.", 3.0)

## Opens the car on the student's floor and rides to `to_zone` once they step
## in (with `companion` too, if given, once they have walked in).
func call_elevator(to_zone: String, companion: Node3D = null) -> void:
	if riding:
		return
	ride_to = to_zone
	ride_companion = companion
	ride_timer = 14.0
	elevator_doors(zone).open()

func _update_elevators(delta: float) -> void:
	if riding:
		return
	if not ride_to.is_empty():
		var doors := elevator_doors(zone)
		var companion_in: bool = ride_companion == null or (in_cab(ride_companion, zone) and not ride_companion.walking)
		if in_cab(player, zone) and doors.is_open() and companion_in:
			_ride()
		elif ride_companion == null and not in_cab(player, zone):
			ride_timer -= delta
			if ride_timer <= 0.0:
				ride_to = ""
		return
	# Doors left open (after arriving) close once everyone is clear of the car.
	for zone_name in ["lobby", "unit"]:
		var doors := elevator_doors(zone_name)
		if doors.is_closed() or doors.target_open == 0.0:
			continue
		var clear := not in_cab(player, zone_name) and player.global_position.distance_to(doors.global_position) > 1.4
		if is_instance_valid(physician) and (in_cab(physician, zone_name) or physician.global_position.distance_to(doors.global_position) < 1.0):
			clear = false
		close_timers[zone_name] = close_timers[zone_name] + delta if clear else 0.0
		if close_timers[zone_name] > 2.5:
			doors.close()
			close_timers[zone_name] = 0.0

func _ride() -> void:
	riding = true
	var from := zone
	var to := ride_to
	var companion := ride_companion
	ride_to = ""
	ride_companion = null
	player.movement_enabled = false
	var doors := elevator_doors(from)
	doors.close()
	while not doors.is_closed():
		await get_tree().process_frame
	await Transition.cover()
	var turn := cab_basis(to) * cab_basis(from).inverse()
	var yaw := turn.get_euler().y
	var offset := player.global_position - cab_centre(from)
	offset.y = 0.0
	player.global_position = cab_centre(to) + turn * offset + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.appearance.rotation.y += yaw
	player.first_person.yaw = wrapf(player.first_person.yaw + yaw, -PI, PI)
	player.first_person.current_eye = player.first_person.eye_target()
	player.first_person.previous_eye = player.first_person.current_eye
	if is_instance_valid(companion):
		var along := companion.global_position - cab_centre(from)
		along.y = 0.0
		companion.place(cab_centre(to) + turn * along, companion.appearance.rotation.y + yaw)
	var arriving := elevator_doors(to)
	arriving.set_open_now(false)
	_update_zone(true)
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.45).timeout
	Transition.reveal()
	arriving.open()
	close_timers[to] = 0.0
	riding = false
	player.movement_enabled = true
	ride_finished.emit(to)

# --- EHR close-up -------------------------------------------------------------------------

## Eases the view in to the workstation screen, leaving room below it for the dialogue card.
func open_ehr() -> void:
	if ehr_open:
		return
	ehr_open = true
	ehr_chart.reset()
	var source := get_viewport().get_camera_3d()
	ehr_camera = LectureCamera.new()
	ehr_camera.name = "EHRCamera"
	ehr_camera.target_fov = EHR_FOV
	ehr_camera.arc_height = 0.0
	ehr_camera.duration = 0.001 if DisplayServer.get_name() == "headless" else 0.9
	add_child(ehr_camera)
	var pose := ehr_pose()
	ehr_camera.focus_distance = pose.origin.distance_to(ehr_screen.global_position)
	ehr_camera.transition_finished.connect(_on_ehr_camera)
	ehr_camera.enter(source, pose)
	player.appearance.visible = false

func close_ehr() -> void:
	if not ehr_open:
		return
	ehr_open = false
	ehr_chart.reset()
	if is_instance_valid(ehr_camera):
		ehr_camera.leave()

func _on_ehr_camera(entered: bool) -> void:
	if entered:
		ehr_ready.emit()
		return
	player.appearance.visible = true
	if is_instance_valid(ehr_camera):
		ehr_camera.queue_free()
	ehr_camera = null

func ehr_view_ready() -> bool:
	return ehr_open and is_instance_valid(ehr_camera) and ehr_camera.in_lecture_view()

## Square to the screen, far enough that it fills EHR_FILL of the view, and
## aimed a little below it so the screen sits above the dialogue card.
func ehr_pose() -> Transform3D:
	var quad := ehr_screen.mesh as QuadMesh
	var basis := ehr_screen.global_basis
	var normal := basis.z.normalized()
	var up := basis.y.normalized()
	var center := ehr_screen.global_position
	var distance := quad.size.y / (2.0 * tan(deg_to_rad(EHR_FOV) / 2.0) * EHR_FILL)
	var eye := center + normal * distance
	var aim := center - up * distance * tan(deg_to_rad(EHR_FOV) / 2.0) * 0.1
	return Transform3D(Basis.looking_at(aim - eye, Vector3.UP), eye)

# --- Light and life -------------------------------------------------------------------------

func _build_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("24343c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e4e6e2")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.04
	environment_node.environment = environment
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.name = "Daylight"
	light.rotation_degrees = Vector3(-58, -32, 0)
	light.light_energy = 0.5
	light.light_color = Color("fff6ec")
	Geometry.configure_shadows(light)
	add_child(light)
	# Warm fill under the atrium skylight and along the unit corridor (first person).
	for point in [Vector3(0, 7.5, -3), Vector3(-9, 4, 2), Vector3(9, 4, -4)]:
		var fill := OmniLight3D.new()
		fill.position = point
		fill.omni_range = 14.0
		fill.light_energy = 0.35
		fill.light_color = Color("fff4e4")
		add_child(fill)
		fp_nodes.append(fill)
	for x in [4.0, 16.0, 28.0]:
		var fill := OmniLight3D.new()
		fill.position = UNIT_OFFSET + Vector3(x, 2.6, 0.5)
		fill.omni_range = 9.0
		fill.light_energy = 0.3
		fill.light_color = Color("fff6ea")
		add_child(fill)
		fp_nodes.append(fill)

## A few visitors crossing the atrium (the campus passer-by, on a lobby graph).
func _build_visitors() -> void:
	var keep_clear := [[Vector2(0, -1.8), 2.6], [Vector2(-7.4, -1.6), 1.8], [Vector2(-7.6, 3.4), 2.8], [Vector2(5.6, 5.8), 1.2]]
	for index in range(3):
		var walker := Pedestrian.new()
		walker.name = "Visitor"
		walker.nodes = VISITOR_NODES
		walker.edges = VISITOR_EDGES
		add_child(walker)
		walker.setup("", player, keep_clear)
		visitors.append(walker)

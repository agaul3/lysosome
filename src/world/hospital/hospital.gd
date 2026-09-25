extends Node3D
## University Hospital: the Level 1 atrium and the 4 West inpatient unit
## (Milestone 11), and the Emergency Department with Emergency Radiology on
## its second level. Every floor is built in this one scene, far apart (the
## unit 140 m east of the lobby, the ED 140 m west, radiology 140 m north),
## and working elevator cars and staff doors carry the student between them
## behind a short fade, so moving through the building needs no scene change.
## Only the floor the student is on is shown.
##
## The builders (hospital_lobby.gd, hospital_unit.gd, hospital_ed.gd,
## hospital_imaging.gd) lay out geometry in a HospitalKit and call back into
## this scene for everything that is a node: doors, signs, people, screens,
## interactions and named anchors. The shadowing session
## (shadowing_session.gd) drives the physician through the anchors;
## ed_life.gd keeps the Emergency Department busy.
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
const ED = preload("res://world/hospital/hospital_ed.gd")
const Imaging = preload("res://world/hospital/hospital_imaging.gd")
const EDLife = preload("res://world/hospital/ed_life.gd")
const EDDisplay = preload("res://ui/ed_display.gd")
const VitalsAtlas = preload("res://ui/vitals_atlas.gd")
const RadiologyImages = preload("res://ui/radiology_images.gd")
const UNIT_OFFSET := Vector3(140, 0, 0)
const ED_OFFSET := ED.ORIGIN
const IMAGING_OFFSET := Vector3(0, 0, -140)
## Per floor: HUD location, camera framing and follow bounds (world x, z).
const ZONES := {
	"lobby": {"title": "University Hospital · Level 1 Lobby", "min": Vector2(-11, -9.5), "max": Vector2(11, 6.5), "view": 19.5},
	"unit": {"title": "University Hospital · Level 4 · 4 West", "min": Vector2(137, -2.5), "max": Vector2(172, 3.0), "view": 15.5},
	"ed": {"title": "University Hospital · Emergency Department", "min": Vector2(-169, -12.0), "max": Vector2(-111, 20.0), "view": 20.0},
	"imaging": {"title": "University Hospital · Level 2 · Emergency Radiology", "min": Vector2(-17, -149.0), "max": Vector2(17, -131.0), "view": 17.0},
}
## Which floor each floor's working elevator car goes to.
const ELEVATOR_ROUTES := {"lobby": "unit", "unit": "lobby", "ed": "imaging", "imaging": "ed"}
const ELEVATOR_TITLES := {
	"unit": "Take the elevator to Level 4 · 4 West",
	"lobby": "Take the elevator to Level 1 · Lobby",
	"imaging": "Take the elevator to Level 2 · Emergency Radiology",
	"ed": "Take the elevator to Level 1 · Emergency Department",
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
var ed_elevator: Node3D
var imaging_elevator: Node3D
## One root per floor; only the student's floor is shown.
var zone_roots := {}
## Where builders put the nodes they add (the root of the floor being built).
var build_root: Node3D
## Busy life in the Emergency Department (EMS crews, walk-ins, boards).
var ed_life: Node
var ed_exit: Node3D
var lobby_to_ed: Node3D
var ed_to_lobby: Node3D
## What the ED builder hands the life simulation: bays, seats, doors, routes.
var ed_layout := {}
var imaging_layout := {}
## Shared live displays (one viewport each, shown on many screens).
var displays := {}
var display_viewports := {}
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
var close_timers := {"lobby": 0.0, "unit": 0.0, "ed": 0.0, "imaging": 0.0}
var marker: MeshInstance3D
## The workroom's EHR workstation screen and the close-up camera.
var ehr_screen: MeshInstance3D
var ehr_viewport: SubViewport
var ehr_chart: Control
var ehr_camera: Camera3D
var ehr_open := false

func _ready() -> void:
	player = Player.instantiate()
	for zone_name in ["lobby", "unit", "ed", "imaging"]:
		var root := Node3D.new()
		root.name = zone_name.capitalize() + "Floor"
		add_child(root)
		zone_roots[zone_name] = root
	_build_floor("lobby", Lobby, Vector3.ZERO, "Lobby")
	_build_floor("unit", Unit, UNIT_OFFSET, "Unit")
	_build_floor("ed", ED, ED_OFFSET, "EmergencyDepartment")
	_build_floor("imaging", Imaging, IMAGING_OFFSET, "EmergencyRadiology")
	build_root = self
	_build_lighting()
	# Floor slabs: the floor finishes are visual only.
	_floor_slab(Vector3(UNIT_OFFSET.x / 2.0, -0.5, 0), Vector3(260, 1, 120))
	_floor_slab(ED_OFFSET + Vector3(0, -0.5, 8), Vector3(170, 1, 90))
	_floor_slab(IMAGING_OFFSET + Vector3(0, -0.5, 0), Vector3(70, 1, 50))
	marker = ring(0.42, Color("5ec8b5"))
	marker.name = "StandMarker"
	marker.visible = false
	add_child(marker)
	exit_door = add_endpoint("CampusExit", "Leave for campus", "", Vector3(0, 1.0, 9.1), 1.7)
	exit_door.activated.connect(AppState.enter_campus.bind("hospital"))
	ed_exit = add_endpoint("EmergencyExit", "Leave for campus", "", anchors.ed_exit, 1.7)
	ed_exit.activated.connect(AppState.enter_campus.bind("ed"))
	# Staff doors between the atrium's west corridor and the Emergency Department.
	lobby_to_ed = add_endpoint("LobbyToED", "Go to the Emergency Department", "", Vector3(-29.2, 1.0, -10.5), 1.7)
	lobby_to_ed.activated.connect(_on_transfer.bind(anchors.ed_from_lobby, PI / 2))
	ed_to_lobby = add_endpoint("EDToLobby", "Go to the main hospital · Atrium", "", anchors.ed_link_door, 1.7)
	ed_to_lobby.activated.connect(_on_transfer.bind(Vector3(-28.0, 0, -10.5), -PI / 2))
	var arrival: Vector3 = anchors.ed_entrance if AppState.hospital_entry == "ed" else anchors.entrance
	player.position = arrival + Vector3(0, 0.05, 0)
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
	ed_life = EDLife.new()
	ed_life.name = "EDLife"
	add_child(ed_life)
	ed_life.setup(self)
	AppState.view_changed.connect(apply_view)
	apply_view(AppState.first_person)
	_update_zone(true)

## Builds one floor into its root with a HospitalKit at `origin`.
func _build_floor(zone_name: String, builder: Variant, origin: Vector3, label: String) -> void:
	build_root = zone_roots[zone_name]
	var kit := Kit.new(origin)
	builder.build(self, kit)
	layers.append(kit.commit(build_root, label))

func _floor_slab(center: Vector3, size: Vector3) -> void:
	var ground := StaticBody3D.new()
	ground.name = "FloorCollision"
	var slab := CollisionShape3D.new()
	slab.shape = BoxShape3D.new()
	slab.shape.size = size
	slab.position = center
	ground.add_child(slab)
	add_child(ground)

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
	if point.x > UNIT_OFFSET.x / 2.0:
		return "unit"
	if point.x < ED_OFFSET.x / 2.0:
		return "ed"
	if point.z < IMAGING_OFFSET.z / 2.0:
		return "imaging"
	return "lobby"

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
	for zone_name in zone_roots:
		zone_roots[zone_name].visible = zone_name == zone
	# The ED's live displays only render while the student is there to see them.
	for mode in display_viewports:
		if mode != "radiology":
			display_viewports[mode].render_target_update_mode = SubViewport.UPDATE_ALWAYS if zone in ["ed", "imaging"] else SubViewport.UPDATE_DISABLED
	# A save made here resumes at the entrance of this part of the hospital.
	AppState.hospital_entry = "ed" if zone in ["ed", "imaging"] else "main"

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
func add_doors(node_name: String, pos: Vector3, yaw: float, width: float, height: float, glazed: bool, frame := Color("3a4045")) -> Node3D:
	var doors := SlidingDoors.new(width, height, glazed)
	doors.frame_color = frame
	doors.name = node_name
	doors.position = pos
	doors.rotation.y = yaw
	build_root.add_child(doors)
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
	build_root.add_child(sign)
	_layered(sign, layer)
	return sign

## Wayfinding text on the floor in front of a door, readable from the corridor.
func add_floor_label(text: String, pos: Vector3, pixel := 0.0036) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = Nameplate.FONT
	label.font_size = 64
	label.pixel_size = pixel
	label.modulate = Color(0.36, 0.42, 0.45, 0.75)
	label.outline_size = 0
	label.rotation = Vector3(-PI / 2, 0, 0)
	label.position = pos
	label.shaded = false
	build_root.add_child(label)
	return label

func add_letters(text: String, pos: Vector3, yaw: float, height: float) -> void:
	Buildings.letters(build_root, text, pos, yaw, height, Color("3a4247"), 0.05)

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
	build_root.add_child(label)

## The call point for the working car on a floor: rides to `to_zone`. A panel
## inside the car does the same, so the student can also ride from inside.
func add_elevator_call(node_name: String, pos: Vector3, to_zone: String) -> void:
	var here := zone_of(pos)
	var title: String = ELEVATOR_TITLES[to_zone]
	var call_point := add_endpoint(node_name, title, "", pos, 2.0)
	call_point.activated.connect(_on_elevator_requested.bind(to_zone))
	var panel := add_endpoint(node_name + "Panel", title, "", cab_centre(here) + cab_basis(here) * Vector3(-0.85, 1.2, 0.85), 1.5)
	panel.activated.connect(_on_elevator_requested.bind(to_zone))
	elevator_calls[here] = [call_point, panel]

## A standing, seated or bedbound figure. `who` is a preset id or a full look.
## Seated figures take the seat height; bedbound ones are placed by the hip.
func add_figure(who: Variant, pos: Vector3, yaw: float, pose := "stand", seat_top := Props.ARMCHAIR_SEAT, tilt := Props.BED_TILT) -> Node3D:
	var figure := Node3D.new()
	figure.name = "Figure"
	var look := Appearance.new()
	look.name = "Appearance"
	figure.add_child(look)
	build_root.add_child(figure)
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
			# (tilt 0 lies flat) and bend at the hips so the legs lie flat.
			figure.position = pos
			Props.lay(figure, look, tilt, yaw)
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
	build_root.add_child(endpoint)
	return endpoint

## A hand-sanitizer dispenser the student can use; `id` names it for the script.
func add_dispenser(id: String, pos: Vector3) -> Node3D:
	var endpoint := add_endpoint("Dispenser_" + id, "Clean your hands", "Alcohol foam, rubbed in until your hands are dry.", pos, 1.6)
	targets[id] = endpoint
	return endpoint

func add_tree(pos: Vector3, scale: float) -> void:
	Flora.plant(build_root, "ornamental", [[pos, scale, pos.x * 1.7]], false)

func add_shrubs(pos: Vector3, size: float) -> void:
	var placements := []
	for index in range(4):
		var angle := TAU * index / 4.0 + 0.6
		placements.append([pos + Vector3(cos(angle), 0, sin(angle)) * size * 0.26, 0.42, angle])
	Flora.plant(build_root, "shrub", placements, false)

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
	build_root.add_child(ehr_screen)

## An empty node on the current floor for a moving prop (a scanner tabletop).
func add_prop_node(node_name: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = pos
	node.rotation.y = yaw
	build_root.add_child(node)
	return node

## A plain box as its own node (a blanket that comes and goes with a patient).
func add_box_node(node_name: String, center: Vector3, size: Vector3, color: Color, yaw := 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.position = center
	mesh.rotation.y = yaw
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material_override = material
	build_root.add_child(mesh)
	return mesh

## The texture of a shared ED display ("tracking", "trauma", "waiting").
func board_texture(mode: String) -> Texture2D:
	if not displays.has(mode):
		var display := EDDisplay.new(mode)
		displays[mode] = display
		display_viewports[mode] = add_board("Display_" + mode, display, Vector2i(EDDisplay.SIZE))
	return display_viewports[mode].get_texture()

## The bedside monitors' atlas (each screen shows one tile).
func vitals_texture() -> Texture2D:
	if not displays.has("vitals"):
		var atlas := VitalsAtlas.new()
		displays["vitals"] = atlas
		display_viewports["vitals"] = add_board("VitalsAtlas", atlas, Vector2i(VitalsAtlas.SIZE))
	return display_viewports["vitals"].get_texture()

## Schematic radiology images (drawn once).
func radiology_texture() -> Texture2D:
	if not displays.has("radiology"):
		var images := RadiologyImages.new()
		displays["radiology"] = images
		var viewport := add_board("RadiologyImages", images, Vector2i(RadiologyImages.SIZE))
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		display_viewports["radiology"] = viewport
	return display_viewports["radiology"].get_texture()

## A live display: a Control drawn into its own viewport (boards, monitors).
## Returns the viewport; use its texture on one or more screens.
func add_board(node_name: String, control: Control, size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = node_name
	viewport.size = size
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	viewport.add_child(control)
	return viewport

## A screen showing `texture` (optionally one tile of it) facing +Z rotated by yaw.
func add_screen(texture: Texture2D, pos: Vector3, yaw: float, screen_size: Vector2, tile := Rect2(0, 0, 1, 1), layer: Variant = "always") -> MeshInstance3D:
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	screen.mesh = QuadMesh.new()
	screen.mesh.size = screen_size
	screen.position = pos + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.004)
	screen.rotation.y = yaw
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.uv1_scale = Vector3(tile.size.x, tile.size.y, 1)
	material.uv1_offset = Vector3(tile.position.x, tile.position.y, 0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	screen.material_override = material
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	build_root.add_child(screen)
	_layered(screen, layer)
	return screen

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
	return {"lobby": lobby_elevator, "unit": unit_elevator, "ed": ed_elevator, "imaging": imaging_elevator}[zone_name]

func cab_rect(zone_name: String) -> Rect2:
	match zone_name:
		"lobby":
			return Lobby.CAB
		"unit":
			return Rect2(Unit.CAB.position + Vector2(UNIT_OFFSET.x, UNIT_OFFSET.z), Unit.CAB.size)
		"ed":
			return Rect2(ED.CAB.position + Vector2(ED_OFFSET.x, ED_OFFSET.z), ED.CAB.size)
	return Rect2(Imaging.CAB.position + Vector2(IMAGING_OFFSET.x, IMAGING_OFFSET.z), Imaging.CAB.size)

func cab_centre(zone_name: String) -> Vector3:
	var rect := cab_rect(zone_name)
	return Vector3(rect.get_center().x, 0, rect.get_center().y)

## The car's frame: local +Z points out through its doors.
func cab_basis(zone_name: String) -> Basis:
	match zone_name:
		"lobby":
			return Basis.IDENTITY
		"unit":
			return Basis(Vector3.UP, PI / 2)
	return Basis(Vector3.UP, PI) # ED and radiology cars open to the north.

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
	for zone_name in ["lobby", "unit", "ed", "imaging"]:
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

## Staff doors between floors (the atrium's west corridor and the ED): a fade
## and a step through, like the elevator. Not while the session is guiding.
func _on_transfer(to_point: Vector3, yaw: float) -> void:
	if riding:
		return
	if not session.allows_free_ride():
		hud.show_message("Stay with Dr. Okafor for now.", 4.0)
		return
	transfer(to_point, yaw)

func transfer(to_point: Vector3, yaw: float) -> void:
	riding = true
	player.movement_enabled = false
	await Transition.cover()
	player.global_position = to_point + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.appearance.rotation.y = yaw
	player.first_person.yaw = yaw
	player.first_person.current_eye = player.first_person.eye_target()
	player.first_person.previous_eye = player.first_person.current_eye
	_update_zone(true)
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.25).timeout
	Transition.reveal()
	riding = false
	player.movement_enabled = true

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
		zone_roots.lobby.add_child(fill)
		fp_nodes.append(fill)
	for x in [4.0, 16.0, 28.0]:
		var fill := OmniLight3D.new()
		fill.position = UNIT_OFFSET + Vector3(x, 2.6, 0.5)
		fill.omni_range = 9.0
		fill.light_energy = 0.3
		fill.light_color = Color("fff6ea")
		zone_roots.unit.add_child(fill)
		fp_nodes.append(fill)
	# The Emergency Department and radiology: cooler, even clinical light.
	for point in [Vector3(-26, 2.9, -8), Vector3(-10, 2.9, -8), Vector3(6, 2.9, -8), Vector3(22, 2.9, -2), Vector3(-20, 2.9, 8), Vector3(0, 2.9, 10), Vector3(20, 2.9, 12)]:
		var fill := OmniLight3D.new()
		fill.position = ED_OFFSET + point
		fill.omni_range = 13.0
		fill.light_energy = 0.28
		fill.light_color = Color("f4f8fa")
		zone_roots.ed.add_child(fill)
		fp_nodes.append(fill)
	for point in [Vector3(-14, 2.8, -6), Vector3(4, 2.8, -6), Vector3(-10, 2.8, 7), Vector3(10, 2.8, 7)]:
		var fill := OmniLight3D.new()
		fill.position = IMAGING_OFFSET + point
		fill.omni_range = 12.0
		fill.light_energy = 0.26
		fill.light_color = Color("f4f8fa")
		zone_roots.imaging.add_child(fill)
		fp_nodes.append(fill)

## A few visitors crossing the atrium (the campus passer-by, on a lobby graph).
func _build_visitors() -> void:
	var keep_clear := [[Vector2(0, -1.8), 2.6], [Vector2(-7.4, -1.6), 1.8], [Vector2(-7.6, 3.4), 2.8], [Vector2(5.6, 5.8), 1.2]]
	for index in range(3):
		var walker := Pedestrian.new()
		walker.name = "Visitor"
		walker.nodes = VISITOR_NODES
		walker.edges = VISITOR_EDGES
		zone_roots.lobby.add_child(walker)
		walker.setup("", player, keep_clear)
		visitors.append(walker)

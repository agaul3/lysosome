extends Node3D
## Base for the campus buildings added for the first year (the Medical
## Education Center, the Biomedical Library, the Student Center…). A
## building is a set of zones (floors or wings) laid out far apart in one
## scene. Static builders lay geometry into a HospitalKit per zone and call
## back into this scene for everything that is a node, through the same API
## as University Hospital (signs, people, doors, screens, interactions,
## anchors), so hospital props and builders work here unchanged.
##
## Subclasses override:
##   zones()       {zone: {title, origin, min, max, view}}; origin is where
##                 the zone's builder lays out (zone-local coordinates)
##   builders()    {zone: builder script with static build(scene, kit)}
##   arrival()     where the student appears for AppState's entry
##   populate()    people, shops and activities once the geometry exists
## and call add_exit()/add_transfer() for the ways in and out.
const Geometry = preload("res://world/geometry.gd")
const Endpoint = preload("res://world/interactable.gd")
const Camera = preload("res://world/exploration_camera.gd")
const Player = preload("res://player/player.tscn")
const HUD = preload("res://ui/dorm_ui.gd")
const Kit = preload("res://world/hospital/hospital_kit.gd")
const Props = preload("res://world/hospital/hospital_props.gd")
const SlidingDoors = preload("res://world/hospital/sliding_doors.gd")
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
const Nameplate = preload("res://ui/world_nameplate.gd")
const Buildings = preload("res://world/campus/buildings.gd")
const Flora = preload("res://world/campus/flora.gd")
const Pedestrian = preload("res://npc/ambient/pedestrian.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var zone := ""
var anchors := {}
var targets := {}
var fp_nodes: Array[Node3D] = []
var tp_nodes: Array[Node3D] = []
## [first-person mesh, cutaway mesh] per zone.
var layers: Array = []
var zone_roots := {}
var build_root: Node3D
var figures: Array[Node3D] = []
var walkers: Array[Node3D] = []
var displays := {}
var riding := false
## Chairs the student can sit in (world/seat.gd); bound to the player once it exists.
var seats: Array[Node3D] = []
## Library and lab PCs: endpoint -> the screen quad the computer draws onto.
var computers := {}
## How far walkers step aside indoors (npc/ambient/pedestrian.gd).
const INDOOR_ASIDE := 0.5

func zones() -> Dictionary:
	return {}

func builders() -> Dictionary:
	return {}

func arrival() -> Vector3:
	return Vector3.ZERO

func arrival_yaw() -> float:
	return PI

func populate() -> void:
	pass

func _ready() -> void:
	player = Player.instantiate()
	var zone_data := zones()
	var zone_builders := builders()
	for zone_name in zone_data:
		var root := Node3D.new()
		root.name = String(zone_name).capitalize().replace(" ", "") + "Zone"
		add_child(root)
		zone_roots[zone_name] = root
	for zone_name in zone_data:
		build_root = zone_roots[zone_name]
		var kit := Kit.new(zone_data[zone_name].origin)
		zone_builders[zone_name].build(self, kit)
		layers.append(kit.commit(build_root, String(zone_name).capitalize()))
		_floor_slab(zone_data[zone_name].origin + Vector3(0, -0.5, 0), Vector3(120, 1, 120))
	build_root = self
	_build_lighting()
	player.position = arrival() + Vector3(0, 0.05, 0)
	add_child(player)
	player.appearance.rotation.y = arrival_yaw()
	player.first_person.yaw = arrival_yaw()
	camera = Camera.new()
	add_child(camera)
	player.movement_camera = camera
	hud = HUD.new()
	add_child(hud)
	hud.bind_player(player)
	for seat in seats:
		seat.sit_requested.connect(player.seating.request)
	populate()
	build_root = self
	AppState.view_changed.connect(apply_view)
	apply_view(AppState.first_person)
	_update_zone(true)
	camera.follow(player)

func _floor_slab(center: Vector3, size: Vector3) -> void:
	var ground := StaticBody3D.new()
	ground.name = "FloorCollision"
	var slab := CollisionShape3D.new()
	slab.shape = BoxShape3D.new()
	slab.shape.size = size
	slab.position = center
	ground.add_child(slab)
	add_child(ground)

func _build_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("24343c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e6e4df")
	environment.ambient_light_energy = 0.44
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

## Warm interior fill (first person only), at zone-local points.
func add_fill(zone_name: String, points: Array, energy := 0.32, reach := 12.0, color := Color("fff4e4")) -> void:
	for point in points:
		var fill := OmniLight3D.new()
		fill.position = zones()[zone_name].origin + point
		fill.omni_range = reach
		fill.light_energy = energy
		fill.light_color = color
		zone_roots[zone_name].add_child(fill)
		fp_nodes.append(fill)

## First person shows the whole building; the overhead view shows the cutaway.
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

## The zone whose follow bounds (grown a little) contain the point.
func zone_of(point: Vector3) -> String:
	var zone_data := zones()
	var best := ""
	var best_distance := INF
	for zone_name in zone_data:
		var entry: Dictionary = zone_data[zone_name]
		var rect := Rect2(entry.min, entry.max - entry.min).grow(12.0)
		var here := Vector2(point.x, point.z)
		if rect.has_point(here):
			var distance := here.distance_to(rect.get_center())
			if distance < best_distance:
				best = zone_name
				best_distance = distance
	return best if not best.is_empty() else zone

func _process(_delta: float) -> void:
	_update_zone()

func _update_zone(force := false) -> void:
	var now := zone_of(player.global_position)
	if now == zone and not force:
		return
	if now.is_empty():
		return
	zone = now
	var framing: Dictionary = zones()[zone]
	camera.size = framing.view
	camera.view_size = framing.view
	camera.follow_min = framing.min
	camera.follow_max = framing.max
	camera.follow(player)
	hud.set_location(framing.title)
	for zone_name in zone_roots:
		zone_roots[zone_name].visible = zone_name == zone
	Achievements.visit(scene_key() + ":" + zone)
	zone_changed(zone)

## Scene key (AppState.SCENES) of this building.
func scene_key() -> String:
	return AppState.location_key()

func zone_changed(_zone_name: String) -> void:
	pass

# --- Ways in and out -------------------------------------------------------------------------

## A door back to campus, arriving at `campus_entry`.
func add_exit(node_name: String, title: String, pos: Vector3, campus_entry: String, reach := 1.7) -> Node3D:
	var exit := add_endpoint(node_name, title, "", pos, reach)
	exit.activated.connect(AppState.enter_campus.bind(campus_entry))
	return exit

## Stairs, a lift or a doorway to another zone: a short fade to `to_point`.
func add_transfer(node_name: String, title: String, pos: Vector3, to_point: Vector3, yaw: float, reach := 1.7) -> Node3D:
	var point := add_endpoint(node_name, title, "", pos, reach)
	point.activated.connect(transfer.bind(to_point, yaw))
	return point

func transfer(to_point: Vector3, yaw: float) -> void:
	if riding:
		return
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
		await get_tree().create_timer(0.2).timeout
	Transition.reveal()
	player.movement_enabled = true
	riding = false

# --- Builder API (the same as University Hospital's) --------------------------------------------

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

func add_doors(node_name: String, pos: Vector3, yaw: float, width: float, height: float, glazed: bool, frame := Color("3a4045"), leaf := Color("a3aaaf")) -> Node3D:
	var doors := SlidingDoors.new(width, height, glazed)
	doors.frame_color = frame
	doors.leaf_color = leaf
	doors.name = node_name
	doors.position = pos
	doors.rotation.y = yaw
	build_root.add_child(doors)
	return doors

## Automatic doors that open for the student and for walkers (like the hospital's).
func add_auto_doors(node_name: String, pos: Vector3, yaw: float, width: float, glazed := true, depth := 1.8) -> Node3D:
	var doors := add_doors(node_name, pos, yaw, width, 2.4, glazed, Color("9aa2a7"))
	doors.auto_target = player
	doors.auto_group = "door_openers"
	doors.auto_depth = depth
	doors.speed = 2.6
	return doors

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

func add_letters(text: String, pos: Vector3, yaw: float, height: float, color := Color("3a4247")) -> void:
	Buildings.letters(build_root, text, pos, yaw, height, color, 0.05)

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
			figure.position = pos + Vector3(0, seat_top - 0.28, 0) + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.06)
			figure.rotation.y = yaw
		"bed":
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

## A chair the student can sit in, facing −Z turned by `yaw`. A seat at a
## table carries `laptop_surface` (seat-local), so the laptop can come out.
## `occupant` (a look) seats a student there instead, with a laptop open if
## the seat has a surface for one.
func add_seat(node_name: String, pos: Vector3, yaw: float, laptop_surface := Vector3.INF, color := Color("5b6f7a"), occupant := {}) -> Node3D:
	var seat := preload("res://world/seat.gd").new()
	seat.name = node_name
	seat.color = color
	seat.position = pos
	seat.rotation.y = yaw
	seat.laptop_surface = laptop_surface
	if not occupant.is_empty():
		seat.occupied = true
		seat.occupant_look = occupant
	build_root.add_child(seat)
	if not occupant.is_empty() and laptop_surface != Vector3.INF:
		var laptop := preload("res://world/laptop.gd").new()
		laptop.name = "OpenLaptop"
		laptop.position = laptop_surface
		seat.add_child(laptop)
	seats.append(seat)
	return seat

## A usable computer: the screen quad on a monitor (idle: the pixel lock
## screen) and an endpoint in front of it that opens the desktop there.
func add_pc(node_name: String, screen_pos: Vector3, yaw: float, use_pos: Vector3, title := "Use the PC", size := Vector2(0.46, 0.26)) -> Node3D:
	var screen := MeshInstance3D.new()
	screen.name = node_name + "Screen"
	screen.mesh = QuadMesh.new()
	screen.mesh.size = size
	screen.position = screen_pos
	screen.rotation.y = yaw
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var idle := ShaderMaterial.new()
	idle.shader = preload("res://assets/pixel_screen.gdshader")
	idle.set_shader_parameter("image", preload("res://assets/windows_lock.png"))
	screen.material_override = idle
	build_root.add_child(screen)
	var endpoint := add_endpoint(node_name, title, "", use_pos, 1.3)
	endpoint.activated.connect(func() -> void: hud.open_computer("windows", screen))
	computers[endpoint] = screen
	return endpoint

## Where a scheduled activity in `room` starts (world/activity_station.gd);
## between events it shows `title` and `text`.
func add_station(node_name: String, room: String, pos: Vector3, title: String, text := "", reach := 1.7) -> Node3D:
	var station := preload("res://world/activity_station.gd").new()
	station.name = node_name
	station.position = pos
	station.reach = reach
	station.setup(scene_key(), room, hud, title, text)
	build_root.add_child(station)
	return station

func add_dispenser(id: String, pos: Vector3) -> Node3D:
	var endpoint := add_endpoint("Dispenser_" + id, "Clean your hands", "Alcohol foam, rubbed in until your hands are dry.", pos, 1.6)
	endpoint.activated.connect(func() -> void: Achievements.bump("hands_cleaned"))
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

func add_prop_node(node_name: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = pos
	node.rotation.y = yaw
	build_root.add_child(node)
	return node

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

## A walker on a path graph (x, z pairs in world coordinates) in a zone. It
## steps `aside` (INDOOR_ASIDE unless a tight room asks for less) to the side
## for the student, so a graph edge needs about 0.42 m plus that clear on
## each side (tests/interior_clearance_test.gd).
## Walkers don't open doors: keep graphs inside a room or through doorways.
func add_walkers(zone_name: String, nodes: Array, edges: Array, count: int, keep_clear: Array = [], looks: Array = [], aside := INDOOR_ASIDE) -> void:
	for index in range(count):
		var walker := Pedestrian.new()
		walker.name = "Walker"
		walker.nodes = nodes
		walker.edges = edges
		zone_roots[zone_name].add_child(walker)
		walker.setup(looks[index % looks.size()] if not looks.is_empty() else "", player, keep_clear)
		walker.aside_width = aside
		walkers.append(walker)

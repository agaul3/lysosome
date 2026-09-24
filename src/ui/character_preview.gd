extends SubViewportContainer
## A character on a lit plinth in its own small world, used by the creator,
## the closet and the inventory. It turns slowly on its own, and dragging
## with the mouse turns it by hand. "full" frames the whole body; "portrait"
## frames head and shoulders (the preset cards).
const Appearance = preload("res://player/appearance.gd")
var viewport: SubViewport
var figure: Node3D
var camera: Camera3D
var framing := "full"
var turntable := true
var spin_speed := 0.55
var dragging := false
var _size := Vector2i(320, 400)

func _init(view_size := Vector2i(320, 400), view_framing := "full", spins := true) -> void:
	_size = view_size
	framing = view_framing
	turntable = spins
	custom_minimum_size = Vector2(view_size)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP if spins else Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = _size
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if turntable else SubViewport.UPDATE_ONCE
	add_child(viewport)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e3ebee")
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	viewport.add_child(environment_node)
	if framing == "full":
		var plinth := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.62
		disc.bottom_radius = 0.66
		disc.height = 0.06
		plinth.mesh = disc
		var plinth_material := StandardMaterial3D.new()
		plinth_material.albedo_color = Color("22404a")
		plinth.material_override = plinth_material
		plinth.position.y = -0.03
		viewport.add_child(plinth)
	figure = Appearance.new()
	figure.name = "Figure"
	viewport.add_child(figure)
	camera = Camera3D.new()
	viewport.add_child(camera)
	if framing == "portrait":
		var eye := Vector3(0.18, 1.52, -1.7)
		camera.transform = Transform3D(Basis.looking_at(Vector3(0, 1.4, 0) - eye), eye)
		camera.fov = 25
		figure.rotation.y = 0.3
	else:
		var eye := Vector3(0, 1.3, -3.9)
		camera.transform = Transform3D(Basis.looking_at(Vector3(0, 0.88, 0) - eye), eye)
		camera.fov = 32
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 150, 0)
	light.light_energy = 0.95
	viewport.add_child(light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, -20, 0)
	rim.light_energy = 0.4
	rim.light_color = Color("9ce0d4")
	viewport.add_child(rim)

func show_look(look: Dictionary) -> void:
	if not is_instance_valid(figure):
		return
	var facing: float = figure.rotation.y
	figure.apply_look(look)
	figure.rotation.y = facing
	if not turntable and is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func show_preset(id: String) -> void:
	show_look(preload("res://data/character_presets.gd").look_of(id))

func _process(delta: float) -> void:
	if turntable and not dragging and is_visible_in_tree() and is_instance_valid(figure):
		figure.rotation.y += delta * spin_speed

func _gui_input(event: InputEvent) -> void:
	if not turntable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		figure.rotation.y += event.relative.x * 0.012
		accept_event()

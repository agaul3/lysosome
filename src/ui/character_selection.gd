extends VBoxContainer
signal cancelled
const Presets = preload("res://data/character_presets.gd")
const Appearance = preload("res://player/appearance.gd")
var preset_buttons: Array[Button] = []
var enter_button: Button
var back_button: Button
var preview: Node3D

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var heading := Label.new()
	heading.text = "Choose your student"
	heading.add_theme_font_size_override("font_size", 28)
	add_child(heading)
	_build_preview()
	for preset in Presets.PRESETS:
		var button := Button.new()
		button.text = preset.description
		button.toggle_mode = true
		button.custom_minimum_size.y = 40
		button.pressed.connect(select_preset.bind(preset.id))
		add_child(button)
		preset_buttons.append(button)
	enter_button = Button.new()
	enter_button.text = "Begin morning"
	enter_button.custom_minimum_size.y = 48
	enter_button.pressed.connect(AppState.enter_dorm)
	add_child(enter_button)
	back_button = Button.new()
	back_button.text = "Back to title"
	back_button.pressed.connect(func() -> void: cancelled.emit())
	add_child(back_button)
	select_preset(AppState.selected_character)

func _build_preview() -> void:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(370, 160)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(370, 160)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	container.add_child(viewport)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e0e9ef")
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	viewport.add_child(environment_node)
	preview = Appearance.new()
	viewport.add_child(preview)
	preview.rotation.y = -0.35
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 1.15, -4)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 150, 0)
	light.light_energy = 0.8
	viewport.add_child(light)

func select_preset(id: String) -> void:
	if not AppState.select_character(id):
		return
	preview.apply_preset(id)
	for index in range(preset_buttons.size()):
		preset_buttons[index].set_pressed_no_signal(Presets.PRESETS[index].id == id)

func focus_selection() -> void:
	select_preset(AppState.selected_character)
	preset_buttons[0].grab_focus()

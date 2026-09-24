extends VBoxContainer
## Character setup (spec §9.2): a turntable preview beside four preset cards.
signal cancelled
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Presets = preload("res://data/character_presets.gd")
const Appearance = preload("res://player/appearance.gd")
var preset_buttons: Array[Button] = []
var enter_button: Button
var back_button: Button
var preview: Node3D
var preview_name: Label
var preview_description: Label

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(UI.label("New game", UI.SIZE_CAPTION, UI.ACCENT, 600, true))
	add_child(UI.label("Choose your student", UI.SIZE_HEADING + 4, UI.TEXT, 600))
	add_child(UI.paragraph("Pick how you look on campus. It's cosmetic — every student starts with the same schedule.", 440, UI.SIZE_BODY, UI.TEXT_MUTED))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	add_child(body)
	body.add_child(_build_preview())
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(list)
	for preset in Presets.PRESETS:
		var button := Button.new()
		button.toggle_mode = true
		button.theme_type_variation = "CardButton"
		button.custom_minimum_size = Vector2(0, 54)
		button.text = ""
		button.pressed.connect(func() -> void:
			Sfx.play("ui_move")
			select_preset(preset.id))
		button.focus_entered.connect(select_preset.bind(preset.id))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 14
		row.offset_right = -12
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var swatches := HBoxContainer.new()
		swatches.add_theme_constant_override("separation", -5)
		swatches.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for key in ["skin", "hair", "shirt"]:
			var colour := Color(preset[key])
			var dot := Control.new()
			dot.custom_minimum_size = Vector2(18, 18)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.draw.connect(func() -> void:
				dot.draw_circle(Vector2(9, 9), 9, UI.SURFACE_RAISED)
				dot.draw_circle(Vector2(9, 9), 7.5, colour))
			swatches.add_child(dot)
		row.add_child(swatches)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", -1)
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text.add_child(UI.label(preset.name, UI.SIZE_BODY, UI.TEXT, 600))
		text.add_child(UI.label(preset.description, UI.SIZE_CAPTION, UI.TEXT_MUTED, 400))
		row.add_child(text)
		button.add_child(row)
		list.add_child(button)
		preset_buttons.append(button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(110, 46)
	back_button.pressed.connect(func() -> void: cancelled.emit())
	actions.add_child(back_button)
	enter_button = Button.new()
	enter_button.text = "Begin your first morning"
	enter_button.theme_type_variation = "PrimaryButton"
	enter_button.custom_minimum_size = Vector2(0, 46)
	enter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enter_button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		AppState.enter_dorm())
	actions.add_child(enter_button)
	select_preset(AppState.selected_character)

func _build_preview() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.box(Color(UI.SURFACE, 0.85), 12, UI.LINE_SOFT, 1, Vector4(0, 0, 0, 12)))
	card.custom_minimum_size = Vector2(190, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	card.add_child(column)
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(190, 210)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(190, 210)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	container.add_child(viewport)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dfe8ec")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	viewport.add_child(environment_node)
	# A soft plinth for the figure to stand on.
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
	preview = Appearance.new()
	viewport.add_child(preview)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	var eye := Vector3(0, 1.25, -3.6)
	camera.transform = Transform3D(Basis.looking_at(Vector3(0, 0.85, 0) - eye), eye)
	camera.fov = 34
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 150, 0)
	light.light_energy = 0.95
	viewport.add_child(light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, -20, 0)
	rim.light_energy = 0.35
	rim.light_color = Color("9ce0d4")
	viewport.add_child(rim)
	preview_name = UI.label("", UI.SIZE_TITLE, UI.TEXT, 600)
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(preview_name)
	preview_description = UI.label("First-year student", UI.SIZE_CAPTION, UI.TEXT_MUTED, 500)
	preview_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(preview_description)
	return card

func _process(delta: float) -> void:
	if visible and is_instance_valid(preview):
		preview.rotation.y += delta * 0.6

func select_preset(id: String) -> void:
	if not AppState.select_character(id):
		return
	if not is_instance_valid(preview):
		return
	if preview.preset_id != id:
		preview.apply_preset(id)
	var data := Presets.get_preset(id)
	preview_name.text = data.name
	for index in range(preset_buttons.size()):
		preset_buttons[index].set_pressed_no_signal(Presets.PRESETS[index].id == id)

func focus_selection() -> void:
	select_preset(AppState.selected_character)
	var index := 0
	for i in range(Presets.PRESETS.size()):
		if Presets.PRESETS[i].id == AppState.selected_character:
			index = i
	preset_buttons[index].grab_focus()

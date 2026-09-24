extends VBoxContainer
## Character creator (spec §9.2, extended): name your student, then either
## pick one of eight presets (each card shows a rendered portrait) or build
## your own look — build, skin, height, hair, eyes, brows, mouth, cheeks,
## facial hair and a starting outfit — with a large turntable preview.
## Everything can be changed again later at the closet in your room.
signal cancelled
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Presets = preload("res://data/character_presets.gd")
const Looks = preload("res://data/looks.gd")
const CharacterPreview = preload("res://ui/character_preview.gd")
const LookEditor = preload("res://ui/look_editor.gd")
const WIDTH := 960.0
var preset_buttons: Array[Button] = []
var mode_buttons: Array[Button] = []
var enter_button: Button
var back_button: Button
var randomize_button: Button
var name_edit: LineEdit
## The figure in the large preview (an Appearance node).
var preview: Node3D
var preview_widget: SubViewportContainer
var preview_name: Label
var preview_description: Label
var presets_view: Control
var create_view: ScrollContainer
var editor: VBoxContainer
var mode := "presets"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	custom_minimum_size.x = WIDTH
	add_theme_constant_override("separation", 10)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	add_child(heading)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.add_child(UI.label("New game", UI.SIZE_CAPTION, UI.ACCENT, 600, true))
	titles.add_child(UI.label("Create your student", UI.SIZE_HEADING + 4, UI.TEXT, 600))
	heading.add_child(titles)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	add_child(body)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size.x = 560
	body.add_child(left)
	left.add_child(_top_row())
	presets_view = _presets_grid()
	left.add_child(presets_view)
	create_view = _create_panel()
	left.add_child(create_view)
	body.add_child(_preview_card())
	preview = preview_widget.figure
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(110, 46)
	back_button.pressed.connect(func() -> void: cancelled.emit())
	actions.add_child(back_button)
	actions.add_child(UI.label("You can change your look any time at the closet in your room.", UI.SIZE_LABEL, UI.TEXT_FAINT, 400))
	actions.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.get_child(1).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	enter_button = Button.new()
	enter_button.text = "Begin your first morning"
	enter_button.theme_type_variation = "PrimaryButton"
	enter_button.custom_minimum_size = Vector2(300, 46)
	enter_button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		if not name_edit.text.strip_edges().is_empty():
			AppState.set_player_name(name_edit.text)
		AppState.enter_dorm())
	actions.add_child(enter_button)
	AppState.look_changed.connect(_on_look_changed)
	set_mode("presets")
	select_preset(AppState.selected_character if Presets.is_valid(AppState.selected_character) else Presets.DEFAULT_ID)

func _top_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := UI.label("Name", UI.SIZE_LABEL, UI.TEXT_MUTED, 600)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	name_edit = LineEdit.new()
	name_edit.name = "NameField"
	name_edit.custom_minimum_size = Vector2(200, 38)
	name_edit.max_length = 20
	name_edit.placeholder_text = "Your name"
	name_edit.text = AppState.display_name()
	name_edit.text_changed.connect(func(text: String) -> void:
		AppState.set_player_name(text, true)
		preview_name.text = AppState.display_name())
	name_edit.text_submitted.connect(func(_text: String) -> void: enter_button.grab_focus())
	row.add_child(name_edit)
	row.add_child(UI.spacer(0, 0, true))
	for entry in [["presets", "Presets"], ["create", "Create your own"]]:
		var button := Button.new()
		button.text = entry[1]
		button.toggle_mode = true
		button.theme_type_variation = "NavButton"
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(func() -> void:
			Sfx.play("ui_move")
			set_mode(entry[0])
			_focus_mode_content())
		row.add_child(button)
		mode_buttons.append(button)
	return row

func _presets_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for preset in Presets.PRESETS:
		var button := Button.new()
		button.toggle_mode = true
		button.theme_type_variation = "CardButton"
		button.custom_minimum_size = Vector2(275, 78)
		button.text = ""
		button.pressed.connect(func() -> void:
			Sfx.play("ui_move")
			select_preset(preset.id))
		button.focus_entered.connect(select_preset.bind(preset.id))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.offset_right = -10
		row.offset_top = 6
		row.offset_bottom = -6
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait_frame := PanelContainer.new()
		portrait_frame.add_theme_stylebox_override("panel", UI.box(Color(UI.INK, 0.5), 8, UI.LINE_SOFT, 1, Vector4(0, 0, 0, 0)))
		portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait := CharacterPreview.new(Vector2i(62, 62), "portrait", false)
		portrait_frame.add_child(portrait)
		row.add_child(portrait_frame)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_child(UI.label(preset.name, UI.SIZE_BODY, UI.TEXT, 600))
		text.add_child(UI.label(preset.description, UI.SIZE_CAPTION, UI.TEXT_MUTED, 400))
		row.add_child(text)
		button.add_child(row)
		grid.add_child(button)
		preset_buttons.append(button)
		portrait.ready.connect(portrait.show_preset.bind(preset.id))
	return grid

func _create_panel() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 344)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	column.add_child(tools)
	randomize_button = Button.new()
	randomize_button.text = "Randomize"
	randomize_button.custom_minimum_size = Vector2(130, 36)
	randomize_button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		editor.randomize_look(rng))
	tools.add_child(randomize_button)
	var hint := UI.label("← → change a row · ↑ ↓ move between rows", UI.SIZE_CAPTION, UI.TEXT_FAINT, 400)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tools.add_child(hint)
	editor = LookEditor.new(true)
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.look_changed.connect(func(look: Dictionary) -> void: AppState.set_custom_look(look))
	column.add_child(editor)
	return scroll

func _preview_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.box(Color(UI.SURFACE, 0.85), 12, UI.LINE_SOFT, 1, Vector4(0, 8, 0, 12)))
	card.custom_minimum_size = Vector2(370, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	card.add_child(column)
	preview_widget = CharacterPreview.new(Vector2i(370, 330), "full", true)
	column.add_child(preview_widget)
	preview_name = UI.label("", UI.SIZE_TITLE, UI.TEXT, 600)
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(preview_name)
	preview_description = UI.label("", UI.SIZE_CAPTION, UI.TEXT_MUTED, 500)
	preview_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(preview_description)
	var hint := UI.label("Drag to turn", UI.SIZE_CAPTION, UI.TEXT_FAINT, 400)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	return card

func set_mode(next: String) -> void:
	mode = next
	presets_view.visible = mode == "presets"
	create_view.visible = mode == "create"
	for i in range(mode_buttons.size()):
		mode_buttons[i].set_pressed_no_signal((i == 0) == (mode == "presets"))
	if mode == "create":
		editor.set_look(AppState.player_look)

## After switching tabs: the editor's first row, or the chosen preset's card.
## A custom look is never replaced just by returning to the Presets tab.
func _focus_mode_content() -> void:
	if mode == "create":
		editor.first_row().grab_focus()
		return
	for i in range(Presets.PRESETS.size()):
		if Presets.PRESETS[i].id == AppState.selected_character:
			preset_buttons[i].grab_focus()

func select_preset(id: String) -> void:
	if not AppState.select_character(id):
		return
	if is_instance_valid(name_edit) and name_edit.text != AppState.display_name():
		name_edit.text = AppState.display_name()
	for index in range(preset_buttons.size()):
		preset_buttons[index].set_pressed_no_signal(Presets.PRESETS[index].id == id)

func _on_look_changed(look: Dictionary) -> void:
	if not is_instance_valid(preview_widget):
		return
	preview_widget.show_look(look)
	preview = preview_widget.figure
	preview_name.text = AppState.display_name()
	var description: String = Presets.get_preset(AppState.selected_character).description if Presets.is_valid(AppState.selected_character) else "Your own look"
	preview_description.text = "%s · %s" % [description, LookEditor._height_text(float(look.height))]
	if mode == "presets" and not Presets.is_valid(AppState.selected_character):
		for button in preset_buttons:
			button.set_pressed_no_signal(false)

func focus_selection() -> void:
	if not Presets.is_valid(AppState.selected_character):
		set_mode("create")
		editor.first_row().grab_focus()
		return
	set_mode("presets")
	select_preset(AppState.selected_character)
	var index := 0
	for i in range(Presets.PRESETS.size()):
		if Presets.PRESETS[i].id == AppState.selected_character:
			index = i
	preset_buttons[index].grab_focus()

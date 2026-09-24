extends Control
## The closet in your dorm room: a large preview of your student beside two
## tabs — Clothes (the equipment sheet: everything you own, worn at a click)
## and Mirror (hair, face, skin, build and height). Changes apply to your
## student immediately and are saved with the game. The world keeps running.
signal closed
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Looks = preload("res://data/looks.gd")
const CharacterPreview = preload("res://ui/character_preview.gd")
const EquipmentView = preload("res://ui/equipment_view.gd")
const LookEditor = preload("res://ui/look_editor.gd")
const KeyPrompt = preload("res://ui/key_prompt.gd")
const PANEL_SIZE := Vector2(1000, 610)
var panel: PanelContainer
var preview: SubViewportContainer
var tabs: TabContainer
var tab_buttons: Array[Button] = []
var equipment: VBoxContainer
var editor: VBoxContainer
var done_button: Button
var height_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color(UI.INK, 0.6)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style())
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -PANEL_SIZE.x / 2.0
	panel.offset_right = PANEL_SIZE.x / 2.0
	panel.offset_top = -PANEL_SIZE.y / 2.0
	panel.offset_bottom = PANEL_SIZE.y / 2.0
	add_child(panel)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	panel.add_child(layout)
	layout.add_child(_preview_side())
	layout.add_child(UI.hairline(true))
	layout.add_child(_content_side())
	AppState.look_changed.connect(_on_look_changed)
	hide()

func _preview_side() -> Control:
	var side := PanelContainer.new()
	side.custom_minimum_size.x = 320
	var style := UI.box(Color(UI.INK, 0.55), 0, Color.TRANSPARENT, 0, Vector4(20, 20, 20, 18))
	style.corner_radius_top_left = 14
	style.corner_radius_bottom_left = 14
	side.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	side.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Icon.new("inventory", 18, UI.ACCENT))
	head.add_child(UI.label("Closet", UI.SIZE_TITLE + 1, UI.TEXT, 600))
	column.add_child(head)
	column.add_child(UI.label("Try things on. Everything saves with your game.", UI.SIZE_LABEL, UI.TEXT_MUTED, 400))
	preview = CharacterPreview.new(Vector2i(280, 440), "full", true)
	column.add_child(preview)
	height_label = UI.label("", UI.SIZE_LABEL, UI.TEXT_MUTED, 500)
	height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(height_label)
	var hint := UI.label("Drag to turn", UI.SIZE_CAPTION, UI.TEXT_FAINT, 400)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	return side

func _content_side() -> Control:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	column.add_child(bar)
	for entry in [["Clothes", "inventory"], ["Mirror", "person"]]:
		var button := Button.new()
		button.text = entry[0]
		button.toggle_mode = true
		button.theme_type_variation = "NavButton"
		button.custom_minimum_size = Vector2(120, 36)
		var index := tab_buttons.size()
		button.pressed.connect(show_tab.bind(index))
		bar.add_child(button)
		tab_buttons.append(button)
	bar.add_child(UI.spacer(0, 0, true))
	var key := KeyPrompt.new()
	key.key = "Esc"
	bar.add_child(key)
	done_button = Button.new()
	done_button.text = "Done"
	done_button.theme_type_variation = "PrimaryButton"
	done_button.custom_minimum_size = Vector2(96, 36)
	done_button.pressed.connect(close)
	bar.add_child(done_button)
	column.add_child(UI.hairline())
	tabs = TabContainer.new()
	tabs.tabs_visible = false
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column.add_child(tabs)
	var clothes_scroll := ScrollContainer.new()
	clothes_scroll.name = "Clothes"
	clothes_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	equipment = EquipmentView.new(false)
	equipment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clothes_scroll.add_child(equipment)
	tabs.add_child(clothes_scroll)
	var mirror_scroll := ScrollContainer.new()
	mirror_scroll.name = "Mirror"
	mirror_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var mirror_column := VBoxContainer.new()
	mirror_column.add_theme_constant_override("separation", 10)
	mirror_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mirror_scroll.add_child(mirror_column)
	editor = LookEditor.new(false)
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.look_changed.connect(func(look: Dictionary) -> void: AppState.set_look(look))
	mirror_column.add_child(editor)
	tabs.add_child(mirror_scroll)
	return margin

func show_tab(index: int) -> void:
	tabs.current_tab = index
	for i in range(tab_buttons.size()):
		tab_buttons[i].set_pressed_no_signal(i == index)
	var target: Control = equipment.first_focus() if index == 0 else editor.first_row()
	if is_instance_valid(target) and visible:
		target.grab_focus()

func open(tab := 0) -> void:
	show()
	editor.set_look(AppState.player_look)
	equipment.refresh()
	_on_look_changed(AppState.player_look)
	show_tab(tab)
	Sfx.play("ui_open")

func close() -> void:
	if not visible:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	hide()
	Sfx.play("ui_close")
	closed.emit()

func _on_look_changed(look: Dictionary) -> void:
	# Keep the mirror's rows (and its copy of the outfit) in step with changes
	# made on the Clothes tab, so restyling never undoes a new jacket.
	if is_instance_valid(editor):
		editor.set_look(look)
	if is_instance_valid(preview):
		preview.show_look(look)
	if is_instance_valid(height_label):
		height_label.text = "%s · %s" % [AppState.display_name(), editor._height_text(float(look.height)) if is_instance_valid(editor) else ""]

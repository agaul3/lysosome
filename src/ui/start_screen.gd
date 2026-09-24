extends Control
## Title screen: a live campus panorama behind a clean menu column.
## Continue (when a save exists), New Game, Settings and Quit; character
## selection and settings open in the same column.
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const KeyPrompt = preload("res://ui/key_prompt.gd")
const CharacterSelection = preload("res://ui/character_selection.gd")
const SettingsPanel = preload("res://ui/settings_panel.gd")
const Panorama = preload("res://world/campus/panorama.gd")
const COLUMN_WIDTH := 380.0
var title_panel: VBoxContainer
var selection_panel: VBoxContainer
var settings_panel: VBoxContainer
var confirm_panel: PanelContainer
var new_game_button: Button
var continue_button: Button
var continue_detail: Label
var settings_button: Button
var quit_button: Button
var return_button: Button
var confirm_button: Button
var confirm_cancel: Button
var intro: Control

func _ready() -> void:
	theme = UI.theme()
	_build_backdrop()
	_build_ui()
	AppState.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(AppState.phase)

func _build_backdrop() -> void:
	var fill := ColorRect.new()
	fill.color = UI.INK
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	viewport.add_child(Panorama.new())
	# Ink gradient from the left so the menu reads over the scene.
	var shade := TextureRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(UI.INK, 0.96))
	gradient.set_color(1, Color(UI.INK, 0.0))
	gradient.add_point(0.42, Color(UI.INK, 0.86))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0.78, 0)
	shade.texture = texture
	add_child(shade)
	var bottom := TextureRect.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.stretch_mode = TextureRect.STRETCH_SCALE
	var fade := Gradient.new()
	fade.set_color(0, Color(UI.INK, 0.0))
	fade.set_color(1, Color(UI.INK, 0.7))
	var fade_texture := GradientTexture2D.new()
	fade_texture.gradient = fade
	fade_texture.fill_from = Vector2(0, 0.7)
	fade_texture.fill_to = Vector2(0, 1)
	bottom.texture = fade_texture
	add_child(bottom)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.custom_minimum_size.x = COLUMN_WIDTH + 80
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margin.add_child(column)
	# Wordmark.
	var mark := HBoxContainer.new()
	mark.add_theme_constant_override("separation", 10)
	var emblem := PanelContainer.new()
	emblem.add_theme_stylebox_override("panel", UI.box(Color(UI.ACCENT, 0.12), 9, Color(UI.ACCENT, 0.55), 1, Vector4(7, 7, 7, 7)))
	emblem.add_child(Icon.new("knowledge", 18, UI.ACCENT))
	mark.add_child(emblem)
	var mark_text := VBoxContainer.new()
	mark_text.add_theme_constant_override("separation", -2)
	mark_text.add_child(UI.label("Medical School", UI.SIZE_LABEL, UI.TEXT, 600, true))
	mark_text.add_child(UI.label("An RPG of the first year", UI.SIZE_CAPTION, UI.TEXT_MUTED, 400))
	mark.add_child(mark_text)
	column.add_child(mark)
	column.add_child(UI.spacer(26))
	# Content area: intro + menu, or the character / settings panels.
	intro = VBoxContainer.new()
	intro.add_theme_constant_override("separation", 12)
	column.add_child(intro)
	var headline := UI.label("Your first morning\nof medical school.", UI.SIZE_DISPLAY, UI.TEXT, 600)
	intro.add_child(headline)
	intro.add_child(UI.paragraph("Make it to your first Pharmacodynamics lecture, work through original exam-style questions and watch your knowledge — and your level — grow.", COLUMN_WIDTH + 40, UI.SIZE_BODY + 1, UI.TEXT_MUTED))
	intro.add_child(UI.spacer(14))
	title_panel = VBoxContainer.new()
	title_panel.add_theme_constant_override("separation", 10)
	title_panel.custom_minimum_size.x = COLUMN_WIDTH
	title_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	intro.add_child(title_panel)
	continue_button = _menu_button("Continue", "play", AppState.continue_game, true)
	continue_detail = UI.label("", UI.SIZE_CAPTION, UI.TEXT_MUTED, 500)
	title_panel.add_child(continue_detail)
	new_game_button = _menu_button("New Game", "plus", _request_new_game, false)
	settings_button = _menu_button("Settings", "settings", _open_settings, false)
	quit_button = _menu_button("Quit", "power", _quit, false)
	quit_button.theme_type_variation = "GhostButton"
	UI.pad_left(quit_button, 48)
	_refresh_continue()
	selection_panel = CharacterSelection.new()
	selection_panel.custom_minimum_size.x = COLUMN_WIDTH + 80
	column.add_child(selection_panel)
	selection_panel.cancelled.connect(AppState.return_to_title)
	return_button = selection_panel.back_button
	settings_panel = SettingsPanel.new()
	settings_panel.custom_minimum_size.x = COLUMN_WIDTH + 40
	settings_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(settings_panel)
	settings_panel.closed.connect(_close_settings)
	column.add_child(UI.spacer(0, 0, true))
	# Footer: navigation hints and version.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	for pair in [["↑↓", "Select"], ["Enter", "Confirm"], ["Esc", "Back"]]:
		var key := KeyPrompt.new()
		key.key = pair[0]
		footer.add_child(key)
		footer.add_child(UI.label(pair[1], UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
		footer.add_child(UI.spacer(0, 10))
	column.add_child(footer)
	var version := UI.label("Vertical slice v0.1", UI.SIZE_CAPTION, UI.TEXT_FAINT, 400)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -28
	version.offset_bottom = -20
	add_child(version)
	_build_confirm()

func _menu_button(text: String, icon: String, callback: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(COLUMN_WIDTH, 48)
	button.theme_type_variation = "PrimaryButton" if primary else ""
	UI.pad_left(button, 48)
	var glyph := Icon.new(icon, 16, UI.INK if primary else UI.TEXT)
	glyph.name = "Glyph"
	glyph.position = Vector2(18, 16)
	button.add_child(glyph)
	button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		callback.call())
	button.focus_entered.connect(func() -> void: Sfx.play("ui_move"))
	title_panel.add_child(button)
	return button

## Continue is the primary action when a valid save exists.
func _refresh_continue() -> void:
	var summary := SaveGame.summary()
	var available := not summary.is_empty()
	continue_button.disabled = not available
	continue_button.visible = available
	continue_detail.visible = available
	if available:
		var name: String = summary.name
		continue_detail.text = "%s · Lvl %d · %s · %s, %s" % [name, summary.level, summary.location, summary.date, summary.time]
	new_game_button.theme_type_variation = "" if available else "PrimaryButton"
	UI.pad_left(new_game_button, 48)
	new_game_button.get_node("Glyph").color = UI.TEXT if available else UI.INK

func _build_confirm() -> void:
	confirm_panel = PanelContainer.new()
	confirm_panel.add_theme_stylebox_override("panel", UI.panel_style())
	confirm_panel.anchor_left = 0.5
	confirm_panel.anchor_right = 0.5
	confirm_panel.anchor_top = 0.5
	confirm_panel.anchor_bottom = 0.5
	confirm_panel.offset_left = -220
	confirm_panel.offset_right = 220
	confirm_panel.offset_top = -100
	confirm_panel.offset_bottom = 100
	add_child(confirm_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	confirm_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	column.add_child(UI.label("Start a new game?", UI.SIZE_TITLE + 1, UI.TEXT, 600))
	column.add_child(UI.paragraph("Your saved progress will be replaced the first time the new game saves.", 380, UI.SIZE_BODY, UI.TEXT_MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	confirm_cancel = Button.new()
	confirm_cancel.text = "Cancel"
	confirm_cancel.pressed.connect(_close_confirm)
	row.add_child(confirm_cancel)
	confirm_button = Button.new()
	confirm_button.text = "Start new game"
	confirm_button.theme_type_variation = "PrimaryButton"
	confirm_button.pressed.connect(func() -> void:
		confirm_panel.hide()
		AppState.start_new_game())
	row.add_child(confirm_button)
	column.add_child(row)
	confirm_panel.hide()

func _request_new_game() -> void:
	if SaveGame.has_save():
		confirm_panel.show()
		confirm_cancel.grab_focus()
	else:
		AppState.start_new_game()

func _close_confirm() -> void:
	confirm_panel.hide()
	new_game_button.grab_focus()

func _on_phase_changed(phase: AppState.Phase) -> void:
	settings_panel.hide()
	confirm_panel.hide()
	intro.visible = phase == AppState.Phase.TITLE
	title_panel.visible = phase == AppState.Phase.TITLE
	selection_panel.visible = phase == AppState.Phase.CHARACTER_SELECT
	if title_panel.visible:
		_refresh_continue()
		(continue_button if continue_button.visible else new_game_button).grab_focus()
	else:
		selection_panel.focus_selection()

func _open_settings() -> void:
	intro.hide()
	title_panel.hide()
	settings_panel.show()
	settings_panel.volume_slider.grab_focus()

func _close_settings() -> void:
	settings_panel.hide()
	intro.show()
	title_panel.show()
	settings_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if confirm_panel.visible:
			_close_confirm()
		elif settings_panel.visible:
			_close_settings()
		elif selection_panel.visible:
			AppState.return_to_title()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and not event.is_echo():
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and not focused.disabled:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()

func _quit() -> void:
	get_tree().quit()

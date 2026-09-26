extends Control
## A centred dialog in the design system: a dimmed backdrop, a panel with an
## eyebrow, a title, a body column and a row of buttons. The HUD opens it
## with open_modal(); `closed` tells the HUD to put it away. Buttons take
## the keyboard and controller (Tab/arrows and E/Enter).
signal closed
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
var panel: PanelContainer
var eyebrow_label: Label
var title_label: Label
var body: VBoxContainer
var buttons: HBoxContainer
var width := 520.0
## Esc (or the menu button) closes it unless false.
var dismissible := true

func _init(panel_width := 520.0) -> void:
	width = panel_width

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(UI.INK, 0.62)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, 14, UI.LINE, 1, Vector4(26, 22, 26, 22)))
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	eyebrow_label = UI.label("", UI.SIZE_CAPTION, UI.ACCENT, 600, true)
	column.add_child(eyebrow_label)
	title_label = UI.label("", UI.SIZE_HEADING - 4, UI.TEXT, 600)
	column.add_child(title_label)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	column.add_child(body)
	buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(UI.spacer(2))
	column.add_child(buttons)
	build()
	_focus_first.call_deferred()

## Subclasses fill the dialog here.
func build() -> void:
	pass

func set_heading(eyebrow: String, title: String) -> void:
	eyebrow_label.text = eyebrow
	eyebrow_label.visible = not eyebrow.is_empty()
	title_label.text = title

func add_text(text: String, color := UI.TEXT_MUTED, size := UI.SIZE_BODY) -> Label:
	var label := UI.paragraph(text, width - 52, size, color)
	body.add_child(label)
	return label

func add_button(text: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 38)
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		action.call())
	buttons.add_child(button)
	return button

func _focus_first() -> void:
	for child in buttons.get_children():
		if child is Button and child.theme_type_variation == "PrimaryButton":
			child.grab_focus()
			return
	if buttons.get_child_count() > 0:
		buttons.get_child(0).grab_focus()

func close() -> void:
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if dismissible and (event.is_action_pressed("cancel") or event.is_action_pressed("open_menu")):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("interact") and get_viewport().gui_get_focus_owner() is Button:
		get_viewport().set_input_as_handled()
		(get_viewport().gui_get_focus_owner() as Button).pressed.emit()

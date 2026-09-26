extends VBoxContainer
## The HUD's money and energy card, beside the level card: the balance, an
## energy bar, and one small chip per active boost (icon and minutes left).
## Money changes float up beside the balance. Read-only: nothing here
## changes the wallet or wellbeing.
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Items = preload("res://data/items.gd")
const ENERGY_BAR := Vector2(52, 5)
var card: PanelContainer
var money_label: Label
var energy_label: Label
var energy_bar: Control
var boost_row: HBoxContainer
var float_layer: Control
var shown_energy := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card = UI.hud_card()
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	row.add_child(Icon.new("coin", 15, UI.SUCCESS))
	money_label = UI.label("", 14, UI.TEXT, 600)
	row.add_child(money_label)
	row.add_child(UI.spacer(0, 2))
	row.add_child(Icon.new("bolt", 15, UI.REWARD))
	var energy_stack := VBoxContainer.new()
	energy_stack.add_theme_constant_override("separation", 2)
	energy_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(energy_stack)
	energy_bar = Control.new()
	energy_bar.custom_minimum_size = ENERGY_BAR
	energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_bar.draw.connect(_draw_energy)
	energy_stack.add_child(energy_bar)
	energy_label = UI.label("", 11, UI.TEXT_MUTED)
	energy_stack.add_child(energy_label)
	boost_row = HBoxContainer.new()
	boost_row.add_theme_constant_override("separation", 4)
	boost_row.alignment = BoxContainer.ALIGNMENT_END
	boost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boost_row)
	float_layer = Control.new()
	float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(float_layer)
	Wallet.changed.connect(_on_money)
	Wellbeing.changed.connect(refresh)
	GameClock.minute_changed.connect(refresh)
	shown_energy = Wellbeing.energy_fraction()
	refresh()

func refresh() -> void:
	money_label.text = Wallet.formatted()
	var fraction := Wellbeing.energy_fraction()
	energy_label.text = "%d · %s" % [int(round(Wellbeing.energy)), Wellbeing.energy_state()]
	energy_label.add_theme_color_override("font_color", UI.DANGER if Wellbeing.energy < 20.0 else (UI.REWARD if Wellbeing.energy < 40.0 else UI.TEXT_MUTED))
	if not is_equal_approx(fraction, shown_energy):
		var tween := create_tween()
		tween.tween_method(func(value: float) -> void:
			shown_energy = value
			energy_bar.queue_redraw(), shown_energy, fraction, 0.4).set_trans(Tween.TRANS_SINE)
	_refresh_boosts()

func _refresh_boosts() -> void:
	for child in boost_row.get_children():
		boost_row.remove_child(child)
		child.queue_free()
	for boost in Wellbeing.active_boosts().slice(0, 4):
		var chip := UI.hud_card()
		chip.add_theme_stylebox_override("panel", UI.box(Color(UI.SURFACE, 0.82), 8, Color(UI.REWARD, 0.35), 1, Vector4(7, 3, 8, 3)))
		chip.tooltip_text = "%s · +%d%% XP" % [boost.name, int(round(float(boost.xp) * 100))]
		var chip_row := HBoxContainer.new()
		chip_row.add_theme_constant_override("separation", 4)
		chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(chip_row)
		chip_row.add_child(Icon.new(String(boost.icon), 12, UI.REWARD))
		chip_row.add_child(UI.label(_minutes(int(boost.minutes_left)), 11, UI.TEXT, 600))
		boost_row.add_child(chip)

static func _minutes(minutes: int) -> String:
	return "%dm" % minutes if minutes < 60 else "%dh%s" % [minutes / 60, ("%02d" % (minutes % 60)) if minutes % 60 else ""]

func _draw_energy() -> void:
	var rect := Rect2(Vector2.ZERO, ENERGY_BAR)
	energy_bar.draw_rect(rect, Color(1, 1, 1, 0.12))
	var color := UI.DANGER if Wellbeing.energy < 20.0 else UI.REWARD
	energy_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(ENERGY_BAR.x * clampf(shown_energy, 0.0, 1.0), ENERGY_BAR.y)), color)

func _on_money(_balance: int, delta: int, _label: String) -> void:
	refresh()
	if delta == 0 or not is_inside_tree():
		return
	var float_label := UI.label(("+" if delta > 0 else "") + Items.format_money(delta), 13, UI.SUCCESS if delta > 0 else UI.TEXT_MUTED, 600)
	float_label.add_theme_color_override("font_outline_color", Color(UI.INK, 0.9))
	float_label.add_theme_constant_override("outline_size", 4)
	float_label.position = Vector2(8, 0)
	float_layer.add_child(float_label)
	var tween := float_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(float_label, "position:y", -26.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tween.chain().tween_callback(float_label.queue_free)

extends VBoxContainer
## Notifications under the HUD's top bar: achievements, pay, boosts and skill
## points. Each toast slides in, holds and fades; at most three show at once
## and the rest wait their turn. Mouse-transparent, so it never blocks play.
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const MAX_VISIBLE := 3
const WIDTH := 360.0
var queue: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH / 2.0
	offset_right = WIDTH / 2.0
	offset_top = 70
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_theme_constant_override("separation", 6)

## `eyebrow` is the small caps line ("ACHIEVEMENT UNLOCKED"); `color` tints it and the icon.
func push(eyebrow: String, title: String, detail := "", icon := "spark", color := UI.REWARD, seconds := 3.6) -> void:
	queue.append([eyebrow, title, detail, icon, color, seconds])
	_pump()

func _pump() -> void:
	while not queue.is_empty() and get_child_count() < MAX_VISIBLE:
		var entry: Array = queue.pop_front()
		_show(entry[0], entry[1], entry[2], entry[3], entry[4], entry[5])

func _show(eyebrow: String, title: String, detail: String, icon: String, color: Color, seconds: float) -> void:
	var toast := PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel", UI.box(Color(UI.SURFACE, 0.94), 12, Color(color, 0.45), 1, Vector4(14, 10, 16, 10)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(row)
	var medal := PanelContainer.new()
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.add_theme_stylebox_override("panel", UI.box(Color(color, 0.16), 18, Color(color, 0.55), 1, Vector4(0, 0, 0, 0)))
	medal.custom_minimum_size = Vector2(36, 36)
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := Icon.new(icon, 18, color)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medal.add_child(glyph)
	row.add_child(medal)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	column.add_child(UI.label(eyebrow, 10, color, 600, true))
	column.add_child(UI.label(title, UI.SIZE_BODY, UI.TEXT, 600))
	if not detail.is_empty():
		var detail_label := UI.paragraph(detail, WIDTH - 90, UI.SIZE_CAPTION, UI.TEXT_MUTED)
		column.add_child(detail_label)
	toast.modulate.a = 0.0
	add_child(toast)
	var tween := toast.create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(seconds)
	tween.tween_property(toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		toast.queue_free()
		_pump.call_deferred())

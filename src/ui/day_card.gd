extends CanvasLayer
## A chapter-style title card for the start of a story day: the week and
## weekday, the date, the day's title and the block. It fades in over the
## world, holds and fades out; it never takes input.
const UI = preload("res://ui/style/ui_style.gd")
const HOLD_SECONDS := 2.6
var backdrop: ColorRect
var column: VBoxContainer

func _ready() -> void:
	layer = 110
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	add_child(root)
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(UI.INK, 0.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	column = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)
	column.modulate.a = 0.0

## Shows the card for a story day ({date, title, block}).
func show_day(day: Dictionary) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var date := String(day.get("date", YearCalendar.today_date()))
	var block: Dictionary = YearCalendar.block(String(day.get("block", "")))
	var eyebrow := UI.label(YearCalendar.day_heading(date).to_upper(), UI.SIZE_LABEL, UI.ACCENT, 600, true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var moment := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string(date + "T12:00:00"))
	var date_label := UI.label(GameClock.format_date(moment.year, moment.month, moment.day), UI.SIZE_BODY, UI.TEXT_MUTED, 500)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(date_label)
	var title := UI.label(String(day.get("title", "")), UI.SIZE_DISPLAY - 6, UI.TEXT, 600)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(UI.INK, 0.9))
	title.add_theme_constant_override("outline_size", 6)
	column.add_child(title)
	var rule := ColorRect.new()
	rule.color = Color(UI.REWARD, 0.8)
	rule.custom_minimum_size = Vector2(120, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(rule)
	if not block.is_empty():
		var block_label := UI.label("%s · %s" % [block.short, block.name], UI.SIZE_BODY, UI.REWARD, 500)
		block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(block_label)
	if not String(day.get("intro", "")).is_empty():
		var intro := UI.paragraph(String(day.intro), 560, UI.SIZE_BODY, UI.TEXT_MUTED)
		intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(intro)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(column, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(backdrop, "color:a", 0.55, 0.6)
	tween.chain().tween_interval(HOLD_SECONDS)
	tween.chain().set_parallel(true)
	tween.tween_property(column, "modulate:a", 0.0, 0.8)
	tween.tween_property(backdrop, "color:a", 0.0, 0.8)
	tween.chain().tween_callback(queue_free)

extends VBoxContainer
## Level and XP feedback, embedded in the exploration HUD's top bar:
## - a compact card with the level and an animated XP bar,
## - floating "+20 XP" values that rise and fade beside the bar,
## - a streak chip that appears only from 10 consecutive correct answers,
## - a brief, larger level-up banner with a particle burst and soft flash.
## All values come from AcademicSession; nothing here changes progression.
const KeyFont = preload("res://assets/outfit_medium.tres")
const BAR_SIZE := Vector2(110, 6)
const FILL := Color("f0a36f")
const GOLD := Color("ffd27a")
var card: PanelContainer
var level_label: Label
var xp_label: Label
var bar: Control
var streak_chip: PanelContainer
var streak_label: Label
var float_layer: Control
var overlay: CanvasLayer
var banner: PanelContainer
var banner_title: Label
var banner_levels: Label
var burst: CPUParticles2D
var flash: ColorRect
## Bar fill currently drawn (animated toward the real progress).
var shown_fraction := 0.0
var bar_tween: Tween
var banner_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card = _card()
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	level_label = _label(15, GOLD)
	row.add_child(level_label)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(stack)
	bar = Control.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	stack.add_child(bar)
	xp_label = _label(11, Color("b9d3cf"))
	stack.add_child(xp_label)
	streak_chip = _card()
	streak_chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	streak_label = _label(13, GOLD)
	streak_chip.add_child(streak_label)
	add_child(streak_chip)
	float_layer = Control.new()
	float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_layer.custom_minimum_size = Vector2(0, 0)
	add_child(float_layer)
	_build_overlay()
	AcademicSession.xp_changed.connect(_on_xp_changed)
	AcademicSession.level_up.connect(_on_level_up)
	AcademicSession.streak_changed.connect(_on_streak)
	shown_fraction = AcademicSession.level_progress().fraction
	_refresh_labels()
	_on_streak(AcademicSession.streak, false)

func _card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.15, 0.19, 0.72)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(font_size: int, color: Color, text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", KeyFont)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _refresh_labels() -> void:
	var progress: Dictionary = AcademicSession.level_progress()
	level_label.text = "LV %d" % progress.level
	var debt := mini(AcademicSession.xp_balance, 0)
	xp_label.text = "%d / %d XP" % [progress.into, progress.needed] + ("  (%d owed)" % -debt if debt < 0 else "")

func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, BAR_SIZE)
	bar.draw_rect(rect, Color(1, 1, 1, 0.14))
	bar.draw_rect(Rect2(Vector2.ZERO, Vector2(BAR_SIZE.x * clampf(shown_fraction, 0.0, 1.0), BAR_SIZE.y)), FILL)

func _set_shown(value: float) -> void:
	shown_fraction = value
	bar.queue_redraw()

## Animates the bar to the new progress. Crossing levels fills the bar,
## empties it and continues, so overflow visibly carries into the next level.
func _on_xp_changed(before: int, after: int, delta: int, reason: String) -> void:
	_float_value(delta)
	var levels_crossed := AcademicSession.LevelCurve.level_for_xp(after) - AcademicSession.LevelCurve.level_for_xp(before)
	var target: float = AcademicSession.level_progress().fraction
	if bar_tween:
		bar_tween.kill()
	bar_tween = create_tween()
	if levels_crossed > 0 and after > before:
		for index in range(levels_crossed):
			bar_tween.tween_method(_set_shown, shown_fraction if index == 0 else 0.0, 1.0, 0.35)
			bar_tween.tween_callback(_set_shown.bind(0.0))
		bar_tween.tween_method(_set_shown, 0.0, target, 0.45)
	else:
		bar_tween.tween_method(_set_shown, shown_fraction, target, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	bar_tween.tween_callback(_refresh_labels)
	_refresh_labels()

## A brief "+20 XP" (or red "−5 XP") that rises from under the bar and fades.
func _float_value(delta: int) -> void:
	if delta == 0:
		return
	var label := _label(16, Color("bff0cc") if delta > 0 else Color("f6a99a"), ("+%d XP" % delta) if delta > 0 else ("−%d XP" % -delta))
	label.add_theme_color_override("font_outline_color", Color("10252d"))
	label.add_theme_constant_override("outline_size", 5)
	label.name = "FloatingXP"
	float_layer.add_child(label)
	label.position = Vector2(card.size.x - 70, 2)
	label.pivot_offset = Vector2(30, 10)
	label.scale = Vector2(0.7, 0.7)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", 34.0, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.75)
	tween.chain().tween_callback(label.queue_free)

func _on_streak(value: int, animate := true) -> void:
	streak_chip.visible = AcademicSession.streak_visible()
	streak_label.text = "%dx STREAK" % value
	if streak_chip.visible and animate:
		streak_chip.pivot_offset = streak_chip.size / 2.0
		var tween := streak_chip.create_tween()
		tween.tween_property(streak_chip, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(streak_chip, "scale", Vector2.ONE, 0.18)

# --- Level up ---------------------------------------------------------------------

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 6
	add_child(overlay)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(root)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.93, 0.75, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	banner = PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.14, 0.18, 0.92)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	banner.add_theme_stylebox_override("panel", style)
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.anchor_top = 0.0
	banner.anchor_bottom = 0.0
	banner.offset_top = 96
	banner.offset_bottom = 96
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(banner)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	banner.add_child(stack)
	banner_title = _label(34, GOLD, "LEVEL UP")
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(banner_title)
	banner_levels = _label(18, Color("f1f6f2"))
	banner_levels.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(banner_levels)
	burst = CPUParticles2D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 70
	burst.lifetime = 1.1
	burst.explosiveness = 0.95
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.initial_velocity_min = 140.0
	burst.initial_velocity_max = 320.0
	burst.gravity = Vector2(0, 260)
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 5.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.86, 0.5, 1.0))
	ramp.set_color(1, Color(1.0, 0.6, 0.35, 0.0))
	burst.color_ramp = ramp
	root.add_child(burst)
	banner.hide()

func _on_level_up(from_level: int, to_level: int) -> void:
	banner_levels.text = "Level %d → Level %d" % [from_level, to_level]
	banner.show()
	banner.modulate.a = 1.0
	await get_tree().process_frame # Let the banner size itself before animating.
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2(0.55, 0.55)
	burst.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0, 96 + banner.size.y / 2.0)
	burst.restart()
	burst.emitting = true
	if banner_tween:
		banner_tween.kill()
	banner_tween = create_tween()
	banner_tween.tween_property(banner, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.parallel().tween_property(flash, "color:a", 0.16, 0.12)
	banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.15)
	banner_tween.parallel().tween_property(flash, "color:a", 0.0, 0.35)
	banner_tween.tween_interval(1.6)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	banner_tween.tween_callback(banner.hide)

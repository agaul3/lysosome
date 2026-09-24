extends RefCounted
## The game's visual language: one palette, one type scale, one set of
## component styles, shared by the title, menus, HUD and lecture overlays.
##
## Direction: a modern learning platform crossed with a polished RPG.
## Deep ink surfaces, a single academic teal accent for interaction and
## navigation, warm gold reserved for progression and rewards, and quiet
## semantic colours for feedback. Outfit throughout, at four weights.

# --- Palette ----------------------------------------------------------------------
const INK := Color("0b161c")          # Deepest background
const SURFACE := Color("12222a")      # Panels
const SURFACE_RAISED := Color("1a2d36")  # Cards within panels
const SURFACE_HOVER := Color("213843")
const LINE := Color("2c4550")         # Hairlines and borders
const LINE_SOFT := Color("223741")
const TEXT := Color("eef3f1")
const TEXT_MUTED := Color("a3b6b8")
const TEXT_FAINT := Color("6d8589")
const ACCENT := Color("5ec8b5")       # Interaction, focus, navigation
const ACCENT_DEEP := Color("2f8f82")
const REWARD := Color("f2c46d")       # XP, levels, streaks
const SUCCESS := Color("7fd6a0")
const DANGER := Color("ef8f7f")
const INFO := Color("8fb5e8")
## HUD cards float over the 3D world, so they are slightly translucent.
const HUD_SURFACE := Color(0.05, 0.11, 0.14, 0.8)

# --- Type scale -------------------------------------------------------------------
const SIZE_CAPTION := 12
const SIZE_LABEL := 13
const SIZE_BODY := 15
const SIZE_TITLE := 19
const SIZE_HEADING := 26
const SIZE_DISPLAY := 46

static var _fonts := {}
static var _theme: Theme

## Outfit at a given weight (400 regular, 500 medium, 600 semibold, 700 bold).
static func font(weight := 500) -> Font:
	if not _fonts.has(weight):
		var variation := FontVariation.new()
		variation.base_font = preload("res://assets/Outfit.ttf")
		variation.variation_opentype = {2003265652: float(weight)}
		_fonts[weight] = variation
	return _fonts[weight]

## Label factory with the type scale. `caps` adds letter spacing for eyebrows.
static func label(text: String, size := SIZE_BODY, color := TEXT, weight := 500, caps := false) -> Label:
	var result := Label.new()
	result.text = text.to_upper() if caps else text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", font(weight) if not caps else _spaced(weight))
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func _spaced(weight: int) -> Font:
	var key := "caps%d" % weight
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = font(weight)
		variation.spacing_glyph = 1
		_fonts[key] = variation
	return _fonts[key]

## Wrapping paragraph.
static func paragraph(text: String, width: float, size := SIZE_BODY, color := TEXT_MUTED) -> Label:
	var result := label(text, size, color, 400)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x = width
	return result

# --- Surfaces ---------------------------------------------------------------------

static func box(fill: Color, radius := 10, border := Color.TRANSPARENT, border_width := 0, padding := Vector4(16, 12, 16, 12)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = padding.x
	style.content_margin_top = padding.y
	style.content_margin_right = padding.z
	style.content_margin_bottom = padding.w
	style.anti_aliasing = true
	return style

static func panel_style() -> StyleBoxFlat:
	var style := box(Color(SURFACE, 0.97), 14, LINE_SOFT, 1, Vector4(0, 0, 0, 0))
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 6)
	return style

static func card_style() -> StyleBoxFlat:
	return box(SURFACE_RAISED, 10, LINE_SOFT, 1, Vector4(16, 14, 16, 14))

static func hud_style() -> StyleBoxFlat:
	return box(HUD_SURFACE, 8, Color(1, 1, 1, 0.06), 1, Vector4(11, 6, 11, 7))

static func card(padding := Vector4(16, 14, 16, 14), fill := SURFACE_RAISED) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", box(fill, 10, LINE_SOFT, 1, padding))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func hud_card() -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", hud_style())
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

## Small rounded status chip, e.g. "ON TIME" or "UPCOMING".
static func chip(text: String, color: Color) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", box(Color(color, 0.14), 6, Color(color, 0.35), 1, Vector4(8, 2, 8, 3)))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(label(text, 11, color, 600, true))
	result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result

## Gives a button extra left padding (room for a drawn icon) in every state,
## keeping the look of its theme type.
static func pad_left(button: Button, amount: float) -> void:
	var type: String = button.theme_type_variation if not button.theme_type_variation.is_empty() else "Button"
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		button.remove_theme_stylebox_override(state)
		var style: StyleBox = theme().get_stylebox(state, type).duplicate()
		style.content_margin_left = amount
		button.add_theme_stylebox_override(state, style)

static func hairline(vertical := false) -> ColorRect:
	var line := ColorRect.new()
	line.color = LINE_SOFT
	line.custom_minimum_size = Vector2(1, 0) if vertical else Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

static func spacer(height := 0.0, width := 0.0, expand := false) -> Control:
	var result := Control.new()
	result.custom_minimum_size = Vector2(width, height)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		result.size_flags_vertical = Control.SIZE_EXPAND_FILL
		result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

# --- Theme ------------------------------------------------------------------------

## The shared Theme: buttons (default, PrimaryButton, NavButton, GhostButton),
## sliders, check buttons, scroll bars and tooltips.
static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(500)
	t.default_font_size = SIZE_BODY
	t.set_color("font_color", "Label", TEXT)
	# Default (secondary) button: outlined surface.
	_button_styles(t, "Button", SURFACE_RAISED, SURFACE_HOVER, LINE, TEXT)
	# Primary: filled accent with dark text.
	t.set_type_variation("PrimaryButton", "Button")
	_button_styles(t, "PrimaryButton", ACCENT, ACCENT.lightened(0.12), ACCENT, INK)
	# Navigation rows in the menu sidebar: flat until hovered or selected.
	t.set_type_variation("NavButton", "Button")
	_button_styles(t, "NavButton", Color.TRANSPARENT, Color(1, 1, 1, 0.05), Color.TRANSPARENT, TEXT_MUTED, 8)
	t.set_stylebox("pressed", "NavButton", box(Color(ACCENT, 0.13), 8, Color.TRANSPARENT, 0, Vector4(12, 8, 12, 8)))
	t.set_color("font_pressed_color", "NavButton", TEXT)
	t.set_color("font_hover_pressed_color", "NavButton", TEXT)
	t.set_constant("h_separation", "NavButton", 12)
	t.set_stylebox("focus", "NavButton", box(Color.TRANSPARENT, 8, Color(ACCENT, 0.4), 1, Vector4(0, 0, 0, 0)))
	# Selectable cards (character presets): accent edge when chosen.
	t.set_type_variation("CardButton", "Button")
	_button_styles(t, "CardButton", Color(SURFACE, 0.85), SURFACE_HOVER, LINE_SOFT, TEXT, 10)
	t.set_stylebox("pressed", "CardButton", box(Color(ACCENT, 0.12), 10, ACCENT, 1, Vector4(16, 10, 16, 10)))
	t.set_stylebox("hover_pressed", "CardButton", box(Color(ACCENT, 0.16), 10, ACCENT, 1, Vector4(16, 10, 16, 10)))
	# Ghost: text-only actions.
	t.set_type_variation("GhostButton", "Button")
	_button_styles(t, "GhostButton", Color.TRANSPARENT, Color(1, 1, 1, 0.05), Color.TRANSPARENT, TEXT_MUTED)
	# Slider.
	t.set_stylebox("slider", "HSlider", box(LINE, 3, Color.TRANSPARENT, 0, Vector4(0, 3, 0, 3)))
	var fill := box(ACCENT, 3, Color.TRANSPARENT, 0, Vector4(0, 3, 0, 3))
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _dot(9, TEXT))
	t.set_icon("grabber_highlight", "HSlider", _dot(10, Color.WHITE))
	# Check button: pill switch drawn as icons.
	t.set_icon("checked", "CheckButton", _switch(true))
	t.set_icon("unchecked", "CheckButton", _switch(false))
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", TEXT)
	t.set_color("font_pressed_color", "CheckButton", TEXT)
	t.set_stylebox("focus", "CheckButton", box(Color.TRANSPARENT, 8, ACCENT, 1, Vector4(4, 4, 4, 4)))
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		t.set_stylebox(state, "CheckButton", box(Color.TRANSPARENT, 8, Color.TRANSPARENT, 0, Vector4(0, 4, 0, 4)))
	# Scroll bars: slim and quiet.
	t.set_stylebox("scroll", "VScrollBar", box(Color(1, 1, 1, 0.03), 3, Color.TRANSPARENT, 0, Vector4(3, 0, 3, 0)))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(state, "VScrollBar", box(Color(1, 1, 1, 0.18 if state == "grabber" else 0.3), 3, Color.TRANSPARENT, 0, Vector4(3, 0, 3, 0)))
	# Tooltips.
	t.set_stylebox("panel", "TooltipPanel", box(SURFACE_RAISED, 6, LINE, 1, Vector4(10, 6, 10, 6)))
	t.set_color("font_color", "TooltipLabel", TEXT)
	_theme = t
	return t

static func _button_styles(t: Theme, type: String, fill: Color, hover: Color, border: Color, text: Color, radius := 9) -> void:
	var padding := Vector4(16, 10, 16, 10) if type != "NavButton" else Vector4(12, 8, 12, 8)
	t.set_stylebox("normal", type, box(fill, radius, border, 1 if border.a > 0 else 0, padding))
	t.set_stylebox("hover", type, box(hover, radius, border.lightened(0.1) if border.a > 0 else border, 1 if border.a > 0 else 0, padding))
	t.set_stylebox("pressed", type, box(hover.darkened(0.08), radius, border, 1 if border.a > 0 else 0, padding))
	t.set_stylebox("hover_pressed", type, box(hover, radius, border, 1 if border.a > 0 else 0, padding))
	t.set_stylebox("disabled", type, box(Color(fill, fill.a * 0.4), radius, Color(border, border.a * 0.4), 1 if border.a > 0 else 0, padding))
	# Focus ring sits just outside the button so it shows on filled buttons too.
	var focus := box(Color.TRANSPARENT, radius + 3, Color(ACCENT, 0.9), 2, Vector4(0, 0, 0, 0))
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	t.set_stylebox("focus", type, focus)
	t.set_color("font_color", type, text)
	t.set_color("font_hover_color", type, text if type != "NavButton" else TEXT)
	t.set_color("font_pressed_color", type, text)
	t.set_color("font_focus_color", type, text if type != "NavButton" else TEXT)
	t.set_color("font_disabled_color", type, Color(text, 0.35))
	t.set_color("icon_normal_color", type, text)
	t.set_color("icon_hover_color", type, TEXT if type == "NavButton" else text)
	t.set_color("icon_pressed_color", type, ACCENT if type == "NavButton" else text)
	t.set_color("icon_focus_color", type, TEXT if type == "NavButton" else text)

static func _dot(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2 + 2
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - size / 2.0, y + 0.5 - size / 2.0).length()
			image.set_pixel(x, y, Color(color, clampf(radius - d + 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)

static func _switch(on: bool) -> ImageTexture:
	var w := 38
	var h := 20
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := ACCENT if on else LINE
	var knob_x := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, h / 2.0, w - h / 2.0)
			var d_track := p.distance_to(Vector2(cx, h / 2.0))
			var color := Color(track, clampf(h / 2.0 - d_track + 0.5, 0.0, 1.0))
			var d_knob := p.distance_to(Vector2(knob_x, h / 2.0))
			var knob := clampf(h / 2.0 - 3.0 - d_knob + 0.5, 0.0, 1.0)
			color = color.lerp(Color(TEXT if on else TEXT_MUTED, 1.0), knob) if color.a > 0 else color
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

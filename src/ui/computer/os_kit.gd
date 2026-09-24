extends RefCounted
## Shared pieces for the in-game computers: system fonts (the host's Segoe UI
## or San Francisco when present, otherwise a close fallback), style boxes,
## and original pixel-art icons drawn from 16×16 maps so every app icon
## matches the game's blocky look. Textures are cached and nearest-filtered.
static var _icons := {}
static var _fonts := {}

const PALETTE := {
	"w": Color("ffffff"), "W": Color("dfe7f1"), "k": Color("1d232b"), "g": Color("8b96a3"), "G": Color("5c6672"),
	"l": Color("c7d0da"), "b": Color("2f6fcf"), "B": Color("1f4f9e"), "c": Color("5fb4ff"), "C": Color("9fd7ff"),
	"y": Color("f4c542"), "Y": Color("d99a1e"), "o": Color("f08a3c"), "r": Color("e5484d"), "R": Color("a8262b"),
	"e": Color("36c27a"), "E": Color("1f8a52"), "t": Color("35b7c9"), "p": Color("a16bd8"), "s": Color("f2d3b1"),
	"n": Color("7a5236"), "m": Color("e9eef4"), "d": Color("3b4452"),
}

const ICONS := {
	"anki": [
		"..bbbbbbbbbbbb..",
		".bbbbbbbbbbbbbb.",
		"bbbbbbbbbbbbbbbb",
		"bbbbbbbwwbbbbbbb",
		"bbbbbbbwwbbbbbbb",
		"bbbbbbwwwwbbbbbb",
		"bbwwwwwwwwwwwwbb",
		"bbbwwwwwwwwwwbbb",
		"bbbbwwwwwwwwbbbb",
		"bbbbbwwwwwwbbbbb",
		"bbbbwwwwwwwwbbbb",
		"bbbbwwwbbwwwbbbb",
		"bbbwwbbbbbbwwbbb",
		"bbbbbbbbbbbbbbbb",
		".BBBBBBBBBBBBBB.",
		"..BBBBBBBBBBBB..",
	],
	"windows": [
		"................",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		"................",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
		".ccccccc.ccccccc",
	],
	"folder": [
		"................",
		"................",
		".YYYYY..........",
		"YyyyyyY.........",
		"YyyyyyyYYYYYYYY.",
		"Yyyyyyyyyyyyyyy.",
		"YyyyyyyyyyyyyyyY",
		"YyyyyyyyyyyyyyyY",
		"YyyyyyyyyyyyyyyY",
		"YyyyyyyyyyyyyyyY",
		"YyyyyyyyyyyyyyyY",
		"YyyyyyyyyyyyyyyY",
		"YyyyyyyyyyyyyyyY",
		".YYYYYYYYYYYYYY.",
		"................",
		"................",
	],
	"browser": [
		".....cccccc.....",
		"...cccccccccc...",
		"..cccCCCCCcccc..",
		".cccCCccccCCccc.",
		".ccCCcccccccCcc.",
		"cccCccttttcccccc",
		"cccCcttEEttccccc",
		"cccccttEEEttcccc",
		"ccccctttEEttcccc",
		"cccccctttttccccc",
		".cccccctttttccc.",
		".tttccccctttttc.",
		"..tttttttttttt..",
		"...ttttttttttt..",
		".....tttttt.....",
		"................",
	],
	"recycle": [
		"................",
		".....gggggg.....",
		"..gggggggggggg..",
		"..llllllllllll..",
		"...lWlWlWlWlW...",
		"...lWlWlWlWlW...",
		"...lWleeeWlWl...",
		"...lWeWlWeWlW...",
		"...lWlWlWeWlW...",
		"...lWleWlWlWl...",
		"...lWeeelWlWl...",
		"...lWlWlWlWlW...",
		"...lWlWlWlWlW...",
		"....llllllll....",
		"................",
		"................",
	],
	"pc": [
		"................",
		".dddddddddddddd.",
		".dccccccccccccd.",
		".dcCcccccccccccd",
		".dccCccccccccccd",
		".dccccccccccccd.",
		".dccccccccccccd.",
		".dccccccccccccd.",
		".dccccccccccccd.",
		".dddddddddddddd.",
		"......dddd......",
		"......dddd......",
		"....dddddddd....",
		"................",
		"................",
		"................",
	],
	"gear": [
		"................",
		"......gggg......",
		"..gg..gggg..gg..",
		"..ggggggggggggg.",
		"...gggggggggg...",
		"..gggggllgggggg.",
		"gggggllllllggggg",
		"ggggglllllllgggg",
		"gggggllllllggggg",
		"..gggggllgggggg.",
		"...gggggggggg...",
		"..ggggggggggggg.",
		"..gg..gggg..gg..",
		"......gggg......",
		"................",
		"................",
	],
	"finder": [
		"cccccccCbbbbbbbb",
		"cccccccCbbbbbbbb",
		"ccccccCCbbbbbbbb",
		"cccckccCbbbbkbbb",
		"cccckccCbbbbkbbb",
		"cccckcCbbbbbkbbb",
		"cccccCCbbbbbbbbb",
		"cccccCbbbbbbbbbb",
		"cccccCCbbbbbbbbb",
		"cccccccCbbbbbbbb",
		"cckccccCbbbbbkbb",
		"ccckkkkkkkkkkbbb",
		"cccccccCbbbbbbbb",
		"cccccccCbbbbbbbb",
		"cccccccCbbbbbbbb",
		"cccccccCbbbbbbbb",
	],
	"safari": [
		".....wwwwww.....",
		"...wwccccccww...",
		"..wccccccccccw..",
		".wccccccccccrcw.",
		".wcccccccccrrcw.",
		"wccccccccrrrcccw",
		"wcccccccrrrccccw",
		"wccccccwrrcccccw",
		"wcccccwwwccccccw",
		"wccccwwwcccccccw",
		"wcccwwwccccccccw",
		".wcwwwcccccccccw",
		".wcwwcccccccccw.",
		"..wccccccccccw..",
		"...wwccccccww...",
		".....wwwwww.....",
	],
	"launchpad": [
		"................",
		".ggggggggggggggg",
		".gGGGGGGGGGGGGGg",
		".gGrrGGyyGGeeGGg",
		".gGrrGGyyGGeeGGg",
		".gGGGGGGGGGGGGGg",
		".gGbbGGppGGttGGg",
		".gGbbGGppGGttGGg",
		".gGGGGGGGGGGGGGg",
		".gGooGGccGGrrGGg",
		".gGooGGccGGrrGGg",
		".gGGGGGGGGGGGGGg",
		".ggggggggggggggg",
		"................",
		"................",
		"................",
	],
	"notes": [
		"..yyyyyyyyyyyy..",
		".yyyyyyyyyyyyyy.",
		".YYYYYYYYYYYYYY.",
		".wwwwwwwwwwwwww.",
		".wggggggggggggw.",
		".wwwwwwwwwwwwww.",
		".wggggggggggggw.",
		".wwwwwwwwwwwwww.",
		".wgggggggggwwww.",
		".wwwwwwwwwwwwww.",
		".wggggggggggggw.",
		".wwwwwwwwwwwwww.",
		".wgggggggwwwwww.",
		".wwwwwwwwwwwwww.",
		"..wwwwwwwwwwww..",
		"................",
	],
	"trash": [
		"................",
		"......llll......",
		"..llllllllllll..",
		"..gggggggggggg..",
		"...lglglglglgl..",
		"...glglglglglg..",
		"...lglglglglgl..",
		"...glglglglglg..",
		"...lglglglglgl..",
		"...glglglglglg..",
		"...lglglglglgl..",
		"...glglglglglg..",
		"....llllllll....",
		"................",
		"................",
		"................",
	],
	"person": [
		"................",
		"................",
		"......llll......",
		".....llllll.....",
		".....llllll.....",
		".....llllll.....",
		"......llll......",
		"................",
		"....llllllll....",
		"...llllllllll...",
		"..llllllllllll..",
		"..llllllllllll..",
		"..llllllllllll..",
		"................",
		"................",
		"................",
	],
	"wifi": [
		"................",
		"................",
		"....wwwwwwww....",
		"..ww........ww..",
		".w............w.",
		"......wwww......",
		"....ww....ww....",
		"...w........w...",
		"................",
		"......wwww......",
		".....w....w.....",
		"................",
		".......ww.......",
		".......ww.......",
		"................",
		"................",
	],
	"volume": [
		"................",
		"................",
		"......w.........",
		".....ww.....w...",
		"....www...w..w..",
		"wwwwwww....w..w.",
		"wwwwwww..w..w.w.",
		"wwwwwww..w..w.w.",
		"wwwwwww..w..w.w.",
		"wwwwwww....w..w.",
		"....www...w..w..",
		".....ww.....w...",
		"......w.........",
		"................",
		"................",
		"................",
	],
	"battery": [
		"................",
		"................",
		"................",
		"................",
		".wwwwwwwwwwwww..",
		".w...........w..",
		".w.wwwwwwwww.ww.",
		".w.wwwwwwwww.ww.",
		".w.wwwwwwwww.ww.",
		".w.wwwwwwwww.ww.",
		".w...........w..",
		".wwwwwwwwwwwww..",
		"................",
		"................",
		"................",
		"................",
	],
	"search": [
		"................",
		"................",
		"....wwwww.......",
		"...w.....w......",
		"..w.......w.....",
		"..w.......w.....",
		"..w.......w.....",
		"..w.......w.....",
		"...w.....w......",
		"....wwwwwww.....",
		"..........ww....",
		"...........ww...",
		"............ww..",
		".............w..",
		"................",
		"................",
	],
	"power": [
		"................",
		"................",
		".......ww.......",
		"...w...ww...w...",
		"..w....ww....w..",
		".w.....ww.....w.",
		".w.....ww.....w.",
		".w............w.",
		".w............w.",
		".w............w.",
		"..w..........w..",
		"...w........w...",
		"....wwwwwwww....",
		"................",
		"................",
		"................",
	],
	"lock": [
		"................",
		"................",
		".....wwwwww.....",
		"....w......w....",
		"....w......w....",
		"....w......w....",
		"...wwwwwwwwwww..",
		"...wwwwwwwwwww..",
		"...wwwww.wwwww..",
		"...wwwww.wwwww..",
		"...wwwwwwwwwww..",
		"...wwwwwwwwwww..",
		"...wwwwwwwwwww..",
		"................",
		"................",
		"................",
	],
	"taskview": [
		"................",
		"................",
		"..wwwwwwwwwwww..",
		"..w....ww....w..",
		"..w....ww....w..",
		"..w....ww....w..",
		"..wwwwwwwwwwww..",
		"................",
		"..wwwwwwwwwwww..",
		"..w..........w..",
		"..w..........w..",
		"..wwwwwwwwwwww..",
		"................",
		"................",
		"................",
		"................",
	],
	"fruit": [
		"................",
		"..........ww....",
		".........ww.....",
		"........ww......",
		"....www....www..",
		"...wwwwwwwwwwww.",
		"..wwwwwwwwwwww..",
		"..wwwwwwwwwww...",
		"..wwwwwwwwwww...",
		"..wwwwwwwwwwww..",
		"...wwwwwwwwwwww.",
		"...wwwwwwwwwww..",
		"....wwwwwwwww...",
		".....www..www...",
		"................",
		"................",
	],
}

## A cached, nearest-filtered texture for a named icon; `tint` recolours
## white glyph pixels (tray and menu-bar icons).
static func icon(name: String, tint := Color.WHITE) -> Texture2D:
	var key := name + tint.to_html()
	if _icons.has(key):
		return _icons[key]
	var rows: Array = ICONS.get(name, ICONS["anki"])
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(16):
		var row: String = rows[y]
		for x in range(mini(16, row.length())):
			var ch := row[x]
			if ch == ".":
				continue
			var color: Color = PALETTE.get(ch, Color.MAGENTA)
			if ch == "w" and tint != Color.WHITE:
				color = tint
			image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	_icons[key] = texture
	return texture

## An icon as a sized TextureRect with crisp pixels.
static func icon_rect(name: String, edge: float, tint := Color.WHITE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon(name, tint)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(edge, edge)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## The host's UI font when installed (Segoe UI on Windows, San Francisco on
## macOS), otherwise a clean sans-serif fallback. `weight` 400–700.
static func font(os_style: String, weight := 400) -> Font:
	var key := "%s:%d" % [os_style, weight]
	if _fonts.has(key):
		return _fonts[key]
	var system := SystemFont.new()
	system.font_names = PackedStringArray(["Segoe UI", "Selawik", "Helvetica Neue", "Arial"] if os_style == "windows" else [".AppleSystemUIFont", "SF Pro Text", "Helvetica Neue", "Arial"])
	system.font_weight = weight
	system.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	_fonts[key] = system
	return system

## Arial-like font for card text (Anki's default card style).
static func card_font() -> Font:
	if _fonts.has("card"):
		return _fonts["card"]
	var system := SystemFont.new()
	system.font_names = PackedStringArray(["Arial", "Helvetica", "Liberation Sans"])
	_fonts["card"] = system
	return system

static func label(text: String, os_style: String, size: int, color: Color, weight := 400) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", font(os_style, weight))
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func box(fill: Color, radius := 0, border := Color.TRANSPARENT, border_width := 0, padding := Vector4.ZERO) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = padding.x
	style.content_margin_top = padding.y
	style.content_margin_right = padding.z
	style.content_margin_bottom = padding.w
	style.anti_aliasing = radius > 0
	return style

## A flat button with per-state fills; text colour stays constant.
static func flat_button(text: String, os_style: String, size: int, color: Color, fills: Array, radius := 0, padding := Vector4(10, 6, 10, 6), weight := 400) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font(os_style, weight))
	button.add_theme_font_size_override("font_size", size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, color)
	button.add_theme_color_override("font_disabled_color", Color(color, 0.4))
	var states := ["normal", "hover", "pressed", "disabled"]
	for index in range(states.size()):
		var fill: Color = fills[mini(index, fills.size() - 1)]
		button.add_theme_stylebox_override(states[index], box(fill, radius, Color.TRANSPARENT, 0, padding))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

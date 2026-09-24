extends RefCounted
## Paints a character's 64×64 pixel skin (Minecraft layout, see
## skin_layout.gd) from a look: skin tone, face, hair and an outfit.
##
## The base layer is opaque: skin, face, tops, bottoms, shoes and a lanyard.
## The overlay shell starts transparent and takes hair volume, outerwear,
## things worn over it (stethoscope, scarf, backpack straps), hats and
## eyewear. Every surface gets a little seeded pixel noise and simple hand
## shading, so each look always paints identically.
##   SkinPainter.new().paint(look) -> Image
const Layout = preload("res://character/skin_layout.gd")
const Clothing = preload("res://data/clothing.gd")
const SIDES := ["front", "right", "back", "left"]
const CLEAR := Color(0, 0, 0, 0)
const WHITE := Color("f4f2ee")
## Tops worn untucked, which hide a belt.
const UNTUCKED := ["sweater", "overshirt", "flannel", "turtleneck", "stripe"]
## Outerwear that hangs open down the front.
const OPEN_FRONT := ["hoodie", "cardigan", "blazer", "coat", "long_coat"]
var image: Image
var look: Dictionary
var slim := false
var seed := 0
var skin := Color.WHITE
var hair := Color.BLACK
var eye_rows: Array = [4]

func paint(target: Dictionary) -> Image:
	look = target
	slim = String(look.get("build", "classic")) == "slim"
	seed = absi(hash(JSON.stringify(look)))
	skin = Color(String(look.skin))
	hair = Color(String(look.hair_color))
	eye_rows = [3, 4] if String(look.eye_style) in ["round", "bright"] else [4]
	image = Image.create(Layout.SIZE, Layout.SIZE, false, Image.FORMAT_RGBA8)
	image.fill(CLEAR)
	var outfit: Dictionary = look.outfit
	_skin_base()
	_face()
	_hair()
	_bottom(Clothing.item(outfit.bottom))
	_shoes(Clothing.item(outfit.shoes))
	_top(Clothing.item(outfit.top))
	_belt(Clothing.item(outfit.bottom), Clothing.item(outfit.top))
	_neck(Clothing.item(outfit.neck), false)
	_outerwear(Clothing.item(outfit.outerwear))
	_neck(Clothing.item(outfit.neck), true)
	_straps(Clothing.item(outfit.back))
	_head_item(Clothing.item(outfit.head))
	_eyewear(Clothing.item(outfit.eyewear))
	return image

## A backpack's own small texture (24×14: an 8×10×4 box unwrapped).
static func paint_backpack(colors: Array) -> Image:
	var main: Color = colors[0]
	var dark: Color = colors[1]
	var accent: Color = colors[2]
	var bag := Image.create(24, 14, false, Image.FORMAT_RGBA8)
	bag.fill(main)
	for y in range(14):
		for x in range(24):
			var n := float(absi(hash(Vector2i(x, y * 7 + 3))) % 1000) / 1000.0 - 0.5
			bag.set_pixel(x, y, main.lightened(n * 0.1) if n > 0 else main.darkened(-n * 0.1))
	# Outer face (the "back" rect, 16..24 × 4..14): a front pocket with a zip.
	for x in range(17, 23):
		bag.set_pixel(x, 9, dark)
		bag.set_pixel(x, 13, dark.darkened(0.2))
	for y in range(9, 14):
		bag.set_pixel(17, y, dark)
		bag.set_pixel(22, y, dark)
	for x in range(17, 23):
		bag.set_pixel(x, 6, accent)
	bag.set_pixel(22, 6, accent.lightened(0.3))
	# Top: a grab handle.
	for x in range(6, 10):
		bag.set_pixel(x, 1, dark)
	return bag

# --- Pixel helpers --------------------------------------------------------------

func _rect(part: String, face: String) -> Rect2i:
	return Layout.face(part, face, slim)

func _put(part: String, face: String, col: int, row: int, color: Color) -> void:
	var r := _rect(part, face)
	if col < 0 or row < 0 or col >= r.size.x or row >= r.size.y:
		return
	image.set_pixel(r.position.x + col, r.position.y + row, color)

func _peek(part: String, face: String, col: int, row: int) -> Color:
	var r := _rect(part, face)
	return image.get_pixel(r.position.x + clampi(col, 0, r.size.x - 1), r.position.y + clampi(row, 0, r.size.y - 1))

## Deterministic noise in [-1, 1] for an atlas pixel.
func _noise(x: int, y: int) -> float:
	return float(absi(hash(Vector3i(x, y, seed))) % 2001) / 1000.0 - 1.0

func _grain(color: Color, part: String, face: String, col: int, row: int, amount: float) -> Color:
	var r := _rect(part, face)
	var n := _noise(r.position.x + col, r.position.y + row)
	return color.lightened(n * amount) if n > 0.0 else color.darkened(-n * amount)

## Gentle per-face shading: tops lighter, backs and undersides darker.
func _face_shade(face: String) -> float:
	return {"top": -0.05, "front": 0.0, "right": 0.03, "left": 0.03, "back": 0.05, "bottom": 0.1}.get(face, 0.0)

func _paint_px(part: String, face: String, col: int, row: int, color: Color, grain := 0.05) -> void:
	var shaded := color.darkened(_face_shade(face)) if _face_shade(face) > 0.0 else color.lightened(-_face_shade(face))
	_put(part, face, col, row, _grain(shaded, part, face, col, row, grain))

## Fills rows [from, to] (inclusive) of the listed faces of a part.
func _band(part: String, from: int, to: int, color: Color, grain := 0.05, faces := SIDES) -> void:
	for face in faces:
		var r := _rect(part, face)
		for row in range(maxi(from, 0), mini(to, r.size.y - 1) + 1):
			for col in range(r.size.x):
				_paint_px(part, face, col, row, color, grain)

func _fill(part: String, face: String, color: Color, grain := 0.05) -> void:
	var r := _rect(part, face)
	for row in range(r.size.y):
		for col in range(r.size.x):
			_paint_px(part, face, col, row, color, grain)

## The outer (away from the body) and inner faces of a limb.
func _outer(part: String) -> String:
	return "right" if part.begins_with("right") else "left"

func _inner(part: String) -> String:
	return "left" if part.begins_with("right") else "right"

func _arms(overlay := false) -> Array:
	return ["right_arm_overlay", "left_arm_overlay"] if overlay else ["right_arm", "left_arm"]

func _legs(overlay := false) -> Array:
	return ["right_leg_overlay", "left_leg_overlay"] if overlay else ["right_leg", "left_leg"]

## Ribbed knit: alternate columns a shade apart.
func _rib(part: String, from: int, to: int, color: Color, faces := SIDES) -> void:
	for face in faces:
		var r := _rect(part, face)
		for row in range(from, mini(to, r.size.y - 1) + 1):
			for col in range(r.size.x):
				_paint_px(part, face, col, row, color.darkened(0.1) if col % 2 == 0 else color, 0.03)

# --- Skin and face --------------------------------------------------------------

func _skin_base() -> void:
	for part in ["head", "body", "right_arm", "left_arm", "right_leg", "left_leg"]:
		for face in Layout.FACES:
			_fill(part, face, skin, 0.03)
	# A soft shadow under the chin and on the palms.
	for col in range(8):
		_paint_px("head", "front", col, 7, skin.darkened(0.05), 0.02)
	for arm in _arms():
		_band(arm, 11, 11, skin.darkened(0.05), 0.02)

func _face() -> void:
	var iris := Color(String(look.eye_color))
	var style := String(look.eye_style)
	var top_row: int = eye_rows[0]
	for row in eye_rows:
		match style:
			"bright":
				for col in [1, 2, 5, 6]:
					_put("head", "front", col, row, iris.lightened(0.12) if row == 4 else iris)
			"calm":
				for col in [1, 2, 5, 6]:
					_put("head", "front", col, row, iris.darkened(0.25))
			_:
				_put("head", "front", 1, row, WHITE)
				_put("head", "front", 2, row, iris)
				_put("head", "front", 5, row, iris)
				_put("head", "front", 6, row, WHITE)
	match style:
		"round":
			_put("head", "front", 2, 4, iris.darkened(0.35))
			_put("head", "front", 5, 4, iris.darkened(0.35))
		"bright":
			_put("head", "front", 1, 3, WHITE)
			_put("head", "front", 5, 3, WHITE)
		"calm":
			for col in [1, 2, 5, 6]:
				_put("head", "front", col, 3, skin.darkened(0.14))
		"narrow":
			for col in [1, 2, 5, 6]:
				_put("head", "front", col, 3, Color("2b2220"))
		"lashes":
			_put("head", "front", 1, 3, Color("2b2220"))
			_put("head", "front", 6, 3, Color("2b2220"))
	# Brows sit on the row above the eyes (two above when lashes take that row).
	var brow_row := top_row - 1 if style in ["classic", "calm", "round", "bright"] else top_row - 2
	if style in ["round", "bright"]:
		brow_row = 2
	var brow := hair.darkened(0.25) if hair.get_luminance() > 0.45 else hair.darkened(0.05)
	match String(look.brows):
		"soft":
			for col in [1, 2, 5, 6]:
				_put("head", "front", col, brow_row, brow.lerp(skin, 0.45))
		"straight":
			for col in [1, 2, 5, 6]:
				_put("head", "front", col, brow_row, brow)
		"bold":
			for col in [0, 1, 2, 5, 6, 7]:
				_put("head", "front", col, brow_row, brow.darkened(0.1))
	# Nose, mouth, cheeks and facial hair.
	var line := skin.darkened(0.3)
	_put("head", "front", 3, 5, skin.darkened(0.07))
	_put("head", "front", 4, 5, skin.darkened(0.07))
	match String(look.mouth):
		"neutral":
			_put("head", "front", 3, 6, line)
			_put("head", "front", 4, 6, line)
		"smile":
			_put("head", "front", 2, 5, line)
			_put("head", "front", 3, 6, line)
			_put("head", "front", 4, 6, line)
			_put("head", "front", 5, 5, line)
		"grin":
			_put("head", "front", 2, 6, line)
			_put("head", "front", 3, 6, WHITE)
			_put("head", "front", 4, 6, WHITE)
			_put("head", "front", 5, 6, line)
	match String(look.cheeks):
		"freckles":
			for spot in [Vector2i(0, 5), Vector2i(1, 6), Vector2i(6, 6), Vector2i(7, 5)]:
				_put("head", "front", spot.x, spot.y, skin.darkened(0.2))
		"blush":
			_put("head", "front", 1, 5, skin.lerp(Color("e8837e"), 0.4))
			_put("head", "front", 6, 5, skin.lerp(Color("e8837e"), 0.4))
	var beard := hair.darkened(0.08)
	match String(look.facial_hair):
		"stubble":
			for row in [6, 7]:
				for col in range(8):
					if _noise(col, row + 40) > -0.2 and not (row == 6 and col in [3, 4] and look.mouth != "none"):
						_put("head", "front", col, row, skin.lerp(hair, 0.38))
		"mustache":
			for col in [2, 3, 4, 5]:
				_put("head", "front", col, 5, beard)
		"goatee":
			for col in [2, 3, 4, 5]:
				_put("head", "front", col, 7, beard)
			_put("head", "front", 2, 6, beard)
			_put("head", "front", 5, 6, beard)
		"beard":
			for row in [6, 7]:
				for col in range(8):
					if not (row == 6 and col in [3, 4] and look.mouth != "none"):
						_put("head", "front", col, row, _grain(beard, "head", "front", col, row, 0.08))
			for col in [0, 1, 6, 7]:
				_put("head", "front", col, 5, beard)
			for row in range(4, 8):
				for col in range(4, 8):
					_put("head", "right", col, row, _grain(beard, "head", "right", col, row, 0.08))
				for col in range(0, 4):
					_put("head", "left", col, row, _grain(beard, "head", "left", col, row, 0.08))
			for row in range(0, 4):
				for col in range(8):
					_put("head", "bottom", col, row, beard.darkened(0.1))

# --- Hair -----------------------------------------------------------------------

func _hair_px(part: String, face: String, col: int, row: int, grain := 0.07) -> void:
	var color := hair.lightened(0.08) if face == "top" and row in [2, 3] and col % 3 != 0 else hair
	_put(part, face, col, row, _grain(color, part, face, col, row, grain))

## Hair over the top and down to the given number of rows on each side. On
## the overlay shell (chance < 1) the covered area stays solid and only its
## lowest row is ragged, so the silhouette reads as tufts rather than noise.
func _hair_cap(part: String, front_rows: int, side_rows: int, back_rows: int, chance := 1.0) -> void:
	for face in ["top", "front", "right", "left", "back"]:
		var rows := {"top": 8, "front": front_rows, "right": side_rows, "left": side_rows, "back": back_rows}[face] as int
		for row in range(rows):
			for col in range(8):
				var ragged: bool = chance < 1.0 and face != "top" and row == rows - 1
				if not ragged or _noise(_rect(part, face).position.x + col, row * 3 + 11) < chance * 2.0 - 1.0:
					_hair_px(part, face, col, row)

func _hair() -> void:
	match String(look.hair_style):
		"short":
			_hair_cap("head", 1, 2, 4)
			_hair_px("head", "front", 0, 1)
			_hair_px("head", "front", 7, 1)
			for row in [2, 3]:
				_hair_px("head", "right", 0, row)
				_hair_px("head", "right", 1, row)
				_hair_px("head", "left", 6, row)
				_hair_px("head", "left", 7, row)
			_hair_cap("head_overlay", 1, 1, 2, 0.6)
		"side_part":
			_hair_cap("head", 1, 3, 4)
			for col in range(3, 8):
				_hair_px("head", "front", col, 1)
			_hair_px("head", "front", 6, 2)
			_hair_px("head", "front", 7, 2)
			for row in range(8):
				_put("head", "top", 2, row, hair.darkened(0.18))
			for col in range(3, 8):
				_hair_px("head_overlay", "front", col, 0)
			for col in range(5, 8):
				_hair_px("head_overlay", "front", col, 1)
			_hair_cap("head_overlay", 0, 2, 2, 0.55)
		"messy":
			_hair_cap("head", 1, 3, 5)
			for col in [0, 1, 2, 4, 5, 6, 7]:
				_hair_px("head", "front", col, 1)
			for col in [0, 6, 7]:
				_hair_px("head", "front", col, 2)
			_hair_cap("head_overlay", 1, 3, 4, 0.7)
			for col in [1, 3, 4, 6]:
				_hair_px("head_overlay", "front", col, 1)
			for col in [2, 5]:
				_hair_px("head_overlay", "front", col, 2)
		"curly":
			_hair_cap("head", 2, 5, 6)
			for face in ["top", "front", "right", "left", "back"]:
				var rows := {"top": 8, "front": 2, "right": 5, "left": 5, "back": 6}[face] as int
				for row in range(rows):
					for col in range(8):
						if (col + row) % 2 == 0:
							_put("head", face, col, row, hair.darkened(0.16))
						if (col + row) % 2 == 1 or face == "top":
							_hair_px("head_overlay", face, col, row, 0.1)
		"buzz":
			for face in ["top", "front", "right", "left", "back"]:
				var rows := {"top": 8, "front": 1, "right": 3, "left": 3, "back": 5}[face] as int
				for row in range(rows):
					for col in range(8):
						_put("head", face, col, row, _grain(skin.lerp(hair, 0.55), "head", face, col, row, 0.1))
		"long":
			_hair_cap("head", 2, 8, 8)
			for row in range(2, 8):
				_hair_px("head", "front", 0, row)
				_hair_px("head", "front", 7, row)
			_hair_cap("head_overlay", 1, 8, 8, 0.85)
			for row in range(1, 7):
				_hair_px("head_overlay", "front", 0, row)
				_hair_px("head_overlay", "front", 7, row)
			for row in range(4):
				for col in range(1, 7):
					if row < 3 or col % 2 == 1:
						_hair_px("body_overlay", "back", col, row)
		"bob":
			_hair_cap("head", 2, 6, 6)
			for row in range(2, 6):
				_hair_px("head", "front", 0, row)
				_hair_px("head", "front", 7, row)
			_hair_cap("head_overlay", 2, 6, 6, 0.8)
		"bun", "ponytail":
			_hair_cap("head", 1, 2, 4)
			_hair_cap("head_overlay", 0, 1, 1, 0.4)
			var add_on := String(look.hair_style)
			for face in Layout.FACES:
				var r := _rect(add_on, face)
				for row in range(r.size.y):
					for col in range(r.size.x):
						_hair_px(add_on, face, col, row, 0.09)
			# A hair tie where it meets the head.
			var tie := hair.darkened(0.3) if hair.get_luminance() > 0.2 else hair.lerp(Color("6b6f78"), 0.3)
			var tie_row := _rect(add_on, "front").size.y - 1 if add_on == "bun" else 0
			for face in SIDES:
				for col in range(_rect(add_on, face).size.x):
					_put(add_on, face, col, tie_row, tie)

# --- Clothing: base layer ---------------------------------------------------------

func _sleeves(color: Color, last_row: int, cuff: Color, grain := 0.05) -> void:
	for arm in _arms():
		_band(arm, 0, last_row, color, grain)
		_fill(arm, "top", color, grain)
		if cuff != Color.TRANSPARENT:
			_band(arm, last_row, last_row, cuff, 0.03)

func _torso(color: Color, grain := 0.05) -> void:
	_band("body", 0, 11, color, grain)
	_fill("body", "top", color, grain)
	_fill("body", "bottom", color.darkened(0.1), grain)

func _top(item: Dictionary) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	var main: Color = c[0]
	var trim: Color = c[1] if c.size() > 1 else main.darkened(0.12)
	match String(item.kind):
		"tee":
			_torso(main, 0.04)
			_sleeves(main, 3, trim)
			for col in range(2, 6):
				_put("body", "front", col, 0, trim)
		"sweater", "turtleneck":
			_torso(main, 0.03)
			_sleeves(main, 9, Color.TRANSPARENT, 0.03)
			for face in SIDES:
				var r := _rect("body", face)
				for row in range(10):
					for col in range(r.size.x):
						if col % 2 == 0:
							_put("body", face, col, row, _peek("body", face, col, row).darkened(0.05))
			_rib("body", 10, 11, trim)
			for arm in _arms():
				_rib(arm, 8, 9, trim)
			if String(item.kind) == "turtleneck":
				_band("body", 0, 0, trim, 0.03)
			else:
				for col in range(2, 6):
					_put("body", "front", col, 0, trim)
		"henley":
			_torso(main, 0.04)
			_sleeves(main, 9, trim)
			var button: Color = c[2] if c.size() > 2 else WHITE
			for row in range(4):
				_put("body", "front", 3, row, trim)
			for row in [1, 2, 3]:
				_put("body", "front", 3, row, button)
			_put("body", "front", 4, 0, skin)
		"overshirt":
			_torso(main, 0.05)
			_sleeves(main, 9, trim)
			var button: Color = c[2] if c.size() > 2 else WHITE
			for row in range(12):
				_put("body", "front", 3, row, trim)
			for row in [2, 5, 8]:
				_put("body", "front", 3, row, button)
			for pocket in [1, 5]:
				for col in [pocket, pocket + 1]:
					_put("body", "front", col, 2, trim)
					_put("body", "front", col, 4, trim.darkened(0.1))
				_put("body", "front", pocket, 3, trim)
			_put("body", "front", 1, 0, main.lightened(0.12))
			_put("body", "front", 6, 0, main.lightened(0.12))
		"scrubs":
			_torso(main, 0.03)
			_sleeves(main, 4, trim)
			for spot in [Vector2i(3, 0), Vector2i(4, 0), Vector2i(3, 1), Vector2i(4, 1)]:
				_put("body", "front", spot.x, spot.y, skin)
			_put("body", "front", 2, 0, trim)
			_put("body", "front", 5, 0, trim)
			var pocket: Color = c[2] if c.size() > 2 else trim
			for col in [5, 6]:
				_put("body", "front", col, 3, pocket)
			_put("body", "front", 5, 4, pocket)
			_put("body", "front", 6, 4, pocket)
			_band("body", 11, 11, trim, 0.03)
		"stripe":
			_torso(main, 0.03)
			_sleeves(main, 9, Color.TRANSPARENT, 0.03)
			for part in ["body"] + _arms():
				for face in SIDES:
					var r := _rect(part, face)
					for row in range(1, 10 if part != "body" else 12, 2):
						for col in range(r.size.x):
							_paint_px(part, face, col, row, trim, 0.03)
		"oxford":
			_torso(main, 0.03)
			_sleeves(main, 9, main.lightened(0.15))
			var tie: Color = c[1] if c.size() > 1 else Color("6b2f3a")
			var stripe: Color = c[2] if c.size() > 2 else tie.lightened(0.2)
			for col in [1, 2, 5, 6]:
				_put("body", "front", col, 0, main.lightened(0.18))
			_put("body", "front", 3, 0, tie.darkened(0.2))
			_put("body", "front", 4, 0, tie.darkened(0.2))
			for row in range(1, 9):
				_put("body", "front", 3, row, stripe if row % 3 == 0 else tie)
				_put("body", "front", 4, row, tie.darkened(0.1))
			_put("body", "front", 3, 9, tie.darkened(0.15))
		"flannel":
			_torso(main, 0.04)
			_sleeves(main, 9, Color.TRANSPARENT, 0.04)
			var line: Color = c[1] if c.size() > 1 else main.darkened(0.4)
			var stitch: Color = c[2] if c.size() > 2 else WHITE
			for part in ["body"] + _arms():
				for face in SIDES:
					var r := _rect(part, face)
					for row in range(10 if part != "body" else 12):
						for col in range(r.size.x):
							var vertical := (r.position.x + col) % 4 == 0
							var horizontal := (r.position.y + row) % 4 == 0
							if vertical and horizontal:
								_put(part, face, col, row, line)
							elif vertical or horizontal:
								_put(part, face, col, row, main.darkened(0.28))
							elif (r.position.x + col + r.position.y + row) % 7 == 0:
								_put(part, face, col, row, main.lerp(stitch, 0.35))
			for row in [2, 5, 8]:
				_put("body", "front", 3, row, stitch)
		_:
			_torso(main)
			_sleeves(main, 3, trim)

func _bottom(item: Dictionary) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	var main: Color = c[0]
	var seam: Color = c[1] if c.size() > 1 else main.darkened(0.15)
	match String(item.kind):
		"jeans":
			for leg in _legs():
				_band(leg, 0, 10, main, 0.1)
				_fill(leg, "top", main, 0.08)
				for row in range(11):
					_put(leg, _outer(leg), 1, row, seam)
				for col in range(4):
					_put(leg, "front", col, 5, main.lightened(0.12))
					_put(leg, "front", col, 6, main.lightened(0.08))
				_band(leg, 10, 10, main.lightened(0.14), 0.04)
		"joggers":
			for leg in _legs():
				_band(leg, 0, 10, main, 0.05)
				_fill(leg, "top", main, 0.05)
				_rib(leg, 9, 10, seam)
				if c.size() > 2:
					for row in range(9):
						_put(leg, _outer(leg), 2, row, c[2])
		"chinos", "cargo":
			for leg in _legs():
				_band(leg, 0, 10, main, 0.04)
				_fill(leg, "top", main, 0.04)
				for row in range(10):
					_put(leg, "front", 1 if leg.begins_with("right") else 2, row, main.lightened(0.06))
				_put(leg, _outer(leg), 3 if leg.begins_with("right") else 0, 0, seam)
				_put(leg, _outer(leg), 3 if leg.begins_with("right") else 0, 1, seam)
				if String(item.kind) == "cargo":
					var flap: Color = c[2] if c.size() > 2 else seam
					for col in range(4):
						_put(leg, _outer(leg), col, 4, flap)
					for row in [5, 6]:
						_put(leg, _outer(leg), 0, row, seam)
						_put(leg, _outer(leg), 3, row, seam)
					for col in range(4):
						_put(leg, _outer(leg), col, 7, seam)
		"scrub_pants":
			for leg in _legs():
				_band(leg, 0, 10, main, 0.03)
				_fill(leg, "top", main, 0.03)
				_band(leg, 10, 10, seam, 0.03)
		"shorts":
			for leg in _legs():
				_band(leg, 0, 5, main, 0.05)
				_fill(leg, "top", main, 0.05)
				_band(leg, 5, 5, seam, 0.03)
				_put(leg, _outer(leg), 1, 2, seam)
				_put(leg, _outer(leg), 2, 2, seam)
				_band(leg, 9, 9, WHITE.darkened(0.04), 0.02)
		_:
			for leg in _legs():
				_band(leg, 0, 10, main)

func _belt(bottom: Dictionary, top: Dictionary) -> void:
	if bottom.is_empty() or not String(bottom.kind) in ["jeans", "chinos", "cargo"]:
		return
	if not top.is_empty() and String(top.kind) in UNTUCKED:
		return
	var leather: Color = bottom.colors[2] if bottom.colors.size() > 2 else Color("4a3527")
	_band("body", 11, 11, leather, 0.04)
	_put("body", "front", 3, 11, Color("c9b37a"))
	_put("body", "front", 4, 11, Color("a8925c"))

func _shoes(item: Dictionary) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	var main: Color = c[0]
	var sole: Color = c[1] if c.size() > 1 else WHITE
	var accent: Color = c[2] if c.size() > 2 else main.darkened(0.2)
	for leg in _legs():
		var outer := _outer(leg)
		match String(item.kind):
			"sneakers":
				_band(leg, 10, 11, main, 0.03)
				_band(leg, 11, 11, sole, 0.02)
				_put(leg, "front", 1, 10, accent)
				_put(leg, "front", 2, 10, accent)
				_put(leg, outer, 1, 10, accent)
			"hightops":
				_band(leg, 9, 11, main, 0.03)
				_band(leg, 11, 11, sole, 0.02)
				for col in range(4):
					_put(leg, "front", col, 11, sole.lightened(0.05))
				_put(leg, "front", 1, 9, accent)
				_put(leg, "front", 2, 10, accent)
				_put(leg, outer, 1, 9, sole)
				_put(leg, outer, 2, 9, sole)
			"runners":
				_band(leg, 10, 11, main, 0.03)
				_band(leg, 11, 11, sole, 0.02)
				_put(leg, outer, 0, 10, accent)
				_put(leg, outer, 1, 10, accent)
				_put(leg, outer, 2, 11, accent)
			"boots":
				_band(leg, 8, 11, main, 0.08)
				_band(leg, 8, 8, main.darkened(0.15), 0.04)
				_band(leg, 11, 11, sole, 0.03)
				for row in [8, 9, 10]:
					_put(leg, "front", 1 + row % 2, row, accent)
			"loafers":
				_band(leg, 10, 11, main, 0.02)
				_band(leg, 11, 11, sole, 0.02)
				for col in range(4):
					_put(leg, "front", col, 10, main.darkened(0.2))
				_put(leg, "front", 1, 11, main.lightened(0.25))
			"clogs":
				_band(leg, 10, 11, main, 0.03)
				_band(leg, 11, 11, sole, 0.02)
				_put(leg, "front", 1, 10, main.darkened(0.35))
				_put(leg, "front", 2, 10, main.darkened(0.35))
				_put(leg, outer, 1, 10, main.darkened(0.2))
			_:
				_band(leg, 10, 11, main)
		_fill(leg, "bottom", sole.darkened(0.25), 0.03)

func _neck(item: Dictionary, over: bool) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	match String(item.kind):
		"lanyard":
			if over:
				return
			var strap: Color = c[0]
			var card: Color = c[1] if c.size() > 1 else WHITE
			var photo: Color = c[2] if c.size() > 2 else Color("3d6fc4")
			for spot in [Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 2), Vector2i(5, 0), Vector2i(5, 1), Vector2i(4, 2)]:
				_put("body", "front", spot.x, spot.y, strap)
			for row in [3, 4, 5]:
				_put("body", "front", 3, row, card)
				_put("body", "front", 4, row, card)
			_put("body", "front", 3, 4, photo)
			for col in range(1, 7):
				_put("body", "back", col, 0, strap)
		"stethoscope":
			if not over:
				return
			var tube: Color = c[0]
			var metal: Color = c[1] if c.size() > 1 else Color("c9ced2")
			for row in range(5):
				_put("body_overlay", "front", 2, row, tube)
			for row in range(4):
				_put("body_overlay", "front", 5, row, tube)
			_put("body_overlay", "front", 5, 4, metal)
			_put("body_overlay", "front", 6, 4, metal.darkened(0.2))
			_put("body_overlay", "front", 2, 5, tube.lightened(0.2))
			for col in range(1, 7):
				_put("body_overlay", "back", col, 0, tube)
			for face in ["right", "left"]:
				for col in range(4):
					_put("body_overlay", face, col, 0, tube)
		"scarf":
			if not over:
				return
			var wool: Color = c[0]
			var line: Color = c[1] if c.size() > 1 else wool.darkened(0.3)
			var fringe: Color = c[2] if c.size() > 2 else wool.lightened(0.3)
			for face in SIDES:
				var r := _rect("body_overlay", face)
				for row in range(2):
					for col in range(r.size.x):
						_put("body_overlay", face, col, row, line if (r.position.x + col) % 3 == 0 else _grain(wool, "body_overlay", face, col, row, 0.06))
			for row in range(2, 7):
				for col in [2, 3]:
					_put("body_overlay", "front", col, row, line if row % 3 == 0 else wool)
			_put("body_overlay", "front", 2, 7, fringe)
			_put("body_overlay", "front", 3, 7, fringe)

# --- Clothing: overlay ---------------------------------------------------------------

func _jacket_body(color: Color, grain: float, last_row := 11) -> void:
	_band("body_overlay", 0, last_row, color, grain)
	_fill("body_overlay", "top", color, grain)

func _jacket_sleeves(color: Color, grain: float, cuff: Color, last_row := 10) -> void:
	for arm in _arms(true):
		_band(arm, 0, last_row, color, grain)
		_fill(arm, "top", color, grain)
		_band(arm, last_row, last_row, cuff, 0.03)

func _open_front(rows: int) -> void:
	for row in range(rows):
		_put("body_overlay", "front", 3, row, CLEAR)
		_put("body_overlay", "front", 4, row, CLEAR)

func _outerwear(item: Dictionary) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	var main: Color = c[0]
	var trim: Color = c[1] if c.size() > 1 else main.darkened(0.15)
	var accent: Color = c[2] if c.size() > 2 else WHITE
	match String(item.kind):
		"hoodie":
			_jacket_body(main, 0.05)
			_rib("body_overlay", 10, 11, trim)
			_jacket_sleeves(main, 0.05, trim)
			_open_front(12)
			for row in range(10):
				_put("body_overlay", "front", 2, row, trim)
				_put("body_overlay", "front", 5, row, trim)
			for col in range(8):
				for row in range(3):
					_put("body_overlay", "back", col, row, trim.lightened(0.05) if row == 1 else trim)
			for row in [1, 2, 3]:
				_put("body_overlay", "front", 2 if row < 3 else 1, row, accent)
				_put("body_overlay", "front", 5 if row < 3 else 6, row, accent)
			for col in [0, 1, 6, 7]:
				_put("body_overlay", "front", col, 7, trim)
		"cardigan":
			_jacket_body(main, 0.04)
			for face in SIDES:
				var r := _rect("body_overlay", face)
				for row in range(10):
					for col in range(0, r.size.x, 2):
						_put("body_overlay", face, col, row, _peek("body_overlay", face, col, row).darkened(0.06))
			_rib("body_overlay", 10, 11, trim)
			_jacket_sleeves(main, 0.04, trim, 9)
			_open_front(6)
			for row in [2, 4]:
				_put("body_overlay", "front", 2, row, accent)
			for row in [7, 9]:
				_put("body_overlay", "front", 3, row, accent)
		"zip_jacket":
			_jacket_body(main, 0.03)
			_jacket_sleeves(main, 0.03, trim)
			for row in range(12):
				_put("body_overlay", "front", 3, row, trim)
			_put("body_overlay", "front", 3, 1, accent)
			for col in range(1, 7):
				_put("body_overlay", "front", col, 0, main.lightened(0.1))
			_put("body_overlay", "front", 5, 2, accent)
			for col in [0, 1, 6, 7]:
				_put("body_overlay", "front", col, 8, trim)
			_band("body_overlay", 11, 11, trim, 0.03)
		"fleece":
			for part in ["body_overlay"] + _arms(true):
				for face in SIDES + ["top"]:
					var r := _rect(part, face)
					var rows := r.size.y if part == "body_overlay" or face == "top" else 11
					for row in range(rows):
						for col in range(r.size.x):
							var n := _noise(r.position.x + col, r.position.y + row + 90)
							var pile := main.lightened(0.1) if n > 0.55 else (main.darkened(0.12) if n < -0.55 else main)
							_paint_px(part, face, col, row, pile, 0.06)
			for col in range(1, 7):
				_put("body_overlay", "front", col, 0, trim)
			_band("body_overlay", 11, 11, trim, 0.03)
			for arm in _arms(true):
				_band(arm, 10, 10, trim, 0.03)
			for row in range(4):
				_put("body_overlay", "front", 3, row, trim)
			_put("body_overlay", "front", 3, 1, Color("d9dcdd"))
			_put("body_overlay", "front", 3, 3, Color("d9dcdd"))
			for row in [3, 4, 5]:
				for col in [5, 6]:
					_put("body_overlay", "front", col, row, trim if row > 3 else trim.darkened(0.12))
			_put("body_overlay", "front", 5, 4, accent)
			_put("body_overlay", "front", 6, 4, Color("e2b04a"))
		"puffer":
			_jacket_body(main, 0.04)
			_jacket_sleeves(main, 0.04, trim)
			for row in [2, 5, 8]:
				_band("body_overlay", row, row, trim, 0.02)
			for row in [1, 4, 7, 10]:
				for face in SIDES:
					for col in range(_rect("body_overlay", face).size.x):
						_put("body_overlay", face, col, row, _peek("body_overlay", face, col, row).lightened(0.08))
			for arm in _arms(true):
				for row in [3, 6, 9]:
					_band(arm, row, row, trim, 0.02)
			for row in range(12):
				_put("body_overlay", "front", 3, row, accent.darkened(0.3))
		"denim_jacket":
			_jacket_body(main, 0.09)
			_jacket_sleeves(main, 0.09, trim)
			_band("body_overlay", 2, 2, trim, 0.04)
			for row in range(12):
				_put("body_overlay", "front", 3, row, trim)
			for row in [3, 6, 9]:
				_put("body_overlay", "front", 3, row, accent)
			for pocket in [1, 5]:
				_put("body_overlay", "front", pocket, 3, trim)
				_put("body_overlay", "front", pocket + 1, 3, trim)
			_put("body_overlay", "front", 1, 4, accent)
			_put("body_overlay", "front", 6, 4, accent)
			_band("body_overlay", 11, 11, trim, 0.05)
		"bomber":
			_jacket_body(main, 0.04)
			_jacket_sleeves(main, 0.04, trim, 10)
			_rib("body_overlay", 10, 11, trim)
			for arm in _arms(true):
				_rib(arm, 9, 10, trim)
			for col in range(1, 7):
				_put("body_overlay", "front", col, 0, trim.lightened(0.15) if col % 2 else trim)
			for row in range(1, 10):
				_put("body_overlay", "front", 3, row, Color("b8b8b4"))
			_put("left_arm_overlay", "left", 1, 2, trim)
			_put("left_arm_overlay", "left", 2, 2, trim)
			_put("left_arm_overlay", "left", 2, 3, accent)
		"rain_shell":
			_jacket_body(main, 0.02)
			_jacket_sleeves(main, 0.02, trim)
			for col in range(8):
				for row in range(4):
					_put("body_overlay", "back", col, row, main.darkened(0.08 if row % 2 else 0.12))
			for row in range(12):
				_put("body_overlay", "front", 3, row, accent)
			_put("body_overlay", "front", 2, 1, accent)
			_put("body_overlay", "front", 5, 1, accent)
			for col in [0, 1, 6, 7]:
				_put("body_overlay", "front", col, 7, trim)
		"quarter_zip":
			_jacket_body(main, 0.03)
			_jacket_sleeves(main, 0.03, trim, 9)
			_rib("body_overlay", 10, 11, trim)
			for col in range(1, 7):
				_put("body_overlay", "front", col, 0, main.darkened(0.08))
			for row in range(4):
				_put("body_overlay", "front", 3, row, accent)
			_put("body_overlay", "front", 3, 3, accent.lightened(0.2))
		"varsity":
			_jacket_body(main, 0.04)
			for arm in _arms(true):
				_band(arm, 0, 10, trim, 0.03)
				_fill(arm, "top", trim, 0.03)
				_band(arm, 9, 9, accent, 0.02)
				_band(arm, 10, 10, main, 0.02)
			_band("body_overlay", 10, 10, accent, 0.02)
			_band("body_overlay", 11, 11, main.darkened(0.1), 0.02)
			for col in range(1, 7):
				_put("body_overlay", "front", col, 0, accent if col % 2 else main)
			for row in [2, 5, 8]:
				_put("body_overlay", "front", 3, row, accent)
			var letter := [[1, 0, 1], [1, 1, 1], [1, 0, 1]]
			for row in range(3):
				for col in range(3):
					if letter[row][col]:
						_put("body_overlay", "front", 5 + col, 2 + row, trim)
		"blazer":
			_jacket_body(main, 0.03)
			_jacket_sleeves(main, 0.03, trim, 9)
			_open_front(4)
			_put("body_overlay", "front", 2, 0, CLEAR)
			_put("body_overlay", "front", 5, 0, CLEAR)
			for spot in [Vector2i(2, 1), Vector2i(5, 1), Vector2i(2, 2), Vector2i(5, 2)]:
				_put("body_overlay", "front", spot.x, spot.y, main.lightened(0.12))
			_put("body_overlay", "front", 3, 5, Color("1e2226"))
			_put("body_overlay", "front", 3, 8, Color("1e2226"))
			for col in [0, 1, 6, 7]:
				_put("body_overlay", "front", col, 8, trim)
			_put("body_overlay", "front", 6, 2, Color("e9e2d4"))
			for arm in _arms(true):
				_put(arm, _outer(arm), 1, 8, accent)
				_put(arm, _outer(arm), 2, 8, accent)
		"coat", "long_coat":
			_jacket_body(main, 0.02)
			_jacket_sleeves(main, 0.02, trim, 9)
			_open_front(10)
			for spot in [Vector2i(2, 1), Vector2i(5, 1), Vector2i(2, 2), Vector2i(5, 2)]:
				_put("body_overlay", "front", spot.x, spot.y, trim)
			for col in [0, 1, 2, 5, 6, 7]:
				_put("body_overlay", "front", col, 8, trim)
			for row in [9, 10]:
				_put("body_overlay", "front", 0, row, trim)
				_put("body_overlay", "front", 7, row, trim)
			for col in [5, 6, 7]:
				_put("body_overlay", "front", col, 3, trim)
			_put("body_overlay", "front", 6, 2, accent)
			_put("body_overlay", "front", 5, 2, Color("2b2b2b"))
			_put("body_overlay", "front", 1, 3, WHITE)
			_put("body_overlay", "front", 2, 3, accent.lightened(0.1))
			for row in range(8, 12):
				_put("body_overlay", "back", 3, row, trim)
			if String(item.kind) == "long_coat":
				for leg in _legs(true):
					_band(leg, 0, 5, main, 0.02, ["front", _outer(leg), "back"])
					_band(leg, 5, 5, trim, 0.02, ["front", _outer(leg), "back"])
		_:
			_jacket_body(main, 0.04)
			_jacket_sleeves(main, 0.04, trim)

func _straps(item: Dictionary) -> void:
	if item.is_empty():
		return
	var strap: Color = item.colors[1] if item.colors.size() > 1 else Color("26363d")
	for row in range(6):
		_put("body_overlay", "front", 1, row, strap)
		_put("body_overlay", "front", 6, row, strap)
	for face in ["right", "left"]:
		for col in range(4):
			_put("body_overlay", face, col, 0, strap)

# --- Head items and eyewear -----------------------------------------------------------

func _head_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	var main: Color = c[0]
	var second: Color = c[1] if c.size() > 1 else main.darkened(0.15)
	match String(item.kind):
		"beanie":
			_fill("head_overlay", "top", main, 0.04)
			for face in SIDES:
				for row in range(3):
					for col in range(8):
						var color := second if row == 2 else main
						_put("head_overlay", face, col, row, _grain(color.darkened(0.08) if col % 2 == 0 else color, "head_overlay", face, col, row, 0.03))
		"cap":
			_fill("head_overlay", "top", main, 0.03)
			_put("head_overlay", "top", 3, 4, c[2] if c.size() > 2 else second)
			for face in SIDES:
				for row in range(2):
					for col in range(8):
						_put("head_overlay", face, col, row, _grain(main, "head_overlay", face, col, row, 0.03))
			for col in range(8):
				_put("head_overlay", "front", col, 1, second)
			_fill("brim", "top", main, 0.03)
			_fill("brim", "bottom", second, 0.02)
			_fill("brim", "front", second, 0.02)
			_fill("brim", "right", second, 0.02)
			_fill("brim", "left", second, 0.02)
		"scrub_cap":
			_fill("head_overlay", "top", main, 0.03)
			for face in SIDES:
				var rows := 4 if face == "back" else 3
				for row in range(rows):
					for col in range(8):
						_put("head_overlay", face, col, row, second if (col + row * 2) % 5 == 0 else main)
			var r := _rect("head_overlay", "top")
			for row in range(r.size.y):
				for col in range(r.size.x):
					if (col * 2 + row) % 5 == 0:
						_put("head_overlay", "top", col, row, second)

func _eyewear(item: Dictionary) -> void:
	if item.is_empty():
		return
	var c: Array = item.colors
	var frame: Color = c[0]
	var lens: Color = c[1] if c.size() > 1 else Color("3a3f44")
	var first: int = eye_rows[0]
	var last: int = eye_rows[-1]
	var kind := String(item.kind)
	for row in eye_rows:
		for col in [0, 3, 4, 7]:
			_put("head_overlay", "front", col, row, frame)
		if kind in ["sunglasses", "aviators"]:
			for col in [1, 2, 5, 6]:
				_put("head_overlay", "front", col, row, lens if kind == "aviators" else frame)
	match kind:
		"round_glasses":
			for col in [1, 2, 5, 6]:
				_put("head_overlay", "front", col, last + 1, frame)
		"rect_glasses":
			for col in [1, 2, 5, 6]:
				_put("head_overlay", "front", col, first - 1, frame)
				_put("head_overlay", "front", col, last + 1, frame)
		"sunglasses":
			for col in range(8):
				_put("head_overlay", "front", col, first - 1, frame)
			_put("head_overlay", "front", 1, first, lens)
			_put("head_overlay", "front", 5, first, lens)
		"aviators":
			for col in range(8):
				_put("head_overlay", "front", col, first - 1, frame)
			for col in [1, 2, 5, 6]:
				_put("head_overlay", "front", col, last + 1, lens.darkened(0.15))
			_put("head_overlay", "front", 1, first, lens.lightened(0.35))
			_put("head_overlay", "front", 5, first, lens.lightened(0.35))
	# Temple arms along the sides of the head.
	for col in range(4, 8):
		_put("head_overlay", "right", col, first, frame)
	for col in range(0, 4):
		_put("head_overlay", "left", col, first, frame)

extends RefCounted
## Appearance options for the character creator and the closet, and the
## "look" dictionary they build. A look is plain JSON-safe data (colours as
## hex strings) so it saves as-is:
##   preset       preset id it started from, or "custom"
##   build        "classic" (4-pixel arms) or "slim" (3-pixel arms)
##   skin         hex colour
##   hair_style / hair_color, eye_style / eye_color, brows, mouth,
##   facial_hair, cheeks
##   height       scale factor (HEIGHT_MIN..HEIGHT_MAX), 1.0 = 171 cm
##   outfit       {slot: clothing item id, or "" for an empty optional slot}
const Clothing = preload("res://data/clothing.gd")
const BUILDS := [["classic", "Classic"], ["slim", "Slim"]]
const SKIN_TONES := [
	["Porcelain", "f3d6c1"], ["Fair", "eac0a0"], ["Light", "e3b08c"], ["Warm beige", "d29d78"],
	["Medium", "c98e66"], ["Tan", "b77958"], ["Olive", "a5764f"], ["Brown", "8d5a44"],
	["Deep brown", "704b3b"], ["Ebony", "4f3126"],
]
const HAIR_STYLES := [
	["short", "Short crop"], ["side_part", "Side part"], ["messy", "Messy fringe"], ["curly", "Curly"],
	["buzz", "Buzz cut"], ["long", "Long"], ["bob", "Bob"], ["bun", "Top bun"],
	["ponytail", "Ponytail"], ["bald", "Shaved"],
]
const HAIR_COLORS := [
	["Black", "1f1c20"], ["Soft black", "29282c"], ["Espresso", "3a2a22"], ["Brown", "5b3b27"],
	["Chestnut", "7a4a2c"], ["Auburn", "854b37"], ["Copper", "b5602f"], ["Light brown", "a07a4f"],
	["Blonde", "d2a45f"], ["Platinum", "e6dcc6"], ["Silver", "b9b6b0"], ["Midnight blue", "2c3a66"],
	["Rose", "c46f86"],
]
const EYE_STYLES := [["classic", "Classic"], ["round", "Round"], ["bright", "Bright"], ["calm", "Calm"], ["narrow", "Focused"], ["lashes", "Lashes"]]
const EYE_COLORS := [
	["Brown", "5a3a24"], ["Dark brown", "35231a"], ["Hazel", "8a6a35"], ["Amber", "b57a2b"],
	["Green", "3f7d4a"], ["Blue", "3d6fc4"], ["Grey", "7d8a96"],
]
const BROWS := [["soft", "Soft"], ["straight", "Straight"], ["bold", "Bold"], ["none", "None"]]
const MOUTHS := [["none", "None"], ["neutral", "Neutral"], ["smile", "Smile"], ["grin", "Grin"]]
const FACIAL_HAIR := [["none", "None"], ["stubble", "Stubble"], ["mustache", "Mustache"], ["goatee", "Goatee"], ["beard", "Full beard"]]
const CHEEKS := [["none", "None"], ["freckles", "Freckles"], ["blush", "Blush"]]
const HEIGHT_MIN := 0.94
const HEIGHT_MAX := 1.06
## Standing height at scale 1.0: 32 skin pixels of 5.33 cm.
const BASE_HEIGHT_CM := 171.0
## Option lists by look key, for the editor rows and validation.
const CHOICES := {
	"build": BUILDS, "hair_style": HAIR_STYLES, "eye_style": EYE_STYLES, "brows": BROWS,
	"mouth": MOUTHS, "facial_hair": FACIAL_HAIR, "cheeks": CHEEKS,
}
const SWATCHES := {"skin": SKIN_TONES, "hair_color": HAIR_COLORS, "eye_color": EYE_COLORS}

static func default_look() -> Dictionary:
	return {
		"preset": "custom", "build": "classic", "skin": "c98e66",
		"hair_style": "short", "hair_color": "3a2a22", "eye_style": "classic", "eye_color": "5a3a24",
		"brows": "soft", "mouth": "neutral", "facial_hair": "none", "cheeks": "none", "height": 1.0,
		"outfit": starter_outfit(),
	}

static func starter_outfit() -> Dictionary:
	return {"head": "", "eyewear": "", "outerwear": "", "top": "white_tee", "bottom": "dark_jeans", "shoes": "white_sneakers", "neck": "student_lanyard", "back": "slate_backpack"}

static func height_cm(scale: float) -> int:
	return int(round(BASE_HEIGHT_CM * scale))

## A complete, valid look: unknown or missing values fall back to defaults,
## height is clamped, and outfit items must exist and fit their slot.
static func sanitize(look: Variant) -> Dictionary:
	var base := default_look()
	if typeof(look) != TYPE_DICTIONARY:
		return base
	var result := base.duplicate(true)
	result.preset = String(look.get("preset", base.preset))
	for key in CHOICES:
		var value := String(look.get(key, base[key]))
		result[key] = value if _has_choice(CHOICES[key], value) else base[key]
	for key in SWATCHES:
		var value := String(look.get(key, base[key])).trim_prefix("#")
		result[key] = value if Color.html_is_valid(value) else base[key]
	result.height = clampf(float(look.get("height", 1.0)), HEIGHT_MIN, HEIGHT_MAX)
	var outfit: Variant = look.get("outfit", {})
	for slot in Clothing.SLOTS:
		var id := String(outfit.get(slot, base.outfit[slot])) if typeof(outfit) == TYPE_DICTIONARY else String(base.outfit[slot])
		if id == "" and not Clothing.REQUIRED.has(slot):
			result.outfit[slot] = ""
		elif Clothing.exists(id) and Clothing.slot_of(id) == slot:
			result.outfit[slot] = id
	return result

## True when a saved look is structurally sound (used by save validation).
static func is_valid(look: Variant) -> bool:
	if typeof(look) != TYPE_DICTIONARY or typeof(look.get("outfit")) != TYPE_DICTIONARY:
		return false
	for key in CHOICES:
		if not _has_choice(CHOICES[key], String(look.get(key, ""))):
			return false
	for key in SWATCHES:
		if not Color.html_is_valid(String(look.get(key, ""))):
			return false
	if typeof(look.get("height")) not in [TYPE_FLOAT, TYPE_INT]:
		return false
	for slot in Clothing.SLOTS:
		var id := String(look.outfit.get(slot, ""))
		if id == "":
			if Clothing.REQUIRED.has(slot):
				return false
		elif not Clothing.exists(id) or Clothing.slot_of(id) != slot:
			return false
	return true

## A random but plausible look for crowd NPCs (seeded, so stable per seed).
static func random(rng: RandomNumberGenerator) -> Dictionary:
	var look := default_look()
	look.build = "slim" if rng.randf() < 0.45 else "classic"
	look.skin = SKIN_TONES[rng.randi() % SKIN_TONES.size()][1]
	var styles := HAIR_STYLES.slice(0, HAIR_STYLES.size() - 1) # Shaved is rare in a crowd.
	look.hair_style = styles[rng.randi() % styles.size()][0] if rng.randf() > 0.04 else "bald"
	look.hair_color = HAIR_COLORS[rng.randi() % 11][1] # Natural colours only.
	look.eye_style = EYE_STYLES[rng.randi() % EYE_STYLES.size()][0]
	look.eye_color = EYE_COLORS[rng.randi() % EYE_COLORS.size()][1]
	look.brows = ["soft", "straight", "bold"][rng.randi() % 3]
	look.mouth = MOUTHS[rng.randi() % MOUTHS.size()][0]
	look.facial_hair = FACIAL_HAIR[rng.randi() % FACIAL_HAIR.size()][0] if rng.randf() < 0.3 else "none"
	look.cheeks = CHEEKS[rng.randi() % CHEEKS.size()][0] if rng.randf() < 0.3 else "none"
	look.height = snappedf(rng.randf_range(0.95, 1.05), 0.01)
	for slot in Clothing.SLOTS:
		var options: Array = Clothing.items_for(slot).filter(func(id: String) -> bool: return not ["epic", "legendary"].has(Clothing.ITEMS[id][2]))
		var optional_chance: float = {"head": 0.18, "eyewear": 0.22, "outerwear": 0.55, "neck": 0.5, "back": 0.6}.get(slot, 1.0)
		look.outfit[slot] = options[rng.randi() % options.size()] if rng.randf() < optional_chance else ""
	return look

## Display name of an option value (e.g. "side_part" → "Side part").
static func option_name(key: String, value: String) -> String:
	var list: Array = CHOICES.get(key, SWATCHES.get(key, []))
	for entry in list:
		if entry[0] == value or entry[1] == value:
			return entry[1] if CHOICES.has(key) else entry[0]
	return value

static func _has_choice(list: Array, value: String) -> bool:
	for entry in list:
		if entry[0] == value:
			return true
	return false

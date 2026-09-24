extends RefCounted
## Ready-made looks. PRESETS are offered in the character creator (their
## names double as the student's default name); EXTRAS dress faculty,
## classmates and passers-by. Each carries a full look (see data/looks.gd).
## Stable IDs are what the save file stores.
const Looks = preload("res://data/looks.gd")
const DEFAULT_ID := "sage"
const PRESETS: Array[Dictionary] = [
	{"id": "sage", "name": "Sage", "description": "Sage overshirt · dark curls", "look": {
		"build": "classic", "skin": "b77958", "hair_style": "curly", "hair_color": "29282c", "eye_style": "classic", "eye_color": "4a3222",
		"brows": "straight", "mouth": "neutral", "facial_hair": "none", "cheeks": "none", "height": 1.0,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "sage_overshirt", "bottom": "navy_chinos", "shoes": "white_sneakers", "neck": "student_lanyard", "back": "slate_backpack"}}},
	{"id": "indigo", "name": "Indigo", "description": "Indigo scrubs · cropped hair", "look": {
		"build": "classic", "skin": "704b3b", "hair_style": "short", "hair_color": "221f24", "eye_style": "round", "eye_color": "35231a",
		"brows": "bold", "mouth": "smile", "facial_hair": "none", "cheeks": "none", "height": 1.03,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "indigo_scrub_top", "bottom": "indigo_scrub_pants", "shoes": "black_hightops", "neck": "student_lanyard", "back": "slate_backpack"}}},
	{"id": "ochre", "name": "Ochre", "description": "Ochre sweater · auburn bob", "look": {
		"build": "slim", "skin": "e6b494", "hair_style": "bob", "hair_color": "854b37", "eye_style": "lashes", "eye_color": "3f7d4a",
		"brows": "soft", "mouth": "smile", "facial_hair": "none", "cheeks": "freckles", "height": 0.97,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "ochre_sweater", "bottom": "slate_trousers", "shoes": "brown_boots", "neck": "", "back": "canvas_backpack"}}},
	{"id": "clay", "name": "Clay", "description": "Clay jacket · dark bun", "look": {
		"build": "slim", "skin": "d29d78", "hair_style": "bun", "hair_color": "332c32", "eye_style": "classic", "eye_color": "5a3a24",
		"brows": "soft", "mouth": "neutral", "facial_hair": "none", "cheeks": "blush", "height": 0.98,
		"outfit": {"head": "", "eyewear": "", "outerwear": "clay_jacket", "top": "white_tee", "bottom": "teal_trousers", "shoes": "white_sneakers", "neck": "student_lanyard", "back": "slate_backpack"}}},
	{"id": "cobalt", "name": "Cobalt", "description": "Open blue hoodie · messy fringe", "look": {
		"build": "classic", "skin": "eac0a0", "hair_style": "messy", "hair_color": "3a2a22", "eye_style": "bright", "eye_color": "3d6fc4",
		"brows": "straight", "mouth": "none", "facial_hair": "none", "cheeks": "none", "height": 1.0,
		"outfit": {"head": "", "eyewear": "", "outerwear": "blue_zip_hoodie", "top": "white_tee", "bottom": "light_jeans", "shoes": "blue_runners", "neck": "", "back": ""}}},
	{"id": "russet", "name": "Russet", "description": "Maroon crewneck · shades", "look": {
		"build": "classic", "skin": "e3b08c", "hair_style": "messy", "hair_color": "a07a4f", "eye_style": "classic", "eye_color": "5a3a24",
		"brows": "soft", "mouth": "none", "facial_hair": "none", "cheeks": "none", "height": 1.01,
		"outfit": {"head": "", "eyewear": "black_shades", "outerwear": "", "top": "maroon_crewneck", "bottom": "cream_cargo", "shoes": "red_sneakers", "neck": "", "back": ""}}},
	{"id": "navy", "name": "Navy", "description": "Navy tee · dark jeans", "look": {
		"build": "classic", "skin": "e3b08c", "hair_style": "short", "hair_color": "3a2a22", "eye_style": "classic", "eye_color": "3d6fc4",
		"brows": "straight", "mouth": "none", "facial_hair": "none", "cheeks": "none", "height": 1.02,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "navy_tee", "bottom": "dark_jeans", "shoes": "black_hightops", "neck": "student_lanyard", "back": "slate_backpack"}}},
	{"id": "ivory", "name": "Ivory", "description": "Oxford & tie · round glasses", "look": {
		"build": "classic", "skin": "8d5a44", "hair_style": "side_part", "hair_color": "1f1c20", "eye_style": "round", "eye_color": "35231a",
		"brows": "soft", "mouth": "smile", "facial_hair": "stubble", "cheeks": "none", "height": 1.04,
		"outfit": {"head": "", "eyewear": "round_glasses", "outerwear": "", "top": "oxford_tie", "bottom": "khaki_chinos", "shoes": "brown_boots", "neck": "student_lanyard", "back": "canvas_backpack"}}},
]

## Non-selectable looks for classmates and faculty; same schema as PRESETS.
const EXTRAS: Array[Dictionary] = [
	{"id": "professor", "name": "Professor", "description": "Long white coat · silver hair", "look": {
		"build": "classic", "skin": "c89373", "hair_style": "short", "hair_color": "b9b6b0", "eye_style": "calm", "eye_color": "5a3a24",
		"brows": "bold", "mouth": "neutral", "facial_hair": "beard", "cheeks": "none", "height": 1.02,
		"outfit": {"head": "", "eyewear": "rect_glasses", "outerwear": "long_white_coat", "top": "oxford_tie", "bottom": "charcoal_trousers", "shoes": "brown_loafers", "neck": "", "back": ""}}},
	{"id": "nyugen", "name": "Dr. Nyugen", "description": "Charcoal blazer · neat black hair", "look": {
		"build": "classic", "skin": "c79a74", "hair_style": "side_part", "hair_color": "1b1a1f", "eye_style": "classic", "eye_color": "35231a",
		"brows": "straight", "mouth": "smile", "facial_hair": "none", "cheeks": "none", "height": 1.0,
		"outfit": {"head": "", "eyewear": "rect_glasses", "outerwear": "charcoal_blazer", "top": "oxford_tie", "bottom": "charcoal_trousers", "shoes": "brown_loafers", "neck": "", "back": ""}}},
	{"id": "teal", "name": "Teal", "description": "Teal hoodie · bun", "look": {
		"build": "slim", "skin": "8d5a44", "hair_style": "bun", "hair_color": "1f1c20", "eye_style": "lashes", "eye_color": "35231a",
		"brows": "soft", "mouth": "smile", "facial_hair": "none", "cheeks": "none", "height": 0.97,
		"outfit": {"head": "", "eyewear": "", "outerwear": "teal_hoodie", "top": "white_tee", "bottom": "black_joggers", "shoes": "white_sneakers", "neck": "student_lanyard", "back": ""}}},
	{"id": "plum", "name": "Plum", "description": "Plum cardigan · blonde bob", "look": {
		"build": "slim", "skin": "f0c7a8", "hair_style": "bob", "hair_color": "c79a5b", "eye_style": "round", "eye_color": "3d6fc4",
		"brows": "soft", "mouth": "neutral", "facial_hair": "none", "cheeks": "blush", "height": 0.96,
		"outfit": {"head": "", "eyewear": "", "outerwear": "plum_cardigan", "top": "white_tee", "bottom": "dark_jeans", "shoes": "white_sneakers", "neck": "", "back": "canvas_backpack"}}},
	{"id": "mint", "name": "Mint", "description": "Ceil scrubs · ponytail", "look": {
		"build": "slim", "skin": "a5764f", "hair_style": "ponytail", "hair_color": "2c2320", "eye_style": "classic", "eye_color": "35231a",
		"brows": "soft", "mouth": "smile", "facial_hair": "none", "cheeks": "none", "height": 0.98,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "ceil_scrub_top", "bottom": "ceil_scrub_pants", "shoes": "hospital_clogs", "neck": "stethoscope", "back": ""}}},
	{"id": "coral", "name": "Coral", "description": "Breton stripes · long blonde hair", "look": {
		"build": "slim", "skin": "f3d6c1", "hair_style": "long", "hair_color": "d2a45f", "eye_style": "bright", "eye_color": "3f7d4a",
		"brows": "soft", "mouth": "smile", "facial_hair": "none", "cheeks": "freckles", "height": 0.99,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "breton_stripe", "bottom": "light_jeans", "shoes": "white_sneakers", "neck": "", "back": "red_backpack"}}},
	{"id": "slate", "name": "Slate", "description": "Black puffer · curls", "look": {
		"build": "classic", "skin": "4f3126", "hair_style": "curly", "hair_color": "1f1c20", "eye_style": "narrow", "eye_color": "35231a",
		"brows": "bold", "mouth": "neutral", "facial_hair": "none", "cheeks": "none", "height": 1.04,
		"outfit": {"head": "", "eyewear": "", "outerwear": "black_puffer", "top": "black_tee", "bottom": "black_joggers", "shoes": "white_sneakers", "neck": "", "back": "slate_backpack"}}},
	# University Hospital staff and the patient on 4 West (Milestone 11).
	{"id": "okafor", "name": "Dr. Maya Okafor", "description": "Attending physician · Internal Medicine", "look": {
		"build": "slim", "skin": "704b3b", "hair_style": "bun", "hair_color": "1f1c20", "eye_style": "calm", "eye_color": "35231a",
		"brows": "straight", "mouth": "smile", "facial_hair": "none", "cheeks": "none", "height": 1.02,
		"outfit": {"head": "", "eyewear": "rect_glasses", "outerwear": "long_white_coat", "top": "black_turtleneck", "bottom": "charcoal_trousers", "shoes": "brown_loafers", "neck": "stethoscope", "back": ""}}},
	{"id": "resident", "name": "Dr. Leo Martin", "description": "Resident physician (PGY-2)", "look": {
		"build": "classic", "skin": "e3b08c", "hair_style": "short", "hair_color": "5b3b27", "eye_style": "classic", "eye_color": "3d6fc4",
		"brows": "straight", "mouth": "neutral", "facial_hair": "stubble", "cheeks": "none", "height": 1.03,
		"outfit": {"head": "", "eyewear": "", "outerwear": "short_white_coat", "top": "ceil_scrub_top", "bottom": "ceil_scrub_pants", "shoes": "blue_runners", "neck": "stethoscope", "back": ""}}},
	{"id": "charge_nurse", "name": "Priya Shah, RN", "description": "Charge nurse · 4 West", "look": {
		"build": "slim", "skin": "a5764f", "hair_style": "ponytail", "hair_color": "1f1c20", "eye_style": "lashes", "eye_color": "35231a",
		"brows": "soft", "mouth": "smile", "facial_hair": "none", "cheeks": "none", "height": 0.97,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "indigo_scrub_top", "bottom": "indigo_scrub_pants", "shoes": "hospital_clogs", "neck": "student_lanyard", "back": ""}}},
	{"id": "nurse", "name": "Nurse", "description": "Registered nurse", "look": {
		"build": "classic", "skin": "d29d78", "hair_style": "short", "hair_color": "3a2a22", "eye_style": "round", "eye_color": "8a6a35",
		"brows": "soft", "mouth": "neutral", "facial_hair": "none", "cheeks": "none", "height": 1.0,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "indigo_scrub_top", "bottom": "indigo_scrub_pants", "shoes": "white_sneakers", "neck": "student_lanyard", "back": ""}}},
	{"id": "security", "name": "Security officer", "description": "Hospital security", "look": {
		"build": "classic", "skin": "8d5a44", "hair_style": "buzz", "hair_color": "1f1c20", "eye_style": "narrow", "eye_color": "35231a",
		"brows": "bold", "mouth": "neutral", "facial_hair": "goatee", "cheeks": "none", "height": 1.05,
		"outfit": {"head": "", "eyewear": "", "outerwear": "navy_quarter_zip", "top": "white_tee", "bottom": "charcoal_trousers", "shoes": "black_hightops", "neck": "student_lanyard", "back": ""}}},
	{"id": "reception", "name": "Information desk", "description": "Welcome desk volunteer", "look": {
		"build": "slim", "skin": "f0c7a8", "hair_style": "bob", "hair_color": "b9b6b0", "eye_style": "round", "eye_color": "7d8a96",
		"brows": "soft", "mouth": "smile", "facial_hair": "none", "cheeks": "blush", "height": 0.96,
		"outfit": {"head": "", "eyewear": "round_glasses", "outerwear": "plum_cardigan", "top": "white_tee", "bottom": "slate_trousers", "shoes": "brown_loafers", "neck": "student_lanyard", "back": ""}}},
	{"id": "patient", "name": "Patient", "description": "Inpatient, room 412", "look": {
		"build": "classic", "skin": "e3b08c", "hair_style": "short", "hair_color": "b9b6b0", "eye_style": "calm", "eye_color": "7d8a96",
		"brows": "soft", "mouth": "neutral", "facial_hair": "stubble", "cheeks": "none", "height": 1.0,
		"outfit": {"head": "", "eyewear": "", "outerwear": "", "top": "grey_henley", "bottom": "grey_joggers", "shoes": "white_sneakers", "neck": "", "back": ""}}},
	{"id": "sand", "name": "Sand", "description": "Red flannel · beard", "look": {
		"build": "classic", "skin": "e3b08c", "hair_style": "buzz", "hair_color": "5b3b27", "eye_style": "calm", "eye_color": "8a6a35",
		"brows": "straight", "mouth": "neutral", "facial_hair": "beard", "cheeks": "none", "height": 1.03,
		"outfit": {"head": "grey_beanie", "eyewear": "", "outerwear": "", "top": "red_flannel", "bottom": "dark_jeans", "shoes": "brown_boots", "neck": "", "back": "canvas_backpack"}}},
]

static func is_valid(id: String) -> bool:
	for preset in PRESETS:
		if preset.id == id:
			return true
	return false

static func get_preset(id: String) -> Dictionary:
	for preset in PRESETS:
		if preset.id == id:
			return preset.duplicate(true)
	for preset in EXTRAS:
		if preset.id == id:
			return preset.duplicate(true)
	return PRESETS[0].duplicate(true)

## The complete look for a preset (or an extra), tagged with its id.
static func look_of(id: String) -> Dictionary:
	var look := Looks.sanitize(get_preset(id).look)
	look.preset = get_preset(id).id
	return look

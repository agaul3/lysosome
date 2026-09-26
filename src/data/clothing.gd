extends RefCounted
## Clothing catalogue for the wardrobe and inventory.
##
## Each item fills one of eight equipment slots and is painted onto the
## character's pixel skin by `character/skin_painter.gd` from its `kind` and
## `colors`: the base layer takes tops, bottoms and shoes; the overlay shell
## takes outerwear, hats, eyewear and things worn over a jacket. Style,
## comfort and warmth are cosmetic outfit stats shown on the equipment page.
##
## Rarity sets when an item becomes available: common and uncommon from the
## start, rare at level 2, epic at level 3, and legendary for finishing the
## first lecture (see `requirement()`).

## Slot order as laid out around the character on the equipment page:
## the first four down the left, the rest down the right.
const SLOTS := ["head", "eyewear", "outerwear", "top", "neck", "back", "bottom", "shoes"]
const SLOT_NAMES := {
	"head": "Head", "eyewear": "Eyewear", "outerwear": "Outerwear", "top": "Top",
	"neck": "Neck", "back": "Back", "bottom": "Bottom", "shoes": "Shoes",
}
## A student is never without these.
const REQUIRED := ["top", "bottom", "shoes"]
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITY_NAMES := {"common": "Common", "uncommon": "Uncommon", "rare": "Rare", "epic": "Epic", "legendary": "Legendary"}
const RARITY_COLORS := {
	"common": Color("9aa7ad"), "uncommon": Color("6cc28a"), "rare": Color("5aa9e6"),
	"epic": Color("b58be6"), "legendary": Color("f2c46d"),
}
const FIRST_LECTURE := "pharmacodynamics_01"
## Given, never unlocked by level: each student organization's shirt.
const REWARD_ONLY := ["kitchen_tee", "clinic_tee", "surgery_tee", "emig_tee", "spanish_tee", "journal_tee", "intramural_jersey"]

## id: [name, slot, rarity, kind, colors, style, comfort, warmth, description]
const ITEMS := {
	# Outerwear (overlay shell over the top).
	"blue_zip_hoodie": ["Blue Zip Hoodie", "outerwear", "common", "hoodie", ["2f5fa8", "24497f", "e8ecef"], 5, 8, 6, "A soft zip hoodie, worn open over whatever's underneath."],
	"grey_hoodie": ["Heather Grey Hoodie", "outerwear", "common", "hoodie", ["8e949a", "6f757b", "f0f0f0"], 4, 8, 6, "The hoodie every first-year owns. Hood up for early lectures."],
	"teal_hoodie": ["Teal Hoodie", "outerwear", "common", "hoodie", ["3f8f8c", "2f6d6b", "eeeeee"], 5, 8, 6, "Teal zip hoodie with white drawstrings."],
	"plum_cardigan": ["Plum Cardigan", "outerwear", "common", "cardigan", ["7d5a86", "5e4166", "e3d7c4"], 6, 7, 5, "A button cardigan in soft plum knit."],
	"clay_jacket": ["Clay Jacket", "outerwear", "common", "zip_jacket", ["b7766a", "8e574d", "e7d9c4"], 6, 6, 5, "A light zip jacket in warm clay."],
	"white_jacket": ["White Jacket", "outerwear", "uncommon", "zip_jacket", ["eef0ee", "b9c0c4", "5b6770"], 7, 6, 5, "Crisp white shell with a grey zip and a stand collar."],
	"denim_jacket": ["Denim Jacket", "outerwear", "uncommon", "denim_jacket", ["4f6f99", "3b5577", "c9a25a"], 7, 5, 5, "Classic trucker jacket: chest pockets, brass buttons."],
	"olive_bomber": ["Olive Bomber", "outerwear", "uncommon", "bomber", ["5d6b43", "2f3431", "c56a2e"], 7, 6, 6, "Flight jacket with ribbed trims and a sleeve pocket."],
	"yellow_rain_shell": ["Yellow Rain Shell", "outerwear", "uncommon", "rain_shell", ["e8b923", "b58a15", "2f3c46"], 5, 5, 5, "Bright waterproof shell. You'll be glad of it in November."],
	"navy_quarter_zip": ["Navy Quarter-Zip", "outerwear", "uncommon", "quarter_zip", ["26344d", "1b2536", "c9ced1"], 7, 7, 6, "Smart pullover with a half zip. Looks good at a clinic."],
	"patagonia_fleece": ["Patagonia Retro Fleece", "outerwear", "rare", "fleece", ["efe6d3", "2e6f73", "d9822b"], 9, 9, 9, "High-pile retro fleece with a contrast chest pocket and snap placket. Warm enough for 7 AM lectures."],
	"black_puffer": ["Black Puffer Jacket", "outerwear", "rare", "puffer", ["2a2d31", "1b1d20", "c8ccd0"], 8, 8, 10, "Quilted and toasty. Walking to the Learning Center in January sorted."],
	"varsity_jacket": ["Varsity Jacket", "outerwear", "rare", "varsity", ["1f3558", "efe6d3", "c8a24a"], 9, 6, 6, "Navy wool body, cream sleeves, gold-striped trims."],
	"charcoal_blazer": ["Charcoal Blazer", "outerwear", "epic", "blazer", ["3a424b", "2b3138", "c9ced2"], 9, 5, 5, "Tailored charcoal wool for presentations and grand rounds."],
	"short_white_coat": ["Short White Coat", "outerwear", "epic", "coat", ["f4f5f2", "c9ced1", "3d6fc4"], 8, 6, 5, "The student's short coat, pockets full of pens and index cards."],
	"long_white_coat": ["Long White Coat", "outerwear", "legendary", "long_coat", ["fbfbf8", "cfd4d6", "2f8f82"], 10, 6, 6, "Earned, not issued: the long coat, for finishing your first lecture."],
	# Tops (base layer: torso and sleeves).
	"white_tee": ["White Tee", "top", "common", "tee", ["f1f1ee", "d7d9d6"], 4, 8, 3, "A plain white T-shirt. Goes with everything."],
	"navy_tee": ["Navy Tee", "top", "common", "tee", ["2b4169", "22355a"], 5, 8, 3, "Soft navy cotton tee."],
	"black_tee": ["Black Tee", "top", "common", "tee", ["26282b", "1c1d20"], 5, 8, 3, "Black crew-neck tee."],
	"maroon_crewneck": ["Maroon Crewneck", "top", "common", "sweater", ["8c2f32", "6d2326"], 6, 7, 6, "Chunky knit crewneck with ribbed cuffs."],
	"ochre_sweater": ["Ochre Sweater", "top", "common", "sweater", ["cd9a4c", "a87a36"], 6, 7, 6, "Warm ochre knit with a ribbed hem."],
	"grey_henley": ["Grey Henley", "top", "common", "henley", ["8f9599", "73797d", "e6e6e2"], 6, 7, 4, "Long-sleeve henley with a three-button placket."],
	"sage_overshirt": ["Sage Overshirt", "top", "common", "overshirt", ["648f81", "4f7466", "e3d7c4"], 6, 7, 4, "Soft twill overshirt with two chest pockets."],
	"indigo_scrub_top": ["Indigo Scrub Top", "top", "common", "scrubs", ["667fab", "4f668f", "2f3f63"], 5, 9, 2, "V-neck scrub top with a chest pocket."],
	"ceil_scrub_top": ["Ceil Blue Scrub Top", "top", "uncommon", "scrubs", ["7fa7c9", "6589ab", "3d5d7c"], 6, 9, 2, "Hospital-issue ceil blue. You look ready for a shift."],
	"breton_stripe": ["Breton Stripe Tee", "top", "uncommon", "stripe", ["f0eee8", "2b3f66"], 7, 7, 3, "Navy and cream stripes."],
	"oxford_tie": ["Oxford Shirt & Tie", "top", "uncommon", "oxford", ["dfe8f3", "6b2f3a", "b9c7d6"], 8, 5, 3, "Pale blue oxford with a burgundy tie."],
	"red_flannel": ["Red Flannel Shirt", "top", "uncommon", "flannel", ["a3312c", "2a2224", "d9cfc0"], 7, 7, 5, "Brushed flannel in a red and black check."],
	"black_turtleneck": ["Black Turtleneck", "top", "rare", "turtleneck", ["202226", "16171a"], 8, 7, 6, "Fine-knit turtleneck. Very lab-to-gallery."],
	"class_crewneck": ["Class of 2030 Crewneck", "top", "rare", "sweater", ["2f4a6b", "24394f"], 8, 8, 6, "Navy crewneck from the Campus Store, CLASS OF 2030 across the chest."],
	"asclepius_tee": ["Rod of Asclepius Tee", "top", "uncommon", "tee", ["e9e4da", "cfc8ba"], 6, 8, 3, "The single serpent on a staff: medicine's own symbol, in slate on oatmeal cotton."],
	# Club shirts: given at reputation level 2 in a student organization.
	"kitchen_tee": ["Community Kitchen Volunteer Tee", "top", "epic", "tee", ["c2452d", "9a3525"], 7, 8, 3, "Tomato-red volunteer tee. Worn at the serving line on Harbor Street."],
	"clinic_tee": ["Free Clinic Volunteer Tee", "top", "epic", "tee", ["2f8f82", "236b62"], 7, 8, 3, "Teal tee from the Student-Run Free Clinic."],
	"surgery_tee": ["Surgery Interest Group Tee", "top", "epic", "tee", ["3d86c6", "2a6399"], 7, 8, 3, "Surgical blue, with a knot-tying diagram on the back."],
	"emig_tee": ["Emergency Medicine Interest Group Tee", "top", "epic", "tee", ["26282b", "c2452d"], 7, 8, 3, "Black with a red ECG line across the chest."],
	"spanish_tee": ["Medical Spanish Tee", "top", "epic", "tee", ["e8b923", "b58a15"], 7, 8, 3, "Sunflower yellow: ¿Cómo se siente hoy?"],
	"journal_tee": ["Journal Club Tee", "top", "epic", "tee", ["4f5b66", "3a444d"], 7, 8, 3, "Slate grey, with a forest plot printed small on the sleeve."],
	"intramural_jersey": ["Intramural Jersey", "top", "epic", "tee", ["2f7a4a", "f2f2ef"], 8, 8, 2, "Green team jersey, number 1 for M1."],
	# Bottoms (base layer: legs, with a belt at the waist for belted styles).
	"dark_jeans": ["Dark Wash Jeans", "bottom", "common", "jeans", ["2e3d57", "243047", "6b4a2e"], 5, 6, 4, "Dark indigo denim with a leather belt."],
	"light_jeans": ["Light Wash Jeans", "bottom", "common", "jeans", ["6f8db3", "5a769a", "3a2c25"], 5, 6, 4, "Faded light-wash denim."],
	"black_joggers": ["Black Joggers", "bottom", "common", "joggers", ["26282b", "1b1c1f", "5b6166"], 4, 9, 5, "Cuffed joggers. Maximum comfort."],
	"grey_joggers": ["Grey Joggers", "bottom", "common", "joggers", ["8a9096", "6f757b", "eeeeee"], 4, 9, 5, "Heather grey joggers with a side stripe."],
	"khaki_chinos": ["Khaki Chinos", "bottom", "common", "chinos", ["c2ad86", "a8936c", "5b3b27"], 6, 6, 4, "Pressed khaki chinos."],
	"navy_chinos": ["Navy Chinos", "bottom", "common", "chinos", ["283c50", "1f3040", "3a2c25"], 6, 6, 4, "Navy chinos with a brown belt."],
	"slate_trousers": ["Slate Trousers", "bottom", "common", "chinos", ["4b5359", "3c4347", "2a2d30"], 6, 6, 4, "Slate grey straight-leg trousers."],
	"teal_trousers": ["Deep Teal Trousers", "bottom", "common", "chinos", ["304b4e", "253b3d", "2a2d30"], 6, 6, 4, "Relaxed trousers in deep teal."],
	"indigo_scrub_pants": ["Indigo Scrub Pants", "bottom", "common", "scrub_pants", ["343d5c", "283048"], 4, 9, 3, "Drawstring scrub pants."],
	"ceil_scrub_pants": ["Ceil Blue Scrub Pants", "bottom", "uncommon", "scrub_pants", ["7fa7c9", "6589ab"], 5, 9, 3, "The matching half of hospital blues."],
	"cream_cargo": ["Cream Cargo Pants", "bottom", "uncommon", "cargo", ["e3dcc7", "c4bba2", "8a7f68"], 6, 7, 4, "Utility cargos with flap side pockets."],
	"charcoal_trousers": ["Charcoal Trousers", "bottom", "uncommon", "chinos", ["3b4148", "2e3339", "1f2226"], 7, 5, 4, "Tailored charcoal trousers."],
	"cargo_shorts": ["Cargo Shorts", "bottom", "common", "shorts", ["8a7a58", "6f6245"], 5, 8, 1, "For the brave, in any weather."],
	# Shoes (the lowest rows of the legs and the soles).
	"white_sneakers": ["White Sneakers", "shoes", "common", "sneakers", ["f2f2ef", "c9ccce", "9aa3a8"], 6, 8, 3, "Clean white low-tops."],
	"black_hightops": ["Black High-tops", "shoes", "common", "hightops", ["24262a", "efece4", "d9d9d9"], 6, 7, 4, "Canvas high-tops with white toe caps."],
	"blue_runners": ["Blue Runners", "shoes", "uncommon", "runners", ["2f5fa8", "f2f2ef", "f2a93b"], 7, 9, 3, "Light running shoes for the long walk to the hospital."],
	"red_sneakers": ["Red Sneakers", "shoes", "uncommon", "sneakers", ["b3342e", "efece4", "8c2420"], 7, 8, 3, "Bold red low-tops."],
	"brown_boots": ["Brown Leather Boots", "shoes", "uncommon", "boots", ["6e4a33", "3a2a20", "c9a25a"], 7, 6, 7, "Lace-up leather boots."],
	"brown_loafers": ["Brown Loafers", "shoes", "uncommon", "loafers", ["5b3b27", "3a2519"], 8, 6, 3, "Polished penny loafers."],
	"hospital_clogs": ["Hospital Clogs", "shoes", "rare", "clogs", ["3d86c6", "2a6399"], 5, 10, 3, "Twelve-hour-shift comfort. Surprisingly stylish."],
	# Head (overlay shell over the hair).
	"grey_beanie": ["Grey Beanie", "head", "common", "beanie", ["7d858b", "5f666b"], 6, 7, 7, "Ribbed knit beanie with a turn-up."],
	"mustard_beanie": ["Mustard Beanie", "head", "uncommon", "beanie", ["c99a2e", "a37b1f"], 7, 7, 7, "A cheerful mustard knit."],
	"navy_cap": ["Navy Cap", "head", "common", "cap", ["26344d", "1b2536", "e8e8e2"], 6, 7, 2, "Six-panel cap with a curved brim."],
	"scrub_cap": ["Surgical Scrub Cap", "head", "rare", "scrub_cap", ["3d86c6", "f2f2ef"], 6, 7, 2, "Patterned scrub cap. You're basically a surgeon."],
	# Eyewear (overlay over the eyes).
	"round_glasses": ["Round Glasses", "eyewear", "common", "round_glasses", ["2a2522"], 6, 6, 0, "Thin round frames."],
	"rect_glasses": ["Rectangular Glasses", "eyewear", "common", "rect_glasses", ["1f2326"], 6, 6, 0, "Sensible rectangular frames."],
	"black_shades": ["Black Shades", "eyewear", "uncommon", "sunglasses", ["141416", "5c6166"], 8, 5, 0, "Dark sunglasses. Too cool for 8 AM."],
	"gold_aviators": ["Gold Aviators", "eyewear", "rare", "aviators", ["c8a24a", "3a3f44"], 9, 6, 0, "Gold-rimmed aviators with smoke lenses."],
	# Neck (lanyards under outerwear, stethoscopes and scarves over it).
	"student_lanyard": ["Student ID Lanyard", "neck", "common", "lanyard", ["2f8f82", "f2f2ef", "3d6fc4"], 2, 10, 0, "Cedar Residence and Learning Center access."],
	"stethoscope": ["Stethoscope", "neck", "rare", "stethoscope", ["2a2d31", "c9ced2"], 8, 7, 0, "Your first stethoscope. You'll wear it everywhere for a month."],
	"plaid_scarf": ["Plaid Scarf", "neck", "uncommon", "scarf", ["a3312c", "2b3f66", "d9cfc0"], 7, 8, 8, "A long wool scarf in a red and navy plaid."],
	# Back (a backpack on the back, straps painted over the shoulders).
	"slate_backpack": ["Slate Backpack", "back", "common", "backpack", ["384f59", "26363d", "c9a25a"], 4, 8, 0, "Laptop, charger, and a water bottle."],
	"canvas_backpack": ["Canvas Backpack", "back", "common", "backpack", ["b9a47a", "8a7550", "5b3b27"], 5, 8, 0, "Waxed canvas with leather trim."],
	"red_backpack": ["Red Backpack", "back", "uncommon", "backpack", ["a8322d", "7a2320", "e0e0dc"], 6, 8, 0, "Bright red, easy to spot in the library."],
}

static func exists(id: String) -> bool:
	return ITEMS.has(id)

## Item as a dictionary with named fields (empty when unknown).
static func item(id: String) -> Dictionary:
	if not ITEMS.has(id):
		return {}
	var entry: Array = ITEMS[id]
	return {
		"id": id, "name": entry[0], "slot": entry[1], "rarity": entry[2], "kind": entry[3],
		"colors": entry[4].map(func(hex: String) -> Color: return Color(hex)),
		"style": entry[5], "comfort": entry[6], "warmth": entry[7], "description": entry[8],
	}

static func slot_of(id: String) -> String:
	return ITEMS[id][1] if ITEMS.has(id) else ""

## Item ids for a slot, ordered by rarity then name.
static func items_for(slot: String) -> Array:
	var ids: Array = ITEMS.keys().filter(func(id: String) -> bool: return ITEMS[id][1] == slot)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra := RARITIES.find(ITEMS[a][2])
		var rb := RARITIES.find(ITEMS[b][2])
		return ra < rb if ra != rb else String(ITEMS[a][0]) < String(ITEMS[b][0]))
	return ids

## Whether an item is available yet, and the requirement in words:
## {"met": bool, "text": String}.
static func requirement(id: String) -> Dictionary:
	if id in REWARD_ONLY:
		return {"met": false, "text": "A student organization's shirt"}
	var rarity: String = ITEMS[id][2] if ITEMS.has(id) else "common"
	match rarity:
		"rare":
			return {"met": _level() >= 2, "text": "Reach Lvl 2"}
		"epic":
			return {"met": _level() >= 3, "text": "Reach Lvl 3"}
		"legendary":
			return {"met": _lecture_done(), "text": "Complete your first lecture"}
	return {"met": true, "text": ""}

## Available: its rarity requirement is met, or the student owns it outright
## (bought at the student store or given as a reward, e.g. at the White Coat
## Ceremony).
static func unlocked(id: String) -> bool:
	return exists(id) and (requirement(id).met or _owned(id))

static func item_name(id: String) -> String:
	return String(ITEMS[id][0]) if ITEMS.has(id) else id

static func _owned(id: String) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var wallet: Node = tree.root.get_node_or_null("Wallet") if tree else null
	return wallet != null and wallet.owns_clothing(id)

## Items unlocked by reaching `level` from `previous` (for the HUD notice).
static func unlocked_by_level(previous: int, level: int) -> Array:
	var names: Array = []
	for id in ITEMS:
		var rarity: String = ITEMS[id][2]
		var needed := 2 if rarity == "rare" else (3 if rarity == "epic" else 0)
		if id in REWARD_ONLY:
			continue
		if needed > previous and needed <= level:
			names.append(ITEMS[id][0])
	return names

static func legendary_names() -> Array:
	return ITEMS.keys().filter(func(id: String) -> bool: return ITEMS[id][2] == "legendary").map(func(id: String) -> String: return ITEMS[id][0])

## Outfit totals for the equipment page: {"style", "comfort", "warmth", "max"}.
static func outfit_stats(outfit: Dictionary) -> Dictionary:
	var totals := {"style": 0, "comfort": 0, "warmth": 0, "max": 10 * SLOTS.size()}
	for slot in SLOTS:
		var id: String = outfit.get(slot, "")
		if ITEMS.has(id):
			totals.style += int(ITEMS[id][5])
			totals.comfort += int(ITEMS[id][6])
			totals.warmth += int(ITEMS[id][7])
	return totals

static func _level() -> int:
	var session := _session()
	return int(session.level) if session else 1

static func _lecture_done() -> bool:
	var session := _session()
	return session != null and session.lectures_completed.has(FIRST_LECTURE)

static func _session() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("AcademicSession") if tree else null

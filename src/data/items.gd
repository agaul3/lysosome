extends RefCounted
## Things the student can buy and consume: coffee, food and snacks. Prices
## are in cents. Eating or drinking restores energy and may start a boost:
## a timed bonus to XP earned from learning (answers, flashcards, patient
## encounters), never from anything else.
##
## Boosts sit in slots, one per slot at a time: a newer drink replaces the
## last drink's boost, and a meal replaces the last meal's.
##   drink  coffee and tea
##   meal   a real meal
##   snack  a quick bite (energy only, no boost)
##
## id: name, price (cents), energy, boost {slot, name, xp, minutes} or {},
## icon (a UI icon name), description, "carry" (can be bought to go and kept
## in the backpack for later).
const ITEMS := {
	# Drinks.
	"drip_coffee": {"name": "Drip Coffee", "price": 275, "energy": 10, "boost": {"slot": "drink", "name": "Caffeinated", "xp": 0.05, "minutes": 60}, "icon": "cup", "carry": false,
		"description": "Hot, strong and bottomless (almost). +5% XP for an hour."},
	"cold_brew": {"name": "Cold Brew", "price": 450, "energy": 15, "boost": {"slot": "drink", "name": "Cold Brew", "xp": 0.10, "minutes": 90}, "icon": "cup", "carry": false,
		"description": "Slow-steeped and smooth. +10% XP for 90 minutes."},
	"matcha_latte": {"name": "Matcha Latte", "price": 525, "energy": 12, "boost": {"slot": "drink", "name": "Calm Focus", "xp": 0.08, "minutes": 120}, "icon": "cup", "carry": false,
		"description": "Steady caffeine without the jitters. +8% XP for two hours."},
	"green_tea": {"name": "Green Tea", "price": 225, "energy": 6, "boost": {"slot": "drink", "name": "Green Tea", "xp": 0.04, "minutes": 90}, "icon": "cup", "carry": false,
		"description": "A gentle lift. +4% XP for 90 minutes."},
	"energy_drink": {"name": "Energy Drink", "price": 325, "energy": 22, "boost": {"slot": "drink", "name": "Wired", "xp": 0.05, "minutes": 45}, "icon": "bolt", "carry": true,
		"description": "A big jolt of energy. +5% XP for 45 minutes."},
	"water": {"name": "Bottled Water", "price": 175, "energy": 3, "boost": {}, "icon": "cup", "carry": true,
		"description": "Stay hydrated."},
	# Meals.
	"breakfast_burrito": {"name": "Breakfast Burrito", "price": 795, "energy": 25, "boost": {"slot": "meal", "name": "Well Fed", "xp": 0.05, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Eggs, potatoes and salsa. +5% XP for three hours."},
	"grain_bowl": {"name": "Mediterranean Grain Bowl", "price": 1150, "energy": 30, "boost": {"slot": "meal", "name": "Brain Food", "xp": 0.10, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Farro, chickpeas, greens and tahini. +10% XP for three hours."},
	"turkey_sandwich": {"name": "Turkey Avocado Sandwich", "price": 925, "energy": 25, "boost": {"slot": "meal", "name": "Well Fed", "xp": 0.05, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Stacked on sourdough. +5% XP for three hours."},
	"sushi_combo": {"name": "Sushi Combo", "price": 1295, "energy": 28, "boost": {"slot": "meal", "name": "Brain Food", "xp": 0.10, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Salmon, tuna and a veggie roll. +10% XP for three hours."},
	"pho": {"name": "Chicken Pho", "price": 1195, "energy": 30, "boost": {"slot": "meal", "name": "Comfort Food", "xp": 0.08, "minutes": 240}, "icon": "bowl", "carry": false,
		"description": "Warm broth for a long day. +8% XP for four hours."},
	"pizza_slice": {"name": "Pizza Slice", "price": 395, "energy": 18, "boost": {"slot": "meal", "name": "Fueled", "xp": 0.03, "minutes": 120}, "icon": "bowl", "carry": false,
		"description": "Classic cheese. +3% XP for two hours."},
	"caesar_salad": {"name": "Chicken Caesar Salad", "price": 975, "energy": 22, "boost": {"slot": "meal", "name": "Light and Sharp", "xp": 0.07, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Crisp and filling. +7% XP for three hours."},
	"chicken_soup": {"name": "Chicken Noodle Soup", "price": 575, "energy": 16, "boost": {"slot": "meal", "name": "Warmed Up", "xp": 0.04, "minutes": 150}, "icon": "bowl", "carry": false,
		"description": "The hospital's famous soup, with a roll. +4% XP for two and a half hours."},
	# Snacks (energy only; can be carried).
	"protein_bar": {"name": "Protein Bar", "price": 250, "energy": 12, "boost": {}, "icon": "bar", "carry": true,
		"description": "Keeps you going between classes."},
	"trail_mix": {"name": "Trail Mix", "price": 300, "energy": 10, "boost": {}, "icon": "bar", "carry": true,
		"description": "Nuts, raisins and a few chocolate pieces."},
	"banana": {"name": "Banana", "price": 95, "energy": 8, "boost": {}, "icon": "bar", "carry": true,
		"description": "Nature's snack bar."},
	"fruit_cup": {"name": "Fruit Cup", "price": 350, "energy": 9, "boost": {}, "icon": "bar", "carry": true,
		"description": "Melon, berries and grapes."},
	"yogurt_parfait": {"name": "Yogurt Parfait", "price": 425, "energy": 10, "boost": {}, "icon": "bar", "carry": true,
		"description": "Greek yogurt, granola and berries."},
	# Smoothies (the Student Center's juice bar): a drink boost that lasts.
	"berry_smoothie": {"name": "Berry Blast Smoothie", "price": 650, "energy": 16, "boost": {"slot": "drink", "name": "Fresh Start", "xp": 0.06, "minutes": 150}, "icon": "cup", "carry": false,
		"description": "Strawberry, blueberry, banana and yogurt. +6% XP for 2½ hours."},
	"green_smoothie": {"name": "Green Machine Smoothie", "price": 695, "energy": 14, "boost": {"slot": "drink", "name": "Green Focus", "xp": 0.08, "minutes": 150}, "icon": "cup", "carry": false,
		"description": "Spinach, mango, pineapple and ginger. +8% XP for 2½ hours."},
	"protein_shake": {"name": "Peanut Butter Protein Shake", "price": 725, "energy": 24, "boost": {}, "icon": "cup", "carry": false,
		"description": "After the gym. Lots of energy, no boost."},
	"acai_bowl": {"name": "Açaí Bowl", "price": 1050, "energy": 26, "boost": {"slot": "meal", "name": "Bright Mind", "xp": 0.08, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Açaí, granola, banana and honey. +8% XP for three hours."},
	# The Community Center's kitchen (volunteers eat with the guests, free).
	"community_supper": {"name": "Community Supper", "price": 0, "energy": 30, "boost": {"slot": "meal", "name": "Shared Table", "xp": 0.06, "minutes": 180}, "icon": "bowl", "carry": false,
		"description": "Tonight's supper, eaten with the guests. +6% XP for three hours."},
}

## Study aids from the Campus Store: bought once, kept for the year. Each is
## a small permanent bonus (Skills.effect keys, like the perks'), never a
## shortcut: they add to what correct answers earn.
## id: name, price (cents), effects, icon, description.
const AIDS := {
	"review_book": {"name": "First-Year Review Book", "price": 4800, "effects": {"xp:lecture": 0.05}, "icon": "book",
		"description": "High-yield summaries to pre-read before class. +5% lecture XP."},
	"flashcard_app": {"name": "Premium Flashcard Add-ons", "price": 2500, "effects": {"xp:flashcard": 0.05, "flashcard:cap": 20}, "icon": "notes",
		"description": "Image occlusion and heatmaps for your flashcards. +5% flashcard XP and +20 to the daily flashcard XP cap."},
	"qbank": {"name": "Question Bank · One Year", "price": 14900, "effects": {"xp:exam": 0.05, "exam:time": 0.05}, "icon": "target",
		"description": "Timed practice blocks in exam format. +5% exam XP and 5% more exam time."},
	"exam_guide": {"name": "Pocket Guide to the Physical Exam", "price": 3200, "effects": {"xp:clinical": 0.05}, "icon": "person",
		"description": "Every maneuver on one page, for the white coat's pocket. +5% XP in patient encounters."},
	"anatomy_atlas": {"name": "Anatomy Atlas", "price": 5900, "effects": {"xp:lab": 0.08}, "icon": "knowledge",
		"description": "Hand-drawn plates, lab-proof binding. +8% XP in labs and practicals."},
	"headphones": {"name": "Noise-Cancelling Headphones", "price": 12900, "effects": {"xp:flashcard": 0.05, "xp:lecture": 0.02}, "icon": "spark",
		"description": "Silence in the reading room. +5% flashcard XP and +2% lecture XP."},
	"water_bottle": {"name": "Insulated Water Bottle", "price": 2800, "effects": {"energy:max": 5}, "icon": "cup",
		"description": "Cold for 24 hours. +5 maximum energy."},
	"planner": {"name": "Academic Planner", "price": 1800, "effects": {"energy:restore": 0.05}, "icon": "calendar",
		"description": "Every exam and deadline in one place: less stress. +5% energy from food and rest."},
}

## The Campus Store's clothing (bought once and owned: available whatever
## your level) and its study aids, with prices in cents.
const STORE_CLOTHING := [
	["class_crewneck", 4200], ["asclepius_tee", 2200], ["navy_quarter_zip", 5400], ["grey_hoodie", 3800],
	["ceil_scrub_top", 2800], ["ceil_scrub_pants", 2600], ["indigo_scrub_top", 2400], ["indigo_scrub_pants", 2200],
	["stethoscope", 8900], ["hospital_clogs", 6500], ["scrub_cap", 1800], ["student_lanyard", 600],
	["black_puffer", 12900], ["varsity_jacket", 9800], ["charcoal_blazer", 15900], ["canvas_backpack", 5600], ["red_backpack", 4900],
]

## Each place that sells food and what it sells.
const VENDORS := {
	"cafe_kiosk": {"name": "Commons Café", "items": ["drip_coffee", "cold_brew", "matcha_latte", "green_tea", "breakfast_burrito", "banana", "protein_bar"]},
	"library_cafe": {"name": "Stacks Café", "items": ["drip_coffee", "cold_brew", "matcha_latte", "green_tea", "fruit_cup", "trail_mix", "water"]},
	"med_ed_grill": {"name": "Commons Grill", "items": ["breakfast_burrito", "turkey_sandwich", "pizza_slice", "water"]},
	"med_ed_bowls": {"name": "Harvest Bowls", "items": ["grain_bowl", "caesar_salad", "fruit_cup", "green_tea"]},
	"med_ed_noodle": {"name": "Noodle Bar", "items": ["pho", "sushi_combo", "green_tea", "water"]},
	"med_ed_coffee": {"name": "Pulse Coffee", "items": ["drip_coffee", "cold_brew", "matcha_latte", "protein_bar", "banana"]},
	"atrium_cafe": {"name": "Atrium Café", "items": ["drip_coffee", "cold_brew", "green_tea", "fruit_cup", "banana", "water"]},
	"hospital_grill": {"name": "Grill 24", "items": ["breakfast_burrito", "turkey_sandwich", "pizza_slice", "chicken_soup", "water"]},
	"hospital_market": {"name": "Fresh Market", "items": ["grain_bowl", "caesar_salad", "sushi_combo", "chicken_soup", "yogurt_parfait", "fruit_cup", "banana"]},
	"hospital_coffee": {"name": "Rounds Coffee", "items": ["drip_coffee", "cold_brew", "matcha_latte", "green_tea", "yogurt_parfait", "protein_bar"]},
	"vending": {"name": "Vending Machine", "items": ["energy_drink", "water", "protein_bar", "trail_mix"]},
	"student_center_juice": {"name": "Fuel Juice Bar", "items": ["berry_smoothie", "green_smoothie", "protein_shake", "acai_bowl", "water", "protein_bar"]},
	"community_kitchen": {"name": "Community Supper", "items": ["community_supper", "water"]},
}

static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func get_aid(id: String) -> Dictionary:
	return AIDS.get(id, {})

## Summed effect of `key` over the aids in `owned`.
static func aid_effect(key: String, owned: Array) -> float:
	var total := 0.0
	for id in owned:
		total += float(AIDS.get(id, {}).get("effects", {}).get(key, 0.0))
	return total

static func store_price(clothing_id: String) -> int:
	for entry in STORE_CLOTHING:
		if entry[0] == clothing_id:
			return int(entry[1])
	return 0

static func format_money(cents: int) -> String:
	var negative := cents < 0
	var value := absi(cents)
	var dollars := str(value / 100)
	var grouped := ""
	while dollars.length() > 3:
		grouped = "," + dollars.right(3) + grouped
		dollars = dollars.left(dollars.length() - 3)
	return "%s$%s%s.%02d" % ["−" if negative else "", dollars, grouped, value % 100]

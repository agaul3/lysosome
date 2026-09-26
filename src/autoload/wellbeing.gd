extends Node
## Energy and boosts.
##
## Energy (0 to 100, plus perks) is spent by the day's activities (lectures,
## labs, exams, patient encounters, club events, study sessions, workouts)
## and restored by food, drink, rest and sleep. When it runs low, XP from
## learning is reduced: tired students retain less. It is what keeps a day
## finite and makes a meal worth stopping for.
##
## Boosts are timed bonuses to XP earned from learning (answers, flashcards,
## patient encounters), from food and drink (data/items.gd), a good night's
## sleep, a workout or a study group. They run on game time, so skipped days
## let them expire. One boost per slot: drink, meal, rest, exercise, social.
##
## xp_multiplier(context) is applied wherever learning XP is awarded:
## (1 + perk bonus + boost bonus) × energy factor. With no perks, no boosts
## and energy above 40 it is exactly 1.
signal changed
## A boost began: {name, xp, minutes, icon, slot}.
signal boost_started(boost: Dictionary)
const Items = preload("res://data/items.gd")
const BASE_MAX_ENERGY := 100.0
## Contexts that learning boosts apply to.
const LEARNING := ["lecture", "flashcard", "exam", "clinical", "immersion", "club", "tutoring", "lab"]
var energy := BASE_MAX_ENERGY
## slot -> {name, xp, until (game time), icon, source}
var boosts: Dictionary = {}

func reset() -> void:
	energy = BASE_MAX_ENERGY
	boosts.clear()
	changed.emit()

func max_energy() -> float:
	return BASE_MAX_ENERGY + Skills.effect("energy:max")

func energy_fraction() -> float:
	return clampf(energy / max_energy(), 0.0, 1.0)

## "Energized", "Tired", "Exhausted"…
func energy_state() -> String:
	if energy <= 0.0:
		return "Exhausted"
	if energy < 20.0:
		return "Very tired"
	if energy < 40.0:
		return "Tired"
	return "Energized" if energy >= 75.0 else "Steady"

## XP factor from energy: full at 40 and above.
func energy_factor() -> float:
	if energy >= 40.0:
		return 1.0
	if energy >= 20.0:
		return 0.9
	if energy > 0.0:
		return 0.75
	return 0.6

func spend(amount: float, _reason := "") -> void:
	if amount <= 0.0:
		return
	energy = maxf(0.0, energy - amount)
	changed.emit()

## Restores energy (perks increase it) up to the maximum. Returns the amount gained.
func restore(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var before := energy
	energy = minf(max_energy(), energy + amount * (1.0 + Skills.effect("energy:restore")))
	changed.emit()
	return energy - before

## Starts (or replaces) the boost in `slot`, lasting `minutes` of game time.
func add_boost(slot: String, boost_name: String, xp: float, minutes: float, icon := "spark", source := "") -> void:
	var scaled := minutes
	if slot in ["drink", "meal"]:
		scaled *= 1.0 + Skills.effect("boost:duration")
	boosts[slot] = {"name": boost_name, "xp": xp, "until": GameClock.now_seconds() + scaled * 60.0, "icon": icon, "source": source}
	changed.emit()
	boost_started.emit({"name": boost_name, "xp": xp, "minutes": int(round(scaled)), "icon": icon, "slot": slot})

## Eats or drinks an item: energy, and its boost if it has one.
func consume(item_id: String) -> void:
	var item := Items.get_item(item_id)
	if item.is_empty():
		return
	restore(float(item.energy))
	var boost: Dictionary = item.boost
	if not boost.is_empty():
		add_boost(boost.slot, boost.name, float(boost.xp), float(boost.minutes), item.icon, item_id)
	changed.emit()

## Active boosts, soonest to expire first; expired ones are dropped.
func active_boosts() -> Array:
	var now := GameClock.now_seconds()
	var expired: Array = []
	var result: Array = []
	for slot in boosts:
		var boost: Dictionary = boosts[slot]
		if float(boost.until) <= now:
			expired.append(slot)
		else:
			var entry := boost.duplicate()
			entry.slot = slot
			entry.minutes_left = int(ceil((float(boost.until) - now) / 60.0))
			result.append(entry)
	for slot in expired:
		boosts.erase(slot)
	if not expired.is_empty():
		changed.emit()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.until) < float(b.until))
	return result

func boost_bonus() -> float:
	var total := 0.0
	for boost in active_boosts():
		total += float(boost.xp)
	return total

## Multiplier for learning XP in `context`; exactly 1 for a fresh student.
func xp_multiplier(context: String) -> float:
	if context not in LEARNING:
		return 1.0
	var bonus := Skills.effect("xp:" + context) + boost_bonus()
	return (1.0 + bonus) * energy_factor()

## Learning XP after perks, boosts and energy (whole points).
func apply(base: int, context: String) -> int:
	if base <= 0:
		return base
	return int(round(base * xp_multiplier(context)))

## A night's sleep: boosts end and energy returns to full (70% after a
## night that ran past 2 AM). The calendar adds "Well Rested" after an early night.
func sleep(_well_rested: bool, fraction := 1.0) -> void:
	boosts.clear()
	energy = minf(max_energy(), max_energy() * clampf(fraction, 0.0, 1.0) + Skills.effect("energy:wake"))
	changed.emit()

func snapshot() -> Dictionary:
	return {"energy": energy, "boosts": boosts.duplicate(true)}

func restore_state(data: Dictionary) -> void:
	energy = clampf(float(data.get("energy", BASE_MAX_ENERGY)), 0.0, 1000.0)
	boosts.clear()
	var saved: Dictionary = data.get("boosts", {})
	for slot in saved:
		var boost: Variant = saved[slot]
		if boost is Dictionary and boost.has("until"):
			boosts[slot] = {"name": String(boost.get("name", "Boost")), "xp": float(boost.get("xp", 0.0)), "until": float(boost.until), "icon": String(boost.get("icon", "spark")), "source": String(boost.get("source", ""))}
	changed.emit()

static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("energy")) not in [TYPE_INT, TYPE_FLOAT]:
		return "Save file has invalid wellbeing."
	return ""

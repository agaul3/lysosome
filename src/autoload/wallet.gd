extends Node
## The student's money, in cents: a balance, a short transaction history and
## the snacks carried in the backpack. Money comes from the monthly financial
## aid disbursement, tutoring shifts, merit awards and achievements; it goes
## on food, drink and the student store. Perks (Leadership) raise pay and
## lower prices.
signal changed(balance: int, delta: int, label: String)
const Items = preload("res://data/items.gd")
const STARTING_BALANCE := 30000
const HISTORY_LENGTH := 40
var balance := STARTING_BALANCE
var earned_total := 0
var spent_total := 0
## Newest first: {at (game time), delta, label, kind}.
var history: Array = []
## Carried items (item id -> count).
var carried: Dictionary = {}
## Clothing owned outright (bought at the store or given as a reward),
## wearable whatever the level.
var owned_clothing: Array = []
## Study aids bought at the Campus Store (data/items.gd AIDS), kept all year.
var owned_aids: Array = []

func reset() -> void:
	balance = STARTING_BALANCE
	earned_total = 0
	spent_total = 0
	history.clear()
	carried.clear()
	owned_clothing.clear()
	owned_aids.clear()
	changed.emit(balance, 0, "")

func formatted() -> String:
	return Items.format_money(balance)

## Adds money. `kind` scales it by perks: "tutoring", "award" or "" (none).
func earn(cents: int, label: String, kind := "") -> int:
	if cents <= 0:
		return 0
	var bonus := Skills.effect("money:income")
	if kind == "tutoring":
		bonus += Skills.effect("money:tutoring")
	elif kind == "award":
		bonus += Skills.effect("money:awards")
	var amount := int(round(cents * (1.0 + bonus)))
	balance += amount
	earned_total += amount
	_log(amount, label, kind)
	Achievements.set_stat("money_earned", earned_total)
	changed.emit(balance, amount, label)
	return amount

## Price after the Frugal discount.
func price(cents: int) -> int:
	return int(round(cents * (1.0 - clampf(Skills.effect("money:discount"), 0.0, 0.5))))

func can_afford(cents: int) -> bool:
	return balance >= price(cents)

## Pays a (discountable) price. False, and nothing changes, if short.
func spend(cents: int, label: String, kind := "purchase") -> bool:
	var amount := price(cents)
	if amount < 0 or balance < amount:
		return false
	balance -= amount
	spent_total += amount
	_log(-amount, label, kind)
	Achievements.set_stat("money_spent", spent_total)
	changed.emit(balance, -amount, label)
	return true

## Buys an item: eaten now, or carried if `to_go` and it can be carried.
func buy(item_id: String, to_go := false) -> bool:
	var item := Items.get_item(item_id)
	if item.is_empty():
		return false
	if to_go and not item.get("carry", false):
		return false
	if not spend(int(item.price), item.name, "food"):
		return false
	Achievements.bump("items_bought")
	if to_go:
		carried[item_id] = int(carried.get(item_id, 0)) + 1
		changed.emit(balance, 0, item.name)
	else:
		Wellbeing.consume(item_id)
	return true

## Eats or drinks a carried item.
func use(item_id: String) -> bool:
	if int(carried.get(item_id, 0)) <= 0:
		return false
	carried[item_id] = int(carried[item_id]) - 1
	if int(carried[item_id]) <= 0:
		carried.erase(item_id)
	Wellbeing.consume(item_id)
	changed.emit(balance, 0, "")
	return true

## Adds a clothing item to what the student owns (a store purchase or a reward).
func grant_clothing(item_id: String) -> void:
	if item_id not in owned_clothing:
		owned_clothing.append(item_id)
		changed.emit(balance, 0, "")

func owns_clothing(item_id: String) -> bool:
	return item_id in owned_clothing

## Buys a piece of clothing at the Campus Store: owned (and wearable) from now on.
func buy_clothing(item_id: String) -> bool:
	var cost := Items.store_price(item_id)
	if cost <= 0 or owns_clothing(item_id) or not spend(cost, preload("res://data/clothing.gd").item_name(item_id), "store"):
		return false
	grant_clothing(item_id)
	Achievements.bump("store_purchases")
	return true

## Buys a study aid: its bonus applies for the rest of the year.
func buy_aid(aid_id: String) -> bool:
	var aid := Items.get_aid(aid_id)
	if aid.is_empty() or aid_id in owned_aids or not spend(int(aid.price), String(aid.name), "store"):
		return false
	owned_aids.append(aid_id)
	Achievements.bump("store_purchases")
	Skills.changed.emit()
	changed.emit(balance, 0, String(aid.name))
	return true

func aid_effect(key: String) -> float:
	return Items.aid_effect(key, owned_aids)

func _log(delta: int, label: String, kind: String) -> void:
	history.push_front({"at": int(GameClock.now_seconds()), "delta": delta, "label": label, "kind": kind})
	if history.size() > HISTORY_LENGTH:
		history.resize(HISTORY_LENGTH)

func snapshot() -> Dictionary:
	return {"balance": balance, "earned_total": earned_total, "spent_total": spent_total, "history": history.duplicate(true), "carried": carried.duplicate(), "owned_clothing": owned_clothing.duplicate(), "owned_aids": owned_aids.duplicate()}

func restore(data: Dictionary) -> void:
	balance = int(data.get("balance", STARTING_BALANCE))
	earned_total = maxi(0, int(data.get("earned_total", 0)))
	spent_total = maxi(0, int(data.get("spent_total", 0)))
	history = []
	for entry in data.get("history", []):
		if entry is Dictionary:
			history.append({"at": int(entry.get("at", 0)), "delta": int(entry.get("delta", 0)), "label": String(entry.get("label", "")), "kind": String(entry.get("kind", ""))})
	carried.clear()
	var saved: Dictionary = data.get("carried", {})
	for id in saved:
		if Items.ITEMS.has(id) and int(saved[id]) > 0:
			carried[id] = int(saved[id])
	owned_clothing.clear()
	for id in data.get("owned_clothing", []):
		if typeof(id) == TYPE_STRING and preload("res://data/clothing.gd").ITEMS.has(id):
			owned_clothing.append(id)
	owned_aids.clear()
	for id in data.get("owned_aids", []):
		if typeof(id) == TYPE_STRING and Items.AIDS.has(id) and id not in owned_aids:
			owned_aids.append(id)
	changed.emit(balance, 0, "")

static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("balance")) not in [TYPE_INT, TYPE_FLOAT]:
		return "Save file has an invalid wallet."
	return ""

extends Node
## Skill points and perks (data/skill_tree.gd). Points come from levels (one
## per level gained) and achievement rewards; each perk rank costs one point
## and needs its prerequisites and a minimum level. Other systems ask
## effect(key) for the summed bonus of every rank bought.
signal changed
const SkillTree = preload("res://data/skill_tree.gd")
## Perk id -> ranks bought.
var ranks: Dictionary = {}
## Skill points granted by achievements.
var bonus_points := 0

func reset() -> void:
	ranks.clear()
	bonus_points = 0
	changed.emit()

func points_total() -> int:
	return maxi(0, AcademicSession.level - 1) + bonus_points

func points_spent() -> int:
	var total := 0
	for id in ranks:
		total += int(ranks[id])
	return total

func points_available() -> int:
	return maxi(0, points_total() - points_spent())

func rank(id: String) -> int:
	return int(ranks.get(id, 0))

## Why the next rank of `id` cannot be bought, or "" if it can.
func block_reason(id: String) -> String:
	if not SkillTree.PERKS.has(id):
		return "Unknown perk"
	var perk: Dictionary = SkillTree.PERKS[id]
	if rank(id) >= int(perk.ranks):
		return "Fully trained"
	if AcademicSession.level < int(perk.level):
		return "Requires level %d" % int(perk.level)
	for required in perk.requires:
		if rank(required) < int(perk.requires[required]):
			return "Requires %s %s" % [SkillTree.PERKS[required].name, _roman(int(perk.requires[required]))]
	if points_available() <= 0:
		return "No skill points"
	return ""

func can_buy(id: String) -> bool:
	return block_reason(id).is_empty()

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	ranks[id] = rank(id) + 1
	changed.emit()
	Achievements.bump("perks_bought")
	return true

## Summed bonus of `key` over every rank bought, plus the study aids owned
## (data/items.gd AIDS), which use the same keys.
func effect(key: String) -> float:
	var total := Wallet.aid_effect(key)
	for id in ranks:
		var perk: Dictionary = SkillTree.PERKS.get(id, {})
		total += float(perk.get("effects", {}).get(key, 0.0)) * int(ranks[id])
	return total

func grant_points(amount: int) -> void:
	bonus_points += maxi(0, amount)
	changed.emit()

func title() -> String:
	return SkillTree.title_for_level(AcademicSession.level)

func snapshot() -> Dictionary:
	return {"ranks": ranks.duplicate(), "bonus_points": bonus_points}

func restore(data: Dictionary) -> void:
	ranks.clear()
	var saved: Dictionary = data.get("ranks", {})
	for id in saved:
		if SkillTree.PERKS.has(id):
			ranks[id] = clampi(int(saved[id]), 0, int(SkillTree.PERKS[id].ranks))
	bonus_points = maxi(0, int(data.get("bonus_points", 0)))
	changed.emit()

static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("ranks", {})) != TYPE_DICTIONARY:
		return "Save file has invalid skills."
	return ""

static func _roman(value: int) -> String:
	return ["", "I", "II", "III", "IV", "V"][clampi(value, 0, 5)]

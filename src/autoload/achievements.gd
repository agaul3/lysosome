extends Node
## Lifetime stats and achievements (data/achievements.gd).
##
## Systems report what happened (bump/set_stat for counters, set_flag for
## one-off moments); every change re-checks the catalogue and unlocks what
## is due, once, paying its reward: money, skill points or clothing (never
## XP, which stays a measure of learning).
## A few stats are read live from other systems (level, best streak,
## lectures completed) so they can never drift.
signal unlocked(id: String, achievement: Dictionary)
signal stats_changed
const Catalogue = preload("res://data/achievements.gd")
var stats: Dictionary = {}
var flags: Dictionary = {}
## id -> game time unlocked.
var unlocked_at: Dictionary = {}
## Places visited (for the explorer achievements).
var visited: Dictionary = {}
var _checking := false

func _ready() -> void:
	AcademicSession.answer_recorded.connect(_on_answer)
	AcademicSession.level_up.connect(func(_from: int, _to: int) -> void: check())
	AcademicSession.lecture_completed.connect(_on_lecture_completed)
	AcademicSession.attendance_recorded.connect(_on_attendance)
	AcademicSession.streak_changed.connect(func(_streak: int) -> void: check())

func reset() -> void:
	stats.clear()
	flags.clear()
	unlocked_at.clear()
	visited.clear()
	stats_changed.emit()

func stat(name: String) -> int:
	match name:
		"level":
			return AcademicSession.level
		"best_streak":
			return AcademicSession.best_streak
		"lectures_completed":
			return _lectures_completed()
	return int(stats.get(name, 0))

func bump(name: String, amount := 1) -> void:
	stats[name] = int(stats.get(name, 0)) + amount
	stats_changed.emit()
	check()

func set_stat(name: String, value: int) -> void:
	if int(stats.get(name, 0)) == value:
		return
	stats[name] = value
	stats_changed.emit()
	check()

func set_flag(name: String) -> void:
	if flags.has(name):
		return
	flags[name] = true
	stats_changed.emit()
	check()

func has_flag(name: String) -> bool:
	return flags.has(name)

## Notes that something happened today ("lecture", "club", "workout"); all
## three in one day earns Balance.
func note_today(kind: String) -> void:
	var date := YearCalendar.today_date()
	set_flag("today:%s:%s" % [date, kind])
	if ["lecture", "club", "workout"].all(func(done: String) -> bool: return flags.has("today:%s:%s" % [date, done])):
		set_flag("balanced_day")

## Records a first visit to a place (a building or floor).
func visit(place: String) -> void:
	if visited.has(place):
		return
	visited[place] = true
	set_stat("buildings_visited", visited.size())

func is_unlocked(id: String) -> bool:
	return unlocked_at.has(id)

## [current, goal] for a stat goal (flags: 0/1 of 1).
func progress(id: String) -> Array:
	var goal: Dictionary = Catalogue.ACHIEVEMENTS[id].goal
	if goal.has("flag"):
		return [1 if flags.has(goal.flag) else 0, 1]
	return [mini(stat(goal.stat), int(goal.value)), int(goal.value)]

## Unlocks everything whose goal is met (rewards may cascade, e.g. XP → level).
func check() -> void:
	if _checking:
		return
	_checking = true
	var pending := true
	while pending:
		pending = false
		for id in Catalogue.ACHIEVEMENTS:
			if unlocked_at.has(id):
				continue
			var goal: Dictionary = Catalogue.ACHIEVEMENTS[id].goal
			var met := flags.has(goal.flag) if goal.has("flag") else stat(goal.stat) >= int(goal.value)
			if met:
				_unlock(id)
				pending = true
	_checking = false

func _unlock(id: String) -> void:
	var achievement: Dictionary = Catalogue.ACHIEVEMENTS[id]
	unlocked_at[id] = int(GameClock.now_seconds())
	var reward: Dictionary = achievement.get("reward", {})
	if int(reward.get("money", 0)) > 0:
		Wallet.earn(int(reward.money), "Achievement · " + achievement.title)
	if int(reward.get("skill_points", 0)) > 0:
		Skills.grant_points(int(reward.skill_points))
	if not String(reward.get("item", "")).is_empty():
		Wallet.grant_clothing(String(reward.item))
	# The fanfare waits a moment so it never lands on top of the answer chime.
	if is_inside_tree():
		get_tree().create_timer(0.7).timeout.connect(func() -> void: Sfx.play("achievement"))
	unlocked.emit(id, achievement)

func unlocked_count() -> int:
	return unlocked_at.size()

func reward_text(id: String) -> String:
	var reward: Dictionary = Catalogue.ACHIEVEMENTS[id].get("reward", {})
	var parts: Array = []
	if int(reward.get("money", 0)) > 0:
		parts.append("+" + preload("res://data/items.gd").format_money(int(reward.money)))
	if int(reward.get("skill_points", 0)) > 0:
		parts.append("+%d skill point%s" % [int(reward.skill_points), "" if int(reward.skill_points) == 1 else "s"])
	if not String(reward.get("item", "")).is_empty():
		parts.append(preload("res://data/clothing.gd").item_name(String(reward.item)))
	return " · ".join(parts)

# --- Event hooks ------------------------------------------------------------------------------

func _on_answer(result: Dictionary) -> void:
	if result.get("correct", false):
		bump("questions_correct")
	else:
		check()

func _on_attendance(record: Dictionary) -> void:
	if not record.get("late", true):
		bump("on_time_arrivals")

func _on_lecture_completed(lecture_id: String) -> void:
	var summary: Dictionary = AcademicSession.lectures_completed.get(lecture_id, {})
	var accuracy := float(summary.get("accuracy", 0.0))
	if accuracy >= 0.8 and int(summary.get("attempted", 0)) > 0:
		set_flag("lecture_80")
	if accuracy >= 1.0 and int(summary.get("attempted", 0)) > 0:
		set_flag("lecture_100")
	if not lecture_id.begins_with("hospital_") and not lecture_id.begins_with("immersion_"):
		note_today("lecture")
	check()

## Lectures only (the shadowing session is stored with them, but it isn't a lecture).
func _lectures_completed() -> int:
	var count := 0
	for id in AcademicSession.lectures_completed:
		if not String(id).begins_with("hospital_") and not String(id).begins_with("immersion_"):
			count += 1
	return count

func snapshot() -> Dictionary:
	return {"stats": stats.duplicate(), "flags": flags.duplicate(), "unlocked": unlocked_at.duplicate(), "visited": visited.duplicate()}

func restore(data: Dictionary) -> void:
	stats.clear()
	flags.clear()
	unlocked_at.clear()
	visited.clear()
	for key in data.get("stats", {}):
		stats[String(key)] = int(data.stats[key])
	for key in data.get("flags", {}):
		flags[String(key)] = true
	for key in data.get("unlocked", {}):
		if Catalogue.ACHIEVEMENTS.has(key):
			unlocked_at[String(key)] = int(data.unlocked[key])
	for key in data.get("visited", {}):
		visited[String(key)] = true
	stats_changed.emit()

static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "Save file has invalid achievements."
	for key in ["stats", "flags", "unlocked"]:
		if typeof(data.get(key, {})) != TYPE_DICTIONARY:
			return "Save file has invalid achievements."
	return ""

extends Node
## Minimum session ledger/hooks for attendance and question evaluation, not the level system.
signal attendance_recorded(record: Dictionary)
signal answer_recorded(result: Dictionary)
## XP moved by `delta` for `reason` ("answer", "late"); `before`/`after` are totals.
signal xp_changed(before: int, after: int, delta: int, reason: String)
signal level_up(from_level: int, to_level: int)
signal streak_changed(streak: int)
const LevelCurve = preload("res://education/progression/level_curve.gd")
var attendance: Dictionary = {}
var xp_balance := 0
var question_history: Dictionary = {}
var topic_statistics: Dictionary = {}
var attempted := 0
var correct := 0
## Highest level reached. Levels never go down, so a late penalty after
## earning XP cannot undo a level-up.
var level := 1
## Consecutive correct answers (reset by any incorrect answer) and the best run.
var streak := 0
var best_streak := 0
## Lecture id -> summary {correct, attempted, accuracy, xp} once completed this session.
var lectures_completed: Dictionary = {}
## Lecture id -> number of segments reached (lecture notes fill in as class goes).
var notes_progress: Dictionary = {}

func reset() -> void:
	attendance.clear()
	xp_balance = 0
	question_history.clear()
	topic_statistics.clear()
	attempted = 0
	correct = 0
	lectures_completed.clear()
	notes_progress.clear()
	level = 1
	streak = 0
	best_streak = 0

func events_for_date(date: String) -> Array:
	return GameClock.config.events.filter(func(event: Dictionary) -> bool: return event.date == date).duplicate(true)

func record_arrival(event_id: String, arrived_at: float = -1.0) -> Dictionary:
	var event: Dictionary = {}
	for candidate in GameClock.config.events:
		if candidate.id == event_id:
			event = candidate
	if event.is_empty():
		return {}
	var key: String = event.date + ":" + event_id
	if attendance.has(key):
		return attendance[key].duplicate(true)
	var timestamp := GameClock.now_seconds() if arrived_at < 0 else arrived_at
	if not is_finite(timestamp) or Time.get_date_string_from_unix_time(int(timestamp)) != event.date:
		return {} # A one-off event must not penalize a different day's visit.
	var start := Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [event.date, event.hour, event.minute])
	var late := timestamp > start + float(event.late_grace_seconds)
	var penalty: int = int(event.late_penalty) if late and event.mandatory else 0
	if penalty > 0:
		add_xp(-penalty, "late")
	var record := {"event_id": event_id, "date": event.date, "arrival_time": timestamp, "late": late, "xp_delta": -penalty, "penalty_applied": penalty > 0}
	attendance[key] = record.duplicate(true)
	attendance_recorded.emit(record.duplicate(true))
	return record

func commit_answer(attempt_id: String, question: Dictionary, result: Dictionary) -> void:
	question_history[attempt_id] = result.duplicate(true)
	attempted += 1
	correct += 1 if result.correct else 0
	streak = streak + 1 if result.correct else 0
	best_streak = maxi(best_streak, streak)
	streak_changed.emit(streak)
	if int(result.xp_reward) != 0:
		add_xp(int(result.xp_reward), "answer")
	for key in [question.discipline, question.discipline + "/" + question.topic, question.discipline + "/" + question.topic + "/" + question.subtopic]:
		var counts: Dictionary = topic_statistics.get(key, {"attempted": 0, "correct": 0})
		counts.attempted += 1
		counts.correct += 1 if result.correct else 0
		topic_statistics[key] = counts
	answer_recorded.emit(result.duplicate(true))

## The single place XP changes. Awards past a threshold carry over into the
## next level; several levels can be gained at once (one level_up signal).
func add_xp(delta: int, reason: String) -> void:
	var before := xp_balance
	xp_balance += delta
	xp_changed.emit(before, xp_balance, delta, reason)
	var reached := LevelCurve.level_for_xp(xp_balance)
	if reached > level:
		var previous := level
		level = reached
		level_up.emit(previous, level)

## HUD data: the displayed level never drops; progress is clamped to it.
func level_progress() -> Dictionary:
	var progress := LevelCurve.progress(xp_balance)
	if progress.level < level:
		progress = {"level": level, "into": 0, "needed": LevelCurve.cost(level), "fraction": 0.0}
	return progress

func streak_visible() -> bool:
	return streak >= int(GameClock.config.get("streak_display_threshold", 10))

func accuracy(topic: String) -> float:
	var counts: Dictionary = topic_statistics.get(topic, {"attempted": 0, "correct": 0})
	return float(counts.correct) / counts.attempted if counts.attempted > 0 else 0.0

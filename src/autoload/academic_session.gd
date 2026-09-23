extends Node
## Minimum session ledger/hooks for attendance and question evaluation, not the level system.
signal attendance_recorded(record: Dictionary)
signal answer_recorded(result: Dictionary)
var attendance: Dictionary = {}
var xp_balance := 0
var question_history: Dictionary = {}
var topic_statistics: Dictionary = {}
var attempted := 0
var correct := 0
## Lecture id -> true once its presentation has been delivered this session.
var presentations_completed: Dictionary = {}

func reset() -> void:
	attendance.clear()
	xp_balance = 0
	question_history.clear()
	topic_statistics.clear()
	attempted = 0
	correct = 0
	presentations_completed.clear()

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
	xp_balance -= penalty
	var record := {"event_id": event_id, "date": event.date, "arrival_time": timestamp, "late": late, "xp_delta": -penalty, "penalty_applied": penalty > 0}
	attendance[key] = record.duplicate(true)
	attendance_recorded.emit(record.duplicate(true))
	return record

func commit_answer(attempt_id: String, question: Dictionary, result: Dictionary) -> void:
	question_history[attempt_id] = result.duplicate(true)
	attempted += 1
	correct += 1 if result.correct else 0
	xp_balance += int(result.xp_reward)
	for key in [question.discipline, question.discipline + "/" + question.topic, question.discipline + "/" + question.topic + "/" + question.subtopic]:
		var counts: Dictionary = topic_statistics.get(key, {"attempted": 0, "correct": 0})
		counts.attempted += 1
		counts.correct += 1 if result.correct else 0
		topic_statistics[key] = counts
	answer_recorded.emit(result.duplicate(true))

func accuracy(topic: String) -> float:
	var counts: Dictionary = topic_statistics.get(topic, {"attempted": 0, "correct": 0})
	return float(counts.correct) / counts.attempted if counts.attempted > 0 else 0.0

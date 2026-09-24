extends RefCounted
## Deterministic Anki-style classic scheduler. Seconds use real time, not GameClock.
## Learning: 1m / 10m; graduation: 1d; easy: 4d; relearning: 10m.
## No FSRS, fuzz or local 4am rollover; a day is a UTC calendar day.
const DAY := 86400
const MAX_DAYS := 36500

static func fresh() -> Dictionary:
	return {"phase": "new", "step": 0, "due": 0, "interval": 0, "ease": 2.5,
		"reps": 0, "lapses": 0, "suspended": false, "buried_until": 0, "reward_day": -1}

static func next(state: Dictionary, rating: int, now: int) -> Dictionary:
	var result := state.duplicate(true)
	if rating < 1 or rating > 4:
		return result
	var delay := 60
	if state.phase == "review":
		var old := int(state.interval)
		var late := maxi(0, int((now - int(state.due)) / DAY))
		var hard := maxi(old + 1, int(round(old * 1.2)))
		var good := maxi(hard + 1, int(round((old + late / 2.0) * float(state.ease))))
		var easy := maxi(good + 1, int(round((old + late) * float(state.ease) * 1.3)))
		match rating:
			1:
				result.phase = "relearning"
				result.step = 0
				result.interval = 1
				result.ease = maxf(1.3, float(state.ease) - 0.2)
				result.lapses += 1
				delay = 600
				# Leech: pause after eight lapses so the note can be rewritten.
				if result.lapses >= 8:
					result.suspended = true
			2:
				result.ease = maxf(1.3, float(state.ease) - 0.15)
				result.interval = mini(hard, MAX_DAYS)
			3: result.interval = mini(good, MAX_DAYS)
			4:
				result.ease += 0.15
				result.interval = mini(easy, MAX_DAYS)
		if rating != 1:
			delay = result.interval * DAY
	else:
		var relearning: bool = state.phase == "relearning"
		result.phase = "relearning" if relearning else "learning"
		match rating:
			1:
				result.step = 0
				delay = 600 if relearning else 60
			2: delay = 900 if relearning else (330 if int(state.step) == 0 else 600)
			3:
				if relearning or int(state.step) == 1:
					result.phase = "review"
					result.interval = maxi(1, int(state.interval))
					delay = result.interval * DAY
				else:
					result.step = 1
					delay = 600
			4:
				result.phase = "review"
				result.interval = maxi(4, int(state.interval))
				delay = result.interval * DAY
	result.due = now + delay
	result.reps += 1
	return result

static func interval_text(seconds: int) -> String:
	if seconds < 60:
		return "%ds" % maxi(1, seconds)
	if seconds < 3600:
		return str(snappedf(seconds / 60.0, 0.1)) + "m"
	if seconds < DAY:
		return str(snappedf(seconds / 3600.0, 0.1)) + "h"
	return "%dd" % int(ceil(seconds / float(DAY)))

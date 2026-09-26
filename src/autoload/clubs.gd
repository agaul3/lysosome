extends Node
## Membership and reputation in the student organizations (data/clubs.gd),
## and whether their meetings are on.
##
## A meeting is "on" from Data.EARLY minutes before it starts until it ends,
## on the weekdays the club meets; a member takes part once per meeting.
## record() is called when the club's activity ends: the score (0–1) earns
## reputation, and a new level brings its reward (the shirt at level 2, a
## skill point at 3, the Club Officer achievement at 5).
signal changed
## {club, score, points, level_before, level, reward}
signal event_recorded(result: Dictionary)
const Data = preload("res://data/clubs.gd")
const Clothing = preload("res://data/clothing.gd")
var memberships: Array = []
## club id -> reputation points (kept if you leave, in case you come back).
var reputation: Dictionary = {}
## "date:club" -> score (0–1) of each meeting taken part in.
var attended: Dictionary = {}

func reset() -> void:
	memberships.clear()
	reputation.clear()
	attended.clear()
	changed.emit()

func is_member(id: String) -> bool:
	return id in memberships

## "" if you can join, otherwise why not.
func join_block(id: String) -> String:
	if not Data.CLUBS.has(id):
		return "There's no such organization."
	if is_member(id):
		return "You're already a member."
	if memberships.size() >= Data.MAX_MEMBERSHIPS:
		return "You can be in %d organizations at a time. Leave one first." % Data.MAX_MEMBERSHIPS
	return ""

func join(id: String) -> bool:
	if not join_block(id).is_empty():
		return false
	memberships.append(id)
	if not reputation.has(id):
		reputation[id] = 0
	Achievements.set_stat("clubs_joined", maxi(Achievements.stat("clubs_joined"), memberships.size()))
	changed.emit()
	return true

func leave(id: String) -> void:
	if memberships.has(id):
		memberships.erase(id)
		changed.emit()

func points(id: String) -> int:
	return int(reputation.get(id, 0))

func level(id: String) -> int:
	return Data.level_for(points(id))

## [points into this level, points the level spans] (the span is 0 at level 5).
func level_progress(id: String) -> Array:
	var current := level(id)
	if current >= Data.LEVELS.size():
		return [0, 0]
	var floor_points: int = Data.LEVELS[current - 1]
	return [points(id) - floor_points, int(Data.LEVELS[current]) - floor_points]

## Today's meeting of a club as {start, end} game times ({} if it doesn't
## meet today).
func meeting_today(id: String) -> Dictionary:
	var club := Data.get_club(id)
	if club.is_empty():
		return {}
	var now := GameClock.snapshot()
	for meeting in club.meets:
		if int(meeting[0]) == int(now.weekday):
			var start := Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [now.date, int(meeting[1]), int(meeting[2])])
			return {"start": float(start), "end": float(start) + float(club.minutes) * 60.0}
	return {}

## Whether the club's meeting is on now (and you haven't taken part yet).
func meeting_on(id: String) -> bool:
	var meeting := meeting_today(id)
	if meeting.is_empty() or attended_today(id):
		return false
	var now := GameClock.now_seconds()
	return now >= float(meeting.start) - Data.EARLY * 60.0 and now < float(meeting.end)

func attended_today(id: String) -> bool:
	return attended.has(YearCalendar.today_date() + ":" + id)

## Clubs meeting now at a scene key (and room, if given).
func meetings_at(place: String, room := "") -> Array:
	var result: Array = []
	for id in Data.CLUBS:
		var club: Dictionary = Data.CLUBS[id]
		if String(club.place) == place and (room.is_empty() or String(club.room) == room) and meeting_on(id):
			result.append(id)
	return result

## "Today at 5:30 PM", "Now, until 7:30 PM", or the club's weekly schedule.
func when_text(id: String) -> String:
	var meeting := meeting_today(id)
	if not meeting.is_empty():
		var now := GameClock.now_seconds()
		if attended_today(id):
			return "You took part today"
		if now >= float(meeting.start) - Data.EARLY * 60.0 and now < float(meeting.end):
			return "Meeting now, until " + _clock(float(meeting.end))
		if now < float(meeting.start):
			return "Today at " + _clock(float(meeting.start))
	return Data.schedule_text(id)

func _clock(timestamp: float) -> String:
	var moment := Time.get_datetime_dict_from_unix_time(int(timestamp))
	var hour := int(moment.hour)
	return "%d:%02d %s" % [12 if hour % 12 == 0 else hour % 12, int(moment.minute), "AM" if hour < 12 else "PM"]

## A meeting's activity finished with `score` (0–1): reputation, rewards
## and the counters behind the achievements. Returns what happened.
func record(id: String, score: float) -> Dictionary:
	var club := Data.get_club(id)
	if club.is_empty():
		return {}
	var before := level(id)
	var earned := int(round((12.0 + 18.0 * clampf(score, 0.0, 1.0)) * (1.0 + Skills.effect("club:reputation"))))
	reputation[id] = points(id) + earned
	attended[YearCalendar.today_date() + ":" + id] = clampf(score, 0.0, 1.0)
	var after := level(id)
	var reward := ""
	for reached in range(before + 1, after + 1):
		match reached:
			2:
				Wallet.grant_clothing(String(club.shirt))
				reward = Clothing.item_name(String(club.shirt))
			3:
				Skills.grant_points(1)
				reward = "+1 skill point"
			5:
				Achievements.set_flag("club_max_reputation")
				reward = "Club Officer"
	Achievements.bump("club_events")
	Achievements.note_today("club")
	var result := {"club": id, "score": score, "points": earned, "level_before": before, "level": after, "reward": reward}
	changed.emit()
	event_recorded.emit(result)
	return result

func snapshot() -> Dictionary:
	return {"memberships": memberships.duplicate(), "reputation": reputation.duplicate(), "attended": attended.duplicate()}

func restore(data: Dictionary) -> void:
	reset()
	for id in data.get("memberships", []):
		if Data.CLUBS.has(String(id)) and not memberships.has(String(id)) and memberships.size() < Data.MAX_MEMBERSHIPS:
			memberships.append(String(id))
	var saved: Dictionary = data.get("reputation", {})
	for id in saved:
		if Data.CLUBS.has(String(id)):
			reputation[String(id)] = maxi(0, int(saved[id]))
	var days: Dictionary = data.get("attended", {})
	for key in days:
		attended[String(key)] = clampf(float(days[key]), 0.0, 1.0)
	changed.emit()

static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("memberships", [])) != TYPE_ARRAY or typeof(data.get("reputation", {})) != TYPE_DICTIONARY:
		return "Save file has invalid club data."
	return ""

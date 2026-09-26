extends Node
## The first year as a sequence of story days (data/year_one.json).
##
## Each story day is played from morning to night. Sleeping ends it: today's
## unattended mandatory events are marked absent (a missed exam gets a make-up
## the next day), a summary of the day is produced, and the clock jumps to
## the next *ready* story day's wake-up time, with energy restored and a
## "Well Rested" boost after an early night. The monthly financial aid
## disbursement is paid on the first story day of each new month.
##
## The year's events are merged into the schedule (GameClock.config.events)
## so attendance, lateness and the schedule pages work for all of them, with
## day 1's two events defined in academic_config.json as before.
##
## A day can be flagged "ready": false to skip it while its content is being
## built (every day of the first year is ready now). After the last story day
## the year is over and each night leads to a free summer morning.
signal day_started(day: Dictionary)
signal day_ended(summary: Dictionary)
## The night ran past 2 AM away from bed: the HUD puts the student to sleep.
signal pass_out
const DATA_PATH := "res://data/year_one.json"
const Items = preload("res://data/items.gd")
const STIPEND := 65000
## Sleeping is allowed from this hour; past LATE_HOUR (the next morning) the
## student falls asleep wherever they are.
const BEDTIME_HOUR := 18
const LATE_HOUR := 2
const WEEKDAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var data: Dictionary = {}
var days: Array = []
var events_by_id: Dictionary = {}
var last_error := ""
## Date -> summary of each finished story day.
var completed_days: Dictionary = {}
## Event keys ("date:id") marked absent.
var absences: Dictionary = {}
## Make-up events created for missed exams.
var extra_events: Array = []
## Month ("YYYY-MM") of the last stipend paid (September is covered by the
## starting balance).
var last_stipend_month := "2026-09"
## Totals at the start of the current day, for its summary.
var day_start := {}

func _ready() -> void:
	load_data()
	mark_day_start()
	GameClock.minute_changed.connect(_on_minute)

func load_data() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	var error := validate(parsed)
	if not error.is_empty():
		last_error = error
		push_error(error)
		return false
	data = parsed
	days = data.days.duplicate(true)
	days.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.date) < String(b.date))
	_merge_events(data.events)
	return true

static func validate(parsed: Variant) -> String:
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != 1:
		return "Year data needs version 1"
	for key in ["terms", "blocks", "days", "events"]:
		if typeof(parsed.get(key)) != TYPE_ARRAY:
			return "Year data needs '%s'" % key
	var blocks := {}
	for block in parsed.blocks:
		blocks[String(block.get("id", ""))] = true
	var dates := {}
	for day in parsed.days:
		if typeof(day) != TYPE_DICTIONARY or typeof(day.get("date")) != TYPE_STRING or Time.get_unix_time_from_datetime_string(String(day.date) + "T00:00:00") <= 0:
			return "Every story day needs a valid date"
		if dates.has(day.date):
			return "Duplicate story day: " + String(day.date)
		dates[day.date] = true
		if not blocks.has(String(day.get("block", ""))):
			return "Story day %s names an unknown block" % day.date
	var ids := {}
	for event in parsed.events:
		for key in ["id", "title", "date", "location", "type"]:
			if typeof(event.get(key)) != TYPE_STRING or String(event.get(key)).is_empty():
				return "Event needs '%s'" % key
		if ids.has(event.id):
			return "Duplicate event id: " + String(event.id)
		ids[event.id] = true
		if not dates.has(event.date):
			return "Event %s is not on a story day" % event.id
		if int(event.get("hour", -1)) < 0 or int(event.get("hour", -1)) > 23 or int(event.get("minute", -1)) < 0 or int(event.get("minute", -1)) > 59:
			return "Event %s has an invalid time" % event.id
	return ""

func _merge_events(list: Array) -> void:
	var existing := {}
	for event in GameClock.config.events:
		existing[event.id] = true
		events_by_id[event.id] = event
	for event in list:
		if existing.has(event.id):
			continue
		var copy: Dictionary = event.duplicate(true)
		GameClock.config.events.append(copy)
		events_by_id[copy.id] = copy
		existing[copy.id] = true

func reset() -> void:
	completed_days.clear()
	absences.clear()
	last_stipend_month = "2026-09"
	# Drop make-up events a previous game created.
	for event in extra_events:
		GameClock.config.events.erase(events_by_id.get(event.id, {}))
		events_by_id.erase(event.id)
	extra_events.clear()
	mark_day_start()

# --- Days --------------------------------------------------------------------------------------

func today_date() -> String:
	return GameClock.snapshot().date

## The story day for the current date ({} between story days).
func current_day() -> Dictionary:
	return day_for(today_date())

func day_for(date: String) -> Dictionary:
	for day in days:
		if day.date == date:
			return day
	return {}

## 1-based number of the current story day (0 if not on one).
func day_number(date := "") -> int:
	var target := today_date() if date.is_empty() else date
	for index in range(days.size()):
		if days[index].date == target:
			return index + 1
	return 0

func ready_days() -> Array:
	return days.filter(func(day: Dictionary) -> bool: return day.get("ready", false))

## The next ready story day after `date` ({} when the year is over for now).
func next_day(date := "") -> Dictionary:
	var after := today_date() if date.is_empty() else date
	for day in days:
		if String(day.date) > after and day.get("ready", false):
			return day
	return {}

func block(id: String) -> Dictionary:
	for entry in data.get("blocks", []):
		if entry.id == id:
			return entry
	return {}

func current_block() -> Dictionary:
	var date := today_date()
	var found: Dictionary = {}
	for entry in data.get("blocks", []):
		if String(entry.start) <= date:
			found = entry
	return found

func term(date := "") -> Dictionary:
	var target := today_date() if date.is_empty() else date
	var found: Dictionary = {}
	for entry in data.get("terms", []):
		if String(entry.start) <= target:
			found = entry
	return found

## Week of the current term (1-based).
func week_of_term(date := "") -> int:
	var target := today_date() if date.is_empty() else date
	var current := term(target)
	if current.is_empty():
		return 1
	var start := Time.get_unix_time_from_datetime_string(String(current.start) + "T12:00:00")
	var now := Time.get_unix_time_from_datetime_string(target + "T12:00:00")
	return int((now - start) / (7 * 86400)) + 1

## "Week 1 · Wednesday"
func day_heading(date := "") -> String:
	var target := today_date() if date.is_empty() else date
	var moment := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string(target + "T12:00:00"))
	return "Week %d · %s" % [week_of_term(target), WEEKDAYS[int(moment.weekday)]]

func weekday_name(date: String) -> String:
	var moment := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string(date + "T12:00:00"))
	return WEEKDAYS[int(moment.weekday)]

# --- Events ------------------------------------------------------------------------------------

func event(id: String) -> Dictionary:
	return events_by_id.get(id, {})

func events_on(date: String) -> Array:
	var list: Array = GameClock.config.events.filter(func(entry: Dictionary) -> bool: return entry.date == date)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.hour) * 60 + int(a.minute) < int(b.hour) * 60 + int(b.minute))
	return list

static func start_of(entry: Dictionary) -> float:
	return Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [entry.date, int(entry.hour), int(entry.minute)])

static func end_of(entry: Dictionary) -> float:
	return start_of(entry) + float(entry.get("duration", 60)) * 60.0

static func type_of(entry: Dictionary) -> String:
	if entry.has("type"):
		return String(entry.type)
	return "shadowing" if String(entry.id).begins_with("hospital_") else "lecture"

func attended(entry: Dictionary) -> bool:
	return AcademicSession.attendance.has(String(entry.date) + ":" + String(entry.id)) or AcademicSession.lectures_completed.has(String(entry.get("content", entry.id)))

func completed(entry: Dictionary) -> bool:
	return AcademicSession.lectures_completed.has(String(entry.get("content", entry.id))) or Achievements.has_flag("done:" + String(entry.id))

## Marks a non-lecture event finished (ceremonies, labs, encounters…).
func mark_completed(event_id: String) -> void:
	Achievements.set_flag("done:" + event_id)

## The next event today that hasn't finished and hasn't ended ({} if none).
func next_event() -> Dictionary:
	var now := GameClock.now_seconds()
	for entry in events_on(today_date()):
		if completed(entry):
			continue
		if end_of(entry) > now:
			return entry
	return {}

## Mandatory events today that were neither attended nor completed.
func unattended_today() -> Array:
	return events_on(today_date()).filter(func(entry: Dictionary) -> bool: return entry.get("mandatory", false) and not attended(entry) and not completed(entry))

# --- Time --------------------------------------------------------------------------------------

## Moves the clock forward to `timestamp` (never backward).
func advance_to(timestamp: float) -> void:
	var delta := timestamp - GameClock.now_seconds()
	if delta > 0.0:
		GameClock.elapsed_seconds += delta
		GameClock.minute_changed.emit()

## An activity that takes `minutes` of game time (a study group, a shuttle
## ride, a club event, a workout).
func pass_time(minutes: float) -> void:
	advance_to(GameClock.now_seconds() + minutes * 60.0)

## Skips ahead to `lead_minutes` before an event's start.
func wait_for(entry: Dictionary, lead_minutes := 10.0) -> void:
	advance_to(start_of(entry) - lead_minutes * 60.0)

## The last story day of the year.
func last_date() -> String:
	return _last_date_of("spring")

## Every story day is behind the student: the first year is finished.
func year_over() -> bool:
	var last := last_date()
	return not last.is_empty() and completed_days.has(last)

## Bed is for the night: from 6 PM until morning.
func can_sleep() -> bool:
	var hour := int(GameClock.snapshot().hour)
	return hour >= BEDTIME_HOUR or hour < 7

# --- Sleep ---------------------------------------------------------------------------------------

func mark_day_start() -> void:
	day_start = {
		"xp": AcademicSession.xp_balance,
		"earned": Wallet.earned_total,
		"spent": Wallet.spent_total,
		"achievements": Achievements.unlocked_count(),
		"cards": Achievements.stat("flashcards_reviewed"),
		"correct": AcademicSession.correct,
		"attempted": AcademicSession.attempted,
	}

## Ends the story day: absences, the summary, the jump to the next ready day,
## energy, well-rested, stipend. `late` is a night that ran past 2 AM.
func sleep(late := false) -> Dictionary:
	var date := _story_date()
	var bedtime := GameClock.snapshot()
	var missed: Array = []
	for entry in events_on(date):
		if entry.get("mandatory", false) and not attended(entry) and not completed(entry):
			missed.append(entry)
			absences[date + ":" + String(entry.id)] = true
			if type_of(entry) == "exam":
				_schedule_makeup(entry, date)
	var summary := _summary(date, missed)
	if not day_for(date).is_empty():
		completed_days[date] = summary.duplicate(true)
	Achievements.set_stat("days_completed", completed_days.size())
	if date == _last_date_of("fall"):
		Achievements.set_flag("fall_complete")
	if date == _last_date_of("spring"):
		Achievements.set_flag("year_complete")
	var following := next_day(date)
	summary["next"] = following.duplicate(true)
	var early := not late and (int(bedtime.hour) >= BEDTIME_HOUR and int(bedtime.hour) <= 23)
	var wake: Dictionary = data.get("wake", {"hour": 7, "minute": 30})
	var morning := ""
	if not following.is_empty():
		morning = String(following.date)
	elif year_over():
		# Summer break: after the last story day, every night leads to a free
		# morning (no classes; the clubs, the gym and the library carry on).
		morning = today_date() if int(bedtime.hour) < 7 else Time.get_date_string_from_unix_time(int(GameClock.now_seconds()) + 86400)
		summary["summer"] = true
	if not morning.is_empty():
		advance_to(Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [morning, int(wake.hour), int(wake.minute)]))
		Wellbeing.sleep(early, 0.7 if late else 1.0)
		if early:
			Wellbeing.add_boost("rest", "Well Rested", 0.05, 270.0, "moon", "sleep")
			Achievements.bump("well_rested_days")
		summary["well_rested"] = early
		summary["stipend"] = _pay_stipend() if not following.is_empty() else 0
	day_ended.emit(summary)
	mark_day_start()
	if not following.is_empty():
		day_started.emit(following)
	return summary

## The story day being played: today, or yesterday after midnight.
func _story_date() -> String:
	if not current_day().is_empty():
		return today_date()
	var yesterday := Time.get_date_string_from_unix_time(int(GameClock.now_seconds()) - 86400)
	return yesterday if int(GameClock.snapshot().hour) < 7 and not day_for(yesterday).is_empty() else today_date()

func _summary(date: String, missed: Array) -> Dictionary:
	var day := day_for(date)
	var events: Array = []
	for entry in events_on(date):
		events.append({"title": String(entry.title), "attended": attended(entry) or completed(entry), "mandatory": entry.get("mandatory", false), "optional": not entry.get("mandatory", false)})
	return {
		"date": date,
		"title": String(day.get("title", "Summer break" if year_over() else "")),
		"heading": day_heading(date) if not day.is_empty() or not year_over() else "Summer · " + weekday_name(date),
		"xp": AcademicSession.xp_balance - int(day_start.get("xp", 0)),
		"earned": Wallet.earned_total - int(day_start.get("earned", 0)),
		"spent": Wallet.spent_total - int(day_start.get("spent", 0)),
		"achievements": Achievements.unlocked_count() - int(day_start.get("achievements", 0)),
		"cards": Achievements.stat("flashcards_reviewed") - int(day_start.get("cards", 0)),
		"correct": AcademicSession.correct - int(day_start.get("correct", 0)),
		"attempted": AcademicSession.attempted - int(day_start.get("attempted", 0)),
		"events": events,
		"missed": missed.map(func(entry: Dictionary) -> String: return String(entry.title)),
		"energy": int(round(Wellbeing.energy)),
	}

func _pay_stipend() -> int:
	var month := today_date().left(7)
	if month <= last_stipend_month:
		return 0
	last_stipend_month = month
	return Wallet.earn(STIPEND, "Financial aid · living allowance")

func _last_date_of(term_id: String) -> String:
	var term_entry: Dictionary = {}
	for entry in data.get("terms", []):
		if entry.id == term_id:
			term_entry = entry
	var last := ""
	for day in days:
		if not term_entry.is_empty() and String(day.date) >= String(term_entry.start) and String(day.date) <= String(term_entry.end):
			last = day.date
	return last

## A missed exam is rescheduled for 1 PM on the next ready story day.
func _schedule_makeup(entry: Dictionary, date: String) -> void:
	var following := next_day(date)
	if following.is_empty():
		return
	var makeup: Dictionary = entry.duplicate(true)
	makeup.id = String(entry.id) + "_makeup"
	if events_by_id.has(makeup.id):
		return
	makeup.title = "MAKE-UP: " + String(entry.title)
	makeup.date = following.date
	makeup.hour = 13
	makeup.minute = 0
	makeup.description = "Rescheduled after an absence. " + String(entry.get("description", ""))
	extra_events.append(makeup)
	GameClock.config.events.append(makeup)
	events_by_id[makeup.id] = makeup

## Past 2 AM the student falls asleep wherever they are.
func _on_minute() -> void:
	if not AppState.in_world() or AppState.transitioning:
		return
	var day := current_day()
	var now := GameClock.snapshot()
	if day.is_empty() and int(now.hour) >= LATE_HOUR and int(now.hour) < 7:
		var yesterday := Time.get_date_string_from_unix_time(int(GameClock.now_seconds()) - 86400)
		if not day_for(yesterday).is_empty() and not completed_days.has(yesterday):
			pass_out.emit()

func snapshot() -> Dictionary:
	return {"completed_days": completed_days.duplicate(true), "absences": absences.duplicate(), "extra_events": extra_events.duplicate(true), "last_stipend_month": last_stipend_month, "day_start": day_start.duplicate()}

func restore(saved: Dictionary) -> void:
	reset()
	completed_days = saved.get("completed_days", {}).duplicate(true)
	for key in saved.get("absences", {}):
		absences[String(key)] = true
	last_stipend_month = String(saved.get("last_stipend_month", "2026-09"))
	for entry in saved.get("extra_events", []):
		if entry is Dictionary and entry.has("id") and not events_by_id.has(entry.id):
			extra_events.append(entry)
			GameClock.config.events.append(entry)
			events_by_id[entry.id] = entry
	var start: Variant = saved.get("day_start", {})
	if start is Dictionary and not start.is_empty():
		day_start = start.duplicate()
	else:
		mark_day_start()

static func validate_save(saved: Variant) -> String:
	if typeof(saved) != TYPE_DICTIONARY or typeof(saved.get("completed_days", {})) != TYPE_DICTIONARY:
		return "Save file has an invalid calendar."
	return ""

extends Node
signal minute_changed
const CONFIG_PATH := "res://data/academic_config.json"
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
var elapsed_seconds := 0.0
var start_timestamp: int
var running := false

func _ready() -> void:
	reset()

func reset() -> void:
	start_timestamp = Time.get_unix_time_from_datetime_string(config.start_datetime)
	elapsed_seconds = 0.0
	running = false
	minute_changed.emit()

func _process(delta: float) -> void:
	if running:
		advance(delta)

func advance(real_seconds: float) -> void:
	if not is_finite(real_seconds) or real_seconds <= 0:
		return
	var before := int(now_seconds() / 60)
	elapsed_seconds += real_seconds * float(config.time_scale)
	if int(now_seconds() / 60) != before:
		minute_changed.emit()

func now_seconds() -> float:
	return start_timestamp + elapsed_seconds

func snapshot() -> Dictionary:
	var value := Time.get_datetime_dict_from_unix_time(int(now_seconds()))
	value["date"] = "%04d-%02d-%02d" % [value.year, value.month, value.day]
	value["day_of_month"] = value.day
	value["day"] = int((int(now_seconds()) / 86400) - (start_timestamp / 86400)) + 1
	value["academic_week"] = int(config.starting_academic_week) + int((value.day - 1) / 7)
	value["semester"] = config.semester
	return value

func display_time() -> String:
	var value := snapshot()
	var hour: int = value.hour % 12
	return "%d:%02d %s" % [12 if hour == 0 else hour, value.minute, "AM" if value.hour < 12 else "PM"]

func display_date() -> String:
	var value := snapshot()
	return format_date(value.year, value.month, value.day_of_month)

static func format_date(year: int, month: int, day: int) -> String:
	var months := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	var suffix := "th"
	if day % 100 not in [11, 12, 13]:
		suffix = {1: "st", 2: "nd", 3: "rd"}.get(day % 10, "th")
	return "%s %d%s, %d" % [months[month - 1], day, suffix, year]

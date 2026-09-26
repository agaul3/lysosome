extends RefCounted
## Which lecture runs where and when. Lectures are schedule events (day 1's
## in data/academic_config.json, the rest of the year's in
## data/year_one.json) whose script lives at education/lectures/<id>.json.
## Hall A is in the Learning Center; Hall B in the Medical Education Center.
const HALLS := {
	"hall_a": {"name": "Lecture Hall A", "building": "Learning Center"},
	"hall_b": {"name": "Lecture Hall B", "building": "Medical Education Center"},
}
const DEFAULT_LECTURE := "pharmacodynamics_01"

static func path_for(lecture_id: String) -> String:
	return "res://education/lectures/%s.json" % lecture_id

static func exists(lecture_id: String) -> bool:
	return FileAccess.file_exists(path_for(lecture_id))

## The hall a lecture event is in ("hall_a" unless it says Hall B).
static func hall_of(event: Dictionary) -> String:
	return "hall_b" if String(event.get("room", "")) == "hall_b" else "hall_a"

static func is_lecture(event: Dictionary) -> bool:
	if event.has("type"):
		return String(event.type) == "lecture"
	return not String(event.get("id", "")).begins_with("hospital_")

static func _events() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var clock: Node = tree.root.get_node_or_null("GameClock") if tree else null
	return clock.config.events if clock else []

## The lecture scheduled in `hall` on `date` whose script exists ({} if none).
static func lecture_on(hall: String, date: String) -> Dictionary:
	var found: Dictionary = {}
	for event in _events():
		if event.date == date and is_lecture(event) and hall_of(event) == hall and exists(String(event.get("content", event.id))):
			if found.is_empty() or int(event.hour) * 60 + int(event.minute) < int(found.hour) * 60 + int(found.minute):
				found = event
	return found

## Every lecture event of the year, in date order.
static func all_lectures() -> Array:
	var list: Array = _events().filter(func(event: Dictionary) -> bool: return is_lecture(event))
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.date) + "%02d%02d" % [int(a.hour), int(a.minute)] < String(b.date) + "%02d%02d" % [int(b.hour), int(b.minute)])
	return list

static func lecture_id(event: Dictionary) -> String:
	return String(event.get("content", event.get("id", DEFAULT_LECTURE)))

extends RefCounted
## A shadowing session as data (see README.md): the stops a physician walks
## the student through, and at each stop the lines, questions, player actions
## and EHR moments that happen there. This class loads and validates a script;
## world/hospital/shadowing_session.gd runs it in the hospital.
const STEP_KINDS := ["say", "question", "action", "ehr"]
const ACTIONS := ["board", "talk", "sanitize", "stand"]
const EHR_VIEWS := ["open", "close", "banner", "vitals", "results", "notes"]
const LINE_KEYS := ["too_early", "on_time", "late", "after", "wait"]
var data: Dictionary = {}
var last_error := ""

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		last_error = "Shadowing script not found: " + path
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	last_error = validate(parsed)
	if not last_error.is_empty():
		return false
	data = parsed
	return true

func stops() -> Array:
	return data.get("stops", [])

func speaker_name(key: String) -> String:
	return String(data.get("speakers", {}).get(key, key))

func line(key: String) -> String:
	return String(data.get("lines", {}).get(key, ""))

## Every anchor a script refers to (stops, routes and action targets), for
## checking against the scene that runs it.
func anchors() -> Array:
	var result: Array = []
	for stop in stops():
		for id in stop.route + [stop.at]:
			if id not in result:
				result.append(id)
	return result

func action_targets() -> Array:
	var result: Array = []
	for stop in stops():
		for step in stop.steps:
			if step.has("action") and String(step.target) not in result:
				result.append(String(step.target))
	return result

func question_ids() -> Array:
	var result: Array = []
	for stop in stops():
		for step in stop.steps:
			if step.has("question"):
				result.append(String(step.question))
	return result

## "" when the script is well formed.
static func validate(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "Script is not an object"
	if int(value.get("version", 0)) != 1:
		return "Unsupported script version"
	for key in ["id", "title", "unit"]:
		if typeof(value.get(key)) != TYPE_STRING or String(value[key]).strip_edges().is_empty():
			return "Missing field: " + key
	if typeof(value.get("speakers")) != TYPE_DICTIONARY or not value.speakers.has("okafor"):
		return "Speakers must include the physician (okafor)"
	if typeof(value.get("lines")) != TYPE_DICTIONARY:
		return "Missing lines"
	for key in LINE_KEYS:
		if typeof(value.lines.get(key)) != TYPE_STRING or String(value.lines[key]).is_empty():
			return "Missing line: " + key
	if typeof(value.get("stops")) != TYPE_ARRAY or value.stops.is_empty():
		return "A script needs at least one stop"
	var ids: Array = []
	for stop in value.stops:
		if typeof(stop) != TYPE_DICTIONARY:
			return "Stop must be an object"
		for key in ["id", "at", "topic", "objective", "takeaway"]:
			if typeof(stop.get(key)) != TYPE_STRING or String(stop[key]).strip_edges().is_empty():
				return "Stop missing field: " + key
		if stop.id in ids:
			return "Duplicate stop id: " + stop.id
		ids.append(stop.id)
		if typeof(stop.get("route")) != TYPE_ARRAY or typeof(stop.get("steps")) != TYPE_ARRAY or stop.steps.is_empty():
			return "Stop %s needs a route array and steps" % stop.id
		for step in stop.steps:
			var error := _validate_step(step, value.speakers)
			if not error.is_empty():
				return "Stop %s: %s" % [stop.id, error]
	return ""

static func _validate_step(step: Variant, speakers: Dictionary) -> String:
	if typeof(step) != TYPE_DICTIONARY:
		return "step must be an object"
	var kinds: Array = STEP_KINDS.filter(func(kind: String) -> bool: return step.has(kind))
	if kinds.size() != 1:
		return "each step has exactly one of %s" % str(STEP_KINDS)
	match String(kinds[0]):
		"say":
			if typeof(step.say) != TYPE_STRING or String(step.say).strip_edges().is_empty():
				return "empty line"
			if step.has("speaker") and not speakers.has(step.speaker):
				return "unknown speaker " + str(step.speaker)
		"question":
			if typeof(step.question) != TYPE_STRING or String(step.question).is_empty():
				return "question needs an id"
		"action":
			if not String(step.action) in ACTIONS:
				return "unknown action " + str(step.action)
			for key in ["target", "objective"]:
				if typeof(step.get(key)) != TYPE_STRING or String(step[key]).is_empty():
					return "action needs " + key
			if step.action == "talk" and (typeof(step.get("reply")) != TYPE_STRING or String(step.reply).is_empty()):
				return "talk action needs a reply"
		"ehr":
			if not String(step.ehr) in EHR_VIEWS:
				return "unknown EHR view " + str(step.ehr)
	return ""

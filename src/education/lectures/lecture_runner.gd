extends RefCounted
## Loads a lecture script (JSON, see README.md) and steps through it one
## professor line at a time. Knows nothing about scenes or UI; views listen to
## its signals. Question and visualization beats will join the same cursor.
signal segment_started(segment: Dictionary, index: int)
signal line_started(line: Dictionary)
signal finished
const GESTURES := ["audience", "screen", "none"]
const DIAGRAMS := ["title", "receptor_binding", "full_partial", "antagonist_block", "competitive_shift", "noncompetitive", "potency", "efficacy", "graded_quantal", "clinical_opioid", "summary"]

var script_data: Dictionary = {}
var segment_index := -1
var line_index := -1
var last_error := ""
var done := false

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		last_error = "Missing lecture file: " + path
		return false
	return load_json(FileAccess.get_file_as_string(path))

func load_json(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	var error := validate(parsed)
	if not error.is_empty():
		last_error = error
		return false
	script_data = parsed
	reset()
	return true

static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "Lecture must be an object"
	for field in ["id", "title", "professor"]:
		if typeof(data.get(field)) != TYPE_STRING or String(data.get(field)).is_empty():
			return "Lecture needs a nonempty '%s'" % field
	if int(data.get("version", 0)) != 1:
		return "Unsupported lecture version"
	var segments: Variant = data.get("segments")
	if typeof(segments) != TYPE_ARRAY or segments.is_empty():
		return "Lecture needs segments"
	var ids := {}
	for segment in segments:
		if typeof(segment) != TYPE_DICTIONARY or typeof(segment.get("id")) != TYPE_STRING:
			return "Each segment needs an id"
		if ids.has(segment.id):
			return "Duplicate segment id: " + segment.id
		ids[segment.id] = true
		var slide: Variant = segment.get("slide")
		if typeof(slide) != TYPE_DICTIONARY or typeof(slide.get("heading")) != TYPE_STRING or typeof(slide.get("bullets")) != TYPE_ARRAY:
			return "Segment %s needs a slide with heading and bullets" % segment.id
		if slide.bullets.size() > 5:
			return "Segment %s has too many bullets for one slide" % segment.id
		if not DIAGRAMS.has(slide.get("diagram", "")):
			return "Segment %s has an unknown diagram" % segment.id
		var lines: Variant = segment.get("lines")
		if typeof(lines) != TYPE_ARRAY or lines.is_empty():
			return "Segment %s needs professor lines" % segment.id
		for line in lines:
			if typeof(line) != TYPE_DICTIONARY or typeof(line.get("text")) != TYPE_STRING or String(line.text).strip_edges().is_empty():
				return "Segment %s has an empty line" % segment.id
			if not GESTURES.has(line.get("gesture", "none")):
				return "Segment %s has an unknown gesture" % segment.id
			if int(line.get("reveal", 0)) > slide.bullets.size():
				return "Segment %s reveals more bullets than it has" % segment.id
	return ""

func reset() -> void:
	segment_index = -1
	line_index = -1
	done = false

func segments() -> Array:
	return script_data.get("segments", [])

func current_segment() -> Dictionary:
	return segments()[segment_index] if segment_index >= 0 and segment_index < segments().size() else {}

func current_line() -> Dictionary:
	var segment := current_segment()
	return segment.lines[line_index] if not segment.is_empty() and line_index >= 0 else {}

## Bullets shown so far on the current slide. A line's "reveal" is the number
## of bullets visible from that line on; it never hides bullets already shown.
func revealed_bullets() -> int:
	var segment := current_segment()
	if segment.is_empty():
		return 0
	var shown := 0
	for index in range(line_index + 1):
		shown = maxi(shown, int(segment.lines[index].get("reveal", 0)))
	return shown

func start() -> void:
	reset()
	advance()

## Moves to the next line, entering the next segment when needed.
func advance() -> void:
	if done or script_data.is_empty():
		return
	var segment := current_segment()
	if segment.is_empty() or line_index + 1 >= segment.lines.size():
		segment_index += 1
		line_index = -1
		if segment_index >= segments().size():
			done = true
			finished.emit()
			return
		segment_started.emit(current_segment(), segment_index)
	line_index += 1
	line_started.emit(current_line())

func progress_label() -> String:
	return "%d / %d  ·  %s" % [segment_index + 1, segments().size(), current_segment().get("topic", "")]

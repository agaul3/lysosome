extends Node
## Persistent, deterministic event simulation; independent of loaded scene and player menus.
signal stage_changed(stage: Stage)
signal line_spoken(speaker: String, text: String)
const Route = preload("res://data/npc_route.gd")
enum Stage { IDLE, APPROACH, CONVERSATION, TO_BUILDING, LOBBY, TO_SEAT, SEATED }
var stage: Stage = Stage.IDLE
var zone := "campus"
var actor_position := Vector3(-5, 0, 3)
var facing := Vector3.FORWARD
var dialogue_speaker := ""
var dialogue_text := ""
var started := false
var seated_count := 0
var spoken_count := 0
var elapsed := 0.0
var line_index := 0
var path := PackedVector3Array()
var path_index := 0

func reset() -> void:
	stage = Stage.IDLE
	zone = "campus"
	actor_position = Route.GRAPHS.campus.points[0]
	facing = Vector3.FORWARD
	dialogue_speaker = ""
	dialogue_text = ""
	started = false
	seated_count = 0
	spoken_count = 0
	elapsed = 0
	line_index = 0
	path.clear()
	path_index = 0
	stage_changed.emit(stage)

## JSON-safe copy of the event state for the save file.
func snapshot() -> Dictionary:
	var points: Array = []
	for point in path:
		points.append([point.x, point.y, point.z])
	return {
		"stage": int(stage), "zone": zone, "position": [actor_position.x, actor_position.y, actor_position.z],
		"facing": [facing.x, facing.y, facing.z], "speaker": dialogue_speaker, "text": dialogue_text,
		"started": started, "seated_count": seated_count, "spoken_count": spoken_count,
		"elapsed": elapsed, "line_index": line_index, "path": points, "path_index": path_index,
	}

func restore(data: Dictionary) -> void:
	var vec := func(values: Array) -> Vector3: return Vector3(float(values[0]), float(values[1]), float(values[2]))
	stage = clampi(int(data.get("stage", 0)), 0, Stage.SEATED) as Stage
	zone = String(data.get("zone", "campus"))
	actor_position = vec.call(data.get("position", [0, 0, 0]))
	facing = vec.call(data.get("facing", [0, 0, -1]))
	dialogue_speaker = String(data.get("speaker", ""))
	dialogue_text = String(data.get("text", ""))
	started = bool(data.get("started", false))
	seated_count = int(data.get("seated_count", 0))
	spoken_count = int(data.get("spoken_count", 0))
	elapsed = float(data.get("elapsed", 0.0))
	line_index = int(data.get("line_index", 0))
	path = PackedVector3Array()
	for point in data.get("path", []):
		path.append(vec.call(point))
	path_index = clampi(int(data.get("path_index", 0)), 0, maxi(path.size() - 1, 0))
	if stage not in [Stage.IDLE, Stage.CONVERSATION, Stage.SEATED] and path.size() < 2:
		stage = Stage.IDLE # Damaged walk state: restart the event rather than stall.
	stage_changed.emit(stage)

func start() -> void:
	if not started:
		started = true
		elapsed = Route.START_DELAY

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not started or stage == Stage.SEATED or delta <= 0:
		return
	# Consume time across boundaries, preserving behavior even on a long frame.
	var remaining := delta
	while remaining > 0.00001 and stage != Stage.SEATED:
		if stage in [Stage.IDLE, Stage.CONVERSATION]:
			var consumed := minf(remaining, elapsed)
			elapsed -= consumed
			remaining -= consumed
			if elapsed <= 0.00001:
				if stage == Stage.IDLE:
					_begin_path("campus", 0, 2, Stage.APPROACH)
				else:
					line_index += 1
					if line_index < Route.LINES.size():
						_speak()
					else:
						dialogue_text = ""
						dialogue_speaker = ""
						_begin_path("campus", 2, 4, Stage.TO_BUILDING)
		else:
			var offset := path[path_index] - actor_position
			var distance := offset.length()
			if distance > 0.00001:
				facing = offset.normalized()
				var consumed := minf(remaining, distance / Route.SPEED)
				actor_position += facing * Route.SPEED * consumed
				remaining -= consumed
			if actor_position.distance_to(path[path_index]) < 0.0001:
				actor_position = path[path_index]
				path_index += 1
				if path_index == path.size():
					_arrived()

func _begin_path(next_zone: String, start_point: int, goal: int, next_stage: Stage) -> void:
	zone = next_zone
	path = Route.find_path(zone, start_point, goal)
	assert(path.size() >= 2, "NPC route must connect its endpoints")
	actor_position = path[0]
	path_index = 1
	stage = next_stage
	stage_changed.emit(stage)

func _arrived() -> void:
	match stage:
		Stage.APPROACH:
			stage = Stage.CONVERSATION
			facing = Vector3.FORWARD
			line_index = 0
			stage_changed.emit(stage)
			_speak()
		Stage.TO_BUILDING:
			_begin_path("lecture_building", 0, 2, Stage.LOBBY)
		Stage.LOBBY:
			_begin_path("lecture_hall", 0, Route.GRAPHS.lecture_hall.points.size() - 1, Stage.TO_SEAT)
		Stage.TO_SEAT:
			# Views animate the side-step and sit from the aisle-side approach point.
			stage = Stage.SEATED
			actor_position = Route.HALL_SEAT
			facing = Vector3.FORWARD
			seated_count += 1
			stage_changed.emit(stage)

func _speak() -> void:
	var line: Dictionary = Route.LINES[line_index]
	dialogue_speaker = line.speaker
	dialogue_text = line.text
	elapsed = Route.LINE_SECONDS
	spoken_count += 1
	line_spoken.emit(dialogue_speaker, dialogue_text)

extends Node
## Application flow and the selected preset only; no progression or save manager yet.
signal phase_changed(phase: Phase)
signal transition_failed(error: Error)
const Presets = preload("res://data/character_presets.gd")
const SCENES := {
	"title": "res://ui/start_screen.tscn",
	"dorm": "res://world/dorm/dorm.tscn",
	"campus": "res://world/campus/campus.tscn",
	"lecture_building": "res://world/lecture_building/lecture_building.tscn",
	"lecture_hall": "res://world/lecture_hall/lecture_hall.tscn",
}
enum Phase { TITLE, CHARACTER_SELECT, DORM, CAMPUS, LECTURE_BUILDING, LECTURE_HALL }
var phase: Phase = Phase.TITLE
var selected_character: String = Presets.DEFAULT_ID
var transitioning := false
var campus_entry := "dorm"

func start_new_game() -> void:
	NPCSchedule.reset()
	GameClock.reset()
	AcademicSession.reset()
	selected_character = Presets.DEFAULT_ID
	campus_entry = "dorm"
	_set_phase(Phase.CHARACTER_SELECT)

func select_character(id: String) -> bool:
	if not Presets.is_valid(id):
		return false
	selected_character = id
	return true

func enter_dorm() -> void:
	_request_transition("dorm", Phase.DORM)

func leave_dorm() -> void:
	if phase == Phase.DORM:
		enter_campus("dorm")

func enter_campus(entry: String = "dorm") -> void:
	if transitioning:
		return
	campus_entry = entry if entry in ["dorm", "lecture_building"] else "dorm"
	_request_transition("campus", Phase.CAMPUS)

func enter_lecture_building() -> void:
	if phase in [Phase.CAMPUS, Phase.LECTURE_HALL]:
		_request_transition("lecture_building", Phase.LECTURE_BUILDING)

func enter_lecture_hall() -> void:
	if phase == Phase.LECTURE_BUILDING:
		_request_transition("lecture_hall", Phase.LECTURE_HALL)

func return_to_title() -> void:
	if phase in [Phase.DORM, Phase.CAMPUS, Phase.LECTURE_BUILDING, Phase.LECTURE_HALL]:
		_request_transition("title", Phase.TITLE)
	else:
		_set_phase(Phase.TITLE)

func _request_transition(destination: String, next_phase: Phase) -> void:
	if transitioning:
		return
	transitioning = true
	# Defer scene replacement until input/physics signal delivery is complete.
	_commit_transition.call_deferred(destination, next_phase)

func _commit_transition(destination: String, next_phase: Phase) -> void:
	var previous_phase := phase
	phase = next_phase
	var error := get_tree().change_scene_to_file(SCENES[destination])
	if error != OK:
		phase = previous_phase
		transitioning = false
		transition_failed.emit(error)
		push_error("Could not change scene: %s" % error_string(error))
		return
	await get_tree().scene_changed
	transitioning = false
	GameClock.running = phase in [Phase.DORM, Phase.CAMPUS, Phase.LECTURE_BUILDING, Phase.LECTURE_HALL]
	phase_changed.emit(phase)
	if phase == Phase.LECTURE_HALL:
		AcademicSession.record_arrival("pharmacodynamics_01")

func _set_phase(next_phase: Phase) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	GameClock.running = phase in [Phase.DORM, Phase.CAMPUS, Phase.LECTURE_BUILDING, Phase.LECTURE_HALL]
	phase_changed.emit(phase)

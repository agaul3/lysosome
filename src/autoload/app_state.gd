extends Node
## Application flow and the selected preset only; no progression or save manager yet.
signal phase_changed(phase: Phase)
signal transition_failed(error: Error)
const Presets = preload("res://data/character_presets.gd")
const SCENES := {
	"title": "res://ui/start_screen.tscn",
	"dorm": "res://world/dorm/dorm.tscn",
	"exit": "res://world/dorm/exit_destination.tscn",
}
enum Phase { TITLE, CHARACTER_SELECT, DORM, EXIT }
var phase: Phase = Phase.TITLE
var selected_character: String = Presets.DEFAULT_ID
var transitioning := false

func start_new_game() -> void:
	selected_character = Presets.DEFAULT_ID
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
		_request_transition("exit", Phase.EXIT)

func return_to_title() -> void:
	if phase in [Phase.DORM, Phase.EXIT]:
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
	phase_changed.emit(phase)

func _set_phase(next_phase: Phase) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	phase_changed.emit(phase)

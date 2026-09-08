extends Node
## Only application flow belongs here. Gameplay managers arrive with their milestones.
signal phase_changed(phase: Phase)

enum Phase { TITLE, FOUNDATION }
var phase: Phase = Phase.TITLE

func start_new_game() -> void:
	_set_phase(Phase.FOUNDATION)

func return_to_title() -> void:
	_set_phase(Phase.TITLE)

func _set_phase(next_phase: Phase) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	phase_changed.emit(phase)

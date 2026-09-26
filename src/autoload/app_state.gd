extends Node
## Application flow: phases, scene transitions (with a fade), the selected
## preset, and resuming a saved game. Progress itself lives in AcademicSession.
signal phase_changed(phase: Phase)
signal transition_failed(error: Error)
## First-person view on or off (Settings, Cmd+F / Ctrl+F, or the controller's View button).
signal view_changed(first_person: bool)
## The student's appearance or outfit changed (creator, closet or inventory).
signal look_changed(look: Dictionary)
const Presets = preload("res://data/character_presets.gd")
const Looks = preload("res://data/looks.gd")
const Clothing = preload("res://data/clothing.gd")
const PHASE_BY_SCENE := {"dorm": 2, "campus": 3, "lecture_building": 4, "lecture_hall": 5, "hospital": 6, "med_ed": 7, "library": 8, "student_center": 9, "anatomy": 10, "community": 11}
const SCENES := {
	"title": "res://ui/start_screen.tscn",
	"dorm": "res://world/dorm/dorm.tscn",
	"campus": "res://world/campus/campus.tscn",
	"lecture_building": "res://world/lecture_building/lecture_building.tscn",
	"lecture_hall": "res://world/lecture_hall/lecture_hall.tscn",
	"hospital": "res://world/hospital/hospital.tscn",
	"med_ed": "res://world/med_ed/med_ed.tscn",
	"library": "res://world/library/library.tscn",
	"student_center": "res://world/student_center/student_center.tscn",
	"anatomy": "res://world/anatomy/anatomy.tscn",
	"community": "res://world/community/community.tscn",
}
enum Phase { TITLE, CHARACTER_SELECT, DORM, CAMPUS, LECTURE_BUILDING, LECTURE_HALL, HOSPITAL, MED_ED, LIBRARY, STUDENT_CENTER, ANATOMY, COMMUNITY }
## Where the campus can be entered from (data/campus_config.gd SPAWNS).
const CAMPUS_ENTRIES := ["dorm", "lecture_building", "hospital", "ed", "med_ed", "library", "student_center", "anatomy", "shuttle_quad", "shuttle_hospital", "shuttle_east", "community"]
const WORLD_PHASES := [Phase.DORM, Phase.CAMPUS, Phase.LECTURE_BUILDING, Phase.LECTURE_HALL, Phase.HOSPITAL, Phase.MED_ED, Phase.LIBRARY, Phase.STUDENT_CENTER, Phase.ANATOMY, Phase.COMMUNITY]
var phase: Phase = Phase.TITLE
## Preset the look started from, or "custom" once built in the creator.
var selected_character: String = Presets.DEFAULT_ID
## The student's complete look (data/looks.gd) and the name they go by.
var player_look: Dictionary = Presets.look_of(Presets.DEFAULT_ID)
var player_name: String = Presets.get_preset(Presets.DEFAULT_ID).name
## True once the player has typed a name; until then it follows the preset.
var name_customized := false
var transitioning := false
var campus_entry := "dorm"
## Where the student arrives in the hospital: "main" (the atrium) or "ed"
## (the Emergency Department's walk-in entrance). The hospital keeps it
## current while you move around, so a save resumes in the right part.
var hospital_entry := "main"
## The lecture hall being entered: "hall_a" (Learning Center) or "hall_b"
## (Medical Education Center).
var current_hall := "hall_a"
## Where the student appears in the Medical Education Center: "main" (the
## entrance), "hall_b" (coming out of Lecture Hall B) or "level2".
var med_ed_entry := "main"
## Where the student appears in the Biomedical Library, the Student Center,
## Anatomy Hall or the Community Center: "main" (the entrance) or a zone the
## building names ("level2"…), kept current so a save resumes on that floor.
var interior_entry := "main"
## View preference for this session (like volume and fullscreen, not saved).
var first_person := false
## Mouse / right-stick look speed multiplier for the first-person view.
var look_sensitivity := 1.0

func start_new_game() -> void:
	Flashcards.reset()
	NPCSchedule.reset()
	GameClock.reset()
	AcademicSession.reset()
	Skills.reset()
	Wellbeing.reset()
	Wallet.reset()
	Achievements.reset()
	YearCalendar.reset()
	Clubs.reset()
	player_name = ""
	name_customized = false
	select_character(Presets.DEFAULT_ID)
	campus_entry = "dorm"
	hospital_entry = "main"
	current_hall = "hall_a"
	med_ed_entry = "main"
	interior_entry = "main"
	_set_phase(Phase.CHARACTER_SELECT)

func set_first_person(enabled: bool) -> void:
	if first_person == enabled:
		return
	first_person = enabled
	view_changed.emit(enabled)

func _unhandled_input(event: InputEvent) -> void:
	# Cmd+F (Ctrl+F off macOS) switches between the third- and first-person views.
	if event.is_action_pressed("toggle_view") and not event.is_echo() and in_world() and not transitioning:
		set_first_person(not first_person)
		get_viewport().set_input_as_handled()

func in_world() -> bool:
	return phase in WORLD_PHASES

## Scene key of the current world location (used by the save file).
func location_key() -> String:
	for key in PHASE_BY_SCENE:
		if PHASE_BY_SCENE[key] == phase:
			return key
	return "dorm"

## Loads the save slot and travels to where it was made. False if unreadable.
func continue_game() -> bool:
	if transitioning:
		return false
	var data := SaveGame.read()
	if not SaveGame.apply(data):
		return false
	var scene: String = data.location.scene
	_request_transition(scene, PHASE_BY_SCENE[scene] as Phase)
	return true

## Chooses a preset look. The name follows the preset unless the player typed their own.
func select_character(id: String) -> bool:
	if not Presets.is_valid(id):
		return false
	selected_character = id
	player_look = Presets.look_of(id)
	if not name_customized:
		player_name = _preset_name(id)
	look_changed.emit(player_look)
	return true

## A look built in the creator.
func set_custom_look(look: Dictionary) -> void:
	selected_character = "custom"
	player_look = Looks.sanitize(look)
	player_look.preset = "custom"
	look_changed.emit(player_look)

## Changes the current look (hair, clothes…) without changing where it started.
func set_look(look: Dictionary) -> void:
	var preset: String = player_look.get("preset", selected_character)
	player_look = Looks.sanitize(look)
	player_look.preset = preset
	look_changed.emit(player_look)

## Puts on an unlocked item (or clears an optional slot with ""). False if not allowed.
func equip(slot: String, item_id: String) -> bool:
	if not Clothing.SLOTS.has(slot):
		return false
	if item_id == "":
		if Clothing.REQUIRED.has(slot):
			return false
	elif Clothing.slot_of(item_id) != slot or not Clothing.unlocked(item_id):
		return false
	var look := player_look.duplicate(true)
	look.outfit[slot] = item_id
	set_look(look)
	return true

## `typed` marks a name the player entered themselves (it then stops following the preset).
func set_player_name(value: String, typed := false) -> void:
	player_name = value.strip_edges().left(20)
	if typed:
		name_customized = not player_name.is_empty()

func display_name() -> String:
	return player_name if not player_name.strip_edges().is_empty() else _preset_name(selected_character)

func _preset_name(id: String) -> String:
	return Presets.get_preset(id).name if Presets.is_valid(id) else "Student"

func enter_dorm() -> void:
	_request_transition("dorm", Phase.DORM)

func leave_dorm() -> void:
	if phase == Phase.DORM:
		enter_campus("dorm")

func enter_campus(entry: String = "dorm") -> void:
	if transitioning:
		return
	campus_entry = entry if CAMPUS_ENTRIES.has(entry) else "dorm"
	_request_transition("campus", Phase.CAMPUS)

func enter_lecture_building() -> void:
	if phase in [Phase.CAMPUS, Phase.LECTURE_HALL]:
		_request_transition("lecture_building", Phase.LECTURE_BUILDING)

func enter_lecture_hall() -> void:
	if phase == Phase.LECTURE_BUILDING:
		current_hall = "hall_a"
		_request_transition("lecture_hall", Phase.LECTURE_HALL)

## The Medical Education Center (north of the Learning Center).
func enter_med_ed(entry := "main") -> void:
	if phase in [Phase.CAMPUS, Phase.LECTURE_HALL] and not transitioning:
		med_ed_entry = entry if entry in ["main", "hall_b", "level2"] else "main"
		_request_transition("med_ed", Phase.MED_ED)

## The Biomedical Library, the Student Center and Anatomy Hall, from campus.
func enter_library(entry := "main") -> void:
	_enter_building("library", Phase.LIBRARY, entry)

func enter_student_center(entry := "main") -> void:
	_enter_building("student_center", Phase.STUDENT_CENTER, entry)

func enter_anatomy(entry := "main") -> void:
	_enter_building("anatomy", Phase.ANATOMY, entry)

## The Harbor Street Community Center, off campus by the campus shuttle.
func enter_community(entry := "main") -> void:
	_enter_building("community", Phase.COMMUNITY, entry)

func _enter_building(scene: String, next_phase: Phase, entry: String) -> void:
	if phase == Phase.CAMPUS and not transitioning:
		interior_entry = entry
		_request_transition(scene, next_phase)

## Lecture Hall B, from the Medical Education Center's atrium.
func enter_lecture_hall_b() -> void:
	if phase == Phase.MED_ED and not transitioning:
		current_hall = "hall_b"
		_request_transition("lecture_hall", Phase.LECTURE_HALL)

## Out of a lecture hall, back to the building it belongs to.
func leave_lecture_hall() -> void:
	if current_hall == "hall_b":
		enter_med_ed("hall_b")
	else:
		enter_lecture_building()

## University Hospital, across the street from the campus: its main
## entrance, or the Emergency Department's walk-in entrance ("ed").
func enter_hospital(entry := "main") -> void:
	if phase == Phase.CAMPUS and not transitioning:
		hospital_entry = entry if entry in ["main", "ed"] else "main"
		_request_transition("hospital", Phase.HOSPITAL)

func return_to_title() -> void:
	if phase in WORLD_PHASES:
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
	await Transition.cover()
	var previous_phase := phase
	phase = next_phase
	var error := get_tree().change_scene_to_file(SCENES[destination])
	if error != OK:
		phase = previous_phase
		transitioning = false
		Transition.reveal()
		transition_failed.emit(error)
		push_error("Could not change scene: %s" % error_string(error))
		return
	await get_tree().scene_changed
	transitioning = false
	GameClock.running = in_world()
	Transition.reveal()
	phase_changed.emit(phase)
	if in_world():
		Achievements.visit(destination)
	if phase == Phase.LECTURE_HALL:
		var lecture: Dictionary = preload("res://education/lectures/lecture_catalog.gd").lecture_on(current_hall, YearCalendar.today_date())
		if not lecture.is_empty():
			AcademicSession.record_arrival(String(lecture.id))
	SaveGame.autosave()

func _set_phase(next_phase: Phase) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	GameClock.running = phase in WORLD_PHASES
	phase_changed.emit(phase)

extends Node
## One local save slot (spec §35): versioned JSON in user://.
##
## Persists the student's look (appearance and outfit) and name, the preset
## it started from, level/XP, question history, attempt and
## correct counts, topic statistics, streaks, game date and time, current
## location, lecture completion and notes progress, attendance (lateness) and
## the autonomous NPC event, so a reload resumes exactly where the student was.
##
## The first-year systems live in an optional "life" section: money, energy
## and boosts, skills, achievements and stats, the calendar (finished days,
## absences, make-up exams, the last stipend) and club memberships. Saves from before it
## load with those systems at their starting values.
##
## Writes are atomic (temp file, verified, then renamed over the old save) and
## loads are all-or-nothing: the file is fully parsed and validated before any
## game state is touched, so a damaged file can never half-apply.
signal saved(summary: Dictionary)
const VERSION := 1
const LOCATIONS := ["dorm", "campus", "lecture_building", "lecture_hall", "hospital", "med_ed", "library", "student_center", "anatomy", "community"]
var path := "user://savegame.json"
var last_error := ""
## Autosaves are skipped while this is false (e.g. before a game has begun).
var enabled := true

func _ready() -> void:
	# Test scripts run as the main loop; keep their saves away from the player's.
	if Engine.get_main_loop().get_script() != null:
		path = "user://savegame_test.json"
		delete_save() # Each test run starts without a save.

func has_save() -> bool:
	return FileAccess.file_exists(path)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## Current game state as plain JSON-safe data.
func snapshot() -> Dictionary:
	return {
		"version": VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"selected_character": AppState.selected_character,
		"look": AppState.player_look,
		"name": AppState.player_name,
		"location": {"scene": AppState.location_key(), "campus_entry": AppState.campus_entry, "hospital_entry": AppState.hospital_entry, "hall": AppState.current_hall, "med_ed_entry": AppState.med_ed_entry, "interior_entry": AppState.interior_entry},
		"clock": {"elapsed_seconds": GameClock.elapsed_seconds},
		"academic": {
			"xp_balance": AcademicSession.xp_balance,
			"level": AcademicSession.level,
			"streak": AcademicSession.streak,
			"best_streak": AcademicSession.best_streak,
			"attempted": AcademicSession.attempted,
			"correct": AcademicSession.correct,
			"question_history": AcademicSession.question_history,
			"topic_statistics": AcademicSession.topic_statistics,
			"attendance": AcademicSession.attendance,
			"lectures_completed": AcademicSession.lectures_completed,
			"notes_progress": AcademicSession.notes_progress,
		},
		"npc": NPCSchedule.snapshot(),
		"flashcards": Flashcards.snapshot(),
		"life": {
			"wallet": Wallet.snapshot(),
			"wellbeing": Wellbeing.snapshot(),
			"skills": Skills.snapshot(),
			"achievements": Achievements.snapshot(),
			"calendar": YearCalendar.snapshot(),
			"clubs": Clubs.snapshot(),
		},
	}

## Writes the current game. Returns false (with last_error) on failure.
func save() -> bool:
	if not AppState.in_world():
		last_error = "Nothing to save outside the game world."
		return false
	var data := snapshot()
	var text := JSON.stringify(data, "\t", false, true)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write save: %s" % error_string(FileAccess.get_open_error())
		return false
	file.store_string(text)
	file.close()
	# Verify what reached the disk before replacing the previous save.
	if validate(JSON.parse_string(FileAccess.get_file_as_string(temp))) != "":
		last_error = "Save verification failed."
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute)
	if error != OK:
		last_error = "Could not finalise save: %s" % error_string(error)
		return false
	last_error = ""
	saved.emit(summary(data))
	return true

## Autosave hook used at safe points (arriving somewhere, finishing class).
func autosave() -> void:
	if enabled and AppState.in_world():
		save()

## Reads and validates the save without applying it. Empty on failure.
func read() -> Dictionary:
	if not has_save():
		last_error = "No save found."
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var error := validate(parsed)
	if error != "":
		last_error = error
		return {}
	return _integers(parsed)

## A one-line description for the title screen's Continue button.
func summary(data: Dictionary = {}) -> Dictionary:
	if data.is_empty():
		data = read()
	if data.is_empty():
		return {}
	var names := {"dorm": "Cedar Residence", "campus": "Student Commons", "lecture_building": "Learning Center", "lecture_hall": "Lecture Hall A" if String(data.location.get("hall", "hall_a")) == "hall_a" else "Lecture Hall B", "hospital": "University Hospital", "med_ed": "Medical Education Center", "library": "Biomedical Library", "student_center": "Student Center", "anatomy": "Anatomy Hall", "community": "Harbor Street Community Center"}
	var start := Time.get_unix_time_from_datetime_string(GameClock.config.start_datetime)
	var moment := Time.get_datetime_dict_from_unix_time(int(start + float(data.clock.elapsed_seconds)))
	var hour: int = int(moment.hour) % 12
	return {
		"level": int(data.academic.level),
		"location": names.get(data.location.scene, "Campus"),
		"time": "%d:%02d %s" % [12 if hour == 0 else hour, moment.minute, "AM" if moment.hour < 12 else "PM"],
		"date": GameClock.format_date(moment.year, moment.month, moment.day),
		"character": String(data.selected_character),
		"name": String(data.get("name", "")) if not String(data.get("name", "")).is_empty() else preload("res://data/character_presets.gd").get_preset(String(data.selected_character)).name,
	}

## Applies a validated save to every system. Returns false if unreadable.
func apply(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	AppState.selected_character = data.selected_character
	var Presets := preload("res://data/character_presets.gd")
	AppState.player_look = preload("res://data/looks.gd").sanitize(data.look) if data.has("look") else Presets.look_of(String(data.selected_character))
	if not data.has("look"):
		AppState.player_look.preset = String(data.selected_character)
	AppState.player_name = String(data.get("name", Presets.get_preset(String(data.selected_character)).name))
	AppState.name_customized = true
	AppState.look_changed.emit(AppState.player_look)
	AppState.campus_entry = data.location.campus_entry
	AppState.hospital_entry = String(data.location.get("hospital_entry", "main"))
	AppState.current_hall = String(data.location.get("hall", "hall_a"))
	AppState.med_ed_entry = String(data.location.get("med_ed_entry", "main"))
	AppState.interior_entry = String(data.location.get("interior_entry", "main"))
	GameClock.elapsed_seconds = float(data.clock.elapsed_seconds)
	var academic: Dictionary = data.academic
	AcademicSession.reset()
	AcademicSession.xp_balance = int(academic.xp_balance)
	AcademicSession.level = int(academic.level)
	AcademicSession.streak = int(academic.streak)
	AcademicSession.best_streak = int(academic.best_streak)
	AcademicSession.attempted = int(academic.attempted)
	AcademicSession.correct = int(academic.correct)
	AcademicSession.question_history = academic.question_history
	AcademicSession.topic_statistics = academic.topic_statistics
	AcademicSession.attendance = academic.attendance
	AcademicSession.lectures_completed = academic.lectures_completed
	AcademicSession.notes_progress = academic.notes_progress
	Flashcards.restore(data.get("flashcards", {}))
	NPCSchedule.restore(data.npc)
	var life: Dictionary = data.get("life", {})
	Skills.restore(life.get("skills", {}))
	Wallet.restore(life.get("wallet", {}))
	Wellbeing.restore_state(life.get("wellbeing", {}))
	Achievements.restore(life.get("achievements", {}))
	if life.has("calendar"):
		YearCalendar.restore(life.calendar)
	else:
		YearCalendar.reset()
	Clubs.restore(life.get("clubs", {}))
	GameClock.minute_changed.emit()
	return true

## Structural validation; returns "" when the data is usable.
static func validate(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "Save file is not readable."
	if int(data.get("version", -1)) != VERSION:
		return "Save file version is not supported."
	for key in ["selected_character", "location", "clock", "academic", "npc"]:
		if not data.has(key):
			return "Save file is missing '%s'." % key
	if data.has("flashcards"):
		var flashcard_error := preload("res://education/flashcards/collection.gd").validate(data.flashcards)
		if not flashcard_error.is_empty():
			return flashcard_error
	var character := String(data.selected_character)
	if not preload("res://data/character_presets.gd").is_valid(character) and not (character == "custom" and data.has("look")):
		return "Save file has an unknown character."
	if data.has("look") and not preload("res://data/looks.gd").is_valid(data.look):
		return "Save file has an invalid appearance."
	if data.has("name") and typeof(data.name) != TYPE_STRING:
		return "Save file has an invalid name."
	if typeof(data.location) != TYPE_DICTIONARY or not LOCATIONS.has(data.location.get("scene", "")):
		return "Save file has an unknown location."
	if typeof(data.clock) != TYPE_DICTIONARY or typeof(data.clock.get("elapsed_seconds")) not in [TYPE_FLOAT, TYPE_INT] or float(data.clock.elapsed_seconds) < 0.0:
		return "Save file has an invalid time."
	var academic: Variant = data.academic
	if typeof(academic) != TYPE_DICTIONARY:
		return "Save file has invalid progress."
	for key in ["xp_balance", "level", "streak", "best_streak", "attempted", "correct"]:
		if typeof(academic.get(key)) not in [TYPE_FLOAT, TYPE_INT]:
			return "Save file progress is missing '%s'." % key
	for key in ["question_history", "topic_statistics", "attendance", "lectures_completed", "notes_progress"]:
		if typeof(academic.get(key)) != TYPE_DICTIONARY:
			return "Save file progress is missing '%s'." % key
	if int(academic.attempted) < int(academic.correct) or int(academic.level) < 1:
		return "Save file progress is inconsistent."
	if typeof(data.npc) != TYPE_DICTIONARY or not data.npc.has("stage"):
		return "Save file has an invalid NPC state."
	if data.has("life"):
		var life: Variant = data.life
		if typeof(life) != TYPE_DICTIONARY:
			return "Save file has invalid first-year data."
		var checks := [
			["wallet", Wallet.validate],
			["wellbeing", Wellbeing.validate],
			["skills", Skills.validate],
			["achievements", Achievements.validate],
			["calendar", YearCalendar.validate_save],
			["clubs", Clubs.validate],
		]
		for entry in checks:
			if life.has(entry[0]):
				var error: String = entry[1].call(life[entry[0]])
				if not error.is_empty():
					return error
	return ""

## JSON numbers load as floats; restore whole numbers to ints recursively so
## counts and XP compare and format exactly as they did before saving.
static func _integers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var result := {}
			for key in value:
				result[key] = _integers(value[key]) if key != "elapsed_seconds" else value[key]
			return result
		TYPE_ARRAY:
			return value.map(func(item): return _integers(item))
		TYPE_FLOAT:
			# Exact test: approximate comparison would round large timestamps like 1789977733.5.
			return int(value) if value == floorf(value) and absf(value) < 1e15 else value
	return value

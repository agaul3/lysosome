extends RefCounted
## The player's current objective, derived from where they are and what they
## have done, so a first-time player always knows the next step. Shown in the
## HUD and on the menu's Overview page. Lecture scenes may override it.
const LECTURE_ID := "pharmacodynamics_01"

## Location heading for each world phase ("eyebrow" text in the HUD).
const LOCATIONS := {
	"dorm": "Cedar Residence · Your Room",
	"campus": "Student Commons",
	"lecture_building": "Learning Center · Ground Floor",
	"lecture_hall": "Learning Center · Lecture Hall A",
}

static func location(scene: String) -> String:
	return LOCATIONS.get(scene, "Campus")

static func current(scene: String) -> String:
	if AcademicSession.lectures_completed.has(LECTURE_ID):
		return "Class complete · Review your results in the menu (Tab)"
	var event: Dictionary = {}
	for candidate in GameClock.config.events:
		if candidate.id == LECTURE_ID:
			event = candidate
	var start := Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [event.date, int(event.hour), int(event.minute)])
	var minutes := int(ceil((start - GameClock.now_seconds()) / 60.0))
	var when := ("starts in %d min" % minutes) if minutes > 0 else "has started"
	match scene:
		"dorm":
			return "Pharmacodynamics %s · Leave by the door" % when
		"campus":
			return "Cross the quad to the Learning Center (north)"
		"lecture_building":
			return "Lecture Hall A is straight ahead"
		"lecture_hall":
			return "Find an open seat for Pharmacodynamics"
	return ""

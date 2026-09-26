extends RefCounted
## The player's current objective, derived from where they are and what they
## have done, so a first-time player always knows the next step. Shown in the
## HUD and on the menu's Overview page. Lecture and hospital scenes may
## override it while they run their own sequence.
const LECTURE_ID := "pharmacodynamics_01"
const SHADOWING_ID := "hospital_orientation_01"

## Location heading for each world phase ("eyebrow" text in the HUD).
const LOCATIONS := {
	"dorm": "Cedar Residence · Your Room",
	"campus": "Student Commons",
	"lecture_building": "Learning Center · Ground Floor",
	"lecture_hall": "Learning Center · Lecture Hall A",
	"hospital": "University Hospital · Level 1 Lobby",
	"med_ed": "Medical Education Center · Level 1",
	"library": "Biomedical Library",
	"student_center": "Student Center",
	"anatomy": "Anatomy Hall",
	"community": "Harbor Street Community Center",
}

static func location(scene: String) -> String:
	return LOCATIONS.get(scene, "Campus")

## "starts in N min" / "has started" for a schedule event.
static func _when(event_id: String) -> String:
	var event: Dictionary = {}
	for candidate in GameClock.config.events:
		if candidate.id == event_id:
			event = candidate
	if event.is_empty():
		return ""
	var start := Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [event.date, int(event.hour), int(event.minute)])
	var minutes := int(ceil((start - GameClock.now_seconds()) / 60.0))
	return ("starts in %d min" % minutes) if minutes > 0 else "has started"

static func current(scene: String) -> String:
	# Day 1 keeps its hand-written guidance; later story days read the schedule.
	if YearCalendar.day_number() > 1 or (YearCalendar.day_number() == 0 and YearCalendar.completed_days.size() > 0):
		return _year_objective(scene)
	if AcademicSession.lectures_completed.has(LECTURE_ID):
		return _after_class(scene)
	var when := _when(LECTURE_ID)
	match scene:
		"dorm":
			return "Pharmacodynamics %s · Leave by the door" % when
		"campus":
			return "Cross the quad to the Learning Center (north)"
		"lecture_building":
			return "Lecture Hall A is straight ahead"
		"lecture_hall":
			return "Find an open seat for Pharmacodynamics"
		"hospital":
			return "Pharmacodynamics first (Learning Center, 8:00)"
	return ""

## After the lecture: physician shadowing at University Hospital, then the day is done.
static func _after_class(scene: String) -> String:
	if AcademicSession.lectures_completed.has(SHADOWING_ID):
		return "Day complete · Free time: explore, study, eat · Sleep from 6 PM"
	var when := _when(SHADOWING_ID)
	match scene:
		"dorm":
			return "Physician shadowing %s · Head to University Hospital" % when
		"campus":
			return "Shadowing %s · Cross the street to University Hospital (south-east)" % when
		"lecture_building", "lecture_hall":
			return "Class complete · Shadowing at University Hospital, across the street"
		"hospital":
			return "Meet Dr. Okafor at the Information desk"
	return ""

## Any story day after the first: the next event and where it is, or free time.
static func _year_objective(scene: String) -> String:
	var next: Dictionary = YearCalendar.next_event()
	var hour := int(GameClock.snapshot().hour)
	if next.is_empty():
		if hour >= YearCalendar.BEDTIME_HOUR:
			return "Day's work done · Head home to sleep (Cedar Residence)" if scene != "dorm" else "Day's work done · Your bed is ready when you are"
		if YearCalendar.year_over():
			return "Summer break · The clubs, the gym and the library are open · Sleep from 6 PM"
		return "Free time · Study, eat, explore or see your clubs · Sleep from 6 PM"
	var start := YearCalendar.start_of(next)
	var minutes := int(ceil((start - GameClock.now_seconds()) / 60.0))
	var when := ("in %d min" % minutes) if minutes > 0 and minutes < 120 else ("at " + _clock(int(next.hour), int(next.minute)) if minutes > 0 else "now")
	var title := String(next.title).capitalize()
	return "%s %s · %s" % [title, when, String(next.location)]

static func _clock(hour: int, minute: int) -> String:
	return "%d:%02d %s" % [12 if hour % 12 == 0 else hour % 12, minute, "AM" if hour < 12 else "PM"]

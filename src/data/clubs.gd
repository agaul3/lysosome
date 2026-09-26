extends RefCounted
## The student organizations. Join at the Club Fair (on the quad, the first
## Wednesday afternoon) or at the Office of Student Life in the Student
## Center; up to MAX_MEMBERSHIPS at a time.
##
## A club meets on set weekdays; while a meeting is on (from 20 minutes
## before it starts until it ends) members can take part at its place, which
## runs the club's activity (ui/clubs/). How well it goes earns reputation:
## levels 1–5 (LEVELS). Level 2 brings the club's shirt, level 3 a skill point,
## level 5 the Club Officer achievement. Every meeting counts toward the
## Helping Hands and Balance achievements.
##
## The activities are original. Their clinical and social facts are flagged
## for review in docs/development/MEDICAL_CONTENT_REVIEW.md.
const MAX_MEMBERSHIPS := 3
## Reputation needed for levels 1 to 5.
const LEVELS := [0, 40, 100, 180, 280]
const LEVEL_NAMES := ["Member", "Regular", "Core Member", "Coordinator", "Officer"]
## Minutes before a meeting's start when members can already join in.
const EARLY := 20
## id: name, short name, category, colour, icon, the pitch, when it meets
## ([weekday (0 Sunday), hour, minute]), how long (minutes), where (a scene
## key and a room in it, and the words for it), the activity and the shirt.
const CLUBS := {
	"community_kitchen": {
		"name": "Community Kitchen Volunteers", "short": "Community Kitchen", "category": "Service",
		"color": Color("c2452d"), "icon": "bowl",
		"pitch": "Cook and serve supper at the Harbor Street Community Center, where anyone who is hungry eats free, no questions asked. Learn the neighborhood you'll care for.",
		"meets": [[1, 17, 30], [3, 17, 30]], "minutes": 120,
		"place": "community", "room": "kitchen", "where": "Harbor Street Community Center · Kitchen (take the campus shuttle)",
		"activity": "kitchen", "shirt": "kitchen_tee",
	},
	"free_clinic": {
		"name": "Student-Run Free Clinic", "short": "Free Clinic", "category": "Clinical service",
		"color": Color("2f8f82"), "icon": "person",
		"pitch": "First-years take vitals and run screening questions for uninsured patients, supervised by volunteer physicians. Real patients, from your first month.",
		"meets": [[4, 17, 30], [6, 9, 0]], "minutes": 180,
		"place": "community", "room": "clinic", "where": "Harbor Street Community Center · Free Clinic (take the campus shuttle)",
		"activity": "free_clinic", "shirt": "clinic_tee",
	},
	"surgery": {
		"name": "Surgery Interest Group", "short": "Surgery Interest Group", "category": "Specialty interest",
		"color": Color("3d86c6"), "icon": "target",
		"pitch": "Monday-night suturing workshops on skin pads with the surgery residents: simple interrupted sutures, instrument ties, even spacing.",
		"meets": [[1, 18, 0]], "minutes": 90,
		"place": "med_ed", "room": "skills_lab", "where": "Medical Education Center · Level 2 · Skills Lab",
		"activity": "suturing", "shirt": "surgery_tee",
	},
	"emig": {
		"name": "Emergency Medicine Interest Group", "short": "EM Interest Group", "category": "Specialty interest",
		"color": Color("26282b"), "icon": "flame",
		"pitch": "Skills nights in the Simulation Suite: hands-only CPR on the feedback manikin, the AED, and Stop the Bleed.",
		"meets": [[3, 18, 0]], "minutes": 90,
		"place": "med_ed", "room": "sim", "where": "Medical Education Center · Level 2 · Simulation Suite",
		"activity": "cpr", "shirt": "emig_tee",
	},
	"spanish": {
		"name": "Medical Spanish", "short": "Medical Spanish", "category": "Language",
		"color": Color("e8b923"), "icon": "users",
		"pitch": "Practice the history in Spanish: greetings, symptoms, pain, medications and instructions, with native-speaker classmates.",
		"meets": [[2, 17, 30], [4, 17, 30]], "minutes": 60,
		"place": "student_center", "room": "club_a", "where": "Student Center · Level 2 · Club Room A",
		"activity": "spanish", "shirt": "spanish_tee",
	},
	"journal": {
		"name": "Journal Club", "short": "Journal Club", "category": "Research",
		"color": Color("4f5b66"), "icon": "journal",
		"pitch": "Friday lunch and one paper: study design, bias, and what the numbers really mean for a patient. Pizza provided.",
		"meets": [[5, 12, 15]], "minutes": 60,
		"place": "student_center", "room": "club_b", "where": "Student Center · Level 2 · Club Room B",
		"activity": "journal", "shirt": "journal_tee",
	},
	"intramurals": {
		"name": "Intramural Sports", "short": "Intramurals", "category": "Wellbeing",
		"color": Color("2f7a4a"), "icon": "bolt",
		"pitch": "Pick-up soccer on the quad lawn. No experience needed; the M2s are beatable. Good for energy, better for sanity.",
		"meets": [[3, 16, 30], [6, 10, 0]], "minutes": 60,
		"place": "campus", "room": "quad", "where": "The quad lawn",
		"activity": "intramurals", "shirt": "intramural_jersey",
	},
}

static func get_club(id: String) -> Dictionary:
	return CLUBS.get(id, {})

## Reputation level (1–5) for `points`.
static func level_for(points: int) -> int:
	var level := 1
	for index in range(LEVELS.size()):
		if points >= int(LEVELS[index]):
			level = index + 1
	return level

## "Mondays and Wednesdays, 5:30 PM"
static func schedule_text(id: String) -> String:
	var club := get_club(id)
	if club.is_empty():
		return ""
	var days := ["Sundays", "Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays"]
	var parts: Array = []
	for meeting in club.meets:
		var hour := int(meeting[1])
		parts.append("%s %d:%02d %s" % [days[int(meeting[0])], 12 if hour % 12 == 0 else hour % 12, int(meeting[2]), "AM" if hour < 12 else "PM"])
	return " · ".join(parts)

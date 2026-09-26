extends RefCounted
## The skill tree: four branches of perks bought with skill points (one for
## every level gained, plus a few from achievements). Each rank adds its
## `effects` to the totals Skills.effect() reports.
##
## Perks change how the year feels (more XP from the things you do well,
## longer boosts, cheaper coffee, more time on exams); none of them does the
## learning for you: no answers are revealed and nothing passes for you.
##
## Effect keys:
##   xp:<context>        + fraction of XP earned in that context: lecture,
##                       flashcard, exam, clinical, immersion, club, tutoring,
##                       lab (labs and practicals)
##   money:income        + fraction on every paycheck and award
##   money:tutoring      + fraction on tutoring pay
##   money:awards        + fraction on merit awards
##   money:discount      fraction off food, drink and store prices
##   energy:max          extra maximum energy
##   energy:restore      + fraction on energy restored by food, rest and sleep
##   energy:wake         extra energy on waking
##   boost:duration      + fraction on how long food and drink boosts last
##   boost:exercise      workouts also grant an XP boost
##   exam:time           + fraction of exam time
##   lecture:second_look re-answer one missed lecture question per lecture (half XP)
##   flashcard:cap       extra daily flashcard XP cap
##   clinical:hints      key history questions highlighted per encounter
##   clinical:second_opinion  one diagnosis re-choice per encounter (half credit)
##   skills:window       wider timing windows in hands-on skills (suturing, CPR)
##   club:reputation     + fraction of club reputation earned

const BRANCHES := [
	{"id": "scholar", "name": "Scholar", "color": Color("8fb5e8"), "icon": "book", "tagline": "Lectures, flashcards and exams"},
	{"id": "clinician", "name": "Clinician", "color": Color("5ec8b5"), "icon": "person", "tagline": "Patients, skills and the wards"},
	{"id": "wellbeing", "name": "Wellbeing", "color": Color("7fd6a0"), "icon": "spark", "tagline": "Energy, food and rest"},
	{"id": "leadership", "name": "Leadership", "color": Color("f2c46d"), "icon": "achievements", "tagline": "Clubs, community and money"},
]

## id: branch, name, ranks, per-rank effects, requirements ({perk: rank}),
## minimum level, and a description of one rank.
const PERKS := {
	# Scholar.
	"front_row": {"branch": "scholar", "name": "Front Row", "ranks": 3, "effects": {"xp:lecture": 0.05}, "requires": {}, "level": 1,
		"description": "+5% XP from lecture questions per rank."},
	"active_recall": {"branch": "scholar", "name": "Active Recall", "ranks": 3, "effects": {"xp:flashcard": 0.05}, "requires": {}, "level": 1,
		"description": "+5% XP from flashcard reviews per rank."},
	"test_strategy": {"branch": "scholar", "name": "Test-Taking Strategy", "ranks": 2, "effects": {"exam:time": 0.10, "xp:exam": 0.05}, "requires": {"front_row": 1}, "level": 3,
		"description": "+10% exam time and +5% exam XP per rank."},
	"second_look": {"branch": "scholar", "name": "Second Look", "ranks": 1, "effects": {"lecture:second_look": 1}, "requires": {"front_row": 2}, "level": 5,
		"description": "Once per lecture, re-answer a question you missed for half its XP."},
	"spaced_mastery": {"branch": "scholar", "name": "Spaced Mastery", "ranks": 1, "effects": {"flashcard:cap": 50}, "requires": {"active_recall": 2}, "level": 5,
		"description": "Your daily flashcard XP cap rises by 50."},
	# Clinician.
	"bedside_manner": {"branch": "clinician", "name": "Bedside Manner", "ranks": 3, "effects": {"xp:clinical": 0.05}, "requires": {}, "level": 1,
		"description": "+5% XP from patient encounters per rank."},
	"steady_hands": {"branch": "clinician", "name": "Steady Hands", "ranks": 2, "effects": {"skills:window": 0.15}, "requires": {}, "level": 1,
		"description": "Timing windows in hands-on skills (suturing, CPR) are 15% wider per rank."},
	"clinical_eye": {"branch": "clinician", "name": "Clinical Eye", "ranks": 2, "effects": {"clinical:hints": 1}, "requires": {"bedside_manner": 1}, "level": 3,
		"description": "One key history question is highlighted in each encounter, per rank."},
	"team_player": {"branch": "clinician", "name": "Team Player", "ranks": 2, "effects": {"xp:immersion": 0.10}, "requires": {"bedside_manner": 1}, "level": 3,
		"description": "+10% XP from Clinical Immersion shifts per rank."},
	"second_opinion": {"branch": "clinician", "name": "Second Opinion", "ranks": 1, "effects": {"clinical:second_opinion": 1}, "requires": {"bedside_manner": 2}, "level": 6,
		"description": "Once per encounter, reconsider a wrong diagnosis for half credit."},
	# Wellbeing.
	"iron_constitution": {"branch": "wellbeing", "name": "Iron Constitution", "ranks": 3, "effects": {"energy:max": 10}, "requires": {}, "level": 1,
		"description": "+10 maximum energy per rank."},
	"early_riser": {"branch": "wellbeing", "name": "Early Riser", "ranks": 1, "effects": {"energy:wake": 15}, "requires": {}, "level": 1,
		"description": "Wake with 15 extra energy (up to your maximum)."},
	"foodie": {"branch": "wellbeing", "name": "Foodie", "ranks": 2, "effects": {"boost:duration": 0.25}, "requires": {}, "level": 2,
		"description": "Food and drink boosts last 25% longer per rank."},
	"mindfulness": {"branch": "wellbeing", "name": "Mindfulness", "ranks": 2, "effects": {"energy:restore": 0.25}, "requires": {"iron_constitution": 1}, "level": 3,
		"description": "Food, rest and sleep restore 25% more energy per rank."},
	"runners_high": {"branch": "wellbeing", "name": "Runner's High", "ranks": 1, "effects": {"boost:exercise": 1}, "requires": {"iron_constitution": 1}, "level": 4,
		"description": "A workout also gives +10% XP for two hours."},
	# Leadership.
	"networker": {"branch": "leadership", "name": "Networker", "ranks": 3, "effects": {"club:reputation": 0.10}, "requires": {}, "level": 1,
		"description": "+10% club reputation per rank."},
	"frugal": {"branch": "leadership", "name": "Frugal", "ranks": 2, "effects": {"money:discount": 0.10}, "requires": {}, "level": 2,
		"description": "10% off food, drink and the student store per rank."},
	"tutor": {"branch": "leadership", "name": "Tutor", "ranks": 3, "effects": {"money:tutoring": 0.15}, "requires": {}, "level": 2,
		"description": "+15% tutoring pay per rank."},
	"organizer": {"branch": "leadership", "name": "Organizer", "ranks": 1, "effects": {"xp:club": 0.25}, "requires": {"networker": 2}, "level": 4,
		"description": "+25% XP from club activities."},
	"scholarship_hunter": {"branch": "leadership", "name": "Scholarship Hunter", "ranks": 1, "effects": {"money:awards": 0.25}, "requires": {"frugal": 1}, "level": 6,
		"description": "Merit awards for exam results are 25% larger."},
}

## Perks of one branch, in display order.
static func branch_perks(branch: String) -> Array:
	var result: Array = []
	for id in PERKS:
		if PERKS[id].branch == branch:
			result.append(id)
	return result

static func branch(id: String) -> Dictionary:
	for entry in BRANCHES:
		if entry.id == id:
			return entry
	return {}

## Ranks and titles by level (the student's standing, shown in the menu).
const TITLES := [
	[1, "First-Year Student"], [3, "Apprentice"], [5, "Scholar"], [8, "Clinician-in-Training"],
	[11, "Diagnostician"], [14, "Senior Scholar"], [17, "Honor Student"], [20, "Future Physician"],
]

static func title_for_level(level: int) -> String:
	var title: String = TITLES[0][1]
	for entry in TITLES:
		if level >= int(entry[0]):
			title = entry[1]
	return title

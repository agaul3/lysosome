extends "res://world/interior/interior_scene.gd"
## Anatomy Hall, north-west of the quad: the classical building where the
## first year meets its first patients.
##   Ground floor: the lobby and the donor memorial, the old anatomical
##                 theatre (the donor dedication) and the stair hall
##                 (anatomy_ground.gd)
##   Lower level:  the Gross Anatomy Laboratory, with the PPE room, the model
##                 room and study tables (anatomy_lab.gd)
## The lab opens to the class on the day of the donor dedication (Block 2);
## until then the stair is closed to first-years. Labs, the practical and
## the dedication run from their places here (world/activities).
const Ground = preload("res://world/anatomy/anatomy_ground.gd")
const Lab = preload("res://world/anatomy/anatomy_lab.gd")
const Looks = preload("res://data/looks.gd")
const LAB_OFFSET := Vector3(0, 0, -140)
## When the lab opens to first-years.
const LAB_OPENS := "2026-11-02"
## Filled in by the builders.
var entrance_doors: Array = []
var lab_doors: Node3D
var memorial_point: Vector3
var lectern_point: Vector3
var stairs_point: Vector3
var stairs_up_point: Vector3
var ppe_point: Vector3
var table_point: Vector3
var models_point: Vector3
var theatre_seats: Array = []
var study_seats: Array[Node3D] = []
## The interactions, for tests and activities.
var memorial: Node3D
var stairs_down: Node3D
var stairs_up: Node3D
var ppe: Node3D
var models: Node3D
var table: Node3D
var theatre: Node3D
var campus_exit: Node3D

func zones() -> Dictionary:
	return {
		"ground": {"title": "Anatomy Hall", "origin": Vector3.ZERO, "min": Vector2(-4.0, -3.0), "max": Vector2(4.0, 4.0), "view": 16.0},
		"lab": {"title": "Anatomy Hall · Gross Anatomy Laboratory", "origin": LAB_OFFSET, "min": Vector2(-8.0, -147.0), "max": Vector2(8.0, -133.0), "view": 20.0},
	}

func builders() -> Dictionary:
	return {"ground": Ground, "lab": Lab}

func scene_key() -> String:
	return "anatomy"

func arrival() -> Vector3:
	return anchor("arrival") if AppState.interior_entry == "lab" else anchor("entrance")

func arrival_yaw() -> float:
	return PI / 2 if AppState.interior_entry == "lab" else 0.0

func student_look(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 61
	return Looks.random(rng)

## A look with some of its outfit replaced (lab scrubs, a white coat…).
func dressed(look: Dictionary, outfit: Dictionary) -> Dictionary:
	var copy := look.duplicate(true)
	for slot in outfit:
		copy.outfit[slot] = outfit[slot]
	return Looks.sanitize(copy)

## Whether first-years may go down to the lab yet.
func lab_open() -> bool:
	return YearCalendar.today_date() >= LAB_OPENS or YearCalendar.completed(YearCalendar.event("donor_dedication"))

func populate() -> void:
	build_root = zone_roots.ground
	campus_exit = add_exit("CampusExit", "Leave for the quad", anchor("entrance") + Vector3(0, 1.0, 1.0), "anatomy", 1.8)
	memorial = add_endpoint("Memorial", "Read the memorial", "The plaque reads: \"In gratitude to those who gave their bodies so that we might learn to heal. They are our first patients.\" The book of remembrance lists this year's donors by first name only. Someone has left fresh flowers.", memorial_point, 1.8)
	theatre = add_station("Theatre", "theatre", lectern_point, "The anatomical theatre", "Three tiers of oak benches rise round a single table. For two hundred years students watched dissections from here; now the class gathers in it once a year, to thank the donors before the first day of lab.", 1.8)
	stairs_down = add_endpoint("StairsDown", "Go down to the Gross Anatomy Lab", "", stairs_point, 1.8)
	stairs_down.activated.connect(go_down)
	add_walkers("ground", [Vector2(1.6, 4.4), Vector2(4.0, 3.0), Vector2(4.0, 0.2), Vector2(-3.2, 2.8)], [[0, 1], [1, 2], [0, 3]], 1, [[Vector2(7.2, 3.4), 1.2]])
	add_fill("ground", [Vector3(-3.2, 4.0, -2.4), Vector3(4.0, 4.0, 3.0)], 0.3, 12.0, Color("fff0da"))
	build_root = zone_roots.lab
	stairs_up = add_transfer("StairsUp", "Go up to the ground floor", stairs_up_point, anchor("stairs"), PI)
	ppe = add_endpoint("PPE", "Put on a gown, gloves and eye protection", "Gown on, gloves on, glasses on. The lab's rules are on the wall: no photographs, no phones out, and treat every donor with the respect you'd want for your own family.", ppe_point, 1.7)
	models = add_endpoint("Models", "Study the models", "", models_point, 1.8)
	models.activated.connect(study_models)
	table = add_station("YourTable", "lab", table_point, "Table 7 · your dissection group", "Your group's donor lies under the drape. Lab sessions and the practical start here when they're scheduled.", 1.6)
	# Instructors and students between the table rows (the aisles are narrow:
	# they barely step aside, and wait).
	add_walkers("lab", [Vector2(11.6, -139.4), Vector2(11.6, -133.4), Vector2(-12.4, -133.4), Vector2(-12.4, -137.0), Vector2(11.6, -137.0)],
		[[0, 4], [4, 1], [1, 2], [2, 3], [3, 4]], 2, [], [dressed(student_look(740), Lab.SCRUBS), dressed(student_look(741), Lab.SCRUBS)], 0.2)
	add_fill("lab", [Vector3(-8, 3.0, 4), Vector3(4, 3.0, 4), Vector3(-6, 3.0, -6), Vector3(10, 3.0, -6)], 0.28, 12.0, Color("f4f8f8"))
	build_root = self

func zone_changed(zone_name: String) -> void:
	AppState.interior_entry = "lab" if zone_name == "lab" else "main"

func go_down() -> void:
	if not lab_open():
		hud.show_message("The lab opens to your class on the morning of the donor dedication, the first day of Block 2 (Monday, November 2).", 6.0)
		return
	transfer(anchor("arrival"), PI / 2)

## Open study with the models and bones: a half-hour of review (flashcards
## from anatomy, once you've had it) that restores nothing, but counts.
func study_models() -> void:
	hud.show_message("You work through the brachial plexus on the plastic arm and the bones of the wrist with a classmate: scaphoid, lunate, triquetrum, pisiform, trapezium, trapezoid, capitate, hamate.", 6.0)
	YearCalendar.pass_time(30.0)
	Achievements.bump("model_sessions")

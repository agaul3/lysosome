extends "res://world/interior/interior_scene.gd"
## The Biomedical Library, at the east end of the Health Sciences Walk.
##   Level 1: circulation, the Computer Commons (PCs with the flashcard app),
##            laptop tables, the group study rooms and Stacks Café
##            (library_ground.gd)
##   Level 2: the quiet floor: the reading room, carrels, the stacks and the
##            history-of-medicine exhibit (library_level2.gd)
## Study here the way you would at home: sit at a PC, or take a seat at a
## table and open your laptop. The class study group meets in Room 2.
const Ground = preload("res://world/library/library_ground.gd")
const Level2 = preload("res://world/library/library_level2.gd")
const Looks = preload("res://data/looks.gd")
const ShopPanel = preload("res://ui/shop_panel.gd")
const LEVEL2_OFFSET := Vector3(0, 0, -140)
## Filled in by the builders.
var entrance_doors: Array = []
var elevator_point: Vector3
var elevator_point_2: Vector3
var library_pcs: Array[Node3D] = []
var study_seats: Array[Node3D] = []
var study_group: Node3D
var cafe: Node3D
var campus_exit: Node3D

func zones() -> Dictionary:
	return {
		"ground": {"title": "Biomedical Library · Level 1", "origin": Vector3.ZERO, "min": Vector2(-8.0, -9.0), "max": Vector2(8.0, 10.0), "view": 19.0},
		"level2": {"title": "Biomedical Library · Level 2 · Quiet Floor", "origin": LEVEL2_OFFSET, "min": Vector2(-8.0, -149.0), "max": Vector2(8.0, -130.0), "view": 19.0},
	}

func builders() -> Dictionary:
	return {"ground": Ground, "level2": Level2}

func scene_key() -> String:
	return "library"

func arrival() -> Vector3:
	return anchor("arrival") if AppState.interior_entry == "level2" else anchor("entrance")

func arrival_yaw() -> float:
	return PI if AppState.interior_entry == "level2" else 0.0

## A student's look from a seed: a different face at every table.
func student_look(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 29
	return Looks.random(rng)

func populate() -> void:
	build_root = zone_roots.ground
	campus_exit = add_exit("CampusExit", "Leave for the Health Sciences Walk", anchor("entrance") + Vector3(0, 1.0, 1.0), "library", 1.8)
	add_transfer("ElevatorUp", "Take the elevator to Level 2", elevator_point, anchor("arrival"), PI)
	cafe.activated.connect(open_shop.bind("library_cafe"))
	study_group.activated.connect(join_study_group)
	add_walkers("ground", [Vector2(0, 11.0), Vector2(0, 7.0), Vector2(-2.6, 5.4), Vector2(-2.6, -8.4), Vector2(5.2, -8.4), Vector2(5.2, 5.2), Vector2(10.5, 5.2)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 2], [5, 6]], 2,
		# No room to step aside along the study rooms, between their glass and the chairs.
		[[Vector2(-6.5, 8.6), 2.6], [Vector2(-1.4, -8.4), 1.3], [Vector2(1.0, -8.4), 1.3], [Vector2(3.4, -8.4), 1.3], [Vector2(5.2, -8.4), 1.3]])
	add_fill("ground", [Vector3(-8, 3.8, -2), Vector3(5, 3.8, -2), Vector3(9, 3.6, 10), Vector3(-3.5, 3.6, -12)], 0.3, 12.0)
	build_root = zone_roots.level2
	add_transfer("ElevatorDown", "Take the elevator to Level 1", elevator_point_2, anchor("elevator"), PI)
	# From the exhibit, through its doorway, along the stacks and into the reading room.
	add_walkers("level2", [Vector2(10.5, -145.6), Vector2(8.0, -145.0), Vector2(5.9, -145.0), Vector2(5.9, -149.3), Vector2(-2.0, -149.3),
		Vector2(5.9, -139.6), Vector2(0.0, -139.6), Vector2(0.0, -127.8), Vector2(-10.2, -139.6), Vector2(-10.2, -128.0)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [2, 5], [5, 6], [6, 7], [6, 8], [8, 9]], 2)
	add_fill("level2", [Vector3(-6, 3.8, 6), Vector3(6, 3.8, 6), Vector3(-4, 3.6, -8), Vector3(10.5, 3.4, -5)], 0.3, 12.0, Color("fff1dc"))
	build_root = self

## Night Owl: studying at a PC or on a laptop here after 10 PM.
func _process(delta: float) -> void:
	super(delta)
	if hud.computer_open and not Achievements.has_flag("library_late"):
		var hour := int(GameClock.snapshot().hour)
		if hour >= 22 or hour < 5:
			Achievements.set_flag("library_late")

func zone_changed(zone_name: String) -> void:
	AppState.interior_entry = "level2" if zone_name == "level2" else "main"

func open_shop(vendor: String) -> void:
	hud.open_modal(ShopPanel.new(vendor))

## The class study group in Room 2 (ui/study_group_panel.gd).
func join_study_group() -> void:
	hud.open_modal(preload("res://ui/study_group_panel.gd").new())

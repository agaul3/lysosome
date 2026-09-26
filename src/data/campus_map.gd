extends RefCounted
## Plan-view campus layout for the menu's Campus Map. Footprints match the
## geometry built in world/campus/campus.gd and buildings.gd (world metres,
## x east, z south; the map draws north up).
## Campus plus University Hospital across the street (to the south) and the
## street behind it with the Emergency Department, and the East Campus along
## the Health Sciences Walk.
const BOUNDS := Rect2(-39, -60, 185, 145)
const PLAZA_CENTER := Vector2(0, -2)
const PLAZA_RADIUS := 4.5
## [x0, z0, x1, z1]
const LAWNS := [[-12.0, -12.0, -1.5, -3.5], [1.5, -12.0, 12.0, -3.5], [-12.0, -0.5, -1.5, 8.0], [1.5, -0.5, 12.0, 8.0],
	[42.0, -12.0, 66.5, 3.5], [69.5, -12.0, 96.0, 3.5], [42.0, 6.5, 66.5, 19.5], [69.5, 6.5, 96.0, 19.5]]
## The East Green's fountain plaza.
const FOUNTAIN := Vector2(68, 5)
const FOUNTAIN_RADIUS := 6.5
const PATHS := [
	[-15, -15, 15, -12], [-15, 8, 15, 11], [-15, -12, -12, 8], [12, -12, 15, 8], [-1.5, -12, 1.5, 8],
	[-12, -3.5, 12, -0.5], [-22, -3.5, -15, -0.5], [15, -3.5, 20.5, -0.5], [-26, 11, 26, 14], [-1.5, 11, 1.5, 14],
	[26, 11, 30.5, 14], [27.5, 14, 30.5, 37], [11.5, 70, 37, 74.5],
	[66.5, -12, 69.5, 20], [20.5, 3.5, 100, 6.5], [97, 6.5, 100, 20], [40, -15, 42, 20],
	[30.5, 20, 134.5, 25], [30.5, 14, 34, 20], [40, 37, 140, 40],
]
## The street between the campus and the hospital, and the one behind it.
const STREET := [-39, 27, 145, 35]
const BACK_STREET := [-39, 75.5, 37, 82.5]
const PLAZAS := [[-17, -24.7, 17, -15], [-22, -7, -15, 4], [17, -22, 36, -14], [15, -11, 20.5, 5], [-20, -24, -15, -15], [-32, 37, 24, 44], [24, 37, 36.5, 74.5],
	[36, -22, 134.5, -15], [56, -15, 80, -12], [98, -30, 104, -22], [100, 18, 134.5, 21.5]]
const PARKING := [-25, 14, 25, 26]
## id -> [name, x0, z0, x1, z1, scene it contains]
const BUILDINGS := {
	"learning_center": ["Learning Center", -15.0, -36.0, 15.0, -24.6, "lecture_building"],
	"residence": ["Cedar Residence", -34.0, -12.0, -22.0, 9.0, "dorm"],
	"medical": ["Research", 18.0, -36.0, 34.0, -22.0, ""],
	"anatomy": ["Anatomy Hall", -38.0, -37.0, -20.0, -24.0, "anatomy"],
	"cafe": ["Café", 20.5, -9.0, 29.5, 3.0, ""],
	"hospital": ["University Hospital", -32.0, 44.0, 27.5, 70.0, "hospital"],
	"med_ed": ["Medical Education Center", 38.0, -58.0, 98.0, -22.0, "med_ed"],
	"library": ["Library", 104.0, -52.0, 132.0, -22.0, "library"],
	"student_center": ["Student Center", 102.0, -6.0, 132.0, 18.0, "student_center"],
}
## Doors the player can use: [label, x, z]
const ENTRANCES := [["Learning Center", 0.0, -23.4], ["Cedar Residence", -21.4, -2.0], ["University Hospital", 27.8, 50.0], ["Emergency Department", 15.0, 70.7],
	["Medical Education Center", 68.0, -21.2], ["Biomedical Library", 118.0, -20.3], ["Student Center", 112.0, 18.8], ["Anatomy Hall", -29.0, -23.1]]
## Campus shuttle stops: [label, x, z]. The shuttle also runs off campus to
## the Harbor Street Community Center.
const SHUTTLES := [["Quad", -18.6, 13.5], ["Hospital", 33.6, 24.4], ["East Campus", 89.6, 24.4]]
const DIRECTORY := Vector2(-17, 3)

## Building that contains a given indoor scene, if any.
static func building_for_scene(scene: String) -> String:
	if scene == "lecture_hall":
		scene = "med_ed" if _hall() == "hall_b" else "lecture_building"
	for id in BUILDINGS:
		if BUILDINGS[id][5] == scene:
			return id
	return ""

static func _hall() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var state: Node = tree.root.get_node_or_null("AppState") if tree else null
	return String(state.current_hall) if state else "hall_a"

## The building an event happens in (for the map's destination), or "".
static func building_for_event(entry: Dictionary) -> String:
	var place := String(entry.get("place", ""))
	if place.is_empty():
		# Day 1's events: the lecture in Hall A, shadowing at the hospital.
		return "hospital" if String(entry.get("id", "")).begins_with("hospital_") else "learning_center"
	if place == "lecture_hall":
		return "med_ed" if String(entry.get("room", "")) == "hall_b" else "learning_center"
	if place == "campus" or place == "community":
		return ""
	return building_for_scene(place)

extends RefCounted
## Plan-view campus layout for the menu's Campus Map. Footprints match the
## geometry built in world/campus/campus.gd and buildings.gd (world metres,
## x east, z south; the map draws north up).
const BOUNDS := Rect2(-39, -37, 75, 63)
const PLAZA_CENTER := Vector2(0, -2)
const PLAZA_RADIUS := 4.5
## [x0, z0, x1, z1]
const LAWNS := [[-12.0, -12.0, -1.5, -3.5], [1.5, -12.0, 12.0, -3.5], [-12.0, -0.5, -1.5, 8.0], [1.5, -0.5, 12.0, 8.0]]
const PATHS := [
	[-15, -15, 15, -12], [-15, 8, 15, 11], [-15, -12, -12, 8], [12, -12, 15, 8], [-1.5, -12, 1.5, 8],
	[-12, -3.5, 12, -0.5], [-22, -3.5, -15, -0.5], [15, -3.5, 20.5, -0.5], [-26, 11, 26, 14], [-1.5, 11, 1.5, 14],
]
const PLAZAS := [[-17, -24.7, 17, -15], [-22, -7, -15, 4], [17, -22, 36, -14], [15, -11, 20.5, 5], [-20, -24, -15, -15]]
const PARKING := [-25, 14, 25, 26]
## id -> [name, x0, z0, x1, z1, scene it contains]
const BUILDINGS := {
	"learning_center": ["Learning Center", -15.0, -36.0, 15.0, -24.6, "lecture_building"],
	"residence": ["Cedar Residence", -34.0, -12.0, -22.0, 9.0, "dorm"],
	"medical": ["Medical Center", 18.0, -36.0, 34.0, -22.0, ""],
	"anatomy": ["Anatomy Hall", -38.0, -37.0, -20.0, -24.0, ""],
	"cafe": ["Café", 20.5, -9.0, 29.5, 3.0, ""],
}
## Doors the player can use: [label, x, z]
const ENTRANCES := [["Learning Center", 0.0, -23.4], ["Cedar Residence", -21.4, -2.0]]
const DIRECTORY := Vector2(-17, 3)

## Building that contains a given indoor scene, if any.
static func building_for_scene(scene: String) -> String:
	if scene == "lecture_hall":
		scene = "lecture_building"
	for id in BUILDINGS:
		if BUILDINGS[id][5] == scene:
			return id
	return ""

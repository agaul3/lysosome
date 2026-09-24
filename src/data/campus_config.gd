extends RefCounted
## Campus palette, arrival positions, doors and camera framing; starting time
## lives in academic_config.json. See world/campus/campus.gd for the layout.
const Route = preload("res://data/npc_route.gd")
const MORNING := {
	"sun_rotation": Vector3(-32, -40, 0),
	"sun_color": Color("ffe6c4"), "sun_energy": 1.2,
	"ambient_color": Color("cbdce1"), "ambient_energy": 0.65,
}
const SPAWNS := {
	"dorm": Vector3(-19.8, 0.05, -2),
	"lecture_building": Vector3(0, 0.05, -21.8),
	"hospital": Vector3(29.0, 0.05, 50),
}
## Arrivals face out of the door they came through (east from the residence,
## south from the Learning Center, east from the hospital's main entrance).
const SPAWN_YAWS := {"dorm": -PI / 2, "lecture_building": PI, "hospital": -PI / 2}
const RESIDENCE_DOOR := Vector3(-21.2, 1, -2)
const LEARNING_CENTER_DOOR := Vector3(0, 1, -23.2)
## University Hospital's main entrance (east face), across the street.
const HOSPITAL_DOOR := Vector3(28.1, 1, 50)
## The crosswalk from the campus to the hospital plaza (x range) and the plaza itself.
const CROSSWALK_X := Vector2(27.5, 30.5)
const HOSPITAL_PLAZA := Rect2(24.0, 37.0, 12.5, 21.0)
const SAM_POSITION := Route.SAM_POSITION
const CAMERA_VIEW := 21.0
const CAMERA_MIN := Vector2(-24, -24)
const CAMERA_MAX := Vector2(26, 46)

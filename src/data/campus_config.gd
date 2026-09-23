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
}
const RESIDENCE_DOOR := Vector3(-21.2, 1, -2)
const LEARNING_CENTER_DOOR := Vector3(0, 1, -23.2)
const SAM_POSITION := Route.SAM_POSITION
const CAMERA_VIEW := 21.0
const CAMERA_MIN := Vector2(-24, -24)
const CAMERA_MAX := Vector2(24, 16)

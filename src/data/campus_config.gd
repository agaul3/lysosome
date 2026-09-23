extends RefCounted
## Campus palette and arrival positions; starting time lives in academic_config.json.
const MORNING := {
	"sun_rotation": Vector3(-32, -40, 0),
	"sun_color": Color("ffe6c4"), "sun_energy": 1.2,
	"ambient_color": Color("cbdce1"), "ambient_energy": 0.65,
}
const SPAWNS := {
	"dorm": Vector3(-6.1, 0.05, 5),
	"lecture_building": Vector3(8, 0.05, -3.5),
}

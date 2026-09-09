extends RefCounted
## Presentation-only morning data. The live time/schedule system belongs to Milestone 5.
const MORNING := {
	"hour": 7, "minute": 35,
	"sun_rotation": Vector3(-32, -40, 0),
	"sun_color": Color("ffe0b5"), "sun_energy": 0.85,
	"ambient_color": Color("cbdce1"), "ambient_energy": 0.65,
}
const SPAWNS := {
	"dorm": Vector3(-6.1, 0.05, 5),
	"lecture_building": Vector3(8, 0.05, -3.5),
}

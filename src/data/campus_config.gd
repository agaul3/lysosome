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
	"ed": Vector3(15.0, 0.05, 71.6),
	"med_ed": Vector3(68, 0.05, -19.6),
	"library": Vector3(118, 0.05, -19.0),
	"student_center": Vector3(112, 0.05, 20.2),
	"anatomy": Vector3(-29, 0.05, -19.8),
	# Off a campus shuttle (world/campus/east_campus.gd SHUTTLE_STOPS), and
	# back from the Community Center, which the shuttle drops at the East stop.
	"shuttle_quad": Vector3(-18.6, 0.05, 12.3),
	"shuttle_hospital": Vector3(32.4, 0.05, 23.2),
	"shuttle_east": Vector3(92.0, 0.05, 22.6),
	"community": Vector3(92.0, 0.05, 22.6),
}
## Arrivals face out of the door they came through (east from the residence,
## south from the Learning Center and the East Campus buildings, east from the
## hospital's main entrance); shuttle riders face the way they are going.
const SPAWN_YAWS := {
	"dorm": -PI / 2, "lecture_building": PI, "hospital": -PI / 2, "ed": PI,
	"med_ed": PI, "library": PI, "student_center": PI, "anatomy": PI,
	"shuttle_quad": 0.0, "shuttle_hospital": PI / 2, "shuttle_east": 0.0, "community": 0.0,
}
## The door of each East Campus building and Anatomy Hall (for the map and tests).
const MED_ED_DOOR := Vector3(68, 1, -21.2)
const LIBRARY_DOOR := Vector3(118, 1, -20.3)
const STUDENT_CENTER_DOOR := Vector3(112, 1, 18.8)
const RESIDENCE_DOOR := Vector3(-21.2, 1, -2)
const LEARNING_CENTER_DOOR := Vector3(0, 1, -23.2)
## University Hospital's main entrance (east face), across the street.
const HOSPITAL_DOOR := Vector3(28.1, 1, 50)
## The Emergency Department's walk-in entrance on the hospital's south side.
const ED_DOOR := Vector3(15.0, 1, 70.7)
## The crosswalk from the campus to the hospital plaza (x range) and the plaza itself.
const CROSSWALK_X := Vector2(27.5, 30.5)
## The entrance plaza, continuing south along the building to the ED.
const HOSPITAL_PLAZA := Rect2(24.0, 37.0, 12.5, 37.5)
## The sidewalk in front of the Emergency Department (x 11.5–24, z 70–74.5).
const ED_SIDEWALK := Rect2(11.5, 70.0, 12.5, 4.5)
const SAM_POSITION := Route.SAM_POSITION
const CAMERA_VIEW := 21.0
const CAMERA_MIN := Vector2(-24, -24)
const CAMERA_MAX := Vector2(124, 72)

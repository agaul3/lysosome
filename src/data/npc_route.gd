extends RefCounted
## Authored navigation graph: positions are local to each independently loaded world.
const SPEED := 1.65
const START_DELAY := 2.0
const LINE_SECONDS := 2.4
const LINES := [
	{"speaker": "alex", "text": "Hey."},
	{"speaker": "sam", "text": "Hey, you heading to pharm?"},
	{"speaker": "alex", "text": "Yeah. See you in Hall A."},
]
## Where Sam waits on the quad, beside a bench west of the round plaza.
const SAM_POSITION := Vector3(-6, 0, -4.6)
## Origin of Alex's saved seat in Hall A: row 2, centre section (see lecture_hall.gd ALEX_SEAT).
const HALL_SEAT := Vector3(-1.84, 0.76, 1.04)
const GRAPHS := {
	"campus": {
		# Out of Cedar Residence, along the east-west path to Sam by the plaza,
		# then north across the quad to the Learning Center doors.
		"points": [Vector3(-19, 0, -1.8), Vector3(-12, 0, -2), Vector3(-6, 0, -3.2), Vector3(-1.2, 0, -8.5), Vector3(0, 0, -22.6)],
		"edges": [[0, 1], [1, 2], [2, 3], [3, 4]],
	},
	"lecture_building": {
		"points": [Vector3(0, 0, 2.5), Vector3(0, 0, 0), Vector3(0, 0, -3)],
		"edges": [[0, 1], [1, 2]],
	},
	"lecture_hall": {
		# Front-left door, across the teaching floor, up the left aisle steps
		# (foot and head of each flight follow the ramp), then along row 2.
		"points": [
			Vector3(-7, 0, -6.2), Vector3(-3.9, 0, -6.2), Vector3(-3.9, 0, -4.3), Vector3(-3.9, 0, -3.08),
			Vector3(-3.9, 0, -2.75), Vector3(-3.9, 0.38, -2.15), Vector3(-3.9, 0.38, -1.48),
			Vector3(-3.9, 0.38, -1.15), Vector3(-3.9, 0.76, -0.55), Vector3(-3.9, 0.76, 0.12),
			Vector3(-2.76, 0.76, 0.12), Vector3(-1.84, 0.76, 0.12),
		],
		"edges": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [9, 10], [10, 11]],
	},
}

static func find_path(zone: String, start: int, goal: int) -> PackedVector3Array:
	var data: Dictionary = GRAPHS[zone]
	var graph := AStar3D.new()
	for index in range(data.points.size()):
		graph.add_point(index, data.points[index])
	for edge in data.edges:
		graph.connect_points(edge[0], edge[1])
	return graph.get_point_path(start, goal)

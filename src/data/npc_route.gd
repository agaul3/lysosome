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
const GRAPHS := {
	"campus": {
		"points": [Vector3(-5, 0, 3), Vector3(-1, 0, 2), Vector3(3.5, 0, 1.1), Vector3(8, 0, 1.1), Vector3(8, 0, -4.8)],
		"edges": [[0, 1], [1, 2], [2, 3], [3, 4]],
	},
	"lecture_building": {
		"points": [Vector3(0, 0, 2.5), Vector3(0, 0, 0), Vector3(0, 0, -3)],
		"edges": [[0, 1], [1, 2]],
	},
	"lecture_hall": {
		"points": [Vector3(0, 0, 3.4), Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(2, 0, -2)],
		"edges": [[0, 1], [1, 2], [2, 3]],
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

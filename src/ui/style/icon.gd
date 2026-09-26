extends Control
## Consistent line icons, drawn as vectors at native resolution so they stay
## crisp at any UI scale. One stroke weight and corner style throughout.
## Names: overview, schedule, calendar, map, knowledge, notes, achievements,
## inventory, settings, clock, pin, target, spark, flame, check, lock, save,
## play, power, plus, arrow, book, person, users, coin, bolt, cup, bowl,
## bar, moon, bag, star, journal, tree.
@export var icon := "overview":
	set(value):
		icon = value
		queue_redraw()
@export var color := Color("eef3f1"):
	set(value):
		color = value
		queue_redraw()
@export var stroke := 1.6

func _init(name_value := "overview", size_value := 18.0, color_value := Color("eef3f1")) -> void:
	icon = name_value
	color = color_value
	custom_minimum_size = Vector2(size_value, size_value)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _p(x: float, y: float) -> Vector2:
	var s := minf(size.x, size.y)
	var offset := (size - Vector2(s, s)) / 2.0
	return offset + Vector2(x, y) * s

func _s() -> float:
	return minf(size.x, size.y)

func _line(points: Array, closed := false) -> void:
	var packed := PackedVector2Array()
	for point in points:
		packed.append(_p(point.x, point.y))
	if closed:
		packed.append(packed[0])
	draw_polyline(packed, color, stroke, true)

func _circle(cx: float, cy: float, r: float, filled := false) -> void:
	if filled:
		draw_circle(_p(cx, cy), r * _s(), color)
	else:
		draw_arc(_p(cx, cy), r * _s(), 0, TAU, 32, color, stroke, true)

func _arc(cx: float, cy: float, r: float, a0: float, a1: float) -> void:
	draw_arc(_p(cx, cy), r * _s(), a0, a1, 24, color, stroke, true)

## Rounded rectangle outline in unit coordinates.
func _rrect(x0: float, y0: float, x1: float, y1: float, r: float) -> void:
	var points: Array = []
	var corners := [[x1 - r, y0 + r, -PI / 2], [x1 - r, y1 - r, 0.0], [x0 + r, y1 - r, PI / 2], [x0 + r, y0 + r, PI]]
	for corner in corners:
		for step in range(7):
			var angle: float = corner[2] + step / 6.0 * (PI / 2)
			points.append(Vector2(corner[0] + cos(angle) * r, corner[1] + sin(angle) * r))
	_line(points, true)

func _draw() -> void:
	match icon:
		"overview":
			_rrect(0.12, 0.12, 0.45, 0.45, 0.07)
			_rrect(0.55, 0.12, 0.88, 0.45, 0.07)
			_rrect(0.12, 0.55, 0.45, 0.88, 0.07)
			_rrect(0.55, 0.55, 0.88, 0.88, 0.07)
		"schedule":
			_rrect(0.2, 0.16, 0.8, 0.9, 0.08)
			_rrect(0.36, 0.08, 0.64, 0.24, 0.04)
			for y in [0.42, 0.57, 0.72]:
				_line([Vector2(0.33, y), Vector2(0.67, y)])
		"calendar":
			_rrect(0.12, 0.2, 0.88, 0.88, 0.09)
			_line([Vector2(0.12, 0.38), Vector2(0.88, 0.38)])
			_line([Vector2(0.33, 0.1), Vector2(0.33, 0.27)])
			_line([Vector2(0.67, 0.1), Vector2(0.67, 0.27)])
			for y in [0.54, 0.72]:
				for x in [0.32, 0.5, 0.68]:
					_circle(x, y, 0.035, true)
		"map":
			_line([Vector2(0.1, 0.24), Vector2(0.37, 0.14), Vector2(0.63, 0.26), Vector2(0.9, 0.16), Vector2(0.9, 0.76), Vector2(0.63, 0.86), Vector2(0.37, 0.74), Vector2(0.1, 0.84)], true)
			_line([Vector2(0.37, 0.14), Vector2(0.37, 0.74)])
			_line([Vector2(0.63, 0.26), Vector2(0.63, 0.86)])
		"knowledge", "book":
			_line([Vector2(0.5, 0.28), Vector2(0.5, 0.86)])
			_line([Vector2(0.5, 0.28), Vector2(0.36, 0.2), Vector2(0.1, 0.2), Vector2(0.1, 0.78), Vector2(0.36, 0.78), Vector2(0.5, 0.86)])
			_line([Vector2(0.5, 0.28), Vector2(0.64, 0.2), Vector2(0.9, 0.2), Vector2(0.9, 0.78), Vector2(0.64, 0.78), Vector2(0.5, 0.86)])
			if icon == "knowledge":
				_line([Vector2(0.2, 0.62), Vector2(0.28, 0.5), Vector2(0.34, 0.56), Vector2(0.42, 0.4)])
		"notes":
			_rrect(0.22, 0.1, 0.84, 0.9, 0.07)
			for y in [0.24, 0.42, 0.6, 0.78]:
				_line([Vector2(0.14, y), Vector2(0.28, y)])
			for y in [0.36, 0.52, 0.68]:
				_line([Vector2(0.42, y), Vector2(0.72, y)])
		"achievements":
			_circle(0.5, 0.4, 0.24)
			_circle(0.5, 0.4, 0.1)
			_line([Vector2(0.36, 0.6), Vector2(0.28, 0.9), Vector2(0.4, 0.83), Vector2(0.46, 0.94), Vector2(0.5, 0.66)])
			_line([Vector2(0.64, 0.6), Vector2(0.72, 0.9), Vector2(0.6, 0.83), Vector2(0.54, 0.94), Vector2(0.5, 0.66)])
		"inventory":
			_rrect(0.18, 0.3, 0.82, 0.9, 0.14)
			_arc(0.5, 0.3, 0.16, PI, TAU)
			_rrect(0.32, 0.55, 0.68, 0.78, 0.06)
		"settings":
			_circle(0.5, 0.5, 0.14)
			_circle(0.5, 0.5, 0.29)
			for index in range(8):
				var angle := index * TAU / 8.0
				_line([Vector2(0.5 + cos(angle) * 0.3, 0.5 + sin(angle) * 0.3), Vector2(0.5 + cos(angle) * 0.42, 0.5 + sin(angle) * 0.42)])
		"clock":
			_circle(0.5, 0.5, 0.38)
			_line([Vector2(0.5, 0.26), Vector2(0.5, 0.5), Vector2(0.66, 0.6)])
		"pin":
			var points: Array = []
			for step in range(25):
				var angle := PI * 0.8 + step / 24.0 * PI * 1.4
				points.append(Vector2(0.5 + cos(angle) * 0.28, 0.4 + sin(angle) * 0.28))
			points.append(Vector2(0.5, 0.92))
			_line(points, true)
			_circle(0.5, 0.4, 0.1)
		"target":
			_circle(0.5, 0.5, 0.38)
			_circle(0.5, 0.5, 0.2)
			_circle(0.5, 0.5, 0.05, true)
		"spark":
			var star: Array = []
			for index in range(8):
				var angle := index * TAU / 8.0 - PI / 2
				var r := 0.42 if index % 2 == 0 else 0.14
				star.append(Vector2(0.5 + cos(angle) * r, 0.5 + sin(angle) * r))
			_line(star, true)
		"flame":
			_line([Vector2(0.5, 0.08), Vector2(0.66, 0.3), Vector2(0.78, 0.52), Vector2(0.74, 0.74), Vector2(0.6, 0.88), Vector2(0.4, 0.88), Vector2(0.26, 0.74), Vector2(0.24, 0.52), Vector2(0.36, 0.36), Vector2(0.42, 0.5), Vector2(0.5, 0.08)])
			_line([Vector2(0.5, 0.52), Vector2(0.6, 0.66), Vector2(0.56, 0.8), Vector2(0.44, 0.8), Vector2(0.4, 0.66), Vector2(0.5, 0.52)])
		"check":
			_line([Vector2(0.2, 0.52), Vector2(0.42, 0.72), Vector2(0.8, 0.3)])
		"lock":
			_rrect(0.2, 0.44, 0.8, 0.9, 0.08)
			_arc(0.5, 0.44, 0.2, PI, TAU)
			_line([Vector2(0.3, 0.44), Vector2(0.3, 0.36)])
			_line([Vector2(0.7, 0.44), Vector2(0.7, 0.36)])
		"save":
			_line([Vector2(0.5, 0.12), Vector2(0.5, 0.62)])
			_line([Vector2(0.32, 0.46), Vector2(0.5, 0.64), Vector2(0.68, 0.46)])
			_line([Vector2(0.14, 0.62), Vector2(0.14, 0.86), Vector2(0.86, 0.86), Vector2(0.86, 0.62)])
		"play":
			_line([Vector2(0.3, 0.18), Vector2(0.8, 0.5), Vector2(0.3, 0.82)], true)
		"power":
			_arc(0.5, 0.54, 0.32, -PI * 0.3, PI * 1.3)
			_line([Vector2(0.5, 0.12), Vector2(0.5, 0.48)])
		"plus":
			_line([Vector2(0.5, 0.2), Vector2(0.5, 0.8)])
			_line([Vector2(0.2, 0.5), Vector2(0.8, 0.5)])
		"arrow":
			_line([Vector2(0.16, 0.5), Vector2(0.82, 0.5)])
			_line([Vector2(0.58, 0.26), Vector2(0.82, 0.5), Vector2(0.58, 0.74)])
		"person":
			_circle(0.5, 0.32, 0.17)
			_arc(0.5, 0.95, 0.36, PI * 1.15, PI * 1.85)
		"users":
			_circle(0.38, 0.34, 0.14)
			_arc(0.38, 0.92, 0.3, PI * 1.15, PI * 1.85)
			_circle(0.68, 0.38, 0.11)
			_arc(0.7, 0.9, 0.24, PI * 1.25, PI * 1.85)
		"coin":
			_circle(0.5, 0.5, 0.38)
			_line([Vector2(0.6, 0.34), Vector2(0.44, 0.34), Vector2(0.38, 0.42), Vector2(0.44, 0.5), Vector2(0.56, 0.5), Vector2(0.62, 0.58), Vector2(0.56, 0.66), Vector2(0.4, 0.66)])
			_line([Vector2(0.5, 0.24), Vector2(0.5, 0.76)])
		"bolt":
			_line([Vector2(0.58, 0.08), Vector2(0.26, 0.56), Vector2(0.48, 0.56), Vector2(0.4, 0.92), Vector2(0.74, 0.42), Vector2(0.52, 0.42), Vector2(0.58, 0.08)])
		"cup":
			_line([Vector2(0.22, 0.34), Vector2(0.28, 0.86), Vector2(0.66, 0.86), Vector2(0.72, 0.34)], true)
			_arc(0.76, 0.56, 0.12, -PI / 2, PI / 2)
			_line([Vector2(0.38, 0.1), Vector2(0.36, 0.22)])
			_line([Vector2(0.54, 0.1), Vector2(0.52, 0.22)])
		"bowl":
			_arc(0.5, 0.46, 0.38, 0.0, PI)
			_line([Vector2(0.12, 0.46), Vector2(0.88, 0.46)])
			_line([Vector2(0.38, 0.84), Vector2(0.62, 0.84)])
			_line([Vector2(0.62, 0.12), Vector2(0.44, 0.4)])
			_line([Vector2(0.76, 0.16), Vector2(0.56, 0.42)])
		"bar":
			_rrect(0.14, 0.34, 0.86, 0.66, 0.1)
			_line([Vector2(0.38, 0.34), Vector2(0.38, 0.66)])
			_line([Vector2(0.62, 0.34), Vector2(0.62, 0.66)])
		"moon":
			_arc(0.5, 0.5, 0.36, PI * 0.42, PI * 1.9)
			_arc(0.66, 0.4, 0.28, PI * 0.72, PI * 1.62)
		"bag":
			_rrect(0.16, 0.32, 0.84, 0.9, 0.08)
			_arc(0.5, 0.34, 0.18, PI, TAU)
		"star":
			var points: Array = []
			for index in range(10):
				var angle := index * TAU / 10.0 - PI / 2
				var r := 0.42 if index % 2 == 0 else 0.18
				points.append(Vector2(0.5 + cos(angle) * r, 0.52 + sin(angle) * r))
			_line(points, true)
		"journal":
			_rrect(0.2, 0.1, 0.8, 0.9, 0.08)
			_line([Vector2(0.32, 0.1), Vector2(0.32, 0.9)])
			_line([Vector2(0.44, 0.32), Vector2(0.7, 0.32)])
			_line([Vector2(0.44, 0.46), Vector2(0.7, 0.46)])
		"tree":
			_circle(0.5, 0.18, 0.1)
			_circle(0.22, 0.78, 0.1)
			_circle(0.78, 0.78, 0.1)
			_circle(0.5, 0.78, 0.1)
			_line([Vector2(0.5, 0.28), Vector2(0.5, 0.68)])
			_line([Vector2(0.5, 0.46), Vector2(0.22, 0.68)])
			_line([Vector2(0.5, 0.46), Vector2(0.78, 0.68)])

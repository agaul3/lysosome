extends Control
## Stylised, obviously schematic imaging for radiology screens (not real
## studies): an axial CT of the head, a chest X-ray, an axial CT of the
## abdomen and an axial T2 MRI of the brain, as a 2 × 2 atlas drawn once.
## Reading-room and control-room monitors each show one tile.
const UI = preload("res://ui/style/ui_style.gd")
const PANEL := 512.0
const SIZE := Vector2(PANEL * 2, PANEL * 2)
var font: Font

func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	font = UI.font(500)

## UV rectangle of image `index` (0 CT head, 1 chest X-ray, 2 CT abdomen, 3 MRI brain).
static func tile_rect(index: int) -> Rect2:
	return Rect2((index % 2) * 0.5, floori(index / 2.0) * 0.5, 0.5, 0.5)

func _ellipse(center: Vector2, radii: Vector2, color: Color, rotation := 0.0) -> void:
	var points := PackedVector2Array()
	for step in range(48):
		var angle := TAU * step / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation))
	draw_colored_polygon(points, color)

func _label(origin: Vector2, lines: Array) -> void:
	for index in range(lines.size()):
		draw_string(font, origin + Vector2(14, 26 + index * 20), lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("c8d0d4"))
	draw_string(font, origin + Vector2(PANEL - 14, PANEL - 14), "SCHEMATIC · TRAINING", HORIZONTAL_ALIGNMENT_RIGHT, 300, 13, Color("7d8a90"))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color.BLACK)
	_ct_head(Vector2.ZERO)
	_chest(Vector2(PANEL, 0))
	_ct_abdomen(Vector2(0, PANEL))
	_mri(Vector2(PANEL, PANEL))

func _ct_head(origin: Vector2) -> void:
	var c := origin + Vector2(PANEL / 2.0, PANEL / 2.0 + 10)
	_ellipse(c, Vector2(176, 212), Color("5a5a5a"))
	_ellipse(c, Vector2(164, 200), Color("f2f2f2"))
	_ellipse(c, Vector2(150, 186), Color("7a7a7a"))
	_ellipse(c + Vector2(0, -6), Vector2(138, 172), Color("8c8c8c"))
	for side in [-1, 1]:
		_ellipse(c + Vector2(side * 22, -20), Vector2(14, 46), Color("303030"), side * 0.35)
	_ellipse(c + Vector2(0, 40), Vector2(8, 12), Color("303030"))
	draw_line(c + Vector2(0, -172), c + Vector2(0, 170), Color("6a6a6a"), 2.0)
	_label(origin, ["CT HEAD WITHOUT CONTRAST", "AXIAL  ·  12 / 28"])

func _chest(origin: Vector2) -> void:
	var c := origin + Vector2(PANEL / 2.0, PANEL / 2.0 + 20)
	_ellipse(c, Vector2(214, 206), Color("4a4a4a"))
	for side in [-1, 1]:
		_ellipse(c + Vector2(side * 92, -20), Vector2(78, 150), Color("161616"), side * -0.08)
		for rib in range(6):
			var curve := PackedVector2Array()
			for step in range(11):
				var t := step / 10.0
				curve.append(c + Vector2(side * (16 + t * 160), -150.0 + rib * 44.0 + t * t * 46.0))
			draw_polyline(curve, Color("8a8a8a"), 3.0)
		draw_line(c + Vector2(side * 20, -168), c + Vector2(side * 160, -150), Color("bdbdbd"), 6.0)
	_ellipse(c + Vector2(22, 70), Vector2(92, 84), Color("cfcfcf"))
	draw_rect(Rect2(c.x - 12, c.y - 200, 24, 320), Color("d8d8d8"))
	_ellipse(c + Vector2(0, 170), Vector2(210, 40), Color("9a9a9a"))
	_label(origin, ["CHEST  ·  PA", "PORTABLE"])

func _ct_abdomen(origin: Vector2) -> void:
	var c := origin + Vector2(PANEL / 2.0, PANEL / 2.0 + 10)
	_ellipse(c, Vector2(214, 160), Color("3a3a3a"))
	_ellipse(c, Vector2(202, 148), Color("777777"))
	_ellipse(c + Vector2(-70, -30), Vector2(90, 70), Color("9a9a9a"))
	_ellipse(c + Vector2(80, -40), Vector2(46, 36), Color("8a8a8a"))
	for side in [-1, 1]:
		_ellipse(c + Vector2(side * 76, 50), Vector2(30, 40), Color("a8a8a8"))
	_ellipse(c + Vector2(0, 88), Vector2(34, 32), Color("eeeeee"))
	_ellipse(c + Vector2(0, 88), Vector2(16, 14), Color("555555"))
	_ellipse(c + Vector2(-14, 44), Vector2(14, 14), Color("c8c8c8"))
	for index in range(5):
		_ellipse(c + Vector2(-20 + index * 30, -10 + (index % 2) * 30), Vector2(14, 12), Color("2c2c2c"))
	_label(origin, ["CT ABDOMEN / PELVIS", "AXIAL  ·  WITH CONTRAST"])

func _mri(origin: Vector2) -> void:
	var c := origin + Vector2(PANEL / 2.0, PANEL / 2.0 + 10)
	_ellipse(c, Vector2(170, 206), Color("3c3c3c"))
	_ellipse(c, Vector2(156, 192), Color("e6e6e6"))
	_ellipse(c, Vector2(146, 180), Color("6e6e6e"))
	for index in range(9):
		var angle := -1.2 + index * 0.3
		_ellipse(c + Vector2(cos(angle) * 120, sin(angle) * 150), Vector2(20, 10), Color("9a9a9a"), angle)
	for side in [-1, 1]:
		_ellipse(c + Vector2(side * 24, -16), Vector2(16, 50), Color("f0f0f0"), side * 0.3)
	_ellipse(c + Vector2(0, 110), Vector2(40, 30), Color("5e5e5e"))
	_label(origin, ["MRI BRAIN  ·  AXIAL T2", "SERIES 4  ·  IMAGE 14"])

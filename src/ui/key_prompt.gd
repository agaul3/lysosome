extends Control
## Original vector keycaps, drawn at native UI resolution. Compact and unboxed.
var key := "E":
	set(value):
		key = value
		_resize()
		queue_redraw()
const FONT = preload("res://assets/outfit_medium.tres") # Outfit 500, as in the UI style.
const CAP_HEIGHT := 22.0
const FONT_SIZE := 12

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_resize()

func _resize() -> void:
	if key == "WASD":
		custom_minimum_size = Vector2(52, 34)
	elif key.begins_with("⌘"):
		# Two caps: the Command key (drawn; the UI font has no ⌘ glyph) and the letter.
		custom_minimum_size = Vector2(CAP_HEIGHT * 2 + 3, CAP_HEIGHT + 2)
	else:
		var width := FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		custom_minimum_size = Vector2(maxf(CAP_HEIGHT, width + 12), CAP_HEIGHT + 2)
	size = custom_minimum_size

func _draw() -> void:
	if key == "WASD":
		for index in range(3):
			_cap(Rect2(0 + index * 18, 18, 16, 15), ["A", "S", "D"][index], 10)
		_cap(Rect2(18, 1, 16, 15), "W", 10)
	elif key.begins_with("⌘"):
		_cap(Rect2(0, 1, CAP_HEIGHT, CAP_HEIGHT), "", FONT_SIZE)
		_command_glyph(Vector2(CAP_HEIGHT / 2, 1 + CAP_HEIGHT / 2 - 1), 3.0)
		_cap(Rect2(CAP_HEIGHT + 3, 1, CAP_HEIGHT, CAP_HEIGHT), key.substr(1), FONT_SIZE)
	else:
		_cap(Rect2(Vector2(0, 1), Vector2(custom_minimum_size.x, CAP_HEIGHT)), key, FONT_SIZE)

func _cap(rect: Rect2, text: String, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e8eeec")
	style.border_color = Color("8ea5a7")
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(4)
	style.draw(get_canvas_item(), rect)
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(FONT, Vector2(rect.position.x + (rect.size.x - width) / 2, rect.position.y + rect.size.y / 2 + font_size * 0.3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("16272e"))

## The ⌘ symbol: a square whose sides run on into a loop at each corner.
func _command_glyph(center: Vector2, half: float) -> void:
	var ink := Color("16272e")
	var reach := half + 2.0
	for sign in [-1.0, 1.0]:
		draw_line(center + Vector2(-reach, sign * half), center + Vector2(reach, sign * half), ink, 1.2, true)
		draw_line(center + Vector2(sign * half, -reach), center + Vector2(sign * half, reach), ink, 1.2, true)
	for corner in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		# Each loop starts where one side ends and wraps round the outside to the other.
		var loop_center: Vector2 = center + corner * reach
		var start := atan2(-corner.y, 0.0)
		draw_arc(loop_center, 2.0, start, start + (1.5 * PI if corner.x * corner.y > 0 else -1.5 * PI), 12, ink, 1.2, true)

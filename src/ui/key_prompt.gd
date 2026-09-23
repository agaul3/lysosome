extends Control
## Original vector keycaps, drawn at native UI resolution.
var key := "E":
	set(value):
		key = value
		queue_redraw()
const FONT = preload("res://assets/outfit_medium.tres")

func _init() -> void:
	custom_minimum_size = Vector2(70, 42)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if key == "WASD":
		for index in range(3):
			_cap(Rect2(1 + index * 23, 22, 21, 19), ["A", "S", "D"][index], 12)
		_cap(Rect2(24, 1, 21, 19), "W", 12)
	else:
		_cap(Rect2(4, 5, 62, 31), key, 16)

func _cap(rect: Rect2, text: String, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e9f0eb")
	style.border_color = Color("87a4a5")
	style.set_border_width_all(1)
	style.border_width_bottom = 4
	style.set_corner_radius_all(5)
	style.draw(get_canvas_item(), rect)
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(FONT, Vector2(rect.position.x + (rect.size.x - width) / 2, rect.position.y + rect.size.y / 2 + font_size * 0.3 - 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("203b44"))

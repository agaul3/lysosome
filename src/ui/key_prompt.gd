extends Control
## Original vector keycaps, drawn at native UI resolution. Compact and unboxed.
var key := "E":
	set(value):
		key = value
		_resize()
		queue_redraw()
const FONT = preload("res://assets/outfit_medium.tres")
const CAP_HEIGHT := 22.0
const FONT_SIZE := 12

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_resize()

func _resize() -> void:
	if key == "WASD":
		custom_minimum_size = Vector2(52, 34)
	else:
		var width := FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		custom_minimum_size = Vector2(maxf(CAP_HEIGHT, width + 12), CAP_HEIGHT + 2)
	size = custom_minimum_size

func _draw() -> void:
	if key == "WASD":
		for index in range(3):
			_cap(Rect2(0 + index * 18, 18, 16, 15), ["A", "S", "D"][index], 10)
		_cap(Rect2(18, 1, 16, 15), "W", 10)
	else:
		_cap(Rect2(Vector2(0, 1), Vector2(custom_minimum_size.x, CAP_HEIGHT)), key, FONT_SIZE)

func _cap(rect: Rect2, text: String, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e9f0eb")
	style.border_color = Color("87a4a5")
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(4)
	style.draw(get_canvas_item(), rect)
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(FONT, Vector2(rect.position.x + (rect.size.x - width) / 2, rect.position.y + rect.size.y / 2 + font_size * 0.3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("203b44"))

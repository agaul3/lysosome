extends Control
## Pixel-art icon for a clothing item, drawn in the item's own colours on a
## 12×12 grid so it matches the characters' blocky skins. An empty icon shows
## a faint outline of what the slot holds.
const Clothing = preload("res://data/clothing.gd")
var item_id := "":
	set(value):
		item_id = value
		queue_redraw()
var slot := "top":
	set(value):
		slot = value
		queue_redraw()
var dim := false:
	set(value):
		dim = value
		queue_redraw()

func _init(icon_size := 36.0) -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _draw() -> void:
	var item := Clothing.item(item_id)
	var kind: String = item.get("kind", "")
	var colors: Array = item.get("colors", [])
	var ghost := Color(1, 1, 1, 0.12)
	var main: Color = colors[0] if colors.size() > 0 else ghost
	var trim: Color = colors[1] if colors.size() > 1 else (main.darkened(0.25) if not item.is_empty() else ghost)
	var accent: Color = colors[2] if colors.size() > 2 else (main.lightened(0.3) if not item.is_empty() else ghost)
	if dim:
		main = Color(main, 0.35)
		trim = Color(trim, 0.35)
		accent = Color(accent, 0.35)
	var outline := Color(0, 0, 0, 0.35) if not item.is_empty() else Color(1, 1, 1, 0.08)
	var shape: String = slot if item.is_empty() else String(item.slot)
	match shape:
		"outerwear":
			_blocks(outline, [[0.6, 2.6, 3, 8.4], [8.4, 2.6, 3, 8.4], [2.6, 1.6, 6.8, 10]])
			_blocks(main, [[1, 3, 2.2, 7.6], [8.8, 3, 2.2, 7.6], [3, 2, 6, 9.4]])
			_blocks(trim, [[1, 9, 2.2, 1.4], [8.8, 9, 2.2, 1.4], [4, 1.6, 4, 1.4]])
			_blocks(trim if kind != "fleece" else accent, [[5.5, 3, 1, 8.4]])
			if kind == "fleece":
				_blocks(trim, [[6.8, 4, 1.8, 2]])
		"top":
			_blocks(outline, [[0.6, 2.6, 3.4, 4], [8, 2.6, 3.4, 4], [2.6, 2.6, 6.8, 9]])
			_blocks(main, [[1, 3, 3, 3.2], [8, 3, 3, 3.2], [3, 3, 6, 8.2]])
			_blocks(trim, [[3, 10, 6, 1.2]])
			_blocks(Color(0, 0, 0, 0.3), [[5, 3, 2, 1.2]])
			if kind == "oxford":
				_blocks(trim, [[5.4, 4, 1.2, 5]])
		"bottom":
			_blocks(outline, [[2.6, 1.6, 6.8, 10]])
			_blocks(main, [[3, 3, 2.6, 8.2], [6.4, 3, 2.6, 8.2]])
			_blocks(trim if kind != "jeans" else accent, [[3, 2, 6, 1.4]])
			if kind == "shorts":
				_blocks(Color(0, 0, 0, 0.5), [[3, 7, 6, 4.2]])
		"shoes":
			for x in [0.6, 6.2]:
				_blocks(outline, [[x, 5.6, 5.4, 5]])
				_blocks(main, [[x + 1, 6, 3.8, 3], [x + 0.4, 7.6, 1.2, 1.4]])
				_blocks(trim, [[x + 0.4, 9, 4.6, 1.2]])
		"head":
			_blocks(outline, [[1.6, 2.6, 8.8, 8]])
			_blocks(main, [[2, 3, 8, 5.4]])
			if kind == "cap":
				_blocks(trim, [[1, 8, 6, 1.4]])
			else:
				_blocks(trim, [[2, 8, 8, 2]])
			if kind == "scrub_cap":
				_blocks(trim, [[3, 4, 1, 1], [6, 5, 1, 1], [8, 3.6, 1, 1]])
		"eyewear":
			var lens := trim if kind in ["sunglasses", "aviators"] else Color(0.8, 0.9, 1.0, 0.25 if not dim else 0.1)
			for x in [0.8, 6.6]:
				_blocks(main, [[x, 4.4, 4.6, 3.8]])
				_blocks(lens, [[x + 0.8, 5.2, 3, 2.2]])
			_blocks(main, [[5.2, 5, 1.6, 0.8]])
		"neck":
			if kind == "stethoscope":
				_blocks(main, [[2.6, 1, 1, 6], [8.4, 1, 1, 6], [2.6, 6.4, 6.8, 1], [5.5, 7, 1, 2.4]])
				_blocks(trim, [[4.6, 9, 2.8, 2.4]])
			elif kind == "scarf":
				_blocks(main, [[2, 3, 8, 3], [6, 6, 2.4, 5]])
				_blocks(trim, [[4, 3, 1, 3], [7, 3, 1, 3], [6, 8, 2.4, 0.8]])
			else:
				_blocks(main, [[3, 1, 1, 3], [4, 3.5, 1, 2], [8, 1, 1, 3], [7, 3.5, 1, 2], [5, 5, 2, 1.4]])
				_blocks(trim, [[4, 6.4, 4, 4.6]])
				_blocks(accent, [[4.6, 7, 1.4, 1.6]])
		"back":
			_blocks(outline, [[1.6, 1.6, 8.8, 10]])
			_blocks(main, [[2, 2, 8, 9.4]])
			_blocks(trim, [[3, 6, 6, 4.4], [5, 1, 2, 1.2]])
			_blocks(accent, [[3, 5.2, 6, 0.8]])

func _blocks(color: Color, rects: Array) -> void:
	var unit := minf(size.x, size.y) / 12.0
	var offset := (size - Vector2.ONE * unit * 12.0) / 2.0
	for r in rects:
		draw_rect(Rect2(offset + Vector2(r[0], r[1]) * unit, Vector2(r[2], r[3]) * unit), color)

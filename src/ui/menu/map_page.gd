extends "res://ui/menu/menu_page.gd"
## Campus Map (representative): a plan view of the campus drawn from
## data/campus_map.gd, with the student's position (live on campus, or the
## building they are in), today's class destination and the entrances.
const MapData = preload("res://data/campus_map.gd")
const MAP_SIZE := Vector2(584, 340)
var hud: CanvasLayer
var canvas: Control
var time := 0.0

func _init(owner_hud: CanvasLayer = null) -> void:
	super._init()
	hud = owner_hud

func _ready() -> void:
	refresh()

func refresh() -> void:
	clear()
	var frame := UI.card(Vector4(8, 8, 8, 8), Color(UI.INK, 0.6))
	content.add_child(frame)
	canvas = Control.new()
	canvas.custom_minimum_size = MAP_SIZE
	canvas.draw.connect(_draw_map)
	frame.add_child(canvas)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 18)
	legend.add_child(_legend_item(UI.ACCENT, "You are here"))
	legend.add_child(_legend_item(UI.REWARD, "Today's class"))
	legend.add_child(_legend_item(UI.TEXT, "Entrance"))
	var where := UI.label(_where_text(), UI.SIZE_LABEL, UI.TEXT_MUTED, 500)
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	legend.add_child(where)
	content.add_child(legend)

func _legend_item(color: Color, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var dot := Control.new()
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.draw.connect(func() -> void: dot.draw_circle(Vector2(5, 5), 4.5, color))
	row.add_child(dot)
	row.add_child(UI.label(text, UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	return row

func _where_text() -> String:
	var scene := AppState.location_key()
	var names := {"dorm": "In your room, Cedar Residence", "campus": "Outdoors, Student Commons", "lecture_building": "Inside the Learning Center", "lecture_hall": "In Lecture Hall A"}
	return names.get(scene, "")

func _process(delta: float) -> void:
	if is_visible_in_tree() and is_instance_valid(canvas):
		time += delta
		canvas.queue_redraw()

func _to_map(x: float, z: float) -> Vector2:
	var b := MapData.BOUNDS
	var scale := minf(MAP_SIZE.x / b.size.x, MAP_SIZE.y / b.size.y)
	var offset := (MAP_SIZE - b.size * scale) / 2.0
	return offset + Vector2((x - b.position.x) * scale, (z - b.position.y) * scale)

func _rect(values: Array) -> Rect2:
	var a := _to_map(values[0], values[1])
	var b := _to_map(values[2], values[3])
	return Rect2(a, b - a)

func _draw_map() -> void:
	var font := UI.font(600)
	canvas.draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("16261f"))
	canvas.draw_rect(Rect2(_to_map(MapData.BOUNDS.position.x, MapData.BOUNDS.position.y), MapData.BOUNDS.size * minf(MAP_SIZE.x / MapData.BOUNDS.size.x, MAP_SIZE.y / MapData.BOUNDS.size.y)), Color("1c3329"))
	for lawn in MapData.LAWNS:
		canvas.draw_rect(_rect(lawn), Color("2f5a3f"))
	for area in MapData.PLAZAS + MapData.PATHS:
		canvas.draw_rect(_rect(area), Color("3c5157"))
	canvas.draw_rect(_rect(MapData.PARKING), Color("2a373c"))
	var plaza := _to_map(MapData.PLAZA_CENTER.x, MapData.PLAZA_CENTER.y)
	var scale := _to_map(1, 0).x - _to_map(0, 0).x
	canvas.draw_circle(plaza, MapData.PLAZA_RADIUS * scale, Color("46595e"))
	canvas.draw_circle(plaza, 1.9 * scale, Color("2f5a3f"))
	var parking := _rect(MapData.PARKING)
	canvas.draw_string(UI.font(500), parking.get_center() + Vector2(-22, 4), "Parking", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.TEXT_FAINT)
	canvas.draw_string(UI.font(500), _to_map(-11.5, 7.2), "The Quad", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(UI.TEXT, 0.55))
	var destination := "" if AcademicSession.lectures_completed.has("pharmacodynamics_01") else "learning_center"
	for id in MapData.BUILDINGS:
		var entry: Array = MapData.BUILDINGS[id]
		var rect := _rect([entry[1], entry[2], entry[3], entry[4]])
		var style := UI.box(UI.SURFACE_HOVER, 4, UI.REWARD if id == destination else UI.LINE, 2 if id == destination else 1)
		style.draw(canvas.get_canvas_item(), rect)
		var name: String = entry[0]
		var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		canvas.draw_string(font, rect.get_center() + Vector2(-width / 2.0, 4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.TEXT if id == destination else UI.TEXT_MUTED)
		if id == destination:
			canvas.draw_string(UI.font(500), rect.get_center() + Vector2(-38, 20), "Lecture Hall A · 8:00", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.REWARD)
	for entrance in MapData.ENTRANCES:
		var point := _to_map(entrance[1], entrance[2])
		canvas.draw_circle(point, 3.5, UI.TEXT)
	canvas.draw_rect(Rect2(_to_map(MapData.DIRECTORY.x, MapData.DIRECTORY.y) - Vector2(3, 3), Vector2(6, 6)), UI.INFO)
	# North arrow.
	var north := Vector2(MAP_SIZE.x - 22, 22)
	canvas.draw_colored_polygon(PackedVector2Array([north + Vector2(0, -10), north + Vector2(6, 6), north + Vector2(0, 2), north + Vector2(-6, 6)]), UI.TEXT_MUTED)
	canvas.draw_string(font, north + Vector2(-4, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.TEXT_MUTED)
	# You are here: live on campus, otherwise the building you are in.
	var here := Vector2.ZERO
	var scene := AppState.location_key()
	if scene == "campus" and hud and is_instance_valid(hud.player):
		here = _to_map(hud.player.global_position.x, hud.player.global_position.z)
	else:
		var building := MapData.building_for_scene(scene)
		if building.is_empty():
			return
		var entry: Array = MapData.BUILDINGS[building]
		here = _rect([entry[1], entry[2], entry[3], entry[4]]).get_center() + Vector2(0, -24)
	var pulse := fposmod(time, 1.6) / 1.6
	canvas.draw_circle(here, 6 + 10 * pulse, Color(UI.ACCENT, 0.35 * (1.0 - pulse)))
	canvas.draw_circle(here, 6, UI.ACCENT)
	canvas.draw_circle(here, 2.5, UI.INK)

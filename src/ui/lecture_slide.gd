extends Control
## One projected lecture slide: heading, progressively revealed bullets and a
## diagram. Drawn into a SubViewport and shown on the hall's screen. Curves use
## the real Hill equation on a log-concentration axis.
const DoseResponse = preload("res://education/models/dose_response.gd")
const FONT = preload("res://assets/outfit_medium.tres")
const BACKGROUND := Color("1d2a33")
const INK := Color("eef2ef")
const MUTED := Color("9fb3b3")
const ACCENT := Color("e98a4f") # Echoes the hall's seat colour.
const SECOND := Color("6fc3c0")
const THIRD := Color("c7a4e0")

var slide: Dictionary = {}
var revealed := 0
var heading: Label
var subheading: Label
var bullet_box: VBoxContainer
var diagram: Control

func _ready() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var accent_bar := ColorRect.new()
	accent_bar.color = ACCENT
	accent_bar.position = Vector2(60, 58)
	accent_bar.size = Vector2(8, 64)
	add_child(accent_bar)
	heading = _label(54, INK)
	heading.position = Vector2(88, 48)
	heading.size = Vector2(1060, 80)
	add_child(heading)
	subheading = _label(34, MUTED)
	subheading.position = Vector2(90, 140)
	add_child(subheading)
	bullet_box = VBoxContainer.new()
	bullet_box.position = Vector2(72, 160)
	bullet_box.size = Vector2(560, 400)
	bullet_box.add_theme_constant_override("separation", 18)
	add_child(bullet_box)
	diagram = Control.new()
	diagram.position = Vector2(660, 150)
	diagram.size = Vector2(500, 410)
	diagram.draw.connect(_draw_diagram)
	add_child(diagram)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func show_slide(data: Dictionary, reveal_count: int) -> void:
	slide = data
	revealed = reveal_count
	heading.text = data.get("heading", "")
	subheading.text = data.get("subheading", "")
	subheading.visible = not subheading.text.is_empty()
	for child in bullet_box.get_children():
		bullet_box.remove_child(child) # Detach now so reveal counts never see stale rows.
		child.queue_free()
	var bullets: Array = data.get("bullets", [])
	for index in range(bullets.size()):
		var row := _label(30, INK)
		row.text = "•  " + bullets[index]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size.x = 560
		# Unrevealed bullets keep their space so the slide does not reflow.
		row.modulate.a = 1.0 if index < reveal_count else 0.0
		bullet_box.add_child(row)
	var wide := bullets.is_empty()
	diagram.position = Vector2(300, 200) if wide else Vector2(660, 150)
	diagram.size = Vector2(600, 370) if wide else Vector2(500, 410)
	diagram.queue_redraw()

func set_revealed(count: int) -> void:
	revealed = count
	var rows := bullet_box.get_children()
	for index in range(rows.size()):
		rows[index].modulate.a = 1.0 if index < count else 0.0

# --- Diagrams -----------------------------------------------------------------

func _draw_diagram() -> void:
	match slide.get("diagram", ""):
		"title": _title_art()
		"receptor_binding": _receptor_art(false)
		"antagonist_block": _receptor_art(true)
		"full_partial": _curves([[100.0, 1.0, ACCENT, "Full agonist"], [55.0, 1.0, SECOND, "Partial agonist"]])
		"competitive_shift": _curves([[100.0, 1.0, ACCENT, "Agonist"], [100.0, DoseResponse.competitive_ec50(1.0, 9.0, 1.0), SECOND, "+ competitive antagonist"]], true)
		"noncompetitive": _curves([[100.0, 1.0, ACCENT, "Agonist"], [DoseResponse.noncompetitive_emax(100.0, 0.45), 1.0, SECOND, "+ noncompetitive antagonist"]])
		"potency": _curves([[100.0, 0.3, ACCENT, "Drug A (more potent)"], [100.0, 8.0, SECOND, "Drug B"]], false, true)
		"efficacy": _curves([[100.0, 3.0, ACCENT, "Drug A (more efficacious)"], [60.0, 0.4, SECOND, "Drug B (more potent)"]])
		"graded_quantal": _quantal()
		"clinical_opioid": _curves([[100.0, 1.0, ACCENT, "Full μ agonist"], [45.0, 0.3, SECOND, "Buprenorphine (partial)"]])
		"summary": _curves([[100.0, 1.0, ACCENT, "Agonist"], [100.0, 10.0, SECOND, "Competitive"], [55.0, 1.0, THIRD, "Noncompetitive"]])

func _plot_rect() -> Rect2:
	return Rect2(Vector2(70, 20), diagram.size - Vector2(90, 110))

## Log10 concentration from -2 to 3 across the plot width.
func _to_screen(log_c: float, value: float, rect: Rect2) -> Vector2:
	var x := rect.position.x + (log_c + 2.0) / 5.0 * rect.size.x
	var y := rect.end.y - value / 100.0 * rect.size.y
	return Vector2(x, y)

func _axes(rect: Rect2, x_label := "log [drug]", y_label := "Response (% max)") -> void:
	diagram.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), MUTED, 3.0)
	diagram.draw_line(Vector2(rect.position.x, rect.end.y), rect.end, MUTED, 3.0)
	diagram.draw_string(FONT, Vector2(rect.position.x + 6, rect.end.y + 38), x_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MUTED)
	diagram.draw_set_transform(Vector2(rect.position.x - 22, rect.end.y), -PI / 2)
	diagram.draw_string(FONT, Vector2(0, 0), y_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MUTED)
	diagram.draw_set_transform(Vector2.ZERO)

## curves: [emax, ec50, color, label]; marks EC50 for each curve.
func _curves(curves: Array, arrow := false, mark_ec50 := false) -> void:
	var rect := _plot_rect()
	_axes(rect)
	var legend_y := rect.end.y + 70
	for index in range(curves.size()):
		var curve: Array = curves[index]
		var points := PackedVector2Array()
		for step in range(121):
			var log_c := -2.0 + step / 120.0 * 5.0
			points.append(_to_screen(log_c, DoseResponse.response(pow(10.0, log_c), curve[0], curve[1]), rect))
		diagram.draw_polyline(points, curve[2], 5.0, true)
		if mark_ec50:
			var half := _to_screen(log(curve[1]) / log(10.0), curve[0] / 2.0, rect)
			diagram.draw_dashed_line(half, Vector2(half.x, rect.end.y), curve[2], 2.0, 8.0)
			diagram.draw_circle(half, 7.0, curve[2])
		var legend_x := 10.0 + (index % 2) * 250.0
		var row_y := legend_y + int(index / 2) * 30
		diagram.draw_rect(Rect2(legend_x, row_y - 14, 22, 8), curve[2])
		diagram.draw_string(FONT, Vector2(legend_x + 32, row_y - 3), curve[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	if arrow:
		var from := _to_screen(-0.3, 50.0, rect)
		var to := _to_screen(0.7, 50.0, rect)
		diagram.draw_line(from, to, INK, 3.0)
		diagram.draw_colored_polygon(PackedVector2Array([to + Vector2(4, 0), to + Vector2(-14, -9), to + Vector2(-14, 9)]), INK)

func _quantal() -> void:
	var rect := _plot_rect()
	_axes(rect, "log dose", "% of population responding")
	var curves := [[1.0, SECOND, "Therapeutic effect", "ED50"], [60.0, ACCENT, "Toxic effect", "TD50"]]
	for index in range(curves.size()):
		var curve: Array = curves[index]
		var points := PackedVector2Array()
		for step in range(121):
			var log_c := -2.0 + step / 120.0 * 5.0
			# Quantal curves are cumulative population fractions; a steeper Hill slope reads clearly.
			points.append(_to_screen(log_c, DoseResponse.response(pow(10.0, log_c), 100.0, curve[0], 2.2), rect))
		diagram.draw_polyline(points, curve[1], 5.0, true)
		var half := _to_screen(log(curve[0]) / log(10.0), 50.0, rect)
		diagram.draw_dashed_line(half, Vector2(half.x, rect.end.y), curve[1], 2.0, 8.0)
		# Label beside the dashed marker, inside the plot, clear of the axis title.
		diagram.draw_string(FONT, Vector2(half.x + 8, rect.end.y - 12), curve[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, curve[1])
		diagram.draw_rect(Rect2(10 + index * 250, rect.end.y + 62, 22, 8), curve[1])
		diagram.draw_string(FONT, Vector2(42 + index * 250, rect.end.y + 73), curve[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	diagram.draw_string(FONT, Vector2(10, rect.end.y + 100), "Therapeutic index = TD50 / ED50 = 60", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)

## Membrane with a receptor; agonists (circles) bind, or an antagonist (square) occupies it.
func _receptor_art(blocked: bool) -> void:
	var size := diagram.size
	var membrane_y := size.y * 0.62
	diagram.draw_rect(Rect2(0, membrane_y, size.x, 34), Color("3b4f58"))
	diagram.draw_rect(Rect2(0, membrane_y + 34, size.x, 4), Color("5d7580"))
	var center := Vector2(size.x * 0.5, membrane_y)
	var receptor := Color("8fb8c9")
	# U-shaped receptor spanning the membrane with a binding pocket on top.
	diagram.draw_rect(Rect2(center.x - 70, center.y - 70, 36, 150), receptor)
	diagram.draw_rect(Rect2(center.x + 34, center.y - 70, 36, 150), receptor)
	diagram.draw_rect(Rect2(center.x - 70, center.y + 44, 140, 36), receptor)
	if blocked:
		diagram.draw_rect(Rect2(center.x - 30, center.y - 60, 60, 60), THIRD)
		diagram.draw_string(FONT, Vector2(center.x - 70, center.y - 90), "Antagonist: bound, no signal", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, THIRD)
		diagram.draw_circle(Vector2(center.x + 140, center.y - 150), 26, ACCENT)
		diagram.draw_string(FONT, Vector2(center.x + 90, center.y - 190), "Agonist blocked", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ACCENT)
	else:
		diagram.draw_circle(Vector2(center.x, center.y - 30), 28, ACCENT)
		diagram.draw_string(FONT, Vector2(center.x - 60, center.y - 80), "Ligand bound", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ACCENT)
		for offset in [Vector2(-170, -170), Vector2(150, -120), Vector2(-120, -250)]:
			diagram.draw_circle(center + offset, 22, ACCENT.darkened(0.2))
	diagram.draw_string(FONT, Vector2(12, membrane_y + 76), "Cell membrane", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MUTED)

func _title_art() -> void:
	var rect := Rect2(Vector2(40, 30), Vector2(diagram.size.x - 80, diagram.size.y - 90))
	var points := PackedVector2Array()
	for step in range(121):
		var log_c := -2.0 + step / 120.0 * 5.0
		points.append(_to_screen(log_c, DoseResponse.response(pow(10.0, log_c), 100.0, 1.0), rect))
	diagram.draw_polyline(points, ACCENT, 6.0, true)
	diagram.draw_string(FONT, Vector2(rect.position.x, rect.end.y + 50), "Lecture Hall A  ·  First-year Pharmacology", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, MUTED)

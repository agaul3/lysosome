extends Control
## A deliberately small electronic health record, drawn onto the workroom
## monitor during the shadowing session: a patient banner, a chart menu and one
## panel at a time (summary, vitals, results, notes). It is read-only and
## shows a single fictional patient; the session points at parts of it while
## the physician explains them. Not a full EHR: nothing can be ordered or typed.
const UI = preload("res://ui/style/ui_style.gd")
const SIZE := Vector2(1280, 800)
const VIEWS := ["summary", "vitals", "results", "notes"]
const BAR := Color("1f3a4a")
const PAPER := Color("f6f8f9")
const BANNER := Color("e3eef2")
const INK := Color("1d2b33")
const MUTED := Color("5d7079")
const RULE := Color("d3dde1")
const FLAG := Color("c2412d")
const FOCUS := Color("2f8f82")
const NAV := ["Summary", "Vitals", "Results", "Notes", "Orders", "Medications"]
const TIMES := ["9/20 06:00", "9/20 14:00", "9/20 22:00", "9/21 02:00", "9/21 06:00"]
const VITALS := [
	["Temp (°C)", ["38.4", "37.9", "37.2", "36.9", "36.8"], [true, false, false, false, false]],
	["Heart rate", ["102", "94", "86", "82", "80"], [true, false, false, false, false]],
	["Blood pressure", ["118/72", "121/74", "124/76", "122/74", "126/78"], [false, false, false, false, false]],
	["Resp. rate", ["24", "20", "18", "16", "16"], [true, false, false, false, false]],
	["SpO₂", ["92% 2 L", "94% 2 L", "95% 1 L", "95% RA", "96% RA"], [false, false, false, false, false]],
]
const RESULTS := [
	["WBC (×10⁹/L)", "4.0–11.0", ["14.2", "12.6", "11.2"], true],
	["CRP (mg/L)", "< 5", ["96", "71", "48"], true],
	["Hemoglobin (g/dL)", "13.5–17.5", ["13.9", "13.6", "13.8"], false],
	["Platelets (×10⁹/L)", "150–400", ["241", "238", "252"], false],
	["Sodium (mmol/L)", "135–145", ["136", "136", "137"], false],
	["Creatinine (mg/dL)", "0.7–1.3", ["1.1", "1.0", "1.0"], false],
]
## Which view is showing, and which region is outlined ("" for none).
var view := "summary"
var focus := ""
var font: Font
var bold: Font

func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	font = UI.font(500)
	bold = UI.font(700)

## "banner" outlines the banner over the summary; the others open their panel.
func show_view(name: String) -> void:
	focus = name
	view = name if name in VIEWS else "summary"
	queue_redraw()

func reset() -> void:
	view = "summary"
	focus = ""
	queue_redraw()

func _text(position: Vector2, text: String, size_px: int, color := INK, heavy := false, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(bold if heavy else font, position, text, align, width, size_px, color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), PAPER)
	# Application bar.
	draw_rect(Rect2(0, 0, SIZE.x, 50), BAR)
	_text(Vector2(24, 34), "UH Chart", 24, Color.WHITE, true)
	_text(Vector2(140, 34), "Training environment", 20, Color("9fc3cf"))
	_text(Vector2(SIZE.x - 24, 34), "Medical student · view only", 20, Color("cfe2e8"), false, 460, HORIZONTAL_ALIGNMENT_RIGHT)
	_banner(Rect2(0, 50, SIZE.x, 104))
	_nav(Rect2(0, 154, 210, SIZE.y - 154 - 40))
	var panel := Rect2(226, 170, SIZE.x - 226 - 18, SIZE.y - 170 - 56)
	match view:
		"vitals": _vitals(panel)
		"results": _results(panel)
		"notes": _notes(panel)
		_: _summary(panel)
	# Footer: this is a training record.
	draw_rect(Rect2(0, SIZE.y - 40, SIZE.x, 40), Color("e9eef0"))
	_text(Vector2(24, SIZE.y - 13), "Fictional patient for training · every chart you open is logged", 18, MUTED)
	if focus == "banner":
		_outline(Rect2(6, 56, SIZE.x - 12, 92))
	elif focus in ["vitals", "results", "notes"]:
		_outline(panel.grow(8))

func _outline(rect: Rect2) -> void:
	draw_rect(rect, Color(FOCUS, 0.07))
	draw_rect(rect, FOCUS, false, 4.0)

func _banner(rect: Rect2) -> void:
	draw_rect(rect, BANNER)
	draw_line(Vector2(0, rect.end.y), Vector2(SIZE.x, rect.end.y), RULE, 2.0)
	# Avatar circle with initials.
	draw_circle(rect.position + Vector2(56, 52), 32, Color("8aa9b6"))
	_text(rect.position + Vector2(24, 62), "DR", 26, Color.WHITE, true, 64, HORIZONTAL_ALIGNMENT_CENTER)
	_text(rect.position + Vector2(104, 44), "REYES, Daniel", 32, INK, true)
	_text(rect.position + Vector2(104, 80), "67 y · Male · MRN DEMO-0412", 21, MUTED)
	var fields := [["Location", "4 West · Room 412"], ["Allergies", "None known"], ["Code status", "Full code"], ["Attending", "Dr. M. Okafor"]]
	for index in range(fields.size()):
		var x := 480.0 + index * 196.0
		_text(Vector2(x, rect.position.y + 40), fields[index][0].to_upper(), 16, MUTED, true)
		_text(Vector2(x, rect.position.y + 72), fields[index][1], 19, INK, false, 186)

func _nav(rect: Rect2) -> void:
	draw_rect(rect, Color("edf2f4"))
	var active: int = {"summary": 0, "vitals": 1, "results": 2, "notes": 3}.get(view, 0)
	for index in range(NAV.size()):
		var row := Rect2(rect.position.x, rect.position.y + 14 + index * 54, rect.size.x, 48)
		if index == active:
			draw_rect(row, Color("d5e6eb"))
			draw_rect(Rect2(row.position, Vector2(6, row.size.y)), FOCUS)
		_text(row.position + Vector2(26, 32), NAV[index], 22, INK if index == active else MUTED, index == active)

func _heading(rect: Rect2, title: String, note := "") -> void:
	_text(rect.position + Vector2(0, 30), title, 28, INK, true)
	if not note.is_empty():
		_text(Vector2(rect.end.x, rect.position.y + 30), note, 18, MUTED, false, 520, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(rect.position + Vector2(0, 46), Vector2(rect.end.x, rect.position.y + 46), RULE, 2.0)

func _summary(rect: Rect2) -> void:
	_heading(rect, "Summary", "Hospital day 3 · admitted 9/19")
	_text(rect.position + Vector2(0, 90), "Community-acquired pneumonia, right lower lobe", 24, INK, true)
	_text(rect.position + Vector2(0, 126), "Improving on antibiotics. Afebrile for 24 hours. Room air since 02:00.", 21, MUTED)
	var tiles := [["Temp", "36.8 °C"], ["Heart rate", "80"], ["BP", "126/78"], ["SpO₂", "96% RA"]]
	for index in range(tiles.size()):
		var tile := Rect2(rect.position.x + index * 250, rect.position.y + 160, 232, 110)
		draw_rect(tile, Color.WHITE)
		draw_rect(tile, RULE, false, 2.0)
		_text(tile.position + Vector2(18, 38), tiles[index][0], 19, MUTED)
		_text(tile.position + Vector2(18, 86), tiles[index][1], 32, INK, true)
	_text(rect.position + Vector2(0, 330), "Care team", 21, MUTED, true)
	_text(rect.position + Vector2(0, 366), "Dr. Okafor (attending) · Dr. Martin (resident) · Priya S., RN (charge)", 21, INK)
	_text(rect.position + Vector2(0, 420), "Plan today", 21, MUTED, true)
	_text(rect.position + Vector2(0, 456), "Walk twice with nursing · continue antibiotics · discharge planning", 21, INK)

func _vitals(rect: Rect2) -> void:
	_heading(rect, "Vital signs", "Last 24 hours")
	var label_w := 230.0
	var col_w := (rect.size.x - label_w) / TIMES.size()
	for column in range(TIMES.size()):
		_text(Vector2(rect.position.x + label_w + column * col_w, rect.position.y + 84), TIMES[column], 18, MUTED, true, col_w - 8)
	for row in range(VITALS.size()):
		var y := rect.position.y + 128 + row * 50
		if row % 2 == 0:
			draw_rect(Rect2(rect.position.x - 8, y - 32, rect.size.x + 8, 48), Color("eef3f5"))
		_text(Vector2(rect.position.x, y), VITALS[row][0], 21, INK, true)
		for column in range(TIMES.size()):
			var abnormal: bool = VITALS[row][2][column]
			_text(Vector2(rect.position.x + label_w + column * col_w, y), VITALS[row][1][column], 21, FLAG if abnormal else INK, abnormal)
	# Temperature trend.
	var chart := Rect2(rect.position.x + label_w, rect.position.y + 395, rect.size.x - label_w - 20, 118)
	_text(Vector2(rect.position.x, chart.position.y + 30), "Temperature", 19, MUTED, true)
	_text(Vector2(rect.position.x, chart.position.y + 58), "trend", 19, MUTED)
	draw_rect(chart, Color.WHITE)
	var fever_y := chart.position.y + chart.size.y * (1.0 - (38.0 - 36.0) / 3.0)
	draw_dashed_line(Vector2(chart.position.x, fever_y), Vector2(chart.end.x, fever_y), Color(FLAG, 0.5), 2.0, 10.0)
	var points := PackedVector2Array()
	for column in range(TIMES.size()):
		var value := float(VITALS[0][1][column])
		points.append(Vector2(chart.position.x + (column + 0.5) * chart.size.x / TIMES.size(), chart.position.y + chart.size.y * (1.0 - (value - 36.0) / 3.0)))
	draw_polyline(points, FOCUS, 4.0, true)
	for point in points:
		draw_circle(point, 7, FOCUS)

func _results(rect: Rect2) -> void:
	_heading(rect, "Results", "H = above the reference range")
	var columns := [0.0, 300.0, 470.0, 610.0, 750.0]
	var header := ["Test", "Reference", "9/19", "9/20", "9/21"]
	for index in range(header.size()):
		_text(Vector2(rect.position.x + columns[index], rect.position.y + 84), header[index], 18, MUTED, true)
	for row in range(RESULTS.size()):
		var y := rect.position.y + 128 + row * 46
		if row % 2 == 0:
			draw_rect(Rect2(rect.position.x - 8, y - 30, rect.size.x + 8, 44), Color("eef3f5"))
		var entry: Array = RESULTS[row]
		_text(Vector2(rect.position.x, y), entry[0], 20, INK, true)
		_text(Vector2(rect.position.x + columns[1], y), entry[1], 19, MUTED)
		for day in range(3):
			var flagged: bool = entry[3]
			_text(Vector2(rect.position.x + columns[2 + day], y), entry[2][day] + (" H" if flagged else ""), 20, FLAG if flagged else INK, flagged)
	var foot := rect.position.y + 128 + RESULTS.size() * 46 + 12
	_text(Vector2(rect.position.x, foot), "Blood cultures (9/19): no growth at 48 hours", 20, INK)
	_text(Vector2(rect.position.x, foot + 36), "Chest X-ray (9/19): right lower lobe consolidation", 20, INK)

func _notes(rect: Rect2) -> void:
	_heading(rect, "Notes", "Newest first")
	var notes := [
		["Nursing note · 9/21 05:40 · Priya S., RN", "Afebrile overnight and slept well. Walked to the bathroom with standby help. SpO₂ 95–96% on room air since 02:00. Eating breakfast; no new concerns."],
		["Progress note · 9/20 16:10 · Dr. L. Martin", "Pneumonia improving: fever settling, oxygen weaned to 1 L. Continue antibiotics. Walk with nursing. Discuss discharge if stable on room air."],
	]
	var y := rect.position.y + 86
	for note in notes:
		_text(Vector2(rect.position.x, y), note[0], 20, FOCUS, true)
		var lines := _wrap(note[1], rect.size.x - 10, 21)
		for index in range(lines.size()):
			_text(Vector2(rect.position.x, y + 34 + index * 30), lines[index], 21, INK)
		y += 58 + lines.size() * 30
	_text(Vector2(rect.position.x, y + 10), "Active orders", 20, MUTED, true)
	_text(Vector2(rect.position.x, y + 44), "Vital signs every 4 h · Walk twice daily with nursing · Regular diet · Antibiotics per medication record", 19, INK, false, rect.size.x)

func _wrap(text: String, width: float, size_px: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in text.split(" "):
		var candidate := word if line.is_empty() else line + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > width and not line.is_empty():
			lines.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		lines.append(line)
	return lines

extends RefCounted
## Data-driven figures for lecture slides and exam questions, drawn with a
## Control's draw calls into a rectangle. A figure is a dictionary with a
## "type" (see validate()); everything else comes from the data, so new
## lectures need no drawing code.
##
##   curves  axes and series: sampled from a named function with parameters
##           (so curves are quantitatively right) or given as points;
##           optional marks, vertical and horizontal guide lines
##   flow    labelled boxes on a 0–1 grid joined by arrows: pathways, reflex
##           arcs, the brachial plexus
##   table   a small comparison table with an optional highlighted row
##   cycle   steps around a circle with an optional centre label
##   bars    labelled bars against a value axis
##   micrograph  a light-microscope field of a tissue in H&E, drawn from its
##           name (so histology questions need no images): simple_squamous,
##           stratified_squamous, simple_cuboidal, simple_columnar,
##           pseudostratified, hyaline_cartilage, compact_bone,
##           skeletal_muscle, cardiac_muscle, smooth_muscle, dense_regular
##   ecg_strip  a rhythm strip on ECG paper: {rate, rhythm ("sinus" or
##           "afib"), st (mV of ST shift), seconds, lead}
##
## Functions for curves (x in the axis units):
##   hill                y = emax·xⁿ/(ec50ⁿ + xⁿ)          {emax, ec50, n}
##   michaelis_menten    y = vmax·x/(km + x)                {vmax, km}
##   lineweaver_burk     y = (km/vmax)·x + 1/vmax           {vmax, km}
##   exponential_decay   y = c0·e^(−kx), k = ln2/half_life  {c0, half_life}
##   linear              y = m·x + b                        {m, b}
##   saturating          y = ymax·(1 − e^(−x/tau)) + y0     {ymax, tau, y0}
##   repeated_dose       C(t) after doses every `interval`  {dose_c, half_life, interval}
##   oral_absorption     y = scale·(e^(−kx) − e^(−ka·x))    {scale, half_life, absorption_half_life}
##   ecg                 an ECG trace in mV (x in seconds)   {rate, rhythm, st, t_amp}
## A series can ask for more samples than the default 160 ("samples").
const FONT = preload("res://assets/outfit_medium.tres")
const INK := Color("eef2ef")
const MUTED := Color("9fb3b3")
const FAINT := Color("5e7478")
const COLORS := {
	"accent": Color("e98a4f"), "second": Color("6fc3c0"), "third": Color("c7a4e0"),
	"gold": Color("f2c46d"), "red": Color("e8707a"), "green": Color("7fd6a0"), "blue": Color("8fb5e8"), "muted": Color("9fb3b3"),
}
const TYPES := ["curves", "flow", "table", "cycle", "bars", "micrograph", "ecg_strip"]
const FUNCTIONS := ["hill", "michaelis_menten", "lineweaver_burk", "exponential_decay", "linear", "saturating", "repeated_dose", "oral_absorption", "ecg"]
const TISSUES := ["simple_squamous", "stratified_squamous", "simple_cuboidal", "simple_columnar", "pseudostratified", "hyaline_cartilage", "compact_bone", "skeletal_muscle", "cardiac_muscle", "smooth_muscle", "dense_regular"]
## H&E: eosin pinks for cytoplasm and matrix, hematoxylin purples for nuclei.
const EOSIN := Color("e7a3b8")
const EOSIN_DEEP := Color("cf6f93")
const HEMATOXYLIN := Color("4b2a6e")
const HEMATOXYLIN_PALE := Color("8a6aa8")
const LUMEN := Color("f7f1f4")

## "" when the figure is usable, otherwise what's wrong.
static func validate(figure: Variant) -> String:
	if typeof(figure) != TYPE_DICTIONARY or not TYPES.has(String(figure.get("type", ""))):
		return "Figure needs a known type"
	match String(figure.type):
		"curves":
			if typeof(figure.get("series")) != TYPE_ARRAY or figure.series.is_empty():
				return "Curves need series"
			for series in figure.series:
				if typeof(series) != TYPE_DICTIONARY:
					return "Each series must be an object"
				if series.has("fn"):
					if not FUNCTIONS.has(String(series.fn)):
						return "Unknown curve function: " + String(series.fn)
				elif typeof(series.get("points")) != TYPE_ARRAY or series.points.size() < 2:
					return "A series needs a function or at least two points"
		"flow":
			if typeof(figure.get("nodes")) != TYPE_ARRAY or figure.nodes.is_empty():
				return "Flow needs nodes"
			var ids := {}
			for node in figure.nodes:
				ids[String(node.get("id", ""))] = true
			for edge in figure.get("edges", []):
				if not ids.has(String(edge.get("from", ""))) or not ids.has(String(edge.get("to", ""))):
					return "Flow edge joins an unknown node"
		"table":
			if typeof(figure.get("columns")) != TYPE_ARRAY or typeof(figure.get("rows")) != TYPE_ARRAY:
				return "Table needs columns and rows"
			for row in figure.rows:
				if typeof(row) != TYPE_ARRAY or row.size() != figure.columns.size():
					return "Every table row needs one cell per column"
		"cycle":
			if typeof(figure.get("steps")) != TYPE_ARRAY or figure.steps.size() < 3:
				return "A cycle needs at least three steps"
		"bars":
			if typeof(figure.get("bars")) != TYPE_ARRAY or figure.bars.is_empty():
				return "Bars need values"
		"micrograph":
			if not TISSUES.has(String(figure.get("tissue", ""))):
				return "Unknown tissue: " + String(figure.get("tissue", ""))
		"ecg_strip":
			if float(figure.get("rate", 0.0)) < 20.0 or float(figure.get("rate", 0.0)) > 250.0:
				return "An ECG strip needs a rate from 20 to 250"
	return ""

static func color(name: Variant, fallback := "accent") -> Color:
	if typeof(name) == TYPE_STRING and COLORS.has(name):
		return COLORS[name]
	if typeof(name) == TYPE_STRING and String(name).begins_with("#"):
		return Color(String(name))
	return COLORS[fallback]

## Draws `figure` onto `canvas` inside `rect`; `scale` sizes text and lines
## (1.0 suits a 1200-px slide).
static func draw(canvas: Control, figure: Dictionary, rect: Rect2, scale := 1.0) -> void:
	match String(figure.get("type", "")):
		"curves": _curves(canvas, figure, rect, scale)
		"flow": _flow(canvas, figure, rect, scale)
		"table": _table(canvas, figure, rect, scale)
		"cycle": _cycle(canvas, figure, rect, scale)
		"bars": _bars(canvas, figure, rect, scale)
		"micrograph": _micrograph(canvas, figure, rect, scale)
		"ecg_strip": _ecg_strip(canvas, figure, rect, scale)

# --- Curves ---------------------------------------------------------------------------------------

static func evaluate(fn: String, params: Dictionary, x: float) -> float:
	match fn:
		"hill":
			var n := float(params.get("n", 1.0))
			var ec50 := float(params.get("ec50", 1.0))
			return float(params.get("emax", 100.0)) * pow(maxf(x, 0.0), n) / (pow(ec50, n) + pow(maxf(x, 0.0), n))
		"michaelis_menten":
			return float(params.get("vmax", 100.0)) * x / (float(params.get("km", 1.0)) + x)
		"lineweaver_burk":
			var vmax := float(params.get("vmax", 1.0))
			return float(params.get("km", 1.0)) / vmax * x + 1.0 / vmax
		"exponential_decay":
			return float(params.get("c0", 100.0)) * exp(-log(2.0) / float(params.get("half_life", 1.0)) * x)
		"linear":
			return float(params.get("m", 1.0)) * x + float(params.get("b", 0.0))
		"saturating":
			return float(params.get("ymax", 100.0)) * (1.0 - exp(-x / float(params.get("tau", 1.0)))) + float(params.get("y0", 0.0))
		"oral_absorption":
			# One-compartment oral dose (Bateman): absorption and elimination both first-order.
			var k_el := log(2.0) / float(params.get("half_life", 1.0))
			var k_abs := log(2.0) / float(params.get("absorption_half_life", 0.5))
			return float(params.get("scale", 50.0)) * (exp(-k_el * x) - exp(-k_abs * x))
		"ecg":
			return ecg(x, params)
		"repeated_dose":
			# Superposition of identical doses (instant absorption), each decaying first-order.
			var k := log(2.0) / float(params.get("half_life", 1.0))
			var interval := float(params.get("interval", 1.0))
			var total := 0.0
			var dose_time := 0.0
			while dose_time <= x + 0.0001:
				total += float(params.get("dose_c", 10.0)) * exp(-k * (x - dose_time))
				dose_time += interval
			return total
	return 0.0

static func _curves(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var x_axis: Dictionary = figure.get("x", {})
	var y_axis: Dictionary = figure.get("y", {})
	var x_min := float(x_axis.get("min", 0.0))
	var x_max := float(x_axis.get("max", 10.0))
	var y_min := float(y_axis.get("min", 0.0))
	var y_max := float(y_axis.get("max", 100.0))
	var log_x: bool = x_axis.get("log", false)
	var legend_rows := int(ceil(figure.series.size() / 2.0))
	var plot := Rect2(rect.position + Vector2(70, 16) * scale, rect.size - Vector2(90, 70 + legend_rows * 30) * scale)
	var to_screen := func(x: float, y: float) -> Vector2:
		var fx := (log(maxf(x, 1e-9)) / log(10.0) - log(x_min) / log(10.0)) / (log(x_max) / log(10.0) - log(x_min) / log(10.0)) if log_x else (x - x_min) / (x_max - x_min)
		var fy := (y - y_min) / (y_max - y_min)
		return Vector2(plot.position.x + fx * plot.size.x, plot.end.y - clampf(fy, -0.05, 1.05) * plot.size.y)
	# Axes.
	canvas.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), MUTED, 3.0 * scale)
	canvas.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, MUTED, 3.0 * scale)
	canvas.draw_string(FONT, Vector2(plot.position.x + 6 * scale, plot.end.y + 34 * scale), String(x_axis.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * scale), MUTED)
	canvas.draw_set_transform(Vector2(plot.position.x - 22 * scale, plot.end.y), -PI / 2)
	canvas.draw_string(FONT, Vector2.ZERO, String(y_axis.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, int(plot.size.y), int(22 * scale), MUTED)
	canvas.draw_set_transform(Vector2.ZERO)
	# Guide lines.
	for line in figure.get("vlines", []):
		var top: Vector2 = to_screen.call(float(line.x), y_max)
		var bottom: Vector2 = to_screen.call(float(line.x), y_min)
		canvas.draw_dashed_line(top, bottom, color(line.get("color", "muted"), "muted"), 2.0 * scale, 8.0 * scale)
		if line.has("label"):
			canvas.draw_string(FONT, top + Vector2(6, 22) * scale, String(line.label), HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * scale), color(line.get("color", "muted"), "muted"))
	for line in figure.get("hlines", []):
		var left: Vector2 = to_screen.call(x_min, float(line.y))
		var right: Vector2 = to_screen.call(x_max, float(line.y))
		canvas.draw_dashed_line(left, right, color(line.get("color", "muted"), "muted"), 2.0 * scale, 8.0 * scale)
		if line.has("label"):
			canvas.draw_string(FONT, right + Vector2(-200, -8) * scale, String(line.label), HORIZONTAL_ALIGNMENT_RIGHT, 200 * scale, int(20 * scale), color(line.get("color", "muted"), "muted"))
	# Series.
	for index in range(figure.series.size()):
		var series: Dictionary = figure.series[index]
		var tint := color(series.get("color", ["accent", "second", "third", "gold", "red"][index % 5]))
		var points := PackedVector2Array()
		if series.has("fn"):
			var from := float(series.get("from", x_min))
			var to := float(series.get("to", x_max))
			var samples := int(series.get("samples", 160))
			for step in range(samples + 1):
				var t := step / float(samples)
				var x := pow(10.0, lerpf(log(maxf(from, 1e-9)) / log(10.0), log(to) / log(10.0), t)) if log_x else lerpf(from, to, t)
				points.append(to_screen.call(x, evaluate(String(series.fn), series.get("params", {}), x)))
		else:
			for point in series.points:
				points.append(to_screen.call(float(point[0]), float(point[1])))
			if series.get("closed", false):
				points.append(points[0])
		if series.get("dashed", false):
			for p in range(points.size() - 1):
				if p % 2 == 0:
					canvas.draw_line(points[p], points[p + 1], tint, 4.0 * scale, true)
		else:
			canvas.draw_polyline(points, tint, 5.0 * scale, true)
		var legend_x := rect.position.x + 10 * scale + (index % 2) * rect.size.x * 0.5
		var legend_y := plot.end.y + (62 + int(index / 2) * 30) * scale
		canvas.draw_rect(Rect2(legend_x, legend_y - 12 * scale, 22 * scale, 8 * scale), tint)
		canvas.draw_string(FONT, Vector2(legend_x + 30 * scale, legend_y - 2 * scale), String(series.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.5 - 40 * scale, int(20 * scale), INK)
	for mark in figure.get("marks", []):
		var at: Vector2 = to_screen.call(float(mark.x), float(mark.y))
		var tint := color(mark.get("color", "gold"))
		canvas.draw_circle(at, 7.0 * scale, tint)
		if mark.has("label"):
			canvas.draw_string(FONT, at + Vector2(10, -10) * scale, String(mark.label), HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * scale), tint)

# --- Flow -----------------------------------------------------------------------------------------

static func _flow(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var boxes := {}
	var font_size := int(float(figure.get("text_size", 20)) * scale)
	for node in figure.nodes:
		var label := String(node.get("label", node.id))
		var lines := label.split("\n")
		var width := 0.0
		for line in lines:
			width = maxf(width, FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		var box_size := Vector2(width + 24 * scale, lines.size() * font_size * 1.25 + 14 * scale)
		var center := rect.position + Vector2(float(node.get("x", 0.5)), float(node.get("y", 0.5))) * rect.size
		boxes[node.id] = Rect2(center - box_size / 2.0, box_size)
	for edge in figure.get("edges", []):
		var a: Rect2 = boxes[edge.from]
		var b: Rect2 = boxes[edge.to]
		var start := _edge_point(a, b.get_center())
		var end := _edge_point(b, a.get_center())
		var tint := color(edge.get("color", "muted"), "muted")
		if edge.get("dashed", false):
			canvas.draw_dashed_line(start, end, tint, 3.0 * scale, 10.0 * scale)
		else:
			canvas.draw_line(start, end, tint, 3.0 * scale, true)
		var direction := (end - start).normalized()
		var side := Vector2(-direction.y, direction.x)
		canvas.draw_colored_polygon(PackedVector2Array([end, end - direction * 14 * scale + side * 7 * scale, end - direction * 14 * scale - side * 7 * scale]), tint)
		if edge.has("label"):
			canvas.draw_string(FONT, (start + end) / 2.0 + side * 14 * scale + Vector2(-60, 6) * scale, String(edge.label), HORIZONTAL_ALIGNMENT_CENTER, 120 * scale, int(17 * scale), MUTED)
	for node in figure.nodes:
		var box: Rect2 = boxes[node.id]
		var tint := color(node.get("color", "second"), "second")
		var highlighted: bool = node.get("highlight", false)
		canvas.draw_rect(box, Color(tint, 0.34 if highlighted else 0.16))
		canvas.draw_rect(box, tint, false, (4.0 if highlighted else 2.0) * scale)
		var lines := String(node.get("label", node.id)).split("\n")
		for line_index in range(lines.size()):
			var y := box.position.y + 8 * scale + (line_index + 0.85) * font_size * 1.25 - font_size * 0.25
			canvas.draw_string(FONT, Vector2(box.position.x, y), lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, box.size.x, font_size, INK)

static func _edge_point(box: Rect2, toward: Vector2) -> Vector2:
	var center := box.get_center()
	var direction := toward - center
	if direction.length() < 0.01:
		return center
	var half := box.size / 2.0
	var scale_x := half.x / absf(direction.x) if absf(direction.x) > 0.001 else INF
	var scale_y := half.y / absf(direction.y) if absf(direction.y) > 0.001 else INF
	return center + direction * minf(scale_x, scale_y)

# --- Table ----------------------------------------------------------------------------------------

static func _table(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var columns: Array = figure.columns
	var rows: Array = figure.rows
	var font_size := int(float(figure.get("text_size", 20)) * scale)
	var row_height := font_size * 1.9
	var widths: Array = figure.get("widths", [])
	if widths.size() != columns.size():
		widths = []
		for index in range(columns.size()):
			widths.append(1.0 / columns.size())
	var y := rect.position.y
	var highlight := int(figure.get("highlight", -1))
	for row_index in range(-1, rows.size()):
		var cells: Array = columns if row_index < 0 else rows[row_index]
		if row_index == highlight:
			canvas.draw_rect(Rect2(rect.position.x, y, rect.size.x, row_height), Color(COLORS.gold, 0.18))
		var x := rect.position.x
		for index in range(cells.size()):
			var width := float(widths[index]) * rect.size.x
			canvas.draw_string(FONT, Vector2(x + 8 * scale, y + row_height * 0.66), String(cells[index]), HORIZONTAL_ALIGNMENT_LEFT, width - 12 * scale, font_size, MUTED if row_index < 0 else INK)
			x += width
		y += row_height
		canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), MUTED if row_index < 0 else Color(FAINT, 0.6), (2.0 if row_index < 0 else 1.0) * scale)

# --- Cycle ----------------------------------------------------------------------------------------

static func _cycle(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var steps: Array = figure.steps
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.36
	var font_size := int(float(figure.get("text_size", 20)) * scale)
	canvas.draw_arc(center, radius, 0.0, TAU, 96, Color(MUTED, 0.45), 3.0 * scale, true)
	for index in range(steps.size()):
		var angle := -PI / 2 + index * TAU / steps.size()
		var next_angle := angle + TAU / steps.size()
		# Arrowhead between this step and the next, on the ring.
		var mid := angle + (next_angle - angle) * 0.5
		var at := center + Vector2(cos(mid), sin(mid)) * radius
		var tangent := Vector2(-sin(mid), cos(mid))
		canvas.draw_colored_polygon(PackedVector2Array([at + tangent * 12 * scale, at - tangent * 4 * scale + tangent.orthogonal() * 8 * scale, at - tangent * 4 * scale - tangent.orthogonal() * 8 * scale]), MUTED)
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		var tint := color(["accent", "second", "third", "gold", "blue", "green"][index % 6])
		canvas.draw_circle(point, 11 * scale, tint)
		var label := String(steps[index])
		var text_width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var outward := Vector2(cos(angle), sin(angle))
		var text_at := point + outward * 24 * scale + Vector2(-text_width / 2.0 + outward.x * text_width / 2.0, font_size * 0.35 + outward.y * font_size * 0.4)
		canvas.draw_string(FONT, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)
	if figure.has("center"):
		canvas.draw_string(FONT, center + Vector2(-radius, font_size * 0.35), String(figure.center), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, int(font_size * 1.1), MUTED)

# --- Bars -----------------------------------------------------------------------------------------

static func _bars(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var bars: Array = figure.bars
	var max_value := float(figure.get("max", 0.0))
	if max_value <= 0.0:
		for bar in bars:
			max_value = maxf(max_value, float(bar.value))
	var plot := Rect2(rect.position + Vector2(60, 10) * scale, rect.size - Vector2(70, 60) * scale)
	canvas.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, MUTED, 3.0 * scale)
	canvas.draw_set_transform(Vector2(plot.position.x - 24 * scale, plot.end.y), -PI / 2)
	canvas.draw_string(FONT, Vector2.ZERO, String(figure.get("y_label", "")), HORIZONTAL_ALIGNMENT_LEFT, int(plot.size.y), int(20 * scale), MUTED)
	canvas.draw_set_transform(Vector2.ZERO)
	var slot := plot.size.x / bars.size()
	for index in range(bars.size()):
		var bar: Dictionary = bars[index]
		var height := float(bar.value) / max_value * plot.size.y
		var tint := color(bar.get("color", ["accent", "second", "third", "gold"][index % 4]))
		var box := Rect2(plot.position.x + index * slot + slot * 0.18, plot.end.y - height, slot * 0.64, height)
		canvas.draw_rect(box, tint)
		canvas.draw_string(FONT, Vector2(box.position.x - slot * 0.18, plot.end.y + 30 * scale), String(bar.get("label", "")), HORIZONTAL_ALIGNMENT_CENTER, slot, int(19 * scale), INK)
		canvas.draw_string(FONT, Vector2(box.position.x - slot * 0.18, box.position.y - 8 * scale), String(bar.get("text", str(bar.value))), HORIZONTAL_ALIGNMENT_CENTER, slot, int(19 * scale), MUTED)

# --- ECG ------------------------------------------------------------------------------------------

## Beat times (s) from 0 to `seconds`: regular at `rate`, or irregularly
## irregular for atrial fibrillation (a fixed pseudo-random pattern).
static func beat_times(params: Dictionary, seconds: float) -> Array:
	var rate := float(params.get("rate", 75.0))
	var interval := 60.0 / rate
	var times: Array = []
	var t := 0.25
	var index := 0
	while t < seconds + interval:
		times.append(t)
		var factor := 1.0
		if String(params.get("rhythm", "sinus")) == "afib":
			factor = 0.62 + 0.76 * fposmod(sin(float(index) * 12.9898) * 43758.5453, 1.0)
		t += interval * factor
		index += 1
	return times

static func _wave(x: float, center: float, width: float, height: float) -> float:
	return height * exp(-pow((x - center) / width, 2.0))

## An ECG trace (mV) at time x: P, QRS and T for each beat; atrial
## fibrillation has no P waves and a fibrillating baseline; `st` lifts (or
## depresses) the ST segment.
static func ecg(x: float, params: Dictionary) -> float:
	var afib := String(params.get("rhythm", "sinus")) == "afib"
	var st := float(params.get("st", 0.0))
	var t_amp := float(params.get("t_amp", 0.3))
	var value := 0.0
	for beat in beat_times(params, x + 1.0):
		var b := float(beat)
		if absf(x - b) > 1.2:
			continue
		if not afib:
			value += _wave(x, b - 0.16, 0.035, 0.15)
		value += _wave(x, b - 0.025, 0.012, -0.1)
		value += _wave(x, b, 0.014, 1.25)
		value += _wave(x, b + 0.03, 0.014, -0.28)
		# The ST segment rides at `st` from the J point into the T wave.
		if st != 0.0:
			value += st * clampf(1.0 - absf(x - (b + 0.16)) / 0.13, 0.0, 1.0)
		value += _wave(x, b + 0.3, 0.06, t_amp + st * 0.5)
	if afib:
		value += 0.05 * sin(x * 37.0) + 0.03 * sin(x * 53.0 + 1.3)
	return value

static func _ecg_strip(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var seconds := float(figure.get("seconds", 6.0))
	canvas.draw_rect(rect, Color("fdeef0"))
	# ECG paper: 1 mm = 0.04 s by 0.1 mV; bold lines every 5 mm.
	var mm := rect.size.x / (seconds / 0.04)
	var columns := int(rect.size.x / mm)
	for index in range(columns + 1):
		var x := rect.position.x + index * mm
		canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("f3b8c2") if index % 5 == 0 else Color("f9d9df"), (2.0 if index % 5 == 0 else 1.0) * scale)
	var rows := int(rect.size.y / mm)
	for index in range(rows + 1):
		var y := rect.position.y + index * mm
		canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("f3b8c2") if index % 5 == 0 else Color("f9d9df"), (2.0 if index % 5 == 0 else 1.0) * scale)
	var baseline := rect.position.y + rect.size.y * 0.62
	var points := PackedVector2Array()
	var samples := int(rect.size.x)
	for step in range(samples + 1):
		var t := seconds * step / float(samples)
		points.append(Vector2(rect.position.x + rect.size.x * step / float(samples), baseline - ecg(t, figure) * mm * 10.0))
	canvas.draw_polyline(points, Color("1d2a33"), 2.4 * scale, true)
	canvas.draw_string(FONT, rect.position + Vector2(10, 26) * scale, String(figure.get("lead", "II")), HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * scale), Color("1d2a33"))
	canvas.draw_string(FONT, Vector2(rect.end.x - 250 * scale, rect.end.y - 12 * scale), "25 mm/s · 10 mm/mV", HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * scale), Color("6d5a60"))

# --- Micrographs ----------------------------------------------------------------------------------

## A light-microscope field in H&E. Each tissue is drawn from its hallmarks,
## deterministic for its name, inside a round field of view.
static func _micrograph(canvas: Control, figure: Dictionary, rect: Rect2, scale: float) -> void:
	var tissue := String(figure.get("tissue", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tissue)
	var field := Rect2(rect.get_center() - Vector2(1, 1) * minf(rect.size.x, rect.size.y) * 0.5, Vector2(1, 1) * minf(rect.size.x, rect.size.y))
	canvas.draw_rect(field, Color("1a1216"))
	var r := field.size.x * 0.48
	var c := field.get_center()
	canvas.draw_circle(c, r, LUMEN)
	var s := field.size.x / 100.0
	match tissue:
		"simple_squamous":
			canvas.draw_rect(Rect2(c.x - r, c.y - 2 * s, r * 2, r), EOSIN)
			for index in range(14):
				var x := c.x - r + index * 7.4 * s + rng.randf_range(-1, 1) * s
				canvas.draw_rect(Rect2(x, c.y - 3.2 * s, 6.8 * s, 1.4 * s), EOSIN_DEEP)
				if index % 2 == 0:
					_ellipse(canvas, Vector2(x + 3.4 * s, c.y - 3.0 * s), Vector2(2.6, 0.9) * s, HEMATOXYLIN)
			for index in range(18):
				_ellipse(canvas, c + Vector2(rng.randf_range(-r, r), rng.randf_range(8, r * 0.8 / s) * s), Vector2(1.6, 0.8) * s, HEMATOXYLIN_PALE)
		"stratified_squamous":
			canvas.draw_rect(Rect2(c.x - r, c.y - 30 * s, r * 2, 70 * s), EOSIN)
			for layer in range(9):
				var y := c.y + 26 * s - layer * 6.2 * s
				var flat := float(layer) / 8.0
				var count := 12 - int(layer / 3)
				for index in range(count + 1):
					var x := c.x - r + (index + 0.5 * (layer % 2)) * (2 * r / count)
					var size := Vector2(2.2 + flat * 2.6, 2.2 - flat * 1.4) * s
					_ellipse(canvas, Vector2(x, y), size, HEMATOXYLIN if layer < 7 else HEMATOXYLIN_PALE)
			canvas.draw_rect(Rect2(c.x - r, c.y + 30 * s, r * 2, 20 * s), EOSIN_DEEP.lightened(0.2))
		"simple_cuboidal":
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, r * 2), EOSIN.lightened(0.2))
			for tubule in [Vector2(-22, -18), Vector2(20, -20), Vector2(-18, 20), Vector2(22, 18)]:
				var at: Vector2 = c + tubule * s
				canvas.draw_circle(at, 14 * s, EOSIN)
				canvas.draw_circle(at, 6 * s, LUMEN)
				for index in range(10):
					var angle := index * TAU / 10.0
					canvas.draw_circle(at + Vector2(cos(angle), sin(angle)) * 10 * s, 1.8 * s, HEMATOXYLIN)
		"simple_columnar":
			canvas.draw_rect(Rect2(c.x - r, c.y - 20 * s, r * 2, 70 * s), EOSIN_DEEP.lightened(0.3))
			for index in range(16):
				var x := c.x - r + index * 6.4 * s
				canvas.draw_rect(Rect2(x, c.y - 20 * s, 5.8 * s, 26 * s), EOSIN)
				if index % 5 == 2:
					_ellipse(canvas, Vector2(x + 2.9 * s, c.y - 10 * s), Vector2(2.4, 6.5) * s, LUMEN)
				_ellipse(canvas, Vector2(x + 2.9 * s, c.y + 1.5 * s), Vector2(1.6, 3.4) * s, HEMATOXYLIN)
			canvas.draw_rect(Rect2(c.x - r, c.y - 21.5 * s, r * 2, 1.5 * s), EOSIN_DEEP)
		"pseudostratified":
			canvas.draw_rect(Rect2(c.x - r, c.y - 22 * s, r * 2, 70 * s), EOSIN_DEEP.lightened(0.3))
			canvas.draw_rect(Rect2(c.x - r, c.y - 22 * s, r * 2, 30 * s), EOSIN)
			for index in range(22):
				var x := c.x - r + index * 4.6 * s + rng.randf_range(-1, 1) * s
				_ellipse(canvas, Vector2(x, c.y + rng.randf_range(-8, 5) * s), Vector2(1.5, 2.8) * s, HEMATOXYLIN)
				canvas.draw_line(Vector2(x, c.y - 22 * s), Vector2(x + rng.randf_range(-0.6, 0.6) * s, c.y - 26 * s), EOSIN_DEEP, 1.0 * scale)
			for index in [4, 12, 18]:
				_ellipse(canvas, Vector2(c.x - r + index * 4.6 * s, c.y - 14 * s), Vector2(2.4, 5.5) * s, LUMEN)
		"hyaline_cartilage":
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, r * 2), Color("b9a3d0"))
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, 10 * s), EOSIN_DEEP)
			for group in range(12):
				var at := c + Vector2(rng.randf_range(-36, 36), rng.randf_range(-28, 38)) * s
				for member in range(rng.randi_range(1, 3)):
					var cell := at + Vector2(member * 4.2, rng.randf_range(-1, 1)) * s
					_ellipse(canvas, cell, Vector2(2.6, 2.0) * s, LUMEN)
					canvas.draw_circle(cell, 1.2 * s, HEMATOXYLIN)
		"compact_bone":
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, r * 2), Color("e9c7cf"))
			for osteon in [Vector2(-20, -18), Vector2(18, -22), Vector2(-24, 20), Vector2(20, 18), Vector2(0, 0)]:
				var at: Vector2 = c + osteon * s
				for ring in range(5):
					canvas.draw_arc(at, (4 + ring * 3.2) * s, 0, TAU, 32, Color("c98a9c"), 1.2 * scale)
				canvas.draw_circle(at, 2.8 * s, LUMEN)
				for index in range(8):
					var angle := index * TAU / 8.0 + 0.3
					_ellipse(canvas, at + Vector2(cos(angle), sin(angle)) * (7.5 + (index % 2) * 5.0) * s, Vector2(1.4, 0.7) * s, HEMATOXYLIN)
		"skeletal_muscle":
			for fiber in range(8):
				var y := c.y - r + fiber * 12 * s
				canvas.draw_rect(Rect2(c.x - r, y, r * 2, 10.6 * s), EOSIN)
				var x := c.x - r
				while x < c.x + r:
					canvas.draw_line(Vector2(x, y), Vector2(x, y + 10.6 * s), EOSIN_DEEP, 0.8 * scale)
					x += 1.6 * s
				for index in range(4):
					_ellipse(canvas, Vector2(c.x - r + (index * 26 + fiber * 7) * s, y + 1.2 * s), Vector2(3.2, 0.9) * s, HEMATOXYLIN)
		"cardiac_muscle":
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, r * 2), LUMEN)
			for fiber in range(7):
				var y := c.y - r + fiber * 14 * s
				canvas.draw_rect(Rect2(c.x - r, y, r * 2, 10 * s), EOSIN)
				for index in range(5):
					var x := c.x - r + (index * 22 + (fiber % 2) * 11) * s
					_ellipse(canvas, Vector2(x + 8 * s, y + 5 * s), Vector2(2.6, 1.3) * s, HEMATOXYLIN)
					canvas.draw_line(Vector2(x + 17 * s, y), Vector2(x + 18 * s, y + 10 * s), HEMATOXYLIN, 1.8 * scale)
				if fiber < 6:
					canvas.draw_line(Vector2(c.x - r + (30 + fiber * 9) * s, y + 10 * s), Vector2(c.x - r + (36 + fiber * 9) * s, y + 14 * s), EOSIN, 6 * s)
		"smooth_muscle":
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, r * 2), EOSIN.lightened(0.15))
			for index in range(30):
				var at := c + Vector2(rng.randf_range(-44, 44), rng.randf_range(-44, 44)) * s
				_ellipse(canvas, at, Vector2(9, 2.2) * s, EOSIN_DEEP.lightened(0.15))
				_ellipse(canvas, at, Vector2(3.6, 0.9) * s, HEMATOXYLIN)
		"dense_regular":
			canvas.draw_rect(Rect2(c.x - r, c.y - r, r * 2, r * 2), EOSIN.lightened(0.1))
			for band in range(12):
				var y := c.y - r + band * 8.4 * s
				var points := PackedVector2Array()
				for step in range(41):
					var x := c.x - r + step * 2 * r / 40.0
					points.append(Vector2(x, y + sin(step * 0.8 + band) * 1.2 * s))
				canvas.draw_polyline(points, EOSIN_DEEP, 3.2 * s)
				for index in range(3):
					_ellipse(canvas, Vector2(c.x - r + (index * 30 + band * 5) * s, y + 4.2 * s), Vector2(3.4, 0.7) * s, HEMATOXYLIN)
	# Mask the square corners back to the dark round field of view.
	for corner in range(64):
		var a0 := corner * TAU / 64.0
		var a1 := (corner + 1) * TAU / 64.0
		var outer := r * 1.5
		canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a0), sin(a0)) * outer, c + Vector2(cos(a1), sin(a1)) * outer, c + Vector2(cos(a1), sin(a1)) * r]), Color("1a1216"))
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, field.position.y - rect.position.y)), Color("1a1216"))
	canvas.draw_rect(Rect2(Vector2(rect.position.x, field.end.y), Vector2(rect.size.x, rect.end.y - field.end.y)), Color("1a1216"))
	canvas.draw_rect(Rect2(rect.position, Vector2(field.position.x - rect.position.x, rect.size.y)), Color("1a1216"))
	canvas.draw_rect(Rect2(Vector2(field.end.x, rect.position.y), Vector2(rect.end.x - field.end.x, rect.size.y)), Color("1a1216"))
	canvas.draw_string(FONT, rect.position + Vector2(12, rect.size.y - 14 * scale), "H&E · " + String(figure.get("magnification", "×400")), HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * scale), MUTED)

static func _ellipse(canvas: Control, center: Vector2, radii: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := index * TAU / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	canvas.draw_colored_polygon(points, tint)

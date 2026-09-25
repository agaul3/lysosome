extends Control
## Bedside monitors for the Emergency Department, all drawn into one texture
## (a 4 × 4 atlas): each tile is one bay's monitor, with the bay label, a
## scrolling ECG, pulse-oximeter pleth and respiration traces, and heart
## rate, SpO₂, blood pressure and respiratory rate. Screens in the rooms show
## their own tile, so sixteen live monitors cost a single viewport.
## Values come from the ED state (ed_life.gd `monitor_data()`), fictional.
const UI = preload("res://ui/style/ui_style.gd")
const COLUMNS := 4
const ROWS := 4
const TILE := Vector2(320, 200)
const SIZE := Vector2(TILE.x * COLUMNS, TILE.y * ROWS)
const WINDOW := 3.2
## Provides monitor_data(): an array of COLUMNS × ROWS bay dictionaries.
var source: Object
var font: Font
var bold: Font
var time := 0.0
var refresh := 0.0

func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	font = UI.font(500)
	bold = UI.font(700)

## UV rectangle of tile `index` for a screen material.
static func tile_rect(index: int) -> Rect2:
	return Rect2((index % COLUMNS) / float(COLUMNS), floori(index / float(COLUMNS)) / float(ROWS), 1.0 / COLUMNS, 1.0 / ROWS)

func _process(delta: float) -> void:
	time += delta
	refresh -= delta
	if refresh <= 0.0:
		refresh = 1.0 / 12.0
		queue_redraw()

static func ecg(t: float, rate: float) -> float:
	var period := 60.0 / maxf(rate, 20.0)
	var phase := fposmod(t, period) / period
	var value := 0.0
	value += 0.12 * exp(-pow((phase - 0.16) / 0.035, 2.0))
	value -= 0.14 * exp(-pow((phase - 0.285) / 0.01, 2.0))
	value += 1.0 * exp(-pow((phase - 0.31) / 0.012, 2.0))
	value -= 0.26 * exp(-pow((phase - 0.335) / 0.012, 2.0))
	value += 0.26 * exp(-pow((phase - 0.58) / 0.06, 2.0))
	return value

static func pleth(t: float, rate: float) -> float:
	var period := 60.0 / maxf(rate, 20.0)
	var phase := fposmod(t - 0.18, period) / period
	return exp(-pow((phase - 0.22) / 0.1, 2.0)) + 0.32 * exp(-pow((phase - 0.52) / 0.12, 2.0))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("050807"))
	var data: Array = source.monitor_data() if source else []
	for index in range(COLUMNS * ROWS):
		var origin := Vector2((index % COLUMNS) * TILE.x, floori(index / float(COLUMNS)) * TILE.y)
		var bay: Dictionary = data[index] if index < data.size() else {}
		_tile(origin, bay, index)

func _tile(origin: Vector2, bay: Dictionary, index: int) -> void:
	draw_rect(Rect2(origin + Vector2(2, 2), TILE - Vector2(4, 4)), Color("0a0f0e"))
	draw_rect(Rect2(origin + Vector2(2, 2), Vector2(TILE.x - 4, 26)), Color("15232a"))
	draw_string(bold, origin + Vector2(10, 22), String(bay.get("label", "BAY")), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if not bay.get("active", false):
		draw_string(font, origin + Vector2(TILE.x - 10, 22), "STANDBY", HORIZONTAL_ALIGNMENT_RIGHT, 120, 16, Color("6d8589"))
		draw_line(origin + Vector2(10, 110), origin + Vector2(TILE.x - 10, 110), Color("1d3a2c"), 2.0)
		return
	draw_string(font, origin + Vector2(TILE.x - 10, 22), String(bay.get("name", "")), HORIZONTAL_ALIGNMENT_RIGHT, 160, 16, Color("b7cdd8"))
	var rate := float(bay.get("hr", 80))
	var offset := index * 0.37
	var width := 200.0
	var ecg_points := PackedVector2Array()
	var pleth_points := PackedVector2Array()
	var resp_points := PackedVector2Array()
	for step in range(0, 101):
		var x := step / 100.0
		var t := time + offset - WINDOW + x * WINDOW
		ecg_points.append(origin + Vector2(10 + x * width, 84 - ecg(t, rate) * 34.0))
		pleth_points.append(origin + Vector2(10 + x * width, 146 - pleth(t, rate) * 26.0))
		resp_points.append(origin + Vector2(10 + x * width, 180 - sin(TAU * t * float(bay.get("rr", 16)) / 60.0) * 8.0))
	draw_polyline(ecg_points, Color("4cff7a"), 2.0)
	draw_polyline(pleth_points, Color("5ad8ff"), 2.0)
	draw_polyline(resp_points, Color("ffd84a"), 1.6)
	var column := origin + Vector2(222, 0)
	draw_string(font, column + Vector2(0, 46), "HR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("4cff7a"))
	draw_string(bold, column + Vector2(0, 84), str(int(rate)), HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("4cff7a"))
	draw_string(font, column + Vector2(0, 108), "SpO₂", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("5ad8ff"))
	draw_string(bold, column + Vector2(0, 140), "%d" % int(bay.get("spo2", 97)), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("5ad8ff"))
	draw_string(font, column + Vector2(0, 162), "%d/%d" % [int(bay.get("sbp", 120)), int(bay.get("dbp", 76))], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2f2f0"))
	draw_string(font, column + Vector2(0, 188), "RR %d" % int(bay.get("rr", 16)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffd84a"))

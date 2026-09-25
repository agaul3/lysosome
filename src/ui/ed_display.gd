extends Control
## The Emergency Department's wall displays, drawn from the live ED state
## (world/hospital/ed_life.gd) into a viewport shown on TVs:
##   "tracking" — the tracking board: every bed with its ESI level, patient
##               initials, complaint, nurse, physician, status and time in
##               the department (fictional training data);
##   "trauma"   — the trauma/resuscitation board: EMS inbound with a live ETA,
##               and the four trauma bays;
##   "waiting"  — the waiting-room screen: how triage works and the wait.
## ESI (Emergency Severity Index) colours follow a common tracking-board
## convention: 1 red, 2 orange, 3 yellow, 4 green, 5 blue.
const UI = preload("res://ui/style/ui_style.gd")
const SIZE := Vector2(1280, 720)
const ESI_COLORS := {1: Color("d7263d"), 2: Color("f28c28"), 3: Color("f2c230"), 4: Color("3aa76d"), 5: Color("3d7fd6")}
const ESI_NAMES := {1: "Resuscitation", 2: "Emergent", 3: "Urgent", 4: "Less urgent", 5: "Non-urgent"}
var mode := "tracking"
## Provides tracking_rows(), status_info() and bay_rows().
var source: Object
var font: Font
var bold: Font
var refresh := 0.0

func _init(display_mode := "tracking") -> void:
	mode = display_mode
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	font = UI.font(500)
	bold = UI.font(700)

func _process(delta: float) -> void:
	refresh -= delta
	if refresh <= 0.0:
		refresh = 0.5
		queue_redraw()

func _text(at: Vector2, text: String, size_px: int, color: Color, heavy := false, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(bold if heavy else font, at, text, align, width, size_px, color)

static func clock_text() -> String:
	var time: Dictionary = GameClock.snapshot()
	var hour: int = int(time.hour) % 12
	return "%d:%02d %s" % [12 if hour == 0 else hour, int(time.minute), "AM" if int(time.hour) < 12 else "PM"]

func _draw() -> void:
	match mode:
		"trauma":
			_trauma()
		"waiting":
			_waiting()
		_:
			_tracking()

func _chip(rect: Rect2, esi: int) -> void:
	var color: Color = ESI_COLORS.get(esi, Color("8a969c"))
	draw_rect(rect, color)
	_text(rect.position + Vector2(0, rect.size.y - 9), str(esi), 24, Color("1d1d1d") if esi == 3 else Color.WHITE, true, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _tracking() -> void:
	var info: Dictionary = source.status_info() if source else {}
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("f4f7f9"))
	draw_rect(Rect2(0, 0, SIZE.x, 64), Color("13283a"))
	_text(Vector2(24, 42), "EMERGENCY DEPARTMENT · TRACKING BOARD", 28, Color.WHITE, true)
	_text(Vector2(SIZE.x - 24, 42), "Waiting %d  ·  EMS inbound %d  ·  %s" % [int(info.get("waiting", 0)), int(info.get("inbound", 0)), clock_text()], 22, Color("cfe2e8"), false, 560, HORIZONTAL_ALIGNMENT_RIGHT)
	var columns := [[24, "BED"], [130, "ESI"], [200, "PT"], [280, "AGE"], [370, "CHIEF COMPLAINT"], [700, "RN"], [790, "MD"], [880, "STATUS"], [1190, "TIME"]]
	draw_rect(Rect2(0, 64, SIZE.x, 40), Color("1d3a52"))
	for column in columns:
		_text(Vector2(column[0], 92), column[1], 17, Color("b7cdd8"), true)
	var rows: Array = source.tracking_rows() if source else []
	for index in range(mini(rows.size(), 14)):
		var row: Dictionary = rows[index]
		var y := 104.0 + index * 42.0
		draw_rect(Rect2(0, y, SIZE.x, 42), Color("ffffff") if index % 2 == 0 else Color("eaf0f4"))
		_text(Vector2(24, y + 29), String(row.bed), 22, Color("13283a"), true)
		_chip(Rect2(130, y + 6, 44, 30), int(row.esi))
		_text(Vector2(200, y + 29), String(row.initials), 21, Color("13283a"), true)
		_text(Vector2(280, y + 29), String(row.age), 20, Color("3d5563"))
		_text(Vector2(370, y + 29), String(row.complaint), 20, Color("13283a"), false, 320)
		_text(Vector2(700, y + 29), String(row.rn), 20, Color("3d5563"))
		_text(Vector2(790, y + 29), String(row.md), 20, Color("3d5563"))
		_text(Vector2(880, y + 29), String(row.status), 20, _status_color(String(row.status)), true, 300)
		_text(Vector2(1190, y + 29), String(row.time), 20, Color("3d5563"))
	# Legend.
	var legend_y := SIZE.y - 30
	draw_rect(Rect2(0, legend_y - 6, SIZE.x, 36), Color("dfe7ec"))
	var x := 24.0
	_text(Vector2(x, legend_y + 18), "ESI", 18, Color("13283a"), true)
	x += 50
	for level in range(1, 6):
		draw_rect(Rect2(x, legend_y + 2, 22, 20), ESI_COLORS[level])
		_text(Vector2(x + 30, legend_y + 18), "%d %s" % [level, ESI_NAMES[level]], 17, Color("13283a"))
		x += 200
	_text(Vector2(SIZE.x - 24, legend_y + 18), "Fictional training data", 15, Color("5d7079"), false, 240, HORIZONTAL_ALIGNMENT_RIGHT)

static func _status_color(status: String) -> Color:
	if status.begins_with("Trauma") or status.begins_with("Resus"):
		return Color("c0202f")
	if status.begins_with("Awaiting") or status.begins_with("In ") or status.begins_with("To "):
		return Color("b36b00")
	if status.begins_with("Admit") or status.begins_with("Boarding"):
		return Color("6b3fa0")
	if status.begins_with("Discharge") or status.begins_with("Ready"):
		return Color("1f7a4a")
	return Color("13283a")

func _trauma() -> void:
	var info: Dictionary = source.status_info() if source else {}
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("0f1a24"))
	_text(Vector2(32, 58), "TRAUMA & RESUSCITATION", 36, Color.WHITE, true)
	_text(Vector2(SIZE.x - 32, 58), "Level I Trauma Center  ·  %s" % clock_text(), 22, Color("9fb8c6"), false, 520, HORIZONTAL_ALIGNMENT_RIGHT)
	var panel := Rect2(32, 92, SIZE.x - 64, 250)
	var inbound: Dictionary = info.get("next_ems", {})
	var eta := float(info.get("eta", -1.0))
	if not inbound.is_empty() and eta >= 0.0:
		var flash := floori(Time.get_ticks_msec() / 600.0) % 2 == 0
		draw_rect(panel, Color("7a1520") if flash else Color("5e1019"))
		_text(panel.position + Vector2(28, 64), "EMS INBOUND", 44, Color.WHITE, true)
		_text(panel.position + Vector2(panel.size.x - 28, 64), "ETA %d:%02d" % [floori(eta / 60.0), int(eta) % 60], 44, Color.WHITE, true, 400, HORIZONTAL_ALIGNMENT_RIGHT)
		_text(panel.position + Vector2(28, 132), "%s  ·  %s" % [String(inbound.get("unit", "")), String(inbound.get("summary", ""))], 30, Color("ffd9dc"))
		_chip(Rect2(panel.position.x + 28, panel.position.y + 164, 56, 44), int(inbound.get("esi", 2)))
		_text(panel.position + Vector2(100, 198), "ESI %d  →  %s" % [int(inbound.get("esi", 2)), String(inbound.get("bed", ""))], 30, Color.WHITE, true)
	elif not inbound.is_empty():
		draw_rect(panel, Color("16303f"))
		_text(panel.position + Vector2(28, 64), "EMS ARRIVED", 40, Color("7fe0b0"), true)
		_text(panel.position + Vector2(28, 132), "%s  ·  %s" % [String(inbound.get("unit", "")), String(inbound.get("summary", ""))], 30, Color("cfe2e8"))
		_text(panel.position + Vector2(28, 198), "Patient to %s" % String(inbound.get("bed", "")), 30, Color.WHITE, true)
	else:
		draw_rect(panel, Color("16303f"))
		_text(panel.position + Vector2(28, 64), "NO EMS INBOUND", 40, Color("9fb8c6"), true)
		_text(panel.position + Vector2(28, 132), "Radio: EMS will call in with age, mechanism, vitals and ETA", 26, Color("7d97a6"))
	var bays: Array = source.bay_rows() if source else []
	for index in range(mini(bays.size(), 4)):
		var bay: Dictionary = bays[index]
		var rect := Rect2(32 + (index % 2) * 616, 366 + floori(index / 2.0) * 150, 600, 134)
		draw_rect(rect, Color("1a2c3a"))
		draw_rect(Rect2(rect.position, Vector2(10, rect.size.y)), ESI_COLORS.get(int(bay.get("esi", 0)), Color("3d5563")))
		_text(rect.position + Vector2(30, 48), String(bay.bed), 34, Color.WHITE, true)
		_text(rect.position + Vector2(30, 100), String(bay.status), 26, Color("cfe2e8"), false, 540)
	_text(Vector2(32, SIZE.y - 18), "Trauma activations today: %d" % int(info.get("activations", 0)), 20, Color("7d97a6"))

func _waiting() -> void:
	var info: Dictionary = source.status_info() if source else {}
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("13283a"))
	_text(Vector2(56, 110), "Welcome to the Emergency Department", 48, Color.WHITE, true)
	_text(Vector2(56, 178), "Patients are seen in order of medical need, not arrival time.", 30, Color("cfe2e8"))
	_text(Vector2(56, 222), "A triage nurse assesses everyone using the Emergency Severity Index (ESI).", 26, Color("9fb8c6"))
	for level in range(1, 6):
		var y := 270.0 + (level - 1) * 62.0
		_chip(Rect2(56, y, 56, 46), level)
		_text(Vector2(132, y + 34), "Level %d · %s" % [level, ESI_NAMES[level]], 28, Color.WHITE, true)
		_text(Vector2(480, y + 34), ["Immediate life-saving care", "High risk · seen right away", "Stable · needs several tests or treatments", "Stable · needs one test or treatment", "Stable · no tests needed"][level - 1], 24, Color("9fb8c6"))
	draw_rect(Rect2(56, 600, SIZE.x - 112, 72), Color("1d3a52"))
	_text(Vector2(80, 646), "Current wait for less urgent care: about %d min  ·  %s" % [int(info.get("wait", 40)), clock_text()], 28, Color.WHITE, true)
	_text(Vector2(56, 704), "Please tell the triage nurse right away if your symptoms change or get worse.", 22, Color("f2c46d"))

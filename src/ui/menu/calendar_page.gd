extends "res://ui/menu/menu_page.gd"
## Academic Calendar (representative): the current month as a grid with
## today and scheduled events marked, followed by the list of term events.
const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
const CELL := Vector2(80, 38)

func _ready() -> void:
	GameClock.minute_changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func refresh() -> void:
	clear()
	var now := GameClock.snapshot()
	var year: int = now.year
	var month: int = now.month
	var header := HBoxContainer.new()
	var title := UI.label("%s %d" % [MONTHS[month - 1], year], UI.SIZE_TITLE, UI.TEXT, 600)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UI.label("%s · Week %d" % [now.semester, now.academic_week], UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	content.add_child(header)
	var event_days := {}
	for event in GameClock.config.events:
		event_days[event.date] = event
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for name in ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]:
		var label := UI.label(name, UI.SIZE_CAPTION, UI.TEXT_FAINT, 600, true)
		label.custom_minimum_size = Vector2(CELL.x, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(label)
	var first := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string("%04d-%02d-01T12:00:00" % [year, month]))
	for index in range(int(first.weekday)):
		grid.add_child(UI.spacer(CELL.y, CELL.x))
	var days := _days_in_month(year, month)
	for day in range(1, days + 1):
		var date := "%04d-%02d-%02d" % [year, month, day]
		grid.add_child(_day_cell(day, date == now.date, event_days.get(date, {})))
	content.add_child(grid)
	var list := section("Term events", "schedule")
	for event in GameClock.config.events:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var parts: PackedStringArray = String(event.date).split("-")
		row.add_child(UI.label("%s %d" % [MONTHS[int(parts[1]) - 1].left(3), int(parts[2])], UI.SIZE_BODY, UI.TEXT, 600))
		row.add_child(UI.label(clock_text(int(event.hour), int(event.minute)), UI.SIZE_BODY, UI.TEXT_MUTED, 500))
		var name := UI.label(String(event.title).capitalize() + " · " + event.location, UI.SIZE_BODY, UI.TEXT, 500)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		row.add_child(UI.chip("Mandatory" if event.mandatory else "Optional", UI.REWARD if event.mandatory else UI.TEXT_MUTED))
		var status := event_status(event)
		row.add_child(UI.chip(status[0], status[1]))
		list.add_child(row)
	list.add_child(UI.label("More of the term timetable unlocks in later versions.", UI.SIZE_CAPTION, UI.TEXT_FAINT, 400))

func _day_cell(day: int, today: bool, event: Dictionary) -> Control:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL
	var fill := Color(UI.ACCENT, 0.12) if today else Color(1, 1, 1, 0.025)
	cell.add_theme_stylebox_override("panel", UI.box(fill, 7, UI.ACCENT if today else Color.TRANSPARENT, 1 if today else 0, Vector4(8, 4, 8, 4)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	cell.add_child(column)
	column.add_child(UI.label(str(day), UI.SIZE_LABEL, UI.TEXT if today else UI.TEXT_MUTED, 600 if today else 500))
	if not event.is_empty():
		var tag := HBoxContainer.new()
		tag.add_theme_constant_override("separation", 4)
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.draw.connect(func() -> void: dot.draw_circle(Vector2(3, 3), 3, UI.REWARD))
		tag.add_child(dot)
		tag.add_child(UI.label(clock_text(int(event.hour), int(event.minute)), 10, UI.REWARD, 600))
		column.add_child(tag)
	return cell

static func _days_in_month(year: int, month: int) -> int:
	if month == 2:
		return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
	return 30 if month in [4, 6, 9, 11] else 31

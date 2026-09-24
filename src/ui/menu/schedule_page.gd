extends "res://ui/menu/menu_page.gd"
## Today's Schedule (fully functional): a timeline of today's events with
## time, location, requirement, the student's status and any result.

func _ready() -> void:
	GameClock.minute_changed.connect(refresh)
	AcademicSession.attendance_recorded.connect(func(_record: Dictionary) -> void: refresh())
	refresh()

func refresh() -> void:
	clear()
	var snapshot := GameClock.snapshot()
	var date_row := HBoxContainer.new()
	date_row.add_theme_constant_override("separation", 8)
	date_row.add_child(Icon.new("calendar", 16, UI.ACCENT))
	var weekdays := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	var day := UI.label("%s, %s" % [weekdays[int(snapshot.weekday)], GameClock.display_date()], UI.SIZE_BODY, UI.TEXT, 600)
	day.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_row.add_child(day)
	date_row.add_child(UI.label("Now " + GameClock.display_time(), UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	content.add_child(date_row)
	var events := AcademicSession.events_for_date(snapshot.date)
	if events.is_empty():
		empty_state("schedule", "No classes today", "Nothing is scheduled for the rest of the day. Use the time to explore campus or review your Knowledge page.")
		return
	for event in events:
		content.add_child(_event_row(event))

func _event_row(event: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	# Time rail.
	var rail := VBoxContainer.new()
	rail.custom_minimum_size.x = 78
	rail.add_theme_constant_override("separation", 0)
	var time := UI.label(clock_text(int(event.hour), int(event.minute)), UI.SIZE_TITLE, UI.TEXT, 600)
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rail.add_child(time)
	var length := UI.label("50 min", UI.SIZE_CAPTION, UI.TEXT_FAINT, 500)
	length.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rail.add_child(length)
	row.add_child(rail)
	# Event card with an accent edge.
	var card := UI.card(Vector4(18, 14, 18, 14))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
	style.border_width_left = 3
	style.border_color = UI.ACCENT
	card.add_theme_stylebox_override("panel", style)
	row.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var title := UI.label(String(event.title).capitalize(), UI.SIZE_TITLE, UI.TEXT, 600)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var status := event_status(event)
	top.add_child(UI.chip(status[0], status[1]))
	column.add_child(top)
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 6)
	meta.add_child(Icon.new("pin", 13, UI.TEXT_MUTED))
	meta.add_child(UI.label(event.location, UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	meta.add_child(UI.spacer(0, 10))
	meta.add_child(UI.chip("Mandatory" if event.mandatory else "Optional", UI.REWARD if event.mandatory else UI.TEXT_MUTED))
	column.add_child(meta)
	var lecture: Dictionary = AcademicSession.lectures_completed.get(event.id, {})
	var record: Dictionary = AcademicSession.attendance.get(event.date + ":" + event.id, {})
	if not lecture.is_empty():
		column.add_child(UI.label("Lecture complete • %d/%d correct • +%d XP" % [lecture.correct, lecture.attempted, lecture.xp], UI.SIZE_LABEL, UI.SUCCESS, 500))
	elif record.is_empty():
		var penalty := int(event.late_penalty)
		column.add_child(UI.paragraph("Arrive by %s. Arriving late costs %d XP (once)." % [clock_text(int(event.hour), int(event.minute)), penalty] if event.mandatory else "Attendance is optional.", 430, UI.SIZE_LABEL))
	elif record.late:
		column.add_child(UI.paragraph("Arrived late — the %d XP penalty was recorded once. You can still attend and earn XP." % absi(int(record.xp_delta)), 430, UI.SIZE_LABEL))
	else:
		column.add_child(UI.paragraph("You arrived on time. Take a seat in the hall to begin.", 430, UI.SIZE_LABEL))
	return row

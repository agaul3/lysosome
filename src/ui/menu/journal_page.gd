extends "res://ui/menu/menu_page.gd"
## Journal: the story of the first year. The current block and today's
## chapter with its events, then the whole year block by block: story days
## finished, today, coming up, and those still to be written.

func _ready() -> void:
	YearCalendar.day_started.connect(func(_day: Dictionary) -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func refresh() -> void:
	clear()
	var day := YearCalendar.current_day()
	var current_block := YearCalendar.block(String(day.get("block", ""))) if not day.is_empty() else YearCalendar.current_block()
	# Today's chapter.
	var hero := UI.card(Vector4(20, 16, 20, 16), Color(UI.ACCENT_DEEP, 0.22))
	content.add_child(hero)
	var hero_column := VBoxContainer.new()
	hero_column.add_theme_constant_override("separation", 6)
	hero.add_child(hero_column)
	if not current_block.is_empty():
		hero_column.add_child(UI.label("%s · %s" % [current_block.short, current_block.name], UI.SIZE_CAPTION, UI.REWARD, 600, true))
	if day.is_empty() and YearCalendar.year_over():
		hero_column.add_child(UI.label("Summer break", UI.SIZE_TITLE, UI.TEXT, 600))
		hero_column.add_child(UI.paragraph("Your first year of medical school is complete. The clubs, the gym, the library and the Community Kitchen carry on through the summer; second year begins in August.", WIDTH - 40, UI.SIZE_LABEL, UI.TEXT_MUTED))
	elif day.is_empty():
		hero_column.add_child(UI.label("Between chapters", UI.SIZE_TITLE, UI.TEXT, 600))
	else:
		hero_column.add_child(UI.label("Day %d · %s" % [YearCalendar.day_number(), String(day.title)], UI.SIZE_TITLE, UI.TEXT, 600))
		hero_column.add_child(UI.paragraph(String(day.get("intro", "")), WIDTH - 40, UI.SIZE_LABEL, UI.TEXT_MUTED))
		for entry in YearCalendar.events_on(String(day.date)):
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 8)
			var done := YearCalendar.completed(entry) or YearCalendar.attended(entry)
			line.add_child(Icon.new("check" if done else "clock", 14, UI.SUCCESS if done else UI.TEXT_MUTED))
			var hour := int(entry.hour)
			var text := UI.label("%d:%02d %s  %s" % [12 if hour % 12 == 0 else hour % 12, int(entry.minute), "AM" if hour < 12 else "PM", String(entry.title).capitalize()], UI.SIZE_LABEL, UI.TEXT if not done else UI.TEXT_MUTED, 500)
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(text)
			line.add_child(UI.label("Required" if entry.get("mandatory", false) else "Optional", 10, UI.ACCENT if entry.get("mandatory", false) else UI.TEXT_FAINT, 600))
			hero_column.add_child(line)
	# The year.
	var today := YearCalendar.today_date()
	for entry in YearCalendar.data.get("blocks", []):
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", 8)
		heading.add_child(Icon.new("book", 14, UI.ACCENT))
		var title := UI.label("%s · %s" % [String(entry.short).to_upper(), String(entry.name).to_upper()], UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		content.add_child(heading)
		for story in YearCalendar.days.filter(func(candidate: Dictionary) -> bool: return candidate.block == entry.id):
			content.add_child(_story_row(story, today))

func _story_row(story: Dictionary, today: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var finished := YearCalendar.completed_days.has(story.date)
	var is_today: bool = story.date == today
	var ready: bool = story.get("ready", false)
	var state := "Done" if finished else ("Today" if is_today else ("Coming up" if ready else "Later update"))
	var color := UI.SUCCESS if finished else (UI.ACCENT if is_today else (UI.TEXT_MUTED if ready else UI.TEXT_FAINT))
	var moment := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string(String(story.date) + "T12:00:00"))
	var date := UI.label("%s %d" % [["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][int(moment.month) - 1], int(moment.day)], UI.SIZE_LABEL, color, 600)
	date.custom_minimum_size.x = 52
	row.add_child(date)
	var name := UI.label(String(story.title), UI.SIZE_LABEL, UI.TEXT if ready else UI.TEXT_FAINT, 500)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	row.add_child(UI.label(state, 10, color, 600))
	return row

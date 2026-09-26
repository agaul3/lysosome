extends "res://ui/modal_panel.gd"
## "Go to sleep?": ends the story day. Warns about mandatory events today
## that haven't happened yet (sleeping now means missing them) and says what
## tomorrow brings.
signal confirmed

func build() -> void:
	var day := YearCalendar.current_day()
	set_heading("Cedar Residence · %s" % GameClock.display_time(), "Call it a night?")
	var unattended: Array = YearCalendar.unattended_today()
	if not unattended.is_empty():
		var names: Array = unattended.map(func(entry: Dictionary) -> String: return String(entry.title).capitalize())
		var warning := add_text("You haven't attended: %s. Sleeping now counts as an absence%s." % [", ".join(names), ", and a missed exam moves to a make-up" if unattended.any(func(entry: Dictionary) -> bool: return YearCalendar.type_of(entry) == "exam") else ""], UI.DANGER)
		warning.name = "Warning"
	var following := YearCalendar.next_day(String(day.get("date", YearCalendar.today_date())))
	if following.is_empty() and (YearCalendar.year_over() or String(day.get("date", "")) == YearCalendar.last_date()):
		add_text("The first year is over. Tomorrow is a summer day: no classes, just the campus.")
	elif following.is_empty():
		add_text("That's everything built so far. Your first year continues in a later update.")
	else:
		add_text("Next: %s, %s — %s." % [YearCalendar.weekday_name(following.date), _date_text(following.date), following.title])
	var hour := int(GameClock.snapshot().hour)
	if hour >= YearCalendar.BEDTIME_HOUR and hour <= 23:
		add_text("An early night: you'll wake up Well Rested (+5% XP until midday).", UI.SUCCESS, UI.SIZE_LABEL)
	add_button("Not yet", close)
	add_button("Sleep", func() -> void: confirmed.emit(), true)

static func _date_text(date: String) -> String:
	var moment := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string(date + "T12:00:00"))
	return GameClock.format_date(moment.year, moment.month, moment.day)

extends VBoxContainer
signal closed
@export var calendar := false
var body: Label
var back_button: Button

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(350, 230)
	body.add_theme_font_size_override("font_size", 18)
	add_child(body)
	back_button = Button.new()
	back_button.text = "Back to exploration"
	back_button.custom_minimum_size.y = 44
	back_button.pressed.connect(func() -> void: closed.emit())
	add_child(back_button)
	GameClock.minute_changed.connect(refresh)
	AcademicSession.attendance_recorded.connect(func(_record: Dictionary) -> void: refresh())
	refresh()

func refresh() -> void:
	var date: String = GameClock.snapshot().date
	var events: Array = GameClock.config.events if calendar else AcademicSession.events_for_date(date)
	body.text = ("Academic Calendar" if calendar else "Today's Schedule") + "\n" + date + " • " + GameClock.display_time() + "\n\n"
	if events.is_empty():
		body.text += "No scheduled events for today."
	for event in events:
		var hour: int = int(event.hour) % 12
		body.text += "%s\n%d:%02d %s — %s\n%s • %s\n" % [event.date, 12 if hour == 0 else hour, event.minute, "AM" if event.hour < 12 else "PM", event.title, event.location, "MANDATORY" if event.mandatory else "OPTIONAL"]
		var record: Dictionary = AcademicSession.attendance.get(event.date + ":" + event.id, {})
		body.text += ("Not yet attended" if record.is_empty() else ("Late • %d XP" % record.xp_delta if record.late else "Arrived on time")) + "\n"
		var lecture: Dictionary = AcademicSession.lectures_completed.get(event.id, {})
		if not lecture.is_empty():
			body.text += "Lecture complete • %d/%d correct • +%d XP\n" % [lecture.correct, lecture.attempted, lecture.xp]
		body.text += "\n"
	body.text += "XP balance: %d\nTime continues while this menu is open." % AcademicSession.xp_balance
	body.text = body.text.replace("\n", "
")

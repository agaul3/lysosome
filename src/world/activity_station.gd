extends "res://world/interactable.gd"
## Where a scheduled activity happens in a building: the histology benches,
## a standardized-patient room, the Testing Center's desk, the anatomy
## lab's table, the theatre… (data/year_one.json events carry the scene key
## as "place" and the spot as "room"). When an event here is on (from half
## an hour before it starts until it ends) and not yet done, the prompt says
## so and interacting opens it: education/activities/<content>.json in the
## activity panel, or the exam panel for exams. Otherwise it shows the idle
## title and text it was given.
const ActivityPanel = preload("res://ui/activity_panel.gd")
const ExamPanel = preload("res://ui/exam_panel.gd")
const EARLY := 30.0 * 60.0
var place := ""
var room := ""
var hud: CanvasLayer
var idle_title := ""
var idle_text := ""
## Out of the way between events (nothing to say there otherwise).
var hide_when_idle := false

## `rooms` may list several rooms separated by commas (a desk that serves them all).
func setup(scene_key: String, rooms: String, owner_hud: CanvasLayer, title: String, text := "") -> void:
	place = scene_key
	room = rooms
	hud = owner_hud
	idle_title = title
	idle_text = text
	display_name = title
	response = text

func _ready() -> void:
	super()
	activated.connect(_open)
	refresh()
	GameClock.minute_changed.connect(refresh)

## Today's event here that's on now, or {}.
func current_event() -> Dictionary:
	var now := GameClock.now_seconds()
	var rooms := room.split(",", false)
	for event in YearCalendar.events_on(YearCalendar.today_date()):
		if String(event.get("place", "")) != place:
			continue
		if not rooms.is_empty() and not rooms.has(String(event.get("room", ""))):
			continue
		if YearCalendar.completed(event):
			continue
		if now >= YearCalendar.start_of(event) - EARLY and now < YearCalendar.end_of(event):
			return event
	return {}

func refresh() -> void:
	var event := current_event()
	if event.is_empty():
		display_name = idle_title
		response = idle_text
	else:
		display_name = "Begin: " + String(event.title).capitalize()
		response = ""
	var available := not event.is_empty() or not hide_when_idle
	if available and not is_in_group("interactables"):
		add_to_group("interactables")
	elif not available and is_in_group("interactables"):
		remove_from_group("interactables")
		set_highlighted(false)

func _open() -> void:
	var event := current_event()
	if event.is_empty() or not is_instance_valid(hud):
		return
	var activity := ActivityPanel.load_activity(String(event.get("content", event.id)))
	if activity.is_empty():
		hud.show_message("This session isn't ready yet.", 4.0)
		return
	if String(activity.get("kind", "")) == "exam":
		hud.open_modal(ExamPanel.new(activity, event))
	else:
		hud.open_modal(ActivityPanel.new(activity, event))

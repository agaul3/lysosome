extends "res://ui/clubs/club_event_panel.gd"
## Community Kitchen Volunteers: the supper line at the Harbor Street
## Community Center. Guests come up one at a time and say what they need;
## you plate a main and a side that fit (vegetarian, no dairy, soft food for
## new dentures, nothing spicy…) before the line backs up. Every correct
## plate is a meal served (Community Kitchen Hero counts them). Then a word
## with the site coordinator, and questions on food insecurity.
const SERVICE_SECONDS := 100.0
const GUESTS := 10
## Dishes on the line and what they are.
const MAINS := {
	"chicken": ["Roast chicken & rice", ["meat"]],
	"curry": ["Chickpea & vegetable curry", ["vegetarian", "vegan", "spicy"]],
	"pasta": ["Baked pasta with cheese", ["vegetarian", "dairy", "soft"]],
	"soup": ["Lentil soup", ["vegetarian", "vegan", "soft"]],
}
const SIDES := {
	"salad": ["Green salad", ["vegetarian", "vegan"]],
	"mash": ["Mashed potatoes (butter, milk)", ["vegetarian", "dairy", "soft"]],
	"squash": ["Roasted squash", ["vegetarian", "vegan", "soft"]],
	"roll": ["Dinner roll", ["vegetarian", "vegan"]],
}
## Guests: [name, what they say, tags every dish must have, tags no dish may
## have, tags the main must have].
const REQUESTS := [
	["Walter", "\"Vegetarian, please. Has been for forty years.\"", ["vegetarian"], [], []],
	["Denise", "\"I just got new dentures. Something soft, if you've got it?\"", ["soft"], [], []],
	["Luis", "\"For my daughter. She's allergic to milk.\"", [], ["dairy"], []],
	["Mrs. Obi", "\"Nothing spicy, please. My stomach won't have it.\"", [], ["spicy"], []],
	["Jordan", "\"I'm vegan. Is there anything for me?\"", ["vegan"], [], []],
	["Tom", "\"Whatever's hot. I've been outside all day.\"", [], [], []],
	["Grace", "\"Soft food, and no dairy, please. It's been a hard week.\"", ["soft"], ["dairy"], []],
	["Ahmed", "\"No meat for me, thank you.\"", ["vegetarian"], [], []],
	["Keisha", "\"My son's seven. Nothing too spicy for him.\"", [], ["spicy"], []],
	["Frank", "\"I'm off dairy. It doesn't agree with me.\"", [], ["dairy"], []],
	["Hannah", "\"Vegetarian, and I can't do spicy.\"", ["vegetarian"], ["spicy"], []],
	["Dev", "\"Any meat you've got. I'm starving.\"", [], [], ["meat"]],
]
## What the coordinator tells you as the line winds down (flagged for review).
const TALKS := [
	"\"Most people here work. They just can't make the money last to the end of the month. When the rent goes up, food is the bill that gives.\"",
	"\"A lot of our regulars have diabetes or high blood pressure. When you're choosing between groceries and medication, both lose.\"",
	"\"Ask your patients about food. Two questions: did you worry your food would run out, and did it run out before you could buy more? It's called the Hunger Vital Sign.\"",
]
var time_left := SERVICE_SECONDS
var order: Array = []
var guest_index := 0
var served := 0
var main_pick := ""
var side_pick := ""
var guest_label: Label
var request_label: Label
var clock_label: Label
var tally_label: Label
var main_buttons := {}
var side_buttons := {}
var serve_button: Button
var note: Label
var running := false

func activity_title() -> String:
	return "Supper service"

func activity_intro() -> String:
	if event_id == "thanksgiving_meal":
		return "Thanksgiving at Harbor Street: the kitchen has been cooking since noon, half your class has signed up to help, and the line is out the door. Aprons on. Listen to each guest, plate a main and a side that suit them, and keep the line moving."
	return "Aprons on. Tonight the Community Kitchen serves supper to anyone who comes, no questions asked. You're on the line: listen to each guest, plate a main and a side that suit them, and keep the line moving. About a hundred seconds of service."

func energy_cost() -> float:
	return 12.0

func questions_per_meeting() -> int:
	return 2

func start_activity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("kitchen:" + YearCalendar.today_date())
	order = range(REQUESTS.size())
	for index in range(order.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: int = order[index]
		order[index] = order[other]
		order[other] = swap
	order = order.slice(0, GUESTS)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	clock_label = UI.label("", UI.SIZE_LABEL, UI.REWARD, 600)
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(clock_label)
	tally_label = UI.label("", UI.SIZE_LABEL, UI.SUCCESS, 600)
	top.add_child(tally_label)
	body.add_child(top)
	var card := UI.card(Vector4(14, 10, 14, 10))
	var column := VBoxContainer.new()
	card.add_child(column)
	guest_label = UI.label("", UI.SIZE_TITLE, UI.TEXT, 600)
	column.add_child(guest_label)
	request_label = UI.paragraph("", width - 90, UI.SIZE_BODY, UI.TEXT)
	column.add_child(request_label)
	body.add_child(card)
	body.add_child(UI.label("MAIN", UI.SIZE_CAPTION, UI.TEXT_FAINT, 600, true))
	body.add_child(_row(MAINS, main_buttons, "Main_", _pick_main))
	body.add_child(UI.label("SIDE", UI.SIZE_CAPTION, UI.TEXT_FAINT, 600, true))
	body.add_child(_row(SIDES, side_buttons, "Side_", _pick_side))
	note = UI.paragraph("", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	body.add_child(note)
	serve_button = add_button("Serve", serve, true)
	serve_button.name = "Serve"
	running = true
	_show_guest()

func _row(dishes: Dictionary, store: Dictionary, prefix: String, action: Callable) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	for id in dishes:
		var button := Button.new()
		button.name = prefix + String(id)
		button.text = String(dishes[id][0])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2((width - 60) / 2.0, 34)
		button.pressed.connect(action.bind(String(id)))
		grid.add_child(button)
		store[id] = button
	return grid

func _pick_main(id: String) -> void:
	main_pick = id
	for key in main_buttons:
		(main_buttons[key] as Button).set_pressed_no_signal(key == id)
	_update_serve()

func _pick_side(id: String) -> void:
	side_pick = id
	for key in side_buttons:
		(side_buttons[key] as Button).set_pressed_no_signal(key == id)
	_update_serve()

func _update_serve() -> void:
	serve_button.disabled = main_pick.is_empty() or side_pick.is_empty()

func _show_guest() -> void:
	var request: Array = REQUESTS[order[guest_index]]
	guest_label.text = "%s  ·  guest %d of %d" % [request[0], guest_index + 1, order.size()]
	request_label.text = String(request[1])
	main_pick = ""
	side_pick = ""
	for button in main_buttons.values() + side_buttons.values():
		(button as Button).set_pressed_no_signal(false)
	_update_serve()
	_update_labels()

## Whether a main and side suit a request.
static func suits(request: Array, main: String, side: String) -> bool:
	for needed in request[4]:
		if not MAINS[main][1].has(needed):
			return false
	for dish in [MAINS[main], SIDES[side]]:
		var tags: Array = dish[1]
		for needed in request[2]:
			if not tags.has(needed):
				return false
		for banned in request[3]:
			if tags.has(banned):
				return false
	return true

func serve() -> void:
	if not running or main_pick.is_empty() or side_pick.is_empty():
		return
	var request: Array = REQUESTS[order[guest_index]]
	if suits(request, main_pick, side_pick):
		served += 1
		note.add_theme_color_override("font_color", UI.SUCCESS)
		note.text = "%s thanks you and finds a seat." % request[0]
		Sfx.play("correct")
	else:
		note.add_theme_color_override("font_color", UI.DANGER)
		note.text = "%s hands the plate back: that doesn't work for them. A volunteer re-plates it." % request[0]
		Sfx.play("incorrect")
		time_left -= 4.0
	guest_index += 1
	if guest_index >= order.size():
		_end_service()
	else:
		_show_guest()

func _update_labels() -> void:
	clock_label.text = "Service  %d s" % int(ceil(maxf(0.0, time_left)))
	tally_label.text = "Served %d" % served

func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	_update_labels()
	if time_left <= 0.0:
		_end_service()

func _end_service() -> void:
	if not running:
		return
	running = false
	var talk: String = TALKS[absi(hash(YearCalendar.today_date())) % TALKS.size()]
	var missed := order.size() - guest_index
	var summary := "You served %d of %d plates correctly%s. The site coordinator, Mrs. Alvarez, hands you a cup of tea: %s" % [served, order.size(), (", and %d guests were still waiting when the pans ran low" % missed) if missed > 0 else "", talk]
	activity_done(float(served) / float(order.size()), summary)

func on_recorded(_record: Dictionary) -> void:
	Achievements.bump("meals_served", served)
	# Volunteers eat with the guests afterwards.
	Wellbeing.consume("community_supper")

func completion_text() -> String:
	return "%d meals served · supper with the guests: +%d energy, Shared Table +6%% XP for three hours." % [served, int(Items.get_item("community_supper").energy)]

func _unhandled_input(event: InputEvent) -> void:
	if stage == "activity" and running and event is InputEventKey and event.pressed and not event.echo:
		var keys := [KEY_1, KEY_2, KEY_3, KEY_4]
		var sides := [KEY_Q, KEY_W, KEY_E, KEY_R]
		if keys.has(event.keycode):
			_pick_main(String(MAINS.keys()[keys.find(event.keycode)]))
			get_viewport().set_input_as_handled()
			return
		if sides.has(event.keycode):
			_pick_side(String(SIDES.keys()[sides.find(event.keycode)]))
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_ENTER, KEY_SPACE] and not serve_button.disabled:
			serve()
			get_viewport().set_input_as_handled()
			return
	super(event)

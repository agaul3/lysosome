extends "res://ui/modal_panel.gd"
## The campus shuttle's route card at a stop: every other stop with its ride
## time. Riding is fast travel that costs game time; the caller moves the
## student (campus.gd ride_shuttle, or the Community Center back to campus).
## The loop runs from 6 AM to 1 AM.
signal ride(to_stop: String, minutes: int)
## id: [stop name, where it is, map position (for ride times)]
const STOPS := {
	"quad": ["Cedar Residence · Quad", "The residence hall and the Learning Center", Vector2(-18.6, 12.3)],
	"hospital": ["University Hospital", "Main entrance and the Emergency Department", Vector2(32.4, 23.2)],
	"east": ["East Campus · Student Center", "Medical Education Center, Biomedical Library, Student Center", Vector2(92.0, 22.6)],
	"community": ["Harbor Street Community Center", "Off campus: the Community Kitchen and the Student-Run Free Clinic", Vector2(260.0, 140.0)],
}
const FIRST_HOUR := 6
const LAST_HOUR := 1
var stop := ""

func _init(at_stop: String) -> void:
	super(540.0)
	stop = at_stop

## Minutes on the bus between two stops (about 20 m a second with stops,
## plus the wait at the stop), never under 3.
static func minutes_between(from: String, to: String) -> int:
	var a: Vector2 = STOPS[from][2]
	var b: Vector2 = STOPS[to][2]
	return maxi(3, int(round(a.distance_to(b) / 20.0)) + 2)

static func running() -> bool:
	var hour := int(GameClock.snapshot().hour)
	return hour >= FIRST_HOUR or hour < LAST_HOUR

func build() -> void:
	set_heading("Campus shuttle", String(STOPS.get(stop, ["Shuttle stop"])[0]))
	if not running():
		add_text("The shuttle has stopped for the night. The first bus leaves at 6:00 AM.")
		add_button("Close", close, true)
		return
	add_text("Free for students and staff. Buses loop every few minutes.", UI.TEXT_FAINT, UI.SIZE_LABEL)
	var first := true
	for id in STOPS:
		if id == stop:
			continue
		var minutes := minutes_between(stop, id)
		var card := UI.card(Vector4(12, 8, 12, 8))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		row.add_child(Icon.new("pin", 16, UI.ACCENT))
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 1)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		text.add_child(UI.label(String(STOPS[id][0]), UI.SIZE_BODY, UI.TEXT, 600))
		text.add_child(UI.label(String(STOPS[id][1]), UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
		row.add_child(UI.label("%d min" % minutes, UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
		var go := Button.new()
		go.name = "Ride_" + id
		go.text = "Ride"
		go.theme_type_variation = "PrimaryButton" if first else ""
		go.pressed.connect(func() -> void:
			Sfx.play("ui_confirm")
			ride.emit(id, minutes))
		row.add_child(go)
		body.add_child(card)
		first = false
	add_button("Walk instead", close)

func _focus_first() -> void:
	for child in body.find_children("Ride_*", "Button", true, false):
		(child as Button).grab_focus()
		return
	super()

extends "res://ui/clubs/club_event_panel.gd"
## Surgery Interest Group: a suturing workshop on a skin pad. Six simple
## interrupted sutures along a 6 cm incision, each in two moves (Space or E):
## first stop the needle driver, which slides along the wound, where the next
## evenly spaced stitch belongs; then, as the needle rocks, drive it when
## it's perpendicular to the skin (which everts the edges). Scored on spacing
## and entry angle; the Steady Hands perk widens both windows. If the driver
## runs off the end of the wound, the stitches left are missed. Then the
## residents' questions.
const STITCHES := 6
## Seconds for the driver to cross the incision, and for the needle to rock
## once (±ROCK_DEGREES).
const SWEEP := 11.0
const ROCK := 2.4
const ROCK_DEGREES := 35.0
var along := 0.0
var angle := 0.0
var rock_clock := 0.0
## "position" (the driver slides) or "angle" (it's stopped; the needle rocks).
var phase := "position"
var entry := 0.0
var placed: Array = []
var running := false
var pad: Control
var note: Label

func activity_title() -> String:
	return "Suturing workshop"

func activity_intro() -> String:
	return "A surgery resident hands you a needle driver, Adson forceps and a skin pad with a 6 cm incision. \"Six simple interrupted sutures. Enter at ninety degrees, follow the curve of the needle, and space them evenly: about as far apart as each bite is from the edge.\""

func energy_cost() -> float:
	return 6.0

func questions_per_meeting() -> int:
	return 2

## Ideal positions along the wound (0–1): evenly spaced, with the ends a half-gap in.
func ideal(index: int) -> float:
	return (index + 0.5) / float(STITCHES)

func window() -> float:
	return 1.0 + Skills.effect("skills:window")

func start_activity() -> void:
	pad = Control.new()
	pad.name = "SkinPad"
	pad.custom_minimum_size = Vector2(width - 52, 250)
	pad.draw.connect(_draw_pad)
	body.add_child(pad)
	note = UI.paragraph("Stop the driver where the first stitch belongs (Space or E).", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	body.add_child(note)
	var place := add_button("Place", stitch, true)
	place.name = "PlaceStitch"
	running = true

func _process(delta: float) -> void:
	if not running:
		return
	if phase == "position":
		along = minf(1.0, along + delta / SWEEP)
		angle = 0.0
		if along >= 1.0:
			_end()
	else:
		rock_clock += delta
		angle = sin(rock_clock / ROCK * TAU) * ROCK_DEGREES
	pad.queue_redraw()

## Scores one stitch: spacing (distance, in stitch gaps, from where the next
## belongs) and how square the needle entered.
func stitch_score(position: float, tilt: float, index: int) -> float:
	var spacing_error := absf(position - ideal(index)) * STITCHES
	var spacing := clampf(1.0 - maxf(0.0, spacing_error - 0.12 * window()) / 0.38, 0.0, 1.0)
	var square := clampf(1.0 - maxf(0.0, absf(tilt) - 8.0 * window()) / 25.0, 0.0, 1.0)
	return spacing * 0.5 + square * 0.5

func stitch() -> void:
	if not running or placed.size() >= STITCHES:
		return
	if phase == "position":
		entry = along
		phase = "angle"
		# The rock starts at its widest, so the timing is the player's.
		rock_clock = ROCK * 0.25
		note.add_theme_color_override("font_color", UI.TEXT_MUTED)
		note.text = "Driver set. Now drive the needle when it's square to the skin."
		return
	phase = "position"
	var score := stitch_score(entry, angle, placed.size())
	var well_spaced := absf(entry - ideal(placed.size())) * STITCHES < 0.2 * window()
	placed.append([entry, angle, score])
	note.add_theme_color_override("font_color", UI.SUCCESS if score >= 0.75 else (UI.REWARD if score >= 0.4 else UI.DANGER))
	note.text = "Stitch %d: %s, %s." % [placed.size(), "square to the skin" if absf(angle) < 8.0 * window() else ("a little oblique" if absf(angle) < 20.0 else "too oblique; the edges will invert"), "well spaced" if well_spaced else "spacing off"]
	Sfx.play("ui_confirm")
	if placed.size() >= STITCHES:
		_end()

func _end() -> void:
	if not running:
		return
	running = false
	var total := 0.0
	for entry_data in placed:
		total += float(entry_data[2])
	var score := total / float(STITCHES)
	var verdict := "\"Beautiful. I'd let you close in the OR.\"" if score >= 0.8 else ("\"Nice work. Watch that entry angle.\"" if score >= 0.5 else "\"Keep practising. Slow down and let the needle's curve do the work.\"")
	activity_done(score, "%d of %d stitches placed; average %d%%. The resident: %s" % [placed.size(), STITCHES, int(round(score * 100)), verdict])

func _draw_pad() -> void:
	var size := pad.size
	var rect := Rect2(Vector2(20, 20), size - Vector2(40, 40))
	pad.draw_rect(rect, Color("e3b08c"))
	pad.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 8)), Color("d69c77"))
	var y := rect.position.y + rect.size.y * 0.5
	var x0 := rect.position.x + 50
	var x1 := rect.end.x - 50
	pad.draw_line(Vector2(x0, y), Vector2(x1, y), Color("7a3b2e"), 3.0)
	for entry_data in placed:
		var x: float = lerpf(x0, x1, float(entry_data[0]))
		var lean := float(entry_data[1]) / 90.0 * 14.0
		pad.draw_line(Vector2(x - lean, y - 18), Vector2(x + lean, y + 18), Color("1d2b52"), 3.0)
		pad.draw_circle(Vector2(x + 7, y - 20), 3.5, Color("1d2b52"))
	if running:
		var x := lerpf(x0, x1, along if phase == "position" else entry)
		var tilt := deg_to_rad(angle)
		var up := Vector2(sin(tilt), -cos(tilt))
		pad.draw_line(Vector2(x, y) - up * 40, Vector2(x, y) + up * 40, Color("9aa3a8"), 4.0)
		pad.draw_arc(Vector2(x, y) + up * 44, 12, 0, TAU, 16, Color("5b6c74"), 2.0)
	var font := UI.font(500)
	var status := "slide the driver" if phase == "position" else "needle %+d°" % int(round(angle))
	pad.draw_string(font, Vector2(rect.position.x + 12, rect.end.y - 12), "Stitch %d of %d  ·  %s" % [mini(placed.size() + 1, STITCHES), STITCHES, status], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5b3b27"))

func _unhandled_input(event: InputEvent) -> void:
	if stage == "activity" and running and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)):
		stitch()
		get_viewport().set_input_as_handled()
		return
	super(event)

extends "res://ui/clubs/club_event_panel.gd"
## Emergency Medicine Interest Group: hands-only CPR on the feedback manikin.
## Two cycles of 30 compressions (Space or E), keeping the rate between 100
## and 120 a minute; between them the AED analyzes, and nobody may touch the
## patient. Scored on the share of compressions in the target rate (the
## Steady Hands perk widens it); 80% or more earns Lifesaver.
const PER_CYCLE := 30
const CYCLES := 2
## Seconds the AED spends analyzing between cycles.
const ANALYZE := 3.0
var clock := 0.0
var last_press := -1.0
var intervals: Array = []
var compressions := 0
var cycle := 0
var analyzing := 0.0
var touched := false
var running := false
var meter: Control
var note: Label
var rate_now := 0.0

func activity_title() -> String:
	return "CPR skills night"

func activity_intro() -> String:
	return "The feedback manikin lights up with every compression. \"Hands in the middle of the chest, arms straight, push hard and fast: a hundred to a hundred and twenty a minute, and let the chest come all the way back up. Think of a song around a hundred and ten beats a minute.\" Two cycles of thirty; when the AED analyzes, hands off."

func energy_cost() -> float:
	return 10.0

func questions_per_meeting() -> int:
	return 2

## The target interval between compressions (seconds), widened by the perk.
func target() -> Vector2:
	var slack := 0.02 * Skills.effect("skills:window") * 2.5
	return Vector2(60.0 / 120.0 - slack, 60.0 / 100.0 + slack)

func start_activity() -> void:
	meter = Control.new()
	meter.name = "Manikin"
	meter.custom_minimum_size = Vector2(width - 52, 210)
	meter.draw.connect(_draw_meter)
	body.add_child(meter)
	note = UI.paragraph("Compress with Space or E.", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	body.add_child(note)
	var push := add_button("Compress", compress, true)
	push.name = "Compress"
	running = true

func _process(delta: float) -> void:
	if not running:
		return
	clock += delta
	if analyzing > 0.0:
		analyzing -= delta
		if analyzing <= 0.0:
			note.add_theme_color_override("font_color", UI.TEXT)
			note.text = "\"No shock advised. Resume CPR.\" Cycle %d: go." % (cycle + 1)
			last_press = -1.0
	meter.queue_redraw()

func compress() -> void:
	if not running:
		return
	if analyzing > 0.0:
		touched = true
		note.add_theme_color_override("font_color", UI.DANGER)
		note.text = "\"Stand clear! Don't touch the patient while I analyze.\""
		Sfx.play("incorrect")
		return
	if last_press >= 0.0:
		var interval := clock - last_press
		intervals.append(interval)
		rate_now = 60.0 / maxf(0.05, interval)
	last_press = clock
	compressions += 1
	Sfx.play("ui_move")
	var window := target()
	if intervals.size() > 0:
		var last: float = intervals[-1]
		note.add_theme_color_override("font_color", UI.SUCCESS if last >= window.x and last <= window.y else UI.REWARD)
		note.text = "%d / %d  ·  %d per minute  %s" % [compressions, PER_CYCLE, int(round(rate_now)), "Good rate." if last >= window.x and last <= window.y else ("Faster!" if last > window.y else "A little slower.")]
	if compressions >= PER_CYCLE:
		compressions = 0
		cycle += 1
		if cycle >= CYCLES:
			_end()
		else:
			analyzing = ANALYZE
			note.add_theme_color_override("font_color", UI.REWARD)
			note.text = "\"Analyzing heart rhythm. Do not touch the patient.\""

## Share of compressions in the target rate.
func rate_score() -> float:
	if intervals.is_empty():
		return 0.0
	var window := target()
	var good := intervals.filter(func(value: float) -> bool: return value >= window.x and value <= window.y).size()
	return float(good) / float(intervals.size())

func _end() -> void:
	running = false
	var score := rate_score()
	if touched:
		score *= 0.85
	if score >= 0.8:
		Achievements.set_flag("cpr_passed")
	var average := 0.0
	for value in intervals:
		average += float(value)
	average = 60.0 / maxf(0.05, average / maxf(1.0, intervals.size()))
	activity_done(score, "Two cycles done: %d%% of compressions in the 100–120 range, average %d a minute%s. %s" % [int(round(rate_score() * 100)), int(round(average)), "; you touched the patient during analysis" if touched else "", "The EMIG president signs your card: skills checked." if score >= 0.8 else "\"Again next week. Get that rhythm into your hands.\""])

func _draw_meter() -> void:
	var size := meter.size
	# The manikin's chest, lit by each compression.
	var chest := Rect2(Vector2(24, 30), Vector2(size.x * 0.42, size.y - 60))
	meter.draw_rect(chest, Color("e3c4a8"))
	var pressed := last_press >= 0.0 and clock - last_press < 0.15
	meter.draw_circle(chest.get_center(), 26 if pressed else 22, Color(UI.ACCENT, 0.9 if pressed else 0.35))
	# The rate gauge: 60–160 per minute, the target band shaded.
	var bar := Rect2(Vector2(size.x * 0.52, size.y * 0.42), Vector2(size.x * 0.42, 26))
	meter.draw_rect(bar, Color("2a3238"))
	var window := target()
	var low := 60.0 / window.y
	var high := 60.0 / window.x
	var band := Rect2(bar.position + Vector2((low - 60.0) / 100.0 * bar.size.x, 0), Vector2((high - low) / 100.0 * bar.size.x, bar.size.y))
	meter.draw_rect(band, Color(UI.SUCCESS, 0.45))
	if rate_now > 0.0:
		var x := bar.position.x + clampf((rate_now - 60.0) / 100.0, 0.0, 1.0) * bar.size.x
		meter.draw_line(Vector2(x, bar.position.y - 8), Vector2(x, bar.end.y + 8), UI.REWARD, 3.0)
	var font := UI.font(500)
	meter.draw_string(font, bar.position + Vector2(0, -14), "Rate (per minute)   100–120", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.TEXT_MUTED)
	meter.draw_string(font, bar.position + Vector2(0, 50), "Cycle %d of %d  ·  %d / %d" % [mini(cycle + 1, CYCLES), CYCLES, compressions, PER_CYCLE], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.TEXT)
	if analyzing > 0.0:
		meter.draw_string(font, bar.position + Vector2(0, 76), "AED ANALYZING · STAND CLEAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.DANGER)

func _unhandled_input(event: InputEvent) -> void:
	if stage == "activity" and running and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)):
		compress()
		get_viewport().set_input_as_handled()
		return
	super(event)

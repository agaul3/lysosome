extends "res://ui/clubs/club_event_panel.gd"
## Intramural Sports: pick-up soccer on the quad lawn against the M2s, decided
## (as always) by penalties. Five kicks, two presses each (Space or E): stop
## the aim as it sweeps across the goal, then the power as it rises and falls.
## The keeper guesses a third of the goal; shots there are saved, shots
## outside the green power band go over or roll in weakly and are saved. Win
## or lose, an hour of running earns Team Spirit (a boost to learning XP).
const KICKS := 5
const AIM_SWEEP := 1.4
const POWER_SWEEP := 1.1
var kick := 0
var goals := 0
var phase := "aim"
var clock := 0.0
var aim := 0.0
var power := 0.0
var keeper := 0
var shots: Array = []
var running := false
var pitch: Control
var note: Label
var rng := RandomNumberGenerator.new()

func activity_title() -> String:
	return "Pick-up soccer on the quad"

func activity_intro() -> String:
	return "Fifty minutes of running around the quad lawn with the M1s against the M2s. It ends level, so it's penalties: five kicks each, and you're taking yours."

func energy_cost() -> float:
	return 16.0

func questions_per_meeting() -> int:
	return 0

func question_pool() -> Array:
	return []

func start_activity() -> void:
	rng.seed = hash("penalties:" + YearCalendar.today_date())
	pitch = Control.new()
	pitch.name = "Goal"
	pitch.custom_minimum_size = Vector2(width - 52, 230)
	pitch.draw.connect(_draw_goal)
	body.add_child(pitch)
	note = UI.paragraph("Stop the aim where you want to shoot (Space or E).", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	body.add_child(note)
	var shoot := add_button("Kick", press, true)
	shoot.name = "Kick"
	keeper = rng.randi_range(0, 2)
	running = true

func _process(delta: float) -> void:
	if not running:
		return
	clock += delta
	if phase == "aim":
		aim = (sin(clock / AIM_SWEEP * TAU) + 1.0) / 2.0
	elif phase == "power":
		power = (sin(clock / POWER_SWEEP * TAU - PI / 2.0) + 1.0) / 2.0
	pitch.queue_redraw()

## Whether a shot at `aim_at` (0–1 across the goal) with `strength` (0–1)
## beats a keeper diving to third `dive` (0 left, 1 centre, 2 right).
static func scores(aim_at: float, strength: float, dive: int) -> bool:
	if strength < 0.55 or strength > 0.9:
		return false
	return int(clampf(aim_at, 0.0, 0.999) * 3.0) != dive

func press() -> void:
	if not running:
		return
	if phase == "aim":
		phase = "power"
		clock = 0.0
		note.text = "Now the power: into the green (Space or E)."
		return
	var goal := scores(aim, power, keeper)
	shots.append([aim, power, goal, keeper])
	if goal:
		goals += 1
		Sfx.play("correct")
	else:
		Sfx.play("incorrect")
	var where: String = ["left", "down the middle", "right"][int(clampf(aim, 0.0, 0.999) * 3.0)]
	note.add_theme_color_override("font_color", UI.SUCCESS if goal else UI.DANGER)
	note.text = "Kick %d: %s, %s. %s" % [kick + 1, where, "struck well" if power >= 0.55 and power <= 0.9 else ("too soft" if power < 0.55 else "skied it"), "GOAL!" if goal else ("The keeper guessed right." if power >= 0.55 and power <= 0.9 else "Saved.")]
	kick += 1
	phase = "aim"
	clock = 0.0
	keeper = rng.randi_range(0, 2)
	if kick >= KICKS:
		running = false
		var won := goals >= 3
		activity_done(float(goals) / float(KICKS), "%d of %d penalties scored. %s" % [goals, KICKS, "The M1s win the shoot-out! You're carried off the lawn." if won else "The M2s win it this time. Rematch next week."])

func on_recorded(_record: Dictionary) -> void:
	Wellbeing.add_boost("exercise", "Team Spirit", 0.06, 180.0, "bolt", "intramurals")

func completion_text() -> String:
	return "Team Spirit: +6% learning XP for three hours."

func _draw_goal() -> void:
	var size := pitch.size
	pitch.draw_rect(Rect2(Vector2.ZERO, size), Color("3f7f45"))
	var goal := Rect2(Vector2(size.x * 0.15, 30), Vector2(size.x * 0.7, size.y * 0.5))
	for third in range(3):
		pitch.draw_rect(Rect2(goal.position + Vector2(goal.size.x * third / 3.0, 0), Vector2(goal.size.x / 3.0, goal.size.y)), Color(1, 1, 1, 0.05 + 0.04 * (third % 2)))
	pitch.draw_rect(goal, Color.WHITE, false, 4.0)
	# The keeper, leaning toward where they'll dive once you've aimed.
	var lean := 0.0 if phase == "aim" else float(keeper - 1) * 0.28
	var keeper_x := goal.position.x + goal.size.x * (0.5 + lean)
	pitch.draw_rect(Rect2(Vector2(keeper_x - 14, goal.end.y - 70), Vector2(28, 70)), Color("e8b923"))
	# Aim marker and power bar.
	var aim_x := goal.position.x + goal.size.x * aim
	pitch.draw_circle(Vector2(aim_x, goal.position.y + goal.size.y * 0.55), 9, Color("f2f2ef"))
	var bar := Rect2(Vector2(size.x * 0.15, size.y - 44), Vector2(size.x * 0.7, 16))
	pitch.draw_rect(bar, Color("1f2f22"))
	pitch.draw_rect(Rect2(bar.position + Vector2(bar.size.x * 0.55, 0), Vector2(bar.size.x * 0.35, bar.size.y)), Color(UI.SUCCESS, 0.55))
	if phase == "power":
		pitch.draw_rect(Rect2(bar.position, Vector2(bar.size.x * power, bar.size.y)), Color(UI.REWARD, 0.8))
	var font := UI.font(600)
	pitch.draw_string(font, Vector2(12, 20), "M1s %d · kick %d of %d" % [goals, mini(kick + 1, KICKS), KICKS], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _unhandled_input(event: InputEvent) -> void:
	if stage == "activity" and running and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)):
		press()
		get_viewport().set_input_as_handled()
		return
	super(event)

extends "res://ui/modal_panel.gd"
## The Student Center's Fitness Center: pick a workout. It takes game time
## and energy now, and pays it back: an Endorphins boost (+XP from learning
## for a few hours, stronger with the Runner's High perk) and, after a good
## shower, a little energy. Once every few hours; counts toward Gym Regular
## and Balance.
const WORKOUTS := [
	{"id": "cardio", "name": "Cardio · treadmill intervals", "minutes": 35, "energy": 14, "boost": 0.06, "boost_minutes": 180,
		"text": "Thirty minutes of intervals on the treadmill, then a cool-down walk."},
	{"id": "strength", "name": "Strength · full-body circuit", "minutes": 45, "energy": 18, "boost": 0.07, "boost_minutes": 210,
		"text": "Squats, rows, presses and planks, three rounds with a classmate spotting."},
	{"id": "yoga", "name": "Yoga · stretch and breathe", "minutes": 30, "energy": 6, "boost": 0.05, "boost_minutes": 180,
		"text": "Hips, hamstrings and shoulders after a day in lecture seats. Slow breathing to finish."},
]
## Hours between workouts that count.
const REST_HOURS := 3.0
var status: Label

func _init() -> void:
	super(560.0)

## Game time of the last workout (0 if none).
static func last_workout() -> float:
	return float(Achievements.stat("last_workout_at"))

static func ready_in_minutes() -> int:
	var wait := last_workout() + REST_HOURS * 3600.0 - GameClock.now_seconds()
	return int(ceil(wait / 60.0)) if wait > 0.0 else 0

func build() -> void:
	set_heading("Fitness Center", "Work out")
	add_text("Free for students with your ID. Energy now: %d · %s." % [int(round(Wellbeing.energy)), Wellbeing.energy_state()], UI.TEXT_MUTED, UI.SIZE_LABEL)
	var wait := ready_in_minutes()
	for workout in WORKOUTS:
		var card := UI.card(Vector4(12, 8, 12, 8))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		row.add_child(Icon.new("bolt", 18, UI.REWARD))
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 1)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		text.add_child(UI.label(String(workout.name), UI.SIZE_BODY, UI.TEXT, 600))
		text.add_child(UI.paragraph(String(workout.text), width - 200, UI.SIZE_CAPTION, UI.TEXT_MUTED))
		text.add_child(UI.label("%d min · −%d energy · Endorphins +%d%% XP for %d h" % [int(workout.minutes), int(workout.energy), int(round((float(workout.boost) + _perk_bonus()) * 100)), int(workout.boost_minutes) / 60], UI.SIZE_CAPTION, UI.REWARD, 500))
		var go := Button.new()
		go.name = "Workout_" + String(workout.id)
		go.text = "Start"
		go.disabled = wait > 0 or Wellbeing.energy < float(workout.energy)
		go.pressed.connect(_work_out.bind(workout))
		row.add_child(go)
		body.add_child(card)
	status = UI.label("", UI.SIZE_LABEL, UI.SUCCESS, 500)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = width - 52
	body.add_child(status)
	if wait > 0:
		status.add_theme_color_override("font_color", UI.TEXT_MUTED)
		status.text = "You worked out recently. Rest for another %d minutes." % wait
	elif WORKOUTS.all(func(workout: Dictionary) -> bool: return Wellbeing.energy < float(workout.energy)):
		status.add_theme_color_override("font_color", UI.TEXT_MUTED)
		status.text = "You're too tired to work out. Eat something first."
	add_button("Not now", close, true)

## Runner's High (skill tree) makes the boost stronger.
static func _perk_bonus() -> float:
	return 0.04 * Skills.effect("boost:exercise")

func _work_out(workout: Dictionary) -> void:
	Wellbeing.spend(float(workout.energy), "workout")
	YearCalendar.pass_time(float(workout.minutes))
	Wellbeing.restore(4.0)
	Wellbeing.add_boost("exercise", "Endorphins", float(workout.boost) + _perk_bonus(), float(workout.boost_minutes), "bolt", "workout:" + String(workout.id))
	Achievements.set_stat("last_workout_at", int(GameClock.now_seconds()))
	Achievements.bump("workouts")
	Achievements.note_today("workout")
	Sfx.play("ui_confirm")
	for child in buttons.get_children():
		child.queue_free()
	for child in body.get_children():
		if child != status:
			child.queue_free()
	set_heading("Fitness Center", "Good workout")
	status.add_theme_color_override("font_color", UI.SUCCESS)
	status.text = "%s done. Endorphins: +%d%% XP from learning for the next %d hours." % [String(workout.name).get_slice(" · ", 0), int(round((float(workout.boost) + _perk_bonus()) * 100)), int(workout.boost_minutes) / 60]
	add_button("Hit the showers", close, true)
	_focus_first.call_deferred()

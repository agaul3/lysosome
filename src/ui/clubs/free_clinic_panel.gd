extends "res://ui/clubs/club_event_panel.gd"
## Student-Run Free Clinic: first-years take the vitals. Three patients; for
## each, a manual blood pressure by auscultation. The cuff is pumped up past
## the systolic pressure and let down at about 3 mmHg a second; record the
## systolic at the first tapping sound (Korotkoff phase I) and the diastolic
## when the sounds disappear (phase V). Within 4 mmHg is full credit, within
## 8 half (wider with the Steady Hands perk). Then screening questions.
## Patients: [name, age, reason, systolic, diastolic, heart rate]. Fictional.
const PATIENTS := [
	["Ms. Reyes", 46, "Blood pressure check; she ran out of her pills last month.", 152, 94, 78],
	["Mr. Novak", 63, "Follow-up for his diabetes and a refill.", 138, 82, 70],
	["Ms. Johnson", 29, "A cough for a week; here for a check-up.", 118, 74, 88],
	["Mr. Haddad", 55, "Headaches in the mornings; he has never had his blood pressure taken.", 164, 102, 72],
	["Mrs. Lin", 71, "Dizzy when she stands up quickly.", 126, 70, 64],
	["Mr. Diallo", 38, "Work physical for a new job at the port.", 132, 86, 76],
]
const PER_NIGHT := 3
## mmHg a second, as taught (2–3), and how far past the systolic the cuff is
## pumped (20–30 above where the radial pulse disappears).
const DEFLATE := 3.0
const PUMP_ABOVE := 25.0
var order: Array = []
var patient := 0
var pressure := 0.0
var beat_clock := 0.0
var tap := 0.0
var measured_systolic := -1.0
var measured_diastolic := -1.0
var scores: Array = []
var lines: Array = []
var running := false
var gauge: Control
var patient_label: Label
var reading_label: Label
var hint_label: Label
var record_button: Button

func activity_title() -> String:
	return "Vitals at the free clinic"

func activity_intro() -> String:
	return "Saturday mornings and Thursday evenings the Student-Run Free Clinic sees patients without insurance. Tonight you're on vitals: a manual blood pressure for three patients, supervised by a volunteer internist. Seat each patient with the arm supported at heart level, cuff sized to the arm. Record the systolic at the first tapping sound, the diastolic when the sounds disappear."

func energy_cost() -> float:
	return 10.0

func questions_per_meeting() -> int:
	return 3

func tolerance() -> float:
	return 4.0 * (1.0 + Skills.effect("skills:window"))

func start_activity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("clinic:" + YearCalendar.today_date())
	order = range(PATIENTS.size())
	for index in range(order.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: int = order[index]
		order[index] = order[other]
		order[other] = swap
	order = order.slice(0, PER_NIGHT)
	patient_label = UI.label("", UI.SIZE_BODY, UI.TEXT, 600)
	body.add_child(patient_label)
	var reason := UI.paragraph("", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	reason.name = "Reason"
	body.add_child(reason)
	gauge = Control.new()
	gauge.name = "Gauge"
	gauge.custom_minimum_size = Vector2(width - 52, 230)
	gauge.draw.connect(_draw_gauge)
	body.add_child(gauge)
	reading_label = UI.label("", UI.SIZE_TITLE, UI.REWARD, 600)
	body.add_child(reading_label)
	hint_label = UI.paragraph("", width - 52, UI.SIZE_LABEL, UI.TEXT_MUTED)
	body.add_child(hint_label)
	record_button = add_button("Record systolic", record, true)
	record_button.name = "Record"
	_start_patient()

func _start_patient() -> void:
	var data: Array = PATIENTS[order[patient]]
	patient_label.text = "%s, %d  ·  patient %d of %d" % [data[0], data[1], patient + 1, order.size()]
	(body.get_node("Reason") as Label).text = String(data[2])
	pressure = float(data[3]) + PUMP_ABOVE
	beat_clock = 0.0
	tap = 0.0
	measured_systolic = -1.0
	measured_diastolic = -1.0
	record_button.text = "Record systolic"
	record_button.disabled = false
	reading_label.text = ""
	hint_label.text = "Cuff pumped up past the pulse; now letting it down slowly. Listen for the first tap. (Space or E to record.)"
	running = true

## Whether the stethoscope hears the brachial artery at this cuff pressure.
func sounds_present() -> bool:
	var data: Array = PATIENTS[order[patient]]
	return pressure <= float(data[3]) and pressure >= float(data[4])

func _process(delta: float) -> void:
	if not running:
		return
	var data: Array = PATIENTS[order[patient]]
	pressure -= DEFLATE * delta
	beat_clock += delta
	var interval := 60.0 / float(data[5])
	if beat_clock >= interval:
		beat_clock -= interval
		if sounds_present():
			tap = 1.0
			Sfx.play("ui_move")
	tap = maxf(0.0, tap - delta * 5.0)
	gauge.queue_redraw()
	if pressure < 30.0:
		# Let all the way down without a reading: whatever wasn't recorded counts as missed.
		_end_patient()

func record() -> void:
	if not running:
		return
	if measured_systolic < 0.0:
		measured_systolic = round(pressure)
		record_button.text = "Record diastolic"
		hint_label.text = "Systolic %d. Keep listening until the tapping stops." % int(measured_systolic)
	else:
		measured_diastolic = round(pressure)
		_end_patient()

## Credit for one value: full within the tolerance, half within twice it.
func credit(measured: float, actual: float) -> float:
	if measured < 0.0:
		return 0.0
	var error := absf(measured - actual)
	return 1.0 if error <= tolerance() else (0.5 if error <= tolerance() * 2.0 else 0.0)

func _end_patient() -> void:
	running = false
	var data: Array = PATIENTS[order[patient]]
	var score := (credit(measured_systolic, float(data[3])) + credit(measured_diastolic, float(data[4]))) / 2.0
	scores.append(score)
	var yours := "%s/%s" % [str(int(measured_systolic)) if measured_systolic >= 0.0 else "—", str(int(measured_diastolic)) if measured_diastolic >= 0.0 else "—"]
	lines.append("%s: you %s, the internist %d/%d" % [data[0], yours, data[3], data[4]])
	reading_label.text = "You: %s mmHg   ·   The internist: %d/%d" % [yours, data[3], data[4]]
	hint_label.text = "Spot on." if score >= 1.0 else ("Close enough to recheck together." if score >= 0.5 else "Off: listen again for the first tap and the last.")
	record_button.disabled = true
	await get_tree().create_timer(1.6 if DisplayServer.get_name() != "headless" else 0.01).timeout
	if stage != "activity":
		return
	patient += 1
	if patient >= order.size():
		var total := 0.0
		for value in scores:
			total += float(value)
		activity_done(total / float(scores.size()), "Blood pressures taken: " + "; ".join(lines) + ".")
	else:
		_start_patient()

func _draw_gauge() -> void:
	var size := gauge.size
	var centre := Vector2(size.x * 0.3, size.y * 0.52)
	var radius := minf(size.y * 0.46, size.x * 0.28)
	gauge.draw_circle(centre, radius + 6, Color("2a3238"))
	gauge.draw_circle(centre, radius, Color("f2f0ea"))
	var font := UI.font(600)
	for value in range(0, 301, 10):
		var angle := _angle(float(value))
		var outer := centre + Vector2(cos(angle), sin(angle)) * radius * 0.95
		var inner := centre + Vector2(cos(angle), sin(angle)) * radius * (0.82 if value % 50 == 0 else 0.88)
		gauge.draw_line(inner, outer, Color("2a3238"), 2.0 if value % 50 == 0 else 1.0)
		if value % 50 == 0:
			var at := centre + Vector2(cos(angle), sin(angle)) * radius * 0.68
			gauge.draw_string(font, at - Vector2(12, -5), str(value), HORIZONTAL_ALIGNMENT_CENTER, 24, 13, Color("2a3238"))
	var needle := _angle(pressure)
	gauge.draw_line(centre, centre + Vector2(cos(needle), sin(needle)) * radius * 0.9, Color("c2452d"), 3.0)
	gauge.draw_circle(centre, 6, Color("2a3238"))
	gauge.draw_string(font, centre + Vector2(-20, radius * 0.45), "mmHg", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("5d6468"))
	# The stethoscope: a ring that pulses with each Korotkoff sound.
	var ear := Vector2(size.x * 0.72, size.y * 0.5)
	gauge.draw_arc(ear, 34, 0, TAU, 40, Color(UI.ACCENT, 0.35 + 0.65 * tap), 3.0 + 5.0 * tap)
	gauge.draw_string(font, ear + Vector2(-44, 58), "stethoscope", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.TEXT_MUTED)
	if tap > 0.4:
		gauge.draw_string(font, ear + Vector2(-16, 6), "tap", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UI.REWARD)

## The dial runs clockwise from the bottom left (0) round to the bottom right (300).
func _angle(value: float) -> float:
	return deg_to_rad(135.0 + clampf(value, 0.0, 300.0) / 300.0 * 270.0)

func _unhandled_input(event: InputEvent) -> void:
	if stage == "activity" and running and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)):
		record()
		get_viewport().set_input_as_handled()
		return
	super(event)

extends Node
## One lecture question beat: ask a bank question, grade it through
## QuestionBank.submit (which records performance and XP once per attempt),
## show correct/incorrect feedback with the explanation, and — only for beats
## that name a remediation question — follow a wrong answer with a simpler
## question before continuing.
signal finished
enum Phase { IDLE, ASK, FEEDBACK, REMEDIATE_ASK, REMEDIATE_FEEDBACK }
var phase := Phase.IDLE
var line: Dictionary = {}
var lecture_id := ""
var speaker := ""
var ui: CanvasLayer
var professor: Node3D
var current_id := ""
var last_result: Dictionary = {}

func begin(beat: Dictionary, lecture: String, speaker_name: String, target_ui: CanvasLayer, target_professor: Node3D) -> void:
	line = beat
	lecture_id = lecture
	speaker = speaker_name
	ui = target_ui
	professor = target_professor
	_ask(beat.question, beat.get("lead", ""), Phase.ASK)

func running() -> bool:
	return phase != Phase.IDLE

func _ask(id: String, lead: String, next: Phase) -> void:
	current_id = id
	phase = next
	professor.set_line("audience")
	var question: Dictionary = QuestionBank.get_question(id)
	var keys: Array = question.choices.keys()
	keys.sort()
	var lead_text := speaker.to_upper() + ("  ·  " + lead if not lead.is_empty() else "")
	ui.show_question(question.prompt, keys.map(func(key): return [key, question.choices[key]]), lead_text)

## Stable per-lecture attempt id, so retries of the same lecture cannot double-count.
func attempt_id(id: String) -> String:
	return "%s:%s" % [lecture_id, id]

func answer(key: String) -> void:
	var result := QuestionBank.submit(current_id, key, attempt_id(current_id))
	if not result.get("valid", false):
		return
	last_result = result
	phase = Phase.FEEDBACK if phase == Phase.ASK else Phase.REMEDIATE_FEEDBACK
	ui.show_feedback(result.correct, key, result.correct_answer, result.explanation, result.xp_reward)

func _continue() -> void:
	if phase == Phase.FEEDBACK and not last_result.get("correct", true) and line.has("remediation"):
		_ask(line.remediation, "Let's try a simpler one.", Phase.REMEDIATE_ASK)
		return
	phase = Phase.IDLE
	finished.emit()

## Keyboard/controller input routed from the lecture session.
func handle_input(event: InputEvent) -> bool:
	var pressed_continue := event.is_action_pressed("interact") or event.is_action_pressed("confirm")
	match phase:
		Phase.ASK, Phase.REMEDIATE_ASK:
			if event.is_action_pressed("move_up"):
				ui.move_selection(-1)
				return true
			if event.is_action_pressed("move_down"):
				ui.move_selection(1)
				return true
			if event is InputEventKey and event.pressed and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
				ui.select(event.physical_keycode - KEY_1)
				return true
			if pressed_continue:
				answer(ui.selected_key())
				return true
		Phase.FEEDBACK, Phase.REMEDIATE_FEEDBACK:
			if pressed_continue:
				_continue()
				return true
	return pressed_continue

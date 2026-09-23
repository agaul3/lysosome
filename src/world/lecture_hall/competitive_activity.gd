extends Node
## Interactive competitive-antagonism activity, run from a lecture "activity"
## line. The player raises agonist concentration to reach a near-maximal
## response; the professor adds a fixed competitive antagonist; the player
## predicts what more agonist will do (a question from the shared bank); then
## tests the prediction by raising the agonist until the full response returns.
## The live model is drawn on the projection screen.
signal finished
const Model = preload("res://education/models/competitive_antagonism.gd")
enum Phase { INTRO, ANTAGONIST, PREDICT, FEEDBACK, TEST, WRAP, DONE }
## Decades of agonist concentration per second while a direction is held.
const RATE := 1.1
var phase := Phase.DONE
var model := Model.new()
var data: Dictionary = {}
var ui: CanvasLayer
var slide: Control
var professor: Node3D
var speaker := ""
var attempt_id := ""
var result: Dictionary = {}
var goal_timer := 0.0

func begin(activity: Dictionary, lecture_id: String, speaker_name: String, target_ui: CanvasLayer, target_slide: Control, target_professor: Node3D) -> void:
	data = activity
	ui = target_ui
	slide = target_slide
	professor = target_professor
	speaker = speaker_name
	attempt_id = "%s:%s" % [lecture_id, activity.question]
	model = Model.new()
	result = {}
	slide.show_model(model, activity.get("title", "Try it: competitive antagonism"))
	_enter(Phase.INTRO)

func running() -> bool:
	return phase != Phase.DONE

func _controls() -> Array:
	var controller: bool = ui.using_controller
	return [["LS" if controller else "A", "Less"], ["LS" if controller else "D", "More agonist"]]

func _enter(next: Phase) -> void:
	phase = next
	goal_timer = 0.0
	var steps: Dictionary = data.steps
	match phase:
		Phase.INTRO:
			professor.set_line("screen")
			ui.show_activity(speaker, steps.intro, _controls())
		Phase.ANTAGONIST:
			model.antagonist = true
			professor.set_line("screen")
			ui.show_activity(speaker, steps.antagonist, [["E", "Continue"]])
		Phase.PREDICT:
			professor.set_line("audience")
			var question: Dictionary = QuestionBank.get_question(data.question)
			var keys: Array = question.choices.keys()
			keys.sort()
			ui.show_question(question.prompt, keys.map(func(key): return [key, question.choices[key]]), speaker.to_upper() + "  ·  " + steps.predict)
		Phase.TEST:
			professor.set_line("screen")
			ui.show_activity(speaker, steps.test, _controls())
		Phase.WRAP:
			professor.set_line("screen")
			ui.show_activity(speaker, steps.wrap, [["E", "Continue"]])
		Phase.DONE:
			finished.emit()

func _process(delta: float) -> void:
	if phase == Phase.DONE:
		return
	model.advance(delta)
	if phase in [Phase.INTRO, Phase.TEST]:
		var direction := Input.get_axis("move_left", "move_right")
		if absf(direction) > 0.1:
			model.change_agonist(direction * RATE * delta)
		if phase == Phase.INTRO:
			# Stop at the goal so the antagonist's effect is shown from the same
			# starting point every time (goal response with no antagonist).
			var goal := float(data.get("goal_response", 90))
			model.log_agonist = minf(model.log_agonist, log(goal / (100.0 - goal)) / log(10.0) + 0.001)
		# Hold the goal briefly so the player sees the curve reach the plateau.
		if model.response() >= float(data.get("goal_response", 90)) and model.antagonist_level >= (0.99 if phase == Phase.TEST else 0.0):
			goal_timer += delta
			if goal_timer > 0.6:
				_enter(Phase.ANTAGONIST if phase == Phase.INTRO else Phase.WRAP)
		else:
			goal_timer = 0.0
	slide.refresh_model()

## Keyboard/controller input routed from the lecture session.
func handle_input(event: InputEvent) -> bool:
	var pressed_continue := event.is_action_pressed("interact") or event.is_action_pressed("confirm")
	if pressed_continue and ui.typing:
		ui.finish_typing()
		return true
	match phase:
		Phase.ANTAGONIST:
			if pressed_continue and model.antagonist_level >= 0.99:
				_enter(Phase.PREDICT)
				return true
		Phase.PREDICT:
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
		Phase.FEEDBACK:
			if pressed_continue:
				_enter(Phase.TEST)
				return true
		Phase.WRAP:
			if pressed_continue:
				_enter(Phase.DONE)
				return true
	return pressed_continue or event.is_action_pressed("move_left") or event.is_action_pressed("move_right")

## Grades through the shared question bank (one attempt per lecture run).
func answer(key: String) -> void:
	result = QuestionBank.submit(data.question, key, attempt_id)
	if not result.get("valid", false):
		return
	phase = Phase.FEEDBACK
	ui.show_feedback(result.correct, key, result.correct_answer, result.explanation, result.xp_reward)

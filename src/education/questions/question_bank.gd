extends Node
## Shared JSON database for future lecture and study clients. Grading is independent of UI.
const DEFAULT_PATH := "res://education/questions/pharmacodynamics.json"
## Every content file the game loads at start: the Pharmacodynamics lecture and
## the Hospital Orientation shadowing session (Clinical Skills).
const PATHS := [DEFAULT_PATH, "res://education/questions/hospital_orientation.json"]
const TYPES := ["Recall", "Conceptual", "Application", "Clinical Application", "Interpretation", "Synthesis"]
var records: Dictionary = {}
var last_error := ""

func _ready() -> void:
	if not load_files(PATHS):
		push_error(last_error)

func load_file(path: String) -> bool:
	return load_files([path])

## Loads several question files as one bank. All of them are parsed and
## validated first (IDs must be unique across files), then the bank is
## replaced in one step, so a bad file never leaves a half-loaded bank.
func load_files(paths: Array) -> bool:
	var candidate: Dictionary = {}
	for path in paths:
		if not FileAccess.file_exists(path):
			last_error = "Question file not found: " + String(path)
			return false
		if not _parse_into(FileAccess.get_file_as_string(path), candidate):
			return false
	records = candidate
	last_error = ""
	return true

func load_json(text: String) -> bool:
	var candidate: Dictionary = {}
	if not _parse_into(text, candidate):
		return false
	records = candidate # Atomic replacement: a bad import never corrupts the loaded bank.
	last_error = ""
	return true

func _parse_into(text: String, candidate: Dictionary) -> bool:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		last_error = "Invalid JSON: " + parser.get_error_message()
		return false
	var data = parser.data
	if not data is Dictionary or data.get("version") != 1 or not data.get("questions") is Array:
		last_error = "Expected version 1 and a questions array"
		return false
	for question in data.questions:
		var error := validate(question)
		if not error.is_empty():
			last_error = error
			return false
		if candidate.has(question.id):
			last_error = "Duplicate question ID: " + question.id
			return false
		candidate[question.id] = question.duplicate(true)
	return true

func validate(question: Variant) -> String:
	if not question is Dictionary:
		return "Question must be an object"
	for key in ["id", "discipline", "topic", "subtopic", "question_type", "prompt", "correct_answer", "explanation", "learning_objective", "lecture_id"]:
		if not question.get(key) is String or question[key].strip_edges().is_empty():
			return "Missing/non-string field: " + key
	if question.question_type not in TYPES:
		return "Unsupported question type"
	var tier = question.get("difficulty_tier")
	if not (tier is int or tier is float) or not is_finite(tier) or floor(tier) != tier or tier < 1 or tier > 3:
		return "Difficulty tier must be 1, 2 or 3"
	if not question.has("xp_reward"):
		return "Missing xp_reward (null uses configured tier reward)"
	var reward = question.xp_reward
	if reward != null and (not (reward is int or reward is float) or not is_finite(reward) or reward < 0 or reward > 1000000 or floor(reward) != reward):
		return "XP reward must be an integer from 0 to 1000000, or null"
	if not question.get("choices") is Dictionary:
		return "Choices must be an object"
	var format = question.get("format", "multiple_choice")
	if format == "multiple_choice":
		if question.choices.size() < 2 or not question.choices.has(question.correct_answer):
			return "Multiple choice needs two choices and one valid answer key"
		var texts: Array = []
		for key in question.choices:
			var choice = question.choices[key]
			if not key is String or key.is_empty() or not choice is String or choice.strip_edges().is_empty() or choice in texts:
				return "Invalid or duplicate choice"
			texts.append(choice)
	elif format == "short_answer":
		if not question.get("accepted_short_answers") is Array or question.accepted_short_answers.is_empty():
			return "Short answer needs predefined accepted answers"
		for answer in question.accepted_short_answers:
			if not answer is String or answer.strip_edges().is_empty():
				return "Invalid accepted answer"
		if _normalize(question.correct_answer) not in question.accepted_short_answers.map(_normalize):
			return "Correct answer must be accepted"
	else:
		return "Unsupported answer format"
	return ""

func get_question(id: String) -> Dictionary:
	return records.get(id, {}).duplicate(true)

func for_lecture(lecture_id: String) -> Array:
	return records.values().filter(func(q: Dictionary) -> bool: return q.lecture_id == lecture_id).duplicate(true)

func grade(id: String, answer: Variant) -> Dictionary:
	if not records.has(id) or not answer is String or answer.strip_edges().is_empty():
		return {"valid": false, "error": "Unknown question or empty/non-string answer"}
	var question: Dictionary = records[id]
	var correct_answer := false
	if question.get("format", "multiple_choice") == "multiple_choice":
		if not question.choices.has(answer):
			return {"valid": false, "error": "Unknown choice key"}
		correct_answer = answer == question.correct_answer
	else:
		correct_answer = _normalize(answer) in question.accepted_short_answers.map(_normalize)
	var reward: int = int(question.xp_reward) if question.xp_reward != null else int(GameClock.config.xp_by_tier[str(int(question.difficulty_tier))])
	return {"valid": true, "question_id": id, "answer": answer, "correct": correct_answer, "correct_answer": question.correct_answer, "explanation": question.explanation, "learning_objective": question.learning_objective, "xp_reward": reward if correct_answer else 0}

func submit(id: String, answer: Variant, attempt_id: String) -> Dictionary:
	if attempt_id.strip_edges().is_empty():
		return {"valid": false, "error": "An attempt ID is required"}
	if AcademicSession.question_history.has(attempt_id):
		var previous: Dictionary = AcademicSession.question_history[attempt_id]
		if previous.question_id != id or previous.answer != answer:
			return {"valid": false, "error": "Attempt ID conflicts with a previous submission"}
		return previous.duplicate(true)
	var result := grade(id, answer)
	if result.valid:
		AcademicSession.commit_answer(attempt_id, records[id], result)
	return result

func _normalize(answer: String) -> String:
	return " ".join(answer.strip_edges().to_lower().split(" ", false))

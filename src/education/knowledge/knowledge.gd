extends RefCounted
## Knowledge tracking (spec §31): mastery is purely performance-based,
## accuracy = correct / attempted, at discipline, topic and subtopic level.
##
## The tree's shape comes from the question bank's taxonomy, so topics with
## no attempts yet still appear (as "not yet attempted"), and any statistics
## for areas outside the bank are kept too, so new disciplines and subtopics
## need no code changes. Counts come from AcademicSession.topic_statistics;
## `from_history` recounts them independently from the raw attempt history.

## Builds [{name, path, attempted, correct, accuracy, children: [...]}] for
## disciplines -> topics -> subtopics, in the bank's order.
static func tree(records: Array, statistics: Dictionary) -> Array:
	var order: Array = []
	for record in records:
		for path in _paths(record):
			if not order.has(path):
				order.append(path)
	for path in statistics:
		if not order.has(path):
			order.append(path)
	var nodes := {}
	var roots: Array = []
	for path in order:
		var counts: Dictionary = statistics.get(path, {"attempted": 0, "correct": 0})
		var parts: PackedStringArray = path.split("/")
		var node := {
			"name": parts[parts.size() - 1],
			"path": path,
			"depth": parts.size() - 1,
			"attempted": int(counts.attempted),
			"correct": int(counts.correct),
			"accuracy": accuracy(int(counts.correct), int(counts.attempted)),
			"children": [],
		}
		nodes[path] = node
		if parts.size() == 1:
			roots.append(node)
		else:
			var parent_path := "/".join(parts.slice(0, parts.size() - 1))
			if nodes.has(parent_path):
				nodes[parent_path].children.append(node)
	return roots

## discipline, discipline/topic and discipline/topic/subtopic for one record.
static func _paths(record: Dictionary) -> Array:
	var discipline: String = record.discipline
	var topic: String = discipline + "/" + String(record.topic)
	return [discipline, topic, topic + "/" + String(record.subtopic)]

## Safe for zero attempts.
static func accuracy(correct: int, attempted: int) -> float:
	return float(correct) / attempted if attempted > 0 else 0.0

static func accuracy_text(node: Dictionary) -> String:
	return "—" if node.attempted == 0 else "%d%%" % int(round(node.accuracy * 100.0))

static func counts_text(node: Dictionary) -> String:
	return "Not yet attempted" if node.attempted == 0 else "%d/%d correct" % [node.correct, node.attempted]

## Independent recount from AcademicSession.question_history and the bank:
## {path: {attempted, correct}}. Used to verify the displayed statistics.
static func from_history(history: Dictionary, bank: Node) -> Dictionary:
	var counts := {}
	for attempt in history.values():
		var record: Dictionary = bank.get_question(attempt.question_id)
		if record.is_empty():
			continue
		for path in _paths(record):
			var entry: Dictionary = counts.get(path, {"attempted": 0, "correct": 0})
			entry.attempted += 1
			entry.correct += 1 if attempt.correct else 0
			counts[path] = entry
	return counts

## The most recent attempts, newest first: [{prompt, subtopic, correct, xp}].
static func recent(history: Dictionary, bank: Node, limit := 6) -> Array:
	var result: Array = []
	var attempts := history.values()
	for index in range(attempts.size() - 1, -1, -1):
		if result.size() >= limit:
			break
		var attempt: Dictionary = attempts[index]
		var record: Dictionary = bank.get_question(attempt.question_id)
		if record.is_empty():
			continue
		result.append({"prompt": record.prompt, "subtopic": record.subtopic, "correct": attempt.correct, "xp": int(attempt.xp_reward)})
	return result

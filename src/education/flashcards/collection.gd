extends Node
## A single offline collection shared by the dorm PC and the carried laptop.
## The bank remains authoritative: study views do not duplicate medical facts.
signal changed
const Scheduler = preload("res://education/flashcards/scheduler.gd")
const DEFAULT_DECK := "Medicine::Pharmacology::Pharmacodynamics"
const XP_PER_CARD := 2
const DAILY_XP_CAP := 100
var states: Dictionary = {}
var notes: Dictionary = {}
var review_log: Array = []
var new_limit := 20
var day_counts: Dictionary = {}
var next_id := 1
var active_id := ""
var revealed := false
var shown_at := 0
var last_error := ""

func reset() -> void:
	states.clear()
	notes.clear()
	review_log.clear()
	day_counts.clear()
	new_limit = 20
	next_id = 1
	end_review()
	changed.emit()

func now() -> int:
	return int(Time.get_unix_time_from_system())

func has_laptop() -> bool:
	var item: String = AppState.player_look.get("outfit", {}).get("back", "")
	return item.ends_with("_backpack")

func cards() -> Array:
	var result: Array = []
	for q in QuestionBank.records.values():
		# Presentation-only prompts require a graph/slide and cannot stand alone.
		if q.id == "pd_viz_competitive_01":
			continue
		result.append({"id": "bank:" + q.id, "note": "bank:" + q.id, "deck": DEFAULT_DECK,
			"front": q.prompt, "back": q.choices.get(q.correct_answer, q.correct_answer),
			"extra": q.explanation, "tags": q.subtopic, "objective": q.learning_objective, "source": q.id})
	for id in notes:
		var note: Dictionary = notes[id]
		if note.type == "Basic":
			result.append({"id": id, "note": id, "deck": note.deck, "front": note.front,
				"back": note.back, "extra": note.extra, "tags": note.tags, "source": "Personal note"})
		else:
			var pattern := cloze_pattern()
			var ordinals: Array = []
			for found in pattern.search_all(note.front):
				var ordinal := found.get_string(1)
				if ordinal not in ordinals:
					ordinals.append(ordinal)
			for ordinal in ordinals:
				var front: String = note.front
				var back: String = note.front
				var matches := pattern.search_all(note.front)
				matches.reverse()
				for found in matches:
					var answer := found.get_string(2)
					var hint := found.get_string(3)
					var replacement := ("[" + (hint if not hint.is_empty() else "…") + "]") if found.get_string(1) == ordinal else answer
					front = front.substr(0, found.get_start()) + replacement + front.substr(found.get_end())
					back = back.substr(0, found.get_start()) + answer + back.substr(found.get_end())
				result.append({"id": id + ":c" + ordinal, "note": id, "deck": note.deck,
					"front": front, "back": back, "extra": note.extra, "tags": note.tags, "source": "Personal cloze"})
	return result

static func cloze_pattern() -> RegEx:
	var pattern := RegEx.new()
	pattern.compile("\\{\\{c([1-9][0-9]*)::([^{}]+?)(?:::(.*?))?\\}\\}")
	return pattern

func card(id: String) -> Dictionary:
	for item in cards():
		if item.id == id:
			return item
	return {}

func status(id: String) -> Dictionary:
	return states.get(id, Scheduler.fresh()).duplicate(true)

func decks() -> Array:
	var result: Array = []
	for item in cards():
		if item.deck not in result:
			result.append(item.deck)
	result.sort()
	return result

func _today(at: int) -> Dictionary:
	return day_counts.get(str(at / Scheduler.DAY), {"new": 0, "xp": 0, "reviews": 0}).duplicate(true)

func available(id: String, at: int) -> bool:
	var s := status(id)
	return not s.suspended and int(s.buried_until) <= at and int(s.due) <= at and (s.phase != "new" or int(_today(at).new) < new_limit)

func queue(deck: String, at: int = -1) -> Array:
	if at < 0:
		at = now()
	var result := cards().filter(func(c: Dictionary) -> bool: return (deck.is_empty() or c.deck == deck or c.deck.begins_with(deck + "::")) and available(c.id, at))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := status(a.id)
		var sb := status(b.id)
		var pa: int = {"learning": 0, "relearning": 0, "review": 1, "new": 2}[sa.phase]
		var pb: int = {"learning": 0, "relearning": 0, "review": 1, "new": 2}[sb.phase]
		return pa < pb if pa != pb else (int(sa.due) < int(sb.due) if sa.due != sb.due else a.id < b.id))
	var remaining := maxi(0, new_limit - int(_today(at).new))
	var limited: Array = []
	for item in result:
		if status(item.id).phase == "new":
			if remaining <= 0:
				continue
			remaining -= 1
		limited.append(item)
	return limited

func counts(deck: String) -> Dictionary:
	var result := {"new": 0, "learn": 0, "due": 0, "total": 0}
	for c in cards():
		if c.deck == deck or c.deck.begins_with(deck + "::"):
			result.total += 1
	for c in queue(deck):
		var phase: String = status(c.id).phase
		result["new" if phase == "new" else ("due" if phase == "review" else "learn")] += 1
	return result

func next_due(deck: String) -> int:
	var earliest := 0
	for c in cards():
		var s := status(c.id)
		if (c.deck == deck or c.deck.begins_with(deck + "::")) and not s.suspended and s.phase != "new":
			var due := maxi(int(s.due), int(s.buried_until))
			if earliest == 0 or due < earliest:
				earliest = due
	return earliest

func begin_review(id: String) -> bool:
	end_review()
	if card(id).is_empty() or not available(id, now()):
		return false
	active_id = id
	shown_at = Time.get_ticks_msec()
	return true

func reveal() -> void:
	if not active_id.is_empty():
		revealed = true

func end_review() -> void:
	active_id = ""
	revealed = false

func rate(rating: int) -> Dictionary:
	if active_id.is_empty() or not revealed or rating < 1 or rating > 4 or not available(active_id, now()):
		return {}
	var id := active_id
	var at := now()
	var previous := status(id)
	var next := Scheduler.next(previous, rating, at)
	var daily := _today(at)
	if previous.phase == "new":
		daily.new += 1
	var day := int(at / Scheduler.DAY)
	# Same effort reward for all ratings; honest failure must not cost XP.
	# A three-second minimum blocks accidental instant reveal/rate rewards.
	var reward := 0
	if int(previous.reward_day) != day and int(daily.xp) < DAILY_XP_CAP and Time.get_ticks_msec() - shown_at >= 3000:
		reward = mini(XP_PER_CARD, DAILY_XP_CAP - int(daily.xp))
		next.reward_day = day
		daily.xp += reward
	daily.reviews += 1
	day_counts[str(day)] = daily
	states[id] = next
	# Bury cloze siblings to avoid one card giving away the next answer.
	var note: String = card(id).note
	for sibling in cards():
		if sibling.note == note and sibling.id != id:
			var sibling_state := status(sibling.id)
			sibling_state.buried_until = (day + 1) * Scheduler.DAY
			states[sibling.id] = sibling_state
	review_log.append({"id": id, "rating": rating, "at": at, "phase": previous.phase, "xp": reward})
	if review_log.size() > 5000:
		review_log.pop_front()
	end_review()
	if reward > 0:
		AcademicSession.add_xp(reward, "flashcards")
	SaveGame.autosave()
	changed.emit()
	return {"xp": reward, "due": next.due, "suspended": next.suspended}

func set_suspended(id: String, value: bool) -> void:
	if card(id).is_empty():
		return
	var s := status(id)
	s.suspended = value
	states[id] = s
	end_review()
	SaveGame.autosave()
	changed.emit()

func bury(id: String) -> void:
	if card(id).is_empty():
		return
	var s := status(id)
	s.buried_until = (int(now() / Scheduler.DAY) + 1) * Scheduler.DAY
	states[id] = s
	end_review()
	SaveGame.autosave()
	changed.emit()

func save_note(note: Dictionary, id := "") -> String:
	last_error = validate_note(note)
	if not last_error.is_empty():
		return ""
	if not id.is_empty() and not notes.has(id):
		last_error = "Only personal notes can be edited."
		return ""
	if id.is_empty():
		id = "user:%d" % next_id
		next_id += 1
	notes[id] = note.duplicate(true)
	SaveGame.autosave()
	changed.emit()
	return id

static func validate_note(note: Variant) -> String:
	if not note is Dictionary:
		return "Invalid note."
	for field in ["type", "deck", "front", "back", "extra", "tags"]:
		if not note.get(field) is String or note[field].length() > 12000:
			return "Invalid note field: " + field
	if note.type not in ["Basic", "Cloze"] or note.deck.strip_edges().is_empty() or note.front.strip_edges().is_empty():
		return "Choose a type and enter a deck and front."
	if note.type == "Basic" and note.back.strip_edges().is_empty():
		return "A Basic note needs an answer."
	if note.type == "Cloze" and cloze_pattern().search(note.front) == null:
		return "Use {{c1::answer}} or {{c1::answer::hint}} in the text."
	return ""

func snapshot() -> Dictionary:
	return {"states": states.duplicate(true), "notes": notes.duplicate(true), "log": review_log.duplicate(true),
		"new_limit": new_limit, "days": day_counts.duplicate(true), "next_id": next_id}

func restore(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		return
	states = data.states.duplicate(true)
	notes = data.notes.duplicate(true)
	review_log = data.log.duplicate(true)
	new_limit = int(data.new_limit)
	day_counts = data.days.duplicate(true)
	next_id = int(data.next_id)

static func _number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(value) and value >= low and value <= high

static func validate(data: Variant) -> String:
	if not data is Dictionary:
		return "Invalid flashcard collection."
	for field in ["states", "notes", "days"]:
		if not data.get(field) is Dictionary:
			return "Invalid flashcard " + field
	if not data.get("log") is Array or not _number(data.get("new_limit"), 0, 999) or not _number(data.get("next_id"), 1, 1000000000):
		return "Invalid flashcard options."
	for note in data.notes.values():
		if not validate_note(note).is_empty():
			return "Invalid saved flashcard note."
	for id in data.notes:
		if not id is String or not id.begins_with("user:") or not id.trim_prefix("user:").is_valid_int() or int(id.trim_prefix("user:")) >= int(data.next_id):
			return "Invalid flashcard note ID."
	for s in data.states.values():
		if not s is Dictionary or s.get("phase") not in ["new", "learning", "review", "relearning"] or not s.get("suspended") is bool:
			return "Invalid flashcard schedule."
		for field in ["step", "due", "interval", "ease", "reps", "lapses", "buried_until", "reward_day"]:
			if not _number(s.get(field), -1 if field == "reward_day" else 0, 100000000000):
				return "Invalid flashcard schedule field."
		if s.step > 1 or s.ease < 1.3 or s.interval > Scheduler.MAX_DAYS:
			return "Invalid flashcard interval."
	for d in data.days.values():
		if not d is Dictionary:
			return "Invalid flashcard daily counts."
		for field in ["new", "xp", "reviews"]:
			if not _number(d.get(field), 0, 1000000000):
				return "Invalid flashcard daily count."
	for entry in data.log:
		if not entry is Dictionary or not entry.get("id") is String or not _number(entry.get("rating"), 1, 4) or not _number(entry.get("at"), 0, 100000000000) or not _number(entry.get("xp"), 0, XP_PER_CARD) or entry.get("phase") not in ["new", "learning", "review", "relearning"]:
			return "Invalid flashcard history."
	return ""

extends VBoxContainer
## Anki-style study UI; the persistent collection owns scheduling and rewards.
const UI = preload("res://ui/style/ui_style.gd")
const Scheduler = preload("res://education/flashcards/scheduler.gd")
const INK := Color("253344")
const MUTED := Color("647487")
const BLUE := Color("357ace")
var body: VBoxContainer
var footer: Label
var review_controls: VBoxContainer
var recall_hint: Label
var deck := ""
var current: Dictionary = {}
var page := "decks"
var editor_fields := {}
var editor_id := ""
var search: LineEdit
var browser_list: VBoxContainer
var reveal_button: Button
var rating_buttons: Array[Button] = []
var refresh_elapsed := 0.0

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(nav)
	for item in [["Decks", show_decks], ["Add", show_editor], ["Browse", show_browser], ["Stats", show_stats], ["Options", show_options]]:
		nav.add_child(button(item[0], item[1]))
	add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	review_controls = VBoxContainer.new()
	review_controls.add_theme_constant_override("separation", 10)
	add_child(review_controls)
	footer = UI.label("", 13, MUTED)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(footer)
	show_decks()

static func button(text: String, callback: Callable, color := INK) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_hover_color", color)
	result.add_theme_color_override("font_pressed_color", color)
	result.add_theme_color_override("font_focus_color", color)
	result.add_theme_color_override("font_disabled_color", MUTED)
	for state in ["normal", "hover", "pressed", "disabled"]:
		result.add_theme_stylebox_override(state, UI.box(Color("e7edf5") if state == "hover" else Color("f6f8fc"), 6, Color("d0d8e4"), 1, Vector4(14, 9, 14, 9)))
	result.pressed.connect(callback)
	return result

func clear(next_page: String) -> void:
	Flashcards.end_review()
	current = {}
	page = next_page
	rating_buttons.clear()
	for parent in [body, review_controls]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()
	footer.text = "Your collection is shared automatically between your dorm PC and laptop."

func text(value: String, size := 16, color := INK, center := false) -> Label:
	var label := UI.label(value, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(label)
	return label

func show_decks() -> void:
	clear("decks")
	text("Decks", 28)
	text("A little retrieval, every day.", 15, MUTED)
	var header := HBoxContainer.new()
	body.add_child(header)
	var title := UI.label("DECK", 12, MUTED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for pair in [["NEW", BLUE], ["LEARN", Color("c25852")], ["DUE", Color("29886a")]]:
		var label := UI.label(pair[0], 12, pair[1])
		label.custom_minimum_size.x = 70
		header.add_child(label)
	for name in Flashcards.decks():
		var count: Dictionary = Flashcards.counts(name)
		var row := HBoxContainer.new()
		body.add_child(row)
		var open := button(name.replace("::", "  ›  "), func() -> void: show_overview(name))
		open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		open.alignment = HORIZONTAL_ALIGNMENT_LEFT
		open.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(open)
		for pair in [["new", BLUE], ["learn", Color("c25852")], ["due", Color("29886a")]]:
			var label := UI.label(str(count[pair[0]]), 20, pair[1])
			label.custom_minimum_size.x = 70
			row.add_child(label)
	body.add_child(HSeparator.new())
	text("Study XP: +2 per card per UTC day, up to 100 XP. All four ratings earn the same amount after at least 3 seconds of study. Repeated learning steps do not pay again.", 14, MUTED)
	text("Self-rated recall is tracked here separately from graded lecture accuracy.", 14, MUTED)

func show_overview(name: String) -> void:
	clear("overview")
	deck = name
	var count: Dictionary = Flashcards.counts(deck)
	text(deck.replace("::", "  /  "), 25, INK, true)
	text("New  %d     Learning  %d     Review  %d" % [count.new, count.learn, count.due], 20, BLUE, true)
	text("Recall the answer before revealing it. Grade what you remembered, not what looks familiar.", 16, MUTED, true)
	var start := button("Study Now", study_next, BLUE)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(start)

func study_next() -> void:
	clear("review")
	var queue: Array = Flashcards.queue(deck)
	if queue.is_empty():
		page = "complete"
		text("All caught up for now", 30, INK, true)
		var due: int = Flashcards.next_due(deck)
		text("Next scheduled card in %s." % Scheduler.interval_text(due - Flashcards.now()) if due > Flashcards.now() else "No cards available. New-card limits, burying, and suspension may hide cards until later.", 17, MUTED, true)
		text("Your progress is saved. Come back later or add a personal note.", 16, MUTED, true)
		body.add_child(button("Check for due cards", study_next))
		return
	current = queue[0]
	if not Flashcards.begin_review(current.id):
		return
	text(deck.get_slice("::", deck.get_slice_count("::") - 1) + "  /  " + current.tags, 13, MUTED, true)
	text(current.front, 25, INK, true)
	recall_hint = text("Think of your answer before continuing.", 14, MUTED, true)
	reveal_button = button("Show Answer   ·   Space", show_answer, BLUE)
	reveal_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	review_controls.add_child(reveal_button)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	review_controls.add_child(actions)
	actions.add_child(button("Bury until tomorrow", func() -> void: Flashcards.bury(current.id); study_next()))
	actions.add_child(button("Suspend card", func() -> void: Flashcards.set_suspended(current.id, true); study_next()))
	footer.text = "Space: reveal   ·   1–4: rate after revealing   ·   Esc: close computer"

func show_answer() -> void:
	if current.is_empty() or Flashcards.revealed:
		return
	Flashcards.reveal()
	reveal_button.hide()
	recall_hint.hide()
	body.add_child(HSeparator.new())
	text(current.back, 23, Color("236f61"), true)
	if not current.extra.is_empty():
		text(current.extra, 16, MUTED)
	if current.has("objective"):
		text("Learning objective: " + current.objective, 13, MUTED)
	text("Source: " + current.source, 12, MUTED)
	var ratings := HBoxContainer.new()
	ratings.alignment = BoxContainer.ALIGNMENT_CENTER
	review_controls.add_child(ratings)
	review_controls.move_child(ratings, 0)
	var colors := [Color("b84844"), Color("a57127"), Color("258064"), BLUE]
	for index in range(4):
		var scheduled := Scheduler.next(Flashcards.status(current.id), index + 1, Flashcards.now())
		var label: String = ["Again", "Hard", "Good", "Easy"][index]
		var rating := button("%s\n%d  %s" % [Scheduler.interval_text(scheduled.due - Flashcards.now()), index + 1, label], func() -> void: rate(index + 1), colors[index])
		rating.tooltip_text = ["Forgot or incorrect", "Correct, but difficult", "Correct with some effort", "Correct immediately and effortlessly"][index]
		ratings.add_child(rating)
		rating_buttons.append(rating)
	var hint := UI.label("Again: forgot   ·   Hard: correct, difficult   ·   Good: recalled   ·   Easy: effortless", 13, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	review_controls.add_child(hint)

func rate(value: int) -> void:
	var result: Dictionary = Flashcards.rate(value)
	if result.is_empty():
		return
	study_next()
	footer.text = ("+%d study XP. " % result.xp if result.xp > 0 else "Review saved. ") + ("Leech suspended after 8 lapses; revise it in Browse." if result.suspended else "Use honest ratings to keep your schedule useful.")

func shortcut(event: InputEvent) -> bool:
	if page != "review" or current.is_empty() or not event is InputEventKey or not event.pressed or event.echo:
		return false
	if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		if Flashcards.revealed:
			rate(3)
		else:
			show_answer()
		return true
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		if Flashcards.revealed:
			rate(event.keycode - KEY_1 + 1)
		return true
	return false

func show_browser() -> void:
	clear("browse")
	text("Browse collection", 26)
	search = field("Search questions, answers, topics, or tags")
	body.add_child(search)
	browser_list = VBoxContainer.new()
	browser_list.add_theme_constant_override("separation", 12)
	body.add_child(browser_list)
	search.text_changed.connect(func(_value: String) -> void: _browser_results())
	_browser_results()

func _browser_results() -> void:
	for child in browser_list.get_children():
		browser_list.remove_child(child)
		child.queue_free()
	for c in Flashcards.cards():
		if not search.text.to_lower() in (c.front + " " + c.back + " " + c.tags).to_lower():
			continue
		var s: Dictionary = Flashcards.status(c.id)
		var row := VBoxContainer.new()
		browser_list.add_child(row)
		var label := UI.label(c.front, 16, INK)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var info := "%s  ·  %s  ·  %d reviews  ·  %d lapses" % [c.tags, "suspended" if s.suspended else s.phase, s.reps, s.lapses]
		if int(s.buried_until) > Flashcards.now():
			info += "  ·  buried"
		if s.phase != "new":
			info += "  ·  due " + Time.get_datetime_string_from_unix_time(int(s.due), true) + " UTC"
		var detail := UI.label(info, 12, MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(detail)
		var buttons := HBoxContainer.new()
		row.add_child(buttons)
		buttons.add_child(button("Inspect / Edit" if c.id.begins_with("user:") else "Inspect source", func() -> void: inspect_card(c)))
		buttons.add_child(button("Resume" if s.suspended else "Suspend", func() -> void: Flashcards.set_suspended(c.id, not s.suspended); _browser_results()))
		row.add_child(HSeparator.new())

func inspect_card(c: Dictionary) -> void:
	if c.id.begins_with("user:"):
		show_editor(c.note)
		return
	clear("inspect")
	text(c.front, 23)
	text(c.back, 20, Color("236f61"))
	text(c.extra, 16, MUTED)
	text("Shared question bank: " + c.source + "\n" + c.objective, 13, MUTED)
	body.add_child(button("Back to Browse", show_browser))

static func field(placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.add_theme_color_override("font_color", INK)
	edit.add_theme_color_override("font_placeholder_color", MUTED)
	edit.add_theme_color_override("caret_color", INK)
	edit.add_theme_stylebox_override("normal", UI.box(Color.WHITE, 6, Color("ccd5e2"), 1))
	edit.add_theme_stylebox_override("focus", UI.box(Color.WHITE, 6, BLUE, 2))
	return edit

func show_editor(id := "") -> void:
	clear("editor")
	editor_id = id
	editor_fields.clear()
	text("Add note" if id.is_empty() else "Edit note", 26)
	var note: Dictionary = Flashcards.notes.get(id, {"type": "Basic", "deck": "Personal", "front": "", "back": "", "extra": "", "tags": ""})
	var type := OptionButton.new()
	type.add_item("Basic")
	type.add_item("Cloze")
	type.select(0 if note.type == "Basic" else 1)
	body.add_child(type)
	editor_fields.type = type
	for pair in [["deck", "Deck (use :: for subdecks)"], ["front", "Front / Cloze text"], ["back", "Back (Basic only)"], ["extra", "Extra explanation / reference"], ["tags", "Tags"]]:
		text(pair[1], 13, MUTED)
		if pair[0] in ["front", "back", "extra"]:
			var edit := TextEdit.new()
			edit.custom_minimum_size.y = 90
			edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			edit.text = note[pair[0]]
			edit.add_theme_color_override("font_color", INK)
			edit.add_theme_color_override("caret_color", INK)
			edit.add_theme_stylebox_override("normal", UI.box(Color.WHITE, 6, Color("ccd5e2"), 1))
			body.add_child(edit)
			editor_fields[pair[0]] = edit
		else:
			var edit := field(pair[1])
			edit.text = note[pair[0]]
			body.add_child(edit)
			editor_fields[pair[0]] = edit
	text("Cloze format: {{c1::answer}} or {{c1::answer::hint}}. Use c2 for a separate card; matching numbers hide together. Keep each card focused on one idea.", 14, MUTED)
	body.add_child(button("Save note", _save_editor, BLUE))

func _save_editor() -> void:
	var note := {"type": "Basic" if editor_fields.type.selected == 0 else "Cloze"}
	for key in ["deck", "front", "back", "extra", "tags"]:
		note[key] = editor_fields[key].text.strip_edges()
	if Flashcards.save_note(note, editor_id).is_empty():
		footer.text = Flashcards.last_error
	else:
		show_decks()
		footer.text = "Note saved to your collection."

func show_stats() -> void:
	clear("stats")
	text("Your study history", 28)
	var counts := [0, 0, 0, 0]
	var xp := 0
	for entry in Flashcards.review_log:
		counts[int(entry.rating) - 1] += 1
		xp += int(entry.xp)
	text("%d reviews   ·   %d study XP" % [Flashcards.review_log.size(), xp], 23, BLUE)
	for index in range(4):
		text("%s   %d" % [["Again", "Hard", "Good", "Easy"][index], counts[index]], 18)
	var retained: int = counts[1] + counts[2] + counts[3]
	text("Self-reported recall: %d%%" % int(100.0 * retained / maxi(1, Flashcards.review_log.size())), 19)
	text("History shows the latest 5,000 reviews. Recall ratings are self-reported, so they do not change graded question accuracy or lecture streaks.", 14, MUTED)

func show_options() -> void:
	clear("options")
	text("Collection options", 28)
	text("New cards per day (shared across all decks)", 16)
	var limit := SpinBox.new()
	limit.min_value = 0
	limit.max_value = 999
	limit.value = Flashcards.new_limit
	body.add_child(limit)
	limit.value_changed.connect(func(value: float) -> void: Flashcards.new_limit = int(value); SaveGame.autosave())
	text("Classic Anki-style scheduling\nLearning steps: 1 minute, 10 minutes\nGraduation: 1 day · Easy: 4 days\nRelearning: 10 minutes · Minimum ease: 130%\nLeeches: suspend after 8 review lapses\nCloze siblings: buried until the next UTC day", 17)
	text("Schedules use real time, even while the game is closed. Days reset at 00:00 UTC. Reviews are never limited; new cards have a daily limit.", 15, MUTED)
	text("This is an offline in-game implementation. FSRS, AnkiWeb, .apkg imports, add-ons, interval fuzz, and undo are not included.", 14, MUTED)

func _process(delta: float) -> void:
	refresh_elapsed += delta
	if refresh_elapsed >= 10.0:
		refresh_elapsed = 0.0
		if page == "complete":
			study_next()

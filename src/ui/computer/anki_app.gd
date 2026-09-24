extends VBoxContainer
## The Anki app, laid out like desktop Anki (light theme):
## - the top toolbar (Decks · Add · Browse · Stats · Sync);
## - the deck list: a collapsible tree with New / Learn / Due counts and a
##   gear menu per deck;
## - the overview (Study Now) and the reviewer: the card is centred, the
##   answer sits under a rule, and the bottom bar holds Edit, the remaining
##   counts with Show Answer (then Again / Hard / Good / Easy with their next
##   intervals) and More;
## - the Add window (note type, deck, fields, cloze button, tags);
## - a Browse window with sidebar filters, a search box that understands
##   is:/deck:/tag:, a card table and a preview pane;
## - Stats (today, future due, card counts, answer buttons, reviews);
## - deck Options.
## Scheduling, XP and persistence belong to the Flashcards collection.
const Kit = preload("res://ui/computer/os_kit.gd")
const Scheduler = preload("res://education/flashcards/scheduler.gd")
const INK := Color("1f1f1f")
const MUTED := Color("707070")
const LINE := Color("d9d9d9")
const PAPER := Color("ffffff")
const CHROME := Color("f3f3f3")
const NEW := Color("2563eb")
const LEARN := Color("dc2626")
const DUE := Color("16a34a")
const ACCENT := Color("2f6fcf")
var os_style := "windows"
var toolbar_buttons := {}
var main: Control
var body: VBoxContainer
var scroll: ScrollContainer
var bottom: PanelContainer
var bottom_row: HBoxContainer
var toast: PanelContainer
var toast_label: Label
var toast_tween: Tween
var deck := ""
var last_deck := ""
var current: Dictionary = {}
var page := "decks"
var collapsed := {}
var editor_fields := {}
var editor_id := ""
var search: LineEdit
var browser_list: VBoxContainer
var browser_selected := ""
var browser_preview: VBoxContainer
var reveal_button: Button
var rating_buttons: Array[Button] = []
var refresh_elapsed := 0.0

func _init(style := "windows") -> void:
	os_style = style

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 0)
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _line_box(CHROME, false))
	add_child(bar)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 4)
	bar.add_child(nav)
	for item in [["Decks", show_decks], ["Add", show_editor], ["Browse", show_browser], ["Stats", show_stats], ["Sync", _sync]]:
		var link := Kit.flat_button(item[0], os_style, 15, INK, [Color.TRANSPARENT, Color("e3e3e3"), Color("d6d6d6")], 6, Vector4(14, 5, 14, 5))
		link.pressed.connect(item[1])
		nav.add_child(link)
		toolbar_buttons[item[0]] = link
	main = Control.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.clip_contents = true
	add_child(main)
	var paper := ColorRect.new()
	paper.color = PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(paper)
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	scroll.add_child(margin)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(body)
	toast = PanelContainer.new()
	toast.add_theme_stylebox_override("panel", Kit.box(Color(0.12, 0.12, 0.14, 0.9), 8, Color.TRANSPARENT, 0, Vector4(14, 7, 14, 7)))
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast.position.y -= 16
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.modulate.a = 0.0
	toast_label = Kit.label("", os_style, 14, Color.WHITE)
	toast.add_child(toast_label)
	main.add_child(toast)
	bottom = PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _line_box(CHROME, true))
	add_child(bottom)
	bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	bottom.add_child(bottom_row)
	show_decks()

# --- Building blocks ---------------------------------------------------------------

func _line_box(fill: Color, top: bool) -> StyleBoxFlat:
	var style := Kit.box(fill, 0, LINE, 0, Vector4(12, 7, 12, 7))
	if top:
		style.border_width_top = 1
	else:
		style.border_width_bottom = 1
	return style

## Anki's standard push button: white-to-grey, 1 px border, rounded.
func button(text: String, callback: Callable, primary := false, size := 14) -> Button:
	var result := Button.new()
	result.text = text
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_override("font", Kit.font(os_style, 600 if primary else 400))
	result.add_theme_font_size_override("font_size", size)
	var ink := Color.WHITE if primary else INK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		result.add_theme_color_override(state, ink)
	result.add_theme_color_override("font_disabled_color", Color(ink, 0.45))
	var fills := [ACCENT, ACCENT.lightened(0.1), ACCENT.darkened(0.12), ACCENT.lightened(0.35)] if primary else [Color("fdfdfd"), Color("f0f4fa"), Color("e2e8f0"), Color("f6f6f6")]
	var states := ["normal", "hover", "pressed", "disabled"]
	for index in range(4):
		result.add_theme_stylebox_override(states[index], Kit.box(fills[index], 6, ACCENT.darkened(0.15) if primary else Color("c4c4c4"), 1, Vector4(14, 6, 14, 6)))
	result.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	result.pressed.connect(callback)
	return result

## A label; `wrap` only where it has a width to wrap into (a column, or an
## expanding cell), since a wrapping label in a row shrinks to one letter.
func label(text: String, size := 15, color := INK, weight := 400, center := false, wrap := false) -> Label:
	var result := Kit.label(text, os_style, size, color, weight)
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result

func text(value: String, size := 15, color := INK, center := false, weight := 400) -> Label:
	var result := label(value, size, color, weight, center, true)
	body.add_child(result)
	return result

## Card text in Anki's default card style (Arial, centred).
func card_text(value: String, size: int, color := INK) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_override("font", Kit.card_font())
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_constant_override("line_spacing", 4)
	body.add_child(result)
	return result

static func field(placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.add_theme_color_override("font_color", INK)
	edit.add_theme_color_override("font_placeholder_color", MUTED)
	edit.add_theme_color_override("caret_color", INK)
	edit.add_theme_color_override("selection_color", Color("b8d4ff"))
	edit.add_theme_stylebox_override("normal", Kit.box(Color.WHITE, 5, Color("c4c4c4"), 1, Vector4(9, 6, 9, 6)))
	edit.add_theme_stylebox_override("focus", Kit.box(Color.WHITE, 5, ACCENT, 2, Vector4(9, 6, 9, 6)))
	return edit

func _field_box(value: String, height: float) -> TextEdit:
	var edit := TextEdit.new()
	edit.custom_minimum_size.y = height
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.text = value
	edit.add_theme_font_override("font", Kit.card_font())
	edit.add_theme_font_size_override("font_size", 16)
	edit.add_theme_color_override("font_color", INK)
	edit.add_theme_color_override("caret_color", INK)
	edit.add_theme_color_override("selection_color", Color("b8d4ff"))
	edit.add_theme_stylebox_override("normal", Kit.box(Color.WHITE, 5, Color("c4c4c4"), 1, Vector4(10, 8, 10, 8)))
	edit.add_theme_stylebox_override("focus", Kit.box(Color.WHITE, 5, ACCENT, 2, Vector4(10, 8, 10, 8)))
	return edit

func _count_label(value: int, color: Color, width := 64.0, size := 16) -> Label:
	var result := Kit.label(str(value), os_style, size, color if value > 0 else Color("c2c2c2"), 600 if value > 0 else 400)
	result.custom_minimum_size.x = width
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return result

func show_toast(message: String) -> void:
	toast_label.text = message
	if toast_tween:
		toast_tween.kill()
	toast.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)

func clear(next_page: String) -> void:
	Flashcards.end_review()
	current = {}
	page = next_page
	rating_buttons.clear()
	reveal_button = null
	for parent in [body, bottom_row]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()
	scroll.scroll_vertical = 0
	for key in toolbar_buttons:
		var active: bool = {"Decks": ["decks", "overview", "review", "complete", "options"], "Add": ["editor"], "Browse": ["browse", "inspect"], "Stats": ["stats"]}.get(key, []).has(next_page)
		toolbar_buttons[key].add_theme_stylebox_override("normal", Kit.box(Color("e3e3e3") if active else Color.TRANSPARENT, 6, Color.TRANSPARENT, 0, Vector4(14, 5, 14, 5)))

func _bottom_spacer() -> void:
	bottom_row.add_child(Control.new())
	bottom_row.get_child(bottom_row.get_child_count() - 1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _sync() -> void:
	show_toast("Offline — your collection is saved on this device and shared with your other computer.")

func _today_start() -> int:
	return int(Flashcards.now() / Scheduler.DAY) * Scheduler.DAY

func _today_reviews() -> Array:
	var start := _today_start()
	return Flashcards.review_log.filter(func(entry: Dictionary) -> bool: return int(entry.at) >= start)

static func leaf(name: String) -> String:
	return name.get_slice("::", name.get_slice_count("::") - 1)

## Interval text as Anki shows it on the answer buttons: <1m, <10m, 4d, 1.5mo, 2.1y.
static func anki_interval(seconds: int) -> String:
	if seconds < 3600:
		return "<%dm" % maxi(1, int(ceil(seconds / 60.0)))
	if seconds < Scheduler.DAY:
		return "<%dh" % int(ceil(seconds / 3600.0))
	var days := seconds / float(Scheduler.DAY)
	if days < 30.0:
		return "%dd" % int(round(days))
	if days < 365.0:
		return "%.1fmo" % (days / 30.0)
	return "%.1fy" % (days / 365.0)

# --- Decks ------------------------------------------------------------------------

func show_decks() -> void:
	clear("decks")
	var center := CenterContainer.new()
	body.add_child(center)
	var table := VBoxContainer.new()
	table.custom_minimum_size.x = 640
	table.add_theme_constant_override("separation", 2)
	center.add_child(table)
	var header := HBoxContainer.new()
	table.add_child(header)
	var title := Kit.label("Deck", os_style, 14, MUTED, 600)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for heading in ["New", "Learn", "Due"]:
		var cell := Kit.label(heading, os_style, 14, MUTED, 600)
		cell.custom_minimum_size.x = 64
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		header.add_child(cell)
	header.add_child(Control.new())
	header.get_child(header.get_child_count() - 1).custom_minimum_size.x = 34
	var rule := ColorRect.new()
	rule.color = LINE
	rule.custom_minimum_size.y = 1
	table.add_child(rule)
	for entry in _deck_tree():
		table.add_child(_deck_row(entry[0], entry[1], entry[2]))
	var today := _today_reviews()
	var xp := 0
	for entry in today:
		xp += int(entry.xp)
	body.add_child(Control.new())
	text("Studied %d card%s today." % [today.size(), "" if today.size() == 1 else "s"], 14, MUTED, true)
	text("Study XP today: %d / %d" % [xp, Flashcards.DAILY_XP_CAP], 13, Color("9a9a9a"), true)
	var shared := button("Get Shared", func() -> void: show_toast("Shared decks need AnkiWeb, which isn't available offline."))
	bottom_row.add_child(shared)
	bottom_row.add_child(button("Create Deck", func() -> void: show_editor()))
	bottom_row.add_child(button("Import File", func() -> void: show_toast("Importing isn't available in this version.")))
	_bottom_spacer()
	bottom_row.add_child(label("Collection shared between your dorm PC and laptop", 12, MUTED))

## [path, depth, has_children] for every visible deck, parents before children.
func _deck_tree() -> Array:
	var paths: Array = []
	for name in Flashcards.decks():
		var parts: PackedStringArray = name.split("::")
		for depth in range(parts.size()):
			var path := "::".join(parts.slice(0, depth + 1))
			if path not in paths:
				paths.append(path)
	paths.sort()
	var result: Array = []
	for path in paths:
		var hidden := false
		var parts: PackedStringArray = path.split("::")
		for depth in range(parts.size() - 1):
			if collapsed.get("::".join(parts.slice(0, depth + 1)), false):
				hidden = true
		if hidden:
			continue
		var has_children := paths.any(func(other: String) -> bool: return other.begins_with(path + "::"))
		result.append([path, parts.size() - 1, has_children])
	return result

func _deck_row(path: String, depth: int, has_children: bool) -> Control:
	var row := PanelContainer.new()
	var selected := path == last_deck
	row.add_theme_stylebox_override("panel", Kit.box(Color("e8f0fe") if selected else Color.TRANSPARENT, 5, Color.TRANSPARENT, 0, Vector4(6, 3, 6, 3)))
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.mouse_entered.connect(func() -> void:
		if path != last_deck:
			row.add_theme_stylebox_override("panel", Kit.box(Color("f3f6fb"), 5, Color.TRANSPARENT, 0, Vector4(6, 3, 6, 3))))
	row.mouse_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", Kit.box(Color("e8f0fe") if path == last_deck else Color.TRANSPARENT, 5, Color.TRANSPARENT, 0, Vector4(6, 3, 6, 3))))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 2)
	row.add_child(line)
	line.add_child(Control.new())
	line.get_child(0).custom_minimum_size.x = depth * 22
	var toggle := Kit.flat_button(("+" if collapsed.get(path, false) else "−") if has_children else "", os_style, 15, MUTED, [Color.TRANSPARENT, Color("e3e3e3")], 4, Vector4(4, 0, 4, 0))
	toggle.custom_minimum_size.x = 22
	toggle.disabled = not has_children
	toggle.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	toggle.pressed.connect(func() -> void:
		collapsed[path] = not collapsed.get(path, false)
		show_decks())
	line.add_child(toggle)
	var name := Kit.flat_button(leaf(path), os_style, 16, INK, [Color.TRANSPARENT], 0, Vector4(4, 4, 4, 4), 600 if depth == 0 else 400)
	name.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	name.pressed.connect(func() -> void: show_overview(path))
	line.add_child(name)
	var count: Dictionary = Flashcards.counts(path)
	line.add_child(_count_label(count.new, NEW))
	line.add_child(_count_label(count.learn, LEARN))
	line.add_child(_count_label(count.due, DUE))
	var gear := Button.new()
	gear.icon = Kit.icon("gear")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(26, 22)
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gear.modulate = Color(1, 1, 1, 0.75)
	gear.focus_mode = Control.FOCUS_NONE
	gear.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	gear.add_theme_stylebox_override("hover", Kit.box(Color("e3e3e3"), 5))
	gear.add_theme_stylebox_override("pressed", Kit.box(Color("d6d6d6"), 5))
	gear.tooltip_text = "Options"
	gear.pressed.connect(func() -> void:
		last_deck = path
		show_options())
	line.add_child(gear)
	return row

# --- Overview and review ------------------------------------------------------------

func show_overview(name: String) -> void:
	clear("overview")
	deck = name
	last_deck = name
	var count: Dictionary = Flashcards.counts(deck)
	body.add_child(Control.new())
	text(leaf(deck), 30, INK, true, 600)
	var center := CenterContainer.new()
	body.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	center.add_child(grid)
	for entry in [["New:", count.new, NEW], ["Learning:", count.learn, LEARN], ["To Review:", count.due, DUE]]:
		var name_label := Kit.label(entry[0], os_style, 17, INK)
		grid.add_child(name_label)
		var value := Kit.label(str(entry[1]), os_style, 17, entry[2], 600)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(value)
	var start_row := CenterContainer.new()
	body.add_child(start_row)
	var start := button("Study Now", study_next, true, 16)
	start.custom_minimum_size = Vector2(150, 40)
	start_row.add_child(start)
	var description := "Original questions from the Pharmacodynamics lecture. Answer from memory, then grade yourself honestly." if deck.begins_with("Medicine") else "Your own notes. Add more from Add in the toolbar."
	text(description, 14, MUTED, true)
	text("Press S or Enter to study.", 12, Color("a0a0a0"), true)
	bottom_row.add_child(button("Options", show_options))
	bottom_row.add_child(button("Custom Study", func() -> void: show_toast("Custom study sessions aren't available in this version.")))
	bottom_row.add_child(button("Description", func() -> void: show_toast(description)))

func study_next() -> void:
	clear("review")
	if deck.is_empty():
		deck = last_deck
	var queue: Array = Flashcards.queue(deck)
	if queue.is_empty():
		page = "complete"
		body.add_child(Control.new())
		text("Congratulations! You have finished this deck for now.", 22, INK, true, 600)
		var due: int = Flashcards.next_due(deck)
		if due > Flashcards.now():
			text("The next card will be ready in %s." % Scheduler.interval_text(due - Flashcards.now()), 16, MUTED, true)
		else:
			text("New cards may be waiting behind today's limit, or buried and suspended cards are hidden until later.", 15, MUTED, true)
		text("If you wish to study outside of the regular schedule, you can raise today's new card limit in Options.", 14, Color("9a9a9a"), true)
		bottom_row.add_child(button("Decks", show_decks))
		_bottom_spacer()
		bottom_row.add_child(button("Options", show_options))
		return
	current = queue[0]
	if not Flashcards.begin_review(current.id):
		return
	body.add_child(Control.new())
	card_text(current.front, 26)
	_review_bar(false)

func _review_bar(answered: bool) -> void:
	for child in bottom_row.get_children():
		bottom_row.remove_child(child)
		child.queue_free()
	var edit := button("Edit", _edit_current)
	edit.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_row.add_child(edit)
	_bottom_spacer()
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 4)
	bottom_row.add_child(center)
	if not answered:
		var counts := HBoxContainer.new()
		counts.alignment = BoxContainer.ALIGNMENT_CENTER
		counts.add_theme_constant_override("separation", 6)
		center.add_child(counts)
		var count: Dictionary = Flashcards.counts(deck)
		var phase: String = Flashcards.status(current.id).phase
		var active := "new" if phase == "new" else ("due" if phase == "review" else "learn")
		for index in range(3):
			var key: String = ["new", "learn", "due"][index]
			var number := Kit.label(str(count[key]), os_style, 15, [NEW, LEARN, DUE][index], 700 if key == active else 400)
			if key == active:
				number.draw.connect(func() -> void:
					number.draw_line(Vector2(0, number.size.y - 1), Vector2(number.size.x, number.size.y - 1), [NEW, LEARN, DUE][index], 2.0))
			counts.add_child(number)
			if index < 2:
				counts.add_child(Kit.label("+", os_style, 15, MUTED))
		reveal_button = button("Show Answer", show_answer, false, 15)
		reveal_button.custom_minimum_size = Vector2(220, 36)
		center.add_child(reveal_button)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		center.add_child(row)
		var colors := [LEARN, Color("b45309"), DUE, NEW]
		for index in range(4):
			var scheduled := Scheduler.next(Flashcards.status(current.id), index + 1, Flashcards.now())
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", 2)
			row.add_child(cell)
			var interval := Kit.label(anki_interval(int(scheduled.due) - Flashcards.now()), os_style, 12, MUTED)
			interval.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(interval)
			var rating := button(["Again", "Hard", "Good", "Easy"][index], rate.bind(index + 1), false, 15)
			rating.add_theme_color_override("font_color", colors[index])
			rating.add_theme_color_override("font_hover_color", colors[index])
			rating.custom_minimum_size = Vector2(104, 36)
			rating.tooltip_text = "%d · %s" % [index + 1, ["Forgot", "Recalled with serious difficulty", "Recalled after some thought", "Recalled instantly"][index]]
			cell.add_child(rating)
			rating_buttons.append(rating)
	_bottom_spacer()
	var more := MenuButton.new()
	more.text = "More ▾"
	more.focus_mode = Control.FOCUS_NONE
	more.add_theme_font_override("font", Kit.font(os_style))
	more.add_theme_font_size_override("font_size", 14)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		more.add_theme_color_override(state, INK)
	more.add_theme_stylebox_override("normal", Kit.box(Color("fdfdfd"), 6, Color("c4c4c4"), 1, Vector4(14, 6, 14, 6)))
	more.add_theme_stylebox_override("hover", Kit.box(Color("f0f4fa"), 6, Color("c4c4c4"), 1, Vector4(14, 6, 14, 6)))
	more.add_theme_stylebox_override("pressed", Kit.box(Color("e2e8f0"), 6, Color("c4c4c4"), 1, Vector4(14, 6, 14, 6)))
	more.size_flags_vertical = Control.SIZE_SHRINK_END
	var popup := more.get_popup()
	popup.add_item("Bury Card            -", 0)
	popup.add_item("Suspend Card        @", 1)
	popup.add_item("Edit                        E", 2)
	popup.id_pressed.connect(_more_pressed)
	bottom_row.add_child(more)

func _more_pressed(id: int) -> void:
	if id == 0:
		_bury_current()
	elif id == 1:
		_suspend_current()
	else:
		_edit_current()

func show_answer() -> void:
	if current.is_empty() or Flashcards.revealed:
		return
	Flashcards.reveal()
	var rule := ColorRect.new()
	rule.color = LINE
	rule.custom_minimum_size.y = 1
	body.add_child(rule)
	card_text(current.back, 26)
	if not String(current.get("extra", "")).is_empty():
		var extra := card_text(current.extra, 17, Color("4a4a4a"))
		extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var details: Array = []
	if current.has("objective") and not String(current.objective).is_empty():
		details.append("Objective: " + current.objective)
	details.append(String(current.tags) + "  ·  " + String(current.source))
	text("\n".join(details), 12, Color("9a9a9a"), true)
	_review_bar(true)

func rate(value: int) -> void:
	var result: Dictionary = Flashcards.rate(value)
	if result.is_empty():
		return
	study_next()
	if result.suspended:
		show_toast("Card was a leech and has been suspended.")
	elif result.xp > 0:
		show_toast("+%d XP" % result.xp)

func _bury_current() -> void:
	if current.is_empty():
		return
	Flashcards.bury(current.id)
	study_next()
	show_toast("Card buried.")

func _suspend_current() -> void:
	if current.is_empty():
		return
	Flashcards.set_suspended(current.id, true)
	study_next()
	show_toast("Card suspended.")

func _edit_current() -> void:
	if current.is_empty():
		return
	inspect_card(current)

## Ctrl+Enter (⌘+Enter on the Mac) adds the note, even while typing in a field.
func editor_shortcut(event: InputEvent) -> bool:
	if page != "editor" or not event is InputEventKey or not event.pressed or event.echo:
		return false
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER] and (event.ctrl_pressed or event.meta_pressed):
		_save_editor()
		return true
	return false

## Reviewer keys as in Anki: Space/Enter reveal (then Good), 1–4 rate,
## - bury, @ suspend, E edit; S or Enter starts studying from the overview.
func shortcut(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:
		return false
	if page == "overview" and event.keycode in [KEY_S, KEY_ENTER, KEY_SPACE]:
		study_next()
		return true
	if page != "review" or current.is_empty():
		return false
	if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if Flashcards.revealed:
			rate(3)
		else:
			show_answer()
		return true
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		if Flashcards.revealed:
			rate(event.keycode - KEY_1 + 1)
		return true
	if event.keycode == KEY_MINUS:
		_bury_current()
		return true
	if event.unicode == "@".unicode_at(0) or (event.keycode == KEY_2 and event.shift_pressed):
		_suspend_current()
		return true
	if event.keycode == KEY_E:
		_edit_current()
		return true
	return false

# --- Browse ------------------------------------------------------------------------

func show_browser() -> void:
	clear("browse")
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	body.add_child(top)
	search = field("Search cards (e.g. is:due, deck:Personal, tag:Potency, or any words)")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(search)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	body.add_child(split)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 170
	sidebar.add_theme_constant_override("separation", 1)
	split.add_child(sidebar)
	var filters: Array = [["Whole Collection", ""], ["Due Today", "is:due"], ["", ""], ["New", "is:new"], ["Learning", "is:learn"], ["Review", "is:review"], ["Suspended", "is:suspended"], ["", ""]]
	for name in Flashcards.decks():
		filters.append([leaf(name), "deck:\"%s\"" % name])
	var tags: Array = []
	for c in Flashcards.cards():
		for tag in String(c.tags).split(" ", false):
			if tag not in tags:
				tags.append(tag)
	tags.sort()
	if not tags.is_empty():
		filters.append(["", ""])
		for tag in tags.slice(0, 8):
			filters.append(["# " + tag, "tag:" + tag])
	for entry in filters:
		if entry[0].is_empty():
			var gap := ColorRect.new()
			gap.color = LINE
			gap.custom_minimum_size.y = 1
			sidebar.add_child(gap)
			continue
		var item := Kit.flat_button(entry[0], os_style, 13, INK, [Color.TRANSPARENT, Color("e8f0fe"), Color("d4e3fc")], 4, Vector4(8, 4, 8, 4))
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var query: String = entry[1]
		item.pressed.connect(func() -> void:
			search.text = query
			_browser_results())
		sidebar.add_child(item)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	split.add_child(right)
	var header := _browser_row_box(Color("f3f3f3"))
	right.add_child(header)
	_browser_cells(header.get_child(0), ["Sort Field", "Card", "Due", "Deck", "Reviews"], MUTED, 600)
	browser_list = VBoxContainer.new()
	browser_list.add_theme_constant_override("separation", 0)
	right.add_child(browser_list)
	browser_preview = VBoxContainer.new()
	browser_preview.add_theme_constant_override("separation", 6)
	body.add_child(browser_preview)
	search.text_changed.connect(func(_value: String) -> void: _browser_results())
	_browser_results()
	bottom_row.add_child(label("Click a card to preview it.", 13, MUTED))

func _browser_row_box(fill: Color) -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", Kit.box(fill, 0, Color.TRANSPARENT, 0, Vector4(8, 5, 8, 5)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	return box

func _browser_cells(row: HBoxContainer, values: Array, color: Color, weight := 400) -> void:
	var widths := [0.0, 90.0, 110.0, 140.0, 60.0]
	for index in range(values.size()):
		var cell := Kit.label(values[index], os_style, 13, color, weight)
		cell.clip_text = true
		cell.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if index == 0:
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.custom_minimum_size.x = 120
		else:
			cell.custom_minimum_size.x = widths[index]
		row.add_child(cell)

## Anki-style search: is:new|learn|review|due|suspended, deck:"Name",
## tag:Name, and free words (all terms must match).
func _matches(c: Dictionary, query: String) -> bool:
	var s: Dictionary = Flashcards.status(c.id)
	var terms := RegEx.create_from_string("(\\w+:\"[^\"]*\"|\\S+)").search_all(query)
	for found in terms:
		var term := found.get_string().to_lower()
		if term.begins_with("is:"):
			var wanted := term.substr(3)
			var ok := false
			match wanted:
				"new": ok = s.phase == "new"
				"learn": ok = s.phase in ["learning", "relearning"]
				"review": ok = s.phase == "review"
				"due": ok = s.phase != "new" and int(s.due) <= Flashcards.now() and not s.suspended
				"suspended": ok = bool(s.suspended)
			if not ok:
				return false
		elif term.begins_with("deck:"):
			var name := term.substr(5).trim_prefix("\"").trim_suffix("\"")
			if not (String(c.deck).to_lower() == name or String(c.deck).to_lower().begins_with(name + "::")):
				return false
		elif term.begins_with("tag:"):
			if not term.substr(4) in String(c.tags).to_lower().split(" ", false):
				return false
		elif not term in (String(c.front) + " " + String(c.back) + " " + String(c.tags) + " " + String(c.get("extra", ""))).to_lower():
			return false
	return true

func _browser_results() -> void:
	for child in browser_list.get_children():
		browser_list.remove_child(child)
		child.queue_free()
	var index := 0
	for c in Flashcards.cards():
		if not _matches(c, search.text):
			continue
		var s: Dictionary = Flashcards.status(c.id)
		var selected := String(c.id) == browser_selected
		var fill := Color("cfe0fc") if selected else (Color("fafafa") if index % 2 else Color.WHITE)
		if s.suspended and not selected:
			fill = Color("fdf6d8")
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size.y = 28
		row.add_theme_stylebox_override("normal", Kit.box(fill))
		row.add_theme_stylebox_override("hover", Kit.box(Color("e8f0fe") if not selected else fill))
		row.add_theme_stylebox_override("pressed", Kit.box(Color("cfe0fc")))
		var cells := HBoxContainer.new()
		cells.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cells.offset_left = 8
		cells.offset_right = -8
		cells.add_theme_constant_override("separation", 10)
		cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cells)
		var due := "New" if s.phase == "new" else Time.get_date_string_from_unix_time(int(s.due))
		if s.suspended:
			due = "(suspended)"
		var kind := "Question" if String(c.id).begins_with("bank:") else ("Cloze " + String(c.id).get_slice(":c", 1) if ":c" in String(c.id) else "Basic")
		_browser_cells(cells, [String(c.front).replace("\n", " "), kind, due, leaf(c.deck), str(s.reps)], INK)
		var card: Dictionary = c
		row.pressed.connect(func() -> void:
			browser_selected = card.id
			_browser_results()
			_browser_preview(card))
		browser_list.add_child(row)
		index += 1

func _browser_preview(c: Dictionary) -> void:
	for child in browser_preview.get_children():
		browser_preview.remove_child(child)
		child.queue_free()
	var rule := ColorRect.new()
	rule.color = LINE
	rule.custom_minimum_size.y = 1
	browser_preview.add_child(rule)
	var s: Dictionary = Flashcards.status(c.id)
	for entry in [["Front", c.front], ["Back", c.back], ["Extra", c.get("extra", "")]]:
		if String(entry[1]).is_empty():
			continue
		browser_preview.add_child(label(entry[0], 12, MUTED, 600))
		browser_preview.add_child(label(entry[1], 15, INK, 400, false, true))
	var info := "%s  ·  %s  ·  %d reviews  ·  %d lapses  ·  ease %d%%" % [c.tags, "suspended" if s.suspended else s.phase, s.reps, s.lapses, int(float(s.ease) * 100)]
	browser_preview.add_child(label(info, 12, MUTED, 400, false, true))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	browser_preview.add_child(actions)
	actions.add_child(button("Edit Note" if String(c.id).begins_with("user:") else "Card Info", func() -> void: inspect_card(c)))
	actions.add_child(button("Unsuspend" if s.suspended else "Suspend", func() -> void:
		Flashcards.set_suspended(c.id, not s.suspended)
		_browser_results()
		_browser_preview(Flashcards.card(c.id))))

func inspect_card(c: Dictionary) -> void:
	if String(c.id).begins_with("user:"):
		show_editor(c.note)
		return
	clear("inspect")
	text("Card Info", 22, INK, false, 600)
	var s: Dictionary = Flashcards.status(c.id)
	text(c.front, 18)
	text(c.back, 17, DUE.darkened(0.2))
	text(String(c.get("extra", "")), 14, MUTED)
	text("Source: shared question bank (%s)\n%s\nReviews %d · Lapses %d · Ease %d%% · %s" % [c.source, c.get("objective", ""), s.reps, s.lapses, int(float(s.ease) * 100), "New" if s.phase == "new" else "Due " + Time.get_date_string_from_unix_time(int(s.due))], 13, MUTED)
	text("Question-bank cards are read-only; add your own version from Add.", 13, Color("9a9a9a"))
	bottom_row.add_child(button("Back to Browse", show_browser))

# --- Add / edit ----------------------------------------------------------------------

func show_editor(id := "") -> void:
	clear("editor")
	editor_id = id
	editor_fields.clear()
	var note: Dictionary = Flashcards.notes.get(id, {"type": "Basic", "deck": last_deck if last_deck.begins_with("Personal") else "Personal", "front": "", "back": "", "extra": "", "tags": ""})
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	body.add_child(top)
	top.add_child(label("Type", 14, MUTED))
	var type := OptionButton.new()
	type.add_item("Basic")
	type.add_item("Cloze")
	type.select(0 if note.type == "Basic" else 1)
	type.focus_mode = Control.FOCUS_NONE
	type.custom_minimum_size.x = 140
	top.add_child(type)
	editor_fields.type = type
	top.add_child(UIHelpers.gap(18))
	top.add_child(label("Deck", 14, MUTED))
	var deck_edit := field("Personal")
	deck_edit.text = note.deck
	deck_edit.custom_minimum_size.x = 280
	top.add_child(deck_edit)
	editor_fields.deck = deck_edit
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 6)
	body.add_child(tools)
	var cloze := button("[…]  Cloze", _insert_cloze)
	cloze.tooltip_text = "Wrap the selection in a cloze deletion (Ctrl+Shift+C in Anki)"
	tools.add_child(cloze)
	var hint := label("", 12, MUTED, 400, false, true)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(hint)
	var titles := {"front": "Front", "back": "Back", "extra": "Extra"}
	for key in ["front", "back", "extra"]:
		var title := label(titles[key], 13, INK, 600)
		body.add_child(title)
		var edit := _field_box(note[key], 70 if key != "extra" else 56)
		body.add_child(edit)
		editor_fields[key] = edit
		editor_fields[key + "_title"] = title
	body.add_child(label("Tags", 13, INK, 600))
	var tags := field("space-separated tags")
	tags.text = note.tags
	body.add_child(tags)
	editor_fields.tags = tags
	var relabel := func(index: int) -> void:
		var is_cloze := index == 1
		editor_fields.front_title.text = "Text" if is_cloze else "Front"
		editor_fields.back_title.visible = not is_cloze
		editor_fields.back.visible = not is_cloze
		editor_fields.extra_title.text = "Back Extra" if is_cloze else "Extra"
		hint.text = "{{c1::answer}} or {{c1::answer::hint}} — matching numbers hide together; c2 makes a second card." if is_cloze else "One idea per card. Ctrl+Enter adds the note."
	type.item_selected.connect(relabel)
	relabel.call(type.selected)
	bottom_row.add_child(button("History", func() -> void: show_toast("%d personal note%s in your collection." % [Flashcards.notes.size(), "" if Flashcards.notes.size() == 1 else "s"])))
	_bottom_spacer()
	bottom_row.add_child(button("Close", show_browser if not id.is_empty() else show_decks))
	bottom_row.add_child(button("Save" if not id.is_empty() else "Add", _save_editor, true))
	var front: TextEdit = editor_fields.front
	(func() -> void:
		if is_instance_valid(front) and front.is_inside_tree():
			front.grab_focus()).call_deferred()

## Wraps the Text field's selection (or inserts at the caret) in the next cloze number.
func _insert_cloze() -> void:
	var edit: TextEdit = editor_fields.front
	if editor_fields.type.selected != 1:
		editor_fields.type.select(1)
		editor_fields.type.item_selected.emit(1)
	var highest := 0
	for found in Flashcards.cloze_pattern().search_all(edit.text):
		highest = maxi(highest, int(found.get_string(1)))
	var selected := edit.get_selected_text()
	edit.insert_text_at_caret("{{c%d::%s}}" % [highest + 1, selected if not selected.is_empty() else "answer"])

func _save_editor() -> void:
	var note := {"type": "Basic" if editor_fields.type.selected == 0 else "Cloze"}
	for key in ["deck", "front", "back", "extra", "tags"]:
		note[key] = editor_fields[key].text.strip_edges()
	if note.type == "Cloze":
		note.back = ""
	var editing := not editor_id.is_empty()
	if Flashcards.save_note(note, editor_id).is_empty():
		show_toast(Flashcards.last_error)
		return
	if editing:
		show_browser()
		show_toast("Note saved.")
	else:
		# As in Anki, the Add window stays open for the next note.
		last_deck = note.deck
		editor_fields.front.text = ""
		editor_fields.back.text = ""
		editor_fields.extra.text = ""
		editor_fields.front.grab_focus()
		show_toast("Added.")

# --- Stats ---------------------------------------------------------------------------

func show_stats() -> void:
	clear("stats")
	var today := _today_reviews()
	var again := today.filter(func(e: Dictionary) -> bool: return int(e.rating) == 1).size()
	text("Today", 20, INK, true, 600)
	if today.is_empty():
		text("No cards have been studied today.", 15, MUTED, true)
	else:
		var learn := today.filter(func(e: Dictionary) -> bool: return e.phase in ["new", "learning"]).size()
		var relearn := today.filter(func(e: Dictionary) -> bool: return e.phase == "relearning").size()
		text("Studied %d cards today.\nAgain count: %d (%d%% correct)\nLearn: %d · Review: %d · Relearn: %d" % [today.size(), again, int(100.0 * (today.size() - again) / today.size()), learn, today.size() - learn - relearn, relearn], 15, INK, true)
	var forecast: Array = []
	forecast.resize(31)
	forecast.fill(0)
	var kinds := {"New": 0, "Learning": 0, "Young": 0, "Mature": 0, "Suspended": 0}
	var start := _today_start()
	for c in Flashcards.cards():
		var s: Dictionary = Flashcards.status(c.id)
		if s.suspended:
			kinds.Suspended += 1
			continue
		match String(s.phase):
			"new": kinds.New += 1
			"learning", "relearning": kinds.Learning += 1
			_: kinds["Mature" if int(s.interval) >= 21 else "Young"] += 1
		if s.phase != "new":
			var day := clampi(int((int(s.due) - start) / Scheduler.DAY), 0, 30)
			forecast[day] += 1
	_stat_card("Future Due", "Cards due each day for the next month (today includes overdue).", _bar_chart(forecast, DUE, ["Today", "+10", "+20", "+30"]))
	var counts_box := VBoxContainer.new()
	var stacked := Control.new()
	stacked.custom_minimum_size = Vector2(0, 18)
	var palette := {"New": NEW, "Learning": LEARN, "Young": Color("65a30d"), "Mature": Color("15803d"), "Suspended": Color("eab308")}
	var total := maxi(1, Flashcards.cards().size())
	stacked.draw.connect(func() -> void:
		var x := 0.0
		for key in kinds:
			var w: float = stacked.size.x * kinds[key] / total
			stacked.draw_rect(Rect2(x, 0, w, stacked.size.y), palette[key])
			x += w)
	counts_box.add_child(stacked)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 18)
	for key in kinds:
		legend.add_child(label("■ %s %d" % [key, kinds[key]], 13, palette[key].darkened(0.1)))
	counts_box.add_child(legend)
	_stat_card("Card Counts", "%d cards in your collection." % Flashcards.cards().size(), counts_box)
	var buttons := [0, 0, 0, 0]
	for entry in Flashcards.review_log:
		buttons[int(entry.rating) - 1] += 1
	var answer_box := VBoxContainer.new()
	var reviews := maxi(1, Flashcards.review_log.size())
	for index in range(4):
		var row := HBoxContainer.new()
		row.add_child(label(["Again", "Hard", "Good", "Easy"][index], 13, INK))
		row.get_child(0).custom_minimum_size.x = 60
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fraction: float = buttons[index] / float(reviews)
		var color: Color = [LEARN, Color("b45309"), DUE, NEW][index]
		bar.draw.connect(func() -> void:
			bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color("f0f0f0"))
			bar.draw_rect(Rect2(0, 0, bar.size.x * fraction, bar.size.y), color))
		row.add_child(bar)
		row.add_child(label("  %d (%d%%)" % [buttons[index], int(round(fraction * 100))], 13, MUTED))
		answer_box.add_child(row)
	_stat_card("Answer Buttons", "Self-rated recall; it never changes graded lecture accuracy.", answer_box)
	var per_day: Array = []
	per_day.resize(30)
	per_day.fill(0)
	for entry in Flashcards.review_log:
		var ago := int((start - int(entry.at) + Scheduler.DAY - 1) / Scheduler.DAY)
		var slot := 29 - ago
		if slot >= 0 and slot < 30:
			per_day[slot] += 1
	_stat_card("Reviews", "Cards reviewed each day over the last month.", _bar_chart(per_day, ACCENT, ["-29", "-20", "-10", "Today"]))

func _stat_card(title: String, subtitle: String, content: Control) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Kit.box(Color.WHITE, 8, LINE, 1, Vector4(18, 12, 18, 14)))
	body.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	column.add_child(label(title, 16, INK, 600, true))
	column.add_child(label(subtitle, 12, MUTED, 400, true, true))
	column.add_child(content)

func _bar_chart(values: Array, color: Color, ticks: Array) -> Control:
	var chart := Control.new()
	chart.custom_minimum_size = Vector2(0, 110)
	var highest := 1
	for v in values:
		highest = maxi(highest, int(v))
	var font := Kit.font(os_style)
	var empty := values.all(func(v) -> bool: return int(v) == 0)
	chart.draw.connect(func() -> void:
		if empty:
			chart.draw_string(font, Vector2(0, chart.size.y / 2.0), "No data", HORIZONTAL_ALIGNMENT_CENTER, chart.size.x, 13, MUTED)
			return
		var plot := Rect2(28, 4, chart.size.x - 32, chart.size.y - 24)
		chart.draw_line(plot.position + Vector2(0, plot.size.y), plot.end, LINE, 1.0)
		chart.draw_string(font, Vector2(0, plot.position.y + 10), str(highest), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)
		var w := plot.size.x / values.size()
		for i in range(values.size()):
			var h := plot.size.y * int(values[i]) / float(highest)
			if h > 0:
				chart.draw_rect(Rect2(plot.position.x + i * w + 1, plot.end.y - h, maxf(1.0, w - 2), h), color)
		for t in range(ticks.size()):
			var x := plot.position.x + plot.size.x * t / float(ticks.size() - 1)
			chart.draw_string(font, Vector2(x - 14, chart.size.y - 4), ticks[t], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED))
	return chart

# --- Options ---------------------------------------------------------------------------

func show_options() -> void:
	clear("options")
	text("Deck Options", 22, INK, false, 600)
	text("Preset: Default (used by all decks)", 13, MUTED)
	var sections := [
		["Daily Limits", [["New cards/day", "spin"], ["Maximum reviews/day", "Unlimited"]]],
		["New Cards", [["Learning steps", "1m 10m"], ["Graduating interval", "1 day"], ["Easy interval", "4 days"], ["Insertion order", "Sequential"]]],
		["Lapses", [["Relearning steps", "10m"], ["Minimum interval", "1 day"], ["Leech threshold", "8 lapses"], ["Leech action", "Suspend Card"]]],
		["Advanced", [["Maximum interval", "36500 days"], ["Starting ease", "2.50"], ["Easy bonus", "1.30"], ["Hard interval", "1.20"], ["New interval", "0.00"], ["Next day starts at", "00:00 UTC"], ["FSRS", "Off"]]],
	]
	for section in sections:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", Kit.box(Color.WHITE, 8, LINE, 1, Vector4(18, 12, 18, 12)))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		card.add_child(column)
		column.add_child(label(section[0], 16, INK, 600))
		for row_data in section[1]:
			var row := HBoxContainer.new()
			var name := label(row_data[0], 14, INK)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name)
			if row_data[1] == "spin":
				var limit := SpinBox.new()
				limit.min_value = 0
				limit.max_value = 9999
				limit.value = Flashcards.new_limit
				limit.custom_minimum_size.x = 120
				limit.value_changed.connect(func(value: float) -> void:
					Flashcards.new_limit = int(value)
					Flashcards.changed.emit()
					SaveGame.autosave())
				row.add_child(limit)
			else:
				var value := label(row_data[1], 14, MUTED)
				value.custom_minimum_size.x = 150
				value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(value)
			column.add_child(row)
	text("Schedules use real time, even while the game is closed. Only the new-card limit can be changed in this version.", 13, MUTED)
	bottom_row.add_child(button("Decks", show_decks))
	_bottom_spacer()
	bottom_row.add_child(button("Save", func() -> void:
		show_decks()
		show_toast("Options saved."), true))

func _process(delta: float) -> void:
	refresh_elapsed += delta
	if refresh_elapsed >= 10.0:
		refresh_elapsed = 0.0
		if page == "complete":
			study_next()

class UIHelpers:
	static func gap(width: float) -> Control:
		var spacer := Control.new()
		spacer.custom_minimum_size.x = width
		return spacer

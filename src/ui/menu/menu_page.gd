extends ScrollContainer
## Base for player-menu pages: a vertical content column that scrolls when
## needed. Pages rebuild their content in refresh() from live game state.
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
## Width available to page content inside the menu panel.
const WIDTH := 600.0
var content: VBoxContainer

func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(content)

func clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func refresh() -> void:
	pass

## Plain text of everything on the page, in reading order (for tests and
## accessibility tooling).
func summary_text() -> String:
	var parts: Array = []
	_collect(content, parts)
	return "\n".join(parts)

func _collect(node: Node, parts: Array) -> void:
	if node is Label and node.visible and not node.text.is_empty():
		parts.append(node.text)
	if node is Button and node.visible and not node.text.is_empty():
		parts.append(node.text)
	for child in node.get_children():
		_collect(child, parts)

## Card with an icon + title row, returning the card's body column.
func section(title: String, icon := "", trailing: Control = null) -> VBoxContainer:
	var card := UI.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	if not title.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		if not icon.is_empty():
			row.add_child(Icon.new(icon, 15, UI.ACCENT))
		var heading := UI.label(title, UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(heading)
		if trailing:
			row.add_child(trailing)
		column.add_child(row)
	return column

## Centered empty-state message with an icon.
func empty_state(icon: String, title: String, detail: String) -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size.y = 260
	var badge := CenterContainer.new()
	badge.add_child(Icon.new(icon, 34, UI.TEXT_FAINT))
	box.add_child(badge)
	var heading := UI.label(title, UI.SIZE_TITLE, UI.TEXT, 600)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var text := UI.paragraph(detail, 380, UI.SIZE_BODY, UI.TEXT_MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var holder := CenterContainer.new()
	holder.add_child(text)
	box.add_child(holder)
	content.add_child(box)

## A thin horizontal progress bar.
static func bar(fraction: float, color: Color, width := 120.0, height := 6.0) -> Control:
	var control := Control.new()
	control.custom_minimum_size = Vector2(width, height)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.draw.connect(func() -> void:
		var radius := height / 2.0
		var track := UI.box(Color(1, 1, 1, 0.08), int(radius))
		track.draw(control.get_canvas_item(), Rect2(Vector2.ZERO, control.size))
		if fraction > 0.0:
			var fill := UI.box(color, int(radius))
			fill.draw(control.get_canvas_item(), Rect2(Vector2.ZERO, Vector2(maxf(control.size.x * clampf(fraction, 0.0, 1.0), height), control.size.y))))
	return control

## Event helpers shared by the schedule, calendar and overview.
static func event_start(event: Dictionary) -> float:
	return Time.get_unix_time_from_datetime_string("%sT%02d:%02d:00" % [event.date, int(event.hour), int(event.minute)])

static func clock_text(hour: int, minute: int) -> String:
	var h := hour % 12
	return "%d:%02d %s" % [12 if h == 0 else h, minute, "AM" if hour < 12 else "PM"]

## Status of an event for the student: [label, colour].
static func event_status(event: Dictionary) -> Array:
	var lecture: Dictionary = AcademicSession.lectures_completed.get(event.id, {})
	if not lecture.is_empty():
		return ["Completed", UI.SUCCESS]
	var record: Dictionary = AcademicSession.attendance.get(event.date + ":" + event.id, {})
	if not record.is_empty():
		return ["Late · %d XP" % record.xp_delta, UI.DANGER] if record.late else ["Arrived on time", UI.SUCCESS]
	var now := GameClock.now_seconds()
	var start := event_start(event)
	if now < start:
		return ["Upcoming", UI.INFO]
	if Time.get_date_string_from_unix_time(int(now)) == event.date:
		return ["In progress", UI.REWARD]
	return ["Missed", UI.TEXT_FAINT]

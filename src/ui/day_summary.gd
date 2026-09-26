extends CanvasLayer
## The end-of-day screen, shown over the fade to black after sleeping: what
## the day brought (XP, questions, flashcards, money, achievements, events
## attended or missed), then the days skipped until the next story day and
## the stipend if one was paid. Continue wakes the student up.
signal continued
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Items = preload("res://data/items.gd")
var summary: Dictionary
var continue_button: Button

func _init(day_summary: Dictionary) -> void:
	summary = day_summary

func _ready() -> void:
	layer = 110
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.theme()
	add_child(root)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.043, 0.086, 0.11, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 620
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	column.add_child(UI.label("END OF DAY · " + String(summary.get("heading", "")).to_upper(), UI.SIZE_CAPTION, UI.ACCENT, 600, true))
	column.add_child(UI.label(String(summary.get("title", "")), UI.SIZE_HEADING, UI.TEXT, 600))
	# Stat tiles.
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	column.add_child(tiles)
	tiles.add_child(_tile("spark", "XP earned", "%+d" % int(summary.get("xp", 0)), UI.REWARD))
	var attempted := int(summary.get("attempted", 0))
	tiles.add_child(_tile("check", "Questions", ("%d / %d" % [int(summary.get("correct", 0)), attempted]) if attempted > 0 else "—", UI.SUCCESS))
	tiles.add_child(_tile("notes", "Flashcards", str(int(summary.get("cards", 0))), UI.INFO))
	var net := int(summary.get("earned", 0)) - int(summary.get("spent", 0))
	tiles.add_child(_tile("coin", "Money", ("+" if net >= 0 else "") + Items.format_money(net), UI.SUCCESS if net >= 0 else UI.TEXT_MUTED))
	# Events.
	var events: Array = summary.get("events", [])
	if not events.is_empty():
		var card := UI.card(Vector4(16, 12, 16, 12))
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 6)
		card.add_child(list)
		for entry in events:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var done: bool = entry.attended
			row.add_child(Icon.new("check" if done else ("lock" if entry.mandatory else "clock"), 14, UI.SUCCESS if done else (UI.DANGER if entry.mandatory else UI.TEXT_FAINT)))
			var name := UI.label(String(entry.title).capitalize(), UI.SIZE_LABEL, UI.TEXT if done else UI.TEXT_MUTED, 500)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name)
			row.add_child(UI.label("Attended" if done else ("Absent" if entry.mandatory else "Skipped"), UI.SIZE_CAPTION, UI.SUCCESS if done else (UI.DANGER if entry.mandatory else UI.TEXT_FAINT), 600))
			list.add_child(row)
		column.add_child(card)
	if int(summary.get("achievements", 0)) > 0:
		column.add_child(UI.label("%d achievement%s unlocked today" % [int(summary.achievements), "" if int(summary.achievements) == 1 else "s"], UI.SIZE_LABEL, UI.REWARD, 600))
	# What comes next.
	var following: Dictionary = summary.get("next", {})
	if following.is_empty():
		var text := "That's everything built so far. Your first year continues in a later update."
		if summary.get("summer", false):
			text = "Summer break. The first year is done: no classes until second year, but the clubs, the gym and the library carry on, and the campus is yours."
		column.add_child(UI.paragraph(text, 620, UI.SIZE_BODY, UI.TEXT_MUTED))
		if bool(summary.get("well_rested", false)):
			column.add_child(UI.label("You slept well: Well Rested (+5% XP until midday).", UI.SIZE_LABEL, UI.SUCCESS, 500))
	else:
		column.add_child(UI.hairline())
		if not String(following.get("between", "")).is_empty():
			column.add_child(UI.paragraph(String(following.between), 620, UI.SIZE_BODY, UI.TEXT_MUTED))
		if bool(summary.get("well_rested", false)):
			column.add_child(UI.label("You slept well: Well Rested (+5% XP until midday).", UI.SIZE_LABEL, UI.SUCCESS, 500))
		if int(summary.get("stipend", 0)) > 0:
			column.add_child(UI.label("Financial aid deposited: %s" % Items.format_money(int(summary.stipend)), UI.SIZE_LABEL, UI.SUCCESS, 500))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	continue_button = Button.new()
	continue_button.text = "Wake up" if not following.is_empty() or summary.get("summer", false) else "Continue"
	continue_button.theme_type_variation = "PrimaryButton"
	continue_button.custom_minimum_size = Vector2(140, 40)
	continue_button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		continued.emit())
	buttons.add_child(continue_button)
	continue_button.grab_focus.call_deferred()

func _tile(icon: String, caption: String, value: String, color: Color) -> Control:
	var card := UI.card(Vector4(14, 12, 14, 12))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.add_child(Icon.new(icon, 14, color))
	top.add_child(UI.label(caption, UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
	column.add_child(top)
	column.add_child(UI.label(value, UI.SIZE_TITLE, UI.TEXT, 600))
	return card

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		continued.emit()

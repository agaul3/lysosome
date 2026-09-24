extends "res://ui/menu/menu_page.gd"
## Overview: greeting and objective, then progress, the next class and
## knowledge at a glance, and the save status.
const Objectives = preload("res://data/objectives.gd")
const Knowledge = preload("res://education/knowledge/knowledge.gd")
const Presets = preload("res://data/character_presets.gd")
signal open_page(index: int)
var save_status: Label

func _ready() -> void:
	SaveGame.saved.connect(func(_summary: Dictionary) -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func refresh() -> void:
	clear()
	var now := GameClock.snapshot()
	# Greeting with the current objective.
	var hero := UI.card(Vector4(20, 18, 20, 18), Color(UI.ACCENT_DEEP, 0.22))
	var hero_style: StyleBoxFlat = hero.get_theme_stylebox("panel").duplicate()
	hero_style.border_color = Color(UI.ACCENT, 0.35)
	hero.add_theme_stylebox_override("panel", hero_style)
	content.add_child(hero)
	var hero_column := VBoxContainer.new()
	hero_column.add_theme_constant_override("separation", 6)
	hero.add_child(hero_column)
	var greeting := "Good morning" if now.hour < 12 else ("Good afternoon" if now.hour < 18 else "Good evening")
	hero_column.add_child(UI.label("%s, %s" % [greeting, Presets.get_preset(AppState.selected_character).name], UI.SIZE_HEADING - 2, UI.TEXT, 600))
	hero_column.add_child(UI.label("%s · %s · %s, Week %d" % [GameClock.display_date(), GameClock.display_time(), now.semester, now.academic_week], UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	var objective := HBoxContainer.new()
	objective.add_theme_constant_override("separation", 8)
	objective.add_child(Icon.new("target", 16, UI.ACCENT))
	objective.add_child(UI.label(Objectives.current(AppState.location_key()), UI.SIZE_BODY, UI.TEXT, 500))
	hero_column.add_child(UI.spacer(4))
	hero_column.add_child(objective)
	# Three summary cards.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	row.add_child(_progress_card())
	row.add_child(_next_card())
	row.add_child(_knowledge_card())
	# Save status.
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 8)
	save_row.add_child(Icon.new("save", 15, UI.TEXT_MUTED))
	save_status = UI.label(_save_text(), UI.SIZE_LABEL, UI.TEXT_MUTED, 500)
	save_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(save_status)
	var save_button := Button.new()
	save_button.text = "Save now"
	save_button.pressed.connect(func() -> void:
		Sfx.play("ui_confirm")
		save_status.text = ("Saved just now · " + GameClock.display_time()) if SaveGame.save() else SaveGame.last_error)
	save_row.add_child(save_button)
	content.add_child(save_row)

func _small_card(title: String, icon: String) -> VBoxContainer:
	var card := UI.card(Vector4(16, 14, 16, 14))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 172
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	heading.add_child(Icon.new(icon, 14, UI.ACCENT))
	heading.add_child(UI.label(title, UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	column.add_child(heading)
	column.set_meta("card", card)
	return column

func _progress_card() -> Control:
	var column := _small_card("Progress", "spark")
	var progress: Dictionary = AcademicSession.level_progress()
	var ring := Control.new()
	ring.custom_minimum_size = Vector2(0, 72)
	ring.draw.connect(func() -> void:
		var center := Vector2(34, 36)
		ring.draw_arc(center, 30, 0, TAU, 48, Color(1, 1, 1, 0.08), 6, true)
		if progress.fraction > 0.0:
			ring.draw_arc(center, 30, -PI / 2, -PI / 2 + TAU * progress.fraction, 48, UI.REWARD, 6, true)
		var font := UI.font(700)
		var text := str(progress.level)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		ring.draw_string(font, center + Vector2(-width / 2.0, 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UI.TEXT)
		ring.draw_string(UI.font(600), Vector2(78, 30), "Level %d" % progress.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.REWARD)
		ring.draw_string(UI.font(500), Vector2(78, 50), "%d / %d XP" % [progress.into, progress.needed], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.TEXT_MUTED))
	column.add_child(ring)
	var streak := HBoxContainer.new()
	streak.add_theme_constant_override("separation", 6)
	streak.add_child(Icon.new("flame", 14, UI.REWARD if AcademicSession.streak >= 3 else UI.TEXT_FAINT))
	streak.add_child(UI.label("Streak %d · Best %d" % [AcademicSession.streak, AcademicSession.best_streak], UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	column.add_child(streak)
	column.add_child(UI.label("%d XP total" % maxi(AcademicSession.xp_balance, 0), UI.SIZE_CAPTION, UI.TEXT_FAINT, 500))
	return column.get_meta("card")

func _next_card() -> Control:
	var column := _small_card("Up next", "clock")
	var upcoming: Dictionary = {}
	for event in GameClock.config.events:
		if not AcademicSession.lectures_completed.has(event.id):
			upcoming = event
			break
	if upcoming.is_empty():
		column.add_child(UI.label("All caught up", UI.SIZE_TITLE, UI.TEXT, 600))
		column.add_child(UI.paragraph("No more classes today. Explore campus or review your notes.", 160, UI.SIZE_LABEL))
		return column.get_meta("card")
	column.add_child(UI.label(String(upcoming.title).capitalize(), UI.SIZE_TITLE, UI.TEXT, 600))
	column.add_child(UI.label("%s · %s" % [clock_text(int(upcoming.hour), int(upcoming.minute)), upcoming.location], UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	var minutes := int(ceil((event_start(upcoming) - GameClock.now_seconds()) / 60.0))
	if minutes > 0:
		column.add_child(UI.label("Starts in %d min" % minutes, UI.SIZE_BODY, UI.INFO, 600))
	var status := event_status(upcoming)
	column.add_child(UI.chip(status[0], status[1]))
	return column.get_meta("card")

func _knowledge_card() -> Control:
	var column := _small_card("Knowledge", "knowledge")
	var counts: Dictionary = AcademicSession.topic_statistics.get("Pharmacology/Pharmacodynamics", {"attempted": 0, "correct": 0})
	var attempted := int(counts.attempted)
	var accuracy := Knowledge.accuracy(int(counts.correct), attempted)
	column.add_child(UI.label("Pharmacodynamics", UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	column.add_child(UI.label("—" if attempted == 0 else "%d%%" % int(round(accuracy * 100.0)), 30, UI.TEXT, 600))
	column.add_child(bar(accuracy, UI.SUCCESS, 150))
	column.add_child(UI.label("Not yet attempted" if attempted == 0 else "%d of %d correct" % [counts.correct, attempted], UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
	var details := Button.new()
	details.theme_type_variation = "GhostButton"
	details.text = "View details"
	details.alignment = HORIZONTAL_ALIGNMENT_LEFT
	details.pressed.connect(func() -> void: open_page.emit(4))
	column.add_child(details)
	return column.get_meta("card")

func _save_text() -> String:
	var saved := SaveGame.summary()
	if saved.is_empty():
		return "Progress autosaves when you arrive somewhere new and when class ends."
	return "Autosave on · Last saved at %s, %s" % [saved.time, saved.location]

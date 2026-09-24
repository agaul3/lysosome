extends "res://ui/menu/menu_page.gd"
## Achievements (placeholder per spec): a preview of milestone badges,
## derived directly from existing progress — no separate achievement system.

func _ready() -> void:
	refresh()

func _badges() -> Array:
	var lecture: Dictionary = AcademicSession.lectures_completed.get("pharmacodynamics_01", {})
	var arrival: Dictionary = {}
	for record in AcademicSession.attendance.values():
		arrival = record
	return [
		["Punctual", "Arrive on time for your first lecture.", "clock", not arrival.is_empty() and not arrival.late],
		["First Correct Answer", "Answer a lecture question correctly.", "check", AcademicSession.correct > 0],
		["Pharmacodynamics I", "Complete the Pharmacodynamics lecture.", "book", not lecture.is_empty()],
		["Sharp Mind", "Score 80% or more in a lecture.", "target", not lecture.is_empty() and float(lecture.accuracy) >= 0.8],
		["In the Zone", "Answer 10 questions in a row correctly.", "flame", AcademicSession.best_streak >= 10],
		["Level Up", "Reach Level 2.", "spark", AcademicSession.level >= 2],
	]

func refresh() -> void:
	clear()
	var badges := _badges()
	var unlocked := badges.filter(func(badge): return badge[3]).size()
	var head := HBoxContainer.new()
	var count := UI.label("%d of %d unlocked" % [unlocked, badges.size()], UI.SIZE_BODY, UI.TEXT, 600)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(count)
	head.add_child(UI.chip("Preview", UI.TEXT_MUTED))
	content.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for badge in badges:
		grid.add_child(_badge(badge[0], badge[1], badge[2], badge[3]))
	content.add_child(UI.label("More achievements arrive with later chapters of the year.", UI.SIZE_LABEL, UI.TEXT_FAINT, 400))

func _badge(title: String, detail: String, icon: String, unlocked: bool) -> Control:
	var card := UI.card(Vector4(14, 12, 14, 12), UI.SURFACE_RAISED if unlocked else Color(UI.SURFACE_RAISED, 0.5))
	card.custom_minimum_size = Vector2(294, 72)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var medal := PanelContainer.new()
	medal.add_theme_stylebox_override("panel", UI.box(Color(UI.REWARD, 0.14) if unlocked else Color(1, 1, 1, 0.04), 20, Color(UI.REWARD, 0.6) if unlocked else UI.LINE, 1, Vector4(0, 0, 0, 0)))
	medal.custom_minimum_size = Vector2(44, 44)
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := Icon.new(icon if unlocked else "lock", 20, UI.REWARD if unlocked else UI.TEXT_FAINT)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medal.add_child(glyph)
	row.add_child(medal)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 1)
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_child(UI.label(title, UI.SIZE_BODY, UI.TEXT if unlocked else UI.TEXT_MUTED, 600))
	text.add_child(UI.paragraph(detail, 200, UI.SIZE_CAPTION, UI.TEXT_MUTED if unlocked else UI.TEXT_FAINT))
	row.add_child(text)
	return card

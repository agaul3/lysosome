extends "res://ui/menu/menu_page.gd"
## Achievements: the whole catalogue (data/achievements.gd) by category, with
## progress toward stat goals and each reward. Hidden achievements keep
## their description until unlocked.
const Catalogue = preload("res://data/achievements.gd")

func _ready() -> void:
	Achievements.unlocked.connect(func(_id: String, _achievement: Dictionary) -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func refresh() -> void:
	clear()
	var total := Catalogue.ACHIEVEMENTS.size()
	var head := HBoxContainer.new()
	var count := UI.label("%d of %d unlocked" % [Achievements.unlocked_count(), total], UI.SIZE_BODY, UI.TEXT, 600)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(count)
	head.add_child(UI.chip("Rewards: money · skill points · clothing", UI.REWARD))
	content.add_child(head)
	for category in Catalogue.CATEGORIES:
		var ids: Array = Catalogue.ACHIEVEMENTS.keys().filter(func(id: String) -> bool: return Catalogue.ACHIEVEMENTS[id].category == category[0])
		if ids.is_empty():
			continue
		var done := ids.filter(func(id: String) -> bool: return Achievements.is_unlocked(id)).size()
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", 8)
		heading.add_child(Icon.new(category[2], 15, UI.ACCENT))
		var title := UI.label(String(category[1]).to_upper(), UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		heading.add_child(UI.label("%d / %d" % [done, ids.size()], UI.SIZE_CAPTION, UI.TEXT_FAINT, 600))
		content.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)
		for id in ids:
			grid.add_child(_badge(id))

func _badge(id: String) -> Control:
	var achievement: Dictionary = Catalogue.ACHIEVEMENTS[id]
	var unlocked := Achievements.is_unlocked(id)
	var card := UI.card(Vector4(14, 12, 14, 12), UI.SURFACE_RAISED if unlocked else Color(UI.SURFACE_RAISED, 0.5))
	card.custom_minimum_size = Vector2(294, 86)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var medal := PanelContainer.new()
	medal.add_theme_stylebox_override("panel", UI.box(Color(UI.REWARD, 0.14) if unlocked else Color(1, 1, 1, 0.04), 20, Color(UI.REWARD, 0.6) if unlocked else UI.LINE, 1, Vector4(0, 0, 0, 0)))
	medal.custom_minimum_size = Vector2(44, 44)
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := Icon.new(String(achievement.icon) if unlocked else "lock", 20, UI.REWARD if unlocked else UI.TEXT_FAINT)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medal.add_child(glyph)
	row.add_child(medal)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UI.label(String(achievement.title), UI.SIZE_BODY, UI.TEXT if unlocked else UI.TEXT_MUTED, 600))
	var hidden: bool = achievement.get("hidden", false) and not unlocked
	text.add_child(UI.paragraph("A secret, for now." if hidden else String(achievement.description), 200, UI.SIZE_CAPTION, UI.TEXT_MUTED if unlocked else UI.TEXT_FAINT))
	var progress: Array = Achievements.progress(id)
	if not unlocked and int(progress[1]) > 1:
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(200, 4)
		var fraction := float(progress[0]) / float(progress[1])
		bar.draw.connect(func() -> void:
			bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(1, 1, 1, 0.08))
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * fraction, bar.size.y)), UI.ACCENT))
		text.add_child(bar)
		text.add_child(UI.label("%d / %d" % [progress[0], progress[1]], 10, UI.TEXT_FAINT, 600))
	var reward := Achievements.reward_text(id)
	if not reward.is_empty():
		text.add_child(UI.label(reward, 10, UI.REWARD if unlocked else UI.TEXT_FAINT, 600))
	return card

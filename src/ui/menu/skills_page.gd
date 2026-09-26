extends "res://ui/menu/menu_page.gd"
## Skills: the four branches of the skill tree side by side, each perk with
## its ranks, what it does and what it needs. Train a rank with a point.
const SkillTree = preload("res://data/skill_tree.gd")
var points_label: Label

func _ready() -> void:
	Skills.changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())
	AcademicSession.level_up.connect(func(_from: int, _to: int) -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func refresh() -> void:
	clear()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var rank := UI.label("%s · Level %d" % [Skills.title(), AcademicSession.level], UI.SIZE_BODY, UI.TEXT, 600)
	rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(rank)
	var available := Skills.points_available()
	points_label = UI.label("%d skill point%s available" % [available, "" if available == 1 else "s"], UI.SIZE_LABEL, UI.ACCENT if available > 0 else UI.TEXT_MUTED, 600)
	head.add_child(points_label)
	content.add_child(head)
	content.add_child(UI.paragraph("A point for every level, and a few from achievements. Perks make the year go better; none of them does the learning for you.", WIDTH, UI.SIZE_CAPTION, UI.TEXT_FAINT))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	content.add_child(columns)
	for branch in SkillTree.BRANCHES:
		columns.add_child(_branch(branch))

func _branch(branch: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	heading.add_child(Icon.new(String(branch.icon), 15, branch.color))
	heading.add_child(UI.label(String(branch.name).to_upper(), UI.SIZE_CAPTION, branch.color, 600, true))
	column.add_child(heading)
	column.add_child(UI.paragraph(String(branch.tagline), 140, 11, UI.TEXT_FAINT))
	for id in SkillTree.branch_perks(String(branch.id)):
		column.add_child(_perk(id, branch.color))
	return column

func _perk(id: String, color: Color) -> Control:
	var perk: Dictionary = SkillTree.PERKS[id]
	var owned := Skills.rank(id)
	var maxed := owned >= int(perk.ranks)
	var reason := Skills.block_reason(id)
	var card := UI.card(Vector4(10, 9, 10, 10), UI.SURFACE_RAISED if owned > 0 else Color(UI.SURFACE_RAISED, 0.55))
	var card_style: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
	if owned > 0:
		card_style.border_color = Color(color, 0.55)
		card_style.border_width_left = 2
	card.add_theme_stylebox_override("panel", card_style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	var name := UI.label(String(perk.name), UI.SIZE_LABEL, UI.TEXT if owned > 0 or reason.is_empty() else UI.TEXT_MUTED, 600)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.x = 80
	top.add_child(name)
	stack.add_child(top)
	# Rank pips.
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 3)
	for index in range(int(perk.ranks)):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 4)
		pip.color = color if index < owned else Color(1, 1, 1, 0.12)
		pips.add_child(pip)
	stack.add_child(pips)
	stack.add_child(UI.paragraph(String(perk.description), 120, 11, UI.TEXT_MUTED))
	if maxed:
		stack.add_child(UI.label("Fully trained", 10, color, 600))
	elif reason.is_empty():
		var train := Button.new()
		train.name = "Train_" + id
		train.text = "Train" if owned == 0 else "Rank %d" % (owned + 1)
		train.theme_type_variation = "PrimaryButton"
		train.add_theme_font_size_override("font_size", 12)
		train.pressed.connect(func() -> void:
			if Skills.buy(id):
				Sfx.play("achievement")
				refresh())
		stack.add_child(train)
	else:
		stack.add_child(UI.label(reason, 10, UI.TEXT_FAINT, 600))
	return card

extends "res://ui/menu/menu_page.gd"
## Wallet & Wellbeing: the balance and where it came from and went, energy,
## active boosts, snacks carried in the backpack (use them here) and recent
## transactions.
const Items = preload("res://data/items.gd")

func _ready() -> void:
	Wallet.changed.connect(func(_b: int, _d: int, _l: String) -> void:
		if is_visible_in_tree():
			refresh())
	Wellbeing.changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())
	refresh()

func refresh() -> void:
	clear()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	# Balance.
	var money := UI.card(Vector4(18, 14, 18, 14))
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var money_column := VBoxContainer.new()
	money_column.add_theme_constant_override("separation", 4)
	money.add_child(money_column)
	var money_top := HBoxContainer.new()
	money_top.add_theme_constant_override("separation", 8)
	money_top.add_child(Icon.new("coin", 16, UI.SUCCESS))
	money_top.add_child(UI.label("BALANCE", UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	money_column.add_child(money_top)
	money_column.add_child(UI.label(Wallet.formatted(), UI.SIZE_HEADING, UI.TEXT, 600))
	money_column.add_child(UI.label("Earned %s · Spent %s" % [Items.format_money(Wallet.earned_total), Items.format_money(Wallet.spent_total)], UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
	money_column.add_child(UI.label("Financial aid is deposited on the first class day of each month.", 11, UI.TEXT_FAINT, 400))
	row.add_child(money)
	# Energy and boosts.
	var energy := UI.card(Vector4(18, 14, 18, 14))
	energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var energy_column := VBoxContainer.new()
	energy_column.add_theme_constant_override("separation", 4)
	energy.add_child(energy_column)
	var energy_top := HBoxContainer.new()
	energy_top.add_theme_constant_override("separation", 8)
	energy_top.add_child(Icon.new("bolt", 16, UI.REWARD))
	energy_top.add_child(UI.label("ENERGY", UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	energy_column.add_child(energy_top)
	energy_column.add_child(UI.label("%d / %d · %s" % [int(round(Wellbeing.energy)), int(Wellbeing.max_energy()), Wellbeing.energy_state()], UI.SIZE_TITLE, UI.TEXT, 600))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 5)
	var fraction := Wellbeing.energy_fraction()
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(1, 1, 1, 0.1))
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * fraction, bar.size.y)), UI.REWARD if Wellbeing.energy >= 20.0 else UI.DANGER))
	energy_column.add_child(bar)
	var factor := Wellbeing.energy_factor()
	energy_column.add_child(UI.label("Learning XP %s" % ("at full strength" if factor >= 1.0 else "reduced to %d%% (tired)" % int(round(factor * 100))), 11, UI.TEXT_MUTED if factor >= 1.0 else UI.DANGER, 500))
	row.add_child(energy)
	# Boosts.
	content.add_child(_section("BOOSTS", "spark"))
	var boosts := Wellbeing.active_boosts()
	if boosts.is_empty():
		content.add_child(UI.paragraph("No boosts active. Coffee, a real meal or an early night each give a bonus to the XP you earn from learning.", WIDTH, UI.SIZE_LABEL, UI.TEXT_FAINT))
	else:
		for boost in boosts:
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 10)
			line.add_child(Icon.new(String(boost.icon), 15, UI.REWARD))
			var name := UI.label(String(boost.name), UI.SIZE_BODY, UI.TEXT, 600)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(name)
			line.add_child(UI.label("+%d%% XP" % int(round(float(boost.xp) * 100)), UI.SIZE_LABEL, UI.REWARD, 600))
			line.add_child(UI.label("%d min left" % int(boost.minutes_left), UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
			content.add_child(line)
		content.add_child(UI.label("Total: +%d%% XP from learning" % int(round(Wellbeing.boost_bonus() * 100)), UI.SIZE_CAPTION, UI.TEXT_MUTED, 600))
	# Backpack.
	content.add_child(_section("IN YOUR BACKPACK", "bag"))
	if Wallet.carried.is_empty():
		content.add_child(UI.paragraph("Nothing to eat. Snacks and drinks bought to go wait here.", WIDTH, UI.SIZE_LABEL, UI.TEXT_FAINT))
	for id in Wallet.carried:
		var item := Items.get_item(id)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		line.add_child(Icon.new(String(item.icon), 15, UI.TEXT_MUTED))
		var name := UI.label("%s × %d" % [item.name, int(Wallet.carried[id])], UI.SIZE_BODY, UI.TEXT, 500)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name)
		line.add_child(UI.label("+%d energy" % int(item.energy), UI.SIZE_CAPTION, UI.TEXT_MUTED, 500))
		var use := Button.new()
		use.name = "Use_" + id
		use.text = "Use"
		use.pressed.connect(func() -> void:
			if Wallet.use(id):
				Sfx.play("ui_confirm")
				refresh())
		line.add_child(use)
		content.add_child(line)
	# History.
	content.add_child(_section("RECENT", "notes"))
	if Wallet.history.is_empty():
		content.add_child(UI.paragraph("No transactions yet.", WIDTH, UI.SIZE_LABEL, UI.TEXT_FAINT))
	for entry in Wallet.history.slice(0, 10):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var label := UI.label(String(entry.label), UI.SIZE_LABEL, UI.TEXT, 500)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		var moment := Time.get_datetime_dict_from_unix_time(int(entry.at))
		line.add_child(UI.label("%s %d" % [["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][int(moment.month) - 1], int(moment.day)], UI.SIZE_CAPTION, UI.TEXT_FAINT, 500))
		var delta := int(entry.delta)
		line.add_child(UI.label(("+" if delta > 0 else "") + Items.format_money(delta), UI.SIZE_LABEL, UI.SUCCESS if delta > 0 else UI.TEXT_MUTED, 600))
		content.add_child(line)

func _section(title: String, icon: String) -> Control:
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	heading.add_child(Icon.new(icon, 14, UI.ACCENT))
	heading.add_child(UI.label(title, UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	return heading

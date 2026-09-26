extends "res://ui/modal_panel.gd"
## The Campus Store in the Student Center: clothing (owned once bought, so
## wearable whatever your level; wear it straight away) and study aids (small
## permanent bonuses that add to what correct answers earn).
const Items = preload("res://data/items.gd")
const Clothing = preload("res://data/clothing.gd")
var tab := "clothing"
var list: VBoxContainer
var balance: Label
var status: Label
var tabs: HBoxContainer

func _init() -> void:
	super(660.0)

func build() -> void:
	set_heading("Student Center", "Campus Store")
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(Icon.new("coin", 15, UI.SUCCESS))
	balance = UI.label("", UI.SIZE_BODY, UI.TEXT, 600)
	balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(balance)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	top.add_child(tabs)
	for entry in [["clothing", "Clothing"], ["aids", "Study aids"]]:
		var button := Button.new()
		button.name = "Tab_" + String(entry[0])
		button.text = String(entry[1])
		button.pressed.connect(func() -> void:
			tab = String(entry[0])
			refresh())
		tabs.add_child(button)
	body.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width - 52, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	status = UI.label("", UI.SIZE_LABEL, UI.SUCCESS, 500)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = width - 52
	body.add_child(status)
	add_button("Done", close, true)
	refresh()

func refresh() -> void:
	balance.text = Wallet.formatted()
	for button in tabs.get_children():
		(button as Button).theme_type_variation = "PrimaryButton" if button.name == "Tab_" + tab else "GhostButton"
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if tab == "clothing":
		for entry in Items.STORE_CLOTHING:
			list.add_child(_clothing_row(String(entry[0]), int(entry[1])))
	else:
		for id in Items.AIDS:
			list.add_child(_aid_row(String(id)))

func _row(icon: String, title: String, note: String, note_color: Color, price: int, owned: bool) -> Array:
	var card := UI.card(Vector4(12, 8, 12, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(Icon.new(icon, 18, UI.TEXT_MUTED))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UI.label(title, UI.SIZE_BODY, UI.TEXT, 600))
	var note_label := UI.paragraph(note, width - 300, UI.SIZE_CAPTION, note_color)
	text.add_child(note_label)
	var cost := Wallet.price(price)
	row.add_child(UI.label("Owned" if owned else Items.format_money(cost), UI.SIZE_BODY, UI.SUCCESS if owned else (UI.TEXT if Wallet.balance >= cost else UI.DANGER), 600))
	return [card, row]

func _clothing_row(id: String, price: int) -> Control:
	var item := Clothing.item(id)
	var owned := Wallet.owns_clothing(id)
	var parts := _row("bag", String(item.name), "%s · %s · %s" % [Clothing.RARITY_NAMES[item.rarity], Clothing.SLOT_NAMES[item.slot], item.description], Clothing.RARITY_COLORS[item.rarity], price, owned)
	var row: HBoxContainer = parts[1]
	if owned:
		var wear := Button.new()
		wear.name = "Wear_" + id
		var worn := String(AppState.player_look.get("outfit", {}).get(item.slot, "")) == id
		wear.text = "Wearing" if worn else "Wear"
		wear.disabled = worn
		wear.theme_type_variation = "GhostButton"
		wear.pressed.connect(func() -> void:
			if AppState.equip(String(item.slot), id):
				status.add_theme_color_override("font_color", UI.SUCCESS)
				status.text = "You're wearing the %s." % item.name
			refresh())
		row.add_child(wear)
	else:
		var buy := Button.new()
		buy.name = "Buy_" + id
		buy.text = "Buy"
		buy.disabled = Wallet.balance < Wallet.price(price)
		buy.pressed.connect(_buy_clothing.bind(id))
		row.add_child(buy)
	return parts[0]

func _aid_row(id: String) -> Control:
	var aid := Items.get_aid(id)
	var owned: bool = id in Wallet.owned_aids
	var parts := _row(String(aid.icon), String(aid.name), String(aid.description), UI.REWARD, int(aid.price), owned)
	if not owned:
		var buy := Button.new()
		buy.name = "Buy_" + id
		buy.text = "Buy"
		buy.disabled = Wallet.balance < Wallet.price(int(aid.price))
		buy.pressed.connect(_buy_aid.bind(id))
		parts[1].add_child(buy)
	return parts[0]

func _buy_clothing(id: String) -> void:
	var item_name := Clothing.item_name(id)
	if Wallet.buy_clothing(id):
		Sfx.play("ui_confirm")
		status.add_theme_color_override("font_color", UI.SUCCESS)
		status.text = "Bought the %s. It's in your wardrobe now." % item_name
	else:
		status.add_theme_color_override("font_color", UI.DANGER)
		status.text = "Not enough money for the %s." % item_name
	refresh()

func _buy_aid(id: String) -> void:
	var aid := Items.get_aid(id)
	if Wallet.buy_aid(id):
		Sfx.play("ui_confirm")
		status.add_theme_color_override("font_color", UI.SUCCESS)
		status.text = "Bought: %s. %s" % [aid.name, aid.description]
	else:
		status.add_theme_color_override("font_color", UI.DANGER)
		status.text = "Not enough money for %s." % aid.name
	refresh()

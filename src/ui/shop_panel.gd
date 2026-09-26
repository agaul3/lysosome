extends "res://ui/modal_panel.gd"
## A vendor's menu: what they sell, the price (after any Frugal discount),
## the energy it gives and its boost. Eat or drink here, or buy snacks to go
## for the backpack. Shows the balance and what happened after each purchase.
const Items = preload("res://data/items.gd")
var vendor := ""
var list: VBoxContainer
var status: Label
var balance: Label

func _init(vendor_id: String) -> void:
	super(560.0)
	vendor = vendor_id

func build() -> void:
	var info: Dictionary = Items.VENDORS.get(vendor, {"name": "Shop", "items": []})
	set_heading("Order", String(info.name))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(Icon.new("coin", 15, UI.SUCCESS))
	balance = UI.label("", UI.SIZE_BODY, UI.TEXT, 600)
	balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(balance)
	top.add_child(Icon.new("bolt", 15, UI.REWARD))
	top.add_child(UI.label("", UI.SIZE_LABEL, UI.TEXT_MUTED, 500))
	body.add_child(top)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	body.add_child(list)
	status = UI.label("", UI.SIZE_LABEL, UI.SUCCESS, 500)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = width - 52
	body.add_child(status)
	add_button("Done", close, true)
	refresh()

func refresh() -> void:
	balance.text = Wallet.formatted()
	(balance.get_parent().get_child(3) as Label).text = "%d · %s" % [int(round(Wellbeing.energy)), Wellbeing.energy_state()]
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var info: Dictionary = Items.VENDORS.get(vendor, {"items": []})
	for id in info.items:
		list.add_child(_row(String(id)))

func _row(id: String) -> Control:
	var item := Items.get_item(id)
	var card := UI.card(Vector4(12, 8, 12, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(Icon.new(String(item.icon), 18, UI.TEXT_MUTED))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UI.label(String(item.name), UI.SIZE_BODY, UI.TEXT, 600))
	var effects := "+%d energy" % int(item.energy)
	if not item.boost.is_empty():
		effects += " · %s +%d%% XP, %d min" % [item.boost.name, int(round(float(item.boost.xp) * 100)), int(item.boost.minutes)]
	text.add_child(UI.label(effects, UI.SIZE_CAPTION, UI.REWARD if not item.boost.is_empty() else UI.TEXT_MUTED, 500))
	var price := Wallet.price(int(item.price))
	var price_label := UI.label(Items.format_money(price), UI.SIZE_BODY, UI.TEXT if Wallet.balance >= price else UI.DANGER, 600)
	row.add_child(price_label)
	var buy := Button.new()
	buy.name = "Buy_" + id
	buy.text = "Buy"
	buy.disabled = Wallet.balance < price
	buy.pressed.connect(_buy.bind(id, false))
	row.add_child(buy)
	if item.get("carry", false):
		var to_go := Button.new()
		to_go.name = "ToGo_" + id
		to_go.text = "To go"
		to_go.theme_type_variation = "GhostButton"
		to_go.disabled = Wallet.balance < price
		to_go.pressed.connect(_buy.bind(id, true))
		row.add_child(to_go)
	return card

func _buy(id: String, to_go: bool) -> void:
	var item := Items.get_item(id)
	if not Wallet.buy(id, to_go):
		status.add_theme_color_override("font_color", UI.DANGER)
		status.text = "Not enough money for the %s." % item.name
		return
	Sfx.play("ui_confirm")
	status.add_theme_color_override("font_color", UI.SUCCESS)
	if to_go:
		status.text = "%s packed in your backpack (use it from the Wallet page)." % item.name
	elif item.boost.is_empty():
		status.text = "%s. +%d energy." % [item.name, int(item.energy)]
	else:
		status.text = "%s. +%d energy · %s: +%d%% XP from learning for %d min." % [item.name, int(item.energy), item.boost.name, int(round(float(item.boost.xp) * 100)), int(item.boost.minutes)]
	refresh()

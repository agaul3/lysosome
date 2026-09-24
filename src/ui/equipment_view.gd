extends VBoxContainer
## Clothing equipment, laid out like an RPG character sheet: eight slots
## around the student (head, eyewear, outerwear and top down the left; neck,
## back, bottom and shoes down the right), an item card for whatever is
## selected, the items for the chosen slot below with rarity borders and lock
## badges, and outfit totals. Choosing an item wears it at once
## (AppState.equip); locked items say what unlocks them.
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Clothing = preload("res://data/clothing.gd")
const ItemIcon = preload("res://ui/item_icon.gd")
const CharacterPreview = preload("res://ui/character_preview.gd")
const SLOT_SIZE := 50.0
const CELL_SIZE := 50.0
var show_preview := true
var preview: SubViewportContainer
var slot_buttons := {}
var item_buttons: Array[Button] = []
var item_grid: GridContainer
var grid_title: Label
var selected_slot := "outerwear"
var shown_item := ""
var shown_slot := "outerwear"
var card_name: Label
var card_meta: Label
var card_text: Label
var card_stats: VBoxContainer
var card_lock: Label
var equip_button: Button
var stat_bars := {}

func _init(with_preview := true) -> void:
	show_preview = with_preview

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	add_child(top)
	var left := _slot_column(Clothing.SLOTS.slice(0, 4))
	top.add_child(left)
	if show_preview:
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UI.box(Color(UI.INK, 0.55), 10, UI.LINE_SOFT, 1, Vector4(0, 0, 0, 0)))
		preview = CharacterPreview.new(Vector2i(176, 240), "full", true)
		frame.add_child(preview)
		top.add_child(frame)
	top.add_child(_slot_column(Clothing.SLOTS.slice(4, 8)))
	top.add_child(_item_card())
	var grid_card := UI.card(Vector4(14, 12, 14, 12))
	add_child(grid_card)
	var grid_column := VBoxContainer.new()
	grid_column.add_theme_constant_override("separation", 8)
	grid_card.add_child(grid_column)
	grid_title = UI.label("", UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true)
	grid_column.add_child(grid_title)
	item_grid = GridContainer.new()
	item_grid.columns = 9
	item_grid.add_theme_constant_override("h_separation", 8)
	item_grid.add_theme_constant_override("v_separation", 8)
	grid_column.add_child(item_grid)
	add_child(_stats_card())
	AppState.look_changed.connect(func(_look: Dictionary) -> void: refresh())
	refresh()

func _slot_column(slots: Array) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	for slot in slots:
		var button := _tile(SLOT_SIZE)
		button.name = "Slot_" + slot
		button.tooltip_text = Clothing.SLOT_NAMES[slot]
		button.focus_entered.connect(select_slot.bind(slot))
		button.mouse_entered.connect(func() -> void: _show_item(String(AppState.player_look.outfit[slot]), slot))
		button.pressed.connect(func() -> void:
			select_slot(slot)
			if not item_buttons.is_empty():
				item_buttons[0].grab_focus())
		column.add_child(button)
		slot_buttons[slot] = button
	return column

func _tile(edge: float) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(edge, edge)
	button.focus_mode = Control.FOCUS_ALL
	button.theme_type_variation = "CardButton"
	var icon := ItemIcon.new(edge - 16.0)
	icon.name = "Icon"
	# Fill the tile with an 8 px inset (anchored to the full rect, so it stays
	# centred when the button is laid out).
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 8
	icon.offset_top = 8
	icon.offset_right = -8
	icon.offset_bottom = -8
	button.add_child(icon)
	return button

func _item_card() -> PanelContainer:
	var card := UI.card(Vector4(14, 12, 14, 12))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(170, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	card_meta = UI.label("", UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true)
	column.add_child(card_meta)
	card_name = UI.label("", UI.SIZE_TITLE - 2, UI.TEXT, 600)
	card_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(card_name)
	card_text = UI.label("", UI.SIZE_LABEL, UI.TEXT_MUTED, 400)
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size.x = 150
	column.add_child(card_text)
	card_stats = VBoxContainer.new()
	card_stats.add_theme_constant_override("separation", 3)
	column.add_child(card_stats)
	card_lock = UI.label("", UI.SIZE_LABEL, UI.REWARD, 600)
	card_lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(card_lock)
	column.add_child(UI.spacer(0, 0, true))
	equip_button = Button.new()
	equip_button.theme_type_variation = "PrimaryButton"
	equip_button.custom_minimum_size = Vector2(0, 34)
	equip_button.pressed.connect(_equip_shown)
	column.add_child(equip_button)
	return card

func _stats_card() -> PanelContainer:
	var card := UI.card(Vector4(14, 10, 14, 12))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Icon.new("spark", 14, UI.ACCENT))
	head.add_child(UI.label("Outfit", UI.SIZE_CAPTION, UI.TEXT_MUTED, 600, true))
	column.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	column.add_child(grid)
	for stat in [["style", "Style", UI.ACCENT], ["comfort", "Comfort", UI.INFO], ["warmth", "Warmth", UI.REWARD]]:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 3)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := UI.label("", UI.SIZE_LABEL, UI.TEXT, 500)
		cell.add_child(label)
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(150, 6)
		bar.set_meta("colour", stat[2])
		bar.set_meta("fraction", 0.0)
		bar.draw.connect(func() -> void:
			bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(1, 1, 1, 0.08))
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * float(bar.get_meta("fraction")), bar.size.y)), bar.get_meta("colour")))
		cell.add_child(bar)
		grid.add_child(cell)
		stat_bars[stat[0]] = [label, bar, stat[1]]
	return card

## Shows the chosen slot's items and the item worn there.
func select_slot(slot: String) -> void:
	selected_slot = slot
	_show_item(String(AppState.player_look.outfit[slot]), slot)
	_build_grid()
	for key in slot_buttons:
		slot_buttons[key].set_pressed_no_signal(key == slot)

func refresh() -> void:
	if not is_instance_valid(item_grid):
		return
	var outfit: Dictionary = AppState.player_look.outfit
	for slot in slot_buttons:
		var button: Button = slot_buttons[slot]
		var icon: Control = button.get_node("Icon")
		icon.slot = slot
		icon.item_id = String(outfit[slot])
		button.toggle_mode = true
		button.set_pressed_no_signal(slot == selected_slot)
		_rarity_border(button, String(outfit[slot]))
	if is_instance_valid(preview):
		preview.show_look(AppState.player_look)
	var totals := Clothing.outfit_stats(outfit)
	for stat in stat_bars:
		var entry: Array = stat_bars[stat]
		entry[0].text = "%s  %d" % [entry[2], totals[stat]]
		entry[1].set_meta("fraction", float(totals[stat]) / float(totals.max))
		entry[1].queue_redraw()
	_build_grid()
	# After any change the card shows what is now worn in the selected slot.
	_show_item(String(outfit[selected_slot]), selected_slot)

func _build_grid() -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var refocus := -1
	for index in range(item_buttons.size()):
		if item_buttons[index] == focused:
			refocus = index
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	item_buttons.clear()
	var ids: Array = Clothing.items_for(selected_slot)
	if not Clothing.REQUIRED.has(selected_slot):
		ids.push_front("")
	var worn := String(AppState.player_look.outfit[selected_slot])
	var available := ids.filter(func(id: String) -> bool: return id == "" or Clothing.unlocked(id)).size()
	grid_title.text = "%s · %d of %d available" % [Clothing.SLOT_NAMES[selected_slot], available, ids.size()]
	for id in ids:
		var button := _tile(CELL_SIZE)
		button.name = "Item_" + (id if id != "" else "none")
		var icon: Control = button.get_node("Icon")
		icon.slot = selected_slot
		icon.item_id = id
		var locked: bool = id != "" and not Clothing.unlocked(id)
		icon.dim = locked
		button.tooltip_text = "None" if id == "" else String(Clothing.ITEMS[id][0])
		_rarity_border(button, id, id == worn)
		if locked:
			var lock := Icon.new("lock", 13, UI.TEXT_MUTED)
			lock.position = Vector2(CELL_SIZE - 18, 4)
			button.add_child(lock)
		elif id == worn:
			var tick := Icon.new("check", 13, UI.ACCENT)
			tick.position = Vector2(CELL_SIZE - 18, 4)
			button.add_child(tick)
		button.focus_entered.connect(_show_item.bind(id, selected_slot))
		button.mouse_entered.connect(_show_item.bind(id, selected_slot))
		button.pressed.connect(_choose.bind(id, selected_slot))
		item_grid.add_child(button)
		item_buttons.append(button)
	if refocus >= 0 and refocus < item_buttons.size():
		item_buttons[refocus].grab_focus.call_deferred()

func _rarity_border(button: Button, id: String, worn := false) -> void:
	var color: Color = Clothing.RARITY_COLORS[Clothing.ITEMS[id][2]] if Clothing.exists(id) else UI.LINE
	for state in ["normal", "hover", "pressed", "focus"]:
		var fill := UI.SURFACE_HOVER if state in ["hover", "pressed"] else Color(UI.INK, 0.5)
		var style := UI.box(fill, 8, color if state != "focus" else UI.ACCENT, 2 if (worn or state in ["focus", "pressed"]) else 1, Vector4(0, 0, 0, 0))
		if state == "normal" and Clothing.exists(id):
			style.bg_color = Color(UI.INK, 0.5).blend(Color(color, 0.12))
		button.add_theme_stylebox_override(state, style)

## Fills the item card.
func _show_item(id: String, slot: String) -> void:
	shown_item = id
	shown_slot = slot
	var worn := String(AppState.player_look.outfit[slot]) == id
	for child in card_stats.get_children():
		card_stats.remove_child(child)
		child.queue_free()
	if id == "":
		card_meta.text = Clothing.SLOT_NAMES[slot]
		card_meta.add_theme_color_override("font_color", UI.TEXT_MUTED)
		card_name.text = "Nothing" if worn else "Take it off"
		card_text.text = "Leave the %s slot empty." % Clothing.SLOT_NAMES[slot].to_lower()
		card_lock.text = ""
		equip_button.text = "Wearing nothing here" if worn else "Remove"
		equip_button.disabled = worn
		return
	var item := Clothing.item(id)
	var requirement := Clothing.requirement(id)
	card_meta.text = "%s · %s" % [Clothing.RARITY_NAMES[item.rarity], Clothing.SLOT_NAMES[item.slot]]
	card_meta.add_theme_color_override("font_color", Clothing.RARITY_COLORS[item.rarity])
	card_name.text = item.name
	card_text.text = item.description
	for stat in [["Style", item.style], ["Comfort", item.comfort], ["Warmth", item.warmth]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var stat_label := UI.label(stat[0], UI.SIZE_CAPTION, UI.TEXT_MUTED, 500)
		stat_label.custom_minimum_size.x = 56
		row.add_child(stat_label)
		var pips := Control.new()
		pips.custom_minimum_size = Vector2(80, 8)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var amount: int = stat[1]
		pips.draw.connect(func() -> void:
			for pip in range(10):
				pips.draw_rect(Rect2(pip * 8, 0, 6, 8), UI.ACCENT if pip < amount else Color(1, 1, 1, 0.1)))
		row.add_child(pips)
		card_stats.add_child(row)
	card_lock.text = "" if requirement.met else "Locked · %s" % requirement.text
	equip_button.disabled = worn or not requirement.met
	equip_button.text = "Wearing" if worn else ("Locked" if not requirement.met else "Wear")

func _choose(id: String, slot := "") -> void:
	var target := slot if slot != "" else selected_slot
	if id != "" and not Clothing.unlocked(id):
		Sfx.play("ui_close")
		_show_item(id, target)
		return
	if AppState.equip(target, id):
		Sfx.play("ui_confirm")

func _equip_shown() -> void:
	_choose(shown_item, shown_slot)

func first_focus() -> Control:
	return slot_buttons.get(selected_slot)

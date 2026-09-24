extends "res://ui/menu/menu_page.gd"
## Inventory: the student's clothing, worn and owned, on an RPG-style
## equipment sheet (ui/equipment_view.gd). Picking a slot lists its items;
## picking an item wears it straight away. The closet in the dorm offers the
## same clothes plus a mirror for hair and face.
const EquipmentView = preload("res://ui/equipment_view.gd")
signal laptop_requested
var laptop_button: Button
var equipment: VBoxContainer

func _ready() -> void:
	laptop_button = Button.new()
	laptop_button.pressed.connect(func() -> void: laptop_requested.emit())
	content.add_child(laptop_button)
	equipment = EquipmentView.new(true)
	equipment.name = "Equipment"
	content.add_child(equipment)
	var hint := UI.label("New clothes unlock as you level up. Visit the closet in your room to restyle your hair and face.", UI.SIZE_LABEL, UI.TEXT_FAINT, 400)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	AppState.look_changed.connect(func(_look: Dictionary) -> void: _refresh_laptop())
	_refresh_laptop()

func refresh() -> void:
	_refresh_laptop()
	if is_instance_valid(equipment):
		equipment.refresh()

func _refresh_laptop() -> void:
	if not is_instance_valid(laptop_button):
		return
	laptop_button.text = "MacBook  ·  In backpack  ·  Open while seated" if Flashcards.has_laptop() else "MacBook  ·  Equip a backpack to carry your laptop"
	laptop_button.disabled = not Flashcards.has_laptop()

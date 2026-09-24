extends "res://ui/menu/menu_page.gd"
## Inventory (placeholder per spec): what the student is carrying, shown as a
## small slot grid. Items are representative; no inventory system exists yet.

func _ready() -> void:
	refresh()

func refresh() -> void:
	clear()
	var has_notes := int(AcademicSession.notes_progress.get("pharmacodynamics_01", 0)) > 0
	var items := [
		["Student ID badge", "Cedar Residence and Learning Center access.", "person", true],
		["Backpack", "Laptop, charger and a water bottle.", "inventory", true],
		["Pharmacology notes", "Your lecture notes. Read them under Lecture Notes.", "notes", has_notes],
		["Stethoscope", "Issued at clinical orientation.", "lock", false],
	]
	var head := HBoxContainer.new()
	var count := UI.label("%d items" % items.filter(func(item): return item[3]).size(), UI.SIZE_BODY, UI.TEXT, 600)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(count)
	head.add_child(UI.chip("Preview", UI.TEXT_MUTED))
	content.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for item in items:
		var card := UI.card(Vector4(14, 12, 14, 12), UI.SURFACE_RAISED if item[3] else Color(UI.SURFACE_RAISED, 0.45))
		card.custom_minimum_size = Vector2(294, 66)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", UI.box(Color(1, 1, 1, 0.04), 8, UI.LINE, 1, Vector4(0, 0, 0, 0)))
		slot.custom_minimum_size = Vector2(42, 42)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var glyph := Icon.new(item[2], 20, UI.TEXT if item[3] else UI.TEXT_FAINT)
		glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.add_child(glyph)
		row.add_child(slot)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 1)
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text.add_child(UI.label(item[0], UI.SIZE_BODY, UI.TEXT if item[3] else UI.TEXT_MUTED, 600))
		text.add_child(UI.paragraph(item[1] if item[3] else "Not yet issued · " + item[1], 210, UI.SIZE_CAPTION, UI.TEXT_MUTED if item[3] else UI.TEXT_FAINT))
		row.add_child(text)
		grid.add_child(card)
	content.add_child(UI.label("A full inventory arrives in a later version.", UI.SIZE_LABEL, UI.TEXT_FAINT, 400))

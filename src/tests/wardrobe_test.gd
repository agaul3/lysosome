extends "res://tests/campus_test.gd"
## Minecraft-style characters, the character creator, clothing, the closet
## and the equipment inventory:
## - the painted 64×64 skin (base layer opaque, overlay shell transparent
##   except hair and outerwear) carries the look's skin, eyes, hair and outfit;
## - the rig keeps its joint heights, slim builds narrow the arms, height
##   scales the figure but seating still meets the chair;
## - looks are sanitized and validated; rarity gates unlocks by level and the
##   first lecture; equip() refuses locked items and empty required slots;
## - the creator offers eight rendered presets and a full "create your own"
##   editor, and names follow presets until typed;
## - the dorm closet opens on interaction, pauses movement, dresses and
##   restyles the student live, and closes with Esc;
## - the inventory's equipment sheet lists, locks and equips items;
## - the look and name save, reload and resume exactly.
var Looks: GDScript
var Clothing: GDScript
var Appearance: GDScript
var Painter: GDScript
var Layout: GDScript
var academics: Node

func _run() -> void:
	Looks = load("res://data/looks.gd")
	Clothing = load("res://data/clothing.gd")
	Appearance = load("res://player/appearance.gd")
	Painter = load("res://character/skin_painter.gd")
	Layout = load("res://character/skin_layout.gd")
	state = root.get_node("AppState")
	academics = root.get_node("AcademicSession")
	skin_checks()
	rig_checks()
	look_checks()
	await creator_checks()
	await closet_checks()
	await inventory_checks()
	await save_checks()
	print("WARDROBE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func pixel(image: Image, part: String, face: String, col: int, row: int, slim := false) -> Color:
	var r: Rect2i = Layout.face(part, face, slim)
	return image.get_pixel(r.position.x + col, r.position.y + row)

func near(a: Color, b: Color, tolerance := 0.12) -> bool:
	return absf(a.r - b.r) < tolerance and absf(a.g - b.g) < tolerance and absf(a.b - b.b) < tolerance

func skin_checks() -> void:
	var look: Dictionary = Looks.default_look()
	look.skin = "8d5a44"
	look.eye_color = "3d6fc4"
	look.hair_color = "b5602f"
	look.hair_style = "short"
	look.outfit.top = "navy_tee"
	look.outfit.outerwear = ""
	var image: Image = Painter.new().paint(look)
	check(image.get_width() == 64 and image.get_height() == 64, "Skins are 64×64 in the Minecraft layout")
	var opaque := true
	for part in ["head", "body", "right_arm", "left_arm", "right_leg", "left_leg"]:
		for face in Layout.FACES:
			var r: Rect2i = Layout.face(part, face)
			for y in range(r.size.y):
				for x in range(r.size.x):
					opaque = opaque and image.get_pixel(r.position.x + x, r.position.y + y).a > 0.99
	check(opaque, "The base layer is fully opaque")
	check(pixel(image, "body_overlay", "front", 3, 6).a < 0.01, "Without a jacket the overlay shell is empty over the chest")
	check(near(pixel(image, "head", "front", 3, 3), Color("8d5a44")), "Skin tone paints the face")
	check(near(pixel(image, "head", "front", 2, 4), Color("3d6fc4"), 0.08), "Eye colour paints the irises")
	check(near(pixel(image, "head", "top", 4, 4), Color("b5602f"), 0.15), "Hair colour covers the top of the head")
	check(near(pixel(image, "body", "front", 1, 6), Color("2b4169"), 0.1), "The top is painted on the torso")
	check(near(pixel(image, "right_arm", "front", 1, 8), Color("8d5a44")), "Short sleeves leave the forearms bare")
	check(near(pixel(image, "right_leg", "front", 0, 3), Color("2e3d57"), 0.14), "Jeans are painted on the legs")
	check(near(pixel(image, "right_leg", "front", 1, 11), Color("c9ccce"), 0.12), "Sneaker soles at the foot")
	look.outfit.outerwear = "patagonia_fleece"
	look.outfit.eyewear = "black_shades"
	var dressed: Image = Painter.new().paint(look)
	check(dressed.get_pixel(Layout.face("body_overlay", "front").position.x + 1, Layout.face("body_overlay", "front").position.y + 6).a > 0.99, "A jacket fills the overlay shell")
	check(near(pixel(dressed, "body_overlay", "front", 5, 5), Color("2e6f73"), 0.1) and near(pixel(dressed, "body_overlay", "front", 5, 4), Color("d9822b"), 0.1), "The rare fleece has its contrast chest pocket and logo")
	check(pixel(dressed, "head_overlay", "front", 1, 4).a > 0.99, "Sunglasses sit on the overlay over the eyes")
	var again: Image = Painter.new().paint(look)
	check(again.get_data() == dressed.get_data(), "The same look always paints the same skin")

func rig_checks() -> void:
	var classic: Node3D = Appearance.new()
	root.add_child(classic)
	classic.apply_preset("sage")
	var slim: Node3D = Appearance.new()
	root.add_child(slim)
	slim.apply_preset("ochre")
	check(is_equal_approx(classic.pelvis.position.y, 0.64) and is_equal_approx(classic.knees[0].position.y, -0.32), "Hips at 0.64 m, knees halfway down the leg")
	var head_top: float = classic.head.position.y + classic.pelvis.position.y + 8 * Layout.PIXEL
	check(absf(head_top - 32 * Layout.PIXEL) < 0.005, "The figure is 32 skin pixels tall (%.2f m)" % head_top)
	check(absf(classic.shoulders[1].position.x) > absf(slim.shoulders[1].position.x), "Slim builds have narrower arms")
	var arm_mesh: MeshInstance3D = classic.shoulders[1].get_child(0)
	check(arm_mesh.material_override.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Pixel-crisp skins (nearest filtering)")
	check(classic.backpack != null and slim.backpack != null, "Backpacks are worn as their own box")
	var tall: Node3D = Appearance.new()
	root.add_child(tall)
	var look: Dictionary = Presets.look_of("sage")
	look.height = 1.06
	tall.apply_look(look)
	check(is_equal_approx(tall.scale.y, 1.06), "Height scales the figure")
	tall.set_seated(true)
	check(absf(tall.pelvis.global_position.y - 0.37) < 0.005, "Seated hips still meet the chair at any height")
	for figure in [classic, slim, tall]:
		figure.free()

func look_checks() -> void:
	var messy: Dictionary = {"hair_style": "mohawk", "skin": "zzz", "height": 3.0, "outfit": {"top": "patagonia_fleece", "shoes": ""}}
	var clean: Dictionary = Looks.sanitize(messy)
	check(clean.hair_style == "short" and clean.skin == Looks.default_look().skin, "Unknown options fall back to defaults")
	check(is_equal_approx(clean.height, Looks.HEIGHT_MAX), "Height is clamped")
	check(clean.outfit.top == "white_tee" and clean.outfit.shoes == "white_sneakers", "Items in the wrong slot or empty required slots are refused")
	check(Looks.is_valid(Presets.look_of("ivory")) and not Looks.is_valid(messy), "Looks validate")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var random_ok := true
	for index in range(40):
		random_ok = random_ok and Looks.is_valid(Looks.random(rng))
	check(random_ok, "Random crowd looks are always valid")
	check(Clothing.ITEMS.size() >= 60 and Clothing.item("patagonia_fleece").rarity == "rare" and Clothing.item("white_jacket").slot == "outerwear", "A catalogue of 60+ items, including the rare Patagonia fleece and the white jacket")
	var all_rarities := true
	for rarity in Clothing.RARITIES:
		all_rarities = all_rarities and Clothing.ITEMS.values().any(func(entry: Array) -> bool: return entry[2] == rarity)
	check(all_rarities, "Every rarity from common to legendary is represented")

func creator_checks() -> void:
	change_scene_to_file("res://ui/start_screen.tscn")
	await scene_changed
	await ticks(3)
	current_scene.new_game_button.pressed.emit()
	await ticks(4)
	var creator: Control = current_scene.selection_panel
	check(creator.preset_buttons.size() == 8, "Eight presets to choose from")
	var portraits: Array = creator.presets_view.find_children("*", "SubViewportContainer", true, false)
	check(portraits.size() == 8, "Each preset card shows a rendered portrait")
	creator.preset_buttons[4].grab_focus()
	await ticks(2)
	check(state.selected_character == "cobalt" and creator.preview.preset_id == "cobalt", "Choosing a preset dresses the preview")
	check(creator.name_edit.text == "Cobalt", "The name follows the preset")
	creator.mode_buttons[1].pressed.emit()
	await ticks(2)
	check(creator.create_view.visible and not creator.presets_view.visible, "Create your own opens the editor")
	var rows: Dictionary = creator.editor.rows
	check(rows.has("hair_style") and rows.has("hair_color") and rows.has("eye_style") and rows.has("eye_color") and rows.has("height") and rows.has("facial_hair") and rows.has("build"), "Hair, eyes, height, build and face options")
	check(rows.has("outfit:outerwear") and rows.has("outfit:top"), "A starting outfit can be chosen")
	var locked_offered := false
	for option in rows["outfit:outerwear"].options:
		locked_offered = locked_offered or (option[0] != "" and not Clothing.unlocked(option[0]))
	check(not locked_offered, "Only unlocked clothes are offered at the start")
	rows.hair_style.step(1)
	await ticks(1)
	check(state.selected_character == "custom" and state.player_look.hair_style == rows.hair_style.value(), "Editing a row builds a custom look")
	var before: float = state.player_look.height
	rows.height.step(1)
	rows.height.step(1)
	check(state.player_look.height > before and creator.preview.height_scale == state.player_look.height, "Height changes the preview's height")
	creator.editor.randomize_look(RandomNumberGenerator.new())
	await ticks(1)
	check(Looks.is_valid(state.player_look), "Randomize gives a valid look")
	creator.name_edit.text = "Jordan"
	creator.name_edit.text_changed.emit("Jordan")
	creator.mode_buttons[0].pressed.emit()
	creator.select_preset("navy")
	check(state.player_name == "Jordan" and state.selected_character == "navy", "A typed name stays when the look changes")
	creator.mode_buttons[1].pressed.emit()
	rows.hair_style.set_value("bun")
	rows.hair_style.step(1)
	rows.hair_style.step(-1)
	await ticks(1)
	var chosen: Dictionary = state.player_look.duplicate(true)
	creator.enter_button.pressed.emit()
	await acquire_world()
	check(player.appearance.look.hair_style == chosen.hair_style and player.appearance.look.skin == chosen.skin, "The created look reaches the game")
	check(state.display_name() == "Jordan" and dorm.hud.menu.identity_name.text == "Jordan", "The student goes by their chosen name")
	check(player.appearance.head_parts.size() >= 2, "A bun is part of the head (hidden with it in first person)")

func closet_checks() -> void:
	check(dorm.has_node("Wardrobe") and dorm.closet.display_name == "Open closet", "A wardrobe in the dorm room")
	await walk_to(Vector3(-2.6, 0, 2.05))
	await walk_to(Vector3(-3.3, 0, 2.05))
	check(player.interaction.target == dorm.closet, "The closet can be targeted")
	await press_interact()
	await ticks(2)
	var hud: CanvasLayer = dorm.hud
	check(hud.closet_open and hud.closet.visible, "Interacting opens the closet")
	check(not player.movement_enabled, "Movement pauses while choosing clothes")
	var equipment: Control = hud.closet.equipment
	check(equipment.slot_buttons.size() == 8, "Eight equipment slots")
	equipment.select_slot("outerwear")
	var white_jacket: Button = equipment.item_grid.get_node("Item_white_jacket")
	white_jacket.pressed.emit()
	await ticks(1)
	check(state.player_look.outfit.outerwear == "white_jacket" and player.appearance.look.outfit.outerwear == "white_jacket", "Choosing the white jacket puts it on")
	check(pixel(player.appearance.skin_image, "body_overlay", "front", 0, 6).a > 0.99, "The jacket is painted on the student")
	var fleece: Button = equipment.item_grid.get_node("Item_patagonia_fleece")
	check(fleece.find_children("*", "Control", false, false).any(func(c: Node) -> bool: return c.get_script() == load("res://ui/style/icon.gd") and c.icon == "lock"), "Rare items show a lock at level 1")
	fleece.pressed.emit()
	await ticks(1)
	check(state.player_look.outfit.outerwear == "white_jacket", "Locked items can't be worn yet")
	check(equipment.card_lock.text.contains("Lvl 2"), "The item card says what unlocks it")
	check(not state.equip("top", "") and not state.equip("top", "dark_jeans"), "Required slots can't be emptied or filled with the wrong item")
	check(state.equip("eyewear", "round_glasses") and state.equip("eyewear", ""), "Optional slots can be worn or emptied")
	hud.closet.show_tab(1)
	var mirror: Control = hud.closet.editor
	mirror.rows.hair_color.set_value("c46f86")
	mirror.rows.hair_color.step(1)
	mirror.rows.hair_color.step(-1)
	await ticks(1)
	check(state.player_look.hair_color == "c46f86" and player.appearance.look.hair_color == "c46f86", "The mirror restyles the student live")
	check(state.player_look.outfit.outerwear == "white_jacket", "Restyling keeps the outfit")
	var esc := InputEventAction.new()
	esc.action = "cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await ticks(2)
	var up := esc.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await ticks(1)
	check(not hud.closet_open and not hud.closet.visible and player.movement_enabled, "Esc closes the closet and movement returns")
	check(not hud.settings_open, "Closing the closet doesn't open the menu")

func inventory_checks() -> void:
	var hud: CanvasLayer = dorm.hud
	hud.set_settings_open(true)
	hud.menu.show_page(7)
	await ticks(2)
	var page: Control = hud.menu.pages.get_child(7)
	check(page.equipment != null and page.equipment.preview != null, "The inventory is an equipment sheet with the student in the middle")
	check(page.equipment.slot_buttons.outerwear.get_node("Icon").item_id == "white_jacket", "Slots show what's worn")
	# Level up to 2: rare items unlock.
	academics.add_xp(90, "test")
	await ticks(2)
	check(academics.level >= 2 and Clothing.unlocked("patagonia_fleece"), "Reaching Lvl 2 unlocks rare items")
	check(hud.message.text.contains("Patagonia Retro Fleece"), "A notice lists the new clothes")
	page.equipment.select_slot("outerwear")
	page.equipment.item_grid.get_node("Item_patagonia_fleece").pressed.emit()
	await ticks(1)
	check(state.player_look.outfit.outerwear == "patagonia_fleece" and player.appearance.look.outfit.outerwear == "patagonia_fleece", "The rare Patagonia fleece can be worn from the inventory")
	var totals: Dictionary = Clothing.outfit_stats(state.player_look.outfit)
	check(page.equipment.stat_bars.style[0].text.contains(str(totals.style)), "Outfit totals update")
	check(not Clothing.unlocked("long_white_coat"), "The legendary long coat waits for the first lecture")
	academics.lectures_completed["pharmacodynamics_01"] = {"correct": 12, "attempted": 12, "xp": 190, "accuracy": 1.0}
	academics.lecture_completed.emit("pharmacodynamics_01")
	check(Clothing.unlocked("long_white_coat") and hud.message.text.contains("Long White Coat"), "Finishing the first lecture unlocks it")
	hud.set_settings_open(false)

func save_checks() -> void:
	var save: Node = root.get_node("SaveGame")
	var expected: Dictionary = state.player_look.duplicate(true)
	check(save.save(), "Saves with the new look")
	var data: Dictionary = save.read()
	check(data.has("look") and data.name == "Jordan", "The save holds the look and name")
	state.return_to_title()
	await scene_changed
	await ticks(3)
	check(current_scene.continue_detail.text.begins_with("Jordan"), "Continue names the student")
	state.player_look = Presets.look_of("sage")
	current_scene.continue_button.pressed.emit()
	await acquire_world()
	check(state.player_look == expected and player.appearance.look == expected, "Reloading restores the exact look and outfit")
	check(state.display_name() == "Jordan", "Reloading restores the name")
	var legacy := data.duplicate(true)
	legacy.erase("look")
	legacy.erase("name")
	legacy.selected_character = "clay"
	check(save.validate(legacy) == "", "Older saves without a look still load")
	var broken := data.duplicate(true)
	broken.look.outfit.top = "not_a_real_item"
	check(save.validate(broken) != "", "A save with an unknown item is rejected")

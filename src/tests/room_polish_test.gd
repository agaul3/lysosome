extends "res://tests/campus_test.gd"

func _run() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	var clock := root.get_node("GameClock")
	for day in [1, 2, 3, 11, 12, 13, 21, 22, 23, 31]:
		var expected: String = {1: "1st", 2: "2nd", 3: "3rd", 11: "11th", 12: "12th", 13: "13th", 21: "21st", 22: "22nd", 23: "23rd", 31: "31st"}[day]
		check(clock.format_date(2026, 1, day) == "January " + expected + ", 2026", "Date ordinal " + expected)
	check(dorm.hud.clock_label.text.contains("September 21st, 2026"), "Written-out HUD date")
	check(is_equal_approx(dorm.get_node("Desk").position.x, dorm.get_node("Chair").position.x), "Chair centered at desk")
	check(not dorm.has_node("Storage"), "Extra cabinet removed")
	check(dorm.get_node("Desk").get_child(1).shape.size.y < 0.15, "Desk has open space below the top")
	check(dorm.hud.key_prompts[2].key == "Tab", "Rendered Tab key prompt")
	dorm.hud._device_changed(true)
	check(dorm.hud.key_prompts[2].key == "Start", "Controller prompts switch")
	dorm.hud._device_changed(false)
	check(dorm.hud.key_prompts[0].key == "WASD", "Keyboard prompts return")
	var boxed := false
	for icon in dorm.hud.key_prompts + [dorm.hud.context_key]:
		var node: Node = icon.get_parent()
		while node != null and node != dorm.hud:
			boxed = boxed or node is PanelContainer or node is Panel or node is ColorRect
			node = node.get_parent()
	check(not boxed, "Keycap prompts float without filled boxes")
	var hud_area := 0.0
	for card in dorm.hud.find_children("*", "PanelContainer", true, false):
		if card.is_visible_in_tree():
			hud_area += card.size.x * card.size.y
			check(card.size.y < 64, "Compact HUD card height: %d" % card.size.y)
	check(hud_area < 0.06 * 1152 * 720, "HUD cards cover under 6%% of the screen (%d px)" % hud_area)
	await capture("polish-dorm")
	state.enter_campus("dorm")
	await acquire_world()
	state.enter_lecture_building()
	await acquire_world()
	check(dorm.find_children("VendingMachine*", "StaticBody3D", true, false).size() == 2, "Two solid vending machines")
	check(dorm.has_node("SofaBase") and dorm.has_node("LoungeBookshelf"), "Lounge furnishings present")
	check(dorm.get_node("Floor").get_child(0).material_override.albedo_color == Color("526571"), "Solid muted carpet")
	await capture("polish-lobby")
	state.enter_campus("dorm")
	await acquire_world()
	player.position = Vector3(-3.5, 0.05, 5.5)
	await ticks(45)
	var signs := dorm.find_children("*", "Label3D", true, false)
	var all_backed := true
	for sign in signs:
		if sign.text != "•" and sign.get("backing") == null:
			all_backed = false
	check(all_backed and not signs.is_empty(), "World names use filled backings")
	await capture("polish-campus")
	print("ROOM POLISH: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

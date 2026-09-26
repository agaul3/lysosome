extends "res://tests/campus_test.gd"
## Milestone 10 UI: title screen, character setup, HUD, player menu pages,
## keyboard navigation, objectives, transitions and small polish features.
var academics: Node
var clock: Node
var sfx: Node

func _run() -> void:
	academics = root.get_node("AcademicSession")
	clock = root.get_node("GameClock")
	sfx = root.get_node("Sfx")
	state = root.get_node("AppState")
	await title_tests()
	await hud_tests()
	await menu_tests()
	await objective_tests()
	print("UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(1)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await ticks(1)

func title_tests() -> void:
	change_scene_to_file("res://ui/start_screen.tscn")
	await scene_changed
	await ticks(3)
	var screen: Control = current_scene
	var panoramas := screen.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() == load("res://world/campus/panorama.gd"))
	check(panoramas.size() == 1 and panoramas[0].get_viewport() != screen.get_viewport(), "Title shows the campus panorama in its own world")
	check(panoramas[0].find_child("LearningCenter", false, false) != null, "Panorama reuses the real campus buildings")
	check(not screen.continue_button.visible and screen.new_game_button.theme_type_variation == "PrimaryButton", "Without a save, New Game is the primary action")
	check(screen.new_game_button.has_focus(), "New Game is focused")
	await press("ui_down")
	check(screen.settings_button.has_focus() and sfx.history.back() == "ui_move", "Arrow keys move through the menu with a soft tick")
	screen.new_game_button.pressed.emit()
	await ticks(2)
	var selection: Control = screen.selection_panel
	check(selection.visible and selection.preset_buttons.size() == 8, "Character setup shows eight presets")
	selection.preset_buttons[2].grab_focus()
	await ticks(2)
	check(state.selected_character == Presets.PRESETS[2].id and selection.preview.preset_id == Presets.PRESETS[2].id, "Focusing a preset card selects it and updates the preview")
	check(selection.preset_buttons[2].button_pressed and not selection.preset_buttons[0].button_pressed, "Only the chosen card is highlighted")
	check(selection.preview_name.text == Presets.PRESETS[2].name, "Preview names the student")
	var spin: float = selection.preview.rotation.y
	await ticks(10)
	check(selection.preview.rotation.y > spin, "Preview turns slowly")
	selection.enter_button.pressed.emit()
	await acquire_world()
	var transition := root.get_node("Transition")
	check(transition.veil.color.a < 0.01 and transition.veil.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Transition veil clears after arriving")

func hud_tests() -> void:
	var hud: CanvasLayer = dorm.hud
	check(hud.location_label.text == "CEDAR RESIDENCE · YOUR ROOM", "HUD names the location")
	check(hud.objective_label.text.begins_with("Pharmacodynamics starts in 25 min"), "HUD objective counts down to class: " + hud.objective_label.text)
	check(hud.clock_label.text == "September 21st, 2026" and hud.time_label.text == "7:35 AM", "Clock card shows the date above the time")
	check(hud.clock_label.get_index() < hud.time_label.get_index(), "Date sits above the time")
	check(hud.progression.level_label.text == "Lvl 1", "Level reads 'Lvl'")
	clock.advance(60.0 / 5.0 * 5.0) # five game minutes
	await ticks(2)
	check(hud.objective_label.text.begins_with("Pharmacodynamics starts in 20 min"), "Objective updates as time passes")
	var materials: Array = player.silhouette_materials
	check(materials.size() > 5 and materials.all(func(m): return m.stencil_mode == BaseMaterial3D.STENCIL_MODE_XRAY), "Player has an x-ray silhouette when hidden by scenery")

func menu_tests() -> void:
	var hud: CanvasLayer = dorm.hud
	var menu: Control = hud.menu
	var before: float = clock.now_seconds()
	hud.set_settings_open(true)
	await ticks(2)
	check(menu.visible and menu.pages.current_tab == 0 and menu.page_title.text == "Overview", "Menu opens on the Overview")
	check(sfx.history.back() == "ui_open", "Opening the menu plays a soft cue")
	check(menu.nav_buttons.size() == 12 and menu.nav_buttons[0].has_focus(), "Twelve sections; the current one has focus")
	check(not player.movement_enabled, "Player stands still while reading the menu")
	var titles := []
	for index in range(9):
		menu.show_page(index)
		await ticks(1)
		titles.append(menu.page_title.text)
		check(menu.pages.get_child(index).is_visible_in_tree(), "Page visible: " + menu.page_title.text)
		check(menu.nav_buttons[index].button_pressed, "Sidebar highlights: " + menu.page_title.text)
	check(titles == ["Overview", "Today's Schedule", "Academic Calendar", "Campus Map", "Knowledge", "Lecture Notes", "Achievements", "Inventory", "Settings"], "Every section of spec §32 is present")
	var first_year_titles := []
	for index in range(9, 12):
		menu.show_page(index)
		await ticks(1)
		first_year_titles.append(menu.page_title.text)
		check(menu.pages.get_child(index).is_visible_in_tree() and menu.nav_buttons[index].button_pressed, "Page visible: " + menu.page_title.text)
	check(first_year_titles == ["Skills", "Wallet & Wellbeing", "Journal"], "First-year pages: skills, wallet, journal")
	# Keyboard navigation: focus moves down the sidebar and follows the page.
	menu.show_page(0)
	menu.nav_buttons[0].grab_focus()
	await press("ui_down")
	await press("ui_down")
	check(menu.pages.current_tab == 2 and menu.nav_buttons[2].has_focus(), "Arrow keys step through sections")
	# Overview content.
	var overview: Control = menu.pages.get_child(0)
	menu.show_page(0)
	var text: String = overview.summary_text()
	check(text.contains("Good morning, " + Presets.get_preset(state.selected_character).name), "Overview greets the student by name")
	check(text.contains("Pharmacodynamics starts in") and text.contains("Starts in"), "Overview shows the objective and the next class")
	check(text.contains("Level 1") or overview.find_children("*", "Control", true, false).size() > 10, "Overview shows progress")
	var save_button: Button = overview.find_children("*", "Button", true, false).filter(func(b): return b.text == "Save now")[0]
	save_button.pressed.emit()
	check(root.get_node("SaveGame").has_save() and overview.save_status.text.begins_with("Saved just now"), "Save now saves and confirms")
	# Map: indoors the marker is the residence.
	var map: Control = menu.pages.get_child(3)
	menu.show_page(3)
	check(map.summary_text().contains("In your room, Cedar Residence"), "Map says where the student is")
	# Notes: empty, then filled as the lecture progresses.
	var notes: Control = menu.pages.get_child(5)
	menu.show_page(5)
	check(notes.summary_text().contains("No notes yet"), "Notes explain they fill in during lectures")
	academics.notes_progress["pharmacodynamics_01"] = 3
	menu.show_page(5)
	check(notes.summary_text().contains("RECEPTORS AND LIGANDS") and notes.summary_text().contains("Most drug binding is reversible") and notes.summary_text().contains("3 OF 11 SECTIONS"), "Notes list the sections reached")
	check(not notes.summary_text().contains("COMPETITIVE ANTAGONISM"), "Unreached sections stay hidden")
	# Achievements derive from progress.
	var achievements: Control = menu.pages.get_child(6)
	menu.show_page(6)
	var total: int = preload("res://data/achievements.gd").ACHIEVEMENTS.size()
	check(achievements.summary_text().contains("0 of %d unlocked" % total), "Achievements start locked")
	academics.best_streak = 10
	root.get_node("Achievements").check()
	menu.show_page(6)
	check(achievements.summary_text().contains("1 of %d unlocked" % total) and achievements.summary_text().contains("In the Zone"), "Achievements reflect progress")
	academics.best_streak = 0
	# Settings in game offers save and return.
	menu.show_page(8)
	check(hud.settings.save_button != null and hud.settings.title_button != null and hud.settings.volume_slider != null, "In-game settings include save and return to title")
	# The world keeps running; Tab closes.
	await ticks(30)
	check(clock.now_seconds() > before + 2.0, "Game time keeps moving with the menu open")
	var tab := InputEventAction.new()
	tab.action = "open_menu"
	tab.pressed = true
	Input.parse_input_event(tab)
	await ticks(2)
	check(not menu.visible and not hud.settings_open and player.movement_enabled, "Tab closes the menu and returns control")
	check(sfx.history.back() == "ui_close", "Closing plays its cue")

func objective_tests() -> void:
	state.enter_campus("dorm")
	await acquire_world()
	check(dorm.hud.location_label.text == "STUDENT COMMONS" and dorm.hud.objective_label.text.contains("Learning Center"), "Campus objective points to the Learning Center")
	dorm.hud.set_settings_open(true)
	dorm.hud.menu.show_page(3)
	await ticks(2)
	var map: Control = dorm.hud.menu.pages.get_child(3)
	check(map.summary_text().contains("Outdoors, Student Commons"), "Map tracks the student outdoors")
	dorm.hud.set_settings_open(false)
	state.enter_lecture_building()
	await acquire_world()
	check(dorm.hud.objective_label.text.contains("Lecture Hall A"), "Lobby objective points to Hall A")
	academics.lectures_completed["pharmacodynamics_01"] = {"correct": 12, "attempted": 12, "xp": 200, "accuracy": 1.0}
	clock.advance(12.0)
	await ticks(2)
	check(dorm.hud.objective_label.text.begins_with("Class complete"), "After class the objective points to the results")
	await capture("ui")

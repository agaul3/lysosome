extends "res://tests/campus_test.gd"
## The first-year systems:
## - the year calendar (story days, events merged into the schedule, week
##   headings, sleep, absences, make-up exams, the monthly stipend);
## - money (spending, earning, carrying, discounts);
## - energy and boosts (food, expiry on game time, XP multipliers on answers
##   and flashcards, tired students);
## - skills (points from levels, prerequisites, effects);
## - achievements (stats, flags, rewards paid once, clothing rewards);
## - saving the lot, loading older saves;
## - the HUD and menu: the money and energy card, the bed at night, the
##   sleep dialog, the day summary and title card, Skills, Wallet, Journal.
var calendar: Node
var wallet: Node
var wellbeing: Node
var skills: Node
var achievements: Node
var academics: Node
var clock: Node
var bank: Node

func _run() -> void:
	state = root.get_node("AppState")
	calendar = root.get_node("YearCalendar")
	wallet = root.get_node("Wallet")
	wellbeing = root.get_node("Wellbeing")
	skills = root.get_node("Skills")
	achievements = root.get_node("Achievements")
	academics = root.get_node("AcademicSession")
	clock = root.get_node("GameClock")
	bank = root.get_node("QuestionBank")
	state.start_new_game()
	calendar_data()
	money_and_energy()
	skills_and_achievements()
	sleeping()
	await saving()
	await hud_and_menu()
	print("YEAR: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func calendar_data() -> void:
	check(calendar.last_error.is_empty() and calendar.days.size() == 28, "The year loads: 28 story days (%s)" % calendar.last_error)
	check(clock.config.events[0].id == "pharmacodynamics_01" and not calendar.event("pharmacokinetics_01").is_empty() and not calendar.event("exam_b6").is_empty(), "The year's events join the schedule after day 1's")
	var sorted := true
	for index in range(1, calendar.days.size()):
		sorted = sorted and String(calendar.days[index - 1].date) < String(calendar.days[index].date)
	check(sorted, "Story days run in order")
	var bad := {"version": 1, "terms": [], "blocks": [{"id": "b1"}], "days": [{"date": "2026-09-21", "block": "b1"}, {"date": "2026-09-21", "block": "b1"}], "events": []}
	check(calendar.validate(bad).contains("Duplicate"), "Duplicate story days are rejected")
	bad.days = [{"date": "2026-09-21", "block": "b1"}]
	bad.events = [{"id": "x", "title": "X", "date": "2026-09-22", "location": "L", "type": "lecture", "hour": 9, "minute": 0}]
	check(calendar.validate(bad).contains("not on a story day"), "Events must fall on story days")
	bad.events = [{"id": "x", "title": "X", "date": "2026-09-21", "location": "L", "type": "lecture", "hour": 25, "minute": 0}]
	check(calendar.validate(bad).contains("invalid time"), "Event times are checked")
	check(calendar.day_number() == 1 and calendar.current_day().title == "First Day of Classes", "Day 1 is the first day of classes")
	check(calendar.day_heading() == "Week 1 · Monday" and calendar.day_heading("2027-01-13") == "Week 2 · Wednesday", "Week headings count from each term's start")
	check(calendar.current_block().name == "Foundations of Medicine", "Block 1 is Foundations of Medicine")
	var next: Dictionary = calendar.next_event()
	check(next.id == "pharmacodynamics_01", "The next event is Pharmacodynamics")

func money_and_energy() -> void:
	check(wallet.balance == 30000 and wallet.formatted() == "$300.00", "A new student starts with $300.00")
	check(wallet.spend(500, "Test") and wallet.balance == 29500 and wallet.spent_total == 500, "Spending lowers the balance")
	check(not wallet.spend(1000000, "Too much") and wallet.balance == 29500, "No overspending")
	check(wallet.earn(1000, "Pay") == 1000 and wallet.earned_total == 1000 and wallet.history[0].label == "Pay", "Earning is logged")
	check(preload("res://data/items.gd").format_money(123456) == "$1,234.56" and preload("res://data/items.gd").format_money(-275) == "−$2.75", "Money is formatted with separators")
	# Food: energy and a boost that multiplies learning XP.
	wellbeing.energy = 50.0
	check(wallet.buy("cold_brew") and is_equal_approx(wellbeing.energy, 65.0), "Cold brew restores 15 energy")
	var boosts: Array = wellbeing.active_boosts()
	check(boosts.size() == 1 and boosts[0].name == "Cold Brew" and is_equal_approx(float(boosts[0].xp), 0.10), "…and starts a +10% XP boost")
	check(is_equal_approx(wellbeing.xp_multiplier("lecture"), 1.1) and is_equal_approx(wellbeing.xp_multiplier("walking"), 1.0), "Boosts apply to learning only")
	var key: String = bank.get_question("pd_efficacy_01").correct_answer
	var result: Dictionary = bank.submit("pd_efficacy_01", key, "year-test:boost")
	check(result.base_xp == 10 and result.xp_reward == 11 and academics.xp_balance == 11, "A boosted answer earns 11 XP instead of 10")
	check(wallet.buy("matcha_latte") and wellbeing.active_boosts().size() == 1 and wellbeing.active_boosts()[0].name == "Calm Focus", "A new drink replaces the last drink's boost")
	check(wallet.buy("grain_bowl") and wellbeing.active_boosts().size() == 2, "A meal's boost stacks with a drink's")
	calendar.advance_to(clock.now_seconds() + 181 * 60)
	check(wellbeing.active_boosts().is_empty(), "Boosts expire on game time")
	for pair in [[30.0, 0.9], [10.0, 0.75], [0.0, 0.6], [45.0, 1.0]]:
		wellbeing.energy = pair[0]
		check(is_equal_approx(wellbeing.energy_factor(), pair[1]), "Energy %d gives XP × %.2f" % [int(pair[0]), pair[1]])
	check(wallet.buy("protein_bar", true) and int(wallet.carried.protein_bar) == 1, "Snacks can be bought to go")
	check(not wallet.buy("grain_bowl", true), "Meals can't be carried")
	wellbeing.energy = 40.0
	check(wallet.use("protein_bar") and not wallet.carried.has("protein_bar") and is_equal_approx(wellbeing.energy, 52.0), "A carried snack is eaten from the backpack")
	wellbeing.energy = 100.0

func skills_and_achievements() -> void:
	check(skills.points_available() == 0, "No skill points at level 1")
	academics.add_xp(80, "test")
	check(academics.level == 2 and skills.points_available() == 1, "Level 2 brings a skill point")
	check(skills.block_reason("test_strategy").begins_with("Requires level"), "Perks need their level")
	check(skills.buy("front_row") and is_equal_approx(skills.effect("xp:lecture"), 0.05), "Front Row adds +5% lecture XP")
	check(not skills.buy("front_row") and skills.block_reason("front_row") == "No skill points", "A rank costs a point")
	skills.grant_points(2)
	check(skills.buy("frugal") and wallet.price(1000) == 900, "Frugal takes 10% off prices")
	check(skills.block_reason("organizer").begins_with("Requires level"), "Deeper perks need levels and prerequisites")
	var before: int = wallet.balance
	achievements.bump("clubs_joined")
	check(achievements.is_unlocked("joiner") and wallet.balance == before + 1500, "Joiner unlocks and pays $15")
	achievements.bump("clubs_joined")
	check(wallet.balance == before + 1500, "Rewards are paid once")
	check(achievements.is_unlocked("skilled"), "Training a perk unlocks Skilled")
	var clothing := preload("res://data/clothing.gd")
	check(not clothing.unlocked("short_white_coat"), "The white coat is epic: locked below level 3")
	achievements.set_flag("white_coat")
	check(achievements.is_unlocked("white_coat") and clothing.unlocked("short_white_coat"), "The ceremony's reward is the coat, whatever the level")
	check(achievements.progress("century") == [1, 100], "Stat goals report progress")
	var xp: int = academics.xp_balance
	achievements.set_flag("fall_complete")
	check(academics.xp_balance == xp, "Achievements never give XP")

func sleeping() -> void:
	check(not calendar.can_sleep(), "Too early for bed in the morning")
	calendar.advance_to(Time.get_unix_time_from_datetime_string("2026-09-21T19:00:00"))
	check(calendar.can_sleep(), "Bedtime from 6 PM")
	# Days 2, 6 and 7 must be open for this test whatever the data says.
	var was_ready: Array = calendar.days.map(func(day: Dictionary) -> bool: return day.get("ready", false))
	calendar.days[1].ready = true
	wellbeing.energy = 35.0
	var summary: Dictionary = calendar.sleep()
	check(summary.missed.size() == 2 and calendar.absences.has("2026-09-21:pharmacodynamics_01"), "Unattended mandatory events are absences")
	check(calendar.today_date() == "2026-09-23" and clock.snapshot().hour == 7 and clock.snapshot().minute == 30, "Sleep jumps to the next story day at 7:30")
	check(is_equal_approx(wellbeing.energy, 100.0) and bool(summary.well_rested) and wellbeing.active_boosts()[0].name == "Well Rested", "An early night restores energy and leaves you Well Rested")
	check(summary.next.date == "2026-09-23" and int(summary.stipend) == 0, "No stipend within September")
	check(achievements.is_unlocked("week_one") and calendar.completed_days.has("2026-09-21"), "Day 1 is finished")
	check(calendar.day_number() == 2 and calendar.current_day().title.begins_with("Pharmacokinetics"), "Day 2 begins")
	# A missed exam moves to a make-up; a new month pays the stipend.
	calendar.days[5].ready = true
	calendar.days[6].ready = true
	calendar.advance_to(Time.get_unix_time_from_datetime_string("2026-10-23T20:00:00"))
	var balance: int = wallet.balance
	var night: Dictionary = calendar.sleep()
	var makeup: Dictionary = calendar.event("exam_b1_makeup")
	check(not makeup.is_empty() and makeup.date == "2026-11-02" and int(makeup.hour) == 13, "A missed exam becomes a make-up at 1 PM on the next story day")
	check(int(night.stipend) == 65000 and wallet.balance == balance + 65000, "The first story day of a new month pays the $650 stipend")
	check(calendar.today_date() == "2026-11-02", "…on 2 November")
	for index in range(was_ready.size()):
		calendar.days[index].ready = was_ready[index]

func saving() -> void:
	var save := root.get_node("SaveGame")
	state.phase = state.Phase.DORM
	check(save.save(), "Save with first-year data: " + save.last_error)
	var data: Dictionary = save.read()
	check(data.has("life") and int(data.life.wallet.balance) == wallet.balance, "The save holds the wallet")
	var balance: int = wallet.balance
	var ranks: Dictionary = skills.ranks.duplicate()
	var unlocked: int = achievements.unlocked_count()
	wallet.reset()
	skills.reset()
	achievements.reset()
	calendar.reset()
	check(save.apply(data), "Load applies")
	check(wallet.balance == balance and skills.ranks == ranks and achievements.unlocked_count() == unlocked, "Money, skills and achievements survive a reload")
	check(calendar.completed_days.has("2026-09-21") and not calendar.event("exam_b1_makeup").is_empty(), "Finished days and make-up exams survive a reload")
	# An older save without the first-year section loads with starting values.
	data.erase("life")
	check(save.validate(data) == "" and save.apply(data) and wallet.balance == 30000 and skills.ranks.is_empty(), "Older saves load with a fresh wallet and skill tree")
	var broken: Dictionary = save.read()
	broken.life.wallet = "nonsense"
	check(save.validate(broken) != "", "A damaged first-year section is rejected")

func hud_and_menu() -> void:
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	var hud: CanvasLayer = dorm.hud
	check(hud.life.money_label.text == "$300.00" and hud.life.energy_label.text.begins_with("100"), "The HUD shows money and energy")
	check(dorm.bed.display_name == "Inspect bed" and dorm.bed.response.contains("freshly made bed"), "In the morning the bed is just a bed")
	# Boost chip.
	wallet.buy("drip_coffee")
	await ticks(2)
	check(hud.life.boost_row.get_child_count() == 1 and hud.toasts.get_child_count() >= 1, "A coffee shows a boost chip and a notification")
	# Evening: the sleep dialog.
	var day_two_ready: bool = calendar.days[1].get("ready", false)
	calendar.days[1].ready = true
	calendar.advance_to(Time.get_unix_time_from_datetime_string("2026-09-21T21:00:00"))
	await ticks(2)
	check(dorm.bed.display_name == "Go to sleep", "At night the bed offers sleep")
	hud.request_sleep()
	await ticks(2)
	check(hud.modal_open(), "The sleep dialog opens")
	var warning: Node = hud.modal.find_child("Warning", true, false)
	check(warning != null and warning.text.contains("Pharmacodynamics"), "It warns about the day's missed classes")
	check(not player.movement_enabled, "The student holds still while it's open")
	hud.modal.confirmed.emit()
	await ticks(3)
	var screens := hud.get_children().filter(func(node: Node) -> bool: return node.get_script() != null and node.get_script().resource_path == "res://ui/day_summary.gd")
	check(screens.size() == 1 and calendar.today_date() == "2026-09-23", "Sleeping shows the day summary and moves to day 2")
	screens[0].continued.emit()
	await ticks(3)
	var cards := hud.get_children().filter(func(node: Node) -> bool: return node.get_script() != null and node.get_script().resource_path == "res://ui/day_card.gd")
	check(cards.size() == 1 and player.movement_enabled and not hud.modal_open(), "Waking shows the day's title card and play resumes")
	calendar.days[1].ready = day_two_ready
	# Menu pages.
	academics.add_xp(200, "test")
	hud.set_settings_open(true)
	await ticks(2)
	hud.menu.show_page(9)
	await ticks(1)
	var skills_page: Control = hud.menu.pages.get_child(9)
	check(skills_page.summary_text().contains("skill points available") and skills_page.find_child("Train_front_row", true, false) != null, "Skills lists perks you can train")
	(skills_page.find_child("Train_front_row", true, false) as Button).pressed.emit()
	await ticks(1)
	check(skills.rank("front_row") == 1, "Training from the page spends a point")
	hud.menu.show_page(10)
	await ticks(1)
	var wallet_page: Control = hud.menu.pages.get_child(10)
	check(wallet_page.summary_text().contains("BALANCE") and wallet_page.summary_text().contains("Well Rested"), "Wallet shows the balance and active boosts")
	hud.menu.show_page(11)
	await ticks(1)
	var journal: Control = hud.menu.pages.get_child(11)
	var story: String = journal.summary_text().to_lower()
	check(story.contains("foundations of medicine") and story.contains("the last day of m1") and story.contains("brain & behavior"), "The journal tells the whole year")
	hud.set_settings_open(false)

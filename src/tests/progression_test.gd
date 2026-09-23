extends "res://tests/campus_test.gd"
## Milestone 8: level curve, XP awards, overflow, multiple level-ups, lateness
## safety, streaks, and the HUD/audio feedback that reacts to them.
const LevelCurve = preload("res://education/progression/level_curve.gd")
var academics: Node
var bank: Node
var attempt := 0
var clock: Node

func _run() -> void:
	academics = root.get_node("AcademicSession")
	bank = root.get_node("QuestionBank")
	clock = root.get_node("GameClock")
	curve_tests()
	xp_tests()
	streak_tests()
	await hud_tests()
	print("PROGRESSION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func curve_tests() -> void:
	check(LevelCurve.threshold(1) == 0 and LevelCurve.threshold(2) == 80 and LevelCurve.threshold(3) == 184 and LevelCurve.threshold(4) == 319, "Documented thresholds: 80, 184, 319")
	var escalating := true
	for level in range(1, 20):
		escalating = escalating and LevelCurve.cost(level + 1) > LevelCurve.cost(level)
	check(escalating, "Each level costs more than the last")
	check(LevelCurve.level_for_xp(79) == 1 and LevelCurve.level_for_xp(80) == 2 and LevelCurve.level_for_xp(183) == 2 and LevelCurve.level_for_xp(184) == 3, "Level thresholds are exact")
	var progress := LevelCurve.progress(100)
	check(progress.level == 2 and progress.into == 20 and progress.needed == 104, "UI progress toward the next level")
	check(LevelCurve.level_for_xp(-5) == 1 and LevelCurve.progress(-5).into == 0, "Negative balance is treated as zero")
	check(LevelCurve.level_for_xp(1_000_000_000) == int(clock.config.level_curve.max_level), "Level is capped at the configured maximum")
	var saved: Dictionary = clock.config.level_curve.duplicate()
	clock.config.level_curve.base_xp = 100
	check(LevelCurve.threshold(2) == 100, "Curve reads its configuration from academic_config.json")
	clock.config.level_curve = saved

func answer(id: String, correct: bool) -> Dictionary:
	attempt += 1
	var question: Dictionary = bank.get_question(id)
	var key: String = question.correct_answer
	if not correct:
		for choice in question.choices:
			if choice != key:
				key = choice
				break
	return bank.submit(id, key, "progression-test:%d" % attempt)

func xp_tests() -> void:
	academics.reset()
	var levels := []
	var record := func(from_level: int, to_level: int) -> void: levels.append([from_level, to_level])
	academics.level_up.connect(record)
	var tier_two: int = int(clock.config.xp_by_tier["2"])
	var result := answer("pd_potency_01", true)
	check(result.correct and result.xp_reward == tier_two and academics.xp_balance == tier_two, "Correct answer awards its tier XP (%d)" % tier_two)
	result = answer("pd_potency_01", false)
	check(not result.correct and result.xp_reward == 0 and academics.xp_balance == tier_two, "Incorrect answer awards zero")
	academics.reset()
	levels.clear()
	academics.add_xp(50, "answer")
	academics.add_xp(40, "answer")
	check(academics.level == 2 and academics.level_progress().into == 10 and levels == [[1, 2]], "Crossing a threshold levels up once and keeps the overflow")
	academics.reset()
	levels.clear()
	academics.add_xp(400, "answer")
	check(academics.level == 4 and academics.level_progress().into == 81 and levels == [[1, 4]], "One large award can gain several levels without breaking state")
	academics.reset()
	levels.clear()
	academics.add_xp(-5, "late")
	check(academics.xp_balance == -5 and academics.level == 1 and academics.level_progress().into == 0 and academics.level_progress().fraction == 0.0, "Late penalty at zero XP: balance -5, level and bar stay safe")
	academics.add_xp(80, "answer")
	check(academics.xp_balance == 75 and academics.level == 1 and levels.is_empty(), "Later rewards repay the penalty before counting toward a level")
	academics.reset()
	academics.add_xp(90, "answer")
	academics.add_xp(-20, "late")
	check(academics.level == 2 and academics.level_progress().level == 2 and academics.level_progress().fraction == 0.0, "A penalty after levelling never takes the level away")
	academics.level_up.disconnect(record)
	# Lateness through the real attendance path still subtracts exactly 5 once.
	academics.reset()
	clock.elapsed_seconds = 26 * 60
	academics.record_arrival("pharmacodynamics_01")
	academics.record_arrival("pharmacodynamics_01")
	check(academics.xp_balance == -5, "Lateness subtracts 5 exactly once")
	clock.reset()
	academics.reset()

func streak_tests() -> void:
	academics.reset()
	var visible_at := -1
	for index in range(12):
		answer("pd_efficacy_01", true)
		if academics.streak_visible() and visible_at < 0:
			visible_at = academics.streak
	check(academics.streak == 12 and visible_at == 10, "Streak increments per correct answer and becomes visible at 10")
	answer("pd_efficacy_01", false)
	check(academics.streak == 0 and not academics.streak_visible() and academics.best_streak == 12, "An incorrect answer resets the streak (best kept)")
	academics.reset()

func hud_tests() -> void:
	state = root.get_node("AppState")
	var sfx := root.get_node("Sfx")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	var hud: Node = dorm.hud.progression
	check(hud.card.visible and hud.level_label.text == "LV 1" and hud.xp_label.text.begins_with("0 / 80"), "HUD shows level and XP progress")
	check(not hud.streak_chip.visible, "Streak is not shown before 10")
	answer("pd_efficacy_01", true) # tier 1: 10 XP
	await ticks(2)
	check(sfx.history.back() == "correct", "Correct answer plays the confirmation sound")
	var floaters: Array = hud.float_layer.get_children().filter(func(n): return n.name.begins_with("FloatingXP"))
	check(floaters.size() == 1 and floaters[0].text == "+10 XP", "Floating XP value appears")
	await ticks(50)
	check(absf(hud.shown_fraction - 10.0 / 80.0) < 0.01, "XP bar animates to the new progress")
	await ticks(60)
	check(hud.float_layer.get_child_count() == 0, "Floating XP fades away")
	answer("pd_efficacy_01", false)
	await ticks(2)
	check(sfx.history.back() == "incorrect", "Incorrect answer plays its own sound")
	for index in range(10):
		answer("pd_efficacy_01", true)
	await ticks(2)
	check(hud.streak_chip.visible and hud.streak_label.text == "10x STREAK", "Streak UI appears at 10 consecutive correct answers")
	check(academics.level == 2, "Earned XP levelled the player up (%d XP)" % academics.xp_balance)
	check(hud.banner.visible and hud.banner_levels.text == "Level 1 → Level 2", "Level-up banner shows the level change")
	await create_timer(0.35).timeout
	check(sfx.history.has("level_up"), "Level-up plays the distinctive fanfare")
	await create_timer(0.3).timeout
	check(hud.banner.scale.x > 0.95, "Banner pops to full size")
	answer("pd_efficacy_01", false)
	await ticks(2)
	check(not hud.streak_chip.visible, "Streak UI hides after an incorrect answer")
	await create_timer(2.5).timeout
	check(not hud.banner.visible, "Level-up effect is brief")
	check(hud.level_label.text == "LV 2" and absf(hud.shown_fraction - academics.level_progress().fraction) < 0.01, "Bar settles on the overflow into level 2")
	academics.add_xp(-5, "late")
	await ticks(2)
	var penalty: Array = hud.float_layer.get_children().filter(func(n): return n.text == "−5 XP")
	check(penalty.size() == 1, "A penalty shows a red −5 XP")
	check(hud.level_label.text == "LV 2", "The displayed level does not drop")
	await capture("progression")

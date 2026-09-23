extends "res://tests/campus_test.gd"
## Milestone 9: knowledge statistics and the Knowledge menu page. The
## acceptance test is that displayed statistics match the question history.
const Knowledge = preload("res://education/knowledge/knowledge.gd")
var academics: Node
var bank: Node
var attempt := 0

func _run() -> void:
	academics = root.get_node("AcademicSession")
	bank = root.get_node("QuestionBank")
	model_tests()
	await menu_tests()
	print("KNOWLEDGE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func answer(id: String, correct: bool) -> void:
	attempt += 1
	var question: Dictionary = bank.get_question(id)
	var key: String = question.correct_answer
	if not correct:
		for choice in question.choices:
			if choice != key:
				key = choice
				break
	bank.submit(id, key, "knowledge-test:%d" % attempt)

func find(nodes: Array, path: String) -> Dictionary:
	for node in nodes:
		if node.path == path:
			return node
		var found := find(node.children, path)
		if not found.is_empty():
			return found
	return {}

func model_tests() -> void:
	academics.reset()
	var roots := Knowledge.tree(bank.records.values(), academics.topic_statistics)
	var pharmacology := find(roots, "Pharmacology")
	check(roots.size() == 1 and pharmacology.attempted == 0 and pharmacology.accuracy == 0.0 and Knowledge.accuracy_text(pharmacology) == "—", "Zero-attempt state is safe")
	check(not find(roots, "Pharmacology/Pharmacodynamics").is_empty(), "Pharmacology └ Pharmacodynamics hierarchy present")
	var subtopics: Array = find(roots, "Pharmacology/Pharmacodynamics").children.map(func(n): return n.name)
	check(subtopics == ["Receptors and ligands", "Agonists", "Antagonists", "Competitive antagonism", "Noncompetitive antagonism", "Potency", "Efficacy", "Dose-response", "Clinical application"], "Every subtopic is listed in lecture order, even unattempted %s" % str(subtopics))
	answer("pd_affinity_01", true)
	var pd := find(Knowledge.tree(bank.records.values(), academics.topic_statistics), "Pharmacology/Pharmacodynamics")
	check(pd.attempted == 1 and pd.correct == 1, "Attempt and correct counts increment")
	answer("pd_affinity_01", false)
	pd = find(Knowledge.tree(bank.records.values(), academics.topic_statistics), "Pharmacology/Pharmacodynamics")
	check(pd.attempted == 2 and pd.correct == 1 and is_equal_approx(pd.accuracy, 0.5), "Incorrect answers count as attempts; accuracy recalculates")
	# A mixed history across subtopics; every level must match an independent recount.
	for entry in [["pd_potency_01", true], ["pd_potency_01", false], ["pd_efficacy_01", true], ["pd_competitive_01", true], ["pd_naloxone_01", false], ["pd_buprenorphine_01", true], ["pd_noncompetitive_remedial_01", true]]:
		answer(entry[0], entry[1])
	var recount := Knowledge.from_history(academics.question_history, bank)
	var matches := true
	for path in recount:
		var node := find(Knowledge.tree(bank.records.values(), academics.topic_statistics), path)
		matches = matches and node.attempted == recount[path].attempted and node.correct == recount[path].correct
	check(matches and recount["Pharmacology"].attempted == 9 and recount["Pharmacology"].correct == 6, "Statistics at every level match the question history (6/9)")
	check(Knowledge.accuracy_text(find(Knowledge.tree(bank.records.values(), academics.topic_statistics), "Pharmacology")) == "67%", "Accuracy shown as a rounded percentage")
	var recent := Knowledge.recent(academics.question_history, bank, 3)
	check(recent.size() == 3 and recent[0].prompt == bank.get_question("pd_noncompetitive_remedial_01").prompt and recent[2].correct == false, "Recent answers listed newest first")
	# Future disciplines need no code: they appear from the taxonomy and statistics.
	var future := Knowledge.tree([{"discipline": "Physiology", "topic": "Cardiovascular", "subtopic": "Preload"}], {"Physiology": {"attempted": 4, "correct": 3}, "Physiology/Cardiovascular": {"attempted": 4, "correct": 3}, "Physiology/Cardiovascular/Preload": {"attempted": 4, "correct": 3}})
	check(future.size() == 1 and find(future, "Physiology/Cardiovascular/Preload").accuracy == 0.75, "Architecture supports further disciplines and subtopics")

func menu_tests() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	var hud: Node = dorm.hud
	hud.set_settings_open(true)
	var tabs: TabContainer = hud.menu_tabs
	var names: Array = []
	for index in range(tabs.get_tab_count()):
		names.append(tabs.get_tab_title(index))
	check(names == ["Today", "Calendar", "Knowledge", "Settings"], "Knowledge page in the player menu %s" % str(names))
	tabs.current_tab = 2
	await ticks(3)
	var panel: Node = hud.knowledge_panel
	check(panel.summary.text.begins_with("Accuracy ="), "Fresh game explains accuracy before any attempts")
	check(panel.value_labels["Pharmacology"].text.begins_with("—"), "Unattempted areas show a dash, not 0%")
	answer("pd_affinity_01", true)
	answer("pd_partial_agonist_01", true)
	answer("pd_antagonist_01", false)
	await ticks(2)
	var recount := Knowledge.from_history(academics.question_history, bank)
	var shown_match := true
	for path in recount:
		var node := find(Knowledge.tree(bank.records.values(), academics.topic_statistics), path)
		var expected := Knowledge.accuracy_text(node) + "   " + "%d/%d" % [recount[path].correct, recount[path].attempted]
		shown_match = shown_match and panel.value_labels.has(path) and panel.value_labels[path].text == expected
	check(shown_match, "Displayed statistics match question history at every level")
	check(panel.value_labels["Pharmacology/Pharmacodynamics"].text == "67%   2/3", "Pharmacodynamics shows 67% (2/3)")
	check(panel.summary.text == "Overall: 2 of 3 correct (67%)", "Overall summary matches")
	check(panel.recent_box.get_child_count() == 3 and panel.recent_box.get_child(0).text.begins_with("Missed"), "Recent answers show the latest result first")
	check(panel.value_labels["Pharmacology/Pharmacodynamics/Efficacy"].text.begins_with("—"), "Subtopics without attempts stay unattempted")
	await capture("knowledge")
	hud.set_settings_open(false)

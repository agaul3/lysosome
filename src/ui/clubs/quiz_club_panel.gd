extends "res://ui/clubs/club_event_panel.gd"
## The clubs whose meeting is itself the questions: Medical Spanish (phrases
## for the history, and when to call an interpreter) and Journal Club (one
## original, fictional abstract per meeting, appraised: design, bias, and the
## numbers a patient would care about). The score is the share right.
## Journal Club abstracts: [title, text, tag on its questions]. Fictional
## studies with invented numbers, for practice only.
const ABSTRACTS := [
	["The HARBOR trial (fictional)", "Design: randomized, double-blind, placebo-controlled trial. Participants: 2,000 adults aged 55–80 with atrial fibrillation and no prior stroke, randomized 1:1 to the new anticoagulant \"Drug H\" or placebo. Outcome: stroke at 3 years. Results: stroke occurred in 4.0% on Drug H and 6.0% on placebo. Major bleeding: 2.1% vs 1.5%.", "abstract_harbor"],
	["The Morning Cup cohort (fictional)", "Design: prospective cohort. Participants: 50,000 nurses without liver disease followed for 10 years. Exposure: coffee intake, by questionnaire every two years. Outcome: new chronic liver disease. Results: drinking 3 or more cups a day was associated with a lower risk than drinking none (relative risk 0.80; 95% confidence interval 0.65 to 0.98), after adjusting for age, alcohol and body-mass index.", "abstract_cohort"],
	["A rapid strep test study (fictional)", "Design: diagnostic accuracy study. Participants: 1,000 children with a sore throat, each tested with a new rapid antigen test and with a throat culture (the reference standard). Results: 100 children had strep by culture; the rapid test was positive in 90 of them. Of the 900 without strep, the rapid test was negative in 855.", "abstract_rapid"],
]
var abstract_index := 0

func _init(id: String) -> void:
	super(id)
	abstract_index = absi(hash(YearCalendar.today_date())) % ABSTRACTS.size()

func activity_title() -> String:
	if club_id == "journal":
		return "Journal Club · " + String(ABSTRACTS[abstract_index][0])
	return "Medical Spanish · practice"

func activity_intro() -> String:
	if club_id == "journal":
		return "Lunch and one paper. A second-year leads, you read the abstract and the group appraises it together: the design, what could bias it, and what the numbers mean for a patient."
	return "Tonight: the history in Spanish. Greetings, where it hurts, since when, allergies and medicines, and giving instructions, with the formal usted. The coordinator, a second-year from Puerto Rico, corrects your accent kindly."

func energy_cost() -> float:
	return 4.0

func questions_per_meeting() -> int:
	return 3 if club_id == "journal" else 6

## Journal Club asks about the abstract it read.
func question_pool() -> Array:
	var pool: Array = super()
	if club_id != "journal":
		return pool
	var tag := String(ABSTRACTS[abstract_index][2])
	return pool.filter(func(id: String) -> bool: return QuestionBank.get_question(id).get("tags", []).has(tag))

func start_activity() -> void:
	if club_id == "journal":
		var card := UI.card(Vector4(16, 12, 16, 12))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		card.add_child(column)
		column.add_child(UI.label(String(ABSTRACTS[abstract_index][0]), UI.SIZE_TITLE, UI.TEXT, 600))
		column.add_child(UI.paragraph(String(ABSTRACTS[abstract_index][1]), width - 90, UI.SIZE_BODY, UI.TEXT_MUTED))
		body.add_child(card)
		add_text("Read it carefully: the questions use these numbers.", UI.TEXT_FAINT, UI.SIZE_LABEL)
	else:
		add_text("\"Buenas tardes. Soy estudiante de medicina.\" Six phrases tonight. Say each aloud, then choose what it means (or how to say it).", UI.TEXT, UI.SIZE_BODY)
	var go := add_button("To the questions", func() -> void: activity_done(0.0), true)
	go.name = "ToQuestions"
	_focus_first.call_deferred()

## The score is the share of questions right.
func finish() -> void:
	if not question_results.is_empty():
		var correct := question_results.filter(func(entry: Dictionary) -> bool: return entry.get("correct", false)).size()
		# The meeting's score (and so its 70/30 blend) is simply the share right.
		activity_score = float(correct) / float(question_results.size())
	super()

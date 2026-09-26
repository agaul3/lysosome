# Shared question engine

`QuestionBank` loads the versioned JSON files listed in `QuestionBank.PATHS` as one bank (IDs unique across files): the lectures' banks, the shadowing session, the year's activities and exams (`activities_b1.json`–`activities_b6.json`) and the clubs. Content is separate from scripts and shared by lectures, activities, exams, quizzes and flashcards. No runtime AI is used.

Each document is `{ "version": 1, "questions": [...] }`. Each record requires nonempty string fields `id`, `discipline`, `topic`, `subtopic`, `question_type`, `prompt`, `correct_answer`, `explanation`, `learning_objective`, `lecture_id`; integer `difficulty_tier` 1–3; a `choices` object mapping stable keys to unique text; and `xp_reward` (integer override between 0 and 1,000,000 or null to use `data/academic_config.json` tier rewards). Type is independent of tier. Supported types: Recall, Conceptual, Application, Clinical Application, Interpretation, Synthesis.

`format` defaults to `multiple_choice`. `short_answer` accepts only normalized predefined strings from `accepted_short_answers`; its correct answer must be in that list. Normalization trims edges, folds case and repeated ASCII spaces. No fuzzy or AI grading. Optional fields such as tags and is_remediation are preserved; they do not activate gameplay logic.

Methods:

- `load_file(path)` / `load_json(text)`: atomic import. False with `last_error` on malformed content; the previous bank remains intact.
- `get_question(id)` / `for_lecture(id)`: deep copies so callers cannot mutate the live database.
- `grade(id, answer)`: pure evaluation returning validity, correctness, answer key, explanation, objective and reward. Invalid input is not an incorrect attempt.
- `submit(id, answer, attempt_id)`: valid evaluation plus one session performance/XP transaction. Repeating the same ID and payload is idempotent. Reusing an attempt ID for different content is rejected. A future presentation client creates one attempt ID per question attempt and reuses it for retries.

Performance hooks record attempted/correct totals and discipline/topic/subtopic counts. XP rewards use 10/20/30 by tier unless overridden. The session ledger permits a -5 balance when a late student has no prior XP, retaining the exact penalty. Later earned XP repays this balance. No level curve or level-up audiovisual feedback is implemented yet.

The three seed questions are original, sourced/reviewed as described in `docs/development/MEDICAL_CONTENT_REVIEW.md`. Human educational review is still required. The full lecture question set, presentation and remediation are deferred.

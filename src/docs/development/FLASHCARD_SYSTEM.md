# Computers and flashcard study

Implemented September 23, 2026. This extends the dormant study-desk entry point. The current user request takes precedence over the vertical slice's previously deferred study system.

## Playable flow

- Dorm: interact with **Use study desk PC**. The desk now has a desktop tower, monitor, keyboard and mouse and a Windows-style login/desktop.
- Carrying: any equipped backpack provides a MacBook in Inventory. Removing the backpack removes access, without deleting study progress.
- Laptop: sit at either chair of the café study table (between the terrace umbrellas), or any usable lecture seat. Press **L**, click the laptop prompt, or open it from Inventory. Standing and ordinary non-table chairs do not permit use.
- Lecture seats deploy a writing tray; café laptops rest on the table. The prop packs away when the computer closes. Opening the laptop works while the lecture has locked the seat. Closing it preserves that lock.
- Both devices require **player1 / 122333**. Incorrect credentials leave the login screen open with an error. Password input is masked. This is fictional local authentication, not a network account.
- Click **Anki** from either desktop. **Esc** closes the computer. Player movement and interaction are held while it is open; first-person mouse capture is released. The world and academic clock continue running. Lecture shortcuts do not consume computer input.

## Study and formatting

One offline collection is shared by both devices and included in the existing game save. Old saves without a collection load with an empty study history; a new game clears it. A rated card, note edit, option change, suspension or burial autosaves.

The light Anki-style app uses the project's typography and controls: Decks / Add / Browse / Stats / Options, blue new counts, red learning counts, green review counts, a question-first study screen, separate answer and explanation, and four interval-labelled rating buttons. Long content scrolls while recall buttons remain visible. Space reveals; after revealing, Space/Enter chooses Good and 1–4 chooses Again/Hard/Good/Easy. Ratings are rejected before reveal and duplicate submissions cannot change progress.

The starter deck is `Medicine::Pharmacology::Pharmacodynamics`. It adapts 13 standalone records from the shared QuestionBank at runtime, hides multiple-choice distractors, and retains the exact correct answer, explanation, objective and source ID. The graph-dependent `pd_viz_competitive_01` is excluded because its prompt needs the lecture visualization. Bank content is inspectable but is edited at its authoritative source, not overwritten in a personal save.

Personal notes support:

- **Basic:** front, back, extra explanation/reference, deck, tags.
- **Cloze:** `{{c1::answer}}` and `{{c1::answer::hint}}`. Matching numbers hide together; different numbers create sibling cards. Answering one sibling buries the others until the next UTC day.
- Browse searches front, answer and tags, shows schedules and lapses, edits personal notes, and suspends/resumes cards.
- Bury hides a card until tomorrow. Eight review lapses automatically suspend a leech; Browse can resume it after revising the concept.

## Scheduling and XP decisions

This is an original implementation of **classic Anki-style scheduling**, not a complete Anki port or FSRS implementation. It follows the documented learning/relearning/recall workflow:

| State | Again | Hard | Good | Easy |
| --- | --- | --- | --- | --- |
| New / first learning step | 1 minute | 5.5 minutes | 10 minutes | Graduate, 4 days |
| Final learning step | 1 minute | 10 minutes | Graduate, 1 day | Graduate, 4 days |
| Relearning | 10 minutes | 15 minutes | Graduate, 1 day | Graduate, at least 4 days |
| Review | Relearn; ease −0.20 | Interval ×1.2; ease −0.15 | Interval ×ease | Interval ×ease ×1.3; ease +0.15 |

Ease starts at 2.5, is bounded below by 1.3, and does not fall for failures during learning/relearning. Successful overdue review receives interval credit. Review intervals increase monotonically across Hard/Good/Easy and cap at 36,500 days. There is no random interval fuzz. Due learning cards take priority, then due reviews, then new cards. The configurable new-card limit defaults to 20 across the collection; due reviews remain unlimited.

Scheduling uses the real system clock, including time outside the game, with UTC midnight rollover. The accelerated academic clock never changes card due dates. This deliberately differs from Anki's configurable local study-day cutoff and prevents in-game waiting from making study intervals useless.

**XP:** +2 for a card's first eligible review each real UTC day, at most 100 daily, after at least three seconds with the prompt open. Every rating, including Again, earns the same amount. Repeated learning steps and instant clicks do not repeatedly pay. This rewards study participation without biasing a learner toward Easy. It is not proof of correct recall. Self-ratings do not alter graded question accuracy, knowledge statistics or lecture streaks. Stats display recall ratings and XP for the latest 5,000 reviews.

## Brainstorm: next design choices (not implemented)

1. **Concept-first notes:** atomic prompts grouped by discipline → system → topic. Use Basic for mechanisms, Cloze for small factual relationships, and case prompts for transfer. Keep explanations and sources on the answer side. Avoid turning every lecture slide into one overloaded card.
2. **Lecture integration:** offer a short deck after completing each lecture and suggest a small number of targeted cards following a missed question. Keep author-created cards editable and distinguish faculty content from personal notes.
3. **Progression:** retain rating-neutral study XP. Consider a small consistency reward for clearing a genuinely due queue, and separately verified concept challenges for mastery XP. Avoid permanent study streak penalties or points for clicking Easy.
4. **Modern scheduling:** add tested FSRS with explicit desired-retention settings and review-history migration. Do not label a hand-tuned approximation as FSRS.
5. **Rich material:** image occlusion for anatomy, diagrams for pharmacology, linked concept explanations, and source citations. Each clinical content expansion should follow the existing human-review workflow.
6. **Interoperability:** opt-in CSV / .apkg import and export before considering AnkiWeb integration. Local demo credentials must remain distinct from real Anki credentials.
7. **Desktop polish:** configurable wallpapers, card typography, deck hierarchy expansion, window minimize/restore, and a compact picture-in-picture study mode during lectures.

## Known boundaries

No FSRS, AnkiWeb sync, .apkg import/export, add-ons, media notes, reverse-card template, undo, configurable learning steps, per-deck presets, fuzz, full desktop OS, or network authentication. Desktop menu text is visual decoration; the app shortcut, account panel, lock and close controls are interactive. Shared question-bank medical review remains pending; this feature does not certify those questions for educational release. Physical controller hardware and extended multi-day use still need manual testing.

## Verification

`tests/flashcard_test.gd` covers scheduler transitions, overdue credit, ease floor, leeches, duplicate/pre-reveal rejection, XP, Cloze grouping/hints/sibling burial, note validation, daily limits, save validation and backward compatibility, both logins, note creation/search, shared PC–laptop state, backpack gating, real café seating, lecture tray, first-person pointer release and preserving the lecture seat lock on close. Real key events during an active lecture confirm that Space reveals and number keys rate flashcards without advancing the lesson. The dorm acceptance route now checks that the desk opens the PC instead of showing the obsolete placeholder.

The graphical run captures both login/desktop styles, decks, answer review, Browse, café and lecture laptop placement. Regression results are recorded in CHANGELOG.md.

References consulted:
- [Anki studying manual](https://docs.ankiweb.net/studying.html)
- [Anki scheduling algorithm FAQ](https://faqs.ankiweb.net/what-spaced-repetition-algorithm.html)
- [Anki deck options](https://docs.ankiweb.net/deck-options)

# Milestone 7 acceptance — Pharmacodynamics Lecture

Recorded 2026-09-23 10:14 PDT. Spec: `docs/design/medical_school_rpg_spec.md` §9.7–9.8, §15–25 and §42 (Milestone 7). Acceptance criterion: **the full educational loop works end to end.**

| Requirement | Implementation | Evidence |
|---|---|---|
| Lecture hall, multiple seats, several NPC students | Raked auditorium (`world/lecture_hall/lecture_hall.gd`): 65 seats, 14 seated classmates, Alex arrives and sits | `seating_test.gd` (147 checks), `npc_test.gd` |
| Seat selection; free movement disabled once seated | Any free seat; row routing through the walkway graph; realistic sit/stand; seat locked during class | `seating_test.gd`, `lecture_test.gd` ("Seat is locked during the lecture") |
| Smooth camera transition to a lecture camera | `world/lecture_camera.gd`: orthographic→perspective blend with matched first frame, arcing to an over-the-shoulder view | `seating_test.gd` camera checks (framing drift < 4 px, exact final pose, return) |
| Professor presentation | Data-driven script `education/lectures/pharmacodynamics_01.json` (11 segments, all nine suggested topics); live slides on the screen; animated professor | `lecture_test.gd` runner, slide and gesture checks |
| Interactive visualization | Competitive antagonism: player-controlled agonist, antagonist added, prediction, test; Gaddum occupancy model | `lecture_test.gd` model and activity checks |
| Question progression (concept → feedback → clinical connection → application) | Question beats between explanation lines; efficacy, dose-response and clinical segments pair clinical connections with application questions | `lecture_test.gd` ("Every question beat is asked") |
| About 12 original questions, shared database, not hard-coded | 12 scored questions + 2 remediation follow-ups in `education/questions/pharmacodynamics.json`; the script references ids only | `lecture_test.gd` integrity checks; `academic_test.gd` |
| Recall / conceptual / application / clinical application mix | All four types present | `lecture_test.gd` |
| Incorrect answers: clear failure, explanation, no XP, stats updated | `question_beat.gd` + `QuestionBank.submit` | `lecture_test.gd` (deliberate misses) |
| Selective remediation | Two beats offer a simpler follow-up after a miss | `lecture_test.gd` ("Selected wrong answers get a simpler follow-up") |
| Medical accuracy record | `MEDICAL_CONTENT_REVIEW.md` covers every question and the narration, with review flags | Document |
| Lecture completion; statistics updated; exploration resumes | Summary card (score, accuracy, XP); `AcademicSession.lectures_completed`; schedule shows the result; seat unlocks | `lecture_test.gd` completion checks |

Also verified: graphical captures of every question state, the activity phases, the completion summary and the schedule result; all nine suites pass (see `CHANGELOG.md`).

**Out of scope, deferred to later milestones:**
- XP HUD, floating XP, sounds, streaks and level-ups (Milestone 8).
- The Knowledge interface (Milestone 9).
- Save/load. Lecture results are session-only until then.

**Honest limitations:**
- The questions and narration are AI-assisted prototypes awaiting human review.
- The professor stays at the podium, and there is no audio.

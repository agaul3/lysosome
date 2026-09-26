# The first year — acceptance

Recorded 2026-09-25 (PDT). Status: **PASS, with the limitations listed below**. The whole first year is playable from the first day of classes to the end-of-year celebration, then summer, and every requested element is built and covered by automated tests with real movement. Graphical checks were made from captures in both camera modes. All medical content is original and awaits human review (`MEDICAL_CONTENT_REVIEW.md`); as with Milestone 11, this does not block the feature.

## The request

From the user, after the Emergency Department:
- finish the storyline and progression of the first year: other lectures, exams, more Anki flashcards, clinical rotations, more buildings and the other things first-years take part in;
- student-run clubs the player can join (school, medicine or other; for example, serving food at a food shelter);
- a complete campus with more buildings and lecture halls, with lecture rooms, lobbies and hallways laid out like real medical centers;
- food courts in the hospital and in the medical school;
- a library where the player can study at the PCs or sit down with a laptop;
- a meaningful level-up system, an expanded achievement and skill tree, boosts such as XP boosts, and a currency;
- grandiose but accurate content with the feel of a large open-world AAA RPG.

Later in the run: XP must reflect learning, so achievements pay money, skill points or items and never XP.

## Scope delivered

| Requirement | Where |
|---|---|
| The storyline and progression of the year | `data/year_one.json`, `autoload/year_calendar.gd`: two terms, six blocks, 28 story days, 41 events; title cards, sleep and the day summary, absences and make-up exams, the monthly stipend; summer after the last day. The Journal page tells the year block by block |
| Other lectures | Twelve new lectures (`education/lectures/`) in Hall A and Hall B, with figures drawn from data (`ui/figure_art.gd`) |
| Exams | Six block exams and the anatomy practical in the Testing Center and the anatomy lab (`ui/exam_panel.gd`): timed, answers changeable until submitted, Pass or Honors, merit awards; the end-of-year OSCE |
| More Anki flashcards | Every bank question (276) becomes a card on the day it's taught, including the labs', encounters' and exams' own questions; a club's questions for its members |
| Clinical rotations | Clinical Immersion shifts in the Emergency Department, a family medicine clinic and on 4 West; standardized patients (a cough, a knee, chest pain, breathlessness, abdominal pain, sudden weakness) and the two-station OSCE in the Clinical Skills Center |
| Other things first-years do | Histology, ECG, spirometry and neuroanatomy labs; the anatomy lab; a small-group case; the White Coat Ceremony; the donor dedication; Research Day; the end-of-year celebration; the study group; a paid tutoring job; the gym |
| Clubs | Seven, joined at the Club Fair on the quad or the Office of Student Life (`data/clubs.gd`, `autoload/clubs.gd`, `ui/clubs/`): the Community Kitchen serving supper at the Harbor Street Community Center (the food-shelter example), the Student-Run Free Clinic, the Surgery and Emergency Medicine interest groups, Medical Spanish, Journal Club and intramural soccer, each with its own activity and reputation levels |
| More buildings and lecture halls, realistic layouts | The East Campus (`world/campus/east_campus.gd`) with the Medical Education Center (atrium, food court, Lecture Hall B, Testing Center, Clinical Skills Center, small-group rooms, labs), the Biomedical Library, the Student Center; Anatomy Hall; the Harbor Street Community Center by shuttle. Built on `world/interior/interior_scene.gd` with the hospital's kit, whole in first person and cut away overhead |
| A food court in the medical school | The Commons in the Medical Education Center: four vendors, tables, a lounge |
| A food court in the hospital | The Level 1 Food Court (`world/hospital/hospital_food_court.gd`): Grill 24, Fresh Market and Rounds Coffee, coolers, communal tables with seats, four-tops with diners, a window counter onto a garden; plus the lobby's Atrium Café counter |
| A library with PCs and laptop tables | The Biomedical Library's Computer Commons (the flashcard app) and laptop tables, group study rooms, the quiet floor and the Stacks Café |
| A meaningful level-up system | Levels grant skill points; perks (twenty, four branches) change XP in a context, pay, prices, energy, boosts and exam time; clothing unlocks by level |
| Expanded achievements and skill tree | 46 achievements in six categories (money, skill points or items; never XP); the Skills page |
| Boosts | Timed XP boosts from drinks, meals, sleep, workouts and the study group, one per slot, shown as HUD chips; energy |
| Currency | `autoload/wallet.gd`: the stipend, merit awards, tutoring pay and achievement rewards; food, drink, the Campus Store's clothing and study aids |

## Verification

Automated (headless, each run on its own; they share a test save slot):

**29 suites, 1,798 checks, 0 failures** on 2026-09-25: activities 103/0, food_court 21/0, student_life 101/0, east_campus 52/0, interior_clearance 15/0, curriculum 164/0, year 74/0, ed_clearance 8/0, emergency 68/0, hospital 108/0, foundation 54/0, academic 78/0, knowledge 18/0, flashcard 78/0, save 37/0, ui 64/0, progression 34/0, npc 37/0, ambient 30/0, campus 40/0, dorm 87/0, lecture 118/0, acceptance 47/0, first_person 58/0, seating 147/0, room_polish 27/0, wardrobe 74/0, visual_motion 23/0, cafe_exit 33/0. The save suite's two logged errors are its deliberate corrupt-file checks.

The first-year suites: `year` (money, boosts, skills, achievements, sleep, make-ups, the stipend, saves), `east_campus` and `student_life` (the district, shuttle, library, Medical Education Center, Student Center, Community Center, clubs across a week and Anatomy Hall), `interior_clearance` (the new buildings' walkers), `curriculum` (every lecture validates and plays on its day), `activities` (every activity validates and has its station; eleven played through in date order into summer) and `food_court`.

Graphical: captures of the hospital Food Court (overhead; first person toward the dining room, the coolers and the servery; the windows onto the garden) and the lobby's Food Court doors in both views; activity panels with figures (a micrograph, an ECG strip, spirometry curves), a history board, the year-end recap and the summer day summary. The other new buildings were captured when they were built (see the CHANGELOG).

## Limitations

See `KNOWN_ISSUES.md`, *The first year*. In short: the year is 28 story days rather than every day; activities play in a dialog at their station rather than as staged scenes; failed exams have no retake; the Outpatient Clinics remain a closed door; research shifts, classmates' friendships and side quests weren't built; balance is untested over a full year of play; and every medical item awaits human review.

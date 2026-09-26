# The First Year — expansion plan and status

Run document for the user's request of 2026-09-24:
> Finish the rest of the game: the storyline and progression for the first-year medical student. It should include:
> - other lectures, exams, more Anki flashcards and clinical rotations;
> - more buildings and other things first-years take part in;
> - student clubs (school or medicine related; for example, serving food at a food shelter);
> - a complete campus with more buildings and lecture halls, where lecture rooms, lobbies and hallways are laid out realistically, like actual medical centers;
> - food courts in the hospital and the medical school;
> - a library where the player can study at the PCs or sit down with their laptop;
> - a meaningful level-up system with an expanded achievement and skill tree, boostables (such as XP boosts) and a currency system.
>
> Grandiose but accurate content, with the feel of a large open-world RPG AAA game.

This request overrides the spec's v0.1 out-of-scope list: economy, the full achievement tree, the full M1 curriculum, patients and wards. The spec's principles still bind:
- real learning drives progression, with no meaningless grinding;
- content is original, with no copied question-bank material;
- no live AI;
- every medical item is flagged in `MEDICAL_CONTENT_REVIEW.md` until a human reviews it;
- the Minecraft-style characters, compact HUD and both camera views stay.

## Design

### The year and its days
- **The calendar.** The Fall term runs Mon 21 Sep – Fri 18 Dec 2026, and the Spring term Mon 4 Jan – Fri 28 May 2027. Day 1 of a new game stays Monday 21 September at 7:35: the first day of classes, Pharmacodynamics at 8:00 and shadowing at 9:00, so everything already built and tested keeps working. Orientation week has already happened.
- **Story days.** The year is a sequence of *story days*, each playable morning to night, with a title, scheduled events and optional activities (`data/year_one.json`). Sleeping in your bed ends the day. A day summary follows (XP, money, achievements, what happened in the days skipped), then the next story day begins. The existing single-day events move into the story-day data.
- **Time slots.** Each day has a morning, afternoon and evening. Scheduled events (lectures, labs, exams, clinical sessions, club meetings) sit at fixed times. Free time is spent on activities (a library study session, a club event, a tutoring shift, the gym); each runs its real content and then moves the clock to its end. Walking runs at the usual 5× clock. You can wait for the next event.
- **Attendance.** It is recorded for every mandatory event (late: −5 XP, as now). An unattended mandatory event is marked absent when you sleep, and a missed exam gets a make-up the next story day, so the year can never deadlock.

### Money, boosts, levels, skills, achievements
- **Money.** A dollar balance. Income:
  - a monthly living-stipend disbursement from financial aid;
  - merit awards for exam results;
  - a paid tutoring job, which pays for questions answered correctly in the subject;
  - research assistant shifts;
  - achievement rewards.

  Spending: food and drink, the student store (scrubs, clothing, a stethoscope, study resources), and the gym.
- **Boosts.** Timed effects from food and drink, study groups, sleep and exercise, shown as small HUD icons with timers:
  - food: +XP% for a while;
  - drink: +XP% or energy;
  - "Well-rested";
  - "Study group".

  They multiply XP earned from learning (answers, flashcards, clinical scores) only.
- **Energy.** Energy (0–100) is spent by activities and restored by sleep, food and rest. At low energy, activities give less XP. This limits grinding and makes food meaningful.
- **Levels.** The escalating curve stays, tuned so a thorough first year reaches about level 20–25. Each level grants a skill point, and levels unlock ranks and titles, clothing and store stock.
- **Skill tree.** Four branches of about five perks each, with ranks. Perks make play better without doing the learning for you (no auto-answers):
  - **Scholar:** lectures, flashcards and exams.
  - **Clinician:** patient encounters and shadowing.
  - **Wellbeing:** energy and boosts.
  - **Leadership:** clubs and money.
- **Achievements.** A data-driven catalogue (about 40) in categories: Academic, Clinical, Community, Explorer and Wellbeing. They fire from game events and reward XP, money, skill points or clothing, and they replace the placeholder page.

### The campus
The campus keeps its core (the quad, Cedar Residence, the Learning Center and Hall A, the café pavilion, the hospital across the street) and grows. A new district (built east of the quad; see *Status*) is laid out like a real academic medical center, and new interiors are built with the hospital's kit, working in both views:
- **Medical Education Center:**
  - a lobby with a food court (several vendors and seating);
  - Lecture Hall B;
  - small-group (PBL) rooms;
  - the Testing Center for block exams;
  - the Clinical Skills and Simulation Center (standardized-patient rooms).
- **Biomedical Library:** a reading room with PC stations (the existing computer and Anki system), laptop tables, group study rooms, stacks and a reference desk.
- **Anatomy Hall:** the gross anatomy lab (covered donors, treated respectfully), models and the practical stations.
- **Student Center:** the student store, club rooms, the club fair and a lounge.
- **University Hospital:**
  - a food court on Level 1;
  - the Outpatient Clinics behind the atrium's existing door (Family Medicine).
- **Harbor Street Community Center**, off campus by the campus shuttle: the Community Kitchen (food shelter) and the Student-Run Free Clinic.
- **Getting around:** a campus shuttle with stops (fast travel with a short time cost), and the map and directory updated.

### Curriculum (original content, all flagged for review)
Six blocks run through the year. Each block has lectures in the existing lecture engine, with new data-driven diagram types (curves, flow, table, cycle, bars), plus a lab, a clinical-skills encounter and a block exam in the Testing Center:

| Block | Lectures | Lab / workshop | Clinical |
|---|---|---|---|
| 1 Foundations (Sep–Oct) | Pharmacodynamics (existing), Pharmacokinetics, Enzymes & Metabolism | Histology lab | Shadowing (existing); history-taking SP |
| 2 Musculoskeletal & Anatomy (Nov–Dec) | Upper Limb & Brachial Plexus, Muscle & Bone | Anatomy lab and practical; donor ceremony | MSK exam SP |
| 3 Cardiovascular (Jan–Feb) | The Cardiac Cycle, Blood Pressure & Antihypertensives | ECG lab | Chest pain SP; ED immersion |
| 4 Pulmonary & Renal (Feb–Mar) | Respiratory Mechanics & Gas Exchange, Renal Physiology & Diuretics | Spirometry lab | Dyspnea SP; clinic immersion |
| 5 Endocrine & GI (Mar–Apr) | Diabetes & Glucose Regulation, GI Digestion & the Liver | Nutrition case | Abdominal pain SP; ward immersion |
| 6 Brain & Behavior (May) | Motor Pathways (UMN/LMN), Stroke | Neuroanatomy lab | Neuro SP; end-of-year OSCE |

Other parts of the year:
- **Flashcards:** every new bank question becomes a card automatically. Curated fact decks are added per block.
- **Exams:** a timed exam UI with a results screen (score, Pass/Fail with Honors at ≥ 90%, a discipline breakdown and merit awards). The anatomy practical uses figure-based questions.
- **Standardized-patient encounters:** data-driven histories (question categories, checklist scoring, communication, exam maneuvers with findings), then the diagnosis and next step, with feedback.
- **Clinical Immersion:** first-year observerships on the shadowing engine, in the Emergency Department, on 4 West and in the Family Medicine clinic.
- **Story beats:** the White Coat Ceremony (Saturday of week 4), the donor dedication before anatomy lab, the Thanksgiving and winter breaks, the Research Day poster session in spring, and the end-of-year celebration.

### Clubs
You join at the Club Fair (week 1, Wednesday afternoon, on the quad). Each club meets on a weekday evening and has a reputation level (1–5), rewards (club shirt, perk points, achievements) and an original activity:

| Club | Activity |
|---|---|
| Community Kitchen Volunteers | Serve meals at the food shelter, matching trays to requests against the clock; conversations about food insecurity and social determinants of health |
| Student-Run Free Clinic | Vitals and screening questions for free-clinic patients |
| Surgery Interest Group | Suturing workshop (a timing and precision mini-game) |
| Emergency Medicine Interest Group | CPR and "Stop the Bleed" skills night (compression-rhythm timing at 100–120/min) |
| Medical Spanish | Clinical phrase practice |
| Journal Club | Critical appraisal of original, fictional abstracts |
| Intramural Sports | Wellbeing (energy and boosts) |

## Phases and status
Each phase keeps every existing test passing and adds its own. Each ends with graphical captures (both views) and doc updates.

1. **Systems:**
   - the year calendar and story days, sleep and the day summary, time slots and waiting;
   - money and the wallet;
   - boosts and energy;
   - the skill tree, achievements, ranks and titles;
   - save version 2, migrating version 1;
   - HUD (money, energy, boosts, toasts) and menu pages (Journal, Skills, Achievements, Wallet).
2. **World:** the campus north district, the shuttle, and the interior base; the Biomedical Library, Medical Education Center (food court, Hall B, Testing Center, Simulation Center, small groups), Anatomy Hall, Student Center, hospital food court and clinic, and Community Center.
3. **Curriculum:** lectures and generic diagrams, exams and the Testing Center, labs and practicals, standardized-patient encounters and the OSCE, Clinical Immersion, flashcard decks and story beats.
4. **Clubs and side content:** the club fair, clubs and their activities, the tutoring job, research shifts, classmates and friendships, and side quests.
5. **Polish:** chapter title cards, results screens, lighting through the day, ambient crowds, audio, performance and documentation.

Status is recorded in `CHANGELOG.md` (repository root) as each phase lands.

## Status (September 25, 2026)

All five phases have landed; the whole first year is playable from the first day of classes to the end-of-year celebration, then summer. Details are in the `CHANGELOG.md` entry of 2026-09-25, limitations in `KNOWN_ISSUES.md`, and tests in `tests/` (year, student_life, east_campus, interior_clearance, curriculum, activities, food_court).

**Built as planned:** the calendar and 28 story days; sleep, the day summary and title cards; money, boosts and energy; the skill tree (four branches, twenty perks) and 46 achievements; save data for all of it; the Medical Education Center (Commons food court, Hall B, Testing Center, Clinical Skills Center, small-group rooms, histology and skills labs), the Biomedical Library, Anatomy Hall, the Student Center, the hospital Food Court and the Harbor Street Community Center; the campus shuttle and map; twelve new lectures with data-drawn figures; 27 activities (five labs and the anatomy practical, seven encounters including the OSCE, three immersion shifts, the nutrition case, Research Day, three ceremonies and six block exams); the seven clubs with their activities, the Club Fair and the Thanksgiving meal; tutoring, the study group, the gym and the store.

**Differences from the plan:**
- The new district is **east** of the quad (the Health Sciences Walk and the East Green), not north. Anatomy Hall sits north-west of the quad.
- Achievements pay money, skill points or items, **never XP** (a later instruction from the user: XP must reflect learning).
- The Outpatient Clinics are still a closed door; the Family Medicine immersion starts there and plays in the activity panel.
- Activities run in panels at their stations rather than as staged scenes (see `KNOWN_ISSUES.md`).
- Flashcards come from every bank question (lectures, activities, exams and your clubs' questions) on the day they're taught; there are no separate curated fact decks.
- Not built: research-assistant shifts, classmates with friendships, and side quests. Audio is still the placeholder set; indoor lighting doesn't follow the clock.


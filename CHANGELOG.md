# CHANGELOG — Medical School RPG handoff

**Recorded: 2026-09-23 05:03 PDT (2026-09-23 12:03 UTC).** This is a living Markdown handoff file. Add new change sets at the top, each with its own date and time. Times for the earlier milestone work were not recorded; their implementation dates come from the former `src/docs/development/CHANGELOG.md`, which was merged into this file during the Milestones 4–6 cleanup commit and must not be mistaken for exact timestamps.

**Project:** Godot 4.7.2, Compatibility renderer. Open `src/project.godot`. The authoritative product requirements are in `src/docs/design/medical_school_rpg_spec.md` (also snapshotted as `src/PROJECT_SPEC.md`). Run-specific instructions live in `src/docs/prompts/` and `src/docs/development/`. User instructions in the current task take precedence over this handoff.

**Current state:** Milestones 1–10 are complete: the v0.1 vertical slice is feature-complete per the spec. Milestone 11 (University Hospital, physician shadowing) and the Emergency Department are implemented and committed (`bf38912`, `56202a0`). The first-year expansion (the whole first year as story days, money, skills and achievements, the East Campus buildings and the hospital Food Court, clubs and the full M1 curriculum) is implemented, committed and pushed (see the 2026-09-25 entry). Remaining work is human medical review and any new scope from the user.

## 2026-09-25 13:07 PDT — The first year: story days, money and skills, the East Campus, clubs and the whole M1 curriculum

User request (2026-09-24, after the Emergency Department):
- Finish the rest of the game: the storyline and progression for a first-year medical student, with other lectures, exams, more Anki flashcards, clinical rotations, more buildings and the other things first-years take part in.
- Student-run clubs the player can join (school, medicine or other; for example, serving food at a food shelter).
- Complete the campus with more buildings and lecture halls, with lecture rooms, lobbies and hallways laid out the way real medical centers are; food courts in the hospital and the medical school; a library where the player can study at the PCs or sit down with a laptop.
- A meaningful level-up system, an expanded achievement and skill tree, boosts (such as XP boosts) and a currency.
- Grandiose but accurate, with the feel of a large open-world AAA RPG.

A later instruction in the run: XP must reflect learning, so achievements pay money, skill points or items and never XP.

Committed and pushed at the user's request (2026-09-25 18:43 PDT). The plan, the design and the status are in `src/docs/development/YEAR_ONE_PLAN.md`; limitations in `KNOWN_ISSUES.md`; every new medical item in `MEDICAL_CONTENT_REVIEW.md`.

**The year** (`autoload/year_calendar.gd`, `data/year_one.json`).
- Two terms, six blocks and 28 story days, from Monday 21 September 2026 to Friday 28 May 2027, with 41 events (lectures, labs, encounters, immersion shifts, ceremonies, exams, the Club Fair, the Thanksgiving meal, Research Day and the celebration). Every day is ready to play.
- Each day opens with a title card (`ui/day_card.gd`). Sleeping from 6 PM ends it (`ui/sleep_panel.gd` warns about missed classes): absences are recorded, a missed exam gets a 1 PM make-up on the next story day, and the day summary (`ui/day_summary.gd`) shows XP, questions, flashcards, money, achievements and events before the next story day's 7:30. After 2 AM you fall asleep where you stand. The monthly financial-aid disbursement arrives on the first story day of a month.
- After the last day, each night leads to a free summer morning.

**Money, energy, boosts, skills and achievements.**
- `Wallet` (cents): the stipend, merit awards, tutoring pay and achievement rewards in; food, drink, the Campus Store's clothing and study aids out. The HUD's money and energy card shows the balance, energy and boost chips (`ui/life_hud.gd`); toasts announce pay, boosts, achievements and skill points (`ui/toast_stack.gd`).
- `Wellbeing`: energy spent by activities and restored by food, rest and sleep, and timed XP boosts from drink, meals, sleep, workouts and the study group. They multiply learning XP only; low energy reduces it.
- `Skills`: a point per level gained and from achievements; four branches (Scholar, Clinician, Wellbeing, Leadership) of twenty perks that raise XP in a context, pay, discounts, energy, boost length or exam time, and never answer for you.
- `Achievements`: 46 in six categories, from stats and moments across the game, paying money, skill points or clothing.
- Menu pages: Journal (today's chapter and the year, block by block), Skills, Wallet & Wellbeing, and a working Achievements page.
- Saves keep all of it in a `life` section; older saves load with starting values.

**The campus** (`world/campus/east_campus.gd`, `world/interior/`).
- The East Campus district along the Health Sciences Walk and the East Green, laid out like an academic medical center's teaching blocks; Anatomy Hall north-west of the quad; a campus shuttle between four stops, including the Harbor Street Community Center off campus; the map and directory updated.
- The new interiors share `interior_scene.gd` (zones built by static builders into the hospital's kit, working in both views):
  - **Medical Education Center:** the atrium and welcome desk, the Commons food court (four vendors), Lecture Hall B, the Testing Center, the student lounge; upstairs, the Clinical Skills & Simulation Center, small-group rooms, the histology lab and the skills lab.
  - **Biomedical Library:** the Computer Commons (PCs with the flashcard app), laptop tables, group study rooms and the Stacks Café; the quiet floor with the reading room, carrels, stacks and a history-of-medicine exhibit. The class study group meets in Room 2.
  - **Student Center:** the Office of Student Life, the Campus Store, the lounge, the juice bar, Peer Tutoring (a paid shift); upstairs, the Fitness Center and the club rooms.
  - **Anatomy Hall:** the donor memorial, the old anatomical theatre and, below, the Gross Anatomy Laboratory (PPE room, model room, your group's table), open from the donor dedication.
  - **Harbor Street Community Center:** the dining room and serving line, the client-choice pantry and the free clinic.
- **University Hospital's Food Court** (`world/hospital/hospital_food_court.gd`, today): glass doors off the corridor to the Outpatient Clinics lead to a fifth zone of the hospital scene, with Grill 24, Fresh Market and Rounds Coffee along the servery, drinks coolers and a condiment station, communal tables you can sit at (with the laptop), four-tops full of staff and visitors, a window counter onto a courtyard garden, and two passers-by. The lobby's Atrium Café is now a real counter. Overhead, the rest of the building around the lobby's corridors is drawn as cut mass, and the lobby camera follows into the clinics corridor.

**Clubs** (`data/clubs.gd`, `autoload/clubs.gd`, `ui/clubs/`). Join up to three at the Club Fair on the quad or the Office of Student Life. Each meets on its own days, has an original activity and builds reputation (a shirt at level 2, a skill point at 3, Club Officer at 5):
- Community Kitchen Volunteers: serving supper on Harbor Street, matching each guest's request against the clock (and the Thanksgiving meal, open to everyone);
- Student-Run Free Clinic: manual blood pressures;
- Surgery Interest Group: a suturing workshop;
- Emergency Medicine Interest Group: CPR at 100–120 a minute;
- Medical Spanish and Journal Club: phrase practice and fictional abstracts, with questions;
- Intramural soccer on the lawn.

**The curriculum.**
- **Lectures:** twelve new ones (Pharmacokinetics; Enzymes & Metabolism; the Upper Limb; Muscle & Bone; the Cardiac Cycle; Blood Pressure; Respiratory Mechanics; Renal Physiology; Diabetes; Digestion & the Liver; Motor Pathways; Stroke) in Hall A or Hall B, taught by ten faculty, each with narration, figures drawn from data and a question bank.
- **Figures** (`ui/figure_art.gd`): curves sampled from named functions, flow diagrams, tables, cycles and bars, H&E micrographs of eleven tissues and ECG rhythm strips, all drawn in code.
- **Activities** (`education/activities/`, 27, played at stations with `ui/activity_panel.gd` and `ui/exam_panel.gd`):
  - labs: histology, the anatomy lab, ECG, spirometry, neuroanatomy;
  - standardized patients: a cough, a knee, chest pain, breathlessness (heart failure), abdominal pain (appendicitis), sudden weakness (stroke), and the two-station OSCE, each with a history board, an examination board, communication choices and debrief questions;
  - Clinical Immersion: an evening in the Emergency Department, an afternoon of family medicine, rounds on 4 West;
  - a small-group nutrition case on diabetes and food insecurity; Research Day's posters (biostatistics);
  - the White Coat Ceremony (the coat is given and worn), the donor dedication, and the end-of-year celebration with your year in numbers;
  - six block exams and the anatomy practical: timed, answers changeable until submitted, Pass or Honors and merit awards.
- **Questions and flashcards:** the bank grows to 276 questions in per-topic files. Every bank question becomes a flashcard on the day it's taught; a club's questions only for its members.
- **Around the edges:** the study group (a boost), the tutoring shift (paid by questions answered correctly), the gym (an Endorphins boost), the lounge's breaks.

**Fixes found while testing this entry.**
- `ui/activity_panel.gd` didn't compile (a type-inference error), so no station could open an activity and the campus scene script failed to load in that state; found by the new activities test.
- The end-of-year night left the clock stuck; it now rolls into summer mornings, and summer days aren't counted as story days.
- An exam's and the OSCE's failure texts promised a remediation exam and retakes that don't exist; they now say what actually happens.
- The east campus test walked into the library's and Medical Education Center's passers-by; it now parks them, as the student-life test does.
- A Community Kitchen guest shared the attending's surname, and the library's anesthesia plaque named a real hospital; both changed.
- Older suites assumed the earlier content: the hospital test counted four floors, and the knowledge test two disciplines and the lecture's nine Pharmacodynamics subtopics (the Block 1 exam adds Partial agonists). They now read these from the scene and the bank.
- Calendar details: the ECG and spirometry labs are in the Skills Lab (the spirometry lab reads volume–time curves, not flow–volume loops), the nutrition case is in Room 202 where its station is, and the stroke encounter is titled for what it is.

**Tests.** New: `tests/activities_test.gd` (every activity validates, every activity event has its content and a station in its room, and eleven activities are played through in date order into summer) and `tests/food_court_test.gd` (the doors both ways, ordering, a seat and the laptop, the diners' loop against the furniture, both views). Earlier in the run: `year_test.gd`, `east_campus_test.gd`, `student_life_test.gd`, `interior_clearance_test.gd`, `curriculum_test.gd`. The full regression, one suite at a time: **29 suites, 1,798 checks, 0 failures** (activities 103/0, food_court 21/0, student_life 101/0, east_campus 52/0, interior_clearance 15/0, curriculum 164/0, year 74/0, ed_clearance 8/0, emergency 68/0, hospital 108/0, foundation 54/0, academic 78/0, knowledge 18/0, flashcard 78/0, save 37/0, ui 64/0, progression 34/0, npc 37/0, ambient 30/0, campus 40/0, dorm 87/0, lecture 118/0, acceptance 47/0, first_person 58/0, seating 147/0, room_polish 27/0, wardrobe 74/0, visual_motion 23/0, cafe_exit 33/0). The save suite's two logged errors are its deliberate corrupt-file checks.

**Graphical checks:** the Food Court overhead and in first person (the servery, the dining room, the coolers, the windows onto the garden) and the lobby-side doors in both views; activity panels with their figures (a micrograph at the histology lab, an inferior STEMI strip at the ECG lab, the three spirometry curves), a patient's history board, the year-end recap and the summer day summary.

Commands (from `src`):
```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/activities_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/food_court_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 --script res://tests/food_court_test.gd -- --capture-dir=/absolute/existing/directory
```

## 2026-09-24 12:17 PDT — Emergency Department: Level I trauma center, Emergency Radiology and the campus ambulance

User request, after Milestone 11 was committed and pushed (`bf38912`):
- Add an emergency department to the hospital, a Level 1 trauma center similar to Northwestern Memorial's in Chicago. Seven photos were supplied: the ambulance entrance, the EMERGENCY pylon, the garage, the porte-cochère, an ED room, a station and a "Pods" station.
- It needs an ambulance outside and should feel very alive: patients arriving on stretchers pushed by EMTs, and the ER's double doors opening.
- An ambulance should drive in and out of the ER driveway about every 5 real minutes.
- Areas of care should be organised by how critical patients are (levels 1–5), using the labels Northwestern actually uses.
- A second floor with MRI, CT and other imaging.
- Security at the entrance, automatic sliding doors inside the ER, a medication/supply room, computers, TV screens with patient vitals and bay numbers, and anything else that makes it realistic.
- Mid-task: "Make sure the automatic sliding doors are functional too."

Not committed.

**Acuity scale (researched).**
- **What the sources say:** Northwestern's public pages don't name a triage scale. The US standard is the five-level Emergency Severity Index (ESI), and ESI version 3 was validated at Northwestern's Division of Emergency Medicine (Tanabe et al., *J Emerg Nurs*, 2004).
- **The numbering:** in ESI, **Level 1 is the most critical** (1 Resuscitation, 2 Emergent, 3 Urgent, 4 Less urgent, 5 Non-urgent). That is the reverse of the numbering in the request; the game uses the real convention.
- **Northwestern's own areas:**
  - a Level I trauma and stroke center with about 100,000 visits a year and a "trauma half" of the department;
  - a **Super Track** split-flow for low-complexity patients;
  - a 15-bed **Boarder Care Unit**.
- **Branding:** none of Northwestern's or the Chicago Fire Department's names or logos are used.

**Campus** (`buildings.gd` `_emergency_front()`, `campus.gd`, `npc/ambient/ems_arrivals.gd`).
- **The emergency front:** the hospital's south face gets a back street, a red-walled AMBULANCE ONLY bay with automatic doors, a red EMERGENCY canopy over the walk-in doors, and a red pylon. The plaza walkway continues along the building to the ED sidewalk; bounds close the street.
- **Getting in:** "Enter the Emergency Department" leads to the ED (campus entry `ed`, and `AppState.hospital_entry`, which saves). The map marks the ED entrance.
- **The ambulance cycle:** every 300 s (first after 25 s), an ambulance drives down the street with its lights on and backs into the bay, rear to the doors. The crew wheels the patient in, comes back 90 s later with the empty cot, and it leaves. It brakes for the student, and a second ambulance stays parked in the bay.

**The Emergency Department** (`world/hospital/hospital_ed.gd`, a fourth zone of the hospital scene at x −140).
- **Areas by ESI:**
  - **Trauma & Resuscitation · ESI 1:** T1 & T2 in one room with an active trauma team, plus T3 and T4, by the ambulance entrance.
  - **Acute Care · ESI 2–3:** Rooms 1–12 around the central station.
  - **Super Track · ESI 4–5:** five recliners by the waiting room.
- **Walk-in:** two sets of automatic doors, a metal detector, bag table and two guards, registration, three triage bays, a 24-seat waiting room, vending machines, a check-in kiosk and an ESI information board.
- **EMS:** a vestibule with two sets of automatic doors to the ambulance garage (with a parked ambulance) and EMS check-in.
- **Support:** a medication room behind a badge-reader door (dispensing cabinets, fridge), clean supply, decontamination, results waiting, physician workstations, doors to the Boarder Care Unit and the atrium link.
- **Doors that work:** every room and trauma bay has a glass front with automatic sliding doors that open for whoever steps up (student, crews, patients, transport) and stay shut as people pass along the corridor. Room 11 is locked while being cleaned. Shut doors are solid.
- **Displays:**
  - tracking boards (bed, ESI, initials, complaint, RN/MD, status, time);
  - the trauma board (EMS inbound with a live ETA, and the trauma bays);
  - waiting-room screens;
  - bedside monitors in all 16 bays with live, drifting fictional vitals and traces.

**Emergency Radiology, Level 2** (`hospital_imaging.gd`).
- **Rooms:** CT 1 and CT 2 with lead-glass control rooms, the MRI suite (Zones III and IV, RF door, ferromagnetic posts), X-ray, holding, a dim reading room, ultrasound and MRI screening.
- **Moving parts:** scanner tables slide patients in and out, and a stretcher transport arrives from the elevator.

**Life** (`world/hospital/ed_life.gd`).
- **EMS:** a unit every 2–2.7 min: dispatch, ETA on the board, the ambulance in the garage, the crew wheeling the patient through both door sets to a bay, a handover to the bed and boards, the empty cot backed out, and the ambulance leaving.
- **Walk-ins:** through security and registration to a seat.
- **Triage calls:** waiting patients called through to Super Track.
- **Discharges:** patients walk home by the exit lane beside the arch.
- **Transport:** a wheelchair transport to radiology via the ED's second, out-of-service elevator car.
- **Staff:** six walking the department.

**New pieces.**
- `ambulance.gd` (a Type III box ambulance that drives, reverses and brakes), `cart_crew.gd`, `route_walker.gd`, `ems_arrivals.gd`.
- `ui/ed_display.gd`, `ui/vitals_atlas.gd` and `ui/radiology_images.gd`.
- `sliding_doors.gd` gains `auto_group`, `auto_depth`, `locked` and `frame_color`.
- MeshKit gains a `clear` glass kind.

**Motion and clipping pass.** Scripted walkers and carts move without physics. The new `tests/ed_clearance_test.gd` sweeps every route against every box of both floors and the standing figures, and writing it found and fixed these:
- **EMS cot and crew:** the second EMT walked beside the cot, too wide for the doors and into walls. They now guide from the foot end, in line.
- **Leaving a bay:** the cot spun on the spot between the bed and the wall. It now backs out and turns in the corridor.
- **Hidden transport:** a transport "upstairs" was invisible but still solid in front of the elevator.
- **Room layout:** the portable X-ray blocked the Trauma 1 & 2 doorway. Room 12's door sat at the corridor's dead end.
- **Arch and kiosk:** discharged patients clipped the arch post, and walk-ins cut through the kiosk screen. The arch was narrower than the figures' arm span.
- **Staff shortcuts:** staff cut across the station's counter corners.
- **Recliners:** the leg rests and deep cushions went through seated shins. They are now upright with the leg rest folded.
- **Trauma board:** it poked through into the medication room.
- **Red panel:** a red wall panel covered the ambulance doorway.
- **Elevators:** out-of-service elevator doors were walk-through. This is fixed in `Props.elevator_frame`, so 4 West's decorative car is fixed too.

**Also:**
- **Sitting:** walkers now sit down and stand up with the rig's sit blend (turn, step back to the seat edge, lower), approaching seats along the row aisles.
- **Giving way:** staff pedestrians step aside for crews, transports and walking patients as they do for the student.
- **Campus crew:** the campus crew disappears fully behind the bay doors.

**Tests.**
- **New:** `tests/emergency_test.gd`, 68 checks, 0 failures. It covers the campus ambulance, every set of doors walked for real, an EMS arrival to departure, walk-ins, radiology by elevator, first person, the atrium link, saving and leaving. `tests/ed_clearance_test.gd`, 8 checks, 0 failures.
- **Updated:**
  - `hospital_test` expects 4 zones, and the plaza's far edge is now the street behind the hospital;
  - `campus.ed_pedestrians` keeps the quad's `pedestrians` list unchanged.
- **Regression:** all other suites pass. `ambient_test`'s dog-walker wander check failed once in four runs today, passes on rerun and uses unchanged code: a pre-existing intermittent check.
- **Graphical:** captures in both views, plus zoomed close-ups of crews, doors, the handover, backing out and sitting.

**Docs.**
- New: `src/docs/development/EMERGENCY_DEPARTMENT_ACCEPTANCE.md`.
- Updated: `ARCHITECTURE.md`, `KNOWN_ISSUES.md` (ED limitations), `MEDICAL_CONTENT_REVIEW.md` (all ED text, the ESI wording, and the fictional board and vitals data await review), `src/README.md`, `CLAUDE.md`, `AGENTS.md` and `PROJECT_HANDOFF.md`.

## 2026-09-24 06:51 PDT — Milestone 11: University Hospital and physician shadowing

User request (Milestone 11 run):
- Build a big, modern, realistic academic hospital across the street from the parking lot and the quad (about the size of the two context blocks combined).
- The hospital needs these spaces:
  - exterior arrival;
  - lobby/atrium;
  - security, reception and information;
  - elevators and a waiting zone;
  - a main corridor and a nurses station;
  - a physician workroom;
  - 2–3 patient rooms;
  - a support/orientation area;
  - inaccessible corridors that imply more of the building.
- Make it navigable in both camera modes.
- Build a guided shadowing flow: arrive, meet the physician, orientation, follow, logistics, workflow and rounds, etiquette, complete. It needs wayfinding, signage and objectives; physician meet/follow/dialogue; etiquette moments; and a lightweight EHR introduction.
- Out of scope: patient history, examination or diagnosis gameplay; full clinicals; a full EHR; multi-floor simulation; branching; procedural generation. Reuse existing systems, add targeted tests, and update the docs.

Committed and pushed at the user's request (2026-09-24 07:25 PDT). The previous round (computers and Anki) was committed and pushed as `2dca803` before this work; its entry below still says "Not committed".

**Scope note.** The spec lists hospital wards and patients as outside v0.1. This run's explicit request overrides that. Patients are observed scenery only: no patient interaction, history, examination or diagnosis.

**Getting there** (`world/campus/buildings.gd` `hospital()`, `campus.gd`, `data/campus_config.gd`).
- **The building:** it stands across the street, replacing the two grey context blocks. A 56 × 26 m two-storey podium (glass, white spandrels and fins) carries an inpatient tower set back from the street and capped near 28 m, so the overhead camera never loses the parking lot, the crossing or the plaza behind it. "UNIVERSITY HOSPITAL" appears on the street parapet, the canopy and the tower.
- **The entrance:** it faces east onto a drop-off plaza (the side the overhead camera sees): a glass pavilion with a real door assembly, a timber-soffit canopy over the drop-off lane, and a waiting car.
- **The way over:** the sidewalk continues east of the parking lot to a path, a zebra crossing and the plaza. A wayfinding pylon marks the turn. The street trees leave a gap at the crossing, and bounds open only there.
- **Camera and wayfinding:** the campus camera follows farther south (`CAMERA_MAX` z 46). The campus directory mentions the hospital. Campus entry `hospital` spawns at its door.

**Inside: two floors in one scene** (`world/hospital/`).
- **Level 1 atrium** (`hospital_lobby.gd`):
  - a 9 m glass front with automatic sliding doors, a skylight and a ring pendant over the curved Information desk (receptionist);
  - a security podium (guard), a directory totem, and a walnut elevator bank with a floor directory;
  - a carpeted lounge with armchairs, a curved sofa, seated visitors and indoor trees; the Atrium Café (barista) and a gift shop (closed until 10:00);
  - a mezzanine and grand stair (roped off, "Level 2 by elevator");
  - corridors that end at staff doors to the Emergency Department and the Outpatient Clinics;
  - three visitors strolling (the campus pedestrian, now with a per-scene path graph).
- **Level 4, 4 West Internal Medicine** (`hospital_unit.gd`):
  - an elevator lobby with a closed staff door;
  - a 36 m corridor with handrails and floor labels;
  - patient rooms 410–415: 412 has the rounds patient and resident, 413 is empty, 414 is under contact precautions, and the rest have patients behind drawn curtains. Each has a bathroom, headwall, monitor, window, chair and whiteboard;
  - the nurses station (charting desks, telemetry and census boards, slatted ceiling, mustard accent wall, nurses at work) with Priya, the charge nurse;
  - the team workroom (workstation island, the EHR workstation, the team board and a student orientation board), clean supply and a family lounge;
  - 4 East beyond closed double doors, with its corridor continuing.
- **How it is built:** a `HospitalKit` builds each floor for both views at once. The first-person layer has full-height walls, columns, ceilings, lights and high signs; the overhead layer has the same walls and columns cut to 1.05 m with a dark cap. One full-height collider set means both views walk the same building. Shared furniture is in `hospital_props.gd`.
- **Furniture fits the figures:** seats are low to suit the stylised figures, and the bed's head section is hinged so reclined patients lie on it without clipping.
- **Elevator:** a working car per floor. Call it (or use the panel inside), step in, and the doors close. A short fade later you step out upstairs, with the physician if she is riding along. It works freely once the session is over.
- **Per floor:** camera bounds and the HUD location line follow the floor you are on.

**Dr. Okafor and the session** (`npc/physician.gd`, `education/shadowing/`, `world/hospital/shadowing_session.gd`).
- **Script as data:** the session is a data script with 9 stops, validated like the lecture script. Its format is documented in `education/shadowing/README.md`.
- **The physician:**
  - she waits at the Information desk (before 9:00 with Pharmacodynamics still to attend, she sends you to class);
  - meeting her records attendance for the new mandatory 9:00 "Physician Shadowing" event, with the usual late penalty;
  - she walks her route and waits if you fall behind ("Stay with me."), says "Excuse me." if you block her, turns to you and gestures while talking. You hold still while she talks and turn to her.
- **Stops, in order:**
  - Welcome;
  - the elevators (a privacy check, then ride up together);
  - 4 West;
  - the nurses station (introduce yourself to Priya; the charge-nurse check);
  - the workroom EHR (close-up on the chart: banner, vitals, results, notes; chart-review and EHR-access checks);
  - room 412 (a hand-hygiene check, foam in at the dispenser, the observer-position check);
  - bedside rounds (stand on the marked spot at the foot of the bed; the resident presents; the attending asks the patient's consent and confirms the plan; foam out);
  - the isolation door (the contact-precautions check);
  - professional habits wrap-up.
- **Results:** the 7 etiquette checks are real bank questions (Clinical Skills / Hospital Orientation) with stable attempt ids. They award XP, appear in Knowledge, and become flashcards (bank decks are now per topic). Each stop's takeaway is added to Lecture Notes. A summary card closes the session.
- **The EHR** (`ui/ehr_chart.gd`): a small read-only chart for one fictional patient, drawn onto the workroom monitor. The camera eases in and frames it between the HUD and the dialogue card.

**Supporting changes.**
- **AppState:** a `HOSPITAL` phase, `enter_hospital()` and `WORLD_PHASES`.
- **SaveGame:** the `hospital` location.
- **Objectives:** after class they point to the hospital, then report the day complete.
- **HUD:** `set_location()`; the arrival message names the right event; the legendary-coat notice shows only for the first lecture.
- **Menus:** the map draws the street, the crossing and the hospital, with the next destination highlighted. The notes page shows shadowing takeaways.
- **Question bank:** loads multiple files atomically.
- **MeshKit:** `light` and `walnut` kinds.
- **World nameplate:** plate and text colours, and multi-line sizing.
- **First person:** `turn_toward()`.
- **Presets:** new staff and patient presets.

**Tests.**
- **New:** `tests/hospital_test.gd`, 108 checks, 0 failures. It covers the data; the walk across the street; the full session with real movement (following and lagging, the elevator, the charge nurse, the EHR, hand hygiene, the observer mark, 7 answers, the summary, notes, XP and Knowledge); first person on both floors; a free elevator ride; saving; and leaving.
- **Updated:** `academic_test` (the combined bank) and `knowledge_test` (the second discipline).
- **Regression:** all other suites pass.
- **Graphical:** captures in both views led to a muted palette, cutaway columns, walnut finishes, steel elevator doors and the EHR framing.

**Docs.**
- New: `src/docs/development/MILESTONE_11_ACCEPTANCE.md`.
- Updated: `ARCHITECTURE.md`, `KNOWN_ISSUES.md` (hospital limitations), `MEDICAL_CONTENT_REVIEW.md` (all shadowing content awaits human review), `src/README.md`, `CLAUDE.md`, `AGENTS.md` and `PROJECT_HANDOFF.md`.

## 2026-09-23 23:21 PDT — In-world computer screens, pixel-art wallpapers, rebuilt Windows/macOS shells and Anki UI

User request:
- Improve the Windows PC's lock and home screens, keeping the same images but pixelated to match the game and less blurry.
- Improve the UI of both the PC and the MacBook.
- Don't fill the whole screen when using a computer: zoom in a little so the surroundings stay visible, like using a computer in real life.
- Get familiar with the Codex changes (commit `93eb0b6`) and polish the Anki UI.

Not committed.

**Pixel-art wallpapers** (`assets/pixel_wallpaper.gdshader`).
- **Photos:** the two supplied 738×414 photos are now re-rendered as crisp pixel art rather than stretched (the cause of the blur). Each 320×180 cell averages the photo beneath it, colours snap to a small palette, and a light ordered dither keeps gradients smooth.
- **Desktop photo cleanup:** it was a screenshot, so the shader crops its baked-in taskbar and covers the baked-in desktop icons with nearby sky. The real taskbar and icons replace them.
- **Mac wallpaper:** pixelated to match (`macos_wallpaper.gdshader`).
- **Idle monitor:** shows the pixel lock photo (`assets/pixel_screen.gdshader`).

**The screen stays in the world** (`ui/computer/desktop.gd`, rebuilt).
- **Rendering:** the OS now renders into a SubViewport drawn on the device's own screen: a new `PCScreen` quad on the dorm monitor, and a 16:10 `Screen` quad on the laptop lid.
- **Camera:** it eases in (the generalised lecture camera, now able to start from any perspective or orthographic camera) to a point square to the screen and slightly above it. The screen fills about 60% of the view's height, leaving the desk, keyboard, window and room (or the café) visible around it. The player's head is hidden while zoomed in. Stepping away eases back out, and the laptop packs away only after that.
- **Input:** the mouse is ray-traced onto the screen quad and forwarded (clicks, drags, hover), and keys are forwarded. Nothing reaches the world.
- **Resolution:** the layout is 1024×576 (PC) and 1024×640 (Mac), rendered up to 2× sharper on large windows so text stays legible at the zoom.
- **HUD:** walking hints hide while the computer is in use, replaced by a small "Esc Step away" hint. A floating-panel fallback remains for callers without a world screen.
- **Hall A:** stays whole while zoomed in at a laptop. A lecture that starts while the laptop is open begins once the view returns (`LectureSession` now also handles `STARTING`).

**Windows 10–style shell.**
- **Lock screen:** the clock and date sit bottom-left. Any key or click opens sign-in.
- **Sign-in:** an avatar, the name, User name and Password fields with an attached → button, Windows' own error text, "Sign-in options", the account tile at bottom-left, and network, accessibility and power icons (power shuts down).
- **Desktop:**
  - Recycle Bin, This PC and Anki icons (single click selects, double click opens);
  - a real taskbar: Start, "Type here to search", Task View, File Explorer, Browser, and Anki with a running/active underline; the tray with Wi-Fi, volume and a two-line clock;
  - the Start menu: a rail with account/lock, Documents, Settings and Power; an A–Z app list; Study tiles.
- **Windows:** draggable, with minimise, maximise (or double-click the title bar) and a red-on-hover close (`ui/computer/os_window.gd`). File Explorer, the browser (offline), Settings and the Recycle Bin open small native windows.

**macOS-style shell.**
- **Lock/login:** the date and large clock at top, then avatar, name, Name and Password pills with an → button. A wrong password shakes the fields. Sleep, Restart and Shut Down.
- **Desktop:**
  - a menu bar with a pixel fruit menu (About This Mac, System Settings, Lock Screen, Log Out, Shut Down), the active app's name and its menus (Finder's, or Anki's File/Edit/View/Tools/Help), battery, Wi-Fi, search and the clock;
  - a translucent Dock: Finder, Launchpad, Safari, Notes, Anki, System Settings and Trash. Icons grow on hover and show their names; running apps get a dot.
- **Windows:** traffic lights with hover glyphs.

**Icons and fonts** (`ui/computer/os_kit.gd`).
- **Icons:** all app and tray icons are original 16×16 pixel art, nearest-filtered, matching the game.
- **Fonts:** the OS uses the host's system UI font when installed (Segoe UI / San Francisco), otherwise Helvetica or Arial. Card text uses Arial, like Anki's default card style.

**Anki, rebuilt to look and behave like desktop Anki** (`ui/computer/anki_app.gd`). It uses the same collection, scheduler and XP as Codex's version.
- **Toolbar:** Decks · Add · Browse · Stats · Sync; Sync explains the collection is offline.
- **Deck list:** a collapsible tree (Medicine › Pharmacology › Pharmacodynamics, Personal) with New/Learn/Due columns in blue, red and green (zeros greyed), a gear per deck (Options), "Studied N cards today", today's study XP, and Get Shared / Create Deck / Import File.
- **Overview:** New / Learning / To Review counts, Study Now (S or Enter), description, and Options / Custom Study / Description.
- **Reviewer:**
  - the card centred in Arial;
  - the answer under a rule, with the explanation and source below;
  - a bottom bar with Edit, the remaining counts (the current queue underlined), Show Answer, and More (Bury -, Suspend @, Edit E);
  - after reveal, Again / Hard / Good / Easy with Anki-format intervals above them (<1m, <6m, <10m, 4d).
- **Toasts:** "+2 XP", "Card buried.", and the leech notice.
- **Finished deck:** "Congratulations! You have finished this deck for now." with when the next card is due.
- **Add:** Type (Basic/Cloze), Deck, a […] Cloze button that wraps the selection in the next cloze number, Front/Back/Extra fields (Text/Back Extra for Cloze) and Tags. Ctrl/⌘+Enter or Add saves. As in Anki, the window stays open for the next note ("Added."); editing returns to Browse.
- **Browse:**
  - sidebar filters: Whole Collection, Due Today, card states, decks, tags;
  - a search box that understands `is:new/learn/review/due/suspended`, `deck:"…"`, `tag:…` and free words;
  - a table (Sort Field, Card, Due, Deck, Reviews) with selection;
  - a preview pane with Suspend/Unsuspend and Edit Note or Card Info.
- **Stats:** Today (studied, again count, learn/review/relearn), Future Due (30 days), Card Counts (New, Learning, Young, Mature, Suspended), Answer Buttons and Reviews (30 days), with "No data" when empty.
- **Deck Options:** Daily Limits (editable new cards/day), New Cards, Lapses and Advanced, showing the scheduler's actual settings; Save.

**Tests:** `flashcard_test.gd` now has 78 checks. New checks:
- the lock photo is pixel art;
- the OS draws onto the monitor, not over the view;
- the camera moves in and the screen fills 45–80% of the view's height with the room visible;
- a real mouse click on the monitor in the world reaches the lock screen.

The Add expectation now follows Anki: the window stays open after adding.

**Fixed in Codex's commit (`93eb0b6`).**
- **Symptom:** `seating_test` failed 25 of 152 checks on the committed code, although the Codex entry reported it passing.
- **Cause:** the new stand-up sweep (`Seating._exit_clear`) rejected any overlap at the rise point. A chair tucked under a table (Hall A's front table chairs) starts inside the table's clearance, so every exit failed and the player could never stand up.
- **Fix:** the sweep now ignores only the furniture the chair already sits against. The destination must still be clear, and the path must not cross anything else.

**Also:** the lecture's Space/E overlay hides while the laptop is open, since those keys go to the laptop.

**Verification:**
- **Tests:** flashcard 78, foundation 54, dorm 87, campus 40, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17, save 37, UI 60, acceptance 47, ambient 30, first person 58, wardrobe 74, café exit 33 — all passing (1,077 checks).
- **Graphical captures inspected:** the idle and zoomed dorm monitor; the Windows lock, sign-in, desktop and Start menu; Anki's deck list, overview, question, answer, Browse, Stats and Add on the PC; the café laptop's Mac lock, login, desktop, Anki and system menu; the lecture-seat laptop; the return to the room view.
- Import and `git diff --check` are clean.

## 2026-09-23 22:15 PDT — Dorm PC, backpack laptop and Anki-style flashcard study

User request: brainstorm and implement medical flashcard study through a Windows-style dorm PC and a MacBook/macOS-style laptop carried with a backpack, including use while seated at tables or during lectures. Demo login is **player1 / 122333** on both devices. Existing uncommitted character, wardrobe and inventory work was preserved. No commit or push.

- Replaced the dorm's decorative laptop with a desktop PC, monitor, tower, keyboard and mouse. Its existing walk-up study-desk interaction opens a working login and desktop.
- Backpack equipment provides laptop access in Inventory and a compact **L / Open laptop** prompt at eligible seats. Added two usable café study-table chairs, and lecture seating deploys a laptop on a writing tray. Closing packs it away and preserves the lecture seat lock. Computer input blocks exploration and lecture shortcuts, while the world keeps running; first-person mouse capture is released.
- Added one shared offline collection with 13 standalone pharmacodynamics cards derived from the existing QuestionBank, plus editable Basic/Cloze personal notes, hinted/multiple cloze deletions, sibling burial, search, suspension, leeches, history and options. The graph-dependent lecture item is excluded. Card answers and explanations stay hidden until reveal; recall buttons remain visible while long content scrolls.
- Implemented a deterministic classic Anki-style scheduler: new/learning/review/relearning states, Again/Hard/Good/Easy, 1m/10m learning steps, graduation, ease floor, overdue credit, interval previews, daily new limit, and persisted due dates. Uses real wall time and UTC days independently of the accelerated game clock.
- Study XP: **+2 per card per day**, up to **100/day**, after at least three seconds of study. All ratings earn equally, including honest forgetting; repeated learning steps cannot pay twice. Self-ratings never inflate graded medical accuracy or lecture streaks.
- Extended validated saves with an optional collection; older saves still load and New Game resets it. Added design/brainstorm notes in `src/docs/development/FLASHCARD_SYSTEM.md`; updated architecture, medical review, known issues, README and acceptance expectations.

**Verification:** `flashcard_test.gd` **68 checks**, passing in a graphical Godot run. Covers scheduler behavior, XP cap/repeats, Cloze, validation, save continuity, wrong/correct login, both computers, backpack and seating eligibility, real café seating, active-lecture keyboard isolation and first-person controls. Regression suites: dorm **87**, save **37**, UI **60**, wardrobe **74**, seating **147**, lecture **118**, progression **34**, knowledge **17**, campus **40**, first person **58**, full acceptance **47** — **719 regression checks, all passing**. The full acceptance test was updated to close the new PC before continuing the former placeholder interaction route. Graphical captures inspected: Windows login/desktop, Mac login/desktop, deck list, review/reveal, note editor, Browse, Stats, Options and café/lecture laptop close-ups. Import and whitespace checks clean.

**Boundaries:** this is an Anki-style implementation, not an exact Anki port: no FSRS, AnkiWeb, .apkg import/export, add-ons, media notes, undo or fuzz. The two OS environments are in-game simulations. Human medical review, physical controller hardware and extended real multi-day study remain manual work. The design note separates implemented behavior from future ideas.

## 2026-09-23 20:16 PDT — Minecraft-style characters, character creator, clothing, closet and equipment inventory

User request: re-create the characters so they look like Minecraft character models (reference skins provided). Add deeper customization, rebuild the Inventory UI as a clothing equipment sheet (reference RPG equipment screen provided), and add new clothing items such as a rare Patagonia jacket and a white jacket. The customization covers:
- a new-character menu with a preset *or* a build-your-own look: hair style and colour, eye style and colour, slight height changes;
- an interactive closet for changing clothes and appearance.

Not yet committed; the previous round was committed and pushed as `70531dc`.

**Characters** (`player/appearance.gd`, new `character/`).
- **Rig:** every figure — the player, Alex and Sam, classmates, the professor, bench students, passers-by and the dog walker — is now a Minecraft-style rig. It has six textured boxes: head, torso, two arms, and two legs split at the knee so sitting still bends them.
- **Skin:** one painted 64×64 pixel skin in the standard Minecraft layout (`skin_layout.gd`).
  - **Base layer:** skin, face, top, bottoms, shoes and lanyard.
  - **Overlay shell,** about 0.25 px larger: hair volume, outerwear, stethoscope, scarf, backpack straps, hats and glasses.
  - **Extra boxes:** buns, ponytails, cap brims and backpacks.
- **Painter** (`skin_painter.gd`): draws everything procedurally, with seeded pixel noise and hand shading, so a look always paints identically. It includes ribbed knits, denim seams, flannel checks, quilted puffers, high-pile fleece, lapels, zips, pockets, brass buttons, soles and laces.
- **Meshes** (`rig_mesh.gd`): cached box meshes whose UVs follow the atlas.
- **Proportions:** the rig keeps the old joint heights that seating and routes depend on — hips at 0.64 m, knees halfway down the leg, a 0.37 m seated hip height — and stands 32 px (1.71 m) tall.
- **Build and height:** slim builds have 3-pixel arms. Height scales the figure from 0.94 to 1.06 (161–181 cm); seated hips still meet the chair at any height.
- **Eyes:** the first-person eye point moved to the painted eyes.

**Looks and presets.**
- **Looks** (`data/looks.gd`): a look is plain JSON-safe data. It sets the build, 10 skin tones, 10 hair styles, 13 hair colours, 6 eye styles, 7 eye colours, brows, mouth, cheeks (freckles, blush), facial hair (stubble to full beard), height, and an eight-slot outfit. Looks are sanitized and validated, and `Looks.random()` dresses crowds.
- **Presets** (`data/character_presets.gd`): eight presets, including three modelled on the reference skins — *Cobalt* (open blue hoodie), *Russet* (maroon crewneck and shades) and *Navy* (navy tee and dark jeans). There are also eight extras for faculty and classmates, among them a white-coated professor and Dr. Nyugen in a blazer, shirt, tie and glasses.
- **Crowds:** Hall A's classmates now use varied looks, and passers-by and the dog walker get a random look each visit.

**Clothing** (`data/clothing.gd`). 63 items across eight slots: head, eyewear, outerwear, top, neck, back, bottom and shoes.
- **Examples:** the **rare Patagonia Retro Fleece** (cream pile, teal chest pocket with an orange logo, snap placket) and the **White Jacket**. Also a puffer, a varsity jacket, a denim jacket, a bomber, a rain shell, hoodies, scrubs, an oxford and tie, flannel, sneakers, boots, clogs, beanies, caps, a scrub cap, glasses, aviators, a stethoscope, a scarf and backpacks.
- **Rarity** (common, uncommon, rare, epic, legendary) sets when an item unlocks: rare at Lvl 2, epic at Lvl 3, and the legendary Long White Coat for completing the first lecture (a new `AcademicSession.lecture_completed` signal). The HUD names new clothes when they unlock.
- **Stats:** each item has cosmetic style, comfort and warmth values.
- **Equipping:** `AppState.equip()` refuses locked items and won't leave the top, bottom or shoes empty.

**Character creator** (`ui/character_selection.gd`, with `ui/look_editor.gd`, `ui/option_row.gd` and `ui/character_preview.gd`).
- **Name:** there is a name field; the name follows the chosen preset until you type one.
- **Presets tab:** eight preset cards, each with a rendered portrait.
- **Create your own tab:** stepper rows for build, skin, height (cm and feet/inches), hair, eyes, brows, mouth, cheeks and facial hair, plus a starting outfit from the unlocked clothes. Rows step with ←/→ or the arrow buttons, and colours are clickable swatches.
- **Randomize** button.
- **Preview:** a large turntable preview you can drag to turn.

**Closet** (`ui/wardrobe_panel.gd`). An oak wardrobe with a mirrored door now stands on the dorm's west wall; "Open closet" opens an overlay.
- **Clothes tab:** the equipment sheet.
- **Mirror tab:** the full appearance editor.
- **Behaviour:** changes apply to the student live. Movement pauses (and in first person the mouse is freed) while it is open. Esc, Tab or Done closes it.

**Inventory** (`ui/menu/inventory_page.gd`, `ui/equipment_view.gd`). An RPG equipment sheet in the style of the reference:
- slots around the student (head, eyewear, outerwear and top on the left; neck, back, bottom and shoes on the right);
- an item card with rarity, description, stat pips and requirement;
- the items for the selected slot, with rarity-coloured borders, lock badges and a tick on the worn item;
- outfit totals.

Items have pixel-art icons drawn in their own colours (`ui/item_icon.gd`).

**Menu and save.**
- **Menu:** the sidebar shows a live portrait of the student next to their name, and the Overview and Continue use that name.
- **Save:** the save now stores the look and name. Older saves without them still load, with the preset's new look; a save with an unknown item or an invalid look is rejected.

**Tests.**
- **New `wardrobe_test.gd` (74 checks):**
  - skin layers and colours;
  - rig joints, build and height, including seated height;
  - look sanitizing, validation and random looks;
  - the catalogue and its rarities;
  - the creator (presets, portraits, editor rows, unlocked-only outfit, custom looks, height preview, randomize, typed names, a look reaching the game);
  - the closet (real walk-up and E, movement pause, wearing the White Jacket, the locked fleece and its requirement text, slot rules, mirror restyling that keeps the outfit, Esc);
  - the inventory (worn slots, the Lvl 2 unlock and notice, wearing the fleece, totals, the legendary coat after the lecture);
  - save, reload and Continue restoring the exact look and name, legacy saves, and rejection of broken saves.
- **Updated tests:** `dorm_test` checks the painted skin for all eight presets (now 87 checks); `ui_test` expects eight presets.
- **Also fixed while testing:** item icons that were offset by centre anchoring; the closet mirror overwriting a newly equipped jacket; the Presets tab bouncing a custom look back to the editor.

**Verification:**
- **Tests:** foundation 54, dorm 87, campus 40, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17, save 37, UI 60, acceptance 47, ambient 30, first person 58, wardrobe 74 — all passing (966 checks). Seating, the lecture, NPC routes and first person work unchanged on the new rig.
- **Captures inspected:** the full preset lineup (front, back, three-quarter, face close-ups), the creator's two tabs and a randomized look, the dorm wardrobe (third and first person), both closet tabs, the inventory with the fleece worn, the menu portrait, campus crowds and Hall A's classmates.
- Import and `git diff --check` are clean.

## 2026-09-23 18:55 PDT — First-person review fixes: head shadow, real doors, Anatomy Hall entrance, lobby, glitches

The user reviewed the world in first person and asked for these fixes before committing and pushing.

**Head shadow.** In first person the player's head and hair now render as shadow only (`SHADOWS_ONLY`) instead of being culled from the camera, which had also removed them from the shadow. The whole shadow, head included, falls on the ground. Third person restores the head.

**Doors.** `Buildings.door()` is rebuilt as a real entrance assembly and used by the Learning Center, the residence, the Medical Center and the café:
- a dark metal portal standing 0.3 m proud of the facade (jambs, head, transom bar and a tinted transom light);
- two framed leaves (stiles, top rail, deep kick rail);
- long steel pull handles on standoffs, and a steel threshold;
- a dark vestibule behind.

The leaf glass uses a new plain, reflective `tinted` MeshKit material, because the curtain-wall shader painted its mullion grid onto the doors. The curtain-wall glass of the Learning Center and the residence is cut back around the doors. The shrub in front of the Medical Center doors has been moved.

**Anatomy Hall entrance** (accessible, not yet interactive):
- **Portico:** a raised stone floor with three steps across its width. They collide as one gentle ramp, and the floor's collider starts where the ramp reaches full height, so there is no lip.
- **Columns and handrails:** handrails at both ends; the columns are respaced for a 2 m clear central bay.
- **Doors:** tall panelled timber double doors (`Buildings.classical_door()`) in a stone architrave, with a glazed fanlight, brass pulls and kick plates.
- **Approach:** a paved apron leads to the steps.
- **Test:** walking up with real input reaches the doors.

**Blank walls and other glitches seen at eye level.**
- **Windows:** added to the residence's north and west faces and to both side walls of the Anatomy Hall.
- **Solar panels:** the residence's panels no longer overhang the roof edge; that overhang was the black wedge seen from below.
- **World edge:** the ground now extends to ±280 m, and first person adds distance haze (depth fog in the horizon colour) so its edge never shows.
- **Shadows:** first person uses a shorter shadow range with soft edges, so near shadows are no longer jagged.
- **Flowers:** the flower row laid straight on the residence forecourt paving is removed. The Medical Center's flowers now sit in a raised stone planter.

**Campus directory and bench.**
- **Directory:** now a double-sided pylon with a campus plan (lawns, buildings, a "you are here" dot, a legend) on both faces, mirrored so each face reads north-up. Its sign fits within the pylon; it used to overhang. Its interaction point is on the north side, facing the residence entrance and the path.
- **Bench:** the bench beside it now faces the same way.
- **Tests:** the campus and acceptance tests read the directory from the north.

**Learning Center lobby.**
- **Feature wall:** the walnut slats leave a clean bay, so none cross the screen.
- **Display:** a slim wall-mounted display on a bracket shows a research seminar flyer (`ui/seminar_flyer.gd`, rendered live in a SubViewport):
  - Department of Anatomy & Cell Biology, a "Research Seminar" tab and Dr. Nyugen's studio headshot;
  - the talk title *On-Chip Neural Induction Enhances Neural Stem Cell Commitment: Advancing a Pipeline for iPSC-Based Therapies*;
  - 10:00 PM, Monday, September 21, 2026; Anatomy Building, Room R1023;
  - faint cell-lattice, neural-network and microchip motifs, and a footer band.
- **Headshot:** a live render of a new non-selectable faculty look, `nyugen`, dressed in a charcoal blazer, shirt and tie with thin-framed glasses, in a small studio with key and halo lights.
- **Bookcases:** two free-standing double-sided oak bookcases, `LoungeBookshelf` and `LoungeBookshelfEast`. Each has end panels, a top, a recessed plinth, a back panel and five shelves per side. The books vary in size and colour, with gaps, leaning volumes, lying stacks and title bands.
- **Reception:** the monitor now faces the staff side of the counter, with a lit screen, a keyboard, a mouse and an office chair behind the desk.

**Hall A.**
- **Right wall:** timber panelling now runs its full length, as on the left.
- **Back wall:** fabric acoustic panels.
- **Ceiling:** lighter. All of these fade in with the interior shell.

**Tests:** `first_person_test.gd` now has 58 checks:
- the head casts its shadow;
- haze on and off;
- the directory and bench facing;
- climbing to the Anatomy Hall doors;
- the flyer and headshot, with no slats across the display;
- both bookcases;
- the reception screen on the staff side.

**Verification:**
- **Tests:** foundation 54, dorm 67, campus 40, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17, save 37, UI 60, acceptance 47, ambient 30, first person 58 — all passing (872 checks).
- **First-person captures inspected:** the shadow in four directions, the directory from both sides, the residence door and roof, the Learning Center, Medical Center and café doors, the Anatomy Hall front, side, steps and doors (reached on foot), the world edge, the lobby display, bookcases and reception from both sides, and Hall A's walls.
- **Third-person captures inspected:** the Anatomy Hall and residence area, and the lobby.
- Import and `git diff --check` are clean.

## 2026-09-23 18:00 PDT — First-person view (Settings toggle, Cmd+F)

User request: an immersive first-person perspective alongside the default third person, toggled in Settings or with Cmd+F (press again to return). Milestone 10, the courtyard life and this change set are still uncommitted.

**Switching.**
- `AppState.first_person` is the session preference, and `view_changed` announces changes. Third person remains the default.
- **Ways to switch:**
  - Cmd+F on macOS, Ctrl+F elsewhere: the new `toggle_view` action uses command-or-control autoremap, and plain F does nothing;
  - the controller's View/Back button;
  - the new "First-person view" switch in Settings (title screen and player menu), which stays in sync with the keys.
- **Also in Settings:** a look-sensitivity slider (25–250%). The controls reference lists Camera view and Look.
- **HUD:** a short "First-person view" / "Third-person view" notice; a ⌘F Camera keycap in the controls hint (the ⌘ is drawn as a vector, because Outfit has no ⌘ glyph); a small centre dot while walking in first person.

**The view** (`player/first_person.gd`, a rig on the player).
- **Camera:** placed at the eyes (1.5 m, at the front of the face). It follows the head bone with the walk bob softened to 45%, and positions are interpolated between physics ticks for smooth motion.
- **Your own body:** your head is on render layer 20, which only this camera leaves out. Looking down shows your shirt, legs and shoes, and your shadow stays on the ground. The see-through silhouette is off in this view.
- **Looking and moving:**
  - the mouse looks, captured while no menu is open; opening the menu (Tab/Esc) frees it;
  - the right stick also looks;
  - W/A/S/D move relative to the view, strafing without turning, and the body faces where you look;
  - double-tap sprint works as before.
- **Interaction:** prefers what you are looking at and ignores what is behind you. In third person it is unchanged: the nearest visible target.
- **Sitting and standing:** the view turns with the body and lowers as you sit. Seated, you can look about 110° either way. In Hall A the view settles on the lecture screen.

**Scenes.**
- **Dorm and lobby:** the walls cut away for the overhead camera stand at full height, and a ceiling appears.
  - The dorm adds a room light, plus a framed print and a round clock on its south wall.
  - The lobby adds ceiling light panels, a fill light and glazed exit doors with daylight beyond.
  - None of these cast shadows, so the sunlight matches third person.
- **Campus:** shows a daylight sky gradient (`ProceduralSkyMaterial`, following the clock) instead of the flat backdrop; ambient light is unchanged. Arrivals now face out of the door they came through (`Config.SPAWN_YAWS`).
- **Relief lettering:** no longer casts shadows; at eye level the shadow looked like a ghost copy of the text.
- **Hall A:**
  - the ceiling and near walls stay solid in first person;
  - seated, the view stays first person instead of handing over to the lecture camera;
  - class begins from the first-person seat (`lecture_view_ready()` and `view_settled` replace the session's direct lecture-camera checks);
  - Cmd+F while seated snaps between the first-person seat view and the over-the-shoulder lecture camera, mid-lecture included (`LectureCamera.show_pose()` / `stop()`).

**Tests:** new `first_person_test.gd` (50 checks). It covers:
- toggling by Cmd+F, plain F, the View button and Settings, all kept in sync;
- camera and head hiding, eye height, and the silhouette;
- mouse, stick and sensitivity;
- view-relative walking, strafing and sprint, and the body facing the view;
- interaction by gaze;
- the menu freeing the mouse;
- whole rooms, the campus sky and arrival facing;
- the lobby doors;
- Hall A: solid shell, sitting, lowered eyes, settling on the screen, look limits, the lecture starting, and switching views mid-lecture.

Graphical captures of the dorm (ahead, the door, behind, looking down, walking), the campus (spawn, the quad, the dog lawn, the Learning Center), the lobby, and Hall A (walking, seated in first person, switched to third person and back) were inspected.

**Verification:** foundation 54, dorm 67, campus 40, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17, save 37, UI 60, acceptance 47, ambient 30, first person 50 — all passing (864 checks). Third-person behaviour is unchanged by the existing suites. Import and `git diff --check` are clean.

## 2026-09-23 13:25 PDT — Courtyard life: students on benches, a dog walker, strolling students

User request: add benches to the courtyard with students eating lunch, reading or taking notes, and someone walking a dog on a leash, both moving at random within a defined grassy area, so the world feels more alive and random. Milestone 10 and this change set are still uncommitted.

**Benches.**
- Six new benches bring the total to 13: two on the north perimeter walk at (±8, −13.9), and four on the round plaza's diagonals, facing the planter.
- `_bench()` is rebuilt at a real seat height: the slats top out at about 0.30 m, matching the seated pose.
- Each bench has a rotated collider. `MeshKit.solid()` now accepts a basis.

**Students on benches** (`npc/ambient/bench_student.gd`). Nine students sit on seven benches, set by `BENCH_STUDENTS` in `campus.gd`. They use the existing stylized figures.
- **Lunch:** a sandwich in hand with a bite now and then; a lunch box and a drink on the bench beside them.
- **Reading:** an open book held in both hands, with the occasional page turn.
- **Notes:** a notebook on the lap; the pen writes in bursts, and they look up to think.

Each student has their own random timing and a slow glance. Their knees and feet are solid (`SeatedFeetColliders`).

**Dog walker** (`npc/ambient/dog_walker.gd`, `npc/ambient/dog.gd`) on the quad's south-east lawn (`DOG_LAWN`).
- **Walker:** strolls to random points and pauses. While paused, the walker faces the dog, and also waits while the dog is sniffing at the end of the leash.
- **Dog:** a procedural dog in one of four random coats. It switches between random moods: trotting to a spot, sniffing, zooming in circles round the walker, play-bowing (always followed by a zoom) and sitting. It has a diagonal trot, a wagging tail and head movement.
- **Leash:** 2.6 m, sagging from the walker's hand to the collar. The dog can never pull past it.
- **Bounds:** both stay on the lawn and clear of the bench on its edge, and both are solid.

**Strolling students** (`npc/ambient/pedestrian.gd`). Three students walk the quad's path network, picking random junctions and sometimes stopping to check their phone.
- **Making way:** when the player is in their way, they step to a clear side (never into a bench or the planter), walk on, then drift back to the middle of the path. With no clear side, they wait.
- They are solid.

The title-screen panorama doesn't build any of this.

**Found while testing:**
- `Appearance.apply_preset()` frees the figure's children, so an NPC's blocker must be added after its preset. Pedestrians had silently lost theirs; they now add it afterwards.
- Pushing the dog out of the bench's keep-clear circle could stretch the leash slightly. The two constraints now alternate, with the leash taking priority. A 200,000-frame stress run across ten seeds stayed within 1 mm of both limits.

**Tests:**
- New `ambient_test.gd` (30 checks) covers:
  - placement, seat height, facing and props for all three activities;
  - gestures on independent timings;
  - the plaza benches facing the planter;
  - a minute of the dog walker, checking lawn bounds, bench clearance, leash length, attachment and sag, random targets and at least three moods;
  - pedestrians keeping to the paths, stepping aside for the player, passing without contact and returning to the centre;
  - solidity of all walking figures.
- `visual_motion_test.gd` now removes the dog walker and pedestrians before its sprint measurements, which run on the dog's lawn.

**Verification:** foundation 54, dorm 67, campus 40, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17, save 37, UI 60, acceptance 47, ambient 30 — all passing (814 checks). The ambient test ran five times. One run before the leash fix exposed that edge case; the run after the fix passed, alongside the stress run. Graphical captures of the quad, the bench pairs, the plaza benches, the dog in several moods and a pedestrian sidestep were inspected. The campus holds about 60 FPS with the added figures.

**Note:** test scripts share one test save slot (`user://savegame_test.json`, cleared when each script starts). Run them one at a time: a `save_test` run overlapping another script fails.

## 2026-09-23 12:43 PDT — Milestone 10: UI + polish, save/load, full-slice acceptance

Committed and pushed the campus redesign and Milestone 9 first (`bf423c9`).

**Design system (user brief: modern learning platform × polished RPG).** `ui/style/ui_style.gd` defines the palette, type scale, component styles and the shared Theme (with default, primary, navigation, card and ghost buttons). Its rules:
- ink surfaces;
- a single teal accent for interaction and navigation;
- gold only for progression;
- Outfit at four weights;
- a focus ring offset outside buttons.

`ui/style/icon.gd` is a 22-glyph vector line-icon set. Every screen now uses these.

**Title screen** (`ui/start_screen.gd`).
- **Backdrop:** a live campus panorama in its own world (`world/campus/panorama.gd` extends the campus and reuses its builders), with an ink gradient behind a clean menu column.
- **Buttons:** Continue appears when a valid save exists and shows the character, level, location and game time. New Game asks for confirmation before replacing a save. Settings and Quit follow.
- **Footer:** navigation hints.
- **Character setup** (`ui/character_selection.gd`): preset cards with swatches, and a turntable preview on a plinth.

**HUD** (`ui/dorm_ui.gd`, same public API):
- a location and objective card with a pin icon;
- the level/XP card (spark icon, "Lvl");
- a clock card with the date above the time;
- the unboxed prompt, message card and controls hint.

The objective comes from the new `data/objectives.gd`, so every location tells a first-time player what to do next, including a countdown to class and results guidance afterwards.

**Player menu** (`ui/menu/`, spec §32).
- **Layout:** a centred panel with a sidebar (student identity, level and XP bar, nine sections with icons) and a page header. It opens on the Overview with a soft cue, supports arrow-key and controller navigation, and Tab closes it. The world keeps running behind it.
- **Pages:**
  - **Overview:** greeting, objective, progress ring, next class with countdown, a knowledge snapshot, and save status with "Save now".
  - **Today:** timeline card with status chips and the result.
  - **Calendar:** month grid with today and event markers, plus the term list.
  - **Campus Map:** plan view from `data/campus_map.gd`, with a live position marker on campus or the containing building indoors, and the class destination.
  - **Knowledge:** headline stats, subject tree with bars, recent answers.
  - **Lecture Notes:** slide key points for each section reached, tracked in `AcademicSession.notes_progress`.
  - **Achievements:** a preview of six badges derived from existing progress.
  - **Inventory:** a preview.
  - **Settings:** audio, display, a controls reference, and "Save now" / "Save and return to title".
- **Tests:** pages expose `summary_text()` for tests and accessibility; the tests now use it.

**Save system** (`autoload/save_game.gd`, spec §35).
- **Slot and contents:** one versioned JSON slot in `user://`. It holds the character, XP and level, question history, counts, topic statistics, streaks, game time, location (scene and campus entry), lecture completion, notes, attendance (lateness) and the NPC event (`NPCSchedule.snapshot()` / `restore()`).
- **Writing:** atomic (temp file, re-read and validated, then renamed).
- **Loading:** fully validated before anything is applied (version, character, location, time, counts, NPC state). Numbers are normalized exactly, so timestamps like `…733.5` survive.
- **When it saves:** automatically after every scene arrival and when class ends; manual saves from the Overview or Settings.
- **Resuming:** `AppState.continue_game()` resumes at the saved location. Tests use a separate slot that is cleared per run.

**Other polish.**
- **Transitions:** fade to ink between scenes (`autoload/transition.gd`).
- **UI sounds:** soft focus, confirm and open/close cues (`audio/sfx/ui_*.wav`, original). In headless runs Sfx records requests without starting playback, because the dummy driver leaks playbacks.
- **Player x-ray:** a stencil x-ray silhouette when scenery hides the player, turned off while seated. A shade tree that hid the residence-door spawn was moved.
- **Lobby:** rebuilt to match the modern Learning Center — slate floor, warm walls, a walnut slat feature wall with relief "LEARNING CENTER" and a class info screen, glazed Hall A doors with push bars and relief lettering, a white and walnut reception desk, a charcoal lounge and coffee table, filmic tone mapping.
- **Lecture overlay:** restyled to the design system.
- **Removed:** `ui/schedule_panel.gd` and `ui/knowledge_panel.gd`, superseded by the menu pages.

**Tests:**
- New `save_test.gd` (37 checks): round trip of every persisted field, no duplicate XP or lateness after a reload, seven kinds of damaged file, and resuming from the title.
- New `ui_test.gd` (60 checks).
- New `acceptance_test.gd` (47 checks): the spec's full-slice test end to end with real inputs, from launch to reload.
- Existing tests were updated for the new menu, confirm dialog and text APIs.
- The acceptance record is `src/docs/development/MILESTONE_10_ACCEPTANCE.md`.

## 2026-09-23 11:45 PDT — Milestone 9: Knowledge interface; HUD tweaks

**HUD tweaks (user request).** The level card now reads "Lvl n" instead of "LV n". The top-right clock card shows the date on the first line and the time below it.

**Milestone 9.**
- **`education/knowledge/knowledge.gd`:** accuracy = correct ÷ attempted, safe at zero. `tree()` builds discipline → topic → subtopic from the question bank's taxonomy plus `AcademicSession.topic_statistics`, so unattempted areas still show and new disciplines need no code. `from_history()` independently recounts from `question_history`, and `recent()` lists the latest answers.
- **Knowledge tab** (`ui/knowledge_panel.gd`) in the player menu: an overall summary, then an indented row for each level with its name, an accuracy bar, the percentage and correct/attempted ("—" when not yet attempted), followed by the six most recent answers. It refreshes after every answer and whenever it's opened. The menu is slightly taller to fit.
- **Taxonomy:** subtopics now match the lecture's topics, in lecture order. Seed items were reassigned to Potency, Efficacy and Competitive antagonism, and the bank file is ordered by subtopic.
- **Tests and records:** new `knowledge_test.gd` (17 checks): zero state, increments, recalculation, hierarchy and order, future-discipline support, and a row-by-row comparison of the displayed statistics with a recount from the question history. The acceptance record is `src/docs/development/MILESTONE_9_ACCEPTANCE.md`. `academic_test.gd` now finds the Settings tab by index rather than position.

**Verification:** foundation 54, dorm 67, campus 39, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17 — all passing (639 checks). Import and `git diff --check` are clean. Captures of the campus (several views), the Knowledge page and the new top-right HUD were inspected; the campus holds about 60 FPS on the M1.

## 2026-09-23 11:38 PDT — Campus redesign (modern buildings, larger map, quad, planting); sign glitch fix

Committed and pushed Milestone 8 first (`9121157`).

**Sign glitch (user report: "Learning Center" letters glitching through the sign).** The wayfinding sign's lettering sat 3 mm in front of its panel and its backing plate ended up inside the panel, so the letters z-fought. Every mounted sign (`Geometry.wall_sign`) now stands 2 cm proud of its surface, with the plate 8 mm behind the letters. The campus's big names are now real 3D relief letters (`TextMesh`, using the built-in font because the variable UI font fails TextMesh triangulation), standing clear of their walls.

**Campus redesign (user references: modern stacked academic building, UNLV School of Medicine, Harvard Medical School quad, Harbor-UCLA Medical Center).** The map grows from 28 × 24 m to about 75 × 63 m walkable, with streets and a skyline beyond.
- **Layout** (`world/campus/campus.gd`):
  - a central quad of four lawn panels with a perimeter walk, a north–south axis and an east–west path;
  - a round plaza with a raised planter and a flowering tree, benches and lamp posts;
  - the Learning Center plaza with seat-height planters, one lettered "LEARNING CENTER" and one "SCHOOL OF MEDICINE";
  - the residence forecourt with the campus directory, the medical-centre forecourt, and the café terrace with tables and umbrellas;
  - a south sidewalk, a parking lot with parked cars and planted islands, and a street.
- **Buildings** (`world/campus/buildings.gd`):
  - **Learning Center:** glazed podium with columns and a green roof terrace behind a glass balustrade; three offset floor plates wrapped in white vertical fins; a timber-soffit entry canopy; roof plant.
  - **Cedar Residence:** four storeys, cream render, framed punched windows with orange fins, a projecting grey glazed bay, a red accent core, a glazed lobby, timber canopy and rooftop solar panels.
  - **University Medical Center:** a glazed podium with a timber canopy on slim columns, and a ten-storey tower of light and dark vertical panels.
  - **Anatomy Hall:** classical stone, window rows, cornice, a six-column portico with steps, and relief lettering.
  - **Café pavilion:** glazed, with a planted green roof and timber fascia.
- **Rendering:**
  - Detail is merged per material by `world/campus/mesh_kit.gd`, so each building is a few draw calls.
  - `assets/glass.gdshader` draws curtain walls procedurally: mullion grid, floor spandrels, a sky-reflection gradient with Fresnel, and varied panes, some with warm interiors.
  - `assets/facade.gdshader` grounds matte surfaces with a soft base gradient.
  - Filmic tone mapping and subtle glow; the shadow distance is raised to 70 m.
- **Planting** (`world/campus/flora.gd` and `assets/foliage.gdshader`): instanced species built from leaf clusters with crown-oriented normals for soft volumes, gentle sway and a touch of light through the leaves. Species are shade trees (quad rows), pink flowering trees (medical frontage, residence, plaza), columnar trees (framing the portico and corners), ornamental trees (planters and parking islands), foundation shrubs, parking hedges, and flower-bed blossoms. The turf tufts now cover only the lawn panels. The hall still runs at about 60 FPS on the M1.
- **Gameplay data:**
  - New spawns and doors in `data/campus_config.gd`, which also holds the camera framing and bounds.
  - Alex's route runs from the residence along the east–west path to Sam (now waiting by a bench west of the plaza, `Route.SAM_POSITION`), then north to the Learning Center doors.
  - The campus, NPC and visual-motion tests were updated for the new coordinates. The collision probes cover the four map edges plus the Learning Center, the plaza planter and the residence.

## 2026-09-23 10:33 PDT — Milestone 8: progression feedback

Committed and pushed Milestone 7 first (`0cd1e27`).

- **Level curve:** `education/progression/level_curve.gd` is the only place level maths happens, configured by `level_curve` in `data/academic_config.json`. XP from level L to L+1 is round(80 × 1.3^(L−1)), giving thresholds of 80, 184, 319 and 495. Overflow carries over, one award can cross several levels, negative balances count as 0, and the level never decreases. It looks up `GameClock` at runtime so it compiles even when preloaded early.
- **AcademicSession:** all XP changes now go through `add_xp(delta, reason)`, which emits `xp_changed`, `level_up(from, to)` and `streak_changed`. It tracks `level`, `streak` and `best_streak`, and exposes `level_progress()` and `streak_visible()` (threshold 10, configurable).
- **HUD** (`ui/progression_hud.gd`, in the shared HUD's top bar next to the clock):
  - a compact "Lvl n" card with an XP bar and "into / needed XP" (plus "owed" when the balance is negative);
  - a tweened bar that fills, empties and continues through level-ups;
  - floating "+N XP" (or red "−5 XP") values that rise and fade beside the bar, clear of medical content;
  - a "10x STREAK" chip that only appears at 10 or more in a row, pulses on each correct answer and hides on a miss;
  - a level-up banner ("LEVEL UP / Level 1 → Level 2") with a scale pop, particle burst and soft flash, for about 2.3 s.
- **Audio:** original synthesized sounds in `audio/sfx/` (correct chime, soft incorrect tone, prominent level-up fanfare, and an achievement bell reserved for later), played by the new `Sfx` autoload on the Master bus so the volume setting applies. Answer and level-up sounds follow `AcademicSession` signals, wherever answers come from.
- **Schedule and summary:** the schedule shows level and progress, and the lecture summary includes the level.
- **Tests:** new `progression_test.gd` (34 checks) covers the spec's required XP, level and streak logic plus the HUD and audio feedback. The acceptance record is `src/docs/development/MILESTONE_8_ACCEPTANCE.md`.
- **Verification:** foundation 54, dorm 67, campus 38, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34 — all passing (621 checks). Editor import and `git diff --check` pass. Graphical captures of the HUD, floating XP, streak chip, level-up banner, and XP feedback during the lecture were inspected.

## 2026-09-23 10:14 PDT — Milestone 7 complete; character rebuild reverted; double-tap sprint

**Character models reverted (user request).** The procedural rebuild was removed entirely: `appearance.gd`, presets, character selection, seat dimensions, Alex's route and the professor rig are back to `405f17f`, and `body_mesh.gd`, `hair_mesh.gd` and `hair.gdshader` were deleted. The rest of that session's work (visualization, mounted signs, podium, NPC collision) was committed and pushed as `5f8c4d3`.

**Double-tap sprint (user request, Minecraft-style).** Tap W, A, S or D twice within 0.3 s and keep holding to sprint in that direction. The character turns to face it, so double-tapping S turns you around and sprints back. Letting go of movement ends the sprint. Shift no longer sprints; controller L3 still does. The HUD shows a compact "×2 Sprint" hint. `visual_motion_test.gd` covers: a single or slow double tap doesn't sprint; a quick double tap does; the opposite direction turns you around; letting go stops.

**Milestone 7 finished.**
- **Questions:** there are 12 scored lecture questions (the 3 original seeds, the visualization prediction and 8 new ones) plus 2 remediation follow-ups (5 XP each), all in the shared bank and covering Recall, Conceptual, Application and Clinical Application. The new ones are affinity/Kd, partial agonist intrinsic activity, pure antagonist, noncompetitive antagonism, efficacy vs potency in prescribing, therapeutic index, recurrent respiratory depression after naloxone in methadone overdose, and buprenorphine-precipitated withdrawal.
- **Question beats:** the lecture script places a beat (`{"question", "lead", "remediation"}`) after each topic. The efficacy, dose-response and clinical segments follow the spec's concept → feedback → clinical connection → application loop.
- **Delivery:** `world/lecture_hall/question_beat.gd` delivers each beat on the compact question card. Answers are graded with `QuestionBank.submit`, so there is one attempt per lecture and stats and XP are recorded. A correct answer gets a confirmation and XP. A wrong answer is clearly marked, awards no XP and shows the explanation. Only the noncompetitive and potency beats follow a miss with a simpler question.
- **Completion:** after the summary lines, a completion card shows questions correct, accuracy, lecture XP and overall Pharmacodynamics accuracy. It is recorded in `AcademicSession.lectures_completed` (which replaces `presentations_completed`). Dismissing it unlocks the seat and resumes exploration. The HUD objective and the schedule's Today and Calendar pages show the result.
- **Tests and records:** `lecture_test.gd` (118 checks) plays every beat through real input, deliberately missing one remediated question and the activity prediction, and verifies the 10/12 tally, the XP reconciliation, recording and the resumed exploration. The acceptance record is `src/docs/development/MILESTONE_7_ACCEPTANCE.md`, and every question has an entry in `MEDICAL_CONTENT_REVIEW.md`.

**Verification:** foundation 54, dorm 67, campus 38, NPC 37, academic 77, visual motion 23, room polish 25, seating 147, lecture 118 — all passing. Import and `git diff --check` are clean. Graphical captures of the question, feedback, summary, schedule and HUD were inspected.

## 2026-09-23 09:48 PDT — Competitive-antagonism visualization, NPC collision, sign and podium fixes

**Interactive visualization (Milestone 7).** The competitive-antagonism segment now includes a hands-on activity (`src/world/lecture_hall/competitive_activity.gd`), declared in the lecture JSON as an `activity` line; the runner validates it.
- **Model:** `src/education/models/competitive_antagonism.gd` implements Gaddum competitive binding. Agonist and antagonist occupancies share one site, response = Emax × agonist occupancy, and the antagonist raises EC50 by the dose ratio 1 + [B]/KB (fixed at 10 in the activity).
- **Screen:** `ui/lecture_slide.gd` gained a live model mode. It shows 24 receptors where agonists (circles) and antagonists (squares) bind and unbind at equilibrium fractions, drifting free molecules, readouts, and a live log dose-response plot. The agonist-alone curve stays as a ghost, and the shifted curve, apparent-EC50 marker and a moving operating point update as you play.
- **Flow:**
  1. The player holds A/D (or the stick) to raise agonist to about 90% response. The first phase stops at the goal so the effect is consistent.
  2. The professor adds the antagonist, which washes in visibly, and the response drops to about 47%.
  3. The player predicts what more agonist will do.
  4. The player tests the prediction, and the full response returns only at about ten times the agonist.
  5. The professor wraps up.
- **Prediction question:** it comes from the shared bank (`pd_viz_competitive_01`, added to `pharmacodynamics.json` with a review entry). It is graded with `QuestionBank.submit`: an incorrect answer awards no XP but updates stats. The question card in `ui/lecture_ui.gd` (arrow keys or 1–4, then E) is reusable for the upcoming question set. After answering, it shrinks to show only the chosen and correct choices plus the explanation.

**Character models:** a procedural rebuild (realistic proportions, strand hair) was prototyped in this session, but at the user's request it was reverted in full. The character models, presets, seat dimensions and NPC route are exactly as committed in `405f17f`.

**NPCs are solid (user request).** Alex and Sam carry an animatable capsule on physics layer 3 (disabled when hidden or seated, since the seat's colliders cover seated figures), and the professor has one too. The player now collides with layer 3. Interaction raycasts stay world-only, so NPCs never block prompts.

**Signs no longer cover objects (user request).** `ui/world_nameplate.gd` gained mounted signs: flat, depth-tested plates attached to surfaces, created with `Geometry.wall_sign()`.
- **Dorm:** the "PHARMACOLOGY" label was removed, and "FIRST YEAR" is lettered flat on the noticeboard, so it follows the board's angle. EXIT is smaller and sits above the door.
- **Campus:** CEDAR RESIDENCE sits on the wall between awning and cornice; LEARNING CENTER is above the glazing; LECTURE HALL A is on a canopy fascia; CAMPUS DIRECTORY is on a header plate. The floating path label became a two-post wayfinding sign beside the walk.
- **Elsewhere:** the lobby hall sign is on the wall above the door, and the vending-machine labels are on the machine headers.

**Podium (user request).** The podium has a flat top with two monitors on real stands (base, neck and hinge), with screens facing the professor and showing a slide thumbnail. It also has a keyboard with individual keys, a mouse on a pad with its cable, and a gooseneck microphone. The mic has a weighted base and a curved segmented neck, and its capsule, red ring and windscreen sit just in front of and below the professor's mouth.

**Verification:** all suites pass — foundation 54, dorm 67, campus 38, NPC 37 (new NPC-blocking checks), academic 77, visual motion 19, room polish 25, seating 147, lecture 59 (new model and activity checks, including a deliberately wrong prediction). Editor import and `git diff --check` pass. Graphical captures of the activity (every phase), podium, dorm desk and board, and campus signs were inspected.

**Limitations:** the auditorium seat pitch stays wide (0.92 m) to suit the broad stylized figures.

**Remaining Milestone 7 work:** about 12 lecture questions with feedback and selective remediation, the concept → clinical → application question beats, lecture completion, and the acceptance record.

## 2026-09-23 08:49 PDT — Professor presentation, turf lawn, muted Hall A

Committed the previous change set (`2f0eac8`); both commits were pushed to origin/main together.

**Professor presentation (Milestone 7).**
- **Script as data:** `src/education/lectures/pharmacodynamics_01.json` has 11 segments: introduction; the nine suggested topics in order (receptors and ligands, agonists, antagonists, competitive and noncompetitive antagonism, potency, efficacy, dose-response relationships, clinical application); and a summary. Each segment has one slide (heading, up to four progressively revealed bullets, one diagram) and three or four professor lines with gestures. Schema: `src/education/lectures/README.md`.
- **Runner:** `lecture_runner.gd` validates the script and steps line by line with signals. It has no UI dependency.
- **Model:** `src/education/models/dose_response.gd` provides the Hill equation, occupancy, the competitive dose ratio and the noncompetitive Emax. It is shared with the upcoming interactive model.
- **Slides:** `src/ui/lecture_slide.gd` renders onto the hall's projection screen through a SubViewport. The curves are drawn from the model on a log axis (full vs. partial agonist, competitive shift, noncompetitive depression, potency, efficacy, quantal ED50/TD50 with TI, clinical opioid, summary), plus receptor diagrams.
- **Professor:** `src/npc/professor.gd` (Dr. Lena Park) breathes and shifts her weight, gestures with alternating hands while speaking, and for "screen" lines half-turns and points with the arm on the screen's side.
- **Overlay:** `src/ui/lecture_ui.gd` is compact: a small subtitle card with the speaker's name, typewriter text and a Continue keycap, a topic chip (e.g. "5 / 11 · Competitive antagonism"), and a waiting card.
- **Session flow** (`src/world/lecture_hall/lecture_session.gd`):
  - Sitting before 8:00 shows "Class begins at 8:00 AM" with Space: wait for class, or E: stand up. Waiting fast-forwards the academic clock, and the autonomous NPC event by the matching real time, to the start of class.
  - Once class time has come and the lecture camera has settled, the seat locks, the exploration controls hint hides, and the presentation starts. E, Space or Enter first finishes the current line and then advances.
  - At the end, the presentation is recorded in `AcademicSession.presentations_completed`, the seat unlocks, and a closing message appears. Sitting again does not replay it.
  - The HUD's own prompt and toasts give way while the lecture overlay is showing.
- **Fix:** `seating.state_changed` now fires after seating finishes settling, so listeners can lock the seat reliably.

**Lawn (user reference image).** `grass.gdshader` now draws dense, short, vivid turf: procedural blade flecks at two scales in world space, over very soft tonal variation, with the finest layer faded out at a distance. The tufts are 18,000 short instances in matching greens, and the wildflowers were removed.

**Hall A palette (user request: modern and clean, not bright white).** The hall now uses slate carpet on the floor and tiers, warm greige walls, walnut panelling, muted trim and whiteboard, and slightly lower ambient and key light. The seats keep their colour, which the user approved.

**Verification:** foundation 54, dorm 67, campus 38, NPC 35, academic 77, visual motion 19, room polish 25, seating 147, lecture 42 (new) — all passing. Editor import and `git diff --check` pass. Graphical captures of the whole presentation (every segment and screen-gesture line), the waiting prompt, the hall palette and the lawn were inspected; a mis-anchored subtitle card and slide label overlaps were found and fixed.

**Limitations:**
- The professor does not walk.
- Lines are advanced by the player; there is no voice-over or audio.
- Slides are 2D in a SubViewport and are not readable from the isometric view (they are meant for the seated view).
- Narration awaits human medical review (`MEDICAL_CONTENT_REVIEW.md`).

**Remaining Milestone 7 work:** the competitive-antagonism interactive visualization, about 12 original lecture questions with feedback and selective remediation, the concept → clinical → application question beats in the script, lecture completion, and the acceptance record.

## 2026-09-23 08:03 PDT — Auditorium Hall A, lecture camera, sprint, campus fixes and lawn

Committed the previous change set first (`a20e234`).

**Hall A rebuilt as a raked auditorium**, modeled on the reference photo of a UIC medical-school lecture hall the user supplied (`src/world/lecture_hall/lecture_hall.gd`):
- A floor-level teaching area at the front with a large framed projection screen, a whiteboard, a dark podium with two monitors and a gooseneck microphone (the professor stands behind it), and a side table with two loose chairs.
- Five tiers (0.38 m rise, 1.6 m deep) of upholstered orange-red seats in three sections, split by two stepped aisles. The seats have pedestals, padded backs, shared armrests and row-end panels.
- Wood panelling with reveals on the long wall, and blue double doors with an exit sign at the front left.
- 65 seats in total: 14 classmates plus Alex's saved seat are taken, leaving 50 open.
- **Seat spacing:** the stylized figures are about 0.85 m across the arms, so auditorium seats use a 0.92 m pitch and a 0.8 m cushion. At a realistic 0.6 m, seated arms would pass through the armrests.
- **Aisle collision:** the aisles show two steps per tier, but their collision is a smooth ramp through the step nosings. Walking is continuous, and feet can sit up to about 7 cm off the drawn step.

**Row-seat routing.**
- `world/seat.gd` gained an `auditorium` style and a `navigator` callable.
- The hall builds a walkway graph (`AStar3D`) with a node in front of every seat, aisle landings, the foot and head of each flight, and floor nodes near the door.
- `SitSequence.plan_row_sit()` walks that route, then turns, backs up to the cushion and sits. Approach labels: `front` (already in front of the seat), `row_left` / `row_right` (along the row from the sitter's left or right), or `back` (from the row behind, routed through the nearest aisle).
- Seated classmates' legs are solid, so the player walks around them in the walkway.
- The two table chairs keep the free-standing four-side approach.
- Alex now enters through the front-left door, climbs the left aisle and walks along row 2. When watched, he turns and sits from the walkway.

**Lecture camera transition** (`src/world/lecture_camera.gd`).
- On sitting, a perspective camera takes over. It starts as a 5° field-of-view camera placed far back along the isometric camera's ray, framing the same height, so the first frame matches the orthographic view (the test measures the drift in pixels).
- It then blends focal point, direction (slerp), framed height and field of view (log space) with smootherstep over 1.7 s, arcing over the audience to an over-the-shoulder view of the screen, podium and professor.
- Standing up reverses it and hands back to the exploration camera.
- A ceiling with light panels and full-height near walls fade in only as the lecture view settles, so the isometric cutaway is unchanged.
- `seating.stand_locked` is still the hook for keeping the player seated during class.

**Sprint** (user request).
- The new `sprint` action is bound to Shift and controller L3. Speed ramps from 3.2 to 5.8 m/s over 0.25 s.
- `appearance.gd` blends a run gait from actual ground speed: longer stride cycle, bigger hip swing, the recovering knee folded high, knee lift through the swing, harder arm pump with slightly tucked arms, forward torso lean and more bounce.
- The HUD help row shows a compact Shift/L3 keycap.

**Campus visual fixes** (user screenshots).
- **Cedar Residence:** the horizontal trim lines that crossed the door and windows (and poked out as dots at the corner) were removed. The facade now has a plinth, cornice, corner boards, framed windows with muntins and sills, and a framed door with a glass panel, handle and small awning.
- **Learning Center entrance ("Lecture Hall A"):** a window sill whose front face was coplanar with the door leaf was z-fighting, and it ran through the door. The facade was rebuilt: glazed bays with sills that stop at a proud door frame, two tinted leaves with push bars, and a centre stile. Every layer sits at its own depth.

**Detailed lawn** (user request).
- `src/assets/grass.gdshader` adds broad, low-contrast, non-repeating tonal patches and fine blade speckle in world space, so it has no tiled pattern.
- About 8,000 deterministic grass tufts are drawn in one `MultiMesh`, with a gentle per-tuft sway in `grass_blades.gdshader` and a sprinkling of small wildflowers. Paths, buildings, the planter and other furniture are excluded.

**Verification:** foundation 54, dorm 67, campus 38, NPC 35, academic 77, visual motion 19 (new sprint checks), room polish 25, seating 147 (rewritten for the auditorium, including camera hand-off checks) — all passing. Editor import and `git diff --check` pass. Graphical captures of the campus facades, lawn, sprint, hall, a back-approach sit, and the camera transition in both directions were inspected; the hall runs at about 60 FPS on the M1.

**Limitations:**
- Auditorium seats are wider than real ones to suit the character proportions.
- Aisle steps use a ramp collider.
- The ceiling fades in rather than being a permanent mesh.
- The lecture itself (presentation, visualization, questions, completion) is still to come.
- Physical controller hardware remains untested.

## 2026-09-23 07:10 PDT — Docs cleanup, compact HUD, Milestone 7 started (Hall A seating)

**Docs/test cleanup.** `CLAUDE.md` now points to this file (it referred to a nonexistent `CHANGES`) and no longer claims work is uncommitted; everything through Milestone 6 is committed. `PROJECT_HANDOFF.md` has a current-status banner, an updated milestone history and correct paths; its stale Milestone 2 brief was removed. `tests/foundation_test.gd` looked for the old `src/docs/development/CHANGELOG.md` and now checks the repository-root `CHANGELOG.md` (the only failure in the baseline run). For the record, `room_polish_test.gd` ran 21 checks before this change set, not the 24 reported below.

**Compact HUD (user request).** `src/ui/dorm_ui.gd`: the base font drops from 18 to 15 px. The location and clock are small translucent cards sized to their content, laid out in a top bar. The bottom-left controls and the contextual prompt are drawn directly over the world with no filled boxes: a small keycap plus outlined text. Response messages use a narrow card that is shown only while there is text. `src/ui/key_prompt.gd` keycaps are smaller and sized to their label. The menu panel shrank slightly. World sign nameplates keep their filled backings, per the earlier preference.

**Milestone 7: Hall A seating (user request: sit in any seat, with realistic motion from the side you approach).**
- `src/world/seat.gd`: a reusable solid chair (colliders for the seat and backrest; visible legs and rear posts) with local approach points: front, both sides, back corners, pre-sit and exit. A taken seat has no interaction and a collider covering the seated person's legs.
- `src/world/lecture_hall/lecture_hall.gd` was rebuilt: 18 chairs in three rows with a centre aisle, six seated classmates, the professor at a lectern, a titled display, and Alex's saved seat (jacket over the backrest). The 11 free chairs can all be used.
- `src/player/sit_sequence.gd` plans and plays the motion, based on which side of the chair the player is on. From the left or right he walks beside the chair, turns to face forward and side-steps in front of the cushion. From the front he walks to a point in front, turns around and backs up. From behind he detours around a back corner to a free side. Blocked approach points are rejected with a shape query and another side is tried; if none is clear, the HUD says so. Walking uses the body's real `move_and_slide` collision. Only the final side-step/back-step and the sit itself are kinematic, and none of them pass through the chair.
- `src/player/appearance.gd` now has knee joints and a spine pivot. `set_sit_blend(t)` blends continuously: hips hinge and drop, knees bend, the torso leans forward to balance and settles back, and the arms come forward onto the thighs. Walking bends the knees slightly, and side-steps swing the legs outward.
- `src/player/seating.gd` (added to the player at runtime) handles E to sit, E to stand, a stuck-walk abort and a `stand_locked` hook for the lecture. Movement input is ignored while seated.
- Alex now walks down the aisle to the side of his saved seat. If the player is watching, he turns, side-steps and sits with the same animation; otherwise he loads already seated.
- Classmate/professor looks are in `Presets.EXTRAS`, which cannot be selected as player presets.
- New `src/tests/seating_test.gd` (79 checks) covers every approach side, 30/60/120 Hz ticks, real E-key input, standing up, the ignored movement input, blocked seats, and a per-tick audit. The audit checks that the body never enters a chair's footprint outside the sit itself and that walking never overlaps solid geometry. `room_polish_test.gd` gained checks for unboxed keycaps and HUD coverage.

**Verification:** foundation 54, dorm 67, campus 38, NPC 35, academic 77, visual motion 11, room polish 25, seating 79 — all passing. Editor import and `git diff --check` pass. Graphical captures of the left, front and back sits and of the dorm, campus and hall HUD were inspected. **Limitations:** the stand-up always exits to the front. The chair colliders are simple boxes. Seated classmates are static figures. Physical controller hardware remains untested.

**Remaining Milestone 7 work:** lecture camera transition, professor presentation, competitive-antagonism visualization, about 12 questions with feedback and remediation, lecture completion, and the Milestone 7 acceptance record.

## 2026-09-23 05:03 PDT — Handoff recorded; latest dorm wood change completed on 2026-09-23

- Added `src/assets/wood.gdshader`, an original procedural wood material with fine grain, slight board variation, and restrained plank joins. `src/world/dorm/dorm.gd` applies it to the floor and wood furniture through `_apply_wood()`.
- The user explicitly disliked strong patterns on **all** floors. The lobby carpet and campus paths are plain, and the dorm rug is plain. Keep future wood details natural and low contrast rather than adding conspicuous stripes or repeating floor tiles.
- The final dorm render was inspected after the wood change. `src/tests/room_polish_test.gd` passed 24 checks, and Godot's final editor import and `git diff --check` passed. See `src/docs/development/ROOM_UI_POLISH.md`.

## 2026-09-23 05:03 PDT — Handoff recorded; room, shadow, and UI refinement completed on 2026-09-23

- Reworked `src/world/lecture_building/lecture_building.gd`: muted, solid carpet; two detailed decorative vending machines; cushioned library sofa; bookshelf. The center corridor remains open for the player and scheduled NPC. Vending machines are scenery, with no interaction behavior yet.
- Reorganized `src/world/dorm/dorm.gd`: the chair and laptop are centered at a real tabletop with four legs and open space beneath it; the stray cabinet was removed. The bed, bookshelf, entry, and study interaction remain usable.
- Improved shadows by preventing cutaway wall meshes from casting unrealistic interior shadows, setting camera far range in `src/world/exploration_camera.gd`, tuning the shared directional light in `src/world/geometry.gd`, and raising directional shadow precision in `src/project.godot`. This removed the diagonal shadow bands and jagged roof outline visible in the user's screenshots.
- Added filled world labels in `src/ui/world_nameplate.gd`, keyboard/controller keycaps drawn in `src/ui/key_prompt.gd`, and licensed Outfit typography in `src/assets/` (license: `Outfit-LICENSE.txt`). The shared exploration HUD in `src/ui/dorm_ui.gd` uses these elements, has a more compact interaction panel, and displays the written-out date (for example, **September 21st, 2026**). Date formatting lives in `src/autoload/game_clock.gd`.
- Latest checked graphical captures are the dorm, lobby, and campus images documented by `src/docs/development/ROOM_UI_POLISH.md`. Room/UI checks: 24 passed; the contemporaneous dorm, campus, NPC, academic, and motion suites also passed. Physical controller hardware was not tested.

## 2026-09-23 05:03 PDT — Handoff recorded; visual and movement polish completed on 2026-09-23

- Strengthened the campus/interior palette and morning lighting and added landscaping, planting, facade trim, window reflections, potted plants, and antialiasing. The scene builders are in `src/world/campus/`, `src/world/dorm/`, `src/world/lecture_building/`, and `src/world/lecture_hall/`; shared geometry helpers are in `src/world/geometry.gd`.
- Refactored `src/player/appearance.gd` into a shared procedural character pose with independently swinging legs and arms, foot movement, subtle bounce, and a seated pose. `src/player/player.gd` advances the gait from actual displacement so pushing against a wall does not make the player walk in place. `src/npc/student.gd` animates from the NPC's actual movement. `src/tests/visual_motion_test.gd` covers walking, idling, collision blocking, NPC motion, seated behavior, and frame-rate independence.

## 2026-09-23 05:03 PDT — Handoff recorded; Milestones 5–6 completed on 2026-09-23

- **Milestone 5:** `src/autoload/game_clock.gd` and `src/data/academic_config.json` provide a 5× fictional clock, academic date/week/semester, and an 8:00 AM mandatory Pharmacodynamics event in Lecture Hall A. `src/ui/schedule_panel.gd` powers Today and Calendar tabs inside the exploration menu. Campus daylight follows the clock.
- `src/autoload/academic_session.gd` records the **first successful Hall A entry** for the event date. Arrival after the configured start/grace period is late. The late penalty is exactly −5 XP and applies once, even when the starting balance is zero. Later rewards repay that signed balance. New Game resets academic state; the title stops the clock.
- **Milestone 6:** `src/education/questions/question_bank.gd` loads and validates versioned JSON atomically, gives callers deep copies, grades multiple choice and predefined normalized short answers, supplies explanations and objectives, and records idempotent XP/performance transactions keyed by attempt ID. `src/education/questions/pharmacodynamics.json` has three original seed questions. Schema/API details: `src/education/questions/README.md`; medical review notes: `src/docs/development/MEDICAL_CONTENT_REVIEW.md`.
- The question engine is intentionally independent of lecture presentation. There is no full lecture question set or delivery UI yet. Levels, save/load, and remediation are also later scope. Acceptance record: `src/docs/development/MILESTONES_5_6_ACCEPTANCE.md` (77 academic headless checks and 79 graphical checks, plus 193 earlier regression checks, all passing at that milestone).

## 2026-09-10, exact time not recorded — Milestone 4: autonomous student

- Added persistent `src/autoload/npc_schedule.gd`, authored AStar routes in `src/data/npc_route.gd`, reusable `src/npc/student.gd` / `.tscn`, and a minimal `src/world/lecture_hall/` scene. Alex meets Sam, talks, walks through campus and lobby, enters Hall A, and sits. The sequence progresses while offscreen or while the settings menu is open.
- `src/tests/npc_test.gd` verifies the sequence and routes. Acceptance notes: `src/docs/development/MILESTONE_4_ACCEPTANCE.md`.

## 2026-09-10, exact time not recorded — Milestone 3: campus

- Replaced the temporary dorm exit with an explorable courtyard and Learning Center lobby. Added collision, doors, directory/student interactions, isometric camera follow, location HUD, and campus traversal tests.
- Main files: `src/world/campus/campus.gd`, `src/world/lecture_building/lecture_building.gd`, and `src/tests/campus_test.gd`. Acceptance notes: `src/docs/development/MILESTONE_3_ACCEPTANCE.md`.

## 2026-09-10, exact time not recorded — Milestone 2: player and dorm

- Added four selectable character presets, reusable player movement/collision and appearance, a low-poly dorm with bed/desk interactions, orthographic camera, scene transitions, and dorm tests.
- Main files: `src/player/`, `src/world/dorm/`, `src/data/character_presets.gd`, and `src/tests/dorm_test.gd`. Acceptance notes: `src/docs/development/MILESTONE_2_ACCEPTANCE.md`.

## 2026-09-09, exact time not recorded — Milestone 1: foundation

- Created the Godot project structure, input actions, title screen, character selection foundation, session settings, `AppState` scene transitions, and foundation tests. `Continue` remains disabled until save/load is implemented.
- Acceptance notes: `src/docs/development/MILESTONE_1_ACCEPTANCE.md`.

## How to resume

1. Read the product spec and the relevant milestone/run document before beginning another milestone. Read this file from top to bottom for the current architecture and user preferences.
2. Inspect `git status --short` before editing and preserve any uncommitted work you find.
3. Run tests with `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/<suite>.gd`. Existing suites are `foundation_test.gd`, `dorm_test.gd`, `campus_test.gd`, `npc_test.gd`, `academic_test.gd`, `visual_motion_test.gd`, `room_polish_test.gd`, `seating_test.gd`, `lecture_test.gd`, `progression_test.gd`, `knowledge_test.gd`, `save_test.gd`, `ui_test.gd`, and `acceptance_test.gd`. Use `--path src --editor --import --quit` to validate import. Run graphical capture when visual behavior changes.
4. Update this file with a new timestamped section at the top for each future change set. Preserve the user's preferences: plain floor surfaces, subtle wood grain, a small HUD with unboxed keycap prompts, physically plausible character motion around furniture, and the UIC-style raked auditorium for Hall A.

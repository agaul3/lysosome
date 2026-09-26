# Known issues — Milestones 5–11 and the first year

- Physical controller hardware has not been tested. Bindings and injected controller events are covered by automated tests.
- Volume and fullscreen settings are not stored in the save (they are per-session preferences). There is no music or ambience.
- Original low-poly visuals are placeholders. The room camera is intentionally fixed and near walls are visually cut away while retaining collision.
- NPC navigation uses a fixed authored AStar route; dynamic crowd avoidance and player blocking are not implemented. The reserved chair is entered intentionally for the seated pose.
- Campus light follows the clock; indoor lighting remains fixed. NPC prototype timing remains elapsed-time based.
- Hall A is a raked auditorium with working seating and the lecture camera transition. The full Pharmacodynamics lecture (presentation, visualization, 12 questions with selective remediation, and completion) works. Lecture results persist in the save slot. The professor stays at the podium, and there is no audio or voice-over.  Auditorium seats use a 0.92 m pitch (wider than real seating) to fit the broad stylized figures. Aisle steps are drawn as steps but collide as a smooth ramp, so feet can hover or sink by up to about 7 cm. Standing up always exits to the front of the seat. Seated classmates are static.

The earlier sandbox launch/certificate issues are historical: graphical launch and fullscreen worked with the current environment. The Run #2 instructions also state Milestone 1 was manually verified and committed. Its original acceptance report is retained as historical evidence rather than rewritten.

See `MILESTONES_5_6_ACCEPTANCE.md` for current validation results.

- Progress (attendance, question history, XP, level, streak, notes, lecture results) is saved in one local slot. A late student at zero XP has a −5 balance (shown as "owed"); later rewards repay it before counting toward a level. Levels never decrease.
- Sound effects are original synthesized placeholders.
- The question bank holds 276 questions (13 lectures, the year's activities and exams, the clubs and the shadowing session). Human medical-content review is required before educational release.
- The first year's calendar is a set of story days (see *The first year* below); each lecture is scheduled once.
- NPC blockers are simple capsules. Moving NPCs push the player aside rather than steering around them.
- The residence, the Learning Center, University Hospital, the Medical Education Center, the Biomedical Library, the Student Center, Anatomy Hall and the Harbor Street Community Center have interiors; the research tower and the other campus buildings are scenery. Cars are static props. Relief lettering uses Godot's built-in font, because the Outfit variable font fails TextMesh triangulation.
- The Inventory page is a preview, as the spec allows; Achievements, Skills, Wallet and Journal are working pages. The Campus Map is a plan view drawn from layout data.
- Saving mid-lecture resumes at the Hall A entrance; sitting again restarts the presentation. Answers already given keep their results and XP (attempt ids are stable), so nothing is double-counted.
- Ambient campus life is not tied to the clock: bench students eat lunch at 7:30 a.m. They are not saved either, so their timing and the dog's coat are random each visit. Ambient figures do not react to the player, beyond pedestrians stepping aside. They do not avoid Alex or Sam, so they can briefly overlap. The dog has no sounds.
- Test scripts share one test save slot (`user://savegame_test.json`, cleared at each script's start). Run them one at a time.
- First person:
  - The view preference and look sensitivity are per session, like volume and fullscreen; a fresh launch starts in third person.
  - Looking straight ahead shows no hands or arms.
  - Walking backwards or sideways uses the forward walk cycle, which is visible only in your shadow.
  - Standing right against an NPC can clip their head at the near plane.
  - Alex starts the morning at the residence door, so arriving on campus early puts you face to face.
  - Steps up to the Anatomy Hall collide as a smooth ramp, so feet can hover up to about 7 cm over the treads, as on Hall A's aisles.
  - The Cmd+F binding is fixed (not remappable).
- Characters and clothing:
  - Clothing is painted onto the character's pixel skin and its overlay shell. Only backpacks, buns, ponytails and cap brims are separate boxes. Long coats paint their skirts on the upper legs rather than hanging free.
  - Items unlock by level (rare Lvl 2, epic Lvl 3) or by finishing the first lecture, or are bought at the Campus Store or given as rewards (club shirts, the white coat). Outfit stats are cosmetic.
  - The closet is only in the dorm; the Inventory's equipment sheet works anywhere.
  - Skins are generated procedurally; custom skin files can't be imported.
  - Seated short characters' feet can hover up to about 5 cm above the floor; tall characters' feet reach it.
  - Saves from before this change load with their preset's new look.
  - First person still shows no hands or arms.

## Computer / flashcard scope (September 23, 2026)

- Both simulated desktop environments and the shared offline study collection are functional. This is classic Anki-style scheduling, with deliberate differences (real-time UTC rollover, no fuzz/learning-ahead), not exact compatibility with Anki or FSRS. AnkiWeb, .apkg import/export, undo, rich-media cards and full OS window management remain unimplemented. The desktops are simulations: window resizing by dragging edges, multiple desktops, a working browser, file management and Launchpad are not implemented; menu-bar menus other than the Mac fruit menu are decorative. Screen text is legible at the default window size but small on very small windows. The system font falls back to Helvetica/Arial when Segoe UI or San Francisco isn't installed.
- Flashcard starter content retains the shared question bank's pending human medical review. Study XP rewards participation; self-rated recall never changes graded knowledge accuracy.
- Physical controller hardware and real multi-day use remain manual checks. See [FLASHCARD_SYSTEM.md](FLASHCARD_SYSTEM.md) for access instructions and design ideas.

## University Hospital and shadowing (Milestone 11, September 24, 2026)

- **Scope.** The hospital is a partial slice: the Level 1 atrium, one inpatient unit (4 West), since September 24 the Emergency Department with Emergency Radiology (see below), and since September 25 the Level 1 Food Court. The Outpatient Clinics, Level 2 mezzanine, 4 East and the other patient rooms are closed doors, roped stairs or scenery. The main elevators reach only Level 1 and Level 4; the directory lists eight floors.
- **Patients are observed scenery.** No history, examination, diagnosis or EHR entry, by design. Patients and staff other than Dr. Okafor are static figures. The charge nurse turns to face you when you talk to her.
- **The EHR is a read-only illustration for one fictional patient,** driven by the session. Outside the session, the workstation only shows a message.
- **The session is one-off.** It is the 9:00 event on 2026-09-21. Attendance is recorded when you meet Dr. Okafor; after the lecture you can meet her early without waiting. Completing it once records the results; there is no replay mode.
- **Saving and resuming.**
  - A save made mid-session resumes at the hospital entrance with the session waiting to start again. Answers already given keep their results and XP (stable attempt ids).
  - A save made on 4 West also resumes at the entrance.
- **Dr. Okafor's movement.**
  - She walks straight lines between authored anchors and does not path-find. If you stand directly in her way she waits (and says "Excuse me.") rather than stepping around you.
  - Lobby visitors do not avoid her, so they can briefly overlap.
- **The elevators** are a fade-and-teleport between paired cars (atrium ↔ 4 West, ED ↔ radiology). There is no ride animation, and the doors of the other cars are decorative.
- **Overhead cutaway.** Tall atrium walls on the far (north and west) sides stay full height. Ceilings, high signs and the ring pendant appear only in first person.
- **Campus side.**
  - The hospital's campus footprint has no interior at campus scale. Its east entrance leads into the separate hospital scene, whose glass front faces the camera, so inside and outside orientations differ.
  - Only the crossing, the plaza and the entrance are walkable across the street.
- **Visitor looks are random** each visit.
- **Medical content.** All shadowing content, including the seven questions and the chart values, awaits human review (see `MEDICAL_CONTENT_REVIEW.md`).

## Emergency Department and Emergency Radiology (September 24, 2026)

- **Two simulations, not one.**
  - The campus exterior and the department are separate scenes, like the rest of the hospital. The ambulance you watch back into the campus bay (about every 5 minutes) is not the one that arrives inside. While you are in the hospital, the ED runs its own busier EMS cycle (a unit every 2–2.7 minutes).
  - The department's floor plan does not correspond to the campus footprint; the campus building has no interior at campus scale.
- **Scripted movement.**
  - EMS crews, transports and walking patients follow authored routes in straight lines. They pause for the student, but they do not steer round the student or each other, so walkers and crews can briefly overlap.
  - Staff walk a path graph and step aside for the student.
  - The trauma team, seated clinicians, registrars, guards and waiting patients are static or scripted figures.
- **Appearing and vanishing.**
  - Ambulances appear and disappear at the garage entrance and exit (and at the far ends of the campus street).
  - The wheelchair transport disappears at the ED's second, out-of-service elevator car for 40 s ("upstairs") without riding it; the radiology stretcher appears and disappears at the Level 2 elevator.
  - A crew and cot vanish as the ambulance's rear doors close; there is no loading animation into the vehicle.
- **Carts and seats.**
  - An empty cot is backed out of the bay, then turned in the corridor. Carts corner on the move, so a tight corner can look slightly stiff.
  - The second crew member walks ahead of the foot end rather than beside the cot, so the pair fits the doorways.
  - `tests/ed_clearance_test.gd` keeps every scripted route clear of the geometry and the standing figures, but not of seated figures' knees and feet, which the row aisles avoid by design. The check models a turn as happening on the spot.
  - Sitting and standing are animated with the rig's sit blend, but walkers do not route round a seated neighbour's legs when reaching the seat.
- **Access.**
  - Doors open for anyone walking up, and there is no badge logic. The student can walk into the trauma bays, rooms, the medication room and the ambulance garage. Room 11 (being cleaned) is the only locked room.
  - The Boarder Care Unit and main-hospital double doors on the ED's side walls are closed scenery; the atrium link is a staff door with a fade.
- **Patients are scenery:** there is no patient interaction or clinical gameplay in the ED (not requested). Endpoints explain what you are looking at.
- **Boards and monitors.**
  - All names, initials, complaints, statuses and vitals are fictional. Vitals drift randomly within a range for the patient's ESI level; they are not modelled physiology, and the monitor traces are stylised.
  - The ESI colour code (1 red to 5 blue) is a game convention.
  - Radiology screens show obviously schematic images.
- **Saving:** a save in the ED or radiology resumes at the ED walk-in entrance. The department's patients, EMS and transports are not saved; the department restarts from the same seeded state each visit.
- **Performance:** while you are on the ED or radiology floor, three 1280×720 board viewports and a 1280×800 bedside-monitor atlas render every frame. The frame rate has not been measured on low-end machines.
- **Medical and operational content** (triage explanations, EMS call summaries, board data, room and imaging descriptions) awaits human review (see `MEDICAL_CONTENT_REVIEW.md`).

## The first year (September 25, 2026)

- **The year is a sequence of 28 story days, not every day.** Sleeping jumps to the next story day; the days between are summarised in a sentence. Weekends and ordinary weekdays between story days can't be played during term. After the last day (Friday 28 May 2027) every night leads to a free summer morning with no scheduled content; the clubs, gym, library and shops carry on. There is no second year.
- **Activities play in a dialog over the world.** Labs, standardized-patient encounters, the small-group case, Clinical Immersion shifts, the ceremonies, Research Day, the OSCE and exams run in the activity or exam panel at their station. The world doesn't stage them: the anatomical theatre has no seated classmates during the dedication, Hall A has no audience at the White Coat Ceremony, the immersion shifts don't walk you through the Emergency Department, 4 West or clinic, and the exam carrels, proctor and standardized patients' rooms are scenery. The clinic immersion starts at the Outpatient Clinics' doors, which stay closed.
- **Exams.** The timer counts real seconds. A missed exam moves to a 1 PM make-up on the next story day; missing the make-up too has no further consequence. A failed exam or OSCE has no retake; its questions become flashcards like every other bank question.
- **Clubs** meet on fixed weekdays, so a club only meets on the story days that fall on its days (and on summer days). Reputation, shirts and rewards follow meetings attended. The club mini-games are simple timing and choice games.
- **Balance is untested over a full year of real play:** the XP curve's target (about level 20–25 by May), energy costs, boost strengths, prices, pay and the monthly stipend are first estimates. Achievements never pay XP, by design.
- **The hospital Food Court** is a separate floor of the hospital scene reached through the glass doors off the clinics corridor, with a fade (like the Emergency Department link); it isn't inside the lobby's footprint. Its diners are static, and two passers-by walk a fixed loop. In the overhead view, the rest of the building around the lobby's corridors is drawn as dark cut mass.
- **New buildings' passers-by** (Medical Education Center, library, Student Center, Anatomy Hall, Community Center, Food Court) move without physics on authored path graphs and are solid. `tests/interior_clearance_test.gd` and `tests/food_court_test.gd` keep their routes and side lanes clear of the furniture; they can still briefly overlap each other or pause in the student's way, and the scripted tests park them.
- **Content.** Every lecture, question, activity, club text, figure and exhibit is original, AI-assisted and awaiting human review (`MEDICAL_CONTENT_REVIEW.md`); the Medical Spanish phrases need a fluent reviewer. Patients, clinicians, abstracts, charts, strips and results are fictional. Figures are drawn from data (schematic micrographs, synthetic ECG strips, model spirometry curves), not images.
- **The original Pharmacodynamics bank** (Milestone 7) has most of its correct answers in position a (11 of 14); the new banks are balanced across a–d.
- **Saving.** Saves keep the calendar, money, skills, achievements, clubs and owned items (the save's `life` section). An activity or exam in progress isn't saved: a save mid-activity resumes before it, and answers already given keep their results (stable attempt ids).

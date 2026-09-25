# Known issues — Milestones 5–11

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
- The question bank holds the 12-question lecture set plus two remediation items. Human medical-content review is required before educational release.
- The configured lecture is a one-off event. Subsequent dates show no scheduled event; repeated daily academic calendars remain future content.
- NPC blockers are simple capsules. Moving NPCs push the player aside rather than steering around them.
- Campus buildings other than the residence and the Learning Center are scenery (no interiors). Cars are static props. Relief lettering uses Godot's built-in font, because the Outfit variable font fails TextMesh triangulation.
- Achievements and Inventory menu pages are previews, as the spec allows. The Campus Map is a plan view drawn from layout data.
- Saving mid-lecture resumes at the Hall A entrance; sitting again restarts the presentation. Answers already given keep their results and XP (attempt ids are stable), so nothing is double-counted.
- Ambient campus life is not tied to the clock: bench students eat lunch at 7:30 a.m. They are not saved either, so their timing and the dog's coat are random each visit. Ambient figures do not react to the player, beyond pedestrians stepping aside. They do not avoid Alex or Sam, so they can briefly overlap. The dog has no sounds.
- Test scripts share one test save slot (`user://savegame_test.json`, cleared at each script's start). Run them one at a time.
- First person:
  - The view preference and look sensitivity are per session, like volume and fullscreen; a fresh launch starts in third person.
  - Looking straight ahead shows no hands or arms.
  - Walking backwards or sideways uses the forward walk cycle, which is visible only in your shadow.
  - Standing right against an NPC can clip their head at the near plane.
  - Alex starts the morning at the residence door, so arriving on campus early puts you face to face.
  - Campus buildings other than the residence and the Learning Center still have no interiors. The Anatomy Hall's doors can be reached but not opened yet; the seminar on the lobby display is not yet an event.
  - Steps up to the Anatomy Hall collide as a smooth ramp, so feet can hover up to about 7 cm over the treads, as on Hall A's aisles.
  - The Cmd+F binding is fixed (not remappable).
- Characters and clothing:
  - Clothing is painted onto the character's pixel skin and its overlay shell. Only backpacks, buns, ponytails and cap brims are separate boxes. Long coats paint their skirts on the upper legs rather than hanging free.
  - Items unlock by level (rare Lvl 2, epic Lvl 3) or by finishing the first lecture. There is no shop, currency or drop system yet, and every unlocked item counts as owned. Outfit stats are cosmetic.
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

- **Scope.** The hospital is a partial slice: the Level 1 atrium, one inpatient unit (4 West) and, since September 24, the Emergency Department with Emergency Radiology (see below). The Outpatient Clinics, Level 2 mezzanine, 4 East and the other patient rooms are closed doors, roped stairs or scenery. The main elevators reach only Level 1 and Level 4; the directory lists eight floors.
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

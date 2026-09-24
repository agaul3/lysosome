# Known issues — Milestones 5–6

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

- Both simulated desktop environments and the shared offline study collection are functional. This is classic Anki-style scheduling, with deliberate differences (real-time UTC rollover, no fuzz/learning-ahead), not exact compatibility with Anki or FSRS. AnkiWeb, .apkg import/export, undo, rich-media cards and full OS window management remain unimplemented.
- Flashcard starter content retains the shared question bank's pending human medical review. Study XP rewards participation; self-rated recall never changes graded knowledge accuracy.
- Physical controller hardware and real multi-day use remain manual checks. See [FLASHCARD_SYSTEM.md](FLASHCARD_SYSTEM.md) for access instructions and design ideas.

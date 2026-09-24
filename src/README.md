# Medical School RPG — Vertical Slice v0.1 (Milestones 1–10)

A local educational RPG prototype where real medical learning will drive progression. This build implements character selection, a playable dorm, a small outdoor campus and the Learning Center lobby. An autonomous student walks to a classmate, exchanges a short conversation, then enters Hall A and sits down. The 5× academic clock, schedule and arrival penalty now work. A shared question engine is available for the lecture. Milestone 7 has begun. Hall A is a raked auditorium where the player can sit in any free seat, routed along the rows and aisles and animating into it, and the camera then transitions smoothly into a seated lecture view. At 8:00 (or press Space to wait for class) Dr. Lena Park presents the Pharmacodynamics lecture with live slides; press E to advance. During the competitive-antagonism segment, use A/D to adjust agonist concentration in a live receptor model, then predict and test what the antagonist does. Answer the lecture's questions with the arrow keys (or 1–4) and E; a results summary closes the lecture. Correct answers chime, float their XP and fill the level bar (top right); ten in a row shows a streak, and levelling up plays a short fanfare and banner. Progress autosaves; Continue on the title screen resumes where you left off. The menu (Tab) has an Overview, today's schedule, the calendar, a campus map, lecture notes and more; its Knowledge tab shows accuracy for Pharmacology, Pharmacodynamics and each subtopic, plus your recent answers. Double-tap and hold a movement key (or press L3) to sprint. The courtyard is busy: students eat lunch, read and take notes on the benches, others stroll the paths (and step aside for you), and someone walks their dog on the south-east lawn. Press Cmd+F (Ctrl+F on other systems, or the controller's View button), or use Settings, to switch between the default third-person view and first person, where the mouse looks around. Characters look like Minecraft figures. New Game opens a character creator: pick one of eight presets or build your own look (hair, eyes, face, skin, build, height and starting clothes). The oak wardrobe in your room opens a closet to change clothes and restyle, and the menu's Inventory is an equipment sheet for your outfit. Rarer clothes, such as the Patagonia fleece, unlock as you level up.

## Launch

Tested with **Godot 4.7.2.stable.official.ed1daf0bf**. Import `project.godot` in Godot and press F5, or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/adamgault3/Developer/personal/games/rpg_med/src
```

Choose **New Game**, choose a preset or create your student, then **Begin morning**. Interact with the dorm study desk to open the Windows-style PC; sign in with **player1 / 122333**, then open **Anki**. Equip a backpack in Inventory to carry a MacBook. Sit at the café study table or in a lecture seat, then press **L** or use Inventory to open its macOS-style desktop. Both computers share your cards and review history. Space reveals an answer; 1–4 rates recall. Esc closes the computer. The [flashcard design notes](docs/development/FLASHCARD_SYSTEM.md) explain the scheduler, XP and future ideas.

The green dorm door leads to campus and the Learning Center. Hall A offers the Pharmacodynamics lecture and return routes. Progress autosaves, and Continue resumes a saved game. The date/clock appear in the HUD; Tab opens the player menu while time and NPCs continue. The first Hall A entry records attendance for the configured 8:00 AM lecture; arriving after its deadline deducts 5 XP once.

## Controls

| Action | Keyboard/mouse | Standard controller |
|---|---|---|
| Move relative to camera | WASD | Left stick / D-pad |
| Interact with highlighted object | E | X / west face button |
| Player menu | Tab or Escape | Start or B / east face button |
| Confirm UI | Enter / Space / click | A / south face button |
| Back / close computer | Escape | B / east face button |
| Laptop (backpack + table/lecture seat) | L / Inventory | Inventory |
| Reveal flashcard / rate Good | Space / Enter | Focus button + A |
| Rate flashcard after reveal | 1–4 | Focus rating + A |
| Navigate UI | Arrows / Tab / mouse | D-pad |

Movement is normalized, uses Godot physics, and preserves analog strength. Settings block player movement while leaving the scene tree running. The HUD displays a single nearby interaction prompt and temporary response text.

## Structure

- `autoload/`: application phases, selected character ID, guarded scene transitions and persistent NPC event simulation.
- `data/`: stable character preset records, campus arrival points, morning-light configuration and authored NPC routes/dialogue.
- `player/`: reusable CharacterBody3D scene, movement, visual appearance, interaction detector.
- `world/`: shared original geometry, interaction endpoint, exploration camera.
- `world/dorm/`: furnished dorm scene.
- `world/campus/`: outdoor commons, directory and student encounter.
- `world/lecture_building/`: entry lobby and access to Hall A.
- `world/lecture_hall/`: minimal seating prototype for the autonomous NPC.
- `npc/`: reusable scene-local student views driven by persistent event state.
- `ui/`: title, selection preview, settings, shared contextual exploration HUD.
- `tests/`: dependency-free Godot integration tests.
- `docs/architecture/`, `docs/design/`, `docs/development/`, `docs/prompts/`: established documentation locations.
- Other existing domain directories remain reserved for later milestones. No new directories were needed.

## Tests

Run these from the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/foundation_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/dorm_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/campus_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/npc_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/academic_test.gd
```

The other suites run the same way: `visual_motion`, `room_polish`, `seating`, `lecture`, `progression`, `knowledge`, `save`, `ui`, `acceptance` (the full spec §46 slice), `ambient` (courtyard life), `first_person` (the first-person view) and `wardrobe` (characters, creator, clothing, closet, inventory), each as `res://tests/<name>_test.gd`. Run test scripts one at a time; they share a test save slot.

The dorm and campus suites each take about one minute. It exercises all presets, a complete walking/interaction/exit route, restart, physical keyboard and injected controller events, 30/60/120 Hz movement, furniture and boundary collision, overlapping/occluded/removed targets, and settings. Inspect output for errors as well as the check counts: Godot may return exit code 0 on some script errors.

The campus suite walks the full dorm → campus → lecture lobby → campus → dorm route, checks appearance continuity, directory/student interactions, camera follow, obstacles, settings and repeated entry.

For graphical testing, omit `--headless` from a test command. The campus and NPC tests optionally accept `-- --capture-dir=/absolute/existing/directory` to save rendered checkpoints. Also manually check mouse navigation, readable visuals, and fullscreen both ways; these are not established by headless tests.

See `docs/development/MILESTONES_5_6_ACCEPTANCE.md` for recorded results and `docs/architecture/ARCHITECTURE.md` for ownership. `docs/design/medical_school_rpg_spec.md` is authoritative; `PROJECT_SPEC.md` is its exact snapshot. Milestones 5 and 6 of the product specification define this run; no separate run documents were present. No third-party assets, runtime AI, or network services are used.

## Observing the NPC event

The event starts automatically on first arrival at campus. Alex begins near the residence, walks along the main path, and speaks with Sam near the bench. Follow Alex through the Learning Center and into Hall A to see the seated pose. The entire sequence takes roughly half a minute. It continues while settings is open or while another scene is loaded, does not replay on re-entry, and resets with New Game. There is no need to press Interact to trigger the encounter.

NPC navigation follows an authored AStar graph validated against fixed world obstacles. It does not implement dynamic crowd avoidance or player blocking. The small reserved-chair approach is the intentional exception to obstacle clearance. This scope keeps the prototype independent from the later clock and lecture systems.


## Academic configuration and engine

`data/academic_config.json` centralizes the fictional starting Monday (2026-09-21, 7:35 AM), 5× clock rate, semester/week, lecture date/time, grace interval, mandatory flag, penalty and tier rewards. This is game time independent of the computer's timezone/date. The campus sky/light broadly responds to time of day.

`GameClock` supports calendar rollover and emits minute changes. `AcademicSession` holds attendance, a signed XP ledger, attempted/correct counts and question history for this session. First entry to Hall A defines arrival for this milestone; player lecture seating does not exist yet. At zero XP a late entry produces -5 XP, and later rewards repay it. The level curve and final progression HUD are deferred.

`QuestionBank` validates/loads three original seed questions, grades multiple choice and predefined short answers, returns explanations and records valid submissions exactly once per attempt ID. See `education/questions/README.md` for schema and API. The engine is tested independently; there is no question delivery UI before Milestone 7. Invalid data/answers do not mutate performance or XP.

The academic suite validates time/calendar boundaries, non-pausing menus/NPCs, exact arrival/grace boundaries, real Hall A penalty feedback, re-entry, invalid question imports, answer formats, rewards, idempotency and performance. Run graphically with optional `-- --capture-dir=/absolute/existing/directory` for schedule/late-feedback captures. Session data is not saved to disk; Continue stays disabled.

# CHANGES — Medical School RPG handoff

**Recorded: 2026-09-23 05:03 PDT (2026-09-23 12:03 UTC).** This is a living Markdown handoff file. Add new change sets at the top, each with its own date and time. Times for the earlier milestone work were not recorded; their implementation dates come from `src/docs/development/CHANGELOG.md` and must not be mistaken for exact timestamps.

**Project:** Godot 4.7.2, Compatibility renderer. Open `src/project.godot`. The authoritative product requirements are in `src/docs/design/medical_school_rpg_spec.md` (also snapshotted as `src/PROJECT_SPEC.md`). Run-specific instructions live in `src/docs/prompts/` and `src/docs/development/`. User instructions in the current task take precedence over this handoff.

**Current state:** Milestones 1–6 are implemented. Milestone 7 has not been started. The more recent visual, room, and UI improvements below sit on top of Milestones 1–6. Work is uncommitted, and the working tree contains earlier uncommitted changes as well as the changes described here. Do not reset the tree to clean it. `git status --short` is the quickest inventory. The modified root `.DS_Store` predates some of this work and is unrelated to gameplay.

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
2. Inspect `git status --short` before editing; many files from Milestones 4–6 and subsequent polish are intentionally uncommitted.
3. Run tests with `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/<suite>.gd`. Existing suites are `foundation_test.gd`, `dorm_test.gd`, `campus_test.gd`, `npc_test.gd`, `academic_test.gd`, `visual_motion_test.gd`, and `room_polish_test.gd`. Use `--path src --editor --import --quit` to validate import. Run graphical capture when visual behavior changes.
4. Update this file with a new timestamped section at the top for each future change set. Preserve the user's preference for plain floor surfaces and subtle wood grain.

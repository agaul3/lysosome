# CHANGELOG — Medical School RPG handoff

**Recorded: 2026-09-23 05:03 PDT (2026-09-23 12:03 UTC).** This is a living Markdown handoff file. Add new change sets at the top, each with its own date and time. Times for the earlier milestone work were not recorded; their implementation dates come from the former `src/docs/development/CHANGELOG.md`, which was merged into this file during the Milestones 4–6 cleanup commit and must not be mistaken for exact timestamps.

**Project:** Godot 4.7.2, Compatibility renderer. Open `src/project.godot`. The authoritative product requirements are in `src/docs/design/medical_school_rpg_spec.md` (also snapshotted as `src/PROJECT_SPEC.md`). Run-specific instructions live in `src/docs/prompts/` and `src/docs/development/`. User instructions in the current task take precedence over this handoff.

**Current state:** Milestones 1–6 are implemented and committed. Milestone 7 is in progress: Hall A seating is done; the lecture camera, professor presentation, visualization, questions and completion remain. The more recent visual, room, and UI improvements below sit on top of Milestones 1–6. (This note originally said the work was uncommitted; it has since been committed — see the 2026-09-23 documentation entry above.)

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
3. Run tests with `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/<suite>.gd`. Existing suites are `foundation_test.gd`, `dorm_test.gd`, `campus_test.gd`, `npc_test.gd`, `academic_test.gd`, `visual_motion_test.gd`, `room_polish_test.gd`, and `seating_test.gd`. Use `--path src --editor --import --quit` to validate import. Run graphical capture when visual behavior changes.
4. Update this file with a new timestamped section at the top for each future change set. Preserve the user's preferences: plain floor surfaces, subtle wood grain, a small HUD with unboxed keycap prompts, and physically plausible character motion around furniture.

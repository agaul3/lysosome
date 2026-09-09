# Milestone 3 — PASS

Completed 2026-09-10 with Godot 4.7.2.stable.official.ed1daf0bf on macOS / Apple M1 using the Compatibility renderer. No separate Run #3 instruction file existed; this run follows Milestone 3 in the authoritative product specification.

## Implemented

- Compact original 3D campus with residence and Learning Center exteriors, paths, courtyard, palms, benches, static students and solid boundaries.
- Dorm → campus → Learning Center lobby transitions and a complete return route, preserving selected appearance and choosing the appropriate arrival point.
- Campus directory, one static student conversation, and Hall A inspection using the existing interaction architecture.
- Bounded smooth orthographic camera follow on campus; fixed interior cameras retained.
- Configured morning sunlight and ambient lighting. No running clock or schedule yet.
- Shared location/objective HUD with readable text backgrounds, and existing session settings reused.
- Updated README, architecture, changelog, known issues and tests. No new directories. Obsolete Milestone 2 exit-placeholder scene/script removed.

## Tested

| Check | Result |
|---|---|
| Headless editor import after final changes | PASS, exit 0, no script errors/warnings |
| Foundation regression suite | 54 checks, zero failures |
| Dorm regression suite, including final shared HUD | 68 checks, zero failures |
| Campus suite, headless | 37 checks, zero failures |
| Campus suite with OpenGL rendering and three captured checkpoints | 40 checks, zero failures; rerun after visual improvements |
| Visual inspection of captured campus and lobby | PASS; signs, text contrast and lobby lighting corrected |
| Git whitespace/diff check | PASS |

The acceptance route used actual semantic input and physics movement, without teleporting: New Game → chosen preset → dorm exit → directory → student → Learning Center entry → Hall A → campus → residence → dorm. Separate collision probes checked campus boundaries, planter and building frontage. Additional checks cover appearance continuity, camera bounds/orientation, re-entry spawn points, duplicate transition requests, settings/input state and New Game reset.

An initial test reused one synthetic input event in the same frame; it was corrected to use a distinct release event. Collision test thresholds were corrected to the obstacle faces plus capsule clearance. Final runs reported no such warnings or failures. Visual review found clipped signs and poor outdoor/lobby contrast; final rendered checkpoints were re-inspected after fixes.

## Architecture decisions

AppState's existing scene map and guarded deferred transitions now cover CAMPUS and LECTURE_BUILDING. A small campus-entry key determines the return spawn and is protected while a transition is pending. The existing player, interaction endpoint, geometry and appearance components are reused. The camera supports optional translation-only follow, preserving its movement basis. The existing `ui/dorm_ui.gd` is configurable and shared rather than duplicated. Presentation and arrival configuration live in `data/campus_config.gd`.

## Known limitations

No known critical Milestone 3 blocker. Students are static; autonomous behavior is Milestone 4. Morning presentation is static; the clock and schedule are Milestone 5. Hall A is only an inspection endpoint; lecture content and seating remain deferred. Save/load and physical controller hardware verification remain outstanding as documented in earlier milestones. No runtime AI or external assets were introduced.

## Files of interest

- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/campus/campus.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/campus/campus.tscn`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/lecture_building/lecture_building.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/data/campus_config.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/exploration_camera.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/autoload/app_state.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/ui/dorm_ui.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/tests/campus_test.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/docs/architecture/ARCHITECTURE.md`

## Git status and next milestone

Changes are uncommitted: tracked files modified, the obsolete placeholder files deleted, and new campus/lobby/config/test/report files untracked, with Godot UID companions. The pre-existing parent `.DS_Store` change was left untouched. Source product specifications were not changed. No new directories were created.

Milestone 4 will implement the autonomous NPC sequence, navigation, conversation and seating route. It has not been started.

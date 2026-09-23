# Milestone 4 — PASS

Completed 2026-09-10. Engine: Godot 4.7.2.stable.official.ed1daf0bf, macOS / Apple M1, Compatibility renderer. No separate Run #4 file was present, so the product specification's Milestone 4 defines this run.

## Implemented

Alex autonomously walks from the residence side of campus to Sam, exchanges three original predefined lines, continues to the Learning Center, traverses the lobby, enters Hall A, reaches a reserved chair and sits down. No interaction is required to start the sequence. It starts once on first campus arrival, continues with settings open or scenes unloaded, survives re-entry and resets on New Game.

Added a reusable student scene/view, persistent event state machine, authored AStar3D route graphs, world-space dialogue, a seated pose, and the minimum Hall A geometry/return route needed to observe seating. Earlier player, settings and interaction behavior is retained. The Hall A placeholder was upgraded to an actual doorway. No lecture camera, player seating, questions, progression, live AI or running game clock was added.

## Actual validation

| Test | Result |
|---|---|
| Foundation regression | 54 checks, zero failures |
| Dorm regression | 68 checks, zero failures |
| Campus regression, including Hall A entry/return | 38 checks, zero failures |
| NPC model/integration/route suite, headless | 33 checks, zero failures |
| Same NPC suite with OpenGL and two rendered checkpoint captures | 35 checks, zero failures |
| Visual inspection of conversation and seated pose captures | Passed |
| Final Godot editor import | Exit 0, no script errors/warnings |
| Git whitespace check | Passed |

The NPC suite checks 30/60/120 Hz movement consistency, long-frame stage consumption, ordered stages and alternating speakers, one-time seating, reset, automatic campus start, progress while settings is open, offscreen dialogue, re-entry without replay, view visibility and the seated pose. Capsule samples validate route clearance against the loaded worlds, excluding the intentional final approach into the reserved chair.

The graphical sequence ran in the actual game engine. Captures were reviewed: Alex's speech is visible beside Sam, and Alex is seated facing the display in Hall A. Earlier scene traversal and interaction regressions continue to pass. The campus suite now enters and exits Hall A rather than expecting the superseded inspection placeholder.

## Architecture decisions

- NPCSchedule is a second autoload because the event must keep advancing while its scene is unloaded. It owns stage, zone, position, facing, dialogue and completion; scene-local views own only rendering.
- Authored AStar3D graphs keep the small known route understandable and testable without introducing a navmesh/crowd framework. Route timing and conversation are centralized data.
- Remaining delta is consumed across state boundaries, so low frame rates and long frames do not skip dialogue or break progression.
- Zone portals transfer the actor's model between independent world coordinate systems. The player uses the existing AppState transition architecture.
- The shared appearance builder supplies the seated pose; rebuilding first prevents accumulated offsets on repeated pose changes.

## Known limitations

No known critical Milestone 4 blocker. NPCs are nonblocking views; dynamic collision avoidance, player blocking and replanning around newly placed obstacles are not implemented. Paths are authored for the fixed world and validated against its solids. The final reserved-chair approach intentionally enters the chair geometry to reach the seated pose. The event uses elapsed seconds rather than the future academic/game clock. Save/load and physical-controller hardware validation remain deferred as before.

## Structure and files of interest

No new directories. Existing `npc`, `autoload`, `data`, `player`, `world/lecture_hall`, `tests` and documentation folders were reused.

- `/Users/adamgault3/Developer/personal/games/rpg_med/src/autoload/npc_schedule.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/data/npc_route.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/npc/student.tscn`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/npc/student.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/player/appearance.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/lecture_hall/lecture_hall.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/tests/npc_test.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/docs/architecture/ARCHITECTURE.md`

## Git and next milestone

Changes are uncommitted: modified tracked project files and new untracked NPC/route/hall/test/document files with Godot UID companions. The pre-existing parent `.DS_Store` modification was left untouched. Source product specifications were not changed.

Milestone 5 covers the 5× game clock, structured schedule, arrival classification and one-time lateness penalty. It has not been started.

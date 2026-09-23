# Architecture — Milestones 1–6

## Application and scenes

`project.godot` owns semantic input bindings, Compatibility rendering, the start scene, and the AppState and NPCSchedule autoloads. AppState owns TITLE, CHARACTER_SELECT, DORM, CAMPUS, LECTURE_BUILDING and LECTURE_HALL phases plus the selected preset's stable string ID. New Game resets the selection to the default. Invalid selection is rejected without changing the current selection.

The title owns its settings and character-selection panels. Beginning the morning, leaving the dorm, entering/leaving the lecture building, returning to the dorm, and returning to the title use a centralized scene-path map in AppState and Godot's `change_scene_to_file`. Transitions are deferred until input/physics callbacks finish, duplicate requests are ignored while a transition is in progress, and phase changes are signaled after the destination is ready. A failure restores the previous phase and emits `transition_failed` with the engine error.

Milestone 4 adds NPCSchedule as a persistent model, described below. The temporary Milestone 2 exit scene has been retired. Campus and the lecture-building lobby use the existing world domain folders. AppState retains a small campus-entry key so returning from the lobby spawns at its entrance while leaving the dorm spawns at the residence. Pending transitions cannot overwrite that key. Scene replacement frees the previous player and HUD, so returning creates a fresh spawn without stale targets or motion.

## Player and appearance

`player/player.tscn` is a reusable CharacterBody3D with capsule collision, an Appearance child, and an Interaction child. The body is on layer 2 and collides with world layer 1. The collision capsule is independent of visual appearance.

`player/player.gd` samples the semantic movement actions with `Input.get_vector`, projects them onto the camera's horizontal right/backward basis, and limits the result to unit length. Horizontal velocity is metres per second; `move_and_slide` integrates it using the physics timestep. Gravity uses delta. Facing interpolation is exponential in delta. No jumping or combat is implemented.

`data/character_presets.gd` contains four original presets, each with a stable ID, display description, colors and simple hair style. The selection preview and spawned player use the same `player/appearance.gd` builder, so the preview and gameplay share appearance data. The visual child can later host animation without changing locomotion. Only the selected ID belongs in future save data; save/load is not implemented now.

## Camera and world

`world/exploration_camera.gd` is a separate orthographic Camera3D component with fixed room framing by default. Campus enables bounded, exponentially smoothed follow: only translation changes, preserving orientation and movement basis. The camera snaps to the initial target before rendering and stays within configured campus bounds. A fixed camera keeps the small dorm readable and avoids movement jitter. Movement uses its basis rather than hard-coded world directions. Future scenes can substitute another camera component; no lecture camera is built.

`world/dorm/dorm.gd` owns the room and furniture layout, static colliders, lighting, three interaction endpoints, and player/UI assembly. `world/geometry.gd` provides a small shared factory for original boxes, spheres and materials. Major furniture and all four walls are solid. Near walls are visually cut away but retain full-height colliders. Desk, bed, chair, bookshelf, storage, laptop, textbooks and simple decor communicate student living without external assets.

## Interaction and UI

`world/interactable.gd` is a reusable endpoint with a name, response, configurable reach, highlight, and activation signal. Its owner connects behavior; the desk and bed display text, while the exit calls the scene transition. Nothing in this component depends on study questions, NPCs or doors.

`player/interaction.gd` picks the closest endpoint within reach whose ray is not blocked by a world collider. Only that endpoint is highlighted. It emits target, device and activation signals; pressed semantic interact events ignore key echo. Explicit handling for removed targets prevents stale HUD references. Physics queries ignore the player's collision layer.

`ui/dorm_ui.gd` observes interaction signals and shows one contextual prompt, using keyboard or controller wording based on the last input device. A timer clears response text. The small settings overlay reuses Milestone 1 settings and disables player movement/interaction without pausing the scene tree. No final HUD, knowledge pages, schedule, inventory or achievement UI has been added.

## Documentation and deferred systems

All existing domain directories were reused; no new directories were created. Documentation stays in the user's reorganized `docs/architecture`, `docs/design`, `docs/development` and `docs/prompts` structure. Foundation tests were updated for those paths; the source product specification and PROJECT_SPEC snapshot remain unchanged.

Campus traversal, the lecture-building lobby and the prototype NPC event are implemented; centralized time/schedule is Milestone 5. Questions, lecture, XP/levels/streaks, knowledge tracking and local saves remain unimplemented. No speculative interfaces or global managers were added for them. The future menu must continue to leave time and NPC simulation running.

## Verification

`tests/foundation_test.gd` retains the foundation checks, with New Game now expected to open selection rather than the superseded foundation placeholder. `tests/dorm_test.gd` exercises actual scenes, inputs, physics, interactions and transitions. Its acceptance route walks from spawn to desk, bed and exit without teleporting. Separate collision probes reposition the player for coverage but skip physically invalid starting positions inside adjacent solids. The tests vary physics tick rate and inject keyboard/controller events; physical controller hardware remains a separate manual check.


## Campus and lecture building — Milestone 3

`world/campus/campus.gd` owns a bounded 28×24 metre courtyard, residence exterior, lecture-building exterior, paths, palms, seating, a directory and two student figures. The player, geometry helpers, appearance builder and interaction endpoint are reused. Sam offers fixed directions through the same interaction interface as the directory. Alex now follows the autonomous route and conversation controlled by NPCSchedule.

`world/lecture_building/lecture_building.gd` is an explorable entry lobby, not a lecture hall. Its Hall A door now enters the minimal NPC seating prototype. Both scenes reuse `ui/dorm_ui.gd`, now configurable through location_title and objective_text; the existing filename is retained to avoid needless duplication/renaming. Settings and contextual prompt behavior are shared.

`data/campus_config.gd` centralizes morning presentation values and campus arrival positions. Warm low-angle sunlight, ambient light and a morning caption establish the setting. The configured 7:35 is presentation metadata, not a running game clock or schedule. Milestone 5 remains responsible for time progression.

No new directories were created. The obsolete `world/dorm/exit_destination.tscn` and `ui/exit_destination.gd` were removed. The dorm regression test now expects the actual campus destination while preserving its movement, collision and interaction checks. `tests/campus_test.gd` reuses the dorm harness's movement helpers for the full return route, and separately tests obstacles, boundaries, camera behavior and state continuity.


## Autonomous NPC prototype — Milestone 4

`autoload/npc_schedule.gd` owns the event state machine: IDLE → APPROACH → CONVERSATION → TO_BUILDING → LOBBY → TO_SEAT → SEATED. Campus starts it once without player interaction. Scene changes and menus do not pause it. New Game explicitly resets it. Signals expose stage changes and spoken lines; the model stores position, facing, zone and current dialogue. It consumes remaining delta across state boundaries so long frames do not drop movement or dialogue stages.

`data/npc_route.gd` holds the original three-line conversation, walking speed, line duration and per-zone waypoint graphs. AStar3D produces paths through authored open corridors. This is a small deterministic navigation prototype rather than a baked navmesh or a general crowd simulation. Zone portals map to separate lobby/hall coordinate systems. Test capsule sweeps sample those paths against static world solids, excluding the final reserved-chair approach.

`npc/student.tscn` and its script are scene-local views for Alex and Sam. Each loaded scene owns its view; the view reads the persistent model and is visible only in the actor's current zone. Thus the actor can advance while its scene is unloaded and reappear at the correct position. Sam remains near the bench; both speakers display world-space dialogue. NPC views are nonblocking to the player and do not implement dynamic avoidance. Fixed-geometry clearance is established by authored routes and tests.

`player/appearance.gd` now supports a simple seated pose with bent thighs and shins, reused by the NPC view. The pose rebuilds from the preset to avoid accumulating offsets across repeated applications. `world/lecture_hall/lecture_hall.tscn` provides only the geometry, reserved chair, player exploration and lobby return needed to observe the event. Player seating, professor, lecture camera, questions, rewards and a game clock are not implemented here.

`tests/npc_test.gd` verifies 30/60/120 Hz consistency, large-delta state transitions, ordered dialogue, one-time completion, New Game reset, unprompted start, offscreen/menu progress, route clearance, visible speech, seating and re-entry. Earlier suites continue to run; the campus suite now traverses the Hall A doorway and returns rather than inspecting its superseded placeholder.

No new directories: the existing npc/, world/lecture_hall/, autoload/, data/ and tests/ domains were reused.


## Time, schedule and question engine — Milestones 5–6

`GameClock` owns configured starting time and elapsed game seconds, at 5× real delta. Snapshots expose day index (plus day_of_month), date, hour/minute/second, weekday, academic week and semester. Godot calendar conversion handles leap days and year rollover. AppState starts/stops the clock after successful world/title transitions; character selection is untimed. Menus never pause the scene tree. NPCSchedule remains an elapsed-time autonomous prototype and continues independently.

`data/academic_config.json` is the single source for starting date/time, lecture event, grace interval, penalty and default XP tiers. `data/campus_config.gd` retains only visual palette/spawns. Campus lights and sky respond to clock minute changes; indoor scenes remain artificially lit.

`AcademicSession` owns per-event/date attendance and a minimal signed XP ledger. Arrival is recorded only after a successful Hall A scene transition. Exactly-at-start is on time; strictly after start plus configurable grace is late. First attendance is immutable, wrong-date/unknown events do nothing, and optional events incur no penalty. A zero-XP late arrival stores -5 rather than silently dropping the penalty; rewards repay it. This is not a level progression implementation.

The shared exploration menu now contains Today, Calendar and Settings. Both schedule pages consume structured data. HUD minute updates show the date/time and arrival signals produce visible feedback; attendance remains visible in the schedule after the toast expires.

`QuestionBank` owns the versioned JSON database and strict schema/answer validation. Imports replace the bank atomically only after every record validates; readers receive deep copies. Pure grade() has no side effects. submit() uses caller-supplied attempt IDs to prevent duplicate XP/performance writes and reject conflicting retries. Valid outcomes commit to AcademicSession and emit answer_recorded for future systems. Minimal discipline/topic/subtopic counters are hooks for Milestone 9; no Knowledge interface or sophisticated mastery algorithm is built.

The three original seed questions demonstrate loading/grading and are documented for human review. Short answers use predefined strings only. The approximately twelve-item lecture, delivery, remediation, camera/seating, streaks, level curve/feedback and save system remain later work. No new directories were introduced.

Earlier milestone sections describe the state at their completion; the academic clock and Hall A attendance in this section supersede earlier statements about static time or deferred schedule/question systems.

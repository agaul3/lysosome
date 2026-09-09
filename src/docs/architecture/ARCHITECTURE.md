# Architecture — Milestones 1–3

## Application and scenes

`project.godot` owns semantic input bindings, Compatibility rendering, the start scene, and the single AppState autoload. AppState owns TITLE, CHARACTER_SELECT, DORM, CAMPUS and LECTURE_BUILDING phases plus the selected preset's stable string ID. New Game resets the selection to the default. Invalid selection is rejected without changing the current selection.

The title owns its settings and character-selection panels. Beginning the morning, leaving the dorm, entering/leaving the lecture building, returning to the dorm, and returning to the title use a centralized scene-path map in AppState and Godot's `change_scene_to_file`. Transitions are deferred until input/physics callbacks finish, duplicate requests are ignored while a transition is in progress, and phase changes are signaled after the destination is ready. A failure restores the previous phase and emits `transition_failed` with the engine error.

No additional global manager was necessary. The temporary Milestone 2 exit scene has been retired. Campus and the lecture-building lobby use the existing world domain folders. AppState retains a small campus-entry key so returning from the lobby spawns at its entrance while leaving the dorm spawns at the residence. Pending transitions cannot overwrite that key. Scene replacement frees the previous player and HUD, so returning creates a fresh spawn without stale targets or motion.

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

Campus traversal and the lecture-building lobby are now implemented; NPC state/scheduling is Milestone 4; centralized time/schedule is Milestone 5. Questions, lecture, XP/levels/streaks, knowledge tracking and local saves remain unimplemented. No speculative interfaces or global managers were added for them. The future menu must continue to leave time and NPC simulation running.

## Verification

`tests/foundation_test.gd` retains the foundation checks, with New Game now expected to open selection rather than the superseded foundation placeholder. `tests/dorm_test.gd` exercises actual scenes, inputs, physics, interactions and transitions. Its acceptance route walks from spawn to desk, bed and exit without teleporting. Separate collision probes reposition the player for coverage but skip physically invalid starting positions inside adjacent solids. The tests vary physics tick rate and inject keyboard/controller events; physical controller hardware remains a separate manual check.


## Campus and lecture building — Milestone 3

`world/campus/campus.gd` owns a bounded 28×24 metre courtyard, residence exterior, lecture-building exterior, paths, palms, seating, a directory and two static student figures. The player, geometry helpers, appearance builder and interaction endpoint are reused. One student offers a fixed greeting/directions through the same interaction interface as the directory. There is no NPC movement, schedule or dialogue state machine yet.

`world/lecture_building/lecture_building.gd` is an explorable entry lobby, not a lecture hall. Its Hall A interaction marks the current gameplay boundary. Both scenes reuse `ui/dorm_ui.gd`, now configurable through location_title and objective_text; the existing filename is retained to avoid needless duplication/renaming. Settings and contextual prompt behavior are shared.

`data/campus_config.gd` centralizes morning presentation values and campus arrival positions. Warm low-angle sunlight, ambient light and a morning caption establish the setting. The configured 7:35 is presentation metadata, not a running game clock or schedule. Milestone 5 remains responsible for time progression.

No new directories were created. The obsolete `world/dorm/exit_destination.tscn` and `ui/exit_destination.gd` were removed. The dorm regression test now expects the actual campus destination while preserving its movement, collision and interaction checks. `tests/campus_test.gd` reuses the dorm harness's movement helpers for the full return route, and separately tests obstacles, boundaries, camera behavior and state continuity.

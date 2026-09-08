# Architecture — Milestone 1

## Current ownership

`project.godot` owns input bindings, the startup scene, display configuration, and the single AppState autoload. Compatibility rendering supports this UI foundation and a future low-poly 3D world; this does not replace the required 3D orthographic exploration architecture with a 2D world.

`autoload/app_state.gd` owns only the TITLE/FOUNDATION phase enum and emits `phase_changed` when it changes. Repeating the same request is safe. There is no gameplay state, save data, timer, or speculative manager infrastructure.

`ui/start_screen.tscn` owns the UI shell. Its script constructs container-based layout, observes application phase signals, and owns keyboard/controller focus. New Game changes phase to an explicit foundation screen. This is a functional routing boundary, not character selection or a dorm stub. Returning changes phase to TITLE. Quit calls SceneTree.quit.

`ui/settings_panel.gd` owns master-bus volume and fullscreen controls. These apply immediately and last for the session, without introducing gameplay persistence. UI code never pauses the scene tree. Layout scales from a 1152×720 reference viewport via canvas_items.

The source specification and its PROJECT_SPEC snapshot are preserved byte-for-byte. The earlier “Game Design Document & Technical Product Specification v0.1.md” is left untouched and was not used to override the designated source of truth.

## Deferred responsibilities

These are product requirements, not implemented systems:

- Player, collisions, 3D orthographic camera, appearances, dorm: Milestone 2.
- Actual scene transition manager: add when world scenes need transitions.
- Time/schedule: centralized configured 5× clock and structured events in Milestone 5; menu must leave time and NPCs running.
- Questions: shared structured records, answer evaluation, explanations in Milestone 6; format choice remains deferred.
- XP/levels, knowledge, streaks: dedicated systems when their milestones require them; no curve selected prematurely.
- NPC state machine: introduced with autonomous campus behavior in Milestone 4.
- Save/load: versioned local slot later, persisting the full fields required by the product specification. Continue remains unavailable until meaningful save data exists.
- Lecture/audio/medical content: deferred; no runtime AI dependency.

This keeps future ownership clear without creating empty managers or untested future features. Signals connect current application flow to its view; gameplay systems should follow the same focused ownership principle.

## Verification

The test harness runs in Godot with the autoload and real UI scene. It checks input bindings, structure, specification preservation, UI transitions, focus, volume, non-pausing behavior, injected keyboard/controller events, repeat transitions, and actual Quit. Graphical checks cover rendering and platform window mode, which the headless display cannot validate.

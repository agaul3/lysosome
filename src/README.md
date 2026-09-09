# Medical School RPG — Milestone 3

A local educational RPG prototype where real medical learning will drive progression. This build implements character selection, a playable dorm, a small outdoor campus and the Learning Center lobby. Educational systems remain deferred.

## Launch

Tested with **Godot 4.7.2.stable.official.ed1daf0bf**. Import `project.godot` in Godot and press F5, or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/adamgault3/Developer/personal/games/rpg_med/src
```

Choose **New Game**, select one of four student appearances, then **Begin morning**. Walk to the desk or bed and interact. The green door leads to campus. Inspect the directory, talk to a student, follow the path to the Learning Center, and enter its lobby. Hall A can be inspected; the lecture itself arrives later. Both the lobby and residence doors support returning. Continue is disabled until save/load exists. Settings apply volume/fullscreen for the current session.

## Controls

| Action | Keyboard/mouse | Standard controller |
|---|---|---|
| Move relative to camera | WASD | Left stick / D-pad |
| Interact with highlighted object | E | X / west face button |
| Dorm settings | Tab or Escape | Start or B / east face button |
| Confirm UI | Enter / Space / click | A / south face button |
| Back | Escape | B / east face button |
| Navigate UI | Arrows / Tab / mouse | D-pad |

Movement is normalized, uses Godot physics, and preserves analog strength. Settings block player movement while leaving the scene tree running. The HUD displays a single nearby interaction prompt and temporary response text.

## Structure

- `autoload/`: application phases, selected character ID, guarded scene transitions.
- `data/`: stable character preset records, campus arrival points and morning-light configuration.
- `player/`: reusable CharacterBody3D scene, movement, visual appearance, interaction detector.
- `world/`: shared original geometry, interaction endpoint, exploration camera.
- `world/dorm/`: furnished dorm scene.
- `world/campus/`: outdoor commons, directory and static student interaction.
- `world/lecture_building/`: entry lobby and Hall A marker.
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
```

The dorm and campus suites each take about one minute. It exercises all presets, a complete walking/interaction/exit route, restart, physical keyboard and injected controller events, 30/60/120 Hz movement, furniture and boundary collision, overlapping/occluded/removed targets, and settings. Inspect output for errors as well as the check counts: Godot may return exit code 0 on some script errors.

The campus suite walks the full dorm → campus → lecture lobby → campus → dorm route, checks appearance continuity, directory/student interactions, camera follow, obstacles, settings and repeated entry.

For graphical testing, omit `--headless` from a test command. The campus test optionally accepts `-- --capture-dir=/absolute/existing/directory` to save rendered checkpoints. Also manually check mouse navigation, readable visuals, and fullscreen both ways; these are not established by headless tests.

See `docs/development/MILESTONE_3_ACCEPTANCE.md` for recorded results and `docs/architecture/ARCHITECTURE.md` for ownership. `docs/design/medical_school_rpg_spec.md` is authoritative; `PROJECT_SPEC.md` is its exact snapshot. Milestone 3 of the product specification defines this run; no separate Run #3 document was present. No third-party assets, runtime AI, or network services are used.

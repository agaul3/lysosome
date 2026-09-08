# Medical School RPG — Milestone 1

A local educational RPG prototype in which real medical learning will drive progression. This build contains only the project foundation. It has no explorable world or medical content yet.

## Launch

Tested with **Godot 4.7.2.stable.official.ed1daf0bf**, the installed stable Godot 4.x version. No third-party dependencies or runtime network services.

Import `project.godot` in Godot and press F6 with `ui/start_screen.tscn` open, or F5 to run the project. On this Mac:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/adamgault3/Developer/personal/games/rpg_med/src
```

New Game opens a foundation placeholder with Back to title. Continue is disabled because save/load is deferred. Settings changes master volume and fullscreen for the current session. Quit closes the application.

## Controls

| Action | Keyboard | Standard controller |
|---|---|---|
| Movement (reserved) | WASD | Left stick / D-pad |
| Interact (reserved) | E | X / west face button |
| Player menu (reserved) | Tab | Start |
| Confirm | Enter / Space | A / south face button |
| Cancel / Back | Escape | B / east face button |
| Title/settings navigation | Arrow keys / Tab / mouse | D-pad / built-in UI navigation |

Gameplay actions are configured but deliberately have no movement or interaction consumer yet. Godot's built-in `ui_*` actions handle Control navigation; semantic `confirm`/`cancel` support application actions. Analog movement uses a 0.25 deadzone.

## Structure

- `autoload/`: minimal application flow.
- `ui/`: start scene and session settings.
- `player/`, `npc/`, `world/{dorm,campus,lecture_building,lecture_hall}/`: reserved directories only.
- `education/{questions,lectures,models}/`: reserved directories only.
- `audio/`, `assets/`, `data/`, `docs/`: reserved content/documentation locations.
- `tests/`: dependency-free Godot integration harness.

## Test

From the project root (or replace `.` with its absolute path):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/foundation_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 120
```

Require zero failures and inspect console output for script/runtime errors, not just the process exit code. Graphical acceptance: launch, activate New Game and Back, open Settings, change volume, toggle fullscreen both ways, return with Escape, verify disabled Continue, and Quit. Physical controller hardware should also be checked when available.

See `docs/MILESTONE_1_ACCEPTANCE.md` for actual validation results and `ARCHITECTURE.md` for ownership and deferred work. `medical_school_rpg_spec.md` is authoritative; `PROJECT_SPEC.md` is its exact immutable snapshot. The run file limits this implementation to Milestone 1.

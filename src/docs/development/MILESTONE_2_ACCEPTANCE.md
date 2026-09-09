# Milestone 2 — PASS

Completed 2026-09-10 with Godot 4.7.2.stable.official.ed1daf0bf on macOS / Apple M1, Compatibility renderer.

## Implemented

Four preset students with shared 3D preview/gameplay appearance data; reusable player movement, collision and interaction components; camera-relative keyboard/controller movement; fixed orthographic 3D exploration camera; original low-poly furnished dorm; contextual desk and bed responses; a usable exit and temporary destination; clean return/restart; and reused session settings. Documentation updated in the existing locations. No Milestone 3 content was built.

## Tested

- Headless editor import: exit 0, no script errors or warnings in the final output.
- Foundation integration suite: **54 checks, zero failures**, including title, disabled Continue, New Game/Back, focus, settings volume, keyboard/controller confirm/cancel and actual Quit.
- Dorm integration suite, headless: **68 checks, zero failures** after fixes.
- Same dorm integration suite with the actual OpenGL graphical renderer: **68 checks, zero failures**, exit 0, no runtime errors/warnings in the final log.
- Actual route tested without teleporting: title → New Game → preset → dorm → walk to desk → prompt/interaction → walk to bed → interaction → walk to exit → scene transition → return to a fresh dorm.
- All four presets reached gameplay with the expected material colors; invalid selection was rejected safely.
- Physical keyboard events and injected controller stick events moved the character. Diagonal velocity stayed within configured speed; movement was checked at 30, 60 and 120 physics ticks per second.
- Collision probes verified bed, desk, chair, bookshelf, storage and all room boundaries. Probes from invalid positions overlapping adjacent furniture are skipped, rather than treating an embedded spawn as ordinary gameplay.
- Interaction checks covered range, one dominating nearest prompt, occlusion, key echo, removed targets, response text and restart cleanup.
- Direct desktop checks verified rendered title, mouse New Game/preset selection, rendered dorm, settings overlay, fullscreen on/off and Escape return. Character-preview lighting was subsequently improved and exercised in the graphical suite. A final optional desktop re-inspection encountered computer-use state errors; it did not affect the completed graphical integration run.
- `git diff --check` passed.

## Regression testing

Milestone 1 tests remain at 54 checks. Five pre-existing failures were stale documentation paths after the user's folder reorganization; the tests now use the established docs locations. The New Game expectation was updated from the obsolete foundation placeholder to character selection. Other foundation behavior remains intact. The source specification and PROJECT_SPEC are unchanged and match byte-for-byte.

## Architecture decisions

One AppState autoload owns the stable selected-character ID and guarded, deferred scene replacement. Player locomotion, appearance and interaction remain separate components. The camera is separate and fixed for room readability. Interactables emit signals; owning scenes provide behavior. Settings disable player input without pausing the scene tree. All geometry is original. No save manager or future education systems were introduced.

Testing exposed and fixed a stale HUD reference when a target was freed. It also exposed a collision probe that began inside the desk/chair gap; the probe now checks that its starting capsule fits before driving the player.

## Known issues

No known critical Milestone 2 blocker. Physical controller hardware remains unverified; controller events and mappings are tested. Save/load and persistent settings are deferred. Visuals are simple low-poly placeholders. The campus is intentionally a temporary destination screen only.

## Files of interest

- `/Users/adamgault3/Developer/personal/games/rpg_med/src/player/player.tscn`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/player/player.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/player/interaction.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/player/appearance.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/data/character_presets.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/dorm/dorm.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/world/dorm/exit_destination.tscn`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/autoload/app_state.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/ui/character_selection.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/ui/dorm_ui.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/tests/dorm_test.gd`
- `/Users/adamgault3/Developer/personal/games/rpg_med/src/docs/architecture/ARCHITECTURE.md`

## Project structure

No new directories. Files reuse `player`, `data`, `world`, `world/dorm`, `ui`, `tests`, `autoload` and the existing documentation folders. Godot-generated `.gd.uid` companions should be committed with their scripts; `.godot/` remains ignored.

## Git status

Changes are uncommitted. Existing tracked files were modified and new Milestone 2 scripts/scenes/tests are untracked. The user's new Run #2 instruction file remains untracked. The pre-existing parent `.DS_Store` modification was left untouched. No commit, reset or source-document rewrite was performed.

## Next milestone

Milestone 3 will cover campus traversal and the lecture-building exterior/entry. It has not been started.

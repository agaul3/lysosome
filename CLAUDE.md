# Medical School RPG — Claude Code project instructions

Read `CHANGELOG.md` (repository root) first. It is the running handoff log and records completed work, current limitations, user preferences, and test commands. Keep it updated: prepend each new change set with its actual local date and time. Do not invent timestamps for earlier work.

Read `src/docs/design/medical_school_rpg_spec.md` before changing product behavior. It is the authoritative product specification. For milestone work, read the relevant run document under `src/docs/prompts/` or `src/docs/development/`; the run document determines the current scope. Follow any newer instruction from the user when it changes that scope.

This is a Godot 4.7.2 project in `src/`, using the Compatibility renderer. Use `/Applications/Godot.app/Contents/MacOS/Godot` for imports, runs, and tests on this Mac. Test scripts are in `src/tests/`. For example:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/room_polish_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --editor --import --quit
```

Before editing, inspect `git status --short`. Completed milestones are committed; any uncommitted changes you find may be the user's or a previous session's work in progress. Preserve them. Do not reset, clean, overwrite, or commit changes unless the user asks. Work directly in this local checkout.

Keep the scene route, interactions, and existing tests working. After changes, run the relevant tests and a graphical Godot check for visual work. Document material limitations honestly. The user prefers plain floor surfaces, subtle natural wood grain, readable filled labels on world signs, and compact key-shaped control prompts without filled text boxes behind them. Keep the HUD small; the world should dominate the screen. Character motion that touches furniture (sitting, standing) must look physically plausible and never clip through the furniture. Do not add strong repeating floor patterns. Hall A should stay modern and muted (not bright white); the campus lawn is dense, vivid turf. Signs are mounted flat on surfaces and must not cover objects; NPCs are solid to the player. The user preferred the original stylized character models over a realistic procedural rebuild, so keep the existing figures.

Milestones 1–8 are complete; Milestone 9 (Knowledge interface) is next, then UI polish and save/load. Do not treat foundations from earlier milestones as completed versions of those features. Sprint is a Minecraft-style double-tap of a movement key.

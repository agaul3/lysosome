# Medical School RPG — Claude Code project instructions

Read `CHANGES` first. It is the running handoff log and records completed work, current limitations, user preferences, and test commands. Keep it updated: prepend each new change set with its actual local date and time. Do not invent timestamps for earlier work.

Read `src/docs/design/medical_school_rpg_spec.md` before changing product behavior. It is the authoritative product specification. For milestone work, read the relevant run document under `src/docs/prompts/` or `src/docs/development/`; the run document determines the current scope. Follow any newer instruction from the user when it changes that scope.

This is a Godot 4.7.2 project in `src/`, using the Compatibility renderer. Use `/Applications/Godot.app/Contents/MacOS/Godot` for imports, runs, and tests on this Mac. Test scripts are in `src/tests/`. For example:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/room_polish_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --editor --import --quit
```

Before editing, inspect `git status --short`. Prior work is intentionally uncommitted, including newly added files. Preserve it. Do not reset, clean, overwrite, or commit changes unless the user asks. Work directly in this local checkout so current uncommitted work remains available.

Keep the scene route, interactions, and existing tests working. After changes, run the relevant tests and a graphical Godot check for visual work. Document material limitations honestly. The user prefers plain floor surfaces, subtle natural wood grain, readable filled labels, and compact key-shaped control prompts. Do not add strong repeating floor patterns.

Milestones 1–6 are complete; Milestone 7 has not been started. The lecture delivery UI, full question set, save/load, and later progression features remain future work. Do not treat foundations from Milestones 5–6 as completed versions of those features.

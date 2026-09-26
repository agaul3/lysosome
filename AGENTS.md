# Medical School RPG — Codex project instructions

This repository contains the `rpg_med` medical-school RPG. The Godot project is under `src/`.

## Current project state

- Godot 4.7.2 stable, Compatibility renderer.
- Primary language: GDScript.
- Milestones 1–10 are complete; the v0.1 vertical slice is feature-complete.
- Development has continued beyond Milestone 10 with courtyard-life improvements, first-person view, visual refinements, and review fixes.
- Milestone 11 (University Hospital, physician shadowing) is implemented; see `src/docs/development/MILESTONE_11_ACCEPTANCE.md`.
- The hospital's Emergency Department (Level I trauma center, Emergency Radiology on Level 2, the campus ambulance) is implemented; see `src/docs/development/EMERGENCY_DEPARTMENT_ACCEPTANCE.md`. `tests/ed_clearance_test.gd` keeps the ED's scripted routes clear of furniture.
- The first-year expansion is implemented and committed: the whole first year is playable as 28 story days (`src/data/year_one.json`), with money, energy, boosts, skills and achievements, the East Campus buildings (`src/world/interior/interior_scene.gd` and its subclasses), clubs, twelve more lectures, and the year's labs, encounters, immersion shifts, ceremonies and exams in `src/education/activities/`. See `src/docs/development/YEAR_ONE_PLAN.md`. The clock only runs forward (tests visit dates in order); the new buildings' walkers are solid and move without physics (`tests/interior_clearance_test.gd`, `tests/food_court_test.gd`); achievements never pay XP.
- `CHANGELOG.md` at the repository root is the running handoff log and the best source for the latest implemented state.
- `PROJECT_HANDOFF.md` provides cross-agent project context.
- `CLAUDE.md` contains Claude-specific standing instructions; shared project rules in this file apply to Codex.

## Source-of-truth hierarchy

When working on a task, use this order:

1. The user's current instruction.
2. The relevant active task/run document, when one exists.
3. `src/docs/design/medical_school_rpg_spec.md` for authoritative product requirements.
4. `CHANGELOG.md` for the latest implemented state and recent decisions.
5. `src/docs/architecture/ARCHITECTURE.md` for architecture and repository organization.
6. Relevant acceptance, known-issues, and medical-review documents under `src/docs/development/`.

`src/PROJECT_SPEC.md` is a snapshot of the authoritative product specification.

Do not rely on old chat history when the repository contains newer information.

## How to begin work

Read only the repository context needed for the user's task, including the latest relevant entries in `CHANGELOG.md` and the applicable source/spec/test files.

Check `git status --short` before editing so existing work is not accidentally overwritten.

Do not stop to produce a separate repository-inspection or handoff report unless the user explicitly asks for one. After obtaining enough context to work safely, proceed with the requested task.

## Git safety

- Preserve unfamiliar or uncommitted work.
- Never use destructive cleanup such as `git reset --hard`, `git clean`, or equivalent unless the user explicitly requests it and the consequences are clear.
- Do not overwrite unrelated user or previous-agent changes.
- Do not commit or push unless the user explicitly asks.
- When asked to commit, make focused commits whose messages accurately describe the completed work.
- GitHub is the shared checkpoint between coding agents, but the local working tree may contain newer uncommitted work.

## Repository organization

Before creating a new file or directory, inspect the existing project tree and `src/docs/architecture/ARCHITECTURE.md`.

Reuse established domains and naming. Do not create semantically duplicate top-level structures such as:
- `audio/` and `sounds/`
- `player/` and a second character/player domain
- `docs/` and `documentation/`
- nested asset categories that duplicate an existing top-level domain

Create a new top-level directory only when it represents a genuinely new architectural domain.

Keep systems modular and understandable. Avoid giant monolithic scripts and speculative infrastructure.

## Godot and testing

The Godot project is `src/project.godot`.

On this Mac, Godot is available at:

```sh
/Applications/Godot.app/Contents/MacOS/Godot

Test scripts are under src/tests/.

Typical commands:

/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/<suite>.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --editor --import --quit

After code changes:

run the relevant targeted tests;
run appropriate regression tests when shared systems are affected;
validate Godot import after structural/resource changes;
perform a graphical Godot check for visual work when possible;
report any manual verification that still remains.

Do not claim behavior was verified if it was not actually tested.

Existing design and interaction constraints

Preserve established project behavior unless the current task intentionally changes it.

Important standing preferences and constraints include:

The world should dominate the screen; keep the exploration HUD compact.
UI work should follow the design system under src/ui/style/.
Use readable filled labels on world signs.
Key/control prompts should be compact and key-shaped, without large filled text boxes.
Floors should generally remain visually restrained; avoid strong repeating floor patterns.
Wood grain should be subtle and natural.
Hall A should remain modern and muted rather than bright white.
Campus lawn should remain dense, vivid turf.
Signs should be mounted cleanly to surfaces and should not cover unrelated objects.
NPCs are solid to the player.
Preserve the existing stylized character models rather than replacing them with a realistic procedural style unless explicitly requested.
Sitting, standing, and other character/furniture interactions must look physically plausible and avoid clipping.
Sprint uses the established Minecraft-style double-tap movement behavior, with existing controller support preserved.
The game supports both the default third-person/overhead presentation and an optional first-person view.
New or modified world geometry should account for both camera modes. Rooms that are cut away for the overhead camera must still appear complete in first person.
Medical-learning content

The game is intended to be a legitimate study tool, not merely a medical-themed RPG.

For new educational content:

preserve the project's established question/content schema;
keep medical claims reviewable and academically credible;
do not copy proprietary exam questions;
update the appropriate medical-content review documentation when the established workflow requires it.
Documentation and handoff

For meaningful completed change sets, keep the repository documentation aligned with the implementation.

Update CHANGELOG.md when appropriate with the actual local date/time and a concise record of what changed, tests run, and important limitations or user preferences. Do not invent timestamps for earlier work.

Update acceptance or development documentation when a task changes behavior covered by those records.

Development philosophy
Preserve tested behavior.
Favor clear, maintainable systems over clever abstractions.
Implement the requested scope rather than expanding into unrelated features.
Reuse existing architecture before introducing new systems.
Functionality and correctness come before decorative complexity.
For visual work, polish should support readability, immersion, and the established art direction.

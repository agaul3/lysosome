# PROJECT_HANDOFF.md — rpg_med

## Purpose
This file is the cross-agent handoff for the ongoing `rpg_med` project.

A new coding agent should use the repository itself, Git history, tests, and the authoritative design/specification files to reconstruct state rather than relying on prior chat history.

## Product summary
`rpg_med` is an educational medical-school RPG built in Godot.

Core product identity:

> A medical-learning platform whose primary interface is an RPG world.

The player is a medical student. Real medical learning should drive XP, levels, mastery, and later progression. The first vertical slice is intentionally narrow and is meant to prove that medical studying can be made more engaging through RPG systems without becoming academically superficial.

## Confirmed technology
- Godot 4.7.2 stable was installed and verified on macOS.
- `godot` was configured as a working shell command.
- Primary scripting language: GDScript.
- Git is used for milestone checkpoints.

## Confirmed project history
The following facts are confirmed from the prior development workflow:

- Milestone 1 established the initial project foundation.
- The user manually verified fullscreen and other desktop/settings behavior after the first agent initially reported Milestone 1 as PARTIAL.
- Milestone 1 was subsequently committed to Git as a baseline.
- The next planned milestone was Milestone 2: Player + Dorm.
- Do not assume Milestone 2 is untouched: inspect `git status`, `git diff`, file timestamps/content, recent commits, and any milestone files to determine whether work continued after this handoff document was authored.

## Important existing files
The project has contained files/directories including:

- `ARCHITECTURE.md`
- `assets/`
- `audio/`
- `autoload/`
- `CHANGELOG.md`
- `data/`
- `docs/`
- `education/`
- `KNOWN_ISSUES.md`
- `MEDICAL_CONTENT_REVIEW.md`
- `medical_school_rpg_spec.md`
- `Game Design Document & Technical Product Specification v0.1.md`
- `astra_run_01_milestone_1.md`

Paths may change over time. Locate files instead of relying on this list as an exact tree.

## Repository organization
The user wants later milestone work to extend existing directories rather than create redundant parallel structures.

Examples:
- future sound effects should go under the established `audio/` hierarchy
- player-specific files should use the established player domain when it exists
- documentation should remain under the existing docs/documentation convention
- new top-level folders should only be added for genuinely new domains

Before changing structure, inspect the current tree and `ARCHITECTURE.md`.

## Authoritative design context
Read the complete project specification before major implementation work.

`medical_school_rpg_spec.md` is the primary product specification unless the user explicitly supersedes it.

The broader Game Design Document provides design context and long-term intent.

Do not implement all long-term features at once. The project deliberately proceeds in narrow milestones.

## Milestone approach
The project uses milestone-scoped coding-agent runs.

The intended major milestones were:

1. Project Foundation
2. Player + Dorm
3. Campus
4. NPC Prototype
5. Time + Schedule
6. Question Engine
7. Pharmacodynamics Lecture
8. Progression Feedback
9. Knowledge Interface
10. UI + Polish

These are planning boundaries, not proof of completion. Verify actual repository state.

## Milestone 2 intent
When Milestone 2 is the active task, the target flow is:

Launch
→ New Game
→ choose simple character preset
→ spawn in dorm
→ WASD/controller movement
→ stable collision with room/furniture
→ orthographic/isometric exploration camera
→ contextual interaction prompt
→ desk interaction
→ one additional object interaction
→ interact with dorm exit
→ exercise scene-transition architecture into a temporary destination

Milestone 2 should NOT build the campus, lecture system, question database, XP system, NPC schedules, hospital, live AI, or other later systems.

## Development philosophy
- Functionality before visual polish.
- Preserve tested milestones.
- Keep systems understandable and modular.
- Avoid giant monolithic scripts.
- Avoid speculative infrastructure.
- Use placeholders rather than blocking on art.
- Use Git as the persistent record of what actually changed.
- Verify behavior in Godot, not just by reading code.

## Handoff procedure for a new agent
Before doing new work:

1. Read `CLAUDE.md` if present.
2. Run:
   - `pwd`
   - `git rev-parse --show-toplevel`
   - `git status --short`
   - `git log --oneline --decorate -10`
3. Locate `project.godot`.
4. Inspect the current tree.
5. Read the authoritative specification, architecture, changelog, known issues, and active milestone instructions.
6. Inspect any uncommitted changes before modifying them.
7. Run the current project/tests to establish a baseline.
8. Summarize the actual current state to the user.
9. Only then begin the requested milestone/task.

## Safety
Do not discard or rewrite unfamiliar work just to obtain a clean state.

If the repository is dirty, determine whether the changes are:
- user work
- unfinished prior-agent work
- generated/cache files
- intentional documentation changes

Preserve them until their purpose is understood.

## Current handoff goal
The new agent should take over ongoing implementation with the same project-level access expected of a coding agent: inspect files, edit/create files in the repository, run shell commands and Godot, test changes, and work from Git history.

No prior chat transcript should be required once the repository documentation is current.

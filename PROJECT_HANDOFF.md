# PROJECT_HANDOFF.md — rpg_med

## Current status (updated 2026-09-23)
Milestones 1–9 are complete; Milestone 10 (UI + Polish) is next. `CHANGELOG.md` at the repository root is the running, timestamped record of current state and supersedes the historical notes below. `CLAUDE.md` holds standing agent instructions.

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
- Milestone 1 (Project Foundation) — committed as the baseline after the user manually verified fullscreen/settings behavior.
- Milestone 2 (Player + Dorm) and Milestone 3 (Campus) — committed.
- Milestones 4–6 (NPC Prototype, Time + Schedule, Question Engine) plus room/UI polish — committed together with a documentation cleanup.
- Milestone 7 (Pharmacodynamics Lecture) — complete; see `src/docs/development/MILESTONE_7_ACCEPTANCE.md`.
- Milestone 8 (Progression Feedback) — complete; see `src/docs/development/MILESTONE_8_ACCEPTANCE.md`.
- Milestone 9 (Knowledge Interface) — complete; see `src/docs/development/MILESTONE_9_ACCEPTANCE.md`.

Verify against `git log` rather than trusting this list.

## Important existing files
- `CLAUDE.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md` (repository root)
- `src/project.godot` — the Godot project
- `src/PROJECT_SPEC.md` — byte-identical snapshot of `src/docs/design/medical_school_rpg_spec.md`
- `src/docs/design/` — authoritative spec and the broader Game Design Document
- `src/docs/architecture/ARCHITECTURE.md`
- `src/docs/development/` — acceptance records, `KNOWN_ISSUES.md`, `MEDICAL_CONTENT_REVIEW.md`, run documents
- `src/docs/prompts/` — milestone run prompts
- `src/tests/` — headless test suites

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

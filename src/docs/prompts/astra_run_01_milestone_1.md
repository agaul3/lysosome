# Astra Run #1 — Milestone 1: Project Foundation

Read `medical_school_rpg_spec.md` in full before making any changes.

Treat that file as the authoritative source of truth for **Medical School RPG — Vertical Slice v0.1**.

For this run, implement **only Milestone 1: Project Foundation** unless a minimal piece of later architecture is technically necessary to establish the foundation.

## Your objectives

1. Inspect the available development environment.
2. Confirm the installed stable Godot 4.x version, or configure the appropriate stable version if the environment permits.
3. Create the Godot project workspace.
4. Create the project directory structure described in the specification, improving it only where there is a clear engineering benefit.
5. Configure semantic input actions for:
   - movement
   - interaction
   - menu
   - confirm
   - cancel
   - controller equivalents
6. Establish only the core global/autoload architecture necessary for future milestones.
7. Create a simple functional start screen with:
   - New Game
   - Continue
   - Settings
   - Quit
8. `Continue` may be disabled or clearly marked unavailable until save data exists.
9. Create or update:
   - `README.md`
   - `PROJECT_SPEC.md`
   - `ARCHITECTURE.md`
   - `CHANGELOG.md`
   - `KNOWN_ISSUES.md`
   - `MEDICAL_CONTENT_REVIEW.md`
10. Ensure `PROJECT_SPEC.md` preserves the immutable v0.1 product requirements from `medical_school_rpg_spec.md`.
11. Add the minimum automated checks or test harness appropriate for the foundation.
12. Launch the project.
13. Inspect runtime errors and warnings.
14. Fix critical issues.
15. Re-run until Milestone 1 is stable.

## Important constraints

Do **not** begin building:

- the player controller
- the dorm
- the campus
- NPC behavior
- pharmacodynamics questions
- the lecture
- the XP feedback system
- knowledge UI
- future systems

unless a very small interface or stub is technically required to establish Milestone 1 architecture.

Do not over-engineer future features.

Do not stop at planning or pseudocode. Create and test the actual project files.

Use placeholder visuals where needed.

Favor code that is understandable to a developer who is still learning programming.

## Before finishing this run

Perform a Milestone 1 acceptance check.

Confirm that:

- the project launches without critical runtime errors
- the start screen works
- input actions are configured
- folder architecture exists
- required documentation exists
- core architecture is documented
- there are no known critical blockers preventing Milestone 2

Then provide a concise completion report containing:

### Milestone status
`PASS`, `PARTIAL`, or `BLOCKED`

### Implemented
What you actually created.

### Tested
What you actually ran or verified.

### Architecture decisions
Only meaningful decisions and why they were made.

### Known issues
Anything unresolved.

### Files of interest
The most important project files for me to inspect.

### Next milestone
State what Milestone 2 will cover, but **do not implement it yet**.

Do not mark Milestone 1 as `PASS` unless it was actually tested.

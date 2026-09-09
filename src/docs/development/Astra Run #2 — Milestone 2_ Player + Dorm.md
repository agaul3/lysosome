# Astra Run #2 — Milestone 2: Player + Dorm

Read `medical_school_rpg_spec.md` in full and inspect the existing project before modifying anything.

Milestone 1 has been completed, manually verified, and committed to Git. Preserve all currently working Milestone 1 functionality.

For this run, implement and test **only Milestone 2: Player + Dorm**, except for minimal supporting architecture that is genuinely necessary.

## Project-structure rule

Before creating any new file or directory, inspect the existing project tree and `ARCHITECTURE.md`.

Reuse existing top-level directories and established naming conventions.

Do not create duplicate or semantically overlapping directories such as:

- `audio/` and `sounds/`
- `player/` and `characters/`
- `docs/` and `documentation/`
- `assets/audio/` when the project already has `audio/`

If a new subdirectory is required, place it beneath the most appropriate existing domain directory whenever possible.

Create a new top-level directory only when it represents a genuinely new architectural domain.

---

# 1. Primary Objective

Create the first genuinely playable environment.

A fresh player should be able to:

1. Launch the game.
2. Select **New Game**.
3. Select from a small number of preset medical-student appearances.
4. Spawn inside a dorm/apartment.
5. Move the character using WASD.
6. Use equivalent controller input.
7. Collide correctly with walls and furniture.
8. Move around the room using the intended 2.5D/isometric presentation.
9. Approach interactive objects.
10. Receive contextual interaction prompts.
11. Interact with the desk.
12. Interact with at least one additional dorm object.
13. Approach and use the dorm exit.
14. Reach a temporary transition/end state representing the future campus transition.

Do not build the campus yet.

---

# 2. Preserve Milestone 1

Do not break:

- start screen
- settings
- fullscreen/window behavior
- semantic input architecture
- project organization
- core autoload architecture
- documentation
- existing passing tests

Run regression checks on Milestone 1 before marking Milestone 2 complete.

---

# 3. Character Selection

Implement approximately **3–5 simple preset medical-student appearances**.

The purpose is to prove that selected appearance data can persist into gameplay.

Do NOT implement:

- face sliders
- body sliders
- height modification
- weight modification
- extensive clothing selection
- advanced character creation

Placeholder or simple original character visuals are acceptable.

The selected preset must:

- be stored in game state
- determine the appearance of the spawned player
- remain compatible with future save/load expansion

---

# 4. Player Architecture

Create a reusable player scene/component rather than embedding player logic directly into the dorm.

The player should support:

- movement
- collision
- character appearance
- interaction detection
- future animation support
- future camera-mode changes

Keep responsibilities separated.

Avoid one giant player script.

---

# 5. Movement

Implement responsive movement using the semantic input actions established in Milestone 1.

Requirements:

- WASD
- controller equivalent
- frame-rate-independent movement
- diagonal movement must not be unintentionally faster
- stable collision
- player cannot pass through walls or furniture

Do not implement combat or jumping.

---

# 6. Camera

Implement the prototype exploration camera.

Desired presentation:

> **3D spatial environment viewed through an orthographic/isometric-style camera**

The camera should:

- clearly show the character
- provide useful visibility of the dorm
- remain stable during movement
- follow the player smoothly if appropriate
- establish the visual foundation for the future campus

Do not implement the lecture camera yet.

However, preserve an architecture that allows additional camera modes later.

---

# 7. Dorm Environment

Create a small but intentional medical-student dorm/apartment.

It should visually communicate:

> A student currently attending medical school lives here.

Include representative geometry such as:

- bed
- desk
- chair
- bookshelf or storage
- door/exit
- basic room structure

Optional lightweight props may include:

- textbooks
- laptop/computer
- backpack
- lamp
- wall decoration
- notes

Do not spend excessive time on detailed art.

Use original placeholder/low-poly geometry or clearly permissible assets.

---

# 8. Collision

The player must not be able to walk through:

- walls
- desk
- bed
- major furniture
- room boundaries

Verify collision behavior from multiple movement directions.

---

# 9. Interaction System

Create a reusable interaction architecture.

The system should not be specific only to the desk.

It should be extensible to future:

- NPCs
- doors
- textbooks
- lecture seats
- hospital objects
- study stations

When the player enters interaction range, show a contextual prompt such as:

```text
E — Interact
```

Use an appropriate controller prompt when practical.

Only the most relevant interaction prompt should dominate when interaction ranges overlap.

---

# 10. Required Dorm Interactions

Implement at least:

## Desk

Interaction should demonstrate that the desk can eventually become the entry point for the study system.

For this milestone it may display something like:

> Study system unavailable in this prototype milestone.

Do not build the question-bank/Anki system yet.

## One Additional Object

Choose one:

- textbook
- bed
- computer
- backpack

Provide a simple contextual response.

Example:

> “Your pharmacology notes are open to pharmacodynamics.”

Do not create a new gameplay system around this object.

---

# 11. Dorm Exit

The exit door must be interactable.

Using it should exercise the project’s existing scene-transition architecture.

Because the campus belongs to Milestone 3, transition to:

- a simple temporary scene,
- placeholder destination,
- or clearly marked campus-transition test scene.

The purpose is to prove:

```text
Dorm
  ↓
Scene transition
  ↓
Temporary destination
```

Do NOT build the actual campus.

---

# 12. UI

Preserve the existing HUD/menu architecture.

Add only the UI necessary for:

- character selection
- interaction prompts
- temporary contextual interaction text

Do not build:

- final XP HUD
- Knowledge interface
- Academic Calendar
- achievements
- inventory mechanics

---

# 13. Save / State Preparation

The selected character preset should integrate with existing state/save architecture where appropriate.

Do not expand the save system unnecessarily.

At minimum ensure:

- selected preset exists in game state
- gameplay receives the selected preset reliably

---

# 14. Testing Requirements

Actually launch and test the project.

Validate:

## Character selection
- each preset can be selected
- selected appearance reaches gameplay
- invalid selection does not crash the game

## Movement
- all directions work
- diagonal speed is normalized
- movement is frame-rate independent
- controller mappings do not break keyboard input

## Collision
- player cannot walk through room boundaries
- player cannot walk through major furniture

## Interaction
- prompt appears in range
- prompt disappears outside range
- desk interaction works
- second-object interaction works
- one button press does not accidentally trigger repeatedly

## Exit
- dorm exit triggers transition
- transition does not crash
- restarting does not leave broken player state

## Regression
- main menu works
- settings work
- fullscreen/window settings still work
- project launches without critical runtime errors

---

# 15. Scope Restrictions

Do NOT implement:

- campus environment
- lecture building
- NPC schedules
- pharmacodynamics lecture
- question database
- XP system
- streak system
- mastery system
- live AI
- patients
- hospital
- achievements
- inventory mechanics
- study-question system
- complex character creator

Do not advance into Milestone 3.

---

# 16. Documentation

Update as appropriate:

- `README.md`
- `ARCHITECTURE.md`
- `CHANGELOG.md`
- `KNOWN_ISSUES.md`

Document:

- player architecture
- movement implementation
- interaction architecture
- camera architecture
- character-preset data flow
- scene-transition behavior
- any new directories created and why

---

# 17. Completion Criteria

Milestone 2 is `PASS` only if a fresh run can complete:

```text
Launch
  ↓
New Game
  ↓
Choose character preset
  ↓
Spawn in dorm
  ↓
Move around room
  ↓
Collision works
  ↓
Approach desk
  ↓
Interaction prompt appears
  ↓
Interact
  ↓
Interact with second object
  ↓
Approach exit
  ↓
Trigger scene transition
```

Do not mark `PASS` unless this sequence was actually tested.

---

# 18. Final Report

When finished, provide:

## Milestone status
`PASS`, `PARTIAL`, or `BLOCKED`

## Implemented
What was actually created.

## Tested
What was actually run and verified.

## Regression testing
Whether Milestone 1 still passes.

## Architecture decisions
Important implementation choices and rationale.

## Known issues
Anything unresolved.

## Files of interest
Important new or modified files.

## Project-structure changes
List any new directories created and why they were necessary.

## Git status
Report the current working-tree state.

## Next milestone
Briefly state that Milestone 3 will cover the campus, but **do not implement Milestone 3**.
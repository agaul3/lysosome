# Medical School RPG — Vertical Slice v0.1
## Product & Technical Specification

**Status:** Source of truth for implementation  
**Prototype goal:** Build a polished 15–20 minute vertical slice proving that legitimate medical learning can function as the central progression loop of an explorable RPG.

---

# 1. Product Identity

Medical School RPG is a single-player educational RPG in which the player controls a medical student progressing through a realistic modern American medical-school environment.

The product should be treated as:

> **A legitimate medical-learning platform whose primary interface is an RPG world.**

It is not an RPG with occasional quizzes attached.

Medical knowledge acquisition is the primary progression mechanic. The player should gain XP, levels, mastery, achievements, and future academic progression mainly because they are actually learning medicine.

The educational and RPG layers must reinforce one another.

---

# 2. Vertical Slice v0.1 Objective

The first build should provide approximately **15–20 minutes of representative gameplay**.

Its main validation question is:

> **Can legitimate medical education inside an explorable RPG make studying medicine more engaging without reducing educational quality?**

The vertical slice should demonstrate:

1. Character selection
2. Player-controlled movement
3. Dorm environment
4. Campus traversal
5. Environmental interaction
6. Simple autonomous NPC behavior
7. Game clock and schedule
8. Mandatory pharmacodynamics lecture
9. Lateness detection
10. Lecture seating
11. Camera transition into lecture mode
12. Shortened interactive lecture
13. Pharmacodynamics educational content
14. Structured question system
15. Correct/incorrect feedback
16. XP acquisition
17. Level progression
18. Correct-answer streaks
19. Knowledge-performance tracking
20. Game menus and HUD
21. Return to exploration after lecture

Do not expand scope beyond what is necessary to prove this loop.

---

# 3. Target Audience

Primary audience:

- incoming medical students
- M1 students
- M2 students

Secondary audience:

- premedical students
- medically oriented university students
- later-stage medical students
- people interested in medicine

Future versions may use an onboarding questionnaire and/or placement assessment to set starting difficulty. This is not required for v0.1.

---

# 4. Design Pillars

## 4.1 Knowledge is power
Real medical learning should directly drive RPG progression.

## 4.2 Active learning over passive consumption
Avoid long passive lectures. The player should answer questions, inspect diagrams, manipulate models, make predictions, and apply concepts.

## 4.3 Visible progression
The player should always understand what they earned, how close they are to leveling, and how well they know each topic.

## 4.4 A world that exists beyond the player
NPCs should show basic autonomous schedules and interactions without requiring player initiation.

## 4.5 Game systems must reinforce education
Avoid meaningless grinding. Progress should primarily come from demonstrated learning.

---

# 5. Technology

**Engine:** latest stable Godot 4.x available in the environment  
**Primary language:** GDScript  
**Target:** Desktop  
**Primary controls:** Keyboard/mouse  
**Secondary controls:** Standard game controller

Prefer built-in Godot systems and avoid unnecessary third-party dependencies.

---

# 6. Rendering & World Architecture

Use a **3D spatial world with an orthographic/isometric exploration camera** to create the 2.5D presentation.

Reason: the game must later support a more conventional lecture camera and may eventually evolve toward full third-person/first-person gameplay.

The visual direction may be broadly inspired by the layered 2.5D readability of *Eiyuden Chronicle: Rising*, but do not copy its art, assets, UI, animations, or proprietary visual identity.

Prototype visuals may use:

- original low-poly geometry
- simple original characters
- permissively licensed placeholder assets
- basic but intentional lighting
- billboard/sprite elements where technically useful

Prioritize functionality and readability over visual fidelity.

---

# 7. Campus Setting

The v0.1 campus should be **inspired by the UCLA medical-school campus**.

Do not attempt a centimeter-accurate reconstruction.

The environment should communicate:

- student dorm/apartment
- outdoor medical-school campus
- lecture building
- lecture hall
- modern Southern California academic-medical setting

Gameplay readability takes priority over architectural fidelity.

Do not use protected logos, ripped commercial assets, or copied proprietary branding.

---

# 8. Copyright & Content Rules

Do not use:

- ripped commercial-game assets
- copied Boot.dev graphics
- copied Eiyuden Chronicle assets
- copied NBA 2K assets
- copied Cyberpunk assets
- Patagonia logos
- UCLA logos unless appropriately licensed
- copied AAMC questions
- copied NBME/USMLE questions
- copied UWorld, AMBOSS, Kaplan, or other commercial question-bank material

Medical questions must be **original**, while matching the reasoning style and rigor of medical-education assessments where appropriate.

If licensing is uncertain, use an original placeholder.

---

# 9. Core Gameplay Flow

## 9.1 Start Screen
Provide:

- New Game
- Continue, if save data exists
- Settings
- Quit

## 9.2 Character Setup
Provide approximately 3–5 preset medical-student appearances.

Do not build a complex character creator.

## 9.3 Dorm Start
The player begins in a dorm/apartment on a weekday morning.

Recommended default:

- current time: ~7:35 AM
- mandatory pharmacodynamics lecture: 8:00 AM

These values must be configurable data, not scattered hard-coded constants.

## 9.4 Dorm Gameplay
The player can:

- move with WASD
- use controller equivalents
- interact with desk
- inspect at least one additional object
- open the player interface
- check today's schedule
- leave the dorm

The dorm desk should be architected as a future entry point for study sessions, but the full study system is not required yet.

## 9.5 Campus
The player can:

- traverse a small outdoor campus
- observe NPC students
- interact with at least one NPC
- inspect at least one environmental element
- locate and enter the lecture building

Do not build a large empty open world.

## 9.6 Autonomous NPC Event
At least one NPC sequence occurs without player initiation:

1. NPC A walks through campus
2. NPC A encounters NPC B
3. they exchange a short predefined conversation
4. NPC A continues toward the lecture
5. NPC A enters the lecture area
6. NPC A reaches a seat
7. NPC A sits down

Example:

> NPC A: “Hey.”  
> NPC B: “Hey, you heading to pharm?”  
> NPC A: “Yeah.”

This is a prototype of a world that exists independently of the player.

## 9.7 Lecture Hall
The player enters the lecture room in exploration mode.

Requirements:

- multiple visible seats
- several NPC students
- available-seat interaction
- player selects a seat
- free movement is disabled once seated
- camera transitions smoothly to lecture mode
- lecture begins

## 9.8 Post-Lecture
After the lecture:

- knowledge statistics are updated
- progression remains saved
- normal exploration resumes

---

# 10. Controls

Use semantic Godot input actions rather than hard-coded physical keys.

Required actions should include equivalents of:

```text
move_up
move_down
move_left
move_right
interact
open_menu
confirm
cancel
```

Movement must be frame-rate independent.

---

# 11. Time System

Initial time scale:

> **1 real minute = 5 in-game minutes**

Central time state should support:

```text
day
date
hour
minute
weekday
academic_week
semester
```

Only a subset needs to affect v0.1 gameplay.

Architecture should allow later support for:

- weekends
- sleep
- exams
- semesters
- academic calendars
- board-exam dates
- day/night cycles

Lighting should broadly match time of day.

---

# 12. Menu Time Behavior

Opening the player menu must **not pause the simulation**.

While the player views:

- map
- schedule
- knowledge
- inventory
- calendar

the clock continues and NPC schedules continue.

Do not pause the entire scene tree for this menu.

---

# 13. Schedule System

The prototype schedule includes:

```text
8:00 AM
PHARMACODYNAMICS

Location:
Lecture Hall A

Status:
MANDATORY
```

The event should appear in:

- Today's Schedule
- Academic Calendar or equivalent

Schedule data must be structured and separate from UI code.

---

# 14. Lateness

The pharmacodynamics lecture is mandatory.

If the player enters the required lecture state after the configured start time:

> **−5 XP**

Requirements:

- penalty triggers exactly once
- clear UI feedback is shown
- lateness is stored in state
- repeated scene entry does not repeat the penalty
- XP state remains valid

The threshold must be configurable.

---

# 15. Camera System

## Exploration
Orthographic/isometric perspective.

## Lecture
Perspective-oriented camera showing the seated experience, professor, and lecture display.

Possible forms:

- over-the-shoulder
- behind the seated student
- seated third-person

The exact framing is an implementation decision.

Camera transitions should be smooth and extensible.

---

# 16. Pharmacodynamics Lecture

Build **one strong lecture**, not many shallow lectures.

Suggested topics:

1. receptors and ligands
2. agonists
3. antagonists
4. competitive antagonism
5. noncompetitive antagonism
6. potency
7. efficacy
8. dose-response relationships
9. basic clinical application

The exact order may be adjusted for educational coherence.

---

# 17. Lecture Gameplay Loop

Use the following pattern repeatedly:

```text
PROFESSOR EXPLAINS CONCEPT
        ↓
VISUAL / INTERACTIVE MODEL
        ↓
PLAYER INTERACTION
        ↓
CONCEPT QUESTION
        ↓
ANSWER
        ↓
FEEDBACK
        ↓
CLINICAL CONNECTION
        ↓
APPLICATION QUESTION
        ↓
NEXT CONCEPT
```

The lecture must not feel like a PowerPoint deck with quizzes inserted between slides.

---

# 18. Interactive Pharmacology Visualization

Implement at least one meaningful interactive visualization.

Preferred prototype:

## Competitive Antagonism

Represent:

- receptor
- agonist
- antagonist

Possible interaction:

- player adjusts agonist concentration
- antagonist is introduced
- response changes or curve shifts
- player predicts the outcome

The visualization does not need molecular-dynamics realism.

It must communicate the pharmacodynamic concept correctly.

---

# 19. Shared Question Architecture

Lecture questions and future study questions should use the **same underlying question database**.

Do not hard-code question content into lecture scripts.

A question record should support at least:

```text
id
discipline
topic
subtopic
question_type
difficulty_tier
prompt
choices
correct_answer
explanation
learning_objective
xp_reward
lecture_id
```

Recommended optional fields:

```text
format
accepted_short_answers
tags
is_remediation
```

Use JSON, Godot Resources, or another clean structured format and document the choice.

---

# 20. Question Types & Difficulty

Question **type** and **difficulty tier** are independent.

Examples:

```text
Type: Recall
Tier: 1
```

```text
Type: Recall
Tier: 3
```

```text
Type: Clinical Application
Tier: 2
```

Supported metadata may include:

- Recall
- Conceptual
- Application
- Clinical Application
- Interpretation
- Synthesis

For v0.1, actual content can focus on Recall, Conceptual, Application, and Clinical Application.

Lecture difficulty should match what the learner is expected to know from that lecture.

Do not dynamically adapt lecture-question difficulty.

Future optional quizzes may use adaptive difficulty.

---

# 21. Question Content

Create approximately **12 original pharmacodynamics questions**.

Include a mix of:

- basic concept checks
- receptor-mechanism reasoning
- dose-response reasoning
- potency vs efficacy
- antagonist concepts
- clinical vignette/application questions

At least several should resemble the reasoning structure of medical licensing-exam-style questions.

All questions must be original.

---

# 22. Medical Accuracy

Prioritize medical correctness.

Every question should have:

- one best answer
- clear terminology
- concise explanation
- explanation of why the correct answer is correct
- distractor explanation where educationally useful
- learning objective

Create:

```text
MEDICAL_CONTENT_REVIEW.md
```

For each question, record:

- question ID
- learning objective
- answer
- explanation
- any uncertainty requiring later human review

Do not represent AI-generated prototype questions as professionally validated educational material.

---

# 23. Runtime AI

Do **not** use live AI in v0.1.

Do not add:

- runtime API calls
- OpenAI API dependency
- dynamic runtime question generation
- AI NPC conversation
- AI tutoring
- AI patient generation

All gameplay content should work locally.

Future AI integration should remain architecturally possible.

---

# 24. Answer Formats

Required:

### Multiple Choice
Primary format.

Optional if straightforward:

### Short Answer
Use predefined acceptable answers or keywords.

Do not use fuzzy AI grading.

If short-answer support threatens project stability, architecture support is sufficient for v0.1.

---

# 25. Incorrect Answers

Incorrect answers should:

1. clearly indicate failure
2. provide educational feedback
3. award no XP
4. update performance statistics

Selected questions may trigger a small remediation action.

Example:

> Incorrect → explanation → simpler follow-up → continue

Do not remediate every wrong answer.

---

# 26. XP System

For v0.1, XP comes primarily from correct medical answers.

Recommended initial rewards:

```text
Tier 1: 10 XP
Tier 2: 20 XP
Tier 3: 30 XP
```

These values must be configurable.

Configure progression so a strong player can reasonably experience **at least one level-up** during the 15–20 minute slice.

---

# 27. Level Curve

Use an escalating RPG-style XP curve.

Requirements:

- later levels require more XP
- formula/configuration is centralized
- UI can calculate progress toward next level
- overflow XP is preserved
- multiple level-ups do not break state
- lateness penalties cannot corrupt progression

Document the chosen formula.

---

# 28. Correct-Answer Feedback

Every correct answer should produce:

1. satisfying confirmation sound
2. brief floating XP value
3. animated XP bar movement

Example:

```text
+20 XP
```

Feedback should be satisfying without obscuring medical content.

---

# 29. Streak System

Track consecutive correct answers.

Do not prominently show the streak before 10.

At **10 consecutive correct answers**, display the streak UI.

Example:

```text
10x STREAK
```

Reset the streak after an incorrect answer.

---

# 30. Level-Up Feedback

A level-up should be noticeably more significant than a normal correct answer.

Use:

- distinctive sound
- larger UI animation
- visual effect
- clear level change text

Example:

```text
LEVEL UP
Level 4 → Level 5
```

Keep the effect satisfying but brief.

---

# 31. Knowledge Tracking

For v0.1, mastery is purely performance-based:

> **accuracy = correct answers / attempted questions**

Support at least:

```text
Pharmacology
└── Pharmacodynamics
```

After each attempted question:

- attempted count increments
- correct count increments when appropriate
- percentages recalculate

The architecture must support future disciplines and subtopics.

A more sophisticated mastery algorithm using recency, difficulty, forgetting, confidence, and response time is explicitly deferred.

---

# 32. Player Menu

Provide navigation for:

- Overview
- Today's Schedule
- Academic Calendar
- Campus Map
- Knowledge
- Recent Lecture Notes
- Achievements
- Inventory
- Settings

For v0.1:

## Fully functional
- Today's Schedule
- Knowledge
- Settings

## Basic / representative
- Academic Calendar
- Campus Map
- Lecture Notes

## Placeholder acceptable
- Achievements
- Inventory

Do not build unnecessary inventory or achievement systems yet.

---

# 33. HUD

The exploration HUD should remain restrained.

Required:

- overall level
- XP progress bar

Recommended:

- current in-game time

Contextual prompts appear only when needed.

Example:

```text
E — Interact
```

Do not copy Boot.dev's visual design.

---

# 34. Audio

Provide distinct original or permissibly licensed placeholder audio for:

- correct answer
- incorrect answer
- level up
- future mastery/achievement unlock

The correct-answer sound should be short and satisfying.

The level-up sound should be substantially more prominent.

---

# 35. Save System

Implement one simple local save slot.

Persist at minimum:

```text
selected_character
overall_level
current_xp
question_history
correct_count
attempt_count
topic_statistics
current_streak
game_date
game_time
current_location
lecture_completion
lateness_state
```

Use versioned save data if practical.

---

# 36. Recommended Architecture

Prefer modular responsibilities rather than giant scripts.

Suggested systems:

```text
GameStateManager
TimeManager
ScheduleManager
PlayerProgressionManager
KnowledgeManager
QuestionManager
LectureManager
SceneTransitionManager
NPCScheduleManager
SaveManager
AudioFeedbackManager
UIManager
```

Names may change if a cleaner design is justified.

Avoid excessive global state and tight coupling.

Use signals and structured data where appropriate.

---

# 37. Suggested Project Structure

A structure comparable to the following is preferred:

```text
res://
├── autoload/
├── player/
├── npc/
├── world/
│   ├── dorm/
│   ├── campus/
│   ├── lecture_building/
│   └── lecture_hall/
├── education/
│   ├── questions/
│   ├── lectures/
│   └── models/
├── ui/
├── audio/
├── assets/
├── data/
├── tests/
└── docs/
```

Improve the structure when there is a clear engineering reason.

---

# 38. Coding Standards

Use:

- descriptive names
- typed GDScript where practical
- small focused functions
- reusable components
- signals for loose coupling
- structured data instead of hard-coded content
- clear scene ownership
- comments for non-obvious logic

Avoid:

- giant monolithic scripts
- unexplained magic numbers
- unnecessary global state
- copy-pasted logic
- scattered hard-coded scene paths
- excessive nesting

The code should be understandable to a motivated developer who is still learning programming.

---

# 39. Documentation

Maintain:

```text
README.md
ARCHITECTURE.md
PROJECT_SPEC.md
MEDICAL_CONTENT_REVIEW.md
CHANGELOG.md
KNOWN_ISSUES.md
```

## README.md
Include:

- project purpose
- Godot version
- how to launch
- controls
- implemented systems
- project structure
- testing instructions

## ARCHITECTURE.md
Explain:

- game state
- time/schedule
- scene transitions
- questions
- XP/levels
- knowledge tracking
- NPC state machine
- save system
- major architectural decisions

---

# 40. Testing Requirements

Testing is mandatory.

After each milestone:

1. launch the project
2. test the new functionality
3. inspect errors and warnings
4. fix regressions
5. rerun the relevant scenario

Do not mark a feature complete because the code merely looks correct.

---

# 41. Required Logic Tests

Validate at minimum:

## XP
- correct answer awards correct XP
- incorrect answer awards zero
- lateness subtracts 5 exactly once
- level threshold works
- overflow XP is preserved

## Questions
- correct answer recognized
- incorrect answer recognized
- explanation returned
- malformed question data handled

## Knowledge
- attempts increment
- correct count increments
- accuracy is correct
- zero-attempt state is safe

## Streaks
- increments after correct answer
- resets after incorrect answer
- UI activates at 10

## Time
- game time advances near 5× real time
- player menu does not stop clock

## Schedule
- on-time arrival detected
- late arrival detected
- lateness penalty occurs once

## Save/load
- progression survives reload
- knowledge survives reload
- time survives reload

---

# 42. Development Milestones

## Milestone 1 — Project Foundation
Create:

- Godot project
- directory architecture
- input actions
- core global/autoload systems
- start screen
- documentation foundation

**Acceptance:** project launches reliably without critical runtime errors.

## Milestone 2 — Player + Dorm
Create:

- player
- movement
- collisions
- camera
- preset appearance selection
- dorm
- interactables
- exit

**Acceptance:** player can traverse dorm and leave.

## Milestone 3 — Campus
Create:

- outdoor campus
- dorm-to-campus transition
- lecture building
- basic interactions
- time-of-day presentation

**Acceptance:** player can traverse from dorm to lecture building.

## Milestone 4 — NPC Prototype
Create:

- reusable NPC scene
- simple state machine
- navigation/pathfinding
- NPC-to-NPC conversation
- route to lecture
- seating

**Acceptance:** NPC sequence occurs without player initiation.

## Milestone 5 — Time + Schedule
Create:

- 1:5 clock
- schedule data
- Today's Schedule UI
- pharmacodynamics event
- lateness detection
- −5 XP penalty

**Acceptance:** both on-time and late cases work.

## Milestone 6 — Question Engine
Create:

- question schema
- loader
- answer checking
- explanations
- metadata
- XP values
- performance hooks

**Acceptance:** question logic works independently of lecture presentation.

## Milestone 7 — Pharmacodynamics Lecture
Create:

- lecture hall
- seat selection
- camera transition
- professor presentation
- interactive visualization
- question progression
- feedback
- lecture completion

**Acceptance:** full educational loop works end-to-end.

## Milestone 8 — Progression Feedback
Create:

- XP HUD
- floating XP
- correct-answer audio
- streak system
- level-up logic
- level-up audiovisual feedback

**Acceptance:** progression and feedback work reliably.

## Milestone 9 — Knowledge Interface
Create:

- Pharmacology accuracy
- Pharmacodynamics accuracy
- attempts/correct data
- Knowledge menu

**Acceptance:** displayed statistics match question history.

## Milestone 10 — UI + Polish
Finish:

- start screen
- HUD
- player menu
- schedule
- calendar
- map representation
- lecture notes
- placeholders
- settings
- transitions
- audio
- lighting
- visual consistency

**Acceptance:** fresh user can complete the slice without developer intervention.

---

# 43. Explicitly Out of Scope for v0.1

Do not implement:

- patients
- diagnosis systems
- hospital wards
- procedural medicine
- M2/M3/M4
- residency
- research gameplay
- multiplayer
- online leaderboards
- live AI
- AI NPCs
- AI patients
- runtime AI questions
- full UCLA campus
- large open city
- sophisticated character creator
- complex inventory
- economy
- romance
- extensive relationship simulation
- full achievement tree
- sophisticated mastery algorithm
- adaptive lecture difficulty
- full M1 curriculum
- board-exam simulation

Architect lightly for future expansion where appropriate, but do not build these systems now.

---

# 44. Autonomy Rules

Make routine engineering decisions without repeatedly asking the user.

You may decide:

- exact node hierarchy
- filenames
- internal signal names
- interpolation values
- walking speeds
- animation timing
- placeholder materials
- exact level-curve constants
- exact serialization method
- UI spacing
- scene-transition mechanics

Document meaningful assumptions.

Ask only when:

1. the decision materially changes product vision
2. required information cannot reasonably be inferred
3. credentials/access are required
4. legal/licensing issues block progress
5. two viable choices create materially different long-term architectures

---

# 45. Placeholder Policy

Placeholder visuals are acceptable.

Broken systems are not.

Prioritize:

1. functional gameplay
2. educational interaction
3. architecture
4. usability
5. polish

A grey-box system that works is better than a polished but broken feature.

---

# 46. Full Vertical Slice Acceptance Test

The slice is complete only when a fresh player can:

1. launch the game
2. start a new game
3. choose a preset appearance
4. spawn in dorm
5. move with WASD
6. interact with a dorm object
7. open player menu
8. view today's schedule
9. observe that time continues while menu is open
10. leave dorm
11. traverse campus
12. use optional environment/NPC interaction
13. witness autonomous NPC interaction
14. observe NPC continue toward lecture
15. enter lecture building
16. be classified as on-time or late
17. receive exactly −5 XP if late
18. enter lecture hall
19. select seat
20. experience camera transition
21. begin pharmacodynamics lecture
22. receive professor explanations
23. use at least one interactive educational visualization
24. answer multiple original medical questions
25. receive correct/incorrect feedback
26. gain XP from correct answers
27. update knowledge statistics
28. see floating XP
29. see XP bar animation
30. activate streak display at 10 consecutive correct answers
31. trigger a level-up when enough XP is earned
32. receive larger level-up feedback
33. complete the lecture
34. inspect updated pharmacodynamics performance
35. return to exploration
36. save and reload progress without corruption

Target representative playtime: **15–20 minutes**.

---

# 47. Product Success Criteria

The prototype succeeds when:

- movement feels responsive
- the world feels like a place rather than a menu wrapper
- NPC autonomy is visible
- exploration-to-learning transitions feel natural
- lecture gameplay requires active reasoning
- medical questions are substantive
- correct answers feel rewarding
- progress is immediately visible
- knowledge statistics are accurate
- the RPG layer increases motivation to continue studying
- the educational layer remains genuinely useful

The guiding principle is:

> **Real medical learning → visible RPG progression**

Do not reward meaningless grinding.

The RPG should make studying more compelling without making the studying less rigorous.

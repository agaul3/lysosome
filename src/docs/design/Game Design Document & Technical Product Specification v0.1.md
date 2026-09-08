# Medical School RPG
## Game Design Document + Technical Product Specification
### Vertical Slice v0.1

**Document status:** Pre-production specification  
**Primary objective:** Define the first playable vertical slice and establish an extensible foundation for a larger medical-school RPG and educational platform.

---

# 1. Product Vision

Medical School RPG is a single-player educational role-playing game in which the player assumes the role of a medical student progressing through a realistic modern American medical-school environment.

The long-term vision is to simulate the progression of a medical career beginning with medical school and potentially expanding in future versions into residency, fellowship, and attending-level practice. The initial product, however, focuses specifically on the medical-school experience, with early development centered primarily on the M1 stage. 
The game should combine two normally separate experiences:

**A legitimate medical-learning platform**

and

**An explorable RPG with character progression, environments, NPCs, customization, and reward systems.**

The game should therefore not be treated as an RPG that occasionally asks medical questions. Its central design philosophy is:

> **Learning medicine is the primary gameplay mechanic through which the player's character grows stronger.**

The target experience is comparable conceptually to the way Boot.dev turns programming instruction into an interactive progression system, but Medical School RPG places the educational experience inside a traversable world controlled through an RPG character.

---

# 2. Product Goals

The product should satisfy four simultaneous goals.

### 2.1 Genuine learning

A player should be able to spend meaningful time playing the game while also genuinely studying medical material.

Medical questions, interactive models, lectures, future patient encounters, study sessions, and assessments should be educationally substantive rather than superficial minigames.

### 2.2 RPG progression

Medical competence should generate visible progression through:

- experience points
- character levels
- topic-specific progression
- mastery indicators
- achievements
- unlockable cosmetics
- streaks
- class ranking
- later leaderboard systems

The player should feel increasingly capable because of improvements in their actual medical knowledge.

### 2.3 Medical-school simulation

The game world should reflect recognizable elements of contemporary American medical education, including:

- lectures
- laboratories
- seminars
- studying
- examinations
- schedules
- semesters
- academic calendars
- eventual clinical experiences
- eventual board-exam preparation

The simulation does not need to reproduce every minute of real medical school, but the structure should remain recognizably grounded in real medical education.

### 2.4 Player autonomy and immersion

The player should control an actual character who can move through environments, attend activities, return home, interact with objects and NPCs, choose where to go, decide whether to study, and eventually shape their own medical-school experience.

The intended long-term experience is predominantly sandbox-driven rather than a heavily scripted narrative campaign.

---

# 3. Target Audience

The primary target audience is:

**Incoming medical students and early medical students, particularly M1 and M2 learners.**

A secondary audience includes:

- premedical students preparing to enter medical school
- biology or medically oriented university students
- later-stage medical students
- players generally interested in medicine

The long-term game should adapt to the player's baseline knowledge.

Potential onboarding approaches include:

1. asking the player's current educational stage, and/or
2. administering an approximately 20–30-question placement assessment.

The result would establish an appropriate starting difficulty and assumed knowledge level.

This adaptive onboarding is **not required for Vertical Slice v0.1**.

---

# 4. Design Pillars

## 4.1 Knowledge is power

Progression should originate primarily from demonstrated medical learning.

Correct answers, successful reasoning, and later clinical performance become the equivalent of combat victories or quest completion in a traditional RPG.

## 4.2 Active learning over passive consumption

The game should avoid becoming:

> walk to lecture → watch PowerPoint → answer quiz

Lectures and study activities should instead require participation through questions, diagrams, models, interpretation, manipulation, and application of concepts.

## 4.3 Visible progression

Correct performance should produce immediate and satisfying feedback.

The player should consistently understand:

- what they accomplished
- how much XP they earned
- how close they are to leveling
- how well they know a topic
- what they have mastered
- where weaknesses remain

## 4.4 A world that exists beyond the player

NPCs should eventually behave according to independent schedules and routines.

Even in the first prototype, the player should observe simple autonomous behavior such as one NPC encountering another NPC, exchanging brief dialogue, traveling to class, and choosing a seat without player involvement.

## 4.5 Education and game mechanics should reinforce one another

Progression systems should not merely be layered over unrelated quizzes.

Medical learning should influence:

- XP
- levels
- mastery
- achievements
- future access
- eventually clinical performance
- eventually class ranking
- eventually specialty-specific competence

---

# 5. Long-Term Gameplay Priorities

The current priority order is:

1. Medical knowledge challenges
2. Patient diagnosis and management
3. Conversational patient encounters
4. Exams
5. Research
6. Character and social relationships

This order may evolve during development.

Vertical Slice v0.1 concentrates almost entirely on **medical knowledge challenges and medical-school simulation**.

Patient care, research, and sophisticated social systems remain future features.

---

# 6. Vertical Slice v0.1

## 6.1 Purpose

Vertical Slice v0.1 exists to answer one primary product question:

> **Can studying medicine inside an explorable RPG environment feel both educationally useful and genuinely enjoyable?**

The vertical slice should provide approximately **15–20 minutes of representative gameplay**.

It is not intended to represent the entire M1 year.

It should instead prove the viability of:

- movement
- exploration
- schedules
- environmental transitions
- NPC autonomy
- lecture gameplay
- medical questions
- XP progression
- mastery tracking
- UI
- time progression

---

# 7. Vertical Slice Gameplay Sequence

The intended first-session flow is:

### Start screen

Player launches the game and begins a new session.

### Character setup

The player selects from a limited number of preset character appearances.

Advanced facial customization, detailed body sliders, and extensive character creation are reserved for later versions.

### Dorm

The player begins inside their medical-school dorm or apartment.

The player can:

- move using WASD
- use controller input
- inspect at least one or two objects
- interact with the desk
- access their player interface
- check today's schedule
- leave the dorm

### Campus

The player enters an outdoor medical-school campus environment.

The first environment should use the UCLA medical-school campus as the intended setting/layout reference. Exact architectural fidelity has not yet been specified.

The player should be able to:

- traverse the environment
- enter designated buildings
- interact with a small number of NPCs
- interact with a small number of environmental objects
- observe NPC activity

The player does not need to interact with every visible object or person. Two to three representative optional interactions are sufficient to demonstrate the intended world-system capability.

### Autonomous NPC event

At least one NPC should:

1. walk through the environment
2. encounter another NPC
3. exchange a short predefined conversation
4. continue toward the lecture building
5. enter the lecture hall
6. occupy a seat

Example dialogue:

> NPC A: “Hi.”  
> NPC B: “Hello.”

More sophisticated NPC behavior is intentionally out of scope for v0.1.

### Lecture building

The player enters the lecture building through an environment transition.

Interior and exterior spaces may be separate scenes.

### Lecture hall

The player enters the lecture room and selects an available seat.

Once seated:

- movement mode changes
- the camera transitions from normal exploration view
- the player receives a lecture-oriented perspective
- the professor and lecture material become the visual focus

The intended camera concept is to transition away from the normal 2.5D/isometric exploration perspective toward a perspective that allows the player to see both their character and the lecture presentation.

---

# 8. First Lecture

The prototype lecture is:

# Pharmacodynamics

The lecture should be substantially shorter than a real medical-school lecture.

The objective is not to simulate an hour-long PowerPoint presentation.

Instead, the lecture should demonstrate an active educational loop.

Recommended prototype topics include:

- receptors and ligands
- agonists
- antagonists
- competitive antagonism
- noncompetitive antagonism
- potency
- efficacy
- dose-response relationships

The exact final topic list may be adjusted during implementation.

---

# 9. Lecture Gameplay Loop

The preferred lecture structure is:

**Professor explanation**

↓

**Interactive visualization or model**

↓

**Player interaction**

↓

**Concept question**

↓

**Immediate feedback**

↓

**Clinical connection**

↓

**Application / Step-style question**

↓

**Next concept**

This structure reflects the selected design direction for shortened but actively interactive lectures. 
Different subjects should eventually support different forms of interaction.

Examples include:

**Pharmacology**
- drug-receptor visualization
- agonist/antagonist interaction
- competitive inhibition
- dose-response curves

**Anatomy**
- identifying structures
- manipulating body models

**Neuroscience**
- examining brain models
- identifying neural structures

These systems do not all need to be implemented in v0.1.

Only enough pharmacodynamics interaction should be built to prove that subject-specific educational gameplay is feasible.

---

# 10. Question System

All educational questions should eventually originate from a shared question architecture.

Lecture questions and independent study questions should use the same underlying question database.

Each question should support metadata conceptually similar to:

**Question ID**  
**Discipline**  
**Topic**  
**Subtopic**  
**Question type**  
**Difficulty tier**  
**Prompt**  
**Answer choices, if applicable**  
**Correct answer**  
**Explanation**  
**Learning objective**  
**XP reward**  
**Associated lecture**

Difficulty and question type must be separate concepts.

For example:

> Type: Recall  
> Tier: 1

or:

> Type: Recall  
> Tier: 3

or:

> Type: Clinical Application  
> Tier: 2

Question categories may eventually include:

- memory/recall
- conceptual understanding
- application
- clinical reasoning
- interpretation
- synthesis

This reflects the requirement that question type and difficulty should be independently classified.

---

# 11. Medical Question Standard

The educational material should use accurate medical terminology and seek to approximate the logic, rigor, difficulty, and reasoning expected from AAMC/USMLE-style medical questions where appropriate.

For v0.1, questions should be **pre-generated and locally stored**.

The running game should not make live AI calls to generate educational content.

### Implementation requirement

Astra may generate the initial content during development, but generated medical questions should be stored as game data rather than produced dynamically at runtime.

### Product-quality requirement

AI-generated medical content should not automatically be treated as medically validated.

A future production release will require an explicit medical-content review and validation workflow.

---

# 12. Question Difficulty Adaptation

Lecture questions should **not** dynamically change difficulty based on player performance.

Lecture questions should instead correspond to what the learner should reasonably understand from that lecture.

Adaptive difficulty may later be used in optional:

- quizzes
- assessments
- question-bank sessions
- mastery evaluations

This preserves instructional consistency while leaving room for adaptive learning elsewhere.

---

# 13. Incorrect Answers

Incorrect answers may trigger different responses depending on the educational context.

Possible responses include:

- immediate explanation
- hint
- opportunity to retry
- small remediation activity
- later clinical consequence in future patient scenarios

Remediation should be used selectively rather than after every incorrect answer. 
---

# 14. XP System

For Vertical Slice v0.1, XP is awarded primarily for **correctly answering medical questions**.

The exact XP progression curve is not yet locked.

### Recommended implementation

Use a conventional escalating level curve rather than a fixed XP requirement per level.

The system should be data-driven so the progression curve can be adjusted without rewriting gameplay logic.

Example conceptual function:

> XP required for next level increases progressively as overall level rises.

The exact constants should be tuned through playtesting.

---

# 15. Correct-Answer Feedback

A correct answer should trigger:

- a satisfying confirmation sound
- brief floating XP text
- animated XP/level bar movement

A streak indicator should become visible only once the player reaches **10 consecutive correct answers**.

Difficult questions do not currently require special feedback.

Mastery or achievement unlocks should use a distinct audio and visual treatment.

Leveling up should trigger a substantially larger audiovisual celebration.

The reward feedback should feel satisfying without visually obscuring the educational content.

---

# 16. Overall Level

The player has an overall RPG level representing cumulative progression.

Levels may eventually unlock:

- clothing
- cosmetics
- status items
- additional progression rewards

One example long-term reward is unlocking medical-school apparel at particular levels.

---

# 17. Topic-Specific Levels

The design may also support domain-specific progression such as:

> Pharmacology Level 8  
> Neuroscience Level 3  
> OB-GYN Level 9

Topic-specific levels may eventually produce XP modifiers.

Example concept:

> Neuroscience Level 5 → 1.10× XP on future neuroscience questions.

This concept has been selected for exploration but does not need to be fully implemented in the first prototype.

---

# 18. Mastery Tracking

Vertical Slice v0.1 should use a simple performance-based metric:

> **Accuracy = Correct Answers / Total Attempted Questions**

The player should be able to inspect performance by discipline and subtopic.

Example:

**Pharmacology — 78%**

- Pharmacodynamics — 84%
- Pharmacokinetics — 71%

A player may therefore perform well in pharmacology overall while still identifying pharmacodynamics as a relative weakness.

A more advanced mastery model may eventually incorporate:

- question difficulty
- recency
- repetition
- confidence
- response time
- forgetting

This advanced system is explicitly deferred.

---

# 19. Achievement / Mastery Tree

The long-term progression system should differ from a traditional combat skill tree.

Instead, the player should have an **achievement/mastery tree** representing educational accomplishment.

Potential achievements include:

> 10 consecutive correct answers

or:

> 80% accuracy across the most recent 50 OB-GYN questions → Gold

or:

> 90% accuracy across the most recent 50 OB-GYN questions → Platinum

Certain performance-based badges may be lost if performance falls sufficiently below the required threshold.

Lost badges may eventually support a remediation or reacquisition process.

The detailed badge system is a future feature, but the architecture should avoid preventing its later implementation.

---

# 20. Study Gameplay

Independent study should eventually become a genuine gameplay activity rather than a menu-only feature.

The player should be able to:

1. return to their dorm
2. sit at their desk
3. initiate a study activity
4. access an Anki-like review system or virtual question bank
5. answer medical questions
6. earn XP
7. earn study-related achievements

Skipping studying should remain a valid player choice.

Future academic performance should reflect that choice.

A complete study system is not mandatory for the first 15–20-minute lecture vertical slice, but the dorm desk should be architected as a future entry point into this system.

---

# 21. Time System

The world should contain an in-game clock.

Initial time scale:

> **1 real minute = 5 in-game minutes**

The long-term simulation should support:

- days
- nights
- sleep
- weekdays
- weekends
- class schedules
- exams
- semesters
- academic calendar
- board-exam dates

Environmental lighting should correspond logically to in-game time.

---

# 22. Mandatory Lecture and Lateness

The pharmacodynamics lecture in Vertical Slice v0.1 is mandatory.

If the player arrives late:

> **−5 XP**

The penalty should be noticeable but relatively minor.

The exact threshold defining "late" should be configurable.

---

# 23. Pause and Menu Behavior

Opening the game menu does **not** stop simulation time.

NPCs and the game world continue operating while the player views menus.

This means schedules and time management remain relevant even while the player is examining game information.

---

# 24. Player Interface

The player's primary interface should eventually include tabs for:

**Overview**  
**Today's Schedule**  
**Academic Calendar**  
**Campus Map**  
**Knowledge / Mastery**  
**Recent Lecture Notes and Topics**  
**Achievements**  
**Inventory**  
**Settings**

The exact final organization can be refined during UI design.

The requirements specifically call for schedule, academic calendar, campus map, recent lecture information, inventory, and knowledge-performance views. 
---

# 25. HUD

During normal exploration, the HUD should remain relatively unobtrusive.

The top-right area should contain a persistent representation of player level and XP progression.

The design may be inspired conceptually by the clarity of Boot.dev's progression display but must have its own visual identity.

Possible persistent information:

**Level**  
**XP progress**  
**Current time**  
**Contextual interaction prompts**

The streak display should appear only after the required threshold.

---

# 26. Player Character

Long-term customization goals include:

- preset faces
- body types
- potentially height
- potentially weight
- facial modification
- clothing
- scrub color
- medical-school apparel

NBA 2K and Cyberpunk were provided as examples of the eventual depth of character customization, though this complexity is not required for the first version.

### Vertical Slice requirement

Provide a small set of preset character appearances.

Extensive customization is deferred.

---

# 27. Player Movement

Required:

- WASD movement
- controller compatibility
- environmental collision
- interaction system
- transitions between exterior and interior spaces

The player must actively manipulate the medical-student avatar rather than merely navigate through menus.

---

# 28. Inventory

The long-term role of inventory remains undefined.

Potential future inventory items may include:

- textbooks
- notes
- study materials
- medical tools
- clothing
- personal items

Because a compelling mechanical use for inventory has not yet been established, v0.1 should implement at most a basic placeholder inventory interface.

No unnecessary item-economy system should be created.

---

# 29. NPC System

Vertical Slice v0.1 requires only basic NPC functionality:

- walking
- simple pathfinding
- simple schedule behavior
- short predefined conversations
- entering lecture areas
- selecting or reaching seats

Future NPC design should move toward a world in which classmates and faculty appear to possess lives independent of the player.

Live AI-powered NPC dialogue is explicitly outside v0.1.

---

# 30. Story Structure

The game should primarily function as a sandbox simulation.

Named characters may include:

- classmates
- friends
- mentors
- professors
- physicians
- nurses

The game does not currently require extensive authored character arcs.

---

# 31. World Design

The long-term world should resemble a contemporary major-city American medical environment.

Chicago was identified as a particularly relevant long-term setting concept because of its concentration of medical schools and hospital systems.

For v0.1, however, the selected campus reference is the UCLA medical-school campus.

### Unresolved requirement

The current specification does not define whether the prototype must reproduce UCLA architecture precisely or simply use it as a recognizable layout and environmental reference.

Until explicitly decided otherwise, implementation should prioritize **gameplay readability over exact architectural reconstruction**.

---

# 32. Visual Direction

The selected visual reference for the first prototype is:

> **Eiyuden Chronicle: Rising**

The desired presentation is a lighter 2.5D/isometric-style RPG rather than the eventual fully 3D first-/third-person experience. 
Long term, the ambition is to move toward a more immersive modern third-person and potentially first-person RPG presentation.

The v0.1 art direction should be treated as a prototype style rather than a final visual commitment.

---

# 33. Recommended Technical Architecture

**The following section contains implementation recommendations rather than requirements explicitly selected in the source answers.**

## Recommended engine

**Godot 4.x**

Reasons:

- appropriate for a small-to-medium RPG prototype
- strong 2D and 3D scene support
- suitable for 2.5D presentation
- lightweight iteration
- accessible scripting language
- open architecture
- appropriate for a learning developer

## Recommended scripting language

**GDScript**

This recommendation favors development accessibility and rapid iteration.

## Recommended high-level architecture

Use modular systems rather than embedding game logic directly into individual scenes.

Suggested core systems:

**GameStateManager**  
Global player progression and persistent state.

**TimeManager**  
In-game date and time.

**ScheduleManager**  
Class events and lateness.

**SceneTransitionManager**  
Dorm/campus/building transitions.

**PlayerProgressionManager**  
XP and levels.

**KnowledgeManager**  
Correct/attempted statistics and mastery percentages.

**QuestionManager**  
Question loading and selection.

**LectureManager**  
Lecture sequence and interactive educational events.

**NPCScheduleManager**  
Basic autonomous NPC behavior.

**SaveManager**  
Persistence.

**AudioFeedbackManager**  
Correct-answer, achievement, and level-up sounds.

**UIManager**  
HUD and menu states.

These systems should remain loosely coupled enough that later features can be added without rewriting the complete project.

---

# 34. Recommended Question Data Model

Questions should be stored as structured data rather than hard-coded inside lecture scenes.

A conceptual record should support:

```text
id
discipline
topic
subtopic
question_type
difficulty_tier
prompt
answer_choices
correct_answer
explanation
learning_objective
xp_reward
lecture_id
```

This makes the same educational content reusable by:

- lectures
- dorm studying
- quizzes
- exams
- remediation
- future clinical scenarios

---

# 35. Save Data

Recommended v0.1 save data:

```text
Player appearance
Overall level
Current XP
Question history
Correct-answer count
Attempt count
Topic accuracy
Current streak
Current date/time
Current location
Lecture completion
Schedule state
```

Achievement and specialty-progression data may be added later.

---

# 36. Audio Requirements

At minimum, v0.1 requires distinct audio feedback for:

**Correct answer**  
Short, satisfying confirmation.

**Incorrect answer**  
Informative but not excessively punitive.

**XP acquisition**  
May accompany floating XP.

**Level up**  
Substantially more prominent.

**Mastery/achievement unlock**  
Distinct from ordinary XP.

Music and environmental ambience are desirable polish items but secondary to functional gameplay.

---

# 37. Out of Scope for Vertical Slice v0.1

The following should **not** be fully implemented:

- complete M1 curriculum
- M2/M3/M4 progression
- residency
- attending career
- patient diagnosis system
- procedural medicine
- hospital simulation
- live AI
- AI-generated runtime questions
- open-ended AI NPC dialogue
- multiplayer
- global leaderboard backend
- research mechanics
- detailed relationship simulation
- comprehensive character creator
- complete UCLA reconstruction
- complete achievement tree
- sophisticated mastery algorithm
- dynamic adaptive lecture difficulty
- complex economy
- detailed inventory mechanics
- full board-exam system

The code may anticipate future expansion, but Astra should not spend implementation time building these systems prematurely.

---

# 38. Development Milestones

## Milestone 1 — Project foundation

Deliver:

- functioning game project
- scene organization
- input mapping
- global game state
- basic save architecture
- placeholder start screen

**Acceptance criterion:** project launches reliably without runtime errors.

## Milestone 2 — Player and dorm

Deliver:

- playable character
- WASD movement
- controller input
- collisions
- camera
- dorm
- desk interaction
- exit interaction

**Acceptance criterion:** player can freely traverse the dorm and leave.

## Milestone 3 — Campus

Deliver:

- exterior campus
- lecture building
- basic environmental interactions
- transitions between scenes
- initial time system

**Acceptance criterion:** player can move from dorm to lecture building through a traversable world.

## Milestone 4 — NPC behavior

Deliver:

- autonomous walking
- simple interaction between two NPCs
- route to lecture
- seating behavior

**Acceptance criterion:** NPC sequence occurs without player initiation.

## Milestone 5 — Schedule and time

Deliver:

- 1:5 time scale
- class schedule
- required pharmacodynamics lecture
- lateness detection
- −5 XP penalty

**Acceptance criterion:** late arrival correctly produces the penalty.

## Milestone 6 — Question engine

Deliver:

- structured question data
- answer checking
- explanation support
- XP assignment
- question metadata

**Acceptance criterion:** question logic operates independently of the lecture scene.

## Milestone 7 — Pharmacodynamics lecture

Deliver:

- shortened lecture
- professor presentation
- interactive visualization
- concept questions
- clinical/application questions
- feedback
- lecture completion

**Acceptance criterion:** lecture demonstrates the full educational loop.

## Milestone 8 — Progression

Deliver:

- XP
- level progression
- floating XP
- level-bar animation
- streak threshold
- level-up effect

**Acceptance criterion:** progression responds correctly to question performance.

## Milestone 9 — Knowledge tracking

Deliver:

- correct / attempted storage
- discipline accuracy
- subtopic accuracy
- knowledge menu

**Acceptance criterion:** pharmacodynamics statistics update correctly after questions.

## Milestone 10 — UI and polish

Deliver:

- start screen
- HUD
- main player interface
- schedule
- calendar
- map placeholder
- knowledge tab
- inventory placeholder
- settings
- pause/menu behavior without world freezing
- improved transitions
- sound
- visual feedback

**Acceptance criterion:** prototype can be played from launch through lecture without developer intervention.

---

# 39. Vertical Slice Acceptance Test

Version 0.1 is complete only when a new player can:

1. Launch the game.
2. Start a new game.
3. Select a preset medical-student appearance.
4. Spawn in a dorm.
5. Move using keyboard controls.
6. Inspect or interact with at least one dorm object.
7. Open the game interface.
8. View the day's pharmacodynamics lecture.
9. Leave the dorm.
10. Traverse a medical-school campus.
11. Observe autonomous NPC behavior.
12. Interact with at least several optional world elements.
13. Enter the lecture building.
14. Arrive on time or trigger the lateness penalty.
15. Enter the lecture hall.
16. Select a seat.
17. Experience the camera transition.
18. Participate in the shortened pharmacodynamics lecture.
19. Interact with at least one educational visualization.
20. Answer multiple medical questions.
21. Receive correct/incorrect feedback.
22. Earn XP from correct answers.
23. Observe floating XP and level-bar movement.
24. Trigger the streak system if conditions are met.
25. Level up if sufficient XP is earned.
26. View updated pharmacology/pharmacodynamics accuracy.
27. Finish the lecture.
28. Resume world exploration afterward.

The entire representative gameplay experience should target approximately **15–20 minutes**.

---

# 40. Core Prototype Success Criteria

The prototype should not be judged primarily on asset quantity.

It succeeds if:

**Movement feels responsive.**

**The world feels like a place rather than a sequence of menus.**

**NPC autonomy is visible.**

**The transition between exploration and learning feels natural.**

**The lecture requires active participation.**

**Medical questions feel substantive.**

**Correct answers feel satisfying.**

**Progress is immediately visible.**

**Knowledge statistics accurately reflect performance.**

**The player wants to continue learning partly because progressing their medical knowledge also progresses their character.**

The most important validation question remains:

> **Does wrapping legitimate medical education inside RPG progression make the player more motivated to continue studying?**

If the answer is yes, subsequent versions should expand depth rather than merely expand map size.

---

# 41. Product Identity

The core identity of Medical School RPG should remain:

> **A medical-learning platform whose primary interface is an RPG world.**

The educational system is not supplementary content.

It is the game's central progression engine.

Likewise, the RPG layer is not merely cosmetic.

It exists to make competence, growth, exploration, choice, and long-term learning tangible.

That relationship between **real knowledge acquisition** and **character progression** should guide every future feature decision.
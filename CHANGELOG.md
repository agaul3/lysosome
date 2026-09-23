# CHANGELOG — Medical School RPG handoff

**Recorded: 2026-09-23 05:03 PDT (2026-09-23 12:03 UTC).** This is a living Markdown handoff file. Add new change sets at the top, each with its own date and time. Times for the earlier milestone work were not recorded; their implementation dates come from the former `src/docs/development/CHANGELOG.md`, which was merged into this file during the Milestones 4–6 cleanup commit and must not be mistaken for exact timestamps.

**Project:** Godot 4.7.2, Compatibility renderer. Open `src/project.godot`. The authoritative product requirements are in `src/docs/design/medical_school_rpg_spec.md` (also snapshotted as `src/PROJECT_SPEC.md`). Run-specific instructions live in `src/docs/prompts/` and `src/docs/development/`. User instructions in the current task take precedence over this handoff.

**Current state:** Milestones 1–6 are implemented and committed. Milestones 1–9 are complete. Milestone 10 (UI + polish, including save/load) is next. The more recent visual, room, and UI improvements below sit on top of Milestones 1–6. (This note originally said the work was uncommitted; it has since been committed — see the 2026-09-23 documentation entry above.)

## 2026-09-23 11:45 PDT — Milestone 9: Knowledge interface; HUD tweaks

**HUD tweaks (user request).** The level card now reads "Lvl n" instead of "LV n". The top-right clock card shows the date on the first line and the time below it.

**Milestone 9.**
- **`education/knowledge/knowledge.gd`:** accuracy = correct ÷ attempted, safe at zero. `tree()` builds discipline → topic → subtopic from the question bank's taxonomy plus `AcademicSession.topic_statistics`, so unattempted areas still show and new disciplines need no code. `from_history()` independently recounts from `question_history`, and `recent()` lists the latest answers.
- **Knowledge tab** (`ui/knowledge_panel.gd`) in the player menu: an overall summary, then an indented row for each level with its name, an accuracy bar, the percentage and correct/attempted ("—" when not yet attempted), followed by the six most recent answers. It refreshes after every answer and whenever it's opened. The menu is slightly taller to fit.
- **Taxonomy:** subtopics now match the lecture's topics, in lecture order. Seed items were reassigned to Potency, Efficacy and Competitive antagonism, and the bank file is ordered by subtopic.
- **Tests and records:** new `knowledge_test.gd` (17 checks): zero state, increments, recalculation, hierarchy and order, future-discipline support, and a row-by-row comparison of the displayed statistics with a recount from the question history. The acceptance record is `src/docs/development/MILESTONE_9_ACCEPTANCE.md`. `academic_test.gd` now finds the Settings tab by index rather than position.

**Verification:** foundation 54, dorm 67, campus 39, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34, knowledge 17 — all passing (639 checks). Import and `git diff --check` are clean. Captures of the campus (several views), the Knowledge page and the new top-right HUD were inspected; the campus holds about 60 FPS on the M1.

## 2026-09-23 11:38 PDT — Campus redesign (modern buildings, larger map, quad, planting); sign glitch fix

Committed and pushed Milestone 8 first (`9121157`).

**Sign glitch (user report: "Learning Center" letters glitching through the sign).** The wayfinding sign's lettering sat 3 mm in front of its panel and its backing plate ended up inside the panel, so the letters z-fought. Every mounted sign (`Geometry.wall_sign`) now stands 2 cm proud of its surface, with the plate 8 mm behind the letters. The campus's big names are now real 3D relief letters (`TextMesh`, using the built-in font because the variable UI font fails TextMesh triangulation), standing clear of their walls.

**Campus redesign (user references: modern stacked academic building, UNLV School of Medicine, Harvard Medical School quad, Harbor-UCLA Medical Center).** The map grows from 28 × 24 m to about 75 × 63 m walkable, with streets and a skyline beyond.
- **Layout** (`world/campus/campus.gd`):
  - a central quad of four lawn panels with a perimeter walk, a north–south axis and an east–west path;
  - a round plaza with a raised planter and a flowering tree, benches and lamp posts;
  - the Learning Center plaza with seat-height planters, one lettered "LEARNING CENTER" and one "SCHOOL OF MEDICINE";
  - the residence forecourt with the campus directory, the medical-centre forecourt, and the café terrace with tables and umbrellas;
  - a south sidewalk, a parking lot with parked cars and planted islands, and a street.
- **Buildings** (`world/campus/buildings.gd`):
  - **Learning Center:** glazed podium with columns and a green roof terrace behind a glass balustrade; three offset floor plates wrapped in white vertical fins; a timber-soffit entry canopy; roof plant.
  - **Cedar Residence:** four storeys, cream render, framed punched windows with orange fins, a projecting grey glazed bay, a red accent core, a glazed lobby, timber canopy and rooftop solar panels.
  - **University Medical Center:** a glazed podium with a timber canopy on slim columns, and a ten-storey tower of light and dark vertical panels.
  - **Anatomy Hall:** classical stone, window rows, cornice, a six-column portico with steps, and relief lettering.
  - **Café pavilion:** glazed, with a planted green roof and timber fascia.
- **Rendering:**
  - Detail is merged per material by `world/campus/mesh_kit.gd`, so each building is a few draw calls.
  - `assets/glass.gdshader` draws curtain walls procedurally: mullion grid, floor spandrels, a sky-reflection gradient with Fresnel, and varied panes, some with warm interiors.
  - `assets/facade.gdshader` grounds matte surfaces with a soft base gradient.
  - Filmic tone mapping and subtle glow; the shadow distance is raised to 70 m.
- **Planting** (`world/campus/flora.gd` and `assets/foliage.gdshader`): instanced species built from leaf clusters with crown-oriented normals for soft volumes, gentle sway and a touch of light through the leaves. Species are shade trees (quad rows), pink flowering trees (medical frontage, residence, plaza), columnar trees (framing the portico and corners), ornamental trees (planters and parking islands), foundation shrubs, parking hedges, and flower-bed blossoms. The turf tufts now cover only the lawn panels. The hall still runs at about 60 FPS on the M1.
- **Gameplay data:**
  - New spawns and doors in `data/campus_config.gd`, which also holds the camera framing and bounds.
  - Alex's route runs from the residence along the east–west path to Sam (now waiting by a bench west of the plaza, `Route.SAM_POSITION`), then north to the Learning Center doors.
  - The campus, NPC and visual-motion tests were updated for the new coordinates. The collision probes cover the four map edges plus the Learning Center, the plaza planter and the residence.

## 2026-09-23 10:33 PDT — Milestone 8: progression feedback

Committed and pushed Milestone 7 first (`0cd1e27`).

- **Level curve:** `education/progression/level_curve.gd` is the only place level maths happens, configured by `level_curve` in `data/academic_config.json`. XP from level L to L+1 is round(80 × 1.3^(L−1)), giving thresholds of 80, 184, 319 and 495. Overflow carries over, one award can cross several levels, negative balances count as 0, and the level never decreases. It looks up `GameClock` at runtime so it compiles even when preloaded early.
- **AcademicSession:** all XP changes now go through `add_xp(delta, reason)`, which emits `xp_changed`, `level_up(from, to)` and `streak_changed`. It tracks `level`, `streak` and `best_streak`, and exposes `level_progress()` and `streak_visible()` (threshold 10, configurable).
- **HUD** (`ui/progression_hud.gd`, in the shared HUD's top bar next to the clock):
  - a compact "Lvl n" card with an XP bar and "into / needed XP" (plus "owed" when the balance is negative);
  - a tweened bar that fills, empties and continues through level-ups;
  - floating "+N XP" (or red "−5 XP") values that rise and fade beside the bar, clear of medical content;
  - a "10x STREAK" chip that only appears at 10 or more in a row, pulses on each correct answer and hides on a miss;
  - a level-up banner ("LEVEL UP / Level 1 → Level 2") with a scale pop, particle burst and soft flash, for about 2.3 s.
- **Audio:** original synthesized sounds in `audio/sfx/` (correct chime, soft incorrect tone, prominent level-up fanfare, and an achievement bell reserved for later), played by the new `Sfx` autoload on the Master bus so the volume setting applies. Answer and level-up sounds follow `AcademicSession` signals, wherever answers come from.
- **Schedule and summary:** the schedule shows level and progress, and the lecture summary includes the level.
- **Tests:** new `progression_test.gd` (34 checks) covers the spec's required XP, level and streak logic plus the HUD and audio feedback. The acceptance record is `src/docs/development/MILESTONE_8_ACCEPTANCE.md`.
- **Verification:** foundation 54, dorm 67, campus 38, NPC 37, academic 77, visual motion 23, room polish 26, seating 147, lecture 118, progression 34 — all passing (621 checks). Editor import and `git diff --check` pass. Graphical captures of the HUD, floating XP, streak chip, level-up banner, and XP feedback during the lecture were inspected.

## 2026-09-23 10:14 PDT — Milestone 7 complete; character rebuild reverted; double-tap sprint

**Character models reverted (user request).** The procedural rebuild was removed entirely: `appearance.gd`, presets, character selection, seat dimensions, Alex's route and the professor rig are back to `405f17f`, and `body_mesh.gd`, `hair_mesh.gd` and `hair.gdshader` were deleted. The rest of that session's work (visualization, mounted signs, podium, NPC collision) was committed and pushed as `5f8c4d3`.

**Double-tap sprint (user request, Minecraft-style).** Tap W, A, S or D twice within 0.3 s and keep holding to sprint in that direction. The character turns to face it, so double-tapping S turns you around and sprints back. Letting go of movement ends the sprint. Shift no longer sprints; controller L3 still does. The HUD shows a compact "×2 Sprint" hint. `visual_motion_test.gd` covers: a single or slow double tap doesn't sprint; a quick double tap does; the opposite direction turns you around; letting go stops.

**Milestone 7 finished.**
- **Questions:** there are 12 scored lecture questions (the 3 original seeds, the visualization prediction and 8 new ones) plus 2 remediation follow-ups (5 XP each), all in the shared bank and covering Recall, Conceptual, Application and Clinical Application. The new ones are affinity/Kd, partial agonist intrinsic activity, pure antagonist, noncompetitive antagonism, efficacy vs potency in prescribing, therapeutic index, recurrent respiratory depression after naloxone in methadone overdose, and buprenorphine-precipitated withdrawal.
- **Question beats:** the lecture script places a beat (`{"question", "lead", "remediation"}`) after each topic. The efficacy, dose-response and clinical segments follow the spec's concept → feedback → clinical connection → application loop.
- **Delivery:** `world/lecture_hall/question_beat.gd` delivers each beat on the compact question card. Answers are graded with `QuestionBank.submit`, so there is one attempt per lecture and stats and XP are recorded. A correct answer gets a confirmation and XP. A wrong answer is clearly marked, awards no XP and shows the explanation. Only the noncompetitive and potency beats follow a miss with a simpler question.
- **Completion:** after the summary lines, a completion card shows questions correct, accuracy, lecture XP and overall Pharmacodynamics accuracy. It is recorded in `AcademicSession.lectures_completed` (which replaces `presentations_completed`). Dismissing it unlocks the seat and resumes exploration. The HUD objective and the schedule's Today and Calendar pages show the result.
- **Tests and records:** `lecture_test.gd` (118 checks) plays every beat through real input, deliberately missing one remediated question and the activity prediction, and verifies the 10/12 tally, the XP reconciliation, recording and the resumed exploration. The acceptance record is `src/docs/development/MILESTONE_7_ACCEPTANCE.md`, and every question has an entry in `MEDICAL_CONTENT_REVIEW.md`.

**Verification:** foundation 54, dorm 67, campus 38, NPC 37, academic 77, visual motion 23, room polish 25, seating 147, lecture 118 — all passing. Import and `git diff --check` are clean. Graphical captures of the question, feedback, summary, schedule and HUD were inspected.

## 2026-09-23 09:48 PDT — Competitive-antagonism visualization, NPC collision, sign and podium fixes

**Interactive visualization (Milestone 7).** The competitive-antagonism segment now includes a hands-on activity (`src/world/lecture_hall/competitive_activity.gd`), declared in the lecture JSON as an `activity` line; the runner validates it.
- **Model:** `src/education/models/competitive_antagonism.gd` implements Gaddum competitive binding. Agonist and antagonist occupancies share one site, response = Emax × agonist occupancy, and the antagonist raises EC50 by the dose ratio 1 + [B]/KB (fixed at 10 in the activity).
- **Screen:** `ui/lecture_slide.gd` gained a live model mode. It shows 24 receptors where agonists (circles) and antagonists (squares) bind and unbind at equilibrium fractions, drifting free molecules, readouts, and a live log dose-response plot. The agonist-alone curve stays as a ghost, and the shifted curve, apparent-EC50 marker and a moving operating point update as you play.
- **Flow:**
  1. The player holds A/D (or the stick) to raise agonist to about 90% response. The first phase stops at the goal so the effect is consistent.
  2. The professor adds the antagonist, which washes in visibly, and the response drops to about 47%.
  3. The player predicts what more agonist will do.
  4. The player tests the prediction, and the full response returns only at about ten times the agonist.
  5. The professor wraps up.
- **Prediction question:** it comes from the shared bank (`pd_viz_competitive_01`, added to `pharmacodynamics.json` with a review entry). It is graded with `QuestionBank.submit`: an incorrect answer awards no XP but updates stats. The question card in `ui/lecture_ui.gd` (arrow keys or 1–4, then E) is reusable for the upcoming question set. After answering, it shrinks to show only the chosen and correct choices plus the explanation.

**Character models:** a procedural rebuild (realistic proportions, strand hair) was prototyped in this session, but at the user's request it was reverted in full. The character models, presets, seat dimensions and NPC route are exactly as committed in `405f17f`.

**NPCs are solid (user request).** Alex and Sam carry an animatable capsule on physics layer 3 (disabled when hidden or seated, since the seat's colliders cover seated figures), and the professor has one too. The player now collides with layer 3. Interaction raycasts stay world-only, so NPCs never block prompts.

**Signs no longer cover objects (user request).** `ui/world_nameplate.gd` gained mounted signs: flat, depth-tested plates attached to surfaces, created with `Geometry.wall_sign()`.
- **Dorm:** the "PHARMACOLOGY" label was removed, and "FIRST YEAR" is lettered flat on the noticeboard, so it follows the board's angle. EXIT is smaller and sits above the door.
- **Campus:** CEDAR RESIDENCE sits on the wall between awning and cornice; LEARNING CENTER is above the glazing; LECTURE HALL A is on a canopy fascia; CAMPUS DIRECTORY is on a header plate. The floating path label became a two-post wayfinding sign beside the walk.
- **Elsewhere:** the lobby hall sign is on the wall above the door, and the vending-machine labels are on the machine headers.

**Podium (user request).** The podium has a flat top with two monitors on real stands (base, neck and hinge), with screens facing the professor and showing a slide thumbnail. It also has a keyboard with individual keys, a mouse on a pad with its cable, and a gooseneck microphone. The mic has a weighted base and a curved segmented neck, and its capsule, red ring and windscreen sit just in front of and below the professor's mouth.

**Verification:** all suites pass — foundation 54, dorm 67, campus 38, NPC 37 (new NPC-blocking checks), academic 77, visual motion 19, room polish 25, seating 147, lecture 59 (new model and activity checks, including a deliberately wrong prediction). Editor import and `git diff --check` pass. Graphical captures of the activity (every phase), podium, dorm desk and board, and campus signs were inspected.

**Limitations:** the auditorium seat pitch stays wide (0.92 m) to suit the broad stylized figures.

**Remaining Milestone 7 work:** about 12 lecture questions with feedback and selective remediation, the concept → clinical → application question beats, lecture completion, and the acceptance record.

## 2026-09-23 08:49 PDT — Professor presentation, turf lawn, muted Hall A

Committed the previous change set (`2f0eac8`); both commits were pushed to origin/main together.

**Professor presentation (Milestone 7).**
- **Script as data:** `src/education/lectures/pharmacodynamics_01.json` has 11 segments: introduction; the nine suggested topics in order (receptors and ligands, agonists, antagonists, competitive and noncompetitive antagonism, potency, efficacy, dose-response relationships, clinical application); and a summary. Each segment has one slide (heading, up to four progressively revealed bullets, one diagram) and three or four professor lines with gestures. Schema: `src/education/lectures/README.md`.
- **Runner:** `lecture_runner.gd` validates the script and steps line by line with signals. It has no UI dependency.
- **Model:** `src/education/models/dose_response.gd` provides the Hill equation, occupancy, the competitive dose ratio and the noncompetitive Emax. It is shared with the upcoming interactive model.
- **Slides:** `src/ui/lecture_slide.gd` renders onto the hall's projection screen through a SubViewport. The curves are drawn from the model on a log axis (full vs. partial agonist, competitive shift, noncompetitive depression, potency, efficacy, quantal ED50/TD50 with TI, clinical opioid, summary), plus receptor diagrams.
- **Professor:** `src/npc/professor.gd` (Dr. Lena Park) breathes and shifts her weight, gestures with alternating hands while speaking, and for "screen" lines half-turns and points with the arm on the screen's side.
- **Overlay:** `src/ui/lecture_ui.gd` is compact: a small subtitle card with the speaker's name, typewriter text and a Continue keycap, a topic chip (e.g. "5 / 11 · Competitive antagonism"), and a waiting card.
- **Session flow** (`src/world/lecture_hall/lecture_session.gd`):
  - Sitting before 8:00 shows "Class begins at 8:00 AM" with Space: wait for class, or E: stand up. Waiting fast-forwards the academic clock, and the autonomous NPC event by the matching real time, to the start of class.
  - Once class time has come and the lecture camera has settled, the seat locks, the exploration controls hint hides, and the presentation starts. E, Space or Enter first finishes the current line and then advances.
  - At the end, the presentation is recorded in `AcademicSession.presentations_completed`, the seat unlocks, and a closing message appears. Sitting again does not replay it.
  - The HUD's own prompt and toasts give way while the lecture overlay is showing.
- **Fix:** `seating.state_changed` now fires after seating finishes settling, so listeners can lock the seat reliably.

**Lawn (user reference image).** `grass.gdshader` now draws dense, short, vivid turf: procedural blade flecks at two scales in world space, over very soft tonal variation, with the finest layer faded out at a distance. The tufts are 18,000 short instances in matching greens, and the wildflowers were removed.

**Hall A palette (user request: modern and clean, not bright white).** The hall now uses slate carpet on the floor and tiers, warm greige walls, walnut panelling, muted trim and whiteboard, and slightly lower ambient and key light. The seats keep their colour, which the user approved.

**Verification:** foundation 54, dorm 67, campus 38, NPC 35, academic 77, visual motion 19, room polish 25, seating 147, lecture 42 (new) — all passing. Editor import and `git diff --check` pass. Graphical captures of the whole presentation (every segment and screen-gesture line), the waiting prompt, the hall palette and the lawn were inspected; a mis-anchored subtitle card and slide label overlaps were found and fixed.

**Limitations:**
- The professor does not walk.
- Lines are advanced by the player; there is no voice-over or audio.
- Slides are 2D in a SubViewport and are not readable from the isometric view (they are meant for the seated view).
- Narration awaits human medical review (`MEDICAL_CONTENT_REVIEW.md`).

**Remaining Milestone 7 work:** the competitive-antagonism interactive visualization, about 12 original lecture questions with feedback and selective remediation, the concept → clinical → application question beats in the script, lecture completion, and the acceptance record.

## 2026-09-23 08:03 PDT — Auditorium Hall A, lecture camera, sprint, campus fixes and lawn

Committed the previous change set first (`a20e234`).

**Hall A rebuilt as a raked auditorium**, modeled on the reference photo of a UIC medical-school lecture hall the user supplied (`src/world/lecture_hall/lecture_hall.gd`):
- A floor-level teaching area at the front with a large framed projection screen, a whiteboard, a dark podium with two monitors and a gooseneck microphone (the professor stands behind it), and a side table with two loose chairs.
- Five tiers (0.38 m rise, 1.6 m deep) of upholstered orange-red seats in three sections, split by two stepped aisles. The seats have pedestals, padded backs, shared armrests and row-end panels.
- Wood panelling with reveals on the long wall, and blue double doors with an exit sign at the front left.
- 65 seats in total: 14 classmates plus Alex's saved seat are taken, leaving 50 open.
- **Seat spacing:** the stylized figures are about 0.85 m across the arms, so auditorium seats use a 0.92 m pitch and a 0.8 m cushion. At a realistic 0.6 m, seated arms would pass through the armrests.
- **Aisle collision:** the aisles show two steps per tier, but their collision is a smooth ramp through the step nosings. Walking is continuous, and feet can sit up to about 7 cm off the drawn step.

**Row-seat routing.**
- `world/seat.gd` gained an `auditorium` style and a `navigator` callable.
- The hall builds a walkway graph (`AStar3D`) with a node in front of every seat, aisle landings, the foot and head of each flight, and floor nodes near the door.
- `SitSequence.plan_row_sit()` walks that route, then turns, backs up to the cushion and sits. Approach labels: `front` (already in front of the seat), `row_left` / `row_right` (along the row from the sitter's left or right), or `back` (from the row behind, routed through the nearest aisle).
- Seated classmates' legs are solid, so the player walks around them in the walkway.
- The two table chairs keep the free-standing four-side approach.
- Alex now enters through the front-left door, climbs the left aisle and walks along row 2. When watched, he turns and sits from the walkway.

**Lecture camera transition** (`src/world/lecture_camera.gd`).
- On sitting, a perspective camera takes over. It starts as a 5° field-of-view camera placed far back along the isometric camera's ray, framing the same height, so the first frame matches the orthographic view (the test measures the drift in pixels).
- It then blends focal point, direction (slerp), framed height and field of view (log space) with smootherstep over 1.7 s, arcing over the audience to an over-the-shoulder view of the screen, podium and professor.
- Standing up reverses it and hands back to the exploration camera.
- A ceiling with light panels and full-height near walls fade in only as the lecture view settles, so the isometric cutaway is unchanged.
- `seating.stand_locked` is still the hook for keeping the player seated during class.

**Sprint** (user request).
- The new `sprint` action is bound to Shift and controller L3. Speed ramps from 3.2 to 5.8 m/s over 0.25 s.
- `appearance.gd` blends a run gait from actual ground speed: longer stride cycle, bigger hip swing, the recovering knee folded high, knee lift through the swing, harder arm pump with slightly tucked arms, forward torso lean and more bounce.
- The HUD help row shows a compact Shift/L3 keycap.

**Campus visual fixes** (user screenshots).
- **Cedar Residence:** the horizontal trim lines that crossed the door and windows (and poked out as dots at the corner) were removed. The facade now has a plinth, cornice, corner boards, framed windows with muntins and sills, and a framed door with a glass panel, handle and small awning.
- **Learning Center entrance ("Lecture Hall A"):** a window sill whose front face was coplanar with the door leaf was z-fighting, and it ran through the door. The facade was rebuilt: glazed bays with sills that stop at a proud door frame, two tinted leaves with push bars, and a centre stile. Every layer sits at its own depth.

**Detailed lawn** (user request).
- `src/assets/grass.gdshader` adds broad, low-contrast, non-repeating tonal patches and fine blade speckle in world space, so it has no tiled pattern.
- About 8,000 deterministic grass tufts are drawn in one `MultiMesh`, with a gentle per-tuft sway in `grass_blades.gdshader` and a sprinkling of small wildflowers. Paths, buildings, the planter and other furniture are excluded.

**Verification:** foundation 54, dorm 67, campus 38, NPC 35, academic 77, visual motion 19 (new sprint checks), room polish 25, seating 147 (rewritten for the auditorium, including camera hand-off checks) — all passing. Editor import and `git diff --check` pass. Graphical captures of the campus facades, lawn, sprint, hall, a back-approach sit, and the camera transition in both directions were inspected; the hall runs at about 60 FPS on the M1.

**Limitations:**
- Auditorium seats are wider than real ones to suit the character proportions.
- Aisle steps use a ramp collider.
- The ceiling fades in rather than being a permanent mesh.
- The lecture itself (presentation, visualization, questions, completion) is still to come.
- Physical controller hardware remains untested.

## 2026-09-23 07:10 PDT — Docs cleanup, compact HUD, Milestone 7 started (Hall A seating)

**Docs/test cleanup.** `CLAUDE.md` now points to this file (it referred to a nonexistent `CHANGES`) and no longer claims work is uncommitted; everything through Milestone 6 is committed. `PROJECT_HANDOFF.md` has a current-status banner, an updated milestone history and correct paths; its stale Milestone 2 brief was removed. `tests/foundation_test.gd` looked for the old `src/docs/development/CHANGELOG.md` and now checks the repository-root `CHANGELOG.md` (the only failure in the baseline run). For the record, `room_polish_test.gd` ran 21 checks before this change set, not the 24 reported below.

**Compact HUD (user request).** `src/ui/dorm_ui.gd`: the base font drops from 18 to 15 px. The location and clock are small translucent cards sized to their content, laid out in a top bar. The bottom-left controls and the contextual prompt are drawn directly over the world with no filled boxes: a small keycap plus outlined text. Response messages use a narrow card that is shown only while there is text. `src/ui/key_prompt.gd` keycaps are smaller and sized to their label. The menu panel shrank slightly. World sign nameplates keep their filled backings, per the earlier preference.

**Milestone 7: Hall A seating (user request: sit in any seat, with realistic motion from the side you approach).**
- `src/world/seat.gd`: a reusable solid chair (colliders for the seat and backrest; visible legs and rear posts) with local approach points: front, both sides, back corners, pre-sit and exit. A taken seat has no interaction and a collider covering the seated person's legs.
- `src/world/lecture_hall/lecture_hall.gd` was rebuilt: 18 chairs in three rows with a centre aisle, six seated classmates, the professor at a lectern, a titled display, and Alex's saved seat (jacket over the backrest). The 11 free chairs can all be used.
- `src/player/sit_sequence.gd` plans and plays the motion, based on which side of the chair the player is on. From the left or right he walks beside the chair, turns to face forward and side-steps in front of the cushion. From the front he walks to a point in front, turns around and backs up. From behind he detours around a back corner to a free side. Blocked approach points are rejected with a shape query and another side is tried; if none is clear, the HUD says so. Walking uses the body's real `move_and_slide` collision. Only the final side-step/back-step and the sit itself are kinematic, and none of them pass through the chair.
- `src/player/appearance.gd` now has knee joints and a spine pivot. `set_sit_blend(t)` blends continuously: hips hinge and drop, knees bend, the torso leans forward to balance and settles back, and the arms come forward onto the thighs. Walking bends the knees slightly, and side-steps swing the legs outward.
- `src/player/seating.gd` (added to the player at runtime) handles E to sit, E to stand, a stuck-walk abort and a `stand_locked` hook for the lecture. Movement input is ignored while seated.
- Alex now walks down the aisle to the side of his saved seat. If the player is watching, he turns, side-steps and sits with the same animation; otherwise he loads already seated.
- Classmate/professor looks are in `Presets.EXTRAS`, which cannot be selected as player presets.
- New `src/tests/seating_test.gd` (79 checks) covers every approach side, 30/60/120 Hz ticks, real E-key input, standing up, the ignored movement input, blocked seats, and a per-tick audit. The audit checks that the body never enters a chair's footprint outside the sit itself and that walking never overlaps solid geometry. `room_polish_test.gd` gained checks for unboxed keycaps and HUD coverage.

**Verification:** foundation 54, dorm 67, campus 38, NPC 35, academic 77, visual motion 11, room polish 25, seating 79 — all passing. Editor import and `git diff --check` pass. Graphical captures of the left, front and back sits and of the dorm, campus and hall HUD were inspected. **Limitations:** the stand-up always exits to the front. The chair colliders are simple boxes. Seated classmates are static figures. Physical controller hardware remains untested.

**Remaining Milestone 7 work:** lecture camera transition, professor presentation, competitive-antagonism visualization, about 12 questions with feedback and remediation, lecture completion, and the Milestone 7 acceptance record.

## 2026-09-23 05:03 PDT — Handoff recorded; latest dorm wood change completed on 2026-09-23

- Added `src/assets/wood.gdshader`, an original procedural wood material with fine grain, slight board variation, and restrained plank joins. `src/world/dorm/dorm.gd` applies it to the floor and wood furniture through `_apply_wood()`.
- The user explicitly disliked strong patterns on **all** floors. The lobby carpet and campus paths are plain, and the dorm rug is plain. Keep future wood details natural and low contrast rather than adding conspicuous stripes or repeating floor tiles.
- The final dorm render was inspected after the wood change. `src/tests/room_polish_test.gd` passed 24 checks, and Godot's final editor import and `git diff --check` passed. See `src/docs/development/ROOM_UI_POLISH.md`.

## 2026-09-23 05:03 PDT — Handoff recorded; room, shadow, and UI refinement completed on 2026-09-23

- Reworked `src/world/lecture_building/lecture_building.gd`: muted, solid carpet; two detailed decorative vending machines; cushioned library sofa; bookshelf. The center corridor remains open for the player and scheduled NPC. Vending machines are scenery, with no interaction behavior yet.
- Reorganized `src/world/dorm/dorm.gd`: the chair and laptop are centered at a real tabletop with four legs and open space beneath it; the stray cabinet was removed. The bed, bookshelf, entry, and study interaction remain usable.
- Improved shadows by preventing cutaway wall meshes from casting unrealistic interior shadows, setting camera far range in `src/world/exploration_camera.gd`, tuning the shared directional light in `src/world/geometry.gd`, and raising directional shadow precision in `src/project.godot`. This removed the diagonal shadow bands and jagged roof outline visible in the user's screenshots.
- Added filled world labels in `src/ui/world_nameplate.gd`, keyboard/controller keycaps drawn in `src/ui/key_prompt.gd`, and licensed Outfit typography in `src/assets/` (license: `Outfit-LICENSE.txt`). The shared exploration HUD in `src/ui/dorm_ui.gd` uses these elements, has a more compact interaction panel, and displays the written-out date (for example, **September 21st, 2026**). Date formatting lives in `src/autoload/game_clock.gd`.
- Latest checked graphical captures are the dorm, lobby, and campus images documented by `src/docs/development/ROOM_UI_POLISH.md`. Room/UI checks: 24 passed; the contemporaneous dorm, campus, NPC, academic, and motion suites also passed. Physical controller hardware was not tested.

## 2026-09-23 05:03 PDT — Handoff recorded; visual and movement polish completed on 2026-09-23

- Strengthened the campus/interior palette and morning lighting and added landscaping, planting, facade trim, window reflections, potted plants, and antialiasing. The scene builders are in `src/world/campus/`, `src/world/dorm/`, `src/world/lecture_building/`, and `src/world/lecture_hall/`; shared geometry helpers are in `src/world/geometry.gd`.
- Refactored `src/player/appearance.gd` into a shared procedural character pose with independently swinging legs and arms, foot movement, subtle bounce, and a seated pose. `src/player/player.gd` advances the gait from actual displacement so pushing against a wall does not make the player walk in place. `src/npc/student.gd` animates from the NPC's actual movement. `src/tests/visual_motion_test.gd` covers walking, idling, collision blocking, NPC motion, seated behavior, and frame-rate independence.

## 2026-09-23 05:03 PDT — Handoff recorded; Milestones 5–6 completed on 2026-09-23

- **Milestone 5:** `src/autoload/game_clock.gd` and `src/data/academic_config.json` provide a 5× fictional clock, academic date/week/semester, and an 8:00 AM mandatory Pharmacodynamics event in Lecture Hall A. `src/ui/schedule_panel.gd` powers Today and Calendar tabs inside the exploration menu. Campus daylight follows the clock.
- `src/autoload/academic_session.gd` records the **first successful Hall A entry** for the event date. Arrival after the configured start/grace period is late. The late penalty is exactly −5 XP and applies once, even when the starting balance is zero. Later rewards repay that signed balance. New Game resets academic state; the title stops the clock.
- **Milestone 6:** `src/education/questions/question_bank.gd` loads and validates versioned JSON atomically, gives callers deep copies, grades multiple choice and predefined normalized short answers, supplies explanations and objectives, and records idempotent XP/performance transactions keyed by attempt ID. `src/education/questions/pharmacodynamics.json` has three original seed questions. Schema/API details: `src/education/questions/README.md`; medical review notes: `src/docs/development/MEDICAL_CONTENT_REVIEW.md`.
- The question engine is intentionally independent of lecture presentation. There is no full lecture question set or delivery UI yet. Levels, save/load, and remediation are also later scope. Acceptance record: `src/docs/development/MILESTONES_5_6_ACCEPTANCE.md` (77 academic headless checks and 79 graphical checks, plus 193 earlier regression checks, all passing at that milestone).

## 2026-09-10, exact time not recorded — Milestone 4: autonomous student

- Added persistent `src/autoload/npc_schedule.gd`, authored AStar routes in `src/data/npc_route.gd`, reusable `src/npc/student.gd` / `.tscn`, and a minimal `src/world/lecture_hall/` scene. Alex meets Sam, talks, walks through campus and lobby, enters Hall A, and sits. The sequence progresses while offscreen or while the settings menu is open.
- `src/tests/npc_test.gd` verifies the sequence and routes. Acceptance notes: `src/docs/development/MILESTONE_4_ACCEPTANCE.md`.

## 2026-09-10, exact time not recorded — Milestone 3: campus

- Replaced the temporary dorm exit with an explorable courtyard and Learning Center lobby. Added collision, doors, directory/student interactions, isometric camera follow, location HUD, and campus traversal tests.
- Main files: `src/world/campus/campus.gd`, `src/world/lecture_building/lecture_building.gd`, and `src/tests/campus_test.gd`. Acceptance notes: `src/docs/development/MILESTONE_3_ACCEPTANCE.md`.

## 2026-09-10, exact time not recorded — Milestone 2: player and dorm

- Added four selectable character presets, reusable player movement/collision and appearance, a low-poly dorm with bed/desk interactions, orthographic camera, scene transitions, and dorm tests.
- Main files: `src/player/`, `src/world/dorm/`, `src/data/character_presets.gd`, and `src/tests/dorm_test.gd`. Acceptance notes: `src/docs/development/MILESTONE_2_ACCEPTANCE.md`.

## 2026-09-09, exact time not recorded — Milestone 1: foundation

- Created the Godot project structure, input actions, title screen, character selection foundation, session settings, `AppState` scene transitions, and foundation tests. `Continue` remains disabled until save/load is implemented.
- Acceptance notes: `src/docs/development/MILESTONE_1_ACCEPTANCE.md`.

## How to resume

1. Read the product spec and the relevant milestone/run document before beginning another milestone. Read this file from top to bottom for the current architecture and user preferences.
2. Inspect `git status --short` before editing and preserve any uncommitted work you find.
3. Run tests with `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --script res://tests/<suite>.gd`. Existing suites are `foundation_test.gd`, `dorm_test.gd`, `campus_test.gd`, `npc_test.gd`, `academic_test.gd`, `visual_motion_test.gd`, `room_polish_test.gd`, `seating_test.gd`, `lecture_test.gd`, `progression_test.gd`, and `knowledge_test.gd`. Use `--path src --editor --import --quit` to validate import. Run graphical capture when visual behavior changes.
4. Update this file with a new timestamped section at the top for each future change set. Preserve the user's preferences: plain floor surfaces, subtle wood grain, a small HUD with unboxed keycap prompts, physically plausible character motion around furniture, and the UIC-style raked auditorium for Hall A.

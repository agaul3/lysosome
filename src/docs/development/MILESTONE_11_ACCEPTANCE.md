# Milestone 11 — Physician Shadowing / Hospital Orientation

Recorded 2026-09-24 (PDT). Status: **PASS**. Every requested space, system and flow step is implemented and covered by automated tests. Graphical checks were made from captures in both camera modes. Medical content awaits human review; this is expected and is not a blocker for the milestone.

## Scope delivered

| Requirement | Where |
|---|---|
| Big modern hospital across the street from the parking lot and quad | `world/campus/buildings.gd` `hospital()`: a 56 × 26 m podium, a set-back tower, and an east entrance pavilion with a drop-off canopy |
| Exterior arrival | Sidewalk, path, zebra crossing and entrance plaza (`campus.gd`, `CampusConfig.CROSSWALK_X` / `HOSPITAL_PLAZA`), wayfinding pylon, door endpoint |
| Lobby / atrium | `world/hospital/hospital_lobby.gd`: 36 × 24 m, 9 m high, glass front with automatic doors, skylight, ring pendant, lounge, indoor trees, mezzanine and stair (roped off) |
| Security, reception, information | Security podium and guard, curved Information desk with receptionist, directory totem, floor directory |
| Elevators and waiting zone | Walnut elevator bank (4 visitor + 2 staff cars, one working car), lounge seating with visitors, café and gift shop |
| Main corridor and nurses station | `hospital_unit.gd`: a 36 m corridor, and the station with charting desks, telemetry and census boards and a slatted ceiling |
| Physician workroom / charting | Team workroom with an island of workstations and the EHR workstation |
| 2–3 patient rooms | Rooms 410–415. 412 (the rounds patient) and 413 (empty) are open; 414 is under contact precautions. Each has a bed, headwall, window, bathroom, chair and whiteboard |
| Support / orientation area | Clean supply, family lounge, student orientation board, isolation cart, workstation on wheels |
| Inaccessible corridors implying more | Emergency Department and Outpatient Clinics corridors ending in staff doors; 4 East beyond closed doors; staff door; Level 2 mezzanine |
| Navigable in both camera modes | Cutaway overhead (walls and columns cut to 1.05 m) and a whole building in first person; one set of full-height colliders |
| Flow: arrive → lobby → meet → orientation → follow → logistics → workflow and rounds → etiquette → complete | `education/shadowing/hospital_orientation_01.json` (9 stops) run by `world/hospital/shadowing_session.gd` |
| Wayfinding, signage, floor logic, objectives | Directory totem, floor directory, mounted signs, room numbers, floor labels, per-floor HUD location, per-stop objectives and topic chip, map entry |
| Physician: meet, follow, stops, dialogue | `npc/physician.gd`: walks routes, waits if you lag ("Stay with me."), pauses and says "Excuse me." if blocked, faces and gestures while talking |
| Etiquette moments | Punctuality (attendance and late penalty); public-space privacy; introducing yourself to the charge nurse; hand hygiene in and out; observer position at the bedside; contact precautions; wrap-up |
| Lightweight EHR introduction | `ui/ehr_chart.gd`: banner, vitals, results, notes for one fictional patient, on the workroom monitor, with a close-up camera |
| Reuse existing systems | LectureUI, QuestionBeat, QuestionBank, AcademicSession (attendance, XP, notes, completion), Interactable, NPC blockers, pedestrians, LectureCamera, MeshKit, Flora, HUD, SaveGame, Objectives, map and notes pages |

Out of scope, as requested:
- patient history, examination and diagnosis gameplay;
- full clinical rotations;
- a full EHR (it is read-only, with no orders or entries);
- multi-floor simulation (two floors only);
- branching scenarios;
- procedural generation.

## Automated tests

`tests/hospital_test.gd` passes 108 checks and 0 failures. It covers:
- **Script data:** the stop order, the 7 bank questions, the takeaways and every step type; malformed scripts are rejected.
- **Getting there:** the walk from the campus sidewalk over the crossing to the entrance; bounds, the camera follow, the entrance prompt and the transition.
- **Arrival:** the spawn, the floor title, that every script anchor and action target exists, the cutaway, and the automatic doors.
- **Too early and solidity:** the "too early" refusal before class, and that the physician is solid.
- **The on-time session with real movement:**
  - following, including falling behind (she waits and says so);
  - the elevator ride with her;
  - the charge-nurse talk prompt and reply;
  - the EHR close-up and its banner, vitals, results and notes;
  - hand hygiene prompts in and out, and standing on the mark at the foot of the bed;
  - all 7 questions answered through input;
  - the summary; completion, notes, XP, the Clinical Skills statistics and stable attempt ids; the objectives.
- **Afterwards:** first-person walks on both floors, a free elevator ride back, saving in the hospital (location and summary), and leaving through the front doors to the campus spawn.

The regression suites were re-run and all pass: foundation, academic, knowledge, flashcard, save, ui, progression, npc, ambient, campus, dorm, lecture, acceptance, first_person, seating, room_polish, wardrobe, visual_motion and cafe_exit. `academic_test` now expects the combined bank, and `knowledge_test` expects the second discipline.

## Graphical checks (captures, both views)

- **Campus:** the crossing (overhead), the plaza and entrance (overhead and first person), and the hospital seen from the parking lot (first person).
- **Lobby:** the entrance, the elevators and the lounge (overhead); the entrance, lounge, café and elevator bank (first person).
- **4 West:** the corridor, station, room 412, workroom and isolation door (first person); both halves of the unit (overhead).
- **Session:** the greeting with the dialogue card (both views), and the EHR close-up (vitals and banner).

Adjustments made after review:
- a muted palette (the floors were blown out to white);
- columns cut away in the overhead view;
- walnut feature finishes;
- steel-toned elevator doors;
- lighter door frames;
- the EHR framed between the HUD and the dialogue card;
- the chart's allergy field fitting its column;
- distant context blocks moved away from the plaza.

## Manual checks still recommended

- Play the whole session by hand in both views with keyboard/mouse and a controller. In particular, check comfort following her through doorways in first person, and the feel of the elevator fade.
- Readability of the EHR and signs at small window sizes, and fullscreen.
- A pass on the visual tone of the lobby and unit (lighting warmth, floor colours) on the target display.
- Human medical review of all shadowing content (`MEDICAL_CONTENT_REVIEW.md`).

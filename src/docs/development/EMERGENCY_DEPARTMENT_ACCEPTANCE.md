# Emergency Department — Level I trauma center and Emergency Radiology

Recorded 2026-09-24 (PDT). Status: **PASS**. Every requested element is built and covered by automated tests with real movement. Graphical checks were made from captures in both camera modes. Medical and operational content awaits human review (see `MEDICAL_CONTENT_REVIEW.md`); as with Milestone 11, this does not block the feature.

## The request

The user asked for an emergency department for University Hospital: a Level I trauma center similar to Northwestern Memorial Hospital's in Chicago, based on seven photos (the ambulance entrance with "AMBULANCE ONLY", the red EMERGENCY pylon, the ambulance garage, the main porte-cochère, a glass-fronted ED room, an ED station, and a "Pods" nurses station). It should have:
- an ambulance outside;
- a department that feels very alive, with patients arriving on stretchers pushed by EMTs, and the typical ER double doors opening;
- an ambulance driving in and out of the ER driveway about every 5 real minutes;
- areas of care by how critical patients are, labelled the way Northwestern actually labels them;
- a second floor with MRI, CT and other imaging;
- security at the entrance, automatic sliding doors inside the department (which must be functional), a medication/supply room, computers, and TV screens showing patient vitals and bay numbers.

## Research and the acuity scale

- **Northwestern Memorial's ED:**
  - a Level I trauma center and stroke center (Northwestern Medicine's ED page);
  - about 100,000 visits a year, with trauma managed in "the trauma half of the ED" (Feinberg Department of Emergency Medicine, training sites);
  - a **Super Track**, an evolution of the split-flow model for low-complexity patients, and a 15-bed **Boarder Care Unit** for admitted patients awaiting beds (Feinberg Department of Emergency Medicine, clinical operations initiatives).
- **Triage scale:** Northwestern's public pages don't name one. The standard five-level scale in US EDs is the **Emergency Severity Index (ESI)**, and ESI version 3 was validated in research at Northwestern's Division of Emergency Medicine (Tanabe et al., *Journal of Emergency Nursing*, 2004).
- **Direction of the scale:** in ESI, **Level 1 is the most critical** (resuscitation) and Level 5 the least (non-urgent). That is the opposite of the numbering in the request. The game uses the real convention everywhere: signs, boards, the waiting-room screen and the triage endpoint.
  - 1 Resuscitation: immediate life-saving intervention.
  - 2 Emergent: high risk or a time-critical problem.
  - 3 Urgent: stable, two or more resources.
  - 4 Less urgent: stable, one resource.
  - 5 Non-urgent: stable, no resources.
- **Board colours** (1 red, 2 orange, 3 yellow, 4 green, 5 blue) are a colour code chosen for the game, not a documented Northwestern standard.
- **Branding:** no Northwestern or Chicago Fire Department names or logos. The building stays "University Hospital", and the units are generic ("EMS 7", "Medic 4").

## Scope delivered

| Requirement | Where |
|---|---|
| Emergency front of the hospital on campus | `buildings.gd` `_emergency_front()`: the south face on a new back street, with limestone pilasters, a red-walled AMBULANCE ONLY bay with soffit lights and bollards, a red EMERGENCY canopy over the walk-in doors, and a red EMERGENCY pylon |
| An ambulance outside | One stays parked in the campus bay (`ems_arrivals.gd`); another is parked in the ED's own ambulance garage (`ed_life.gd`) |
| Ambulance in and out about every 5 real minutes | `EMSArrivals.PERIOD` = 300 s (first arrival 25 s after reaching campus). It drives along the back street with lights flashing, pulls past the bay and **backs in** rear to the doors. The crew wheels the patient through the bay's automatic doors and comes back 90 s later with the empty cot, then it pulls out and drives off. It brakes for the student. |
| Patients on stretchers, EMTs pushing | `npc/cart_crew.gd`: a paramedic pushing a cot at the head end and an EMT guiding from the foot end (in line, so they fit the doorways). Inside the ED, every 2–2.7 minutes a unit calls in (shown on the trauma board with a live ETA), pulls into the garage, and the crew wheels the patient through both sets of EMS doors to a trauma bay or acute room, hands over (the patient moves to the bed and appears on the boards), backs the empty cot out and leaves |
| The ER doors that open | `sliding_doors.gd`: the campus bay doors; the ED's EMS vestibule (outer and inner) and walk-in vestibule (outer and inner); the Super Track doors; the medication room door. They open for the student and for anyone in the `door_openers` group (crews, walking patients, transport) |
| Areas by acuity (real ESI labels) | **Trauma & Resuscitation · ESI 1**: T1–T4 by the ambulance entrance (T1 & T2 share a large room with an active trauma team). **Acute Care · ESI 2–3**: Rooms 1–12 around the central station. **Super Track · ESI 4–5**: 5 recliners by the waiting room. Floor labels, hanging signs, an ESI information board, the waiting-room screen and board colours |
| Second floor: MRI, CT, … | `hospital_imaging.gd`: Level 2 Emergency Radiology by the ED elevator. It has CT 1 and CT 2 with lead-glass control rooms and tables that slide the patient in and out; the MRI suite (Zone III control room, Zone IV magnet room, copper RF door, ferromagnetic posts, safety signs); X-ray; ultrasound; patient holding; a dim reading room; and MRI screening and lockers |
| Alive with people | `ed_life.gd`: 6 staff walking a department graph; walk-in patients through both door sets, security, registration and a seat; triage calls to Super Track; discharges out through the doors; a wheelchair transport to radiology and back; a stretcher transport upstairs; the trauma team, family members, triage nurses, a registrar, a housekeeper and seated clinicians |
| Security at the entrance | A walk-through metal detector, bag table, security desk and two guards at the walk-in, with an "All visitors are screened" sign and a guard to talk to |
| Automatic sliding doors inside | Glass-fronted trauma bays and rooms (`_glass_front`: clear glass, mullions, a transom band). Their sliding doors open only for someone stepping up to the doorway (`auto_depth`), so they stay shut as people pass along the corridor. Room 11 is locked while being cleaned. Shut doors are solid. |
| Medication / supply room | A medication room behind a solid automatic door with a badge reader (a student badge opens it), with automated dispensing cabinets, a fridge and a counter with a sink (endpoint), plus clean supply and decontamination |
| Computers | Central station and trauma station workstations, physician desks, triage, registration, security, EMS check-in, workstations on wheels in rooms, CT/MRI control rooms and the reading room |
| TVs with vitals and bay numbers | Bedside monitors in all 16 bays showing live, drifting fictional vitals, with bay label, ECG, pleth and respiration traces (`ui/vitals_atlas.gd`). Also tracking boards (bed, ESI, initials, complaint, RN, MD, status, time), the trauma board (EMS inbound with ETA, the four trauma bays) and waiting-room screens (`ui/ed_display.gd`). Radiology monitors show schematic studies (`ui/radiology_images.gd`) |
| Everything else | Triage bays, registration, a waiting room with vending machines and a check-in kiosk, EMS check-in, portable X-ray and spare stretchers, results waiting, physician workstations, doors to the Boarder Care Unit, and a staff corridor to the main atrium |
| Getting there | Walk round the hospital to the ED doors on campus (the campus map marks the ED entrance), or take the atrium's staff door. Saving in the ED resumes there. |

## Automated tests

`tests/emergency_test.gd` passes 68 checks with 0 failures. It covers:
- **Campus:**
  - the 5-minute period and first arrival, and the parked ambulance;
  - the walk round to the ED entrance, the camera follow, and the street edge;
  - a full ambulance cycle: lights, backing in (rear to the doors), the crew unloading, the bay doors opening for the crew, going inside, the cot coming back, departure and the next arrival time.
- **The walk-in:**
  - both door sets opening as you walk up and closing behind you, and closed doors being solid;
  - the security arch, the ESI information board (Level 1 is the most critical), the tracking board spanning ESI levels, and live boards;
  - through the Super Track doors.
- **Treatment doors:**
  - room doors staying shut as you walk past;
  - into Room 1 through its doors, which close behind you;
  - locked Room 11 staying shut;
  - into Trauma 4;
  - through the EMS vestibule's inner and outer doors to the garage and its parked ambulance;
  - the medication room's badge-reader door (shut, opens as you walk up, and the cabinets inside).
- **EMS inside:**
  - dispatch shown on the trauma board;
  - the crew opening the ambulance doors and the bay's doors;
  - the handover (the patient is on the bed and on the board);
  - a hidden crew leaves nothing solid;
  - the empty cot backed out of the bay (not turned round inside);
  - the ambulance leaving.
- **Life:**
  - a walk-in coming off the street (the doors open for patients);
  - staff and walkers present;
  - the elevator up to Emergency Radiology;
  - the CT table sliding;
  - the elevator back down.
- **Finishing:**
  - first person: the whole department, into Room 3 through its doors, and the corridor;
  - the staff door to the main atrium and back;
  - saving (resumes in the ED);
  - leaving through the walk-in doors to the campus ED spawn.

The department is busy, so the test's walks step round staff and patients the way a player would (people pause for the student rather than walk through them).

`tests/ed_clearance_test.gd` (8 checks, 0 failures) guards the "no clipping" rule. Scripted people move without physics, so it sweeps every route against every box of the ED and radiology geometry (visual boxes as well as colliders) and the standing figures:
- walk-ins to every seat, triage calls and discharges;
- EMS cots to each reachable bay and backing out;
- wheelchair and radiology transports;
- staff paths and their step-aside lanes.

Writing it found and fixed these:
- **EMS cot and crew:** the second EMT walked beside the cot, too wide for the bay doors and into a room's side wall at the handover. The cot also spun in place leaving a bay.
- **Room layout:**
  - The portable X-ray stood in the Trauma 1 & 2 doorway.
  - Room 12's door was at the corridor's dead end, where turning carts swept the end wall.
  - The trauma board poked through into the medication room.
- **Walkers:**
  - Discharged patients clipped the security arch's post, and walk-ins cut through the check-in kiosk's screen.
  - The arch was narrower than the figures' arm span.
  - Staff cut across the central station's counter corners.
- **Seats:** the recliners' extended leg rests and deep cushions went through seated shins.
- **Elevators:** a hidden transport left an invisible solid wheelchair in front of the elevator, and out-of-service elevator doors were walk-through (also on 4 West).
- **Garage:** a red wall panel covered the ambulance doorway.

All other suites pass: hospital, foundation, academic, knowledge, flashcard, save, ui, progression, npc, ambient, campus, dorm, lecture, acceptance, first_person, seating, room_polish, wardrobe, visual_motion and cafe_exit. `ambient_test`'s dog-walker wander check failed once in four runs and passed on rerun. It uses unchanged code, so this is a pre-existing intermittent check.

## Graphical checks (captures, both views)

- **Overhead:** the entrance, triage and waiting, the station, trauma, the garage with an EMS arrival, radiology, and the campus exterior with the ambulance backing in.
- **First person:** the security arch, waiting, the room corridor, the station, the Trauma 1 & 2 door, the EMS doors from both sides, the medication room door (shut and open), Super Track recliners with seated patients, CT and MRI.
- **Zoomed close-ups:** the crew through the vestibule doors and along the corridor, into a bay, the handover, backing out; a walk-in sitting down, seated, and a called patient getting up.

## Manual checks still recommended

- Watch a full 5-minute campus cycle in real time and a few ED arrivals. Judge the pacing, and check whether the ED's own, busier arrival rate feels right.
- Frame rate on the target machine. The ED shows three live 1280×720 board viewports and a 1280×800 vitals atlas while you are on the ED or radiology floor.
- Door feel with a controller and in first person, especially the room doors along the corridor.
- Readability of the boards and bedside monitors at small window sizes.
- Human review of the ED text, the triage explanations, the fictional board and vitals data, the EMS call summaries and the imaging descriptions (`MEDICAL_CONTENT_REVIEW.md`).

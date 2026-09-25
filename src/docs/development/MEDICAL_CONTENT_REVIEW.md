# Medical content review — Milestone 6 seed set

These three questions are original AI-assisted prototype items, not professionally validated educational material. They seed the shared engine; the approximately 12-question lecture set remains Milestone 7 work. There are no copied commercial assessment questions or patient-specific treatment recommendations.

References checked 2026-09-23:

- [Merck Manual Professional — Dose-response relationships](https://www.merckmanuals.com/professional/clinical-pharmacology/pharmacodynamics/dose-response-relationships)
- [Merck Manual Professional — Drug–receptor interactions](https://www.merckmanuals.com/professional/clinical-pharmacology/pharmacodynamics/drug-receptor-interactions)

## pd_potency_01

- Objective: Distinguish EC50-based potency from maximal efficacy.
- Answer: a — A is more potent; their measured maximal efficacy is equal.
- Explanation: A reaches half of its maximal response at a lower concentration. Equal measured maximum responses indicate equal maximal efficacy in this assay.
- Human review: confirm wording and assumptions before educational release. Comparisons are limited to the stated assay; potency does not establish clinical superiority.

## pd_efficacy_01

- Objective: Identify Emax as the maximal effect in a specified system.
- Answer: b — Emax
- Explanation: Emax is the maximal observed response. EC50 describes the concentration associated with half-maximal response; elimination half-life is a pharmacokinetic measure.
- Human review: confirm wording and assumptions before educational release. Comparisons are limited to the stated assay; potency does not establish clinical superiority.

## pd_competitive_01

- Objective: Predict surmountable competitive antagonism in a simplified equilibrium model.
- Answer: c — A rightward shift with unchanged maximum
- Explanation: More agonist is needed for a given response, but sufficient agonist can restore the original maximum under these stated conditions.
- Human review: confirm wording and assumptions before educational release. The antagonist item is explicitly limited to a simple reversible competitive equilibrium model; it must not imply every antagonism mechanism preserves Emax.


# Lecture narration — pharmacodynamics_01 (Milestone 7 presentation)

The professor's narration and slides in `education/lectures/pharmacodynamics_01.json` are original, AI-assisted prototype content, checked 2026-09-23 against the two Merck Manual Professional pages above. They are not professionally validated. Each segment's key claims and review notes follow.

- **Receptors and ligands:** most drugs bind target proteins, often receptors; ligands include endogenous hormones and neurotransmitters; most drug binding is reversible; Kd is the concentration giving 50% occupancy at equilibrium, and a lower Kd means higher affinity. *Review:* "most" is a teaching generalization. Enzyme, transporter and ion-channel targets are not covered.
- **Agonists:** agonists activate; a full agonist can produce the system's maximal response; a partial agonist has a lower maximum even at full occupancy (intrinsic activity). The slide draws both at equal EC50 deliberately, and the narration says so.
- **Antagonists:** they bind without activating and have no effect when no agonist is present. *Review:* inverse agonism and constitutive receptor activity are omitted on purpose, and "pure antagonist" is used to signal this.
- **Competitive antagonism:** reversible binding at the same site; surmountable; parallel rightward shift; EC50 increases and Emax is unchanged. The slide shifts EC50 by the Gaddum/Schild dose ratio 1 + [B]/Kb, drawn with [B]/Kb = 9.
- **Noncompetitive antagonism:** irreversible (often covalent) or allosteric; not surmountable; Emax decreases; in the classic textbook picture EC50 is about the same. *Review:* with spare receptors, an irreversible antagonist can first shift the curve right before depressing Emax. The narration hedges with "classic textbook picture"; a human reviewer should decide whether to mention receptor reserve.
- **Potency:** needed amount for a given effect; compared by EC50 (half of that drug's own maximum); lower EC50 = more potent = further left; potency mainly changes the dose.
- **Efficacy:** Emax is the plateau height. The slide shows Drug B as more potent (EC50 0.4) but less efficacious (Emax 60) than Drug A (EC50 3, Emax 100). Efficacy "usually" matters more when a large effect is needed; this is hedged.
- **Dose-response relationships:** graded vs. quantal curves; sigmoid when plotted against log dose; ED50 and TD50; therapeutic index = TD50/ED50, where larger means a wider margin. *Review:* LD50 (in animals) is not mentioned, and the quantal slide uses an illustrative TI of 60.
- **Clinical application:**
  - Naloxone is a competitive opioid antagonist that can reverse respiratory depression, and it can wear off before the opioid, so patients need observation.
  - Buprenorphine is a high-affinity partial μ-opioid agonist that can precipitate withdrawal in people dependent on full agonists.
  - Warfarin is an example of a narrow therapeutic index requiring close monitoring.
  - *Review:* no doses or treatment protocols are given, and the content is educational only. A clinician reviewer should confirm the phrasing.
- **Summary:** restates the above.


## pd_viz_competitive_01 (visualization prediction)

- Objective: Predict that reversible competitive antagonism is surmountable and shifts the agonist curve right without lowering Emax.
- Answer: b — The response climbs back to the original maximum, but only at higher agonist concentrations.
- Explanation: Both drugs compete reversibly for the same site, so enough agonist outcompetes the antagonist; the curve shifts right and Emax is unchanged.
- Model used by the activity: Gaddum competitive occupancy with a full agonist and simple occupancy theory (response ∝ agonist occupancy), [B]/KB = 9 (dose ratio 10).
- Human review: the simplified occupancy-response model ignores receptor reserve and signal amplification; confirm the wording is appropriately qualified for first-year teaching.


# Lecture question set — pharmacodynamics_01 (Milestone 7)

Twelve scored lecture questions (the three seeds, the visualization prediction and the eight below) plus two remediation follow-ups, delivered from the shared bank by `question_beat.gd`. All are original, AI-assisted prototype items that have not been professionally validated, and they were checked against the Merck Manual Professional pages listed at the top of this file. Remediation appears only after a wrong answer on `pd_noncompetitive_01` and `pd_potency_01`.

## pd_affinity_01

- Objective: Interpret Kd as an inverse measure of receptor affinity.
- Answer: a — A has the higher affinity: it occupies half of the receptors at a lower concentration.
- Explanation: Kd is the concentration that occupies half of the receptors at equilibrium, so a lower Kd means higher affinity. Affinity alone does not set the maximal response (that is efficacy), and elimination is pharmacokinetics.
- Human review: Confirm that equating lower Kd with higher affinity is stated at equilibrium; no issues expected.

## pd_partial_agonist_01

- Objective: Explain a partial agonist's submaximal response in terms of intrinsic activity.
- Answer: a — Low intrinsic activity: even fully occupied receptors are activated less than by a full agonist.
- Explanation: Occupancy is already complete, so neither affinity nor dose explains the lower ceiling. A partial agonist's submaximal response reflects its lower intrinsic activity (efficacy).
- Human review: The stem stipulates full occupancy to isolate intrinsic activity; reviewer may prefer 'efficacy' terminology.

## pd_antagonist_01

- Objective: Define an antagonist as a ligand with affinity but no intrinsic activity.
- Answer: a — No response: it binds the receptor without activating it.
- Explanation: Antagonists have affinity but no intrinsic activity; their effect appears only when they block an agonist. (Inverse agonists acting on constitutively active receptors are a separate case.)
- Human review: Explanation notes inverse agonism as a separate case; confirm the level of detail suits first-year teaching.

## pd_noncompetitive_01

- Objective: Recognise insurmountable antagonism from a reduced Emax.
- Answer: a — Noncompetitive (insurmountable) antagonism: Emax is reduced.
- Explanation: Irreversibly blocked receptors are taken out of use, so adding agonist cannot restore the maximum. That insurmountable loss of Emax is the noncompetitive pattern; a competitive antagonist would shift the curve right without lowering it.
- Human review: Uses the classic insurmountable picture; receptor reserve can initially shift the curve right before Emax falls.

## pd_noncompetitive_remedial_01

- Objective: Identify reduced Emax as the signature of noncompetitive antagonism.
- Answer: a — A lower maximal response
- Explanation: The ceiling falls because blocked receptors cannot be recruited by more agonist. A rightward shift with the same maximum is the competitive pattern.
- Human review: Remediation item (5 XP override); intentionally simple.

## pd_potency_remedial_01

- Objective: Relate lower EC50 and a leftward curve to greater potency.
- Answer: a — The drug with the lower EC50, whose curve sits further left
- Explanation: Potency is compared by EC50: less drug is needed for the same relative effect, so the curve sits further left. Emax describes efficacy, not potency.
- Human review: Remediation item (5 XP override); intentionally simple.

## pd_efficacy_application_01

- Objective: Choose between drugs using efficacy rather than potency when a large effect is needed.
- Answer: a — Drug Y, because its efficacy (Emax) is greater.
- Explanation: X is more potent, but it plateaus at 50% and no dose of X can match Y's maximum. Potency changes the dose needed; efficacy sets the ceiling. (Real prescribing also weighs safety and other factors.)
- Human review: Hypothetical drugs; explanation states that real prescribing also weighs safety. Confirm no implied clinical recommendation.

## pd_therapeutic_index_01

- Objective: Calculate and interpret the therapeutic index from ED50 and TD50.
- Answer: a — Q has the larger therapeutic index (40 vs 4), so it has the wider margin between effective and toxic doses.
- Explanation: Therapeutic index = TD50 / ED50. For P it is 40 / 10 = 4; for Q it is 400 / 10 = 40. The larger index means a wider margin of safety.
- Human review: Uses TD50/ED50 (clinical definition); LD50/ED50 animal definition not mentioned.

## pd_naloxone_01

- Objective: Explain recurrent respiratory depression after naloxone by its shorter duration versus a long-acting opioid.
- Answer: a — Naloxone wore off before the methadone was cleared, so the opioid is binding the receptors again.
- Explanation: Naloxone is a competitive antagonist with a shorter duration of action than long-acting opioids such as methadone. As it is cleared, the opioid again occupies the receptors and respiratory depression returns, which is why these patients need observation and may need repeat doses or an infusion. Withdrawal causes agitation, not respiratory depression.
- Human review: Vignette uses methadone because re-sedation is classic with long-acting opioids. A clinician should confirm the wording; no doses are given.

## pd_buprenorphine_01

- Objective: Explain precipitated withdrawal by buprenorphine's high affinity and partial agonism.
- Answer: a — High affinity with low intrinsic activity: it displaces the full agonist but activates the receptor less.
- Explanation: Buprenorphine is a high-affinity partial agonist at mu-opioid receptors. It displaces the full agonist and produces less receptor activation, so the net effect falls abruptly: precipitated withdrawal. This is why buprenorphine is usually started once mild withdrawal has begun.
- Human review: Precipitated withdrawal scenario; explanation mentions starting buprenorphine once mild withdrawal has begun (general principle, no protocol or doses). Clinician review required.

## Flashcard study adapter — September 23, 2026

The starter flashcard deck derives 13 standalone records directly from `QuestionBank`, preserving prompt, exact correct answer, explanation, learning objective and source question ID. Multiple-choice distractors are hidden to require free recall. `pd_viz_competitive_01` is excluded because its prompt depends on the lecture graph. No new medical assertions or proprietary questions were authored for this feature. Existing human-review requirements above still apply, including review of the adapted free-recall wording. Personal Basic/Cloze notes are labelled personal content and are not medically validated; their self-ratings do not count toward graded knowledge accuracy.

# Physician shadowing — hospital_orientation_01 (Milestone 11, September 24, 2026)

All shadowing narration (`education/shadowing/hospital_orientation_01.json`), the seven etiquette questions (`education/questions/hospital_orientation.json`) and the fictional chart shown in the EHR (`ui/ehr_chart.gd`) are original, AI-assisted prototype content. They were written from general knowledge and have **not** been checked against sources in this session. A human reviewer should confirm them before any educational release.

Suggested references for the reviewer:
- the WHO "My 5 Moments for Hand Hygiene";
- the CDC/HICPAC Guideline for Isolation Precautions (contact precautions);
- the HIPAA Privacy Rule's minimum-necessary standard, and local EHR access policies;
- the IDSA/ATS community-acquired pneumonia guideline (for the scripted patient's course).

The session teaches professional conduct and hospital orientation only. There is no history taking, examination, diagnosis or treatment decision, and the student never acts on the patient.

## Questions (discipline Clinical Skills, topic Hospital Orientation)

| ID | Objective | Answer | Review note |
|---|---|---|---|
| ho_charge_nurse_01 | The charge nurse's coordinating role | a: coordinates nursing assignments, bed flow and staffing for the shift | Role scope varies by institution; wording is deliberately general. |
| ho_hand_hygiene_01 | Hand hygiene entering and leaving a room | b: in and out of the room, and before/after patient or environment contact | "Foam in, foam out" is a common teaching phrase. The explanation notes that gloves don't replace hand hygiene and that soiled hands need soap and water. Confirm against the WHO 5 Moments. |
| ho_rounds_position_01 | Where an observer stands on rounds | b: foot of the bed or back of the room | A teaching convention, not a rule. The explanation also says never to sit on the patient's bed. |
| ho_contact_precautions_01 | Contact-precaution signage and PPE | b: hand hygiene, gown and gloves per the sign, removed before leaving | Doffing is described as "at the doorway". Confirm the local doffing sequence and location wording. |
| ho_privacy_elevator_01 | No patient discussion in public spaces | b: move the conversation somewhere private | The explanation says room number, age or diagnosis can identify a patient. Confirm the tone. |
| ho_chart_review_01 | What pre-rounding chart review is for | b: catch up on changes: vitals, results, nursing notes, orders | The explanation says notes are written fresh each day and orders come from licensed prescribers. Check this for over-generalisation. |
| ho_ehr_access_01 | Role-limited EHR access | b: only the charts of patients you are involved with | The explanation says every access is logged and audited, and that photos of patient information and shared logins are never appropriate. |

## Narration claims to review

- **Arrival and roles:** the student shadows (observes) and does not examine patients or write in the chart; the Information desk and floor directories help with wayfinding.
- **Elevators:** patients on beds or stretchers have priority, and public spaces are not for patient discussion.
- **The unit:**
  - it has 32 beds, and the team has 14 patients (illustrative numbers);
  - the nurses station is the hub (charting, calls, telemetry);
  - nurses spend more time at the bedside and often notice changes first.
- **EHR:**
  - the banner identifies the patient (name, age, room, allergies, code status), and you confirm the chart before reading;
  - vitals trends and flagged results;
  - nursing and overnight notes;
  - orders and the medication record.
- **The scripted patient, Mr. Reyes (67):**
  - community-acquired pneumonia, day 3;
  - no fever for 24 h, SpO₂ 95% on room air, white count down from 14 to about 11;
  - plan: continue antibiotics, walk twice with nursing, discharge tomorrow if improving.
  - *Review:* this is a plausible, uncomplicated course written for illustration, not a management recommendation. No antibiotic names or doses are given anywhere.
- **Before entering a room:** check the door sign, knock, introduce yourself, clean your hands. On rounds, the resident presents, the attending confirms the plan with the patient, and consent is asked for the student to observe.
- **Isolation:** contact precautions need gown and gloves; droplet and airborne precautions need different equipment; ask the nurse when unsure.
- **Professionalism:** be on time, silence your phone, observe without blocking, save questions for after the room, and thank the team.

## Fictional EHR chart values (ui/ehr_chart.gd)

- **Patient:** "REYES, Daniel", 67, MRN DEMO-0412. Allergies: none known. Code status: full code.
- **Vitals, last 24 h:** temperature 38.4 → 36.8 °C; heart rate 102 → 80; respiratory rate 24 → 16; blood pressure about 120/75; SpO₂ from 92% on 2 L to 96% on room air.
- **Labs:**

  | Test | Values | Reference range |
  |---|---|---|
  | WBC | 14.2 → 12.6 → 11.2 (flagged H) | 4.0–11.0 |
  | CRP | 96 → 48 mg/L (flagged H) | — |
  | Hemoglobin | 13.9 / 13.6 / 13.8 g/dL | 13.5–17.5 |
  | Platelets | 241 / 238 / 252 ×10⁹/L | 150–400 |
  | Sodium | 136 / 136 / 137 mmol/L | 135–145 |
  | Creatinine | 1.1 / 1.0 / 1.0 mg/dL | 0.7–1.3 |

  Only WBC and CRP are out of range, and both are flagged.
- **Other results:** blood cultures show no growth at 48 h; the chest X-ray shows right lower lobe consolidation.
- **Notes:** one nursing note and one progress note, both non-specific about antibiotics.
- **Status:** these values are illustrative and are not tied to any real patient. Their internal consistency should be reviewed. Reference ranges vary by laboratory.

# Emergency Department and Emergency Radiology (September 24, 2026)

All ED and radiology text is original, AI-assisted prototype content. This covers interaction text, signs, the waiting-room and tracking-board wording, EMS call summaries, complaint and status lists, and the vitals ranges. The model is a large urban academic Level I trauma center; the user named Northwestern Memorial Hospital (Chicago) as the reference. Nothing here is a Northwestern protocol, and no Northwestern names or branding are used.

**Sources checked in this session:**
- Northwestern Medicine's ED page: a Level I trauma center and stroke center.
- Feinberg Department of Emergency Medicine, training sites: about 100,000 visits a year, with a "trauma half" of the ED.
- Feinberg Department of Emergency Medicine, clinical operations initiatives: the Super Track split-flow model for low-complexity patients, and a 15-bed Boarder Care Unit.
- The Emergency Severity Index level definitions, via a secondary summary (Wikipedia's ESI article). The ESI handbook itself was not consulted.
- Tanabe et al., *J Emerg Nurs* 2004: ESI version 3 validation work at Northwestern's Division of Emergency Medicine.

Northwestern's public pages do not name their triage scale; ESI is assumed as the US standard. A human reviewer should confirm everything below before any educational release.

## Triage (ESI) wording

| Where | Text (summary) | Review note |
|---|---|---|
| ESI information board (waiting room, `ESIBoard`) | Level 1 Resuscitation: immediate life-saving care. Level 2 Emergent: high risk or severe pain; seen right away. Level 3 Urgent: stable, two or more resources (labs, imaging, IV). Level 4 Less urgent: stable, one resource. Level 5 Non-urgent: stable, no resources. "Level 1 is the most critical." | Level 2 also covers new confusion, lethargy or disorientation, and severe distress. Resource examples are simplified (in ESI, IV fluids count as a resource, but an IV line alone does not). Check this against the current ESI handbook. |
| Waiting-room screen (`ui/ed_display.gd`) | "Patients are seen in order of medical need, not arrival time." "A triage nurse assesses everyone using the ESI." Level lines: Immediate life-saving care / High risk · seen right away / Stable · needs several tests or treatments / Stable · needs one test or treatment / Stable · no tests needed. A "current wait for less urgent care" figure (fictional: 12 + 4 min per waiting patient). "Please tell the triage nurse right away if your symptoms change or get worse." | Patient-facing simplification of resources as "tests or treatments". |
| Tracking-board endpoint | The board lists bed, ESI level (1 most critical to 5 least), complaint, nurse, physician, status and time. Initials only, because the board is visible to passers-by. | Privacy practice varies by institution. |
| Area names | Trauma & Resuscitation · ESI 1; Acute Care · ESI 2–3; Super Track · ESI 4–5 | Real departments do not map ESI levels to areas this strictly. Super Track often takes some ESI 3 patients, and acute rooms take ESI 1 overflow. |
| Colours | 1 red, 2 orange, 3 yellow, 4 green, 5 blue | A game convention, not an ESI or Northwestern standard. |

## Interaction text (endpoints)

- **Trauma 1:**
  - The trauma team leader is at the head of the bed, with nurses either side.
  - Resuscitation bays have overhead lights, gases on booms, a crash cart and portable X-ray, because ESI Level 1 patients need life-saving care immediately.
  - *Review:* team positions vary (the airway physician is typically at the head, with the team leader at the foot); confirm the wording.
- **Trauma board:** it shows inbound EMS units (who, mechanism, triage level, ETA), so the team and bay are ready before arrival.
- **Medication room:**
  - Automated dispensing cabinets: badge in, pick the patient and the ordered medication, and only that drawer opens.
  - Every removal is logged and controlled substances are counted.
  - High-alert drugs need a second nurse to check.
  - *Review:* independent double-check requirements are policy- and drug-specific.
- **Super Track:** the fast lane for stable, low-complexity problems (ESI 4–5), such as sprains, small cuts, earaches and prescriptions. They are treated in chairs rather than beds, so they don't wait behind the sickest patients.
- **Security:** everyone walks through the detector, patients and visitors alike. Weapons screening practice varies by hospital.
- **CT scanner:**
  - The X-ray tube spins around the ring while the table slides the patient through, building cross-sections in seconds.
  - Trauma and stroke patients come straight from the ED; the technologist runs the scan from behind lead glass.
- **MRI suite:**
  - Zone III is the control area for screened people only; Zone IV is the magnet room.
  - The magnet is always on, strong enough to pull oxygen tanks and scissors into the bore.
  - Everyone is screened for metal and implants, and a detector at the door alarms on ferromagnetic objects.
  - *Review:* check against the ACR four-zone model; Zone III access rules vary.
- **Reading room:**
  - It is kept dim so subtle findings are easier to see.
  - Every ED scan is read here, and critical findings are phoned straight to the treating team.
  - *Review:* "every scan is read here" is a simplification; off-hours reads may be remote.

## Signs

- MRI · ZONE IV / Strong magnetic field / The magnet is always on.
- ZONE III / Screened patients and staff only.
- MRI safety screening / Remove all metal · lockers here.
- CT 1, CT 2, X-RAY: CAUTION · RADIATION AREA.
- DECONTAMINATION.
- Medication Room / Staff only · badge access.
- All visitors are screened / Weapons are not permitted.
- Boarder Care Unit · Pods C–F / Admitted patients awaiting beds.
- AMBULANCE ONLY; AMBULANCE ENTRANCE · EMS ONLY; EMERGENCY.

## Fictional board and monitor data (`world/hospital/ed_life.gd`)

- **EMS call summaries by ESI:**
  - 1: pedestrian struck (GCS 9), rollover crash, fall from 20 ft, cardiac arrest with ROSC in the field, respiratory failure.
  - 2: chest pain (STEMI alert), stroke alert (onset 40 min), short of breath (SpO₂ 86%), sepsis alert (BP 84/50), head injury on blood thinners.
  - 3: abdominal pain with vomiting, fall at home with hip pain, fever and confusion, kidney stone pain, syncope (now alert).
  - *Review the level assignments:* hypotensive sepsis may be triaged ESI 1, "fever and confusion" is often ESI 2, and syncope depends on context.
- **Tracking-board complaints by ESI:**
  - 1: trauma/MVC, pedestrian struck, cardiac arrest, respiratory failure.
  - 2: chest pain, stroke symptoms, shortness of breath, sepsis, head injury, GI bleed.
  - 3: abdominal pain, fever, kidney stone, fall with hip pain, dizziness, vomiting.
  - 4: ankle injury, laceration, ear pain, back strain, rash.
  - 5: prescription refill, sore throat, wound check, minor burn.
  - Statuses include "Resus in progress", "Trauma team at bedside", "Awaiting CT/labs/results/X-ray", "Consult pending", "Admit · boarding" and "Ready for discharge".
- **Bedside vitals** (random within ranges, drifting slowly):
  - ESI 1–2: HR 104–128, SpO₂ 88–94%, RR 22–30.
  - ESI 1 only: BP about 88–104/50–64.
  - Others: BP about 112–148/66–90; ESI 3–5: HR 64–96, SpO₂ 95–99%, RR 12–18.
  - Traces are stylised. *Review:* ESI 2 patients are not all tachycardic and hypoxic; these ranges exist only to make sicker bays look sicker.
- **Radiology images** (`ui/radiology_images.gd`): obviously schematic drawings (CT head, chest X-ray, CT abdomen, MRI brain), not real studies, with no findings implied.
- **Names and numbers:** EMS units ("EMS 7", "Medic 4", …), staff initials, patient initials and ages are invented.


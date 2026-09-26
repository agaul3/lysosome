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


# The first year: lectures, activities, exams and clubs (September 25, 2026)

Everything below is original, AI-assisted prototype content written for the first-year expansion (`docs/development/YEAR_ONE_PLAN.md`). None of it is professionally validated, none is copied from commercial question banks, and none of it is patient-specific advice. Patients, clinicians, abstracts, charts and results are fictional. It needs review by qualified educators (basic scientists for the lectures, clinicians for the encounters and immersion shifts) before any educational release.

Where a question states a number or a threshold, it follows widely taught first-year teaching and current general guidance as understood when written; the list under *Check first* collects the claims most likely to need a reviewer's judgement or to date.

## Check first: thresholds, doses and time windows

- Pharmacokinetics: loading dose = target concentration × Vd; maintenance dose = CL × target concentration; about 4–5 half-lives to steady state; t½ = 0.693·Vd/CL.
- Histology: identification cues for the eleven drawn tissues (the micrographs are schematic drawings, not photographs).
- ECG: V1 placement (4th intercostal space, right sternal border); normal PR 0.12–0.20 s; QRS under 0.12 s; rate ≈ 300 ÷ large boxes; inferior STEMI localized to II, III, aVF and usually the right coronary artery.
- Chest pain: ECG within 10 minutes of arrival; aspirin 160–325 mg chewed unless allergic or bleeding.
- Emergency Department: Ottawa ankle rules as summarized; the ABCDE order of the primary survey; antibiotics within an hour after cultures in suspected septic shock.
- Knee examination: Lachman test as the most sensitive bedside test for an ACL tear (`sp_knee`).
- Spirometry: FEV1/FVC below about 0.70 (or the lower limit of normal) for obstruction; a bronchodilator response of at least 12% and 200 mL; the volume–time curves are drawn from a one-exponential model (`spirometry_lab_01`).
- Heart failure: ejection-fraction bands (40% or less, 41–49%, 50% or more); BNP then echocardiography; loop diuretics for congestion; beta-blockers started low when stable.
- Family medicine: blood-pressure technique; PHQ-2 content and a positive screen at 3 or more; combination nicotine replacement or varenicline with counseling; asking directly about suicide.
- Acid–base and renal: anion gap normal range (about 8–12); FENa under 1% (prerenal) and above 2% (ATN); peaked T waves first in hyperkalemia; thiazides and calcium; erythropoietin in CKD.
- COPD and oxygen: CO₂ retention explained mainly by V/Q mismatch and the Haldane effect; target saturation 88–92%.
- Diabetes and nutrition: HbA1c target below about 7%, individualized (looser, about 8%, with frailty or hypoglycemia risk); sulfonylurea hypoglycemia; the Hunger Vital Sign's two items (paraphrased, not quoted); the plate method; the rule of 15 for hypoglycemia; metformin sick-day rules.
- Inpatient medicine: IV-to-oral antibiotic switch criteria and about five days for community-acquired pneumonia; overlapping basal insulin by about two hours before stopping an insulin infusion; delirium management without benzodiazepines (except alcohol withdrawal); soap and water for C. difficile.
- Appendicitis: early opioid analgesia doesn't reduce diagnostic accuracy; CT in adults, ultrasound first in children and pregnancy.
- Research Day: the confidence-interval interpretation; confounding; NNT = 1/ARR (4% to 3% gives 100); SnNout.
- Stroke: thrombolysis generally within 4.5 hours of last known well; non-contrast CT and CT angiography first; aspirin after hemorrhage is excluded (and 24 hours after thrombolysis); forehead sparing in upper motor neuron facial weakness.
- OSCE: thunderclap headache as subarachnoid hemorrhage until proven otherwise; CT within six hours is very sensitive; lumbar puncture for xanthochromia (at least 12 hours after onset) or CT angiography after a late normal CT.
- Neurology: status epilepticus at five minutes and a benzodiazepine first; CSF patterns in meningitis; Guillain–Barré monitoring of vital capacity; SSRI onset over two to six weeks.
- Endocrine and GI: primary vs secondary adrenal insufficiency (pigmentation, potassium); Hashimoto as the commonest cause of hypothyroidism where iodine is sufficient; pancreatitis two-of-three criteria; H. pylori eradication; celiac disease biopsy findings; ascites mechanism.
- Anatomy lab and practical: axillary artery parts and branches, the median nerve's "M", brachial plexus lesions; neuroanatomy (CSF circulation, Broca area, the motor homunculus and its arteries, the oculomotor nerve and PComm aneurysms, cerebellar signs).
- The CPR skills night scores compressions at 100–120 per minute; the free-clinic station teaches cuff deflation at 2–3 mmHg per second after pumping 20–30 mmHg past where the radial pulse disappears.

## Lecture scripts

Each script (`education/lectures/<id>.json`) has narration, figures drawn from data (`ui/figure_art.gd`: curves from named functions, flow diagrams, tables, cycles and bars) and question beats from its bank. The narration's claims should be read alongside the questions below.

- `pharmacokinetics_01` — Pharmacokinetics (Dr. Lena Park)
- `enzymes_01` — Enzymes & Metabolism (Dr. Rafael Ortiz)
- `upper_limb_01` — The Upper Limb (Dr. Helen Marsh)
- `muscle_bone_01` — Muscle & Bone (Dr. Kwame Asante)
- `cardiac_cycle_01` — The Cardiac Cycle (Dr. Samuel Adeyemi)
- `blood_pressure_01` — Blood Pressure (Dr. Samuel Adeyemi)
- `respiratory_01` — Respiratory Mechanics & Gas Exchange (Dr. Priya Raman)
- `renal_01` — Renal Physiology & Diuretics (Dr. Luis Ferreira)
- `diabetes_01` — Diabetes & Glucose Regulation (Dr. Jonah Weiss)
- `gi_liver_01` — Digestion & the Liver (Dr. Amara Nwosu)
- `motor_pathways_01` — Motor Pathways (Dr. Mei Chen)
- `stroke_01` — Stroke (Dr. Mei Chen)

## Lecture question banks

### `education/questions/pharmacokinetics.json`

- `pk_bioavailability_01` — Calculate oral bioavailability from AUC ratios. Answer: a — 40%
- `pk_first_pass_01` — Explain how first-pass metabolism reduces oral bioavailability. Answer: a — Much of an oral dose is metabolized by the gut wall and liver before it reaches the systemic circulation.
- `pk_loading_dose_01` — Calculate a loading dose from the volume of distribution and target concentration. Answer: c — 200 mg
- `pk_vd_meaning_01` — Interpret small and large volumes of distribution. Answer: a — X stays largely in the plasma, for example because it is large or highly protein bound; Y is taken up extensively into tissues.
- `pk_zero_order_01` — Distinguish zero-order from first-order elimination. Answer: b — Zero-order elimination
- `pk_half_life_01` — Apply half-life to predict concentrations after first-order elimination. Answer: a — 10 mg/L
- `pk_half_life_remediation_01` — Recall the fraction eliminated after successive half-lives. Answer: c — 4
- `pk_steady_state_01` — Relate the time to steady state to the half-life. Answer: b — About four to five half-lives
- `pk_renal_dosing_01` — Adjust loading and maintenance doses when renal clearance falls. Answer: b — The usual loading dose, and a lower maintenance dose or a longer dosing interval

### `education/questions/enzymes.json`

- `enz_km_01` — Interpret Km as a measure of an enzyme's apparent affinity for its substrate. Answer: d — Enzyme A reaches half its maximal velocity at a lower substrate concentration: it has the higher affinity.
- `enz_vmax_01` — Relate Vmax to enzyme concentration and Km to the enzyme–substrate pair. Answer: c — Vmax doubles; Km is unchanged.
- `enz_lb_01` *(figure: curves)* — Read Km and Vmax from a Lineweaver–Burk plot. Answer: a — At −1/Km
- `enz_competitive_01` — Predict the kinetic effect of a competitive inhibitor, using statins as the example. Answer: a — The apparent Km increases; Vmax is unchanged.
- `enz_inhibition_remediation_01` — Identify competitive inhibition as the type overcome by excess substrate. Answer: c — Competitive inhibition
- `enz_noncompetitive_01` — Predict the kinetic effect of a noncompetitive inhibitor. Answer: d — Vmax decreases; Km is unchanged.
- `enz_allosteric_01` — Recognize sigmoidal kinetics as a sign of cooperativity and allosteric regulation. Answer: b — Cooperative binding among subunits: an allosterically regulated enzyme
- `enz_glucokinase_01` — Contrast hexokinase and glucokinase and explain glucokinase's role as a glucose sensor. Answer: b — A higher Km, so its activity rises with blood glucose after a meal
- `enz_pfk1_01` — List the main activators and inhibitors of PFK-1. Answer: a — Fructose-2,6-bisphosphate
- `enz_methanol_01` — Explain the use of fomepizole in methanol (or ethylene glycol) poisoning. Answer: b — It competitively inhibits alcohol dehydrogenase, slowing conversion of methanol to toxic formaldehyde and formic acid.

### `education/questions/upper_limb.json`

- `ul_plexus_cord_01` — Name the terminal branches of the posterior cord of the brachial plexus. Answer: c — The posterior cord
- `ul_plexus_remediation_01` — Recall the order of the brachial plexus's parts. Answer: d — Roots, trunks, divisions, cords, branches
- `ul_erb_01` — Recognize Erb palsy as an upper-trunk (C5–C6) injury. Answer: b — The upper trunk (C5–C6)
- `ul_axillary_01` — Link surgical-neck fractures and shoulder dislocation to axillary nerve injury. Answer: d — The axillary nerve
- `ul_radial_01` — Explain wrist drop after a humeral shaft fracture. Answer: b — The radial nerve, in the radial groove of the humeral shaft
- `ul_carpal_01` — Recognize carpal tunnel syndrome as median nerve compression at the wrist. Answer: a — The median nerve in the carpal tunnel
- `ul_ulnar_01` — Recognize ulnar neuropathy at the elbow. Answer: a — The ulnar nerve
- `ul_cuff_01` — Name the rotator cuff muscles and their actions. Answer: a — Supraspinatus
- `ul_case_01` — Localize a lesion to the posterior cord from the pattern of weakness. Answer: c — The posterior cord

### `education/questions/muscle_bone.json`

- `mb_troponin_01` — Describe how calcium initiates contraction in skeletal muscle. Answer: b — Troponin C
- `mb_ryr_01` — Recognize malignant hyperthermia and its treatment with dantrolene. Answer: b — Dantrolene, which blocks calcium release through the ryanodine receptor
- `mb_atp_01` — Explain the role of ATP in releasing myosin from actin. Answer: a — It releases the myosin head from actin.
- `mb_atp_remediation_01` — Explain rigor mortis in terms of the cross-bridge cycle. Answer: c — Without ATP, myosin heads cannot detach from actin.
- `mb_size_01` — State the size principle of motor unit recruitment. Answer: a — The small motor units, with small motor neurons
- `mb_rankl_01` — Explain the RANKL–RANK–OPG system and denosumab's mechanism. Answer: d — It stops RANKL from activating RANK on osteoclast precursors, so fewer osteoclasts mature.
- `mb_bisphosphonate_01` — Counsel a patient on taking an oral bisphosphonate safely. Answer: c — Take it with a full glass of water and stay upright for at least 30 minutes.

### `education/questions/cardiac_cycle.json`

- `cc_isovol_01` — Describe the valve positions and pressure changes in isovolumetric contraction. Answer: b — Both the mitral and aortic valves are closed, and pressure rises at constant volume.
- `cc_ef_01` — Calculate stroke volume and ejection fraction from ventricular volumes. Answer: a — 60%
- `cc_ef_remediation_01` — State the definition of ejection fraction. Answer: d — (End-diastolic volume − end-systolic volume) ÷ end-diastolic volume
- `cc_s2_split_01` — Explain physiologic splitting of S2. Answer: b — More venous return to the right heart lengthens right ventricular ejection, so the pulmonic valve closes later.
- `cc_as_01` — Recognize the murmur of aortic stenosis. Answer: c — Aortic stenosis
- `cc_starling_01` — Apply the Frank–Starling law to changes in preload. Answer: c — Increase end-diastolic volume and so increase stroke volume
- `cc_afterload_01` — Predict the effect of increased afterload on stroke volume. Answer: a — Stroke volume falls and end-systolic volume rises.

### `education/questions/blood_pressure.json`

- `bp_map_01` — Estimate mean arterial pressure from systolic and diastolic pressures. Answer: d — 93 mmHg
- `bp_baro_01` — Describe the baroreceptor response to standing. Answer: c — Less baroreceptor firing: sympathetic output rises and vagal tone falls, raising heart rate and vascular resistance
- `bp_stage_01` — Classify blood pressure readings using the 2017 ACC/AHA categories. Answer: a — Stage 1 hypertension
- `bp_ace_cough_01` — Manage ACE-inhibitor cough by switching to an ARB. Answer: b — Switch to an angiotensin receptor blocker, such as losartan
- `bp_pregnancy_01` — Identify antihypertensives contraindicated in pregnancy. Answer: c — An ACE inhibitor (or an angiotensin receptor blocker)
- `bp_renin_01` — List the stimuli for renin release. Answer: b — Reduced perfusion pressure in the afferent arteriole
- `bp_thiazide_01` — Recognize hyperuricemia and gout as adverse effects of thiazides. Answer: a — Thiazides raise serum uric acid, which can precipitate gout.

### `education/questions/respiratory.json`

- `resp_frc_01` — Define FRC and explain why spirometry cannot measure it. Answer: b — The expiratory reserve volume plus the residual volume
- `resp_obstructive_01` *(figure: curves)* — Interpret FEV1/FVC to identify an obstructive pattern. Answer: a — Obstructive: FEV1/FVC is 0.5
- `resp_surfactant_01` — Explain the role of surfactant and neonatal respiratory distress syndrome. Answer: c — Surfactant, made by type II pneumocytes
- `resp_shunt_01` — Recognize shunt physiology and its poor response to oxygen. Answer: a — Shunt: blood passes through alveoli that are filled and not ventilated
- `resp_right_shift_01` — List the factors that shift the oxygen–hemoglobin curve right. Answer: b — A rise in PCO₂ and fall in pH, as in exercising muscle
- `resp_aa_01` — Calculate and interpret the alveolar–arterial oxygen gradient. Answer: c — About 40 mmHg: elevated, pointing to a problem in the lung (V/Q mismatch, shunt or diffusion)
- `resp_aa_remediation_01` — Distinguish hypoventilation from lung disease with the A–a gradient. Answer: d — It stays normal: alveolar and arterial O₂ fall together.

### `education/questions/renal.json`

- `renal_clearance_01` — Calculate renal clearance from urine and plasma concentrations and urine flow. Answer: b — 100 mL/min
- `renal_nsaid_01` — Explain acute kidney injury from NSAIDs with ACE inhibitors in volume depletion. Answer: a — Afferent constriction (prostaglandins blocked) plus efferent dilation (angiotensin II blocked) lowers glomerular pressure.
- `renal_glucose_01` — Explain glucosuria in terms of proximal tubular transport maximum. Answer: b — Filtered glucose exceeds the proximal tubule's SGLT capacity, so the rest is excreted.
- `renal_loop_01` — Identify the site and transporter targeted by loop diuretics. Answer: c — NKCC2, in the thick ascending limb of the loop of Henle
- `renal_spironolactone_01` — Anticipate hyperkalemia with spironolactone and ACE inhibitors. Answer: d — Serum potassium (risk of hyperkalemia)
- `renal_adh_01` — Recognize SIADH and explain it through ADH action in the collecting duct. Answer: a — Inappropriate ADH secretion (SIADH): water is retained through aquaporin-2

### `education/questions/diabetes.json`

- `dm_katp_01` — Explain the mechanism of sulfonylureas using the β-cell K-ATP channel. Answer: a — They close ATP-sensitive K⁺ channels on β cells, depolarizing them and releasing insulin.
- `dm_cpeptide_01` — Use C-peptide to distinguish endogenous from injected insulin. Answer: b — Injected insulin
- `dm_diagnosis_01` — Apply the HbA1c criteria for diagnosing diabetes. Answer: a — Diabetes mellitus
- `dm_a1c_01` — Explain what the HbA1c measures and its limitations. Answer: d — Glucose binds hemoglobin irreversibly, and red cells live about 120 days.
- `dm_a1c_remediation_01` — Recall red-cell lifespan as the basis of the HbA1c. Answer: b — About 120 days
- `dm_dka_k_01` — Manage potassium safely at the start of DKA treatment. Answer: c — Replace potassium first: insulin will drive potassium into cells and lower it further.
- `dm_metformin_01` — State metformin's mechanism and key adverse effects. Answer: c — It reduces the liver's glucose production (gluconeogenesis).
- `dm_sglt2_01` — Identify the adverse effects of SGLT2 inhibitors from their mechanism. Answer: d — It causes glucose in the urine, which encourages genital yeast infections.

### `education/questions/gi_liver.json`

- `gi_ppi_01` — State the mechanism of proton pump inhibitors. Answer: a — Irreversibly inhibiting the H⁺/K⁺-ATPase of parietal cells
- `gi_b12_01` — Relate vitamin B12 absorption to intrinsic factor and the terminal ileum. Answer: d — Vitamin B12
- `gi_cck_01` — Explain the role of CCK in gallbladder contraction. Answer: c — Cholecystokinin (CCK), released by fat in the duodenum, contracts the gallbladder.
- `gi_lactose_01` — Explain the mechanism of symptoms in lactase deficiency. Answer: b — Undigested lactose stays in the gut lumen, drawing water in osmotically, and bacteria ferment it.
- `gi_obstruction_01` — Recognize obstructive (posthepatic) jaundice from its features. Answer: b — Obstruction of bile flow, such as a stone or tumor in the bile duct
- `gi_gilbert_01` — Recognize Gilbert syndrome. Answer: a — Gilbert syndrome
- `gi_nac_01` — Explain N-acetylcysteine treatment of acetaminophen overdose. Answer: c — N-acetylcysteine, which replenishes glutathione to neutralize NAPQI

### `education/questions/motor_pathways.json`

- `mp_decussation_01` — Locate the pyramidal decussation. Answer: c — At the pyramidal decussation in the caudal medulla
- `mp_umn_01` — Distinguish upper from lower motor neuron signs. Answer: b — Weakness, spasticity, brisk reflexes and an extensor plantar response
- `mp_lmn_01` — Localize a lesion from lower motor neuron signs. Answer: d — The lower motor neuron: the anterior horn cells, roots or nerves supplying the hand
- `mp_brown_sequard_01` — Predict the deficits of a spinal cord hemisection. Answer: a — Left leg weakness and loss of vibration sense; loss of pain and temperature on the right
- `mp_brown_sequard_remediation_01` — State where the spinothalamic tract and dorsal columns cross. Answer: a — In the spinal cord, within a segment or two of where they enter
- `mp_als_01` — Recognize ALS from mixed upper and lower motor neuron signs. Answer: b — Amyotrophic lateral sclerosis

### `education/questions/stroke.json`

- `stroke_lkw_01` — Apply the 'last known well' rule to timing a stroke. Answer: c — 10 PM, when she was last known to be well
- `stroke_mca_01` — Localize a middle cerebral artery stroke. Answer: b — Left middle cerebral artery
- `stroke_aca_01` — Localize an anterior cerebral artery stroke. Answer: d — Right anterior cerebral artery
- `stroke_ct_01` — State the purpose of the initial non-contrast CT in stroke. Answer: a — To rule out intracranial hemorrhage before thrombolysis
- `stroke_window_01` — Identify eligibility for intravenous thrombolysis. Answer: b — Intravenous thrombolysis
- `stroke_window_remediation_01` — Recall the time window for IV thrombolysis. Answer: a — 4.5 hours
- `stroke_af_01` — Choose secondary prevention for stroke with atrial fibrillation. Answer: c — An anticoagulant, such as apixaban

## Scheduled activities (`education/activities/`)

Labs, standardized-patient encounters, small-group cases, Clinical Immersion shifts, ceremonies and block exams. Encounters score the history (key questions), the examination (key maneuvers) and communication choices; the findings, histories and preceptor feedback are fictional. The choice options state a *lesson* shown when a weaker option is picked; those lessons are communication teaching points and need review too.

- `anatomy_lab_01` (lab) — Dissection: the axilla and the arm. Questions: `anat_pec_minor_01`, `anat_median_m_01`, `anat_musculocutaneous_01`, `anat_cephalic_01`, `anat_long_thoracic_01`.
- `anatomy_practical_b2` (exam) — Anatomy Practical: The Upper Limb. Questions: `prac_tag_radial_01`, `prac_tag_ulnar_01`, `prac_tag_supraspinatus_01`, `prac_tag_biceps_01`, `prac_tag_axillary_artery_01`, `prac_tag_scaphoid_01`, `prac_tag_deltoid_01`, `prac_tag_median_01`.
- `donor_dedication` (ceremony) — The donor dedication. Questions: none.
- `ecg_lab_01` (lab) — The ECG lab. Questions: `ecg_v1_01`, `ecg_rate_01`, `ecg_pr_01`, `ecg_tachy_01`, `ecg_af_01`, `ecg_stemi_01`.
- `exam_b1` (exam) — Block 1 Examination. Questions: `exb1_partial_01`, `exb1_steady_state_01`, `exb1_vd_01`, `exb1_first_order_01`, `exb1_citrate_01`, `exb1_km_rise_01`, `exb1_keratin_01`, `exb1_goblet_01`, `exb1_interview_01`, `exb1_confidentiality_01`, `pd_competitive_01`, `pd_efficacy_01`, `pk_loading_dose_01`, `pk_half_life_01`, `enz_competitive_01`, `enz_glucokinase_01`.
- `exam_b2` (exam) — Block 2 Examination. Questions: `exb2_klumpke_01`, `exb2_winging_01`, `exb2_tetanus_01`, `exb2_smooth_01`, `exb2_pth_01`, `exb2_vitd_01`, `exb2_meniscus_01`, `exb2_ottawa_knee_01`, `ul_erb_01`, `ul_radial_01`, `mb_ryr_01`, `mb_rankl_01`, `ul_case_01`, `sp_knee_lachman_01`.
- `exam_b3` (exam) — Block 3 Examination. Questions: `exb3_s3_01`, `exb3_mr_01`, `exb3_co_01`, `exb3_tpr_01`, `exb3_ccb_01`, `exb3_af_stroke_01`, `exb3_qrs_01`, `exb3_ace_labs_01`, `cc_ef_01`, `cc_as_01`, `cc_afterload_01`, `bp_baro_01`, `bp_ace_cough_01`, `ecg_af_01`.
- `exam_b4` (exam) — Block 4 Examination. Questions: `exb4_alkalosis_01`, `exb4_oxygen_copd_01`, `exb4_pe_01`, `exb4_prerenal_01`, `exb4_hyperk_01`, `exb4_gap_01`, `exb4_thiazide_01`, `exb4_epo_01`, `resp_obstructive_01`, `resp_shunt_01`, `resp_aa_01`, `renal_clearance_01`, `renal_nsaid_01`, `renal_loop_01`, `spiro_bronchodilator_01`.
- `exam_b5` (exam) — Block 5 Examination. Questions: `exb5_hypothyroid_01`, `exb5_graves_01`, `exb5_addison_01`, `exb5_pancreatitis_01`, `exb5_hpylori_01`, `exb5_celiac_01`, `exb5_hypoglycemia_01`, `exb5_ascites_01`, `dm_katp_01`, `dm_diagnosis_01`, `dm_dka_k_01`, `dm_metformin_01`, `gi_ppi_01`, `gi_obstruction_01`, `gi_nac_01`.
- `exam_b6` (exam) — Block 6 Examination. Questions: `exb6_parkinson_01`, `exb6_myasthenia_01`, `exb6_gbs_01`, `exb6_ms_01`, `exb6_ssri_01`, `exb6_status_01`, `exb6_alzheimer_01`, `exb6_meningitis_01`, `mp_decussation_01`, `mp_umn_01`, `mp_brown_sequard_01`, `stroke_mca_01`, `stroke_window_01`, `stroke_af_01`, `neuro_csf_01`, `sp_weak_forehead_01`.
- `histology_lab_01` (lab) — Histology: epithelium and connective tissue. Questions: `hist_he_01`, `hist_columnar_01`, `hist_squamous_01`, `hist_resp_01`, `hist_simple_squamous_01`, `hist_cartilage_01`, `hist_cardiac_01`, `hist_tendon_01`.
- `immersion_clinic_01` (immersion) — An afternoon in family medicine. Questions: `imm_fm_bp_01`, `imm_fm_phq2_01`, `imm_fm_quit_01`. Lessons: Asking directly about suicide doesn't put the idea in someone's head; it's how you find the risk and get help; Use open questions and reflections (motivational interviewing) so patients voice their own reasons to change.
- `immersion_ed_01` (immersion) — An evening in the Emergency Department. Questions: `imm_ed_ottawa_01`, `imm_ed_abcde_01`, `imm_ed_sepsis_01`. Lessons: Be clear about your role, and bring the right person to talk with families.
- `immersion_wards_01` (immersion) — Rounds on 4 West. Questions: `imm_wards_ivpo_01`, `imm_wards_dka_01`, `imm_wards_cdiff_01`, `imm_wards_delirium_01`, `imm_wards_delirium_02`. Lessons: Present with a one-line summary first, then events, exam, results, assessment and plan.
- `neuroanatomy_lab_01` (lab) — The neuroanatomy lab. Questions: `neuro_csf_01`, `neuro_broca_01`, `neuro_homunculus_01`, `neuro_cn3_01`, `neuro_cerebellum_01`.
- `nutrition_case_01` (case) — Case conference: Ms. Walker. Questions: `nut_a1c_target_01`, `nut_sulfonylurea_01`, `nut_hunger_vital_sign_01`, `nut_plate_01`. Lessons: Treat the social need along with the medical one; Draw everyone into the group; the quiet voice often knows something you don't.
- `osce_01` (encounter) — The end-of-year OSCE. Questions: `osce_sah_01`, `osce_metformin_side_01`, `osce_metformin_sick_01`. Lessons: Introduce yourself and attend to comfort; photophobia is a clue; Use teach-back: ask patients to explain the plan in their own words.
- `research_day` (event) — Research Day. Questions: `res_ci_01`, `res_confounding_01`, `res_nnt_01`, `res_sensitivity_01`. Lessons: Say what you don't know; never bluff about data.
- `sp_abdominal` (encounter) — Standardized patient: abdominal pain. Questions: `sp_abd_migration_01`, `sp_abd_ct_01`, `sp_abd_analgesia_01`. Lessons: Acknowledge pain and explain what you'll do before you start; Be honest about what you think, within your role, and say who will decide.
- `sp_chest_pain` (encounter) — Standardized patient: chest pain. Questions: `sp_cp_first_01`, `sp_cp_aspirin_01`. Lessons: In an unwell patient, focus the history on the emergency first; Be honest about concern while acting quickly and reassuringly.
- `sp_cough` (encounter) — Standardized patient: a cough. Questions: `sp_cough_red_flag_01`, `sp_cough_next_01`. Lessons: Introduce yourself and your role, and ask how the patient would like to be addressed; Open with an open-ended question; Acknowledge and explore the patient's concerns rather than reassuring falsely; Close by summarizing, checking for anything missed, and explaining next steps.
- `sp_dyspnea` (encounter) — Standardized patient: breathlessness. Questions: `sp_dysp_orthopnea_01`, `sp_dysp_echo_01`, `sp_dysp_diuretic_01`. Lessons: Introduce yourself and make the patient comfortable before anything else; Explore why a medicine was stopped and solve the problem together, without blame.
- `sp_knee` (encounter) — Standardized patient: knee pain. Questions: `sp_knee_dx_01`, `sp_knee_lachman_01`. Lessons: Introduce yourself and let the patient tell the story first; Answer honestly within your role, without false reassurance.
- `sp_weakness` (encounter) — Standardized patient: sudden weakness. Questions: `sp_weak_localize_01`, `sp_weak_forehead_01`, `sp_weak_next_01`. Lessons: In a suspected stroke, the time last known well comes first: it decides the treatment; Be honest, give the family something true to hold on to, and don't leave them alone.
- `spirometry_lab_01` (lab) — The spirometry lab. Questions: `spiro_technique_01`, `spiro_ratio_01`, `spiro_restrictive_01`, `spiro_bronchodilator_01`, `spiro_inhaler_01`. Lessons: Coach forced maneuvers actively: full effort, and keep going until the curve plateaus.
- `white_coat` (ceremony) — The White Coat Ceremony. Questions: none.
- `year_end` (ceremony) — The end of the first year. Questions: none.

## Activity question banks

### `education/questions/activities_b1.json`

- `hist_he_01` — Explain what hematoxylin and eosin stain. Answer: d — Hematoxylin, which binds acidic structures such as DNA and RNA
- `hist_columnar_01` *(figure: micrograph)* — Identify simple columnar epithelium with goblet cells and relate it to absorption. Answer: c — The small intestine
- `hist_squamous_01` *(figure: micrograph)* — Distinguish non-keratinized from keratinized stratified squamous epithelium. Answer: c — The esophagus
- `hist_resp_01` *(figure: micrograph)* — Identify respiratory epithelium and describe the mucociliary escalator. Answer: c — The trachea
- `hist_simple_squamous_01` *(figure: micrograph)* — Relate simple squamous epithelium to its function and locations. Answer: b — Rapid diffusion, as in the alveoli and capillary walls
- `hist_cartilage_01` *(figure: micrograph)* — Identify hyaline cartilage and explain its poor healing. Answer: a — It is hyaline cartilage, which is avascular: nutrients reach its cells only by diffusion.
- `hist_cardiac_01` *(figure: micrograph)* — Identify cardiac muscle and the function of intercalated discs. Answer: b — Intercalated discs, joining cardiac muscle cells
- `hist_tendon_01` *(figure: micrograph)* — Identify dense regular connective tissue and relate structure to function. Answer: a — Dense regular connective tissue, as in a tendon
- `sp_cough_red_flag_01` — Identify red-flag features in a patient with chronic cough. Answer: c — Blood-streaked sputum and unintended weight loss in a 40-pack-year smoker
- `sp_cough_next_01` — Choose initial imaging for a smoker with hemoptysis. Answer: a — A chest X-ray
- `exb1_partial_01` — Predict the effect of a partial agonist in the presence of a full agonist. Answer: b — It falls: the partial agonist displaces the full agonist and acts as an antagonist.
- `exb1_steady_state_01` — Estimate the time to steady state from the half-life. Answer: d — About 32–40 hours (four to five half-lives)
- `exb1_vd_01` — Interpret a large volume of distribution. Answer: a — Is extensively bound in tissues, so little remains in plasma
- `exb1_first_order_01` — Distinguish first-order from zero-order elimination. Answer: b — A constant fraction of the drug in the body
- `exb1_citrate_01` — Recall the regulators of PFK-1. Answer: b — Phosphofructokinase-1
- `exb1_km_rise_01` — Apply Km to explain glucokinase's role in glucose handling. Answer: a — Hexokinase is already near Vmax; glucokinase activity rises substantially.
- `exb1_keratin_01` — Identify the epithelium of the epidermis. Answer: c — Keratinized stratified squamous epithelium
- `exb1_goblet_01` — Explain the mucociliary escalator and its failure in smokers. Answer: d — The mucociliary escalator fails, so mucus from goblet cells pools until it's coughed up.
- `exb1_interview_01` — Use open-ended questions to begin a history. Answer: d — "What brings you in today?"
- `exb1_confidentiality_01` — Apply the principle of confidentiality. Answer: d — Decline to share anything without the patient's permission.

### `education/questions/activities_b2.json`

- `anat_pec_minor_01` — Describe the three parts of the axillary artery. Answer: c — The first part lies above (medial to) the muscle, the second behind it, the third below (lateral to) it.
- `anat_median_m_01` — Identify the median nerve by its origin in dissection. Answer: c — The median nerve
- `anat_musculocutaneous_01` — Name the nerve of the anterior compartment of the arm. Answer: a — The musculocutaneous nerve
- `anat_cephalic_01` — Trace the cephalic vein. Answer: c — The cephalic vein
- `anat_long_thoracic_01` — Relate the long thoracic nerve's course to surgical risk. Answer: d — Injuring the long thoracic nerve paralyzes serratus anterior, causing a winged scapula.
- `sp_knee_dx_01` — Recognize the history and examination findings of an ACL tear. Answer: d — An anterior cruciate ligament tear
- `sp_knee_lachman_01` — Choose the best examination test for the ACL. Answer: b — The Lachman test
- `prac_tag_radial_01` *(figure: flow)* — Identify the radial nerve by its origin and course. Answer: a — Radial nerve
- `prac_tag_ulnar_01` — Identify the ulnar nerve by its course. Answer: d — Ulnar nerve
- `prac_tag_supraspinatus_01` — Identify supraspinatus. Answer: b — Supraspinatus
- `prac_tag_biceps_01` — Name biceps brachii's actions. Answer: a — Supination
- `prac_tag_axillary_artery_01` — Name the vessel continuing from the axillary artery. Answer: c — Brachial artery
- `prac_tag_scaphoid_01` — Identify the scaphoid and its clinical significance. Answer: a — Scaphoid
- `prac_tag_deltoid_01` — Name the innervation of the deltoid. Answer: b — Axillary nerve
- `prac_tag_median_01` — Identify the median nerve in the carpal tunnel. Answer: a — Median nerve
- `exb2_klumpke_01` — Recognize a lower-trunk (Klumpke) injury with Horner syndrome. Answer: c — C8 and T1 (lower trunk)
- `exb2_winging_01` — Link winged scapula to serratus anterior and the long thoracic nerve. Answer: d — Serratus anterior
- `exb2_tetanus_01` — Explain summation and tetanus in skeletal muscle. Answer: a — Calcium stays high between stimuli, so contractions summate into a sustained, stronger tetanus.
- `exb2_smooth_01` — Contrast calcium's role in smooth and skeletal muscle. Answer: b — Calmodulin, which activates myosin light-chain kinase
- `exb2_pth_01` — Explain PTH's effect on bone remodeling. Answer: d — It increases osteoclast activity (via RANKL from osteoblasts), releasing calcium from bone.
- `exb2_vitd_01` — Trace the activation of vitamin D. Answer: b — In the kidney, by 1-alpha-hydroxylase
- `exb2_meniscus_01` — Recognize the features of a meniscal tear. Answer: b — The medial meniscus
- `exb2_ottawa_knee_01` — Apply the Ottawa knee rules. Answer: c — Inability to bear weight for four steps, both right after the injury and in the emergency department

### `education/questions/activities_b3.json`

- `ecg_v1_01` — Place the precordial ECG leads correctly. Answer: a — In the fourth intercostal space at the right sternal border
- `ecg_rate_01` *(figure: ecg_strip)* — Calculate heart rate from an ECG strip. Answer: c — 75 beats per minute
- `ecg_pr_01` — State the normal PR interval. Answer: a — 0.12–0.20 seconds (three to five small boxes)
- `ecg_tachy_01` *(figure: ecg_strip)* — Recognize sinus tachycardia. Answer: b — Sinus tachycardia
- `ecg_af_01` *(figure: ecg_strip)* — Recognize atrial fibrillation. Answer: a — Atrial fibrillation
- `ecg_stemi_01` *(figure: ecg_strip)* — Localize an inferior STEMI. Answer: d — Inferior ST-elevation myocardial infarction, most often the right coronary artery
- `sp_cp_first_01` — Prioritize the ECG in suspected acute coronary syndrome. Answer: d — A 12-lead ECG, within 10 minutes of arrival
- `sp_cp_aspirin_01` — Give aspirin early in suspected acute coronary syndrome. Answer: c — Aspirin, chewed (about 160–325 mg)
- `imm_ed_ottawa_01` — Apply the Ottawa ankle rules. Answer: a — No: no bone tenderness at the malleoli, and she can bear weight
- `imm_ed_abcde_01` — Recall the order of the trauma primary survey. Answer: a — The airway, with cervical spine protection
- `imm_ed_sepsis_01` — Prioritize early antibiotics and fluids in sepsis. Answer: d — Broad-spectrum antibiotics and intravenous fluids
- `exb3_s3_01` — Interpret an S3 in an older adult. Answer: b — An S3, from rapid filling of a dilated, volume-overloaded ventricle, as in heart failure
- `exb3_mr_01` — Recognize the murmur of mitral regurgitation. Answer: b — Mitral regurgitation
- `exb3_co_01` — Calculate cardiac output. Answer: c — 4.9 L per minute
- `exb3_tpr_01` — Identify arterioles as the main resistance vessels. Answer: c — The arterioles
- `exb3_ccb_01` — Explain dihydropyridine-induced edema. Answer: b — It dilates arterioles more than venules, raising capillary pressure in the legs.
- `exb3_af_stroke_01` — Recognize the thromboembolic risk of atrial fibrillation. Answer: c — Stroke from clots forming in the left atrial appendage
- `exb3_qrs_01` — Interpret a wide QRS complex. Answer: d — Abnormally slow ventricular conduction, as in a bundle branch block
- `exb3_ace_labs_01` — Monitor potassium and kidney function after starting an ACE inhibitor. Answer: b — Potassium and creatinine

### `education/questions/activities_b4.json`

- `spiro_technique_01` — Describe how to perform forced spirometry. Answer: a — Breathe in as fully as possible, seal the lips around the mouthpiece, then blast out as hard and fast as possible and keep going until empty
- `spiro_ratio_01` *(figure: curves)* — Calculate and interpret the FEV1/FVC ratio. Answer: c — 0.80: normal
- `spiro_restrictive_01` *(figure: curves)* — Recognize a restrictive spirometry pattern. Answer: a — Restrictive: both volumes are small, but the ratio is normal (0.88)
- `spiro_bronchodilator_01` — Interpret a bronchodilator response. Answer: b — Significant reversibility, supporting asthma
- `spiro_inhaler_01` — Teach correct inhaler technique. Answer: d — Shake it, breathe out, seal your lips on the spacer, press once, then breathe in slowly and deeply and hold for about ten seconds
- `sp_dysp_orthopnea_01` — Explain orthopnea and paroxysmal nocturnal dyspnea. Answer: c — Lying down shifts blood from the legs and abdomen into the chest, and her failing left ventricle can't handle the extra return, so pressure backs up into the lungs
- `sp_dysp_echo_01` — Choose the echocardiogram to confirm heart failure. Answer: d — A transthoracic echocardiogram
- `sp_dysp_diuretic_01` — Treat congestion in heart failure with a loop diuretic. Answer: b — A loop diuretic such as furosemide
- `imm_fm_bp_01` — Measure blood pressure accurately. Answer: c — Seated for five minutes with his back supported and feet flat, the arm supported at heart level, and a cuff that fits
- `imm_fm_phq2_01` — Recall the PHQ-2 depression screen. Answer: c — Little interest or pleasure in doing things, and feeling down, depressed or hopeless
- `imm_fm_quit_01` — Recommend effective smoking-cessation treatment. Answer: a — Medication (varenicline, or a nicotine patch with a short-acting form) combined with counseling and support
- `exb4_alkalosis_01` — Identify an acute respiratory alkalosis. Answer: c — Acute respiratory alkalosis
- `exb4_oxygen_copd_01` — Explain CO₂ retention with oxygen in COPD. Answer: b — Oxygen releases hypoxic vasoconstriction, worsening ventilation–perfusion matching, and hemoglobin releases more CO₂ (the Haldane effect)
- `exb4_pe_01` — Recognize a likely pulmonary embolism. Answer: a — Pulmonary embolism
- `exb4_prerenal_01` — Distinguish prerenal injury using the FENa. Answer: d — Prerenal: working tubules are holding on to sodium because perfusion is low
- `exb4_hyperk_01` — Recognize the ECG signs of hyperkalemia. Answer: a — Tall, peaked T waves
- `exb4_gap_01` — Calculate and interpret the anion gap. Answer: b — 30 mEq/L: a high anion gap metabolic acidosis
- `exb4_thiazide_01` — Describe the electrolyte effects of thiazides. Answer: b — Low sodium and low potassium, with less calcium lost in the urine
- `exb4_epo_01` — Explain the anemia of chronic kidney disease. Answer: d — Their kidneys make less erythropoietin

### `education/questions/activities_b5.json`

- `nut_a1c_target_01` — State an individualized HbA1c target. Answer: c — Below about 7%, individualized: looser for people at risk of hypoglycemia or with frailty
- `nut_sulfonylurea_01` — Identify the hypoglycemia risk of sulfonylureas with irregular meals. Answer: d — Glipizide, a sulfonylurea, which can cause hypoglycemia
- `nut_hunger_vital_sign_01` — Screen for food insecurity. Answer: b — Two statements about the past 12 months: worrying that food would run out before there was money to buy more, and food not lasting with no money to get more
- `nut_plate_01` — Give practical, affordable dietary advice in diabetes. Answer: b — The plate method: half the plate non-starchy vegetables (frozen or canned are fine), a quarter lean protein such as beans, eggs or canned fish, a quarter starch
- `sp_abd_migration_01` — Explain the migration of pain in appendicitis. Answer: d — Early pain is visceral, felt in the midgut's T10 dermatome; later the inflamed appendix irritates the parietal peritoneum, which localizes pain precisely
- `sp_abd_ct_01` — Choose imaging for suspected appendicitis. Answer: b — CT of the abdomen and pelvis
- `sp_abd_analgesia_01` — Give analgesia early in acute abdominal pain. Answer: d — Yes: analgesia doesn't hide the diagnosis, and withholding it is unkind
- `res_ci_01` — Interpret a confidence interval. Answer: b — The data are compatible with a true reduction from about 2 to 10 mmHg; because the interval excludes zero, the result is significant at the 5% level
- `res_confounding_01` — Recognize confounding in an observational study. Answer: a — Confounding by smoking, which is linked to both coffee drinking and lung cancer
- `res_nnt_01` — Calculate the number needed to treat. Answer: c — 100
- `res_sensitivity_01` — Apply sensitivity and specificity. Answer: a — Ruling a disease out when the result is negative
- `imm_wards_ivpo_01` — Switch from IV to oral antibiotics when stable. Answer: a — Switch to an oral antibiotic and plan his discharge
- `imm_wards_dka_01` — Transition from IV to subcutaneous insulin after DKA. Answer: d — Give subcutaneous basal insulin first, and stop the infusion only after an overlap of about two hours
- `imm_wards_delirium_01` — Recognize delirium. Answer: c — Delirium
- `imm_wards_delirium_02` — Manage delirium without harm. Answer: a — Find and treat the causes, and use non-drug measures: reorientation, glasses and hearing aids, sleep at night, mobilizing, family visits
- `imm_wards_cdiff_01` — Apply hand hygiene for C. difficile. Answer: d — Soap and water: alcohol hand rub doesn't kill its spores
- `exb5_hypothyroid_01` — Diagnose primary hypothyroidism. Answer: d — Primary hypothyroidism, most often Hashimoto thyroiditis
- `exb5_graves_01` — Explain the mechanism of Graves disease. Answer: b — Antibodies that stimulate the TSH receptor: Graves disease
- `exb5_addison_01` — Distinguish primary from secondary adrenal insufficiency. Answer: a — Darkened skin and a high potassium
- `exb5_pancreatitis_01` — Diagnose acute pancreatitis. Answer: a — Acute pancreatitis
- `exb5_hpylori_01` — Link peptic ulcers to H. pylori. Answer: c — Helicobacter pylori
- `exb5_celiac_01` — Recognize celiac disease. Answer: b — Villous atrophy with crypt hyperplasia; a lifelong gluten-free diet
- `exb5_hypoglycemia_01` — Treat hypoglycemia. Answer: c — 15–20 g of fast-acting glucose by mouth, then recheck in 15 minutes
- `exb5_ascites_01` — Explain ascites in cirrhosis. Answer: c — Portal hypertension, plus salt and water retention driven by the renin–angiotensin–aldosterone system, with low albumin adding to it

### `education/questions/activities_b6.json`

- `neuro_csf_01` — Trace the circulation of cerebrospinal fluid. Answer: c — Choroid plexus of the lateral ventricles → interventricular foramina → third ventricle → cerebral aqueduct → fourth ventricle → subarachnoid space → arachnoid granulations
- `neuro_broca_01` — Localize expressive aphasia. Answer: b — Broca area
- `neuro_homunculus_01` — Map the motor homunculus to its blood supply. Answer: b — On the medial surface, in the paracentral lobule, supplied by the anterior cerebral artery
- `neuro_cn3_01` — Recognize an oculomotor nerve palsy from compression. Answer: d — An eye turned down and out, with a drooping lid and a dilated pupil: the oculomotor nerve
- `neuro_cerebellum_01` — Localize cerebellar signs. Answer: c — Clumsiness and an intention tremor on the same side as the lesion
- `sp_weak_localize_01` — Localize a right middle cerebral artery stroke. Answer: b — The right middle cerebral artery territory
- `sp_weak_forehead_01` — Distinguish upper from lower motor neuron facial weakness. Answer: c — The upper face receives input from both motor cortices, so a one-sided upper motor neuron lesion spares it
- `sp_weak_next_01` — Sequence the first steps in acute stroke. Answer: a — An emergency non-contrast CT (with CT angiography) to rule out bleeding and look for a blocked large vessel, heading for thrombolysis if she's eligible
- `osce_sah_01` — Investigate a thunderclap headache. Answer: c — An urgent non-contrast CT of the head, then a lumbar puncture if it's normal and the scan was late
- `osce_metformin_side_01` — Counsel on metformin's side effects. Answer: d — Stomach upset: nausea, bloating and diarrhea
- `osce_metformin_sick_01` — Teach sick-day rules for metformin. Answer: b — Pause it until he's eating and drinking normally, and get medical advice
- `exb6_parkinson_01` — Identify the neurons lost in Parkinson disease. Answer: a — Dopaminergic neurons of the substantia nigra pars compacta
- `exb6_myasthenia_01` — Explain the mechanism of myasthenia gravis. Answer: c — The acetylcholine receptor at the neuromuscular junction
- `exb6_gbs_01` — Recognize Guillain–Barré syndrome. Answer: a — Guillain–Barré syndrome; monitor breathing (vital capacity)
- `exb6_ms_01` — Recognize multiple sclerosis. Answer: d — Multiple sclerosis
- `exb6_ssri_01` — Counsel on starting an SSRI. Answer: b — An SSRI such as sertraline; improvement usually takes two to six weeks
- `exb6_status_01` — Treat status epilepticus. Answer: d — A benzodiazepine, such as IV lorazepam (or IM midazolam without IV access)
- `exb6_alzheimer_01` — Recognize Alzheimer disease. Answer: a — Alzheimer disease
- `exb6_meningitis_01` — Interpret CSF in meningitis. Answer: a — Many neutrophils, high protein and low glucose

## Clubs (`data/clubs.gd`, `ui/clubs/`, `education/questions/clubs.json`)

- **Community Kitchen:** guests' dietary requests (vegetarian, vegan, soft food, no dairy, not spicy) and the coordinator's lines about food insecurity; the Thanksgiving supper.
- **Student-Run Free Clinic:** fictional patients' blood pressures and pulses; the cuff technique above.
- **Surgery Interest Group:** simple interrupted sutures (bite, spacing, needle angle) as a timing game.
- **Emergency Medicine Interest Group:** compression rate and depth; "Stop the Bleed" wording.
- **Medical Spanish:** phrase translations need a fluent medical Spanish reviewer.
- **Journal Club:** three fictional abstracts (no real trials) and their appraisal questions.
- **Intramurals:** no medical content.

### `education/questions/clubs.json`

- `club_kitchen_sdoh_01` — Distinguish social determinants of health from clinical and genetic factors. Answer: c — Access to affordable, nutritious food
- `club_kitchen_hvs_01` — Recognize the two-item Hunger Vital Sign screen for food insecurity. Answer: a — Food insecurity (the Hunger Vital Sign)
- `club_kitchen_wic_01` — Name the federal nutrition program for pregnant people, infants and young children. Answer: a — WIC
- `club_kitchen_dm_01` — Respond to a positive food-insecurity screen in a patient with diabetes. Answer: c — Connect them with food resources (such as help applying for SNAP or a food bank referral) and review whether the regimen risks hypoglycemia when meals are skipped
- `club_clinic_cuff_01` — Explain how cuff size affects a blood pressure reading. Answer: a — Falsely high
- `club_clinic_arm_01` — Explain the effect of arm position on measured blood pressure. Answer: a — Falsely high
- `club_clinic_deflate_01` — State the recommended cuff deflation rate. Answer: d — 2–3 mmHg per second
- `club_clinic_korotkoff_01` — Identify the Korotkoff phases used to record systolic and diastolic pressure. Answer: d — The first of the tapping sounds (phase I), and the point where the sounds disappear (phase V)
- `club_clinic_severe_01` — Recognize a blood pressure reading that needs immediate escalation. Answer: a — Have the supervising physician see him now and arrange emergency department evaluation
- `club_clinic_spo2_01` — Troubleshoot a low pulse oximetry reading before acting on it. Answer: a — Warm the hand, check the probe's position and the waveform, and recheck, then tell the supervising physician the result
- `club_surgery_angle_01` — Explain why a perpendicular needle entry everts the wound edges. Answer: d — So the bite is at least as wide at its depth as at the surface, which everts the wound edges
- `club_surgery_spacing_01` — Apply the spacing rule for simple interrupted sutures. Answer: c — The distance between sutures is about the same as each bite's distance from the wound edge
- `club_surgery_knot_01` — Recall the principles of tension and knot placement in wound closure. Answer: d — Tie each knot as tight as possible
- `club_emig_rate_01` — State the recommended rate for adult chest compressions. Answer: a — 100–120 per minute
- `club_emig_depth_01` — State the recommended depth of adult chest compressions. Answer: d — At least 5 cm (2 inches) deep, but not more than about 6 cm (2.4 inches)
- `club_emig_recoil_01` — Explain why full chest recoil matters in CPR. Answer: b — Recoil lets blood flow back into the heart before the next compression
- `club_emig_aed_01` — Follow AED prompts safely. Answer: d — Make sure no one is touching the patient
- `club_emig_bleed_01` — Describe the first steps in controlling life-threatening bleeding. Answer: c — Apply firm, direct pressure on the wound (and use a tourniquet above it if pressure doesn't control the bleeding)
- `club_spanish_01` — Understand and use common Spanish phrases for the medical history. Answer: b — Where does it hurt?
- `club_spanish_02` — Understand and use common Spanish phrases for the medical history. Answer: d — How long have you had the pain?
- `club_spanish_03` — Understand and use common Spanish phrases for the medical history. Answer: d — Are you allergic to any medicine?
- `club_spanish_04` — Understand and use common Spanish phrases for the medical history. Answer: d — Take a deep breath.
- `club_spanish_05` — Understand and use common Spanish phrases for the medical history. Answer: b — Do you have a fever?
- `club_spanish_06` — Understand and use common Spanish phrases for the medical history. Answer: c — Take one pill twice a day.
- `club_spanish_07` — Understand and use common Spanish phrases for the medical history. Answer: b — On a scale of one to ten, how bad is the pain?
- `club_spanish_08` — Understand and use common Spanish phrases for the medical history. Answer: c — I'm going to listen to your heart.
- `club_spanish_09` — Understand and use common Spanish phrases for the medical history. Answer: b — Do you smoke?
- `club_spanish_10` — Understand and use common Spanish phrases for the medical history. Answer: c — My chest hurts.
- `club_spanish_11` — Understand and use common Spanish phrases for the medical history. Answer: d — I feel dizzy.
- `club_spanish_12` — Understand and use common Spanish phrases for the medical history. Answer: c — How old are you?
- `club_spanish_13` — Understand and use common Spanish phrases for the medical history. Answer: d — pregnant
- `club_spanish_interp_01` — Choose a professional interpreter over ad hoc interpreting for clinical care. Answer: b — Use a professional medical interpreter, in person, by phone or by video
- `club_journal_arr_01` — Calculate an absolute risk reduction from event rates. Answer: b — 2 percentage points
- `club_journal_nnt_01` — Calculate a number needed to treat. Answer: b — 50
- `club_journal_rrr_01` — Distinguish relative from absolute risk reduction. Answer: b — Relative risk reduction (2 ÷ 6 ≈ 33%)
- `club_journal_design_01` — Identify a prospective cohort design. Answer: a — Prospective cohort study
- `club_journal_causation_01` — Explain why an observational association doesn't prove causation. Answer: c — No: it shows an association; unmeasured differences between coffee drinkers and others could explain it
- `club_journal_ci_01` — Interpret a confidence interval for a relative risk. Answer: c — The association is statistically significant at the 5% level, because the interval does not include 1
- `club_journal_sens_01` — Calculate sensitivity from a two-by-two table. Answer: a — 90%
- `club_journal_spec_01` — Calculate specificity from a two-by-two table. Answer: c — 95%
- `club_journal_ppv_01` — Calculate a positive predictive value and relate it to prevalence. Answer: a — About 67%

## Figures

- **ECG strips** (`ecg_strip`): synthetic traces from a simple model (P, QRS, T and ST shift; sinus or atrial fibrillation). They show rate, rhythm and ST elevation for teaching, not diagnostic morphology.
- **Micrographs** (`micrograph`): schematic H&E drawings of eleven tissues, not photographs.
- **Curves:** Michaelis–Menten, Lineweaver–Burk, Hill, exponential decay, repeated dosing, oral absorption, Frank–Starling-style and pressure–volume loops (as points), the oxygen–hemoglobin curve, and the spirometry volume–time curves. The functions are quantitatively right for their stated parameters; the parameters are illustrative.

## World text

- **Library exhibit** (`world/library/library_level2.gd`): Laennec's stethoscope (1816; the treatise 1819), ether anesthesia (16 October 1846, Boston), Semmelweis (1847, chlorinated lime, Vienna), and penicillin (Fleming 1928; Florey, Chain and the Oxford team 1940–41).
- **Anatomy Hall:** the donor memorial and dedication wording, and the lab's rules (respect, no photographs, covering donors).
- **Community Center notices:** benefits navigation (SNAP), English classes, flu shots, tax preparation and tenants' legal aid are illustrative services.
- **Hospital Food Court and café:** menus only; no health claims.

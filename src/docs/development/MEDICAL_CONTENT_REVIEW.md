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

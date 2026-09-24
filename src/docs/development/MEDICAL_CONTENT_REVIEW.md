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

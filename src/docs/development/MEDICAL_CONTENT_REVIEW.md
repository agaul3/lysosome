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

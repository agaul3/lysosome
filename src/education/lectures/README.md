# Lecture scripts

Lectures are data, not code. `pharmacodynamics_01.json` is loaded by `lecture_runner.gd`, which validates it and steps through it one professor line at a time. `world/lecture_hall/lecture_session.gd` connects the runner to the hall: the projected slide, the professor's gestures and the subtitle overlay.

```json
{
  "version": 1,
  "id": "pharmacodynamics_01",        // matches the schedule event id in data/academic_config.json
  "title": "Pharmacodynamics",
  "professor": "Dr. Lena Park",
  "segments": [
    {
      "id": "competitive",               // unique within the lecture
      "topic": "Competitive antagonism", // shown in the topic chip and HUD
      "slide": {
        "heading": "Competitive antagonism",
        "subheading": "",                // optional
        "bullets": ["…", "…"],           // at most 5; revealed progressively
        "diagram": "competitive_shift"   // one of LectureRunner.DIAGRAMS
      },
      "lines": [
        {"text": "…", "gesture": "screen", "reveal": 2}
      ]
    }
  ]
}
```

- `gesture` is `audience`, `screen` (the professor half-turns and points at the screen) or `none`.
- `reveal` is the number of bullets visible from that line on. It only ever adds bullets and never hides one already shown.
- Diagrams are drawn by `ui/lecture_slide.gd` from `education/models/dose_response.gd`, using the Hill equation on a log-concentration axis, so the curves are quantitatively consistent: EC50 at half of Emax, and a competitive shift by the dose ratio 1 + [B]/Kb.
- Questions are not written into lecture scripts. A question beat is a line `{"question": "pd_affinity_01", "lead": "Quick check.", "remediation": "optional_follow_up_id"}`, and the text comes from the shared bank (`education/questions/`). An activity line `{"activity": {"type": "competitive_antagonism", "question": id, "steps": {...}}}` runs the interactive model.

All narration is original, AI-assisted prototype content awaiting human review; see `docs/development/MEDICAL_CONTENT_REVIEW.md`.

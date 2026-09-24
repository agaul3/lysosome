# Shadowing scripts

A shadowing session is data, like a lecture. `hospital_orientation_01.json` is loaded and validated by `shadowing_script.gd`; `world/hospital/shadowing_session.gd` runs it in the hospital. The physician walks the student from stop to stop. At each stop she turns to the student and the stop's steps play in order.

```json
{
  "version": 1,
  "id": "hospital_orientation_01",      // matches the schedule event in data/academic_config.json
  "title": "Hospital orientation",
  "unit": "4 West · Internal Medicine",
  "speakers": {"okafor": "Dr. Maya Okafor", "patient": "Mr. Reyes"},  // "okafor" is the default speaker
  "lines": {"too_early": "…", "on_time": "…", "late": "…", "after": "…", "wait": "…"},
  "stops": [
    {
      "id": "station",                   // unique within the script
      "route": ["corridor_west"],        // anchors walked through on the way (may be empty)
      "at": "station",                   // anchor where the stop happens
      "topic": "Nurses station",         // shown in the topic chip
      "objective": "Follow Dr. Okafor to the nurses station",   // HUD objective while following
      "takeaway": "…",                   // saved to Lecture Notes once the stop is reached
      "steps": [ … ]
    }
  ]
}
```

Anchors are named points in the hospital scene (`Hospital.anchors`). The test suite checks that every anchor and action target a script uses exists.

## Steps

Each step has exactly one kind:

- `{"say": "…", "speaker": "martin"}` shows a line in the dialogue card. `speaker` is optional and defaults to the physician. The student stands and listens; E continues.
- `{"question": "ho_charge_nurse_01", "lead": "Quick check"}` asks a question from the shared bank (`education/questions/`). It is graded through `QuestionBank.submit` with a stable attempt ID (`<script id>:<question id>`), so XP and Knowledge statistics are recorded once however often the session is repeated.
- `{"action": "…", "target": "…", "objective": "…"}` hands control to the student until they do it:
  - `board`: step into the elevator car (`target`: the zone to ride to, e.g. `unit`);
  - `talk`: walk up to someone and press E (`target`: an NPC interaction). Also needs a `reply`;
  - `sanitize`: use a hand-sanitizer dispenser (`target`: its interaction);
  - `stand`: stand on a marked spot (`target`: a floor marker).
- `{"ehr": "open"}` zooms the view onto the workroom's EHR workstation. `banner`, `vitals`, `results` and `notes` highlight part of the chart, and `close` zooms back out.

All narration is original, AI-assisted prototype content awaiting human review; see `docs/development/MEDICAL_CONTENT_REVIEW.md`.

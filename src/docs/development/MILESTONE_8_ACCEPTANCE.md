# Milestone 8 acceptance — Progression Feedback

Spec: `docs/design/medical_school_rpg_spec.md` §26–30, §33–34, §41 and §42 (Milestone 8). Acceptance criterion: **progression and feedback work reliably.**

## Level formula

Configured in `data/academic_config.json` under `"level_curve": {"base_xp": 80, "growth": 1.3, "max_level": 50}` and implemented only in `education/progression/level_curve.gd`:

- XP to go from level L to L+1 = round(base_xp × growth^(L−1)), i.e. 80, 104, 135, 176, …
- Cumulative thresholds: level 2 at 80 XP, level 3 at 184, level 4 at 319, level 5 at 495.
- XP is a running total, so overflow carries into the next level automatically. One award can cross several levels.
- A negative balance (a late arrival before any reward) counts as 0 for levelling. `AcademicSession.level` records the highest level reached and never decreases, so a penalty can't undo a level.
- Tier rewards stay configurable (`xp_by_tier`: 10/20/30). The Pharmacodynamics lecture offers 200 XP, so a strong student reaches level 3 and a typical one at least level 2 during the slice.

| Requirement | Implementation | Evidence (`progression_test.gd` unless noted) |
|---|---|---|
| Correct answer awards the correct XP; incorrect awards zero | `QuestionBank.submit` → `AcademicSession.add_xp` | "Correct answer awards its tier XP", "Incorrect answer awards zero" |
| Lateness subtracts 5 exactly once | `record_arrival` → `add_xp(-5, "late")`, first arrival immutable | "Lateness subtracts 5 exactly once"; `academic_test.gd` |
| Level threshold; overflow preserved; multiple level-ups | `LevelCurve`; single `level_up(from, to)` signal | threshold, overflow and multi-level checks |
| Penalties cannot corrupt progression | Level floor at 0 XP; peak level kept; bar clamped | lateness safety checks |
| XP HUD (level + progress bar) | `ui/progression_hud.gd` in the shared HUD's top bar | "HUD shows level and XP progress" |
| Correct feedback: sound, floating XP, animated bar | `autoload/sfx.gd` (`correct.wav`); floating "+N XP"; tweened bar that wraps through level-ups | sound, floating and bar checks |
| Streak tracked; hidden below 10; shown at 10; reset on miss | `AcademicSession.streak`; "10x STREAK" chip | streak checks (logic and UI) |
| Level-up feedback more significant | Distinct `level_up.wav`; banner "LEVEL UP / Level N → Level N+1" with scale pop, particle burst and soft flash; about 2.3 s | banner, fanfare and brevity checks |
| Distinct audio: correct, incorrect, level up, future achievement | Original synthesized WAVs in `audio/sfx/` (see README) | sound checks; files present |

Graphical captures of the HUD, floating XP, streak chip, level-up banner, and XP feedback during the lecture were inspected.

**Deferred:** the Knowledge interface (Milestone 9); save/load, since progression is session-only until then.

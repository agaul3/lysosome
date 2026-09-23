# Milestones 5 and 6 acceptance report

Date: 2026-09-23
Result: **PASS** for both milestones.

Scope follows the authoritative medical_school_rpg_spec.md. Milestone 7 has not been started.

## Milestone 5 — Time and attendance

- Configurable 5× game clock with date, academic week and semester state, plus a persistent exploration clock display.
- Today and Calendar tabs show the structured mandatory 8:00 AM pharmacodynamics event in Lecture Hall A. Campus daylight responds to game time.
- The first successful Hall A entry records attendance for that event date. Arrival exactly at 8:00 AM is on time; arrival afterward is late under the configured zero-second grace period.
- Late arrival displays feedback and applies exactly -5 XP once. Leaving and reentering cannot repeat the penalty or replace the original attendance result.
- The session XP ledger supports a negative balance so the exact penalty is retained at zero XP; subsequent rewards repay it.
- Time and autonomous NPC events continue while the menu is open. New Game resets academic state, and returning to the title stops the clock.

## Milestone 6 — Shared question engine

- Versioned JSON schema separates medical content from gameplay scripts, including discipline/topic/subtopic, question type, independent difficulty tier, answer, explanation, objective, lecture association and configurable reward.
- Strict, atomic validation rejects malformed records without replacing the previously loaded bank. Returned question records are deep copies.
- Pure grading supports multiple choice and predefined normalized short answers. No fuzzy grading or runtime AI is used.
- Submission provides explanations and exactly-once XP/performance transactions using attempt IDs. Invalid answers are not counted as incorrect attempts; conflicting retries are rejected.
- Three original pharmacodynamics seed questions exercise the shared engine independently of lecture delivery. Medical source and human-review notes are recorded in MEDICAL_CONTENT_REVIEW.md.

## Verification

Godot 4.7.2 stable, Compatibility renderer.

- Academic headless suite: **77 checks, zero failures**.
- Academic graphical suite: **79 checks, zero failures**, including two screenshot captures.
- Earlier regression suites: foundation 54, dorm 68, campus 38, NPC 33 — **193 checks, zero failures**.
- Editor import and script parsing succeeded.
- Rendered schedule and lateness feedback inspected visually.
- Whitespace validation passed.

Coverage includes frame-rate-independent time, midnight/week/leap-day boundaries, invalid elapsed time, exact attendance deadlines, repeated arrival, live scene transitions and menus, reset behavior, malformed question imports, reward bounds, answer explanations, retry handling, metadata counters and XP debt repayment.

## Remaining scope and limitations

- Lecture presentation, the full approximately 12-question lecture and remediation remain future milestone work. There is no question delivery UI in this milestone.
- Levels and level-up feedback are deferred; the ledger and performance hooks are foundations only.
- Academic state is session-only. Save/load is deferred.
- Existing NPC event timing remains based on elapsed real seconds independently of the academic clock.
- Seed medical content requires human educational review before release.
- Physical controller hardware was not validated in this run.
- Existing Milestone 4 changes were preserved. All changes remain uncommitted.

No critical blockers were found for the Milestone 5–6 scope.

# Known issues — Milestones 5–6

- Physical controller hardware has not been tested. Bindings and injected controller events are covered by automated tests.
- Continue remains unavailable and character selection lasts only for this process. Save/load is deferred.
- Volume/fullscreen settings are session-only. There is no game audio yet; volume is checked against the audio bus.
- Original low-poly visuals are placeholders. The room camera is intentionally fixed and near walls are visually cut away while retaining collision.
- NPC navigation uses a fixed authored AStar route; dynamic crowd avoidance and player blocking are not implemented. The reserved chair is entered intentionally for the seated pose.
- Campus light follows the clock; indoor lighting remains fixed. NPC prototype timing remains elapsed-time based.
- Hall A is a minimal NPC seating prototype. Player seating, lecture camera, questions and progression remain deferred.

The earlier sandbox launch/certificate issues are historical: graphical launch and fullscreen worked with the current environment. The Run #2 instructions also state Milestone 1 was manually verified and committed. Its original acceptance report is retained as historical evidence rather than rewritten.

See `MILESTONES_5_6_ACCEPTANCE.md` for current validation results.

- Academic attendance, question history and XP are session-only until save/load is implemented. A late student at zero XP has a -5 balance; later rewards repay it. No level curve exists yet.
- The question bank contains three seed items, not the full lecture set, and has no delivery UI yet. Human medical-content review is required before educational release.
- The configured lecture is a one-off event. Subsequent dates show no scheduled event; repeated daily academic calendars remain future content.

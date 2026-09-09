# Known issues — Milestone 3

- Physical controller hardware has not been tested. Bindings and injected controller events are covered by automated tests.
- Continue remains unavailable and character selection lasts only for this process. Save/load is deferred.
- Volume/fullscreen settings are session-only. There is no game audio yet; volume is checked against the audio bus.
- Original low-poly visuals are placeholders. The room camera is intentionally fixed and near walls are visually cut away while retaining collision.
- Campus students are static figures with one simple interaction; autonomous NPC behavior is Milestone 4.
- Morning light is a static configuration, not a running clock; time/schedule arrive in Milestone 5.
- Hall A is an inspection endpoint in the entry lobby. Lecture seating, questions and progression remain deferred.

The earlier sandbox launch/certificate issues are historical: graphical launch and fullscreen worked with the current environment. The Run #2 instructions also state Milestone 1 was manually verified and committed. Its original acceptance report is retained as historical evidence rather than rewritten.

See `MILESTONE_3_ACCEPTANCE.md` for current validation results.

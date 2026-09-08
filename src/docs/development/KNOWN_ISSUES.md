# Known issues

- New Game intentionally ends at the foundation screen. Player, appearances and dorm are Milestone 2 work.
- Continue is unavailable; save/load is not implemented.
- Volume/fullscreen settings are session-only. This build has no game audio, so volume is verified against the audio bus.
- Physical controller hardware has not been tested; automated tests inject controller events and verify bindings.
- Sandboxed Godot can emit a macOS certificate-store initialization error (`get_system_ca_certificates`). No project network functionality exists. Initial import also reported denied Godot cache/user-data writes; access was subsequently granted for normal engine directories.

Graphical launch from the sandbox exited with code 134. The desktop-control tool displayed Project Manager but repeatedly failed with `noWindowsAvailable`; Finder also failed with `cgWindowNotFound`. Rendered game layout, mouse interaction, and fullscreen remain unverified. Overall Milestone 1 status is PARTIAL pending graphical acceptance. No critical code blocker was found in headless tests; desktop acceptance must still be resolved. See `docs/MILESTONE_1_ACCEPTANCE.md`.

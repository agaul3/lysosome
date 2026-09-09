# Changelog

## 2026-09-10 — Milestone 3: Campus

- Replaced the temporary dorm exit with a traversable academic courtyard and Learning Center entry lobby.
- Added directory and static student interactions, signs, original low-poly buildings/palms, collision and configured morning lighting.
- Added bounded camera follow, configurable shared location HUD, destination-specific arrival state and return transitions.
- Added full campus-route tests and updated dorm regression expectations. Reused existing folders; no Milestone 4 or 5 simulation built.

## 2026-09-10 — Milestone 2: Player + Dorm

- Added four original preset appearances, shared preview/gameplay visuals and stable selection IDs.
- Added reusable camera-relative player movement, capsule collision and orthographic dorm camera.
- Added an original low-poly dorm, solid furniture/boundaries, desk and bed interactions, and a temporary exit scene.
- Extended AppState with guarded scene transitions; reused session settings in the dorm.
- Added integration coverage for the full walking route, input, physics rates, collisions, interaction lifetime and restart. Fixed stale HUD references when an interaction target is freed.
- Updated foundation checks and documentation links for the reorganized docs tree. No new directories or Milestone 3 systems.

## 2026-09-09 — Milestone 1 foundation

- Added Godot 4.7.2 project with Compatibility renderer and semantic keyboard/controller actions.
- Added minimal signal-based application state, start screen, explicit New Game foundation destination, disabled Continue, working Quit, and session volume/fullscreen settings.
- Created the requested directory skeleton, documentation, immutable product-spec snapshot, and Godot foundation test harness.
- No Milestone 2 gameplay or later educational/progression systems implemented.

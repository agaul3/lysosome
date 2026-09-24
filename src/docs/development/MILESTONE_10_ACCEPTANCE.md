# Milestone 10 acceptance — UI + Polish

Spec: `docs/design/medical_school_rpg_spec.md` §9.1, §12, §32–35, §42 (Milestone 10) and §46. Acceptance criterion: **a fresh user can complete the slice without developer intervention.**

## Design direction

The brief was a modern educational platform crossed with a polished RPG: clean, professional, motivating and slightly premium, with a subtle medical-academic identity, and nothing cartoonish, cheesy-hospital or MMO-cluttered. It is implemented as one design system, `ui/style/ui_style.gd`:
- **Palette:** deep ink surfaces; a single academic teal accent for interaction and navigation; warm gold reserved for progression (XP, levels, streaks); quiet semantic greens and corals for feedback.
- **Type:** Outfit at four weights on a fixed scale (12 / 13 / 15 / 19 / 26 / 46). Uppercase eyebrows use letter spacing.
- **Components:** panels, cards, chips, hairlines, and buttons (default, primary, navigation, card, ghost) with an offset focus ring that stays visible on filled buttons. Slider and switch are drawn to match.
- **Icons:** one vector line-icon set (`ui/style/icon.gd`, 22 glyphs) at a single stroke weight.
- **HUD:** stays minimal. The player menu is the rich screen.

| Requirement | Implementation | Evidence |
|---|---|---|
| Start screen: New Game, Continue if a save exists, Settings, Quit | `ui/start_screen.gd` over a live campus panorama (`world/campus/panorama.gd`, reusing the real campus builders). Continue is primary when a valid save exists and shows what it will resume. New Game confirms before replacing a save. | `foundation_test.gd`, `ui_test.gd`, `save_test.gd` |
| Character setup (3–5 presets) | Preset cards with colour swatches and a turntable 3D preview | `ui_test.gd`, `dorm_test.gd` |
| HUD: level, XP bar, time; contextual prompts only when needed | Location + objective card; level/XP card; date-over-time clock card; unboxed prompt and controls hint; compact message card | `room_polish_test.gd`, `ui_test.gd` |
| Player menu with all nine sections (§32) | Sidebar menu (`ui/menu/`). Fully functional: Today, Knowledge, Settings. Representative: Calendar (month grid), Campus Map (plan view with a live position marker), Lecture Notes (sections reached). Placeholder previews: Achievements (derived from progress) and Inventory. Plus an Overview. | `ui_test.gd`, `knowledge_test.gd`, `academic_test.gd` |
| Menu does not pause the world (§12) | Menu is an overlay; time and NPCs run while it is open | `ui_test.gd`, `academic_test.gd`, `npc_test.gd` |
| Save system (§35) | `autoload/save_game.gd`: versioned JSON; atomic verified writes; all-or-nothing validated loads; autosave on arrival and after class; manual save; resume at the saved location | `save_test.gd` (37 checks) |
| Transitions | `autoload/transition.gd`: fade to ink, swap scene, fade in (instant in headless tests) | `ui_test.gd` |
| Audio | Answer and level-up sounds (Milestone 8) plus soft UI cues for focus, confirm, and menu open/close; all original | `ui_test.gd`, `progression_test.gd` |
| Lighting / visual consistency | Campus redesign; lobby rebuilt to match the modern Learning Center (slate floor, timber feature wall, glazed hall doors, relief lettering); filmic tone mapping outdoors and in the lobby | Graphical captures |
| Guidance for a fresh player | `data/objectives.gd` gives the next step for every location (with a class countdown) in the HUD and on the Overview | `ui_test.gd` |
| Player visible behind scenery | Stencil x-ray silhouette on the player, off while seated | `ui_test.gd`, capture |
| Fresh user completes the slice (§46) | End-to-end run with real inputs: every numbered step from launch to reload | `acceptance_test.gd` (47 checks) |

**Honest limitations:**
- Achievements and Inventory are previews, as the spec allows. There is no separate achievement or inventory system.
- The map is a plan view drawn from layout data, not a render.
- Sound effects are synthesized placeholders, and there is no music or ambience.
- Medical content still awaits human review.

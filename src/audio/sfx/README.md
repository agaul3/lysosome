# Sound effects

Original placeholder sounds synthesized for this project (additive sine/bell
partials with simple envelopes); no third-party audio is used.

| File | Use |
|---|---|
| `correct.wav` | Correct answer: short rising two-note chime |
| `incorrect.wav` | Incorrect answer: soft falling low pair |
| `level_up.wav` | Level up: arpeggio into a sustained chord with shimmer (more prominent) |
| `achievement.wav` | Reserved for future mastery/achievement unlocks |
| `ui_move.wav` | Menu focus/hover tick (very quiet) |
| `ui_confirm.wav` | Button press |
| `ui_open.wav` / `ui_close.wav` | Player menu opening and closing |

Played through `autoload/sfx.gd` on the Master bus, so the volume setting applies.

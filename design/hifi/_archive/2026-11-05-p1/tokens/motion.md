# Motion

Durations stay between 150 and 250 ms, with M3 easing: *standard* `cubic-bezier(.2,0,0,1)` and *emphasized decelerate* `cubic-bezier(.05,.7,.1,1)` for things entering. When reduce motion is on (`MediaQuery.disableAnimations` / iOS Reduce Motion), every movement below becomes a 100 ms cross-fade or an instant change. Nothing loops, except the spinner and the linear progress bar, which are system indicators.

Motion is not a token family in this system (the type has no motion tokens). Suggested Dart constants: `VgMotion.short = 150ms`, `VgMotion.medium = 200ms`, `VgMotion.long = 250ms`.

| Moment | Motion | Duration · easing | Reduce motion |
|---|---|---|---|
| Period change (‹ › or swipe on the chart) | The ring and the centre totals slide 24 dp in the swipe direction and fade; the period title cross-fades; the budget bar animates its width | 200 ms · standard | Cross-fade 100 ms; the bar jumps |
| Keypad press | Ripple state layer (10 % ink), with a 1 dp scale-down to 0.97 on press and back up on release; light haptic on Save and Backspace | 150 ms · standard | Ripple only, no scale |
| Category tapped → saved → Home (D-018) | The tapped cell fills with `primary-container` for 100 ms, the sheet slides down (200 ms), the entry route pops (Android: predictive back; iOS: slide), and on Home the matching ring arc grows from its old to its new length (250 ms). A "Saved" state is the arc growth itself, so no snackbar | 100 + 200 + 250 ms · emphasized | Instant pop and cross-fade; the arc jumps |
| Sheet open / close | Slides up from the bottom while the scrim fades to `scrim`; closes with the reverse at 150 ms | 250 ms in · 150 ms out · emphasized decelerate | Fade only |
| Dialog | Fades and scales from 0.92 to 1 | 200 ms · emphasized decelerate | Fade |
| Snackbar | Rises 16 dp and fades in; leaves with a fade. A 10-second snackbar shows a thin timer line that shrinks linearly | 200 ms in · 150 ms out | Fade; the timer line stays static |
| Search results update | The list cross-fades on query change (debounced 150 ms); the summary line updates with the list | 150 ms | Instant |
| Hidden accounts expand / collapse | Height animates; the chevron rotates 180° | 200 ms · standard | Instant |
| PIN error | The 4 dots shake horizontally (±8 dp, 3 cycles) and clear; "Wrong PIN" fades in; error haptic | 250 ms | No shake: the dots clear and the error text appears |
| Auto-backup running → done | The button label is replaced by a 18 dp spinner; when the run ends, the spinner cross-fades back to the label, the status line icon changes (⏱ → ✓ or ⚠) and the "Backup saved" snackbar enters | 150 ms cross-fades | Same, without movement |
| Switch | Thumb slides and grows from 16 to 24 dp (Material) | 150 ms | Instant |
| Widget tap → app | System launch animation; no in-app transition except the Lock overlay fade (150 ms) | — | — |

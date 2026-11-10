# ActionButtons

The main − / + buttons, the button family (filled, tonal, outlined, text, danger), the button pair, the extended FAB and the wide Save key.

States per row: default · pressed (12 % state layer) · focused (2 dp `focus` ring, 2 dp offset) · disabled (38 %).

- − / + : 64 dp, `radius-lg`, glyph (`key-glyph`) + word (`label-lg`). At ≥ 130 % the glyph renders as a 32 dp icon and the word wraps under it (min height 96).
- Filled = the one main action of a dialog or sheet. Tonal = a frequent secondary action (Back up now). Outlined = an alternative (Choose folder again, Hide account). Text = Cancel and low-emphasis actions. Danger: `error` fill in destructive dialogs; `error` text in management areas.
- Button pair: tonal + outlined, 8 dp gap, wraps to two lines at large text. In an error state, emphasis swaps to the fix.

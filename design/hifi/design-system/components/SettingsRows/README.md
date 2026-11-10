# SettingsRows

Settings building blocks: group card, segmented control, switch row with a long subtitle, value row, danger row, status row and pill.

- Group = a title-sm group title in `primary` above a `surface-container-low` card (`radius-lg`). Groups are 24 dp apart; cards in a group 12 dp.
- Switch rows always show their full subtitle (privacy consequences). The switch aligns to the first line.
- Values are subtitles under the row title, not trailing text, so long VI titles and 200 % never collide.
- Status row: an icon plus text. OK = ✓ `primary`; idle = ⏱ `ink-muted`; error = ⚠ on an `error-container` strip with `on-error-container` text.

# HomeWidget

The Android home-screen widget (EXT-01), redrawn for the full-app round. One widget class, 2 × 2 (164 × 186 dp) and stretched 4 × 2. Its colours are fixed brand colours and do not follow the app theme or dynamic colour; the widget renders in the brand's dark scheme (`data-theme="dark"` on the widget), so `warning` uses its dark value.

- **Surface:** `widget-surface`, radius 24 (the system widget radius on Android 12+), 12 dp padding, soft shadow, a faint `brand-mint` halo top-right.
- **Header:** monochrome logo + label in `label-sm` 600, `brand-mint`.
- **Hero amount:** the month's spending in the **main currency**, 22 sp bold, tabular (26 sp in 4 × 2).
- **Budget:** 6 dp bar (`brand-mint` on 18 % paper) and caption "of $2,800.00 · 66%". At ≥ 80 % the bar and caption turn `warning`, with the warning icon and "Almost over".
- **Buttons:** `brand-paper` fill, `brand-deep` text (8.9:1), radius 16, ≥ 56 dp. A 26 dp disc in `widget-expense` / `widget-income` carries the − / + glyph, and the word is always shown. In 2 × 2 the glyph sits above the word; in 4 × 2 the buttons stack on the right.
- **Privacy:** the default has amounts off and shows the picker description instead. With PIN on, the header says "Locked with PIN" and the amount is a dotted mask, so the layout does not jump.

New copy: `widgetSpentLabel` ("Spent this month" / "Tháng này đã chi") and `widgetOfBudget` ("of {budget} · {percent}" / "trên {budget} · {percent}") replace the one-line "Spent this month: X / Y", which used to truncate.

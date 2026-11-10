# Assumptions

Places where product.md was ambiguous. Each choice below was made without stopping to ask, and is marked on the frames with a dark numbered pin or listed in the frame notes.

| ID | Assumption |
|---|---|
| A01 | Ring slot count is computed from the ring circumference: 17 slots at 360 dp (16 categories + ⋯). The same 17 are drawn at 393 pt; if the code fits 18 there, the ⋯ simply moves one slot later. |
| A02 | VI and 200 % variants are drawn on Android 360 dp, light only (the tightest width), as §11.2 allows “one platform” for 200 % and does not name a platform for VI. |
| A03 | Auto-backup time in EN uses the app’s short date order “Nov 25, 21:04” (sample data wrote “25 Nov, 21:04”); VI “25 thg 11, 21:04”. |
| A04 | At ≥ 130 % text on Home: the − / + glyphs render as 32 dp icons (not scaled text), the word wraps under them and the buttons grow to 96 dp; ring totals move to a labelled list below the ring. |
| A05 | Category-limit bars always show the current month (rule 9). When another period is viewed, the line gets a NEW “This month:” prefix (proposal, copy key categoryLimitThisMonth). |
| A06 | Empty search query = the field is focused, keyboard up, and the scope’s records are listed newest first without a summary line. |
| A07 | In the flat search list amounts carry − / + (expense / income) in their colours because types are mixed; transfers have no sign. Amount matches highlight digits across thousands separators. |
| A08 | With PIN on, the “Show amounts on widget” row shows a “Locked with PIN” pill that reuses the existing widget string widgetLockedByPin (no new copy). |
| A09 | Currency rows show the localized currency name (CLDR, already used for search) as a subtitle; while a query is typed the pinned current currency is hidden. |
| A10 | Hidden accounts: section header shows the count in parentheses; each hidden row has a visible “Show again” button and the row itself still opens Edit account. |
| A11 | The “last visible account” case is shown with Cash as the only visible account and the others hidden. |
| A12 | Frequency-change hint date = next due date of the old schedule (Rent: Dec 1), per rule 8. Hint copy is NEW. |
| A13 | While encrypting / decrypting (“Working”), Cancel is disabled because the operation cannot be interrupted safely. |
| A14 | The reminder time picker is Flutter’s Material showTimePicker on both platforms (not a native picker); its “OK”/“Cancel” labels come from Material localizations; 24 h follows the device. |
| A15 | Widget 2 × 2: buttons stack vertically and the status line may use 2 lines before ellipsis (brief says 1 line) — needed for “Spent this month: X / Y” and for VI. |
| A16 | Android small notification / status-bar icon is a monochrome silhouette redrawn from the logo; production should export it from the existing monochrome launcher layer (F-23). |
| A17 | The blank Recents card colour is drawn by the system; shown here as the app surface colour. |
| A18 | Settings groups without a title today (Categories/Accounts; Budget…Month start) stay untitled — no new group-title copy. |
| A19 | EXT frames: “theme” folder = light / dark wallpaper. EXT-01 and EXT-03 Android only; EXT-02 both platforms. EXT files use EXT01, EXT02, EXT03 as the <NN> part. |
| A20 | iOS frames use the same adaptive Material components as Android (no Cupertino widgets); status bar, keyboard and OS prompts are placeholders. |
| A21 | Search scope is a two-chip single choice (“{current period}” | “All time”) — same behaviour as the existing All time chip, just with the other option made visible. |
| A22 | Sample “today” = Thu 26 Nov 2026, period November 2026; 25-category stress month totals ₫15,240,000 with a ₫16,000,000 budget (default month in §8 is ₫11,780,000). |

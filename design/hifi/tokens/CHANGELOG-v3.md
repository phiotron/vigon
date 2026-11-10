# Changelog: tokens v2 → v3 (full-app redraw, 2026-11-10)

v3 keeps the v2 schema and every v2 name. It **adds 29 tokens**, **removes none** and **changes one value**: `radius-widget` 20 → 24 px, for the redrawn widget. The usage notes of `secondary-container`, `error`, `widget-surface`, `widget-expense` and `widget-income` were updated.

## Added

### Colour (light / dark)

| Token | Light | Dark | Use |
|---|---|---|---|
| `warning` | `#8A4F00` | `#FFB869` | "Almost over" and "Overdue" text, icons and bars. At least 5.4:1 on every surface |
| `on-warning` | `#FFFFFF` | `#4A2800` | Text on a solid `warning` fill |
| `warning-container` | `#FFDCBE` | `#693C00` | Amber chip or strip: Overdue, offline rates |
| `on-warning-container` | `#2E1500` | `#FFDCBE` | Text and icons on `warning-container` |
| `info-container` | `#DDE6F1` | `#25313D` | Neutral info: queue banner, "Created account" card, ✉ marker, reminder chips |
| `on-info-container` | `#0F1D2B` | `#D7E3F0` | Text and icons on `info-container` |
| `badge` | `#BA1A1A` | `#FFB4AB` | Count badge (queue) |
| `on-badge` | `#FFFFFF` | `#690005` | Number on the badge |
| `tabbar-surface` | `#ECF2EF` | `#1B211F` | Reserved for the bottom navigation (not used this round) |
| `tabbar-indicator` | `#CCE8DF` | `#334B44` | Reserved for the bottom navigation |
| `tabbar-active` | `#062019` | `#CCE8DF` | Reserved for the bottom navigation |
| `tabbar-inactive` | `#3F4946` | `#BEC9C4` | Reserved for the bottom navigation |
| `chart-income` | `#2E7D32` | `#81C784` | Charts (reserved) |
| `chart-expense` | `#C62828` | `#EF9A9A` | Charts (reserved) |
| `chart-line` | `#2E7D6B` | `#8CD5BF` | Charts (reserved) |
| `chart-grid` | `#D3DCD8` | `#2C3431` | Charts (reserved) |
| `chart-axis` | `#3F4946` | `#BEC9C4` | Charts (reserved) |
| `chart-highlight` | `#CCE8DF` | `#334B44` | Charts (reserved) |
| `cal-selected` | `#2E7D6B` | `#8CD5BF` | Calendar (reserved) |
| `on-cal-selected` | `#FFFFFF` | `#00382D` | Calendar (reserved) |
| `cal-today` | `#2E7D6B` | `#8CD5BF` | Calendar (reserved) |
| `cal-muted` | `#6F7975` | `#89938F` | Calendar (reserved) |
| `cal-income-dot` | `#2E7D32` | `#81C784` | Calendar (reserved) |

### Size and radius

| Token | Value | Use |
|---|---|---|
| `tabbar-height` | `80px` | Bottom navigation height (reserved) |
| `tabbar-indicator-w` | `56px` | Tab indicator width (reserved) |
| `tabbar-indicator-h` | `28px` | Tab indicator height (reserved) |
| `cal-cell-h` | `52px` | Calendar cell height (reserved) |
| `chart-bar-w` | `8px` | Chart bar width (reserved) |
| `radius-bar` | `3px` | Chart bar corner (reserved) |

"Reserved" tokens belong to the Overview / Stats / Calendar / tab-bar work from brief v3. They are in the file so nothing has to be renamed later, but no frame in this round uses them.

## Mapping

- `warning*`, `info-container*` and `badge*` go into `ThemeExtension<ViGonColors>`. `ColorScheme` has no slots for them.
- Sizes go into `VgTap` and radius into `VgRadius`.
- `TextTheme` is unchanged: 12 styles, amounts in tabular figures.

## New component patterns (no new tokens needed)

| Pattern | What it does |
|---|---|
| **Main-currency-first amount** | Main amount in bold first. When the record or account uses another currency, its own amount sits on a muted second line. |
| **Status chip** | ok / warn / err / info / neutral. Always icon + text, never colour alone. |
| **Savings wallet card** | Progress bar + % text, "Saved X of Y", "Y to go", deadline chip, reminder line, Add money. |
| **Debt row** | Avatar initials, paid-of bar, due chip, next reminder date, remaining amount. |
| **Queue card** | Payee and content, bank amount ≈ main, source account, category strip with **Suggested**, actions. |
| **"Remind me" choice chips** | Don't remind · On the day · 1 / 3 / 7 days before. |
| **Rate row** | "1 A equals x B", source chip (Auto / Offline / Set by you), the account that needs it. |
| **Onboarding step** | Step counter, progress pill, one large primary button at the bottom. |

## Home-screen widget (redrawn)

The old widget, with solid red and green button blocks and a one-line status that truncated, is gone. The new one:

- `widget-surface` with a faint `brand-mint` halo, radius `radius-widget` (now 24, the Android 12+ system widget radius).
- The month's spending in the main currency as the hero, a budget bar, and `warning` with "Almost over" at ≥ 80 %.
- Two `brand-paper` buttons with `brand-deep` text. `widget-expense` / `widget-income` now colour only the small − / + disc.
- New copy: `widgetSpentLabel`, `widgetOfBudget`.

## Existing screens that change visibly

| Screen | What changes |
|---|---|
| Home | Balance bar names its period and currency; account-filter chip; queue banner + badge |
| Records | Rows show time, ✉ and amounts with the main currency first |
| Entry | Time chip; amount in the account's currency with a "≈ main" line; email-source strip |
| Accounts | Currency per account; "Total in USD" hero; wallet / email tags |
| Transfer | Shows what the other account receives across currencies |
| Settings | 9 groups; Main currency first; Exchange rates; Due reminders |
| Currency picker | Becomes the "Main currency" picker |
| Widget (EXT-01) | Redrawn; replaces the P1 widget everywhere, including the archive |

# Changelog — widget tokens v3 (2026-11-06)

The home screen widget was redesigned ("Emerald & gold", direction B chosen by the user after seeing the 2×2 widget on the Galaxy A13). The `widget-*` tokens now have a light and a dark value (Android `values/` and `values-night/`, iOS `colorScheme`), following the device's light/dark mode. No dynamic color: the brand colors stay fixed. Other tokens are unchanged.

| Token | Light | Dark | Use |
|---|---|---|---|
| `widget-surface` | `#FBF8F1` | `#0A2F27` | Background, start of a soft gradient (top left). Changed (was `#0E5244`) |
| `widget-surface-end` | `#F3ECDD` | `#062019` | Background gradient end (bottom right). New |
| `widget-ink` | `#0E3B32` | `#F4EBD3` | App name and button labels. Changed (was `#F7FAF8`) |
| `widget-gold` | `#6E5C34` | `#D6B66E` | Status line and its lock/update icon. New |
| `widget-outline` | `#D9C48F` | `#7D6B3F` | 1dp gold outline around the widget. New |
| `widget-action` | `#EFE5CF` | `#1B3E36` | Background of the Expense/Income buttons. New |
| `widget-expense` | `#C0463A` | same | Round badge behind "−" on Expense (white 4.98:1). Changed (was `#C62828` button fill) |
| `widget-income` | `#1F7A5C` | same | Round badge behind "+" on Income (white 5.25:1). Changed (was `#2E7D32` button fill) |
| `on-widget-action` | `#FFFFFF` | same | The − / + glyph on the badges |

Widget buttons use `radius-lg` (16) instead of `radius-md`. Contrast pairs are checked in `test/ui/theme_test.dart`.

# Changelog — tokens v1 → v2

Tokens v2 keeps the v1 schema and every v1 token name and value. `tool/gen_tokens.py` keeps working; the new tokens only need to be added to `ColorScheme` / `ViGonColors` / `VgRadius` / `VgTap` (mapping below).

## Added (14)

| Token | Light | Dark | Maps to | Used by |
|---|---|---|---|---|
| `surface-container-low` | `#F2F6F4` | `#171D1B` | `ColorScheme.surfaceContainerLow` | Settings group cards (SCR-12/33). `primary` on it 4.52:1 |
| `error-container` | `#FFDAD6` | `#93000A` | `ColorScheme.errorContainer` | Auto-backup error strip (SCR-31) |
| `on-error-container` | `#410002` | `#FFDAD6` | `ColorScheme.onErrorContainer` | Text and icon on that strip (13.3:1 / 7.2:1) |
| `brand-deep` | `#0E5244` | same | `ViGonColors.brandDeep` | Logo background, Android notification circle |
| `brand-mint` | `#8CD5BF` | same | `ViGonColors.brandMint` | Logo back card only |
| `brand-paper` | `#F7FAF8` | same | `ViGonColors.brandPaper` | Logo front card only |
| `brand-dot` | `#E65100` | same | `ViGonColors.brandDot` | Logo dot only |
| `widget-surface` | `#0E5244` | same | Android `res/values/colors.xml` | Widget background (EXT-01) |
| `widget-ink` | `#F7FAF8` | same | Android resources | Widget status line, name (8.65:1) |
| `widget-expense` | `#C62828` | same | Android resources | Widget Expense button (white 5.62:1) |
| `widget-income` | `#2E7D32` | same | Android resources | Widget Income button (white 5.13:1) |
| `on-widget-action` | `#FFFFFF` | same | Android resources | Text and glyph on the two widget buttons |
| `radius-widget` | `20px` | | `VgRadius.widget` + `@dimen` | Widget corner where the launcher doesn't apply the system radius |
| `row-two-line` | `72px` | | `VgTap.rowTwoLine` | Minimum height of two-line rows: switch rows with subtitles, search results, currency rows |

## Removed

None.

## Changed

No value changed. Only the usage notes of six tokens changed, to cover their new roles:

| Token | New usage added |
|---|---|
| `primary-container` | Search-match highlight (with weight 600) |
| `secondary-container` | Tonal button, selected segment, selected filter and choice chip |
| `surface-container` | Search field background |
| `outline` | Dashed ring of the ⋯ "More categories" slot |
| `inverse-surface` | The snackbar always sits above − / + and the keypad, and grows to 1–3 lines |
| `swipe-delete` | Note that it equals `error-container` in light; kept separate because it is already mapped |

Type: the 12 styles are unchanged. Components scale them with the text-scale factor (Flutter does this already). The widget is a native Android view and uses `label-sm` (status) and `title-md` at weight 700 (buttons).

Known contrast exception (from v1): `primary` text on `surface-container` is 4.34:1 (sheets). In P1, sheets use `primary` only for icons and filled buttons, never for body text.

## Existing ✅ screens that change visibly (proposed P2 scope)

The token values are unchanged, so tokens alone change nothing. These visible changes come from the updated components:

| Existing frame(s) | What changes | Component |
|---|---|---|
| 2.1, 2.2, 2.3 Home | "Income" / "Expenses" labels in the ring centre; the balance bar shows the period title under "Balance"; the empty state gets friendlier (§10.1 #16) | Ring, Balance bar |
| 2.4–2.6 (Home behind sheets) | Same Home changes in the background | Ring, Balance bar |
| 2.6 + Home + Entries header | Visible active-account chip (§10.1 #1). Designed in P2 | Chip (filter) |
| 3.1–3.8 New entry | Note field 56 dp instead of 52; snackbar above the keypad; 3.3 annotation updated for D-018 (pick = save) | Text field, Snackbar |
| 3.3 Category grid | Same grid as 07, with a selected ring on the chosen cell | Category avatar |
| 4.1–4.4 Entries | Record amounts line up with category totals (24 dp gutter); 🔍 Search action in the app bar; category limit bars | List rows, App bar |
| 4.3 Undo snackbar | Positioned above the content; stacked layout when the text is long | Snackbar |
| 4.5–4.7 Edit record | Field height 56 | Text field |
| 5.1, 5.2 Settings | Grouped cards; First day of week as a segmented control; values as subtitles; CSV format subtitle; new rows | Settings rows |
| 5.3, 5.4 Monthly budget dialog | Dialog body scrolls with actions pinned at large text; 56 dp field | Dialog, Text field |
| 5.5 Currency | Replaced by the full-height searchable sheet (SCR-13) | Sheet |
| 6.1 Categories | Optional limit hint on rows (§10.1 #6, proposal) | List rows |
| 6.2 Edit category | Budget field and pinned footer (SCR-16) | Sheet, Text field |
| 6.3 Delete category, 8.9–8.10, 1.3–1.5 | Same confirm dialog, now with a scrolling body at 200 % | Dialog |
| 6.4, 6.5 Accounts | Hidden section; management area (SCR-17/18) | List rows, Sheet |
| 6.6, 6.7 Transfer | Field and snackbar tweaks only | Text field |
| 7.1 Repeating records | No change; 7.2 is replaced by the full-height sheet (SCR-21) | Sheet |
| 8.5 Export (share sheet) | Now preceded by the export dialog (SCR-26) | Dialog (form) |
| 8.6, 8.7 Restore | Confirm dialog gets the NEW switches note; password dialog added (SCR-27) | Dialog |
| 8.11, 9.2 Snackbars | Stacked variant; timer line on the 10-second variant | Snackbar |

Unchanged: 1.1–1.2 Lock, 8.1–8.4 PIN set-up, keypad (T2), period sheet and range calendar (2.4/2.5) apart from the background, About (9.1).

# Ví Gọn

**Ví Gọn** ("tidy wallet") is an offline personal expense tracker for Android and iPhone (Flutter, adaptive Material, portrait only). It has no account, no server and no network permission. This is the **v2 design system**, an upgrade of the approved v1 (`design/current/screens/`). The visual language is unchanged: same tokens, Be Vietnam Pro, Material Symbols Rounded and the two-stacked-cards logo. v2 adds the components and states the v1.1/v1.2 features need (brief v2, 2026-11-05).

> Scope of this round: **P1**, the 🆕 screens that were never drawn. Hi-fi frames live in `design/hifi/<platform>/<theme>/` (see *Frames* below). P2 (refreshing ✅ screens) and P3 (iOS proposals) come later. The **Changelog** section lists which existing screens P2 will touch.

## Principles

1. **Offline and private by design.** No sign-in, spinners or cloud wording. Every switch that affects privacy states its consequence in full, never truncated.
2. **Log an entry in ≤ 3 taps.** Ring icon → digits → Save; or − → digits → Choose category → tap = saved.
3. **Calm, compact finance UI.** Numbers are the hero. Colour is spare: category colours on the ring, red and green only for money direction, `error` only for problems.
4. **Thumb zone first.** − / +, the keypad, Save and sheet footers sit in the bottom half.
5. **Colour is never the only cue.** Income and expense carry a sign or word; over-budget has a word and an icon; status rows have an icon and text; selected items have a ✓.
6. **Forgiving.** A single record deletes with a 5-second Undo; bulk deletes always confirm; password dialogs always show the forget warning.

## Content

- Vietnamese is the default, English the second language, and both are first-class. Design in EN, then check VI on the tightest frames: VI strings run up to 2× longer ("Tất cả thời gian", "Nhắc ghi chép hằng ngày").
- Write short sentences that say what will happen: "Delete all data", not "Are you sure?". The cancel button is always "Cancel" / "Hủy". No emoji, no "I", no all-caps words.
- Money: VI `1.250.000 ₫` (non-breaking space before ₫), EN `₫1,250,000`; tabular figures; negative account balances `-₫85,000` in normal ink. Flat search lists add − / + because they mix income and expense.
- Every new string is marked **NEW** (dotted underline in the frames) and listed with EN + VI for both `.arb` files. P1 adds 12 keys; the full list is in `design/hifi/index.html`.

## Colour

All colours come from `tokens.json`, in light and dark.

- **Surfaces.** Screen `surface`; Settings group cards `surface-container-low` *(v2)*; sheets, menus and search fields `surface-container`; dialogs, the balance bar and digit keys `surface-container-high`.
- **Ink.** Main text `ink`; secondary text `ink-muted`. Both are ≥ 4.5:1 on every surface in both themes.
- **Brand.** `primary` `#2E7D6B` / `#8CD5BF` for switches, selected tabs, budget bars, group titles and filled buttons. `secondary-container` for tonal buttons, selected segments and chips. `primary-container` for the search-match highlight (always with weight 600).
- **Money.** `income` / `expense`, always with + / − or the word Thu / Chi. Text on their fills uses `on-income` / `on-expense`.
- **Problems.** `error` for text and icons; `error-container` + `on-error-container` *(v2)* for status strips. Destructive dialog buttons use an `error` fill.
- **Categories.** `cat-01…16`, the same in both themes, with `on-cat` white glyphs. Category colours are user data (an ARGB int in backups).
- **Brand and widget** *(v2)*: `brand-deep / mint / paper / dot` are for the logo only. `widget-*` are the fixed colours of the Android home-screen widget, which does not follow the app theme.
- **Don't**: `income` or `primary` as body text on `surface-container-high` in light theme (4.22 / 4.06:1), or `primary` body text on `surface-container` (4.34:1).

## Type: Be Vietnam Pro

Twelve styles map 1:1 to the Flutter `TextTheme` (unchanged in v2): `amount-xl` 40/48 for the amount being typed, `amount-md` 18/24 for totals, `title-lg/md/sm`, `body-md/sm`, `label-lg/md/sm`, `key-digit`, `key-glyph`. Amounts always use tabular figures. Text scales to **200 %** without clipping:

- At ≥ 130 %, amounts move under their row titles, segmented controls stack, button pairs wrap, the area above a keypad scrolls and dialog bodies scroll with actions pinned.
- App-bar titles wrap instead of ellipsizing.

## Space, size, shape

- Spacing `space-1…8` (4–32): screen margins 16, dialog padding 24, 24 between Settings groups and 12 between cards in a group.
- Touch targets: `tap-min` 48, `tap-key` 56 (keys, rows, balance bar), `tap-main` 64 (− / +, PIN keys), `row-two-line` 72 *(v2)*. Units are dp on Android and pt on iPhone.
- Radius: `radius-sm` 8 (chips, fields, snackbar), `md` 12 (keys, balance bar, widget buttons), `lg` 16 (− / +, FAB, Save, Settings cards), `xl` 28 (dialogs, sheet tops), `full`, and `radius-widget` 20 *(v2)*.
- Shadows only on things that float: `shadow-sheet`, `shadow-float`. Cards and rows have none.

## Layout

- **No tab bar.** One stack from Home. App-bar titles are left-aligned on both platforms, and every pushed screen or full-height sheet has a visible back or close button (iOS has no hardware Back).
- **Bottom sheets** are for choosing things and short forms. **Full-height sheets** (close ✕, pinned footer) replace dialogs that grew past three fields: Currency, Edit repeating record. **Dialogs** are for confirming and for one value or one password.
- **The snackbar** floats above the − / + buttons, the keypad and sheet footers. When the text runs past one line, the action moves under it.

## Components (v2 sheet)

Each component card shows **light and dark side by side** and its states: default, pressed, focused (2 dp `focus` ring), disabled (38 %), error, selected.

| Card | What's new in v2 |
|---|---|
| ActionButtons | Button family (filled, tonal, outlined, text, danger), button pair, FAB, Save key |
| Keypad | Unchanged; amount display states |
| Chips | Filter-chip pair for search scope, choice chips for Repeat |
| CategoryAvatar | ⋯ "More categories" slot: a dashed ring, never a filled disc |
| ChartRing | Labelled centre totals, total and **category** budget bars, balance bar with the period, period header |
| ListRows | Aligned amount column, category limit bar, search result row with highlight, collapsible section |
| SearchField | App-bar search field with clear button; scope chips; summary line |
| SettingsRows | Group card, segmented control, switch row with long subtitle, value row, **status row** (auto backup), pill |
| TextFields | Name, amount with currency, note with counter, password with visibility toggle |
| Sheets | Bottom sheet, full-height sheet with close and pinned footer |
| Dialogs | Normal, destructive, **form with password fields**, scroll at 200 % |
| Feedback | Snackbar (1 line, stacked, 10-second with timer), spinner, linear progress, button "Working" |
| PinPad | Dots and pad, error |
| CalendarMenu | Range calendar, menu |
| HomeWidget | Android widget 2 × 2 / 4 × 2, all status states |
| Notification | Android and iOS reminder notification, monochrome small icon |

## iPhone and Android

Layout, colour, type and icons are the same on both platforms. Only OS-owned behaviour differs: safe areas, back gesture, share and file pickers, the notification permission prompt and the keyboard. **Android-only** features are removed on iOS, not disabled: Hide content when switching apps, Show amounts on widget, Automatic backup, the widget and the monochrome icon. iOS Settings (SCR-33) is drawn without those rows.

## Frames

Folder `design/hifi/` holds:

- `<platform>/<theme>/<NN>_<slug>__<state>.png` + `.html`, where `platform` is `android` (360 × 800 dp) or `ios` (393 × 852 pt).
- VI and 200 % variants: Android, light.
- `index.html` (gallery), `assumptions.html`, `ideas.html` and `tokens/` (tokens.json, tokens.css, changelog, motion, icons).

Each frame's HTML shows the screen next to its notes, its ASSUMPTION markers (dark numbered pins), its NEW copy, the spoken labels and the flow it belongs to.

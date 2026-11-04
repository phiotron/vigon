# Ví Gọn — Product brief for Hi‑Fi UI design

> **What this file is for:** the brief to send to **Claude Design** to produce Hi‑Fi mockups (UX/UI optimised) for the
> mobile app **Ví Gọn** on **Android + iOS**. It says *what* each screen must do and *why*; *how it looks* is Claude
> Design's proposal, within the limits in §2 and §10.
>
> **Direction: UPGRADE, not redesign.** Start from the approved design system "Ví Gọn" (tokens, components and frames
> in `design/current/screens/`, attached). Keep its structure, colours, type and component vocabulary; polish hierarchy,
> spacing, states, motion and the weak points in §8. Do **not** add features: scope is exactly the current spec
> (`docs/SPEC.md`, F‑01..F‑13 / AC‑01..AC‑43). Ideas outside that go to §9 only.
>
> Internal code `A002-vigon` · Bundle ID `com.phiotron.vigon` · Version 1.0 · Date 2026‑11‑04
> Glossary: `CONTEXT.md` (Entry, Category, Account, Transfer, Period, Recurring series, Budget, Backup…).
> All UI copy below is the real copy from `lib/l10n/app_en.arb` and `app_vi.arb`. Where a design needs **new** copy,
> mark it `NEW:` in the mockup so the developer adds it to both `.arb` files.

---

## Contents
1. Product overview
2. Design constraints
3. Business rules the designer must know
4. Information architecture and navigation
5. Screens and dialogs (SCR‑01 … SCR‑27)
6. Key flows
7. Sample data for mockups
8. Known UX weak points → design opportunities
9. Out of scope / Future
10. Deliverables requested from Claude Design

---

## 1. Product overview

### 1.1 One line
**Ví Gọn** ("tidy wallet") — record income and expenses in seconds and see at a glance where the money went, by
category. Fully offline, no account, no data collection.

### 1.2 Problem
People who want to know where their money goes each month give up on tracking because apps take too many steps, ask for
an account, or send data to a server. They fall back to paper, phone notes or spreadsheets and never get a summary.
Ví Gọn logs an expense in a few seconds and immediately shows spending by category.

### 1.3 Target users (personas)

| Persona | Situation | What they need from the UI |
|---|---|---|
| **Linh, 27, office worker (HCMC)** | Pays for lunch, coffee, ride-hailing several times a day; logs right after paying, standing at the counter, **one hand**, often weak signal | Open → tap category → type amount → Save. Thumb-reachable controls, big keypad, no typing on the system keyboard |
| **Minh, 20, student** | Small budget, wants to stay under a monthly limit | Monthly budget bar that is honest and calm, "Over by X" clearly stated |
| **Cô Hạnh, 52, keeps the family's market money** | Not tech-savvy; Vietnamese only; often uses large system text | Large tap targets, readable at 200 % text, plain words, no hidden gestures as the only path |
| **Alex, 34, expat (EN)** | Uses USD or another currency, English UI, several accounts (cash, card, e‑wallet) | Account filter, transfers between accounts, correct currency format |

### 1.4 Core jobs (in priority order)
1. **Log an expense right after paying** — the reason the app exists.
2. **See where money went this period** — donut chart by category, totals, balance.
3. **Fix mistakes** — edit or delete a record, with undo.
4. **Stay within a monthly budget.**
5. **Keep data safe** — export a backup file, restore it, export CSV; optional PIN lock.
6. **Set up once** — categories, accounts, currency, week/month start, repeating records.

### 1.5 Design principles
1. **Offline & private by design.** No sign‑in, no cloud, no spinners for network, no "sync" anything. The UI should
   quietly reassure ("Your data is stored only on this phone"), never nag.
2. **Log an entry in ≤ 3 taps** (AC‑02), not counting digit taps. Fastest path: Home → category icon → digits → **Save**
   (2 taps). Every design decision on Home and the Entry editor is judged against this.
3. **Calm, compact finance UI.** Numbers are the hero; colour is used sparingly (income green, expense red, category
   colours on the ring). No gamification, no alarming red walls, no dark patterns.
4. **Thumb zone first.** Primary actions (− / +, keypad, Save) live in the bottom half of the screen (AC‑37).
5. **Never rely on colour alone.** Income/expense always carry a sign or a word; "over budget" always has text + icon.
6. **Forgiving.** Single records delete instantly with a 5‑second Undo; destructive bulk actions (delete category,
   delete all data, restore) always confirm.
7. **Same app on both platforms.** One layout; only OS‑owned behaviour differs (§2.2).

---

## 2. Design constraints

### 2.1 Platforms, frames, orientation
- **Android** (Material 3) and **iOS** (adaptive Material, not Cupertino widgets). One shared layout.
- **Base frames:** Android **360 × 800 dp** (smallest supported width; AC "min width 360 dp") and iPhone 15/16
  **393 × 852 pt**. Design at these sizes; the layout must also hold at 412 × 915 (common large Android).
- **Portrait only** (locked on both platforms). No tablet/landscape layouts.
- **Safe areas:** status bar, Android gesture bar (edge‑to‑edge), iPhone Dynamic Island and Home indicator. Bottom
  buttons and keypad sit above the Home indicator / gesture bar.

### 2.2 Platform differences (only where the OS decides)

| Topic | iPhone | Android |
|---|---|---|
| Back | Visible back arrow in app bar **+ swipe from left edge** (Cupertino page transition). No hardware back, so **every pushed screen and full-screen dialog needs a visible back/close control** | Back arrow + system Back button/gesture, predictive back |
| Exit app | No exit control (Home gesture) | Back on Home exits |
| Share backup / CSV | iOS share sheet (`UIActivityViewController`) | Android Sharesheet |
| Pick a file to restore | Files app document picker (`UIDocumentPicker`) | System file picker (SAF) |
| PIN hash storage | Keychain | Keystore |
| Haptics | Light haptic on wrong PIN and on delete | Same |
| Screen reader | VoiceOver | TalkBack |
| App bar title | **Left-aligned on both** (override iOS centring) | Left-aligned |
| Date picker (single date) | Material date picker on both, for consistency | Material |
| Custom range picker | App's own calendar inside a bottom sheet (already approved) | Same |

Show the OS share sheet and document picker as **system chrome placeholders** in the flow frames — do not design them.

### 2.3 Theme and visual starting point
- **Light, Dark, System** (AC‑35). Every frame in both themes.
- Start from `design/current/screens/tokens.json` (source of truth): primary `#2E7D6B` / dark `#8CD5BF`, income
  `#2E7D32` / `#81C784`, expense `#C62828` / `#EF9A9A`, error `#BA1A1A` / `#FFB4AB`, surfaces `#F7FAF8` …, 16 category
  colours. Type **Be Vietnam Pro** (full Vietnamese diacritics; bundled, no runtime download) with **tabular figures for
  every amount**. Icons **Material Symbols Rounded** (filled for category icons, outlined for actions).
- You may refine tokens (e.g. surface steps, elevation, ring stroke), but **keep token names** so the developer can map
  them to Flutter `ColorScheme` + a `ThemeExtension` (§10.3). Contrast must stay ≥ 4.5:1 text / 3:1 large text & icons
  in both themes (AC‑40). Two known failing pairs in light theme — don't use: `income` text on
  `surface-container-high` (4.22:1), `primary` text on `surface-container-high` (4.06:1).
- **Category colours and icons are stored in user data** (colour as an ARGB int, icon as a string key, and both are in
  backup files). You may restyle the *glyph* but each of the 31 icon keys and 16 colour slots must map 1:1 to a design
  (list in §3.6). If you want to change a colour value, give an explicit old → new mapping.
- **Brand (D‑009):** logo "two stacked cards" — background `#0E5244`; back card `#8CD5BF` rotated −14°; front card
  `#F7FAF8` rotated +8°, large radius; lines `#0E5244` (long) and `#0E5244` at 35 % (short); round dot `#E65100`;
  wordmark Be Vietnam Pro 600/700. The app icon is final (`store/brand/icon-512.png`); use the wordmark/logo only where
  it helps (About, Lock screen). Do **not** use coins, $, piggy banks, wallets with flaps, leaves or a donut as the logo.
- **No tab bar.** Navigation is a stack from Home (see §4). Do not add a `NavigationBar`.

### 2.4 Accessibility (WCAG 2.2 AA target)
- **Touch targets ≥ 48 × 48 dp / 44 × 44 pt minimum**; tokens already use 48 (`tap-min`), 56 (`tap-key`: keypad keys,
  list rows, balance bar), 64 (`tap-main`: − / + buttons, PIN keys).
- **Text scale up to 200 %** without clipping or overlap (AC‑38). Design 200 % variants for: Home, Entry editor,
  Entries list, Settings, Lock screen (§10). Current rules at ≥ 130 %: amounts move under the row title, 3‑option
  segmented controls stack vertically, the area above the keypad scrolls while the keypad stays pinned.
- Every control has a spoken label (listed per screen). Charts have a text alternative. Live regions for the amount
  being typed and PIN progress.
- Visible 2 px focus ring (`focus` token) for keyboard / switch access.

### 2.5 Languages and copy length
- **Vietnamese (default) and English**, follows the device by default, switchable in Settings (AC‑36). App name
  "Ví Gọn" is the same in both languages.
- **Design in English, then check Vietnamese** on the tight screens (Home, Entry editor, Settings, Entries, Lock,
  dialogs). VI is usually 30–100 % longer for short labels. Longest/riskiest VI strings:

| Key | EN | VI (longest) | Where it bites |
|---|---|---|---|
| `forgotPinBody` | Ví Gọn has no server, so a PIN cannot be recovered. You can delete all data in the app to use it again. | Ví Gọn không có máy chủ nên không lấy lại được mã PIN. Bạn có thể xóa toàn bộ dữ liệu trong app để dùng lại. | Forgot‑PIN dialog |
| `currencyNote` | Changing the currency only changes the symbol; … switching back may lose the fractional part. (≈ 280 chars) | Đổi tiền tệ chỉ đổi ký hiệu, không quy đổi tỉ giá. Nếu hai tiền tệ có số chữ số thập phân khác nhau (ví dụ VND và USD), số tiền được nhân hoặc chia để giữ nguyên con số; đổi ngược lại có thể mất phần lẻ. | Currency picker header |
| `pinWarning` | If you forget the PIN, the only way back in is to delete all data in the app. | Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong app. | Settings switch subtitle, PIN setup |
| `restoreFailed` | The file is invalid or damaged. Your data was not changed. | File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi. | Snackbar (2 lines) |
| `backupReminder` | Data is stored only on this phone. Export a backup regularly. | Dữ liệu chỉ nằm trên máy này. Nên xuất bản sao lưu thường xuyên. | Settings Data header |
| `restoreConfirm` | Your current data will be replaced by the backup. Continue? | Dữ liệu hiện tại sẽ bị thay thế bằng bản sao lưu. Tiếp tục? | Dialog |
| `deleteAllConfirm` | Delete all records, categories, accounts and settings on this phone? | Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy này? | Dialog |
| `privacyPolicy` | Privacy policy | Chính sách quyền riêng tư | About row |
| `restore` | Restore from backup | Khôi phục từ bản sao lưu | Settings row |
| `monthStartDay` | Month starts on day | Tháng bắt đầu từ ngày | Settings row + trailing dropdown |
| `allAccounts` | All accounts | Tất cả tài khoản | Account filter |
| `periodCustom` | Custom range | Khoảng tùy chọn | Period sheet |
| `themeSystem` | System | Theo hệ thống | 3‑way segmented control (fits?) |
| `emptyPeriod` | Tap − to record your first expense | Bấm − để ghi khoản chi đầu tiên | Inside the ring area |
| `noRecurring` | No repeating records yet. Turn on Repeat when adding a record. | Chưa có khoản định kỳ. Bật Lặp lại khi ghi khoản. | Empty state |
| `stopRepeat` / `repeatMonthly` | Stop repeating / Monthly | Dừng lặp lại / Hằng tháng | Chips in editor |
| `undo` | Undo | Hoàn tác | Snackbar action |
| Period title (week) | Nov 2 – Nov 8, 2026 | 2 thg 11 – 8 thg 11, 2026 | Period header between ‹ › |

### 2.6 Number, currency and date formatting
- One currency for the whole app (ISO 4217, 31 codes, default from device region; Vietnam → VND). No exchange rates.
- Money is an integer of minor units; display follows the **UI language**:
  - VI: `1.250.000 ₫` — dot thousands, symbol **after**, non‑breaking space. USD in VI: `1.250,00 $` (symbol from the
    `intl` simple‑currency table; some codes have no symbol and show the code, e.g. `CHF`).
  - EN: `₫1,250,000` — comma thousands, symbol **before**. USD in EN: `$1,250.00`.
  - Negative: leading `-` (`-200.000 ₫`, e.g. account balance).
- **Large numbers:** max single amount = 10¹² minor units → VI `1.000.000.000.000 ₫` (19 chars), EN `₫1,000,000,000,000`;
  USD `$10,000,000,000.00`. Period totals for "All time" can exceed that. Amount text must **shrink to fit**
  (typing display) or wrap/ellipsize gracefully (lists, ring centre) — design these cases.
- Percent: one decimal — VI `53,7%`, EN `53.7%`; a section always sums to 100.0.
- Short date: VI `3 thg 11, 2026`, EN `Nov 3, 2026`; today shows **Today / Hôm nay**.
- Period titles: Day `Tue, Nov 3, 2026` (VI similar, capitalised); Week `Nov 2 – Nov 8, 2026`; Month starting on day 1
  `November 2026` / `Tháng 11 năm 2026`; Month starting on another day → a date range; Year `2026`; All time `All time` /
  `Tất cả`; Custom → date range.

---

## 3. Business rules the designer must know

1. **Entry** = one income or expense record: amount > 0, category, account, date (default today), optional note
   (≤ 200 chars). Type (income/expense) cannot be changed after saving.
2. **Transfer** = moving money between two accounts. It is **not** income or expense; it never appears in the ring,
   totals or budget. It shows in its own "Transfer" section of the Entries list and changes account balances.
3. **Two different "balances"** (important for labels):
   - **Period balance** on Home and Entries = income − expense **of the selected period** (ignores transfers).
   - **Account balance** on Accounts = starting balance + income − expense ± transfers, all time.
4. **Period** = Day / Week / Month / Year / All time / Custom range. Default = the month containing today. Week start
   (Monday/Sunday) and month start day (1–28) come from Settings. The selected period and account filter live only in
   memory (reset on app restart).
5. **Account filter** (only when ≥ 2 accounts): Home and Entries show only records of one account; a transfer counts if
   that account is source or destination.
6. **Ring icons** = expense categories in the user's sort order, placed around the ring; tapping one opens a new expense
   with that category pre‑selected. Income is recorded only via **+**.
   - Default expense categories (10): Food, Transport, Home, Bills, Shopping, Health, Entertainment, Education, Family,
     Other. Income (3): Salary, Bonus, Other income.
   - The 31 category icon keys (stored): restaurant, local_cafe, local_grocery_store, directions_bus,
     local_gas_station, two_wheeler, home, receipt_long, bolt, wifi, phone_android, shopping_bag, checkroom,
     medical_services, fitness_center, movie, sports_esports, flight, school, menu_book, family_restroom, child_care,
     pets, card_giftcard, volunteer_activism, payments, redeem, savings, trending_up, work, more_horiz.
   - The 16 category colour slots (stored ARGB): `#C62828 #AD1457 #6A1B9A #4527A0 #283593 #1565C0 #0277BD #00838F
     #00695C #2E7D32 #558B2F #E65100 #BF360C #5D4037 #455A64 #616161`. Icons on them are always white.
     *(Note: `design/current` tokens list a slightly different palette/defaults — see §8 item 14.)*
7. **Repeating record (recurring series):** created only from the New‑entry editor by setting Repeat to
   Daily/Weekly/Monthly/Yearly. When the app opens or returns to foreground, all due records up to today are generated
   (no duplicates, no background job). Stopping or editing a series never changes records already generated. Resuming
   continues from today (no back‑fill). Only amount and note of a series are editable.
8. **Monthly budget:** one total limit for the current month (by month start day), all accounts, independent of the
   period being viewed. Over 100 % → "Over by X" + warning style.
9. **Delete:** a single record (or transfer) deletes immediately, with a **"Deleted · Undo" snackbar for 5 s**.
   Deleting a category requires choosing another category of the same type to receive its records (the last category of
   a type can't be deleted). Accounts cannot be deleted in v1.
10. **Backup** = a `.vigon` file (JSON, not encrypted, no PIN inside) shared via the OS share sheet. **Restore** checks
    the file first; a bad file shows an error and changes nothing; a good file asks for confirmation then **replaces
    all data** in one transaction. **CSV export** = UTF‑8 with BOM for Excel.
11. **PIN lock:** optional 4‑digit PIN; asked on cold start and when returning after > 1 minute in background. No server
    → a forgotten PIN can only be cleared by deleting all data (two extra confirmations). Wrong attempts are unlimited
    and not delayed (v1).
12. **Currency change** only swaps the symbol; if decimal places differ (VND 0, USD 2) amounts are scaled so the visible
    numbers stay the same; switching back may lose fractions.

---

## 4. Information architecture and navigation

### 4.1 Routes (one stack, all children of `/`)

| Route | Screen | Params | SCR |
|---|---|---|---|
| `/` | Home | — | SCR‑01 |
| `/entry/new` | New entry (expense or income) | `type=expense\|income` (default expense), `category=<id>` (pre‑selected) | SCR‑05 |
| `/entry/:id` | Edit / delete an income or expense | `id` | SCR‑06 |
| `/entries` | Entries list for current period + account filter | — | SCR‑10 |
| `/settings` | Settings | — | SCR‑11 |
| `/categories` | Categories (Expense / Income tabs) | — | SCR‑14 |
| `/accounts` | Accounts | — | SCR‑16 |
| `/transfer` | New transfer | — | SCR‑18 |
| `/transfer/:id` | Edit / delete a transfer | `id` | SCR‑18 |
| `/recurring` | Repeating records | — | SCR‑19 |
| `/about` | About | — | SCR‑21 |
| *(overlay, outside router)* | Lock screen | — | SCR‑22 |

### 4.2 Navigation map

```
App start ──► [Lock screen SCR-22] (if PIN on) ──correct PIN──► Home
                 └─ Forgot PIN ─► 3 dialogs (SCR-24) ─► Home (fresh data)

Home "/" (SCR-01)
 ├─ [−] / [+] ─────────────────────► New entry /entry/new?type=… (SCR-05)
 │                                      ├─ Category sheet (SCR-07)  ├─ Date picker (SCR-09)
 │                                      ├─ Repeat sheet (SCR-08a)   └─ Account sheet (SCR-08b)
 ├─ category icon around ring ─────► New expense, category pre-selected
 ├─ period title ──────────────────► Period sheet (SCR-02) ─► Custom range calendar
 ├─ ‹ › / horizontal swipe ────────► previous / next period (same screen)
 ├─ budget bar ────────────────────► Budget dialog (SCR-04)
 ├─ balance bar / list icon ───────► Entries /entries (SCR-10)
 │                                      └─ tap row ─► Edit entry /entry/:id (SCR-06) or /transfer/:id (SCR-18)
 ├─ wallet icon (≥ 2 accounts) ────► Account filter menu (SCR-03)
 └─ gear ──────────────────────────► Settings /settings (SCR-11)
       ├─ Categories ─► /categories (SCR-14) ─► Add/Edit sheet (SCR-15) ─► Delete + move dialog
       ├─ Accounts ───► /accounts (SCR-16) ─► Add/Edit sheet (SCR-17)
       │                   └─ ⇄ (≥ 2 accounts) ─► Transfer /transfer (SCR-18)
       ├─ Monthly budget ─► Budget dialog (SCR-04)
       ├─ Repeating records ─► /recurring (SCR-19) ─► Edit series dialog (SCR-20)
       ├─ Currency ─► Currency picker (SCR-12)
       ├─ First day of week ─► toggles Monday/Sunday
       ├─ Month starts on day ─► 1–28 menu (SCR-13)
       ├─ Lock with PIN ─► PIN setup / PIN check (SCR-23)
       ├─ Export backup / Export CSV ─► OS share sheet (SCR-25)
       ├─ Restore from backup ─► OS file picker ─► confirm (SCR-25)
       ├─ Delete all data ─► 2 dialogs (SCR-26)
       └─ About ─► /about (SCR-21)
```

Back from any screen returns to the previous one; Back on Home exits (Android).

---

## 5. Screens and dialogs

Format per screen: **Purpose · Entry points · Components · Data · States · Interactions · Copy (EN | VI) ·
Accessibility**. "Existing frame" refers to the approved frames in `design/current/screens/` (numbers like 2.1).
Copy tables list each string once; placeholders in `{braces}`.

### SCR‑01 · Home — `/`
**Existing frames:** 2.1 data, 2.2 over budget, 2.3 empty (`S02_ManChinh`).
**Purpose:** see where money went in the selected period and start a new record in one tap (F‑01, F‑02, F‑09).

**Components (top → bottom):**
1. **App bar:** title "Ví Gọn" (left). Actions: wallet icon **account filter** (only if ≥ 2 accounts) · list icon
   **Records** → `/entries` · gear **Settings** → `/settings`.
2. **Period header:** ‹ previous · period title (tap → period sheet, min height 48) · › next.
3. **Budget bar** (only when a budget is set): one line of text + 8 dp progress bar. Tap → budget dialog.
4. **Chart area** (fills remaining space; horizontal swipe changes period):
   - Donut ring: one arc per expense category of the period, in the category colour, largest first, from 12 o'clock.
   - Centre: total **income** (green, with "+"/label) then total **expense** (red, with "−"/label).
   - Expense category icons (48 dp circles, category colour, white glyph) evenly spaced around the ring, in user sort
     order. Only as many as fit the circumference are shown (see §8 item 1).
5. **Balance bar** (56 dp, `surface-container-high`, chevron ›): "Balance: X" (period balance). Tap → Entries.
6. **Two big buttons** (64 dp, thumb zone): **− Expense** (red, left) and **+ Income** (green, right). Approved design
   adds visible words next to the glyphs.

**Data:** period totals (income, expense, balance, excluding transfers), expense by category with % (sums to 100.0),
budget spent/limit for current month, accounts list (for filter), active filter.

**States to design:**
| State | What shows |
|---|---|
| Default with data | Ring + icons + totals (sample data §7) |
| **Empty period** | No ring; centred message "Tap − to record your first expense" (make it friendly, point to −) — icons still around for quick entry (current code keeps icons) |
| Income only, no expense | Ring is a full green circle |
| Budget under limit | "Monthly budget: Spent X of Y", primary‑colour bar |
| Budget ≥ 100 % | Error colour, bold, warning icon, full bar, "Monthly budget: Over by X" |
| No budget set | Budget bar hidden |
| One account only | No wallet icon |
| Account filter active | Wallet icon + **visible indicator of the filtered account name** (currently tooltip only — §8 item 2) |
| **> 10 expense categories** (e.g. 16) | More categories than fit around the ring at 360 dp — design the overflow (§8 item 1) |
| Long category names | Names are not shown under ring icons; tooltip on long‑press shows the name (any length up to 50 chars) |
| Large numbers | Centre totals up to `1.000.000.000.000 ₫` and more for "All time" — must fit inside the ring hole (scale down) |
| Text 200 % | Ring shrinks; header, budget text, balance bar, buttons must not clip |
| Day / Week / Year / All time / Custom titles | Long VI week range "2 thg 11 – 8 thg 11, 2026" between arrows |
| "All time" | ‹ › do nothing — show them disabled |
| Loading | Data streams from local DB: first frame can be empty for a few ms. Use a neutral skeleton or nothing — **no network spinner** |

**Interactions:** tap −/+ → `/entry/new?type=expense|income`; tap ring icon → `/entry/new?type=expense&category=id`;
long‑press ring icon → tooltip name; swipe left → next period, swipe right → previous (min velocity); tap period title →
SCR‑02; tap budget bar → SCR‑04; tap balance bar → `/entries`; wallet → SCR‑03.

**Copy:**
| Element | EN | VI |
|---|---|---|
| Title | Ví Gọn | Ví Gọn |
| Wallet tooltip | Account / Account: {name} | Tài khoản / Tài khoản: {name} |
| List icon | Records | Các khoản |
| Gear | Settings | Cài đặt |
| Arrows | Previous period / Next period | Kỳ trước / Kỳ sau |
| Period title hint | Choose period | Chọn kỳ xem |
| Centre labels | Income / Expenses | Thu / Chi |
| Budget | Monthly budget: Spent {spent} of {limit} | Ngân sách tháng: Đã chi {spent} / {limit} |
| Budget over | Monthly budget: Over by {amount} | Ngân sách tháng: Vượt {amount} |
| Balance bar | Balance: {amount} | Số dư: {amount} |
| Buttons (tooltips) | Add expense / Add income | Thêm khoản chi / Thêm khoản thu |
| Button visible words | NEW: Expense / Income (suggest reuse `income`; `expense` is "Expenses") | Chi / Thu |
| Empty | Tap − to record your first expense | Bấm − để ghi khoản chi đầu tiên |

**Accessibility:** chart = one sentence "Expenses by category: Home, ₫3,500,000, 29.7%; Food, …" (no per‑arc focus).
Ring icon label "Add expense: Food, ₫3,240,000, 27.5%" or "Add expense: Education, no records". Budget bar reads the
whole status sentence. Period title is a button with hint "Choose period".

---

### SCR‑02 · Period sheet + custom range calendar (bottom sheet on Home)
**Existing frames:** 2.4, 2.5 (`S03_ChonKy`).
**Purpose:** choose the period type (F‑03).
**Components:** drag handle; 6 rows **Day, Week, Month, Year, All time, Custom range**; selected row highlighted
(`primary-container`) with ✓. Choosing a type jumps to the period of that type **containing today**. "Custom range" opens
the app's own **range calendar in a bottom sheet** (start/end circles in primary, range fill primary‑container, today
outlined; years 2000 → current+10; default = range being viewed; reversed picks auto‑swap; Cancel keeps old period).
**States:** each type selected; custom range mid‑selection (only start chosen); range across months; VI labels.
**Copy:** Day/Ngày · Week/Tuần · Month/Tháng · Year/Năm · All time/Tất cả · Custom range/Khoảng tùy chọn · the sheet
has no title today (optional: reuse "Choose period"/"Chọn kỳ xem") · Cancel/Hủy · Save/Lưu (calendar confirm — or NEW:
"Apply" if you prefer).
**A11y:** rows are radio‑like, selected state announced; calendar days have full date labels.

### SCR‑03 · Account filter menu (on Home)
**Existing frame:** 2.6.
**Purpose:** limit Home and Entries to one account (AC‑20).
**Components:** menu anchored to the wallet icon: "All accounts" + each account name; current choice marked.
**States:** 2 accounts; 6 accounts (scroll); long name "Tài khoản tiết kiệm gia đình" / 50 chars (ellipsis);
filter active indicator on Home (§8 item 2).
**Copy:** All accounts / Tất cả tài khoản; account names (default "Cash"/"Tiền mặt").
**A11y:** wallet button label "Account" or "Account: {name}".

### SCR‑04 · Monthly budget dialog
**Existing frames:** 5.3, 5.4 (`S09_NganSachTienTe`).
**Purpose:** set/remove one monthly spending limit (F‑09). Opened from Home budget bar or Settings.
**Components:** title; amount field (numeric keyboard, autofocus); buttons **Remove budget** (only when set, left,
destructive‑text), **Cancel**, **Save**.
**States:** empty; prefilled; error "Amount must be greater than 0"; VI.
**Copy:** Monthly budget/Ngân sách tháng · Remove budget/Bỏ ngân sách · Cancel/Hủy · Save/Lưu · Amount must be greater
than 0/Số tiền phải lớn hơn 0.
**A11y:** error announced; field labelled with currency.

### SCR‑05 · Entry editor + keypad — `/entry/new`
**Existing frames:** 3.1–3.8 (`S04_GhiKhoan`, `S05_TuyChonGhi`), keypad `T2_BanPhim`.
**Purpose:** record a new expense or income as fast as possible (F‑01, F‑08).

**Components:**
1. App bar: back arrow; title "New expense" / "New income".
2. **Amount display** (live region): small line = expression being typed (`120+35`, ellipsized at start if long), big
   line = evaluated, formatted amount (`155.000 ₫`), red for expense / green for income, **auto‑shrinks to fit**; error
   line in red beneath when invalid.
3. **Chip row** (wraps): **Category** chip (icon + name; only after a category is chosen) · **Date** chip ("Today" or
   short date) · **Repeat** chip ("Does not repeat"/Daily/…; new entries only) · **Account** chip (only if ≥ 2
   accounts; default = first account).
4. **Note** field: hint "Note", max 200 with counter, keyboard action "Done".
5. Upper part scrolls when space is short (large text); **keypad pinned to the bottom**.
6. **Keypad** (5 rows, keys ≥ 56 dp, 8 dp gaps):
   ```
    7    8    9    ÷
    4    5    6    ×
    1    2    3    −
   000   0    ⌫    +      ("000" for zero-decimal currencies like VND; "." for USD etc.)
    =   [     Save / Choose category     ]
   ```
   Operator keys use `secondary-container`. The wide action key reads **Choose category** until a category is chosen,
   then **Save**; colour = expense red or income green, text `on-expense` / `on-income`.

**Rules:** max 30 typed chars; result ≤ 10¹² minor units; two operators in a row → the second replaces the first;
cannot start with an operator; `⌫` deletes last char; `=` replaces the expression with its result (if valid and > 0);
× ÷ before + −; result rounded to the currency's minor unit.

**Save logic:** validate amount → if no category, open the category sheet (closing it without choosing = no save) →
after choosing, the key becomes **Save** → tap Save → write → close screen → Home updates.

**States:**
| State | Notes |
|---|---|
| Fresh expense (no category) | Amount `0 ₫`, action key "Choose category" |
| Pre‑selected category (from ring icon) | Category chip visible, action key "Save" |
| Typing expression | `120+35` above `155.000 ₫` |
| Invalid expression (`5+`, overflow) | "Invalid calculation" in red under amount |
| Zero / negative | "Amount must be greater than 0" |
| New income | Green accents, income categories |
| Repeat chosen | Repeat chip shows "Monthly" |
| ≥ 2 accounts | Account chip visible |
| Long note (200 chars), long category name (50) | Chip ellipsis; note field grows ≤ 3 lines then scrolls |
| Huge amount | `1.000.000.000.000 ₫` shrinks to fit 360 dp width |
| Text 200 % | Top scrolls, keypad stays ≥ 56 dp, labels don't clip |
| USD currency | "." key instead of "000"; `$1,250.00` |

**Copy:**
| Element | EN | VI |
|---|---|---|
| Titles | New expense / New income | Khoản chi mới / Khoản thu mới |
| Action key | Choose category / Save | Chọn danh mục / Lưu |
| Date chip | Today / {short date} | Hôm nay / {ngày ngắn} |
| Repeat chip | Does not repeat · Daily · Weekly · Monthly · Yearly | Không lặp · Hằng ngày · Hằng tuần · Hằng tháng · Hằng năm |
| Repeat sheet title | Repeat | Lặp lại |
| Account sheet title | Account | Tài khoản |
| Note | Note | Ghi chú |
| Errors | Invalid calculation · Amount must be greater than 0 | Phép tính không hợp lệ · Số tiền phải lớn hơn 0 |

**A11y:** amount display is a live region (re‑read on change); keys "Backspace"/"Xóa lùi", "Equals"/"Bằng", operator
names; chips are buttons with their current value.

### SCR‑06 · Edit entry — `/entry/:id`
**Existing frames:** 4.5–4.7 (`S07_SuaKhoan`).
**Purpose:** change or delete an existing income/expense (F‑04).
**Differences from SCR‑05:** title "Edit record"; trash icon "Delete" in app bar; all fields prefilled (amount shown as a
simple expression); type cannot change; **no Repeat chooser** — if the record belongs to a running series, show the
series frequency chip with a ⏹ **Stop repeating** control; after stopping, the chip shows "Stopped" (snackbar "Stopped").
**States:** loading (centred progress while the record loads — very brief); record no longer exists → screen closes
itself; part of running series; part of stopped series; transfer records open SCR‑18 instead.
**Interactions:** Save → update in place, close; Delete → delete immediately, close, show "Deleted · Undo" (5 s) on the
previous screen.
**Copy:** Edit record/Sửa khoản · Delete/Xóa · Stop repeating/Dừng lặp lại · Stopped/Đã dừng · Deleted/Đã xóa ·
Undo/Hoàn tác.
**A11y:** trash button "Delete"; stop control "Stop repeating".

### SCR‑07 · Category sheet (in entry editor)
**Existing frame:** 3.3.
**Purpose:** pick the category for the current entry type.
**Components:** title "Choose category"; grid of 48 dp category circles + name (`label-sm`, max 2 lines), cells ≤ 96 dp
wide; tap = select and close (does **not** save).
**States:** 10 expense defaults; 3 income defaults; **16+ categories** (scrolls; sheet max height); long names (2‑line
ellipsis); selected category marked.
**Copy:** Choose category/Chọn danh mục; default names EN Food, Transport, Home, Bills, Shopping, Health,
Entertainment, Education, Family, Other; Salary, Bonus, Other income — VI Ăn uống, Đi lại, Nhà cửa, Hóa đơn, Mua sắm,
Sức khỏe, Giải trí, Giáo dục, Gia đình, Khác; Lương, Thưởng, Thu khác.
**A11y:** each cell = button with category name; selected state.

### SCR‑08 · Repeat sheet (a) and Account sheet (b)
**Existing frames:** 3.5, 3.6.
(a) 5 rows: Does not repeat, Daily, Weekly, Monthly, Yearly; ✓ on current. (b) list of accounts; ✓ on current; long
names ellipsize. Both bottom sheets with handle. Copy as in SCR‑05.

### SCR‑09 · Date picker (entry and transfer)
Material single‑date picker on both platforms, range 2000‑01‑01 → current year + 10 (an older stored date is allowed).
Restyle with tokens only. Copy: Cancel/Hủy, OK (system).

### SCR‑10 · Entries list — `/entries`
**Existing frames:** 4.1–4.4 (`S06_CacKhoan`).
**Purpose:** see every record in the period, grouped by category, with totals and % (AC‑08); edit or delete.
**Components:**
1. App bar: back; title = current period title (same format as Home).
2. **Balance** row (large): "Balance" + amount (amount moves below at ≥ 130 % text).
3. Divider.
4. **Expenses** section (if any): section total (red) then each expense category, sorted by total desc. Category row:
   40 dp avatar · name + percent ("53.7%") · total + chevron ⌄/⌃. Tap → expand/collapse its records (newest first).
5. **Income** section (if any): same, green.
6. **Transfer** section (if any): flat list of transfers labelled "{from} → {to}".
7. 24 dp bottom padding.
- **Record row:** title = note, or category name if no note; subtitle = short date; amount right (moves to subtitle line
  at large text). Tap → `/entry/:id` or `/transfer/:id`. **Swipe left → delete** immediately (`swipe-delete` background
  + trash icon), then "Deleted · Undo" 5 s.
**Data:** respects Home's period and account filter. Expand/collapse state is per visit.
**States:** with data (several categories, one expanded); swipe in progress; undo snackbar; **empty** "No records in
this period"; only transfers; 5,000 records (lazy list; scroll perf); long notes (1 line ellipsis); large amounts;
16 categories; text 200 %; filtered by account (show which account — §8 item 2).
**Copy:** Balance/Số dư · Expenses/Chi · Income/Thu · Transfer/Chuyển tiền · {from} → {to} · No records in this
period/Kỳ này chưa có khoản nào · Deleted/Đã xóa · Undo/Hoàn tác.
**A11y:** category row announces name, amount, percent and expanded/collapsed; swipe‑to‑delete also needs a non‑gesture
path (tap → editor → Delete exists — keep it obvious); record row announces note/category, date, amount.

### SCR‑11 · Settings — `/settings`
**Existing frames:** 5.1, 5.2 (`S08_CaiDat`).
**Purpose:** all configuration and data actions in one scrolling list.
**Order and components:**
| # | Item | Control | Behaviour |
|---|---|---|---|
| 1 | **Theme** (group) | 3‑way segmented: System / Light / Dark | Instant; stacks vertically at ≥ 130 % |
| 2 | **Language** (group) | 3‑way: System / Tiếng Việt / English | Instant |
| 3 | Categories › | Nav row | → `/categories` |
| 4 | Accounts › | Nav row | → `/accounts` |
| 5 | Monthly budget | Row + subtitle "Not set" or amount | → SCR‑04 |
| 6 | Repeating records › | Nav row | → `/recurring` |
| 7 | Currency | Row + subtitle "VND · ₫" | → SCR‑12 |
| 8 | First day of week | Row + subtitle Monday/Sunday | **Each tap toggles** (§8 item 4) |
| 9 | Month starts on day | Row + trailing dropdown 1–28 | → SCR‑13 |
| 10 | **Security** (group) | | |
| 11 | Lock with PIN | Switch + warning subtitle | On → SCR‑23 setup; Off → SCR‑23 check |
| 12 | **Data** (group) + reminder line | | |
| 13 | Export backup | Row + subtitle "Backup files are not encrypted…" | SCR‑25 |
| 14 | Restore from backup | Row | SCR‑25 |
| 15 | Export CSV | Row | SCR‑25 |
| 16 | Delete all data | Row in error colour | SCR‑26 |
| 17 | divider, About › | Nav row | → `/about` |

**States:** top and bottom halves; PIN on/off; budget set/not set; VI (longest labels); text 200 %; dark.
**Copy:**
| EN | VI |
|---|---|
| Settings | Cài đặt |
| Theme · System · Light · Dark | Giao diện · Theo hệ thống · Sáng · Tối |
| Language · System · Tiếng Việt · English | Ngôn ngữ · Theo máy · Tiếng Việt · English |
| Categories · Accounts | Danh mục · Tài khoản |
| Monthly budget · Not set | Ngân sách tháng · Chưa đặt |
| Repeating records | Khoản định kỳ |
| Currency | Tiền tệ |
| First day of week · Monday · Sunday | Ngày đầu tuần · Thứ Hai · Chủ Nhật |
| Month starts on day | Tháng bắt đầu từ ngày |
| Security · Lock with PIN | Bảo mật · Khóa bằng mã PIN |
| If you forget the PIN, the only way back in is to delete all data in the app. | Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong app. |
| Data · Data is stored only on this phone. Export a backup regularly. | Dữ liệu · Dữ liệu chỉ nằm trên máy này. Nên xuất bản sao lưu thường xuyên. |
| Export backup · Backup files are not encrypted. Keep them somewhere safe. | Xuất bản sao lưu · File sao lưu không được mã hóa. Hãy cất ở nơi an toàn. |
| Restore from backup · Export CSV · Delete all data | Khôi phục từ bản sao lưu · Xuất CSV · Xóa toàn bộ dữ liệu |
| About | Giới thiệu |
**A11y:** segmented options are radios with selected state; switch announces on/off + warning; destructive row
announced normally (colour + position + wording).

### SCR‑12 · Currency picker
**Existing frame:** 5.5.
**Purpose:** choose the single app currency (F‑07).
**Components:** title "Currency"; explanatory note (long, see §2.5); list of 31 ISO codes (VND, USD, EUR, GBP, JPY, KRW,
CNY, TWD, HKD, SGD, THB, MYR, IDR, PHP, INR, AUD, NZD, CAD, CHF, SEK, NOK, DKK, PLN, CZK, HUF, TRY, BRL, MXN, ZAR, AED,
SAR), each with symbol; ✓ on current. Choosing applies immediately.
**States:** VND selected; scrolled to bottom; VI note (wraps 5–6 lines at 360 dp) — consider a full‑height sheet with the
note collapsible.
**Copy:** Currency/Tiền tệ; `currencyNote` (§2.5). Row format "{CODE} · {symbol}" (e.g. "USD · $"), or just "{CODE}" when the symbol equals the code.
**A11y:** rows are radios; note readable before the list.

### SCR‑13 · Month start day menu
**Existing frame:** 5.6. Dropdown/menu of 1–28 on the Settings row; current value marked; scrollable. Copy: Month starts
on day/Tháng bắt đầu từ ngày.

### SCR‑14 · Categories — `/categories`
**Existing frames:** 6.1 (`S10_DanhMuc`).
**Purpose:** add, edit, reorder categories (F‑05).
**Components:** app bar "Categories"; tabs **Expenses / Income** (tap or swipe); list rows: 40 dp avatar · name · drag
handle ☰ ("Drag to reorder"); FAB **+ Add category** (bottom right; list has 88 dp bottom padding).
**Interactions:** tap row → SCR‑15 edit; drag handle → reorder (saved instantly; order drives ring icons and grid);
FAB → SCR‑15 add for current tab.
**States:** defaults; 16+ categories (scroll); dragging state (lifted row); long name 50 chars; VI.
**Copy:** Categories/Danh mục · Expenses/Chi · Income/Thu · Add category/Thêm danh mục · Drag to reorder/Kéo để sắp xếp.
**A11y:** reorder must have a non‑drag alternative for screen readers (custom actions "Move up/Move down" — NEW copy).

### SCR‑15 · Category add/edit sheet + delete/move dialog
**Existing frames:** 6.2, 6.3.
**Sheet (keyboard‑aware):** title "Add category"/"Edit category"; **Name** field (≤ 50, autofocus on add; empty →
"Enter a name"); **Icon** grid (31 icons, selected one filled with the category colour); **Color** row/grid (16 swatches
48 dp, selected has ring + ✓); buttons **Delete category** (edit only, and only if ≥ 2 categories of this type) and
**Save**. Default categories keep their localized name unless the user renames them.
**Delete dialog:** title "Delete this category?"; line "{count} records will be moved to:"; list of other categories of
the same type; tapping one deletes the old category and moves its records **and repeating series** there. Cancel.
**States:** add (empty); edit default category; name error; keyboard open (sheet pushed up, Save still reachable);
delete with 0 / 37 records; only 2 categories left.
**Copy:** Add category/Thêm danh mục · Edit category/Sửa danh mục · Name/Tên · Enter a name/Nhập tên · Icon/Biểu tượng ·
Color/Màu · Delete category/Xóa danh mục · Save/Lưu · Delete this category?/Xóa danh mục này? · {count} records will be
moved to:/{count} khoản sẽ được chuyển sang: · Cancel/Hủy.
**A11y:** icons "Icon 1…31"/"Biểu tượng 1…31"; colours "Color N" + selected (NEW key for colours if missing).

### SCR‑16 · Accounts — `/accounts`
**Existing frame:** 6.4 (`S11_TaiKhoan`).
**Purpose:** list accounts with current balances; add/edit; entry to transfers (F‑06).
**Components:** app bar "Accounts" + ⇄ "Transfer" action (only if ≥ 2 accounts); rows: wallet icon · name · **account
balance** right (below name at large text; negative allowed, e.g. credit card); FAB **+ Add account**.
**States:** only "Cash"; 4 accounts incl. negative balance; long name; large balance; text 200 %.
**Copy:** Accounts/Tài khoản · Transfer/Chuyển tiền · Add account/Thêm tài khoản · Cash/Tiền mặt.
**Note:** no delete/hide for accounts in v1 — don't design one.

### SCR‑17 · Account add/edit sheet
**Existing frame:** 6.5.
**Components:** title "Add account"/"Edit account"; **Name** (≤ 50, "Enter a name"); **Starting balance** (numeric,
allows `-` and decimal, empty = 0; bad input → "Invalid calculation"); **Save**.
**Copy:** Add account/Thêm tài khoản · Edit account/Sửa tài khoản · Name/Tên · Starting balance/Số dư ban đầu · Save/Lưu.

### SCR‑18 · Transfer — `/transfer`, `/transfer/:id`
**Existing frames:** 6.6, 6.7.
**Purpose:** move money between two accounts (AC‑19). Only reachable with ≥ 2 accounts.
**Components:** app bar "Transfer" (+ trash "Delete" when editing); **From** and **To** account selectors stacked
vertically (approved change, so long names fit); big amount display (as SCR‑05); date chip; note (≤ 200); same keypad
with action key **Save** in `primary`.
**States:** new (defaults: 1st and 2nd account); same account error "Choose two different accounts"; amount error;
edit with delete; long account names; text 200 %.
**Copy:** Transfer/Chuyển tiền · From/Từ · To/Đến · Save/Lưu · Delete/Xóa · Choose two different accounts/Chọn hai tài
khoản khác nhau · Amount must be greater than 0/Số tiền phải lớn hơn 0.

### SCR‑19 · Repeating records — `/recurring`
**Existing frames:** 7.1, 7.3 (`S12_DinhKy`).
**Purpose:** see and control repeating series (F‑08).
**Components:** app bar "Repeating records"; list (running first, then by start date). Row: category avatar · title
"{Category} · {amount}" · subtitle "{Frequency} · {next due date}" or "{Frequency} · Stopped" · **switch** (off = stop,
on = resume from today). Tap row → SCR‑20. **No add button** (series are created from the entry editor).
**States:** mixed running/stopped; **empty** "No repeating records yet. Turn on Repeat when adding a record."; long
category names; income vs expense series (sign/colour on amount).
**Copy:** Repeating records/Khoản định kỳ · Daily/Weekly/Monthly/Yearly (Hằng ngày/tuần/tháng/năm) · Stopped/Đã dừng.
**A11y:** switch label includes the series name and state.

### SCR‑20 · Edit series dialog
**Existing frame:** 7.2.
**Components:** title "Repeating records" (current copy — consider a clearer NEW title such as "Edit repeating record");
amount field (`0-9 . ,`); note field (≤ 200); Cancel / Save. Only future generated records change — say so (NEW hint).
Frequency and category are **read‑only** here (show them as context).
**Copy:** Repeating records/Khoản định kỳ · Note/Ghi chú · Cancel/Hủy · Save/Lưu · Amount must be greater than 0.

### SCR‑21 · About — `/about`
**Existing frames:** 9.1, 9.2 (`S16_GioiThieu`).
**Components:** logo/wordmark "Ví Gọn"; "Version 1.0.0 (1)"; privacy line; divider; rows: **Privacy policy** (opens
browser; **disabled with subtitle "Web page coming soon"** while URL is empty), **Report a security issue** (subtitle
"Contact email: {email}", opens mail app with subject), **Open source licenses** (Flutter license page).
**States:** policy enabled vs pending; "could not open" snackbar.
**Copy:** About/Giới thiệu · Version {version}/Phiên bản {version} · Your data is stored only on this phone. Ví Gọn does
not send it anywhere./Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu. · Privacy policy/Chính sách quyền
riêng tư · Web page coming soon/Đang chuẩn bị trang web · Report a security issue/Báo lỗi bảo mật · Contact email:
{email}/Email liên hệ: {email} · Open source licenses/Giấy phép nguồn mở · Could not open it. You can write to {target}
yourself/Không mở được. Bạn có thể tự gửi email tới {target}.
(Mockup email: use a placeholder such as `hello@example.com`.)

### SCR‑22 · Lock screen (overlay)
**Existing frames:** 1.1, 1.2 (`S01_KhoaPIN`).
**Purpose:** gate the app when PIN lock is on (F‑11).
**Components:** lock icon (or logo); title "Enter PIN"; **4 progress dots** (16 dp, fill as you type); error line (fixed
24 dp height so layout doesn't jump); **PIN pad 3 × 4** (1–9, blank, 0, ⌫; pill keys ~88 × 64); text button **Forgot
PIN**.
**Behaviour:** 4th digit auto‑checks; correct → unlock to the exact screen that was open; wrong → "Wrong PIN", dots
clear, light haptic, unlimited retries. While checking whether PIN is enabled at startup: blank screen in surface colour
(no flash of content).
**States:** idle; 2 digits entered; wrong PIN; secure storage error (looks the same; only Forgot PIN works); text 200 %;
dark.
**Copy:** Enter PIN/Nhập mã PIN · Wrong PIN/Sai mã PIN · Forgot PIN/Quên mã.
**A11y:** keys "Digit N"/"Số N", ⌫ "Backspace"/"Xóa lùi"; dots = live region "{count} of 4 digits entered"/"Đã nhập
{count} trên 4 số". Content behind is hidden from screen readers.

### SCR‑23 · PIN setup and PIN check (full‑screen, from Settings)
**Existing frames:** 8.1–8.4 (`S13_DatPIN`).
**Setup:** app bar "Lock with PIN" with back arrow (back = cancel, PIN not enabled); title "Choose a 4-digit PIN" + PIN
warning; after 4 digits → "Enter the PIN again"; match → save + close (switch on); mismatch → "The PINs do not match",
restart from step 1.
**Check (turning off):** title "Enter PIN"; correct → PIN off; wrong → "Wrong PIN".
**Copy:** Lock with PIN/Khóa bằng mã PIN · Choose a 4-digit PIN/Đặt mã PIN 4 số · Enter the PIN again/Nhập lại mã PIN ·
The PINs do not match/Hai lần nhập không khớp · Enter PIN/Nhập mã PIN · Wrong PIN/Sai mã PIN · `pinWarning`.

### SCR‑24 · Forgot PIN (3 dialogs over the lock screen)
**Existing frames:** 1.3–1.5.
1. Title "Forgot PIN", body `forgotPinBody`, buttons Cancel / **Delete all data**.
2. Title "Delete all data", body "Delete all records, categories, accounts and settings on this phone?", Cancel /
   **Delete**.
3. Title "Delete all data", body "This cannot be undone. Delete everything?", Cancel / **Delete all data** (error‑filled).
Then: data wiped, PIN off, unlocked, Home (fresh defaults) + snackbar "All data deleted". Cancel at any step → back to
lock screen.
**Copy VI:** Quên mã · (body §2.5) · Xóa toàn bộ dữ liệu · Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy
này? · Xóa · Không hoàn tác được. Xóa hết? · Đã xóa toàn bộ dữ liệu · Hủy.

### SCR‑25 · Backup, restore, CSV (from Settings)
**Existing frames:** 8.5–8.8 (`S14_SaoLuu`).
- **Export backup:** writes `vigon-YYYYMMDD-HHMM.vigon` → OS share sheet (placeholder). No storage permission.
- **Export CSV:** writes `vigon-YYYYMMDD-HHMM.csv` → OS share sheet.
- **Restore:** OS file picker (placeholder) → file validated **before** anything changes:
  - invalid → snackbar "The file is invalid or damaged. Your data was not changed." (no dialog);
  - valid → confirm dialog title "Restore from backup", body "Your current data will be replaced by the backup.
    Continue?", Cancel / **Confirm** → success snackbar "Data restored" (account filter resets to All).
- Optional design: a brief non‑blocking progress state while writing/reading large files (local only, typically < 1 s).
**Copy VI:** Xuất bản sao lưu · Xuất CSV · Khôi phục từ bản sao lưu · Dữ liệu hiện tại sẽ bị thay thế bằng bản sao lưu.
Tiếp tục? · Đồng ý · Hủy · Đã khôi phục dữ liệu · File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi.

### SCR‑26 · Delete all data (from Settings)
**Existing frames:** 8.9–8.11 (`S15_XoaDuLieu`).
Dialog 1: "Delete all data" / "Delete all records, categories, accounts and settings on this phone?" / Cancel ·
**Delete**. Dialog 2: "Delete all data" / "This cannot be undone. Delete everything?" / Cancel · **Delete all data**
(error‑filled). Result: defaults recreated (categories, "Cash"), currency re‑detected, theme/language/budget back to
default, PIN off; snackbar "All data deleted"; frame 8.11 shows Home after wipe (empty state).

### SCR‑27 · Shared patterns: confirm dialog and snackbars
- **Confirm dialog:** title, body, **Cancel** + action button (filled; `error` fill for destructive). Tap outside / Back
  = Cancel. Radius 28, `surface-container-high`.
- **Snackbar** (floating, `inverse-surface`, action in `inverse-primary`): "Deleted · Undo" (5 s, survives closing the
  editor), "Data restored", "All data deleted", "Stopped", "The file is invalid or damaged…", "Could not open it…".
  Design 1‑line and 2‑line (VI) variants; it must not cover the − / + buttons permanently (lift above them or accept
  5 s overlap — propose).

---

## 6. Key flows (step by step — prototype these)

**F1 · Log an expense — fastest path (target ≤ 3 taps excl. digits)**
- Via ring icon: Home → tap **Food** icon → type `45000` → **Save** → back on Home, ring/totals/budget updated. *(2 taps)*
- Via −: Home → **−** → type amount → **Choose category** → tap category (sheet closes, no save) → **Save**. *(4 taps
  today — see §8 item 3)*
- Income: Home → **+** → amount → Choose category → Salary → Save.
- With options: tap Date chip → pick date; tap Account chip → pick; type note; Repeat → Monthly.

**F2 · Edit / delete + undo**
- Home → balance bar (or list icon) → Entries → expand **Food** → tap record → change amount → **Save**.
- Delete from editor: trash → editor closes → "Deleted · Undo" (5 s) → **Undo** restores the identical record.
- Delete from list: swipe row left → removed → "Deleted · Undo".

**F3 · Change period**
- Tap period title → sheet → **Week** → Home shows this week. Swipe right → previous week. Tap › → next.
- Custom: title → **Custom range** → calendar → pick start, end → apply; Cancel keeps old period.
- Entries list follows the same period.

**F4 · Filter by account** (≥ 2 accounts): wallet icon → **Card** → Home and Entries show only Card records (transfers
in/out of Card included) → wallet → **All accounts** to clear.

**F5 · Transfer**: Home → Settings → Accounts → ⇄ → From **Cash** → To **Card** → amount → Save → account balances
change; Entries shows it under "Transfer"; Home totals unchanged.

**F6 · Recurring**: New expense → Repeat chip → **Monthly** → Save (first record created; series starts). Later:
Settings → Repeating records → toggle off (stop) / on (resume from today) → tap row → edit amount/note. Or open a
generated record → ⏹ Stop repeating.

**F7 · Budget**: tap budget bar (or Settings → Monthly budget) → enter 10,000,000 → Save → bar appears. Over → error
style + "Over by X". Remove budget → bar disappears.

**F8 · Backup / restore / CSV**: Settings → Export backup → share sheet → save to Files/Drive. Restore → file picker →
(bad file → error snackbar, nothing changed) / (good file → confirm → "Data restored"). Export CSV → share sheet.

**F9 · PIN on / off / forgot**: Settings → Lock with PIN switch → Choose PIN → Enter again → on. Leave app > 1 min →
return → Lock screen → enter PIN → same screen. Off: switch → Enter PIN → off. Forgot: Lock screen → Forgot PIN → 3
dialogs → fresh Home.

**F10 · Wipe data**: Settings → Delete all data → Delete → Delete all data → fresh Home + "All data deleted".

---

## 7. Sample data for mockups
Currency VND, language EN for base frames (VI for checks). Mock "today" = **2026‑11‑26**, period = **November 2026**.

**Accounts:** Cash/Tiền mặt (start 2,000,000) · Bank card/Thẻ ngân hàng (start 15,000,000) · E‑wallet/Ví điện tử
(start 500,000) · *(long‑name test)* "Family savings account"/"Tài khoản tiết kiệm gia đình".

**November 2026 expense by category** (total **11,780,000 ₫**):
| Category | Amount | % |
|---|---|---|
| Home (rent) | 3,500,000 | 29.7 |
| Food | 3,240,000 | 27.5 |
| Shopping | 1,450,000 | 12.3 |
| Bills | 1,120,000 | 9.5 |
| Transport | 860,000 | 7.3 |
| Family | 600,000 | 5.1 |
| Entertainment | 540,000 | 4.6 |
| Health | 320,000 | 2.7 |
| Other | 150,000 | 1.3 |
| Education | 0 | — (icon shown, "no records") |

**Income:** Salary 18,000,000 + Bonus 1,500,000 = **19,500,000 ₫**. **Period balance:** 7,720,000 ₫.
**Budget:** 12,000,000 → "Spent ₫11,780,000 of ₫12,000,000" (98 %). Over‑budget frame: budget 10,000,000 → "Over by
₫1,780,000".
**Records (examples):** Nov 26 "Beef pho"/"Phở bò" Food 45,000 · Nov 25 "Groceries"/"Đi chợ" Food 320,000 · Nov 1
"November rent"/"Tiền nhà tháng 11" Home 3,500,000 (monthly series) · Nov 20 "Electricity"/"Tiền điện" Bills 680,000 ·
Nov 18 "Ride to work"/"Xe ôm đi làm" Transport 35,000 · Nov 5 Salary 18,000,000 (monthly series) · Nov 10 Transfer Bank
card → Cash 2,000,000.
**Repeating series:** Rent 3,500,000 Monthly, next Dec 1 (running) · Salary 18,000,000 Monthly, next Dec 5 (running) ·
Internet 250,000 Monthly (stopped) · Gym 120,000 Weekly, next Nov 30 (running).
**Stress cases:** 16 expense categories (add: Coffee, Groceries, Fuel, Phone, Pets, Travel); category name of 50 chars
"Motorbike repairs and regular maintenance costs xx" / "Chi phí sửa chữa xe máy và bảo dưỡng định kỳ hằng năm";
amount `1.000.000.000.000 ₫`; note of 200 chars; USD variant `$1,250.00`.

---

## 8. Known UX weak points → design opportunities
These come from the UI review (`design/current/ui-spec.md` §9) and open items in `APP.md`. Solve them **within the
current feature set**; if a fix needs a behaviour change, mark it clearly as a proposal so the user can approve it.

1. **> 10 expense categories are not reachable from the ring** (AC‑06). Only `floor(2π·r / 56)` icons fit; extras are
   silently hidden (still selectable in the category sheet). Design an overflow: e.g. last slot = "More" that opens the
   category sheet for expense, or a scrollable/second ring, or smaller icons beyond N. Must keep 48 dp targets.
2. **Account filter is invisible.** The wallet icon looks the same whether filtered or not; the account name is only in
   the tooltip. Show the active filter as a visible label/chip on Home and in the Entries title area (tap → menu).
3. **The "−" path takes 4 taps, AC‑02 asks ≤ 3.** Options to evaluate: show frequent categories inline above the keypad
   so one tap both selects and saves when the amount is valid; or make picking in the sheet save immediately when the
   amount is valid. Propose one; it changes behaviour, so mark it as a proposal.
4. **"First day of week" toggles on tap** with no visible affordance. Use a 2‑option segmented control or a small menu.
5. **"Balance" means two different things** (period net on Home/Entries vs account balance on Accounts). Make the Home
   label/semantics clearer (e.g. visual "Income − Expenses" relationship) without new features; propose copy if needed.
6. **Entries list amount alignment:** child record amounts align further right than category totals (because of the
   chevron). Align all amounts to one column.
7. **Empty Home** is just a sentence in the ring area. Make it friendlier and point to the − button / ring icons.
8. **Delete without confirmation relies on a 5‑second snackbar.** Make the snackbar prominent, readable at 200 % text,
   and positioned so it isn't missed (it also appears after the editor closes).
9. **Max amount error is generic** ("Invalid calculation" also for > 10¹²). Optionally propose a specific message (NEW
   copy).
10. **Currency picker** is a long list under a 280‑char note. Consider full‑height sheet, codes + symbols aligned, note
    collapsible, current currency pinned on top.
11. **Repeating‑series edit dialog** is titled like the screen and hides what can't change. Show frequency/category as
    read‑only context and explain "applies to future records".
12. **Transfer is buried** (Settings → Accounts → ⇄). Consider a secondary entry point (e.g. from the account filter menu
    or Entries) — mark as proposal; no new capability.
13. **Large text (200 %) on Home:** the ring shrinks to fit; define the minimum ring size and what moves (e.g. budget text
    wraps to 2 lines, buttons keep 64 dp).
14. **Design‑system vs code mismatch to reconcile:** `design/current` lists default category colours/icons (e.g. Food =
    orange cat‑13, "Học tập") that differ from the code seed (Food = red `#C62828`, "Giáo dục") and a palette with
    `#827717 #6D4C41 #546E7A` where code has `#5D4037 #455A64 #616161`. Pick one and give the mapping (§2.3).
15. **Privacy policy row** is disabled with "Web page coming soon" until the URL exists — design the disabled state so it
    doesn't look broken.
16. **PIN has no attempt limit** and **accounts can't be deleted/hidden** — known v1 limits; do **not** design new
    controls for them (see §9).

---

## 9. Out of scope / Future (do not design in the main frames)
Not in v1 SPEC — listed so the layout can leave room, nothing more:
- Cloud sync, accounts/sign‑in, Google Drive/Dropbox backup, encrypted backups.
- Multiple currencies at once, exchange rates.
- Per‑category budgets, notifications/reminders, home‑screen widgets.
- Biometric unlock (Face ID / fingerprint), PIN attempt limit/back‑off.
- Delete/hide (archive) accounts; search records; edit frequency/category of a repeating series.
- Onboarding/tutorial screens, charts over time (trend), reports.
- Ads, in‑app purchases, Pro tier, analytics, crash SDKs.
- Reading bank SMS, receipt scanning, AI categorisation.
- Tablet / landscape layouts.

---

## 10. Deliverables requested from Claude Design

### 10.1 Frames
For **each platform** (Android 360 × 800 dp; iPhone 15/16 393 × 852 pt) × **both themes** (light, dark):
- Every screen SCR‑01 … SCR‑27 with the states listed in §5 (at minimum the "existing frame" states plus the new ones
  marked in §8).
- **VI variants** (light only is fine) for: SCR‑01, 05, 10, 11, 12, 22, 24.
- **200 % text variants** (one platform, light): SCR‑01, 05, 10, 11, 22.
- **Stress variants:** SCR‑01 with 16 categories; SCR‑01 / 05 with `1.000.000.000.000 ₫`; SCR‑10 with long notes.
- Platform‑specific frames only where §2.2 differs: iOS back swipe affordance (no hardware back), share sheet /
  document picker placeholders, safe areas.
- Prototype links for flows F1–F10 (§6).

### 10.2 File naming (1:1 with routes)
`design/hifi/<platform>/<theme>/<NN>_<slug>__<state>.png` (+ the HTML export of the same frame), where `<platform>` =
`android|ios`, `<theme>` = `light|dark`, `<NN>` = SCR number, `<state>` = `default|empty|error|over-budget|filtered|
loading|locked|long-text|large-number|many-categories|text-200|vi|…`. Overlays use `<route-slug>~<overlay>`.

| SCR | Route / owner | Slug |
|---|---|---|
| 01 | `/` | `home` |
| 02 | `/` sheet | `home~period-picker`, `home~custom-range` |
| 03 | `/` menu | `home~account-filter` |
| 04 | `/` or `/settings` dialog | `home~budget` |
| 05 | `/entry/new` | `entry-new` (`?type=income` → state `income`) |
| 06 | `/entry/:id` | `entry-id` |
| 07 | `/entry/new` sheet | `entry-new~category` |
| 08 | `/entry/new` sheets | `entry-new~repeat`, `entry-new~account` |
| 09 | date picker | `entry-new~date` |
| 10 | `/entries` | `entries` |
| 11 | `/settings` | `settings` (`__top`, `__bottom`) |
| 12 | `/settings` dialog | `settings~currency` |
| 13 | `/settings` menu | `settings~month-start` |
| 14 | `/categories` | `categories` |
| 15 | `/categories` sheet/dialog | `categories~edit`, `categories~delete` |
| 16 | `/accounts` | `accounts` |
| 17 | `/accounts` sheet | `accounts~edit` |
| 18 | `/transfer`, `/transfer/:id` | `transfer`, `transfer-id` |
| 19 | `/recurring` | `recurring` |
| 20 | `/recurring` dialog | `recurring~edit` |
| 21 | `/about` | `about` |
| 22 | overlay | `lock` |
| 23 | from `/settings` | `settings~pin-setup`, `settings~pin-check` |
| 24 | overlay dialogs | `lock~forgot-1`, `lock~forgot-2`, `lock~forgot-3` |
| 25 | from `/settings` | `settings~backup`, `settings~restore`, `settings~csv` |
| 26 | from `/settings` | `settings~delete-all-1`, `settings~delete-all-2` |
| 27 | shared | `shared~dialog`, `shared~snackbar` |

### 10.3 Design system page
- **Tokens export** as JSON in the **same schema as `design/current/screens/tokens.json`** (colour light/dark, type
  styles, spacing, radius, size, shadow) + CSS variables. Keep existing token names; list added/removed/changed tokens
  in a short changelog so session #2 can map them to:
  - Flutter `ColorScheme` (primary, onPrimary, primaryContainer, onPrimaryContainer, secondaryContainer,
    onSecondaryContainer, surface, surfaceContainer, surfaceContainerHigh, onSurface=`ink`,
    onSurfaceVariant=`ink-muted`, outline, outlineVariant, error, onError, inverseSurface, onInverseSurface=`inverse-ink`,
    inversePrimary, scrim);
  - a `ThemeExtension` for income/on‑income, expense/on‑expense, swipe‑delete, focus, cat‑01…16;
  - `TextTheme` (12 styles, tabular figures for amounts); spacing/radius/tap constants.
- **Component sheet** (each with states: default, pressed, focused, disabled, error, selected; light + dark):
  main action buttons (− / +), amount keypad + operator keys + wide action key, amount display, entry chips, category
  avatar (40/48), spending ring + ring icons (+ overflow), budget bar (normal/over), balance bar, period header, list
  rows (category expandable, record, swipe‑delete), section headers, segmented control, switch row, nav row, FAB,
  bottom sheet, dialog (normal/destructive), snackbar, PIN pad + dots, text fields (name, amount, note with counter),
  calendar range, menu.
- **Motion notes** (short, 150–250 ms): ring/totals transition when the period changes, keypad press feedback, sheet
  open/close, snackbar in/out, PIN error shake (respect "reduce motion").
- **Icon list:** final glyph for each of the 31 category keys (§3) and every action icon used.

### 10.4 Format
claude.ai link + exported HTML/PNG per frame (so the developer can read exact colours, spacing and fonts). Save exports
into `apps/A002-vigon/design/hifi/` using §10.2 names.

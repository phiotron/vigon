# Vigon (Ví Gọn) — Product brief for Hi‑Fi UI design (v3, version 2.0)

> **What this file is for:** the brief to send to **Claude Design** to produce Hi‑Fi mockups (UX/UI optimised) for the
> mobile app **Vigon** (Vietnamese name **Ví Gọn**, "tidy wallet") on **Android + iOS**. It says *what* each screen must
> do and *why*; *how it looks* is Claude Design's proposal, within the limits in §2 and §11.
>
> **Starting point = the app as it is today.** Version 1.x (records, ring chart, budgets, accounts, backup, PIN, widget,
> reminder — SPEC F‑01..F‑26) is already designed and implemented from the approved **Hi‑Fi P1 + P2 design system**
> (`design/hifi/`, tokens v2, Be Vietnam Pro, Material Symbols Rounded). **Upgrade, don't redesign:** keep its tokens,
> component vocabulary and the look of every screen that already has a frame. This brief asks for **three things**:
>
> 1. 🆕 **Draw the 2.0 screens that have no mockup yet** (Overview, Statistics, Calendar, Savings, Debts, Import queue,
>    Email import, Advanced filter, Excel/PDF export, biometric unlock, budget warnings, time field, currency
>    conversion dialogs…). These are the priority — §5 Part B.
> 2. 🔁 **Re‑compose the app shell:** a new **5‑tab bottom navigation** (§4) and a restructured **More** tab that replaces
>    today's long Settings list. Home keeps its look and its ≤ 3‑tap logging flow.
> 3. 🇬🇧 **English is now the default language** (no "follow the device" option). All frames are drawn in **English**
>    first; Vietnamese variants are only for checking text length (§2.4).
>
> Internal code `A002-vigon` · Bundle ID `com.phiotron.vigon` · Brief v3 · 2026‑11‑06 (replaces v2 of 2026‑11‑05).
> Glossary: `CONTEXT.md`. Specification: `docs/SPEC.md` (F‑01..F‑42, AC‑01..AC‑126). Copy quoted below is the real copy
> from `lib/l10n/app_en.arb` / `app_vi.arb` when it exists; copy a design needs that does not exist yet → mark `NEW:` in
> the mockup so the developer adds it to both `.arb` files.

**Frame status legend** (on every screen heading):
- ✅ **Drawn** — an approved frame exists in `design/hifi/` (frame numbers like 01, 05…). Refresh only; keep the look.
- 🟡 **Changed** — exists and is drawn, but this brief changes it (tab bar, new rows, new states).
- 🆕 **No frame** — implemented in the app from shared components but **never designed**, or not built yet. **Draw it.**
- 🤖 Android only · 🍏 needs an iOS note (§9).

---

## Contents
1. Product overview
2. Design constraints
3. Business rules the designer must know
4. Information architecture and navigation (**new 5‑tab shell**)
5. Screens — Part A: existing screens (refresh) · Part B: 2.0 screens (draw)
6. Surfaces outside the app (widget, notifications, icon)
7. Key flows
8. Sample data for mockups
9. iOS notes
10. UX weak points → opportunities · Out of scope
11. Deliverables requested from Claude Design

---

## 1. Product overview

### 1.1 One line
**Vigon** — record income and expenses in seconds, see at a glance where the money went, and (new in 2.0) let your
**bank's receipt emails** fill in expenses for you — all offline‑first, no account, no analytics, nothing sent to a
server.

### 1.2 Problem
People who want to know where their money goes each month give up because apps take too many steps, ask for an
account, or send data to a server. Vigon logs an expense in a few seconds, shows spending by category, and in 2.0 adds
the "whole picture" (overview, statistics, calendar, savings goals, debts) plus **optional** email import so manual typing
is needed less.

### 1.3 What is new in version 2.0 (the delta this brief designs)
| Area | New |
|---|---|
| **Shell** | Bottom navigation with 5 tabs: Home · Overview · Stats · Calendar · More |
| **Overview** (F‑35) | Total balance, "Income − expense" and "Budget left" tiles, 6‑month income/expense bars, change vs last month |
| **Statistics** (F‑36) | Income/expense bar chart by sub‑period, top 5 spending categories, biggest spending day, balance history line |
| **Calendar** (F‑38) | Month grid with daily spend, tap a day → its records |
| **Budget warnings** (F‑37) | "Almost over" state from a threshold (default 80 %), optional local notification with percentages only |
| **Advanced filter** (F‑39) | Amount range, several categories, date range, combined with search |
| **Time of entry** (F‑27) | Optional time on every record |
| **Savings** (F‑33) | Goals linked to an account; progress; "Add money" = transfer |
| **Debts** (F‑34) | Memo list: lent / borrowed, partial payments, due date |
| **Email import** (F‑28..F‑32) | Add a mailbox (Gmail/Yahoo/iCloud, app password) → MB Bank receipt emails become a **queue** where you pick the category; remembered suggestions |
| **Export** (F‑40) | Excel (.xlsx) and PDF report next to backup and CSV |
| **Biometrics** (F‑41) | Fingerprint / Face ID unlock on top of the PIN |
| **Language / currency** (D‑036) | English default; Settings offers English / Tiếng Việt; first‑run currency is USD; changing currency converts every amount with a live exchange rate (D‑025) |

### 1.4 Target users (personas)

| Persona | Situation | What they need from the UI |
|---|---|---|
| **Linh, 27, office worker (HCMC), Android** | Pays several times a day; logs right after paying, standing, **one hand**, weak signal; has an MB Bank account | Widget → Expense → amount → category = saved. Receipt emails from MB land in a **queue** she clears in 20 seconds with one thumb |
| **Minh, 20, student, iPhone** | Small budget; food is the risky category | Monthly budget + a **food limit**, "Almost over 82 %" warning, a savings goal "New laptop" |
| **Cô Hạnh, 52, keeps the family's market money** | Not tech‑savvy, Vietnamese only, large system text, worried about losing data | Big targets, readable at 200 %, plain words; automatic backup set up once; a debt memo for who owes her |
| **Alex, 34, expat (EN), Android** | USD, several accounts, wants numbers | Overview, Statistics, Calendar, filter by amount range, Excel/PDF export for taxes, fingerprint unlock |

### 1.5 Core jobs (priority order)
1. **Log an expense right after paying** — from Home, the widget or the reminder notification (unchanged).
2. **Clear the import queue** — pick a category for each bank‑email record (new).
3. **See where money went** — Home ring (period), Overview (month vs month), Statistics, Calendar.
4. **Find and fix records** — list, search, advanced filter, edit, delete with undo.
5. **Stay within budget** and **save toward goals**; remember **debts**.
6. **Keep data safe and private** — backup (manual/auto, optionally encrypted), PIN + biometrics, hide in app switcher.
7. **Report** — CSV, Excel, PDF.

### 1.6 Design principles
1. **Offline & private by design.** No sign‑in, no cloud, no analytics. Email import is optional, runs on the phone, reads
   only bank receipts, and says so in plain words wherever it asks for a mailbox.
2. **Log an entry in ≤ 3 taps** (AC‑02, excluding digit taps). Ring icon → digits → **Save** (2 taps); **−** → digits →
   **Choose category** → tap category = **saved** (3 taps, D‑018). The new tab bar must not add a tap to this.
3. **Calm, compact finance UI.** Numbers are the hero; colour sparingly; no gamification, no alarm walls.
4. **Thumb zone first.** Primary actions in the bottom half; the tab bar sits at the bottom, so keep primary buttons
   clear of it (§4.3).
5. **Never rely on colour alone.** Income/expense carry a sign or word; "Almost over" / "Over" carry icon + text.
6. **Forgiving.** Single records delete with 5‑s Undo; queue "Skip" confirms; passwords always warn "if you forget it,
   the file can't be opened".
7. **Same app on both platforms**, except OS‑owned behaviour (§9).

---

## 2. Design constraints

### 2.1 Platforms, frames, orientation
- **Android** (Material 3, edge‑to‑edge) and **iOS 16+** (adaptive Material, not Cupertino widgets). One shared layout.
- **Base frames:** Android **360 × 800 dp** (smallest supported) and iPhone 15/16 **393 × 852 pt**; must hold at 412 × 915.
- **Portrait only**, phone only (no tablet/landscape). Respect safe areas (status bar, gesture bar, Dynamic Island, Home
  indicator).

### 2.2 Theme and visual starting point (keep — this is the approved system)
- **Light, Dark, System** theme (AC‑35); every in‑app frame in both. (Only the *language* lost its "System" option.)
- Tokens: `design/hifi/tokens/tokens.json` (v2) is the source of truth and is wired into the app
  (`lib/src/ui/tokens.g.dart`). Primary `#2E7D6B`/`#8CD5BF`; income `#2E7D32`/`#81C784`; expense `#C62828`/`#EF9A9A`; error
  `#BA1A1A`/`#FFB4AB`; 16 category colours `cat-01…16`. Type **Be Vietnam Pro** with **tabular figures**; 12 type styles.
  Icons **Material Symbols Rounded** (filled for category icons, outlined for actions).
- You may refine tokens, **keep token names**, and list every change (§11.4). Contrast ≥ 4.5:1 text / 3:1 large text &
  icons in both themes (AC‑40). **New semantic need:** a **warning** colour pair for "Almost over" (distinct from
  `error` "Over" and from `expense`) and a neutral **info** surface for "from email" markers — propose tokens
  `warning`, `on-warning`, `warning-container`.
- **Category colours and icons are user data** (ARGB int + icon key, in backups): keep keys and the 16 colour slots.
- **Brand (D‑009):** logo "two stacked cards", background `#0E5244`, back card `#8CD5BF` −14°, front card `#F7FAF8` +8°,
  dot `#E65100`. Wordmark is now **"Vigon"** in English, **"Ví Gọn"** in Vietnamese. Final app icon exists; use the logo only
  where it helps (About, Lock, widget, empty states). Never coins, $, piggy bank, wallet with flap, leaf or donut as logo.
- **Navigation changed:** v1 had *no tab bar*. 2.0 introduces a **5‑tab bottom bar** (§4). Add the component (label +
  icon, selected pill using `secondary-container`, 80 dp high incl. safe area, works at 200 % text — labels may wrap to two
  lines or the bar switches to icons + selected label at ≥ 130 %).

### 2.3 Accessibility (WCAG 2.2 AA target)
- **Touch targets ≥ 48 × 48 dp / 44 × 44 pt** (`tap-min` 48, `tap-key` 56, `tap-main` 64).
- **Text scale up to 200 %** without clipping (AC‑38). At ≥ 130 %: amounts move under row titles, 3‑way segmented controls
  stack, areas above keypads scroll, button pairs wrap, **tab bar shows icons + label of selected tab only**.
- Every control has a spoken label; **every chart (ring, bars, line, calendar) has a text alternative** (one sentence + a
  hidden table); live regions for typed amounts and PIN progress; TalkBack and VoiceOver. 2 px `focus` ring; respect
  "reduce motion".

### 2.4 Languages and copy length
- **English (default) and Vietnamese.** First launch is English on every phone; the user can switch in Settings
  (English / Tiếng Việt). **Draw every frame in English**; additionally draw **VI variants** (light) for the screens listed
  in §11.2 to check that Vietnamese (≈ 20–40 % longer) still fits.
- Brand name: **Vigon** (EN) · **Ví Gọn** (VI). Widget button text and the launcher label follow the **device** language
  (OS‑owned); everything inside the app follows the app language.
- Riskiest long strings (EN | VI):

| Key | EN | VI | Where it bites |
|---|---|---|---|
| `emailIntroRead` | Vigon reads your bank's transfer receipt emails in the mailbox you add, then puts them in a queue for you to pick a category. | Ví Gọn đọc email biên lai chuyển tiền của ngân hàng trong hộp thư bạn thêm, rồi đưa vào hàng đợi để bạn chọn danh mục. | Email intro |
| `queueCurrencyNote` | The email is in {emailCurrency} but the app uses {appCurrency}. You'll enter the amount in the next step. | Email bằng {emailCurrency} nhưng app đang dùng {appCurrency}. Bạn sẽ nhập số tiền ở bước sau. | Queue card |
| `savingsAccountFixed` | The linked account can't be changed. To link a different account, delete the goal and create it again. | (VI longer) | Goal editor note |
| `debtNote` | A reminder list only: it doesn't count in income, expenses or account balances. | Chỉ là danh sách ghi nhớ: không tính vào thu, chi hay số dư tài khoản. | Debts header |
| `emailScheduleAndroid` | Vigon checks email when you open the app and about every hour while it's closed. Pull down to check now. | (VI longer) | Mailbox screen |
| `pinWarning` / `forgotPinBody` / `autoBackupNote` / `backupNote` | see v2 copy in the app (`app_en.arb`) | | Settings subtitles |
| Period title (week) | Nov 2 – Nov 8, 2026 | 2 thg 11 – 8 thg 11, 2026 | Period header |

### 2.5 Number, currency and date formatting
- **One currency for the whole app; default USD** on first launch (D‑036). All active ISO 4217 codes (~156), 0/2/3
  decimals. Changing currency opens the **conversion dialog** (§5 Part B, N‑14): every amount in the app is converted at a
  live rate fetched once (with manual rate fallback).
- Money display follows the **app language**: EN `$1,250.00`, `₫1,250,000`; VI `1.250.000 ₫`. Negative `-$200.00`.
  Money is stored exactly (6 hidden decimals) but **always displayed rounded** to the currency's decimals.
- **Large numbers** up to 10¹² minor units; totals can be larger → ring centre, tiles, chart labels must scale or wrap.
- Percent one decimal (`53.7%` / `53,7%`); sums to 100.0. Short date `Nov 3, 2026`; today = Today. **Time** `12:02` follows the
  device 12/24 h setting (`12:02 PM`). Compact chart/calendar amounts: EN `50K`, `1.2M`; VI `50k`, `1,2tr`.
- **CSV / Excel / PDF** follow the app language (CSV VI: `;` separator, `,` decimal).

---

## 3. Business rules the designer must know

Unchanged v1 rules (summarised) — **1** Entry = income/expense, amount ≥ 0, category, account, date (**+ optional time**),
note ≤ 200. **2** Transfer ≠ income/expense; own section in lists; changes account balances. **3** Two balances: *period
balance* (Home/Entries: income − expense of the viewed period) vs *account balance* (Accounts: starting + income −
expense ± transfers, all time). **4** Period: Day/Week/Month/Year/All time/Custom; week start and month start day in
Settings; period and account filter live in memory. **5** Account filter (≥ 2 visible accounts). **6** Ring icons =
expense categories, last slot "More categories". **7** Choosing a category saves when the key reads "Choose category".
**8** Repeating records generated on open. **9** Budgets: monthly total (Home bar) + optional per‑category limits.
**10** Accounts: hide / delete rules. **11** Search matches note, category, amount. **12** Delete = 5‑s undo.
**13** Manual backup `.vigon` (optional password, AES‑256‑GCM). **14** Auto backup: daily at a chosen hour (default 21:00),
always encrypted, keeps 2 files; Android background, iPhone via a notification. **15** Daily reminder (generic text).
**16** Widget Expense/Income (Android + iOS). **17** Hide content in app switcher (Android + iOS cover). **18** PIN lock
(4 digits). Details: `docs/SPEC.md`.

**New / changed in 2.0:**

19. **Time (F‑27):** every record may have a time `HH:mm`; new records default to "now"; old and recurring‑generated
    records show "No time set". Same‑day lists order by time (latest first).
20. **Email import (F‑28..F‑32):** Settings → "Import from bank email". The user adds up to **3 mailboxes** (Gmail, Yahoo,
    iCloud) with an **app password** (never the main password; stored only in Keystore/Keychain). Vigon searches only for
    **MB Bank** receipt emails, read‑only. Android checks about hourly in the background; iPhone only when the app is
    opened. Only **successful outgoing transfers** become items; each item is a **queue item**, *not yet a record* — it is
    excluded from every total, chart, budget and balance until the user picks a category.
21. **Matching:** if the user already typed the same expense (same account, same amount, ±2 h), the email attaches to it
    silently ("Matched with MB email 12:02" bar with Undo) instead of entering the queue. A small ✉ marks email‑sourced
    records on rows.
22. **Auto‑created account:** the first email for a bank account creates "MB Bank …1234" (balance 0) and shows a card at
    the top of the queue: *Created account MB Bank …1234 · Attach to an existing account*.
23. **Queue item actions:** pick a category (a **suggested** one is pre‑highlighted from past choices for the same payee, but
    still needs one tap), **Edit before saving**, **Move to my account** (becomes a transfer), **Skip** (with confirm). If the
    email's currency differs from the app's, the amount is entered manually.
24. **Savings goal:** name, target, optional deadline, linked account (existing unlinked one or a new one). Progress =
    linked account balance ÷ target. **Add money** opens Transfer pre‑filled; totals/budgets do not change. Reached = balance ≥
    target ("Reached" with ✓ and text).
25. **Debts:** memo only — person, direction (I lent / I borrowed), amount, date, optional due date, note, payments. Does
    not touch records, accounts, totals.
26. **Overview month** is independent of Home's period; totals include all accounts (hidden ones too) and **exclude** queue
    items. "vs last month" shows % change of spending and of income with an arrow **and** the words up/down; last month 0 → "—".
27. **Budget states:** *normal* · **Almost over** (≥ threshold, default 80 %, adjustable 50–95 %) · **Over by X**. Optional
    local notification at the threshold and at 100 %, once per budget per month, **percentages only, never amounts**.
28. **Advanced filter:** amount range + several categories (income and expense) + date range, AND‑combined with search and
    account filter; results are a flat list with "N records · spent X · income Y"; each condition is a removable chip.
29. **Biometrics:** only offered when PIN is on and the phone has enrolled biometrics; PIN remains the fallback.
30. **Export:** Excel (.xlsx: Records / By category / Debts sheets) and PDF (A4 report) for a chosen range, via the system
    share sheet.
31. **Currency change (D‑025/D‑029):** choosing another currency opens "Convert to X?" with a live rate both ways, an
    example (before → after), a rounding warning and "Use a different rate" manual entry; offline/failed → clear error +
    manual rate. Converting there and back returns the original numbers.

---

## 4. Information architecture and navigation

### 4.1 New app shell — 5 bottom tabs (decided 2026‑11‑06)

| Tab | Icon (Material Symbols Rounded) | Root route | Contains |
|---|---|---|---|
| **Home** | `home` / `donut_large` | `/` | Existing Home: period header, ring, budget bar, balance bar, − / + |
| **Overview** | `dashboard` | `/overview` | N‑01 |
| **Stats** | `monitoring` | `/stats` | N‑02 |
| **Calendar** | `calendar_month` | `/calendar` | N‑03 |
| **More** | `menu` / `more_horiz` | `/more` | N‑05 hub: Records, Savings, Debts, Import queue, Categories, Accounts, Repeating, Settings groups, About |

- The tab bar is **visible on the five root screens only**. Any pushed screen (New/Edit entry, Entries list, Savings, Debts,
  Queue, Settings sub‑pages, dialogs, sheets) is full screen with a back/close and **no tab bar**.
- **Home keeps its identity:** the − / + buttons, ring icons and ≤ 3‑tap logging stay. Design where the tab bar sits relative
  to the − / + buttons so the primary buttons remain the strongest elements (they are the app's core). Home's
  top‑bar icons become: wallet (account filter) · queue badge (when items wait) — the receipt/records icon moves into the
  balance bar tap and **More → Records**; the gear moves into **More**.
- **Quick add on other tabs (proposal):** Overview/Stats/Calendar may show a compact "+" action (FAB or top‑bar) → New
  entry. Mark as proposal; show both with and without.
- **Badges:** the **More** tab (and the Home top‑bar queue icon) shows a count badge when queue items wait ("3"); also a
  one‑line **banner under the Home period header**: *3 records waiting for a category* → opens the queue.
- Deep links (widget, notification) still open **New entry** (through the PIN lock) — unchanged; budget notifications open
  **Overview**.

### 4.2 Routes

| Route | Screen | SCR / N |
|---|---|---|
| `/` | Home | SCR‑01 |
| `/overview` · `/stats` · `/calendar` | Overview · Statistics · Calendar | N‑01 · N‑02 · N‑03 |
| `/more` | More hub | N‑05 |
| `/entry/new`, `/entry/:id` | New / edit entry (**+ time field**) | SCR‑05/06 + N‑04 |
| `/entries` | Records list + search + **Filter** | SCR‑10/11 + N‑04 |
| `/savings` | Savings goals (+ editor, contribute) | N‑06 |
| `/debts` | Debts (+ editor, detail, payment) | N‑07 |
| `/import-queue` | Import queue | N‑08 |
| `/settings/email-import` | Email import intro / mailbox list / add | N‑09 |
| `/settings` | Settings (now a sub‑page of More) | SCR‑12 (re‑grouped) |
| `/categories` `/accounts` `/transfer` `/recurring` | as v2 | SCR‑15…22 |
| overlay | Lock (+ biometric) | SCR‑23 + N‑12 |

### 4.3 Navigation map

```
Tabs:  Home "/" │ Overview │ Stats │ Calendar │ More
Home ─ −/+ , ring icon, ⋯ ─► New entry (time, account, repeat…)         (no tab bar)
     ─ banner "3 records waiting" ─► Import queue (N-08)
     ─ balance bar ─► Records (/entries) ─ 🔍 search · Filter (N-04)
Overview ─ month ‹ › · tiles · bars · vs last month ─ "Set a budget" ─► budget dialog
Stats ─ period "View by" (same sheet as Home) · account filter · charts
Calendar ─ tap a day ─► day sheet/list (tap record ─► Edit)
More ─ Records · Savings · Debts · Import queue (badge) · Categories · Accounts · Repeating records
     ─ Settings ─► Appearance & language · Currency · Budget & warnings · Security (PIN, biometrics, hide content)
                    · Reminders · Data (backup, auto backup, restore, CSV, Excel, PDF, delete all) · Email import · About
Savings ─ goal ─► Add money (Transfer pre-filled) · edit · delete
Debts ─ debt ─► detail with payments ─► add payment
Import queue ─ item ─► save to category · edit first · move to my account · skip ; ─ "Remembered suggestions"
Email import ─ intro ─► Add mailbox (provider, address, app password, steps) ─► Connected / error
Outside: Widget · Reminder · Budget-warning notification · Recents cover
```

---

## 5. Screens

Per screen: **Status · Purpose · Components · States · Interactions · Copy (EN | VI) · Accessibility.**

### Part A — existing screens (refresh; keep the approved look unless noted)

| SCR | Screen | Status | What to do |
|---|---|---|---|
| 01 | **Home** | 🟡 | Add tab bar, queue banner + badge, move gear/records icon (see §4.1). Show **filtered‑account chip** (v2 weak point #1) and "Almost over" budget state. Keep ring, ⋯ slot, − / +, empty state |
| 02 | "View by" sheet + range calendar | ✅ | Refresh; reused by **Stats** (Overview has its own month header) |
| 03 | Account filter menu | ✅ | Refresh; also on Stats, Calendar, Entries |
| 04 | Monthly budget dialog | ✅ | Refresh; add warning‑threshold row link ("Warn me at 80 %") |
| 05 | **New entry + keypad** | 🟡 | **Add the Time field** next to Date (N‑04). Keep keypad and D‑018 flow |
| 06 | Edit entry | 🟡 | Time field incl. "No time set"; "From email" source line (✉ MB Bank · ref ending 4821) |
| 07–09 | Category grid, Repeat/Account sheets, Date picker | ✅ | Refresh |
| 10 | **Records list** | 🟡 | Rows show time and ✉ marker; header gets **Filter** button next to search; category budget bars show the Almost‑over state |
| 11 | Search | ✅ | Refresh; combine with Filter chips (N‑04) |
| 12 | **Settings** | 🟡 | Becomes a sub‑page of More, **regrouped** (N‑05b): Appearance & language (language = 2‑option segmented **English / Tiếng Việt**, **no "System"**) · Currency · Budget & warnings · Security · Reminders · Data · Email import · About |
| 13 | Currency picker | 🟡 | Add the conversion flow (N‑14) after choosing |
| 14 | Month‑start menu | ✅ | Refresh |
| 15–16 | Categories, edit sheet, delete+move | ✅ | Refresh |
| 17–18 | Accounts, edit sheet | 🟡 | Add **"From email MB"** label under linked accounts; linked‑account marker; savings‑goal linked accounts show a goal chip |
| 19 | Transfer | 🟡 | Support pre‑fill from "Add money" (To = goal account); time field |
| 20–21 | Repeating records + edit | ✅ | Refresh |
| 22 | About | ✅ | Refresh; wordmark Vigon |
| 23–25 | Lock, PIN, Forgot PIN | 🟡 | Add the biometric button/state on Lock (N‑12) |
| 26–29 | Backup export, restore, CSV, delete all | ✅ | Refresh; **Export row group now has CSV · Excel · PDF** (N‑11) |
| 30–31 | Reminder dialogs, Auto backup | ✅ | Refresh (auto backup now: daily at chosen hour, keeps 2 files, status "Checked, nothing new") |
| 32–33 | Shared dialog/snackbar, Settings iOS | ✅ | Refresh |

Home / Entries / Settings copy is as in `lib/l10n/app_en.arb`; do not invent new copy for unchanged screens.

### Part B — 2.0 screens to draw (🆕, priority)

#### N‑01 · Overview — `/overview` (tab) 🆕  (F‑35, AC‑107, AC‑108)
**Purpose:** "How am I doing this month?" in one glance.
**Components (top → bottom):**
1. App bar "Overview" + account‑independent note (all accounts). Month header ‹ **November 2026** › (own month, default
   current month by month‑start day; independent of Home's period; swipe also changes month).
2. **Total balance** hero card: sum of all accounts (hidden included), `amount-xl`, caption "All accounts".
3. Two **tiles side by side:** *Income − expenses* (signed, green/red + sign) and *Budget left* (amount; if over: "Over by X"
   with icon; if no budget: a tonal **Set a budget** button; Almost‑over state uses warning tokens).
4. **Bar chart — income vs expenses, last 6 months** ending at the chosen month; paired bars (income green, expense red),
   month labels, selected month highlighted; tap a bar → shows exact values in a callout; text alternative table.
5. **vs last month** card: two rows — *Spending* ▲ **up 25 %** / ▼ down, *Income* ▲/▼ — arrow + words + %, "—" when last
   month is 0; one‑sentence summary ("You spent 25 % more than in October").
6. Optional: **Savings strip** (top goal progress) and **Debts strip** (owed to you / you owe) linking to N‑06/N‑07 — propose,
   keep calm.
**States:** normal · no data this month (friendly empty with link to Home) · no budget · budget Almost over · over ·
large numbers · negative total balance · text 200 % (tiles stack) · queue items waiting (a note "3 records waiting are not
counted yet").
**Copy (existing/NEW):** Total balance · Income − expenses · Budget left · Over by {amount} · Set a budget · vs last month ·
Spending up/down {n}% · NEW: strings above marked NEW.
**A11y:** every tile one sentence; chart table "October: income $2,100, expenses $1,500 …".

#### N‑02 · Statistics — `/stats` (tab) 🆕  (F‑36, AC‑109, AC‑110)
**Purpose:** analyse a chosen period.
**Components:** period header + "View by" (reuse SCR‑02) + account filter · **Income/expense bar chart** whose sub‑periods
depend on the period (Week → 7 days; Month → days; Year → 12 months; All time → years; custom ≤ 31 d days, ≤ 366 d months,
else years) · **Top 5 spending categories** list (icon, name, amount, % bar) · **Biggest spending day** card (date + amount;
hidden for Day period) · **Balance history** line (total balance at the end of each sub‑period) · the existing donut/percent by
category can be reached via a "By category" segmented switch or kept on Home — **propose** the cleanest arrangement.
**States:** empty period (single empty illustration, no empty charts) · one data point · long VI labels · 10 000 records
(must feel instant) · negative balance in line · text 200 %.
**Interactions:** tap bar → callout; tap category → Records filtered to it; reduce‑motion‑safe animation.

#### N‑03 · Calendar — `/calendar` (tab) 🆕  (F‑38, AC‑114)
**Purpose:** see spending day by day.
**Components:** month header ‹ › (swipe) · week‑start aware 7‑column grid (reuse `range_calendar` look): each day shows the
**compact day spending** (`50K`, `1.2M`) and a **dot** if there was income; today outlined; selected day filled · below the
grid a **day panel**: date, day totals (spent · income), then the day's records (edit, swipe‑delete + undo, like Records) ·
account filter.
**States:** empty month · busy month (6 rows) · day with 15 records (panel scrolls) · future days muted · large amounts
truncated gracefully · text 200 % (grid cells show amount only on selection) · queue items are not shown.
**A11y:** cell reads "November 6, spent $250.00, income recorded".

#### N‑04 · Time field, Records filter, record rows 🆕  (F‑27, F‑39, AC‑74..76, AC‑115)
- **Time field** on New/Edit entry and Transfer: a row next to Date: *Time · 12:02* → system time picker; Edit of old record
  shows *Time · No time set* with a "Set time" affordance; changing the date keeps the time.
- **Record rows** show `12:02` next to the account name, and a small ✉ for email‑sourced records.
- **Filter sheet** (opened by **Filter** button beside the search icon in Records): Amount range (two fields From/To; error
  below if From > To), Categories (multi‑select grid, expense + income groups), Date range (reuse range calendar), buttons
  **Clear** / **Apply**. Active filters appear as **removable chips** under the search bar; result header "12 records ·
  spent $420.00 · income $0.00"; "Clear filters" link. Combine with search text and account filter (AND).
- States: no results · many chips (wraps to 2 lines) · VI long labels.

#### N‑05 · More tab (hub) and regrouped Settings 🆕🟡
**More hub** (list of cards/rows with icons, calm, scannable): *Records* · *Savings* · *Debts* · *Import queue* (badge) ·
*Categories* · *Accounts* · *Repeating records* · *Settings* · *About*. Show a small status summary on some rows (e.g.
Savings "2 goals", Debts "$80 owed to you", Queue "3 waiting").
**Settings (regrouped, replaces the ~25‑row list; v2 weak point #3):** group cards with titles and status chips —
**Appearance & language** (Theme: System/Light/Dark · Language: **English | Tiếng Việt**) · **Money** (Currency → conversion
flow, first day of week, month start day, monthly budget, **Warn me at 80 %** stepper 50–95 %, **Budget notifications**
switch) · **Security** (PIN, **fingerprint/Face ID** switch + reason when unavailable, hide in app switcher) · **Reminders**
(daily reminder + time) · **Widget** (show amounts) · **Data** (Export backup, Restore, **Export CSV / Excel / PDF**, Automatic
backup status chip OK/error, Delete all data) · **Auto import** (Import from bank email → status "No mailbox yet" /
"1 mailbox · Connected") · **Info** (About, privacy policy). Propose sub‑pages only where clearer (e.g. *Backup & data*) —
mark as proposal. iOS variant hides nothing now (all features exist on iOS; only Android‑specific copy differs, §9).

#### N‑06 · Savings — `/savings` 🆕  (F‑33, AC‑100..103)
**Purpose:** keep goals visible and motivating without gamification.
**List:** one card per goal: name, **progress bar** (+ % text), "Saved $3,000 of $10,000", "$7,000 to go", deadline chip
("12 days left" / "Overdue 3 days"), **Reached** ✓ state (text + icon), **Add money** button. Header "Savings", FAB/Top
action **Add goal**. Empty state: "No savings goals yet. Set a goal, then add money to it over time." with illustration.
**Goal editor (sheet/page):** Name (≤ 50) · Target amount · Deadline (optional, "Remove deadline") · **Linked account**
radio list: existing unlinked accounts + "Create a new account" (note: named like the goal, starts at 0); fixed‑after‑create
note; error "This account is already linked to another goal". Delete goal confirm (accounts/records stay).
**Add money:** opens Transfer (SCR‑19) with *To* = goal account, *From* = default account; after save, goal progress animates.
**States:** 1 goal · 6 goals · reached · overdue · no deadline · account balance fell below target (lost "Reached") · text 200 %
· long names · need another account (hint "You need another account to add money from").

#### N‑07 · Debts — `/debts` 🆕  (F‑34, AC‑104..106)
**List:** header note "A reminder list only: it doesn't count in income, expenses or account balances." Two groups with totals —
**Owed to you** (I lent) and **You owe** (I borrowed): row = person, amount remaining, "Paid $20 of $100" mini bar, due chip
("Due Dec 1" / **Overdue** word + icon). Collapsible **Settled (n)** section. Add debt button.
**Editor:** Person · Direction (segmented: I lent / I borrowed) · Amount · Date · Due date (optional) · Note (≤ 200).
**Detail:** big remaining amount, progress, **Payments** list (date, amount, delete), **Add payment** (amount; error "More
than the remaining $60"), edit, delete debt confirm ("Its payments are deleted too. No record or account balance is
affected."). Settled state with ✓ "Settled".
**States:** empty · both groups · overdue · settled · long person name · large amounts · 200 % text.

#### N‑08 · Import queue — `/import-queue` 🆕  (F‑32, AC‑95..99) — **the most important new screen**
**Purpose:** turn bank‑email items into records with one tap each, quickly, one‑handed.
**Layout:** app bar "Queue" (+ overflow: *Remembered suggestions*). Optional top **info card**: "Created account MB Bank …1234 ·
Attach to an existing account · Dismiss". Then a **vertical list of item cards** (or a pager — propose; the list must show
2 items without scrolling at 360 × 800):
- **Item header:** date + time (from the email), **amount** (`amount-l`, expense colour), payee ("LE VAN KHACH" or "Unknown
  payee"), transfer content (1–2 lines), "From MB Bank …4821" account line, small ✉ marker.
- **Category grid** (same avatar grid as the entry editor, expense categories, scrollable horizontally or 2 rows with ⋯): if a
  **suggestion** exists, that category is pre‑selected, tagged **Suggested**, and the primary button reads **Save to Food**;
  tapping another category saves to that one; with no suggestion, tapping a category saves immediately (D‑018 behaviour).
- **Secondary actions:** *Edit before saving* · *Move to my account* · *Skip*.
- **Currency mismatch variant:** note "The email is in VND but the app uses USD. You'll enter the amount in the next step."
  and the primary action opens the entry editor with an empty amount.
- After saving: item collapses out with a snackbar "Saved to Food" (+ Undo proposal). A **reverse‑match bar** can appear after
  saving a manual record: "Matched with MB email 12:02 · Undo".
**Empty state:** "Nothing is waiting. When a new receipt email arrives, it shows up here for you to pick a category." + pull‑to‑check
hint (Android: "checks about every hour"; iPhone: "checks when you open the app").
**Dialogs/sheets:** *Move to account* (account list incl. savings goals' accounts) · *Skip this record?* ("It leaves the queue and
won't be imported again from this email.") · *Attach to account* · *Remembered suggestions* screen (list: payee → category/
account, delete suggestion; empty text).
**States:** 1 item · 12 items · long payee/content · suggestion vs none · currency mismatch · account auto‑created card ·
loading while checking mail (pull‑to‑refresh) · error line · 200 % text (grid scrolls, buttons stack) · dark.

#### N‑09 · Email import — `/settings/email-import` 🆕  (F‑28, AC‑78..83)
1. **Intro (first open):** title "Record spending from receipt emails"; four reassurance lines with icons (read the bank's
   receipts only · on this phone only, never sent anywhere · nothing changed/deleted/marked read · needs an **app password**, not
   your main password) + "Only MB Bank is supported for now." + iPhone note; primary **Add mailbox**.
2. **Add mailbox:** Provider (Gmail / Yahoo / iCloud, segmented or cards) · Email address · **App password** (masked, show
   toggle) · numbered **"Create an app password"** steps for the chosen provider with a button that opens the provider's page in
   the browser · **Connect** → inline progress → "Connected" or a clear error (*Wrong address or app password* · *IMAP is turned
   off for this mailbox* · *No internet connection* · *Couldn't make a secure connection…*).
3. **Mailbox list / status:** each mailbox card: address, provider, status chip (Connected / Paused — *Enter the app password
   again*), "Last check: 10:05", "2 MB emails couldn't be read" (warning, tap to explain: the email format may have changed),
   **Re‑enter password**, **Remove mailbox** (confirm: "Vigon will stop reading email from … and delete the app password…").
   Footer: schedule note (Android hourly vs iPhone on open) and **Remembered suggestions** link. Max 3 mailboxes message.
**States:** none · connecting · connected · error variants · paused · limit reached · iPhone vs Android notes · 200 % text.

#### N‑10 · Budget warning states and notification 🆕  (F‑37, AC‑111..113)
- Budget bar (Home), "Budget left" tile (Overview) and category budget rows (Records) get **three visual states**: normal ·
  **Almost over** (warning tokens, icon + "Used 82 %") · **Over by X** (error). Show all three on each place.
- Settings: **Warn me at** stepper/segmented (50–95 %, step 5, default 80) with a live example ("$4,000 of $5,000"); **Budget
  notifications** switch (default off) with an explain sheet before the OS permission prompt.
- **Notification** (Android + iOS): "Monthly budget November: 80% used" · "Food: 100% of the November limit used" — **percentages
  only, no amounts, even with PIN off**. Show lock screen appearance, light + dark.

#### N‑11 · Export Excel & PDF 🆕  (F‑40, AC‑116..118)
Settings → Data lists **Export CSV · Export Excel · Export PDF**. Tapping Excel/PDF opens a **range sheet**: Current period ·
Custom range (calendar) · All time, a short description of what is included (Excel: Records, By category, Debts sheets; PDF: A4
report with totals, category table, record list), and **Export** → progress → system share sheet. States: preparing (progress
for big ranges), done, error, empty range ("No records in this range"). Also draw a **PDF page preview** (A4: title "Income &
expense report — November 2026", totals row, category table with % bars, records table) in light only, to guide the
generated layout (fonts: Be Vietnam Pro embedded).

#### N‑12 · Biometric unlock 🆕  (F‑41, AC‑119/120)
- Settings → Security: switch **Unlock with fingerprint** (Android) / **Face ID / Touch ID** (iPhone), default off; hidden while
  PIN is off; disabled with a one‑line reason when no biometrics are enrolled; turning on asks for one authentication.
- **Lock screen** (SCR‑23) states: biometric prompt auto‑shown (system sheet placeholder) · fell back to PIN pad with a
  **biometric button** to retry · wrong biometric/cancelled · temporarily locked by the OS. PIN pad stays fully usable.

#### N‑13 · Language & first launch 🟡
- **Settings → Language** is a 2‑option segmented control **English | Tiếng Việt** (selected = English by default). Draw it
  in both languages.
- There is **no onboarding or language prompt**: first launch opens Home in English with USD and an empty state (design a
  friendlier empty Home pointing at − / ring icons).

#### N‑14 · Currency conversion dialogs 🆕  (F‑07, AC‑70..73, D‑025/D‑029)
Settings → Currency → pick (searchable list; current pinned) → **Convert to X?** dialog: loading "Fetching exchange rate…" →
two‑way rate ("1 VND = 0.0000385 USD" · "1 USD = 25,974 VND"), date, attribution "Rates By Exchange Rate API" (tappable),
**example** (latest record before → after), rounding warning, advice to export a backup first, buttons **Cancel / Convert**,
**Use a different rate** (manual field "1 A = ? B", swap direction). **Error variant** (offline / no rate): reason line, manual rate
field pre‑filled with the last known rate and its date, **Try again / Continue / Cancel**; field error for ≤ 0. Success snackbar
"Converted all amounts to USD". States: loading · success · manual · error · 200 % text · VI.

#### N‑15 · Records matched from email (small components) 🆕
- **✉ source marker** on record rows and in Edit entry ("From MB email · reference ending 4821").
- **Match undo bar** (snackbar‑like): "Matched with MB email 12:02 · Undo".
- **Home queue banner** and **More‑tab badge** (§4.1) — show all states: 0 (hidden), 1, 12, 99+.

---

## 6. Surfaces outside the app

| EXT | Surface | Status | Notes |
|---|---|---|---|
| 01 | Home‑screen widget 2×2 / 4×2 (Android, iPhone) | ✅ refresh | Expense / Income buttons; no amounts unless allowed and PIN off; "Open the app to update"; launcher label follows device language. Widget title row shows the logo + "Vigon" |
| 02 | Daily reminder notification | ✅ refresh | Generic text, no figures |
| 03 | Budget‑warning notification | 🆕 | Percentages only (N‑10) |
| 04 | Recents / app‑switcher cover (Android + iPhone) | ✅ refresh | Blank/blurred with logo |
| 05 | OS sheets & pickers (placeholders) | — | Share sheet, file/folder picker, biometric prompt, notification permission |
| 06 | App icon incl. Android monochrome | ✅ | unchanged |

---

## 7. Key flows (prototype these)

- **F1 Log an expense:** ring **Food** → `4.50` → **Save** (2 taps) · **−** → amount → Choose category → tap Food = saved (3 taps)
  · set a **time**. The tab bar must not add taps.
- **F2 Clear the queue:** Home banner "3 records waiting" → Queue → item 1 has **Suggested: Food** → **Save to Food** → snackbar;
  item 2 no suggestion → tap **Shopping** = saved; item 3 → **Move to my account** → account list → saved as transfer; item 4 →
  **Skip** → confirm.
- **F3 Add a mailbox:** More → Settings → Import from bank email → intro → Add mailbox → Gmail → steps → address + app password →
  Connect → Connected → mailbox card with last check.
- **F4 Match:** type a $12.00 coffee at "MB Bank …1234" 12:00 → 12:02 email arrives → silent match, row shows ✉ "12:00".
- **F5 Overview → Stats → Calendar:** change Overview month, tap a bar, "Set a budget" → dialog; Stats → Week → tap Food in top‑5
  → Records filtered; Calendar → tap Nov 6 → day panel → edit a record.
- **F6 Budget warning:** raise spending past 80 % → Home bar turns Almost over; past 100 % → Over; notification at the lock screen.
- **F7 Savings:** More → Savings → Add goal "New laptop" $1,200, deadline Mar 1, create new account → Add money $100 → progress.
- **F8 Debts:** Add debt "Hạnh owes me" $100 → add payment $40 → progress 40 % → settle → Settled section.
- **F9 Filter:** Records → Filter → $5–$20, Food + Transport, Nov 1–15 → chips → results header → Clear filters.
- **F10 Export:** Settings → Data → Export PDF → range sheet → progress → share sheet · Excel the same.
- **F11 Biometrics:** Settings → Security → turn on fingerprint → cold start → prompt → success; cancel → PIN pad.
- **F12 Switch language & currency:** Settings → Language → Tiếng Việt (instant) · Currency → VND → conversion dialog (rate, example) →
  Convert → "Converted all amounts to VND"; error variant offline → manual rate.
- **F13 Unchanged v1 flows:** search, period & filter, accounts hide/delete, transfer, repeating, backup/restore/CSV, auto
  backup, reminder, PIN, wipe data (frames exist; refresh only).

---

## 8. Sample data for mockups
Currency **USD** (EN base), VND/VI variants for checks. Mock "today" = **2026‑11‑26**, period **November 2026**.

**Accounts:** Cash (start $120.00) · Bank card ($900.00) · E‑wallet ($40.00) · **MB Bank …4821** (auto‑created, $0.00, label "From
MB email") · *hidden:* Old credit card (−$50.00) · *savings goal accounts:* "New laptop" ($300.00). Long‑name test: "Family savings
account for the house deposit".
**November expenses by category** (total **$1,840.00**): Home $540.00 (29.3 %) · Food $495.00 (26.9 %) · Shopping $215.00 ·
Bills $170.00 · Transport $130.00 · Family $90.00 · Entertainment $80.00 · Health $50.00 · Other $20.00 · Education $0 (no records).
**Income:** Salary $2,300.00 + Bonus $200.00 = **$2,500.00**. **Period balance** $660.00. **Total balance (all accounts)** $2,060.00.
**Monthly budget** $2,000.00 → "Used 92 %" (Almost over). Over‑budget variant $1,700.00 → "Over by $140.00". Normal variant $2,800.00
(66 %). **Category limits:** Food $450.00 → Over by $45.00 · Shopping $300.00 → 72 % · Transport $160.00 → Almost over 81 %.
**Last 6 months (income / expenses):** Jun 2,300/1,520 · Jul 2,300/1,610 · Aug 2,350/1,700 · Sep 2,300/1,480 · Oct 2,300/1,470 ·
Nov 2,500/1,840 → "Spending up 25 % vs October".
**Biggest spending day:** Nov 14 — $310.00. **Calendar day cells:** Nov 1 `$540` (rent) · Nov 5 dot (salary) · Nov 6 `250` · Nov 14 `310`
· Nov 26 `4.50`.
**Records (with time):** Nov 26 12:02 "Beef pho" Food $4.50 ✉ · Nov 25 18:40 "Groceries" Food $32.00 · Nov 1 — "November rent"
Home $540.00 (series, no time) · Nov 20 "Electricity" Bills $68.00 · Nov 18 07:50 "Ride to work" Transport $3.50 · Nov 5 Salary $2,300.00
(series) · Nov 10 Transfer Bank card → Cash $200.00.
**Queue items (3)** (MB emails are in VND): (1) Nov 26 12:02 **50,000 ₫** "LE VAN KHACH — tra tien com" from MB …4821,
*Suggested: Food* · (2) Nov 26 09:15 **1,200,000 ₫** "CONG TY ABC — thanh toan hoa don", no suggestion · (3) Nov 25 20:30
**2,000,000 ₫** payee = the user's own e‑wallet → "Move to my account" candidate. Show the **currency mismatch** note since app =
USD, and a second set where app = VND so amounts are directly usable. Auto‑created account card: "Created account MB Bank …4821".
**Savings:** "New laptop" $300 of $1,200 (25 %), deadline Mar 1, 2027 → 95 days left · "Emergency fund" $1,500 of $1,500 → **Reached** ·
"Trip" $50 of $800, deadline Oct 31 → **Overdue 26 days**.
**Debts:** Owed to you — Hạnh $100 (paid $40 → $60 remaining, due Dec 1), Tuấn $20 (due Nov 20 → **Overdue**) → "$80 remaining";
You owe — Landlord $30 → "$30 remaining"; Settled (1): Minh $15.
**Mailbox:** gmail "linh.nguyen@gmail.com" Connected, Last check 10:05, "2 MB emails couldn't be read" (variant); paused variant.
**Suggestions:** "CONG TY ABC" → Food · "TAP HOA CO LAN" → Shopping.
**Advanced filter example:** $5–$20 · Food + Transport · Nov 1–15 · results "9 records · spent $87.50".
**Auto backup:** folder "Vigon backups" (Google Drive) · "Last: Nov 25, 21:04" · "Checked 21:00 — nothing new" · error variant.
**Reminder:** on, 20:00. **Widget:** "Spent this month: $1,840 / $2,000". **Notifications:** "Monthly budget November: 80% used".
**Stress:** 25 expense categories · category name 50 chars · amount `1,000,000,000,000` · note 200 chars · KWD `1,250.000` ·
20 savings goals · 30 debts · 99+ queue items · month with 10 000 records (Stats/Calendar) · negative total balance.

---

## 9. iOS notes
All 2.0 features exist on iPhone. Differences:
| Topic | iPhone | Android |
|---|---|---|
| Back | Visible back arrow + edge swipe on every pushed screen (**no tab bar on pushed screens**) | Arrow + system Back (Back on a root tab → Home → exit) |
| Email checks | Only when the app is opened/returned to (say so in the UI) | Also about hourly in the background |
| Auto backup | Chosen folder via Files; a notification at the chosen time, tap to back up; catches up on open | Background job, no notification |
| Widget | WidgetKit (iOS 16+) via App Group | AppWidget 2×2 / 4×2 |
| Hide in switcher | Brand cover (no screenshot blocking) | Secure window |
| Biometrics | Face ID / Touch ID | Fingerprint (strong biometrics only) |
| Reminder | Exact time | Approximate time |
Draw iPhone frames for every N‑screen; show the iPhone‑specific copy where it differs. Tab bar uses the platform's safe area;
keep the Material look (not Cupertino).

---

## 10. UX weak points → opportunities · Out of scope

### 10.1 Please solve in the design (within the feature set; behaviour changes = mark as proposal)
1. **Tab bar vs the − / + buttons on Home** — keep logging effortless; the buttons must stay the dominant elements.
2. **Where "Records" lives** now that the receipt icon moves (balance bar + More). Is that discoverable enough? Propose.
3. **Settings is long** — the regrouped layout (N‑05) is your chance to cut scanning cost; status chips for auto backup, email,
   notifications, biometrics.
4. **Account filter invisible** — show the active account as a chip on Home, Stats, Calendar, Records.
5. **"Balance" means two things** (period net on Home vs total balance on Overview) — name and place them so they cannot be confused.
6. **Queue speed** — 12 items must be clearable fast with one thumb; consider swipe, sticky bottom action bar, or pager.
   Prove it at 360 × 800 and at 200 % text.
7. **Imported money vs real money** — make it obvious that queue items are **not counted yet** (and where they will appear).
8. **Trust UI for email** — wording and visual calm so the permission feels safe; show where the password lives (phone only).
9. **Charts at a glance and for screen readers** — every chart needs a text table; colour never the only encoding.
10. **Empty states** for Overview, Stats, Calendar, Savings, Debts, Queue — friendly, not sad; point to the next action.
11. **Almost over vs Over** — distinct, accessible, not alarmist.
12. **Password dialogs** (backup, restore, auto backup, mailbox) should look like one family.

### 10.2 Out of scope — don't draw in main frames
- Cloud sync, sign‑in, servers; banks other than MB Bank; reading SMS or notifications; receipt photos/OCR; AI features.
- Multiple currencies at once; shared/family accounts; investments.
- Ads, subscriptions, Pro tier, analytics, crash SDKs. Tablet / landscape. Onboarding/tutorial.

---

## 11. Deliverables requested from Claude Design

### 11.1 Priority
1. **P0 — shell:** 5‑tab bar component + Home with tab bar/banner/badge + More hub + regrouped Settings (N‑05) — everything
   else hangs on these.
2. **P1 — new screens:** N‑01 Overview · N‑02 Stats · N‑03 Calendar · N‑08 Queue · N‑09 Email import · N‑06 Savings · N‑07 Debts ·
   N‑04 Time/Filter/rows · N‑10 Budget states · N‑12 Biometrics · N‑11 Export · N‑14 Currency conversion · N‑15 small components.
3. **P2 — refresh** every ✅/🟡 frame in Part A for consistency (keep their look).
4. **P3 — VI variants and 200 % text** for the screens in §11.2.

### 11.2 Frames
For **each platform** (Android 360 × 800 dp; iPhone 393 × 852 pt) × **light + dark**: every screen with its states.
- **VI variants** (light): Home, New entry, Overview, Stats, Calendar, Queue (item + currency note), Email import (add mailbox),
  Savings, Debts, More, Settings (all groups), Filter sheet, Conversion dialog, Lock.
- **200 % text** (one platform, light): Home with tab bar, Overview, Stats, Calendar, Queue, Savings, Debts, Add mailbox, Settings.
- **Stress:** see §8.
- **Prototype links** for flows F1–F12 (§7).

### 11.3 File naming (1:1 with routes)
`design/hifi/<platform>/<theme>/<NN>_<slug>__<state>.png` + matching HTML export. `<platform>` = `android|ios`, `<theme>` =
`light|dark`. Keep existing SCR numbers 01–33 and EXT numbers; **new numbers** continue from **34**:

| No. | Screen | Slug |
|---|---|---|
| 34 | Overview | `overview` |
| 35 | Statistics | `stats` |
| 36 | Calendar | `calendar` (`__day-panel`) |
| 37 | More hub | `more` |
| 38 | Settings (regrouped) | `settings` (`__top`, `__money`, `__data`) |
| 39 | Records filter | `entries~filter`, `entries__filtered` |
| 40 | Time field | `entry-new__time`, `entry-id__no-time` |
| 41 | Savings | `savings`, `savings~edit`, `savings__reached` |
| 42 | Debts | `debts`, `debts~edit`, `debts~detail`, `debts~payment` |
| 43 | Import queue | `queue` (`__suggested`, `__currency`, `__empty`), `queue~move`, `queue~skip`, `queue~suggestions` |
| 44 | Email import | `email-intro`, `email-add`, `email-connected`, `email-error`, `email-paused` |
| 45 | Budget states | `home__almost-over`, `overview__almost-over`, `settings~budget-warning` |
| 46 | Export Excel / PDF | `settings~export-range`, `export-pdf-preview` |
| 47 | Biometrics | `settings__biometric`, `lock__biometric` |
| 48 | Currency conversion | `settings~convert`, `settings~convert-error` |
| EXT‑03 | Budget notification | `ext-budget-notification` |
| 00 | App shell / tab bar | `shell~tabs` (component states) |

### 11.4 Design system page
- **Tokens** as JSON in the **same schema as `design/hifi/tokens/tokens.json`** + CSS variables; keep names; a changelog of
  added/removed/changed tokens. Required additions: `warning`, `on-warning`, `warning-container` (+ dark), tab‑bar tokens
  (height, indicator, label style), chart tokens (series colours for income/expense/line, gridline, axis label, selected
  highlight) and calendar cell tokens. Everything must map to Flutter `ColorScheme`, `ThemeExtension ViGonColors`,
  `TextTheme` (12 styles, tabular amounts) and `VgSpace/VgRadius/VgTap`.
- **Component sheet** (default, pressed, focused, disabled, error, selected; light + dark): **bottom navigation**, **stat tile**,
  **progress bar (goal, debt, budget — normal/almost/over)**, **bar chart (paired)**, **line chart**, **calendar grid cell**,
  **queue item card**, **suggested chip**, **source ✉ marker**, **status chip (OK / paused / error)**, **banner (queue)**, **filter
  chip (removable)**, **range sheet**, **segmented control (language)**, **stepper (threshold)**, plus all v2 components (ring,
  keypad, buttons, rows, dialogs incl. password forms, snackbar, PIN pad, widget, notification).
- **Motion notes** (150–250 ms, reduce‑motion aware): tab switch, chart draw‑in, goal progress fill, queue item saved → collapse,
  period/month change, keypad press, sheet open/close, snackbar.
- **Icon list:** final glyph for every new action/destination (tabs, Savings, Debts, Queue, Email, Filter, Export, Biometric, ✉).

### 11.5 Format
claude.ai link + HTML/PNG export per frame, saved into `apps/A002-vigon/design/hifi/` with §11.3 names. Include a short
**assumptions page** (what you decided where this brief left room) and the **token changelog**.

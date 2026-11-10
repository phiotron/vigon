# Vigon (Ví Gọn) — Product brief for Hi‑Fi UI design (v4, whole app)

> **What this file is for:** the brief to send to **Claude Design** to produce Hi‑Fi, UX‑optimised mockups of the
> **whole** mobile app **Vigon** (Vietnamese name **Ví Gọn**, "tidy wallet") on **Android + iOS**. It describes *what*
> every screen must do and *why*; *how it looks* is Claude Design's proposal, within the limits in §2 and §11.
>
> **Why v4:** v3 (2026‑11‑06) only described the 2.0 delta. Since then the app changed a lot (multi‑currency with a
> *main currency*, rates screen, onboarding, weekday repeats, regrouped Settings, inline About, email import live,
> savings wallets, deadline reminders…). v4 **replaces v3 completely** and describes the app **as it is now + what is
> still to be built**, so one brief covers everything.
>
> **Starting point:** the approved **Hi‑Fi P1 + P2 design system** in `design/hifi/` (tokens v2, Be Vietnam Pro, Material
> Symbols Rounded). **Upgrade, don't redesign:** keep token names, component vocabulary and the look of screens that
> already have a frame; draw everything that has none.
>
> Internal code `A002-vigon` · Bundle ID `com.phiotron.vigon` · Brief **v4 · 2026‑11‑10** (replaces v3).
> Glossary: `CONTEXT.md`. Behaviour spec: `docs/SPEC.md` (F‑01..F‑48, AC‑01..AC‑158). Decisions: `docs/DECISIONS.md`
> (D‑001..D‑044). Copy below is the **real copy** from `lib/l10n/app_en.arb` / `app_vi.arb` (shown `EN | VI`); copy that
> does not exist yet is marked **NEW:** — keep it, the developer adds it to both files.

**Status legend** (on every screen heading)
- ✅ **Built + drawn** — implemented and an approved frame exists in `design/hifi/`. Refresh only.
- 🔨 **Built, no frame** — implemented from shared components but never designed. **Draw it** (priority).
- 🆕 **Not built** — specified, waiting for this mockup. **Draw it.**
- 🟡 **Changed** — drawn before, but behaviour/layout changed since (see notes).
- 🤖 Android only · 🍏 iOS note in §9.

---

## Contents
1. Product overview
2. Design constraints
3. Business rules (complete)
4. Information architecture and navigation
5. Screens (A Home & logging · B Records · C Money structure · D Plans: budget, savings, debts · E Currency · F Email import · G Settings & data · H Security · I First run · J Insights to build)
6. Surfaces outside the app
7. Key flows
8. Sample data
9. iOS notes
10. UX weak points → opportunities · Out of scope
11. Deliverables

---

## 1. Product overview

### 1.1 One line
**Vigon** — record income and expenses in seconds, in any currency, see at a glance where the money went, save toward
goals, remember debts, and optionally let your **bank's receipt emails** fill in expenses — offline, no account, no ads,
no analytics, nothing sent to a developer server.

### 1.2 Problem
People who want to know where their money goes give up because apps take too many steps, ask for an account, or send
data away. Expats and travellers also juggle **several currencies** and get confusing totals. Vigon logs an expense in a
few seconds, adds everything up in **one main currency the user picks**, and keeps the original amount visible underneath.

### 1.3 Personas
| Persona | Situation | What they need from the UI |
|---|---|---|
| **Linh, 27, office worker (HCMC), Android, VI** | Pays several times a day, one hand, weak signal; MB Bank account | Widget → Expense → amount → category = saved. MB receipt emails land in a **queue** she clears with one thumb |
| **Minh, 20, student, iPhone, VI** | Small budget; saving for a laptop | Monthly budget + food limit, a savings goal with its own wallet, a reminder 7 days before the deadline |
| **Cô Hạnh, 52, keeps the family's market money, VI** | Not tech‑savvy, large system text, fears losing data | Big targets, 200 % text, plain words; automatic backup set once; debt memo with due‑date reminders |
| **Alex, 34, expat, EN, Android** | Main currency **USD**, cash in **VND**, card in **USD**, savings in **EUR** | Everything shown in USD on top, the original ₫/€ amount underneath; exact totals; exchange‑rate screen; Excel/PDF later |

### 1.4 Core jobs (priority order)
1. **Log an expense right after paying** — Home ring, − / +, widget, reminder notification.
2. **See where money went** — Home ring per period, Records list, (to build) Overview, Statistics, Calendar.
3. **Find and fix records** — list, search, edit, delete with undo, (to build) advanced filter.
4. **Plan** — monthly budget + category limits, **savings goals with their own wallet**, **debt memo**, deadline reminders.
5. **Handle several currencies without thinking** — main currency on top, original underneath, exact sums, rates screen.
6. **Clear the email import queue** — pick a category per MB Bank receipt.
7. **Keep data safe and private** — backup (manual/auto, encrypted), PIN, hide in app switcher, (to build) biometrics.

### 1.5 Design principles
1. **Offline & private by design.** No sign‑in, no cloud, no analytics. Network is used only for the daily exchange‑rate
   table and, if the user adds a mailbox, for reading bank receipt emails on the phone.
2. **Log an entry in ≤ 3 taps** (AC‑02, digits excluded): ring icon → digits → **Save**; **−** → digits → **Choose
   category** → tap category = **saved** (D‑018). Nothing may add a tap to this.
3. **Main currency first (NEW, D‑042).** Every amount shows the **main currency big on top** and, only when the record is in
   another currency, the **original amount small underneath**. One currency → one line.
4. **Calm, compact finance UI.** Numbers are the hero; colour sparingly; celebrate a finished savings goal once, quietly.
5. **Thumb zone first.** Primary actions in the bottom half; sheets over full pages for short tasks.
6. **Never colour alone.** Income/expense carry a sign or word; Almost over / Over / Overdue / Done carry icon + text.
7. **Forgiving.** Deletes have 5‑s Undo or a confirm; limits are explained ("Only $40.00 more needed").
8. **Same app on both platforms**, except OS‑owned behaviour (§9).

---

## 2. Design constraints

### 2.1 Platforms, frames, orientation
- **Android** (Material 3, edge‑to‑edge) and **iOS 16+** (adaptive Material, not Cupertino widgets). One shared layout.
- **Base frames:** Android **360 × 800 dp** (smallest supported) and iPhone **393 × 852 pt**; must hold at 412 × 915.
- **Portrait, phone only.** Respect safe areas (status bar, gesture bar, Dynamic Island, Home indicator).

### 2.2 Theme and visual system (keep)
- **Light / Dark / System** theme; every in‑app frame in both.
- Tokens: `design/hifi/tokens/tokens.json` (v2) → `lib/src/ui/tokens.g.dart`. Primary `#2E7D6B`/`#8CD5BF`; income
  `#2E7D32`/`#81C784`; expense `#C62828`/`#EF9A9A`; error `#BA1A1A`/`#FFB4AB`; 16 category colours `cat-01…16`. Type **Be
  Vietnam Pro** with **tabular figures**, 12 type styles. Icons **Material Symbols Rounded**.
- Keep token names; list every change (§11.4). Contrast ≥ 4.5:1 text / 3:1 large text & icons in both themes.
  **Needed:** a **warning** pair (`warning`, `on-warning`, `warning-container`) for *Almost over* and *Due soon*, distinct from
  `error` (*Over*, *Overdue*) and from `expense`; a **success** accent for *Goal completed* that is not the income green.
- Category colours/icons are **user data** (keys in backups) — keep the 16 slots and icon keys.
- **Brand (D‑009):** logo "two stacked cards" (bg `#0E5244`, back card `#8CD5BF` −14°, front `#F7FAF8` +8°, dot `#E65100`).
  Wordmark **Vigon** (EN) / **Ví Gọn** (VI). Never coins, $, piggy bank, wallet‑with‑flap, leaf or donut as the logo.

### 2.3 Accessibility (WCAG 2.2 AA)
- Touch targets ≥ 48 dp / 44 pt (`tap-min` 48, `tap-key` 56, `tap-main` 64).
- **Text scale up to 200 %** without clipping: at ≥ 130 % amounts move under row titles, segmented controls stack, areas
  above keypads scroll, button pairs wrap, the **two‑line money block** (main + original) stays together.
- Every control has a spoken label; every chart has a one‑sentence summary + hidden table; live regions for typed amounts and
  PIN progress; TalkBack and VoiceOver; 2 px focus ring; respect reduce‑motion.
- Two‑line money reads as one phrase: "3 dollars 85, original 100,000 dong".

### 2.4 Languages and copy length
- **English (default on first launch) and Vietnamese**, chosen in onboarding and in Settings (no "follow device").
  Draw every frame in **English**; draw **VI variants** for the screens in §11.2 (VI is ≈ 20–40 % longer).
- Widget button text and launcher label follow the device language (OS‑owned).
- Riskiest strings (EN | VI):

| Key | EN | VI | Where |
|---|---|---|---|
| `primaryCurrencyNote` | Totals, charts and the ≈ line use this currency… (to be rewritten, see S‑E1) | … | Settings |
| `emailIntroRead` | Vigon reads your bank's transfer receipt emails in the mailbox you add, then puts them in a queue for you to pick a category. | Ví Gọn đọc email biên lai chuyển tiền của ngân hàng trong hộp thư bạn thêm, rồi đưa vào hàng đợi để bạn chọn danh mục. | Email intro |
| `queueCurrencyNote` | The email is in {emailCurrency} but the account uses {appCurrency}. You'll enter the amount in the next step. | Email bằng {emailCurrency}, tài khoản đang dùng {appCurrency}. Bạn nhập số tiền ở bước tiếp theo. | Queue card |
| `debtsNote` | A reminder list only: it doesn't count in income, expenses or account balances. | Chỉ là sổ ghi nhớ: không tính vào thu, chi hay số dư tài khoản. | Debts header |
| `onboardingCurrencyHint` | Totals, charts and budgets use this currency. Your Cash account starts in it; you can add accounts in other currencies later. | Tổng, biểu đồ và ngân sách tính theo tiền tệ này. Tài khoản Tiền mặt cũng dùng tiền tệ này; sau này vẫn thêm được tài khoản tiền tệ khác. | Onboarding |
| NEW deadline notification | Debt with An: 2,000,000 ₫ left, due in 7 days | Khoản nợ với An: còn 2.000.000 ₫, đến hạn sau 7 ngày | Lock screen |

### 2.5 Money, currency and date formatting — **read this, it changed (D‑042)**
- **Every record has its own currency** (ISO 4217, ~156 codes, 0/2/3 decimals): accounts, records, transfers (sent and received
  amounts), repeating records, monthly budget, category limits, savings goals, debts and their payments.
- The user picks one **Main currency** (`primaryCurrency`: "Main currency | Tiền tệ chính"). **All totals, charts, budgets and
  balances are shown in it.**
- **Two‑line money block (core component, NEW behaviour):**
  - **Line 1 (big, `amount-*` style):** the amount **in the main currency**.
  - **Line 2 (small, `body-sm`, `on-surface-variant`):** the **original** amount in its own currency — **only when it differs**.
  - Same currency → only line 1. Missing rate → line 1 shows the original and line 2 reads `rateMissing` in `error` colour
    ("No rate for {from} to {to}. This amount is left out of totals." | "Không có tỷ giá từ {from} sang {to}. Số tiền này
    không vào tổng.").
  - Example (main USD): *Beef pho* → **$3.85** / 100,000 ₫ · *Taxi* → **$12.00** (USD, one line) · *Paris hotel* → **$108.70** / €100.00.
  - The old design (original big, "≈ main" small) is **wrong now** — redraw every place that shows it.
- **New records default to the main currency** with a **currency chip** to switch (S‑A3). Editing keeps the saved currency.
- **Exact sums (D‑042):** totals add originals per currency to the smallest unit, then convert and round **once**. Switching the
  main currency back and forth never changes any amount. A total may differ by a cent from adding the rounded rows by hand —
  that's fine, don't design a "rounding" note for it.
- Display follows app language: EN `$1,250.00`, `₫1,250,000`; VI `1.250.000 ₫`, `1.250,00 US$`. Negative `-$200.00`.
  Up to 10¹² minor units per amount; totals can be larger → hero numbers must scale or wrap.
- Percent one decimal (`53.7%` / `53,7%`). Short date `Nov 3, 2026` / `3 thg 11, 2026`; Today. Time `12:02` (device 12/24 h).
  Compact amounts (charts/calendar): EN `50K`, `1.2M`; VI `50k`, `1,2tr`.

---

## 3. Business rules (complete, as built + decided)

**Recording**
1. **Record (Entry)** = Expense or Income: amount > 0, category, account, date, optional **time** (new records default to now;
   old and generated ones show "No time set"), note ≤ 200, **currency** (default main currency), source (manual / MB email).
2. **Transfer** moves money between two accounts; ≠ income/expense; not in charts, totals, budgets. Different currencies →
   **sent** and **received** amounts are both entered and stored.
3. **Two balances:** *Period balance* (Home/Records: income − expense of the viewed period) vs *Account balance* (Accounts:
   starting balance + income − expense ± transfers, all time). Name them so they can't be confused.
4. **Period:** Day / Week / Month / Year / All time / Custom range ("View by" sheet); ‹ › or swipe; week start (Mon/Sun) and
   month start day (1–28) in Settings. Period and account filter live in memory only.
5. **Account filter** (when ≥ 2 visible accounts) applies to Home and Records.
6. Ring icons = expense categories in order; last slot **More categories (⋯)** when they don't fit.
7. **Save on category pick:** when the big key reads "Choose category", tapping a category saves (D‑018).
8. **Repeating records:** Daily · Weekly · **Choose days…** (weekday chips like an alarm; all 7 = Daily; if today isn't a chosen
   day, today's record is *not* saved and the first one is shown: "First: Fri 6/11") · Monthly · Yearly. Generated on open.
   Pause / resume; edit amount, note, frequency, category, account.
9. **Delete** a record → 5‑s **Undo** bar.

**Money structure**
10. **Accounts:** name, currency, starting balance (may be negative), visible/hidden. Hidden accounts still count in balances;
    delete only when unused; ≥ 1 visible account always. **Savings wallets** (rule 16) are normal accounts with a goal badge.
11. **Categories:** expense/income, name, icon (31), colour (16), order, optional **category limit** (expense). Deleting moves
    its records to another category of the same type.
12. **Currencies and rates:** main currency in Settings; rate table auto‑checked on open/return, downloaded at most once a day,
    "Update now"; offline → last saved table; never downloaded → built‑in fallback table (dated). **Rates screen** lists only
    **pairs in use** and lets the user **override** a rate (preview on the first account in that currency). Missing rate →
    amount left out of totals with a visible note.

**Plans**
13. **Monthly budget** (one total limit, current month by month start day, all accounts) → Home bar; **category limits** →
    small bars on Records category rows. Budget has its own **currency selector** (default main currency); shown main‑first.
    States: normal · **Almost over** (≥ threshold, default 80 %, adjustable 50–95 % — *to build*) · **Over by X**.
14. **Debts (memo only):** person, direction **I lent** / **I borrowed**, amount, currency (locked after first payment), date,
    optional due date, note; **payments** (never more than what's left: "More than the remaining {remaining}"); remaining 0 →
    **Settled** (collapsed section). Overdue → word + icon. Debts never touch accounts or totals. **Deleting a debt returns to
    the Debts list** (bug fixed — it used to jump to Settings).
15. **Deadline reminder (NEW, D‑044):** one global setting — on by default, **7 days** before (1–30), at **09:00** (changeable).
    Every savings goal and debt with a due date that isn't done gets a notification **N days before** and **on the due date**,
    **with the amount still left**, even when PIN lock is on (user's choice).
16. **Savings goal = its own wallet (NEW, D‑043):**
    - Creating a goal **always creates a new account** (the *wallet*), never links an existing one. Form: goal name, **Account**
      (wallet name, pre‑filled with the goal name), target amount + currency (default main), **Already saved** (wallet's
      starting balance, default 0), optional deadline.
    - Why: if a goal used "Cash" with 8,000,000 ₫ of food money, a 5,000,000 ₫ goal would be "done" instantly. A wallet starts at 0.
    - The wallet is a **normal account**: spend from it, receive into it, withdraw any time — even before the goal is done.
    - **Progress = wallet balance** (in the goal's currency) vs target.
    - **Add money** = transfer from any account into the wallet, **capped at what's still missing** ("Fill to target" button).
      **Withdraw** = transfer out, capped at the wallet balance.
    - **History** = every movement of the wallet (add +, withdraw −, spending/income recorded directly, the starting amount) —
      always sums to the balance; items deletable with Undo.
    - First time balance ≥ target → **"Savings goal reached"** dialog with the amount, goal moves to a collapsed **Done** section.
      **Done is permanent** (withdrawing later doesn't bring it back); **Reopen** in the goal detail.
    - Deleting a goal keeps the wallet as a normal account and every record.

**Import, data, privacy**
17. **Email import (MB Bank only):** up to 3 mailboxes (Gmail / Yahoo / iCloud) with an **app password** (Keystore/Keychain);
    read‑only; Android checks about hourly + on open, iPhone on open; only **successful outgoing transfers**. Each becomes a
    **queue item** — *not a record yet*, excluded from all totals — until the user picks a category, **Move to my account**
    (transfer), **Edit before saving** or **Skip**. Payee suggestions remembered. First email of an unknown MB account
    auto‑creates "MB Bank …1234". A record typed by hand that matches an email (same account, amount, ±2 h) is matched silently
    with an Undo bar. Email currency ≠ account currency → amount typed manually.
18. **Backup:** manual `.vigon` file (optional password, AES‑256‑GCM) via share sheet; **Restore** replaces everything after a
    check + confirm; **Auto backup** daily at a chosen hour (default 21:00) into a user‑picked folder, always encrypted, keeps 2
    files, status line. **CSV export** (language‑aware). (To build: Excel, PDF.)
19. **PIN lock** (4 digits) on open and after > 1 min in background, also from widget/notifications; it does **not** encrypt.
    Forgot PIN → only "Delete all data". **Hide content in app switcher.** (To build: fingerprint / Face ID on top of PIN.)
20. **Daily reminder** ("Have you recorded your spending today?") at a chosen time (default 20:00), **no figures**. **Budget
    notifications** (to build) show **percentages only**. **Deadline reminders** show amounts (rule 15).
21. **Onboarding** (fresh install only): Language → Welcome → Main currency → Reminder → PIN; Skip = defaults (English, USD,
    reminder off, no PIN).
22. **Delete all data:** two confirms; wipes everything incl. goals, debts, queue, mailboxes; recreates defaults.

---

## 4. Information architecture and navigation

### 4.1 Today (built)
- **Home `/`** is the root. App bar: title + account filter (when ≥ 2 accounts) + **Records** icon + **Settings** gear.
- Everything else is a pushed full screen or a bottom sheet with back/close. **Settings** is the hub for Categories, Accounts,
  Budget, Repeating, **Savings**, **Debts**, Main currency, Rates, Email import & Queue, Security, Reminder, Data, Appearance &
  language, About (9 titled groups, S‑G1).

### 4.2 Decided for 2.0 (draw it): 5‑tab shell
| Tab | Icon | Root | Contains |
|---|---|---|---|
| **Home** | `donut_large` | `/` | Home as today |
| **Overview** | `dashboard` | `/overview` | S‑J1 (to build) |
| **Stats** | `monitoring` | `/stats` | S‑J2 (to build) |
| **Calendar** | `calendar_month` | `/calendar` | S‑J3 (to build) |
| **More** | `menu` | `/more` | Hub: Records · Savings · Debts · Queue (badge) · Categories · Accounts · Repeating · Settings |

- Tab bar only on the 5 roots; pushed screens have no tab bar. **The − / + buttons on Home stay the strongest elements**; the bar
  must not add a tap to logging.
- Queue badge on More (and a one‑line Home banner "3 records waiting for a category").
- Deep links: widget/daily reminder → New entry; deadline reminder → Debt detail / Goal detail; budget notification → Overview.
  All through the PIN lock.
- **Deliver both:** the current Home+Settings navigation (refresh) **and** the 5‑tab shell — the app moves to tabs when J‑screens ship.

### 4.3 Routes
| Route | Screen | ID |
|---|---|---|
| `/onboarding` | First‑run steps | S‑I1 |
| `/` | Home | S‑A1 |
| `/entry/new?type=&category=` · `/entry/:id` | New / edit record | S‑A3 |
| `/entries` | Records + search | S‑B1 |
| `/transfer` · `/transfer/:id` | Transfer | S‑C3 |
| `/accounts` | Accounts | S‑C1 |
| `/categories` | Categories | S‑C2 |
| `/recurring` | Repeating records | S‑B3 |
| `/savings` | Savings (+ detail, editor, add/withdraw sheets) | S‑D2 |
| `/debts` | Debts (+ detail, editor, payment) | S‑D3 |
| `/rates` | Exchange rates | S‑E2 |
| `/import-queue` · `/import-queue/suggestions` | Queue · Remembered suggestions | S‑F2 |
| `/email-import` · `/email-import/add` | Email import · Add mailbox | S‑F1 |
| `/settings` | Settings | S‑G1 |
| overlay | Lock | S‑H1 |
| `/overview` `/stats` `/calendar` `/more` | to build | S‑J1..J4 |

### 4.4 Map
```
Home ─ ring icon / − / + / ⋯ ─► New record (keypad, currency chip, date, time, account, repeat, note)
     ─ balance bar / Records icon ─► Records ─ search
     ─ budget bar ─► Budget dialog
     ─ gear ─► Settings
Settings ─ Categories & accounts: Categories · Accounts
         ─ Plan: Monthly budget · Repeating · Savings · Debts · NEW Deadline reminder
         ─ Currency & period: Main currency · Exchange rates · Week start · Month start day
         ─ Email import: Import from bank email · Items awaiting a category
         ─ Security: PIN lock · Hide content in app switcher
         ─ Reminder: Daily reminder + time
         ─ Data: Backup · Restore · Auto backup · Export CSV · Delete all data
         ─ Appearance & language (sheet) · About (inline card)
Savings ─ goal card ─► Goal detail ─ Add money · Withdraw · History · Edit · Delete · Reopen
Debts ─ debt row ─► Debt detail ─ Add payment · Payments · Edit · Delete (→ back to Debts)
Outside: Widget · Daily reminder · NEW Deadline reminder · Budget notification (to build) · Recents cover
```

---

## 5. Screens

Per screen: **Status · Purpose · Components · States · Copy (EN | VI) · A11y.** Existing copy is in the `.arb` files; don't
invent new copy for unchanged screens.

### A — Home & logging

#### S‑A1 · Home `/` ✅🟡 (frames 01, 07)
**Purpose:** log fast; see the period at a glance.
**Components:** app bar (title, account filter chip *proposal: show the active account as a chip*, Records, Settings) ·
period header ‹ **November 2026** › (tap → "View by" sheet, swipe changes period) · **ring chart** of expenses by category
with the period total in the centre (**main currency**) and category icons around it (last slot ⋯) · **budget bar** (Spent X of
Y, Over by X; to build: Almost over) · **balance bar** (period income − expense, main currency, tap → Records) · big **− Expense**
/ **+ Income** buttons. Queue banner when items wait ("3 records waiting for a category").
**Changed:** every amount main‑currency; ring total uses exact sums.
**States:** empty (first launch: friendly, points to − / ring) · normal · many categories (⋯) · budget over · negative balance ·
filtered account · missing rate note ("1 amount left out — no rate") · 200 % · VI.

#### S‑A2 · "View by" sheet + range calendar ✅ (frame 02) · Account filter menu ✅ (03)
Refresh only.

#### S‑A3 · New / edit record `/entry/new`, `/entry/:id` 🟡 (frames 05, 06)
**Purpose:** type an amount and save in ≤ 3 taps.
**Components:** type toggle (Expense / Income) · **amount display** (live expression, e.g. `120+35`) with the **currency chip**
right next to it (**NEW**: `USD ▾`; default = main currency; tap → currency picker with search, recent/used currencies on top).
When the chosen currency ≠ main, show line 2 live: "≈ $3.85" under "100,000 ₫" *while typing* (input is in the chosen currency;
this preview is the one place the converted line sits under the input) · chip row: **Date** · **Time** (12:02 / No time set) ·
**Account** (sheet lists accounts with their balance, main‑first) · **Repeat** (sheet: None, Daily, Weekly, Choose days…, Monthly,
Yearly; "First: Fri 6/11" line) · **Note** · keypad (digits, `000`/`.`, ⌫, ÷ × − +, =) · big key **Choose category** / **Save**.
Edit adds: source line for email records ("From MB email · ref …4821"), Delete.
**States:** new expense · new income · currency ≠ main · missing rate for chosen currency (inline error, can't save) · Choose
days with first‑occurrence line · edit old record with no time · from email · 200 % (area above keypad scrolls) · VI.

#### S‑A4 · Category grid sheet ✅ (07–09) · Repeat sheet 🟡 (Choose days chips, frame 21 family) · Date/time pickers (OS)

### B — Records

#### S‑B1 · Records `/entries` ✅🟡 (frames 10, 11)
**Components:** period header + account filter · summary (income, expense, balance — main currency) · list grouped by day
(day header with day total) · **record row**: category avatar, note/title, account · time, ✉ marker for email records, and the
**two‑line money block** on the right (main big, original small) · category rows with limit bars · transfers section.
Search mode (frame 11): field, "All time" chip, results "N records · total X".
**Changed:** rows main‑first. *(To build: Filter button + chips — S‑J5.)*
**States:** empty period · many records · long notes · mixed currencies · search no match · 200 % · VI.

#### S‑B2 · Undo bar ✅ — "Deleted · Undo" 5 s.

#### S‑B3 · Repeating records `/recurring` ✅🟡 (frames 20, 21)
List of series (amount main‑first, frequency label incl. "Mon, Tue", next date, Paused); edit sheet with Choose days.

### C — Money structure

#### S‑C1 · Accounts `/accounts` ✅🟡 (frames 17, 18)
**Components:** total balance (main currency, exact) · account rows: icon, name, **currency code chip** (e.g. `VND`), balance as
two‑line block (main big / own currency small) · badges: **Savings wallet** (goal name chip, NEW), "From MB email" · hidden
accounts collapsible · edit sheet (name, currency, starting balance, hide/show, delete rules).
**States:** one account · mixed currencies · wallet accounts · hidden open · last visible · used vs unused · 200 % · VI.

#### S‑C2 · Categories `/categories` ✅ (15, 16) — refresh; limit field has its currency (main‑first display).

#### S‑C3 · Transfer `/transfer` ✅🟡 (frame 19)
From / To account pickers (balances main‑first), amount; **different currencies → two fields "You send" / "They receive"** with
the current rate shown and editable; date, time, note. Pre‑filled when opened from elsewhere.

### D — Plans: budget, savings, debts

#### S‑D1 · Monthly budget dialog ✅🟡 (frame 04)
Amount + **Currency** selector (default main); live line 2 in main currency when it differs; Remove budget. *(To build: "Warn me
at 80 %" link — S‑J6.)*

#### S‑D2 · Savings `/savings` 🔨🟡 — **redesigned (F‑47, D‑043), priority**
**List screen**
- App bar "Savings | Tiết kiệm", FAB **Add goal | Thêm mục tiêu**.
- **In progress** section: one card per goal — name, wallet name (small, with wallet icon), **progress bar + %**, "Saved {have}
  of {target} | Đã có {have} / {target}" (main‑first two‑line block when the goal currency ≠ main), "{amount} to go | Còn thiếu
  {amount}", deadline chip ("12 days left", **Due soon** in warning colour within the reminder window, "3 days overdue" in error),
  primary **Add money | Góp tiền**. Tap card → Goal detail.
- **Done (n)** collapsed section (NEW): goal name, ✓ **Done** + date reached, final amount.
- Empty: "No savings goals yet. Set a goal, then add money to it over time." + illustration (no piggy bank cliché — propose).
**Goal editor (sheet)** — NEW fields
1. **Goal name** (≤ 50) — NEW label "Goal name | Tên mục tiêu".
2. **Account** — wallet name (≤ 50), pre‑filled with the goal name. Label **"Account | Tài khoản"** (was "Linked account | Tài khoản
   gắn"). Helper NEW: "A new account just for this goal. Move money in with Add money. | Một tài khoản mới chỉ cho mục tiêu này.
   Chuyển tiền vào bằng Góp tiền."
3. **Target amount** + **currency bar** (default main currency; locked once the wallet has records — helper explains).
4. **Already saved** (optional, ≥ 0, default 0) — NEW "Already saved (optional) | Đã có sẵn (tuỳ chọn)"; helper "Money you've
   already put aside. It becomes the account's starting balance."
5. **Deadline (optional)** chip + Remove deadline.
6. Edit mode: Delete goal ("The account and all records stay. Only the goal is deleted.").
**Goal detail (sheet or page — propose)** — NEW, mirrors Debt detail
- Header: goal name, wallet name, status (In progress / ✓ Done / Overdue).
- Big progress ring or bar, "Saved X of Y", "Z to go", deadline, reminder hint ("We'll remind you 7 days before").
- Buttons: **Add money** (hidden when Done) · **Withdraw | Rút tiền** (NEW) · Edit · Delete · **Reopen | Mở lại** (Done only).
- **History | Lịch sử** (NEW): newest first; row = date, type icon + label (**Added from Cash** +, **Withdrew to Cash** −, **Spent:
  Flight tickets** −, **Already saved** +), amount (main‑first two‑line when needed), delete (with Undo). Footer: "Balance {amount}".
**Add money sheet** (NEW): amount field in the goal currency with **Fill to target** chip; **From account** list = every visible
account except the wallet, each with its balance (main‑first two‑line); date; error "Only {amount} more needed | Chỉ cần góp
thêm {amount}"; cross‑currency note "Sends ≈ 2,550,000 ₫ from Cash at today's rate". Save.
**Withdraw sheet** (NEW): amount ≤ wallet balance (error "Only {amount} in this account"), **To account**, date. Save.
**Goal reached dialog** (NEW): calm celebration (subtle confetti or check burst, reduce‑motion aware), title **"Savings goal
reached | Tiết kiệm thành công"**, body "You've saved {amount} for {goal}. | Bạn đã đủ {amount} cho {goal}.", buttons **Great |
Tuyệt** · **Withdraw**. The card then animates into Done.
**States:** empty · 1 goal · 6 goals · goal in EUR with main USD · just reached (dialog) · Done list · withdrawn after done (still
Done) · overdue · due soon · add‑money over the cap (error) · only one other account · long names · 200 % · VI · dark.

#### S‑D3 · Debts `/debts` 🔨🟡 (F‑34)
**List:** header note `debtsNote`; two groups with totals (main currency) — **Owed to you | Người khác nợ bạn** and **You owe |
Bạn nợ người khác**; row = person, remaining (two‑line), "Paid {paid} of {total}" mini bar, due chip (**Due soon** warning /
**Overdue** error with icon); collapsible **Settled (n)**; Add debt.
**Editor:** Person · Direction segmented (I lent / I borrowed) · Amount + **currency bar** (default main; locked after first
payment) · Date · Due date (optional) · Note.
**Detail:** person, direction, amount, date, due, note, big **Remaining**, **Payments** list (date, amount, delete), **Add payment**
(amount ≤ remaining; "More than the remaining {remaining}"; propose a "Pay the rest" chip), Edit, **Delete → closes the detail and
stays on Debts** (snackbar "Debt deleted").
**States:** empty · both groups · foreign‑currency debt · overdue · due soon · settled · 200 % · VI · dark.

#### S‑D4 · Deadline reminder setting + notification 🆕 (F‑48, D‑044)
- Settings → Plan → row **"Deadline reminders | Nhắc trước hạn"** (NEW) with value "7 days before · 09:00 | Trước 7 ngày · 09:00".
  Opens a sheet: switch (default on), **Days before** stepper/picker 1–30 (default 7), **Time** (system time picker, default
  09:00), note "For savings goals and debts with a due date. Notifications show the amount left." First turn‑on → explain dialog
  → OS permission; denied → switch off + "Open settings".
- **Notification (lock screen + shade, Android + iOS, light + dark):** title "Vigon"; body examples —
  "Debt with An: 2,000,000 ₫ left, due in 7 days" · "You owe Bình: $500.00 left, due today" · "Goal Trip: €300.00 to go, due in
  7 days" (VI: "Khoản nợ với An: còn 2.000.000 ₫, đến hạn sau 7 ngày" · "Bạn nợ Bình: còn 500,00 US$, đến hạn hôm nay" ·
  "Mục tiêu Du lịch: còn thiếu 300,00 €, hạn sau 7 ngày"). Amount in the item's own currency. Tap → detail.

### E — Currency

#### S‑E1 · Main currency 🟡 (frame 13)
Settings → Currency & period → **Main currency** → searchable picker (current pinned). After choosing: snackbar
`primaryCurrencyChanged` ("Main currency is now {currency}. The amounts you entered are unchanged."). No conversion dialog any more
(v3's N‑14 is obsolete). **Rewrite `primaryCurrencyNote`** NEW: "Everything is shown and added up in this currency. Amounts
recorded in other currencies keep their original value, shown underneath." | "Mọi số được hiển thị và cộng theo tiền tệ này.
Khoản ghi bằng tiền tệ khác giữ nguyên số gốc, hiện ở dòng dưới."

#### S‑E2 · Exchange rates `/rates` 🔨
Intro `ratesIntro`; status chip (Auto · updated today / Offline · rates from yesterday / Built‑in estimate / Set by you); **Update
now**; list of **pairs in use** only ("1 VND equals 0.0000385 USD"), each tappable → override sheet (auto value, "Your rate · 1 EUR
=", preview "Cash: 500,000 ₫ ≈ $19.25", Save this rate / Restore automatic); offline banner; source attribution link.
**States:** auto · offline · built‑in · manual override · no pairs ("Everything is in USD, so there's nothing to convert.") · 200 %.

#### S‑E3 · Currency picker ✅🟡 — reused by record, account, budget, debt, goal; show "In use" group on top.

### F — Email import

#### S‑F1 · Email import `/email-import`, `/email-import/add` 🔨
Intro (title `emailIntroTitle`, four reassurance lines with icons, `emailIntroBanks`, iPhone note, **Add mailbox**) → Add mailbox
(provider Gmail/Yahoo/iCloud, address, app password with show toggle, numbered steps per provider + "Open the app password page",
Connect → progress → Connected / error variants) → mailbox list (status chip Connected / Paused, last check, "2 MB emails couldn't
be read", Re‑enter password, Remove mailbox confirm; schedule note Android vs iPhone; max 3).

#### S‑F2 · Queue `/import-queue` + Remembered suggestions 🔨 — **important**
Item cards: date + time, amount (two‑line if the email currency ≠ main), payee (or "Unknown payee"), content, "From MB Bank
…4821", ✉; category grid with **Suggested** pre‑selected → **Save to Food**; secondary **Edit before saving · Move to my account ·
Skip** (confirm). Currency‑mismatch note. Auto‑created account card ("Created account MB Bank …4821 · Attach to an existing account
· Dismiss"). Pull to check. Empty state `queueEmpty`. Suggestions screen: payee → category/account, delete.
Must clear 2 items without scrolling at 360 × 800 and work at 200 %.

#### S‑F3 · Match bar ✅‑ish — "Matched with MB email 12:02 · Undo".

### G — Settings & data

#### S‑G1 · Settings `/settings` 🔨🟡 (frame 12 is the old layout)
Nine titled groups of cards (as built): **Categories & accounts** (Categories, Accounts) · **Plan** (Monthly budget, Repeating
records, Savings, Debts, **NEW Deadline reminders**) · **Currency & period** (Main currency, Exchange rates with status, Week start,
Month start day) · **Email import** (Import from bank email · status, Items awaiting a category · count) · **Security** (PIN lock +
warning, Hide content in app switcher 🤖/🍏) · **Reminder** (Daily reminder switch, Reminder time) · **Data** (Backup, Restore, Auto
backup section with folder/status/Back up now, Export CSV, Delete all data last) · **Appearance & language** (one row opening a
sheet: Theme System/Light/Dark + Language English/Tiếng Việt) · **About** (inline card: Version `1.0.0 (1)`, Privacy policy, Terms
of use, Open‑source licences, Rate Vigon 🤖, Send feedback, Report a security issue; footer "Data is stored only on this phone…").
Use status chips/values on the right (e.g. "Auto · today", "1 mailbox", "3 awaiting", "7 days before · 09:00").
**States:** top / middle / bottom scroll positions · iOS (no Rate row) · 200 % · VI · dark.

#### S‑G2 · Backup / restore / password dialogs / CSV / delete all ✅ (26–29) · Auto backup ✅ (31) — refresh; make all password
dialogs one family.

#### S‑G3 · Legal page (offline reader) 🔨 — opened when the browser can't; simple readable article.

### H — Security

#### S‑H1 · Lock / Set PIN / Forgot PIN ✅ (23–25) — refresh. *(To build: biometric — S‑J8.)*

### I — First run

#### S‑I1 · Onboarding `/onboarding` 🔨 (F‑44)
Five steps with "Step n of 5", Skip on steps 2–5, system Back steps back:
1. **Choose your language** (English pre‑selected / Tiếng Việt, applies instantly).
2. **Welcome to Vigon** — three benefits (Record in 3 taps · See where your money goes · Private by design) + **Get started**.
3. **Your main currency** — USD pre‑selected, USD / VND quick options + "Choose another currency…"; hint `onboardingCurrencyHint`.
4. **A daily reminder to record** — time 20:00 (tap to change), **Turn on reminder** (asks OS permission) / **Not now**.
5. **Lock Vigon with a PIN?** — **Set a PIN** / Not now.
**States:** each step light/dark, VI, 200 %, permission denied bar.

### J — Insights and extras to build (🆕, from SPEC 3d — draw them; all amounts main‑currency, exact sums)

#### S‑J1 · Overview `/overview` 🆕 (F‑35)
Own month ‹ › · **Total balance** (all accounts incl. hidden, main currency) · tiles **Income − expenses** and **Budget left** (Over
by X / Set a budget / Almost over) · **6‑month income vs expense bars** · **vs last month** (Spending up 25 % … arrow + words; "—"
when last month is 0) · optional strips: top savings goal, debts owed/you owe. States: empty month, no budget, almost over, over,
negative total, queue items not counted note, 200 %.

#### S‑J2 · Statistics `/stats` 🆕 (F‑36)
Period header + View by + account filter · income/expense bars by sub‑period (Week → days, Month → days, Year → months, All →
years; custom ≤ 31 d days, ≤ 366 d months, else years) · **Top 5 spending categories** (amount, % bar) · **Biggest spending day** ·
**Balance history** line. Empty period = one empty state, never empty charts. Must feel instant with 10 000 records.

#### S‑J3 · Calendar `/calendar` 🆕 (F‑38)
Month grid (week‑start aware), each day shows compact spend (`50K` / `1,2tr`) and a dot for income; tap → day panel with totals and
the day's records (edit, swipe delete + Undo). A11y "November 6, spent $250.00, income recorded".

#### S‑J4 · More hub `/more` 🆕 — rows with small status: Records · Savings "2 in progress" · Debts "$80 owed to you" · Queue "3
waiting" · Categories · Accounts · Repeating · Settings.

#### S‑J5 · Records filter 🆕 (F‑39) — Filter button beside search → sheet: amount range From/To (error if From > To), categories
multi‑select (expense + income), date range; Clear / Apply; removable chips; header "12 records · spent $420.00 · income $0.00".

#### S‑J6 · Budget warnings 🆕 (F‑37) — Almost over state on Home bar, Overview tile, category rows; Settings "Warn me at 80 %"
(50–95, step 5, live example) + **Budget notifications** switch (default off). Notification **percentages only**: "Monthly budget
November: 80% used" · "Food: 100% of the November limit used".

#### S‑J7 · Export Excel & PDF 🆕 (F‑40) — Data group: Export CSV · Excel · PDF; range sheet (current period / custom / all time),
what's included, progress, share sheet; empty range message; **A4 PDF preview** (title "Income & expense report — November 2026",
totals, category table with %, records table; Be Vietnam Pro).

#### S‑J8 · Biometric unlock 🆕 (F‑41) — Security switch "Unlock with fingerprint" / "Face ID / Touch ID" (only when PIN on; disabled
with reason when not enrolled); Lock states: prompt auto‑shown, fallback PIN with biometric retry button, cancelled, OS‑locked.

---

## 6. Surfaces outside the app
| EXT | Surface | Status | Notes |
|---|---|---|---|
| 01 | Home‑screen widget 2×2 / 4×2 (Android, iPhone) | ✅ | Expense / Income buttons; amounts only if allowed and PIN off; "Open the app to update" |
| 02 | Daily reminder notification | ✅ | Generic text, no figures |
| 03 | Budget notification | 🆕 | Percentages only |
| 04 | Recents / app‑switcher cover | ✅ | Blank with logo |
| 05 | OS sheets & pickers | — | Share sheet, file/folder picker, time picker, permission prompt, biometric prompt |
| 06 | App icon incl. Android monochrome | ✅ | unchanged |
| **07** | **Deadline reminder notification** | 🆕 | **With amount left** (S‑D4); separate channel "Deadline reminders" |

---

## 7. Key flows (prototype these)
- **F1 Log an expense:** ring **Food** → `4.50` → Save (2 taps) · − → amount → Choose category → Food = saved (3 taps).
- **F2 Log in another currency:** main USD → − → tap currency chip → VND → `100000` (preview "≈ $3.85") → Food → saved; the row
  shows **$3.85** with 100,000 ₫ underneath.
- **F3 Switch main currency:** Settings → Main currency → VND → snackbar; Home ring, Records, Accounts now show ₫ big and the
  original $ amounts underneath; switch back → identical numbers.
- **F4 Savings goal end‑to‑end:** Savings → Add goal "Trip", account "Trip fund", target 5,000,000 ₫, already saved 1,000,000 ₫,
  deadline Dec 31 → card 20 % → Add money 2,000,000 ₫ from Cash → History shows it → try 3,000,000 ₫ more → error "Only
  2,000,000 ₫ more needed" → Fill to target → **Savings goal reached** dialog → card moves to Done → Withdraw 500,000 ₫ to Cash →
  still Done.
- **F5 Spend from the wallet before done:** New record → account "Trip fund" → 300,000 ₫ flight deposit → goal progress drops,
  History shows "Spent: flight deposit".
- **F6 Debt:** Add debt "An owes me" $100, due in 10 days → payment $40 → try $70 → error → "Pay the rest" $60 → Settled → delete
  → stays on Debts.
- **F7 Deadline reminder:** Settings → Deadline reminders → 7 days · 09:00 → (7 days before) lock‑screen notification "Debt with
  An: $60.00 left, due in 7 days" → tap → PIN → Debt detail.
- **F8 Rates:** Settings → Exchange rates → offline banner → tap VND pair → set own rate → preview → Save → totals update.
- **F9 Queue:** banner → Queue → Suggested Food → Save to Food; next → Shopping; next → Move to my account; next → Skip.
- **F10 Add a mailbox:** Email import → intro → Add mailbox → Gmail → steps → Connect → Connected.
- **F11 Onboarding:** fresh install → Tiếng Việt → Bắt đầu → VND → Bật nhắc → Để sau → Home empty state.
- **F12 To build:** Overview → Stats → Calendar; Filter; Budget warning; Export PDF; Biometrics.

---

## 8. Sample data for mockups
**Main currency USD** (EN frames); VI frames use **main VND** with the same data. Mock today **2026‑11‑26**, period **November 2026**.
Rates (built‑in style): 1 USD = 25,974 VND · 1 EUR = 1.087 USD.

**Accounts:** Cash **VND** start 2,000,000 ₫ → balance **$238.70 / 6,200,000 ₫** · Bank card **USD** $900.00 · E‑wallet **VND**
1,040,000 ₫ → $40.04 / 1,040,000 ₫ · **MB Bank …4821** VND (from email) 0 ₫ · Savings wallets: **Trip fund** VND 4,000,000 ₫
(goal Trip) · **Laptop fund** USD $300.00 · **Paris fund** EUR €250.00 · hidden: Old credit card USD −$50.00. Long name: "Family
savings account for the house deposit".
**November expenses** (main USD, exact total **$1,840.00**): Home $540.00 (29.3 %) · Food $495.00 · Shopping $215.00 · Bills $170.00 ·
Transport $130.00 · Family $90.00 · Entertainment $80.00 · Health $50.00 · Other $20.00 · Education none.
**Income:** Salary $2,300.00 + Bonus $200.00. **Period balance** $660.00. **Monthly budget** $2,000.00 → 92 % (Almost over);
over variant $1,700 → "Over by $140.00". Category limits: Food $450 → Over by $45.00 · Transport $160 → 81 %.
**Records (mixed currencies, main‑first):** Nov 26 12:02 "Beef pho" Food **$3.85** / 100,000 ₫ ✉ · Nov 25 18:40 "Groceries" Food
**$32.00** · Nov 24 "Hotel deposit" Entertainment **$108.70** / €100.00 · Nov 20 "Electricity" Bills **$26.18** / 680,000 ₫ · Nov 18
07:50 "Ride to work" Transport **$3.50** · Nov 1 "November rent" Home **$540.00** (repeating, no time) · Nov 10 Transfer Bank card →
Cash **$200.00** → received 5,194,800 ₫ · Missing‑rate variant: "Gift" 50,000 XAF → "No rate for XAF to USD…".
**Savings (In progress):** Trip — target 5,000,000 ₫ (**$192.50**), saved 4,000,000 ₫ → 80 %, due Dec 3 → **Due soon** (7 days) ·
Laptop — $300 of $1,200 (25 %), due Mar 1, 2027 · Paris — €250 of €800 (**$271.75 of $869.60**), no deadline. **Done (1):** Emergency
fund — $1,500 reached Oct 12. History of Trip: Nov 1 Already saved +1,000,000 ₫ · Nov 5 Added from Cash +2,000,000 ₫ · Nov 12 Spent:
flight deposit −300,000 ₫ · Nov 20 Added from E‑wallet +1,300,000 ₫ → balance 4,000,000 ₫.
**Debts:** Owed to you — An $100 (paid $40 → **$60 left**, due Dec 3 → Due soon), Tuấn 500,000 ₫ (**$19.25** / 500,000 ₫, due Nov 20 →
Overdue) · You owe — Landlord $30 · Settled (1): Minh $15.
**Notifications:** deadline "Debt with An: $60.00 left, due in 7 days" · daily reminder · (to build) budget "Monthly budget November:
80% used".
**Queue (3, MB VND):** 50,000 ₫ "LE VAN KHACH — tra tien com" Suggested Food · 1,200,000 ₫ "CONG TY ABC" · 2,000,000 ₫ to own e‑wallet.
**Rates screen:** pairs VND→USD (auto, today), EUR→USD (Set by you: 1.090).
**Stress:** 25 categories · 50‑char names · amount `1,000,000,000,000` · 200‑char note · KWD `1,250.000` · 20 goals · 30 debts · 99+
queue · 10 000 records · negative total balance · 6 currencies in use.

---

## 9. iOS notes
| Topic | iPhone | Android |
|---|---|---|
| Back | Back arrow + edge swipe | Arrow + system Back |
| Email checks | Only on open/return | Also ~hourly in background |
| Auto backup | Folder via Files; a notification at the chosen time, tap to back up | Background job |
| Widget | WidgetKit (iOS 16+) | AppWidget 2×2 / 4×2 |
| Hide in switcher | Brand cover | Secure window |
| Reminders (daily + deadline) | Exact time | Approximate time (daily); deadline exact‑ish |
| Rate the app | Hidden until App Store id exists | Opens Play |
| Biometrics (to build) | Face ID / Touch ID | Fingerprint (strong only) |
Draw iPhone frames for every 🔨/🆕 screen; Material look, iOS safe areas.

---

## 10. UX weak points → opportunities · Out of scope

### 10.1 Please solve in the design
1. **Two‑line money everywhere** — make main‑first + original‑below one clean component that works in rows, cards, totals, sheets,
   at 200 % and in VI; never confuse it with "income vs expense" colour.
2. **Savings wallet mental model** — make it obvious a goal has *its own* account (badge in Accounts, wallet name on the card), that
   Add money moves money from another account, and that withdrawing is allowed.
3. **Caps that teach** — Add money / payment limits should prevent errors gracefully ("Fill to target", "Pay the rest") rather than
   only showing red text.
4. **Goal reached moment** — rewarding but calm; Done section that still feels like an achievement list.
5. **Due soon vs Overdue** — warning vs error, with words; consistent across savings, debts, notifications.
6. **Settings length** — 9 groups; use right‑side status values so users don't open rows to check state.
7. **"Balance" means two things** — period net vs account/total balance; name and place them distinctly.
8. **Account filter visibility** — active account as a chip.
9. **Queue speed** — one thumb, 12 items fast.
10. **Empty states** for Savings, Debts, Queue, Rates (no pairs), Overview/Stats/Calendar.
11. **Password dialogs** (backup, restore, auto backup, mailbox) as one family.

### 10.2 Out of scope — don't draw
Cloud sync, sign‑in, servers; banks other than MB; SMS / notification reading; receipt photos / OCR; AI; shared/family accounts;
investments; historical exchange rates; ads, subscriptions, analytics; tablet/landscape.

---

## 11. Deliverables

### 11.1 Priority
1. **P0 — money component + changed core:** two‑line money block (all contexts), Home, New record with currency chip, Records,
   Accounts, Transfer cross‑currency, Budget dialog.
2. **P1 — Plans:** Savings (list, editor, detail + history, add money, withdraw, reached dialog, Done), Debts (list, editor, detail,
   payment), Deadline reminder setting + notification.
3. **P2 — built but never drawn:** Settings (9 groups) + Appearance sheet + About card, Rates + override, Onboarding 5 steps, Email
   import, Queue + suggestions, Legal reader.
4. **P3 — to build:** 5‑tab shell + More, Overview, Stats, Calendar, Filter, Budget warnings, Export, Biometrics.
5. **P4 — refresh** remaining ✅ frames; VI variants; 200 % text.

### 11.2 Frames
Each platform (Android 360 × 800 dp; iPhone 393 × 852 pt) × light + dark, every screen with its states.
- **VI variants** (light, main VND): Home, New record (currency chip), Records, Accounts, Savings list + detail + editor, Add money,
  Reached dialog, Debts + detail, Deadline reminder sheet + notification, Settings (all groups), Rates, Onboarding, Queue.
- **200 % text** (one platform, light): Home, New record, Records, Accounts, Savings list + detail, Debts detail, Settings, Rates,
  Onboarding step 3, Queue.
- **Prototype links** for F1–F11.

### 11.3 File naming
`design/hifi/<platform>/<theme>/<NN>_<slug>__<state>.png` + HTML. Keep numbers 01–33 and v3's 34–48; new numbers:

| No. | Screen | Slug examples |
|---|---|---|
| 00 | Money block + shell components | `money~two-line`, `shell~tabs` |
| 41 | Savings (redesigned) | `savings`, `savings__done-open`, `savings~edit`, `savings~detail`, `savings~detail__done`, `savings~add-money`, `savings~add-money__cap`, `savings~withdraw`, `savings~reached` |
| 42 | Debts | `debts`, `debts~edit`, `debts~detail`, `debts~payment`, `debts~payment__over` |
| 49 | Onboarding | `onboarding__1-language` … `__5-pin` |
| 50 | Exchange rates | `rates`, `rates__offline`, `rates~override`, `rates__none` |
| 51 | Deadline reminders | `settings~deadline-reminder`, `ext-deadline-notification` |
| 52 | Appearance & language sheet / About card | `settings~appearance`, `settings__about` |
| 53 | New record currency chip | `entry-new__currency`, `entry-new~currency-picker` |
| 54 | Transfer cross‑currency | `transfer__two-currencies` |
| 55 | Legal reader | `legal` |
| 34–40, 43–48 | as v3 (Overview, Stats, Calendar, More, Settings, Filter, Time, Queue, Email, Budget states, Export, Biometrics); **48 Currency conversion is obsolete — skip** | |

### 11.4 Design system page
- **Tokens** as JSON in the schema of `design/hifi/tokens/tokens.json` + CSS variables; keep names; changelog. Required additions:
  `warning` / `on-warning` / `warning-container`, `success` accent for Done, tab‑bar tokens, chart tokens, calendar cell tokens,
  **money block** spec (line 1 / line 2 styles, spacing, alignment start/end, 200 % behaviour).
- **Component sheet** (default, pressed, focused, disabled, error, selected; light + dark): two‑line money block, currency chip,
  currency bar (form field), progress bar (goal / debt / budget: normal · due soon / almost · over / overdue · done), history row,
  amount field with "Fill to target" chip, account picker row with balance, celebration dialog, status chip, stepper (days before),
  bottom navigation, stat tile, bar/line chart, calendar cell, queue card, suggested chip, ✉ marker, banner, filter chip, segmented
  control, plus all v2 components (ring, keypad, rows, dialogs, snackbar, PIN pad, widget, notification).
- **Motion** (150–250 ms, reduce‑motion aware): progress fill, goal → Done, reached burst, sheet open/close, period change, keypad.
- **Icon list** for every new action (Add money, Withdraw, History, Wallet, Deadline reminder, Reopen, Currency chip).

### 11.5 Format
claude.ai link + HTML/PNG per frame into `apps/A002-vigon/design/hifi/` with §11.3 names, plus an **assumptions page** (what you
decided where this brief left room) and the **token changelog**.

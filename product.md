# Vigon (Ví Gọn) — Product brief for Hi‑Fi UI design (v5, whole app)

> **What this file is for:** the brief to send to **Claude Design** to produce Hi‑Fi, UX‑optimised mockups of the
> **whole** mobile app **Vigon** (Vietnamese name **Ví Gọn**, "tidy wallet") on **Android + iOS**. It describes *what*
> every screen must do and *why*; *how it looks* is Claude Design's proposal, within the limits in §2 and §11.
>
> **Why v5:** the **v4 mockups (227 frames, tokens v3)** were delivered and applied on 2026‑11‑10. On 2026‑11‑11 the owner
> tested the app and decided five things that change screens: **(1) you can't spend money an account doesn't have**
> ("có thu mới có chi"), **(2) the account you filter by is the account you log into**, **(3) every money field for
> add money / withdraw / lend / borrow / repay starts in the main currency with a currency chip**, **(4) debts go through
> real accounts and can carry an interest rate (% per month or per year, bank‑style)**, **(5) the remaining 2.0 features
> are built now**: Overview, Statistics, Calendar, Advanced filter, Budget warnings, Excel/PDF export, Fingerprint/Face ID.
> v5 **replaces v4**: the whole app in one brief, every screen tagged with what to draw.
>
> **Starting point:** the approved **v4 design system** in `design/hifi/` (tokens v3, Be Vietnam Pro, Material Symbols
> Rounded, 227 frames). **Upgrade, don't redesign:** keep token names, components and every ✅ frame; draw only 🟡 and 🆕.
>
> Internal code `A002-vigon` · Bundle ID `com.phiotron.vigon` · Brief **v5 · 2026‑11‑11** (replaces v4).
> Glossary: `CONTEXT.md`. Behaviour spec: `docs/SPEC.md` (F‑01..F‑52, AC‑01..AC‑177; new in **§3h**). Decisions:
> `docs/DECISIONS.md` (D‑001..D‑049; this brief's changes are **D‑046..D‑049**; D‑045 = exact‑time reminders). Copy below is the **real copy** from `lib/l10n/app_en.arb` /
> `app_vi.arb` (shown `EN | VI`); copy that does not exist yet is marked **NEW:** — keep it, the developer adds it to both files.

**Status legend** (on every screen heading)
- ✅ **Built + drawn (v4)** — an approved v4 frame exists. **Don't redraw** unless a state below is listed as new.
- 🟡 **Changed** — drawn in v4, but behaviour/fields changed (see "Changed:" notes). **Redraw the listed frames/states.**
- 🆕 **New** — no frame yet (most are being coded now with placeholder UI). **Draw it, all states.**
- 🤖 Android only · 🍏 iOS note in §9.

### Scope of this brief
Everything in the app. **Draw:** every 🟡 and 🆕 item (summary in §11.1). The five changes above touch Home, New record,
Records, Accounts, Transfer, Savings add/withdraw, the whole Debts area, the Queue, and add a **navigation proposal** for the
new screens (§4.2).

---

## Contents
1. Product overview
2. Design constraints
3. Business rules (complete)
4. Information architecture and navigation
5. Screens (A Home & logging · B Records · C Money structure · D Plans: budget, savings, debts · E Currency · F Email import · G Settings & data · H Security · I First run · **J Insights — new**)
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
| **Alex, 34, expat, EN, Android** | Main currency **USD**, cash in **VND**, card in **USD**, savings in **EUR** | Everything shown in USD on top, the original ₫/€ amount underneath; exact totals; exchange‑rate screen |

### 1.4 Core jobs (priority order)
1. **Log an expense right after paying** — Home ring, − / +, widget, reminder notification.
2. **See where money went** — Home ring per period, Records list.
3. **Find and fix records** — list, search, edit, delete with undo.
4. **Plan** — monthly budget + category limits with **"almost over" warnings**, **savings goals with their own wallet**,
   **debts that move real money (with interest)**, deadline reminders.
5. **Understand the month** — **Overview** (balance, this month vs last, budget left, debts), **Statistics**, **Calendar**.
6. **Handle several currencies without thinking** — main currency on top, original underneath, exact sums, rates screen; every
   money field starts in the main currency.
7. **Clear the email import queue** — pick a category per MB Bank receipt.
8. **Keep data safe and private** — backup (manual/auto, encrypted), PIN + fingerprint/Face ID, hide in app switcher, Excel/PDF
   export.

### 1.5 Design principles
1. **Offline & private by design.** No sign‑in, no cloud, no analytics. Network is used only for the daily exchange‑rate
   table and, if the user adds a mailbox, for reading bank receipt emails on the phone.
2. **Log an entry in ≤ 3 taps** (AC‑02, digits excluded): ring icon → digits → **Save**; **−** → digits → **Choose
   category** → tap category = **saved** (D‑018). Nothing may add a tap to this.
3. **Main currency first (NEW, D‑042).** Every amount shows the **main currency big on top** and, only when the record is in
   another currency, the **original amount small underneath**. One currency → one line.
4. **Calm, compact finance UI.** Numbers are the hero; colour sparingly; celebrate a finished savings goal once, quietly.
5. **Thumb zone first.** Primary actions in the bottom half; sheets over full pages for short tasks.
6. **Never colour alone.** Income/expense carry a sign or word; Over / Due soon / Overdue / Done carry icon + text.
7. **Forgiving.** Deletes have 5‑s Undo or a confirm; limits are explained ("Only $40.00 more needed").
8. **Same app on both platforms**, except OS‑owned behaviour (§9).
9. **No spending what you don't have (NEW, D‑046).** An account can't go below zero unless the user marks it "Allow negative
   balance" (credit card). A blocked save must **say how much is there and offer the way out** (top up, pick another
   account) — never a dead end.
10. **The context you're in is the default (NEW, D‑047).** Filtered to *Trip* → new records, transfers, lending all start on *Trip*.

---

## 2. Design constraints

### 2.1 Platforms, frames, orientation
- **Android** (Material 3, edge‑to‑edge) and **iOS 16+** (adaptive Material, not Cupertino widgets). One shared layout.
- **Base frames:** Android **360 × 800 dp** (smallest supported) and iPhone **393 × 852 pt**; must hold at 412 × 915.
- **Portrait, phone only.** Respect safe areas (status bar, gesture bar, Dynamic Island, Home indicator).

### 2.2 Theme and visual system (keep)
- **Light / Dark / System** theme; every in‑app frame in both.
- Tokens: `design/hifi/tokens/tokens.json` (**v3**, already has `warning*` and `success*`) → `lib/src/ui/tokens.g.dart`. Primary `#2E7D6B`/`#8CD5BF`; income
  `#2E7D32`/`#81C784`; expense `#C62828`/`#EF9A9A`; error `#BA1A1A`/`#FFB4AB`; 16 category colours `cat-01…16`. Type **Be
  Vietnam Pro** with **tabular figures**, 12 type styles. Icons **Material Symbols Rounded**.
- Keep token names; list every change (§11.4). Contrast ≥ 4.5:1 text / 3:1 large text & icons in both themes.
  **Needed:** a **warning** pair (`warning`, `on-warning`, `warning-container`) for *Due soon*, distinct from
  `error` (*Over*, *Overdue*) and from `expense`; a **success** accent for *Goal completed* that is not the income green.
- Category colours/icons are **user data** (keys in backups) — keep the 16 slots and icon keys.
- **Brand (D‑009):** logo "two stacked cards" (bg `#0E5244`, back card `#8CD5BF` −14°, front `#F7FAF8` +8°, dot `#E65100`).
  Wordmark **Vigon** (EN) / **Ví Gọn** (VI). Never coins, $, piggy bank, wallet‑with‑flap, leaf or donut as the logo.

### 2.3 Accessibility (WCAG 2.2 AA)
- Touch targets ≥ 48 dp / 44 pt (`tap-min` 48, `tap-key` 56, `tap-main` 64).
- **Text scale up to 200 %** without clipping: at ≥ 130 % amounts move under row titles, segmented controls stack, areas
  above keypads scroll, button pairs wrap, the **two‑line money block** (main + original) stays together.
- Every control has a spoken label; the Home ring has a one‑sentence summary + hidden table; live regions for typed amounts and
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
| NEW insufficient funds | Trip only has 500,000 ₫ | Trip chỉ còn 500.000 ₫ | Under amount field |
| NEW top‑up sheet title | MB Bank …1234 is 200,000 ₫ short | MB Bank …1234 thiếu 200.000 ₫ | Queue |
| NEW allow negative | Allow negative balance — for credit cards and overdrafts | Cho phép số dư âm — dùng cho thẻ tín dụng, thấu chi | Account editor |
| NEW debt remaining | 10,150,000 ₫ left · Principal 10,000,000 ₫ · Interest to date 150,000 ₫ | Còn 10.150.000 ₫ · Gốc 10.000.000 ₫ · Lãi tới hôm nay 150.000 ₫ | Debt detail |
| NEW two sides | Into wallet: $19.23 · From Cash: 500,000 ₫ | Vào ví: 19,23 $ · Trừ từ Tiền mặt: 500.000 ₫ | Add money |
| NEW budget notification | November budget: 80% used | Ngân sách tháng 11: đã dùng 80% | Lock screen |

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
- **NEW (D‑048): the same chip on every money field that moves money between an account and a goal/debt** — Add money,
  Withdraw, Lend / Borrow amount, Payment. Default = main currency. When the two sides differ, show both under the field:
  "Into wallet: $19.23 · From Cash: 500,000 ₫". Caps and "Fill to target" / "Pay the rest" follow the typed currency.
  Switching the chip **keeps the typed number** (50 → 50), it never rescales it.
- **Exact sums (D‑042):** totals add originals per currency to the smallest unit, then convert and round **once**. Switching the
  main currency back and forth never changes any amount. A total may differ by a cent from adding the rounded rows by hand —
  that's fine, don't design a "rounding" note for it.
- Display follows app language: EN `$1,250.00`, `₫1,250,000`; VI `1.250.000 ₫`, `1.250,00 US$`. Negative `-$200.00`.
  Up to 10¹² minor units per amount; totals can be larger → hero numbers must scale or wrap.
- Percent one decimal (`53.7%` / `53,7%`). Short date `Nov 3, 2026` / `3 thg 11, 2026`; Today. Time `12:02` (device 12/24 h).

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
9a. **No spending what you don't have (NEW, D‑046, SPEC F‑49).** Any save that takes money **out** of an account — expense,
    transfer out, add money to a goal (from the source), withdraw (from the wallet), lend, repay (principal + interest), editing
    a record upward, deleting an income/transfer‑in — is blocked if the account's **current** balance would go below 0, unless
    the account has **Allow negative balance** on. Message under the amount: "Trip only has 500,000 ₫". The receiving side of a
    transfer is never blocked. **Repeating records** due on an account without enough money are **skipped** (not saved, not made
    up later) and Home shows a dismissible bar "Skipped 1 repeating record — Trip didn't have enough". **Email queue items**
    stay in the queue and confirming one opens the **Top‑up sheet** (rule 17).
9b. **Default account (NEW, D‑047, F‑50).** Home filtered to an account → −, +, ring icons, ⋯ and Transfer "From" start on it;
    "All accounts" → first visible account.

**Money structure**
10. **Accounts:** name, currency, starting balance (negative only with **Allow negative balance**, NEW switch, default off;
    accounts already negative when the update lands get it switched on + a one‑time notice), visible/hidden; a negative
    balance carries a **"Negative | Âm"** badge (icon + word). Hidden accounts still count in balances;
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
    States: normal · **Over by X**.
13a. **Budget warnings (NEW, F‑37):** "Almost over" threshold default **80 %** (50–95 %, step 5, Settings → Plan); spent ≥
    threshold and ≤ limit → **Almost over** (icon + "82% used", warning colour); > limit → **Over by X** (error). Applies to the
    monthly budget (Home bar, Overview tile) and category limits (Records). Optional **Budget notifications** (off by default):
    one local notification per threshold per budget per month, **percent only, never amounts**.
14. **Debts go through accounts (CHANGED, D‑049, SPEC F‑52):** person, direction **I lent** / **I borrowed**, amount + currency
    chip (default main; locked after the first payment), **Account** (NEW; default per rule 9b; or **"Not through an account"** for
    an old debt you're just writing down), date, optional due date, note, optional **interest rate** (rule 14a).
    - Saving **I lent** takes the money **out** of the account (rule 9a applies); **I borrowed** puts it **in**.
    - Each **payment** has an **Account** too: "Collected" (lent) = money in; "Repaid" (borrowed) = money out.
    - These **debt movements** change account balances but are **not income or expense** (not in totals, charts, budgets,
      statistics — like a transfer). They appear in Records with their own icon and a label "Lent · An", "Collected · An",
      "Borrowed · Bình", "Repaid · Bình"; tapping one opens the **Debt detail**.
    - Debts created before this update stay memo‑only (no movements); their new payments pick an account.
    - **Deleting a debt keeps its movements** in Records (label "Deleted debt"), balances unchanged. Deleting the debt still
      returns to the Debts list.
    - Remaining 0 (principal and interest) → **Settled** (collapsed section). Overdue → word + icon.
14a. **Interest (NEW, bank‑style — Vietnam's Circular 14/2017/TT‑NHNN):** rate in **% per month** or **% per year** (×12); simple
    interest on the **principal still owed**, counted **per day**, year = 365 days; **interest start date** (default = loan
    date, later = grace period); **rate change** from a chosen date. **Remaining = principal left + interest to date.**
    A **payment** is pre‑split **interest first, then principal** (both editable). The **interest part is real income/expense**
    — an expense in category **"Loan interest | Lãi vay"** (borrowed) or income **"Interest | Tiền lãi"** (lent); the principal
    part is a debt movement. Example: borrow 10,000,000 ₫ at 12 %/year from Nov 1 → on Dec 1 interest is 98,630 ₫; paying
    1,000,000 ₫ = interest 98,630 ₫ + principal 901,370 ₫ → principal left 9,098,630 ₫.
15. **Deadline reminder (NEW, D‑044):** one global setting — on by default, **7 days** before (1–30), at **09:00** (changeable).
    Every savings goal and debt with a due date that isn't done gets a notification **N days before** and **on the due date**,
    **with the amount still left**, even when PIN lock is on (user's choice). For a debt with interest the amount is the
    **estimated total due on the due date** ("You owe Bình: about 10,295,890 ₫ due in 7 days").
16. **Savings goal = its own wallet (NEW, D‑043):**
    - Creating a goal **always creates a new account** (the *wallet*), never links an existing one. Form: goal name, **Account**
      (wallet name, pre‑filled with the goal name), target amount + currency (default main), **Already saved** (wallet's
      starting balance, default 0), optional deadline.
    - Why: if a goal used "Cash" with 8,000,000 ₫ of food money, a 5,000,000 ₫ goal would be "done" instantly. A wallet starts at 0.
    - The wallet is a **normal account**: spend from it, receive into it, withdraw any time — even before the goal is done.
    - **Progress = wallet balance** (in the goal's currency) vs target.
    - **Add money** = transfer from any account into the wallet, **capped at what's still missing** ("Fill to target" button).
      **Withdraw** = transfer out, capped at the wallet balance. **CHANGED (D‑048):** the amount is typed in the **main currency**
      by default with a currency chip, and both sides are spelled out ("Into wallet: $19.23 · From Cash: 500,000 ₫"); the source
      account can't go negative (rule 9a). *(Bug that triggered this: a USD wallet only accepted USD, so typing 500000 meant
      $500,000 and the save was refused.)*
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
    with an Undo bar. Email currency ≠ account currency → amount typed manually. **NEW (D‑046):** if the linked account
    doesn't have enough money, the item stays queued and the **Top‑up sheet** opens: "MB Bank …1234 is 200,000 ₫ short" with
    three ways — **Record income into MB …1234** · **Transfer into MB …1234** · **Edit starting balance**; once covered, the item
    is confirmed automatically (Undo bar).
18. **Backup:** manual `.vigon` file (optional password, AES‑256‑GCM) via share sheet; **Restore** replaces everything after a
    check + confirm; **Auto backup** daily at a chosen hour (default 21:00) into a user‑picked folder, always encrypted, keeps 2
    files, status line. **CSV export** (language‑aware). **NEW Excel (.xlsx) and PDF report** (F‑40): pick the range (period
    being viewed or custom), then the OS share sheet. Excel: sheets Records · By category · Debts. PDF A4: "Income & expense
    report <period>", totals, category table, record list.
19. **PIN lock** (4 digits) on open and after > 1 min in background, also from widget/notifications; it does **not** encrypt.
    **NEW Fingerprint / Face ID** (F‑41): switch in Security, only when PIN is on and the phone has biometrics enrolled; the lock
    screen opens the system prompt automatically; cancel/fail → PIN pad (PIN always works).
    Forgot PIN → only "Delete all data". **Hide content in app switcher.**
20. **Daily reminder** ("Have you recorded your spending today?") at a chosen time (default 20:00), **no figures**. **Deadline reminders** show amounts (rule 15).
21. **Onboarding** (fresh install only): Language → Welcome → Main currency → Reminder → PIN; Skip = defaults (English, USD,
    reminder off, no PIN).
22. **Delete all data:** two confirms; wipes everything incl. goals, debts, queue, mailboxes; recreates defaults.

---

## 4. Information architecture and navigation

### 4.1 Today (built, v4)
- **Home `/`** is the root. App bar: title + account filter (when ≥ 2 accounts) + **Records** icon + **Settings** gear.
- Everything else is a pushed full screen or a bottom sheet with back/close. **Settings** is the hub for Categories, Accounts,
  Budget, Repeating, **Savings**, **Debts**, Main currency, Rates, Email import & Queue, Security, Reminder, Data, Appearance &
  language, About (9 titled groups, S‑G1).

### 4.2 Navigation for the new screens — 🆕 **please propose** (S‑J0)
Overview, Statistics and Calendar are new top‑level destinations; Savings and Debts are used weekly but buried in Settings.
The code ships **temporary entry points** (icons in the Home app bar) until your design lands. Propose **one** of these, with
reasons, and draw it on Home + one inner screen, both platforms:
- **A. Bottom navigation (4–5 tabs):** e.g. **Home · Records · Overview · Plans (Budget, Savings, Debts) · Settings**, with
  Statistics and Calendar reached from Overview/Records. Must not push the big − / + buttons out of the thumb zone or add a tap to
  logging (AC‑02).
- **B. Keep Home as root** + a compact "Insights" entry (chip row or app‑bar menu) → Overview / Statistics / Calendar; Plans hub
  reachable from Home.
Whatever you choose: back behaviour on Android and iOS, where the account filter chip lives, and that the widget/notification
deep links still land on New record / Debt detail / Overview through the PIN lock.

### 4.2b Deep links
Widget / daily reminder → New entry; deadline reminder → Debts / Savings; **NEW budget notification → Overview**. All through
the PIN lock.

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
| overlay | Lock (+ fingerprint / Face ID) | S‑H1 |
| NEW `/overview` | Overview | S‑J1 |
| NEW `/stats` | Statistics | S‑J2 |
| NEW `/calendar` | Spending calendar | S‑J3 |
| NEW sheet on `/entries` | Advanced filter | S‑B4 |
| NEW sheet from Settings → Data | Export Excel / PDF | S‑G4 |

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
Debts ─ debt row ─► Debt detail ─ Add payment (interest/principal split) · Payments · Change rate · Edit · Delete (→ back to Debts)
Records ─ debt movement row ─► Debt detail · Filter ─► Advanced filter sheet
NEW Overview ─ Debts card ─► Debts · Budget tile ─► Budget · chart ─► Statistics
NEW Statistics · NEW Calendar ─ day ─► day's records
Queue ─ confirm with too little money ─► NEW Top‑up sheet ─► Record income / Transfer in / Edit starting balance
Outside: Widget · Daily reminder · Deadline reminder · NEW Budget notification · Recents cover
```

---

## 5. Screens

Per screen: **Status · Purpose · Components · States · Copy (EN | VI) · A11y.** Existing copy is in the `.arb` files; don't
invent new copy for unchanged screens.

### A — Home & logging

#### S‑A1 · Home `/` 🟡 (v4 frames 01, 07)
**Changed (v5) — draw these states:** (a) **filtered to an account** — make the active account obvious, because − / + now log
into it (rule 9b); (b) **"Skipped 1 repeating record — Trip didn't have enough"** dismissible bar; (c) budget bar **Almost over**
("82% used", warning) next to the existing Over state; (d) the chosen **navigation** (§4.2).
**Purpose:** log fast; see the period at a glance.
**Components:** app bar (title, account filter chip *proposal: show the active account as a chip*, Records, Settings) ·
period header ‹ **November 2026** › (tap → "View by" sheet, swipe changes period) · **ring chart** of expenses by category
with the period total in the centre (**main currency**) and category icons around it (last slot ⋯) · **budget bar** (Spent X of
Y, Over by X) · **balance bar** (period income − expense, main currency, tap → Records) · big **− Expense**
/ **+ Income** buttons. Queue banner when items wait ("3 records waiting for a category").
**Changed:** every amount main‑currency; ring total uses exact sums.
**States:** empty (first launch: friendly, points to − / ring) · normal · many categories (⋯) · budget over · negative balance ·
filtered account · missing rate note ("1 amount left out — no rate") · 200 % · VI.

#### S‑A2 · "View by" sheet + range calendar ✅ (frame 02) · Account filter menu ✅ (03)
Refresh only.

#### S‑A3 · New / edit record `/entry/new`, `/entry/:id` 🟡 (v4 frames 05, 06, 53)
**Changed (v5) — draw these states:** (a) **insufficient funds**: expense of 700,000 ₫ on *Trip* that has 500,000 ₫ → error
under the amount "Trip only has 500,000 ₫" + a quick way out (tap Account chip to switch; propose a "Record income to Trip"
link); the big key stays enabled but the save is refused; (b) account chip pre‑filled with the **filtered** account; (c) editing
a **debt‑interest** record shows "Interest on debt with Bình" and links to the debt.
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

#### S‑B1 · Records `/entries` 🟡 (v4 frames 10, 11)
**Changed (v5):** (a) **debt movement rows** — own icon (propose: handshake / arrows), title "Lent · An" / "Collected · An" /
"Borrowed · Bình" / "Repaid · Bình" / "Deleted debt", amount with sign, styled so they read as *not* income/expense (like
transfers); tap → Debt detail; (b) **interest rows** are normal expense/income rows in categories "Loan interest" / "Interest";
(c) **Filter** button in the app bar (S‑B4) and active filter chips above the list; (d) category limit bars get **Almost over**.
**Components:** period header + account filter · summary (income, expense, balance — main currency) · list grouped by day
(day header with day total) · **record row**: category avatar, note/title, account · time, ✉ marker for email records, and the
**two‑line money block** on the right (main big, original small) · category rows with limit bars · transfers section.
Search mode (frame 11): field, "All time" chip, results "N records · total X".
**Changed:** rows main‑first.
**States:** empty period · many records · long notes · mixed currencies · search no match · 200 % · VI.

#### S‑B2 · Undo bar ✅ — "Deleted · Undo" 5 s. **New state:** delete refused — "Can't delete: Trip would be −200,000 ₫".

#### S‑B4 · Advanced filter 🆕 (F‑39)
**Purpose:** narrow Records by amount, categories and dates. **Components:** bottom sheet from **Filter**: amount **from / to**
(either may be empty; from > to → error under the field) · **categories** multi‑select (expense and income, with icons/colours;
picking categories hides transfers and debt movements) · **date range** (same range calendar as Custom range; replaces the
period for this list) · **Apply** / **Clear filter**. Result: flat list newest first + "N records · spent X · received Y";
each condition is a removable chip; combines with search and the account filter (AND). Lives only while the app runs.
**States:** empty filter · amount only · 3 categories · date range · no results · invalid range · 200 % · VI · dark.

#### S‑B3 · Repeating records `/recurring` ✅🟡 (frames 20, 21)
List of series (amount main‑first, frequency label incl. "Mon, Tue", next date, Paused); edit sheet with Choose days.

### C — Money structure

#### S‑C1 · Accounts `/accounts` 🟡 (v4 frames 17, 18)
**Changed (v5):** (a) editor gets a switch **"Allow negative balance | Cho phép số dư âm"** with helper "For credit cards and
overdrafts. When off, you can't spend more than the account has."; starting balance field rejects a negative number while the
switch is off; (b) rows with a negative balance show a **"Negative | Âm"** badge (icon + word); (c) one‑time dialog after the
update: "We allowed a negative balance for: Old credit card, VIB card" (OK).
**Components:** total balance (main currency, exact) · account rows: icon, name, **currency code chip** (e.g. `VND`), balance as
two‑line block (main big / own currency small) · badges: **Savings wallet** (goal name chip, NEW), "From MB email" · hidden
accounts collapsible · edit sheet (name, currency, starting balance, hide/show, delete rules).
**States:** one account · mixed currencies · wallet accounts · hidden open · last visible · used vs unused · 200 % · VI.

#### S‑C2 · Categories `/categories` ✅ (15, 16) — refresh; limit field has its currency (main‑first display).

#### S‑C3 · Transfer `/transfer` 🟡 (v4 frames 19, 54)
**Changed (v5):** "From" pre‑filled with the filtered account; **insufficient funds** state on "You send" ("Cash only has
120,000 ₫"); opened from the Top‑up sheet with "To" locked to the short account and the amount pre‑filled with the shortfall.
From / To account pickers (balances main‑first), amount; **different currencies → two fields "You send" / "They receive"** with
the current rate shown and editable; date, time, note. Pre‑filled when opened from elsewhere.

### D — Plans: budget, savings, debts

#### S‑D1 · Monthly budget dialog ✅🟡 (frame 04)
Amount + **Currency** selector (default main); live line 2 in main currency when it differs; Remove budget.

#### S‑D2 · Savings `/savings` ✅ list/editor/detail/reached (v4 frame 41) · 🟡 **Add money + Withdraw sheets**
**Changed (v5) — redraw `savings~add-money*`, `savings~withdraw*`:** the amount field has the **currency chip, default main
currency** (goal in USD, main VND → you type ₫); under it two lines "Into wallet: $19.23" · "From Cash: 500,000 ₫"; the cap
error and **Fill to target** use the typed currency ("Only 253,767,717 ₫ more needed"); new error when the **source account
can't cover it** ("Cash only has 120,000 ₫") with "Choose another account". Withdraw: same chip, cap = wallet balance.
States to draw: same currency · goal USD/main VND · source short · over cap · Fill to target · 200 % · VI.
*(Everything below is the v4 description, still valid.)*
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

#### S‑D3 · Debts `/debts` 🟡 **big change (F‑52, D‑049) — priority** (v4 frame 42)
**List:** header note — **rewrite `debtsNote`** NEW: "Lending and borrowing move money in your accounts but don't count as
income or expense. Interest does." | "Cho vay, đi vay làm đổi số dư tài khoản nhưng không tính là thu hay chi. Tiền lãi thì
có tính." Two groups with totals (main currency, **incl. interest to date**) — **Owed to you** / **You owe**; row = person
(initials avatar), account name small (or "Memo only"), **remaining** (two‑line; for interest‑bearing debts a tiny "incl.
interest" hint or % rate chip "12%/yr"), "Paid {paid} of {total}" bar, due chip; **Settled (n)**; Add debt.
**Editor (sheet)** — CHANGED fields, in this order:
1. Person · 2. Direction (I lent / I borrowed) · 3. **Amount + currency chip** (default main; locked after first payment) ·
4. **Account | Tài khoản** (NEW: picker with balances main‑first; default = filtered account; last option **"Not through an
   account | Không qua tài khoản"** with helper "Just a note — no account balance changes") · helper under it NEW: "Lending
   takes this money out of Cash. | Cho vay sẽ trừ số tiền này khỏi Tiền mặt." (flips for borrowing) · **insufficient funds**
   error when lending more than the account has · 5. Date · 6. Due date (optional) · 7. **Interest (optional)** NEW: rate field
   (up to 2 decimals) + segmented **% / month · % / year**; **Interest starts** date (default = date; helper "Set later for a
   grace period"); live preview "≈ 100,000 ₫ interest per month at today's principal" · 8. Note.
**Detail** — CHANGED: hero **Remaining** = principal left + interest to date, with line 2 "Principal 9,098,630 ₫ · Interest to
date 74,780 ₫"; rate chip "12%/year since Nov 1" + **Change rate** (sheet: new rate, from date; list of rate periods); account
line ("Through Techcombank"); due chip + reminder hint; **Payments** list: date, account, **interest part + principal part**
(e.g. "1,000,000 ₫ · interest 98,630 ₫ · principal 901,370 ₫"), delete (Undo; refused if it would make an account negative);
**Add payment** button; Edit; Delete.
**Add payment sheet** NEW layout: amount + currency chip (default main) · **Account** (default = the debt's account) · date ·
auto split shown as two editable rows **Interest** (pre‑filled with interest to that date) and **Principal** (rest), with a
small "Interest first, like banks" note; chips **Pay interest only** · **Pay the rest** (principal + interest to date); errors:
interest > accrued, principal > left, account short. Saved interest becomes an expense "Loan interest" / income "Interest".
**Delete debt dialog** CHANGED: "Delete the debt with An? Its records stay in your accounts. | Xoá khoản nợ với An? Các khoản
trong sổ vẫn giữ." → closes detail, stays on Debts.
**States:** empty · both groups · memo‑only old debt · lent from account · borrowed into account · with interest (%/month and
%/year) · grace period (interest starts later) · rate changed mid‑way · payment split · pay the rest · account short ·
foreign‑currency debt (USD, main VND) · overdue · due soon · settled · 200 % · VI · dark.

#### S‑D5 · Budget warnings + budget notifications 🆕 (F‑37)
- **Almost over** state for: Home budget bar, Overview "Budget left" tile, category limit bars in Records, Budget dialog preview
  — icon + "82% used" in **warning** colour, distinct from **Over by X** (error). Example: limit 5,000,000 ₫, threshold 80 % →
  3,999,999 normal · 4,000,000 Almost over · 5,000,000 Almost over · 5,000,001 Over by 1.
- Settings → Plan: **"Warn at | Cảnh báo khi đạt"** row with value "80%" → sheet with a 50–95 % slider/stepper (step 5) and switch
  **"Budget notifications | Thông báo ngân sách"** (default off; explain dialog → OS permission).
- **Notification** (EXT 08): "November budget: 80% used" · "Food: 100% of November's limit used" — **never an amount**, even with
  PIN off. Tap → Overview (through PIN).

#### S‑D4 · Deadline reminder setting + notification ✅ (F‑48, D‑044, v4 frame 51)
**Changed (v5):** debt with interest → notification shows the **estimated total due** ("You owe Bình: about 10,295,890 ₫, due
in 7 days"). Only this notification state needs a new frame.
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

#### S‑E2 · Exchange rates `/rates` ✅ (v4 frame 50)
Intro `ratesIntro`; status chip (Auto · updated today / Offline · rates from yesterday / Built‑in estimate / Set by you); **Update
now**; list of **pairs in use** only ("1 VND equals 0.0000385 USD"), each tappable → override sheet (auto value, "Your rate · 1 EUR
=", preview "Cash: 500,000 ₫ ≈ $19.25", Save this rate / Restore automatic); offline banner; source attribution link.
**States:** auto · offline · built‑in · manual override · no pairs ("Everything is in USD, so there's nothing to convert.") · 200 %.

#### S‑E3 · Currency picker ✅🟡 — reused by record, account, budget, debt, goal; show "In use" group on top.

### F — Email import

#### S‑F1 · Email import `/email-import`, `/email-import/add` ✅ (v4 frame 44)
Intro (title `emailIntroTitle`, four reassurance lines with icons, `emailIntroBanks`, iPhone note, **Add mailbox**) → Add mailbox
(provider Gmail/Yahoo/iCloud, address, app password with show toggle, numbered steps per provider + "Open the app password page",
Connect → progress → Connected / error variants) → mailbox list (status chip Connected / Paused, last check, "2 MB emails couldn't
be read", Re‑enter password, Remove mailbox confirm; schedule note Android vs iPhone; max 3).

#### S‑F2 · Queue `/import-queue` + Remembered suggestions ✅ (v4 frame 43) · 🟡 Top‑up sheet
Item cards: date + time, amount (two‑line if the email currency ≠ main), payee (or "Unknown payee"), content, "From MB Bank
…4821", ✉; category grid with **Suggested** pre‑selected → **Save to Food**; secondary **Edit before saving · Move to my account ·
Skip** (confirm). Currency‑mismatch note. Auto‑created account card ("Created account MB Bank …4821 · Attach to an existing account
· Dismiss"). Pull to check. Empty state `queueEmpty`. Suggestions screen: payee → category/account, delete.
Must clear 2 items without scrolling at 360 × 800 and work at 200 %.
**🟡 NEW in v5 — Top‑up sheet (S‑F4):** confirming an item whose linked account is short opens a sheet: icon + title "MB Bank
…1234 is 200,000 ₫ short | MB Bank …1234 thiếu 200.000 ₫", body "The bank already sent this money. Add what's missing so the
account matches. | Ngân hàng đã chuyển khoản này. Bổ sung phần thiếu để số dư khớp.", three full‑width options with icons —
**Record income into MB …1234** (→ New record, income, account and amount pre‑filled) · **Transfer into MB …1234** (→ Transfer,
"To" pre‑filled) · **Edit starting balance** (→ account editor) — and **Not now** (item stays queued). After returning with
enough money the item is confirmed with an Undo bar. Draw: sheet · after top‑up success · 200 % · VI.

#### S‑F3 · Match bar ✅‑ish — "Matched with MB email 12:02 · Undo".

### G — Settings & data

#### S‑G1 · Settings `/settings` 🟡 (v4 frame 12; new rows below)
Nine titled groups of cards (as built): **Categories & accounts** (Categories, Accounts) · **Plan** (Monthly budget, Repeating
records, Savings, Debts, **NEW Deadline reminders**) · **Currency & period** (Main currency, Exchange rates with status, Week start,
Month start day) · **Email import** (Import from bank email · status, Items awaiting a category · count) · **Security** (PIN lock +
warning, Hide content in app switcher 🤖/🍏) · **Reminder** (Daily reminder switch, Reminder time) · **Data** (Backup, Restore, Auto
backup section with folder/status/Back up now, Export CSV, Delete all data last) · **Appearance & language** (one row opening a
sheet: Theme System/Light/Dark + Language English/Tiếng Việt) · **About** (inline card: Version `1.0.0 (1)`, Privacy policy, Terms
of use, Open‑source licences, Rate Vigon 🤖, Send feedback, Report a security issue; footer "Data is stored only on this phone…").
Use status chips/values on the right (e.g. "Auto · today", "1 mailbox", "3 awaiting", "7 days before · 09:00").
**🟡 Changed (v5) — new rows to draw:** Plan → **Warn at 80%** (+ Budget notifications, S‑D5) · Security → **Unlock with
fingerprint / Face ID** switch (S‑H1) · Reminder → **Exact timing | Báo đúng giờ** 🤖 ("On" / "Off · may be a few minutes late",
tap → explain dialog → Android "Alarms & reminders" page; D‑045, already built) · Data → **Export Excel** and **Export PDF**
(S‑G4) · the temporary Overview / Statistics / Calendar entry is **not** in Settings.
**States:** top / middle / bottom scroll positions · iOS (no Rate row) · 200 % · VI · dark.

#### S‑G2 · Backup / restore / password dialogs / CSV / delete all ✅ (26–29) · Auto backup ✅ (31) — refresh; make all password
dialogs one family.

#### S‑G3 · Legal page (offline reader) ✅ — opened when the browser can't; simple readable article.

#### S‑G4 · Export Excel / PDF 🆕 (F‑40)
Sheet from Settings → Data: format (Excel / PDF) · **Range**: "Period being viewed (November 2026)" or "Custom range…" (range
calendar) · what's included ("Records, totals by category, debts") · **Export** → progress ("Preparing 1,240 records…") → OS share
sheet. Errors: nothing in range ("No records in this range"). Also draw a **thumbnail of the PDF page 1** (A4: title "Income &
expense report · November 2026", totals income / expense / difference, category table with %, record list) so the developer can
match the layout, Be Vietnam Pro, light only. States: sheet · custom range · exporting · empty range · 200 % · VI.

### H — Security

#### S‑H1 · Lock / Set PIN / Forgot PIN ✅ (23–25) · 🆕 fingerprint / Face ID (F‑41)
**New:** (a) Settings → Security switch **"Unlock with fingerprint | Mở khoá bằng vân tay"** (Android) / **"Unlock with Face ID |
Touch ID"** (iPhone), only when PIN is on; disabled with a reason when the phone has no enrolled biometrics ("Add a fingerprint in
your phone's settings first"); turning on asks for one biometric check. (b) Lock screen with the **system biometric prompt** on
top (OS‑owned) and a **fingerprint / face button** on the PIN pad to retry; cancel/fail → PIN pad stays usable. Draw: settings
row on/off/unavailable · lock screen with prompt · after cancel · iOS Face ID variant.

### I — First run

#### S‑I1 · Onboarding `/onboarding` ✅ (v4 frame 49) (F‑44)
Five steps with "Step n of 5", Skip on steps 2–5, system Back steps back:
1. **Choose your language** (English pre‑selected / Tiếng Việt, applies instantly).
2. **Welcome to Vigon** — three benefits (Record in 3 taps · See where your money goes · Private by design) + **Get started**.
3. **Your main currency** — USD pre‑selected, USD / VND quick options + "Choose another currency…"; hint `onboardingCurrencyHint`.
4. **A daily reminder to record** — time 20:00 (tap to change), **Turn on reminder** (asks OS permission) / **Not now**.
5. **Lock Vigon with a PIN?** — **Set a PIN** / Not now.
**States:** each step light/dark, VI, 200 %, permission denied bar.

### J — Insights (all 🆕, being coded now with placeholder UI)

#### S‑J0 · Navigation proposal 🆕 — see §4.2.

#### S‑J1 · Overview `/overview` 🆕 (F‑35, D‑034)
**Purpose:** "how am I doing this month?" in one screen. **Own month picker** ‹ November 2026 › (independent of Home's period;
default = current month by month start day). Tiles/cards, all in the main currency, all accounts:
1. **Total balance | Tổng số dư** — sum of every account incl. hidden ones (debts *not* included).
2. **Income − expense this month | Thu − chi tháng** (signed).
3. **Budget left | Ngân sách còn lại** — limit − spent; negative → "Over by X"; Almost over state; no budget → "Set a budget" tile.
4. **Income vs expense, 6 months** — paired bars ending at the selected month; hidden data table for screen readers.
5. **Compared with last month | So với tháng trước** — "Spending up 25% vs October" / "Income down 8%" with arrow **and** word;
   previous month 0 → "—".
6. **Debts | Nợ** (NEW, D‑049) — "Owed to you 2,000,000 ₫ · You owe 10,150,000 ₫" (incl. interest to date), tap → Debts;
   hidden when there are no open debts.
Optional (propose): entry to Statistics and Calendar from here. **States:** normal · no budget · over budget · first month
(no history) · no debts · negative total balance · 200 % · VI · dark. Example: Oct spent 4,000,000, Nov 5,000,000 → "Spending
up 25% vs October".

#### S‑J2 · Statistics `/stats` 🆕 (F‑36)
Same period header and account filter as Home. Sections: (1) **income/expense bars by sub‑period** — Day: one pair; Week: 7
days; Month: each day; Year: 12 months; All time: each year; Custom ≤ 31 days daily, ≤ 366 days monthly, longer yearly;
(2) **Top 5 expense categories** (amount + % of period spending, category icon/colour); (3) **Biggest spending day** (date +
amount; hidden for Day); (4) **Total balance line** (end of each sub‑period). Debt movements excluded; interest included.
Every chart has a table alternative; empty period → empty state, no empty charts. **States:** month · year · all time · empty ·
1 category only · 200 % · VI · dark.

#### S‑J3 · Spending calendar `/calendar` 🆕 (F‑38)
Month grid (week start from Settings): each day shows **compact spending** ("50k", "1.2M" | "50k", "1,2tr") and a **dot** when
there was income; ‹ › and swipe change month; account filter applies. Tap a day → list of that day's records with day totals
(edit, swipe delete, Undo). Screen reader: "November 6, spent 250,000 dong". **States:** normal · empty month · heavy day (big
number) · today · selected day open · 200 % (cells must still fit — propose a fallback, e.g. dots + list) · VI · dark.

---

## 6. Surfaces outside the app
| EXT | Surface | Status | Notes |
|---|---|---|---|
| 01 | Home‑screen widget 2×2 / 4×2 (Android, iPhone) | ✅ | Expense / Income buttons; amounts only if allowed and PIN off; "Open the app to update" |
| 02 | Daily reminder notification | ✅ | Generic text, no figures |
| 04 | Recents / app‑switcher cover | ✅ | Blank with logo |
| 05 | OS sheets & pickers | — | Share sheet, file/folder picker, time picker, permission prompt, biometric prompt |
| 06 | App icon incl. Android monochrome | ✅ | unchanged |
| 07 | Deadline reminder notification | ✅🟡 | With amount left (S‑D4); **v5: interest debt → estimated total due** |
| **08** | **Budget notification** | 🆕 | Percent only, never amounts (S‑D5); channel "Budget"; tap → Overview |
| 05b | OS biometric prompt | — | Fingerprint (Android BiometricPrompt) / Face ID — OS‑owned, show it over the lock screen |

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
- **F11 Onboarding:** fresh install → Tiếng Việt → Bắt đầu → VND → Bật nhắc → Để sau → Home empty state ("Log your first
  expense / Tap a category or −" — shortened 2026‑11‑11).
- **F12 Can't overspend (NEW):** Home filtered to **Trip** (500,000 ₫) → − → `700000` → Food → error "Trip only has 500,000 ₫" →
  switch account to Cash → saved. Then Records shows it on Cash.
- **F13 Lend through an account (NEW):** Debts → Add debt → "An", I lent, 5,000,000 ₫, Account **Techcombank**, due in 30 days,
  interest **1 %/month** → saved → Techcombank −5,000,000 ₫, Records shows "Lent · An" (not an expense), Overview Debts card
  "Owed to you 5,000,000 ₫" → 30 days later Debt detail "Remaining 5,049,315 ₫ · interest to date 49,315 ₫" → Add payment
  2,000,000 ₫ into Techcombank → split interest 49,315 ₫ (income "Interest") + principal 1,950,685 ₫ → remaining 3,049,315 ₫.
- **F14 Borrow and repay with interest (NEW):** I borrowed 10,000,000 ₫ from Bình into Cash, 12 %/year from Nov 1 → Dec 1 Add
  payment 1,000,000 ₫ from Cash → Interest 98,630 ₫ (expense "Loan interest") + Principal 901,370 ₫ → Change rate to 15 %/year
  from Jan 1 → deadline reminder shows the estimated total due.
- **F15 Add money in the main currency (NEW):** goal "du lịch Đà Lạt" in USD, main VND → Add money → type `500000` ₫ → lines
  "Into wallet: $19.23 · From Cash: 500,000 ₫" → Save.
- **F16 Queue top‑up (NEW):** Queue → item 2,000,000 ₫ → Save to Food → Top‑up sheet "MB Bank …4821 is 2,000,000 ₫ short" →
  Transfer into MB from Bank card → back → item confirmed (Undo).
- **F17 Insights (NEW):** Home → Overview (Nov) → Budget tile Almost over 82 % → Statistics (Month) → top category Home →
  Calendar → tap Nov 6 → day's records.
- **F18 Filter + export (NEW):** Records → Filter 50,000–200,000 ₫ · Food + Transport · Nov 1–15 → "12 records · spent X" →
  Settings → Export PDF → November → share sheet.
- **F19 Fingerprint (NEW):** Settings → Security → Unlock with fingerprint → system prompt → on; reopen app → prompt → in.

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
**Income:** Salary $2,300.00 + Bonus $200.00. **Period balance** $660.00. **Monthly budget** $2,000.00 → 92 %;
over variant $1,700 → "Over by $140.00". Category limits: Food $450 → Over by $45.00 · Transport $160 → 81 %.
**Records (mixed currencies, main‑first):** Nov 26 12:02 "Beef pho" Food **$3.85** / 100,000 ₫ ✉ · Nov 25 18:40 "Groceries" Food
**$32.00** · Nov 24 "Hotel deposit" Entertainment **$108.70** / €100.00 · Nov 20 "Electricity" Bills **$26.18** / 680,000 ₫ · Nov 18
07:50 "Ride to work" Transport **$3.50** · Nov 1 "November rent" Home **$540.00** (repeating, no time) · Nov 10 Transfer Bank card →
Cash **$200.00** → received 5,194,800 ₫ · Missing‑rate variant: "Gift" 50,000 XAF → "No rate for XAF to USD…".
**Savings (In progress):** Trip — target 5,000,000 ₫ (**$192.50**), saved 4,000,000 ₫ → 80 %, due Dec 3 → **Due soon** (7 days) ·
Laptop — $300 of $1,200 (25 %), due Mar 1, 2027 · Paris — €250 of €800 (**$271.75 of $869.60**), no deadline. **Done (1):** Emergency
fund — $1,500 reached Oct 12. History of Trip: Nov 1 Already saved +1,000,000 ₫ · Nov 5 Added from Cash +2,000,000 ₫ · Nov 12 Spent:
flight deposit −300,000 ₫ · Nov 20 Added from E‑wallet +1,300,000 ₫ → balance 4,000,000 ₫.
**Debts (v5 — through accounts, some with interest):** Owed to you — An $100 lent from Bank card, no interest (paid $40 → **$60
left**, due Dec 3 → Due soon) · Tuấn 500,000 ₫ lent from Cash, **1 %/month** since Oct 1 (**$19.25** / 500,000 ₫ + interest, due
Nov 20 → Overdue) · Old memo‑only debt "Hà" 300,000 ₫ (Memo only). You owe — **Bình 10,000,000 ₫ borrowed into Cash, 12 %/year
since Nov 1, one payment Dec 1 (interest 98,630 ₫ + principal 901,370 ₫)** · Landlord $30 · Settled (1): Minh $15.
**Debt movements in Records:** Nov 1 "Borrowed · Bình" +10,000,000 ₫ (Cash) · Oct 1 "Lent · Tuấn" −500,000 ₫ · "Repaid · Bình"
−901,370 ₫ + expense "Loan interest" 98,630 ₫.
**Overspending examples:** account **Trip** VND 500,000 ₫ (expense 700,000 ₫ refused) · **VIB credit card** USD −$120.00 with Allow
negative balance on (badge "Negative").
**Overview (Nov):** Total balance $1,286.40 · Income − expense +$660.00 · Budget left $160.00 (92 % → Almost over at 80 %) · last 6
months bars Jun–Nov · Spending up 12 % vs October · Debts: owed to you $79.25 · you owe $381.20.
**Budget warning:** threshold 80 %; Food limit $450 → spent $495 (Over by $45.00); Transport $160 → $130 (81 % Almost over).
**Notifications:** deadline "Debt with An: $60.00 left, due in 7 days" · daily reminder.
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
| Reminders (daily + deadline) | Exact time | Exact when the user allowed "Alarms & reminders" (row "Exact timing"), else a few minutes late |
| Biometric unlock | Face ID / Touch ID (name follows the phone) | Fingerprint (strong biometrics only) |
| Budget notification | Yes | Yes |
| Rate the app | Hidden until App Store id exists | Opens Play |
Draw iPhone frames for every 🟡/🆕 screen; Material look, iOS safe areas.

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
10. **Empty states** for Savings, Debts, Queue, Rates (no pairs).
11. **Password dialogs** (backup, restore, auto backup, mailbox) as one family.
12. **NEW — "You don't have that much" without frustration:** the insufficient‑funds state on every money field must show what
    *is* there and the next step (switch account, record income, transfer in, top up), in one tap. Never block silently.
13. **NEW — Debt movements vs income/expense:** in Records, Overview and Statistics users must see at a glance that lending /
    borrowing isn't spending or earning, while interest is. Same visual language as transfers, distinct from them.
14. **NEW — Interest made understandable:** principal vs interest to date, the split of each payment, the rate period, a grace
    period and a rate change — without a finance degree. Consider a tiny "how is this calculated?" explainer.
15. **NEW — Two currencies in one field:** the chip + "Into wallet / From account" lines must make it impossible to type ₫ and
    have it read as $.
16. **NEW — Navigation** for Overview / Statistics / Calendar / Plans (§4.2).

### 10.2 Out of scope — don't draw
Cloud sync, sign‑in, servers; banks other than MB; SMS / notification reading; receipt photos / OCR; AI; shared/family accounts;
investments; historical exchange rates; ads, subscriptions, analytics; tablet/landscape; compound interest, late‑payment
penalty interest, amortisation schedules / instalment plans for debts; net‑worth figure.

---

## 11. Deliverables

### 11.1 Priority (v5 — draw only these; keep every other v4 frame)
1. **P0 — money rules:** insufficient‑funds states (New record, Transfer, Add money, Debt lend/payment), Accounts "Allow negative"
   + Negative badge + one‑time dialog, Home filtered‑account + skipped‑repeating bar, Top‑up sheet (S‑F4), Delete refused.
2. **P1 — Debts redesigned:** list, editor (account + interest), detail (principal/interest, rate change, payments split), Add
   payment sheet, delete dialog, Records debt‑movement rows, interest deadline notification; Savings **Add money / Withdraw** with
   the currency chip.
3. **P2 — new screens:** navigation proposal (§4.2), Overview, Statistics, Calendar, Advanced filter, Budget warnings + settings
   + notification, Export Excel/PDF (+ PDF page thumbnail), Fingerprint/Face ID, new Settings rows (incl. Exact timing).
4. **P3 —** VI variants and 200 % for all of the above.

### 11.2 Frames
Each platform (Android 360 × 800 dp; iPhone 393 × 852 pt) × light + dark, every screen with its states.
- **VI variants** (light, main VND): every P0–P2 screen.
- **200 % text** (one platform, light): New record (insufficient), Add money, Debt editor, Debt detail, Add payment, Top‑up sheet,
  Overview, Statistics, Calendar, Filter, Export.
- **Prototype links** for F12–F19 (F1–F11 already prototyped in v4).

### 11.3 File naming
`design/hifi/<platform>/<theme>/<NN>_<slug>__<state>.png` + HTML. Keep numbers 01–33; numbers used now:

| No. | Screen | Slug examples |
|---|---|---|
| 00 | Money block component | `money~two-line` |
| 41 | Savings (redesigned) | `savings`, `savings__done-open`, `savings~edit`, `savings~detail`, `savings~detail__done`, `savings~add-money`, `savings~add-money__cap`, `savings~withdraw`, `savings~reached` |
| 42 | Debts | `debts`, `debts~edit`, `debts~detail`, `debts~payment`, `debts~payment__over` |
| 49 | Onboarding | `onboarding__1-language` … `__5-pin` |
| 50 | Exchange rates | `rates`, `rates__offline`, `rates~override`, `rates__none` |
| 51 | Deadline reminders | `settings~deadline-reminder`, `ext-deadline-notification` |
| 52 | Appearance & language sheet / About card | `settings~appearance`, `settings__about` |
| 53 | New record currency chip | `entry-new__currency`, `entry-new~currency-picker` |
| 54 | Transfer cross‑currency | `transfer__two-currencies` |
| 55 | Legal reader | `legal` |
| 12 | Settings (9 groups) | `settings__top`, `settings__middle`, `settings__bottom` |
| 40 | Time field | `entry-new__time`, `entry-id__no-time` |
| 43 | Import queue | `queue`, `queue__suggested`, `queue__currency`, `queue__empty`, `queue~move`, `queue~skip`, `queue~suggestions` |
| 44 | Email import | `email-intro`, `email-add`, `email-connected`, `email-error`, `email-paused` |
| **34** | Overview (v5) | `overview`, `overview__no-budget`, `overview__over`, `overview__first-month` |
| **35** | Statistics (v5) | `stats__month`, `stats__year`, `stats__empty` |
| **36** | Calendar (v5) | `calendar`, `calendar~day`, `calendar__empty` |
| **37** | Navigation proposal (v5) | `nav__home`, `nav__plans` |
| **38** | Advanced filter (v5) | `entries~filter`, `entries__filtered`, `entries~filter__invalid` |
| **39** | Budget warnings (v5) | `home__almost-over`, `settings~budget-warn`, `ext-budget-notification` |
| **45** | Export (v5) | `settings~export`, `settings~export__custom`, `export-pdf-page1` |
| **46** | Biometrics (v5) | `settings__biometric`, `lock__biometric`, `lock__biometric-cancel` |
| **47** | Money rules (v5) | `entry-new__insufficient`, `transfer__insufficient`, `accounts~edit__allow-negative`, `accounts__negative-badge`, `accounts~allow-negative-notice`, `home__skipped-repeat`, `entries~delete-refused` |
| **56** | Top‑up sheet (v5) | `queue~top-up`, `queue__topped-up` |
| 41 / 42 (v5 additions) | Savings / Debts | `savings~add-money__main-currency`, `savings~add-money__source-short`, `debts~edit__interest`, `debts~edit__account`, `debts~detail__interest`, `debts~detail~change-rate`, `debts~payment__split`, `debts~delete-keep`, `entries__debt-rows`, `ext-deadline-notification__interest` |
| 48 | Currency conversion — obsolete, don't use |

### 11.4 Design system page
- **Tokens** as JSON in the schema of `design/hifi/tokens/tokens.json` + CSS variables; keep names; changelog. Required additions:
  `warning` / `on-warning` / `warning-container`, `success` accent for Done,
  **money block** spec (line 1 / line 2 styles, spacing, alignment start/end, 200 % behaviour).
- **Component sheet** (default, pressed, focused, disabled, error, selected; light + dark): two‑line money block, currency chip,
  currency bar (form field), progress bar (goal / debt / budget: normal · due soon · over / overdue · done), history row,
  amount field with "Fill to target" chip, account picker row with balance, celebration dialog, status chip, stepper (days before),
  queue card, suggested chip, ✉ marker, banner, segmented control, plus all v2 components (ring, keypad, rows, dialogs, snackbar, PIN pad, widget, notification).
- **Motion** (150–250 ms, reduce‑motion aware): progress fill, goal → Done, reached burst, sheet open/close, period change, keypad.
- **Icon list** for every new action (Add money, Withdraw, History, Wallet, Deadline reminder, Reopen, Currency chip).
- **v5 additions:** insufficient‑funds field state, Negative badge, top‑up option rows, debt‑movement row icon(s), interest /
  principal split rows, rate chip, stat tile, bar chart (paired income/expense) + line chart + their table alternatives, calendar
  day cell (compact amount + income dot, selected/today), filter chips, Almost‑over status (warning), export option rows,
  biometric button on the PIN pad, and the chosen navigation component. Token additions only if needed — list them in the changelog.

### 11.5 Format
claude.ai link + HTML/PNG per frame into `apps/A002-vigon/design/hifi/` with §11.3 names, plus an **assumptions page** (what you
decided where this brief left room) and the **token changelog**.

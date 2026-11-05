# Ví Gọn — Product brief for Hi‑Fi UI design (v2, merged app)

> **What this file is for:** the brief to send to **Claude Design** to produce Hi‑Fi mockups (UX/UI optimised) for the
> mobile app **Ví Gọn** on **Android + iOS**. It says *what* each screen must do and *why*; *how it looks* is Claude
> Design's proposal, within the limits in §2 and §11.
>
> **Starting point = the app as it is today** (`main` after merging v1.1/v1.2 features F‑14..F‑26 with the PLAN‑001 UI).
> The PLAN‑001 UI is already implemented from the approved design system "Ví Gọn" (`design/current/screens/`, frames
> S01–S16, `tokens.json`, Be Vietnam Pro, Material Symbols Rounded). **Upgrade, don't redesign:** keep its structure,
> tokens and component vocabulary; polish hierarchy, states and motion; and **draw everything that has no frame yet**
> (marked 🆕 below — these are the priority).
>
> **Scope = exactly `docs/SPEC.md` F‑01..F‑26 (AC‑01..AC‑64).** Ideas outside it go to §10 only.
>
> Internal code `A002-vigon` · Bundle ID `com.phiotron.vigon` · Version 1.0 · Brief v2 · 2026‑11‑05 (replaces v1 of
> 2026‑11‑04, which described the older 1.0 UI). Glossary: `CONTEXT.md`. All copy below is the real copy from
> `lib/l10n/app_en.arb` / `app_vi.arb` (and Android widget resources). Copy a design needs that does not exist yet →
> mark `NEW:` in the mockup so the developer adds it to both `.arb` files.

**Frame status legend** (used on every screen heading):
- ✅ **Drawn** — an approved frame exists in `design/current/screens/` (frame numbers like 2.1). Refresh only.
- 🟡 **Partly drawn** — the base frame exists but v1.1/v1.2 additions on it are **not drawn**.
- 🆕 **No frame** — exists in the app (built from shared components) but **never designed**. **Draw first.**
- 🤖 **Android only** (hidden on iOS, D‑019) · 🍏 needs an iOS proposal (§9).

---

## Contents
1. Product overview
2. Design constraints
3. Business rules the designer must know
4. Information architecture and navigation
5. Screens and dialogs inside the app (SCR‑01 … SCR‑33)
6. Surfaces outside the app (EXT‑01 … EXT‑05)
7. Key flows
8. Sample data for mockups
9. iOS: platform differences and proposals requested
10. Known UX weak points → design opportunities · Out of scope / Future
11. Deliverables requested from Claude Design

---

## 1. Product overview

### 1.1 One line
**Ví Gọn** ("tidy wallet") — record income and expenses in seconds and see at a glance where the money went, by
category. Fully offline, no account, no data collection, no internet permission.

### 1.2 Problem
People who want to know where their money goes each month give up because apps take too many steps, ask for an
account, or send data to a server. They fall back to paper, notes or spreadsheets and never get a summary. Ví Gọn logs
an expense in a few seconds and immediately shows spending by category.

### 1.3 Target users (personas)

| Persona | Situation | What they need from the UI |
|---|---|---|
| **Linh, 27, office worker (HCMC), Android** | Pays several times a day; logs right after paying, standing, **one hand**, weak signal. Uses the home‑screen widget | Widget → Expense → amount → category = saved. Thumb‑reachable controls, big keypad |
| **Minh, 20, student, iPhone** | Small budget; food is the risky category | Monthly budget + a **food category limit**, a calm "Over by X", a daily reminder at 21:00 |
| **Cô Hạnh, 52, keeps the family's market money** | Not tech‑savvy, Vietnamese only, large system text, worried about losing data | Big targets, readable at 200 %, plain words; automatic backup to Google Drive she sets up once |
| **Alex, 34, expat (EN), Android** | USD, several accounts (cash, card, e‑wallet), closed an old card | Account filter, transfers, **hide** the old card, search "rent" across all time, password‑protected backup |

### 1.4 Core jobs (priority order)
1. **Log an expense right after paying** — from Home, the widget or the reminder notification.
2. **See where money went this period** — donut by category, totals, balance, budgets.
3. **Find and fix records** — list by category, **search**, edit, delete with undo.
4. **Stay within budget** — monthly total + optional per‑category limits.
5. **Keep data safe and private** — manual backup (optionally password‑encrypted), automatic backup (Android), CSV,
   PIN lock, hide content in the app switcher (Android).
6. **Set up once** — categories, accounts (add/hide/delete), currency (all ISO 4217), week/month start, repeating
   records, reminder.

### 1.5 Design principles
1. **Offline & private by design.** No sign‑in, no cloud, no network spinners. Reassure quietly ("Your data is stored
   only on this phone"); every privacy‑affecting switch explains its consequence in one line.
2. **Log an entry in ≤ 3 taps** (AC‑02, excluding digit taps). Paths: ring icon → digits → **Save** (2 taps);
   **−** → digits → **Choose category** → tap category = **saved** (3 taps, D‑018).
3. **Calm, compact finance UI.** Numbers are the hero; colour is used sparingly. No gamification, no alarm walls.
4. **Thumb zone first.** Primary actions (− / +, keypad, Save) in the bottom half (AC‑37).
5. **Never rely on colour alone.** Income/expense carry a sign or word; any "over budget" has text + icon.
6. **Forgiving.** Single records delete instantly with 5‑s Undo; destructive bulk actions always confirm; passwords
   always warn "if you forget it, the file can't be opened".
7. **Same app on both platforms**, except OS‑owned behaviour and Android‑only features (§9).

---

## 2. Design constraints

### 2.1 Platforms, frames, orientation
- **Android** (Material 3, edge‑to‑edge) and **iOS 15+** (adaptive Material, not Cupertino widgets). One shared layout.
- **Base frames:** Android **360 × 800 dp** (smallest supported width) and iPhone 15/16 **393 × 852 pt**. Must also hold
  at 412 × 915.
- **Portrait only.** iPhone only (no iPad), no tablet/landscape.
- **Safe areas:** status bar, Android gesture bar, Dynamic Island, Home indicator. Bottom buttons/keypad above them.

### 2.2 Theme and visual starting point
- **Light, Dark, System** (AC‑35); every in‑app frame in both themes.
- Tokens: `design/current/screens/tokens.json` is the source of truth and is **already wired into the app**
  (`tool/gen_tokens.py` → `lib/src/ui/tokens.g.dart`, D‑010). Primary `#2E7D6B`/`#8CD5BF`; income `#2E7D32`/`#81C784`;
  expense `#C62828`/`#EF9A9A`; error `#BA1A1A`/`#FFB4AB`; surfaces `#F7FAF8`…; 16 category colours `cat-01…16`.
  Type **Be Vietnam Pro** (bundled) with **tabular figures** for amounts; 12 type styles (`amount-xl` … `key-glyph`).
  Icons **Material Symbols Rounded** (filled for category icons, outlined for actions).
- You may refine tokens, but **keep token names** (they map to Flutter `ColorScheme` + `ThemeExtension ViGonColors`) and
  list every change (§11.3). Contrast ≥ 4.5:1 text / 3:1 large text & icons in both themes (AC‑40). Don't use: `income`
  text on `surface-container-high` (4.22:1), `primary` text on `surface-container-high` (4.06:1) in light theme.
- **Category colours and icons are user data** (colour = ARGB int, icon = string key; both in backup files). Default
  categories now use the token palette (D‑010). The 31 selectable icon keys: restaurant, local_cafe, directions_bus,
  two_wheeler, local_gas_station, home, receipt_long, bolt, water_drop, wifi, shopping_bag, checkroom,
  health_and_safety, medication, movie, sports_esports, school, menu_book, family_restroom, child_care, pets, redeem,
  payments, savings, work, flight, fitness_center, spa, volunteer_activism, build, more_horiz. (Five legacy keys still
  render for old backups: local_grocery_store, phone_android, medical_services, card_giftcard, trending_up — no need to
  design them.) Restyle glyphs freely; keep keys and the 16 colour slots 1:1, or give an explicit old → new mapping.
- **Brand (D‑009):** logo "two stacked cards" — background `#0E5244`; back card `#8CD5BF` rotated −14°; front card
  `#F7FAF8` +8°, large radius, two lines `#0E5244` (long) / `#0E5244` 35 % (short), round dot `#E65100`; wordmark Be
  Vietnam Pro 600/700. App icon final (`store/brand/icon-512.png`, iOS icon set in `ios/Runner/Assets.xcassets`);
  Android 13+ **monochrome** layer exists (F‑23). Use the logo only where it helps (About, Lock, widget). Never coins,
  $, piggy bank, wallet with flap, leaf or donut as logo.
- **No tab bar.** Stack navigation from Home (§4). Don't add `NavigationBar`.

### 2.3 Accessibility (WCAG 2.2 AA target)
- **Touch targets ≥ 48 × 48 dp / 44 × 44 pt**; tokens: `tap-min` 48, `tap-key` 56 (keys, rows, balance bar), `tap-main`
  64 (− / +, PIN keys).
- **Text scale up to 200 %** without clipping (AC‑38). At ≥ 130 %: amounts move under row titles, 3‑way segmented
  controls stack vertically, the area above the keypad scrolls, button pairs wrap.
- Every control has a spoken label (listed per screen); chart has a one‑sentence text alternative; live regions for
  the amount being typed and PIN progress; screen readers TalkBack and VoiceOver.
- 2 px `focus` ring for keyboard / switch access. Respect "reduce motion".

### 2.4 Languages and copy length
- **Vietnamese (default) and English**, follows the device, switchable in Settings (AC‑36). "Ví Gọn" is the same in
  both. Widget button text follows the **device** language; everything else follows the app language.
- Design in English, check Vietnamese on tight screens. Longest / riskiest strings (EN | VI):

| Key | EN | VI | Where it bites |
|---|---|---|---|
| `currencyNote` | Changing the currency only changes the symbol; no exchange rate is applied. If the two currencies have a different number of decimals (for example VND and USD), amounts are multiplied or divided so the numbers you see stay the same; switching back may lose the fractional part. | Đổi tiền tệ chỉ đổi ký hiệu, không quy đổi tỉ giá. Nếu hai tiền tệ có số chữ số thập phân khác nhau (ví dụ VND và USD), số tiền được nhân hoặc chia để giữ nguyên con số; đổi ngược lại có thể mất phần lẻ. | Currency picker header |
| `forgotPinBody` | Ví Gọn has no server, so a PIN cannot be recovered. You can delete all data in the app to use it again. | Ví Gọn không có máy chủ nên không lấy lại được mã PIN. Bạn có thể xóa toàn bộ dữ liệu trong app để dùng lại. | Forgot‑PIN dialog |
| `reminderExplainBody` | Ví Gọn will send one notification every day at the time you choose, to remind you to record your spending. The notification contains no figures. | Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc ghi khoản. Thông báo không chứa số liệu. | Reminder explain dialog |
| `widgetShowAmountsNote` | Anyone holding the phone can see this number on the home screen. While PIN lock is on, the widget always hides amounts. | Ai cầm máy cũng nhìn thấy số này trên màn hình chờ. Khi đang bật khóa PIN, widget luôn ẩn số. | Settings switch subtitle (3 lines) |
| `autoBackupNote` | Ví Gọn only writes files to the folder you choose. Uploading to Google Drive or Dropbox is done by that app. | Ví Gọn chỉ ghi file vào thư mục bạn chọn. Việc tải lên Google Drive hay Dropbox do app đó thực hiện. | Auto‑backup switch subtitle |
| `autoBackupPasswordWarning` | If you forget the password, the backup files cannot be opened; you need it to restore on another device. | Quên mật khẩu thì không mở được các file sao lưu; bạn cần nhớ nó khi khôi phục trên máy khác. | Password dialog |
| `reminderDenied` | Notifications are not allowed. Turn on notifications for Ví Gọn in the system settings. | Chưa có quyền gửi thông báo. Hãy bật thông báo cho Ví Gọn trong cài đặt hệ thống. | 10‑s snackbar + action |
| `pinWarning` | If you forget the PIN, the only way back in is to delete all data in the app. | Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong app. | Settings subtitle |
| `backupNote` | You can protect the file with a password. Without one, the file is not encrypted. | Có thể đặt mật khẩu cho file. Không đặt thì file không được mã hóa. | Settings subtitle |
| `restoreFailed` | The file is invalid or damaged. Your data was not changed. | File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi. | Snackbar |
| `autoBackupFailedAt` + error | Attempt {time}: Could not write to the folder. Choose the folder again | Lần thử {time}: Không ghi được vào thư mục. Chọn lại thư mục | Auto‑backup status line (error colour) |
| `searchAllTime` | All time | Tất cả thời gian | Search chip (VI 2× longer) |
| `reminderSwitch` | Daily reminder | Nhắc ghi chép hằng ngày | Switch title |
| `privacyPolicy` | Privacy policy | Chính sách quyền riêng tư | About row |
| `themeSystem` | System | Theo hệ thống | 3‑way segmented control |
| `allAccounts` | All accounts | Tất cả tài khoản | Account filter |
| `secureWindow` | Hide content when switching apps | Che nội dung khi chuyển app | Settings switch |
| Period title (week) | Nov 2 – Nov 8, 2026 | 2 thg 11 – 8 thg 11, 2026 | Between ‹ › |

### 2.5 Number, currency and date formatting
- One currency for the whole app; **all active ISO 4217 codes (~156)**, 0/2/3 decimals (JPY 0, USD 2, KWD 3); default
  from device region (Vietnam → VND). No exchange rates.
- Money is an integer of minor units; display follows the **app language**: VI `1.250.000 ₫` (dot thousands, symbol
  after, NBSP); EN `₫1,250,000`, `$1,250.00`. Negative `-200.000 ₫` (account balances). Some codes have no symbol →
  the code is shown.
- **Large numbers:** max single amount 10¹² minor units → `1.000.000.000.000 ₫`; period totals ("All time") can be larger.
  Typing display auto‑shrinks; lists/ring centre must scale or wrap gracefully.
- Percent one decimal (`53,7%` / `53.7%`), section sums to 100.0. Short date `3 thg 11, 2026` / `Nov 3, 2026`; today =
  Today/Hôm nay. Time in auto‑backup status uses the app language (`3 thg 11, 18:30`); reminder time uses the device's
  12/24 h format.
- Period titles: Day `Tue, Nov 3, 2026`; Week `Nov 2 – Nov 8, 2026`; Month (starts day 1) `November 2026` / `Tháng 11
  năm 2026`, other start day → date range; Year `2026`; All time `All time` / `Tất cả`; Custom → range.
- **CSV** columns/types follow the app language (VI: `;` separator, `,` decimal; EN: `,` and `.`). Not a screen, but the
  export row may say which format is used.

---

## 3. Business rules the designer must know

1. **Entry** = income or expense record: amount > 0, category, account, date (default today), note ≤ 200. Type can't
   change after saving.
2. **Transfer** moves money between two accounts; it is **not** income/expense (not in ring, totals or budgets); it
   has its own "Transfer" section in Entries and changes account balances.
3. **Two balances:** *Period balance* (Home/Entries) = income − expense of the selected period; *Account balance*
   (Accounts) = starting balance + income − expense ± transfers, all time.
4. **Period:** Day / Week / Month / Year / All time / Custom range; default = month containing today; week start
   (Mon/Sun) and month start day (1–28) from Settings; period and account filter live only in memory.
5. **Account filter** (≥ 2 visible accounts) limits Home and Entries; transfers count if the account is source or
   destination; hidden accounts are not in the filter.
6. **Ring icons** = expense categories in user order around the donut. If more categories than fit (≈ 17 at 360 dp),
   the **last slot becomes "More categories" (⋯)** opening the full expense grid (F‑17). Income only via **+**.
   Defaults: Food, Transport, Home, Bills, Shopping, Health, Entertainment, Education, Family, Other / Salary, Bonus,
   Other income.
7. **Choosing a category saves** when the action key reads "Choose category" (D‑018). Closing the grid without choosing
   = no save.
8. **Repeating record (recurring series):** created only from New entry (Repeat chip). Due records are generated when
   the app opens / returns to foreground (no background job, no duplicates). Edit amount, note, **frequency, category,
   account** (F‑16); changing frequency restarts the series from the next due date of the old schedule (no back‑fill);
   generated records never change. Stop/resume; resume continues from today.
9. **Budgets:** one **monthly total** (Home bar) + optional **monthly limit per expense category** (F‑20, shown as a small
   bar on that category's row in Entries). Both are for the **current month** (month start day), all accounts,
   independent of the viewed period. Over → error style + "Over by X".
10. **Accounts (F‑14):** *Hide* removes an account from pickers, filter and transfer selectors; its old records stay
    and still count. *Delete* only when it has no records (incl. incoming transfers) and no repeating series; otherwise
    "This account has records, so it can only be hidden". At least one visible account must remain. Hidden accounts are
    listed in a collapsed "Hidden accounts" section → "Show again". (Known gap: hiding doesn't stop series that point to
    it.)
11. **Search (F‑15):** in Entries; matches note, category name or amount digits; case/diacritic‑insensitive; current
    period by default, chip "All time" for everything; flat list newest first + "N records · total X"; follows the
    account filter; tap = edit, swipe = delete + undo.
12. **Delete:** single record/transfer deletes immediately + "Deleted · Undo" 5 s. Deleting a category moves its records
    and series to a chosen category of the same type (last category of a type can't be deleted).
13. **Manual backup** `.vigon`: optional **password** (≥ 6 chars, twice, warning) → AES‑256‑GCM encrypted; without →
    plain JSON (app says so). **Restore** validates first; encrypted file → asks password ("Wrong password or the file
    is damaged"); valid → confirm → replaces all data. **CSV** export in app language.
14. **Automatic backup (F‑24, Android only):** user picks a folder (Drive, Dropbox, SD card, phone) via the system folder
    picker + sets a password; app writes an **always‑encrypted** file at most once a day when the app goes to the
    background and data changed; keeps the 7 newest `vigon-auto-*` files. Status line, "Back up now", "Choose folder
    again". Turning off deletes the password and folder access, keeps files. Config is device‑only (not in backups).
15. **Reminder (F‑25, Android + iOS):** daily local notification at a chosen time (default 20:00), generic text, **no
    figures**; asks OS permission only after an explain dialog when switched on; denied → switch stays off + "Open
    settings". Tapping it opens **New expense** (through the PIN lock if on). Approximate time on Android.
16. **Widget (F‑26, Android only):** 2×2 widget with **Expense / Income** buttons → New entry. Shows **no amounts by
    default**; with the "Show amounts on widget" switch on **and PIN off** it shows "Spent this month: X (/ budget)";
    with PIN on it shows "Locked with PIN". After month end without opening the app: "Open the app to update".
17. **Hide content when switching apps (F‑22, Android only):** blocks screenshots and blanks the app in Recents.
18. **PIN lock:** optional 4 digits; asked on cold start and after > 1 min in background; no recovery → delete all data
    (two extra confirms). Wrong attempts unlimited (v1). Widget/notification entry always goes through the lock.
19. **Currency change** only swaps the symbol; different decimals → amounts, budgets and category limits are scaled so
    visible numbers stay the same; switching back may lose fractions.
20. **Device‑only settings:** widget‑amount switch and reminder switch are not restored from backups (they return OFF
    after a restore); reminder time does travel with the backup.

---

## 4. Information architecture and navigation

### 4.1 Routes (one stack, all children of `/`)

| Route | Screen | Params | SCR |
|---|---|---|---|
| `/` | Home | — | 01 |
| `/entry/new` | New entry | `type=expense\|income`, `category=<id>` — also the **only** deep‑link target (widget, notification) | 05 |
| `/entry/:id` | Edit income/expense | `id` | 06 |
| `/entries` | Entries list (+ search mode) | — | 10, 11 |
| `/settings` | Settings | — | 12 |
| `/categories` | Categories | — | 15 |
| `/accounts` | Accounts (+ hidden section) | — | 17 |
| `/transfer`, `/transfer/:id` | Transfer new / edit | `id` | 19 |
| `/recurring` | Repeating records | — | 20 |
| `/about` | About | — | 22 |
| *(overlay)* | Lock screen | — | 23 |

### 4.2 Navigation map

```
App start ─► [Lock SCR-23] (if PIN) ─► Home      Forgot PIN ─► 3 dialogs (SCR-25) ─► fresh Home

Home "/" (SCR-01)
 ├─ [− Expense] / [+ Income] ────► New entry (SCR-05) ─ sheets: category (07), repeat/account (08), date (09)
 ├─ ring category icon ──────────► New expense, category pre-selected
 ├─ ⋯ "More categories" slot ────► Category grid (07) ─► New expense with that category
 ├─ period title ────────────────► "View by" sheet (02) ─► Custom range calendar
 ├─ ‹ › / swipe ─────────────────► previous / next period
 ├─ budget bar ──────────────────► Monthly budget dialog (04)
 ├─ balance bar / list icon ─────► Entries (10) ─ 🔍 Search (11) ─ tap row ─► Edit entry (06) / Transfer (19)
 ├─ wallet icon (≥ 2 accounts) ──► Account filter menu (03)
 └─ gear ────────────────────────► Settings (12)
       Categories (15) ─► sheet (16: name, icon, colour, category budget) ─► delete + move dialog
       Accounts (17) ─► sheet (18: name, starting balance, Hide / Delete) ─► delete confirm
          ├─ Hidden accounts section ─► Show again
          └─ ⇄ ─► Transfer (19)
       Monthly budget (04) · Repeating records (20) ─► edit dialog (21) · Currency (13, searchable) · First day of week
       Month starts on day (14)
       Security: Lock with PIN (24) · Hide content when switching apps 🤖 · Show amounts on widget 🤖
       Reminder: Daily reminder ─► explain dialog (30) ─► OS permission · Reminder time ─► OS time picker
       Data: Export backup ─► password option dialog (26) ─► share sheet
             Restore ─► file picker ─► [password dialog (27)] ─► confirm ─► result
             Export CSV (28) ─► share sheet
             Automatic backup 🤖 ─► folder picker ─► password dialog (31) ─► Back up now / Choose folder again
             Delete all data ─► 2 dialogs (29)
       About (22)

Outside the app: Widget 🤖 (EXT-01) ─► Lock? ─► New entry · Reminder notification (EXT-02) ─► Lock? ─► New expense
                 Recents with hidden content 🤖 (EXT-03) · OS permission / share / file / folder pickers (EXT-04)
                 App icon incl. monochrome 🤖 (EXT-05)
```

---

## 5. Screens and dialogs inside the app

Per screen: **Status · Purpose · Components · States · Interactions · Copy (EN | VI) · Accessibility.** Existing frame
numbers refer to `design/current/screens/components/S01…S16`.

### SCR‑01 · Home — `/` · 🟡 (frames 2.1–2.3; "More categories" slot 🆕)
**Purpose:** see where money went this period; start a record in one tap (F‑01, F‑02, F‑09, F‑17).
**Components (top → bottom), as implemented:**
1. App bar "Ví Gọn" (left‑aligned). Actions: **wallet** (account filter; only if ≥ 2 visible accounts) · **receipt**
   icon "Records" → `/entries` · **gear** "Settings".
2. Period header: ‹ "Previous period" · period title (tap → SCR‑02) · › "Next period".
3. Budget bar (only if a monthly budget is set): text line + 8 dp bar; over → error colour, bold, warning icon, full bar.
4. Chart area (swipe left/right = next/previous period): donut ring (arcs by expense category, largest first from 12
   o'clock), centre **Income** (green) and **Expenses** (red) totals; expense category icons (48 dp) evenly around the
   ring; **🆕 last slot "More categories" (⋯, neutral background)** when categories exceed the slots.
5. Balance bar (56 dp, chevron): "Balance: X" → `/entries`.
6. Two main buttons (64 dp): **− Expenses** (red, left) and **+ Income** (green, right) — glyph + word.
**States:** default with data · **empty period** (ring replaced by "Tap − to record your first expense", icons stay) ·
income only (full green ring) · budget under / ≥ 100 % · no budget · single account (no wallet) · **filter active**
(today only the tooltip shows it — §10.1 #1) · **many categories (25) → ⋯ slot** · large totals · text 200 % · All time
(‹ › disabled) · long VI week title · loading (local DB; no spinner, use nothing or a skeleton).
**Copy:**
| Element | EN | VI |
|---|---|---|
| Title | Ví Gọn | Ví Gọn |
| Wallet tooltip | Account / Account: {name} | Tài khoản / Tài khoản: {name} |
| List icon · gear | Records · Settings | Các khoản · Cài đặt |
| Arrows · title hint | Previous period · Next period · Choose period | Kỳ trước · Kỳ sau · Chọn kỳ xem |
| Centre | Income · Expenses | Thu · Chi |
| Budget | Monthly budget: Spent {spent} of {limit} | Ngân sách tháng: Đã chi {spent} / {limit} |
| Budget over | Monthly budget: Over by {amount} | Ngân sách tháng: Vượt {amount} |
| Balance | Balance: {amount} | Số dư: {amount} |
| Buttons (visible) | − Expenses · + Income | − Chi · + Thu |
| Buttons (spoken) | Add expense · Add income | Thêm khoản chi · Thêm khoản thu |
| ⋯ slot | More categories | Danh mục khác |
| Empty | Tap − to record your first expense | Bấm − để ghi khoản chi đầu tiên |
**A11y:** chart = one sentence "Expenses by category: Home, ₫3,500,000, 29.7%; …"; ring icon "Add expense: Food,
₫3,240,000, 27.5%" or "…, no records"; ⋯ slot "More categories"; budget bar reads the whole sentence.

### SCR‑02 · "View by" sheet + custom range calendar · ✅ (2.4, 2.5)
Bottom sheet titled **View by**: Day, Week, Month, Year, All time, Custom range; selected row `primary-container` + ✓;
choosing jumps to the period containing today. Custom range → app's own **range calendar in a sheet** (month nav
‹ ›, hint "Pick the first day, then the last day", start/end circles, range fill, today outlined, **Apply**; Cancel
keeps old period; reversed picks auto‑swap; years 2000 → now+10).
**States:** each type selected; range half‑picked; range across months; VI.
**Copy:** View by/Xem theo · Day/Ngày · Week/Tuần · Month/Tháng · Year/Năm · All time/Tất cả · Custom range/Khoảng tùy
chọn · Previous month/Tháng trước · Next month/Tháng sau · Pick the first day, then the last day/Chọn ngày đầu rồi ngày
cuối · Apply/Áp dụng · Cancel/Hủy.

### SCR‑03 · Account filter menu · ✅ (2.6)
224‑dp menu under the wallet icon: "All accounts" (select‑all icon) + each **visible** account (wallet icon); ✓ on
current. Hidden accounts never appear; hiding the filtered account clears the filter.
**States:** 2 accounts; 6 accounts; long name (ellipsis). **Copy:** All accounts/Tất cả tài khoản; Cash/Tiền mặt.

### SCR‑04 · Monthly budget dialog · ✅ (5.3, 5.4)
Title "Monthly budget"; field labelled **Amount** with currency, autofocus; **Remove budget** (only if set), **Cancel**,
**Save**; error "Amount must be greater than 0". Opened from Home bar or Settings.
**Copy:** Monthly budget/Ngân sách tháng · Amount/Số tiền · Remove budget/Bỏ ngân sách · Cancel/Hủy · Save/Lưu.

### SCR‑05 · New entry + keypad — `/entry/new` · ✅ (3.1–3.8; note D‑018)
**Purpose:** record an expense/income as fast as possible (F‑01, F‑08). Also opened by the widget and the reminder.
**Components:** back arrow + title "New expense"/"New income"; **amount display** (live region; expression line +
big formatted amount in red/green, auto‑shrink; error line); **chip row** — Category (after choosing) · Date ("Today")
· Repeat ("Does not repeat"…) · Account (only ≥ 2 visible accounts; default = first visible); **Note** (≤ 200, counter);
upper part scrolls; **keypad pinned** (5 rows, keys ≥ 56 dp; ÷ × − + = on `secondary-container`; `000` for 0‑decimal
currencies, `.` otherwise; wide key **Choose category** → after choosing **Save**, red/green).
**Behaviour change vs frame 3.3 (D‑018):** when the wide key reads "Choose category", picking a category in the grid
**saves immediately** and returns to Home. Please update frame 3.3's annotation; show the "saving → back to Home"
transition.
**States:** fresh (no category) · pre‑selected (from ring) · typing `120+35` · invalid / ≤ 0 · income · repeat set ·
≥ 2 accounts · long note / long category · `1.000.000.000.000 ₫` · USD (`.` key) · text 200 % · **opened from widget or
notification** (same screen, Back → Home).
**Copy:** New expense/Khoản chi mới · New income/Khoản thu mới · Choose category/Chọn danh mục · Save/Lưu · Today/Hôm
nay · Repeat/Lặp lại · Does not repeat/Không lặp · Daily/Hằng ngày · Weekly/Hằng tuần · Monthly/Hằng tháng ·
Yearly/Hằng năm · Account/Tài khoản · Note/Ghi chú · Invalid calculation/Phép tính không hợp lệ · Amount must be greater
than 0/Số tiền phải lớn hơn 0.
**A11y:** amount live region; keys "Backspace"/"Xóa lùi", "Equals"/"Bằng"; chips announce current value.

### SCR‑06 · Edit entry — `/entry/:id` · ✅ (4.5–4.7)
Title "Edit record"; trash "Delete"; prefilled; type fixed; series member shows the frequency chip + ⏹ **Stop
repeating** → "Stopped". A **hidden account** of an old record still shows its name in the account chip. States:
loading (brief), record gone (closes), running/stopped series. Delete → close → "Deleted · Undo".
**Copy:** Edit record/Sửa khoản · Delete/Xóa · Stop repeating/Dừng lặp lại · Stopped/Đã dừng · Deleted/Đã xóa ·
Undo/Hoàn tác.

### SCR‑07 · Category grid sheet (shared) · 🟡 (3.3; "from ⋯ slot" variant 🆕)
Title "Choose category"; grid of 48 dp avatars + name (2 lines max), cells ≤ 96 dp. Used by the entry editor
(expense or income categories) and by Home's ⋯ slot (all expense categories → opens New expense with that category).
**States:** 10 / 3 defaults; **25 categories** (scrolls, sheet max height); long names; selected marked.
**Copy:** Choose category/Chọn danh mục; defaults EN Food, Transport, Home, Bills, Shopping, Health, Entertainment,
Education, Family, Other; Salary, Bonus, Other income — VI Ăn uống, Đi lại, Nhà cửa, Hóa đơn, Mua sắm, Sức khỏe, Giải
trí, Giáo dục, Gia đình, Khác; Lương, Thưởng, Thu khác.

### SCR‑08 · Repeat sheet / Account sheet · ✅ (3.5, 3.6)
Choice sheets with ✓. Account sheet lists **visible** accounts only. Copy as SCR‑05.

### SCR‑09 · Date picker · ✅
Material single‑date picker on both platforms (2000 → now+10), token‑styled.

### SCR‑10 · Entries list — `/entries` · 🟡 (4.1–4.4; category‑budget bar 🆕)
**Components:** app bar = period title + **🔍 Search** action; Balance row (large); **Expenses** section (total, then
categories by total: 40 dp avatar · name + % · total + chevron; tap to expand records newest first); **🆕 category with
a monthly limit** shows a small progress bar "Spent X of Y" under its row, **"Over by Z"** in error style when over
(current month, independent of the viewed period); **Income** section; **Transfer** section ("{from} → {to}").
Record row: note (or category), date, amount; tap → edit; **swipe left** → delete + "Deleted · Undo".
**States:** with data (one expanded) · **category under / over its limit** · swipe · undo · empty "No records in this
period" · only transfers · 5,000 records · long notes · 25 categories · text 200 % · filtered by account.
**Copy:** Balance/Số dư · Expenses/Chi · Income/Thu · Transfer/Chuyển tiền · Spent {spent} of {limit}/Đã chi {spent} /
{limit} · Over by {amount}/Vượt {amount} · No records in this period/Kỳ này chưa có khoản nào · Search/Tìm.
**A11y:** category row announces name, amount, %, expanded state and budget status; swipe has a non‑gesture
alternative (open → Delete).

### SCR‑11 · Entries search (mode of `/entries`) · 🆕
**Purpose:** find records by note, category or amount (F‑15).
**Components:** search field in the app bar (hint "Note, category or amount", close "Close search"; Back closes search
first); chip **All time** (off = current period); summary line "{count} records · total {total}"; flat result list
newest first (same record row; transfers included); tap = edit; swipe = delete + undo.
**States:** empty query (show the normal list or a hint — propose) · typing with results · **no match** "No matching
records" · All time on/off · amount query "155" matching 155,000 and 1,550,000 (highlight the match — propose) · VI
diacritic‑insensitive ("an uong" finds "Ăn uống") · filtered by account · keyboard open (results above keyboard).
**Copy:** Search/Tìm · Note, category or amount/Ghi chú, danh mục hoặc số tiền · Close search/Đóng tìm kiếm · All
time/Tất cả thời gian · No matching records/Không có khoản nào khớp · {count} records · total {total}/{count} khoản ·
tổng {total}.

### SCR‑12 · Settings — `/settings` · 🟡 (5.1–5.2; Security additions, Reminder group, Automatic backup 🆕)
One scrolling list (now ≈ 25 rows — the longest screen; §10.1 #3). Order as implemented:
| # | Group / row | Control | Notes |
|---|---|---|---|
| 1 | **Theme** | 3‑way segmented System / Light / Dark | stacks at ≥ 130 % |
| 2 | **Language** | 3‑way System / Tiếng Việt / English | |
| 3 | Categories › · Accounts › | nav rows | |
| 4 | Monthly budget | row + "Not set"/amount | → SCR‑04 |
| 5 | Repeating records › | nav row | |
| 6 | Currency | row + "VND · ₫" | → SCR‑13 |
| 7 | First day of week | row + Monday/Sunday | **tap toggles** (§10.1 #4) |
| 8 | Month starts on day | row + dropdown 1–28 | → SCR‑14 |
| 9 | **Security** · Lock with PIN | switch + `pinWarning` | → SCR‑24 |
| 10 | 🆕🤖 Hide content when switching apps | switch + note | instant; see EXT‑03 |
| 11 | 🆕🤖 Show amounts on widget | switch + 2‑sentence warning | still toggleable when PIN is on, but widget shows "Locked with PIN" — make that visible here |
| 12 | 🆕 **Reminder** · Daily reminder | switch + note | → SCR‑30 |
| 13 | 🆕 Reminder time | row + "20:00" | OS time picker; editable while off (only saves) |
| 14 | **Data** + reminder line | text | |
| 15 | Export backup | row + `backupNote` | → SCR‑26 |
| 16 | Restore from backup | row | → SCR‑27 |
| 17 | Export CSV | row | → SCR‑28 |
| 18 | 🆕🤖 Automatic backup block | switch + note; when on: "Folder: {name}" + status line; buttons **Back up now** · **Choose folder again** | → SCR‑31 |
| 19 | Delete all data | row in error colour | → SCR‑29 |
| 20 | About › | nav row | |
On **iOS rows 10, 11 and 18 are absent** (not disabled — removed); design the iOS Settings frame without them.
**States:** top / middle / bottom; PIN on vs off; widget switch on with PIN on; reminder on/off; auto‑backup off / on
never run / on OK / on error (folder) / on error (other) / running; VI; text 200 %; dark; **iOS variant**.
**Copy (new rows):**
| EN | VI |
|---|---|
| Hide content when switching apps · Blocks screenshots and hides content in the recent apps list | Che nội dung khi chuyển app · Chặn chụp màn hình và ẩn nội dung trong danh sách app gần đây |
| Show amounts on widget · `widgetShowAmountsNote` | Hiện số tiền trên widget · (VI §2.4) |
| Reminder · Daily reminder · One notification a day at the time you choose, with no figures in it | Nhắc ghi chép · Nhắc ghi chép hằng ngày · Mỗi ngày một thông báo vào giờ bạn chọn, không chứa số liệu |
| Reminder time | Giờ nhắc |
| Export backup · You can protect the file with a password. Without one, the file is not encrypted. | Xuất bản sao lưu · Có thể đặt mật khẩu cho file. Không đặt thì file không được mã hóa. |
| Automatic backup · `autoBackupNote` | Sao lưu tự động · (VI §2.4) |
| Folder: {name} · Chosen folder | Thư mục: {name} · Thư mục đã chọn |
| No backup yet · Last: {time} · Attempt {time}: {error} | Chưa sao lưu lần nào · Lần cuối: {time} · Lần thử {time}: {error} |
| Back up now · Choose folder again | Sao lưu ngay · Chọn lại thư mục |
(Unchanged rows as v1: Theme/Giao diện, Language/Ngôn ngữ, Categories/Danh mục, Accounts/Tài khoản, Monthly budget ·
Not set/Ngân sách tháng · Chưa đặt, Repeating records/Khoản định kỳ, Currency/Tiền tệ, First day of week · Monday ·
Sunday/Ngày đầu tuần · Thứ Hai · Chủ Nhật, Month starts on day/Tháng bắt đầu từ ngày, Security/Bảo mật, Lock with
PIN/Khóa bằng mã PIN, Data/Dữ liệu, Restore from backup/Khôi phục từ bản sao lưu, Export CSV/Xuất CSV, Delete all
data/Xóa toàn bộ dữ liệu, About/Giới thiệu.)
**A11y:** group titles are headers; switches announce state + subtitle; error status has text, not only colour.

### SCR‑13 · Currency picker (searchable) · 🟡 (5.5; search field + 156 codes 🆕)
Dialog/sheet: **search field** "Search by code or name"; note `currencyNote`; lazy list of ~156 ISO codes "{CODE} ·
{symbol}" (code only when no symbol) with ✓ on current; empty "No matching currency". Choosing applies immediately.
**States:** VND selected; search "dol" → USD, AUD, CAD…; no match; VI note (6 lines at 360 dp) — propose a full‑height
sheet with collapsible note and current currency pinned.
**Copy:** Currency/Tiền tệ · Search by code or name/Tìm theo mã hoặc tên · No matching currency/Không có tiền tệ nào khớp.

### SCR‑14 · Month start day menu · ✅ (5.6)
Dropdown 1–28 on the Settings row.

### SCR‑15 · Categories — `/categories` · ✅ (6.1)
Tabs **Expenses / Income**; rows (40 dp avatar, name, drag handle "Drag to reorder"); FAB **+ Add category**. Order
drives ring icons and grid. Propose showing a small "limit" hint on rows with a category budget (optional).
**A11y:** non‑drag reorder alternative (custom actions — NEW copy "Move up"/"Move down").

### SCR‑16 · Category add/edit sheet + delete/move dialog · 🟡 (6.2, 6.3; budget field 🆕)
Sheet: title "Add category"/"Edit category"; **Name** (≤ 50, "Enter a name"); **Icon** grid (31); **Color** (16
swatches, ring + ✓); **🆕 expense only: "Category monthly budget"** field (hint "Leave empty for none"; ≤ 0 → "Amount
must be greater than 0"); buttons **Delete category** (edit, ≥ 2 of that type) and **Save**, pinned outside the scroll.
Delete dialog: "Delete this category?" + "{count} records will be moved to:" + list of target categories; **empty
category** variant "This category has no records."
**States:** add; edit default; edit with budget set; name error; budget error; keyboard open; delete with 0 / 37 records.
**Copy:** Add category/Thêm danh mục · Edit category/Sửa danh mục · Name/Tên · Enter a name/Nhập tên · Icon/Biểu tượng ·
Color/Màu · Category monthly budget/Ngân sách tháng của danh mục · Leave empty for none/Để trống nếu không đặt · Delete
category/Xóa danh mục · Save/Lưu · Delete this category?/Xóa danh mục này? · {count} records will be moved to:/{count}
khoản sẽ được chuyển sang: · This category has no records./Danh mục này chưa có khoản nào.
**A11y:** "Icon N"/"Biểu tượng N"; colours "Color N" + selected.

### SCR‑17 · Accounts — `/accounts` · 🟡 (6.4; Hidden accounts section 🆕)
App bar "Accounts" + ⇄ "Transfer" (≥ 2 visible accounts). Rows: wallet icon · name · **account balance** (negative
allowed). FAB **+ Add account**. **🆕 Collapsed "Hidden accounts" section** at the bottom (closed by default) listing
hidden accounts with balances; tap a row or **Show again** to unhide.
**States:** only Cash; 4 accounts incl. negative; with 2 hidden accounts (collapsed / expanded); long names; large
balances; text 200 %.
**Copy:** Accounts/Tài khoản · Transfer/Chuyển tiền · Add account/Thêm tài khoản · Hidden accounts/Tài khoản đã ẩn ·
Show again/Hiện lại · Cash/Tiền mặt.

### SCR‑18 · Account add/edit sheet + Hide / Delete · 🟡 (6.5; Hide/Delete area 🆕)
Sheet: "Add account"/"Edit account"; **Name** (≤ 50); **Starting balance** (helper "Leave empty for 0. Negative amounts
are allowed."; bad input "Invalid calculation"); **Save**. **🆕 Edit only, management area:** **Hide account**;
**Delete account** (only if unused) → confirm dialog (destructive) 'Delete the account "{name}"?'; if used: hint "This
account has records, so it can only be hidden" (no delete button); last visible account: no buttons, hint "At least one
account must remain".
**States:** add; edit unused (Hide + Delete); edit used (Hide + hint); last visible (hint only); delete confirm.
**Copy:** Add account/Thêm tài khoản · Edit account/Sửa tài khoản · Name/Tên · Starting balance/Số dư ban đầu · Leave
empty for 0. Negative amounts are allowed./Để trống = 0. Cho phép số âm. · Hide account/Ẩn tài khoản · Delete
account/Xóa tài khoản · Delete the account "{name}"?/Xóa tài khoản "{name}"? · This account has records, so it can only
be hidden/Tài khoản đã có khoản, chỉ ẩn được · At least one account must remain/Phải còn ít nhất một tài khoản ·
Delete/Xóa · Cancel/Hủy.

### SCR‑19 · Transfer — `/transfer`, `/transfer/:id` · ✅ (6.6, 6.7)
**From** and **To** selectors stacked (error outline when equal), big amount, date chip, note, keypad with **Save** in
primary; trash when editing. Only visible accounts selectable, except a hidden account already used by the transfer
being edited. Errors "Choose two different accounts", "Amount must be greater than 0".
**Copy:** Transfer/Chuyển tiền · From/Từ · To/Đến · Save/Lưu · Delete/Xóa.

### SCR‑20 · Repeating records — `/recurring` · ✅ (7.1, 7.3)
Rows: category avatar · "{Category} · {amount}" · "{Frequency} · {next due}" or "· Stopped" · switch (stop/resume
from today). Tap → SCR‑21. No add button. Empty "No repeating records yet. Turn on Repeat when adding a record."
**Copy:** Repeating records/Khoản định kỳ · Stopped/Đã dừng.

### SCR‑21 · Edit repeating record dialog · 🟡 (7.2 shows amount + note only; frequency/category/account 🆕)
Title "Repeating records"; **Amount** (with currency, autofocus); **Note** with helper "Applies to the records it
creates from now on."; **🆕 Repeat** (Daily/Weekly/Monthly/Yearly); **🆕 Categories** (same type); **🆕 Account** (only
if ≥ 2 visible accounts); **Cancel** / **Save**.
**Design ask:** this is now a 5‑field form — a dialog may be too tight at 360 dp / 200 % text. Propose a full‑height
sheet or page. Explain the frequency rule when it changes (e.g. NEW hint "Restarts from the next due date: Dec 17").
**States:** running / stopped series; frequency changed (show next due); amount error; one account (no account field).
**Copy:** Repeating records/Khoản định kỳ · Amount/Số tiền · Note/Ghi chú · Applies to the records it creates from now
on./Áp dụng cho các lần sinh sau. · Repeat/Lặp lại · Categories/Danh mục · Account/Tài khoản · Cancel/Hủy · Save/Lưu.

### SCR‑22 · About — `/about` · ✅ (9.1, 9.2)
Logo/wordmark; "Version 1.0.0 (1)"; "Your data is stored only on this phone. Ví Gọn does not send it anywhere."; rows
**Privacy policy** (disabled + "Web page coming soon" until the URL exists), **Report a security issue** ("Contact
email: {email}", opens mail), **Open source licenses**. "Could not open it. You can write to {target} yourself" snackbar.
Use a placeholder email in mockups.

### SCR‑23 · Lock screen (overlay) · ✅ (1.1, 1.2)
Lock icon/logo; "Enter PIN"; 4 dots (live region "{count} of 4 digits entered"); fixed‑height error line "Wrong PIN";
PIN pad 3×4 (pill keys ~88 × 64); **Forgot PIN**. Blank surface while checking. **Also shown when entering from the
widget or notification** — after unlocking the user lands on New entry (design this hand‑off).
**Copy:** Enter PIN/Nhập mã PIN · Wrong PIN/Sai mã PIN · Forgot PIN/Quên mã · Digit {n}/Số {n} · Backspace/Xóa lùi.

### SCR‑24 · PIN setup / PIN check · ✅ (8.1–8.4)
Full screen, app bar "Lock with PIN" + back (= cancel). "Choose a 4-digit PIN" + warning → "Enter the PIN again" →
saved; mismatch "The PINs do not match". Turning off: "Enter PIN".
**Copy VI:** Khóa bằng mã PIN · Đặt mã PIN 4 số · Nhập lại mã PIN · Hai lần nhập không khớp · Nhập mã PIN.

### SCR‑25 · Forgot PIN (3 dialogs over the lock) · ✅ (1.3–1.5)
1. "Forgot PIN" / `forgotPinBody` / Cancel · **Delete all data**. 2. "Delete all data?" / "Delete all records,
categories, accounts and settings on this phone?" / Cancel · **Delete**. 3. "This cannot be undone" / "This cannot be
undone. Delete everything?" / Cancel · **Delete all data** (error‑filled). → fresh Home + "All data deleted".
**VI:** Quên mã · Xóa toàn bộ dữ liệu? · Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy này? · Xóa ·
Không hoàn tác được · Không hoàn tác được. Xóa hết? · Xóa toàn bộ dữ liệu · Đã xóa toàn bộ dữ liệu.

### SCR‑26 · Export backup dialog (password option) · 🆕 (frame 8.5 shows only the share sheet)
Dialog title "Export backup"; switch **Protect file with a password** (default off); when on: **Password** and **Repeat
password** (obscured, no suggestions), warning "If you forget the password, this file cannot be opened."; buttons
Cancel / **Export**. Errors under fields: "Password needs at least 6 characters", "Passwords do not match". Encrypting
shows a progress state "Working" (a few seconds on slow phones). Then the OS share sheet (EXT‑04) with
`vigon-YYYYMMDD-HHMM.vigon`.
**States:** off (default) · on empty · on with errors · working · (keyboard open at 360 dp).
**Copy:** Export backup/Xuất bản sao lưu · Protect file with a password/Đặt mật khẩu cho file · Password/Mật khẩu ·
Repeat password/Nhập lại mật khẩu · If you forget the password, this file cannot be opened./Quên mật khẩu thì không mở
được file này. · Password needs at least 6 characters/Mật khẩu tối thiểu 6 ký tự · Passwords do not match/Hai mật khẩu
không khớp · Export/Xuất · Working/Đang xử lý · Cancel/Hủy.

### SCR‑27 · Restore flow (password dialog 🆕) · 🟡 (8.6–8.8)
OS file picker (EXT‑04) → validate. Plain invalid → snackbar `restoreFailed`. **🆕 Encrypted file → dialog "Password-
protected file"**, body "Enter the password you set when exporting this file.", **Password** field, Cancel / **Open**;
wrong → field error "Wrong password or the file is damaged"; decrypting shows "Working". Valid → confirm "Restore from
backup" / "Your current data will be replaced by the backup. Continue?" / Cancel · **Confirm** → "Data restored"
(account filter resets; reminder and widget‑amount switches return OFF — consider a NEW one‑line note).
**Copy:** Password-protected file/File có mật khẩu · Enter the password you set when exporting this file./Nhập mật khẩu
đã đặt khi xuất file này. · Open/Mở · Wrong password or the file is damaged/Sai mật khẩu hoặc file bị hỏng · Restore from
backup/Khôi phục từ bản sao lưu · Your current data will be replaced by the backup. Continue?/Dữ liệu hiện tại sẽ bị
thay thế bằng bản sao lưu. Tiếp tục? · Confirm/Đồng ý · Data restored/Đã khôi phục dữ liệu.

### SCR‑28 · Export CSV · ✅ (within 8.5)
Row → file `vigon-YYYYMMDD-HHMM.csv` → share sheet. Headers/types follow app language (VI `Ngày;Loại;Số tiền;Tiền
tệ;Danh mục;Tài khoản;Đến tài khoản;Ghi chú`, EN `date,type,amount,currency,category,account,to_account,note`). Optional:
a subtitle telling which format (NEW copy) — propose.

### SCR‑29 · Delete all data · ✅ (8.9–8.11)
Dialog 1 "Delete all data?" / `deleteAllConfirm` / Cancel · **Delete**. Dialog 2 "This cannot be undone" /
`deleteAllConfirm2` / Cancel · **Delete all data** (error). Result: defaults recreated, currency re‑detected, PIN off,
**automatic backup turned off** (files kept), "All data deleted", Home empty state.

### SCR‑30 · Reminder: explain dialog, permission, denied, time picker · 🆕
1. Switch on → dialog **"Turn on the reminder?"** / `reminderExplainBody` / Cancel · **Continue**.
2. Continue → OS notification‑permission prompt (Android 13+; iOS) — placeholder (EXT‑04).
3. Allowed → switch on, schedule set. **Denied** → switch stays off + 10‑s snackbar `reminderDenied` with action **Open
   settings**.
4. "Reminder time" → OS time picker (titled "Reminder time"); subtitle shows the new time.
**States:** off; explain dialog; on (20:00); denied snackbar; time changed (21:30); iOS variant.
**Copy:** Turn on the reminder?/Bật nhắc ghi chép? · Continue/Tiếp tục · Open settings/Mở cài đặt · Reminder time/Giờ
nhắc · Cancel/Hủy.

### SCR‑31 · Automatic backup set‑up and status · 🆕🤖🍏
1. Switch on → OS **folder picker** (EXT‑04; Drive/Dropbox/SD/phone). Closing it = nothing. Picker error → "Could not
   open the folder picker".
2. Dialog **"Automatic backup password"**: Password + Repeat password, warning in error colour `autoBackupPasswordWarning`,
   Cancel / **Turn on**; errors as SCR‑26. Cancel = not enabled, folder access released.
3. First **Back up now** runs → spinner on the button → "Backup saved" or error.
4. Block shows: "Folder: {name}"; status "No backup yet" / "Last: 3 Nov, 18:30" / error colour "Attempt 3 Nov, 18:30:
   Could not write to the folder. Choose the folder again" or "…: Backup failed. Try again with Back up now"; buttons
   **Back up now** (tonal) and **Choose folder again** (outlined), wrapping at large text; busy → "A backup is already
   running, try again in a moment".
5. Switch off → "Automatic backup is off. Files already written stay in the folder."
**States:** off · picker · password dialog (+errors) · on never run · running · OK · folder error · other error · busy ·
turned off · text 200 %.
**Copy:** Automatic backup/Sao lưu tự động · Automatic backup password/Mật khẩu sao lưu tự động · Turn on/Bật · Backup
saved/Đã sao lưu · Could not open the folder picker/Không mở được bộ chọn thư mục · Could not write to the folder. Choose
the folder again/Không ghi được vào thư mục. Chọn lại thư mục · Backup failed. Try again with Back up now/Sao lưu không
thành công. Thử lại bằng Sao lưu ngay · A backup is already running, try again in a moment/Đang sao lưu, thử lại sau
giây lát · Automatic backup is off. Files already written stay in the folder./Đã tắt sao lưu tự động. File đã ghi vẫn
còn trong thư mục.

### SCR‑32 · Shared: confirm dialog, snackbar, progress · ✅ (components)
- **Confirm dialog** (`surface-container-high`, radius 28): title, body, Cancel + action (filled; `error` fill when
  destructive). Tap outside / Back = Cancel.
- **Snackbar** (floating, `inverse-surface`, action `inverse-primary`): "Deleted · Undo" (5 s), "Data restored", "All
  data deleted", "Stopped", "Backup saved", `restoreFailed`, `reminderDenied` (10 s + Open settings), "Could not open
  it…". Design 1‑ and 2‑line (VI) variants; keep clear of the − / + buttons.
- **Progress** "Working"/"Đang xử lý" for encrypt/decrypt (button spinner or inline row).

### SCR‑33 · Settings on iOS · 🆕 (variant of SCR‑12)
Same as SCR‑12 without rows 10, 11, 18 (D‑019). Reminder group present (iOS permission prompt). Check spacing still
reads well when the Security group has only "Lock with PIN".

---

## 6. Surfaces outside the app

### EXT‑01 · Home‑screen widget 2×2 · 🆕🤖🍏
Android `AppWidget`, default/min 2×2 (≥ 110 × 110 dp), resizable. Today (functional, not designed): background
`#0E5244`, radius 20, padding 8; optional **status line** (12 sp, `#F7FAF8`, 1 line, ellipsis); two side‑by‑side
buttons **Expense** (`#C62828`) and **Income** (`#2E7D32`), white bold 18 sp, ≥ 48 dp. Fixed colours (doesn't follow app
theme). Tap → app → (Lock if PIN) → New entry of that type.
**Status line states (AC‑64):** switch off → none (two buttons only) · on + PIN off → "Spent this month: ₫150,000" ·
with budget → "Spent this month: ₫150,000 / ₫1,000,000" · PIN on (or unknown) → "Locked with PIN" · month ended without
opening the app → "Open the app to update".
**Design asks:** widget picker preview + label/description; light/dark wallpaper legibility; 2×2 and a stretched 4×2;
Android 12+ rounded/dynamic‑colour considerations (stay brand‑fixed unless you argue otherwise); long VI amounts.
**Copy (device language):** Ví Gọn · Quickly add an expense or income/Thêm nhanh khoản chi hoặc thu · Expense/Chi ·
Income/Thu · Add expense/Thêm khoản chi · Add income/Thêm khoản thu · Spent this month: {spent}/Tháng này đã chi {spent}
· Spent this month: {spent} / {budget}/Tháng này đã chi {spent} / {budget} · Locked with PIN/Đã khóa bằng PIN · Open the
app to update/Mở app để cập nhật. (Status line follows the app language.)

### EXT‑02 · Daily reminder notification · 🆕
Android channel "Reminder" ("A daily reminder to record your spending"), no vibration; iOS local notification. Title
"Ví Gọn", body "Have you recorded your spending today?" / "Hôm nay bạn đã ghi chi tiêu chưa?" — **never figures**. Tap →
(Lock) → New expense. Design: lock‑screen and shade appearance on both platforms; small icon (Android status‑bar icon
must be a monochrome silhouette of the logo).

### EXT‑03 · Recents / app switcher with hidden content · 🆕🤖🍏
With "Hide content when switching apps" on, Android shows a blank card in Recents and blocks screenshots. Show the
before/after card. (iOS: no equivalent yet → proposal §9.)

### EXT‑04 · OS sheets and pickers (placeholders only)
Share sheet (backup, CSV), file picker (restore), folder picker (auto backup, Android SAF), notification permission
prompt, time picker. Show as system chrome placeholders in flow frames — don't design them.

### EXT‑05 · App icon incl. Android monochrome (themed) icon · ✅ (D‑009, F‑23)
Final. Only show the themed‑icon rendering once on a launcher mock for consistency.

---

## 7. Key flows (prototype these)

- **F1 Log an expense:** (a) ring **Food** → `45000` → **Save** (2 taps). (b) **−** → amount → **Choose category** → tap
  **Food** = saved (3 taps). (c) ⋯ **More categories** → **Pets** → amount → Save. (d) Income: **+** → amount → Choose
  category → **Salary** = saved. Options: date, account, note, Repeat → Monthly.
- **F2 Log from outside the app:** widget **Expense** → (Lock → PIN) → New expense → amount → Choose category → saved
  → Home. Reminder notification → same.
- **F3 Edit / delete + undo:** Entries → expand Food → record → change → Save. Trash or swipe → "Deleted · Undo" → Undo.
- **F4 Search:** Entries → 🔍 → "rent" → results this month → **All time** → "12 records · total ₫42,000,000" → tap one →
  edit. No match state.
- **F5 Period & filter:** title → View by **Week** → swipe right; Custom range → calendar → Apply. Wallet → **Card** →
  Home/Entries filtered → All accounts.
- **F6 Budgets:** budget bar → 12,000,000 → Save. Settings → Categories → Food → Category monthly budget 3,000,000 →
  Save → Entries shows Food bar "Over by ₫240,000".
- **F7 Accounts:** Accounts → Old card → **Hide account** → section "Hidden accounts (1)" → Show again. Unused account
  → Delete account → confirm. Used account → hint only.
- **F8 Transfer:** Accounts → ⇄ → From Cash → To Card → amount → Save.
- **F9 Repeating:** New expense → Repeat Monthly → save. Settings → Repeating records → tap Rent → change Monthly →
  Weekly, Account → Card → Save; toggle off/on.
- **F10 Manual backup / restore / CSV:** Export backup → Protect with password → Export → share sheet. Restore → pick
  encrypted file → password (wrong → error; right) → confirm → Data restored. Export CSV.
- **F11 Automatic backup (Android):** switch → folder picker (Drive) → password ×2 → Turn on → Back up now → "Last: …".
  Revoke access → error status → Choose folder again. Switch off.
- **F12 Reminder:** switch → explain → Continue → OS prompt → Allow → 20:00; Deny → snackbar → Open settings. Change
  time.
- **F13 Privacy:** Show amounts on widget → widget shows "Spent this month"; turn PIN on → widget "Locked with PIN".
  Hide content when switching apps → Recents blank.
- **F14 PIN on/off/forgot**, **F15 Wipe data** — as v1 (SCR‑23…25, 29).

---

## 8. Sample data for mockups
Currency VND, EN base frames (VI for checks). Mock "today" = **2026‑11‑26**, period **November 2026**.

**Accounts:** Cash/Tiền mặt (start 2,000,000) · Bank card/Thẻ ngân hàng (15,000,000) · E‑wallet/Ví điện tử (500,000) ·
*hidden:* Old credit card/Thẻ tín dụng cũ (−1,200,000) · *long‑name test:* Family savings account/Tài khoản tiết kiệm
gia đình.

**November expense by category** (total **11,780,000 ₫**): Home 3,500,000 (29.7 %) · Food 3,240,000 (27.5 %) ·
Shopping 1,450,000 (12.3 %) · Bills 1,120,000 (9.5 %) · Transport 860,000 (7.3 %) · Family 600,000 (5.1 %) ·
Entertainment 540,000 (4.6 %) · Health 320,000 (2.7 %) · Other 150,000 (1.3 %) · Education 0 (icon only, "no records").
**Income:** Salary 18,000,000 + Bonus 1,500,000 = **19,500,000 ₫**. **Period balance** 7,720,000 ₫.
**Monthly budget** 12,000,000 → "Spent ₫11,780,000 of ₫12,000,000"; over‑budget frame: 10,000,000 → "Over by
₫1,780,000". **Category limits:** Food 3,000,000 → **Over by ₫240,000**; Shopping 2,000,000 → "Spent ₫1,450,000 of
₫2,000,000".
**Records:** Nov 26 "Beef pho"/"Phở bò" Food 45,000 · Nov 25 "Groceries"/"Đi chợ" Food 320,000 · Nov 1 "November
rent"/"Tiền nhà tháng 11" Home 3,500,000 (series) · Nov 20 "Electricity"/"Tiền điện" Bills 680,000 · Nov 18 "Ride to
work"/"Xe ôm đi làm" Transport 35,000 · Nov 5 Salary 18,000,000 (series) · Nov 10 Transfer Bank card → Cash 2,000,000.
**Search:** "rent" all time → 12 records · total ₫42,000,000.
**Series:** Rent 3,500,000 Monthly next Dec 1 (running) · Salary 18,000,000 Monthly next Dec 5 · Internet 250,000
Monthly (stopped) · Gym 120,000 Weekly next Nov 30.
**Automatic backup:** folder "Ví Gọn backups" (Google Drive) · Last: 25 Nov, 21:04 · error variant "Attempt 26 Nov,
08:12: Could not write to the folder. Choose the folder again".
**Reminder:** on, 20:00. **Widget:** "Spent this month: ₫11,780,000 / ₫12,000,000".
**Stress:** 25 expense categories (adds Coffee, Groceries, Fuel, Phone, Pets, Travel, Gym, Spa, Gifts, Charity, Repairs,
Kids, Water, Internet, Clothes); category name 50 chars "Chi phí sửa chữa xe máy và bảo dưỡng định kỳ hằng năm";
amount `1.000.000.000.000 ₫`; note 200 chars; USD `$1,250.00`; a 3‑decimal currency (KWD, e.g. `1,250.000`).

---

## 9. iOS: platform differences and proposals requested

### 9.1 Differences in v1 (implemented)
| Topic | iPhone | Android |
|---|---|---|
| Back | Visible back arrow + edge swipe; **every pushed screen and full‑screen dialog needs a visible back/close** | Arrow + system Back, predictive back |
| Exit | No exit control | Back on Home exits |
| Share / file pick | iOS share sheet, Files document picker | Sharesheet, SAF picker |
| PIN storage | Keychain (reinstall clears stale PIN, D‑017) | Keystore |
| Reminder | iOS notification permission prompt, exact time | Android 13+ prompt, approximate time |
| App bar title | Left‑aligned (override iOS centring) | Left‑aligned |
| **Android‑only (hidden on iOS, D‑019)** | — | Hide content when switching apps (F‑22), monochrome icon (F‑23), automatic backup (F‑24), widget (F‑26) |

### 9.2 Proposals requested (optional, separate frames, NOT in v1 scope)
Today these features are simply absent on iOS. Please propose — as clearly labelled **"iOS proposal"** frames, so the
user can decide whether to open a separate task — what the iOS version would look like:
1. **Widget (WidgetKit):** small (2×2) home‑screen widget with Expense / Income, the same privacy rule (no amounts
   unless allowed and PIN off), and optionally a lock‑screen accessory widget. Consider that iOS widgets open the app via
   a URL; buttons need iOS 17 interactive widgets.
2. **Automatic backup:** iOS has no persistent folder write like SAF. Options to explore: a folder chosen once via the
   Files picker (security‑scoped bookmark) written when the app goes to background; or a lighter "Back up reminder"
   that opens the share sheet. Show the Settings block and its states.
3. **Hide content in the app switcher:** a blur/brand cover shown when the app resigns active (no screenshot blocking on
   iOS). Show the switcher card.
4. **Tinted / dark app icon (iOS 18):** quick check of the logo in dark and tinted modes (icon assets only).

---

## 10. Known UX weak points → design opportunities · Out of scope

### 10.1 Weak points (solve within the current feature set; behaviour changes = mark as proposal)
Resolved since v1 brief (no action): ring overflow (now ⋯ slot, F‑17); "−" path now 3 taps (D‑018); category palette
reconciled with tokens (D‑010).
1. **Account filter invisible** — wallet icon looks the same filtered or not; name only in tooltip. Show the active
   account as a visible chip/label on Home and in the Entries header.
2. **"Balance" means two things** (period net vs account balance). Clarify on Home without new features.
3. **Settings is now ~25 rows** with long privacy subtitles. Improve scanning: group spacing, collapsible explanations,
   status chips (e.g. auto‑backup OK/error at a glance), consistent switch rows. No new screens unless you argue a
   sub‑page (e.g. "Backup & data") is clearer — mark as proposal.
4. **First day of week toggles on tap** without affordance → 2‑option segmented control or menu.
5. **Edit repeating record** is now a 5‑field dialog (SCR‑21) → sheet/page, show next due date after a frequency change.
6. **Category budget visibility:** limits appear only in Entries rows. Consider a subtle marker on the ring icon or in
   Categories (no new behaviour) — proposal.
7. **⋯ slot appears only at ≈ 17+ categories**; make it recognisable as "more", not a category.
8. **Search:** decide empty‑query state, match highlighting, and how "All time" relates to the period chip.
9. **Password dialogs** (export, restore, auto backup) should look like one family; show strength/visibility toggle only
   if within copy (NEW copy allowed); always show the forget warning.
10. **Auto‑backup status** must read as healthy/unhealthy at a glance (icon + text, not colour only).
11. **Widget‑amount switch with PIN on** still toggles but has no effect — show that state explicitly.
12. **Entries amount alignment** — child amounts align further right than category totals; align to one column.
13. **Delete relies on a 5‑s snackbar** — prominent, 200 %‑safe, clear of the − / + buttons.
14. **Max amount error is generic** ("Invalid calculation" > 10¹²) — optional NEW specific message.
15. **Currency list (~156)** under a long note — full‑height sheet, search first, current pinned.
16. **Empty Home** — friendlier, point to − / ring icons.
17. Known v1 limits **not** to design controls for: PIN attempt limit, hiding an account doesn't stop its series.

### 10.2 Out of scope / Future (don't draw in main frames)
- Cloud sync / two‑way sync via Drive or Dropbox APIs, sign‑in, servers.
- Multiple currencies at once, exchange rates.
- Biometric unlock; PIN attempt limit/back‑off.
- Widget showing amounts while PIN is on.
- iOS widget / auto backup / app‑switcher cover (only as §9.2 proposals).
- Onboarding/tutorial, trend charts, reports, notes attachments, receipt scanning, bank SMS, AI.
- Ads, in‑app purchases, Pro tier, analytics, crash SDKs. Tablet / landscape.

---

## 11. Deliverables requested from Claude Design

### 11.1 Priority
1. **P1 — 🆕 never drawn:** SCR‑01 ⋯ slot, SCR‑07 (from ⋯), SCR‑10 category‑budget bars, SCR‑11 search, SCR‑12 new
   rows/groups, SCR‑13 search, SCR‑16 budget field, SCR‑17 hidden section, SCR‑18 Hide/Delete, SCR‑21 extended edit,
   SCR‑26, SCR‑27 password, SCR‑30, SCR‑31, SCR‑33, EXT‑01, EXT‑02, EXT‑03.
2. **P2 — refresh** every ✅ frame for consistency with P1 (and D‑018 annotation on 3.3).
3. **P3 — iOS proposals** §9.2 (separate page).

### 11.2 Frames
For **each platform** (Android 360 × 800 dp; iPhone 393 × 852 pt) × **light + dark**: every SCR with the states listed.
EXT frames: Android only (EXT‑01, 03, 05) or both (EXT‑02), on light and dark wallpapers.
- **VI variants** (light): SCR‑01, 05, 10, 11, 12 (all three parts), 13, 18, 21, 23, 25, 26, 30, 31, EXT‑01.
- **200 % text** (one platform, light): SCR‑01, 05, 10, 11, 12, 18, 21, 23, 26, 31.
- **Stress:** SCR‑01 with 25 categories; SCR‑01/05 with `1.000.000.000.000 ₫`; SCR‑10 with long notes and over‑limit
  categories.
- Prototype links for flows F1–F15 (§7).

### 11.3 File naming (1:1 with routes)
`design/hifi/<platform>/<theme>/<NN>_<slug>__<state>.png` + matching HTML export. `<platform>` = `android|ios`,
`<theme>` = `light|dark`, `<NN>` = SCR/EXT number, `<state>` e.g. `default|empty|error|over-budget|filtered|searching|
no-match|locked|hidden|running|long-text|large-number|many-categories|text-200|vi|ios-proposal`. Overlays:
`<route-slug>~<overlay>`.

| No. | Route / owner | Slug |
|---|---|---|
| 01 | `/` | `home` (`__more-categories`) |
| 02 | `/` sheet | `home~view-by`, `home~custom-range` |
| 03 | `/` menu | `home~account-filter` |
| 04 | `/` · `/settings` | `home~budget` |
| 05 | `/entry/new` | `entry-new` (`__income`, `__from-widget`) |
| 06 | `/entry/:id` | `entry-id` |
| 07 | sheet | `entry-new~category`, `home~more-categories` |
| 08 | sheets | `entry-new~repeat`, `entry-new~account` |
| 09 | picker | `entry-new~date` |
| 10 | `/entries` | `entries` (`__category-budget`) |
| 11 | `/entries` search | `entries~search` |
| 12 | `/settings` | `settings` (`__top`, `__middle`, `__bottom`) |
| 13 | `/settings` | `settings~currency` |
| 14 | `/settings` | `settings~month-start` |
| 15 | `/categories` | `categories` |
| 16 | `/categories` | `categories~edit`, `categories~delete` |
| 17 | `/accounts` | `accounts` (`__hidden-open`) |
| 18 | `/accounts` | `accounts~edit`, `accounts~delete` |
| 19 | `/transfer`, `/transfer/:id` | `transfer`, `transfer-id` |
| 20 | `/recurring` | `recurring` |
| 21 | `/recurring` | `recurring~edit` |
| 22 | `/about` | `about` |
| 23 | overlay | `lock` |
| 24 | from `/settings` | `settings~pin-setup`, `settings~pin-check` |
| 25 | overlay | `lock~forgot-1`, `lock~forgot-2`, `lock~forgot-3` |
| 26 | `/settings` | `settings~backup-export` |
| 27 | `/settings` | `settings~restore`, `settings~restore-password` |
| 28 | `/settings` | `settings~csv` |
| 29 | `/settings` | `settings~delete-all-1`, `settings~delete-all-2` |
| 30 | `/settings` | `settings~reminder` |
| 31 | `/settings` | `settings~auto-backup`, `settings~auto-backup-password` |
| 32 | shared | `shared~dialog`, `shared~snackbar`, `shared~progress` |
| 33 | `/settings` iOS | `settings__ios` |
| EXT‑01 | launcher | `ext-widget` |
| EXT‑02 | notification | `ext-reminder` |
| EXT‑03 | recents | `ext-recents` |
| EXT‑05 | launcher | `ext-icon` |

### 11.4 Design system page
- **Tokens** as JSON in the **same schema as `design/current/screens/tokens.json`** + CSS variables; keep names; a
  changelog of added/removed/changed tokens. They must map to Flutter `ColorScheme` (primary, onPrimary,
  primaryContainer, onPrimaryContainer, secondaryContainer, onSecondaryContainer, surface, surfaceContainer,
  surfaceContainerHigh, onSurface=`ink`, onSurfaceVariant=`ink-muted`, outline, outlineVariant, error, onError,
  inverseSurface, onInverseSurface=`inverse-ink`, inversePrimary, scrim), `ThemeExtension ViGonColors` (income,
  on‑income, expense, on‑expense, swipe‑delete, focus, cat‑01…16), `TextTheme` (12 styles, tabular amounts) and
  spacing/radius/tap constants (`VgSpace`, `VgRadius`, `VgTap`). Add **widget tokens** (EXT‑01 colours, radius, type)
  if you change them.
- **Component sheet** (states: default, pressed, focused, disabled, error, selected; light + dark): main action buttons,
  keypad, amount display, chips, category avatar 40/48 + ⋯ slot, ring + icons, budget bar (total and **category**),
  balance bar, period header, list rows (category expandable, record, swipe‑delete), **search field + chip**, section
  headers, segmented control, switch row with long subtitle, nav row, **status row (auto backup)**, button pair (tonal +
  outlined), FAB, bottom sheet, dialog (normal / destructive / **form with password fields**), snackbar (with action, 10 s
  variant), progress, PIN pad + dots, text fields (name, amount with currency, note with counter, password), range
  calendar, menu, **widget**, **notification**.
- **Motion notes** (150–250 ms, reduce‑motion aware): period change, keypad press, "category tapped → saved → Home",
  sheet open/close, snackbar, PIN error shake, auto‑backup running → done.
- **Icon list:** final glyph per category key (§2.2) and every action icon.

### 11.5 Format
claude.ai link + HTML/PNG export per frame, saved into `apps/A002-vigon/design/hifi/` with §11.3 names.

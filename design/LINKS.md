# Ví Gọn — Hi-Fi mockups (full app, v4 direction): links and exports

Updated 2026-11-10 (widget redrawn). Links are private until shared from each page's Share menu.

| What | claude.ai link | Local copy (this folder) |
|---|---|---|
| Hi-Fi mockups (Design canvas): 227 new artboards on 5 "Full app" pages; the P1 artboards of Nov 5 are kept on 5 "P1 archive" pages | https://claude.ai/artifact/CRNZuMEvnDTMwX56s1fts6 | `hifi/claude-design-canvas/` |
| Design System (tokens v3, new patterns, redrawn HomeWidget) | https://claude.ai/artifact/EhNKP8PgiDPNqtmMdzTtVR | `hifi/tokens/`, `hifi/design-system/` |
| Frame gallery (all 227 frames, filters, notes) | https://claude.ai/artifact/9n75stZTivVHgWwgLfPJhF | `hifi/index.html` |

## HTML / PNG export

- `hifi/<android|ios>/<light|dark>/<NN>_<slug>__<state>.png` + `.html`: 227 frames. Each HTML is standalone (CSS inline, fonts from `hifi/_shared/`) and shows the notes, ASSUMPTION pins and NEW copy next to the screen.
- Screens: Home, Onboarding, New/Edit record, Records, Settings (9 groups), Main currency, Exchange rates, Accounts, Add account, Transfer, Savings wallets, Debts, Due reminders, Due notification, Import queue, Email import, Lock, Home-screen widget (redrawn).
- Widget (EXT-01), every state on one sheet: `hifi/android/light/EXT01_ext-widget__all-states.png` + `.html`. The same sheet is an artboard on the canvas ("Full app · Android · Light" and "P1 archive · Android · Light" pages).
- `hifi/index.html` gallery · `hifi/assumptions.html` (C00–C10) · `hifi/tokens/` (tokens v3, CHANGELOG-v3.md, motion, icons).
- `vigon-hifi-full-app.zip`: the whole new `hifi/` folder.
- `hifi/_archive/2026-11-05-p1/`: the P1 round (231 frames) and its old LINKS file; `hifi/_archive/vigon-hifi-P1.zip`.

## Sources

product.md v4 was not reachable from this session, so this round is built from `design/current/ui-spec.md` (2026-11-10), `lib/l10n/app_en.arb` + `app_vi.arb` (2026-11-10), brief v3 and the four themes named in chat (main currency first, savings wallets, reminders before due dates, remaining screens). See assumption C00.

The old P1 widget (solid red / green blocks) has been removed everywhere, including `hifi/_archive/` and both archive zips; every widget frame now uses the redrawn style. Token change: `radius-widget` 20 → 24.

`design/current/` is unchanged.

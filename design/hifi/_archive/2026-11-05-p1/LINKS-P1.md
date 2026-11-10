# Ví Gọn — Hi-Fi P1: links and exports

Updated 2026-11-05. Links are private until shared from each page's Share menu.

| What | claude.ai link | Local copy (this folder) |
|---|---|---|
| Hi-Fi mockups (Design canvas: 231 artboards, 5 pages: Android Light, Android Dark, iPhone Light, iPhone Dark, VI + 200 %) | https://claude.ai/artifact/CRNZuMEvnDTMwX56s1fts6 | `hifi/claude-design-canvas/*.dc.html` (artboard source) |
| Design System v2 (tokens, changelog, components light + dark, motion, icons, assumptions, ideas) | https://claude.ai/artifact/EhNKP8PgiDPNqtmMdzTtVR | `hifi/tokens/`, `hifi/design-system/` |
| Frame gallery (all frames with notes, filters) | https://claude.ai/artifact/9n75stZTivVHgWwgLfPJhF | `hifi/index.html` |

## HTML / PNG export

- `hifi/<android|ios>/<light|dark>/<NN>_<slug>__<state>.png` + `.html` — 231 frames, named per product.md §11.3. Each HTML is standalone (CSS inline, fonts from `hifi/_shared/`).
- `hifi/index.html` gallery · `hifi/assumptions.html` · `hifi/ideas.html`
- `hifi/tokens/` — tokens.json + tokens.css (v2, same schema as v1), CHANGELOG.md (incl. P2 impact list), motion.md, icons.md
- `vigon-hifi-P1.zip` — the whole `hifi/` folder (before the canvas source was added)

`design/current/` is unchanged.

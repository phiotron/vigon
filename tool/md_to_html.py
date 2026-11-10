#!/usr/bin/env python3
"""Build static HTML legal pages from the Markdown sources (no dependencies).

Supports the small Markdown subset used in store/legal/*.md:
  # / ## headings, paragraphs, "- " bullet lists, "1. " numbered lists
  (continuation lines indented), **bold**, `code`, [text](url).

Usage:  python tool/md_to_html.py
Writes store/legal/<name>.<lang>.html next to every store/legal/<name>.<lang>.md
and store/legal/index.html. Pages are self-contained (inline CSS, light/dark),
ready to copy to the public legal repo. Re-run after editing the .md files;
never edit the .html by hand.
"""
import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
LEGAL = ROOT / "store" / "legal"
APP_NAME = {"vi": "Ví Gọn", "en": "Vigon"}
OTHER_LANG = {"en": ("vi", "Tiếng Việt"), "vi": ("en", "English")}
DOC_LABEL = {
    "privacy-policy": {"vi": "Chính sách quyền riêng tư", "en": "Privacy Policy"},
    "terms-of-use": {"vi": "Điều khoản sử dụng", "en": "Terms of Use"},
    "support": {"vi": "Hỗ trợ", "en": "Support"},
}

CSS = """
:root{--bg:#ffffff;--fg:#1d2330;--muted:#5b6474;--accent:#0f766e;--line:#e3e7ee}
@media (prefers-color-scheme:dark){:root{--bg:#11151c;--fg:#e8ecf2;--muted:#9aa4b4;--accent:#5eead4;--line:#2a313d}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.6 -apple-system,"Segoe UI",Roboto,Arial,sans-serif}
main{max-width:720px;margin:0 auto;padding:32px 16px 64px}
h1{font-size:1.6rem;line-height:1.25;margin:0 0 16px}
h2{font-size:1.2rem;margin:32px 0 8px;padding-top:16px;border-top:1px solid var(--line)}
a{color:var(--accent)}
code{font-family:ui-monospace,Consolas,monospace;font-size:.9em}
ul,ol{padding-left:1.4em}
li{margin:4px 0}
nav{font-size:.9rem;color:var(--muted);margin-bottom:24px}
footer{margin-top:48px;font-size:.85rem;color:var(--muted)}
"""


def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    text = re.sub(r"\[(.+?)\]\((.+?)\)", r'<a href="\2">\1</a>', text)
    return text


def convert(md):
    out, para, items, kind = [], [], [], None
    title = ""

    def flush_para():
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
            para.clear()

    def flush_list():
        nonlocal kind
        if items:
            out.append(f"<{kind}>" + "".join(f"<li>{inline(i)}</li>" for i in items) + f"</{kind}>")
            items.clear()
        kind = None

    for raw in md.split("\n"):
        line = raw.rstrip()
        bullet = re.match(r"^- (.*)", line)
        number = re.match(r"^\d+\. (.*)", line)
        if line.startswith("# "):
            flush_para(); flush_list()
            title = line[2:].strip()
            out.append(f"<h1>{inline(title)}</h1>")
        elif line.startswith("## "):
            flush_para(); flush_list()
            out.append(f"<h2>{inline(line[3:].strip())}</h2>")
        elif bullet or number:
            flush_para()
            new_kind = "ul" if bullet else "ol"
            if kind and kind != new_kind:
                flush_list()
            kind = new_kind
            items.append((bullet or number).group(1))
        elif line.startswith("  ") and items and line.strip():
            items[-1] += " " + line.strip()
        elif not line.strip():
            # A blank line between list items is a "loose" list: keep the list
            # open so consecutive numbered items stay in one <ol>.
            flush_para()
        else:
            flush_list()
            para.append(line.strip())
    flush_para(); flush_list()
    return title, "\n".join(out)


def nav(lang, stem, docs):
    other_lang, other_label = OTHER_LANG[lang]
    links = [f'<a href="{stem}.{other_lang}.html">{other_label}</a>']
    for other_stem in docs:
        if other_stem != stem:
            links.append(f'<a href="{other_stem}.{lang}.html">{DOC_LABEL[other_stem][lang]}</a>')
    return '<nav>' + ' · '.join(links) + '</nav>'


def page(lang, title, body, nav_html):
    return f"""<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>{CSS}</style>
</head>
<body>
<main>
{nav_html}
{body}
<footer>{APP_NAME[lang]}</footer>
</main>
</body>
</html>
"""


def main():
    paths = sorted(LEGAL.glob("*.*.md"))
    docs = sorted({p.stem.rsplit(".", 1)[0] for p in paths})
    links = []
    for md_path in paths:
        stem, lang = md_path.stem.rsplit(".", 1)
        title, body = convert(md_path.read_text(encoding="utf-8"))
        out = md_path.with_suffix(".html")
        out.write_text(page(lang, title, body, nav(lang, stem, docs)), encoding="utf-8", newline="\n")
        links.append((title, lang, out.name))
        print("wrote", out.relative_to(ROOT))
    groups = {}
    for title, lang, name in links:
        groups.setdefault(lang, []).append((title, name))
    sections = []
    for lang in sorted(groups, reverse=True):
        items = "".join(f'<li><a href="{n}">{html.escape(t)}</a></li>' for t, n in groups[lang])
        sections.append(f"<h2>{APP_NAME[lang]}</h2><ul>{items}</ul>")
    index = page("vi", f"{APP_NAME['vi']} — Pháp lý & hỗ trợ", "\n".join(sections), "")
    (LEGAL / "index.html").write_text(index, encoding="utf-8", newline="\n")
    print("wrote", (LEGAL / "index.html").relative_to(ROOT))


if __name__ == "__main__":
    main()

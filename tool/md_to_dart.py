#!/usr/bin/env python3
"""Generate lib/src/features/settings/legal_texts.dart from store/legal/*.md.

The app shows a bundled copy of the privacy policy and terms while there is no
public URL, and offline. The Markdown in store/legal is the single source;
re-run this after editing those files:

    python tool/md_to_dart.py
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
LEGAL = ROOT / "store" / "legal"
OUT = ROOT / "lib" / "src" / "features" / "settings" / "legal_texts.dart"

DOCS = [
    ("privacy", "privacy-policy", "privacy"),
    ("terms", "terms-of-use", "terms"),
]
LANGS = ["vi", "en"]


def main():
    parts = [
        "// GENERATED from store/legal/*.md — do not edit by hand.",
        "// Regenerate after changing the store texts: python tool/md_to_dart.py",
        "",
        "/// In-app copies of the privacy policy and terms (offline fallback and",
        "/// while a public URL is unreachable).",
        "abstract final class LegalTexts {",
    ]
    for field, stem, _ in DOCS:
        for lang in LANGS:
            path = LEGAL / f"{stem}.{lang}.md"
            text = path.read_text(encoding="utf-8").replace("\r\n", "\n").strip()
            if "'''" in text:
                raise SystemExit(f"{path} contains a triple quote")
            cap = lang.capitalize()
            parts.append(f"  /// store/legal/{path.name}")
            parts.append(f"  static const String {field}{cap} = r'''")
            parts.append(text)
            parts.append("''';")
            parts.append("")
    parts[-1] = "}"
    parts.append("")
    OUT.write_text("\n".join(parts), encoding="utf-8", newline="\n")
    print("wrote", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()

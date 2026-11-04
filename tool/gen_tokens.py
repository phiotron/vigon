"""Sinh lib/src/ui/tokens.g.dart từ design-mobile/screens/tokens.json (D-010).

Chạy tại thư mục app mỗi khi token đổi:
    python tool/gen_tokens.py
Không sửa tay file sinh ra; sửa tokens.json (xuất lại từ design system "Ví Gọn") rồi chạy lại.
"""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

APP = Path(__file__).resolve().parent.parent
SRC = APP / "design-mobile" / "screens" / "tokens.json"
OUT = APP / "lib" / "src" / "ui" / "tokens.g.dart"

# Màu chỉ dùng cho bảng trình bày, không vào app.
SKIP_COLORS = {"canvas"}


def camel(name: str) -> str:
    head, *rest = name.split("-")
    return head + "".join(p[:1].upper() + p[1:] for p in rest)


def px(value: str) -> str:
    n = float(value.removesuffix("px"))
    return str(int(n)) if n.is_integer() else str(n)


def color(value: str) -> str:
    """'#RRGGBB' hoặc 'rgba(r, g, b, a)' thành 'Color(0xAARRGGBB)'."""
    if value.startswith("#") and len(value) == 7:
        return f"Color(0xFF{value[1:].upper()})"
    m = re.fullmatch(r"rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)", value)
    if not m:
        raise SystemExit(f"Không đọc được màu: {value}")
    r, g, b = (int(x) for x in m.groups()[:3])
    a = round(float(m.group(4)) * 255)
    return f"Color(0x{a:02X}{r:02X}{g:02X}{b:02X})"


def shadow(value: str) -> str:
    """'0 -2px 12px rgba(...)' thành một BoxShadow."""
    m = re.fullmatch(r"(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+([\d.]+)(?:px)?\s+(rgba\(.+\))", value)
    if not m:
        raise SystemExit(f"Không đọc được bóng: {value}")
    x, y, blur, c = m.groups()
    return f"BoxShadow(color: {color(c)}, offset: Offset({px(x)}, {px(y)}), blurRadius: {px(blur)})"


def main() -> None:
    data = json.loads(SRC.read_text(encoding="utf-8"))
    themes = [t["id"] for t in data["color"]["themes"]]
    if themes != ["light", "dark"]:
        raise SystemExit(f"Chờ hai chủ đề light, dark; gặp {themes}")

    colors = [t for t in data["color"]["tokens"] if t["name"] not in SKIP_COLORS]
    cats = [t for t in colors if re.fullmatch(r"cat-\d\d", t["name"])]
    named = [t for t in colors if t not in cats]
    for t in cats:
        if t["value"]["light"] != t["value"]["dark"]:
            raise SystemExit(f"{t['name']} khác nhau giữa hai chủ đề; generator chờ màu danh mục chung")
    shadows = data["shadow"]["tokens"]

    fields = [camel(t["name"]) for t in named] + [camel(t["name"]) for t in shadows]

    out = [
        "// SINH TỰ ĐỘNG bởi tool/gen_tokens.py từ design-mobile/screens/tokens.json.",
        "// Không sửa tay: sửa tokens.json rồi chạy `python tool/gen_tokens.py` (D-010).",
        "// ignore_for_file: public_member_api_docs",
        "",
        "import 'package:flutter/painting.dart';",
        "",
        "/// Màu và bóng của một chủ đề (sáng hoặc tối) theo token thiết kế.",
        "class VgPalette {",
        "  const VgPalette({",
        *[f"    required this.{f}," for f in fields],
        "  });",
        "",
        *[f"  final Color {camel(t['name'])};" for t in named],
        *[f"  final List<BoxShadow> {camel(t['name'])};" for t in shadows],
        "",
        "  /// Chuyển dần giữa hai chủ đề khi đổi sáng/tối.",
        "  static VgPalette lerp(VgPalette a, VgPalette b, double t) => VgPalette(",
        *[f"    {camel(x['name'])}: Color.lerp(a.{camel(x['name'])}, b.{camel(x['name'])}, t)!," for x in named],
        *[f"    {camel(x['name'])}: BoxShadow.lerpList(a.{camel(x['name'])}, b.{camel(x['name'])}, t)!," for x in shadows],
        "  );",
        "}",
        "",
    ]
    for theme in themes:
        out += [f"const vg{theme.capitalize()} = VgPalette("]
        out += [f"  {camel(t['name'])}: {color(t['value'][theme])}," for t in named]
        out += [f"  {camel(t['name'])}: [{shadow(t['value'][theme])}]," for t in shadows]
        out += [");", ""]

    out += [
        "/// 16 màu danh mục cat-01 … cat-16, giống nhau ở hai chủ đề; icon trên đó dùng `onCat`.",
        "const vgCategoryColors = <Color>[",
        *[f"  {color(t['value']['light'])}, // {t['name']}" for t in cats],
        "];",
        "",
    ]

    def consts(cls: str, doc: str, tokens: list, prefix: str) -> list:
        lines = [f"/// {doc}", f"abstract final class {cls} {{"]
        for t in tokens:
            name = camel(t["name"].removeprefix(prefix))
            if name[0].isdigit():  # space-4 → s4
                name = "s" + name
            lines.append(f"  static const double {name} = {px(t['value'])};")
        return lines + ["}", ""]

    out += consts("VgSpace", "Khoảng cách (space-*).", data["spacing"]["tokens"], "space-")
    out += consts("VgRadius", "Bo góc (radius-*).", data["radius"]["tokens"], "radius-")
    out += consts("VgSize", "Vùng chạm tối thiểu và chiều cao thanh tiêu đề, dp/pt.", data["size"]["tokens"], "")

    out += [
        "/// 12 kiểu chữ; họ chữ lấy từ theme (Be Vietnam Pro). Số tiền dùng số đều độ rộng.",
        "abstract final class VgType {",
    ]
    for group in data["type"]["groups"]:
        for s in group["styles"]:
            size, line = float(s["fontSize"].removesuffix("px")), float(s["lineHeight"].removesuffix("px"))
            features = ", fontFeatures: [FontFeature.tabularFigures()]" if s["name"].startswith("amount-") else ""
            out.append(
                f"  static const {camel(s['name'])} = TextStyle(fontSize: {px(s['fontSize'])}, "
                f"height: {round(line / size, 4)}, fontWeight: FontWeight.w{s['fontWeight']}{features});"
            )
    out += ["}", ""]

    OUT.write_text("\n".join(out), encoding="utf-8", newline="\n")
    # Định dạng như `dart format lib test` để chạy lại không sinh khác biệt.
    dart = shutil.which("dart")
    if dart:
        subprocess.run([dart, "format", str(OUT)], check=True, capture_output=True)
    else:
        print("CHÚ Ý: không thấy dart trong PATH, chạy `dart format lib` sau đó")
    print(f"Đã ghi {OUT.relative_to(APP)}: {len(named)} màu, {len(cats)} màu danh mục, {len(shadows)} bóng")


if __name__ == "__main__":
    main()

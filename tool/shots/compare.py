"""Ghép ảnh app (tool/shots/out/) cạnh mockup Hi-Fi cùng tên để so bằng mắt.

    python tool/shots/compare.py [lọc-tên ...] [--theme light|dark] [--h 900]

Ra tool/shots/out/compare/<theme>/<frame>.png: trái = app, phải = điện thoại
trong PNG mockup (design/hifi/android/<theme>/<frame>.png, chỉ có ở máy; phần
chú thích bên phải bị cắt). Ảnh được thu về cao --h px để mở nhanh, tốn ít token.
"""
import sys
from pathlib import Path

from PIL import Image

APP = Path(__file__).resolve().parents[2]
OUT = APP / 'tool/shots/out'
HIFI = APP / 'design/hifi/android'


def phone_box(im):
    """Khung điện thoại trong PNG mockup (cột bên trái), dò theo màu nền trang."""
    w, h = im.size
    px = im.load()
    bg = px[4, 4]

    def differs(x, y):
        return sum(abs(a - b) for a, b in zip(px[x, y], bg)) > 40

    x0 = 400
    ys = [y for y in range(0, h, 2) if differs(x0, y)]
    top, bottom = (ys[0], ys[-1]) if ys else (0, h)
    mid = (top + bottom) // 2
    xs = [x for x in range(0, min(w, 900)) if differs(x, mid)]
    left = xs[0] if xs else 40
    # Bên phải là chú thích (chữ có thể chạm cột dò) → lấy đúng bề rộng máy
    # 360 dp × 2 + viền.
    return (left, top, min(w, left + 728), bottom + 1)


def main():
    args = sys.argv[1:]
    theme = 'light'
    height = 900
    filters = []
    i = 0
    while i < len(args):
        if args[i] == '--theme':
            theme = args[i + 1]
            i += 2
        elif args[i] == '--h':
            height = int(args[i + 1])
            i += 2
        else:
            filters.append(args[i])
            i += 1
    dest = OUT / 'compare' / theme
    dest.mkdir(parents=True, exist_ok=True)
    made = 0
    for shot in sorted((OUT / 'android' / theme).glob('*.png')):
        name = shot.stem
        if filters and not any(f in name for f in filters):
            continue
        app = Image.open(shot).convert('RGB')
        ref_path = HIFI / theme / f'{name}.png'
        panels = [app]
        if ref_path.exists():
            ref = Image.open(ref_path).convert('RGB')
            panels.append(ref.crop(phone_box(ref)))
        scaled = []
        for p in panels:
            r = height / p.height
            scaled.append(p.resize((round(p.width * r), height), Image.LANCZOS))
        total = sum(p.width for p in scaled) + 12 * (len(scaled) - 1)
        canvas = Image.new('RGB', (total, height), (255, 0, 255))
        x = 0
        for p in scaled:
            canvas.paste(p, (x, 0))
            x += p.width + 12
        canvas.save(dest / f'{name}.png')
        made += 1
    print(f'{made} ảnh ghép → {dest}')


if __name__ == '__main__':
    main()

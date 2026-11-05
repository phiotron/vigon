"""Vẽ icon app iOS từ hình logo D-009 (chỉ dùng thư viện chuẩn của Python).

Hình lấy đúng từ vector Android `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
(không gian thiết kế 512×512, nhóm ngoài dịch (-8, 4)), nền `#0E5244`. Mỗi cỡ được vẽ
thẳng từ hình (khử răng cưa bằng hàm khoảng cách), không phóng to ảnh có sẵn.
PNG vuông, không trong suốt, không bo góc (iOS tự bo).

Chạy: python tool/render_ios_icon.py            → ghi vào ios/Runner/Assets.xcassets/AppIcon.appiconset
      python tool/render_ios_icon.py --check    → vẽ cỡ 512 và so với docs/store/brand/icon-512.png
Sửa hình thì sửa cả vector Android, canvas Design và file này (D-009).
"""

import json
import math
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
REFERENCE = ROOT / 'docs/store/brand/icon-512.png'

BACKGROUND = (0x0E, 0x52, 0x44)
OUTER_TRANSLATE = (-8.0, 4.0)

# (hình, màu, độ đục, góc quay độ, tâm quay) theo đúng thứ tự vẽ của vector Android.
# Hình chữ nhật bo góc: ('rect', trái, trên, phải, dưới, bán kính); hình tròn: ('circle', x, y, r).
SHAPES = [
    (('rect', 126, 150, 366, 306, 36), (0x8C, 0xD5, 0xBF), 1.0, -14, (246, 228)),
    (('rect', 150, 210, 402, 374, 40), (0xF7, 0xFA, 0xF8), 1.0, 8, (276, 292)),
    (('rect', 186, 262, 290, 282, 10), (0x0E, 0x52, 0x44), 1.0, 8, (276, 292)),
    (('rect', 186, 302, 250, 322, 10), (0x0E, 0x52, 0x44), 0.35, 8, (276, 292)),
    (('circle', 366, 292, 24), (0xE6, 0x51, 0x00), 1.0, 8, (276, 292)),
]


def _sdf(shape, x, y):
    """Khoảng cách có dấu (âm là bên trong) trong không gian thiết kế."""
    if shape[0] == 'circle':
        _, cx, cy, r = shape
        return math.hypot(x - cx, y - cy) - r
    _, left, top, right, bottom, r = shape
    cx, cy = (left + right) / 2, (top + bottom) / 2
    hx, hy = (right - left) / 2 - r, (bottom - top) / 2 - r
    qx, qy = abs(x - cx) - hx, abs(y - cy) - hy
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    return outside + min(max(qx, qy), 0.0) - r


def _bounds(shape, angle, pivot):
    """Khung bao (không gian thiết kế, đã quay và dịch) để chỉ tính điểm ảnh gần hình."""
    if shape[0] == 'circle':
        _, cx, cy, r = shape
        corners = [(cx - r, cy - r), (cx + r, cy - r), (cx - r, cy + r), (cx + r, cy + r)]
    else:
        _, left, top, right, bottom, _ = shape
        corners = [(left, top), (right, top), (left, bottom), (right, bottom)]
    a = math.radians(angle)
    pts = []
    for x, y in corners:
        dx, dy = x - pivot[0], y - pivot[1]
        pts.append((
            pivot[0] + dx * math.cos(a) - dy * math.sin(a) + OUTER_TRANSLATE[0],
            pivot[1] + dx * math.sin(a) + dy * math.cos(a) + OUTER_TRANSLATE[1],
        ))
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def render(size):
    """Trả về danh sách hàng, mỗi hàng là bytearray RGB dài size*3."""
    scale = size / 512
    pixels = [[list(BACKGROUND) for _ in range(size)] for _ in range(size)]
    for shape, color, opacity, angle, pivot in SHAPES:
        a = math.radians(-angle)
        cos_a, sin_a = math.cos(a), math.sin(a)
        x0, y0, x1, y1 = _bounds(shape, angle, pivot)
        px0, py0 = max(0, int(x0 * scale) - 2), max(0, int(y0 * scale) - 2)
        px1, py1 = min(size, int(x1 * scale) + 3), min(size, int(y1 * scale) + 3)
        for py in range(py0, py1):
            row = pixels[py]
            for px in range(px0, px1):
                # Tâm điểm ảnh → không gian thiết kế → bỏ dịch ngoài → quay ngược quanh tâm.
                x = (px + 0.5) / scale - OUTER_TRANSLATE[0] - pivot[0]
                y = (py + 0.5) / scale - OUTER_TRANSLATE[1] - pivot[1]
                lx = pivot[0] + x * cos_a - y * sin_a
                ly = pivot[1] + x * sin_a + y * cos_a
                coverage = min(max(0.5 - _sdf(shape, lx, ly) * scale, 0.0), 1.0)
                if coverage <= 0:
                    continue
                alpha = coverage * opacity
                p = row[px]
                for c in range(3):
                    p[c] = p[c] * (1 - alpha) + color[c] * alpha
    return [bytearray(min(255, max(0, round(v))) for p in row for v in p) for row in pixels]


def write_png(path, rows):
    size = len(rows)
    raw = b''.join(b'\x00' + bytes(r) for r in rows)

    def chunk(kind, data):
        return (struct.pack('>I', len(data)) + kind + data
                + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF))

    # Kiểu màu 2 = RGB 8 bit, không kênh alpha (App Store từ chối icon 1024 trong suốt).
    png = (b'\x89PNG\r\n\x1a\n'
           + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(raw, 9))
           + chunk(b'IEND', b''))
    path.write_bytes(png)


def read_png_rgb(path):
    """Đọc PNG RGB 8 bit không xen kẽ (đủ cho icon-512.png)."""
    data = path.read_bytes()
    i, idat, width, height = 8, b'', 0, 0
    while i < len(data):
        n = struct.unpack('>I', data[i:i + 4])[0]
        kind, body = data[i + 4:i + 8], data[i + 8:i + 8 + n]
        if kind == b'IHDR':
            width, height, depth, ctype, _, _, interlace = struct.unpack('>IIBBBBB', body)
            assert depth == 8 and ctype in (2, 6) and interlace == 0, 'PNG không hỗ trợ'
            bpp = 3 if ctype == 2 else 4
        elif kind == b'IDAT':
            idat += body
        i += 12 + n
    raw = zlib.decompress(idat)
    stride = width * bpp
    rows, prev = [], bytearray(stride)
    for y in range(height):
        f = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + b) & 255
            elif f == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pred) & 255
        rows.append(bytes(line[x] for x in range(stride) if x % bpp < 3))
        prev = line
    return rows


def check():
    ours, ref = render(512), read_png_rgb(REFERENCE)
    total = sum(abs(a - b) for r1, r2 in zip(ours, ref) for a, b in zip(r1, r2))
    off = sum(1 for r1, r2 in zip(ours, ref) for x in range(0, len(r1), 3)
              if max(abs(r1[x + c] - r2[x + c]) for c in range(3)) > 32)
    print(f'chênh trung bình {total / (512 * 512 * 3):.3f}/255, '
          f'điểm ảnh lệch > 32: {off} ({off / 512 / 512:.4%})')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    if '--check' in sys.argv:
        check()
        return
    contents = json.loads((ICONSET / 'Contents.json').read_text(encoding='utf-8'))
    done = {}
    for image in contents['images']:
        points = float(image['size'].split('x')[0])
        px = round(points * int(image['scale'].rstrip('x')))
        name = image['filename']
        if name in done:
            assert done[name] == px, name
            continue
        write_png(ICONSET / name, render(px))
        done[name] = px
        print(f'{name}: {px}×{px}')


if __name__ == '__main__':
    main()

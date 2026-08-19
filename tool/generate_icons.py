#!/usr/bin/env python3
"""Иконка и сплэш «Волны» из токенов дизайн-системы.

Временные ассеты — до финальных от дизайнера. Мотив тот же, что у
`BreathingHorizon`: линия горизонта, которая и есть волна. Две краски
на тёплой бумаге, ничего больше — см. DESIGN.md.

Запуск:  python3 tool/generate_icons.py
Требует: pillow
"""

import json
import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# lib/core/theme/colors.dart
PAPER = (0xFA, 0xF6, 0xF1)
ACCENT = (0xC9, 0x7B, 0x5C)
NIGHT = (0x1C, 0x1A, 0x18)

SS = 4  # суперсэмплинг: рисуем крупно, потом уменьшаем


def _wave_points(size, *, span, amplitude, cycles=1.0, phase=0.0, steps=600):
    """Точки волны в квадрате `size`. `span` — доля ширины под линию."""
    x0 = (1.0 - span) / 2.0
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = x0 + t * span
        # минус: в координатах картинки y растёт вниз, а вдох поднимает
        # горизонт — волна должна сначала идти вверх
        y = 0.5 - amplitude * math.sin(2 * math.pi * (t * cycles + phase))
        pts.append((x * size, y * size))
    return pts


def _stroke_polygon(pts, width):
    """Контур штриха: кривая, сдвинутая по нормали на ±половину толщины.

    `ImageDraw.line(joint="curve")` на пологой синусоиде оставляет
    зазубрины между сегментами, поэтому штрих собирается заливкой.
    """
    half = width / 2.0
    upper, lower = [], []
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        px, py = pts[max(i - 1, 0)]
        nx, ny = pts[min(i + 1, n - 1)]
        dx, dy = nx - px, ny - py
        length = math.hypot(dx, dy) or 1.0
        # нормаль к касательной
        ox, oy = -dy / length * half, dx / length * half
        upper.append((x + ox, y + oy))
        lower.append((x - ox, y - oy))
    return upper + lower[::-1]


def _draw_wave(size, *, bg, span, amplitude, stroke):
    """Квадрат с волной. `bg=None` — прозрачный фон (для adaptive icon)."""
    big = size * SS
    im = Image.new("RGBA", (big, big), (*bg, 255) if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    pts = _wave_points(big, span=span, amplitude=amplitude)
    width = max(1.0, stroke * big)
    d.polygon(_stroke_polygon(pts, width), fill=(*ACCENT, 255))

    # круглые торцы
    for x, y in (pts[0], pts[-1]):
        r = width / 2.0
        d.ellipse([x - r, y - r, x + r, y + r], fill=(*ACCENT, 255))

    return im.resize((size, size), Image.LANCZOS)


def app_icon(size):
    """Полнокадровая иконка: волна во всю ширину бумаги."""
    im = _draw_wave(size, bg=PAPER, span=1.0, amplitude=0.135, stroke=0.085)
    return im.convert("RGB")  # App Store не принимает альфу в иконке


def adaptive_foreground(size):
    """Передний план adaptive icon: волна внутри безопасной зоны 66/108."""
    return _draw_wave(size, bg=None, span=66 / 108, amplitude=0.089, stroke=0.056)


def launch_mark(size):
    """Знак для сплэша: волна на прозрачном, чтобы легла на любой фон."""
    return _draw_wave(size, bg=None, span=0.86, amplitude=0.16, stroke=0.075)


def write(im, path):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    im.save(full)
    print(f"  {path}  {im.size[0]}×{im.size[1]}")


def main():
    # ── iOS: AppIcon ─────────────────────────────────────────────
    print("iOS AppIcon:")
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    with open(os.path.join(ROOT, ios_dir, "Contents.json")) as f:
        contents = json.load(f)

    # Один файл может быть заявлен под несколько идиом — считаем размер
    # один раз на имя файла.
    wanted = {}
    for entry in contents["images"]:
        px = int(round(float(entry["size"].split("x")[0]) * float(entry["scale"][:-1])))
        wanted[entry["filename"]] = px
    for name, px in sorted(wanted.items(), key=lambda kv: kv[1]):
        write(app_icon(px), f"{ios_dir}/{name}")

    # ── iOS: LaunchImage ─────────────────────────────────────────
    print("iOS LaunchImage:")
    launch_dir = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, px in [
        ("LaunchImage.png", 200),
        ("LaunchImage@2x.png", 400),
        ("LaunchImage@3x.png", 600),
    ]:
        write(launch_mark(px), f"{launch_dir}/{name}")

    # ── Android: legacy + adaptive ───────────────────────────────
    print("Android mipmap:")
    for bucket, legacy, adaptive in [
        ("mdpi", 48, 108),
        ("hdpi", 72, 162),
        ("xhdpi", 96, 216),
        ("xxhdpi", 144, 324),
        ("xxxhdpi", 192, 432),
    ]:
        d = f"android/app/src/main/res/mipmap-{bucket}"
        write(app_icon(legacy), f"{d}/ic_launcher.png")
        write(adaptive_foreground(adaptive), f"{d}/ic_launcher_foreground.png")


if __name__ == "__main__":
    main()

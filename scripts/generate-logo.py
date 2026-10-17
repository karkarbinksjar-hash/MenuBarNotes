#!/usr/bin/env python3
"""Render MenuBarNotes brand assets from the design below.

Usage:  python3 scripts/generate-logo.py
Output: assets/logo-1024.png, logo-512.png, logo-256.png, AppIcon.icns

Requires Pillow (pip install pillow). The committed PNG/ICNS files are the
source of truth for packaging; this script only regenerates them.
"""

from __future__ import annotations

import io
import struct
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
S = 4  # supersample factor

TILE = (28, 28, 996, 996, 226)
TOP = (0x6C, 0x7C, 0xFF)
BOTTOM = (0x8B, 0x4D, 0xF0)
PAGE = (264, 176, 790, 848, 60)
FOLD = [(620, 176), (620, 346), (790, 346)]
FOLD_RGB = (0xD3, 0xDC, 0xFF)
INDIGO = (0x4F, 0x46, 0xE5)
NAVY = (0x24, 0x2A, 0x4A)
LINE = (0xC3, 0xCC, 0xE6)
GREEN = (0x22, 0xC5, 0x5E)
WHITE = (0xFF, 0xFF, 0xFF)


def sc(*vals: float) -> list[float]:
    return [v * S for v in vals]


def rounded(draw: ImageDraw.ImageDraw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(sc(*box), radius=radius * S, fill=fill, outline=outline, width=width * S)


def capsule(draw: ImageDraw.ImageDraw, p1, p2, width, fill):
    draw.line([tuple(sc(*p1)), tuple(sc(*p2))], fill=fill, width=round(width * S))
    r = width * S / 2
    for x, y in (p1, p2):
        draw.ellipse([x * S - r, y * S - r, x * S + r, y * S + r], fill=fill)


def polygon(draw: ImageDraw.ImageDraw, points, fill):
    draw.polygon([tuple(sc(*p)) for p in points], fill=fill)


def render(size: int = 1024) -> Image.Image:
    w = h = 1024 * S
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Vertical gradient tile
    gradient = Image.new("RGBA", (1, h))
    gd = ImageDraw.Draw(gradient)
    for y in range(h):
        t = y / max(h - 1, 1)
        gd.point((0, y), fill=tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)) + (255,))
    gradient = gradient.resize((w, h))

    mask = Image.new("L", (w, h), 0)
    rounded(ImageDraw.Draw(mask), TILE[:4], TILE[4], fill=255)
    canvas.alpha_composite(Image.composite(gradient, Image.new("RGBA", (w, h)), mask))

    draw = ImageDraw.Draw(canvas)

    # Soft corner light
    light = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(light).polygon(
        [tuple(sc(28, 250)), tuple(sc(250, 28)), tuple(sc(520, 28)), tuple(sc(28, 520))],
        fill=(255, 255, 255, 26),
    )
    light.putalpha(Image.composite(light.getchannel("A"), Image.new("L", (w, h)), mask))
    canvas.alpha_composite(light)

    # Page (rounded except folded top-right corner)
    page_mask = Image.new("L", (w, h), 0)
    rounded(ImageDraw.Draw(page_mask), PAGE[:4], PAGE[4], fill=255)
    ImageDraw.Draw(page_mask).polygon(
        [tuple(sc(620, 176)), tuple(sc(790, 176)), tuple(sc(790, 346))], fill=0
    )
    page = Image.new("RGBA", (w, h), WHITE)
    canvas.alpha_composite(Image.composite(page, Image.new("RGBA", (w, h)), page_mask))

    polygon(draw, FOLD, FOLD_RGB + (255,))

    # Markdown hash
    capsule(draw, (406, 394), (370, 524), 32, INDIGO)
    capsule(draw, (506, 394), (470, 524), 32, INDIGO)
    capsule(draw, (354, 438), (528, 438), 32, INDIGO)
    capsule(draw, (344, 490), (518, 490), 32, INDIGO)

    # Heading and body lines
    rounded(draw, (592, 414, 740, 454), 20, fill=NAVY)
    for x0, y0, x1 in ((342, 600, 728), (342, 664, 672), (342, 728, 698)):
        rounded(draw, (x0, y0, x1, y0 + 34), 17, fill=LINE)

    # Done badge
    draw.ellipse(sc(622, 642, 830, 850), fill=WHITE)
    draw.ellipse(sc(642, 662, 810, 830), fill=GREEN)
    capsule(draw, (684, 748), (714, 778), 30, WHITE)
    capsule(draw, (714, 778), (770, 716), 30, WHITE)

    # Hairline inner border
    rounded(draw, TILE[:4], TILE[4], outline=(255, 255, 255, 41), width=4)

    return canvas.resize((size, size), Image.LANCZOS)


def write_icns(path: Path, images: dict[str, Image.Image]) -> None:
    entries = []
    for kind, image in images.items():
        buf = io.BytesIO()
        image.save(buf, format="PNG")
        data = buf.getvalue()
        entries.append(kind.encode("ascii") + struct.pack(">I", len(data) + 8) + data)
    body = b"".join(entries)
    path.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)


def main() -> None:
    ASSETS.mkdir(exist_ok=True)
    master = render(1024)
    master.save(ASSETS / "logo-1024.png")
    for px in (512, 256):
        master.resize((px, px), Image.LANCZOS).save(ASSETS / f"logo-{px}.png")

    iconset = {
        "icp4": 16,
        "icp5": 32,
        "icp6": 64,
        "ic07": 128,
        "ic08": 256,
        "ic09": 512,
        "ic10": 1024,
        "ic11": 32,
        "ic12": 64,
        "ic13": 256,
        "ic14": 512,
    }
    images = {kind: master.resize((px, px), Image.LANCZOS) for kind, px in iconset.items()}
    write_icns(ASSETS / "AppIcon.icns", images)
    print("wrote logo PNGs and AppIcon.icns to", ASSETS)


if __name__ == "__main__":
    main()

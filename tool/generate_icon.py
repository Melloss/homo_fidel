#!/usr/bin/env python3
"""Regenerate the app icon assets.

The mark is ፊ (U+134A, ETHIOPIC SYLLABLE FI) — the first letter of ፊደል
(fidäl), the script the app checks. Colours are sampled from the concept
spec: navy #14213D is the header block, gold #E4B363 its accent text.

Usage:  python3 tool/generate_icon.py
Then:   dart run flutter_launcher_icons
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

NAVY = "#14213D"
GOLD = "#E4B363"
FI = "ፊ"
FONT = "/usr/share/fonts/truetype/noto/NotoSansEthiopic-Bold.ttf"
OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"

def draw(size: int, fit: float, bg, fg: str) -> Image.Image:
    """Render ፊ centred on its inked bounds, scaled to `fit` of the canvas
    on whichever axis is tighter (ፊ is wider than it is tall)."""
    im = Image.new("RGBA", (size, size), bg or (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    target = size * fit
    lo, hi = 10, size * 3
    while lo < hi - 1:
        mid = (lo + hi) // 2
        b = d.textbbox((0, 0), FI, font=ImageFont.truetype(FONT, mid))
        if max(b[2] - b[0], b[3] - b[1]) > target:
            hi = mid
        else:
            lo = mid
    font = ImageFont.truetype(FONT, lo)
    b = d.textbbox((0, 0), FI, font=font)
    d.text(((size - (b[2] - b[0])) / 2 - b[0],
            (size - (b[3] - b[1])) / 2 - b[1]), FI, font=font, fill=fg)
    return im

# flutter_launcher_icons wraps the foreground in a 16%-per-side <inset>, so the
# drawable only covers 68% of the adaptive canvas. Size the glyph here to
# FOREGROUND_FIT so it lands at 0.82 * 0.68 = ~56% of the final icon — filling
# the mask without crossing Android's 66% safe zone. Sizing it at the final
# figure instead yields a ~27% speck; verify any change by compositing the
# generated drawable over the plate with the inset applied.
FOREGROUND_FIT = 0.82

OUT.mkdir(parents=True, exist_ok=True)
# Full-bleed: legacy Android, web, favicon. No inset is applied to these.
draw(1024, 0.58, NAVY, GOLD).save(OUT / "icon.png")
# Adaptive foreground: transparent plate, gold glyph.
draw(1024, FOREGROUND_FIT, None, GOLD).save(OUT / "icon_foreground.png")
# Monochrome (Android 13+ themed icons): silhouette the system tints itself.
draw(1024, FOREGROUND_FIT, None, "#FFFFFF").save(OUT / "icon_monochrome.png")
print(f"wrote icon.png, icon_foreground.png, icon_monochrome.png -> {OUT}")

"""Builds the Play Store images from the rendered screens.

Run after render_screens_test.dart:
    python store/compose.py

Writes store/play/: four 1080x1920 phone screenshots, the 1024x500
feature graphic and the 512x512 app icon. Colours mirror lib/core/theme/app_colors.dart.
"""

import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).parent
RAW = HERE / "raw"
OUT = HERE / "play"
ICON = HERE.parent / "assets" / "branding" / "icon_legacy.png"

BACKGROUND = (11, 18, 18)       # darkBackground
DEEP = (2, 33, 27)              # launcher icon background
PRIMARY = (80, 196, 190)        # darkPrimary
TEXT = (241, 245, 244)          # darkText
TEXT_2 = (155, 175, 173)        # darkTextSecondary
OUTLINE = (38, 52, 51)          # darkOutline

SCREENS = [
    ("1_today", "Hit your protein goal",
     "Protein, calories and cost at a glance"),
    ("2_history", "See your progress",
     "Weekly charts, averages and goal streaks"),
    ("3_products", "Your foods, ready to log",
     "Common foods included. Add your own."),
    ("4_settings", "Private and offline",
     "No account. Your data stays on your phone."),
]


def font(weight, size):
    root = os.environ.get("FLUTTER_ROOT")
    if not root:
        from shutil import which
        flutter = which("flutter")
        if not flutter:
            sys.exit("Set FLUTTER_ROOT or put flutter on PATH for the fonts.")
        root = str(Path(flutter).resolve().parent.parent)
    path = Path(root) / "bin/cache/artifacts/material_fonts" / f"roboto-{weight}.ttf"
    return ImageFont.truetype(str(path), size)


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        draw.line([(0, y), (w, y)],
                  fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), img.size], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def centred(draw, y, text, fnt, fill, width):
    w = draw.textlength(text, font=fnt)
    draw.text(((width - w) / 2, y), text, font=fnt, fill=fill)


def phone_shot(name, title, subtitle):
    W, H = 1080, 1920
    canvas = gradient((W, H), DEEP, BACKGROUND).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    centred(draw, 110, title, font("bold", 84), TEXT, W)
    centred(draw, 222, subtitle, font("regular", 44), TEXT_2, W)

    # The screen, scaled to sit under the caption with a frame and shadow.
    shot = Image.open(RAW / f"{name}.png").convert("RGB")
    target_h = 1530
    target_w = round(shot.width * target_h / shot.height)
    shot = shot.resize((target_w, target_h), Image.LANCZOS)
    x, y = (W - target_w) // 2, 340
    bezel, radius = 14, 64

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x - bezel, y - bezel + 24, x + target_w + bezel, y + target_h + bezel + 24],
        radius + bezel, fill=(0, 0, 0, 170))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(36)))

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        [x - bezel, y - bezel, x + target_w + bezel, y + target_h + bezel],
        radius + bezel, fill=(20, 28, 28), outline=OUTLINE, width=3)
    canvas.alpha_composite(rounded(shot, radius), (x, y))
    return canvas.convert("RGB")


def feature_graphic():
    W, H = 1024, 500
    canvas = gradient((W, H), DEEP, BACKGROUND).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # The launcher tile, not app_icon.png: that one carries a black square
    # which read as a hole cut in the teal background.
    size, radius = 230, 52
    ix, iy = 90, (H - size) // 2
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [ix, iy + 14, ix + size, iy + size + 14], radius, fill=(0, 0, 0, 150))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(22)))
    icon = Image.open(ICON).convert("RGBA").resize((size, size), Image.LANCZOS)
    canvas.alpha_composite(rounded(icon, radius), (ix, iy))
    # A hairline edge, since the tile shares the gradient's top colour.
    ImageDraw.Draw(canvas).rounded_rectangle(
        [ix, iy, ix + size - 1, iy + size - 1], radius, outline=OUTLINE, width=2)

    x = 360
    draw.text((x, 150), "Daily Protein", font=font("bold", 76), fill=TEXT)
    draw.text((x, 252), "Track protein, calories and cost.",
              font=font("regular", 36), fill=TEXT_2)
    draw.text((x, 302), "Offline. No account.",
              font=font("medium", 36), fill=PRIMARY)
    return canvas.convert("RGB")


def store_icon():
    # Full-bleed square: Play applies its own rounded mask, so corners or
    # a shadow drawn here would be doubled up. RGBA as Play asks for a
    # 32-bit PNG.
    return Image.open(ICON).convert("RGBA").resize((512, 512), Image.LANCZOS)


def main():
    OUT.mkdir(exist_ok=True)
    for name, title, subtitle in SCREENS:
        phone_shot(name, title, subtitle).save(OUT / f"{name}.png", optimize=True)
    feature_graphic().save(OUT / "feature_graphic.png", optimize=True)
    store_icon().save(OUT / "icon_512.png", optimize=True)
    print(f"Wrote {len(SCREENS) + 2} images to {OUT}")


if __name__ == "__main__":
    main()

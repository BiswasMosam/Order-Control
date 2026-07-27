"""Generates the Order Control launcher icon: a white OC on a red gradient.

Renders at 4x and downsamples, so the letter edges stay clean at 48px.

    pip install pillow
    python tool/make_icon.py
    dart run flutter_launcher_icons

Writes into assets/icon:
    icon.png             full bleed square, the legacy launcher icon
    icon_background.png  the red gradient alone, adaptive background layer
    icon_foreground.png  the OC alone on transparency, adaptive foreground
    icon_monochrome.png  flat silhouette for Android 13 themed icons
"""

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "icon")

SIZE = 1024
SS = 4  # supersample factor
S = SIZE * SS

FONT = os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts", "ariblk.ttf")

# Diagonal red: warm at the top left, deep at the bottom right.
TL = (236, 78, 60)
TR = (214, 45, 40)
BL = (206, 38, 35)
BR = (162, 20, 24)

KERN_RATIO = -0.055  # pulls the C towards the O for a compact mark


def gradient(size):
    """Smooth diagonal blend, made by scaling a 2x2 corner image up."""
    seed = Image.new("RGB", (2, 2))
    seed.putpixel((0, 0), TL)
    seed.putpixel((1, 0), TR)
    seed.putpixel((0, 1), BL)
    seed.putpixel((1, 1), BR)
    return seed.resize((size, size), Image.BICUBIC)


def vignette(img):
    """Slight darkening at the corners so the mark reads as a solid object."""
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    pad = int(size * 0.04)
    ImageDraw.Draw(mask).ellipse([-pad, -pad, size + pad, size + pad], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(size * 0.10))
    shade = Image.new("RGB", (size, size), (120, 10, 14))
    return Image.composite(img, Image.blend(img, shade, 0.30), mask)


def monogram(size, width_ratio, colour=(255, 255, 255, 255), shadow=True):
    """Draws OC centred on transparency, tightly kerned, as its own layer."""
    # Find the point size that makes the pair span the requested width.
    probe = 100
    font = ImageFont.truetype(FONT, probe)
    bo, bc = font.getbbox("O"), font.getbbox("C")
    pair = (bo[2] - bo[0]) + (bc[2] - bc[0]) + KERN_RATIO * probe
    pt = int(probe * (size * width_ratio) / pair)

    font = ImageFont.truetype(FONT, pt)
    bo, bc = font.getbbox("O"), font.getbbox("C")
    w_o = bo[2] - bo[0]
    kern = KERN_RATIO * pt
    total_w = w_o + (bc[2] - bc[0]) + kern
    top, bottom = min(bo[1], bc[1]), max(bo[3], bc[3])

    x = (size - total_w) / 2
    y = (size - (bottom - top)) / 2 - top

    def stamp(target, dy=0, fill=colour):
        d = ImageDraw.Draw(target)
        d.text((x - bo[0], y + dy), "O", font=font, fill=fill)
        d.text((x + w_o + kern - bc[0], y + dy), "C", font=font, fill=fill)

    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if shadow:
        shade = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        stamp(shade, dy=size * 0.012, fill=(90, 0, 4, 110))
        layer = Image.alpha_composite(
            layer, shade.filter(ImageFilter.GaussianBlur(size * 0.012))
        )

    letters = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    stamp(letters)
    return Image.alpha_composite(layer, letters)


def save(img, name):
    img.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(OUT, name))
    print("wrote", name)


def main():
    os.makedirs(OUT, exist_ok=True)
    bg = vignette(gradient(S)).convert("RGBA")

    # Full bleed icon: the mark spans 62% of the square.
    save(Image.alpha_composite(bg, monogram(S, 0.62)), "icon.png")

    # Adaptive layers. Launchers crop the outer quarter, so the foreground
    # mark is held to 50% of the canvas to stay inside the safe circle.
    save(bg, "icon_background.png")
    save(monogram(S, 0.50), "icon_foreground.png")

    # Themed icons are tinted by the system, so no shadow and no gradient.
    save(monogram(S, 0.50, shadow=False), "icon_monochrome.png")


if __name__ == "__main__":
    main()

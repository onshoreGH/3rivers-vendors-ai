#!/usr/bin/env python3
"""Composite raw app screenshots into framed App Store marketing images."""
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC, OUT, KIND = sys.argv[1], sys.argv[2], sys.argv[3]  # KIND = iphone | ipad

if KIND == "iphone":
    CW, CH = 1284, 2778
    CAP_TOP = 132
    CAP_SIZE = 88
    CAP_ZONE = 540          # vertical space reserved for caption
    SHOT_W_FRAC = 0.90
    CORNER = 60
    BEZEL = 12
    BOTTOM_MARGIN = 96
elif KIND == "ipad":
    CW, CH = 2048, 2732
    CAP_TOP = 150
    CAP_SIZE = 116
    CAP_ZONE = 560
    SHOT_W_FRAC = 0.96
    CORNER = 44
    BEZEL = 14
    BOTTOM_MARGIN = 120
else:
    raise SystemExit("KIND must be iphone|ipad")

TOP = (0x27, 0xB0, 0x6E)     # lighter green
BOT = (0x0C, 0x5A, 0x33)     # deep green
TEXT = (0xFF, 0xFF, 0xFF)

CAPTIONS = {
    "01-login.png": "The 3Rivers floor,\nin your pocket",
    "02-home.png": "Every order and shipment\nat a glance",
    "03-work-orders.png": "Track work orders\nby status",
    "04-shipments.png": "Know what's late\nbefore the call",
    "05-directory.png": "Suppliers and vendors\nin one place",
    "06-settings.png": "Secure staff sign-in",
}

def load_font(size):
    for path, kw in [
        ("/System/Library/Fonts/SFNS.ttf", "Bold"),
        ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", None),
        ("/System/Library/Fonts/HelveticaNeue.ttc", None),
    ]:
        try:
            f = ImageFont.truetype(path, size)
            if kw:
                try:
                    f.set_variation_by_name(kw)
                except Exception:
                    pass
            return f
        except Exception:
            continue
    return ImageFont.load_default()

def gradient(w, h, top, bot):
    base = Image.new("RGB", (w, h), top)
    d = ImageDraw.Draw(base)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(round(top[i] + (bot[i]-top[i])*t) for i in range(3)))
    return base

def trim_whitespace(shot):
    """Remove only the trailing empty background band directly above the bottom
    nav bar. Gaps between content sections are left intact."""
    w, h = shot.size
    px = shot.load()
    bg = px[w // 2, int(h * 0.88)]
    xs = range(0, w, 7)
    def blankish(y):
        hits = sum(1 for x in xs if all(abs(px[x, y][i] - bg[i]) < 12 for i in range(3)))
        return hits / len(xs) > 0.985
    nav_h = int(h * 0.105)
    content_bottom = h - nav_h
    while content_bottom > int(h * 0.30) and blankish(content_bottom - 1):
        content_bottom -= 1
    trailing = (h - nav_h) - content_bottom
    if trailing < 140:
        return shot
    y1 = content_bottom + 28
    top = shot.crop((0, 0, w, y1))
    nav = shot.crop((0, h - nav_h, w, h))
    out = Image.new("RGB", (w, y1 + nav_h), bg)
    out.paste(top, (0, 0))
    out.paste(nav, (0, y1))
    return out

def rounded(im, rad):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0]-1, im.size[1]-1], rad, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

font = load_font(CAP_SIZE)
os.makedirs(OUT, exist_ok=True)

for name in sorted(os.listdir(SRC)):
    if not name.endswith(".png"):
        continue
    shot = Image.open(os.path.join(SRC, name)).convert("RGB")
    top_crop = 128 if KIND == "iphone" else 28   # drop the empty status-bar band
    shot = shot.crop((0, top_crop, shot.size[0], shot.size[1]))
    canvas = gradient(CW, CH, TOP, BOT).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    cap = CAPTIONS.get(name, os.path.splitext(name)[1])
    draw.multiline_text((CW/2, CAP_TOP), cap, font=font, fill=TEXT,
                        anchor="ma", align="center", spacing=CAP_SIZE*0.22)

    band_top = CAP_ZONE
    band_bot = CH - BOTTOM_MARGIN
    max_w = int(CW * SHOT_W_FRAC) - BEZEL*2
    max_h = (band_bot - band_top) - BEZEL*2
    ar = shot.size[0] / shot.size[1]
    # size the device as large as the band allows (height-driven, width-clamped)
    th = max_h
    tw = round(th * ar)
    if tw > max_w:
        tw, th = max_w, round(max_w / ar)
    shot = shot.resize((tw, th), Image.LANCZOS)

    framed = Image.new("RGB", (tw + BEZEL*2, th + BEZEL*2), (12, 12, 14))
    framed.paste(shot, (BEZEL, BEZEL))
    framed = rounded(framed, CORNER)

    fx = (CW - framed.size[0]) // 2
    fy = band_top + (band_bot - band_top - framed.size[1]) // 2

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([fx+14, fy+26, fx+framed.size[0]+14, fy+framed.size[1]+26],
                         CORNER, fill=(0, 0, 0, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    canvas = Image.alpha_composite(canvas, shadow)

    canvas.paste(framed, (fx, fy), framed)
    canvas.convert("RGB").save(os.path.join(OUT, name), "PNG")
    print(f"  {name}  {CW}x{CH}")

"""Generates the Google Play "Feature Graphic" (1024x500 PNG) for HelaBox.

Reuses the app's own brand language rather than inventing a new one:
- The teal900->teal800 diagonal gradient used on the login screen and every
  dashboard hero card (see lib/theme/app_theme.dart AppColors).
- The real HelaBox icon mark (helabox_icon.png).
- The app's own bundled fonts (Plus Jakarta Sans for the wordmark, Inter for
  the tagline) instead of a system font, so it reads as the same product.

Run: python make_feature_graphic.py
"""

from PIL import Image, ImageDraw, ImageFont

W, H = 1024, 500

# AppColors.teal900 / teal800 / teal100 (lib/theme/app_theme.dart) — teal100
# is the app's own muted mint-white used for subtitle text on dark hero
# backgrounds (login screen, splash screen), reused here for the tagline.
TEAL_900 = (11, 74, 61)
TEAL_800 = (15, 95, 76)
TEAL_100 = (191, 224, 211)
GREEN_500 = (31, 191, 130)
WHITE = (255, 255, 255)

BASE = r"C:\Users\Administrator\Documents\CODEZ\yekonga-server-go\pesa_box_app"
FONTS = BASE + r"\google_fonts"
BRAND = BASE + r"\assets\brand"


def diagonal_gradient(w, h, c1, c2):
    """Top-left -> bottom-right gradient, matching the hero-card style
    (LinearGradient(begin: topLeft, end: bottomRight)) used throughout the
    app."""
    base = Image.new("RGB", (w, h), c1)
    top = Image.new("RGB", (w, h), c2)
    mask = Image.new("L", (w, h))
    mask_data = []
    max_dist = w + h
    for y in range(h):
        for x in range(w):
            mask_data.append(int(255 * (x + y) / max_dist))
    mask.putdata(mask_data)
    return Image.composite(top, base, mask)


def add_corner_accent(img):
    """A large, soft diamond bleeding off the right edge, echoing the icon's
    own diamond motif — texture without clutter."""
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy, r = W - 40, H // 2, 420
    diamond = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
    draw.polygon(diamond, fill=(255, 255, 255, 14))
    cx2, r2 = W - 120, 260
    diamond2 = [(cx2, cy - r2), (cx2 + r2, cy), (cx2, cy + r2), (cx2 - r2, cy)]
    draw.polygon(diamond2, fill=GREEN_500 + (22,))
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


def main():
    img = diagonal_gradient(W, H, TEAL_900, TEAL_800)
    img = add_corner_accent(img)
    draw = ImageDraw.Draw(img)

    # --- Icon mark, left side ---
    icon = Image.open(BRAND + r"\helabox_icon.png").convert("RGBA")
    icon_size = 280
    icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
    icon_x, icon_y = 72, (H - icon_size) // 2
    img.paste(icon, (icon_x, icon_y), icon)

    # --- Wordmark + tagline, right of the icon ---
    text_x = icon_x + icon_size + 56

    wordmark_font = ImageFont.truetype(FONTS + r"\PlusJakartaSans-ExtraBold.ttf", 96)
    tagline_font = ImageFont.truetype(FONTS + r"\Inter-Medium.ttf", 34)

    wordmark = "HelaBox"
    w_bbox = draw.textbbox((0, 0), wordmark, font=wordmark_font)
    w_h = w_bbox[3] - w_bbox[1]

    tagline = "Savings groups, simplified"
    t_bbox = draw.textbbox((0, 0), tagline, font=tagline_font)
    t_h = t_bbox[3] - t_bbox[1]

    gap = 22
    block_h = w_h + gap + t_h
    start_y = (H - block_h) // 2

    draw.text((text_x, start_y - w_bbox[1]), wordmark, font=wordmark_font, fill=WHITE)
    draw.text(
        (text_x, start_y + w_h + gap - t_bbox[1]),
        tagline,
        font=tagline_font,
        fill=TEAL_100,
    )

    out_path = BRAND + r"\play_feature_graphic.png"
    img.convert("RGB").save(out_path, "PNG")
    print(f"Saved {out_path} ({img.width}x{img.height})")


if __name__ == "__main__":
    main()

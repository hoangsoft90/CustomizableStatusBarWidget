#!/usr/bin/env python3
"""Generate app icon (512x512) and feature graphic (1024x500) for Photo Clock Widget."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# ─── Colors ────────────────────────────────────────────────
BG_DARK = (26, 26, 46)       # #1A1A2E
BG_MID = (15, 52, 96)        # #0F3460
BG_LIGHT = (22, 33, 62)      # #16213E
ACCENT = (0, 188, 212)       # #00BCD4 (cyan)
WHITE = (255, 255, 255)
WHITE_70 = (204, 204, 204)
OVERLAY = (0, 0, 0, 90)      # 35% black

OUT_DIR = "assets_output"
os.makedirs(OUT_DIR, exist_ok=True)


def create_icon(size=512):
    """Create a clean, minimal app icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # ── Background: rounded square with gradient ──
    # Draw gradient manually (top to bottom)
    for y in range(size):
        ratio = y / size
        r = int(BG_DARK[0] * (1 - ratio) + BG_MID[0] * ratio)
        g = int(BG_DARK[1] * (1 - ratio) + BG_MID[1] * ratio)
        b = int(BG_DARK[2] * (1 - ratio) + BG_MID[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # ── Rounded corners mask ──
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = size // 5
    mask_draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=corner_radius,
        fill=255,
    )
    img.putalpha(mask)

    # ── Clock circle ──
    cx, cy = size // 2, size // 2 - size // 12
    clock_r = size // 3

    # Circle outline
    outline_width = max(3, size // 80)
    draw.ellipse(
        [(cx - clock_r, cy - clock_r), (cx + clock_r, cy + clock_r)],
        outline=(*WHITE, 230),
        width=outline_width,
    )

    # Hour markers (12 dots)
    for i in range(12):
        angle = math.radians(i * 30 - 90)
        mx = cx + int((clock_r - size // 20) * math.cos(angle))
        my = cy + int((clock_r - size // 20) * math.sin(angle))
        dot_r = max(2, size // 60)
        draw.ellipse(
            [(mx - dot_r, my - dot_r), (mx + dot_r, my + dot_r)],
            fill=(*WHITE, 200),
        )

    # Hour hand (10:10 position = 300° and 60°)
    hand_width = max(2, size // 70)
    # Hour hand → 10 o'clock = 300°
    h_angle = math.radians(300 - 90)
    hx = cx + int(clock_r * 0.5 * math.cos(h_angle))
    hy = cy + int(clock_r * 0.5 * math.sin(h_angle))
    draw.line([(cx, cy), (hx, hy)], fill=(*WHITE, 240), width=hand_width + 1)

    # Minute hand → 2 o'clock = 60°
    m_angle = math.radians(60 - 90)
    mx2 = cx + int(clock_r * 0.72 * math.cos(m_angle))
    my2 = cy + int(clock_r * 0.72 * math.sin(m_angle))
    draw.line([(cx, cy), (mx2, my2)], fill=(*WHITE, 240), width=hand_width)

    # Center dot
    center_r = max(3, size // 50)
    draw.ellipse(
        [(cx - center_r, cy - center_r), (cx + center_r, cy + center_r)],
        fill=(*ACCENT, 255),
    )

    # ── Date text below clock ──
    try:
        font_size = size // 12
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
    except (OSError, IOError):
        font = ImageFont.load_default()

    date_text = "AUG 30"
    bbox = draw.textbbox((0, 0), date_text, font=font)
    tw = bbox[2] - bbox[0]
    tx = (size - tw) // 2
    ty = cy + clock_r + size // 14
    draw.text((tx, ty), date_text, fill=(*WHITE_70, 220), font=font)

    img.save(os.path.join(OUT_DIR, "icon.png"), "PNG")
    print(f"✅ icon.png saved ({size}x{size})")


def create_feature_graphic():
    """Create feature graphic 1024x500 for Play Store."""
    w, h = 1024, 500
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # ── Background gradient ──
    for y in range(h):
        ratio = y / h
        r = int(BG_DARK[0] * (1 - ratio) + BG_LIGHT[0] * ratio)
        g = int(BG_DARK[1] * (1 - ratio) + BG_LIGHT[1] * ratio)
        b = int(BG_DARK[2] * (1 - ratio) + BG_LIGHT[2] * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    # ── Subtle pattern: diagonal lines ──
    for i in range(-h, w + h, 40):
        draw.line(
            [(i, 0), (i + h, h)],
            fill=(255, 255, 255, 8),
            width=1,
        )

    # ── Left side: 3 phone mockups (simplified rectangles) ──
    phone_w, phone_h = 120, 220
    phones = [
        (80, 100, ACCENT),         # Cyan
        (160, 130, (255, 152, 0)), # Orange
        (240, 160, (76, 175, 80)), # Green
    ]

    for px, py, accent in phones:
        # Phone body
        draw.rounded_rectangle(
            [(px, py), (px + phone_w, py + phone_h)],
            radius=12,
            fill=(30, 30, 50, 220),
            outline=(80, 80, 100, 150),
            width=2,
        )
        # Screen area
        draw.rounded_rectangle(
            [(px + 6, py + 20), (px + phone_w - 6, py + phone_h - 20)],
            radius=4,
            fill=(20, 20, 35, 200),
        )
        # Widget representation inside phone
        widget_x = px + 12
        widget_y = py + 50
        widget_w = phone_w - 24
        widget_h = 40
        draw.rounded_rectangle(
            [(widget_x, widget_y), (widget_x + widget_w, widget_y + widget_h)],
            radius=6,
            fill=(*accent, 180),
        )
        # Time text in widget
        try:
            small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
        except (OSError, IOError):
            small_font = ImageFont.load_default()
        draw.text(
            (widget_x + 8, widget_y + 10),
            "10:15",
            fill=(255, 255, 255, 230),
            font=small_font,
        )

    # ── Right side: Title + Subtitle ──
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 52)
        subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
    except (OSError, IOError):
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()

    title = "Photo Clock"
    title2 = "Widget"
    subtitle = "Your Home Screen,\nBeautifully Updated"

    # Title
    bbox1 = draw.textbbox((0, 0), title, font=title_font)
    tw1 = bbox1[2] - bbox1[0]
    tx1 = 420
    draw.text((tx1, 120), title, fill=(*WHITE, 255), font=title_font)

    bbox2 = draw.textbbox((0, 0), title2, font=title_font)
    draw.text((tx1, 180), title2, fill=(*WHITE, 255), font=title_font)

    # Accent line
    draw.rectangle(
        [(tx1, 250), (tx1 + 80, 254)],
        fill=(*ACCENT, 255),
    )

    # Subtitle
    draw.text((tx1, 270), subtitle, fill=(*WHITE_70, 220), font=subtitle_font)

    # ── Small icon in bottom-right ──
    icon_size = 50
    ix, iy = w - 80, h - 70
    # Mini clock circle
    draw.ellipse(
        [(ix, iy), (ix + icon_size, iy + icon_size)],
        outline=(*WHITE, 150),
        width=2,
    )
    # Mini hands
    icx, icy = ix + icon_size // 2, iy + icon_size // 2
    ir = icon_size // 3
    for angle_deg, length in [(300, 0.45), (60, 0.65)]:
        a = math.radians(angle_deg - 90)
        ex = icx + int(ir * length * math.cos(a))
        ey = icy + int(ir * length * math.sin(a))
        draw.line([(icx, icy), (ex, ey)], fill=(*WHITE, 180), width=2)

    img_rgb = Image.new("RGB", (w, h), BG_DARK)
    img_rgb.paste(img, mask=img.split()[3])
    img_rgb.save(os.path.join(OUT_DIR, "feature_graphic.png"), "PNG")
    print(f"✅ feature_graphic.png saved ({w}x{h})")


if __name__ == "__main__":
    create_icon(512)
    create_feature_graphic()
    print(f"\n📁 Output: {OUT_DIR}/")

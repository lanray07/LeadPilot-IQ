from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "LeadPilotIQ" / "Resources" / "Assets.xcassets"
APPICON = ASSETS / "AppIcon.appiconset"
STORE = ROOT / "AppStoreAssets"
STORE_ICON = STORE / "Icon"
IPHONE = STORE / "Screenshots" / "iPhone-6.5"
IPAD = STORE / "Screenshots" / "iPad-13"

CHARCOAL = (20, 24, 31)
INK = (30, 35, 46)
MUTED = (102, 112, 133)
BLUE = (22, 92, 222)
GREEN = (0, 148, 116)
TEAL = (0, 118, 114)
ORANGE = (226, 139, 36)
PURPLE = (105, 75, 210)
BG = (244, 248, 250)
WHITE = (255, 255, 255)
LINE = (219, 226, 232)


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    candidates = {
        "regular": [
            "C:/Windows/Fonts/segoeui.ttf",
            "C:/Windows/Fonts/arial.ttf",
        ],
        "semibold": [
            "C:/Windows/Fonts/seguisb.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
        "bold": [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
    }[weight]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont, max_width: int) -> list[str]:
    lines: list[str] = []
    for paragraph in text.split("\n"):
        words = paragraph.split()
        if not words:
            lines.append("")
            continue
        current = words[0]
        for word in words[1:]:
            test = f"{current} {word}"
            if text_size(draw, test, fnt)[0] <= max_width:
                current = test
            else:
                lines.append(current)
                current = word
        lines.append(current)
    return lines


def rounded(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], radius: int, fill, outline=None, width: int = 1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, top)
    pixels = image.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image


def draw_logo(draw: ImageDraw.ImageDraw, cx: int, cy: int, scale: float, light: bool = True):
    stroke = WHITE if light else GREEN
    accent = (146, 232, 204) if light else BLUE
    width = max(6, int(16 * scale))
    points = [
        (cx - int(185 * scale), cy + int(70 * scale)),
        (cx - int(95 * scale), cy + int(70 * scale)),
        (cx - int(40 * scale), cy - int(65 * scale)),
        (cx + int(25 * scale), cy + int(42 * scale)),
        (cx + int(88 * scale), cy - int(112 * scale)),
        (cx + int(185 * scale), cy - int(112 * scale)),
    ]
    draw.line(points, fill=stroke, width=width, joint="curve")
    for x, y in points[2:5]:
        draw.ellipse((x - width, y - width, x + width, y + width), fill=accent)


def make_icon_master() -> Image.Image:
    img = gradient((1024, 1024), (7, 44, 40), (7, 92, 78)).convert("RGB")
    draw = ImageDraw.Draw(img)

    for radius, color, width in [(382, (27, 140, 108), 10), (312, (214, 185, 108), 12)]:
        box = (512 - radius, 512 - radius, 512 + radius, 512 + radius)
        draw.ellipse(box, outline=color, width=width)

    for offset, color in [(0, (11, 83, 71)), (18, (6, 61, 54))]:
        rounded(draw, (210 + offset, 206 + offset, 814 + offset, 810 + offset), 132, color)
    rounded(draw, (210, 206, 814, 810), 132, (9, 76, 66), outline=(139, 220, 195), width=10)
    rounded(draw, (286, 282, 738, 734), 96, (21, 105, 86), outline=(214, 185, 108), width=8)

    draw_logo(draw, 512, 466, 1.18, light=True)

    mark_font = font(154, "bold")
    label = "IQ"
    w, h = text_size(draw, label, mark_font)
    draw.text((512 - w / 2, 676 - h / 2), label, font=mark_font, fill=(228, 245, 238))
    return img


ICON_SPECS = [
    ("Icon-20@2x.png", 40, "iphone", "20x20", "2x"),
    ("Icon-20@3x.png", 60, "iphone", "20x20", "3x"),
    ("Icon-29@2x.png", 58, "iphone", "29x29", "2x"),
    ("Icon-29@3x.png", 87, "iphone", "29x29", "3x"),
    ("Icon-40@2x.png", 80, "iphone", "40x40", "2x"),
    ("Icon-40@3x.png", 120, "iphone", "40x40", "3x"),
    ("Icon-60@2x.png", 120, "iphone", "60x60", "2x"),
    ("Icon-60@3x.png", 180, "iphone", "60x60", "3x"),
    ("Icon-20-ipad@1x.png", 20, "ipad", "20x20", "1x"),
    ("Icon-20-ipad@2x.png", 40, "ipad", "20x20", "2x"),
    ("Icon-29-ipad@1x.png", 29, "ipad", "29x29", "1x"),
    ("Icon-29-ipad@2x.png", 58, "ipad", "29x29", "2x"),
    ("Icon-40-ipad@1x.png", 40, "ipad", "40x40", "1x"),
    ("Icon-40-ipad@2x.png", 80, "ipad", "40x40", "2x"),
    ("Icon-76@1x.png", 76, "ipad", "76x76", "1x"),
    ("Icon-76@2x.png", 152, "ipad", "76x76", "2x"),
    ("Icon-83.5@2x.png", 167, "ipad", "83.5x83.5", "2x"),
    ("Icon-1024.png", 1024, "ios-marketing", "1024x1024", "1x"),
]


def make_icons():
    APPICON.mkdir(parents=True, exist_ok=True)
    STORE_ICON.mkdir(parents=True, exist_ok=True)
    master = make_icon_master()
    contents = {"images": [], "info": {"author": "xcode", "version": 1}}
    for filename, px, idiom, size, scale in ICON_SPECS:
        icon = master.resize((px, px), Image.Resampling.LANCZOS)
        icon.save(APPICON / filename)
        contents["images"].append(
            {"filename": filename, "idiom": idiom, "scale": scale, "size": size}
        )
    master.save(STORE_ICON / "LeadPilotIQ-AppStoreIcon-1024.png")
    (APPICON / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")


def draw_status_bar(draw: ImageDraw.ImageDraw, x: int, y: int, w: int):
    draw.text((x + 42, y + 22), "9:41", font=font(26, "semibold"), fill=INK)
    draw.rounded_rectangle((x + w - 145, y + 27, x + w - 66, y + 49), radius=8, outline=INK, width=3)
    draw.rectangle((x + w - 62, y + 34, x + w - 58, y + 42), fill=INK)
    draw.rounded_rectangle((x + w - 140, y + 31, x + w - 74, y + 45), radius=5, fill=GREEN)


def draw_tab_bar(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, active: str):
    bar_h = 110
    top = y + h - bar_h
    draw.line((x, top, x + w, top), fill=LINE, width=2)
    items = [("Dashboard", "grid"), ("Leads", "people"), ("Proposals", "doc"), ("Analytics", "bars"), ("Settings", "gear")]
    step = w / len(items)
    for idx, (label, _) in enumerate(items):
        cx = int(x + step * idx + step / 2)
        color = BLUE if label == active else (132, 140, 152)
        draw.ellipse((cx - 15, top + 24, cx + 15, top + 54), outline=color, width=4)
        tw, _ = text_size(draw, label, font(18, "semibold"))
        draw.text((cx - tw / 2, top + 66), label, font=font(18, "semibold"), fill=color)


def draw_card(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], title: str = "", value: str = "", color=BLUE):
    rounded(draw, box, 18, WHITE)
    x1, y1, x2, y2 = box
    draw.ellipse((x1 + 28, y1 + 26, x1 + 64, y1 + 62), fill=tuple(int(c * 0.16 + 255 * 0.84) for c in color))
    draw.ellipse((x1 + 38, y1 + 36, x1 + 54, y1 + 52), fill=color)
    draw.text((x1 + 26, y1 + 78), value, font=font(30, "bold"), fill=INK)
    draw.text((x1 + 26, y1 + 120), title, font=font(18, "regular"), fill=MUTED)


def draw_lead_row(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], name: str, service: str, score: int, status: str, color=GREEN):
    rounded(draw, box, 18, WHITE)
    x1, y1, x2, y2 = box
    draw.text((x1 + 26, y1 + 24), name, font=font(26, "bold"), fill=INK)
    draw.text((x1 + 26, y1 + 62), service, font=font(20), fill=MUTED)
    pill = (x2 - 162, y1 + 24, x2 - 26, y1 + 72)
    rounded(draw, pill, 16, tuple(int(c * 0.13 + 255 * 0.87) for c in color))
    draw.text((pill[0] + 20, pill[1] + 12), f"{score} {status}", font=font(18, "bold"), fill=color)
    draw.line((x1 + 26, y2 - 48, x2 - 26, y2 - 48), fill=(235, 239, 242), width=2)
    draw.text((x1 + 26, y2 - 34), "Referral  |  Follow up today", font=font(18), fill=MUTED)


def draw_chart(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]):
    rounded(draw, box, 18, WHITE)
    x1, y1, x2, y2 = box
    draw.text((x1 + 28, y1 + 24), "Lead source performance", font=font(24, "bold"), fill=INK)
    labels = ["Web", "Ref", "Insta", "Call"]
    values = [0.62, 0.88, 0.42, 0.70]
    base = y2 - 48
    bar_w = (x2 - x1 - 86) // len(values)
    for idx, value in enumerate(values):
        bx = x1 + 42 + idx * bar_w
        bh = int((y2 - y1 - 130) * value)
        rounded(draw, (bx, base - bh, bx + bar_w - 32, base), 12, [BLUE, GREEN, ORANGE, PURPLE][idx])
        draw.text((bx, base + 12), labels[idx], font=font(16), fill=MUTED)


def draw_phone_ui(draw: ImageDraw.ImageDraw, frame: tuple[int, int, int, int], screen: str):
    x, y, w, h = frame
    rounded(draw, (x, y, x + w, y + h), 58, WHITE)
    draw_status_bar(draw, x, y, w)
    content_x = x + 44
    content_w = w - 88
    top = y + 92
    title = {
        "dashboard": "Dashboard",
        "leads": "Add Lead",
        "qualification": "AI Qualification",
        "proposal": "Proposal",
        "followup": "Follow-Up",
        "analytics": "Analytics",
    }[screen]
    draw.text((content_x, top), title, font=font(36, "bold"), fill=INK)
    cy = top + 68

    if screen == "dashboard":
        metrics = [("New leads", "12", BLUE), ("Hot leads", "5", ORANGE), ("Quotes sent", "8", GREEN), ("Pipeline", "£42K", PURPLE)]
        for idx, (label, value, color) in enumerate(metrics):
            row = idx // 2
            col = idx % 2
            bx = content_x + col * (content_w // 2 + 10)
            by = cy + row * 172
            draw_card(draw, (bx, by, bx + content_w // 2 - 10, by + 150), label, value, color)
        cy += 365
        draw_lead_row(draw, (content_x, cy, content_x + content_w, cy + 150), "Amelia Stone", "Landscape redesign", 91, "Hot")
        draw_lead_row(draw, (content_x, cy + 170, content_x + content_w, cy + 320), "Northgate Cafe", "Electrical inspection", 84, "Urgent", BLUE)
    elif screen == "leads":
        fields = ["Lead name", "Phone", "Email", "Service requested", "Budget range", "Location", "Urgency", "Source", "Notes"]
        for i, label in enumerate(fields):
            by = cy + i * 70
            rounded(draw, (content_x, by, content_x + content_w, by + 52), 12, (247, 249, 251), outline=LINE)
            draw.text((content_x + 18, by + 14), label, font=font(18), fill=MUTED)
        rounded(draw, (content_x, cy + 650, content_x + content_w, cy + 730), 16, BLUE)
        tw, _ = text_size(draw, "Save lead", font(24, "bold"))
        draw.text((content_x + content_w / 2 - tw / 2, cy + 674), "Save lead", font=font(24, "bold"), fill=WHITE)
    elif screen == "qualification":
        rounded(draw, (content_x, cy, content_x + content_w, cy + 210), 20, WHITE)
        draw.text((content_x + 28, cy + 26), "Lead quality score", font=font(28, "bold"), fill=INK)
        draw.text((content_x + 28, cy + 72), "High-value lead", font=font(22), fill=MUTED)
        draw.ellipse((content_x + content_w - 172, cy + 36, content_x + content_w - 42, cy + 166), fill=(224, 247, 240))
        draw.text((content_x + content_w - 142, cy + 78), "91", font=font(42, "bold"), fill=GREEN)
        draw_card(draw, (content_x, cy + 235, content_x + content_w // 2 - 10, cy + 390), "Project value", "£8,500", GREEN)
        draw_card(draw, (content_x + content_w // 2 + 10, cy + 235, content_x + content_w, cy + 390), "Likelihood", "91%", BLUE)
        rounded(draw, (content_x, cy + 420, content_x + content_w, cy + 665), 18, WHITE)
        draw.text((content_x + 26, cy + 446), "Recommended next action", font=font(25, "bold"), fill=INK)
        body = "Book a site visit and send a premium proposal with clear scope, options, timeline, and exclusions."
        for idx, line in enumerate(wrap(draw, body, font(21), content_w - 52)):
            draw.text((content_x + 26, cy + 494 + idx * 31), line, font=font(21), fill=MUTED)
    elif screen == "proposal":
        rounded(draw, (content_x, cy, content_x + content_w, cy + 680), 18, WHITE)
        draw.text((content_x + 26, cy + 24), "Landscape Proposal", font=font(28, "bold"), fill=INK)
        sections = ["Estimate summary", "Service breakdown", "Pricing structure", "Optional upsells", "Timeline estimate", "Exclusions"]
        yy = cy + 86
        for section in sections:
            draw.text((content_x + 26, yy), section, font=font(22, "bold"), fill=INK)
            draw.rounded_rectangle((content_x + 26, yy + 34, content_x + content_w - 26, yy + 52), radius=9, fill=(231, 237, 242))
            draw.rounded_rectangle((content_x + 26, yy + 62, content_x + content_w - 96, yy + 80), radius=9, fill=(231, 237, 242))
            yy += 96
        rounded(draw, (content_x, cy + 710, content_x + content_w, cy + 790), 16, GREEN)
        draw.text((content_x + 170, cy + 734), "Export PDF", font=font(25, "bold"), fill=WHITE)
    elif screen == "followup":
        rounded(draw, (content_x, cy, content_x + content_w, cy + 108), 18, WHITE)
        draw.text((content_x + 26, cy + 28), "Friendly WhatsApp-style", font=font(25, "bold"), fill=INK)
        rounded(draw, (content_x, cy + 140, content_x + content_w, cy + 420), 22, (225, 247, 240))
        msg = "Hi Amelia, just following up on your landscaping enquiry. I can send the next steps and estimate once we confirm a couple of details."
        for idx, line in enumerate(wrap(draw, msg, font(25), content_w - 64)):
            draw.text((content_x + 32, cy + 178 + idx * 36), line, font=font(25), fill=INK)
        rounded(draw, (content_x, cy + 465, content_x + content_w, cy + 545), 16, BLUE)
        draw.text((content_x + 138, cy + 489), "Save follow-up", font=font(25, "bold"), fill=WHITE)
    elif screen == "analytics":
        draw_chart(draw, (content_x, cy, content_x + content_w, cy + 320))
        metrics = [("Conversion", "42%", BLUE), ("Avg quote", "£3.4K", GREEN), ("Pipeline", "£42K", PURPLE), ("Follow-up", "76%", ORANGE)]
        for idx, (label, value, color) in enumerate(metrics):
            row = idx // 2
            col = idx % 2
            bx = content_x + col * (content_w // 2 + 10)
            by = cy + 348 + row * 160
            draw_card(draw, (bx, by, bx + content_w // 2 - 10, by + 138), label, value, color)

    draw_tab_bar(draw, x, y, w, h, "Dashboard" if screen == "dashboard" else "Analytics" if screen == "analytics" else "Leads")


def marketing_screenshot(size: tuple[int, int], filename: Path, headline: str, subtitle: str, screen: str):
    w, h = size
    img = gradient(size, (245, 250, 249), (231, 241, 247)).convert("RGBA")
    draw = ImageDraw.Draw(img)

    margin = int(w * 0.075)
    draw.text((margin, int(h * 0.055)), "LeadPilot IQ", font=font(int(w * 0.047), "bold"), fill=TEAL)
    headline_font = font(int(w * 0.071), "bold")
    sub_font = font(int(w * 0.03), "regular")
    y = int(h * 0.112)
    for line in wrap(draw, headline, headline_font, w - margin * 2):
        draw.text((margin, y), line, font=headline_font, fill=CHARCOAL)
        y += int(w * 0.085)
    y += int(w * 0.014)
    for line in wrap(draw, subtitle, sub_font, w - margin * 2):
        draw.text((margin, y), line, font=sub_font, fill=MUTED)
        y += int(w * 0.043)

    phone_w = int(w * 0.64)
    phone_h = int(phone_w * 2.05)
    if phone_h > int(h * 0.67):
        phone_h = int(h * 0.67)
        phone_w = int(phone_h / 2.05)
    px = int((w - phone_w) / 2)
    py = h - phone_h - int(h * 0.045)
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((px + 14, py + 22, px + phone_w + 14, py + phone_h + 22), radius=64, fill=(0, 33, 45, 42))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(radius=22)))
    draw = ImageDraw.Draw(img)
    draw_phone_ui(draw, (px, py, phone_w, phone_h), screen)
    filename.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(filename, quality=94, optimize=True)


SCREENSHOTS = [
    ("01-dashboard.png", "Prioritize high-value leads", "See hot enquiries, quotes sent, follow-ups, conversion, and pipeline value at a glance.", "dashboard"),
    ("02-lead-capture.png", "Capture every enquiry fast", "Add lead details, source, urgency, budget, notes, and photos in a mobile-first workflow.", "leads"),
    ("03-ai-qualification.png", "Score and qualify leads", "Mock AI mode generates lead scores, value estimates, likelihood, and recommended next actions.", "qualification"),
    ("04-proposals.png", "Draft polished proposals", "Generate editable quotes with pricing structure, upsells, exclusions, timeline, and PDF export.", "proposal"),
    ("05-followups.png", "Send better follow-ups", "Create SMS, email, WhatsApp-style, reminder, objection handling, and review request messages.", "followup"),
    ("06-analytics.png", "Track your sales pipeline", "Understand source performance, conversion, average quote value, and follow-up effectiveness.", "analytics"),
]


def make_screenshots():
    for name, headline, subtitle, screen in SCREENSHOTS:
        marketing_screenshot((1242, 2688), IPHONE / name, headline, subtitle, screen)
        marketing_screenshot((2064, 2752), IPAD / name, headline, subtitle, screen)


def make_readme():
    STORE.mkdir(parents=True, exist_ok=True)
    (STORE / "README.md").write_text(
        """# LeadPilot IQ App Store Assets

Generated production-ready raster assets for App Store Connect.

## Included

- `Icon/LeadPilotIQ-AppStoreIcon-1024.png` - 1024x1024 App Store icon.
- `Screenshots/iPhone-6.5/*.png` - 1242x2688 iPhone screenshots.
- `Screenshots/iPad-13/*.png` - 2064x2752 iPad screenshots.

## Upload order

1. Dashboard
2. Lead Capture
3. AI Qualification
4. Proposals
5. Follow-Ups
6. Analytics

Apple requires one to ten screenshots in PNG, JPG, or JPEG format. Because this target supports iPad, upload the iPad 13-inch set as well as the iPhone set.
""",
        encoding="utf-8",
    )


def main():
    make_icons()
    make_screenshots()
    make_readme()


if __name__ == "__main__":
    main()

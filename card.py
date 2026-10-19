"""يرسم بطاقة خبر 1080×1080 جاهزة للنشر على تلقرام وإنستقرام وتيك توك."""
import os
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

SIZE = 1080
PAD = 80
FONT_PATH = os.path.join(os.path.dirname(__file__), "fonts", "Cairo.ttf")

BG_TOP = (15, 23, 42)
BG_BOTTOM = (30, 41, 59)
TEXT = (248, 250, 252)
MUTED = (148, 163, 184)


def _font(size, weight="Bold"):
    f = ImageFont.truetype(FONT_PATH, size)
    f.set_variation_by_name(weight)
    return f


def _hex(color):
    color = color.lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))


def _wrap(draw, text, font, width):
    lines, line = [], ""
    for word in text.split():
        test = f"{line} {word}".strip()
        if draw.textlength(test, font=font, direction="rtl") <= width:
            line = test
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def _fit_title(draw, title, width, max_height):
    for size in (78, 70, 62, 56, 50, 44):
        font = _font(size)
        lines = _wrap(draw, title, font, width)
        line_h = int(size * 1.6)
        if len(lines) * line_h <= max_height:
            return font, lines, line_h
    font = _font(44)
    line_h = int(44 * 1.6)
    lines = _wrap(draw, title, font, width)[: max_height // line_h]
    lines[-1] += " …"
    return font, lines, line_h


def make_card(title, source, out_path, brand="", accent="#ef4444"):
    accent = _hex(accent)
    img = Image.new("RGB", (SIZE, SIZE), BG_TOP)
    draw = ImageDraw.Draw(img)

    for y in range(SIZE):
        t = y / SIZE
        c = tuple(int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        draw.line([(0, y), (SIZE, y)], fill=c)

    draw.rectangle([0, 0, SIZE, 14], fill=accent)

    # شارة "عاجل" ومصدر الخبر
    badge_font = _font(34)
    badge = "عاجل"
    bw = draw.textlength(badge, font=badge_font, direction="rtl") + 56
    draw.rounded_rectangle([SIZE - PAD - bw, 90, SIZE - PAD, 160], radius=14, fill=accent)
    draw.text((SIZE - PAD - 28, 125), badge, font=badge_font, fill=TEXT, anchor="rm", direction="rtl")
    draw.text((SIZE - PAD - bw - 28, 125), source, font=_font(34, "SemiBold"),
              fill=MUTED, anchor="rm", direction="rtl")

    # العنوان
    top, bottom = 230, SIZE - 200
    font, lines, line_h = _fit_title(draw, title, SIZE - 2 * PAD, bottom - top)
    y = top + ((bottom - top) - len(lines) * line_h) // 2
    for line in lines:
        draw.text((SIZE - PAD, y + line_h // 2), line, font=font, fill=TEXT, anchor="rm", direction="rtl")
        y += line_h

    # الفوتر: اسم البراند والتاريخ
    draw.line([(PAD, SIZE - 150), (SIZE - PAD, SIZE - 150)], fill=(51, 65, 85), width=2)
    if brand:
        draw.text((SIZE - PAD, SIZE - 95), brand, font=_font(38), fill=accent, anchor="rm",
                  direction="ltr" if brand.isascii() else "rtl")
    draw.text((PAD, SIZE - 95), datetime.now().strftime("%Y/%m/%d"), font=_font(32, "Medium"),
              fill=MUTED, anchor="lm")

    img.save(out_path, "PNG", optimize=True)
    return out_path

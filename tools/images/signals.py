"""Sound signals, sign boards (Tafelzeichen), light panels and flags."""

from __future__ import annotations

import itertools
import math

from svg import (BLACK, BLUE, GREEN, GREY, LIGHT_GREEN, LIGHT_RED, NIGHT, RED,
                 SIGN_BLUE, WATER, WHITE, YELLOW, Canvas, rot, sub)

_ids = itertools.count(1)


def _uid(prefix="c"):
    return f"{prefix}{next(_ids)}"


# ─────────────────────────────────────────────────────────────────────────────
# Sound signals
# ─────────────────────────────────────────────────────────────────────────────

DOT_R = 32
DASH_W, DASH_H = 120, 26
GAP = 40


def _row_width(row: str) -> float:
    w = 0.0
    for ch in row:
        if ch == ".":
            w += DOT_R * 2 + GAP
        elif ch == "-":
            w += DASH_W + GAP
        elif ch == " ":
            w += GAP * 2.2
    return w - GAP if w else 0


def _draw_row(c: Canvas, x: float, y: float, row: str):
    for ch in row:
        if ch == ".":
            c.circle(x + DOT_R, y, DOT_R, fill=BLACK)
            x += DOT_R * 2 + GAP
        elif ch == "-":
            c.rect(x, y - DASH_H / 2, DASH_W, DASH_H, fill=BLACK, rx=3)
            x += DASH_W + GAP
        elif ch == " ":
            x += GAP * 2.2


def _bracket(c: Canvas, x: float, cy: float, h: float, opening: str):
    bulge = 20 if opening == "(" else -20
    d = f"M {x + bulge / 2} {cy - h / 2} Q {x - bulge / 2} {cy} {x + bulge / 2} {cy + h / 2}"
    c.path(d, fill="none", stroke=BLACK, sw=10)


def sound_signal(*rows: str, brackets: bool = True) -> Canvas:
    """Render dots (short blast) / dashes (prolonged blast).

    ``rows`` are strings of ``.``, ``-`` and spaces; several rows stack
    vertically (used for long repeated signals).
    """
    widths = [_row_width(r) for r in rows]
    inner_w = max(widths)
    pad = 60 if brackets else 30
    row_h = 90
    w = inner_w + pad * 2
    h = max(220, row_h * len(rows) + 120)
    c = Canvas(w, h)
    top = (h - row_h * (len(rows) - 1)) / 2
    for i, r in enumerate(rows):
        # first row left-aligned after the bracket, last row right-aligned
        x = pad if i == 0 or len(rows) == 1 else pad + (inner_w - widths[i])
        _draw_row(c, x, top + i * row_h, r)
    if brackets:
        bh = row_h * (len(rows) - 1) + 110
        _bracket(c, 22, h / 2, bh, "(")
        _bracket(c, w - 22, h / 2, bh, ")")
    return c


def bell_signal() -> Canvas:
    """Bell rung rapidly for about 5 seconds (fog signal at anchor)."""
    c = Canvas(500, 500)
    c.text(250, 110, "5 s", size=96, weight="600")
    # bell body
    c.path("M 250 170 C 205 170 190 215 188 260 C 186 310 170 345 140 375 "
           "L 360 375 C 330 345 314 310 312 260 C 310 215 295 170 250 170 Z", fill=BLACK)
    c.circle(250, 165, 14, fill="none", stroke=BLACK, sw=8)
    c.ellipse(250, 395, 26, 18, fill=BLACK)
    # sound waves
    for i, r in enumerate((60, 95, 130)):
        a0, a1 = math.radians(-35), math.radians(35)
        cx, cy = 300, 330
        x0, y0 = cx + r * math.cos(a0), cy + r * math.sin(a0)
        x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
        c.path(f"M {x0} {y0} A {r} {r} 0 0 1 {x1} {y1}", fill="none", stroke=BLACK, sw=9,
               stroke_dasharray="4 14" if i else None)
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Sign boards
# ─────────────────────────────────────────────────────────────────────────────

def board(c: Canvas, x, y, w, h, border=RED, inner=WHITE, bw=None):
    bw = bw if bw is not None else min(w, h) * 0.13
    c.rect(x, y, w, h, fill=border, rx=4)
    c.rect(x + bw, y + bw, w - 2 * bw, h - 2 * bw, fill=inner)
    return (x + bw, y + bw, w - 2 * bw, h - 2 * bw)


def prohibition_stripe(c: Canvas, inner, width_frac=0.16, color=RED):
    """Diagonal red bar from top-left to bottom-right, clipped to the board."""
    x, y, w, h = inner
    cid = _uid("clip")
    c.raw(f'<defs><clipPath id="{cid}"><rect x="{x}" y="{y}" width="{w}" height="{h}"/></clipPath></defs>')
    sw = math.hypot(w, h) * width_frac
    c.raw(f'<g clip-path="url(#{cid})"><line x1="{x - 10}" y1="{y - 10}" x2="{x + w + 10}" y2="{y + h + 10}" '
          f'stroke="{color}" stroke-width="{sw:.1f}"/></g>')


def arrow(c: Canvas, cx, tip_y, length, shaft=26, head_w=86, head_h=70, down=False, color=BLACK):
    s = -1 if down else 1
    base_y = tip_y + s * length
    neck_y = tip_y + s * head_h
    c.rect(cx - shaft / 2, min(neck_y, base_y), shaft, abs(base_y - neck_y), fill=color, rx=shaft / 2.5)
    c.poly([(cx, tip_y), (cx - head_w / 2, neck_y), (cx + head_w / 2, neck_y)], fill=color)


def h_arrow(c: Canvas, tip_x, cy, length, shaft=34, head_w=120, head_h=110, left=True, color=BLACK):
    s = 1 if left else -1
    neck = tip_x + s * head_h
    end = tip_x + s * length
    c.rect(min(neck, end) - 4, cy - shaft / 2, abs(end - neck) + 4, shaft, fill=color, rx=shaft / 2)
    c.poly([(tip_x, cy), (neck, cy - head_w / 2), (neck, cy + head_w / 2)], fill=color)


def sign_overtaking_prohibited() -> Canvas:
    c = Canvas(400, 600, bg=None)
    inner = board(c, 0, 0, 400, 600)
    prohibition_stripe(c, inner)
    arrow(c, 135, 300, 225, shaft=46, head_w=124, head_h=96)
    arrow(c, 265, 80, 225, shaft=46, head_w=124, head_h=96)
    return c


def sign_no_meeting() -> Canvas:
    c = Canvas(400, 600, bg=None)
    inner = board(c, 0, 0, 400, 600)
    prohibition_stripe(c, inner)
    arrow(c, 140, 505, 410, down=True, shaft=40, head_w=104, head_h=92)
    arrow(c, 262, 95, 410, shaft=40, head_w=104, head_h=92)
    return c


def sign_avoid_wash() -> Canvas:
    c = Canvas(560, 560, bg=None)
    inner = board(c, 0, 0, 560, 560)
    prohibition_stripe(c, inner)
    for y in (225, 345):
        c.path(f"M 105 {y + 18} C 160 {y - 30} 250 {y - 34} 300 {y - 4} C 350 {y + 24} 410 {y + 10} 455 {y - 22}",
               fill="none", stroke=BLACK, sw=44, cap="butt")
    return c


def sign_min_distance(meters="40") -> Canvas:
    c = Canvas(700, 460, bg=None)
    x, y, w, h = board(c, 0, 0, 700, 460)
    c.poly([(x + 45, y + h / 2), (x + 200, y + 25), (x + w - 25, y + 25), (x + w - 25, y + h - 25), (x + 200, y + h - 25)],
           fill=BLACK)
    c.text(x + w / 2 + 70, y + h / 2 + 70, meters, size=210, fill=WHITE, weight="400")
    return c


def sign_symbol_board(symbol: str, w=560, h=560) -> Canvas:
    """Mandatory/info board with a simple black symbol."""
    c = Canvas(w, h, bg=None)
    x, y, iw, ih = board(c, 0, 0, w, h)
    cx, cy = x + iw / 2, y + ih / 2
    if symbol == "hbar":
        c.rect(cx - 125, cy - 32, 250, 64, fill=BLACK, rx=32)
    elif symbol == "vbar":
        c.rect(cx - 30, cy - 125, 60, 250, fill=BLACK, rx=30)
    elif symbol == "dot":
        c.circle(cx, cy, 90, fill=BLACK)
    elif symbol.isdigit():
        c.text(cx, cy + 0.27 * ih, symbol, size=ih * 0.78, weight="800", letter_spacing="-8")
    return c


def sign_long_blast() -> Canvas:
    """Sound a prolonged blast: dot board + supplementary plate with a dash."""
    c = Canvas(400, 560, bg=None)
    x, y, w, h = board(c, 0, 0, 400, 400)
    c.circle(x + w / 2, y + h / 2, 82, fill=BLACK)
    c.rect(2, 410, 396, 148, fill=WHITE, stroke=BLACK, sw=4)
    c.rect(70, 470, 260, 30, fill=BLACK)
    return c


def sign_no_anchoring() -> Canvas:
    c = Canvas(400, 600, bg=None)
    inner = board(c, 0, 0, 400, 600)
    prohibition_stripe(c, inner)
    cx = 200
    # Anchor drawn crown-up (as on the official sign)
    c.line(cx, 160, cx, 470, sw=40, cap="butt")
    c.path(f"M {cx - 120} 235 Q {cx - 110} 135 {cx} 140 Q {cx + 110} 135 {cx + 120} 235",
           fill="none", stroke=BLACK, sw=40, cap="butt")
    c.poly([(cx - 140, 215), (cx - 98, 215), (cx - 122, 268)], fill=BLACK)
    c.poly([(cx + 140, 215), (cx + 98, 215), (cx + 122, 268)], fill=BLACK)
    c.rect(cx - 52, 420, 104, 24, fill=BLACK, rx=6)
    c.circle(cx, 495, 26, fill="none", stroke=BLACK, sw=14)
    return c


def sign_no_mooring() -> Canvas:
    c = Canvas(560, 560, bg=None)
    inner = board(c, 0, 0, 560, 560)
    prohibition_stripe(c, inner)
    cx = 290
    c.rect(150, 400, 270, 70, fill=BLACK, rx=6)                      # base
    c.path(f"M {cx - 70} 400 L {cx - 55} 250 L {cx + 55} 250 L {cx + 70} 400 Z", fill=BLACK)
    c.path(f"M {cx - 95} 250 Q {cx - 100} 145 {cx} 140 Q {cx + 100} 145 {cx + 95} 250 Z", fill=BLACK)
    c.rect(cx - 105, 232, 210, 30, fill=BLACK, rx=10)
    c.line(95, 300, 475, 285, sw=28, cap="round")                    # mooring line
    return c


def sign_no_motor() -> Canvas:
    c = Canvas(560, 560, bg=None)
    inner = board(c, 0, 0, 560, 560)
    prohibition_stripe(c, inner)
    cx, cy = 290, 280
    blade = sub()
    blade.path(f"M {cx - 16} {cy} C {cx - 85} {cy - 70} {cx - 60} {cy - 190} {cx + 10} {cy - 196} "
               f"C {cx + 80} {cy - 196} {cx + 66} {cy - 80} {cx + 16} {cy} Z", fill=BLACK)
    for a in (35, 155, 275):
        c.group(blade, f"rotate({a} {cx} {cy})")
    c.circle(cx, cy, 48, fill=BLACK)
    return c


def sign_no_turning(prohibited=True) -> Canvas:
    c = Canvas(560, 560, bg=None)
    if prohibited:
        inner = board(c, 0, 0, 560, 560)
        prohibition_stripe(c, inner)
        col = BLACK
    else:
        c.rect(0, 0, 560, 560, fill=SIGN_BLUE, rx=4)
        col = WHITE
    cx, cy, r = 280, 290, 150

    def pt(rr, deg):
        a = math.radians(deg)
        return cx + rr * math.cos(a), cy + rr * math.sin(a)

    x0, y0 = pt(r, 100)
    x1, y1 = pt(r, -25)
    c.path(f"M {x0} {y0} A {r} {r} 0 1 1 {x1} {y1}", fill="none", stroke=col, sw=36, cap="butt")
    hx, hy = pt(r, -10)
    c.poly(rot([(hx - 45, hy - 40), (hx + 45, hy - 40), (hx, hy + 30)], -10, hx, hy), fill=col)
    ri = 72
    x0, y0 = pt(ri, 60)
    x1, y1 = pt(ri, -150)
    c.path(f"M {x0} {y0} A {ri} {ri} 0 1 0 {x1} {y1}", fill="none", stroke=col, sw=28, cap="butt")
    ax, ay = pt(ri, -150)
    c.poly([(ax - 40, ay + 8), (ax + 25, ay - 38), (ax + 25, ay + 45)], fill=col)
    return c


def sign_closed() -> Canvas:
    c = Canvas(700, 480, bg=None)
    c.rect(0, 0, 700, 480, fill=RED, rx=4)
    c.rect(18, 160, 664, 160, fill=WHITE)
    return c


def sign_no_entry_round() -> Canvas:
    c = Canvas(560, 560, bg=None)
    c.circle(280, 280, 278, fill=RED)
    c.rect(40, 245, 480, 70, fill=WHITE)
    return c


def sign_end_of_restriction() -> Canvas:
    c = Canvas(400, 600, bg=None)
    c.rect(0, 0, 400, 600, fill=SIGN_BLUE, rx=4)
    cid = _uid("clip")
    c.raw(f'<defs><clipPath id="{cid}"><rect width="400" height="600"/></clipPath></defs>')
    c.raw(f'<g clip-path="url(#{cid})"><line x1="0" y1="0" x2="400" y2="600" stroke="{WHITE}" stroke-width="44"/></g>')
    return c


def sign_direction(left=True) -> Canvas:
    c = Canvas(760, 500, bg=None)
    x, y, w, h = board(c, 0, 0, 760, 500)
    h_arrow(c, x + 60, y + h / 2, w - 130, shaft=70, head_w=210, head_h=190, left=left)
    return c


def sign_blue(symbol: str) -> Canvas:
    c = Canvas(560, 560, bg=None)
    c.rect(0, 0, 560, 560, fill=SIGN_BLUE, rx=4)
    if symbol == "diamond":
        c.poly([(280, 110), (450, 280), (280, 450), (110, 280)], fill=WHITE)
    elif symbol == "berth_explosive":
        c.poly([(280, 90), (470, 450), (90, 450)], fill=WHITE)
        for i in range(3):
            y = 220 + i * 70
            c.poly([(236, y), (324, y), (280, y + 56)], fill=SIGN_BLUE)
    elif symbol == "weir":
        c.rect(20, 140, 520, 330, fill=WHITE)
        c.rect(20, 110, 60, 60, fill=WHITE)
        c.rect(480, 110, 60, 60, fill=WHITE)
        c.rect(80, 110, 400, 70, fill=SIGN_BLUE)
        for i in range(5):
            c.rect(62 + i * 92, 225, 60, 175, fill=SIGN_BLUE)
    elif symbol == "waterski":
        _waterskier(c)
    elif symbol == "jetski":
        _jetski(c)
    return c


def _waterskier(c: Canvas):
    c.circle(370, 140, 34, fill=WHITE)
    c.polyline([(345, 185), (300, 300), (250, 400)], stroke=WHITE, sw=46)        # torso + leg
    c.polyline([(300, 300), (340, 360), (300, 420)], stroke=WHITE, sw=40)        # bent leg
    c.polyline([(340, 205), (250, 225), (215, 220)], stroke=WHITE, sw=26)        # arms
    c.line(70, 210, 215, 220, stroke=WHITE, sw=7)                                # tow rope
    c.line(150, 445, 430, 455, stroke=WHITE, sw=16)                              # ski
    c.path("M 150 445 Q 130 440 120 420", fill="none", stroke=WHITE, sw=16)


def _jetski(c: Canvas):
    c.path("M 90 410 L 470 410 Q 480 360 430 350 L 300 345 L 250 300 L 180 300 L 150 350 L 110 360 Q 80 375 90 410 Z",
           fill=WHITE)
    c.circle(250, 150, 32, fill=WHITE)
    c.polyline([(245, 190), (215, 290)], stroke=WHITE, sw=44)
    c.polyline([(240, 210), (310, 255), (330, 300)], stroke=WHITE, sw=24)
    c.polyline([(215, 290), (275, 300), (285, 345)], stroke=WHITE, sw=30)
    for i in range(3):
        c.path(f"M {60 + i * 140} 455 q 35 -22 70 0 t 70 0", fill="none", stroke=WHITE, sw=10)


def diamond(c: Canvas, cx, cy, r, fill=YELLOW, stroke=None, sw=None, split=None):
    """Diamond (rhombus). ``split`` = ('left'|'right', colour) paints half."""
    pts = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
    c.poly(pts, fill=WHITE if split else fill, stroke=None)
    if split:
        side, col = split
        half = [(cx, cy - r), (cx, cy + r), (cx - r, cy)] if side == "left" else [(cx, cy - r), (cx + r, cy), (cx, cy + r)]
        c.poly(half, fill=col)
    c.poly(pts, fill="none", stroke=stroke or "#333", sw=sw or 4)


def yellow_diamonds(layout: str) -> Canvas:
    if layout == "one":
        c = Canvas(560, 560)
        diamond(c, 280, 280, 240, stroke="#C9A800", sw=6)
    elif layout == "two":
        c = Canvas(900, 480)
        diamond(c, 225, 240, 200, stroke="#C9A800", sw=6)
        diamond(c, 675, 240, 200, stroke="#C9A800", sw=6)
    else:  # "two_or"
        c = Canvas(1000, 520)
        diamond(c, 110, 260, 85, stroke="#C9A800", sw=5)
        diamond(c, 300, 260, 85, stroke="#C9A800", sw=5)
        c.text(560, 280, "oder", size=56, weight="500")
        diamond(c, 860, 160, 85, stroke="#C9A800", sw=5)
        diamond(c, 860, 360, 85, stroke="#C9A800", sw=5)
    return c


def passage_marks(color: str) -> Canvas:
    """Two half-coloured diamonds on posts with a dashed double arrow (passage only between the boards)."""
    c = Canvas(1000, 640)
    left_split = ("left", color) if color == RED else ("right", color)
    right_split = ("right", color) if color == RED else ("left", color)
    for cx, sp in ((180, left_split), (820, right_split)):
        diamond(c, cx, 170, 140, split=sp, stroke=BLACK, sw=5)
        c.line(cx, 310, cx, 600, sw=6, dash="18 14", cap="butt")
    c.line(250, 500, 750, 500, sw=6, dash="22 16", cap="butt")
    c.poly([(195, 500), (265, 470), (265, 530)], fill=BLACK)
    c.poly([(805, 500), (735, 470), (735, 530)], fill=BLACK)
    return c


def bridge_scene(marks: list[tuple[float, str]]) -> Canvas:
    """Truss bridge over water; marks = [(x_frac, kind)] kind in yellow|redwhite_l|redwhite_r."""
    c = Canvas(1200, 600, bg=WATER)
    c.rect(0, 0, 1200, 140, fill=WHITE)
    top, bot = 150, 260
    c.line(0, top, 1200, top, sw=8)
    c.line(0, bot, 1200, bot, sw=8)
    xs = list(range(0, 1201, 120))
    for i in range(len(xs) - 1):
        c.line(xs[i], bot, xs[i] + 60, top, sw=6)
        c.line(xs[i] + 60, top, xs[i + 1], bot, sw=6)
    for px in (220, 980):
        c.poly([(px - 55, bot + 20), (px + 55, bot + 20), (px + 75, 545), (px - 75, 545)], fill=WHITE, stroke=BLACK, sw=6)
        c.rect(px - 70, bot + 4, 140, 22, fill=WHITE, stroke=BLACK, sw=6)
    for y in (540, 565):
        c.path(" ".join([f"M 0 {y}"] + [f"q 25 -14 50 0 t 50 0" for _ in range(12)]), fill="none", stroke=BLUE, sw=5)
    for frac, kind in marks:
        x = 1200 * frac
        if kind == "yellow":
            diamond(c, x, bot, 52, fill=YELLOW, stroke="#8B7600", sw=4)
        elif kind == "redwhite_l":
            diamond(c, x, bot, 52, split=("left", RED), stroke=BLACK, sw=4)
        elif kind == "redwhite_r":
            diamond(c, x, bot, 52, split=("right", RED), stroke=BLACK, sw=4)
    return c


def entry_prohibited_chevron() -> Canvas:
    c = Canvas(700, 600)
    c.circle(230, 300, 105, fill=LIGHT_RED)
    c.poly([(330, 40), (650, 300), (330, 560), (360, 590), (690, 300), (360, 10)], fill=WHITE, stroke=BLACK, sw=10)
    return c


def lights_pair(color, vertical=False) -> Canvas:
    fill = LIGHT_RED if color == "red" else LIGHT_GREEN
    if vertical:
        c = Canvas(400, 640)
        pos = [(200, 150), (200, 490)]
    else:
        c = Canvas(900, 420)
        pos = [(220, 210), (680, 210)]
    for x, y in pos:
        c.circle(x, y, 120, fill=fill, stroke="#4A2A2A", sw=10)
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Night light panels
# ─────────────────────────────────────────────────────────────────────────────

LIGHT_COLORS = {"w": WHITE, "r": LIGHT_RED, "g": LIGHT_GREEN}


def light_panel(items, w=1200, h=760) -> Canvas:
    """items: (kind, colour, x, y) with kind 'sq' (square) or 'ci' (circle); coords 0..1."""
    c = Canvas(w, h, bg=NIGHT)
    s = min(w, h) * 0.15
    for kind, col, fx, fy in items:
        x, y = fx * w, fy * h
        fill = LIGHT_COLORS[col]
        if kind == "sq":
            c.rect(x - s / 2, y - s / 2, s, s, fill=fill, rx=4)
        else:
            c.circle(x, y, s * 0.55, fill=fill)
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Flags
# ─────────────────────────────────────────────────────────────────────────────

def flag_L() -> Canvas:
    c = Canvas(700, 620)
    c.rect(60, 40, 34, 560, fill=WHITE, stroke=BLACK, sw=5)
    c.path("M 50 48 Q 77 6 104 48 Z", fill=WHITE, stroke=BLACK, sw=5)
    x, y, w, h = 94, 90, 540, 400
    c.rect(x, y, w / 2, h / 2, fill=YELLOW)
    c.rect(x + w / 2, y, w / 2, h / 2, fill=BLACK)
    c.rect(x, y + h / 2, w / 2, h / 2, fill=BLACK)
    c.rect(x + w / 2, y + h / 2, w / 2, h / 2, fill=YELLOW)
    c.rect(x, y, w, h, fill="none", stroke=BLACK, sw=4)
    return c


def _flag_N(c: Canvas, x, y, w, h):
    n = 4
    for i in range(n):
        for j in range(n):
            c.rect(x + j * w / n, y + i * h / n, w / n, h / n, fill=BLUE if (i + j) % 2 == 0 else WHITE)
    c.rect(x, y, w, h, fill="none", stroke=BLACK, sw=3)


def _flag_C(c: Canvas, x, y, w, h):
    cols = [BLUE, WHITE, RED, WHITE, BLUE]
    for i, col in enumerate(cols):
        c.rect(x, y + i * h / 5, w, h / 5, fill=col)
    c.rect(x, y, w, h, fill="none", stroke=BLACK, sw=3)


def flags_NC() -> Canvas:
    """Distress signal N over C hoisted on a mast."""
    c = Canvas(560, 760)
    c.path("M 150 40 L 175 40 L 210 740 L 120 740 Z", fill=WHITE, stroke=BLACK, sw=5)
    c.line(150, 36, 300, 36, sw=8)
    c.line(175, 60, 250, 70, sw=3)
    _flag_N(c, 250, 70, 240, 200)
    c.line(250, 270, 250, 300, sw=3)
    _flag_C(c, 250, 300, 240, 200)
    return c


def flag_and_ball() -> Canvas:
    """Distress: square flag having above or below it a ball (two variants)."""
    c = Canvas(1000, 760)
    for ox, ball_above in ((0, True), (500, False)):
        c.path(f"M {ox + 150} 40 L {ox + 172} 40 L {ox + 205} 740 L {ox + 120} 740 Z", fill=WHITE, stroke=BLACK, sw=5)
        if ball_above:
            c.line(ox + 172, 60, ox + 172, 420, sw=3)
            c.circle(ox + 225, 230, 62, fill=BLACK)
            c.rect(ox + 205, 330, 230, 190, fill="#555", stroke=BLACK, sw=3)
        else:
            c.rect(ox + 205, 120, 230, 190, fill="#555", stroke=BLACK, sw=3)
            c.line(ox + 172, 60, ox + 172, 540, sw=3)
            c.circle(ox + 225, 470, 62, fill=BLACK)
    return c


def morse_sos() -> Canvas:
    return sound_signal("...---...")

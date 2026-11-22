"""Buoys and beacons, light rhythms, weather charts and signal masts (SBF See)."""

from __future__ import annotations

import math

from svg import BLACK, GREEN, GREY, RED, WHITE, YELLOW, Canvas, FONT
from vessels import ball, cone

# bands: list of (from, to, colour) measured bottom→top as fractions of the body height

TOPMARK = 50   # topmark size (px at scale 1)


def _banded_rect(c: Canvas, x, y_bottom, w, h, bands, stroke=BLACK):
    for f0, f1, col in bands:
        c.rect(x - w / 2, y_bottom - f1 * h, w, (f1 - f0) * h, fill=col)
    c.rect(x - w / 2, y_bottom - h, w, h, fill="none", stroke=stroke, sw=3)


def _clip_banded(c: Canvas, shape_d: str, x, y_bottom, w, h, bands, cid):
    c.raw(f'<defs><clipPath id="{cid}"><path d="{shape_d}"/></clipPath></defs>')
    c.raw(f'<g clip-path="url(#{cid})">')
    for f0, f1, col in bands:
        c.rect(x - w, y_bottom - f1 * h - 1, w * 2, (f1 - f0) * h + 2, fill=col)
    c.raw("</g>")
    c.path(shape_d, fill="none", stroke=BLACK, sw=3)


_cid = [0]


def _next(prefix):
    _cid[0] += 1
    return f"{prefix}{_cid[0]}"


def topmark(c: Canvas, x, y, kind, s=26, color=BLACK, parens=False):
    """Draw a topmark whose *bottom* sits at y. Returns the top y."""
    if kind == "cones_N":
        cone(c, x, y - s * 0.9, s, down=False, fill=color)
        cone(c, x, y - s * 2.8, s, down=False, fill=color)
        c.line(x, y, x, y - s * 3.7, sw=3)
        top = y - s * 3.7
    elif kind == "cones_S":
        cone(c, x, y - s * 0.9, s, down=True, fill=color)
        cone(c, x, y - s * 2.8, s, down=True, fill=color)
        c.line(x, y, x, y - s * 3.7, sw=3)
        top = y - s * 3.7
    elif kind == "cones_E":
        cone(c, x, y - s * 0.9, s, down=True, fill=color)
        cone(c, x, y - s * 2.95, s, down=False, fill=color)
        c.line(x, y, x, y - s * 3.85, sw=3)
        top = y - s * 3.85
    elif kind == "cones_W":
        cone(c, x, y - s * 0.9, s, down=False, fill=color)
        cone(c, x, y - s * 2.6, s, down=True, fill=color)
        c.line(x, y, x, y - s * 3.5, sw=3)
        top = y - s * 3.5
    elif kind == "cone_up":
        c.line(x, y, x, y - s * 0.6, sw=3)
        cone(c, x, y - s * 1.45, s * 1.15, down=False, fill=color)
        top = y - s * 2.4
    elif kind == "cyl":
        c.line(x, y, x, y - s * 0.6, sw=3)
        c.rect(x - s * 0.95, y - s * 2.6, s * 1.9, s * 2.0, fill=color, stroke=BLACK, sw=2)
        top = y - s * 2.6
    elif kind == "ball":
        c.line(x, y, x, y - s * 0.6, sw=3)
        ball(c, x, y - s * 1.6, r=s, fill=color)
        top = y - s * 2.6
    elif kind == "two_balls":
        c.line(x, y, x, y - s * 3.6, sw=3)
        ball(c, x, y - s * 1.3, r=s, fill=color)
        ball(c, x, y - s * 3.4, r=s, fill=color)
        top = y - s * 4.4
    elif kind == "x":
        c.line(x, y, x, y - s * 0.5, sw=3)
        cx, cy = x, y - s * 1.5
        for a, b in (((-1, -1), (1, 1)), ((-1, 1), (1, -1))):
            c.line(cx + a[0] * s, cy + a[1] * s, cx + b[0] * s, cy + b[1] * s, stroke=BLACK, sw=s * 0.62)
            c.line(cx + a[0] * s, cy + a[1] * s, cx + b[0] * s, cy + b[1] * s, stroke=YELLOW, sw=s * 0.42)
        top = y - s * 2.5
    else:
        top = y
    if parens:
        h = y - top
        my = (y + top) / 2
        for side in (-1, 1):
            px = x + side * (s * 1.7)
            c.path(f"M {px} {my - h * 0.55} Q {px + side * s * 0.45} {my} {px} {my + h * 0.55}", fill="none",
                   stroke=BLACK, sw=5)
    return top


def light_float(c: Canvas, x, y, bands, mark=None, parens=False, scale=1.0, label=None, mark_color=BLACK,
                vstripes=None):
    """Light float: buoyant base + lattice tower + gallery + topmark.

    ``vstripes`` (list of colours) paints vertical stripes instead of ``bands``.
    """
    s = scale
    bw, bh = 230 * s, 70 * s
    base = (f"M {x - bw / 2} {y} L {x - bw / 2} {y - bh * 0.55} Q {x - bw / 2} {y - bh} {x - bw * 0.25} {y - bh} "
            f"L {x + bw * 0.25} {y - bh} Q {x + bw / 2} {y - bh} {x + bw / 2} {y - bh * 0.55} L {x + bw / 2} {y} Z")
    tw, th = 74 * s, 250 * s
    total_h = bh + th
    # colour the base and tower with the same bands (bottom → top over total height)
    cid = _next("lf")
    tower = f"M {x - tw / 2} {y - bh} L {x - tw * 0.4} {y - total_h} L {x + tw * 0.4} {y - total_h} L {x + tw / 2} {y - bh} Z"
    c.raw(f'<defs><clipPath id="{cid}"><path d="{base} {tower}"/></clipPath></defs><g clip-path="url(#{cid})">')
    if vstripes:
        n = 7
        sw_ = bw / n
        for i in range(n):
            c.rect(x - bw / 2 + i * sw_, y - total_h - 2, sw_ + 0.5, total_h + 4, fill=vstripes[i % len(vstripes)])
    else:
        for f0, f1, col in bands:
            c.rect(x - bw, y - f1 * total_h - 1, bw * 2, (f1 - f0) * total_h + 2, fill=col)
    c.raw("</g>")
    c.path(base, fill="none", stroke=BLACK, sw=3)
    # lattice: white bracing on top of the coloured tower
    c.path(tower, fill="none", stroke=BLACK, sw=3)
    n = 4
    for i in range(n):
        y0 = y - bh - th * i / n
        y1 = y - bh - th * (i + 1) / n
        w0 = tw * (0.5 - 0.1 * i / n)
        w1 = tw * (0.5 - 0.1 * (i + 1) / n)
        c.line(x - w0 + 12 * s, y0, x + w1 - 12 * s, y1, stroke=WHITE, sw=7 * s)
        c.line(x + w0 - 12 * s, y0, x - w1 + 12 * s, y1, stroke=WHITE, sw=7 * s)
        c.line(x - w0 + 12 * s, y0, x - w1 + 12 * s, y1, stroke=WHITE, sw=5 * s)
        c.line(x + w0 - 12 * s, y0, x + w1 - 12 * s, y1, stroke=WHITE, sw=5 * s)
    # gallery
    gy = y - total_h
    c.rect(x - tw * 0.6, gy - 14 * s, tw * 1.2, 14 * s, fill=WHITE, stroke=BLACK, sw=3)
    c.rect(x - tw * 0.25, gy - 40 * s, tw * 0.5, 26 * s, fill=WHITE, stroke=BLACK, sw=3)
    if label:
        lines = label.split("\n")
        for i, t in enumerate(lines):
            c.text(x, y - bh * 0.62 + i * 30 * s, t, size=28 * s, fill=BLACK, weight="700",
                   text_decoration="underline" if i == 0 else None)
    if mark:
        topmark(c, x, gy - 40 * s, mark, s=TOPMARK * s, parens=parens, color=mark_color)


def pillar(c: Canvas, x, y, bands, mark=None, scale=1.0, mark_color=BLACK, parens=False):
    """Pillar / beacon buoy (pointed body with vertical slots)."""
    s = scale
    w, h = 150 * s, 300 * s
    d = (f"M {x - w / 2} {y} C {x - w / 2} {y - h * 0.55} {x - w * 0.18} {y - h * 0.9} {x} {y - h} "
         f"C {x + w * 0.18} {y - h * 0.9} {x + w / 2} {y - h * 0.55} {x + w / 2} {y} Z")
    _clip_banded(c, d, x, y, w, h, bands, _next("pl"))
    for dx in (-0.22, 0, 0.22):
        c.path(f"M {x + dx * w} {y} L {x + dx * w} {y - h * 0.45} Q {x + dx * w * 0.6} {y - h * 0.75} {x} {y - h * 0.95}",
               fill="none", stroke=WHITE, sw=9 * s)
    if mark:
        topmark(c, x, y - h, mark, s=TOPMARK * s, color=mark_color, parens=parens)


def spar_on_block(c: Canvas, x, y, bands, mark=None, scale=1.0, mark_color=BLACK, parens=False):
    s = scale
    c.rect(x - 60 * s, y - 70 * s, 120 * s, 70 * s, fill=bands[0][2], stroke=BLACK, sw=3)
    _banded_rect(c, x, y - 70 * s, 34 * s, 230 * s, bands)
    if mark:
        topmark(c, x, y - 300 * s, mark, s=TOPMARK * s, color=mark_color, parens=parens)


def spar(c: Canvas, x, y, bands, mark=None, scale=1.0, mark_color=BLACK, parens=False):
    s = scale
    _banded_rect(c, x, y, 26 * s, 300 * s, bands)
    if mark:
        topmark(c, x, y - 300 * s, mark, s=TOPMARK * s, color=mark_color, parens=parens)


def conical_buoy(c: Canvas, x, y, color=GREEN, scale=1.0):
    s = scale
    c.path(f"M {x - 85 * s} {y} C {x - 85 * s} {y - 110 * s} {x - 30 * s} {y - 170 * s} {x} {y - 190 * s} "
           f"C {x + 30 * s} {y - 170 * s} {x + 85 * s} {y - 110 * s} {x + 85 * s} {y} Z", fill=color, stroke=BLACK, sw=3)


def can_buoy(c: Canvas, x, y, color=RED, scale=1.0):
    s = scale
    c.path(f"M {x - 75 * s} {y} L {x - 65 * s} {y - 120 * s} Q {x} {y - 135 * s} {x + 65 * s} {y - 120 * s} "
           f"L {x + 75 * s} {y} Z", fill=color, stroke=BLACK, sw=3)


def spar_buoy_tapered(c: Canvas, x, y, color=RED, mark=None, scale=1.0, parens=False):
    s = scale
    c.path(f"M {x - 60 * s} {y} L {x - 14 * s} {y - 110 * s} L {x - 14 * s} {y - 300 * s} L {x + 14 * s} {y - 300 * s} "
           f"L {x + 14 * s} {y - 110 * s} L {x + 60 * s} {y} Z", fill=color, stroke=BLACK, sw=3)
    if mark:
        topmark(c, x, y - 300 * s, mark, s=TOPMARK * s, color=color, parens=parens)


def withy(c: Canvas, x, y, up: bool, scale=1.0):
    """Withy (Pricke): pole with a broom — bundle down (starboard) or up (port)."""
    s = scale
    c.rect(x - 9 * s, y - 330 * s, 18 * s, 330 * s, fill=WHITE, stroke=BLACK, sw=3)
    top = y - 330 * s
    if up:
        for i in range(-6, 7):
            c.line(x, top + 40 * s, x + i * 9 * s, top - 90 * s, sw=5 * s)
        c.rect(x - 16 * s, top + 10 * s, 32 * s, 40 * s, fill=BLACK)
    else:
        for i in range(-6, 7):
            c.line(x, top - 70 * s, x + i * 10 * s, top + 20 * s, sw=5 * s)
        c.rect(x - 14 * s, top - 80 * s, 28 * s, 26 * s, fill=BLACK)
    c.line(x - 60 * s, y, x + 60 * s, y, sw=4)


def tree(c: Canvas, x, y, scale=1.0):
    s = scale

    def branch(x0, y0, ang, length, depth):
        if depth == 0 or length < 8:
            return
        x1 = x0 + length * math.cos(math.radians(ang))
        y1 = y0 - length * math.sin(math.radians(ang))
        c.line(x0, y0, x1, y1, sw=max(2, depth * 2.4 * s))
        branch(x1, y1, ang + 28, length * 0.68, depth - 1)
        branch(x1, y1, ang - 26, length * 0.7, depth - 1)

    c.line(x, y, x, y - 200 * s, sw=12 * s)
    branch(x, y - 200 * s, 90, 70 * s, 5)
    branch(x, y - 150 * s, 130, 55 * s, 3)
    branch(x, y - 160 * s, 50, 55 * s, 3)
    c.line(x - 50 * s, y, x + 50 * s, y, sw=4)


def ground(c: Canvas, y, x0, x1):
    c.line(x0, y, x1, y, sw=4)


# ─────────────────────────────────────────────────────────────────────────────
# Cardinal / isolated danger / safe-water sets
# ─────────────────────────────────────────────────────────────────────────────

CARDINAL = {
    "N": ("cones_N", [(0, 0.5, YELLOW), (0.5, 1.0, BLACK)]),
    "E": ("cones_E", [(0, 0.33, BLACK), (0.33, 0.66, YELLOW), (0.66, 1.0, BLACK)]),
    "S": ("cones_S", [(0, 0.5, BLACK), (0.5, 1.0, YELLOW)]),
    "W": ("cones_W", [(0, 0.33, YELLOW), (0.33, 0.66, BLACK), (0.66, 1.0, YELLOW)]),
}


def mark_set(mark, bands, mark_color=BLACK) -> Canvas:
    c = Canvas(1300, 900)
    y, k = 860, 1.12
    light_float(c, 180, y, bands, mark=mark, scale=k, mark_color=mark_color)
    pillar(c, 520, y, bands, mark=mark, scale=k, mark_color=mark_color)
    spar_on_block(c, 830, y, bands, mark=mark, scale=k, mark_color=mark_color)
    spar(c, 1120, y, bands, mark=mark, scale=k, mark_color=mark_color)
    for x0, x1 in ((30, 330), (410, 630), (720, 940), (1050, 1190)):
        ground(c, y, x0, x1)
    return c


def cardinal(q: str) -> Canvas:
    mark, bands = CARDINAL[q]
    return mark_set(mark, bands)


def isolated_danger() -> Canvas:
    return mark_set("two_balls", [(0, 0.33, BLACK), (0.33, 0.66, RED), (0.66, 1.0, BLACK)])


def safe_water() -> Canvas:
    c = Canvas(700, 900)
    light_float(c, 350, 860, [], mark="ball", parens=True, scale=1.5, mark_color=RED, vstripes=[RED, WHITE])
    ground(c, 860, 130, 570)
    return c


def lateral_starboard() -> Canvas:
    c = Canvas(1300, 760)
    y = 700
    conical_buoy(c, 170, y, GREEN)
    light_float(c, 520, y, [(0, 1, GREEN)], mark="cone_up", parens=True, scale=0.9, mark_color=GREEN)
    spar(c, 830, y, [(0, 1, GREEN)], mark="cone_up", mark_color=GREEN)
    withy(c, 1110, y, up=False)
    for x0, x1 in ((60, 280), (380, 660), (770, 890)):
        ground(c, y, x0, x1)
    return c


def lateral_port() -> Canvas:
    c = Canvas(1500, 760)
    y = 700
    can_buoy(c, 120, y, RED)
    light_float(c, 380, y, [(0, 1, RED)], mark="cyl", parens=True, scale=0.85, mark_color=RED)
    spar_buoy_tapered(c, 640, y, RED, mark="cyl", parens=True)
    spar_on_block(c, 860, y, [(0, 1, RED)], mark="cyl", parens=True, mark_color=RED)
    spar(c, 1060, y, [(0, 1, RED)], mark="cyl", mark_color=RED)
    withy(c, 1240, y, up=True, scale=0.9)
    tree(c, 1410, y, scale=1.1)
    for x0, x1 in ((40, 200), (250, 510), (560, 720), (780, 940), (1000, 1120)):
        ground(c, y, x0, x1)
    return c


def withies(port: bool) -> Canvas:
    if port:
        c = Canvas(800, 760)
        withy(c, 260, 700, up=True, scale=1.3)
        tree(c, 580, 700, scale=1.6)
    else:
        c = Canvas(560, 760)
        withy(c, 280, 700, up=False, scale=1.3)
    return c


def branch_buoy(starboard_main: bool) -> Canvas:
    c = Canvas(760, 960)
    if starboard_main:
        bands = [(0, 0.4, GREEN), (0.4, 0.62, RED), (0.62, 1, GREEN)]
        light_float(c, 380, 920, bands, mark="cone_up", scale=1.6, label="119\nHN 2", mark_color=GREEN)
    else:
        bands = [(0, 0.4, RED), (0.4, 0.62, GREEN), (0.62, 1, RED)]
        light_float(c, 380, 920, bands, mark="cyl", scale=1.6, label="84\nGN 15", mark_color=RED)
    ground(c, 920, 130, 630)
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Special marks
# ─────────────────────────────────────────────────────────────────────────────

def _barrel_path(P):
    return (f"M {P(0, 0)} C {P(0, 190)} {P(110, 300)} {P(250, 300)} L {P(500, 390)} "
            f"C {P(650, 430)} {P(710, 290)} {P(600, 190)} L {P(430, 0)} Z")


def barrel(c: Canvas, x, y, scale=1.0, body=YELLOW, outline=BLACK, sw=4, bands=None, band_color=RED, band_w=40):
    """Lying barrel buoy seen obliquely; (x, y) is the bottom-left of the near end.

    ``bands`` draws a cross on the barrel (clipped to its outline).
    """
    k = scale

    def P(px, py):
        return f"{x + px * k:.1f} {y - py * k:.1f}"

    d = _barrel_path(P)
    c.path(d, fill=body)
    if bands:
        cid = _next("barrel")
        c.raw(f'<defs><clipPath id="{cid}"><path d="{d}"/></clipPath></defs><g clip-path="url(#{cid})">')
        # lengthwise band along the top, girth band around the middle, band on the near end face
        c.path(f"M {P(140, 245)} C {P(270, 285)} {P(430, 320)} {P(640, 370)}", fill="none", stroke=band_color, sw=band_w * k)
        c.path(f"M {P(300, -10)} C {P(300, 160)} {P(340, 300)} {P(400, 420)}", fill="none", stroke=band_color, sw=band_w * k)
        c.path(f"M {P(150, -10)} L {P(150, 245)}", fill="none", stroke=band_color, sw=band_w * k)
        c.raw("</g>")
    c.path(d, fill="none", stroke=outline, sw=sw)
    c.path(f"M {P(0, 0)} C {P(20, 200)} {P(260, 240)} {P(310, 0)}", fill="none", stroke=outline, sw=sw)
    return P


def _waves(c: Canvas, x, y, n=3, w=300):
    for i in range(n):
        c.line(x + i * 25, y + 18 + i * 16, x + w * 0.45 + i * 25, y + 18 + i * 16, sw=4)


def special_marks() -> Canvas:
    c = Canvas(1300, 820)
    barrel(c, 70, 700, scale=0.75)
    _waves(c, 60, 700, w=380)
    topmark(c, 260, 330, "x", s=46, parens=True)
    light_float(c, 990, 760, [(0, 1, YELLOW)], mark="x", parens=True, scale=1.25, mark_color=YELLOW)
    ground(c, 760, 780, 1200)
    return c


def restricted_area() -> Canvas:
    c = Canvas(1000, 900)
    barrel(c, 130, 840, scale=1.15, bands=True, band_color=RED, band_w=36)
    c.text(700, 470, "Sperr-G", size=50, weight="700", transform="rotate(-20 700 470)")
    topmark(c, 470, 230, "x", s=60, parens=True)
    return c


def bathing_area_buoy() -> Canvas:
    """Yellow special mark closing an area to power-driven vessels and PWCs (bathing)."""
    c = Canvas(1000, 860)
    barrel(c, 130, 800, scale=1.15, body=WHITE, outline=GREY, sw=6, bands=True, band_color=YELLOW, band_w=50)
    c.line(100, 800, 900, 800, sw=4)
    return c


def bathing_cross_post() -> Canvas:
    c = Canvas(560, 760)
    c.rect(255, 300, 50, 440, fill=WHITE, stroke=GREY, sw=4)
    for a in (45, -45):
        c.raw(f'<g transform="rotate({a} 280 230)"><rect x="80" y="196" width="400" height="68" fill="{YELLOW}" '
              f'stroke="#9B8700" stroke-width="4"/></g>')
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Light rhythms of cardinal marks
# ─────────────────────────────────────────────────────────────────────────────

def _rhythm_row(c: Canvas, y, pattern, period_px=None, label_y=None):
    """pattern: list of ('f', width) flash, ('d', width) dark, ('l', width) long flash."""
    x = 40
    c.rect(40, y, 1120, 46, fill=BLACK)
    for kind, wpx in pattern:
        if x > 1160:
            break
        if kind == "f":
            c.poly([(x, y + 46), (x + wpx / 2, y + 6), (x + wpx, y + 46)], fill=WHITE)
        elif kind == "l":
            c.rect(x, y + 6, wpx, 40, fill=WHITE)
        x += wpx
    if period_px:
        x0, x1 = period_px
        ly = label_y or y + 75
        c.line(x0, ly, x1, ly, sw=3)
        c.line(x0, ly - 14, x0, ly + 14, sw=3)
        c.line(x1, ly - 14, x1, ly + 14, sw=3)
        c.poly([(x0, ly), (x0 + 20, ly - 8), (x0 + 20, ly + 8)], fill=BLACK)
        c.poly([(x1, ly), (x1 - 20, ly - 8), (x1 - 20, ly + 8)], fill=BLACK)
        c.text((x0 + x1) / 2, ly - 10, "Wiederkehr", size=26, weight="500")


def _group(n, flash, dark, rest, long_flash=0):
    p = []
    for _ in range(n):
        p += [("f", flash), ("d", dark)]
    if long_flash:
        p += [("l", long_flash)]
    p += [("d", rest)]
    return p


def light_rhythm(q: str) -> Canvas:
    c = Canvas(1200, 420)
    if q == "N":
        _rhythm_row(c, 70, [("f", 40)] * 30)
        c.text(40, 205, "oder", size=44, anchor="start")
        _rhythm_row(c, 250, [("f", 20)] * 60)
    else:
        n = {"E": 3, "S": 6, "W": 9}[q]
        lf = 70 if q == "S" else 0
        a = _group(n, 40, 0, 260 if q != "W" else 120, lf)
        b = _group(n, 20, 0, 150 if q != "W" else 90, lf // 2)
        pa = sum(wp for _, wp in a)
        pb = sum(wp for _, wp in b)
        _rhythm_row(c, 60, a * 6, period_px=(40, 40 + pa))
        c.text(40, 215, "oder", size=44, anchor="start")
        _rhythm_row(c, 260, b * 8, period_px=(40, 40 + pb), label_y=345)
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Weather
# ─────────────────────────────────────────────────────────────────────────────

MAP_GREEN = "#A9D47F"
GRID = "#6FAE4A"


def _map_bg(c: Canvas):
    c.rect(0, 0, c.w, c.h, fill=MAP_GREEN)
    for i in range(-4, 14):
        x = i * 120
        c.path(f"M {x} 0 Q {x + 80} {c.h / 2} {x + 30} {c.h}", fill="none", stroke=GRID, sw=3)
    for j in range(1, 8):
        y = j * 100
        c.path(f"M 0 {y} Q {c.w / 2} {y - 60} {c.w} {y}", fill="none", stroke=GRID, sw=3)


def _iso_label(c: Canvas, x, y, t):
    c.rect(x - 36, y - 22, 72, 30, fill=MAP_GREEN)
    c.text(x, y, t, size=24, weight="600")


def high_pressure() -> Canvas:
    c = Canvas(1200, 800)
    _map_bg(c)
    c.path("M 100 400 C 80 180 380 90 650 120 C 950 150 1130 250 1100 450 C 1070 650 820 720 520 700 "
           "C 260 690 115 580 100 400 Z", fill="none", stroke=BLACK, sw=4)
    c.path("M 290 360 C 300 260 480 230 640 280 C 820 335 900 420 840 500 C 780 570 560 560 420 500 "
           "C 320 460 285 420 290 360 Z", fill="none", stroke=BLACK, sw=4)
    _iso_label(c, 230, 160, "1025")
    _iso_label(c, 1000, 680, "1025")
    _iso_label(c, 400, 300, "1030")
    _iso_label(c, 860, 470, "1030")
    c.text(600, 440, "H", size=96, weight="900")
    return c


def low_pressure() -> Canvas:
    c = Canvas(1200, 800)
    _map_bg(c)
    cx, cy = 760, 300
    for i, (rx, ry, lab) in enumerate(((90, 55, "985"), (170, 110, "990"), (260, 170, "995"), (360, 235, "1000"),
                                       (470, 300, "1005"))):
        c.ellipse(cx, cy, rx, ry, fill="none", stroke=BLACK, sw=4, transform=f"rotate(-12 {cx} {cy})")
        _iso_label(c, cx + rx * 0.55, cy + ry * 0.85, lab)
    c.text(cx, cy + 32, "T", size=90, weight="900")
    # cold front (triangles, blue) and warm front (semicircles, red)
    cold = [(cx - 10, cy + 40), (700, 420), (560, 560), (380, 640), (150, 700)]
    c.polyline(cold, stroke="#1E4FD8", sw=7)
    for (x0, y0), (x1, y1) in zip(cold, cold[1:]):
        for t in (0.3, 0.7):
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            ang = math.atan2(y1 - y0, x1 - x0)
            nx, ny = math.sin(ang), -math.cos(ang)
            c.poly([(x - 18 * math.cos(ang), y - 18 * math.sin(ang)), (x + 18 * math.cos(ang), y + 18 * math.sin(ang)),
                    (x + nx * 30, y + ny * 30)], fill="#1E4FD8")
    warm = [(cx + 10, cy + 40), (900, 400), (1010, 470), (1160, 520)]
    c.polyline(warm, stroke="#D81E1E", sw=7)
    for (x0, y0), (x1, y1) in zip(warm, warm[1:]):
        x, y = (x0 + x1) / 2, (y0 + y1) / 2
        ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
        c.path(f"M {x - 20} {y} A 20 20 0 0 0 {x + 20} {y} Z", fill="#D81E1E", transform=f"rotate({ang} {x} {y})")
    # air flows: cold (solid) and warm (hollow)
    for x, y in ((150, 120), (260, 90)):
        c.line(x + 80, y - 50, x, y + 30, sw=12)
        c.poly([(x - 20, y + 50), (x + 10, y - 5), (x + 30, y + 20)], fill=BLACK)
    c.path("M 900 690 L 1080 640 L 1070 615 L 1150 650 L 1090 700 L 1085 675 L 905 720 Z", fill=WHITE, stroke=BLACK, sw=4)
    return c


def wind_symbol() -> Canvas:
    c = Canvas(700, 700)
    cx, cy, r = 470, 470, 70
    c.circle(cx, cy, r, fill=WHITE, stroke=BLACK, sw=14)
    ang = math.radians(225)  # pointing to the north-west (wind *from* NW)
    ex, ey = cx + 420 * math.cos(ang), cy + 420 * math.sin(ang)
    sx, sy = cx + r * math.cos(ang), cy + r * math.sin(ang)
    c.line(sx, sy, ex, ey, sw=26, cap="butt")
    # barbs on the clockwise side: one long (2 Bft) + one short (1 Bft) = 3 Bft
    perp = ang + math.radians(90)
    for dist, length in ((0, 170), (85, 95)):
        bx, by = ex - dist * math.cos(ang), ey - dist * math.sin(ang)
        c.line(bx, by, bx + length * math.cos(perp), by + length * math.sin(perp), sw=26, cap="butt")
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Signal masts (SeeSchStrO)
# ─────────────────────────────────────────────────────────────────────────────

def signal_mast(items) -> Canvas:
    c = Canvas(500, 800)
    c.rect(4, 4, 492, 792, fill="none", stroke=GREY, sw=5)
    c.line(220, 60, 220, 760, sw=14, cap="butt")
    c.line(80, 160, 440, 160, sw=12, cap="butt")
    x = 400
    c.line(x, 160, x, 180, sw=4)
    y = 180
    for kind in items:
        if kind == "ball":
            ball(c, x, y + 58, r=56)
            y += 130
        elif kind == "cone_down":
            cone(c, x, y + 58, s=58, down=True)
            y += 125
        elif kind == "cone_up":
            cone(c, x, y + 58, s=58, down=False)
            y += 125
        elif kind == "red_flag":
            c.rect(x - 22, y + 10, 44, 190, fill=RED, stroke=BLACK, sw=3)
            y += 210
        c.line(x, y - 10, x, y + 6, sw=4)
    return c

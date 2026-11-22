"""Top-view right-of-way sketches for sailing questions (SBF Binnen)."""

from __future__ import annotations

import math

from svg import BLACK, WATER, WATER_DARK, WHITE, Canvas, FONT, sub


def _rel_wind(heading, wind_from):
    """Angle of the wind relative to the bow, 0..360 clockwise (0 = head-on)."""
    return (wind_from - heading) % 360


def _wake(g: Canvas, length=150):
    for dx, spread in ((-18, -40), (0, 0), (18, 40)):
        g.path(f"M {dx} 70 Q {dx + spread * 0.4} {70 + length * 0.5} {dx + spread} {70 + length}",
               fill="none", stroke="#5A7EA0", sw=4)


def sailboat(c: Canvas, x, y, heading, wind_from, label=None, cone=False, scale=1.55, label_offset=(70, 0)):
    g = sub()
    _wake(g)
    hull = "M 0 -95 C 30 -60 38 -10 34 30 C 32 55 28 70 24 78 L -24 78 C -28 70 -32 55 -34 30 C -38 -10 -30 -60 0 -95 Z"
    g.path(hull, fill=WHITE, stroke=BLACK, sw=4)
    g.path("M 0 -60 C 16 -40 20 0 18 40 L -18 40 C -20 0 -16 -40 0 -60 Z", fill="none", stroke=BLACK, sw=2)
    rel = _rel_wind(heading, wind_from)
    from_starboard = 0 < rel < 180
    off = min(rel, 360 - rel)                         # 0 … 180
    boom = max(10.0, min(80.0, 10 + (off - 40) * 0.5))
    side = -1 if from_starboard else 1                # sail on the leeward side (x<0 is port)
    mast = (0, -30)
    # boom points aft from the mast, swung out to leeward by ``boom`` degrees
    bx = mast[0] + side * 115 * math.sin(math.radians(boom))
    by = mast[1] + 115 * math.cos(math.radians(boom))
    belly_x = (mast[0] + bx) / 2 + side * 48 * math.cos(math.radians(boom))
    belly_y = (mast[1] + by) / 2 - 48 * math.sin(math.radians(boom)) * 0.4
    g.path(f"M {mast[0]} {mast[1]} Q {belly_x} {belly_y} {bx} {by} L {mast[0]} {mast[1]} Z", fill="#F7F7F2", stroke=BLACK, sw=5)
    g.line(mast[0], mast[1], bx, by, sw=5)
    # jib
    jx = side * 34 * math.sin(math.radians(boom * 0.7))
    g.path(f"M 0 -92 Q {jx * 1.3} -60 {jx} -36 L 0 -36 Z", fill=WHITE, stroke=BLACK, sw=3)
    g.circle(mast[0], mast[1], 6, fill=BLACK)
    if cone:
        g.poly([(-16, -18), (16, -18), (0, 8)], fill=BLACK)
    c.group(g, f"translate({x} {y}) rotate({heading}) scale({scale})")
    if label:
        c.text(x + label_offset[0] * 1.45, y + label_offset[1] * 1.45 + 18, label, size=58, weight="800")


def motor_vessel(c: Canvas, x, y, heading, label=None, length=1.0, label_offset=(0, -110)):
    g = sub()
    L = 260 * length
    _wake(g, length=180)
    g.path(f"M 0 {-L / 2} C 40 {-L / 2 + 50} 46 {-L / 2 + 90} 46 {-L / 4} L 46 {L / 2 - 20} Q 46 {L / 2} 26 {L / 2} "
           f"L -26 {L / 2} Q -46 {L / 2} -46 {L / 2 - 20} L -46 {-L / 4} C -46 {-L / 2 + 90} -40 {-L / 2 + 50} 0 {-L / 2} Z",
           fill=WHITE, stroke=BLACK, sw=4)
    g.rect(-30, -L * 0.08, 60, L * 0.36, fill=WHITE, stroke=BLACK, sw=3, rx=6)
    g.rect(-20, -L * 0.04, 40, L * 0.12, fill="none", stroke=BLACK, sw=2)
    g.line(-46, L * 0.3, 46, L * 0.3, sw=2)
    c.group(g, f"translate({x} {y}) rotate({heading})")
    if label:
        c.text(x + label_offset[0], y + label_offset[1], label, size=46, weight="800")


def wind_arrow(c: Canvas, x, y, wind_from, length=150):
    """Hollow arrow showing the direction the wind blows *to*."""
    g = sub()
    g.path(f"M -16 {-length / 2} L 16 {-length / 2} L 16 {length / 2 - 40} L 40 {length / 2 - 40} L 0 {length / 2} "
           f"L -40 {length / 2 - 40} L -16 {length / 2 - 40} Z", fill=WHITE, stroke=BLACK, sw=4)
    c.group(g, f"translate({x} {y}) rotate({wind_from})")


def _water(w=1200, h=700, shore=False) -> Canvas:
    c = Canvas(w, h, bg=WATER)
    if shore:
        c.path("M 0 0 L 1200 0 L 1200 60 " + " ".join(f"Q {1200 - i * 100 - 50} {80 if i % 2 else 50} {1200 - (i + 1) * 100} 60"
                                                     for i in range(12)) + " Z", fill=WHITE, stroke=BLACK, sw=4)
    c.rect(2, 2, w - 4, h - 4, fill="none", stroke=WATER_DARK, sw=4)
    return c


def _arrowhead(c: Canvas, tip, toward_from, size=34):
    """Filled arrowhead at ``tip`` pointing away from ``toward_from``."""
    ang = math.atan2(tip[1] - toward_from[1], tip[0] - toward_from[0])
    pts = [tip]
    for side in (-1, 1):
        a = ang + math.pi + side * 0.42
        pts.append((tip[0] + size * math.cos(a), tip[1] + size * math.sin(a)))
    c.poly(pts, fill=BLACK)


def manoeuvre_course() -> Canvas:
    """Segeln 295: course with a tack (1), a gybe (2) and a chicken gybe (3); wind from the left."""
    c = _water(1200, 900)
    s, ox, oy = 1.55, 30, 10

    def p(x, y):
        return f"{ox + x * s:.1f} {oy + y * s:.1f}"

    start, end = (588, 18), (712, 150)
    course = (f"M {p(*start)} L {p(360, 470)} "
              f"C {p(330, 535)} {p(255, 545)} {p(225, 485)} "      # 1: bow through the wind
              f"L {p(130, 330)} C {p(112, 300)} {p(132, 222)} {p(150, 195)} "
              f"L {p(220, 85)} C {p(242, 52)} {p(318, 40)} {p(350, 75)} "  # 2: stern through the wind
              f"L {p(665, 290)} C {p(698, 312)} {p(700, 425)} {p(628, 428)} "
              f"C {p(560, 430)} {p(562, 348)} {p(592, 308)} "        # 3: loop through the wind
              f"L {p(*end)}")
    c.path(course, fill="none", stroke=BLACK, sw=6)
    sx, sy = (ox + start[0] * s, oy + start[1] * s)
    c.circle(sx, sy, 10, fill=BLACK)
    for a, b in (((520, 154), (468, 255)), ((476, 161), (555, 215))):   # direction of travel
        _arrowhead(c, (ox + b[0] * s, oy + b[1] * s), (ox + a[0] * s, oy + a[1] * s), size=40)
    _arrowhead(c, (ox + end[0] * s, oy + end[1] * s), (ox + 650 * s, oy + 215 * s), size=44)
    for label, (x, y) in (("1", (292, 488)), ("2", (282, 108)), ("3", (626, 392))):
        c.text(ox + x * s, oy + y * s + 22, label, size=64, weight="800")
    wind_arrow(c, 105, 420, 270, length=170)
    return c


def scenario(uid: str) -> Canvas:
    if uid == "binnen_180":
        c = _water(shore=True)
        motor_vessel(c, 760, 220, 90, length=1.25)
        sailboat(c, 520, 480, 50, 225)
        wind_arrow(c, 170, 580, 225)
    elif uid == "binnen_183":
        c = _water()
        sailboat(c, 990, 200, 235, 315, label="A", cone=True, label_offset=(-10, 130))
        sailboat(c, 260, 470, 80, 315, label="B", label_offset=(0, 120))
        wind_arrow(c, 300, 140, 315)
    elif uid == "binnen_185":
        c = _water()
        sailboat(c, 300, 430, 30, 0, label="A", label_offset=(80, -40))
        sailboat(c, 900, 430, 330, 0, label="B", label_offset=(-80, -40))
        wind_arrow(c, 600, 120, 0)
    elif uid == "binnen_186":
        c = _water()
        sailboat(c, 380, 200, 60, 270, label="B", label_offset=(110, -30))
        sailboat(c, 820, 500, 10, 270, label="A", label_offset=(90, 0))
        wind_arrow(c, 120, 430, 270)
    elif uid == "binnen_188":
        c = _water()
        for x, lab in ((300, "A"), (600, "B"), (900, "C")):
            sailboat(c, x, 420, 0, 90, label=lab, label_offset=(75, -60))
        wind_arrow(c, 1100, 130, 90)
    elif uid == "binnen_189":
        c = _water()
        sailboat(c, 260, 180, 95, 0, label="C", label_offset=(10, -95))
        sailboat(c, 330, 520, 40, 0, label="B", label_offset=(-110, 40))
        sailboat(c, 930, 520, 320, 0, label="A", label_offset=(110, 40))
        wind_arrow(c, 640, 130, 0)
    else:
        raise KeyError(uid)
    return c

"""Vessel scenes: inland barges, front-view floating equipment, sea-going ships."""

from __future__ import annotations

import math

from svg import (BLACK, GREEN, LIGHT_BLUE, LIGHT_GREEN, LIGHT_RED, NIGHT, RED,
                 WHITE, YELLOW, Canvas, sub)

LIGHT = {"w": WHITE, "r": LIGHT_RED, "g": LIGHT_GREEN, "y": YELLOW, "b": LIGHT_BLUE}


# ─────────────────────────────────────────────────────────────────────────────
# Shapes (day signals) — drawn centred at (x, y)
# ─────────────────────────────────────────────────────────────────────────────

def ball(c: Canvas, x, y, r=28, fill=BLACK, stroke=None):
    c.circle(x, y, r, fill=fill, stroke=stroke, sw=3 if stroke else None)


def cone(c: Canvas, x, y, s=30, down=True, fill=BLACK, stroke=None):
    if down:
        pts = [(x - s, y - s * 0.85), (x + s, y - s * 0.85), (x, y + s * 0.85)]
    else:
        pts = [(x - s, y + s * 0.85), (x + s, y + s * 0.85), (x, y - s * 0.85)]
    c.poly(pts, fill=fill, stroke=stroke, sw=3 if stroke else None)


def rhomb(c: Canvas, x, y, s=30, fill=BLACK, stroke=None):
    c.poly([(x, y - s * 1.25), (x + s * 0.8, y), (x, y + s * 1.25), (x - s * 0.8, y)], fill=fill, stroke=stroke,
           sw=3 if stroke else None)


def cylinder(c: Canvas, x, y, w=40, h=64, fill=BLACK, bands=None, stroke=None):
    c.rect(x - w / 2, y - h / 2, w, h, fill=fill, stroke=stroke, sw=3 if stroke else None)
    for (fy, fh, col) in bands or []:
        c.rect(x - w / 2, y - h / 2 + fy * h, w, fh * h, fill=col)
    if stroke:
        c.rect(x - w / 2, y - h / 2, w, h, fill="none", stroke=stroke, sw=3)


def flag(c: Canvas, x, y, w=70, h=48, top=RED, bottom=None, angle=0, outline=BLACK):
    g = sub()
    if bottom:
        g.rect(x, y, w, h / 2, fill=top)
        g.rect(x, y + h / 2, w, h / 2, fill=bottom)
    else:
        g.rect(x, y, w, h, fill=top)
    g.rect(x, y, w, h, fill="none", stroke=outline, sw=4)
    c.group(g, f"rotate({angle} {x} {y})")


def pennant(c: Canvas, x, y, w=150, h=56, fill=RED):
    c.poly([(x, y), (x, y + h), (x - w, y + h / 2)], fill=fill, stroke=BLACK, sw=3)


def board_bands(c: Canvas, x, y, w=80, h=80, colors=(RED, WHITE, RED), vertical=False, outline=BLACK):
    n = len(colors)
    for i, col in enumerate(colors):
        if vertical:
            c.rect(x + i * w / n, y, w / n, h, fill=col)
        else:
            c.rect(x, y + i * h / n, w, h / n, fill=col)
    c.rect(x, y, w, h, fill="none", stroke=outline, sw=4)


def light(c: Canvas, x, y, col, r=17, square=False, ring=None):
    fill = LIGHT[col]
    if square:
        c.rect(x - r, y - r, 2 * r, 2 * r, fill=fill, rx=3)
        if col == "w" and ring:
            c.circle(x, y, r * 0.35, fill=ring)
    else:
        c.circle(x, y, r, fill=fill)


def flash_star(c: Canvas, x, y, r=40, col=LIGHT_BLUE):
    for a in range(0, 360, 30):
        rad = math.radians(a)
        c.line(x + r * 0.3 * math.cos(rad), y + r * 0.3 * math.sin(rad),
               x + r * math.cos(rad), y + r * math.sin(rad), stroke=col, sw=10)
    c.circle(x, y, r * 0.32, fill=col)


# ─────────────────────────────────────────────────────────────────────────────
# Inland barge — side view, day line art
# ─────────────────────────────────────────────────────────────────────────────

def _water_hatch(c: Canvas, y0, y1, w, color=BLACK, step=26, dash="70 26", sw=4, x0=0):
    y = y0
    i = 0
    while y < y1:
        c.line(x0 + (i % 3) * 30, y, w, y, stroke=color, sw=sw, dash=dash, cap="butt")
        y += step
        i += 1


def barge(mast_shapes=None, cabin=False, inset_lights=None) -> Canvas:
    """Motor barge in side view with a signal mast.

    ``mast_shapes`` is a callable(c, x, y_top) drawing the signal hanging from
    the mast arm.  ``inset_lights`` adds a small night inset (list of colours,
    top to bottom) for questions about day *and* night signals.
    """
    c = Canvas(1200, 800)
    c.rect(4, 4, 1192, 792, fill="none", stroke=BLACK, sw=6)
    _water_hatch(c, 640, 790, 1192, x0=8)
    hull = [(110, 470), (930, 470), (1040, 540), (965, 650), (140, 650), (100, 560)]
    c.poly(hull, fill=WHITE, stroke=BLACK, sw=7)
    c.line(110, 505, 985, 505, sw=5)
    if cabin:
        c.poly([(190, 470), (190, 380), (250, 340), (400, 340), (400, 470)], fill=WHITE, stroke=BLACK, sw=7)
        c.ellipse(320, 340, 45, 16, fill=WHITE, stroke=BLACK, sw=6)
        c.rect(275, 270, 90, 70, fill=WHITE, stroke=BLACK, sw=6)
        c.rect(430, 250, 150, 220, fill=WHITE, stroke=BLACK, sw=7)
        c.poly([(430, 250), (465, 215), (615, 215), (580, 250)], fill=WHITE, stroke=BLACK, sw=7)
        c.poly([(580, 250), (615, 215), (615, 435), (580, 470)], fill=WHITE, stroke=BLACK, sw=7)
    mast_x = 790
    c.line(mast_x, 470, mast_x, 80, sw=7)
    c.line(mast_x, 80, mast_x + 75, 80, sw=7)
    if mast_shapes:
        mast_shapes(c, mast_x + 75, 80)
    if inset_lights:
        c.rect(24, 24, 230, 300, fill=NIGHT, stroke=BLACK, sw=4)
        for i, col in enumerate(inset_lights):
            light(c, 139, 110 + i * 120, col, r=42)
    return c


def hanging(*items, spacing=120):
    """Return a mast_shapes callable drawing shapes hanging below the arm."""
    def draw(c: Canvas, x, y):
        c.line(x, y, x, y + 30, sw=5)
        yy = y + 30
        for kind, col in items:
            if kind == "cone":
                c.line(x, yy, x, yy + 10, sw=5)
                cone(c, x, yy + 60, s=62, fill=col, stroke=BLACK)
                yy += spacing
            elif kind == "ball":
                ball(c, x, yy + 62, r=62, fill=col, stroke=BLACK)
                c.line(x - 62, yy + 62, x + 62, yy + 62, sw=5)
                c.line(x, yy, x, yy + 124, sw=5)
                yy += 130
            elif kind == "cylinder":
                cylinder(c, x, yy + 80, w=84, h=160, fill=col,
                         bands=[(0.0, 0.16, BLACK), (0.36, 0.28, BLACK), (0.84, 0.16, BLACK)], stroke=BLACK)
                yy += 170
            elif kind == "pennant":
                c.line(x + 20, yy - 50, x + 20, yy + 140, sw=7)
                pennant(c, x + 20, yy - 40, w=240, h=100)
                yy += 120
            elif kind == "flag_rw":
                flag(c, x, yy - 10, w=170, h=110, top=RED, bottom=WHITE)
                yy += 120
    return draw


# ─────────────────────────────────────────────────────────────────────────────
# Floating equipment / wreck — front view
# ─────────────────────────────────────────────────────────────────────────────

def _embankment(c: Canvas, night: bool):
    col = WHITE if night else BLACK
    c.poly([(0, 470), (70, 470), (380, 840), (0, 840)], fill=NIGHT if night else WHITE, stroke=col, sw=6)
    for i in range(15):
        t = i / 14
        x, y = 70 + 310 * t, 470 + 370 * t
        c.line(x, y, x - 70, y + 40, stroke=col, sw=5)


def floating_equipment(left, right, night=False, embankment=False, tilt=0.0) -> Canvas:
    """Front view of floating equipment (or a wreck when ``tilt`` != 0).

    ``left``/``right`` are lists of (kind, colour) drawn top→bottom at the
    ends of the signal yard. kinds: light, ball, rhomb, flag, board_h, board_v.
    """
    fg = WHITE if night else BLACK
    bg = NIGHT if night else WHITE
    c = Canvas(1200, 840, bg=bg)
    if not night:
        c.rect(3, 3, 1194, 834, fill="none", stroke=BLACK, sw=6)
    for i, y in enumerate(range(600, 840, 22)):
        c.line(20 + (i % 3) * 25, y, 1180, y, stroke=fg if not night else "#9A9A9A", sw=5, dash="60 18", cap="butt")
    if embankment:
        _embankment(c, night)

    v = sub()
    v.poly([(330, 560), (600, 515), (870, 560), (845, 655), (355, 655)], fill=bg, stroke=fg, sw=7)
    v.line(600, 515, 600, 655, stroke=fg, sw=5)
    v.rect(470, 270, 260, 245, fill=bg, stroke=fg, sw=7)
    v.rect(500, 305, 200, 90, fill=bg, stroke=fg, sw=6)
    v.rect(518, 321, 164, 58, fill=bg, stroke=fg, sw=4)
    v.line(600, 270, 600, 210, stroke=fg, sw=7)
    v.line(390, 210, 810, 210, stroke=fg, sw=7)
    v.line(390, 210, 390, 245, stroke=fg, sw=6)
    v.line(810, 210, 810, 245, stroke=fg, sw=6)
    for i in range(8):                                       # anchor chain
        v.circle(600 - i * 22, 545 + i * 32, 11, fill="none", stroke=fg, sw=5)

    def draw_side(items, x, mirror):
        y = 290
        for kind, col in items:
            if kind == "light":
                light(v, x, y, col, r=46)
                y += 110
            elif kind == "ball":
                ball(v, x, y, r=46, fill=RED if col == "r" else BLACK, stroke=fg)
                y += 110
            elif kind == "rhomb":
                rhomb(v, x, y + 18, s=42, fill=GREEN, stroke=fg)
                y += 120
            elif kind == "flag":
                top, bottom = (RED, WHITE) if col == "rw" else (RED, None)
                ang = 35 if mirror else -35
                flag(v, x - (0 if mirror else 125), y - 30, w=125, h=95, top=top, bottom=bottom, angle=ang, outline=fg)
                y += 120
            elif kind == "board_h":
                board_bands(v, x - 65, y - 40, 130, 130, (RED, WHITE, RED), outline=fg)
                y += 150
            elif kind == "board_v":
                board_bands(v, x - 65, y - 40, 130, 130, (GREEN, WHITE, GREEN), vertical=True, outline=fg)
                y += 150

    draw_side(left, 390, mirror=False)
    draw_side(right, 810, mirror=True)
    c.group(v, f"rotate({tilt} 600 640)" if tilt else "translate(0 0)")
    if tilt:
        # the bank the wreck is lying on
        c.path("M 0 720 C 220 690 420 760 640 730 S 980 800 1200 770 L 1200 840 L 0 840 Z",
               fill=BLACK if not night else "#3A3A3A")
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Sea-going ships — simple 3/4 line art
# ─────────────────────────────────────────────────────────────────────────────

SW = 5          # line width of ship outlines


class Ship:
    """Minimal oblique projection.

    x: 0 stern → 1 bow, z: 0 near (starboard) side → 1 far (port) side, y: up
    in "storeys" of ``H`` px.  The bow points to the right, so the starboard
    side faces the viewer — exactly like the ELWIS drawings.
    """

    def __init__(self, c: Canvas, ox, oy, L, H, dx=170, dy=95, night=True):
        self.c, self.ox, self.oy, self.L, self.H, self.dx, self.dy = c, ox, oy, L, H, dx, dy
        self.fg = WHITE if night else BLACK
        self.bg = NIGHT if night else WHITE
        self.night = night

    def p(self, x, z, y):
        return (self.ox + x * self.L + z * self.dx, self.oy - y * self.H - z * self.dy)

    def _fmt(self, pt):
        return f"{pt[0]:.1f} {pt[1]:.1f}"

    def hull(self, deck=2.0, bow_rise=0.7):
        p, f = self.p, self._fmt
        st_n, st_f = p(0, 0, deck), p(0, 1, deck)
        bow = p(1.0, 0.5, deck + bow_rise)
        mid_n, mid_f = p(0.62, 0, deck - 0.05), p(0.62, 1, deck - 0.05)
        keel_s, keel_b = p(0.02, 0.0, 0.0), p(0.9, 0.5, 0.0)
        # deck (seen from above)
        self.c.path(f"M {f(st_n)} L {f(st_f)} Q {f(mid_f)} {f(bow)} Q {f(mid_n)} {f(st_n)} Z",
                    fill=self.bg, stroke=self.fg, sw=SW)
        # near side of the hull
        self.c.path(f"M {f(st_n)} Q {f(mid_n)} {f(bow)} L {f(keel_b)} Q {f(p(0.5, 0, -0.15))} {f(keel_s)} Z",
                    fill=self.bg, stroke=self.fg, sw=SW)
        # bulwark line
        self.c.path(f"M {f(p(0.01, 0, deck * 0.72))} Q {f(p(0.62, 0, deck * 0.66))} {f(p(0.96, 0.4, deck * 0.8 + bow_rise * 0.6))}",
                    fill="none", stroke=self.fg, sw=3)

    def box(self, x0, x1, y0, y1, z0=0.0, z1=1.0):
        p = self.p
        top = [p(x0, z0, y1), p(x1, z0, y1), p(x1, z1, y1), p(x0, z1, y1)]
        side = [p(x0, z0, y0), p(x1, z0, y0), p(x1, z0, y1), p(x0, z0, y1)]
        front = [p(x1, z0, y0), p(x1, z1, y0), p(x1, z1, y1), p(x1, z0, y1)]
        for face in (top, front, side):
            self.c.poly(face, fill=self.bg, stroke=self.fg, sw=SW - 1)

    def funnel(self, x, y0, y1, r=0.05):
        cx0, cy0 = self.p(x, 0.5, y0)
        cx1, cy1 = self.p(x, 0.5, y1)
        rx = r * self.L
        self.c.rect(cx1 - rx, cy1, 2 * rx, cy0 - cy1, fill=self.bg, stroke=self.fg, sw=SW - 1)
        self.c.ellipse(cx1, cy1, rx, rx * 0.35, fill=self.bg, stroke=self.fg, sw=SW - 1)

    def mast(self, x, y0, y1, yard=True, z=0.5):
        b = self.p(x, z, y0)
        t = self.p(x, z, y1)
        self.c.line(*b, *t, stroke=self.fg, sw=SW + 1)
        if yard:
            a = self.p(x, z - 0.55, y1 - 0.45)
            e = self.p(x, z + 0.55, y1 - 0.45)
            self.c.line(*a, *e, stroke=self.fg, sw=SW - 1)
        return t

    def stay(self, a, b):
        self.c.line(*self.p(*a), *self.p(*b), stroke=self.fg, sw=3)

    def at(self, x, z, y):
        return self.p(x, z, y)

    # ── lights & shapes ──────────────────────────────────────────────────
    def masthead(self, x, y):
        light(self.c, *self.p(x, 0.5, y), "w", r=23, square=True, ring=NIGHT)

    def sidelights(self, x, y):
        light(self.c, *self.p(x, 0.0, y), "g", r=22, square=True)
        light(self.c, *self.p(x, 1.0, y), "r", r=22, square=True)

    def sternlight(self, y=2.4):
        light(self.c, *self.p(0.0, 0.5, y), "w", r=15, square=True, ring=NIGHT)

    def allround(self, x, y_top, cols, step=1.15, z=0.5, r=24):
        for i, col in enumerate(cols):
            light(self.c, *self.p(x, z, y_top - i * step), col, r=r)

    def shapes(self, x, y_top, kinds, step=1.35, z=0.5):
        c = self.c
        for i, kind in enumerate(kinds):
            px, py = self.p(x, z, y_top - i * step)
            if kind == "ball":
                ball(c, px, py, r=25)
            elif kind == "rhomb":
                rhomb(c, px, py, s=24)
            elif kind == "cyl":
                cylinder(c, px, py, w=36, h=60)
            elif kind == "cone_up":
                cone(c, px, py, s=26, down=False)
            elif kind == "cone_down":
                cone(c, px, py, s=26, down=True)


def ship_scene(build, night=True, w=1200, h=720) -> Canvas:
    c = Canvas(w, h, bg=NIGHT if night else WHITE)
    if not night:
        c.rect(3, 3, w - 6, h - 6, fill="none", stroke=BLACK, sw=5)
    build(c)
    return c


# Reference heights (storeys of H px) for the standard cargo ship
DECK = 2.0
BRIDGE_TOP = 3.9
AFT_MAST_X, AFT_MAST_TOP = 0.3, 10.6
FORE_MAST_X, FORE_MAST_TOP = 0.84, 8.9
BRIDGE_FRONT = 0.56


def cargo_ship(c: Canvas, night=True, ox=80, oy=610, L=880, H=46, fore_mast=True):
    s = Ship(c, ox, oy, L, H, night=night)
    s.hull(deck=DECK)
    s.box(0.24, BRIDGE_FRONT, DECK, BRIDGE_TOP)
    s.box(0.28, 0.5, BRIDGE_TOP, 5.1, z0=0.2, z1=0.8)
    s.funnel(0.39, 5.1, 6.6)
    s.mast(AFT_MAST_X, 5.1, AFT_MAST_TOP)
    if fore_mast:
        s.mast(FORE_MAST_X, DECK + 0.3, FORE_MAST_TOP, yard=False)
    return s


def power_lights(s: Ship, fore_masthead=True, stern=True, sides=True):
    s.masthead(AFT_MAST_X, AFT_MAST_TOP - 0.2)
    if fore_masthead:
        s.masthead(FORE_MAST_X, FORE_MAST_TOP - 0.2)
    if sides:
        s.sidelights(BRIDGE_FRONT, BRIDGE_TOP - 0.4)
    if stern:
        s.sternlight()


def tanker(c: Canvas, night: bool):
    s = Ship(c, 60, 600, 1010, 40, dx=150, dy=85, night=night)
    s.hull(deck=2.0, bow_rise=0.8)
    s.box(0.03, 0.17, 2.0, 5.2)
    s.funnel(0.08, 5.2, 6.6, r=0.025)
    s.mast(0.13, 5.2, 11.0)
    s.mast(0.93, 2.3, 7.4)
    for i in range(1, 9):
        s.c.line(*s.at(0.18 + i * 0.08, 0.2, 2.0), *s.at(0.18 + i * 0.08, 0.8, 2.0), stroke=s.fg, sw=3)
    return s


def small_vessel(c: Canvas, night: bool, stays=False, L=720):
    """Fishing vessel / small craft with two masts."""
    s = Ship(c, 200, 600, L, 48, dx=150, dy=85, night=night)
    s.hull(deck=2.0, bow_rise=0.9)
    s.box(0.22, 0.46, 2.0, 3.9, z0=0.15, z1=0.85)
    s.mast(0.14, 2.3, 10.0)
    s.mast(0.72, 2.3, 9.6, yard=False)
    if stays:
        s.stay((0.14, 0.5, 10.0), (0.72, 0.5, 9.6))
        s.stay((0.72, 0.5, 9.6), (1.0, 0.5, 2.9))
        s.stay((0.14, 0.5, 10.0), (0.0, 0.5, 2.2))
    return s


def tug_and_tow(c: Canvas, tows: int):
    """Towing vessel at the front (right) with ``tows`` towed vessels behind it."""
    L, H = 300, 34
    xs = [40 + i * 345 for i in range(tows)]
    for x in xs:
        s = Ship(c, x, 470, L, H, dx=80, dy=45)
        s.hull(deck=2.0, bow_rise=0.8)
        light(c, *s.at(0.8, 0.0, 2.6), "g", r=16, square=True)
        light(c, *s.at(0.8, 1.0, 2.6), "r", r=16, square=True)
        light(c, *s.at(0.0, 0.5, 2.8), "w", r=13, square=True, ring=NIGHT)
    for x in xs:                                    # towing hawsers
        a = (x + L * 0.98, 420)
        b = (x + 345 + 8, 430)
        c.path(f"M {a[0]} {a[1]} Q {(a[0] + b[0]) / 2} {a[1] + 45} {b[0]} {b[1]}", fill="none", stroke=WHITE, sw=4)
    tug = Ship(c, 40 + tows * 345, 520, 330, 40, dx=90, dy=50)
    tug.hull(deck=2.0, bow_rise=1.0)
    tug.box(0.3, 0.6, 2.0, 4.0)
    tug.funnel(0.42, 4.0, 5.2, r=0.04)
    return tug


def dredger(c: Canvas, night: bool, ox=110, oy=600, L=860):
    s = Ship(c, ox, oy, L, 40, dx=160, dy=90, night=night)
    fg, bg, p = s.fg, s.bg, s.p
    for face in ([p(0, 0, 0), p(1, 0, 0), p(1, 0, 2), p(0, 0, 2)],
                 [p(0, 0, 2), p(1, 0, 2), p(1, 1, 2), p(0, 1, 2)],
                 [p(1, 0, 0), p(1, 1, 0), p(1, 1, 2), p(1, 0, 2)]):
        c.poly(face, fill=bg, stroke=fg, sw=SW)
    s.box(0.05, 0.28, 2, 5.4, z0=0.2, z1=0.8)
    a, b = p(0.38, 0.5, 9.0), p(0.86, 0.5, 0.6)       # bucket ladder
    c.line(*a, *b, stroke=fg, sw=34)
    c.line(*a, *b, stroke=bg, sw=22)
    n = 10
    for i in range(n):
        t = (i + 0.5) / n
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        c.rect(x - 14, y - 26, 28, 28, fill=bg, stroke=fg, sw=3)
    c.polyline([p(0.33, 0.5, 2), p(0.39, 0.5, 9.6), p(0.5, 0.5, 2)], stroke=fg, sw=SW)
    return s

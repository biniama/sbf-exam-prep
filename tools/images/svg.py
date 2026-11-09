"""Tiny SVG builder used by the question-image generator.

Every drawing is built in its own coordinate space (``Canvas(w, h)``) and
rendered to PNG by ``build.py`` with resvg.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

# Palette — close to the colours used in the official ELWIS illustrations.
RED = "#E30613"
GREEN = "#2E9E47"
LIGHT_GREEN = "#5FC46E"   # navigation lights (green)
YELLOW = "#FFD400"
BLUE = "#0047BB"
SIGN_BLUE = "#0A3FD9"
BLACK = "#111111"
WHITE = "#FFFFFF"
WATER = "#BFD9EE"
WATER_DARK = "#8DB6D9"
NIGHT = "#0B0B0F"
GREY = "#8A8A8A"
LIGHT_RED = "#F2263A"     # navigation lights (red)
LIGHT_WHITE = "#FFFFFF"
LIGHT_BLUE = "#2F6BFF"

FONT = "Helvetica Neue, Helvetica, Arial, sans-serif"


def _fmt(v: float) -> str:
    if isinstance(v, int):
        return str(v)
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return s if s not in ("-0", "") else "0"


def _attrs(**kw) -> str:
    out = []
    for k, v in kw.items():
        if v is None:
            continue
        k = k.rstrip("_").replace("_", "-")
        if isinstance(v, float):
            v = _fmt(v)
        out.append(f'{k}="{v}"')
    return " ".join(out)


@dataclass
class Canvas:
    w: float
    h: float
    bg: str | None = WHITE
    parts: list[str] = field(default_factory=list)

    # ── primitives ────────────────────────────────────────────────────────
    def raw(self, s: str) -> "Canvas":
        self.parts.append(s)
        return self

    def rect(self, x, y, w, h, fill=BLACK, stroke=None, sw=None, rx=None, **kw):
        return self.raw(f"<rect {_attrs(x=x, y=y, width=w, height=h, fill=fill, stroke=stroke, stroke_width=sw, rx=rx, **kw)}/>")

    def circle(self, cx, cy, r, fill=BLACK, stroke=None, sw=None, **kw):
        return self.raw(f"<circle {_attrs(cx=cx, cy=cy, r=r, fill=fill, stroke=stroke, stroke_width=sw, **kw)}/>")

    def ellipse(self, cx, cy, rx, ry, fill=BLACK, stroke=None, sw=None, **kw):
        return self.raw(f"<ellipse {_attrs(cx=cx, cy=cy, rx=rx, ry=ry, fill=fill, stroke=stroke, stroke_width=sw, **kw)}/>")

    def line(self, x1, y1, x2, y2, stroke=BLACK, sw=4, cap="round", dash=None, **kw):
        return self.raw(f"<line {_attrs(x1=x1, y1=y1, x2=x2, y2=y2, stroke=stroke, stroke_width=sw, stroke_linecap=cap, stroke_dasharray=dash, **kw)}/>")

    def poly(self, pts, fill=BLACK, stroke=None, sw=None, join="round", **kw):
        p = " ".join(f"{_fmt(x)},{_fmt(y)}" for x, y in pts)
        return self.raw(f"<polygon {_attrs(points=p, fill=fill, stroke=stroke, stroke_width=sw, stroke_linejoin=join, **kw)}/>")

    def polyline(self, pts, stroke=BLACK, sw=4, fill="none", join="round", cap="round", dash=None, **kw):
        p = " ".join(f"{_fmt(x)},{_fmt(y)}" for x, y in pts)
        return self.raw(f"<polyline {_attrs(points=p, fill=fill, stroke=stroke, stroke_width=sw, stroke_linejoin=join, stroke_linecap=cap, stroke_dasharray=dash, **kw)}/>")

    def path(self, d, fill=BLACK, stroke=None, sw=None, join="round", cap="round", **kw):
        return self.raw(f"<path {_attrs(d=d, fill=fill, stroke=stroke, stroke_width=sw, stroke_linejoin=join, stroke_linecap=cap, **kw)}/>")

    def text(self, x, y, s, size=40, fill=BLACK, weight="bold", anchor="middle", family=FONT, **kw):
        s = s.replace("&", "&amp;").replace("<", "&lt;")
        return self.raw(f"<text {_attrs(x=x, y=y, font_size=size, fill=fill, font_weight=weight, text_anchor=anchor, font_family=family, **kw)}>{s}</text>")

    def group(self, inner: "Canvas", transform: str) -> "Canvas":
        return self.raw(f'<g transform="{transform}">' + "".join(inner.parts) + "</g>")

    # ── output ────────────────────────────────────────────────────────────
    def svg(self) -> str:
        bg = f'<rect width="100%" height="100%" fill="{self.bg}"/>' if self.bg else ""
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {_fmt(self.w)} {_fmt(self.h)}" '
            f'width="{_fmt(self.w)}" height="{_fmt(self.h)}">{bg}{"".join(self.parts)}</svg>'
        )


def sub(w=0, h=0) -> Canvas:
    """A transparent canvas used to build a group."""
    return Canvas(w, h, bg=None)


def rot(pts, angle_deg, cx, cy):
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]

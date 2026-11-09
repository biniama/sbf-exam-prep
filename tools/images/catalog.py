"""Question id → drawing.  Every entry was checked against the ELWIS original
illustration and the correct answer of the question."""

from __future__ import annotations

from svg import BLACK, GREEN, NIGHT, RED, WHITE, YELLOW, Canvas
import marks as M
import sailing as S
import signals as G
import vessels as V
from vessels import hanging, light


def _split(left: Canvas, right: Canvas) -> Canvas:
    """Place two drawings side by side, keeping each one's background."""
    c = Canvas(left.w + right.w + 40, max(left.h, right.h))
    for canvas, ox in ((left, 0), (right, left.w + 40)):
        oy = (c.h - canvas.h) / 2
        if canvas.bg:
            c.rect(ox, oy, canvas.w, canvas.h, fill=canvas.bg)
        c.group(canvas, f"translate({ox} {oy})")
    return c


# ── See: ships ──────────────────────────────────────────────────────────────
# Heights are in "storeys" of the Ship projection (see vessels.cargo_ship).

FM, FT = V.FORE_MAST_X, V.FORE_MAST_TOP


def _cargo(night, deco, **kw):
    def build(c):
        deco(V.cargo_ship(c, night=night, **kw))
    return V.ship_scene(build, night=night)


def see_092():
    return _cargo(True, lambda s: V.power_lights(s))


def _tow(n_tows, n_masthead):
    def build(c):
        tug = V.tug_and_tow(c, n_tows)
        tug.mast(0.62, 4.0, 11.2, yard=False)
        for i in range(n_masthead):
            light(c, *tug.at(0.55, 0.5, 10.6 - i * 1.25), "w", r=16, square=True, ring=NIGHT)
        tug.allround(0.7, 10.6, "rwr", step=1.25, r=16)
        light(c, *tug.at(0.6, 0.0, 3.6), "g", r=16, square=True)
        light(c, *tug.at(0.6, 1.0, 3.6), "r", r=16, square=True)
        light(c, *tug.at(0.0, 0.5, 4.0), "y", r=14, square=True)
        light(c, *tug.at(0.0, 0.5, 2.8), "w", r=14, square=True, ring=NIGHT)
    return V.ship_scene(build)


def see_097():
    return _cargo(True, lambda s: s.allround(FM, FT - 0.3, "rr"))


def see_098():
    def deco(s):
        s.allround(FM, FT - 0.3, "rr")
        s.sidelights(V.BRIDGE_FRONT, V.BRIDGE_TOP - 0.4)
        s.sternlight()
    return _cargo(True, deco)


def see_099():
    return _cargo(False, lambda s: s.shapes(FM, FT - 0.6, ["ball", "ball"]))


def see_102():
    return _cargo(True, lambda s: s.allround(FM, FT - 0.3, "rwr"))


def _derrick_post(s, top=8.6):
    s.mast(0.7, V.DECK + 0.3, top, yard=False)
    s.stay((0.7, 0.5, top - 0.5), (0.6, 0.5, V.DECK + 0.3))


def see_103():
    def deco(s):
        _derrick_post(s)
        s.allround(0.7, 8.2, "rwr", step=1.15)
        V.power_lights(s)
    return _cargo(True, deco)


def see_104():
    def deco(s):
        _derrick_post(s)
        s.shapes(0.7, 8.0, ["ball", "rhomb", "ball"], step=1.45)
    return _cargo(False, deco)


def see_105():
    def build(c):
        s = V.small_vessel(c, True, stays=True)
        s.allround(0.72, 9.0, "rr")
        light(c, *s.at(1.0, 0.5, 3.4), "w", r=20)            # anchor light
    return V.ship_scene(build)


def see_106():
    return _cargo(False, lambda s: s.shapes(FM, FT - 0.6, ["ball", "ball", "ball"]))


def see_107():
    def deco(s):
        s.stay((FM, 0.5, FT), (1.0, 0.5, V.DECK + 0.7))
        s.allround(FM, FT - 0.3, "rr")
        light(s.c, *s.at(0.99, 0.5, 4.6), "w", r=20)         # forward anchor light (higher)
        light(s.c, *s.at(0.0, 0.5, 3.6), "w", r=20)          # after anchor light
    return _cargo(True, deco)


def see_108():
    def build(c):
        s = V.tanker(c, True)
        s.allround(0.16, 9.9, "rrr", step=1.15)
        s.masthead(0.13, 10.8)
        s.masthead(0.93, 7.2)
        s.sidelights(0.17, 4.6)
        s.sternlight(2.6)
    return V.ship_scene(build)


def see_109():
    def build(c):
        s = V.tanker(c, False)
        s.shapes(0.17, 9.4, ["cyl"])
    return V.ship_scene(build, night=False)


def see_110():
    def build(c):
        s = V.small_vessel(c, True)
        s.allround(0.72, 9.2, "gw", step=1.15)
        s.masthead(0.14, 9.8)
        s.sidelights(0.46, 3.5)
        s.sternlight()
    return V.ship_scene(build)


def see_111():
    def build(c):
        s = V.small_vessel(c, True, stays=True)
        s.allround(0.72, 9.0, "rw", step=1.15)
    return V.ship_scene(build)


def see_112():
    def build(c):
        s = V.small_vessel(c, False, stays=True)
        px, py = s.at(0.72, 0.5, 8.4)
        V.cone(c, px, py - 26, 26, down=True)
        V.cone(c, px, py + 26, 26, down=False)
    return V.ship_scene(build, night=False)


def see_115():
    def build(c):
        s = V.tanker(c, True)
        s.stay((0.13, 0.5, 11.0), (0.0, 0.5, 2.2))
        s.stay((0.93, 0.5, 7.4), (1.0, 0.5, 2.8))
        light(c, *s.at(0.99, 0.5, 5.4), "w", r=21)          # forward anchor light
        light(c, *s.at(0.01, 0.5, 4.2), "w", r=21)          # after anchor light (lower)
        for i in range(10):                                 # deck illumination
            light(c, *s.at(0.22 + i * 0.07, 0.5, 2.4), "y", r=7)
    return V.ship_scene(build)


def see_133():
    return _cargo(False, lambda s: s.shapes(FM, FT - 0.7, ["cyl"]))


def see_134():
    def deco(s):
        s.allround(FM, FT - 1.4, "rrr", step=1.05)
        V.power_lights(s)
    return _cargo(True, deco)


def _dredger_post(s, x=0.95, top=9.5):
    """Signal post at the bow with a cross-arm; returns the arm ends (left, right) in px."""
    s.mast(x, 2.0, top, yard=False)
    px, py = s.at(x, 0.5, top - 0.4)
    s.c.line(px - 95, py, px + 95, py, stroke=s.fg, sw=V.SW)
    return (px - 85, py), (px + 85, py)


def _stack(c, x, y, kinds, step=62):
    for i, k in enumerate(kinds):
        yy = y + 34 + i * step
        if k in ("r", "g", "w"):
            light(c, x, yy, k, r=20)
        elif k == "ball":
            V.ball(c, x, yy, r=25)
        elif k == "rhomb":
            V.rhomb(c, x, yy + 6, s=22)


def _dredger(night, ram_kinds, left, right, way=False):
    def build(c):
        s = V.dredger(c, night)
        s.mast(0.16, 5.4, 13.8 if way else 12.6, yard=False)
        if night:
            s.allround(0.16, 12.0, ram_kinds, step=1.4)
        else:
            s.shapes(0.16, 11.8, ram_kinds, step=1.55)
        (lx, ly), (rx, ry) = _dredger_post(s)
        _stack(c, lx, ly, left)
        _stack(c, rx, ry, right)
        if way:
            s.masthead(0.16, 13.4)
            s.sidelights(0.29, 4.9)
            s.sternlight(1.6)
    return V.ship_scene(build, night=night)


def see_148():
    return _dredger(False, ["ball", "rhomb", "ball"], ["ball", "ball"], ["rhomb", "rhomb"])


def see_149():
    return _dredger(True, "rwr", "rr", "gg", way=True)


def see_150():
    return _dredger(True, "rwr", "rr", "gg")


def see_151():
    def day(c):
        s = V.cargo_ship(c, night=False, ox=30, oy=610, L=540, H=46)
        x, y = s.at(FM, 0.5, FT)
        c.path(f"M {x} {y + 5} L {x + 120} {y + 15} L {x + 85} {y + 50} L {x + 120} {y + 85} L {x} {y + 75} Z",
               fill=RED, stroke=BLACK, sw=3)

    def night(c):
        s = V.cargo_ship(c, night=True, ox=30, oy=610, L=540, H=46)
        s.allround(FM, FT + 0.1, "r")
        V.power_lights(s, fore_masthead=False)
        s.masthead(FM, FT - 1.3)
    return _split(V.ship_scene(day, night=False, w=760), V.ship_scene(night, night=True, w=760))


def see_091():
    def build(c):
        s = V.small_vessel(c, True, L=760)
        s.masthead(0.72, 8.6)
        s.sidelights(0.46, 3.5)
        s.sternlight()
    return V.ship_scene(build)


def see_154():
    def build(c):
        s = V.small_vessel(c, True, L=760)
        V.flash_star(c, *s.at(0.72, 0.5, 10.3), r=50)
        s.masthead(0.72, 8.6)
        s.sidelights(0.46, 3.5)
        s.sternlight()
    return V.ship_scene(build)


# ── Binnen: barge side views ────────────────────────────────────────────────

def binnen_121():
    return V.barge(hanging(("cylinder", YELLOW)), cabin=True)


def binnen_122():
    return V.barge(hanging(("ball", YELLOW)))


def binnen_127():
    return V.barge(hanging(("cone", "#0047BB")))


def binnen_129():
    return V.barge(hanging(("cone", "#0047BB"), ("cone", "#0047BB")))


def binnen_131():
    return V.barge(hanging(("cone", "#0047BB"), ("cone", "#0047BB"), ("cone", "#0047BB")))


def binnen_132():
    return V.barge(hanging(("pennant", RED)), cabin=True)


def binnen_155():
    return V.barge(hanging(("flag_rw", RED)), cabin=True, inset_lights="rw")


# ── catalogue ───────────────────────────────────────────────────────────────

CATALOG = {
    # Basisfragen
    "shared_016": lambda: G.sound_signal(".-.-.-.-.-"),
    "shared_017": G.sign_overtaking_prohibited,
    "shared_018": G.sign_no_meeting,
    "shared_019": G.sign_avoid_wash,
    "shared_020": lambda: G.sign_min_distance("40"),
    "shared_021": lambda: G.sign_symbol_board("hbar"),
    "shared_022": G.sign_no_anchoring,
    "shared_023": G.sign_no_mooring,
    "shared_024": G.sign_long_blast,
    "shared_025": lambda: _split(G.sign_blue("waterski"), G.sign_blue("jetski")),
    "shared_026": G.sign_end_of_restriction,
    "shared_027": G.sign_closed,
    "shared_028": lambda: G.lights_pair("red"),
    "shared_029": lambda: G.lights_pair("red", vertical=True),
    "shared_030": lambda: G.lights_pair("green"),
    # Binnen
    "binnen_107": lambda: G.sign_blue("berth_explosive"),
    "binnen_108": lambda: G.sign_blue("diamond"),
    "binnen_110": lambda: G.bridge_scene([(0.5, "yellow")]),
    "binnen_111": lambda: G.yellow_diamonds("two_or"),
    "binnen_112": lambda: G.passage_marks(RED),
    "binnen_113": lambda: G.passage_marks(GREEN),
    "binnen_114": lambda: G.yellow_diamonds("one"),
    "binnen_115": lambda: G.yellow_diamonds("two"),
    "binnen_116": G.sign_closed,
    "binnen_120": lambda: G.light_panel([("sq", "w", .5, .14), ("sq", "w", .5, .3), ("sq", "g", .25, .82), ("sq", "r", .75, .82)]),
    "binnen_121": binnen_121,
    "binnen_122": binnen_122,
    "binnen_123": lambda: G.light_panel([("sq", "w", .5, .16), ("sq", "w", .43, .36), ("sq", "w", .57, .36),
                                         ("sq", "g", .22, .82), ("sq", "r", .78, .82)]),
    "binnen_124": lambda: G.light_panel([("ci", "g", .5, .25), ("ci", "w", .5, .48)]),
    "binnen_125": lambda: G.light_panel([("ci", "g", .5, .2), ("ci", "w", .5, .42), ("sq", "g", .23, .82), ("sq", "r", .77, .82)]),
    "binnen_127": binnen_127,
    "binnen_129": binnen_129,
    "binnen_131": binnen_131,
    "binnen_132": binnen_132,
    "binnen_145": lambda: V.floating_equipment([("light", "r"), ("light", "w")], [("light", "r"), ("light", "w")], night=True),
    "binnen_146": lambda: V.floating_equipment([("flag", "rw")], [("flag", "rw")]),
    "binnen_147": lambda: V.floating_equipment([("light", "r")], [("light", "r"), ("light", "w")], night=True, tilt=-10),
    "binnen_148": lambda: V.floating_equipment([("flag", "r")], [("flag", "rw")], tilt=-10),
    "binnen_149": lambda: V.floating_equipment([("light", "r")], [("light", "g"), ("light", "g")], night=True, embankment=True),
    "binnen_150": lambda: V.floating_equipment([("ball", "r")], [("rhomb", "g"), ("rhomb", "g")], embankment=True),
    "binnen_151": lambda: V.floating_equipment([("board_h", "")], [("board_v", "")], embankment=True),
    "binnen_152": lambda: V.floating_equipment([("light", "g"), ("light", "g")], [("light", "g"), ("light", "g")], night=True),
    "binnen_153": lambda: V.floating_equipment([("rhomb", "g"), ("rhomb", "g")], [("rhomb", "g"), ("rhomb", "g")]),
    "binnen_154": lambda: V.floating_equipment([("board_v", "")], [("board_v", "")]),
    "binnen_155": binnen_155,
    "binnen_156": G.sign_no_entry_round,
    "binnen_157": G.sign_no_motor,
    "binnen_162": lambda: G.sound_signal("-."),
    "binnen_163": lambda: G.sound_signal("-.."),
    "binnen_164": lambda: G.sound_signal("--."),
    "binnen_165": lambda: G.sound_signal("--.."),
    "binnen_166": lambda: G.sound_signal("---."),
    "binnen_167": lambda: G.sound_signal("---.."),
    "binnen_180": lambda: S.scenario("binnen_180"),
    "binnen_183": lambda: S.scenario("binnen_183"),
    "binnen_185": lambda: S.scenario("binnen_185"),
    "binnen_186": lambda: S.scenario("binnen_186"),
    "binnen_188": lambda: S.scenario("binnen_188"),
    "binnen_189": lambda: S.scenario("binnen_189"),
    "segeln_295": S.manoeuvre_course,
    "binnen_192": lambda: G.light_panel([("sq", "g", .25, .8), ("sq", "w", .75, .8)]),
    "binnen_193": lambda: G.light_panel([("sq", "g", .25, .8), ("sq", "w", .75, .8)]),
    "binnen_196": lambda: G.light_panel([("ci", "r", .5, .28), ("ci", "w", .5, .62)]),
    "binnen_198": G.sign_direction,
    "binnen_199": G.entry_prohibited_chevron,
    "binnen_200": lambda: G.sign_symbol_board("10"),
    "binnen_201": lambda: G.sign_symbol_board("vbar"),
    "binnen_202": lambda: G.sign_no_turning(True),
    "binnen_203": lambda: G.sign_no_turning(False),
    "binnen_204": lambda: G.sign_blue("weir"),
    "binnen_243": lambda: G.bridge_scene([(0.32, "redwhite_r"), (0.5, "yellow"), (0.68, "redwhite_l")]),
    "binnen_244": G.sign_closed,
    # See
    "see_091": see_091,
    "see_092": see_092,
    "see_093": lambda: _tow(1, 2),
    "see_094": lambda: _tow(2, 3),
    "see_097": see_097,
    "see_098": see_098,
    "see_099": see_099,
    "see_102": see_102,
    "see_103": see_103,
    "see_104": see_104,
    "see_105": see_105,
    "see_106": see_106,
    "see_107": see_107,
    "see_108": see_108,
    "see_109": see_109,
    "see_110": see_110,
    "see_111": see_111,
    "see_112": see_112,
    "see_115": see_115,
    "see_116": lambda: G.sound_signal("-", brackets=False),
    "see_117": lambda: G.sound_signal("--", brackets=False),
    "see_118": lambda: G.sound_signal("-.."),
    "see_119": lambda: G.sound_signal("-..."),
    "see_122": G.bell_signal,
    "see_123": G.bell_signal,
    "see_133": see_133,
    "see_134": see_134,
    "see_140": lambda: G.sound_signal(".....", brackets=False),
    "see_141": lambda: G.sound_signal(".-."),
    "see_148": see_148,
    "see_149": see_149,
    "see_150": see_150,
    "see_151": see_151,
    "see_154": see_154,
    "see_162": lambda: G.sound_signal("-....", "-...."),
    "see_176": lambda: G.sign_symbol_board("12"),
    "see_177": lambda: M.signal_mast(["red_flag"]),
    "see_178": lambda: G.sound_signal("...."),
    "see_179": M.bathing_cross_post,
    "see_180": M.bathing_area_buoy,
    "see_182": M.special_marks,
    "see_184": M.restricted_area,
    "see_185": G.flag_L,
    "see_186": lambda: G.sound_signal(".-.."),
    "see_187": lambda: M.signal_mast(["ball", "cone_down", "cone_up"]),
    "see_188": lambda: G.sound_signal("--- ---"),
    "see_189": lambda: M.signal_mast(["ball", "ball", "cone_down"]),
    "see_190": M.safe_water,
    "see_191": lambda: M.withies(port=False),
    "see_192": lambda: M.withies(port=True),
    "see_193": M.lateral_starboard,
    "see_194": M.lateral_port,
    "see_195": lambda: M.branch_buoy(True),
    "see_196": lambda: M.branch_buoy(False),
    "see_200": lambda: M.cardinal("N"),
    "see_201": lambda: M.cardinal("E"),
    "see_202": lambda: M.cardinal("S"),
    "see_203": lambda: M.cardinal("W"),
    "see_204": lambda: M.light_rhythm("N"),
    "see_205": lambda: M.light_rhythm("E"),
    "see_206": lambda: M.light_rhythm("S"),
    "see_207": lambda: M.light_rhythm("W"),
    "see_208": M.isolated_danger,
    "see_260": M.wind_symbol,
    "see_265": M.high_pressure,
    "see_266": M.low_pressure,
    "see_282": G.morse_sos,
    "see_284": G.flags_NC,
    "see_285": G.flag_and_ball,
}

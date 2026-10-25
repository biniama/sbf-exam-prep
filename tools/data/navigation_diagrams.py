"""Step-by-step solution diagrams for the navigation tasks (feature flag navigationDiagrams).

No chart is reproduced. The geometry comes from the official results only: given positions,
true courses with distances (speed × time), dead-reckoning positions and set and drift. Marks that
appear in several tasks (e.g. "ST", "A2") are located once and reused; the official results agree
with each other to about 0.1 nm. Bearing lines are drawn through the fix with the official true
bearing, so they are exact even where the object itself lies outside the drawing.

Coordinates are nautical miles east (x) and north (y) of each diagram's centre; the apps draw a
latitude/longitude grid from ``grid`` (centre and cos(latitude)).
"""

from __future__ import annotations

import math
import re

# Reference for computing shared mark positions (any nearby point works).
_LAT0, _LON0 = 53 + 54 / 60, 8.0
_K = math.cos(math.radians(_LAT0))


def _xy(lat, lon):
    return ((lon[0] + lon[1] / 60 - _LON0) * 60 * _K, (lat[0] + lat[1] / 60 - _LAT0) * 60)


def _mv(p, bearing, d):
    r = math.radians(bearing)
    return (p[0] + d * math.sin(r), p[1] + d * math.cos(r))


def _brg(a, b):
    return math.degrees(math.atan2(b[0] - a[0], b[1] - a[1])) % 360


def _intersect(p, b1, q, b2):
    """Intersection of the line through p with bearing b1 and the line through q with bearing b2."""
    d1 = (math.sin(math.radians(b1)), math.cos(math.radians(b1)))
    d2 = (math.sin(math.radians(b2)), math.cos(math.radians(b2)))
    det = d1[0] * -d2[1] - d1[1] * -d2[0]
    t = ((q[0] - p[0]) * -d2[1] - (q[1] - p[1]) * -d2[0]) / det
    return (p[0] + t * d1[0], p[1] + t * d1[1])


def _latlon(p):
    return _LAT0 + p[1] / 60, _LON0 + p[0] / 60 / _K


# Shared marks, located from the official results.
MARKS: dict[str, tuple[float, float]] = {}
_dr1 = _xy((53, 55.8), (7, 51.3))
MARKS["TG19/Weser 2"] = _mv(_dr1, 259, 4.0)
MARKS["ST"] = _mv(MARKS["TG19/Weser 2"], 79, 6.1)
MARKS["Helgoland-O"] = _xy((54, 9.0), (7, 53.5))
MARKS["Außenelbe-Reede 4"] = _mv(MARKS["Helgoland-O"], 120, 11.1)
MARKS["1b/Jade 1"] = _xy((53, 52.4), (7, 44.0))
MARKS["Accumer Ee"] = _xy((53, 47.2), (7, 29.1))
MARKS["A2"] = _xy((53, 55.3), (7, 58.8))
MARKS["Westertill-N"] = _mv(MARKS["A2"], 59, 5.4)
MARKS["Außenelbe-Reede 2"] = _xy((54, 3.5), (8, 6.9))
MARKS["NGN"] = _mv(MARKS["Außenelbe-Reede 2"], 216, 7.6)
MARKS["A10"] = _xy((53, 52.6), (8, 6.4))
MARKS["10"] = _xy((53, 50.0), (7, 53.4))
MARKS["Leuchtturm Alte Weser"] = _mv(_xy((53, 56.0), (8, 11.0)), 205, 4.6)
_fix5 = _xy((53, 49.7), (7, 35.8))
MARKS["Otzumer Balje"] = _intersect(MARKS["Accumer Ee"], 81, _fix5, 127)


_EN_WORDS = [
    ("beob. Ort (20-m-Linie)", "fix (20 m contour)"), ("beob. Ort", "fix"), ("Koppelort", "DR"),
    ("GPS-Position", "GPS position"), ("Verkehrstrennungsgebiet", "traffic separation scheme"), ("Standort", "position"),
    ("Position", "position"), ("querab E3", "E3 abeam"), ("Leuchtturm Alte Weser", "Alte Weser lighthouse"),
    ("Wasserturm", "water tower"), ("Tonne ", "buoy "), ("Container", "containers"),
]


def _english(label: str) -> str:
    for de, en in _EN_WORDS:
        label = label.replace(de, en)
    label = re.sub(r"(\d),(\d)", r"\1.\2", label)
    return label.replace(" sm", " nm").replace("rwK", "true").replace("BV", "set/drift")


class Diagram:
    def __init__(self):
        self.elements: list[dict] = []
        self.frames: list[dict] = []
        self._shown: list[str] = []

    def point(self, pid, p, label, style, sub=None):
        self.elements.append({"id": pid, "type": "point", "x": p[0], "y": p[1], "label": label,
                              "label_en": _english(label), "style": style, **({"sub": sub} if sub else {})})
        return p

    def line(self, lid, a, b, style, label=None):
        self.elements.append({"id": lid, "type": "line", "x1": a[0], "y1": a[1], "x2": b[0], "y2": b[1], "style": style,
                              **({"label": label, "label_en": _english(label)} if label else {})})

    def ray(self, lid, through, bearing, style, label, length=2.5):
        """A bearing line through the fix towards the object (object may lie outside the drawing)."""
        self.line(lid, _mv(through, bearing + 180, 0.6), _mv(through, bearing, length), style, label)

    def frame(self, show, de, en, step=None):
        # Every frame highlights something; frames that only explain arithmetic re-highlight what they refer to.
        assert show, f"empty frame: {en}"
        self.frames.append({"show": show, "de": de, "en": en, **({"step": step} if step else {})})

    def build(self) -> dict:
        xs = [e["x"] for e in self.elements if e["type"] == "point"] + \
             [v for e in self.elements if e["type"] == "line" for v in (e["x1"], e["x2"])]
        ys = [e["y"] for e in self.elements if e["type"] == "point"] + \
             [v for e in self.elements if e["type"] == "line" for v in (e["y1"], e["y2"])]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        for e in self.elements:
            for kx, ky in (("x", "y"), ("x1", "y1"), ("x2", "y2")):
                if kx in e:
                    e[kx] = round(e[kx] - cx, 3)
                    e[ky] = round(e[ky] - cy, 3)
        lat, lon = _latlon((cx, cy))
        return {
            "grid": {"lat": round(lat, 5), "lon": round(lon, 5), "k": round(math.cos(math.radians(lat)), 5)},
            "width": round(max(xs) - min(xs), 3), "height": round(max(ys) - min(ys), 3),
            "elements": self.elements, "frames": self.frames,
        }


def _deg(b):
    return f"{round(b) % 360:03d}°"


def task1() -> Diagram:
    d = Diagram()
    s, st = MARKS["TG19/Weser 2"], MARKS["ST"]
    dr = _mv(s, 79, 4.0)
    fix = _mv(dr, 103, 0.8)
    d.point("S", s, "TG19/Weser 2", "mark", "10:00")
    d.point("T", st, "ST", "mark")
    d.line("C", s, st, "course", "rwK 079° · 6,1 sm")
    d.point("DR", dr, "Koppelort", "dr", "10:30")
    d.ray("B1", fix, 170, "bearing", "4a · 170°")
    d.ray("B2", fix, 65, "bearing", "ST · 065°", length=2.3)
    d.point("F", fix, "beob. Ort", "fix", "10:30")
    d.line("BV", dr, fix, "set_drift", "BV 103° · 0,8 sm")
    d.frame(["S", "T"], "Um 10:00 Uhr passiert das Boot die Tonne TG19/Weser 2. Ziel ist die Ansteuerungstonne ST.",
            "At 10:00 the boat passes buoy TG19/Weser 2. The destination is the landfall buoy ST.")
    d.frame(["C"], "Kurslinie zwischen beiden Tonnen zeichnen: rechtweisender Kurs 079°, Distanz 6,1 Seemeilen.",
            "Draw the course line between the buoys: true course 079°, distance 6.1 nautical miles.", step=1)
    d.frame(["DR"], "In 30 Minuten legt das Boot bei 8 Knoten 4 Seemeilen zurück. Diese Distanz auf der Kurslinie abtragen: Koppelort 10:30 Uhr.",
            "In 30 minutes at 8 knots the boat covers 4 nautical miles. Mark this off along the course line: dead-reckoning position at 10:30.", step=5)
    d.frame(["B1"], "Erste Standlinie: Peilung zur Tonne 4a, rechtweisend 170°.",
            "First position line: bearing to buoy 4a, true 170°.", step=7)
    d.frame(["B2", "F"], "Zweite Standlinie: Peilung zur Tonne ST, rechtweisend 065°. Der Schnittpunkt ist der beobachtete Ort.",
            "Second position line: bearing to buoy ST, true 065°. Where the lines cross is the observed position.", step=7)
    d.frame(["BV"], "Vom Koppelort zum beobachteten Ort: Besteckversetzung 103°, 0,8 Seemeilen. So weit haben Strom und Wind das Boot versetzt.",
            "From the dead-reckoning position to the observed position: set and drift 103°, 0.8 nautical miles. That is how far current and wind have moved the boat.", step=8)
    return d


def task2() -> Diagram:
    d = Diagram()
    p, ar4 = MARKS["Helgoland-O"], MARKS["Außenelbe-Reede 4"]
    dr = _mv(p, 120, 9.0)
    fix = _mv(dr, 7, 1.6)
    d.point("P", p, "Helgoland-O", "mark", "11:00")
    d.line("C", p, ar4, "course", "rwK 120° · 11,1 sm")
    d.point("A", ar4, "Außenelbe-Reede 4", "mark")
    d.point("DR", dr, "Koppelort", "dr", "11:54")
    d.ray("B", fix, 147, "bearing", "Außenelbe-Reede 4 · 147°", length=_brg_len(fix, ar4))
    d.point("F", fix, "beob. Ort (20-m-Linie)", "fix", "11:54")
    d.line("BV", dr, fix, "set_drift", "BV 007° · 1,6 sm")
    d.frame(["P"], "Um 11:00 Uhr wird die Tonne Helgoland-O passiert.", "At 11:00 buoy Helgoland-O is passed.")
    d.frame(["C", "A"], "MgK 116° wird zum rechtweisenden Kurs 120°. Kurslinie zeichnen; nach 11,1 Seemeilen liegt die Tonne Außenelbe-Reede 4.",
            "MgK 116° becomes true course 120°. Draw the course line; after 11.1 nautical miles lies buoy Außenelbe-Reede 4.", step=4)
    d.frame(["DR"], "Bis 11:54 Uhr sind es 54 Minuten bei 10 Knoten, also 9 Seemeilen: Koppelort.",
            "Until 11:54 that is 54 minutes at 10 knots, so 9 nautical miles: dead-reckoning position.", step=7)
    d.frame(["B", "F"], "Peilung zur Tonne Außenelbe-Reede 4: rechtweisend 147°. Wo diese Standlinie die 20-Meter-Linie schneidet, steht das Boot.",
            "Bearing to buoy Außenelbe-Reede 4: true 147°. Where this position line meets the 20-metre contour is the boat's position.", step=9)
    d.frame(["BV"], "Besteckversetzung vom Koppelort zum beobachteten Ort: 007°, 1,6 Seemeilen.",
            "Set and drift from the dead-reckoning position to the observed position: 007°, 1.6 nautical miles.", step=9)
    return d


def _brg_len(a, b):
    return math.hypot(b[0] - a[0], b[1] - a[1])


def task3() -> Diagram:
    d = Diagram()
    p, acc = MARKS["1b/Jade 1"], MARKS["Accumer Ee"]
    dr = _mv(p, 240, 6.0)
    d.point("P", p, "1b/Jade 1", "mark", "13:30")
    d.point("A", acc, "Accumer Ee", "mark", "15:12")
    d.line("C", p, acc, "course", "rwK 240°")
    d.point("DR", dr, "Koppelort", "dr", "14:30")
    d.ray("B", acc, 52, "bearing", "Accumer Ee · 232°", length=4.0)
    d.frame(["P"], "Um 13:30 Uhr wird die Tonne 1b/Jade 1 passiert.", "At 13:30 buoy 1b/Jade 1 is passed.")
    d.frame(["C", "A"], "Kurs auf die Tonne Accumer Ee: rechtweisend 240°. Die Distanz von etwa 10,2 Seemeilen dauert bei 6 Knoten 102 Minuten: Ankunft 15:12 Uhr.",
            "Course to buoy Accumer Ee: true 240°. The distance of about 10.2 nautical miles takes 102 minutes at 6 knots: arrival 15:12.", step=2)
    d.frame(["DR"], "Um 14:30 Uhr hat das Boot 6 Seemeilen zurückgelegt.", "By 14:30 the boat has covered 6 nautical miles.")
    d.frame(["B"], "Kreuzpeilung: Die Standlinie zur Tonne Accumer Ee verläuft mit 232° durch die Tonne. Die Standlinien zu TG15 (290°) und TG17/Weser1 (345°) werden genauso gezeichnet; wo sich alle drei schneiden, steht das Boot.",
            "Cross bearing: the position line to buoy Accumer Ee runs through the buoy at 232°. The lines to TG15 (290°) and TG17/Weser1 (345°) are drawn the same way; where all three cross is the boat's position.", step=8)
    return d


def task4() -> Diagram:
    d = Diagram()
    p, otz = MARKS["Accumer Ee"], MARKS["Otzumer Balje"]
    dr = _mv(p, 81, 6.0)
    d.point("P", p, "Accumer Ee", "mark", "09:00")
    d.point("O", otz, "Otzumer Balje", "mark")
    d.line("C", p, otz, "course", "rwK 081°")
    d.point("DR", dr, "Koppelort", "dr", "10:00")
    d.ray("B", otz, 215, "bearing", "Otzumer Balje · 035°", length=3.0)
    d.frame(["P"], "Um 09:00 Uhr ist das Boot an der Tonne Accumer Ee.", "At 09:00 the boat is at buoy Accumer Ee.")
    d.frame(["C", "O"], "Kurs auf die Tonne Otzumer Balje: rechtweisend 081°.", "Course to buoy Otzumer Balje: true 081°.", step=2)
    d.frame(["DR"], "Eine Stunde bei 6 Knoten: 6 Seemeilen auf der Kurslinie abtragen, Koppelort 10:00 Uhr.",
            "One hour at 6 knots: mark off 6 nautical miles along the course line, dead-reckoning position at 10:00.", step=6)
    d.frame(["B"], "Um 10:15 Uhr: Standlinie zur Tonne Otzumer Balje mit 035° durch die Tonne. Die Peilung zur Kirche (115°) ergibt die zweite Standlinie.",
            "At 10:15: position line to buoy Otzumer Balje at 035° through the buoy. The bearing to the church (115°) gives the second line.", step=9)
    return d


def task5() -> Diagram:
    d = Diagram()
    fix = _fix5
    otz = MARKS["Otzumer Balje"]
    jade = MARKS["1b/Jade 1"]
    dr = _mv(fix, 61, 1.1)
    d.ray("B1", fix, 221, "bearing", "Wasserturm · 221°")
    d.ray("B2", fix, 127, "bearing", "Otzumer Balje · 127°", length=_brg_len(fix, otz))
    d.point("O", otz, "Otzumer Balje", "mark")
    d.point("F", fix, "beob. Ort", "fix", "14:00")
    d.line("C", fix, jade, "course", "rwK 061° · 5,5 sm")
    d.point("J", jade, "1b/Jade 1", "mark", "14:30")
    d.point("DR", dr, "Koppelort", "dr", "14:06")
    d.frame(["B1"], "Erste Standlinie: Wasserturm Langeoog, rechtweisend 221°.", "First position line: Langeoog water tower, true 221°.", step=2)
    d.frame(["B2", "O", "F"], "Zweite Standlinie: Tonne Otzumer Balje, rechtweisend 127°. Der Schnittpunkt ist der Standort um 14:00 Uhr.",
            "Second position line: buoy Otzumer Balje, true 127°. The crossing point is the position at 14:00.", step=3)
    d.frame(["C", "J"], "Kurs auf die Tonne 1b/Jade 1: rechtweisend 061°. Bei 11 Knoten sind die 5,5 Seemeilen nach 30 Minuten zurückgelegt: 14:30 Uhr.",
            "Course to buoy 1b/Jade 1: true 061°. At 11 knots the 5.5 nautical miles take 30 minutes: 14:30.", step=4)
    d.frame(["DR"], "Maschinenschaden um 14:06 Uhr: 6 Minuten bei 11 Knoten sind 1,1 Seemeilen. Koppelort.",
            "Engine failure at 14:06: 6 minutes at 11 knots is 1.1 nautical miles. Dead-reckoning position.", step=9)
    return d


def task6() -> Diagram:
    d = Diagram()
    a2, w, lt = MARKS["A2"], MARKS["Westertill-N"], MARKS["Leuchtturm Alte Weser"]
    fix = _intersect(lt, 159 + 180, w, 55 + 180)
    d.point("P", a2, "A2", "mark", "09:00")
    d.point("W", w, "Westertill-N", "mark", "09:54")
    d.line("C", a2, w, "course", "rwK 059° · 5,4 sm")
    d.point("L", lt, "Leuchtturm Alte Weser", "mark")
    d.line("B1", fix, lt, "bearing", "159°")
    d.line("B2", fix, w, "bearing", "055°")
    d.point("F", fix, "beob. Ort", "fix")
    d.frame(["P"], "Um 09:00 Uhr steht das Boot an der Tonne A2.", "At 09:00 the boat is at buoy A2.")
    d.frame(["C", "W"], "Kurs auf die Tonne Westertill-N: rechtweisend 059°.", "Course to buoy Westertill-N: true 059°.", step=2)
    d.frame(["L", "B1", "B2", "F"], "Peilungen zum Leuchtturm Alte Weser (159°) und zur Tonne Westertill-N (055°) durch die Objekte zeichnen. Der Schnittpunkt ist der beobachtete Ort.",
            "Draw the bearings of lighthouse Alte Weser (159°) and buoy Westertill-N (055°) through the objects. The crossing point is the observed position.", step=7)
    d.frame(["C", "W"], "Um 09:54 Uhr ist die Tonne Westertill-N erreicht: 5,4 Seemeilen in 54 Minuten ergeben 6 Knoten.",
            "At 09:54 buoy Westertill-N is reached: 5.4 nautical miles in 54 minutes gives 6 knots.", step=8)
    return d


def task7() -> Diagram:
    d = Diagram()
    p, ngn = MARKS["Außenelbe-Reede 2"], MARKS["NGN"]
    dr = _mv(p, 216, 8.0)
    fix = _mv(dr, 273, 1.1)
    d.point("P", p, "Außenelbe-Reede 2", "mark", "11:00")
    d.line("C", p, dr, "course", "rwK 216°")
    d.point("N", ngn, "NGN", "mark", "11:57")
    d.point("DR", dr, "Koppelort", "dr", "12:00")
    d.ray("B1", fix, 241, "bearing", "ST · 241°")
    d.ray("B2", fix, 151, "bearing", "A2 · 151°")
    d.point("F", fix, "beob. Ort", "fix", "12:00")
    d.line("BV", dr, fix, "set_drift", "BV 273° · 1,1 sm")
    d.frame(["P"], "Um 11:00 Uhr steht das Boot an der Tonne Außenelbe-Reede 2.", "At 11:00 the boat is at buoy Außenelbe-Reede 2.")
    d.frame(["C", "N"], "MgK 218° wird zum rechtweisenden Kurs 216°. Bei 8 Knoten ist die Tonne NGN nach 7,6 Seemeilen um 11:57 Uhr erreicht.",
            "MgK 218° becomes true course 216°. At 8 knots buoy NGN is reached after 7.6 nautical miles at 11:57.", step=4)
    d.frame(["DR"], "Koppelort 12:00 Uhr: eine Stunde bei 8 Knoten, also 8 Seemeilen.",
            "Dead-reckoning position at 12:00: one hour at 8 knots, so 8 nautical miles.")
    d.frame(["B1", "B2", "F"], "Peilungen zu den Tonnen ST (241°) und A2 (151°): Der Schnittpunkt ist der beobachtete Ort.",
            "Bearings of buoys ST (241°) and A2 (151°): the crossing point is the observed position.", step=8)
    d.frame(["BV"], "Besteckversetzung vom Koppelort zum beobachteten Ort: 273°, 1,1 Seemeilen.",
            "Set and drift from the dead-reckoning position to the observed position: 273°, 1.1 nautical miles.", step=9)
    return d


def task8() -> Diagram:
    d = Diagram()
    pos = _xy((54, 7.0), (7, 41.0))
    e2 = _mv(pos, 84, 1.6)
    tss = _mv(pos, 232, 3.8)
    out = _mv(tss, 242, 3.0)
    d.point("E", e2, "E2", "mark")
    d.line("B", pos, e2, "bearing", "084° · 1,6 sm")
    d.point("F", pos, "Standort", "fix", "10:00")
    d.line("C", pos, tss, "course", "rwK 232° · 3,8 sm")
    d.point("V", tss, "Verkehrstrennungsgebiet", "dr")
    d.line("X", tss, out, "track", "rwK 242° · 20 min")
    d.frame(["E", "B", "F"], "Peilung und Abstand: Die Tonne E2 liegt rechtweisend 084° in 1,6 Seemeilen. Vom Boot aus gesehen, also auf der Peillinie 1,6 Seemeilen von der Tonne entfernt.",
            "Bearing and distance: buoy E2 bears true 084° at 1.6 nautical miles. The boat is on the bearing line, 1.6 nautical miles from the buoy.", step=2)
    d.frame(["C", "V"], "Kurs auf das Verkehrstrennungsgebiet: rechtweisend 232°, Distanz 3,8 Seemeilen.",
            "Course to the traffic separation scheme: true 232°, distance 3.8 nautical miles.", step=5)
    d.frame(["X"], "Das Verkehrstrennungsgebiet wird rechtwinklig gequert: 242°. Bei 9 Knoten dauern die 3 Seemeilen 20 Minuten.",
            "The traffic separation scheme is crossed at right angles: 242°. At 9 knots the 3 nautical miles take 20 minutes.", step=8)
    return d


def task9() -> Diagram:
    d = Diagram()
    g = _xy((53, 56.0), (8, 11.0))
    lt = MARKS["Leuchtturm Alte Weser"]
    d.point("G", g, "GPS-Position", "gps", "14:20")
    d.line("B2", g, lt, "bearing", "205° · 4,6 sm")
    d.point("L", lt, "Leuchtturm Alte Weser", "mark", "15:20")
    d.ray("B1", g, 96, "bearing", "Neuwerk · 096°", length=3.0)
    d.frame(["G"], "Um 14:20 Uhr wird die GPS-Position 53° 56,0' N, 008° 11,0' E in die Karte eingetragen.",
            "At 14:20 the GPS position 53° 56.0' N, 008° 11.0' E is plotted on the chart.", step=5)
    d.frame(["B1", "B2", "L"], "Von dieser Position aus die Richtungen zu den Leuchttürmen messen: Neuwerk 096°, Alte Weser 205°. Distanz zum Leuchtturm Alte Weser: 4,6 Seemeilen.",
            "From this position measure the directions to the lighthouses: Neuwerk 096°, Alte Weser 205°. Distance to lighthouse Alte Weser: 4.6 nautical miles.", step=8)
    d.frame(["B2", "L"], "Um 15:20 Uhr ist der Leuchtturm erreicht: 4,6 Seemeilen in einer Stunde sind 4,6 Knoten.",
            "At 15:20 the lighthouse is reached: 4.6 nautical miles in one hour is 4.6 knots.", step=9)
    return d


def task10() -> Diagram:
    d = Diagram()
    a10, a2, st, ngn = MARKS["A10"], MARKS["A2"], MARKS["ST"], MARKS["NGN"]
    fix = _intersect(ngn, 112 + 180, st, 227 + 180)
    d.point("P", a10, "A10", "mark", "12:00")
    d.point("A", a2, "A2", "mark", "12:26")
    d.line("C", a10, a2, "course", "rwK 301° · 5,2 sm")
    d.point("S", st, "ST", "mark")
    d.point("N", ngn, "NGN", "mark")
    d.line("B1", fix, ngn, "bearing", "112°")
    d.line("B2", fix, st, "bearing", "227°")
    d.point("F", fix, "beob. Ort", "fix")
    d.frame(["P"], "Um 12:00 Uhr steht das Fahrzeug an der Tonne A10.", "At 12:00 the vessel is at buoy A10.")
    d.frame(["C", "A"], "Kurs auf die Tonne A2: rechtweisend 301°. 5,2 Seemeilen in 26 Minuten ergeben 12 Knoten.",
            "Course to buoy A2: true 301°. 5.2 nautical miles in 26 minutes gives 12 knots.", step=6)
    d.frame(["S", "N", "B1", "B2", "F"], "Peilungen zu den Tonnen Nordergründe-N (112°) und ST (227°) durch die Tonnen zeichnen. Der Schnittpunkt ist der beobachtete Ort.",
            "Draw the bearings of buoys Nordergründe-N (112°) and ST (227°) through the buoys. The crossing point is the observed position.", step=9)
    return d


def task11() -> Diagram:
    d = Diagram()
    p = _xy((53, 54.2), (7, 53.8))
    t5 = _mv(p, 148, 3.7)
    lt = MARKS["Leuchtturm Alte Weser"]
    d.point("P", p, "Position", "gps", "09:00")
    d.line("C", p, t5, "course", "rwK 148° · 3,7 sm")
    d.point("T", t5, "Tonne 5", "mark", "09:37")
    d.point("L", lt, "Leuchtturm Alte Weser", "mark")
    d.ray("B", lt, 12 + 180, "bearing", "012°", length=5.0)
    d.frame(["P"], "Um 09:00 Uhr wird die Position 53° 54,2' N, 007° 53,8' E eingetragen.",
            "At 09:00 the position 53° 54.2' N, 007° 53.8' E is plotted.", step=1)
    d.frame(["C", "T"], "Kurs auf die Tonne 5 der Neuen Weser: rechtweisend 148°. 3,7 Seemeilen bei 6 Knoten dauern 37 Minuten: 09:37 Uhr.",
            "Course to buoy 5 of the Neue Weser: true 148°. 3.7 nautical miles at 6 knots take 37 minutes: 09:37.", step=4)
    d.frame(["L", "B"], "Später: Standlinie zum Leuchtturm Alte Weser, rechtweisend 012°, durch den Leuchtturm. Die Peilung Tegeler Plate (103°) ergibt die zweite Standlinie.",
            "Later: position line to lighthouse Alte Weser, true 012°, through the lighthouse. The bearing of Tegeler Plate (103°) gives the second line.", step=9)
    return d


def task12() -> Diagram:
    d = Diagram()
    p, st = MARKS["10"], MARKS["ST"]
    dr830 = _mv(p, 7, 4.0)
    dr900 = _mv(p, 7, 8.0)
    fix = _mv(dr900, 296, 0.7)
    d.point("P", p, "Tonne 10", "mark", "08:00")
    d.line("C", p, dr900, "course", "rwK 007°")
    d.point("DR1", dr830, "Koppelort", "dr", "08:30")
    d.point("S", st, "ST", "mark")
    d.point("DR2", dr900, "Koppelort", "dr", "09:00")
    d.line("B", fix, st, "bearing", "168° · 2,0 sm")
    d.point("F", fix, "beob. Ort", "fix", "09:00")
    d.line("BV", dr900, fix, "set_drift", "BV 296° · 0,7 sm")
    d.frame(["P"], "Um 08:00 Uhr steht das Boot an der Tonne 10 des Wangerooger Fahrwassers.",
            "At 08:00 the boat is at buoy 10 of the Wangerooge fairway.")
    d.frame(["C", "S"], "Kurs auf die Tonne ST: rechtweisend 007°.", "Course to buoy ST: true 007°.", step=2)
    d.frame(["DR1"], "Um 08:30 Uhr: 30 Minuten bei 8 Knoten sind 4 Seemeilen. Koppelort für die Meldung des Ölfasses.",
            "At 08:30: 30 minutes at 8 knots is 4 nautical miles. Dead-reckoning position for the oil drum report.", step=6)
    d.frame(["DR2", "B", "F"], "Um 09:00 Uhr: Tonne ST in rechtweisend 168° und 2,0 Seemeilen. Vom Boot aus auf der Peillinie 2,0 Seemeilen von der Tonne: beobachteter Ort.",
            "At 09:00: buoy ST bears true 168° at 2.0 nautical miles. On the bearing line, 2.0 nautical miles from the buoy: observed position.", step=7)
    d.frame(["BV"], "Besteckversetzung vom Koppelort 09:00 Uhr zum beobachteten Ort: 296°, 0,7 Seemeilen.",
            "Set and drift from the 09:00 dead-reckoning position to the observed position: 296°, 0.7 nautical miles.", step=8)
    return d


def task13() -> Diagram:
    d = Diagram()
    fix = _xy((54, 8.6), (7, 55.7))
    e3 = _mv(fix, 182, 5.0)
    d.ray("B1", fix, 285, "bearing", "Helgoland-O · 285°", length=1.6)
    d.ray("B2", fix, 9, "bearing", "Düne-S · 009°", length=1.6)
    d.point("F", fix, "beob. Ort", "fix", "09:00")
    d.line("C", fix, e3, "course", "rwK 182°")
    d.point("E", e3, "querab E3", "dr", "09:40")
    d.frame(["B1", "B2", "F"], "Peilungen zu den Tonnen Helgoland-O (285°) und Düne-S (009°): Der Schnittpunkt ist der Standort um 09:00 Uhr.",
            "Bearings of buoys Helgoland-O (285°) and Düne-S (009°): the crossing point is the position at 09:00.", step=3)
    d.frame(["C"], "Kurs auf die Tonne ST: rechtweisend 182°.", "Course to buoy ST: true 182°.", step=5)
    d.frame(["E"], "Um 09:40 Uhr ist die Tonne E3 querab: 5 Seemeilen in 40 Minuten ergeben 7,5 Knoten.",
            "At 09:40 buoy E3 is abeam: 5 nautical miles in 40 minutes gives 7.5 knots.", step=8)
    return d


def task15() -> Diagram:
    d = Diagram()
    fix = _xy((53, 54.9), (8, 7.6))
    b1 = _mv(fix, 37, 5.4)
    obst = _mv(fix, 37, 1.8)
    cont = _xy((53, 59.6), (8, 23.2))
    d.ray("B1", fix, 180, "bearing", "Alte Weser · 180°", length=2.0)
    d.ray("B2", fix, 90, "bearing", "Neuwerk · 090°", length=2.0)
    d.point("F", fix, "beob. Ort", "fix", "09:00")
    d.line("C", fix, b1, "course", "rwK 037° · 5,4 sm")
    d.point("O", obst, "Obstn", "dr")
    d.point("B", b1, "Tonne 1", "mark")
    d.point("K", cont, "Container", "gps")
    d.frame(["B1", "B2", "F"], "Peilungen zu den Leuchttürmen Alte Weser (180°) und Neuwerk (090°): Der Schnittpunkt ist der Standort um 09:00 Uhr.",
            "Bearings of lighthouses Alte Weser (180°) and Neuwerk (090°): the crossing point is the position at 09:00.", step=2)
    d.frame(["C", "B"], "Kurs auf die Tonne 1 des Elbefahrwassers: rechtweisend 037°, Distanz 5,4 Seemeilen.",
            "Course to buoy 1 of the Elbe fairway: true 037°, distance 5.4 nautical miles.", step=6)
    d.frame(["O"], "Nach 1,8 Seemeilen kreuzt der Kurs ein Schifffahrtshindernis (Obstn) mit 9,7 m Kartentiefe.",
            "After 1.8 nautical miles the course crosses an obstruction (Obstn) with 9.7 m charted depth.", step=7)
    d.frame(["K"], "Die gemeldete Position der Container eintragen: 53° 59,6' N, 008° 23,2' E.",
            "Plot the reported position of the containers: 53° 59.6' N, 008° 23.2' E.", step=9)
    return d


BUILDERS = {1: task1, 2: task2, 3: task3, 4: task4, 5: task5, 6: task6, 7: task7, 8: task8, 9: task9,
            10: task10, 11: task11, 12: task12, 13: task13, 15: task15}


def diagram(task_number: int) -> dict | None:
    """Diagram for a task, or None where the official results do not fix the geometry (task 14)."""
    builder = BUILDERS.get(task_number)
    return builder().build() if builder else None

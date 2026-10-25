#!/usr/bin/env python3
"""Import the 15 ELWIS navigation tasks (SBF See, chart D49) into shared/navigation_tasks.json.

Keeps the German texts and official results verbatim, adds the English translations from
``navigation_en.json`` and the structured values from ``navigation_values.json`` (used for the
worked solutions, drills, diagrams and answer checking).

Run:  python3 tools/data/import_navigation.py [--html-dir DIR]   (DIR holds navNN.html copies)
"""

from __future__ import annotations

import argparse
import html
import json
import re
import urllib.request
from pathlib import Path

import navigation_diagrams

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = ROOT / "shared" / "navigation_tasks.json"
TRANSLATIONS = HERE / "navigation_en.json"
VALUES = HERE / "navigation_values.json"
BASE = "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-See/Navigationsaufgaben"
OVERVIEW = f"{BASE}/Navigationsaufgaben-node.html"


def task_url(n: int) -> str:
    return f"{BASE}/Navigationsaufgabe-{n:02d}/Navigationsaufgabe-{n:02d}-node.html"


def clean(fragment: str) -> str:
    text = re.sub(r"<br\s*/?>", "\n", fragment)
    text = html.unescape(re.sub(r"<[^>]+>", "", text))
    lines = [re.sub(r"[ \t ]+", " ", line).strip() for line in text.split("\n")]
    out: list[str] = []
    for line in lines:                       # collapse runs of empty lines into one paragraph break
        if line or (out and out[-1]):
            out.append(line)
    return "\n".join(out).strip()


def parse_task(page: str, number: int) -> dict:
    content = page[page.index('<div id="content"'):]
    content = content[:content.index('class="dateOfIssue"')]
    table = re.search(r"<table.*?</table>", content, re.S)
    if not table:
        raise SystemExit(f"Task {number}: no table found")
    intro = [clean(p) for p in re.findall(r"<p>(.*?)</p>", content[:table.start()], re.S)]
    notes = [clean(p) for p in re.findall(r"<p>(.*?)</p>", content[table.end():], re.S)]
    rows = re.findall(r"<tr[^>]*>\s*<td[^>]*>(\d+)\.</td>\s*<td>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*</tr>",
                      table.group(0), re.S)
    steps = [{"number": int(n), "question_de": clean(q), "answer_de": clean(a)} for n, q, a in rows]
    if [s["number"] for s in steps] != list(range(1, 10)):
        raise SystemExit(f"Task {number}: expected sub-questions 1–9, got {[s['number'] for s in steps]}")
    return {"number": number, "intro_de": "\n\n".join(p for p in intro if p),
            "notes_de": "\n\n".join(p for p in notes if p), "steps": steps}


def chart_excerpts(page: str) -> list[str]:
    """The eight chart excerpts (corner coordinates) the exam tasks are worked on."""
    text = clean(page)
    hint = text[text.index("Kartenausschnitte"):text.index("Aus den nachfolgenden")]
    pairs = re.findall(r"N\s*(\d+)°\s*([\d,]+)',\s*E\s*(\d+)°\s*([\d,]+)'", hint)
    corners = [f"{a}° {b}' N  {c}° {d}' E" for a, b, c, d in pairs]
    return [f"{corners[i]} – {corners[i + 1]}" for i in range(0, len(corners) - 1, 2)]


# ── Worked solutions ──────────────────────────────────────────────────────────────────────────
# Generated from the structured values so both languages show the same, verified arithmetic.

# Practice tolerances for typed answers. ELWIS publishes no official tolerances; these are the
# usual allowances for chart work and are shown to the learner as "practice tolerance".
TOLERANCES = {"degrees": 2, "nm": 0.2, "minutes": 2, "knots": 0.3, "arc_minutes": 0.3}

LIGHTS = {
    "Iso": ("Gleichtaktfeuer (Iso): Licht und Dunkel sind gleich lang", "isophase light (Iso): light and dark phases of equal length"),
    "Fl": ("Blitzfeuer (Fl): kurzer Lichtschein, längere Dunkelpause", "flashing light (Fl): short flash, longer dark phase"),
    "LFl": ("Blinkfeuer (LFl): Lichtschein von mindestens 2 Sekunden", "long-flashing light (LFl): flashes of at least 2 seconds"),
    "Oc": ("Unterbrochenes Feuer (Oc): länger hell als dunkel", "occulting light (Oc): light phase longer than dark phase"),
    "Q": ("Funkelfeuer (Q): 50–60 Blitze pro Minute", "quick flashing light (Q): 50–60 flashes per minute"),
    "IQ": ("Unterbrochenes Funkelfeuer (IQ): Funkelfolge, dann Dunkelpause", "interrupted quick light (IQ): quick flashes, then a dark pause"),
}
COLOURS = {"W": ("weiß", "white"), "R": ("rot", "red"), "G": ("grün", "green"), "Y": ("gelb", "yellow")}
MARKS = {
    "north_cardinal": ("Nord-Kardinalzeichen: Toppzeichen zwei Kegel Spitze oben, schwarz über gelb, Funkelfeuer weiß ohne Unterbrechung. Man passiert es im Norden.",
                       "North cardinal mark: two cones point up, black above yellow, continuous white quick light. Pass it to the north."),
    "east_cardinal": ("Ost-Kardinalzeichen: Toppzeichen zwei Kegel Spitze voneinander weg, schwarz-gelb-schwarz, Funkelfeuer weiß in 3er Gruppen. Man passiert es im Osten.",
                      "East cardinal mark: two cones base to base pointing away from each other, black-yellow-black, white quick light in groups of 3. Pass it to the east."),
    "safe_water": ("Ansteuerungstonne (Mitte-Fahrwasser): rot-weiß senkrecht gestreift, roter Ball, Gleichtakt-, unterbrochenes oder Blinkfeuer weiß bzw. Morse A.",
                   "Safe water mark: red-white vertical stripes, red ball, white isophase, occulting or long-flashing light or Morse A."),
}
PLOT = {
    "course": ("Kursdreieck mit der Kante an Start und Ziel legen und die Kurslinie ziehen. Beschriften mit Uhrzeit und rwK.",
               "Lay the edge of the plotting triangle through start and destination and draw the course line. Label it with time and true course."),
    "bearings": ("Kursdreieck auf die rw-Peilung einstellen, die Kante durch das gepeilte Objekt legen und die Standlinie zum Schiff hin ziehen. Wo sich die Standlinien schneiden, ist der beobachtete Ort.",
                 "Set the plotting triangle to the true bearing, lay its edge through the object and draw the position line towards the boat. Where the lines cross is the observed position."),
    "bearing_distance": ("Peillinie durch das Objekt ziehen, dann die Distanz mit dem Zirkel an der Breitenskala abgreifen (1' Breite = 1 sm) und vom Objekt aus auf der Peillinie abtragen.",
                         "Draw the bearing line through the object, take the distance with the dividers from the latitude scale (1' of latitude = 1 nm) and mark it off along the line from the object."),
    "position": ("Breite am seitlichen, Länge am oberen oder unteren Kartenrand einstellen und mit Kursdreieck oder Zirkel in die Karte übertragen. Den Ort mit Kreis und Uhrzeit markieren.",
                 "Set the latitude on the side border and the longitude on the top or bottom border and transfer both into the chart with the triangle or dividers. Mark the position with a circle and the time."),
}


def deg(v: float) -> str:
    return f"{round(v) % 360:03d}°"


def signed(v: float) -> str:
    return "0°" if v == 0 else f"{v:+g}°".replace("-", "−")


def num(v: float, lang: str) -> str:
    s = f"{v:g}" if v != int(v) else f"{int(v)}"
    return s.replace(".", ",") if lang == "de" else s


def pos(p, lang) -> str:
    return f"{p[0]:02d}° {num(p[1], lang) if p[1] != int(p[1]) else str(int(p[1])) + (',0' if lang == 'de' else '.0')}'"


def position(lat, lon, lang) -> str:
    def fmt(p, width):
        minutes = f"{p[1]:04.1f}"
        if lang == "de":
            minutes = minutes.replace(".", ",")
        return f"{p[0]:0{width}d}° {minutes}'"
    return f"{fmt(lat, 2)} N  {fmt(lon, 3)} E"


def minutes_between(a: str, b: str) -> int:
    ha, ma = map(int, a.split(":"))
    hb, mb = map(int, b.split(":"))
    return (hb * 60 + mb) - (ha * 60 + ma)


def light_text(code: str):
    """'Oc(3).Y.12s' → German and English description of the rhythm."""
    parts = code.split(".")
    m = re.match(r"([A-Za-z]+)(?:\((\d+)\))?", parts[0])
    kind, group = m.group(1), m.group(2)
    colours = parts[1] if len(parts) > 1 else "W"
    period = parts[2][:-1] if len(parts) > 2 else None
    de, en = LIGHTS[kind]
    if group:
        de += f", in {group}er-Gruppen"
        en += f", in groups of {group}"
    col_de = "-".join(COLOURS[c][0] for c in colours)
    col_en = "-".join(COLOURS[c][1] for c in colours)
    de += f"; Farbe {col_de}"
    en += f"; colour {col_en}"
    if period:
        de += f"; Wiederkehr {period} s (Zeit für einen vollständigen Durchlauf)"
        en += f"; period {period} s (time for one complete cycle)"
    return de, en


def line(de: str, en: str) -> dict:
    return {"de": de, "en": en}


def solve(step: dict, task: dict) -> tuple[list[dict], dict | None]:
    """Worked solution lines and the answer check for one sub-question."""
    k, mw = step.get("kind"), task.get("mw", 0)
    s: list[dict] = []
    check = None
    if k == "compass_course":
        mgk = step["rwk"] - mw - step["abl"]
        assert round(mgk) % 360 == step["mgk"] % 360, step
        s += [line("Vom rechtweisenden zum Magnetkompasskurs: Missweisung und Ablenkung werden abgezogen (Ost = +, West = −).",
                   "From true to magnetic compass course: subtract variation and deviation (east = +, west = −)."),
              line(f"Mw (laut Karte) = {signed(mw)}, Abl = {signed(step['abl'])}", f"Variation Mw (from chart) = {signed(mw)}, deviation Abl = {signed(step['abl'])}"),
              line(f"MgK = rwK − Mw − Abl = {deg(step['rwk'])} − ({signed(mw)}) − ({signed(step['abl'])}) = {deg(mgk)}",
                   f"MgK = rwK − Mw − Abl = {deg(step['rwk'])} − ({signed(mw)}) − ({signed(step['abl'])}) = {deg(mgk)}")]
        check = {"type": "degrees", "values": [step["mgk"]]}
    elif k == "true_from_compass":
        rwk = step["mgk"] + step["abl"] + mw
        assert round(rwk) % 360 == step["rwk"] % 360, step
        s += [line("Vom Magnetkompasskurs zum rechtweisenden Kurs: Ablenkung und Missweisung werden addiert (Ost = +, West = −).",
                   "From magnetic compass course to true course: add deviation and variation (east = +, west = −)."),
              line(f"Abl = {signed(step['abl'])}, Mw (laut Karte) = {signed(mw)}", f"Deviation Abl = {signed(step['abl'])}, variation Mw (from chart) = {signed(mw)}"),
              line(f"rwK = MgK + Abl + Mw = {deg(step['mgk'])} + ({signed(step['abl'])}) + ({signed(mw)}) = {deg(rwk)}",
                   f"rwK = MgK + Abl + Mw = {deg(step['mgk'])} + ({signed(step['abl'])}) + ({signed(mw)}) = {deg(rwk)}")]
        check = {"type": "degrees", "values": [step["rwk"]]}
    elif k == "bearings":
        s += [line("Magnetkompasspeilung in rechtweisende Peilung umrechnen: rwP = MgP + Abl + Mw (Ost = +, West = −).",
                   "Convert magnetic compass bearings to true bearings: rwP = MgP + Abl + Mw (east = +, west = −)."),
              line(f"Abl = {signed(step['abl'])}, Mw (laut Karte) = {signed(mw)}", f"Deviation Abl = {signed(step['abl'])}, variation Mw (from chart) = {signed(mw)}")]
        for item in step["items"]:
            rwp = item["mgp"] + step["abl"] + mw
            assert round(rwp) % 360 == item["rwp"] % 360, (step, item)
            calc = f"{deg(item['mgp'])} + ({signed(step['abl'])}) + ({signed(mw)}) = {deg(rwp)}"
            s.append(line(f"{item['object']}: rwP = {calc}", f"{item['object']}: rwP = {calc}"))
        if step["abl"] == 0:
            s.append(line("Beim Hand-Peilkompass ist die Ablenkung 0°, weil er abseits der Störfelder des Bootes benutzt wird.",
                          "With a hand bearing compass the deviation is 0° because it is used away from the boat's magnetic fields."))
        check = {"type": "degrees", "values": [i["rwp"] for i in step["items"]]}
    elif k == "chart_bearings":
        s += [line("Von der eingetragenen Position aus die Richtung zu jedem Leuchtturm mit dem Kursdreieck messen. Das ist die rechtweisende Peilung.",
                   "From the plotted position, measure the direction to each lighthouse with the plotting triangle. That is the true bearing.")]
        for item in step["items"]:
            s.append(line(f"{item['object']}: rwP = {deg(item['rwp'])}", f"{item['object']}: rwP = {deg(item['rwp'])}"))
        check = {"type": "degrees", "values": [i["rwp"] for i in step["items"]]}
    elif k == "true_course":
        if step.get("perpendicular"):
            s += [line("Ein Verkehrstrennungsgebiet wird möglichst rechtwinklig zur allgemeinen Verkehrsrichtung gequert (Kielrichtung).",
                       "A traffic separation scheme is crossed as nearly as possible at right angles to the general direction of traffic (heading)."),
                  line("Die Richtung der Verkehrsrichtung in der Karte messen und 90° addieren bzw. abziehen.",
                       "Measure the direction of the traffic lanes on the chart and add or subtract 90°.")]
        else:
            s += [line(f"Kurslinie von „{step['from']}“ nach „{step['to']}“ zeichnen.", f"Draw the course line from \"{step['from']}\" to \"{step['to']}\"."),
                  line("Kursdreieck an die Kurslinie legen, den Mittelpunkt auf einen Meridian (Längenkreis) schieben und den Winkel an der Gradskala ablesen. Auf die Fahrtrichtung achten!",
                       "Lay the plotting triangle along the course line, slide its centre onto a meridian and read the angle on the degree scale. Mind the direction of travel!")]
        s.append(line(f"rwK = {deg(step['rwk'])}", f"rwK = {deg(step['rwk'])}"))
        check = {"type": "degrees", "values": [step["rwk"]]}
    elif k == "distance":
        s += [line("Distanz mit dem Zirkel abgreifen und am seitlichen Kartenrand (Breitenskala) ablesen: 1 Bogenminute Breite = 1 Seemeile. Nie an der Längenskala messen!",
                   "Take the distance with the dividers and read it on the side border (latitude scale): 1 minute of latitude = 1 nautical mile. Never measure on the longitude scale!"),
              line(f"Distanz = {num(step['nm'], 'de')} sm", f"Distance = {num(step['nm'], 'en')} nm")]
        check = {"type": "nm", "values": [step["nm"]]}
    elif k == "travel_time":
        t = step["nm"] / step["kn"] * 60
        assert abs(t - step["minutes"]) <= 1, step
        prefix_de = "Distanz (aus der Karte gemessen)" if step.get("derived") else "Distanz"
        prefix_en = "Distance (measured on the chart)" if step.get("derived") else "Distance"
        s += [line("Zeit = Distanz ÷ Geschwindigkeit; in Minuten mal 60.", "Time = distance ÷ speed; multiply by 60 for minutes."),
              line(f"{prefix_de}: {num(step['nm'], 'de')} sm, Fahrt: {num(step['kn'], 'de')} kn",
                   f"{prefix_en}: {num(step['nm'], 'en')} nm, speed: {num(step['kn'], 'en')} kn"),
              line(f"t = {num(step['nm'], 'de')} ÷ {num(step['kn'], 'de')} × 60 = {num(round(t, 2), 'de')} min",
                   f"t = {num(step['nm'], 'en')} ÷ {num(step['kn'], 'en')} × 60 = {num(round(t, 2), 'en')} min")]
        check = {"type": "minutes", "values": [step["minutes"]]}
    elif k == "eta":
        t = step["nm"] / step["kn"] * 60
        mins = minutes_between(step["start"], step["eta"])
        assert abs(t - mins) <= 3, (step, t, mins)
        s += [line("Distanz zum Ziel in der Karte messen, Fahrzeit berechnen und zur Startzeit addieren.",
                   "Measure the distance to the destination, work out the time and add it to the start time."),
              line(f"Distanz ≈ {num(step['nm'], 'de')} sm (aus der Karte); t = {num(step['nm'], 'de')} ÷ {num(step['kn'], 'de')} × 60 ≈ {round(t)} min",
                   f"Distance ≈ {num(step['nm'], 'en')} nm (from the chart); t = {num(step['nm'], 'en')} ÷ {num(step['kn'], 'en')} × 60 ≈ {round(t)} min"),
              line(f"Ankunft = {step['start']} + {mins} min = {step['eta']} Uhr", f"Arrival = {step['start']} + {mins} min = {step['eta']}")]
        check = {"type": "clock", "values": [step["eta"]]}
    elif k == "speed":
        mins = minutes_between(step["start"], step["end"])
        v = step["nm"] / mins * 60
        assert abs(v - step["kn"]) <= 0.3, (step, v)
        s += [line("Geschwindigkeit = Distanz ÷ Zeit (in Stunden).", "Speed = distance ÷ time (in hours)."),
              line(f"Zeit: {step['start']} bis {step['end']} = {mins} min; Distanz ≈ {num(step['nm'], 'de')} sm (aus der Karte)",
                   f"Time: {step['start']} to {step['end']} = {mins} min; distance ≈ {num(step['nm'], 'en')} nm (from the chart)"),
              line(f"v = {num(step['nm'], 'de')} ÷ {mins} × 60 = {num(round(v, 1), 'de')} kn", f"v = {num(step['nm'], 'en')} ÷ {mins} × 60 = {num(round(v, 1), 'en')} kn")]
        check = {"type": "knots", "values": [step["kn"]]}
    elif k == "dr_position":
        mins = minutes_between(step["start"], step["end"])
        d = step["kn"] * mins / 60
        s += [line("Koppelort: vom letzten bekannten Ort die gefahrene Distanz auf dem Kurs abtragen.",
                   "Dead-reckoning position: from the last known position, mark off the distance run along the course."),
              line(f"Zeit {step['start']}–{step['end']} = {mins} min; Distanz = {num(step['kn'], 'de')} kn × {mins}/60 h = {num(round(d, 2), 'de')} sm",
                   f"Time {step['start']}–{step['end']} = {mins} min; distance = {num(step['kn'], 'en')} kn × {mins}/60 h = {num(round(d, 2), 'en')} nm"),
              line(f"Distanz mit dem Zirkel an der Breitenskala abgreifen und auf dem Kurs {deg(step['rwk'])} abtragen, dann die Position ablesen:",
                   f"Take this distance from the latitude scale with the dividers, mark it off along course {deg(step['rwk'])} and read the position:"),
              line(position(step["lat"], step["lon"], "de"), position(step["lat"], step["lon"], "en"))]
        check = {"type": "position", "lat": step["lat"], "lon": step["lon"]}
    elif k == "read_position":
        s += [line("Mit Kursdreieck oder Zirkel die Breite zum seitlichen und die Länge zum oberen oder unteren Kartenrand übertragen und ablesen.",
                   "With the triangle or dividers, transfer the latitude to the side border and the longitude to the top or bottom border and read them off."),
              line(position(step["lat"], step["lon"], "de"), position(step["lat"], step["lon"], "en"))]
        check = {"type": "position", "lat": step["lat"], "lon": step["lon"]}
    elif k == "set_drift":
        s += [line("Besteckversetzung (BV) = Richtung und Distanz vom Koppelort zum beobachteten (gepeilten) Ort. Sie zeigt, wie Strom und Wind das Boot versetzt haben.",
                   "Set and drift (BV) = direction and distance from the dead-reckoning position to the observed (fixed) position. It shows how current and wind have moved the boat."),
              line("Richtung mit dem Kursdreieck messen, Distanz mit dem Zirkel an der Breitenskala abgreifen.",
                   "Measure the direction with the plotting triangle and the distance with the dividers on the latitude scale."),
              line(f"BV = {deg(step['direction'])} – {num(step['nm'], 'de')} sm", f"BV = {deg(step['direction'])} – {num(step['nm'], 'en')} nm")]
        check = {"type": "set_drift", "direction": step["direction"], "nm": step["nm"]}
    elif k == "light":
        de, en = light_text(step["code"])
        s += [line(f"Kennung laut Karte: {step['code'].replace('.', ' ')}", f"Light character on the chart: {step['code'].replace('.', ' ')}"),
              line(de, en)]
        if step.get("mark") in MARKS:
            s.append(line(*MARKS[step["mark"]]))
        s.append(line("Farbe und Toppzeichen stehen als Abkürzung am Tonnensymbol (Erklärung in „Karte 1/INT 1“).",
                      "Colour and topmark are given as abbreviations next to the buoy symbol (explained in \"Chart 1/INT 1\")."))
    elif k == "mark_meaning":
        s.append(line(*MARKS[step["mark"]]))
    elif k == "lighthouse":
        s += [line("Die Feuerbeschreibung steht neben dem Leuchtturmsymbol: Kennung, Farben/Sektoren, Feuerhöhe (m) und Nenntragweite (sm).",
                   "The light description is printed next to the lighthouse symbol: character, colours/sectors, height of light (m) and nominal range (nm).")]
        if step.get("code"):
            s.append(line(*light_text(step["code"])))
    elif k in ("chart_entry", "chart_colours"):
        s.append(line("Die Bedeutung aller Zeichen und Abkürzungen in der Seekarte steht im Heft „Karte 1/INT 1“ (Zeichen, Abkürzungen, Begriffe).",
                      "The meaning of all chart symbols and abbreviations is explained in \"Chart 1/INT 1\" (symbols, abbreviations, terms)."))
    elif k == "plot":
        s.append(line(*PLOT[step["what"]]))
    else:
        raise SystemExit(f"unknown kind {k}")
    return s, check


GLOSSARY = [
    ("rwK", "rechtweisender Kurs", "true course", "Kurs bezogen auf geographisch Nord", "course relative to true north"),
    ("MgK", "Magnetkompasskurs", "magnetic compass course", "Kurs, den der Bordkompass anzeigt", "course shown by the boat's compass"),
    ("rwP", "rechtweisende Peilung", "true bearing", "Richtung zu einem Objekt, bezogen auf geographisch Nord", "direction to an object relative to true north"),
    ("MgP", "Magnetkompasspeilung", "magnetic compass bearing", "mit dem Kompass gemessene Richtung zu einem Objekt", "direction to an object measured with the compass"),
    ("Mw", "Missweisung", "variation", "Winkel zwischen geographisch und magnetisch Nord; steht in der Kompassrose der Karte", "angle between true and magnetic north; printed in the chart's compass rose"),
    ("Abl", "Ablenkung", "deviation", "Kompassfehler durch Eisen und Elektrik an Bord; aus der Ablenkungstabelle", "compass error caused by iron and electrics on board; from the deviation table"),
    ("FüG", "Fahrt über Grund", "speed over ground", "Geschwindigkeit gegenüber dem Meeresboden", "speed relative to the sea bed"),
    ("BV", "Besteckversetzung", "set and drift", "Richtung und Distanz vom Koppelort zum beobachteten Ort", "direction and distance from the DR position to the observed position"),
    ("Koppelort", "Koppelort", "dead-reckoning (DR) position", "aus Kurs, Fahrt und Zeit errechneter Ort", "position worked out from course, speed and time"),
    ("beob. Ort", "beobachteter Ort", "observed position (fix)", "durch Peilungen bestimmter Ort", "position found by bearings"),
    ("sm", "Seemeile", "nautical mile (nm)", "1852 m = 1 Bogenminute Breite", "1852 m = 1 minute of latitude"),
    ("kn", "Knoten", "knot", "1 Seemeile pro Stunde", "1 nautical mile per hour"),
    ("Kennung", "Kennung", "light character", "Rhythmus und Farbe eines Feuers", "rhythm and colour of a light"),
    ("Toppzeichen", "Toppzeichen", "topmark", "Form auf der Spitze einer Tonne", "shape on top of a buoy"),
    ("Wiederkehr", "Wiederkehr", "period", "Dauer eines vollständigen Feuerzyklus", "duration of one complete light cycle"),
    ("Nenntragweite", "Nenntragweite", "nominal range", "Sichtweite eines Feuers bei 10 sm meteorologischer Sicht", "range of a light in 10 nm meteorological visibility"),
]

QUESTION_TYPES = {
    286: ("Wie lautet der rwK?", "What is the true course?"),
    287: ("Tragen Sie den Kurs in die Seekarte ein.", "Plot the course on the chart."),
    288: ("Wie lautet der MgK?", "What is the magnetic compass course?"),
    289: ("Wie lauten die Peilungen?", "What are the bearings?"),
    290: ("Tragen Sie die Peilungen in die Seekarte ein.", "Plot the bearings on the chart."),
    291: ("Entnehmen Sie der Seekarte die geographische Position.", "Take the geographical position from the chart."),
    292: ("Tragen Sie die Position in die Seekarte ein.", "Plot the position on the chart."),
    293: ("Wie groß ist die Distanz?", "What is the distance?"),
    294: ("Auf welcher Position befindet sich das Schiff nach Koppelort?", "What is the dead-reckoning position?"),
    295: ("Wie lautet die Besteckversetzung?", "What is the set and drift?"),
    296: ("In welcher Zeit erreichen Sie das Ziel?", "How long until you reach the destination?"),
    297: ("Wie groß ist die Geschwindigkeit?", "What is the speed?"),
    298: ("Welche Bedeutung hat das Schifffahrtszeichen?", "What is the meaning of the mark?"),
    299: ("Beschreiben Sie das Schifffahrtszeichen (zum Beispiel Farbe, Kennung, Toppzeichen, Nenntragweite, Feuerhöhe, Art des Feuers).",
          "Describe the mark (e.g. colour, light character, topmark, nominal range, height of light, type of light)."),
    300: ("Was bedeutet diese Eintragung in der Seekarte?", "What does this entry on the chart mean?"),
}


def fetch(url: str) -> str:
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--html-dir", type=Path, help="saved copies nav01.html … nav15.html and overview.html")
    args = ap.parse_args()

    def page(name: str, url: str) -> str:
        return (args.html_dir / name).read_text(encoding="utf-8") if args.html_dir else fetch(url)

    tasks = [parse_task(page(f"nav{n:02d}.html", task_url(n)), n) for n in range(1, 16)]
    excerpts = chart_excerpts(page("overview.html", OVERVIEW))

    english = json.loads(TRANSLATIONS.read_text(encoding="utf-8")) if TRANSLATIONS.exists() else {}
    values = json.loads(VALUES.read_text(encoding="utf-8")) if VALUES.exists() else {}
    for task in tasks:
        key = str(task["number"])
        en = english.get(key, {})
        task["intro_en"] = en.get("intro")
        task["notes_en"] = en.get("notes")
        task["values"] = values.get(key, {}).get("task", {})
        for step in task["steps"]:
            s = str(step["number"])
            step["question_en"] = en.get("steps", {}).get(s, {}).get("question")
            step["answer_en"] = en.get("steps", {}).get(s, {}).get("answer")
            step.update(values.get(key, {}).get("steps", {}).get(s, {}))
            if "kind" in step:
                step["solution"], check = solve(step, task["values"])
                if check:
                    step["check"] = check
        task["diagram"] = navigation_diagrams.diagram(task["number"])

    out = {
        "source": "ELWIS – Navigationsaufgaben SBF See (Übungskarte D49)",
        "source_url": OVERVIEW,
        "catalog_date": "2023-08-01",
        "chart": "Übungskarte D49 – Mündungen der Jade, Weser und Elbe",
        "chart_excerpts": excerpts,
        "tolerances": TOLERANCES,
        "glossary": [{"abbr": a, "de": de, "en": en, "explanation_de": xde, "explanation_en": xen}
                     for a, de, en, xde, xen in GLOSSARY],
        "question_types": [{"number": n, "de": de, "en": en} for n, (de, en) in QUESTION_TYPES.items()],
        "tasks": tasks,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    missing_en = sum(1 for t in tasks for s in t["steps"] if not s["question_en"])
    print(f"wrote {OUT.relative_to(ROOT)}: {len(tasks)} tasks, {missing_en} sub-questions without English")


if __name__ == "__main__":
    main()

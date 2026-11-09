#!/usr/bin/env python3
"""Import the ELWIS "Spezifische Fragen Segeln" (SBF Binnen under sail, questions 254–300).

Fetches the official catalogue page (or reads a saved copy), keeps the German texts
verbatim, adds the English translations from ``segeln_en.json`` and writes/replaces the
``Segeln`` section of shared/sbf_exam_questions.json.  Afterwards run
``update_questions.py`` to add German category names, image references and explanations.

Run:  python3 tools/data/import_segeln.py [--html saved_page.html]
"""

from __future__ import annotations

import argparse
import html
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUESTIONS = ROOT / "shared" / "sbf_exam_questions.json"
TRANSLATIONS = Path(__file__).resolve().parent / "segeln_en.json"
URL = ("https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragenkatalog-Binnen/"
       "Spezifische-Fragen-Segeln/Spezifische-Fragen-Segeln-node.html")
FIRST, LAST = 254, 300

# Topic of each question (inclusive number ranges).
CATEGORIES = [
    (254, 264, "Boat Types and Stability"),
    (265, 273, "Gear and Sails"),
    (274, 281, "Wind"),
    (282, 294, "Sail Trim and Boat Handling"),
    (295, 300, "Manoeuvres and Emergencies"),
]

QUESTION = re.compile(r"<p>(\d{3})\.\s*(.*?)(?:</p>|<br/>)(.*?)<ol[^>]*>(.*?)</ol>", re.S)
ITEM = re.compile(r"<li>(.*?)</li>", re.S)


def clean(fragment: str) -> str:
    # <br/> separates words; inline tags such as <abbr>UV</abbr>-Strahlung must not add a space.
    text = re.sub(r"<br\s*/?>", " ", fragment)
    text = html.unescape(re.sub(r"<[^>]+>", "", text))
    text = re.sub(r"\s+", " ", text).strip()
    return re.sub(r"\s+([.,;:?!])", r"\1", text)


def category(number: int) -> str:
    return next(name for lo, hi, name in CATEGORIES if lo <= number <= hi)


def parse(page: str) -> list[dict]:
    questions = []
    for m in QUESTION.finditer(page):
        number = int(m.group(1))
        if not FIRST <= number <= LAST:
            continue
        answers = [clean(a) for a in ITEM.findall(m.group(4))]
        questions.append({"number": number, "text": clean(m.group(2)), "answers": answers,
                          "has_image": "<img" in m.group(3)})
    return questions


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--html", type=Path, help="saved copy of the ELWIS page instead of downloading it")
    args = ap.parse_args()

    if args.html:
        page = args.html.read_text(encoding="utf-8")
    else:
        with urllib.request.urlopen(URL, timeout=30) as response:
            page = response.read().decode("utf-8")

    parsed = parse(page)
    numbers = [q["number"] for q in parsed]
    if numbers != list(range(FIRST, LAST + 1)):
        raise SystemExit(f"Expected questions {FIRST}–{LAST}, found {numbers}")
    for q in parsed:
        if len(q["answers"]) != 4 or len(set(q["answers"])) != 4:
            raise SystemExit(f"Question {q['number']}: expected 4 distinct answers, got {q['answers']}")

    english = json.loads(TRANSLATIONS.read_text(encoding="utf-8"))
    out = []
    for q in parsed:
        n = q["number"]
        en = english.get(str(n))
        if not en or len(en["answers"]) != 4:
            raise SystemExit(f"Missing English translation for question {n}")
        out.append({
            "unique_id": f"segeln_{n}",
            "question_number": n,
            "category": category(n),
            "german_text": q["text"],
            "english_text": en["question"],
            # In the official catalogue the first answer (a) is always correct.
            "options": {label: {"german": de, "english": en_text}
                        for label, de, en_text in zip("ABCD", q["answers"], en["answers"])},
            "correct_option": "A",
            "has_image": q["has_image"],
            "image_reference": None,
        })

    data = json.loads(QUESTIONS.read_text(encoding="utf-8"))
    section = {
        "exam_type": "Segeln",
        "description": "Spezifische Fragen Segeln - Questions specific to SBF Binnen under sail",
        "question_range": f"{FIRST}-{LAST}",
        "total": len(out),
        "categories": sorted({q["category"] for q in out}),
        "questions": out,
    }
    # The sailing part belongs to the SBF Binnen: keep it right after the Binnen section.
    sections = [s for s in data["exam_sections"] if s["exam_type"] != "Segeln"]
    binnen = next(i for i, s in enumerate(sections) if s["exam_type"] == "Binnen")
    sections.insert(binnen + 1, section)
    data["exam_sections"] = sections
    meta = data["metadata"]
    meta["total_questions"] = sum(len(s["questions"]) for s in sections)
    meta["description"] = ("Official Sportbootführerschein (SBF) exam questions for Binnen (motor and sail) "
                           "and See, based on the ELWIS August 2023 catalog")
    QUESTIONS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"imported {len(out)} sailing questions ({sum(q['has_image'] for q in out)} with figure); "
          f"total {meta['total_questions']}")


if __name__ == "__main__":
    main()

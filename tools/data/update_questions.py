#!/usr/bin/env python3
"""Idempotent maintenance of shared/sbf_exam_questions.json.

* adds ``category_de`` (German category name) to every question
* adds ``sound_pattern`` (". short, - long, space = pause") to sound-signal questions
  so both apps can play the signal
* normalises ``image_references`` (one generated illustration per question)
* merges explanations from tools/data/explanations/*.json when present
* fixes question texts whose signal glyph was lost when the catalogue was scraped
* removes bracketed "[image: …]" notes from the English translations (they were
  machine-generated guesses and often contradicted the actual figure)

Run:  python3 tools/data/update_questions.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUESTIONS = ROOT / "shared" / "sbf_exam_questions.json"
EXPLANATIONS = Path(__file__).resolve().parent / "explanations"

CATEGORY_DE = {
    "COLREGS and Regulations": "KVR und Vorschriften",
    "Definitions and Terms": "Begriffe und Definitionen",
    "Engine and Technical": "Motor und Technik",
    "Environmental Protection": "Umweltschutz",
    "General Regulations": "Allgemeine Vorschriften",
    "Lights": "Lichter",
    "Lights and Day Signals": "Lichter und Sichtzeichen",
    "Lights and Signals": "Lichter und Signale",
    "Locks": "Schleusen",
    "Navigation": "Navigation",
    "Navigation Signs": "Schifffahrtszeichen",
    "Regulations and Licensing": "Vorschriften und Fahrerlaubnis",
    "Safety": "Sicherheit",
    "Safety and Emergency": "Sicherheit und Notfall",
    "Seamanship": "Seemannschaft",
    "SeeSchStrO Regulations": "SeeSchStrO-Vorschriften",
    "Sound Signals": "Schallsignale",
    "Traffic Rules": "Verkehrsregeln",
    "Vessel Handling": "Bootsführung",
    "Water Sports": "Wassersport",
    "Waterways and Fairway Marks": "Wasserstraßen und Fahrwasserkennzeichnung",
    "Weather": "Wetter",
}

SOUND_PATTERNS = {
    "shared_004": ".",
    "shared_005": "-",
    "shared_016": ".-.-.-.-.-",
    "binnen_162": "-.",
    "binnen_163": "-..",
    "binnen_164": "--.",
    "binnen_165": "--..",
    "binnen_166": "---.",
    "binnen_167": "---..",
    "see_116": "-",
    "see_117": "--",
    "see_118": "-..",
    "see_119": "-...",
    "see_140": ".....",
    "see_141": ".-.",
    "see_162": "-....-....",
    "see_178": "....",
    "see_186": ".-..",
    "see_188": "--- ---",
    "see_282": "...---...",
}

# Questions whose official figure was missing from the original data set.
ADDED_IMAGES = {"see_091"}

IMAGE_NOTE = re.compile(r"\s*\[(?:image|Image|figure|picture|diagram)[^\]]*\]")

TEXT_FIXES = {
    "see_116": ("( )", "(━━)"),
    "see_117": ("( )", "(━━ ━━)"),
    "see_140": ("(mindestens )", "(mindestens • • • • •)"),
}


def main():
    data = json.loads(QUESTIONS.read_text(encoding="utf-8"))
    explanations = {}
    if EXPLANATIONS.exists():
        for f in sorted(EXPLANATIONS.glob("*.json")):
            explanations.update(json.loads(f.read_text(encoding="utf-8")))

    missing_cat = set()
    n_expl = 0
    for section in data["exam_sections"]:
        for q in section["questions"]:
            uid = q["unique_id"]
            cat = q["category"]
            if cat not in CATEGORY_DE:
                missing_cat.add(cat)
            q["category_de"] = CATEGORY_DE.get(cat, cat)

            if uid in SOUND_PATTERNS:
                q["sound_pattern"] = SOUND_PATTERNS[uid]
            else:
                q.pop("sound_pattern", None)

            q["english_text"] = IMAGE_NOTE.sub("", q["english_text"]).strip()
            for opt in q["options"].values():
                opt["english"] = IMAGE_NOTE.sub("", opt["english"]).strip()

            if uid in TEXT_FIXES:
                old, new = TEXT_FIXES[uid]
                q["german_text"] = q["german_text"].replace(old, new)

            if uid in ADDED_IMAGES:
                q["has_image"] = True
            if q.get("has_image"):
                prefix = uid.split("_")[0]
                ref = f"assets/{prefix}/{uid}.png"
                q["image_reference"] = ref
                q["image_references"] = [ref]
            else:
                q["image_reference"] = None
                q.pop("image_references", None)

            if uid in explanations:
                q["explanation_de"] = explanations[uid]["de"]
                q["explanation_en"] = explanations[uid]["en"]
                n_expl += 1

    if missing_cat:
        raise SystemExit(f"No German name for categories: {sorted(missing_cat)}")
    QUESTIONS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"updated {QUESTIONS.relative_to(ROOT)} ({n_expl} explanations)")


if __name__ == "__main__":
    main()

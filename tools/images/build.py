#!/usr/bin/env python3
"""Render all question illustrations to PNG.

    python3 tools/images/build.py                 # render everything into shared/assets
    python3 tools/images/build.py see_092 binnen_1  # render matching ids only
    python3 tools/images/build.py --sheet DIR     # also write review contact sheets

Requires ``resvg`` (brew install resvg).  Output: shared/assets/<exam>/<id>.png
plus the SVG sources in tools/images/out/svg for inspection.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

from catalog import CATALOG  # noqa: E402

ASSETS = ROOT / "shared" / "assets"
SVG_DIR = HERE / "out" / "svg"
LONG_SIDE = 1400


def render(uid: str) -> Path:
    canvas = CATALOG[uid]()
    if canvas.bg is None:
        canvas.bg = "#FFFFFF"
    prefix = uid.split("_")[0]
    svg_path = SVG_DIR / f"{uid}.svg"
    svg_path.parent.mkdir(parents=True, exist_ok=True)
    svg_path.write_text(canvas.svg(), encoding="utf-8")
    out = ASSETS / prefix / f"{uid}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    size = ["-w", str(LONG_SIDE)] if canvas.w >= canvas.h else ["-h", str(LONG_SIDE)]
    subprocess.run(["resvg", *size, str(svg_path), str(out)], check=True)
    return out


def contact_sheet(uids, original_dir: Path, out_dir: Path, per_sheet=8):
    from PIL import Image, ImageDraw, ImageFont

    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 20)
    cw, ch = 380, 260
    out_dir.mkdir(parents=True, exist_ok=True)
    for page in range(0, len(uids), per_sheet):
        batch = uids[page:page + per_sheet]
        sheet = Image.new("RGB", (cw * 2, ch * len(batch)), "white")
        d = ImageDraw.Draw(sheet)
        for i, uid in enumerate(batch):
            prefix = uid.split("_")[0]
            for j, path in enumerate((original_dir / prefix / f"{uid}.png", ASSETS / prefix / f"{uid}.png")):
                if not path.exists():
                    continue
                im = Image.open(path).convert("RGB")
                s = min((cw - 16) / im.width, (ch - 40) / im.height)
                im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
                sheet.paste(im, (j * cw + (cw - im.width) // 2, i * ch + 32 + (ch - 40 - im.height) // 2))
            d.text((6, i * ch + 4), f"{uid}  (ELWIS | new)", fill="red", font=font)
            d.line([(0, i * ch), (cw * 2, i * ch)], fill=(180, 180, 180))
        sheet.save(out_dir / f"review_{page // per_sheet:02d}.png")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="*", help="id prefixes to render (default: all)")
    ap.add_argument("--sheet", type=Path, help="write ELWIS-vs-new review sheets to this directory")
    ap.add_argument("--originals", type=Path, help="directory with original ELWIS images (<exam>/<id>.png)")
    args = ap.parse_args()

    questions = json.loads((ROOT / "shared" / "sbf_exam_questions.json").read_text())
    needed = sorted(q["unique_id"] for s in questions["exam_sections"] for q in s["questions"] if q.get("has_image"))
    missing = [u for u in needed if u not in CATALOG]
    if missing:
        sys.exit(f"No drawing for: {', '.join(missing)}")

    uids = [u for u in needed if not args.ids or any(u.startswith(p) for p in args.ids)]
    for uid in uids:
        render(uid)
    print(f"rendered {len(uids)} images into {ASSETS.relative_to(ROOT)}")
    if args.sheet:
        contact_sheet(uids, args.originals or ASSETS, args.sheet)
        print(f"review sheets in {args.sheet}")


if __name__ == "__main__":
    main()

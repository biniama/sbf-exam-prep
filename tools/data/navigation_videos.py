#!/usr/bin/env python3
"""Curated YouTube videos for the navigation tasks (feature flag navigationVideos).

Run to verify every video (public and playable; title and channel from YouTube's oEmbed endpoint), read its length and,
for the task walkthroughs, the chapter marks of each sub-question. Writes navigation_videos.json,
which import_navigation.py merges into shared/navigation_tasks.json.

The videos are third-party content: the app only links to them and opens them in YouTube.
"""
import json
import pathlib
import re
import sys
import urllib.parse
import urllib.error
import urllib.request

OUT = pathlib.Path(__file__).with_name("navigation_videos.json")
HEADERS = {"User-Agent": "Mozilla/5.0", "Accept-Language": "en-GB,en;q=0.8"}

# One technique per kind of sub-question. Videos in German first (the exam language), then English.
TECHNIQUES = [
    {"id": "course", "de": "Kurse einzeichnen und ablesen", "en": "Plotting and reading courses",
     "kinds": ["true_course", "plot"],
     "videos": [("KbMg4H1Nx54", "de"), ("-vupULL6IJg", "de"), ("VKKpZwPOvU8", "en")]},
    {"id": "conversion", "de": "Kurse und Peilungen umrechnen", "en": "Converting courses and bearings",
     "kinds": ["compass_course", "true_from_compass"],
     "videos": [("YZo7DA2BVrE", "de"), ("yhqVuijarvg", "de"), ("7jTesUTSVOo", "en")]},
    {"id": "position", "de": "Positionen ablesen und eintragen", "en": "Reading and plotting positions",
     "kinds": ["read_position"],
     "videos": [("IwzddELf66w", "de"), ("Mv7otE-fGUw", "de"), ("wcaMMPuDAaA", "en")]},
    {"id": "distance_time", "de": "Distanz, Fahrt und Zeit", "en": "Distance, speed and time",
     "kinds": ["distance", "travel_time", "eta", "speed", "dr_position"],
     "videos": [("KIWbT_0zFvI", "de"), ("wU9imTpEdv8", "de"), ("Kic0BtdDxEo", "en"), ("T6-NtEpCphA", "en")]},
    {"id": "bearings", "de": "Kreuzpeilung und beobachteter Ort", "en": "Cross bearings and fixes",
     "kinds": ["bearings", "chart_bearings"],
     "videos": [("Rv6Qq2At998", "de"), ("I-3SqcHZjGI", "de"), ("JYn_8QKHWp4", "en")]},
    {"id": "set_drift", "de": "Besteckversetzung", "en": "Set and drift",
     "kinds": ["set_drift"],
     "videos": [("bclrWc_XlvE", "de"), ("mmQaFK8qB1Y", "de"), ("UpcfB3dVwPk", "en")]},
    {"id": "lights", "de": "Leuchtfeuer und Kennungen", "en": "Lights and their characters",
     "kinds": ["light", "lighthouse"],
     "videos": [("wPLbbkhPPFs", "de"), ("OvGW-kAknS0", "de"), ("CskLdum3D4E", "en")]},
    {"id": "symbols", "de": "Eintragungen der Seekarte", "en": "Chart symbols and entries",
     "kinds": ["mark_meaning", "chart_entry", "chart_colours"],
     "videos": [("cIbfW9pE3KE", "de"), ("-ICcM_03-Nw", "en")]},
]

# Worked solutions of the 15 official tasks by Bootspruefung.de, in German, one video per task.
WALKTHROUGHS = ["jYWMqmiAeuc", "cQA6Me1A8Mw", "z_VmXaaK4K0", "ef6lf9r9im4", "r2rmB_CXVAs",
                "Ev3ORQwvMD0", "HoodX3bO9CQ", "6ADVwbnjyTg", "sIw6i0hGbLo", "XouLDmrqqK4",
                "ypERrnNVsyk", "iAmmbx4PDxk", "C2k1ITI2aJg", "rDwapPdrokQ", "5HojecpCsos"]


def fetch(url: str) -> str:
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=30).read().decode()


def video(vid: str, lang: str) -> dict:
    """Checks the video plays; title and channel from oEmbed, or from the watch page when the owner disabled embedding
    (the app opens videos in YouTube, so embedding is not needed)."""
    page = fetch(f"https://www.youtube.com/watch?v={vid}")
    status = re.search(r'"playabilityStatus":\{"status":"(\w+)"', page)
    if not status or status.group(1) != "OK":
        sys.exit(f"{vid} is not playable: {status.group(1) if status else 'no status'}")
    try:
        oembed = json.loads(fetch("https://www.youtube.com/oembed?format=json&url="
                                  + urllib.parse.quote(f"https://www.youtube.com/watch?v={vid}")))
        title, channel = oembed["title"], oembed["author_name"]
    except urllib.error.HTTPError:
        def field(name):
            raw = re.search(r'"videoDetails":\{"videoId":"[^"]+".*?"' + name + r'":"((?:[^"\\]|\\.)*)"', page).group(1)
            return json.loads(f'"{raw}"')
        title, channel = field("title"), field("author")
    seconds = int(re.search(r'"lengthSeconds":"(\d+)"', page).group(1))
    return {"id": vid, "lang": lang, "title": title, "channel": channel, "seconds": seconds, "_page": page}


def chapters(page: str) -> dict:
    """Start of each sub-question from the description's chapter list ("04:41 Teilaufgabe 2")."""
    description = json.loads('"' + re.search(r'"shortDescription":"((?:[^"\\]|\\.)*)"', page).group(1) + '"')
    marks = {}
    for minutes, secs, step in re.findall(r"(\d+):(\d\d) Teilaufgabe (\d)", description):
        marks[step] = int(minutes) * 60 + int(secs)
    return marks


def main() -> None:
    techniques = []
    for t in TECHNIQUES:
        videos = []
        for vid, lang in t["videos"]:
            v = video(vid, lang)
            v.pop("_page")
            videos.append(v)
            print(f"  {t['id']:<14} {vid} {v['seconds'] // 60:>3} min  {v['channel']}: {v['title']}")
        techniques.append({**{k: t[k] for k in ("id", "de", "en", "kinds")}, "videos": videos})

    walkthroughs = []
    for number, vid in enumerate(WALKTHROUGHS, start=1):
        v = video(vid, "de")
        marks = chapters(v.pop("_page"))
        if f"Navigationsaufgabe {number} " not in v["title"] + " " or sorted(marks) != [str(i) for i in range(1, 10)]:
            sys.exit(f"walkthrough {number} ({vid}) does not match: {v['title']} {marks}")
        walkthroughs.append({"task": number, **v, "chapters": marks})
        print(f"  task {number:>2}       {vid} {v['seconds'] // 60:>3} min  {v['title']}")

    kinds = [k for t in TECHNIQUES for k in t["kinds"]]
    assert len(kinds) == len(set(kinds)), "a kind belongs to more than one technique"
    OUT.write_text(json.dumps({"techniques": techniques, "walkthroughs": walkthroughs},
                              ensure_ascii=False, indent=1) + "\n")
    print(f"wrote {OUT.name}: {sum(len(t['videos']) for t in techniques)} technique videos, {len(walkthroughs)} walkthroughs")


if __name__ == "__main__":
    main()

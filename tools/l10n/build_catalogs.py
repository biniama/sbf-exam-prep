#!/usr/bin/env python3
"""Builds the String Catalogs (Localizable.xcstrings) for the app and the widget.

Keys are the English source strings extracted by the compiler.  To refresh the
key list after changing UI text, build once and run:

    python3 tools/l10n/build_catalogs.py --derived-data <DerivedData dir>

Without --derived-data the catalogs are rebuilt from the keys below.
Every key must have a German translation; plural forms are declared in PLURALS.
"""

from __future__ import annotations

import argparse
import glob
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

DE = {
    # Tabs & navigation
    "Home": "Start",
    "Browse": "Fragen",
    "Quiz": "Quiz",
    "Saved": "Gemerkt",
    "Settings": "Einstellungen",
    "About": "Über",
    "Results": "Ergebnis",
    "Filter": "Filter",
    "List": "Liste",

    # Exam types & licences
    "All": "Alle",
    "Basic": "Basis",
    "Inland": "Binnen",
    "Sea": "See",
    "Sailing": "Segeln",
    "SBF Inland · sailing": "SBF Binnen · Segeln",
    "questions": "Fragen",
    "basic": "Basis",
    "inland": "Binnen",
    "sailing": "Segeln",
    "sea": "See",
    "Inland questions": "Binnenfragen",
    "Sailing questions": "Segelfragen",
    "Sea questions": "Seefragen",

    # Exam formats & licence
    "Inland · motor": "Binnen · Motor",
    "Inland · sail": "Binnen · Segel",
    "Inland · motor + sail": "Binnen · Motor + Segel",
    "Sailing add-on": "Segel-Ergänzung",
    "%@ · %lld min": "%@ · %lld Min.",
    "%lld of %lld %@": "%lld von %lld %@",
    "Pass: at least %@": "Bestanden mit mindestens %@",
    "Pass: at least %lld of %lld correct in total": "Bestanden mit mindestens %lld von %lld richtigen Antworten insgesamt",
    "Each part is assessed separately and must be passed.": "Jeder Teil wird getrennt bewertet und muss bestanden werden.",
    "For the sailing licence alone, only the total counts.": "Beim reinen Segelschein zählt nur die Gesamtzahl richtiger Antworten.",
    "My licence": "Mein Führerschein",
    "Not needed": "Nicht nötig",
    "Motor": "Motor",
    "Sail": "Segel",
    "Motor + sail": "Motor + Segel",
    "Sail only – I already hold SBF Inland (motor)": "Nur Segel – ich habe schon den SBF Binnen (Motor)",
    "Also preparing for SBF Sea": "Ich mache auch den SBF See",
    "Exam simulations": "Prüfungssimulationen",
    "The sailing licence for inland waters has its own exam with 7 extra sailing questions.":
        "Für den Binnenschein unter Segel gibt es eine eigene Prüfung mit 7 zusätzlichen Segelfragen.",
    "Your choice decides which exam simulations are offered. All questions stay available for practice.":
        "Deine Auswahl bestimmt, welche Prüfungssimulationen angeboten werden. Zum Üben bleiben alle Fragen verfügbar.",
    "Which licence are you taking?": "Welchen Führerschein machst du?",
    "This decides which exam simulations you get. You can change it any time in Settings.":
        "Davon hängt ab, welche Prüfungssimulationen du bekommst. Du kannst es jederzeit in den Einstellungen ändern.",
    "New: sailing questions": "Neu: Segelfragen",
    "Choose your licence to get the right exam simulation.":
        "Wähle deinen Führerschein, um die passende Prüfungssimulation zu bekommen.",
    "All questions": "Alle Fragen",
    "Basic questions": "Basisfragen",
    "SBF Inland": "SBF Binnen",
    "SBF Inland (motor)": "SBF Binnen (Motor)",
    "SBF Inland (specific)": "SBF Binnen (spezifisch)",
    "SBF Sea": "SBF See",
    "SBF Sea (specific)": "SBF See (spezifisch)",
    "%@-specific questions": "%@-spezifische Fragen",
    "Sportbootführerschein Binnen & See": "Sportbootführerschein Binnen & See",
    "SBF Exam Prep": "SBF Exam Prep",

    # Home
    "Accuracy": "Trefferquote",
    "Answered": "Beantwortet",
    "Mastered": "Gelernt",
    "Day streak": "Tage in Folge",
    "Today": "Heute",
    "Nothing due right now": "Gerade nichts fällig",
    "Questions come back at growing intervals until you know them for good.":
        "Fragen kommen in wachsenden Abständen wieder, bis du sie sicher kannst.",
    "Answer new questions — anything you get wrong will come back for review.":
        "Beantworte neue Fragen – was du falsch beantwortest, kommt zur Wiederholung zurück.",
    "Start review": "Wiederholung starten",
    "Start a quick quiz": "Schnelles Quiz starten",
    "Study streak": "Lernserie",
    "^[%lld day](inflect: true)": "^[%lld Tag](inflect: true)",
    "Studied": "Gelernt",
    "Not studied": "Nicht gelernt",
    "Quick start": "Schnellstart",
    "Quick quiz": "Schnelles Quiz",
    "Exam simulation · Inland": "Prüfungssimulation · Binnen",
    "Exam simulation · Sea": "Prüfungssimulation · See",
    "7 basic + 23 inland questions · 45 min": "7 Basis- + 23 Binnenfragen · 45 Min.",
    "7 basic + 23 sea questions · 60 min": "7 Basis- + 23 Seefragen · 60 Min.",
    "Practise mistakes": "Fehler üben",
    "All questions in order": "Alle Fragen der Reihe nach",
    "Go through the whole catalogue": "Den ganzen Fragenkatalog durchgehen",
    "Recent quizzes": "Letzte Quiz",
    "Exam · %@": "Prüfung · %@",
    "Quiz · %@": "Quiz · %@",
    "%lld/%lld": "%lld/%lld",
    "%lld": "%lld",
    "%lld×": "%lld×",

    # Browse
    "Select a question": "Frage auswählen",
    "Choose a question from the list to study it.": "Wähle links eine Frage aus, um sie zu lernen.",
    "Search questions": "Fragen durchsuchen",
    "Choose exam and topic": "Prüfung und Thema wählen",
    "All topics": "Alle Themen",
    "Show only mistakes": "Nur Fehler anzeigen",
    "Show only saved questions": "Nur gemerkte Fragen anzeigen",
    "Exam": "Prüfung",
    "Topic": "Thema",
    "Reset": "Zurücksetzen",
    "Done": "Fertig",
    "Question %lld: %@": "Frage %lld: %@",
    "Answered wrongly": "Falsch beantwortet",

    # Question detail
    "Tap an answer to check yourself": "Tippe auf eine Antwort, um dich zu prüfen",
    "Show correct answer": "Richtige Antwort zeigen",
    "Next question": "Nächste Frage",
    "Previous question": "Vorherige Frage",
    "%lld of %lld": "%lld von %lld",
    "Question %lld": "Frage %lld",
    "No. %lld": "Nr. %lld",
    "Review box %lld of 5": "Lernstufe %lld von 5",
    "Remove from saved": "Nicht mehr merken",
    "Save question": "Frage merken",
    "Answer %@: %@": "Antwort %@: %@",
    "Correct answer": "Richtige Antwort",
    "Wrong": "Falsch",
    "Correct": "Richtig",
    "Why?": "Warum?",

    # Media
    "Double-tap to enlarge": "Zum Vergrößern doppeltippen",
    "Illustration for question %lld": "Abbildung zu Frage %lld",
    "Sound signal: %@": "Schallsignal: %@",
    "Close": "Schließen",
    "Play signal": "Signal abspielen",
    "Stop": "Stopp",
    "Play sound signal": "Schallsignal abspielen",
    "Stop sound signal": "Schallsignal stoppen",
    "short": "kurz",
    "prolonged": "lang",
    "pause": "Pause",

    # Quiz
    "No questions": "Keine Fragen",
    "There are no questions for this selection.": "Für diese Auswahl gibt es keine Fragen.",
    "Close quiz": "Quiz schließen",
    "%lld / %lld": "%lld / %lld",
    "Question %lld of %lld": "Frage %lld von %lld",
    "End the exam?": "Prüfung beenden?",
    "Finish and see result": "Beenden und Ergebnis ansehen",
    "Quit without result": "Ohne Ergebnis abbrechen",
    "Continue": "Weiter",
    "Unanswered questions count as wrong.": "Unbeantwortete Fragen zählen als falsch.",
    "Selected": "Ausgewählt",
    "Your answer, wrong": "Deine Antwort, falsch",
    "Exam simulation · %@": "Prüfungssimulation · %@",
    "Time remaining: %@": "Verbleibende Zeit: %@",
    "See results": "Ergebnis ansehen",

    # Results
    "Passed": "Bestanden",
    "Not passed": "Nicht bestanden",
    "Excellent!": "Hervorragend!",
    "Great job!": "Sehr gut!",
    "Good effort": "Gut gemacht",
    "Keep practising": "Weiter üben",
    "Exam passed": "Prüfung bestanden",
    "Exam not passed": "Prüfung nicht bestanden",
    "%lld of %lld answered correctly": "%lld von %lld richtig beantwortet",
    "Official scoring": "Offizielle Bewertung",
    "Both parts are assessed separately and must each be passed.":
        "Beide Teile werden getrennt bewertet und müssen jeweils bestanden werden.",
    "The real SBF See exam also includes a navigation task (9 questions, at least 7 correct), which is not part of this simulation.":
        "Die echte SBF-See-Prüfung enthält zusätzlich eine Navigationsaufgabe (9 Fragen, mindestens 7 richtig), die nicht Teil dieser Simulation ist.",
    "Pass mark: %lld of %lld": "Bestehensgrenze: %lld von %lld",
    "Review your mistakes": "Fehler ansehen",
    "New exam simulation": "Neue Prüfungssimulation",
    "Retry these questions": "Diese Fragen wiederholen",

    # Quiz setup
    "Exam simulation": "Prüfungssimulation",
    "Configure your quiz": "Quiz zusammenstellen",
    "Mode": "Modus",
    "Practice": "Üben",
    "Random questions with instant feedback": "Zufällige Fragen mit sofortiger Rückmeldung",
    "Due for review": "Fällige Wiederholungen",
    "Mistakes": "Fehler",
    "Official composition, time limit and pass marks": "Offizielle Zusammenstellung, Zeit und Bestehensgrenzen",
    "%lld basic + %lld specific questions": "%lld Basis- + %lld spezifische Fragen",
    "Pass: at least %lld of %lld basic and %lld of %lld specific":
        "Bestanden: mind. %lld von %lld Basisfragen und %lld von %lld spezifischen Fragen",
    "No feedback until the end, like the real exam": "Keine Rückmeldung bis zum Schluss – wie in der echten Prüfung",
    "The navigation task of the SBF See exam is not included": "Die Navigationsaufgabe der SBF-See-Prüfung ist nicht enthalten",
    "Source: ELWIS scoring key for the SBF theory exam.": "Quelle: ELWIS-Bewertungsschlüssel der theoretischen SBF-Prüfung.",
    "Topic (optional)": "Thema (optional)",
    "Number of questions": "Anzahl der Fragen",
    "Spaced repetition": "Intelligente Wiederholung",
    "Questions you answered come back after 1, 3, 7, 14 and 30 days. A wrong answer starts the cycle again.":
        "Beantwortete Fragen kommen nach 1, 3, 7, 14 und 30 Tagen wieder. Eine falsche Antwort startet den Zyklus neu.",
    "Your mistakes": "Deine Fehler",
    "Questions you answered wrongly, most frequent first. Answer one correctly to reduce its count.":
        "Falsch beantwortete Fragen, die häufigsten zuerst. Eine richtige Antwort verringert den Zähler.",
    "Start exam simulation": "Prüfungssimulation starten",

    # Saved / mistakes
    "Saved questions": "Gemerkte Fragen",
    "Practise": "Üben",
    "No saved questions": "Keine gemerkten Fragen",
    "Tap the bookmark while browsing or during a quiz to collect questions here.":
        "Tippe beim Lernen oder im Quiz auf das Lesezeichen, um Fragen hier zu sammeln.",
    "Remove": "Entfernen",
    "No mistakes": "Keine Fehler",
    "Questions you answer wrongly will appear here.": "Falsch beantwortete Fragen erscheinen hier.",
    "Swipe right to mark a question as mastered, swipe left to remove it.":
        "Nach rechts wischen markiert eine Frage als gelernt, nach links entfernt sie.",

    # Settings
    "Show English translation": "Englische Übersetzung anzeigen",
    "Default quiz length": "Standardlänge eines Quiz",
    "App language": "App-Sprache",
    "Learning": "Lernen",
    "Exam questions are always shown in German, as in the official exam. The app language can be changed in the system settings.":
        "Prüfungsfragen werden immer auf Deutsch angezeigt, wie in der offiziellen Prüfung. Die App-Sprache lässt sich in den Systemeinstellungen ändern.",
    "Daily reminder": "Tägliche Erinnerung",
    "Time": "Uhrzeit",
    "Allow notifications in Settings": "Mitteilungen in den Einstellungen erlauben",
    "Reminders": "Erinnerungen",
    "A local notification on this device. No data is sent anywhere.":
        "Eine lokale Mitteilung auf diesem Gerät. Es werden keine Daten übertragen.",
    "Sync with iCloud": "Mit iCloud synchronisieren",
    "Sync": "Synchronisierung",
    "Keeps your progress in your own iCloud account so it follows you to your other devices. The developer has no access to it.":
        "Speichert deinen Fortschritt in deinem eigenen iCloud-Konto, damit er auf deinen anderen Geräten verfügbar ist. Der Entwickler hat keinen Zugriff darauf.",
    "Questions answered": "Beantwortete Fragen",
    "Overall accuracy": "Trefferquote gesamt",
    "Mistakes to review": "Fehler zum Wiederholen",
    "Quizzes completed": "Abgeschlossene Quiz",
    "Statistics": "Statistik",
    "Total": "Gesamt",
    "Question catalogue": "Fragenkatalog",
    "Official ELWIS catalogue, August 2023. The basic questions are part of both exams.":
        "Offizieller ELWIS-Fragenkatalog, August 2023. Die Basisfragen gehören zu beiden Prüfungen.",
    "About SBF Exam Prep": "Über SBF Exam Prep",
    "Help & feedback": "Hilfe & Feedback",
    "Privacy policy": "Datenschutzerklärung",
    "Rate the app": "App bewerten",
    "Version %@": "Version %@",
    "Reset all progress": "Gesamten Fortschritt zurücksetzen",
    "Data": "Daten",
    "Reset progress?": "Fortschritt zurücksetzen?",
    "Cancel": "Abbrechen",
    "This erases your quiz history, saved questions, mistakes and review schedule on all devices that use iCloud sync. This cannot be undone.":
        "Dadurch werden Quiz-Verlauf, gemerkte Fragen, Fehler und Wiederholungsplan auf allen Geräten mit iCloud-Synchronisierung gelöscht. Das kann nicht rückgängig gemacht werden.",
    "Time to study! ⛵": "Zeit zum Lernen! ⛵",
    "Keep your streak going – a short SBF quiz takes just 5 minutes.":
        "Halte deine Serie – ein kurzes SBF-Quiz dauert nur 5 Minuten.",

    # Onboarding
    "Pass your German boating licence exam": "Bestehe deine Sportbootführerschein-Prüfung",
    "All %lld official questions, exam simulation and spaced repetition.":
        "Alle %lld offiziellen Fragen, Prüfungssimulation und intelligente Wiederholung.",
    "Everything you need": "Alles, was du brauchst",
    "Official questions": "Offizielle Fragen",
    "The complete ELWIS catalogue (August 2023) for SBF Binnen (motor and sail) and SBF See, in German with English translations.":
        "Der vollständige ELWIS-Fragenkatalog (August 2023) für SBF Binnen (Motor und Segel) und SBF See, auf Deutsch mit englischer Übersetzung.",
    "Real exam simulation": "Echte Prüfungssimulation",
    "The official composition, pass marks and time limit for your licence.":
        "Offizielle Zusammensetzung, Bestehensgrenzen und Zeitlimit für deinen Führerschein.",
    "Signs, lights & sound signals": "Zeichen, Lichter & Schallsignale",
    "Clear illustrations for every image question — and sound signals you can listen to.":
        "Klare Abbildungen zu jeder Bildfrage – und Schallsignale zum Anhören.",
    "Stay on track": "Dranbleiben",
    "Get a daily reminder at 6 pm to keep your streak going. You can change the time or turn it off in Settings.":
        "Erhalte täglich um 18 Uhr eine Erinnerung, um deine Serie zu halten. Uhrzeit und Erinnerung kannst du in den Einstellungen ändern.",
    "Enable daily reminder": "Tägliche Erinnerung aktivieren",
    "Not now": "Jetzt nicht",
    "Translations": "Übersetzungen",
    "The exam is in German. Show an English translation below each question and answer?":
        "Die Prüfung ist auf Deutsch. Soll unter jeder Frage und Antwort eine englische Übersetzung stehen?",
    "German only": "Nur Deutsch",
    "German + English": "Deutsch + Englisch",
    "Page %lld of %lld": "Seite %lld von %lld",
    "Get started": "Los geht's",

    # About
    "About this app": "Über diese App",
    "SBF Exam Prep helps you prepare for the theory exam of the German recreational boating licence — Sportbootführerschein Binnen (motor and sail) and See.":
        "SBF Exam Prep bereitet dich auf die theoretische Prüfung zum Sportbootführerschein Binnen (unter Antriebsmaschine und unter Segel) und See vor.",
    "Every question is shown in German, as in the exam, with an optional English translation.":
        "Jede Frage wird wie in der Prüfung auf Deutsch angezeigt, wahlweise mit englischer Übersetzung.",
    "Illustrated questions": "Fragen mit Abbildung",
    "Features": "Funktionen",
    "Practice quizzes with instant feedback": "Übungs-Quiz mit sofortiger Rückmeldung",
    "Exam simulation with the official pass marks": "Prüfungssimulation mit offiziellen Bestehensgrenzen",
    "Spaced repetition and mistake review": "Intelligente Wiederholung und Fehlertraining",
    "Sound signals you can listen to": "Schallsignale zum Anhören",
    "Progress sync via iCloud": "Fortschritt per iCloud synchronisieren",
    "Sources & legal": "Quellen & Rechtliches",
    "Questions and answers: official question catalogue for the Sportbootführerschein, published on ELWIS by the Generaldirektion Wasserstraßen und Schifffahrt (status: August 2023).":
        "Fragen und Antworten: amtlicher Fragenkatalog für den Sportbootführerschein, veröffentlicht auf ELWIS von der Generaldirektion Wasserstraßen und Schifffahrt (Stand: August 2023).",
    "Illustrations were drawn for this app following the official figures. English translations are unofficial study aids; only the German text is valid in the exam.":
        "Die Abbildungen wurden für diese App nach den amtlichen Vorlagen gezeichnet. Die englischen Übersetzungen sind inoffizielle Lernhilfen; in der Prüfung gilt nur der deutsche Text.",
    "This app is an independent study aid and is not affiliated with or endorsed by the GDWS, ELWIS, the DMYV or the DSV. Always check the current regulations.":
        "Diese App ist eine unabhängige Lernhilfe und steht in keiner Verbindung zur GDWS, zu ELWIS, zum DMYV oder zum DSV. Bitte prüfe stets die aktuellen Vorschriften.",
    "Official information on ELWIS": "Offizielle Informationen auf ELWIS",
    "Official source: elwis.de": "Offizielle Quelle: elwis.de",
    "Questions from the official ELWIS catalogue (GDWS). Independent study aid, not a government app.":
        "Fragen aus dem amtlichen ELWIS-Fragenkatalog (GDWS). Unabhängige Lernhilfe, keine Behörden-App.",
    "© 2026 SBF Exam Prep": "© 2026 SBF Exam Prep",

    # Widget
    "day streak": "Tage in Folge",
    "All caught up": "Alles erledigt",
    "Studied today ✓": "Heute gelernt ✓",
    "Keep your streak!": "Halte deine Serie!",
    "accuracy": "Trefferquote",
    "mastered": "gelernt",
    "answered": "beantwortet",
    "Study progress": "Lernfortschritt",
    "Your streak and the questions due for review.": "Deine Lernserie und die fälligen Wiederholungen.",
}

# key → (en_one, en_other, de_one, de_other)
PLURALS = {
    "%lld questions": ("%lld question", "%lld questions", "%lld Frage", "%lld Fragen"),
    "%lld questions answered wrongly": ("%lld question answered wrongly", "%lld questions answered wrongly",
                                        "%lld Frage falsch beantwortet", "%lld Fragen falsch beantwortet"),
    "%lld questions available": ("%lld question available", "%lld questions available",
                                 "%lld Frage verfügbar", "%lld Fragen verfügbar"),
    "%lld questions due for review": ("%lld question due for review", "%lld questions due for review",
                                      "%lld Frage zur Wiederholung fällig", "%lld Fragen zur Wiederholung fällig"),
    "%lld questions due today": ("%lld question due today", "%lld questions due today",
                                 "%lld Frage heute fällig", "%lld Fragen heute fällig"),
    "%lld questions to retry": ("%lld question to retry", "%lld questions to retry",
                                "%lld Frage zum Wiederholen", "%lld Fragen zum Wiederholen"),
    "%lld random questions": ("%lld random question", "%lld random questions",
                              "%lld zufällige Frage", "%lld zufällige Fragen"),
    "Answered wrongly %lld times": ("Answered wrongly once", "Answered wrongly %lld times",
                                    "Einmal falsch beantwortet", "%lld-mal falsch beantwortet"),
    "Practise the %lld mistakes": ("Practise the mistake", "Practise the %lld mistakes",
                                   "Den Fehler üben", "Die %lld Fehler üben"),
    "Start · %lld questions": ("Start · %lld question", "Start · %lld questions",
                               "Start · %lld Frage", "Start · %lld Fragen"),
    "Time limit: %lld minutes": ("Time limit: %lld minute", "Time limit: %lld minutes",
                                 "Zeitlimit: %lld Minute", "Zeitlimit: %lld Minuten"),
    "Saved (%lld)": None,
    "Mistakes (%lld)": None,
    # widget
    "%lld questions due": ("%lld question due", "%lld questions due", "%lld Frage fällig", "%lld Fragen fällig"),
    "%lld due": ("%lld due", "%lld due", "%lld fällig", "%lld fällig"),
    "%lld-day streak": ("%lld-day streak", "%lld-day streak", "%lld Tag in Folge", "%lld Tage in Folge"),
}
DE.update({"Saved (%lld)": "Gemerkt (%lld)", "Mistakes (%lld)": "Fehler (%lld)"})


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def entry(key: str):
    plural = PLURALS.get(key)
    if plural:
        en1, en2, de1, de2 = plural
        return {"localizations": {
            "en": {"variations": {"plural": {"one": unit(en1), "other": unit(en2)}}},
            "de": {"variations": {"plural": {"one": unit(de1), "other": unit(de2)}}},
        }}
    if key not in DE:
        raise SystemExit(f"Missing German translation for: {key!r}")
    return {"localizations": {"de": unit(DE[key])}}


def keys_from_derived_data(dd: Path):
    keys = {"app": set(), "widget": set()}
    pattern = str(dd / "Build/Intermediates.noindex/SBFTrainer.build/*/*/Objects-normal/*/*.stringsdata")
    for f in glob.glob(pattern):
        if "/SBFTrainerTests.build/" in f:
            continue
        target = "widget" if "/SBFWidget.build/" in f else "app"
        data = json.loads(Path(f).read_text())
        for entries in data.get("tables", {}).values():
            for e in entries:
                if e["key"].strip():
                    keys[target].add(e["key"])
    return keys


def write(path: Path, keys):
    catalog = {"sourceLanguage": "en", "version": "1.0",
               "strings": {k: entry(k) for k in sorted(keys)}}
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{path.relative_to(ROOT)}: {len(keys)} strings")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--derived-data", type=Path)
    args = ap.parse_args()
    keyfile = Path(__file__).with_name("keys.json")
    if args.derived_data:
        keys = keys_from_derived_data(args.derived_data)
        keyfile.write_text(json.dumps({k: sorted(v) for k, v in keys.items()}, ensure_ascii=False, indent=1))
    else:
        keys = {k: set(v) for k, v in json.loads(keyfile.read_text()).items()}
    write(ROOT / "SBFTrainer" / "Localizable.xcstrings", keys["app"])
    write(ROOT / "SBFWidget" / "Localizable.xcstrings", keys["widget"])


if __name__ == "__main__":
    main()

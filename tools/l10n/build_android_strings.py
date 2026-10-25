#!/usr/bin/env python3
"""Builds the Android string resources (values/ and values-de/) from the same
German translations the iOS String Catalogs use (build_catalogs.DE / PLURALS).

    python3 tools/l10n/build_android_strings.py

Each resource maps to an iOS source key, or to an (English, German) pair for
Android-only text. iOS placeholders (%lld, %@) become Android ones (%1$d, %1$s).
"""

from __future__ import annotations

import re
from pathlib import Path
from xml.sax.saxutils import escape

from build_catalogs import DE, PLURALS

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "android" / "app" / "src" / "main" / "res"

NOT_TRANSLATABLE = {"app_name": "SBF Exam Prep"}

STRINGS = {
    # Tabs & general
    "tab_home": "Home", "tab_browse": "Browse", "tab_quiz": "Quiz", "tab_saved": "Saved", "tab_settings": "Settings",
    "about": "About", "results": "Results", "done": "Done", "cancel": "Cancel", "close": "Close", "reset": "Reset",
    "continue_label": "Continue", "remove": "Remove",
    "back": ("Back", "Zurück"),
    "clear": ("Clear search", "Suche löschen"),
    # Resource-selected display language for catalogue texts (categories, explanations).
    "content_language": ("en", "de"),
    "app_subtitle": "Sportbootführerschein Binnen & See",

    # Exam types
    "exam_all": "All", "exam_basic": "Basic", "exam_inland": "Inland", "exam_sea": "Sea", "exam_sailing": "Sailing",
    "licence_all": "All questions", "licence_basic": "Basic questions",
    "licence_inland": "SBF Inland", "licence_sea": "SBF Sea", "licence_sailing": "SBF Inland · sailing",
    "part_questions": "questions", "part_basic": "basic", "part_inland": "inland", "part_sailing": "sailing",
    "part_sea": "sea", "part_title_inland": "Inland questions", "part_title_sailing": "Sailing questions",
    "part_title_sea": "Sea questions",

    # Feature flags
    "experimental_features": "Experimental features",
    "experimental_footer": "For testing only. These features are not finished and may change.",
    "ff_navigation_tasks": "Navigation tasks", "ff_navigation_tasks_sub": "The 15 official chart tasks with worked solutions.",
    "ff_navigation_exam": "Navigation part in the Sea exam",
    "ff_navigation_exam_sub": "Adds 9 navigation questions to the SBF Sea exam simulation.",
    "ff_navigation_drills": "Navigation drills", "ff_navigation_drills_sub": "Unlimited course, time and light character practice.",
    "ff_navigation_diagrams": "Solution diagrams", "ff_navigation_diagrams_sub": "Step-by-step plot of each solution with narration.",
    "ff_navigation_videos": "Technique videos", "ff_navigation_videos_sub": "Links to videos about working on the chart.",

    # Navigation tasks
    "nav_home_title": "Navigation tasks · Sea", "nav_home_sub": "15 official chart tasks with worked solutions",
    "nav_tasks_title": "Navigation tasks", "nav_glossary": "Terms and abbreviations", "nav_tasks_section": "Tasks",
    "nav_task_n": "Task %lld",
    "nav_source": "Source: ELWIS navigation tasks, status August 2023. English translations are unofficial.",
    "nav_chart_title": "You need practice chart D49",
    "nav_chart_text": "In the exam the 9 navigation questions are solved on paper chart D49 with a plotting triangle and dividers. The app explains every step and the arithmetic.",
    "nav_variation": "Variation (Mw) on this chart excerpt: %@",
    "nav_show_all": "Show all answers", "nav_hide_all": "Hide all answers",
    "nav_chart_work": "Chart work: draw this on chart D49.", "nav_official_result": "Official result",
    "nav_how_to_solve": "How to solve it", "nav_show_solution": "Show solution", "nav_hide_solution": "Hide solution",
    "nav_signs": "Signs: east variation and deviation are positive (+), west negative (−).",
    "nav_question_types": "Exam question types",

    # Navigation exam
    "part_navigation": "navigation", "nav_exam_title": "Navigation task", "nav_exam_task_n": "Navigation task %lld",
    "nav_exam_hint": "Work on chart D49 and type your results. Chart work and descriptions are compared with the official result at the end.",
    "nav_exam_tolerance": "Practice tolerance for typed answers: ±%lld° for courses and bearings, ±%@ nm, ±%lld min, ±%@' for positions. ELWIS publishes no official tolerances.",
    "nav_field_degrees": "Degrees", "nav_field_distance": "Distance", "nav_field_minutes": "Minutes", "nav_field_speed": "Speed",
    "nav_field_clock": "hh:mm", "nav_field_lat_deg": "Lat °", "nav_field_lat_min": "Lat '", "nav_field_lon_deg": "Long °",
    "nav_field_lon_min": "Long '", "nav_field_text": "Your answer (optional)", "nav_unit_nm": "nm",
    "nav_self_grade_hint": "Compare your chart work and descriptions with the official result and mark them yourself.",
    "nav_your_answer": "Your answer: %@", "nav_official_answer": "Official: %@", "nav_self_right": "I had it right",

    # Exam formats & licence
    "format_binnen_motor": "Inland · motor", "format_binnen_sail": "Inland · sail",
    "format_binnen_motor_sail": "Inland · motor + sail", "format_sail_addon": "Sailing add-on",
    "exam_summary": "%@ · %lld min", "part_pass": "%lld of %lld %@", "list_and": ("%1$s and %2$s", "%1$s und %2$s"),
    "rules_pass_parts": "Pass: at least %@",
    "rules_pass_total": "Pass: at least %lld of %lld correct in total",
    "each_part": "Each part is assessed separately and must be passed.",
    "total_only": "For the sailing licence alone, only the total counts.",
    "total": "Total",
    "my_licence": "My licence", "licence_none": "Not needed", "licence_motor": "Motor", "licence_sail": "Sail",
    "licence_motor_sail": "Motor + sail", "licence_sail_addon": "Sail only – I already hold SBF Inland (motor)",
    "licence_also_sea": "Also preparing for SBF Sea",
    "licence_inland_footer": "The sailing licence for inland waters has its own exam with 7 extra sailing questions.",
    "licence_footer": "Your choice decides which exam simulations are offered. All questions stay available for practice.",
    "licence_question": "Which licence are you taking?",
    "licence_question_sub": "This decides which exam simulations you get. You can change it any time in Settings.",
    "new_sailing": "New: sailing questions",
    "new_sailing_sub": "Choose your licence to get the right exam simulation.",
    "sbf_inland": "SBF Inland", "sbf_inland_specific": "SBF Inland (specific)", "sbf_sea_specific": "SBF Sea (specific)",

    # Home
    "accuracy": "Accuracy", "answered": "Answered", "mastered": "Mastered", "day_streak": "Day streak",
    "today": "Today", "nothing_due": "Nothing due right now",
    "due_explainer": "Questions come back at growing intervals until you know them for good.",
    "nothing_due_explainer": "Answer new questions — anything you get wrong will come back for review.",
    "start_review": "Start review", "start_quick_quiz": "Start a quick quiz", "study_streak": "Study streak",
    "studied": "Studied", "not_studied": "Not studied", "quick_start": "Quick start", "quick_quiz": "Quick quiz",
    "practise_mistakes": "Practise mistakes", "all_in_order": "All questions in order",
    "all_in_order_sub": "Go through the whole catalogue", "recent_quizzes": "Recent quizzes",
    "recent_exam": "Exam · %@", "recent_quiz": "Quiz · %@", "score_fraction": "%lld/%lld",

    # Browse
    "select_question": "Select a question", "select_question_hint": "Choose a question from the list to study it.",
    "search_questions": "Search questions", "choose_exam_topic": "Choose exam and topic", "all_topics": "All topics",
    "exam": "Exam", "topic": "Topic", "answered_wrongly": "Answered wrongly", "question_label": "Question %lld: %@",
    "no_results": ("No matching questions", "Keine passenden Fragen"),

    # Question
    "tap_to_check": "Tap an answer to check yourself", "show_correct_answer": "Show correct answer",
    "next_question": "Next question", "previous_question": "Previous question", "n_of_m": "%lld of %lld",
    "question_number": "Question %lld", "number_short": "No. %lld", "review_box": "Review box %lld of 5",
    "remove_from_saved": "Remove from saved", "save_question": "Save question", "answer_label": "Answer %@: %@",
    "correct_answer": "Correct answer", "wrong": "Wrong", "correct": "Correct", "why": "Why?",

    # Media
    "tap_to_enlarge": ("Enlarge", "Vergrößern"),
    "illustration_for": "Illustration for question %lld", "sound_signal_label": "Sound signal: %@",
    "play_signal": "Play signal", "stop": "Stop", "play_sound_signal": "Play sound signal",
    "stop_sound_signal": "Stop sound signal", "blast_short": "short", "blast_prolonged": "prolonged",
    "blast_pause": "pause",

    # Quiz
    "no_questions": "No questions", "no_questions_desc": "There are no questions for this selection.",
    "close_quiz": "Close quiz", "progress_fraction": "%lld / %lld", "question_n_of_m": "Question %lld of %lld",
    "end_exam_title": "End the exam?", "finish_see_result": "Finish and see result",
    "quit_without_result": "Quit without result", "unanswered_wrong": "Unanswered questions count as wrong.",
    "answer_selected": "Selected", "your_answer_wrong": "Your answer, wrong", "exam_sim_type": "Exam simulation · %@",
    "time_remaining": "Time remaining: %@", "see_results": "See results",

    # Results
    "passed": "Passed", "not_passed": "Not passed", "excellent": "Excellent!", "great_job": "Great job!",
    "good_effort": "Good effort", "keep_practising": "Keep practising", "exam_passed": "Exam passed",
    "exam_not_passed": "Exam not passed", "answered_correctly": "%lld of %lld answered correctly",
    "official_scoring": "Official scoring",
    "navigation_task_note": "The real SBF See exam also includes a navigation task (9 questions, at least 7 correct), which is not part of this simulation.",
    "pass_mark": "Pass mark: %lld of %lld", "review_mistakes": "Review your mistakes",
    "new_exam_sim": "New exam simulation", "retry_questions": "Retry these questions",

    # Quiz setup
    "exam_simulation": "Exam simulation", "configure_quiz": "Configure your quiz", "mode": "Mode",
    "practice": "Practice", "practice_sub": "Random questions with instant feedback",
    "due_for_review": "Due for review", "mistakes": "Mistakes",
    "exam_sim_sub": "Official composition, time limit and pass marks",
    "rules_feedback": "No feedback until the end, like the real exam",
    "rules_navigation": "The navigation task of the SBF See exam is not included",
    "rules_source": "Source: ELWIS scoring key for the SBF theory exam.",
    "topic_optional": "Topic (optional)", "number_of_questions": "Number of questions",
    "spaced_repetition": "Spaced repetition",
    "spaced_repetition_text": "Questions you answered come back after 1, 3, 7, 14 and 30 days. A wrong answer starts the cycle again.",
    "your_mistakes": "Your mistakes",
    "your_mistakes_text": "Questions you answered wrongly, most frequent first. Answer one correctly to reduce its count.",
    "start_exam_sim": "Start exam simulation",

    # Saved
    "saved_questions": "Saved questions", "practise": "Practise", "no_saved": "No saved questions",
    "no_saved_text": "Tap the bookmark while browsing or during a quiz to collect questions here.",
    "no_mistakes": "No mistakes", "no_mistakes_text": "Questions you answer wrongly will appear here.",
    "saved_count": "Saved (%lld)", "mistakes_count": "Mistakes (%lld)",
    "mark_mastered": ("Mark as mastered", "Als gelernt markieren"),

    # Settings
    "show_english": "Show English translation", "default_quiz_length": "Default quiz length",
    "app_language": "App language", "learning": "Learning",
    "learning_footer": "Exam questions are always shown in German, as in the official exam. The app language can be changed in the system settings.",
    "daily_reminder": "Daily reminder", "time": "Time", "allow_notifications": "Allow notifications in Settings",
    "reminders": "Reminders", "reminders_footer": "A local notification on this device. No data is sent anywhere.",
    "backup": ("Backup", "Sicherung"),
    "backup_local": ("Saved on this device", "Auf diesem Gerät gespeichert"),
    "backup_footer": ("Your progress stays on this device. If Android backup is turned on, it is included in your own Google account backup. The developer has no access to it.",
                      "Dein Fortschritt bleibt auf diesem Gerät. Ist die Android-Sicherung aktiviert, ist er in der Sicherung deines eigenen Google-Kontos enthalten. Der Entwickler hat keinen Zugriff darauf."),
    "statistics": "Statistics", "questions_answered": "Questions answered", "overall_accuracy": "Overall accuracy",
    "mistakes_to_review": "Mistakes to review", "quizzes_completed": "Quizzes completed", "total": "Total",
    "question_catalogue": "Question catalogue",
    "catalogue_footer": ("Official ELWIS catalogue, August 2023. The basic questions are part of every exam.",
                         "Offizieller ELWIS-Fragenkatalog, August 2023. Die Basisfragen gehören zu jeder Prüfung."),
    "about_app": "About SBF Exam Prep", "help_feedback": "Help & feedback", "privacy_policy": "Privacy policy",
    "rate_app": "Rate the app", "version": "Version %@", "reset_all": "Reset all progress", "data": "Data",
    "reset_title": "Reset progress?",
    "reset_message": ("This erases your quiz history, saved questions, mistakes and review schedule on this device. This cannot be undone.",
                      "Dadurch werden Quiz-Verlauf, gemerkte Fragen, Fehler und Wiederholungsplan auf diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden."),
    "reminder_title": "Time to study! ⛵",
    "reminder_body": "Keep your streak going – a short SBF quiz takes just 5 minutes.",
    "reminder_channel": ("Study reminders", "Lernerinnerungen"),

    # Onboarding
    "pass_your_exam": "Pass your German boating licence exam",
    "onboarding_all_questions": "All %lld official questions, exam simulation and spaced repetition.",
    "everything_you_need": "Everything you need", "official_questions": "Official questions",
    "official_questions_text": "The complete ELWIS catalogue (August 2023) for SBF Binnen (motor and sail) and SBF See, in German with English translations.",
    "real_exam_sim": "Real exam simulation",
    "real_exam_sim_text": "The official composition, pass marks and time limit for your licence.",
    "signs_lights_sounds": "Signs, lights & sound signals",
    "signs_lights_sounds_text": "Clear illustrations for every image question — and sound signals you can listen to.",
    "stay_on_track": "Stay on track",
    "reminder_pitch": "Get a daily reminder at 6 pm to keep your streak going. You can change the time or turn it off in Settings.",
    "enable_reminder": "Enable daily reminder", "not_now": "Not now", "translations": "Translations",
    "translations_question": "The exam is in German. Show an English translation below each question and answer?",
    "german_only": "German only", "german_english": "German + English", "page_n_of_m": "Page %lld of %lld",
    "get_started": "Get started",

    # About
    "about_this_app": "About this app",
    "about_text_1": "SBF Exam Prep helps you prepare for the theory exam of the German recreational boating licence — Sportbootführerschein Binnen (motor and sail) and See.",
    "about_text_2": "Every question is shown in German, as in the exam, with an optional English translation.",
    "illustrated_questions": "Illustrated questions", "features": "Features",
    "feature_practice": "Practice quizzes with instant feedback",
    "feature_exam": "Exam simulation with the official pass marks",
    "feature_spaced": "Spaced repetition and mistake review", "feature_sounds": "Sound signals you can listen to",
    "sources_legal": "Sources & legal",
    "sources_1": "Questions and answers: official question catalogue for the Sportbootführerschein, published on ELWIS by the Generaldirektion Wasserstraßen und Schifffahrt (status: August 2023).",
    "sources_2": "Illustrations were drawn for this app following the official figures. English translations are unofficial study aids; only the German text is valid in the exam.",
    "sources_3": "This app is an independent study aid and is not affiliated with or endorsed by the GDWS, ELWIS, the DMYV or the DSV. Always check the current regulations.",
    "elwis_info": "Official information on ELWIS",
    "source_elwis": ("Official source: elwis.de", "Offizielle Quelle: elwis.de"),
    "not_government": ("Questions from the official ELWIS catalogue (GDWS). Independent study aid, not a government app.",
                       "Fragen aus dem amtlichen ELWIS-Fragenkatalog (GDWS). Unabhängige Lernhilfe, keine Behörden-App."), "copyright": "© 2026 SBF Exam Prep",
}

PLURAL_RES = {
    "answered_wrongly_times": "Answered wrongly %lld times",
    "practise_the_mistakes": "Practise the %lld mistakes",
    "questions_answered_wrongly": "%lld questions answered wrongly",
    "questions_available": "%lld questions available",
    "questions_count": "%lld questions",
    "questions_due_for_review": "%lld questions due for review",
    "questions_due_today": "%lld questions due today",
    "questions_to_retry": "%lld questions to retry",
    "random_questions": "%lld random questions",
    "start_n_questions": "Start · %lld questions",
    "time_limit_minutes": "Time limit: %lld minutes",
    "days": ("%lld day", "%lld days", "%lld Tag", "%lld Tage"),
}


def android_format(text: str) -> str:
    """%lld/%@ → %d/%s, positional when there are several arguments."""
    count = len(re.findall(r"%lld|%@", text))
    n = 0

    def repl(m):
        nonlocal n
        n += 1
        kind = "d" if m.group(0) == "%lld" else "s"
        return f"%{n}${kind}" if count > 1 else f"%{kind}"

    return re.sub(r"%lld|%@", repl, text)


def xml_text(text: str) -> str:
    text = escape(android_format(text)).replace("'", "\\'").replace('"', '\\"')
    return "\\" + text if text[:1] in "@?" else text


def resolve(value):
    if isinstance(value, tuple):
        return value
    if value not in DE:
        raise SystemExit(f"Missing German translation for: {value!r}")
    return value, DE[value]


def write(lang: str):
    lines = ['<?xml version="1.0" encoding="utf-8"?>',
             "<!-- Generated by tools/l10n/build_android_strings.py — do not edit by hand. -->",
             "<resources>"]
    if lang == "en":
        for name, value in NOT_TRANSLATABLE.items():
            lines.append(f'    <string name="{name}" translatable="false">{xml_text(value)}</string>')
    for name, value in sorted(STRINGS.items()):
        en, de = resolve(value)
        lines.append(f'    <string name="{name}">{xml_text(en if lang == "en" else de)}</string>')
    for name, key in sorted(PLURAL_RES.items()):
        en1, en2, de1, de2 = key if isinstance(key, tuple) else PLURALS[key]
        one, other = (en1, en2) if lang == "en" else (de1, de2)
        lines.append(f'    <plurals name="{name}">')
        lines.append(f'        <item quantity="one">{xml_text(one)}</item>')
        lines.append(f'        <item quantity="other">{xml_text(other)}</item>')
        lines.append("    </plurals>")
    lines.append("</resources>")
    folder = RES / ("values" if lang == "en" else "values-de")
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "strings.xml").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{(folder / 'strings.xml').relative_to(ROOT)}: {len(STRINGS) + len(PLURAL_RES)} resources")


if __name__ == "__main__":
    write("en")
    write("de")

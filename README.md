# SBF Exam Prep

Study app for the German recreational boating licence — **Sportbootführerschein Binnen (motor) & See** — for
**iPhone, iPad and Android**. It contains the complete official ELWIS question catalogue (August 2023), shown in
German as in the exam with optional English translations, and an app interface in English and German.

## Features

| | |
|---|---|
| **466 official questions** | 72 basic questions (both exams) + 181 SBF Binnen + 213 SBF See |
| **Illustrations** | 140 image questions with figures redrawn for the app (lights, shapes, buoys, signs, flags, weather maps); pinch to zoom |
| **Sound signals** | 20 questions play the signal (short ≈ 1 s, prolonged ≈ 4 s) with a synthesised horn |
| **Explanations** | Every question has a short explanation in German and English |
| **Exam simulation** | Official composition (7 basic + 23 specific), pass marks (5/7 and 18/23) and time (45 / 60 min), no feedback until the end |
| **Spaced repetition** | Leitner boxes with reviews after 1, 3, 7, 14 and 30 days; a wrong answer starts again |
| **Practice** | By exam and topic, mistakes, saved questions; browse and search the catalogue |
| **Answer order** | The catalogue always lists the correct answer first; the apps shuffle it (stable per question while browsing) |
| **Motivation** | Daily streak, optional daily reminder (local notification) |
| **Platforms** | iPhone, iPad (sidebar, split view, keyboard shortcuts), widget, iCloud sync · Android phones, foldables and tablets (navigation rail, list-detail), Android backup |
| **Languages** | Interface in English and German; dark mode; VoiceOver / TalkBack labels |
| **Privacy** | No account, no ads, no analytics, offline. Privacy manifest included (iOS); no INTERNET permission (Android) |

## Repository layout

```
SBFTrainer/            iOS / iPadOS app (SwiftUI, iOS 17+)
  Models/              Question data, exam rules, progress & spaced repetition, iCloud sync, sound player
  ViewModels/          QuizViewModel (practice, review, mistakes, saved, exam modes)
  Views/               Screens (adaptive iPhone / iPad layouts)
  Shared/              Code shared with the widget (WidgetSnapshot)
  Localizable.xcstrings  English → German string catalog (generated)
SBFWidget/             Home-screen widget (streak, due reviews)
SBFTrainerTests/       Data integrity and logic tests
android/               Android app (Kotlin, Jetpack Compose, Material 3, minSdk 26)
shared/                Question catalogue + illustrations used by both apps
  sbf_exam_questions.json
  assets/{shared,binnen,see}/<id>.png
tools/
  images/              Python SVG drawings of every illustration (build.py renders shared/assets)
  data/                update_questions.py + explanations/*.json (data maintenance)
  l10n/                build_catalogs.py (iOS) and build_android_strings.py (Android)
sbf-hosting/           Firebase Hosting site: privacy policy, support pages (EN/DE)
store/                 App Store and Google Play texts, graphics and screenshots
generate_project.rb    Generates SBFTrainer.xcodeproj
```

## iOS

Requirements: Xcode 26 (iOS 17+ deployment target), Ruby with the `xcodeproj` gem.

```bash
ruby generate_project.rb
open SBFTrainer.xcodeproj
```

Scheme **SBFExamPrep** builds the app and the widget. Run the tests:

```bash
xcodebuild test -project SBFTrainer.xcodeproj -scheme SBFExamPrep -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Before the first release enable **App Groups** (`group.ai.biniam.SBFExamPrep`) for the app and the widget and
**iCloud → Key-value storage** for the app in *Signing & Capabilities* / the developer portal.

Debug builds accept launch arguments for screenshots, e.g.
`-demoProgress YES -screenshotTab browse -screenshotQuestion see_093` or `-screenshotQuiz exam-binnen`.

## Android

Requirements: JDK 17 and the Android SDK (platform 36). The questions and images come straight from `shared/`.

```bash
cd android
./gradlew testDebugUnitTest      # unit tests (data integrity, rules, spaced repetition, timing)
./gradlew installDebug           # install on a running emulator / device
./gradlew bundleRelease          # Play Store bundle (needs android/keystore.properties)
```

`keystore.properties` (not in git) holds `storeFile`, `storePassword`, `keyAlias` and `keyPassword` of the upload key.
Debug builds accept intent extras for screenshots, e.g.
`adb shell am start -n ai.biniam.sbfexamprep/.MainActivity --ez demoProgress true --es screenshotTab home`.

## Data and illustrations

All changes to the catalogue go through the scripts, so they can be re-run safely:

```bash
python3 tools/data/update_questions.py     # categories (DE), sound patterns, text fixes, image refs, explanations
python3 tools/images/build.py              # redraw all illustrations into shared/assets (needs resvg)
python3 tools/images/build.py see_09       # only ids with this prefix
python3 tools/l10n/build_android_strings.py
python3 tools/l10n/build_catalogs.py --derived-data <DerivedData dir>   # after changing iOS UI text
```

Explanations live in `tools/data/explanations/*.json` as `{"<id>": {"de": "…", "en": "…"}}`.
The question data originally came from the ELWIS PDFs (see the sibling `sbf-exam-questions` project).

## Website

`sbf-hosting/site` is deployed with Firebase Hosting (`cd sbf-hosting && firebase deploy --only hosting`):
`/privacy`, `/datenschutz`, `/support`, `/hilfe`. `sbf-hosting/templates/impressum.html` is an Impressum template
that is not deployed until it has been filled in.

## Store

See [store/README.md](store/README.md) for listing texts, privacy answers and release steps.

## Sources

Questions: [ELWIS](https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Sportbootfuehrerscheine-node.html),
Generaldirektion Wasserstraßen und Schifffahrt, catalogue of August 2023. English translations and explanations are
unofficial study aids; only the German text is valid in the exam. This project is not affiliated with the GDWS,
ELWIS, the DMYV or the DSV.

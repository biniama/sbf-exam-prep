# SBF Trainer

A bilingual German/English iOS app for studying the **Sportbootführerschein (SBF)** — the German recreational boating licence exam. Covers both the **Binnen Motor** (inland waterways) and **SBF See** (coastal/sea) syllabi based on the official ELWIS August 2023 question catalog.

---

## Screenshots

| Home | Quiz | Results |
|------|------|---------|
| Accuracy ring, stats, quick-start actions | Question card with image support, colour-coded answer reveal | Animated score ring, wrong-answer review list |

---

## Features

| Feature | Detail |
|---|---|
| **466 exam questions** | 72 shared Basisfragen + 181 Binnen Motor + 213 SBF See |
| **Bilingual** | Every question and all four answer options in German and English |
| **Image questions** | 103 questions display their official ELWIS diagram images |
| **Quiz engine** | Randomised answer order, instant colour-coded feedback, progress bar |
| **Wrong-answer tracking** | Automatically saves every missed question; miss count increments per attempt |
| **Bookmarks** | Save any question during browsing or a quiz |
| **Review mode** | Sorted by miss count; swipe to mark mastered or clear |
| **Browse & search** | Filter by exam type (All / Shared / Binnen / See), category, Mistakes only, Saved only, or free-text search |
| **Quiz setup** | Choose exam type, category, question count (10 / 20 / 30 / 50), or practice from wrong answers only |
| **English toggle** | Show/hide English translations for question text and all options at any time |
| **Statistics** | Total answered, overall accuracy, current streak, quiz history |
| **Persistence** | Bookmarks, wrong answers, quiz history and settings stored in UserDefaults |
| **Reset** | One-tap reset of all progress (with confirmation alert) |

---

## App Structure

```
SBFTrainer/
├── SBFTrainerApp.swift          # App entry point; injects environment objects
├── Models/
│   ├── Question.swift           # Data models: ExamData, ExamSection, Question,
│   │                            #   QuestionOption, ExamType; Bundle image URL helper
│   ├── QuestionStore.swift      # Singleton; loads JSON, filters by type/category
│   └── UserProgress.swift       # Singleton; UserDefaults persistence for bookmarks,
│                                #   wrong answers, quiz history, settings
├── ViewModels/
│   └── QuizViewModel.swift      # Quiz state machine (answering → revealed → finished);
│                                #   answer recording, option colour/icon helpers
├── Views/
│   ├── Theme.swift              # Colour palette, cardStyle/goldBadge modifiers,
│   │                            #   ExamTypeBadge, CategoryBadge, StatCard,
│   │                            #   QuestionImageView (loads PNG from bundle)
│   ├── MainTabView.swift        # 5-tab root: Home, Browse, Quiz, Saved, Review
│   ├── HomeView.swift           # Dashboard: accuracy ring, stats, quick-start actions,
│   │                            #   recent quiz history
│   ├── LearnView.swift          # Browse screen with exam-type picker, category scroll,
│   │                            #   filter chips, searchable question list
│   ├── QuestionDetailView.swift # Full question detail: text, image, options with
│   │                            #   reveal-answer button, bookmark toolbar button
│   ├── QuizSetupView.swift      # Quiz configuration: mode, type, category, count
│   ├── QuizView.swift           # Active quiz: progress bar, question card, OptionButton
│   │                            #   with press animation and colour-coded reveal
│   ├── QuizResultView.swift     # Results: animated accuracy ring, grade, stats,
│   │                            #   wrong-answer list, retry/practice-mistakes actions
│   ├── BookmarksView.swift      # Saved questions with type filter and quiz-from-saved
│   ├── ReviewView.swift         # Wrong-answer list; swipe to master or clear
│   └── SettingsView.swift       # English toggle, quiz length, statistics, reset
├── Resources/
│   ├── sbf_exam_questions.json  # Complete bilingual question dataset (466 questions)
│   └── assets/
│       ├── shared/              # 17 images for Basisfragen (Q6, Q16–Q30, Q33)
│       ├── binnen/              # 113 images for Binnen questions
│       └── see/                 # 152 images for See questions
└── Assets.xcassets/             # App icon, accent colour
```

### Architecture

- **SwiftUI + MVVM** — Views observe `@EnvironmentObject` singletons (`QuestionStore`, `UserProgress`) and a per-screen `@StateObject` (`QuizViewModel`)
- **No third-party dependencies** — pure SwiftUI, Foundation, UIKit
- **Persistence** — `Codable` structs serialised to `UserDefaults`; no Core Data or SwiftData
- **Images** — loaded at runtime from the app bundle with `Bundle.main.url(forResource:withExtension:subdirectory:)` → `UIImage(contentsOfFile:)`

### Colour palette (`Theme.swift`)

| Name | Hex | Use |
|---|---|---|
| `navy` | `#0A2342` | Primary text, buttons, header gradient |
| `navyMid` | `#1A3B5E` | Secondary text, toolbar icons |
| `navyLight` | `#295989` | Borders, subtle backgrounds |
| `gold` | `#C9A84C` | Bookmarks, accuracy ring, streak |
| `oceanTeal` | `#1A9AA8` | Binnen badge |
| `successGreen` | `#2E7D32` | Correct answer highlight |
| `errorRed` | `#C42929` | Wrong answer highlight, review badge |

---

## Dataset

The question dataset lives in the sibling directory `sbf-exam-questions/` and is built from the official ELWIS PDF catalogs.

### Source files

| File | Purpose |
|---|---|
| `fragenkatalog-binnen.pdf` | Official Binnen Motor + Basisfragen PDF (ELWIS, Aug 2023) |
| `fragenkatalog-see.pdf` | Official SBF See PDF (ELWIS, Aug 2023) |
| `fragenkatalog-binnen.txt` | Plain-text extraction of the Binnen PDF |
| `fragenkatalog-see.txt` | Plain-text extraction of the See PDF |

### Build pipeline

```
1. parse_catalog.py      Extract questions → raw JSON (German text, options, has_image flag)
2. translations_*.json   Hand-written English translations for all 466 questions and options
3. merge_translations.py Merge English translations into the raw JSON
4. map_images.py         Extract PNG images from PDFs with pdfimages; rename to question IDs
5. fix_image_refs.py     Correct page-level image→question mapping; fix false-positive has_image flags
6. sbf_exam_questions.json  Final output — 466 questions, fully bilingual, 103 with image paths
```

### Dataset statistics

| Section | Questions | Image questions |
|---|---|---|
| Shared (Basisfragen) | 72 | 17 |
| Binnen Motor specific | 181 | 50 |
| SBF See specific | 213 | 36 |
| **Total** | **466** | **103** |

### Question JSON schema

```json
{
  "unique_id": "shared_016",
  "question_number": 16,
  "category": "Sound and Light Signals",
  "german_text": "Welche Bedeutung hat folgendes Schallsignal?",
  "english_text": "What is the meaning of the following sound signal?",
  "options": {
    "A": { "german": "Bleib-weg-Signal …", "english": "Keep-away signal …" },
    "B": { "german": "Allgemeines Gefahr…", "english": "General danger …" },
    "C": { "german": "Ankerlieger …",       "english": "Vessel at anchor …" },
    "D": { "german": "Manövrierbehinderter…","english": "Restricted manoeuvrability …" }
  },
  "correct_option": "A",
  "has_image": true,
  "image_reference": "assets/shared/shared_016.png"
}
```

> **Note:** In the official ELWIS catalog, answer **A is always the correct option**. The app randomises the display order on every quiz.

---

## Building the App

### Requirements

- macOS 14+ with Xcode 15+
- iOS 17+ deployment target
- Ruby + `xcodeproj` gem (`gem install xcodeproj --user-install`)

### Regenerate the Xcode project

```bash
cd SBFTrainer
ruby generate_project.rb
open SBFTrainer.xcodeproj
```

### Run on iOS Simulator

```bash
xcodebuild \
  -project SBFTrainer.xcodeproj \
  -scheme SBFTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  build
```

### Run on a real iPhone

1. Open `SBFTrainer.xcodeproj` in Xcode
2. Select the **SBFTrainer** target → **Signing & Capabilities**
3. Enable **Automatically manage signing** and select your Apple ID team
4. Connect your iPhone, select it as the run destination, press **⌘R**
5. First launch: on iPhone go to **Settings → General → VPN & Device Management → [your Apple ID] → Trust**

> A free Apple ID works but the provisioning profile expires after 7 days. A paid Apple Developer account ($99/year) removes this limit.

---

## Rebuild the Dataset

If you want to regenerate the JSON from scratch (requires the original PDFs):

```bash
cd sbf-exam-questions

# 1. Parse German text from PDFs
python3 parse_catalog.py

# 2. Merge English translations
python3 merge_translations.py

# 3. Extract and map images from PDFs (requires poppler: brew install poppler)
python3 map_images.py
python3 fix_image_refs.py

# Copy updated JSON and images to the iOS app
cp sbf_exam_questions.json ../SBFTrainer/SBFTrainer/Resources/
cp -r assets/shared/*.png ../SBFTrainer/SBFTrainer/Resources/assets/shared/
cp -r assets/binnen/binnen_*.png ../SBFTrainer/SBFTrainer/Resources/assets/binnen/
cp -r assets/see/see_*.png ../SBFTrainer/SBFTrainer/Resources/assets/see/
```

---

## Key Implementation Notes

- **Answer A is always correct** in the source catalog. `QuizViewModel.setup()` calls `.shuffled()` on the question pool and the options are sorted by key (A/B/C/D) which already randomises which position shows what content — the `correct_option` field always tracks the true answer regardless of display order.
- **Binnen includes Shared**: `QuestionStore.questions(for: .binnen)` returns all 181 binnen-specific questions **plus** all 72 shared Basisfragen (253 total), matching the actual exam structure.
- **Image loading**: `Question.imageURL` resolves the relative `image_reference` path against the app bundle using `Bundle.main.url(forResource:withExtension:subdirectory:)`. If the file isn't found (e.g. question had no extractable diagram), `QuestionImageView` falls back to a placeholder icon.
- **Wrong-answer decay**: `UserProgress.recordAnswer(correct: true)` decrements the wrong count by 1 rather than clearing it immediately, so a question must be answered correctly multiple times to fall off the review list if it was missed many times.

---

## Data Sources

- Questions: [ELWIS — Elektronischer Wasserstraßen-Informationsservice](https://www.elwis.de) (Federal Waterways and Shipping Administration, Germany)
- Official catalog date: August 2023
- Catalog language: German (English translations added for this project)

# Store listings

Texts for App Store Connect and Google Play Console, in English (`en-US`) and German (`de-DE`).
Each file holds exactly one field; the store limits are noted below. The texts were checked against the
limits when they were written.

| App Store field | File | Limit |
| --- | --- | --- |
| Name | `app-store/<lang>/name.txt` | 30 |
| Subtitle | `app-store/<lang>/subtitle.txt` | 30 |
| Keywords | `app-store/<lang>/keywords.txt` | 100 |
| Promotional text | `app-store/<lang>/promotional_text.txt` | 170 |
| Description | `app-store/<lang>/description.txt` | 4000 |
| What's New | `app-store/<lang>/release_notes.txt` | 4000 |

| Google Play field | File | Limit |
| --- | --- | --- |
| App name | `google-play/<lang>/title.txt` | 30 |
| Short description | `google-play/<lang>/short_description.txt` | 80 |
| Full description | `google-play/<lang>/full_description.txt` | 4000 |
| Release notes | `google-play/<lang>/release_notes.txt` | 500 |

Graphics: `google-play-icon-512.png` (hi-res icon) and `google-play-feature-graphic.png` (1024 × 500).
Screenshots (`screenshots/`, English and German): iPhone 6.9" 1320 × 2868 and iPad 13" 2064 × 2752 for
App Store Connect; Android phone 1080 × 2400 and tablet 2560 × 1600 for Google Play. They were taken from debug
builds with demo progress (see the launch options in the main README).

## URLs

| | English | German |
| --- | --- | --- |
| Privacy policy | https://sbf-exam-prep.web.app/privacy | https://sbf-exam-prep.web.app/datenschutz |
| Support | https://sbf-exam-prep.web.app/support | https://sbf-exam-prep.web.app/hilfe |
| Marketing | https://sbf-exam-prep.web.app | |

Deploy the website first: `cd sbf-hosting && firebase deploy --only hosting`.

## App Store Connect

- **Category:** Education (secondary: Reference). **Age rating:** 4+ (no objectionable content).
- **App Privacy:** *Data Not Collected*. The app has no analytics, ads or tracking; progress stays on the
  device and optionally in the user's own iCloud key-value storage, which Apple does not count as collection
  by the developer.
- **Export compliance:** `ITSAppUsesNonExemptEncryption = NO` is set in Info.plist.
- **Review notes:** "No login required. Exam simulation: Home → Exam simulation · Inland/Sea. Sound signals:
  Browse → question 4 (Basic). iCloud sync and the daily reminder are optional (Settings)."
- **Capabilities to enable in the developer portal** for `ai.biniam.SBFExamPrep` and the widget
  `ai.biniam.SBFExamPrep.widget`: App Groups (`group.ai.biniam.SBFExamPrep`) and iCloud (key-value storage).

## Google Play Console

- **Package:** `ai.biniam.sbfexamprep`. **Category:** Education. **Content rating:** Everyone (IARC questionnaire:
  no violence, no user interaction, no data sharing).
- **Data safety:** *No data collected, no data shared.* The app has no INTERNET permission. Progress is
  included in Android Auto Backup, which Google performs for the user and is not developer data collection.
- **Target audience:** 16+ (the licence minimum age), not designed for children.
- **Permissions:** `POST_NOTIFICATIONS` (optional daily reminder), `RECEIVE_BOOT_COMPLETED` (restore the reminder after a restart).
- **Release build:** create an upload key, add `android/keystore.properties` (see `android/app/build.gradle.kts`),
  then `cd android && ./gradlew bundleRelease` → `app/build/outputs/bundle/release/app-release.aab`.

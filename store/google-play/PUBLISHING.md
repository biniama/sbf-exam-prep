# Publishing on Google Play — step by step

Everything below is prepared; each step lists the exact value to enter. Paths are relative to the repository root.

## 0. Before you start

1. **Put the privacy policy online** (Google checks the URL):

   ```bash
   cd sbf-hosting && firebase deploy --only hosting
   ```

   Check that https://sbf-exam-prep.web.app/datenschutz and https://sbf-exam-prep.web.app/privacy open.
2. **Release bundle:** `android/app/build/outputs/bundle/release/app-release.aab` (version 1.0, code 1), signed with
   the upload key `android/upload.jks` (password in `android/keystore.properties`; keep both backed up).
   Rebuild with `cd android && ./gradlew bundleRelease`.

## 1. Create the app

Play Console → **EOTC Tewahedo Apps** → **Create app**

| Field | Value |
| --- | --- |
| App name | `SBF Exam Prep: Binnen & See` |
| Default language | German – de-DE |
| App or game | App |
| Free or paid | Free |
| Declarations | Read and accept the Developer Program Policies and US export laws (your decision) |

## 2. App content (Dashboard → "Set up your app")

| Section | Answer |
| --- | --- |
| Privacy policy | `https://sbf-exam-prep.web.app/datenschutz` |
| App access | All functionality is available without special access |
| Ads | No, my app does not contain ads |
| Content rating | Category: *Reference, news, or educational*. Answer **No** to violence, sexual content, profanity, gambling, user interaction/communication, sharing location, digital purchases. If asked about alcohol: it is only mentioned as legal blood-alcohol limits in exam questions (no depiction or promotion). Expected rating: Everyone / USK 0 / PEGI 3 |
| Target audience | 16–17 and 18 and over (the licence minimum age is 16); not appealing to children |
| News app | No |
| Data safety | "Does your app collect or share any of the required user data types?" → **No**. (Progress stays on the device; Android Auto Backup is done by Google for the user, not collected by the developer.) |
| Government app | No |
| Financial features | My app doesn't provide any financial features |
| Health apps | No health features |

## 3. Store settings

| Field | Value |
| --- | --- |
| App category | Education |
| Tags | Education, Exam prep (pick the closest offered) |
| Email | `biniamasnake+sbf@gmail.com` |
| Website | `https://sbf-exam-prep.web.app` |

## 4. Main store listing

German (default) — texts from `store/google-play/de-DE/`; add **English (United States)** under *Manage translations* with
`store/google-play/en-US/`.

| Field | File |
| --- | --- |
| App name | `title.txt` |
| Short description | `short_description.txt` |
| Full description | `full_description.txt` |
| App icon (512 × 512) | `store/google-play-icon-512.png` |
| Feature graphic (1024 × 500) | `store/google-play-feature-graphic.png` |
| Phone screenshots | `store/screenshots/android/phone/<lang>/1-home.png … 4-quiz.png` (1080 × 1920) |
| 7-inch and 10-inch tablet screenshots | `store/screenshots/android/tablet/<lang>/*.png` (2560 × 1440) |

## 5. Release

Production → **Countries/regions** → *Add countries/regions* → select all → Save.

Production → **Create new release**

1. App integrity: use **Google-generated app signing key** (Play App Signing, default).
2. Upload `app-release.aab`.
3. Release name: `1.0 (1)`.
4. Release notes: `store/google-play/de-DE/release_notes.txt` for `<de-DE>` and `store/google-play/en-US/release_notes.txt` for `<en-US>`.
5. **Next → Save → Publishing overview → Send for review.** The review usually takes a few days.

> **Personal developer accounts created after 13 November 2023** cannot publish to Production straight away: Google
> requires a closed test with at least 12 testers who stay opted in for 14 days. If Play Console shows this
> requirement, create the release under **Testing → Closed testing** instead (same steps), invite 12+ testers by email,
> and apply for production access from the dashboard after 14 days.

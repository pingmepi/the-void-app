# Google Play Store — Upload Guide

**App:** The Void
**Package:** `com.thevoid.the_void_app`
**Version under test:** `1.0.0+1` (set in [pubspec.yaml](../pubspec.yaml))
**Min Android:** API 23 (revisit per `FIX_PLAN.md` P1-2)
**Prereqs:** `FIX_PLAN.md` P0 items completed, `VERIFICATION_PLAN.md` §1–§9 fully checked.

> Apple App Store steps are in [app-store-submission.md](app-store-submission.md) Part 2. This file is the **revised** Play-only path that supersedes Part 1 of that doc.

---

## Phase 0 — One-time confirmations (before doing anything below)

- [ ] You have completed `FIX_PLAN.md` P0-1 through P0-7. Do not skip P0-1; without it, your Data Safety section in §5.7 is false.
- [ ] You have a real Android device for internal testing.
- [ ] You have a Google account you're willing to permanently associate with this app's Play listing.
- [ ] You have $25 USD for the Play Console one-time fee.

---

## Phase 1 — Generate the upload keystore (one-time, irrevocable)

> Losing this keystore = losing the ability to publish updates to this listing forever. Back it up to **two** places (password manager + encrypted external drive or iCloud).

### 1.1 — Generate

From repo root:

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Prompts: keystore password, key password (use the same), name/org/city/country (real info — goes into the cert).

✓ **Verify:** `ls -la android/upload-keystore.jks` shows file > 2 KB.

### 1.2 — Create `key.properties`

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../upload-keystore.jks
```

✓ **Verify:** [android/.gitignore](../android/.gitignore) lists `key.properties` and `upload-keystore.jks`. Run `git status` — neither file should appear as untracked.

### 1.3 — Confirm Gradle reads it

[android/app/build.gradle.kts](../android/app/build.gradle.kts) already wires this up. After applying `FIX_PLAN.md` P0-4, an absent `key.properties` will fail the build at config time. Test:

```bash
mv android/key.properties /tmp/kp.bak
flutter build appbundle --dart-define-from-file=.env.json    # should fail with the GradleException
mv /tmp/kp.bak android/key.properties
flutter build appbundle --dart-define-from-file=.env.json    # should succeed
```

### 1.4 — Back up

- [ ] Keystore copied to password manager
- [ ] Keystore copied to a second location (encrypted external drive / cloud)
- [ ] `key.properties` saved separately from the keystore (in case one location is compromised)

---

## Phase 2 — Google OAuth for the signed build

OAuth on Android binds to the **signing certificate's SHA-1 fingerprint**. Without registering it, Google Sign-In returns a generic "10:" error and silently fails on device.

### 2.1 — Get the SHA-1

```bash
keytool -list -v \
  -keystore android/upload-keystore.jks \
  -alias upload | grep SHA1
```

Copy the colon-separated hex string.

### 2.2 — Also get the Play App Signing SHA-1

Once you upload your first AAB, Google re-signs it with their own key. **OAuth must be registered for that SHA-1 too**, or release builds (downloaded from Play) will fail OAuth.

You'll get this SHA-1 from Play Console after the Internal Testing upload (§3.3) — Setup → App signing → "App signing key certificate" → SHA-1. Add it to OAuth credentials at that point.

### 2.3 — Register in Google Cloud Console

1. [console.cloud.google.com](https://console.cloud.google.com) → the project linked to your Supabase OAuth credentials.
2. APIs & Services → Credentials → + Create Credentials → OAuth client ID → **Android**.
3. Package name: `com.thevoid.the_void_app`. SHA-1: from §2.1. Save.
4. After §3.3, add a **second** Android OAuth client (or add the SHA-1 to the existing one) for the Play App Signing SHA-1.

### 2.4 — Confirm Supabase redirect URL

Supabase Dashboard → Authentication → URL Configuration → Redirect URLs must include:

```
com.thevoidapp://login-callback
```

(Already wired in [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) as the only deep-link intent filter.)

---

## Phase 3 — Build, then dogfood via Internal Testing

### 3.1 — Build the AAB

```bash
flutter build appbundle \
  --dart-define-from-file=.env.json \
  --build-name=1.0.0 \
  --build-number=1
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

✓ **Verify:**
- File exists, between 10 and 50 MB.
- `flutter build appbundle --analyze-size` shows no surprise bloat.
- The AAB is signed with your upload key (not the debug key) — `bundletool` or `jarsigner -verify` confirms.

### 3.2 — Create the Play Console app

1. [play.google.com/console](https://play.google.com/console) → pay $25 if first-time → identity verification (up to 48h).
2. **Create app**: name = `The Void`, default language = English (United States), App, Free.
3. Accept declarations → Create.

### 3.3 — Upload to **Internal Testing first** (do not skip)

1. Release → Testing → **Internal testing** → Create new release.
2. Upload `app-release.aab`.
3. Release notes: `Initial internal test build for v1.0.0`.
4. Save → Review release → Start rollout to internal testing.
5. Add testers list with your own email + 1–2 friendly testers.
6. Use the opt-in URL on a real Android device, install the build.

✓ **Verify on device:**
- App installs and launches.
- Mic permission prompt appears once.
- Record → see transcript → countdown runs → tap rescue → auth sheet appears.
- Sign in with email and Google both succeed.
- Saved gem appears in list, persists across restart.
- Delete account flow wipes everything (test on a throwaway account).
- Run `VERIFICATION_PLAN.md` §2–§7 against this build.

### 3.4 — Register the Play App Signing SHA-1

Now go back to **Phase 2.2** and register the Play-managed SHA-1 for OAuth, otherwise downloaded builds will fail Google Sign-In even though your sideloaded internal-test build works.

---

## Phase 4 — Store-listing content

Required before promoting to Production. Fill all of the below on Play Console → **Store presence → Main store listing**.

### 4.1 — Required fields

| Field | Value | Source |
|---|---|---|
| App name | `The Void` | — |
| Short description (≤ 80 chars) | `Speak. Rescue what matters. Let the rest go.` | — |
| Full description | 3–5 paragraphs explaining the ephemeral voice-note model, on-device transcription, encrypted gems | draft fresh; do not reuse marketing copy that contradicts privacy policy |
| App icon | 512×512 PNG, no alpha on outermost layer | export from `assets/icon/app_icon.png` |
| Feature graphic | 1024×500 PNG | required — without it Play won't let you submit |
| Phone screenshots | ≥ 2 (recommended 4–8) | record from §3.3 device |
| App category | Productivity → Notes | — |
| Tags | voice notes, transcription, ephemeral | — |

### 4.2 — Contact details

| Field | Value |
|---|---|
| Email | the support email used in `docs/privacy.html` |
| Privacy policy URL | the live GitHub Pages URL of `docs/privacy.html` (P0-5) |

✓ **Verify:** Main store listing has zero red "Required" banners.

---

## Phase 5 — Policy & compliance forms

These are accessed via Play Console → **Policy → App content**.

### 5.1 — App access

If sign-in is required to view core content (gems), declare so. Provide a test login (use a dedicated review account, not yours).

### 5.2 — Ads

Select **No, my app does not contain ads**. (The Void has no ad SDKs — verified by §8 of `VERIFICATION_PLAN.md`.)

### 5.3 — Content rating

Start the IARC questionnaire. Category: **Utility, productivity, communication or other**. Answer every question accurately:

- Violence: No
- Sexual content: No
- Profanity: No (user-generated transcripts could contain it but are not shared publicly)
- Controlled substances: No
- User-generated content visible to others: **No** (gems are private to the user)
- Gambling: No
- Crude humour: No

Expected rating: Everyone / PEGI 3.

### 5.4 — Target audience

Target audience: **18 and older** (simplest path; if you target wider, you must comply with COPPA/Designed-for-Families policy).

### 5.5 — Data Safety (the form most likely to bite you)

> **Critical:** answers must match the code AFTER `FIX_PLAN.md` P0-1 ships. If P0-1 is not yet shipped, audio IS transmitted to Google during recording — answer accordingly and update later. Do not lie here.

| Question | Answer |
|---|---|
| Does your app collect or share required user data types? | Yes |
| Is data encrypted in transit? | Yes (HTTPS / TLS) |
| Do you provide a way for users to request deletion? | Yes (in-app delete account) |
| **Personal info → Email** | Collected. Purpose: Account management. Optional: No. Shared: No. |
| **Personal info → User IDs** | Collected. Purpose: Account management. Shared: No. |
| **Audio files → Voice or sound recordings** | Collected ONLY when user taps Rescue. Purpose: App functionality. Shared: No. Optional: Yes. |
| **App activity → Other user-generated content** (transcripts) | Collected on rescue. Purpose: App functionality. Shared: No. |
| Microphone access during use | Yes — used for transcription only; processed by OS speech recognizer on-device (after P0-1). |

### 5.6 — News, government, COVID, financial — all No.

### 5.7 — Final compliance summary

✓ **Verify:** every section in **App content** has a green check. Any orange triangle blocks submission.

---

## Phase 6 — Production rollout

### 6.1 — Create the production release

1. Release → **Production** → Create new release.
2. Use the same AAB from §3.1 (or upload a fresh build).
3. Release name: `1.0.0 (1)`.
4. Release notes (English): one short paragraph — what the app is, what's new in 1.0.

### 6.2 — Staged rollout

Start at **20%**. This catches startup crashes on a subset before they affect everyone. Bump to 50% after ~24h with no crash spikes (Play Console → Quality → Android vitals), then 100% after ~48h.

### 6.3 — Submit for review

First-time review: 3–7 days typical, occasionally up to 2 weeks. Reasons reviews fail:

- Privacy policy URL inaccessible or contradicts Data Safety.
- Permissions used at runtime that aren't declared, or vice versa.
- Test login not provided when sign-in is required.
- Content rating mismatched (e.g. "Everyone" but app description hints at 18+).

You'll get email on approval or rejection. If rejected, fix the cited issue and resubmit — the resubmission queue is faster (~1–2 days).

---

## Phase 7 — After it's live

### 7.1 — Monitor crash-free rate

Play Console → Quality → Android vitals → Crashes. Stay above 99.5% crash-free sessions.

### 7.2 — Respond to reviews

Set up email alerts for new reviews. Respond to 1- and 2-star reviews within 48h. Most reverse course when responded to.

### 7.3 — Update flow

Every update:

1. Bump `pubspec.yaml:19` (e.g. `1.0.1+2`).
2. Update `CHANGELOG.md`.
3. `flutter build appbundle --dart-define-from-file=.env.json`.
4. Play Console → Production → Create new release → upload AAB → release notes → 20% rollout → 100% after 24–48h clean.
5. **Never** re-use a `versionCode` (the `+N` part). Each upload must increment.

---

## Quick checklist (single-page sign-off)

- [ ] FIX_PLAN.md P0-1 through P0-7 done
- [ ] VERIFICATION_PLAN.md §1–§9 all checked
- [ ] Keystore generated and backed up to two places
- [ ] `key.properties` filled, gitignored, build fails without it (P0-4)
- [ ] Upload-key SHA-1 + Play App Signing SHA-1 both registered in Google Cloud Console
- [ ] Supabase redirect URL `com.thevoidapp://login-callback` configured
- [ ] Privacy policy live at a public URL with real email + effective date
- [ ] In-app privacy policy link reachable pre-auth
- [ ] Delete-account flow tested on a throwaway account end-to-end
- [ ] AAB built, sized 10–50 MB, signed with upload key
- [ ] Internal Testing track installed and validated on a real device
- [ ] Store listing complete (icon 512², feature graphic 1024×500, ≥2 screenshots, descriptions)
- [ ] App content forms complete (Ads, Content Rating, Target Audience, Data Safety)
- [ ] Production release created at 20% staged rollout
- [ ] Submitted for review

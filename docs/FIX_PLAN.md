# Fix Plan — Pre-Publish Code & Config Changes

**Target:** Google Play Store v1.0.0 (build 1)
**Scope:** Code + config only. Procedural steps (keystore, store listing, Console setup) are in `PLAY_STORE_UPLOAD.md`.
**Verification steps for each fix:** see `VERIFICATION_PLAN.md`.

Severity legend: **P0** = blocks submission · **P1** = ship-stopper for v1.0 polish · **P2** = nice-to-have.

---

## P0 — Must fix before any release build

### P0-1 · Force on-device speech recognition
**File:** [lib/services/speech_service.dart:81-90](../lib/services/speech_service.dart#L81-L90)
**Why this is P0:** `docs/privacy.html` and `docs/app-store-submission.md` Part 4 both state speech is processed on-device. Current code uses `SpeechListenOptions` without `onDevice: true`, so the OS may route audio to Google Cloud Speech. **Shipping as-is = false privacy claim = Play policy violation + Data Safety form falsified.** (See timeline obs `1139`, `1168`.)

**Change:** add `onDevice: true` to the `SpeechListenOptions` constructor call.

```dart
listenOptions: stt.SpeechListenOptions(
  partialResults: true,
  cancelOnError: true,
  listenMode: stt.ListenMode.dictation,
  onDevice: true, // ← add this
),
```

**Also:** during `initialize()`, check `_speechToText.hasPermission` and the available locales — if the OS does not have an on-device Speech Recognition model installed, surface a setup CTA rather than silently falling back. See decision `1161`: deep-link to Google App voice settings, auto-unblock on return.

### P0-2 · Mid-recording on-device fallback handling
**File:** [lib/services/speech_service.dart](../lib/services/speech_service.dart) (new helper)
**Why:** With `onDevice: true`, devices without a downloaded recognizer model will fail `initialize()` or return zero transcripts. Without UX, the user will think the app is broken.
**Change:** add a state path `LISTENING → ERROR_NO_OFFLINE_MODEL` with copy that fits The Void's voice (no "voice typing" — this app is not a keyboard). Suggested wording: "Your voice stays on your phone. To keep it that way, install the on-device speech model: Settings → Google → Voice → Offline speech recognition → add your language. Come back when it's done." Provide a button that launches the Google App voice-input settings via `url_launcher` intent `package:com.google.android.googlequicksearchbox`. On app resume, auto-retry initialization.

### P0-3 · Cancel countdown timer on app background
**File:** [lib/controllers/void_controller.dart](../lib/controllers/void_controller.dart) (countdown timer)
**Why:** Timer keeps ticking while app is backgrounded; if the user takes >countdown-seconds away, returning to the app shows VOIDED state without the user ever seeing the rescue option. `AppLifecycleController` already wipes `VoidSession` on background — the countdown timer must be cancelled too.
**Change:** in the `paused`/`hidden` lifecycle branch, call `_countdownTimer?.cancel()` and transition state to `IDLE`.

### P0-4 · Confirm release build is signed (not debug-signed)
**File:** [android/app/build.gradle.kts:54-58](../android/app/build.gradle.kts#L54-L58)
**Why:** Current logic falls back to **debug** signing config if `key.properties` is missing. A release AAB built without `key.properties` will silently sign with the debug key and Play will reject it (or worse, succeed and lock you out of future updates).
**Change:** in release buildType, throw at config time if `keyPropertiesFile` does not exist:

```kotlin
buildTypes {
    release {
        signingConfig = if (keyPropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            throw GradleException("Release build requires android/key.properties — see PLAY_STORE_UPLOAD.md Phase 1.")
        }
    }
}
```

### P0-5 · Privacy policy URL must be live before submission
**File:** `docs/privacy.html` is committed but verify GitHub Pages is serving it (commit `81bd600` enabled it). Open the published URL and confirm:
- Loads without auth
- Effective date is filled in (not `[EFFECTIVE DATE]` placeholder)
- Email address is filled in (not `[YOUR EMAIL]` placeholder)
- Statement about on-device speech matches what the code actually does after P0-1

If the page still has placeholders, edit `docs/privacy.html` and `docs/app-store-submission.md` Part 4 to fill them in.

### P0-6 · In-app privacy policy link is reachable pre-auth
**File:** auth screen
**Why:** Apple hard-requires it; Play increasingly does too.
**Change:** ensure the auth bottom sheet has a `TextButton` that opens the privacy URL via `url_launcher` (already in `pubspec.yaml:70`). If missing, add — pattern in `docs/app-store-submission.md:486-497`.

### P0-7 · Verify delete-account flow end-to-end
**File:** account-management bottom sheet on Gems screen (added in `9a6f661` + `6bf3fee`)
**Why:** must actually delete: (a) gems rows in Supabase, (b) audio in Storage, (c) the auth user, (d) sign out the local session. A partial deletion that leaves orphaned audio violates the privacy policy's "deletion is permanent and immediate" claim.
**Change:** confirm the Edge Function exists and is invoked, OR remove the deletion claim from privacy policy until it does. Test on a throwaway account.

---

## P1 — Strongly recommended before public release

### P1-1 · Enable R8 minification on release builds
**File:** [android/app/build.gradle.kts](../android/app/build.gradle.kts) release buildType + new `android/app/proguard-rules.pro`
**Why:** Smaller AAB, harder to reverse-engineer, removes unused code. Right now release builds ship un-minified.
**Change:**
```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
    signingConfig = ...
}
```
Create `android/app/proguard-rules.pro` with `-keep class io.flutter.** { *; }` and rules for any plugins that use reflection (Supabase realtime/JSON, speech_to_text). Then `flutter build appbundle` and verify nothing crashes at startup on a release-mode device.

### P1-2 · Bump `minSdk` to 24
**File:** [android/app/build.gradle.kts:46](../android/app/build.gradle.kts#L46)
**Why:** API 23 (Android 6.0) is < 1% of active devices. API 24 (Nougat) unlocks better TLS defaults and APIs the speech recognizer relies on. Keep at 23 only if you have a documented reason.
**Change:** `minSdk = 24`.

### P1-3 · Splash screen brand polish
**File:** `android/app/src/main/res/drawable/launch_background.xml` + `values/styles.xml` + `values-night/styles.xml`
**Why:** Default Flutter launch screen is plain `windowBackground`. A 200ms branded splash (logo on `#0D0B14` aquamarine glow) sets the tone. Also avoids white flash on cold start (currently flashes white before dark theme paints).
**Change:** put a layer-list drawable with the app icon centered on the dark-theme background. Pattern is well-documented; cap effort at 30 minutes.

### P1-4 · Permission-denied UX
**File:** [lib/services/speech_service.dart](../lib/services/speech_service.dart) error callback chain → UI
**Why:** If the user denies the mic permission, the app currently has no visible state — the record button just does nothing.
**Change:** when `Permission.microphone.status.isPermanentlyDenied`, show a SnackBar / inline message with an "Open settings" button (`openAppSettings()` from `permission_handler`).

### P1-5 · Surface offline / Supabase-down state for gem save
**File:** [lib/controllers/gems_controller.dart](../lib/controllers/gems_controller.dart) save path
**Why:** Save path already falls back to local-only on Supabase failure (good), but the user has no signal that sync failed. Add a small "Saved locally — will sync when online" banner on the gem card if `audioUrl == null` && user is signed in.

---

## P2 — Polish, not blocking

| ID | File | Change | Effort |
|----|------|--------|--------|
| P2-1 | `lib/main.dart` system UI | `SystemChrome.setSystemUIOverlayStyle` to match dark theme (status bar + nav bar tint) | 5 min |
| P2-2 | `analysis_options.yaml` | Add `prefer_const_constructors`, `avoid_print` as errors before release | 5 min |
| P2-3 | `pubspec.yaml` | Run `flutter pub outdated` and bump non-major-version libs | 10 min |
| P2-4 | accessibility | Add `Semantics` labels to record button + rescue button + gem cards (read by TalkBack) | 30 min |
| P2-5 | `docs/KNOWN-ISSUES.md` | Stale: claims "no audio playback", "default Flutter icon", "no delete account" — all shipped. Update or delete the file. | 5 min |

---

## Order of execution

1. **P0-1** + **P0-2** (speech on-device + fallback) — touches the same file, do together.
2. **P0-3** (countdown lifecycle).
3. **P0-4** (signing-config guard) — single-line gradle change.
4. **P0-5** + **P0-6** + **P0-7** (privacy URL live, link reachable, delete flow verified) — these are verification, not code work, except where placeholders remain.
5. **P1-1** through **P1-5** as time allows.
6. **P2** items only if you have spare time before the AAB build.

After step 5, run the full `VERIFICATION_PLAN.md` once on a real device, then proceed to `PLAY_STORE_UPLOAD.md`.

---

## Out of scope (intentionally)

- iOS submission (covered separately in `docs/app-store-submission.md` Part 2).
- New features (audio waveform, search highlight, etc.) — defer to v1.0.1.
- Tests for the new code — add under `test/` as part of each P0 commit but they don't gate Play submission.

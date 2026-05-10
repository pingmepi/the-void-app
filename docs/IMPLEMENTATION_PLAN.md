# Implementation Plan — P0/P1 Fixes for v1.0.0

**Audience:** a Sonnet sub-agent executing this end-to-end. Read [FIX_PLAN.md](FIX_PLAN.md) first for context, then work through this file top-to-bottom.

**Out of scope (do not touch):** iOS submission, Whisper STT (v2), audio playback features, store-listing copy.

---

## Operating rules for the agent

1. **One subtask per commit.** Branch naming: `fix/v1-<subtask-id>` (e.g. `fix/v1-p0-1-on-device-stt`). Message: `fix(v1.0): <one-line summary>` followed by a body that mentions the subtask ID.
2. **Run verification after every subtask.** If verification fails, stop and surface the error — do not "fix forward" by stacking edits.
3. **Do not add features beyond what the subtask describes.** If you spot adjacent issues, log them as TODO comments referencing the issue tracker and move on.
4. **Do not modify generated files** (`*.freezed.dart`, `*.g.dart`) by hand. Re-run `dart run build_runner build --delete-conflicting-outputs` instead.
5. **Pause for user input when:** (a) a subtask is marked `🟡 ASK USER` below, (b) verification fails after one retry, (c) you'd need to make a product/UX decision not specified here.
6. **Each subtask is sized for one focused work session** (≤ ~150 LOC change). If yours grows beyond that, you've misread the spec — re-read.
7. **Commit messages must include `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`** per repo convention.

---

## Phase 0 — Setup (5 min)

### Subtask 0.1 · Working branch

**AIM:** Get a clean branch off the latest `main`-equivalent.

**WORK:**
```bash
cd "/Users/Karans/Desktop/The Void App"
git fetch origin
git checkout enhancement/ui-changes
git pull origin enhancement/ui-changes
git checkout -b fix/v1-p0-bundle
```

**VERIFICATION:**
- `git status` shows clean working tree on the new branch.
- `flutter pub get && dart run build_runner build --delete-conflicting-outputs` runs clean.
- `flutter analyze` returns 0 issues.
- `flutter test` is fully green before any edits.

If `flutter test` is not green at this baseline: stop, surface the failure list. Do **not** start P0-1.

---

## Phase 1 — P0 fixes (must ship)

### Subtask P0-1 · Force on-device speech recognition

**AIM:** Audio must never leave the device during the LISTENING state, so the privacy claim in [docs/privacy.html](privacy.html) is true.

**WORK:**
1. Open [lib/services/speech_service.dart](../lib/services/speech_service.dart). Find the `_speechToText.listen(...)` call (around line 81) with its `SpeechListenOptions(...)` block (around lines 87–90).
2. Add `onDevice: true` to the `SpeechListenOptions` constructor. Final shape:
   ```dart
   listenOptions: stt.SpeechListenOptions(
     partialResults: true,
     cancelOnError: true,
     listenMode: stt.ListenMode.dictation,
     onDevice: true,
   ),
   ```
3. In `initialize()` (around lines 29–66), after `_speechToText.initialize(...)` succeeds, call `_speechToText.locales()` and store whether **any** on-device locale exists. Expose this as `bool get hasOnDeviceModel`.
4. Do not yet wire the missing-model UX — that is P0-2.

**VERIFICATION:**
- `flutter analyze` returns 0 issues.
- Unit test: add or update `test/speech_service_test.dart` to verify the listen-options object has `onDevice: true`. (If `SpeechListenOptions` is opaque, assert via a wrapper / mock.)
- Manual on real Android device: enable Airplane mode, record a short note, confirm the transcript still appears. If it stays empty, the device lacks an on-device model — that's expected pre-P0-2 and proves the flag took effect.

**COMMIT:** `fix(v1.0): force on-device speech recognition (P0-1)`

---

### Subtask P0-2 · Missing on-device model — UX path

**AIM:** When `onDevice: true` fails because no model is installed, show a clear setup CTA instead of a silent failure.

**WORK:**
1. Add a new state to `lib/models/void_state.dart`: `ERROR_NO_OFFLINE_MODEL`. Update the extension methods so this state shows: no recording, no countdown, an error overlay.
2. In [lib/controllers/void_controller.dart](../lib/controllers/void_controller.dart), in the path that handles `SpeechController.initialize()` failure, branch on whether the failure was due to a missing on-device model (use the `hasOnDeviceModel` getter from P0-1). If missing, set state to `ERROR_NO_OFFLINE_MODEL` instead of generic error.
3. Add a new widget `lib/widgets/no_offline_model_sheet.dart` shown when state is `ERROR_NO_OFFLINE_MODEL`. Content:
   - Title: "Your voice stays on your phone."
   - Body: "To keep it that way, install the on-device speech model. Settings → Google → Voice → Offline speech recognition → add your language."
   - Primary button "Open settings" → `url_launcher` to launch the Google App via `package:com.google.android.googlequicksearchbox` intent. On Android, fall back to `Settings.ACTION_VOICE_INPUT_SETTINGS` if the package isn't available.
   - Secondary button "Cancel" → returns state to IDLE.
4. In [lib/controllers/app_lifecycle_controller.dart](../lib/controllers/app_lifecycle_controller.dart) `onResume` hook: if state is `ERROR_NO_OFFLINE_MODEL`, call `SpeechController.initialize()` again so a returning user auto-recovers if they installed the model.
5. Wrap the new buttons with `e2eId('no-model-open-settings', ...)` and `e2eId('no-model-cancel', ...)` per [CLAUDE.md](../CLAUDE.md) E2E rules. Add both ids to [e2e/SELECTORS.md](../e2e/SELECTORS.md).

**VERIFICATION:**
- `flutter analyze` clean. `dart run build_runner build --delete-conflicting-outputs` clean.
- Widget test in `test/no_offline_model_sheet_test.dart`: pump the sheet, confirm the two buttons exist with the correct semantics ids and labels.
- Manual: flip the device into a state with no on-device model (use a non-English-locale Android emulator with no model downloaded) → tap record → see the sheet. Tap "Open settings" → Google App settings open.
- 🟡 **ASK USER** if you cannot reproduce the no-model state on hand — capture screenshots of an alternate test approach for review.

**COMMIT:** `fix(v1.0): add no-offline-model recovery UX (P0-2)`

---

### Subtask P0-3 · Cancel countdown timer on app background

**AIM:** Backgrounding mid-COUNTDOWN must not auto-VOID the session.

**WORK:**
1. In [lib/controllers/void_controller.dart](../lib/controllers/void_controller.dart), expose a `cancelCountdown()` method that calls `_countdownTimer?.cancel()`, sets `_countdownTimer = null`, and transitions state from COUNTDOWN → IDLE (not VOIDED).
2. In [lib/controllers/app_lifecycle_controller.dart](../lib/controllers/app_lifecycle_controller.dart), in the existing `paused`/`hidden`/`detached` branch (where `VoidSession` already gets wiped), call `voidController.cancelCountdown()` before clearing the session.
3. Add a guard in `cancelCountdown()` so it is idempotent — calling on a state that is not COUNTDOWN is a no-op.

**VERIFICATION:**
- Unit test in `test/void_controller_countdown_test.dart` (file already exists per [CLAUDE.md](../CLAUDE.md) commands): add cases — (a) start countdown, call `cancelCountdown`, assert state is IDLE and timer is null; (b) call `cancelCountdown` from IDLE, assert no exception and state stays IDLE.
- Widget/integration test for app lifecycle: mock the lifecycle observer, dispatch `paused` mid-COUNTDOWN, assert the controller's state is IDLE.
- Manual on device: start record → wait until COUNTDOWN → home button → wait the countdown duration + 5s → reopen → app shows IDLE, not VOIDED.

**COMMIT:** `fix(v1.0): cancel countdown timer on app background (P0-3)`

---

### Subtask P0-4 · Fail release build if `key.properties` missing

**AIM:** Stop a release AAB from silently being signed with the debug key.

**WORK:**
1. Open [android/app/build.gradle.kts](../android/app/build.gradle.kts). Locate the buildTypes block (around lines 51–60).
2. Replace the current "if-else" that falls back to debug signing for release with a hard fail:
   ```kotlin
   buildTypes {
       getByName("release") {
           signingConfig = if (keyPropertiesFile.exists()) {
               signingConfigs.getByName("release")
           } else {
               throw GradleException(
                   "Release build requires android/key.properties — see docs/PLAY_STORE_UPLOAD.md Phase 1."
               )
           }
       }
   }
   ```
3. Leave debug builds untouched — they should continue to use the debug signing config.

**VERIFICATION:**
- With `key.properties` present: `flutter build appbundle --dart-define-from-file=.env.json --build-name=1.0.0 --build-number=1` succeeds.
- With `key.properties` temporarily renamed: same command **fails** with the expected `GradleException`. Restore `key.properties` immediately after the test.
- Debug builds still work: `flutter run -d <android-device> --dart-define-from-file=.env.json` (no release flag) launches.
- 🟡 **ASK USER** if `android/upload-keystore.jks` and `android/key.properties` aren't on this machine. Both are gitignored — do not generate them yourself; the user must do that per [PLAY_STORE_UPLOAD.md](PLAY_STORE_UPLOAD.md) Phase 1.

**COMMIT:** `fix(v1.0): hard-fail release build without key.properties (P0-4)`

---

### Subtask P0-5 · Privacy policy URL live + placeholders filled

**AIM:** The published privacy policy must be reachable, accurate, and free of placeholder text.

**WORK:**
1. Read [docs/privacy.html](privacy.html). Search for `[YOUR EMAIL]`, `[EFFECTIVE DATE]`, and any other bracketed placeholder.
2. Read [docs/app-store-submission.md](app-store-submission.md) Part 4 (privacy policy text). Confirm the same fields are filled.
3. 🟡 **ASK USER** for the support email and effective date if either placeholder is still present. Do **not** invent an email.
4. After P0-1 ships, update the "Audio is sent to your device's built-in speech recognition service" paragraph in `privacy.html` to reflect that the audio is now constrained to on-device processing (use the `onDevice: true` capability — phrase it without overclaiming, since on-device support is OS-dependent).
5. Verify GitHub Pages is serving the file. From the repo, find the GitHub Pages config (commit `81bd600` enabled it — check `.github/`, repo settings via `gh repo view`, or the `docs/index.html` redirect). Note the public URL.

**VERIFICATION:**
- `curl -fL <published-url>/privacy.html` returns HTTP 200 and the body contains the real email + real effective date, no placeholder strings.
- The on-device claim in the policy matches the code after P0-1.
- 🟡 **ASK USER** to confirm the URL is the one they will paste into Play Console.

**COMMIT:** `fix(v1.0): finalize privacy policy text and on-device claim (P0-5)`

---

### Subtask P0-6 · In-app privacy policy link pre-auth

**AIM:** A user who has not signed in must be able to reach the privacy policy from within the app in one tap.

**WORK:**
1. Find the auth bottom sheet (likely `lib/screens/auth_screen.dart` or `lib/widgets/auth_sheet.dart`). Use grep `grep -rn "Sign in with Google\|Continue with email\|Not now" lib/`.
2. Below the lowest existing button (the dismiss / "Not now" button), add a `TextButton` with text "Privacy Policy" in `VoidColors.textFaded` (or whatever the existing faded-text color token is in [lib/main.dart](../lib/main.dart)). Tapping it opens the privacy URL via `url_launcher.launchUrl(...)`. Use `LaunchMode.externalApplication`.
3. The URL is the one finalized in P0-5 — read it from a constant in `lib/config/app_config.dart` (add `static const privacyPolicyUrl = '<url>';`). 🟡 **ASK USER** to confirm the URL string.
4. Wrap the button with `e2eId('privacy-policy-link', ...)` and add to [e2e/SELECTORS.md](../e2e/SELECTORS.md).

**VERIFICATION:**
- Widget test: pump the auth sheet without a logged-in user, find the "Privacy Policy" button via the e2e id, simulate tap, verify `launchUrl` is called with the configured URL (use a mock).
- Manual: fresh install, open app, do not sign in, open auth sheet, tap "Privacy Policy" — system browser opens to the live URL.

**COMMIT:** `fix(v1.0): add pre-auth privacy policy link (P0-6)`

---

### Subtask P0-7 · End-to-end verify delete-account flow

**AIM:** Confirm "Delete account" actually wipes (a) `gems` rows, (b) audio in Storage, (c) the auth user, (d) local secure-storage cache.

**WORK:**
1. Locate the delete-account flow added in commits `9a6f661` + `6bf3fee`. Likely in `lib/screens/account_sheet.dart` or `lib/widgets/account_management_sheet.dart`.
2. Trace the call chain: UI → controller → service. Confirm it:
   - Calls a Supabase Edge Function (not `auth.admin.deleteUser` from the client — that requires the service role key, which must never be on-device).
   - Deletes audio files from Supabase Storage by listing the user's prefix and removing each.
   - Deletes `gems` rows for the current user. (RLS may handle this implicitly if cascade is set on the auth user delete — verify.)
   - Calls `supabase.auth.signOut()`.
   - Clears `flutter_secure_storage` keys related to gems and pending rescue.
3. If any step is missing, add it. If the Edge Function does not exist, add a TODO comment + 🟡 **ASK USER** before deploying anything to Supabase — deploying server-side code is out of scope for this agent.
4. Add a unit test for the controller path that mocks the Supabase calls and asserts each of (a)–(d) is invoked in order.

**VERIFICATION:**
- 🟡 **ASK USER** to provide a throwaway Supabase test account (or confirm one already exists). Do **not** delete the user's primary account.
- Manual on-device: with throwaway account, save 1–2 gems, tap "Delete account", confirm. Then: in Supabase dashboard, confirm the `gems` rows for that user are gone, the Storage prefix is empty, the auth user no longer exists. Reopen the app: lands on signed-out home, no cached gems.
- If the Edge Function is missing and the user has not yet deployed it, mark this subtask as **partial-complete** and surface the gap.

**COMMIT:** `fix(v1.0): verify and harden delete-account flow (P0-7)`

---

### Phase 1 sign-off

Before moving to Phase 2:

- [ ] All P0 subtasks committed and pushed.
- [ ] `flutter analyze`, `flutter test`, and `cd e2e && npx playwright test` all green.
- [ ] One full pass of [VERIFICATION_PLAN.md](VERIFICATION_PLAN.md) §2, §3, §4, §7 on a real device.
- [ ] Surface a single message to the user: "P0 complete, ready for P1?" Wait for go/no-go.

---

## Phase 2 — P1 polish (strongly recommended)

Only proceed after the user gives a "go" on Phase 1.

### Subtask P1-1 · Enable R8 minification + ProGuard rules

**AIM:** Smaller, harder-to-reverse-engineer release AAB.

**WORK:**
1. In [android/app/build.gradle.kts](../android/app/build.gradle.kts) release buildType:
   ```kotlin
   isMinifyEnabled = true
   isShrinkResources = true
   proguardFiles(
       getDefaultProguardFile("proguard-android-optimize.txt"),
       "proguard-rules.pro"
   )
   ```
2. Create `android/app/proguard-rules.pro` with at minimum:
   ```
   # Flutter
   -keep class io.flutter.** { *; }
   -keep class io.flutter.plugin.** { *; }
   # speech_to_text reflection
   -keep class com.csdcorp.speech_to_text.** { *; }
   # Supabase Realtime / Gson serialization
   -keepattributes Signature
   -keepattributes *Annotation*
   -keep class kotlinx.serialization.** { *; }
   ```
3. Build a release AAB. If it crashes at startup on a device, capture the logcat stacktrace, identify the missing keep rule, add it, repeat. Common culprits: `flutter_secure_storage`, `permission_handler`, `url_launcher` callback handlers.

**VERIFICATION:**
- AAB size before vs. after — log the delta in the commit body.
- Install the release AAB on a real device; cold launch, record + transcribe + rescue + sign in + view gem detail. Watch logcat for `ClassNotFoundException` or `NoSuchMethodError` — none allowed.
- Re-run [VERIFICATION_PLAN.md](VERIFICATION_PLAN.md) §2 on the minified build.

**COMMIT:** `feat(v1.0): enable R8 minification and shrinkResources (P1-1)`

---

### Subtask P1-2 · Bump `minSdk` to 24

**AIM:** Drop API 23 (Android 6.0 Marshmallow) — < 1% of active devices.

**WORK:**
1. [android/app/build.gradle.kts:46](../android/app/build.gradle.kts#L46) — change `minSdk = 23` to `minSdk = 24`.
2. [pubspec.yaml](../pubspec.yaml) — `flutter_launcher_icons` config: change `min_sdk_android: 23` to `24`.
3. Re-run `flutter pub run flutter_launcher_icons` to regenerate icon manifests.

**VERIFICATION:**
- Release AAB still builds.
- `flutter pub deps` shows no plugin requiring `minSdk > 24`.
- Install on a real device running API 24+ — works. (No need to test on API 23 — you just dropped support for it.)

**COMMIT:** `chore(v1.0): bump minSdk to 24 (P1-2)`

---

### Subtask P1-3 · Branded splash screen

**AIM:** No white flash on cold launch; brand-consistent splash on `#0D0B14`.

**WORK:**
1. Create or update `android/app/src/main/res/drawable/launch_background.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <layer-list xmlns:android="http://schemas.android.com/apk/res/android">
       <item android:drawable="@color/void_bg" />
       <item>
           <bitmap
               android:gravity="center"
               android:src="@mipmap/ic_launcher" />
       </item>
   </layer-list>
   ```
2. Add to `android/app/src/main/res/values/colors.xml` (create if missing):
   ```xml
   <color name="void_bg">#0D0B14</color>
   ```
3. Ensure `android/app/src/main/res/values/styles.xml` and `values-night/styles.xml` both reference `@drawable/launch_background` for the `LaunchTheme` and the `NormalTheme` background.
4. Test cold launch on a real device — no white flash, dark splash with centred icon visible for ~200ms before the Flutter UI takes over.

**VERIFICATION:**
- Cold launch on Pixel and Samsung if available — both show dark splash, no white flash.
- Screen-record cold launch; share with user for design sign-off.
- 🟡 **ASK USER** for sign-off on the splash visual before merging.

**COMMIT:** `feat(v1.0): branded dark splash screen (P1-3)`

---

### Subtask P1-4 · Permission-denied UX

**AIM:** When the user permanently denies the mic permission, show a clear recovery path instead of a dead record button.

**WORK:**
1. In [lib/services/speech_service.dart](../lib/services/speech_service.dart) `initialize()` and the listen() entry point, check `Permission.microphone.status`. If `isPermanentlyDenied`, surface a distinct error code (e.g. `'mic-permanently-denied'`) via the existing `onError` callback.
2. In the controller layer, add a new state `ERROR_MIC_DENIED` (similar to the no-model state in P0-2), or a SnackBar with an "Open settings" CTA invoking `openAppSettings()` from `permission_handler`. SnackBar is fine if the recording UI is otherwise unaffected.
3. Wrap with `e2eId('mic-denied-open-settings', ...)`.

**VERIFICATION:**
- Manual: deny mic at first prompt, then in system settings set it to "Don't ask again". Tap record button — see SnackBar / sheet with "Open settings". Tap → app's system settings opens. Grant mic, return to app — record works.
- Widget test for the new SnackBar/sheet.

**COMMIT:** `feat(v1.0): mic-permission denied recovery UX (P1-4)`

---

### Subtask P1-5 · "Saved locally — will sync" indicator

**AIM:** When a gem is saved while offline or while Supabase is failing, show a small indicator on the gem card so the user trusts the save flow.

**WORK:**
1. [lib/models/gem_note.dart](../lib/models/gem_note.dart) — confirm `audioUrl` is nullable. (It is per CLAUDE.md notes.) A null `audioUrl` for a signed-in user means "not yet synced" — that's the indicator condition.
2. In the gems list widget, when rendering a gem card, if user is authenticated AND `gem.audioUrl == null`, show a small icon (cloud-with-slash or similar) plus tooltip "Saved locally — syncing".
3. In [lib/controllers/gems_controller.dart](../lib/controllers/gems_controller.dart), on auth state change to signed-in or on app foreground, retry uploads for gems whose `audioUrl == null`. Be careful not to duplicate uploads — guard with an in-progress set.

**VERIFICATION:**
- Manual: Airplane mode → save a gem → see the offline indicator. Disable airplane mode → indicator clears within ~5s (after retry succeeds).
- Unit test: the retry path picks up gems with `audioUrl == null` and not the rest.

**COMMIT:** `feat(v1.0): show offline-save indicator and auto-retry (P1-5)`

---

### Phase 2 sign-off

- [ ] All P1 subtasks committed.
- [ ] AAB rebuilt and installed clean.
- [ ] Full [VERIFICATION_PLAN.md](VERIFICATION_PLAN.md) pass on a real device.
- [ ] Open a PR back to `enhancement/ui-changes` with body summarizing every subtask ID + verification evidence.
- [ ] Hand control back to the user for the procedural steps in [PLAY_STORE_UPLOAD.md](PLAY_STORE_UPLOAD.md).

---

## What the agent must NOT do

- Do **not** ship any code that uses cloud STT (Wispr Flow, OpenAI Whisper API, Google Cloud Speech). On-device only.
- Do **not** generate the upload keystore or `key.properties` — the user does this manually per [PLAY_STORE_UPLOAD.md](PLAY_STORE_UPLOAD.md) Phase 1.
- Do **not** push to `main`, force-push any branch, or open a PR to Production stores. Surface PRs to the user; they merge.
- Do **not** deploy Supabase Edge Functions or run database migrations. Surface migrations as `supabase/migrations/<timestamp>_<name>.sql` and wait for the user to apply.
- Do **not** add analytics, crash-reporting, advertising, or device-fingerprinting libraries. The privacy policy explicitly forbids these.
- Do **not** modify [docs/privacy.html](privacy.html) substantively beyond filling placeholders and updating the on-device claim — wording changes need user approval.

---

## Hand-off message template (use when finishing each phase)

```
Phase <N> complete.

Subtasks done: <list of IDs>
Commits: <hashes or branch ref>
Verification:
  - flutter analyze: clean
  - flutter test: <N>/<N> passing
  - playwright: <N>/<N> passing
  - manual on-device checks: <list>

Open questions / 🟡 ASK USER items:
  - <each unresolved question>

Ready to proceed to Phase <N+1>? (y/n)
```

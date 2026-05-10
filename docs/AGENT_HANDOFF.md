# Agent Handoff — The Void App v1.0.0

**Written by:** Sonnet 4.6 agent (Phase 1 executor)  
**Date:** 2026-05-10  
**For:** Next agent executing Phase 2 (P1 polish)

---

## Repo snapshot

| Field | Value |
|---|---|
| Repo | `/Users/Karans/Desktop/The Void App` |
| Active branch | `fix/v1-p0-bundle` |
| Base branch | `enhancement/ui-changes` (34 commits ahead of origin) |
| HEAD commit | `4b4b85b` — P0 omnibus commit |
| `flutter analyze` | ✅ 0 issues |
| `flutter test` | ✅ 43/43 passing |
| Playwright E2E | ❓ Not run — requires a real device / browser; out of scope for this handoff |

---

## What Phase 1 (P0) delivered

All 7 P0 subtasks are merged into commit `4b4b85b` on `fix/v1-p0-bundle`.

### P0-1 — On-device speech recognition forced
**File:** [lib/services/speech_service.dart](../lib/services/speech_service.dart)
- `onDevice: true` added to `SpeechListenOptions` (line ~89)
- `cancelOnError` corrected from `false` → `true`
- `_hasOnDeviceModel` field populated after `initialize()` by calling `locales()`
- `bool get hasOnDeviceModel` getter exposed

### P0-2 — Missing on-device model UX
**Files changed:**
- [lib/models/void_state.dart](../lib/models/void_state.dart) — new `errorNoOfflineModel` state + `isNoOfflineModelError` extension
- [lib/controllers/void_controller.dart](../lib/controllers/void_controller.dart) — new `signalNoOfflineModel()` method
- [lib/controllers/speech_controller.dart](../lib/controllers/speech_controller.dart) — `startRecording()` now routes to `signalNoOfflineModel()` when `!hasOnDeviceModel`
- [lib/widgets/no_offline_model_sheet.dart](../lib/widgets/no_offline_model_sheet.dart) — new widget (sheet + CTA)
- [lib/screens/void_screen.dart](../lib/screens/void_screen.dart) — new state branch overlays the sheet
- [lib/controllers/app_lifecycle_controller.dart](../lib/controllers/app_lifecycle_controller.dart) — `_onResume()` re-attempts init when state is `errorNoOfflineModel`

### P0-3 — Cancel countdown on app background
**File:** [lib/controllers/void_controller.dart](../lib/controllers/void_controller.dart)
- New `cancelCountdown()` method: idempotent, COUNTDOWN → IDLE (not VOIDED)

**File:** [lib/controllers/app_lifecycle_controller.dart](../lib/controllers/app_lifecycle_controller.dart)
- `_wipeOnBackground()` now calls `cancelCountdown()` for COUNTDOWN state; `voidNote()` for all other active sessions

### P0-4 — Hard-fail release build without signing key
**File:** [android/app/build.gradle.kts](../android/app/build.gradle.kts)
- Release `signingConfig` now throws `GradleException` if `key.properties` is absent (no silent debug-key fallback)

### P0-5 — Privacy policy on-device claim updated
**File:** [docs/privacy.html](privacy.html)
- "Third-party services" section updated to explicitly mention `onDevice: true` enforcement on Android
- No bracketed placeholders existed; email is `privacy@thevoidapp.com`; date is "April 2026"

### P0-6 — Pre-auth privacy policy link
**File:** [lib/screens/auth_screen.dart](../lib/screens/auth_screen.dart)
- "Privacy Policy" `TextButton` added below "Not now", uses `AppConfig.privacyPolicyUrl`
- e2eId: `privacy-policy-link` (registered in [e2e/SELECTORS.md](../e2e/SELECTORS.md))

### P0-7 — Delete-account flow hardened
**File:** [lib/controllers/gems_controller.dart](../lib/controllers/gems_controller.dart)
- `clearAllLocalData()` now calls `clearPendingRescue()` in parallel with `clearAllGems()`
- Previously, the pending rescue key (OAuth web redirect transcript) survived account deletion

The server-side delete is handled via the `delete-account` Supabase Edge Function (already deployed). The client calls it via `supabase.functions.invoke('delete-account', method: HttpMethod.post)` in [lib/services/auth_service.dart](../lib/services/auth_service.dart).

---

## Open questions requiring user input

These were flagged `🟡 ASK USER` in the implementation plan and were NOT resolved:

1. **Release signing key** — ⚠️ CONFIRMED MISSING. Neither `android/key.properties` nor `android/upload-keystore.jks` exist on this machine. **The next agent must not attempt a release build.** The user must follow [docs/PLAY_STORE_UPLOAD.md](PLAY_STORE_UPLOAD.md) Phase 1 to generate the keystore and create `key.properties` before any release build is possible.

2. **P0-5 privacy URL** — ✅ CONFIRMED. URL is `https://pingmepi.github.io/the-void-app/privacy` — paste this into Play Console. Email updated to `kmandalam@gmail.com` (commit after this doc).

3. **P0-7 manual verification** — ✅ RESOLVED — not needed before Phase 2. User should test delete-account manually with their own account when they have a device in hand. The code change (clearing pending rescue key) is correct and unit-tested.

4. **P0-2 manual verification** — Needs a device/emulator with no on-device model installed (e.g., non-English locale Android emulator with no offline model). Tap record → expect `NoOfflineModelSheet` to appear. Can be deferred to device testing session.

---

## Phase 2 — P1 polish (your work)

Read [docs/IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) Phase 2 for full specs. Summary:

### P1-1 · Enable R8 minification + ProGuard rules
**Files:** `android/app/build.gradle.kts`, `android/app/proguard-rules.pro` (create)

Add `isMinifyEnabled = true`, `isShrinkResources = true`, and ProGuard rules covering Flutter engine, `speech_to_text`, and Supabase/Kotlin serialization. Build a release AAB, install on device, verify no `ClassNotFoundException`. Log AAB size delta in commit body.

### P1-2 · Bump `minSdk` to 24
**Files:** `android/app/build.gradle.kts` line 46, `pubspec.yaml`

Change `minSdk = 23` → `minSdk = 24`. Re-run `flutter pub run flutter_launcher_icons`. Confirm no plugin requires `minSdk > 24`.

### P1-3 · Branded splash screen
**Files:** `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/values/colors.xml`, `android/app/src/main/res/values/styles.xml`, `android/app/src/main/res/values-night/styles.xml`

Background colour `#0D0B14`, centred adaptive icon. No white flash on cold launch. **Ask user for visual sign-off** before committing.

### P1-4 · Mic permission permanently-denied UX
**Files:** [lib/services/speech_service.dart](../lib/services/speech_service.dart), controller layer

Detect `Permission.microphone.isPermanentlyDenied` in `initialize()`. Surface a SnackBar / sheet with "Open settings" CTA invoking `openAppSettings()`. Add e2eId `mic-denied-open-settings`.

### P1-5 · Offline-save indicator + auto-retry
**Files:** [lib/models/gem_note.dart](../lib/models/gem_note.dart), gems list widget, [lib/controllers/gems_controller.dart](../lib/controllers/gems_controller.dart)

When user is signed in and `gem.audioUrl == null`, show a small cloud-with-slash icon on the gem card. On foreground resume / auth state change, retry uploads for gems with `audioUrl == null`. Guard with an in-progress set to prevent duplicate uploads.

---

## Architecture notes for the next agent

- **State machine:** `IDLE → LISTENING → TRANSCRIBING → COUNTDOWN → [VOIDED | SAVED | errorNoOfflineModel]`. All transitions are in `VoidController`. Use the extension methods (`isNoOfflineModelError`, `canRescue`, etc.) rather than raw enum comparisons in UI code.
- **Code generation:** `GemNote` uses Freezed + `json_serializable`. Run `dart run build_runner build --delete-conflicting-outputs` after any model change. Generated files (`*.freezed.dart`, `*.g.dart`) are committed.
- **E2E IDs:** Any new tappable widget that tests must locate needs `e2eId(...)` from [lib/widgets/e2e_id.dart](../lib/widgets/e2e_id.dart) and an entry in [e2e/SELECTORS.md](../e2e/SELECTORS.md).
- **Secrets:** Never hardcode — use `--dart-define-from-file=.env.json`. `AppConfig` constants are compile-time only.
- **Do not:** cloud STT, force-push, open PRs to `main`, deploy Edge Functions, add analytics.

---

## Phase 2 sign-off checklist (from IMPLEMENTATION_PLAN.md)

Before opening a PR:
- [ ] All P1 subtasks committed
- [ ] AAB rebuilt and installed clean on a real device
- [ ] Full [docs/VERIFICATION_PLAN.md](VERIFICATION_PLAN.md) pass on a real device
- [ ] Open PR to `enhancement/ui-changes` (not `main`) with subtask IDs + verification evidence
- [ ] Hand off to user for [docs/PLAY_STORE_UPLOAD.md](PLAY_STORE_UPLOAD.md) procedural steps

---

## Key file map

| File | Purpose |
|---|---|
| [lib/services/speech_service.dart](../lib/services/speech_service.dart) | STT wrapper — `onDevice:true`, `hasOnDeviceModel` |
| [lib/controllers/void_controller.dart](../lib/controllers/void_controller.dart) | Central state machine |
| [lib/controllers/speech_controller.dart](../lib/controllers/speech_controller.dart) | Bridges STT ↔ VoidController |
| [lib/controllers/app_lifecycle_controller.dart](../lib/controllers/app_lifecycle_controller.dart) | Background wipe + resume re-init |
| [lib/models/void_state.dart](../lib/models/void_state.dart) | State enum + extension methods |
| [lib/models/gem_note.dart](../lib/models/gem_note.dart) | `GemNote` (Freezed) + `VoidSession` (volatile) |
| [lib/widgets/no_offline_model_sheet.dart](../lib/widgets/no_offline_model_sheet.dart) | No-model error UX |
| [lib/screens/auth_screen.dart](../lib/screens/auth_screen.dart) | Auth bottom sheet (has privacy link) |
| [android/app/build.gradle.kts](../android/app/build.gradle.kts) | Release signing guard, minSdk |
| [docs/privacy.html](privacy.html) | Live privacy policy |
| [lib/config/app_config.dart](../lib/config/app_config.dart) | `privacyPolicyUrl`, Supabase config |
| [e2e/SELECTORS.md](../e2e/SELECTORS.md) | E2E identifier registry |
| [docs/VERIFICATION_PLAN.md](VERIFICATION_PLAN.md) | Pre-publish QA checklist |
| [docs/PLAY_STORE_UPLOAD.md](PLAY_STORE_UPLOAD.md) | Play Store submission guide |

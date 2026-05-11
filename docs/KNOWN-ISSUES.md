# Known Issues & Fixes

---

## Active Gaps

### E2E: Full voiding flow not covered
**Symptom:** Playwright's `--use-fake-device-for-media-stream` produces silent audio. The browser's SpeechRecognition API never emits a result, so the app stays in LISTENING and the COUNTDOWN → VOIDED / SAVED path is never reached in automated tests.
**Workaround:** Test the voiding flow manually per `docs/VERIFICATION_PLAN.md §3`.
**Fix path:** Add a test-only hook into `VoidController` to inject a stubbed transcript, or migrate those flows to Flutter's `integration_test` runner.

### E2E: Google / Apple OAuth paths not covered
**Symptom:** OAuth involves a browser popup and real provider accounts — Playwright can't drive it without complex popup handling and test credentials.
**Workaround:** Manual verification only.
**Fix path:** Use Supabase's service-role key to mint a session token and inject it into the test, bypassing the OAuth UI.

### Account buttons not yet wrapped with `e2eId`
**Symptom:** `account_button`, `sign_out_button`, `delete_account_button`, `confirm_delete_account_button` on `GemsScreen` use `Key('...')`, which does not surface in the Flutter web semantics DOM. Playwright cannot locate them.
**Workaround:** These are currently untestable via the E2E suite.
**Fix path:** Replace `Key('...')` with `e2eId('...')` wrappers at each site in `lib/screens/gems_screen.dart` and add entries to `e2e/SELECTORS.md`.

### Audio playback blocked on authenticated gems
**Symptom:** `GemAudioPlayer` requires a signed Supabase Storage URL (`audioUrl`). In E2E and unauthenticated test runs, gems have no audio URL, so the playback UI is never exercised.
**Workaround:** Manual verification with a real signed-in account that has saved gems.
**Fix path:** Wire `E2E_EMAIL` / `E2E_PASSWORD` creds in CI, let auth specs run, then add a playback spec.

### Tags field has no UI
**Symptom:** `GemNote.tags` is a persisted field (Freezed model, Supabase column) but no screen exposes add/edit/filter by tag.
**Workaround:** Field is inert; data is preserved across sync.
**Fix path:** Add tag chips to `GemDetailScreen` with an inline edit flow.

---

## Fixed in 1.0.0 (P0 pre-publish bundle)

| Issue | Fix | PR / commit |
|-------|-----|-------------|
| Speech recognition routed to cloud despite privacy policy claiming on-device | Added `onDevice: true` to `SpeechListenOptions` in `speech_service.dart` | `4b4b85b` |
| No UX when on-device model not installed — app appeared broken | Added `errorNoOfflineModel` state, `NoOfflineModelSheet` widget with deep-link to Android offline speech settings, auto-retry on resume | `4b4b85b` |
| Countdown timer kept ticking while app was backgrounded; user returned to VOIDED state without seeing rescue option | `AppLifecycleController` now calls `cancelCountdown()` (→ IDLE) instead of `voidNote()` when backgrounding during COUNTDOWN | `4b4b85b` |
| Release AAB silently fell back to debug signing when `key.properties` was absent | `build.gradle.kts` now throws `GradleException` at config time if `key.properties` is missing | `4b4b85b` |
| Privacy policy link not accessible before user authenticated | Added `TextButton` linking to privacy policy on `AuthScreen` (pre-auth, visible before any sign-in prompt) | `4b4b85b` |
| Delete account left pending rescue transcript in `flutter_secure_storage` | `GemsController.clearAllLocalData()` now also calls `clearPendingRescue()` | `4b4b85b` |
| Pending rescue transcript could persist indefinitely after cancelled OAuth | Auto-expires after 5 minutes; cleared on expiry check regardless of auth state | `4b4b85b` |
| Release build crashed silently if Supabase credentials missing | Runtime guard in `main()` throws `StateError` (not just a debug `assert`) | earlier |
| `AuthService.currentUser` crashed in tests when Supabase not initialized | Wrapped in try-catch; returns `null` safely | earlier |

# Verification Plan — Pre-Publish QA

**Run order:** complete `FIX_PLAN.md` P0/P1 → run this file end-to-end → only then start `PLAY_STORE_UPLOAD.md`.
**Devices required:** at minimum one real Android phone (API 24+). Emulator is not enough — speech recognizer & permissions behave differently.
**Build under test:** `flutter build appbundle --dart-define-from-file=.env.json --build-name=1.0.0 --build-number=1` then `bundletool build-apks` → install on device. (Or `flutter run --release --dart-define-from-file=.env.json` for faster iteration; just confirm a true AAB build also passes once at the end.)

Check off each line. If anything fails, fix and re-run the relevant section — do not "we'll fix it after launch" any P0 line.

---

## §1 — Build hygiene

- [ ] `flutter clean && flutter pub get` succeeds with no errors.
- [ ] `dart run build_runner build --delete-conflicting-outputs` produces no errors.
- [ ] `flutter analyze` returns zero issues (or only intentional ignores).
- [ ] `flutter test` — all unit & widget tests pass.
- [ ] `cd e2e && npx playwright test` — all E2E specs pass on Flutter web build.
- [ ] `flutter build appbundle --dart-define-from-file=.env.json` completes; output AAB > 10 MB and < 50 MB.
- [ ] `flutter build appbundle --analyze-size` shows no surprise bloat (no >5 MB unknown asset).
- [ ] AAB built **without** `key.properties` fails fast (proves P0-4 guard works).
- [ ] Confirm `.env.json` is gitignored (`git check-ignore .env.json` returns the path).

## §2 — App lifecycle & state machine

Test on a real device with the release AAB.

- [ ] Cold launch: dark theme paints immediately, no white flash, mic permission prompt appears once before main UI.
- [ ] State transitions: IDLE → LISTENING → TRANSCRIBING → COUNTDOWN → VOIDED behave per `lib/models/void_state.dart`.
- [ ] During COUNTDOWN, "Rescue" button works and transitions to SAVED (when authed) or to auth flow (when not).
- [ ] **Background mid-LISTENING** → return: state is IDLE, no transcript leaked into a new session, no countdown running in the background. (Validates P0-3.)
- [ ] **Background mid-COUNTDOWN** → return after countdown duration: app is in IDLE, NOT auto-VOIDED (timer was cancelled).
- [ ] App lock / screen off → unlock: same expectation as above.
- [ ] Force-stop → reopen: no in-flight `VoidSession` survives. Saved gems still load.

## §3 — Permissions

- [ ] Fresh install: mic permission prompt appears at launch (`main.dart` pre-warm).
- [ ] Deny mic at prompt → tap record button → app shows clear permission-denied UX with "Open settings" CTA. (Validates P1-4.)
- [ ] Approve mic from settings → return to app → record works without restart.
- [ ] No additional permissions are requested at runtime (the only declared perms are `INTERNET` + `RECORD_AUDIO`).

## §4 — Speech recognition (privacy-critical)

- [ ] Airplane mode ON → record → speech still transcribes locally. (Validates P0-1 `onDevice: true`.)
- [ ] If on-device model is missing: app shows the setup CTA and deep-links to Google App voice settings. (Validates P0-2.)
- [ ] After installing the on-device model and returning, record works without an app restart.
- [ ] Confirm via OS-level network monitor (or `adb shell` + a packet sniffer) that **no audio bytes** leave the device while LISTENING. Only Supabase REST/Realtime traffic is acceptable, and only AFTER tapping Rescue.
- [ ] Recording auto-stops after ~5s of silence and after 2 min hard cap.

## §5 — Authentication flows

- [ ] **Email signup** (new account) → confirmation → sign in → land on Gems screen.
- [ ] **Email sign-in** existing account → success.
- [ ] **Google OAuth** on Android: SHA-1 registered, OAuth completes, returns via `com.thevoidapp://login-callback`, user lands authed.
- [ ] **Sign out** → app returns to unauthed state, in-memory gems cleared.
- [ ] **OAuth cancel mid-rescue**: pending rescue is preserved, then expires after 5 minutes (per `KNOWN-ISSUES.md` resolved entry).
- [ ] **Mid-session sign-in** triggers Supabase gem refresh (commit `a3ac4ce`).

## §6 — Gem CRUD

- [ ] Save gem (authed, online): appears in list immediately, persists across app restart, syncs to Supabase (verify in Supabase dashboard).
- [ ] Save gem (authed, offline): appears in list, marked as un-synced (per P1-5), syncs on reconnect.
- [ ] Save gem (unauthed) → triggers auth flow → after auth, gem is in list.
- [ ] Open gem detail: full transcript visible, audio plays end-to-end (commit `31712cd`).
- [ ] Search/filter on Gems screen returns expected results.
- [ ] Delete single gem: removed from list, removed from Supabase row, audio removed from Storage.
- [ ] **Delete account**: all rows gone from Supabase `gems` table, all audio gone from Storage bucket, auth user removed, local secure storage wiped, app returns to unauthed home.

## §7 — Privacy policy claims vs. reality

For each line in `docs/privacy.html`, confirm the code matches:

- [ ] "Speech-to-text happens via the operating system — The Void does not send audio to any server it controls." → P0-1 verified by §4 network sniff.
- [ ] "Audio is uploaded only if you tap Rescue." → record without rescue → confirm no Storage upload (Supabase dashboard).
- [ ] "We do not use any analytics or crash-reporting SDKs." → grep `pubspec.yaml` for `firebase_analytics`, `sentry`, `mixpanel`, `amplitude` — must return zero.
- [ ] "We do not collect device identifiers or advertising IDs." → grep code for `androidId`, `advertisingId`, `device_info_plus` — confirm absent or unused.
- [ ] Effective date and contact email in the published HTML are real, not placeholders.
- [ ] Privacy policy is reachable from inside the app pre-auth (P0-6).

## §8 — Security checks

- [ ] `git log --all -p | grep -i "supabase.*key\|sk-\|password"` returns nothing (no leaked secrets in history).
- [ ] Decompile the release AAB (e.g., `apkanalyzer` / `bundletool`) and confirm `.env.json` values aren't embedded as plaintext strings — `--dart-define` injects them but they end up in compiled Dart, which is acceptable for the Supabase **anon** key only. Verify it's the anon key, not the service role.
- [ ] Only `MainActivity` is `exported="true"` in `AndroidManifest.xml`. No exported services/receivers.
- [ ] Deep link scheme `com.thevoidapp://login-callback` is the only intent filter beyond LAUNCHER.
- [ ] Run `flutter pub deps --style=compact | grep -i "deprecated\|abandoned"` — investigate any hits.

## §9 — Store-listing assets

- [ ] App icon: open `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` in Preview — it is the branded glyph, not the Flutter "F".
- [ ] Adaptive icon: launcher with circular / squircle masks shows the icon centered on `#0D0B14` background (test on Pixel + Samsung if possible).
- [ ] 512×512 PNG of the icon is exported for the Play Store listing field.
- [ ] 1024×500 feature graphic created (Play Store requires this — without it you cannot submit).
- [ ] At least 2 phone screenshots captured from internal-testing build (record screen on-device, do NOT use marketing renders that misrepresent the app).
- [ ] Short description ≤ 80 chars; full description 3–5 paragraphs.
- [ ] Content rating questionnaire pre-answered (see `PLAY_STORE_UPLOAD.md` §5.5).
- [ ] Data Safety pre-answered to match what the code actually does (after P0-1 fix, audio is **not** transmitted during recording).

## §10 — Accessibility & i18n smoke

- [ ] System font scale 200% → no clipped text, no overlapping buttons.
- [ ] System dark mode (already the only mode) → colors meet WCAG AA on `#7FFFD4` aquamarine vs `#0D0B14` background.
- [ ] TalkBack on: record button reads as "Record voice note", rescue button reads as "Rescue gem".
- [ ] App is English-only for v1.0 — confirm no `Intl.message` keys are missing translations breaking layout.

## §11 — Sign-off gate

Don't proceed to `PLAY_STORE_UPLOAD.md` Phase 5 (Production submission) until:

- All §1–§7 boxes are checked.
- §8 security boxes are checked.
- §9 has at least 2 screenshots, the icon, and the feature graphic.
- A real human has used the app for 5 minutes without a crash.
- One round trip done via Internal Testing track (Phase 5.3) on a device that is **not** the dev machine.

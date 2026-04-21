# Changelog

All notable changes to The Void are documented here.

## [Unreleased]

### Added

- **Email/password sign-in** — full login form with sign-in / sign-up mode toggle, forgot-password reset, and Supabase `AuthException` handling. Available both on the full-screen LoginScreen and the mid-rescue AuthScreen bottom sheet.
- **Playwright E2E suite** — 19 passing specs across smoke, navigation, auth form, voiding UI transitions, and edge cases. Covers happy paths, validation failure modes, and small-viewport behavior. Auto-skips 2 credential-gated specs when `.env.json` + test creds are absent. See [e2e/README.md](e2e/README.md) and [e2e/SELECTORS.md](e2e/SELECTORS.md).
- **`e2eId` wrapper** ([lib/widgets/e2e_id.dart](lib/widgets/e2e_id.dart)) — wraps widgets in `Semantics(identifier: …)` for stable DOM selectors during E2E runs.
- **E2E mode guard** — `--dart-define=E2E=true` enables Flutter's semantics tree (`SemanticsBinding.ensureSemantics()`) and lets the app boot without Supabase credentials for headless smoke tests.
- **Gems screen** — browse, search, and manage all rescued transcripts in a dark-themed list sorted newest first
- **Gem detail view** — read full transcript with date, duration, and inline title editing (tap to name, auto-saves on submit or unfocus)
- **Delete with confirmation** — remove gems via confirmation dialog from both list and detail views
- **Google & Apple sign-in** — full-screen branded login with OAuth, plus a quick bottom-sheet auth gate during mid-rescue saves
- **Remote gem sync** — gems automatically back up to Supabase when signed in; local-first with encrypted storage
- **Audio recording** — voice captured alongside transcription via MediaRecorder (web) or temp M4A (native) for future playback
- **Navigation button** — profile/nav button on home screen shows user initial (signed in) or sparkle icon (signed out) with gem count badge
- **Login screen** — full-screen branded sign-in (email + OAuth) with "Maybe later" dismiss and auto-pop on auth completion; switched to `SingleChildScrollView` so the form fits small viewports
- **Ethereal UI** — dark navy/purple theme with aquamarine accents, serif fonts, animated glowing mic button, floating background text
- **Responsive layout** — adaptive countdown UI across screen sizes
- **Mobile release config** — Android (permissions, OAuth deep links, release signing, minSdk 23) and iOS (mic/speech permissions, OAuth URL scheme)
- **Deployment config** — Dockerfile + nginx.conf for Railway web deployment
- **App store submission guide** — step-by-step doc for Play Store and App Store with privacy policy text
- **Test suite** — 43 automated tests: 14 controller unit tests, 7 widget tests, 19 screen/integration tests, 3 existing tests

### Fixed

- **Pending rescue expiry** — cancelled OAuth no longer leaves transcript in storage indefinitely; auto-clears after 5 minutes
- **Runtime config guard** — missing credentials fail loudly in release builds (replaced debug-only `assert` with runtime check)
- **Auth safety in tests** — `AuthService.currentUser` wrapped in try-catch to prevent crashes when Supabase isn't initialized

### Security

- All gems encrypted at rest via `flutter_secure_storage`
- Credentials injected at compile time via `--dart-define-from-file` (never committed)
- Pending rescue transcript auto-expires to prevent stale data in localStorage

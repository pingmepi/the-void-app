# Changelog

All notable changes to The Void are documented here.

## [Unreleased]

### Added

- **Gems screen** — browse, search, and manage all rescued transcripts in a dark-themed list sorted newest first
- **Gem detail view** — read full transcript with date, duration, and inline title editing (tap to name, auto-saves on submit or unfocus)
- **Delete with confirmation** — remove gems via confirmation dialog from both list and detail views
- **Google & Apple sign-in** — full-screen branded login with OAuth, plus a quick bottom-sheet auth gate during mid-rescue saves
- **Remote gem sync** — gems automatically back up to Supabase when signed in; local-first with encrypted storage
- **Audio recording** — voice captured alongside transcription via MediaRecorder (web) or temp M4A (native) for future playback
- **Navigation button** — profile/nav button on home screen shows user initial (signed in) or sparkle icon (signed out) with gem count badge
- **Login screen** — full-screen branded sign-in with "Maybe later" dismiss and auto-pop on auth completion
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

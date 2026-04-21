# Progress

Current status of The Void as of 2026-04-21.

---

## Completed

### Core App
- [x] State machine: `IDLE → LISTENING → TRANSCRIBING → COUNTDOWN → VOIDED | SAVED`
- [x] VoidController with countdown timer (10 seconds), transcript accumulation
- [x] SpeechService: real-time transcription, 5s silence detection, 2-minute max
- [x] RecordingService: parallel audio capture (WebM on web, M4A on native)
- [x] AppLifecycleController: auto-wipe volatile data on background
- [x] Privacy: VoidSession is RAM-only, never persisted

### Gems (Saved Notes)
- [x] GemNote model (Freezed): id, transcript, savedAt, title, duration, tags, userId, audioUrl
- [x] GemsController: save, delete, update title, sort, Supabase sync
- [x] StorageService: encrypted local storage via flutter_secure_storage
- [x] GemsScreen: list view, empty state, delete with confirmation dialog, transcript search/filter
- [x] GemDetailScreen: full transcript, inline title editing, delete, audio playback via GemAudioPlayer
- [x] GemCard widget: title/preview, date, duration chip, callbacks
- [x] Pending rescue: persists transcript before OAuth redirect, auto-expires after 5 minutes

### Authentication
- [x] Supabase auth: Google + Apple OAuth
- [x] Email / password: sign-in, sign-up, password reset with Supabase AuthException handling
- [x] EmailAuthForm: reusable form on both LoginScreen and AuthScreen with mode toggle + "Forgot password?"
- [x] AuthScreen: bottom-sheet auth gate during rescue flow
- [x] LoginScreen: full-screen branded sign-in with "Maybe later" dismiss
- [x] Auth state providers: isLoggedIn, currentUserId, userEmail
- [x] AuthService.currentUser: try-catch for test/startup safety
- [x] OAuth deep links: Android intent filter + iOS URL scheme (`com.thevoidapp://login-callback`)

### UI/UX
- [x] Dark ethereal theme: navy/purple background, aquamarine accents, serif fonts
- [x] GlowingMicButton: animated pulsing glow
- [x] WaveformVisualizer: staggered animated bars during recording
- [x] VoidTimerWidget: circular countdown with rescue button
- [x] TranscriptDisplay: styled, auto-scrolling transcript
- [x] EtherealText: floating background text
- [x] Nav button on home screen: user initial (signed in) or sparkle (signed out) + gem count badge
- [x] Responsive layout across screen sizes

### Infrastructure
- [x] Runtime config via `--dart-define-from-file=.env.json` (compile-time injection)
- [x] Runtime config guard (fails loudly in release, not just debug assert)
- [x] Dockerfile + nginx.conf for Railway web deployment
- [x] Android: INTERNET + RECORD_AUDIO permissions, minSdk 23, release signing via key.properties
- [x] iOS: NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription, URL schemes

### Store Readiness
- [x] App icon: branded 1024x1024 asset via flutter_launcher_icons (PR #6)
- [x] Delete account flow: Supabase Edge Function + in-app trigger (PR #6)
- [x] Privacy policy: hosted on GitHub Pages, in-app url_launcher link (PR #9)
- [x] Account management on GemsScreen: sign-out bottom sheet with user email (PR #5)

### Tests (43 unit/widget + 19 Playwright E2E)
- [x] FakeStorageService: in-memory test double for all storage operations
- [x] 14 GemsController unit tests (save, delete, update title, sort, load from storage)
- [x] 7 GemCard widget tests (display, callbacks, formatting)
- [x] 19 screen tests (GemsScreen, GemDetailScreen, LoginScreen, VoidScreen nav button)
- [x] 2 VoidController countdown tests
- [x] 1 smoke test
- [x] Playwright E2E: 19 passing specs (smoke, navigation, auth form, voiding UI, edge cases). 2 credential-gated specs auto-skip without `.env.json` + `E2E_EMAIL` / `E2E_PASSWORD`.
- [x] Semantics bridge: `e2eId()` wrapper + `--dart-define=E2E=true` for stable DOM selectors in Flutter web

### Documentation
- [x] README.md: overview, quick start, project structure, tech stack
- [x] CLAUDE.md: developer guide for AI-assisted development
- [x] CHANGELOG.md: user-facing feature history
- [x] PROGRESS.md: this file
- [x] docs/PRD.md: product requirements
- [x] docs/ARCHITECTURE.md: system design
- [x] docs/KNOWN-ISSUES.md: issues, fixes, workarounds
- [x] docs/app-store-submission.md: Play Store + App Store guide with privacy policy
- [x] e2e/README.md + e2e/SELECTORS.md: Playwright setup, selector inventory, fragility map

---

## Pending

### High Priority (Store Submission Blockers)
- [ ] **Supabase DB setup**: verify prod has gems table, RLS policies, and storage bucket applied (documented in submission guide)

### Medium Priority (Feature Completeness)
- [ ] **E2E: full voiding flow**: blocked on stubbed transcript (Playwright fake audio produces silence, SpeechRecognition never emits). Needs a test-only hook into `VoidController`.
- [ ] **E2E: OAuth paths**: requires real Google/Apple test accounts + popup handling.
- [ ] **Tags**: GemNote.tags field exists but no UI to add/edit tags

### Low Priority (Polish)
- [ ] Particle dissolve animation when note is voided
- [ ] Sound/haptic feedback on state transitions
- [ ] Smooth cross-fade transitions between states
- [ ] Onboarding / first-run experience

---

## Version History

| Version | Date | Highlights |
|---------|------|-----------|
| 0.5.0 | 2026-04-21 | Email/password auth, Playwright E2E suite (19 specs), semantics bridge for DOM-based selectors |
| 0.4.0 | 2026-04-18 | Store readiness: app icon, delete account, privacy policy page, account mgmt sheet |
| 0.3.0 | 2026-04-08 | Gems screens, auth, remote sync, mobile config, 43 tests |
| 0.2.0 | 2026-01-13 | Waveform visualization, countdown tuning, silence detection |
| 0.1.0 | 2026-01-12 | Initial: state machine, speech engine, privacy, basic UI |

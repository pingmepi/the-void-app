# Progress

Current status of The Void as of 2026-04-08.

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
- [x] GemsScreen: list view, empty state, delete with confirmation dialog
- [x] GemDetailScreen: full transcript, inline title editing, delete
- [x] GemCard widget: title/preview, date, duration chip, callbacks
- [x] Pending rescue: persists transcript before OAuth redirect, auto-expires after 5 minutes

### Authentication
- [x] Supabase auth: Google + Apple OAuth
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

### Tests (43 total)
- [x] FakeStorageService: in-memory test double for all storage operations
- [x] 14 GemsController unit tests (save, delete, update title, sort, load from storage)
- [x] 7 GemCard widget tests (display, callbacks, formatting)
- [x] 19 screen tests (GemsScreen, GemDetailScreen, LoginScreen, VoidScreen nav button)
- [x] 2 VoidController countdown tests
- [x] 1 smoke test

### Documentation
- [x] README.md: overview, quick start, project structure, tech stack
- [x] CLAUDE.md: developer guide for AI-assisted development
- [x] CHANGELOG.md: user-facing feature history
- [x] PROGRESS.md: this file
- [x] docs/PRD.md: product requirements
- [x] docs/ARCHITECTURE.md: system design
- [x] docs/KNOWN-ISSUES.md: issues, fixes, workarounds
- [x] docs/app-store-submission.md: Play Store + App Store guide with privacy policy

---

## Pending

### High Priority (Store Submission Blockers)
- [ ] **App icon**: replace Flutter default with branded 1024x1024 PNG (use flutter_launcher_icons)
- [ ] **Delete account flow**: Apple requires this — needs Supabase Edge Function for server-side deletion
- [ ] **Privacy policy page**: host the policy text (content ready in docs/app-store-submission.md) and add in-app url_launcher link
- [ ] **Supabase DB setup**: run SQL for gems table, RLS policies, storage bucket (documented in submission guide)

### Medium Priority (Feature Completeness)
- [ ] **Account management on GemsScreen**: sign-out button / bottom sheet with user email
- [ ] **Audio playback**: gems have audioUrl but no playback UI yet
- [ ] **Gem search/filter**: search by transcript content or title
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
| 0.3.0 | 2026-04-08 | Gems screens, auth, remote sync, mobile config, 43 tests |
| 0.2.0 | 2026-01-13 | Waveform visualization, countdown tuning, silence detection |
| 0.1.0 | 2026-01-12 | Initial: state machine, speech engine, privacy, basic UI |

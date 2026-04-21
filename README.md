# The Void

**Speak. Transcribe. Decide: keep or void.**

The Void is a privacy-first voice note app. Your spoken thoughts are captured, transcribed in real time, and then **voided by default** — after a 10-second countdown, the note is permanently deleted unless you intentionally rescue it as a **Gem**.

---

## Why

Most note apps hoard everything. The Void inverts that: nothing is kept unless you choose to keep it. This creates a low-pressure space to think out loud, where only the ideas worth saving survive.

---

## How It Works

1. **Tap the mic** — recording starts with an animated waveform
2. **Speak freely** — live transcript scrolls as you talk (up to 2 minutes, auto-pauses after 5s silence)
3. **Stop** — a 10-second countdown begins
4. **Rescue or let go** — tap "Rescue" to save as an encrypted Gem, or let the countdown finish to void it forever
5. **Browse gems** — view, rename, or delete your saved transcripts

Backgrounding the app at any point **immediately wipes** all in-progress data.

---

## Quick Start

### Prerequisites

- Flutter SDK (3.10.7+)
- A Supabase project (for auth & sync — [setup guide](docs/app-store-submission.md#part-3-in-app-requirements))

### Setup

```bash
# Install dependencies
flutter pub get

# Generate Freezed models + Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Copy env template and add your Supabase credentials
cp .env.json.example .env.json
# Edit .env.json with your SUPABASE_URL and SUPABASE_ANON_KEY
```

### Run

```bash
# Web
flutter run -d chrome --dart-define-from-file=.env.json

# macOS
flutter run -d macos --dart-define-from-file=.env.json

# iOS / Android (after platform toolchain setup)
flutter run --dart-define-from-file=.env.json
```

### Test

```bash
flutter test          # 43 unit/widget/screen tests
flutter analyze       # static analysis — should be 0 issues

# End-to-end (Playwright, Flutter web)
cd e2e && npm install && npx playwright install chromium ffmpeg
npm test              # 19 passing specs; 2 auto-skipped without auth creds
```

See [e2e/README.md](e2e/README.md) and [e2e/SELECTORS.md](e2e/SELECTORS.md) for the E2E setup, credential story, and selector inventory.

---

## Documentation

| Document | What it covers |
|----------|---------------|
| [README.md](README.md) | This file — overview, quick start, project map |
| [CLAUDE.md](CLAUDE.md) | Developer guide for AI-assisted development (commands, architecture, theme) |
| [CHANGELOG.md](CHANGELOG.md) | User-facing feature history |
| [PROGRESS.md](PROGRESS.md) | Roadmap — what's done, what's next |
| [docs/PRD.md](docs/PRD.md) | Product requirements document |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, state machine, data flow |
| [docs/KNOWN-ISSUES.md](docs/KNOWN-ISSUES.md) | Known issues, fixes applied, and workarounds |
| [docs/app-store-submission.md](docs/app-store-submission.md) | Step-by-step Play Store + App Store submission guide with privacy policy |
| [e2e/README.md](e2e/README.md) | Playwright E2E setup, credential story, intentional gaps |
| [e2e/SELECTORS.md](e2e/SELECTORS.md) | Per-widget selector inventory (robust vs fallback) and triage steps |

---

## Project Structure

```
lib/
├── main.dart                          # Entry point, theme (VoidColors), ProviderScope
├── config/
│   └── app_config.dart                # Runtime config (Supabase creds via --dart-define)
├── controllers/
│   ├── void_controller.dart           # Core state machine (IDLE→LISTENING→…→VOIDED|SAVED)
│   ├── speech_controller.dart         # Bridges SpeechService ↔ VoidController
│   ├── gems_controller.dart           # Gem CRUD + Supabase sync + pending rescue
│   ├── auth_controller.dart           # Auth state providers (isLoggedIn, userEmail)
│   └── app_lifecycle_controller.dart  # Auto-wipes volatile data on background
├── models/
│   ├── void_state.dart                # VoidState enum + extension methods
│   ├── gem_note.dart                  # GemNote (persistent) + VoidSession (volatile)
│   ├── gem_note.freezed.dart          # Generated
│   └── gem_note.g.dart               # Generated
├── screens/
│   ├── void_screen.dart               # Main screen (landing, listening, countdown, result)
│   ├── gems_screen.dart               # Browse saved gems (list, empty state, delete)
│   ├── gem_detail_screen.dart         # View transcript, edit title, delete
│   ├── login_screen.dart              # Full-screen sign-in (email/password + Google/Apple OAuth)
│   └── auth_screen.dart               # Auth gate during rescue flow (bottom sheet)
├── services/
│   ├── speech_service.dart            # Wraps speech_to_text (5s silence, 2min max)
│   ├── recording_service.dart         # Parallel audio capture (WebM web, M4A native)
│   ├── storage_service.dart           # Encrypted local storage + Supabase sync
│   ├── auth_service.dart              # Auth wrapper (email/password + Google/Apple OAuth)
│   └── supabase_service.dart          # Supabase client singleton
└── widgets/
    ├── glowing_mic_button.dart        # Animated pulsing mic (app entry point)
    ├── void_timer_widget.dart         # Circular countdown + rescue button
    ├── transcript_display.dart        # Styled transcript container
    ├── waveform_visualizer.dart       # Animated bars during recording
    ├── ethereal_text.dart             # Floating background text
    ├── gem_card.dart                  # Gem list item (title, preview, date, delete)
    ├── gem_audio_player.dart          # Audio playback UI for gems
    ├── email_auth_form.dart           # Reusable email/password form (sign-in/up, reset)
    └── e2e_id.dart                    # Semantics(identifier:) wrapper for Playwright selectors

e2e/                                   # Playwright tests (Flutter web)
├── playwright.config.ts
├── helpers/                           # byId/byText, fillField, waitForFlutter
└── tests/                             # smoke, navigation, auth, voiding, edge

test/
├── helpers/
│   └── fake_storage_service.dart      # In-memory StorageService for tests
├── gems_controller_test.dart          # 14 unit tests
├── gem_card_test.dart                 # 7 widget tests
├── gems_screen_test.dart              # 19 screen/integration tests
├── void_controller_countdown_test.dart # 2 state machine tests
└── widget_test.dart                   # 1 smoke test

docs/
├── PRD.md                             # Product requirements
├── ARCHITECTURE.md                    # System design
├── KNOWN-ISSUES.md                    # Issues and fixes
└── app-store-submission.md            # Store submission guide + privacy policy
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.10.7+ / Dart 3.10.7+ |
| State | Riverpod (flutter_riverpod + riverpod_annotation) |
| Speech | speech_to_text |
| Audio | record (MediaRecorder on web, native on mobile) |
| Storage | flutter_secure_storage (AES-encrypted) |
| Auth | Supabase (email/password + Google + Apple OAuth) |
| Backend | Supabase (Postgres DB + Storage buckets) |
| Models | Freezed + json_serializable |
| E2E | Playwright (Chromium) against `flutter build web --dart-define=E2E=true` |
| Deployment | Docker + nginx (Railway for web) |

---

## Security

- Credentials injected at compile time via `--dart-define-from-file=.env.json` — never committed
- All saved gems encrypted at rest via `flutter_secure_storage`
- Volatile session data lives only in RAM — wiped on app background
- Pending rescue transcripts auto-expire after 5 minutes
- Runtime config guard prevents misconfigured release builds from running silently

---

## License

Private — not open source.

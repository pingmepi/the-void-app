# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Freezed models, Riverpod providers, JSON serializers) — required after modifying annotated files
dart run build_runner build --delete-conflicting-outputs

# First-time setup: copy env template and fill in Supabase credentials
cp .env.json.example .env.json   # then edit .env.json with real values

# Run the app — --dart-define-from-file injects secrets at compile time (never committed)
flutter run -d chrome --dart-define-from-file=.env.json
flutter run -d macos --dart-define-from-file=.env.json

# Build for web
flutter build web --dart-define-from-file=.env.json

# Run all tests
flutter test

# Run a single test file
flutter test test/void_controller_countdown_test.dart

# Lint / static analysis
flutter analyze
```

## Architecture

The Void is a single-screen Flutter app with a strict state machine at its core.

### State Machine
`IDLE → LISTENING → TRANSCRIBING → COUNTDOWN → VOIDED | SAVED`

Defined in `lib/models/void_state.dart`. The `VoidState` enum has extension methods (`isRecording`, `canRescue`, `isCountdownActive`, etc.) that drive UI visibility decisions. Use these extensions rather than raw enum comparisons in UI code.

### State Management
Riverpod (`flutter_riverpod` + `riverpod_annotation`). All providers use code generation — run `build_runner` after changing annotated provider classes. The three main controllers are:

- `VoidController` (`lib/controllers/void_controller.dart`) — central state machine; owns the countdown timer, transcript accumulation, and all state transitions
- `SpeechController` (`lib/controllers/speech_controller.dart`) — bridges `SpeechService` ↔ `VoidController`
- `GemsController` (`lib/controllers/gems_controller.dart`) — CRUD for saved gems via `StorageService`
- `AppLifecycleController` (`lib/controllers/app_lifecycle_controller.dart`) — wipes volatile in-memory state when the app backgrounds

### Data Model Split
There are two intentionally separate data types:

- `VoidSession` (in `lib/models/gem_note.dart`) — **volatile**, lives only in RAM, wiped on background. Contains transcript, countdown seconds, recording start time.
- `GemNote` (Freezed, in `lib/models/gem_note.dart`) — **persistent**, encrypted via `flutter_secure_storage`. Contains UUID, full transcript, save timestamp, optional title/tags/duration.

Never persist `VoidSession` to storage. Never hold `GemNote` in unencrypted memory longer than necessary.

### Services
- `SpeechService` (`lib/services/speech_service.dart`) — wraps `speech_to_text`; auto-stops after 5s silence, max 2 min recording
- `StorageService` (`lib/services/storage_service.dart`) — wraps `flutter_secure_storage` for gem persistence

### Code Generation
`GemNote` uses Freezed + `json_serializable`. Generated files (`*.freezed.dart`, `*.g.dart`) are committed and must be regenerated after model changes.

## Theme
Dark ethereal palette defined in `lib/main.dart`:
- Background: `#0D0B14` (deep navy/purple)
- Accent/glow: `#7FFFD4` / `#00FF9D` (aquamarine)
- Text: `#E8E8E8`

Material 3 with serif font family for the ethereal aesthetic. Keep new UI consistent with this palette.

# The Void App - Development Progress

## Overview

**The Void** is a privacy-first voice note app built with Flutter. Notes are ephemeral by default - they disappear after 60 seconds unless intentionally saved as "Gems".

## Core Philosophy

- **Ephemeral by default**: All voice notes auto-delete after 60 seconds
- **Intentional by choice**: Users can "rescue" notes before they vanish
- **Privacy-first**: App wipes all in-memory data when backgrounded
- **Minimal friction**: One tap to record, one tap to save

---

## ✅ Completed Features

### 1. Project Setup & Architecture
- [x] Flutter project initialized with proper structure
- [x] Riverpod state management configured
- [x] Code generation with Freezed + JSON Serializable
- [x] Platform entitlements for microphone (macOS/iOS)

### 2. Core State Machine
- [x] `VoidState` enum: `idle → listening → transcribing → countdown → voided/saved`
- [x] `VoidController` manages all state transitions
- [x] `VoidSession` holds volatile in-memory data (transcript, timer, etc.)
- [x] 60-second countdown timer with auto-void

### 3. Speech-to-Text Engine
- [x] `SpeechService` wraps `speech_to_text` package
- [x] Microphone permission handling via `permission_handler`
- [x] Real-time transcription with partial results
- [x] Auto-stop after 3 seconds of silence
- [x] Maximum recording time: 2 minutes
- [x] `SpeechController` bridges speech service with void controller

### 4. Privacy Features
- [x] `AppLifecycleController` observes app lifecycle
- [x] Auto-wipe when app is backgrounded/hidden
- [x] In-memory only volatile data (never written to disk during session)

### 5. Secure Storage (Gems)
- [x] `GemNote` model with Freezed (id, transcript, title, timestamps)
- [x] `StorageService` using `flutter_secure_storage`
- [x] `GemsController` for CRUD operations on saved gems
- [x] Encrypted storage for saved notes

### 6. UI/UX
- [x] Dark theme with Material 3
- [x] `VoidScreen` - main interaction screen
- [x] Mic button for starting recording
- [x] Stop button (red) during recording
- [x] Real-time transcript display while speaking
- [x] `VoidTimerWidget` - circular countdown with rescue button
- [x] `TranscriptDisplay` - styled transcript container
- [x] Visual state feedback (colors, icons per state)

---

## 🚧 In Progress / Pending

### 1. Gem Saving Integration
- [ ] Wire `rescueNote()` to actually save via `GemsController`
- [ ] Show confirmation after saving
- [ ] Return to idle state after save

### 2. Gems Screen
- [ ] List view of saved gems
- [ ] View full transcript
- [ ] Edit title
- [ ] Delete gems
- [ ] Navigation from main screen

### 3. Visual Polish
- [ ] Particle dissolve animation when note is voided
- [ ] Smooth transitions between states
- [ ] Sound/haptic feedback

### 4. Platform Setup
- [ ] Complete Xcode installation for macOS/iOS builds
- [ ] Install CocoaPods for native plugin support
- [ ] Android SDK setup (optional)

---

## Project Structure

```
lib/
├── main.dart                    # App entry, ProviderScope, theme
├── controllers/
│   ├── void_controller.dart     # Core state machine
│   ├── speech_controller.dart   # Speech ↔ Void bridge
│   ├── gems_controller.dart     # Saved notes management
│   └── app_lifecycle_controller.dart  # Privacy wipe on background
├── models/
│   ├── void_state.dart          # State enum + VoidSession
│   └── gem_note.dart            # Freezed model for saved gems
├── screens/
│   └── void_screen.dart         # Main UI screen
├── services/
│   ├── speech_service.dart      # Speech-to-text wrapper
│   └── storage_service.dart     # Secure storage operations
└── widgets/
    ├── void_timer_widget.dart   # Countdown display
    └── transcript_display.dart  # Transcript UI component
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Code generation for providers |
| speech_to_text | ^7.3.0 | Voice recognition |
| flutter_secure_storage | ^10.0.0 | Encrypted gem storage |
| permission_handler | ^11.4.0 | Microphone permissions |
| freezed_annotation | ^2.4.4 | Immutable models |
| json_annotation | ^4.9.0 | JSON serialization |
| uuid | ^4.5.2 | Unique IDs for gems |

---

## How to Run

```bash
# Get dependencies
flutter pub get

# Generate code (models, providers)
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome (works now)
flutter run -d chrome

# Run on macOS (requires Xcode + CocoaPods)
flutter run -d macos
```

---

## State Flow Diagram

```
        ┌──────────┐
        │   IDLE   │ ◄──────────────────────────┐
        └────┬─────┘                            │
             │ tap mic                          │
             ▼                                  │
        ┌──────────┐                            │
        │LISTENING │ ─── real-time transcript   │
        └────┬─────┘                            │
             │ stop / 3s silence                │
             ▼                                  │
      ┌─────────────┐                           │
      │TRANSCRIBING │                           │
      └──────┬──────┘                           │
             │ has content                      │
             ▼                                  │
        ┌──────────┐                            │
        │COUNTDOWN │ ─── 60 seconds             │
        └────┬─────┘                            │
             │                                  │
      ┌──────┴──────┐                           │
      │             │                           │
      ▼             ▼                           │
 ┌────────┐   ┌────────┐                        │
 │ VOIDED │   │ SAVED  │ (rescued as Gem)       │
 └────┬───┘   └────┬───┘                        │
      │            │                            │
      └────────────┴────────────────────────────┘
```

---

## Last Updated

**Date**: 2026-01-12  
**Commit**: Initial commit with speech engine integration


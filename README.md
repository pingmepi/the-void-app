# The Void

**The Void** is a privacy-first voice note app built with Flutter.

Spoken thoughts are captured, transcribed, and then **voided by default**:
after a short countdown (currently 10 seconds), your note is permanently
deleted unless you intentionally rescue it as a **Gem**.

---

## Core Ideas

- **Ephemeral by default** – notes auto-delete after a brief countdown
- **Intentional by choice** – you must actively rescue a note to keep it
- **Privacy-first** – volatile state lives in memory and is wiped when the app
  is backgrounded
- **Low friction** – one tap to start speaking, one tap to stop, one tap to
  rescue

---

## How It Works

1. **Tap the mic** to start recording.
2. The app listens and shows an **animated waveform** while you speak.
3. A **live transcript** appears and auto-scrolls so you can always see the
   last lines you spoke.
4. When you stop speaking (or tap the red stop button), recording ends.
5. If there is content, a **10-second countdown** starts – after that the note
   is **voided forever**.
6. During the countdown, you can **rescue** the note and save it as a **Gem**
   (encrypted in secure storage).

Automatic behavior:

- Recording can continue through natural pauses (up to ~5 seconds of silence)
- Maximum recording duration is capped at **2 minutes**

Manual overrides:

- Tapping the **red stop button** immediately stops speech recognition and
  moves you to processing/countdown
- Cancel flows can discard the current note entirely

---

## Feature Highlights

- 🎙️ Speech-to-text with partial (live) results
- 🔊 Animated waveform visualization while recording
- 🧠 Auto-scrolling transcript that keeps the latest lines in view
- ⏱️ Ephemeral 10-second countdown with rescue action
- 🪙 "Gems": intentionally saved notes stored with encrypted secure storage
- 📴 Privacy safeguards – wipes volatile data when the app is backgrounded

More implementation details and roadmap live in
[`PROGRESS.md`](./PROGRESS.md).

---

## Tech Stack

- **Framework**: Flutter
- **State management**: Riverpod (`flutter_riverpod` + `riverpod_annotation`)
- **Speech recognition**: `speech_to_text`
- **Secure storage**: `flutter_secure_storage`
- **Permissions**: `permission_handler`

---

## Getting Started

### Prerequisites

- Flutter installed and configured
- For macOS/iOS: Xcode + CocoaPods
- For Web: recent Chrome browser

### Setup

From the project root:

```bash
flutter pub get

# Generate code (Freezed models, Riverpod providers)
dart run build_runner build --delete-conflicting-outputs
```

### Run the App

Web (Chrome):

```bash
flutter run -d chrome
```

macOS (desktop):

```bash
flutter run -d macos
```

Other platforms (iOS/Android) will work once their respective toolchains are
configured.

---

## Project Structure (High Level)

- `lib/main.dart` – app entrypoint, theme, and `ProviderScope`
- `lib/controllers/` – app state (void flow, speech bridge, lifecycle, gems)
- `lib/models/` – Freezed data models (`VoidSession`, `GemNote`, etc.)
- `lib/services/` – speech-to-text + secure storage
- `lib/screens/void_screen.dart` – main user experience
- `lib/widgets/` – timer, transcript display, waveform visualizer

For a deeper, dev-focused view of the architecture and roadmap, see
[`PROGRESS.md`](./PROGRESS.md).

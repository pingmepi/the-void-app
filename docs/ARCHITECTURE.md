# Architecture

## Overview

The Void is a Flutter app with a strict layered architecture: **Screens → Controllers (Riverpod) → Services → External**. Data flows down through providers; events flow up through method calls.

---

## State Machine

The core of the app is a finite state machine in `VoidController`:

```
┌──────┐
│ IDLE │◄────────────────────────────┐
└──┬───┘                             │
   │ tap mic                         │
   ▼                                 │
┌───────────┐                        │
│ LISTENING │── real-time transcript  │
└──┬────────┘                        │
   │ 5s silence / manual stop        │
   ▼                                 │
┌──────────────┐                     │
│ TRANSCRIBING │                     │
└──┬───────────┘                     │
   │ has content                     │
   ▼                                 │
┌───────────┐                        │
│ COUNTDOWN │── 10 seconds           │
└──┬────────┘                        │
   │                                 │
   ├──→ VOIDED ──────────────────────┘  (auto, memory wiped)
   │
   └──→ SAVED  ──────────────────────┘  (rescue button, gem persisted)
```

`VoidState` enum lives in `lib/models/void_state.dart` with extension methods (`isRecording`, `canRescue`, `isCountdownActive`) that drive UI visibility. UI code should use these extensions, not raw enum comparisons.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────────────┐
│  SCREENS (UI)                                           │
│  VoidScreen │ GemsScreen │ GemDetailScreen │ LoginScreen│
├─────────────────────────────────────────────────────────┤
│  WIDGETS                                                │
│  GlowingMicButton │ VoidTimer │ Waveform │ GemCard     │
├─────────────────────────────────────────────────────────┤
│  CONTROLLERS (Riverpod StateNotifier)                   │
│  VoidController    — state machine, countdown timer     │
│  SpeechController  — bridges speech service ↔ void ctrl │
│  GemsController    — gem CRUD, Supabase sync            │
│  AuthController    — auth state providers               │
│  AppLifecycleCtrl  — wipes volatile data on background  │
├─────────────────────────────────────────────────────────┤
│  SERVICES                                               │
│  SpeechService     — wraps speech_to_text               │
│  RecordingService  — parallel audio capture             │
│  StorageService    — flutter_secure_storage + Supabase  │
│  AuthService       — email/password + OAuth (Google, Apple) │
│  SupabaseService   — Supabase client singleton          │
├─────────────────────────────────────────────────────────┤
│  EXTERNAL                                               │
│  Supabase (Auth + Postgres DB + Storage buckets)        │
│  Device microphone (via speech_to_text + record)        │
└─────────────────────────────────────────────────────────┘
```

---

## Data Model Split

There are two intentionally separate data types:

### VoidSession (volatile, RAM-only)
Defined in `lib/models/gem_note.dart`. Lives only in memory, wiped on app background.

Fields: `transcript`, `startedAt`, `countdownSeconds`, `audioBytes`, `audioMimeType`

**Rule**: Never persist VoidSession to storage.

### GemNote (persistent, encrypted)
Freezed model in `lib/models/gem_note.dart`. Stored via flutter_secure_storage (AES-encrypted).

Fields: `id` (UUID), `transcript`, `savedAt`, `title?`, `durationSeconds?`, `tags`, `userId?`, `audioUrl?`

**Rule**: Never hold GemNote in unencrypted memory longer than necessary.

---

## Auth & Sync Flow

```
User taps "Rescue" during countdown
        │
        ▼
┌─────────────────┐     ┌──────────────────────┐
│ Is user signed   │─No─→│ Show AuthScreen       │
│ in?              │     │ (bottom sheet)        │
└────────┬────────┘     └──────────┬───────────┘
         │ Yes                      │ OAuth complete
         ▼                          ▼
┌─────────────────────────────────────────────┐
│ Save gem locally (encrypted)                │
│ Sync to Supabase DB + upload audio          │
└─────────────────────────────────────────────┘
```

### Web OAuth Redirect Survival
On web, OAuth redirects away from the app. To preserve the in-progress transcript:
1. Before redirect: persist transcript + timestamp to secure storage as "pending rescue"
2. On return: check for pending rescue, verify < 5 minutes old, resume save flow
3. If > 5 minutes or user never returns: auto-clear the pending rescue

---

## Navigation

Simple `Navigator.push` (MaterialPageRoute). No router package — the app is small.

```
VoidScreen (home)
  ├──→ GemsScreen (tap nav button, signed in)
  │      └──→ GemDetailScreen (tap a gem)
  ├──→ LoginScreen (tap nav button, signed out)
  └──→ AuthScreen (bottom sheet, during rescue)
```

---

## Configuration

Credentials are injected at compile time, never hardcoded:

```
.env.json (gitignored)          →  --dart-define-from-file  →  AppConfig
  SUPABASE_URL                       String.fromEnvironment        .supabaseUrl
  SUPABASE_ANON_KEY                  String.fromEnvironment        .supabaseAnonKey
```

A runtime guard in `main.dart` checks `AppConfig.isConfigured` and throws `StateError` if credentials are missing. This works in release builds (unlike `assert`).

---

## Testing Strategy

All tests run without Supabase, platform channels, or network:

- **FakeStorageService** (`test/helpers/fake_storage_service.dart`): in-memory subclass of StorageService. Passes `const FlutterSecureStorage()` to super (constructor is safe — platform channels only fire on method calls, all overridden).
- **Provider overrides**: tests use `ProviderScope` overrides to inject fakes.
- **AuthService safety**: `currentUser` getter is wrapped in try-catch so it returns null when Supabase isn't initialized (always the case in tests).

Test breakdown:
| File | Count | Type |
|------|-------|------|
| gems_controller_test.dart | 14 | Unit (ProviderContainer) |
| gem_card_test.dart | 7 | Widget |
| gems_screen_test.dart | 19 | Screen/integration |
| void_controller_countdown_test.dart | 2 | Unit |
| widget_test.dart | 1 | Smoke |

---

## Deployment

### Web (Railway)
Multi-stage Docker build: Flutter SDK builds web assets, nginx serves them with SPA fallback, gzip, security headers.

### Mobile
- **Android**: minSdk 23, release signing from `key.properties`, OAuth deep link via intent filter
- **iOS**: mic + speech permissions in Info.plist, OAuth URL scheme (`com.thevoidapp`)
- See `docs/app-store-submission.md` for full submission walkthrough.

---

## Database Migrations

Schema changes are managed via Supabase CLI migrations in `supabase/migrations/`. Files are timestamped SQL scripts, version-controlled in git.

### Applying migrations

```bash
# Link to your Supabase project (one-time)
supabase link --project-ref <your-project-ref>

# Push all pending migrations to remote
supabase db push
```

### Current migrations

| Migration | Purpose |
|-----------|---------|
| `create_gems_table` | `gems` table with RLS (users access own gems only), indexes on `user_id` and `saved_at` |
| `create_storage_bucket` | `gems-audio` private bucket with per-user folder policies |

### Creating new migrations

```bash
supabase migration new <descriptive_name>
# Edit the generated file in supabase/migrations/
# Commit, then supabase db push to apply
```

---

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Ephemeral by default | Core product philosophy — reduces digital clutter |
| 10-second countdown | Short enough to feel urgent, long enough to decide |
| RAM-only volatile data | Privacy guarantee — backgrounding = instant wipe |
| Local-first with optional sync | App must work fully offline; auth is never required |
| Riverpod StateNotifier (v1 API) | Project started before Riverpod 2.0 code gen was stable |
| No router package | Only 4 screens, Navigator.push is sufficient |
| flutter_secure_storage | AES encryption at rest on all platforms |
| Compile-time credential injection | Secrets never in source, never in bundle metadata |

# Known Issues & Fixes

Issues encountered during development, how they were resolved, and current workarounds.

---

## Resolved

### Pending rescue persists indefinitely after cancelled OAuth
**Problem**: When a user initiates OAuth during rescue but cancels, the transcript stays in flutter_secure_storage forever. On web, this is localStorage-backed (AES-encrypted but same-origin accessible).

**Fix**: Added 5-minute expiry in `GemsController._resumePendingRescue()`. If the pending rescue is older than 5 minutes and the user is still unauthenticated, it's cleared immediately.

**Commit**: `8641441` + `cdf01d7`

---

### `assert` in main.dart silently passes in release builds
**Problem**: `assert(AppConfig.isConfigured, ...)` is compiled out in release mode. Missing Supabase credentials cause silent failures instead of a clear crash.

**Fix**: Replaced with runtime `if (!AppConfig.isConfigured) throw StateError(...)` which works in both debug and release.

**File**: `lib/main.dart`

---

### Supabase.instance not initialized in tests
**Problem**: `AuthService.currentUser` accesses `supabase.auth.currentUser` which throws `AssertionError` when Supabase hasn't been initialized (always true in unit/widget tests).

**Fix**: Wrapped `currentUser` getter in try-catch — returns null if Supabase isn't initialized. Safe for tests and early app startup.

**File**: `lib/services/auth_service.dart`

---

### GemsController async constructor timing in tests
**Problem**: `GemsController` calls `_loadGems()` in its constructor (async). Tests using `FakeStorageService.withGems()` showed empty state because the async load hadn't completed.

**Fix**: Tests use `saveGem()` directly through the controller to populate state instead of relying on constructor-time `_loadGems()`. Only the explicit "gems loaded from storage on construction" test pre-seeds the fake and uses a multi-pump flush.

**File**: `test/gems_controller_test.dart`

---

### GemDetailScreen shows "Gem not found" in tests
**Problem**: Using `fake.saveGem(gem)` puts the gem in storage but NOT in the controller's in-memory state (since the controller reads storage async at construction). The detail screen reads from controller state, not storage.

**Fix**: Widget tests use `ProviderScope.containerOf(context).read(gemsControllerProvider.notifier).saveGem()` to add gems through the controller, ensuring both storage and in-memory state are in sync.

**File**: `test/gems_screen_test.dart`

---

### Double underscore lint warning
**Problem**: `separatorBuilder: (_, __) =>` triggers `unnecessary_underscores` lint in recent Dart versions.

**Fix**: Changed to `(_, _)`.

**Commit**: `75e48e0`

---

### Mac mic permission dialog mid-recording
**Problem**: On macOS systems where microphone access is set to "ask every time", the system permission dialog appears _after_ the user taps the mic button. By the time the user reads and approves the dialog, the recording start is delayed and — if the countdown has begun — the 10-second window can lapse before they can say anything.

**Fix**: Added `Permission.microphone.request()` call in `main()` on non-web platforms, immediately after Supabase initialises and before `runApp`. The dialog now appears at app launch rather than mid-flow, so by the time the user taps the mic the OS has already resolved the permission.

**File**: `lib/main.dart`

---

## Current Limitations

### No audio playback
GemNote has an `audioUrl` field and audio is captured during recording, but there's no playback UI. Audio is stored in Supabase Storage (when synced) but can't be played back from the app.

### Web: speech_to_text browser support
`speech_to_text` relies on the Web Speech API which has inconsistent support across browsers. Works reliably in Chrome. Safari and Firefox support varies.

### Web: flutter_secure_storage uses localStorage
On web, `flutter_secure_storage` is backed by localStorage with AES encryption. This is same-origin accessible — adequate for the threat model but not as isolated as native Keychain/Keystore.

### Flutter default app icon
The app still uses the default Flutter blue square icon. Needs a branded 1024x1024 PNG icon before store submission.

### No delete account flow
Apple App Store requires a way for users to delete their account. This needs a Supabase Edge Function for server-side user deletion (client-side `auth.admin.deleteUser` requires the service role key which must never be on-device).


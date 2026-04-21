import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/gem_note.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'auth_controller.dart';

/// Manages saved gems: local persistence + Supabase remote sync.
class GemsController extends StateNotifier<List<GemNote>> {
  GemsController(this._storageService, this._ref) : super([]) {
    _loadGems();
    // Re-sync when auth state transitions to signed-in. Without this, a user
    // who opens the app anonymously and logs in later never pulls their
    // existing Supabase gems, and any gem saved during the login flow only
    // shows up via the local append in [saveGem].
    _ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      if (next != null) {
        _loadGems();
      }
    });
  }

  final StorageService _storageService;
  final Ref _ref;

  /// Serializes [_loadGems] calls. The constructor call and the auth-listener
  /// call can otherwise overlap, causing an earlier run's `state =` to
  /// clobber a later run's merged result.
  Future<void>? _loadInFlight;

  /// On startup (and on sign-in): load local gems, then pull from Supabase if
  /// authenticated and merge. Also checks for a pending rescue (transcript
  /// saved before OAuth redirect).
  Future<void> _loadGems() {
    return _loadInFlight ??= _doLoadGems()
        .whenComplete(() => _loadInFlight = null);
  }

  Future<void> _doLoadGems() async {
    try {
      // 1. Load local cache immediately (works offline)
      final localGems = await _storageService.loadAllGems();
      // Merge with whatever is already in-memory so gems saved during this
      // session (e.g. the rescue-then-login path) aren't dropped.
      state = _mergeById(state, localGems);

      final userId = AuthService.userId;

      // 2. If authenticated, merge authoritative Supabase data over local.
      // Remote wins on conflict; local-only gems (e.g. saved offline or
      // pre-login) are preserved.
      if (userId != null) {
        final remoteGems =
            await _storageService.fetchGemsFromSupabase(userId);
        state = _mergeById(state, remoteGems);
      }

      // 3. Check for a pending rescue that survived a web OAuth redirect
      await _resumePendingRescue();
    } catch (e) {
      debugPrint('GemsController: _loadGems failed: $e');
    }
  }

  /// Merge two gem lists by id. Entries in [incoming] override entries in
  /// [existing] with the same id; ids only present in one list are kept.
  List<GemNote> _mergeById(List<GemNote> existing, List<GemNote> incoming) {
    final byId = <String, GemNote>{for (final g in existing) g.id: g};
    for (final g in incoming) {
      byId[g.id] = g;
    }
    return byId.values.toList();
  }

  /// If the user was redirected to OAuth mid-rescue, their transcript was
  /// persisted to secure storage. Resume the save now that they're back.
  ///
  /// Pending rescues expire after 30 minutes. If the user cancelled OAuth
  /// and never signed in, we clear the transcript rather than leaving
  /// private content in browser storage indefinitely.
  static const _pendingRescueExpiryMinutes = 5;

  Future<void> _resumePendingRescue() async {
    try {
      final pending = await _storageService.readPendingRescue();
      if (pending == null) return;

      // Always check expiry first — clear and bail if stale, regardless of
      // auth state. This prevents abandoned transcripts from sitting in
      // storage when the user cancelled OAuth and never came back.
      final savedAt = DateTime.tryParse(pending['savedAt'] as String? ?? '');
      if (savedAt == null ||
          DateTime.now().difference(savedAt).inMinutes >
              _pendingRescueExpiryMinutes) {
        await _storageService.clearPendingRescue();
        debugPrint('GemsController: pending rescue expired — cleared');
        return;
      }

      final userId = AuthService.userId;
      if (userId == null) return; // not yet signed in, rescue still within window

      // Clear first to prevent double-save on re-init
      await _storageService.clearPendingRescue();

      await saveGem(
        transcript: pending['transcript'] as String,
        durationSeconds: pending['durationSeconds'] as int?,
        // Audio bytes don't survive a page reload, so no audio here
      );

      debugPrint('GemsController: pending rescue saved successfully');
    } catch (e) {
      debugPrint('GemsController: _resumePendingRescue failed: $e');
    }
  }

  /// Save a gem locally, then upload audio + sync to Supabase if authenticated.
  Future<void> saveGem({
    required String transcript,
    String? title,
    int? durationSeconds,
    Uint8List? audioBytes,
    String? audioMimeType,
  }) async {
    final userId = AuthService.userId;

    final gem = GemNote(
      id: const Uuid().v4(),
      transcript: transcript,
      savedAt: DateTime.now(),
      title: title,
      durationSeconds: durationSeconds,
      userId: userId,
    );

    // 1. Save locally first — works offline, instant feedback
    await _storageService.saveGem(gem);
    state = [...state, gem];

    // 2. If authenticated, sync to Supabase
    if (userId != null) {
      try {
        String? audioUrl;

        // Upload audio file (non-fatal if it fails)
        if (audioBytes != null && audioMimeType != null) {
          audioUrl = await _storageService.uploadAudio(
            userId: userId,
            gemId: gem.id,
            audioBytes: audioBytes,
            mimeType: audioMimeType,
          );
        }

        // Upsert gem row with audioUrl
        final gemWithAudio = gem.copyWith(audioUrl: audioUrl);
        await _storageService.syncGemToSupabase(gemWithAudio);

        // Update local copy with audioUrl
        if (audioUrl != null) {
          await _storageService.saveGem(gemWithAudio);
          state = state
              .map((g) => g.id == gem.id ? gemWithAudio : g)
              .toList();
        }
      } catch (e) {
        debugPrint('GemsController: remote sync failed (gem saved locally): $e');
      }
    }
  }

  Future<void> deleteGem(String gemId) async {
    try {
      final gem = state.firstWhere((g) => g.id == gemId);
      await _storageService.deleteGem(gemId);

      if (gem.userId != null) {
        await _storageService.deleteGemFromSupabase(
            gemId, gem.userId!, gem.audioUrl);
      }

      state = state.where((g) => g.id != gemId).toList();
    } catch (e) {
      debugPrint('GemsController: deleteGem failed: $e');
      rethrow;
    }
  }

  Future<void> updateGemTitle(String gemId, String newTitle) async {
    try {
      final idx = state.indexWhere((g) => g.id == gemId);
      if (idx == -1) return;

      final updated = state[idx].copyWith(title: newTitle);
      await _storageService.saveGem(updated);

      if (updated.userId != null) {
        await _storageService.syncGemToSupabase(updated);
      }

      final newState = [...state];
      newState[idx] = updated;
      state = newState;
    } catch (e) {
      debugPrint('GemsController: updateGemTitle failed: $e');
      rethrow;
    }
  }

  /// Wipes all locally cached gems from secure storage and clears in-memory
  /// state. Called after a successful account deletion so transcripts don't
  /// remain visible on the same device.
  Future<void> clearAllLocalData() async {
    try {
      await _storageService.clearAllGems();
      state = [];
    } catch (e) {
      debugPrint('GemsController: clearAllLocalData failed: $e');
    }
  }

  GemNote? getGem(String gemId) {
    try {
      return state.firstWhere((g) => g.id == gemId);
    } catch (_) {
      return null;
    }
  }

  List<GemNote> getGemsSorted() {
    final sorted = [...state];
    sorted.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return sorted;
  }
}

final gemsControllerProvider =
    StateNotifierProvider<GemsController, List<GemNote>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return GemsController(storageService, ref);
});

final allGemsProvider = Provider<List<GemNote>>((ref) {
  return ref.watch(gemsControllerProvider);
});

final sortedGemsProvider = Provider<List<GemNote>>((ref) {
  return ref.watch(gemsControllerProvider.notifier).getGemsSorted();
});

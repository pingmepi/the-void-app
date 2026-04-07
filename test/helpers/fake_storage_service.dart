import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:the_void_app/models/gem_note.dart';
import 'package:the_void_app/services/storage_service.dart';

/// In-memory [StorageService] for tests.
///
/// Passes `const FlutterSecureStorage()` to `super()` — the constructor is
/// safe (no platform channel calls). Every method is overridden so the parent
/// body never executes, meaning no Supabase or secure storage interaction.
class FakeStorageService extends StorageService {
  final Map<String, GemNote> _gems;
  Map<String, dynamic>? _pendingRescue;

  FakeStorageService() : _gems = {}, super(const FlutterSecureStorage());

  FakeStorageService.withGems(List<GemNote> gems)
      : _gems = {for (final g in gems) g.id: g},
        super(const FlutterSecureStorage());

  // ─── Local storage overrides ──────────────────────────────────────────────

  @override
  Future<void> saveGem(GemNote gem) async => _gems[gem.id] = gem;

  @override
  Future<GemNote?> loadGem(String gemId) async => _gems[gemId];

  @override
  Future<List<GemNote>> loadAllGems() async => _gems.values.toList();

  @override
  Future<void> deleteGem(String gemId) async => _gems.remove(gemId);

  @override
  Future<void> clearAllGems() async => _gems.clear();

  // ─── Pending rescue overrides ─────────────────────────────────────────────

  @override
  Future<void> savePendingRescue({
    required String transcript,
    int? durationSeconds,
  }) async {
    _pendingRescue = {
      'transcript': transcript,
      'durationSeconds': durationSeconds,
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> readPendingRescue() async => _pendingRescue;

  @override
  Future<void> clearPendingRescue() async => _pendingRescue = null;

  // ─── Supabase overrides (no-ops) ──────────────────────────────────────────

  @override
  Future<String?> uploadAudio({
    required String userId,
    required String gemId,
    required Uint8List audioBytes,
    required String mimeType,
  }) async => null;

  @override
  Future<void> syncGemToSupabase(GemNote gem) async {}

  @override
  Future<List<GemNote>> fetchGemsFromSupabase(String userId) async => [];

  @override
  Future<void> deleteGemFromSupabase(
      String gemId, String userId, String? audioUrl) async {}
}

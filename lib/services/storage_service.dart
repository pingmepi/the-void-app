import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/gem_note.dart';
import 'supabase_service.dart';

/// Service for gem persistence — local secure storage + Supabase remote.
class StorageService {
  static const String _gemsKey = 'void_gems';
  static const String _gemPrefix = 'gem_';
  static const String _pendingRescueKey = 'pending_rescue';

  final FlutterSecureStorage _secureStorage;

  StorageService(this._secureStorage);

  // ─── Local secure storage ──────────────────────────────────────────────────

  Future<void> saveGem(GemNote gem) async {
    try {
      final key = '$_gemPrefix${gem.id}';
      await _secureStorage.write(key: key, value: jsonEncode(gem.toJson()));
      await _updateGemsIndex();
    } catch (e) {
      debugPrint('StorageService: saveGem failed: $e');
      rethrow;
    }
  }

  Future<GemNote?> loadGem(String gemId) async {
    try {
      final json = await _secureStorage.read(key: '$_gemPrefix$gemId');
      if (json != null) return GemNote.fromJson(jsonDecode(json));
      return null;
    } catch (e) {
      debugPrint('StorageService: loadGem failed: $e');
      return null;
    }
  }

  Future<List<GemNote>> loadAllGems() async {
    try {
      final gemsJson = await _secureStorage.read(key: _gemsKey);
      if (gemsJson == null) return [];

      final gemIds = List<String>.from(jsonDecode(gemsJson));
      final gems = <GemNote>[];
      for (final id in gemIds) {
        final gem = await loadGem(id);
        if (gem != null) gems.add(gem);
      }
      return gems;
    } catch (e) {
      debugPrint('StorageService: loadAllGems failed: $e');
      return [];
    }
  }

  Future<void> deleteGem(String gemId) async {
    try {
      await _secureStorage.delete(key: '$_gemPrefix$gemId');
      await _updateGemsIndex();
    } catch (e) {
      debugPrint('StorageService: deleteGem failed: $e');
      rethrow;
    }
  }

  Future<void> _updateGemsIndex() async {
    try {
      final all = await _secureStorage.readAll();
      final ids = all.keys
          .where((k) => k.startsWith(_gemPrefix))
          .map((k) => k.replaceFirst(_gemPrefix, ''))
          .toList();
      await _secureStorage.write(key: _gemsKey, value: jsonEncode(ids));
    } catch (e) {
      debugPrint('StorageService: _updateGemsIndex failed: $e');
    }
  }

  Future<void> clearAllGems() async {
    try {
      final all = await _secureStorage.readAll();
      for (final key in all.keys) {
        if (key.startsWith(_gemPrefix) || key == _gemsKey) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      debugPrint('StorageService: clearAllGems failed: $e');
      rethrow;
    }
  }

  // ─── Pending rescue (survives web OAuth redirect) ─────────────────────────

  /// Persist the current session data before an OAuth redirect on web.
  /// The transcript and duration are stored; audio bytes cannot survive a
  /// page reload so they are omitted (gem will be saved without audio).
  Future<void> savePendingRescue({
    required String transcript,
    int? durationSeconds,
  }) async {
    final data = jsonEncode({
      'transcript': transcript,
      'durationSeconds': durationSeconds,
      'savedAt': DateTime.now().toIso8601String(),
    });
    await _secureStorage.write(key: _pendingRescueKey, value: data);
  }

  /// Read and return pending rescue data, or null if none exists.
  Future<Map<String, dynamic>?> readPendingRescue() async {
    final json = await _secureStorage.read(key: _pendingRescueKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> clearPendingRescue() async {
    await _secureStorage.delete(key: _pendingRescueKey);
  }

  // ─── Supabase remote ───────────────────────────────────────────────────────

  /// Upload audio bytes to Supabase Storage.
  /// Returns a signed URL valid for [AppConfig.audioUrlExpirySeconds], or null
  /// if the upload fails (non-fatal — gem is saved without audio URL).
  Future<String?> uploadAudio({
    required String userId,
    required String gemId,
    required Uint8List audioBytes,
    required String mimeType,
  }) async {
    try {
      final ext = mimeType == 'audio/webm' ? 'webm' : 'm4a';
      final path = '$userId/$gemId.$ext';

      await supabase.storage.from(AppConfig.audioBucket).uploadBinary(
            path,
            audioBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      return await supabase.storage
          .from(AppConfig.audioBucket)
          .createSignedUrl(path, AppConfig.audioUrlExpirySeconds);
    } catch (e) {
      debugPrint('StorageService: uploadAudio failed: $e');
      return null; // non-fatal
    }
  }

  /// Upsert a gem row into the Supabase `gems` table.
  Future<void> syncGemToSupabase(GemNote gem) async {
    try {
      await supabase.from('gems').upsert({
        'id': gem.id,
        'user_id': gem.userId,
        'transcript': gem.transcript,
        'title': gem.title,
        'duration_seconds': gem.durationSeconds,
        'tags': gem.tags,
        'audio_url': gem.audioUrl,
        'saved_at': gem.savedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('StorageService: syncGemToSupabase failed: $e');
      rethrow;
    }
  }

  /// Fetch all gems for [userId] from Supabase, sorted newest-first.
  Future<List<GemNote>> fetchGemsFromSupabase(String userId) async {
    try {
      final response = await supabase
          .from('gems')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      return (response as List<dynamic>).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        // Map snake_case DB columns → camelCase Freezed fields
        return GemNote(
          id: map['id'] as String,
          transcript: map['transcript'] as String,
          savedAt: DateTime.parse(map['saved_at'] as String),
          title: map['title'] as String?,
          durationSeconds: map['duration_seconds'] as int?,
          tags: (map['tags'] as List<dynamic>?)
                  ?.map((t) => t as String)
                  .toList() ??
              [],
          userId: map['user_id'] as String?,
          audioUrl: map['audio_url'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('StorageService: fetchGemsFromSupabase failed: $e');
      return [];
    }
  }

  /// Delete a gem from Supabase and its audio file from Storage.
  Future<void> deleteGemFromSupabase(
      String gemId, String userId, String? audioUrl) async {
    try {
      await supabase.from('gems').delete().eq('id', gemId);

      if (audioUrl != null) {
        // Determine extension from URL
        final ext = audioUrl.contains('.webm') ? 'webm' : 'm4a';
        await supabase.storage
            .from(AppConfig.audioBucket)
            .remove(['$userId/$gemId.$ext']);
      }
    } catch (e) {
      debugPrint('StorageService: deleteGemFromSupabase failed: $e');
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  const secureStorage = FlutterSecureStorage();
  return StorageService(secureStorage);
});

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/gem_note.dart';

/// Service for secure storage of gems
class StorageService {
  static const String _gemsKey = 'void_gems';
  static const String _gemPrefix = 'gem_';

  final FlutterSecureStorage _secureStorage;

  StorageService(this._secureStorage);

  /// Save a single gem to secure storage
  Future<void> saveGem(GemNote gem) async {
    try {
      final key = '$_gemPrefix${gem.id}';
      final json = jsonEncode(gem.toJson());
      await _secureStorage.write(key: key, value: json);
      
      // Update gems index
      await _updateGemsIndex();
    } catch (e) {
      print('Error saving gem to storage: $e');
      rethrow;
    }
  }

  /// Load a single gem by ID
  Future<GemNote?> loadGem(String gemId) async {
    try {
      final key = '$_gemPrefix$gemId';
      final json = await _secureStorage.read(key: key);
      if (json != null) {
        return GemNote.fromJson(jsonDecode(json));
      }
      return null;
    } catch (e) {
      print('Error loading gem from storage: $e');
      return null;
    }
  }

  /// Load all gems
  Future<List<GemNote>> loadAllGems() async {
    try {
      final gemsJson = await _secureStorage.read(key: _gemsKey);
      if (gemsJson == null) {
        return [];
      }

      final gemIds = List<String>.from(jsonDecode(gemsJson));
      final gems = <GemNote>[];

      for (final gemId in gemIds) {
        final gem = await loadGem(gemId);
        if (gem != null) {
          gems.add(gem);
        }
      }

      return gems;
    } catch (e) {
      print('Error loading all gems: $e');
      return [];
    }
  }

  /// Delete a gem
  Future<void> deleteGem(String gemId) async {
    try {
      final key = '$_gemPrefix$gemId';
      await _secureStorage.delete(key: key);
      await _updateGemsIndex();
    } catch (e) {
      print('Error deleting gem: $e');
      rethrow;
    }
  }

  /// Update the gems index
  Future<void> _updateGemsIndex() async {
    try {
      final allEntries = await _secureStorage.readAll();
      final gemIds = allEntries.keys
          .where((key) => key.startsWith(_gemPrefix))
          .map((key) => key.replaceFirst(_gemPrefix, ''))
          .toList();

      final json = jsonEncode(gemIds);
      await _secureStorage.write(key: _gemsKey, value: json);
    } catch (e) {
      print('Error updating gems index: $e');
    }
  }

  /// Clear all gems (use with caution)
  Future<void> clearAllGems() async {
    try {
      final allEntries = await _secureStorage.readAll();
      for (final key in allEntries.keys) {
        if (key.startsWith(_gemPrefix) || key == _gemsKey) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      print('Error clearing gems: $e');
      rethrow;
    }
  }
}

/// Riverpod provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  const secureStorage = FlutterSecureStorage();
  return StorageService(secureStorage);
});


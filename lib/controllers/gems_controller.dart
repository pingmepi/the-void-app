import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/gem_note.dart';
import '../services/storage_service.dart';

/// Manages saved gems (persistent notes)
class GemsController extends StateNotifier<List<GemNote>> {
  GemsController(this._storageService) : super([]) {
    _loadGems();
  }

  final StorageService _storageService;

  /// Load all gems from secure storage
  Future<void> _loadGems() async {
    try {
      final gems = await _storageService.loadAllGems();
      state = gems;
    } catch (e) {
      debugPrint('Error loading gems: $e');
      state = [];
    }
  }

  /// Save a new gem
  Future<void> saveGem({
    required String transcript,
    String? title,
    int? durationSeconds,
  }) async {
    try {
      final gem = GemNote(
        id: const Uuid().v4(),
        transcript: transcript,
        savedAt: DateTime.now(),
        title: title,
        durationSeconds: durationSeconds,
      );

      // Save to secure storage
      await _storageService.saveGem(gem);

      // Update state
      state = [...state, gem];
    } catch (e) {
      debugPrint('Error saving gem: $e');
      rethrow;
    }
  }

  /// Delete a gem
  Future<void> deleteGem(String gemId) async {
    try {
      await _storageService.deleteGem(gemId);
      state = state.where((gem) => gem.id != gemId).toList();
    } catch (e) {
      debugPrint('Error deleting gem: $e');
      rethrow;
    }
  }

  /// Update a gem's title
  Future<void> updateGemTitle(String gemId, String newTitle) async {
    try {
      final gemIndex = state.indexWhere((gem) => gem.id == gemId);
      if (gemIndex != -1) {
        final updatedGem = state[gemIndex].copyWith(title: newTitle);
        await _storageService.saveGem(updatedGem);
        
        final newState = [...state];
        newState[gemIndex] = updatedGem;
        state = newState;
      }
    } catch (e) {
      debugPrint('Error updating gem: $e');
      rethrow;
    }
  }

  /// Get a specific gem by ID
  GemNote? getGem(String gemId) {
    try {
      return state.firstWhere((gem) => gem.id == gemId);
    } catch (e) {
      return null;
    }
  }

  /// Get all gems sorted by date (newest first)
  List<GemNote> getGemsSorted() {
    final sorted = [...state];
    sorted.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return sorted;
  }
}

/// Riverpod provider for GemsController
final gemsControllerProvider =
    StateNotifierProvider<GemsController, List<GemNote>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return GemsController(storageService);
});

/// Provider to get all gems
final allGemsProvider = Provider<List<GemNote>>((ref) {
  return ref.watch(gemsControllerProvider);
});

/// Provider to get gems sorted by date
final sortedGemsProvider = Provider<List<GemNote>>((ref) {
  final controller = ref.watch(gemsControllerProvider.notifier);
  return controller.getGemsSorted();
});


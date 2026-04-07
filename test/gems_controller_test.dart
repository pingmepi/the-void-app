import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_void_app/controllers/gems_controller.dart';
import 'package:the_void_app/models/gem_note.dart';
import 'package:the_void_app/services/storage_service.dart';

import 'helpers/fake_storage_service.dart';

void main() {
  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Create a container with an empty FakeStorageService.
  ProviderContainer makeContainer() {
    final fake = FakeStorageService();
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Flush the async _loadGems() that fires in the GemsController constructor.
  Future<void> flush() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Save a gem via the controller and return the created GemNote.
  Future<GemNote> saveAndGet(
    ProviderContainer container, {
    String transcript = 'hello world',
    String? title,
    int? durationSeconds,
  }) async {
    final notifier = container.read(gemsControllerProvider.notifier);
    await notifier.saveGem(
      transcript: transcript,
      title: title,
      durationSeconds: durationSeconds,
    );
    return container.read(gemsControllerProvider).last;
  }

  // ─── Tests ────────────────────────────────────────────────────────────────

  group('GemsController', () {
    test('initial state is empty list', () async {
      final container = makeContainer();
      await flush();
      expect(container.read(gemsControllerProvider), isEmpty);
    });

    test('saveGem adds a gem to state', () async {
      final container = makeContainer();
      await flush();

      await container
          .read(gemsControllerProvider.notifier)
          .saveGem(transcript: 'hello world');

      final gems = container.read(gemsControllerProvider);
      expect(gems, hasLength(1));
      expect(gems.first.transcript, 'hello world');
    });

    test('saveGem stores durationSeconds', () async {
      final container = makeContainer();
      await flush();

      await container
          .read(gemsControllerProvider.notifier)
          .saveGem(transcript: 'test', durationSeconds: 42);

      expect(
        container.read(gemsControllerProvider).first.durationSeconds,
        42,
      );
    });

    test('saveGem persists to storage', () async {
      final fake = FakeStorageService();
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      await flush();

      await container
          .read(gemsControllerProvider.notifier)
          .saveGem(transcript: 'persisted');

      final stored = await fake.loadAllGems();
      expect(stored, hasLength(1));
      expect(stored.first.transcript, 'persisted');
    });

    test('deleteGem removes gem from state', () async {
      final container = makeContainer();
      await flush();

      final gem = await saveAndGet(container, transcript: 'to delete');
      expect(container.read(gemsControllerProvider), hasLength(1));

      await container
          .read(gemsControllerProvider.notifier)
          .deleteGem(gem.id);

      expect(container.read(gemsControllerProvider), isEmpty);
    });

    test('deleteGem throws when gemId not found', () async {
      final container = makeContainer();
      await flush();

      expect(
        () => container
            .read(gemsControllerProvider.notifier)
            .deleteGem('nonexistent'),
        throwsStateError,
      );
    });

    test('updateGemTitle changes title in state', () async {
      final container = makeContainer();
      await flush();

      final gem = await saveAndGet(container);
      expect(gem.title, isNull);

      await container
          .read(gemsControllerProvider.notifier)
          .updateGemTitle(gem.id, 'New Title');

      expect(
        container.read(gemsControllerProvider).first.title,
        'New Title',
      );
    });

    test('updateGemTitle on missing id is a no-op', () async {
      final container = makeContainer();
      await flush();

      await saveAndGet(container);

      await container
          .read(gemsControllerProvider.notifier)
          .updateGemTitle('does-not-exist', 'title');

      // Original gem unchanged
      expect(
        container.read(gemsControllerProvider).first.title,
        isNull,
      );
    });

    test('getGem returns gem when present', () async {
      final container = makeContainer();
      await flush();

      final gem = await saveAndGet(container);

      final result = container
          .read(gemsControllerProvider.notifier)
          .getGem(gem.id);
      expect(result, isNotNull);
      expect(result!.id, gem.id);
    });

    test('getGem returns null when absent', () async {
      final container = makeContainer();
      await flush();

      final result = container
          .read(gemsControllerProvider.notifier)
          .getGem('missing');
      expect(result, isNull);
    });

    test('getGemsSorted returns newest first', () async {
      final container = makeContainer();
      await flush();

      final notifier = container.read(gemsControllerProvider.notifier);
      await notifier.saveGem(transcript: 'old');
      // Small delay so savedAt differs
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await notifier.saveGem(transcript: 'new');

      final sorted = notifier.getGemsSorted();
      expect(sorted.first.transcript, 'new');
      expect(sorted.last.transcript, 'old');
    });

    test('sortedGemsProvider returns newest first', () async {
      final container = makeContainer();
      await flush();

      final notifier = container.read(gemsControllerProvider.notifier);
      await notifier.saveGem(transcript: 'old');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await notifier.saveGem(transcript: 'new');

      final sorted = container.read(sortedGemsProvider);
      expect(sorted.first.transcript, 'new');
      expect(sorted.last.transcript, 'old');
    });

    test('allGemsProvider reflects full list', () async {
      final container = makeContainer();
      await flush();

      await saveAndGet(container);

      final all = container.read(allGemsProvider);
      expect(all, hasLength(1));
    });

    test('gems loaded from storage on construction', () async {
      // Pre-populate the fake, then create a NEW container that reads it
      final fake = FakeStorageService();
      await fake.saveGem(GemNote(
        id: 'pre-a',
        transcript: 'pre-saved A',
        savedAt: DateTime(2026, 1, 1),
      ));
      await fake.saveGem(GemNote(
        id: 'pre-b',
        transcript: 'pre-saved B',
        savedAt: DateTime(2026, 2, 1),
      ));

      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      // Force the provider to be created and flush its async init
      container.read(gemsControllerProvider);
      await flush();

      final gems = container.read(gemsControllerProvider);
      expect(gems, hasLength(2));
    });
  });
}

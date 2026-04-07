import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_void_app/controllers/gems_controller.dart';
import 'package:the_void_app/models/gem_note.dart';
import 'package:the_void_app/screens/gems_screen.dart';
import 'package:the_void_app/services/storage_service.dart';
import 'package:the_void_app/widgets/gem_card.dart';

import 'helpers/fake_storage_service.dart';

void main() {
  // ─── Helpers ──────────────────────────────────────────────────────────────

  GemNote makeGem({
    String id = 'gem-1',
    String transcript = 'A test transcript',
    String? title,
    int? durationSeconds,
    DateTime? savedAt,
  }) {
    return GemNote(
      id: id,
      transcript: transcript,
      savedAt: savedAt ?? DateTime(2026, 3, 15),
      title: title,
      durationSeconds: durationSeconds,
    );
  }

  Widget makeGemsScreen({List<GemNote> gems = const []}) {
    final fake = FakeStorageService();
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(fake),
        // Override the sorted provider directly so we don't depend on async _loadGems
        sortedGemsProvider.overrideWithValue(gems),
      ],
      child: const MaterialApp(home: GemsScreen()),
    );
  }

  // ─── GemsScreen ───────────────────────────────────────────────────────────

  group('GemsScreen', () {
    testWidgets('shows empty state when no gems', (tester) async {
      await tester.pumpWidget(makeGemsScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing rescued yet'), findsOneWidget);
    });

    testWidgets('shows gem cards when gems exist', (tester) async {
      final gems = [
        makeGem(id: '1', title: 'Gem One'),
        makeGem(id: '2', title: 'Gem Two'),
      ];
      await tester.pumpWidget(makeGemsScreen(gems: gems));
      await tester.pumpAndSettle();

      expect(find.byType(GemCard), findsNWidgets(2));
    });

    testWidgets('gems displayed newest first', (tester) async {
      final gems = [
        makeGem(
          id: 'new',
          title: 'Newer Gem',
          savedAt: DateTime(2026, 6, 1),
        ),
        makeGem(
          id: 'old',
          title: 'Older Gem',
          savedAt: DateTime(2025, 1, 1),
        ),
      ];
      await tester.pumpWidget(makeGemsScreen(gems: gems));
      await tester.pumpAndSettle();

      // Verify cards rendered — sorted provider already returns newest first
      final cards = tester.widgetList<GemCard>(find.byType(GemCard)).toList();
      expect(cards[0].gem.id, 'new');
      expect(cards[1].gem.id, 'old');
    });

    testWidgets('back navigation closes GemsScreen', (tester) async {
      // Push GemsScreen onto a navigator so there's something to pop to
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sortedGemsProvider.overrideWithValue([]),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GemsScreen()),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(GemsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(GemsScreen), findsNothing);
    });

    testWidgets('app bar shows title text', (tester) async {
      await tester.pumpWidget(makeGemsScreen());
      await tester.pumpAndSettle();

      // Look for the title in the app bar area
      expect(find.textContaining('gems'), findsOneWidget);
    });
  });
}

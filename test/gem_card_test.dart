import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_void_app/models/gem_note.dart';
import 'package:the_void_app/widgets/gem_card.dart';

void main() {
  Widget makeCard({
    required GemNote gem,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GemCard(
          gem: gem,
          onTap: onTap ?? () {},
          onDelete: onDelete ?? () {},
        ),
      ),
    );
  }

  GemNote makeGem({
    String transcript = 'Short transcript',
    String? title,
    int? durationSeconds,
    DateTime? savedAt,
  }) {
    return GemNote(
      id: 'test-gem',
      transcript: transcript,
      savedAt: savedAt ?? DateTime(2026, 3, 15),
      title: title,
      durationSeconds: durationSeconds,
    );
  }

  group('GemCard', () {
    testWidgets('shows truncated transcript when no title', (tester) async {
      final long = 'A' * 80;
      await tester.pumpWidget(makeCard(gem: makeGem(transcript: long)));

      // Should show first 60 chars, not the full 80
      expect(find.textContaining('A' * 60), findsOneWidget);
    });

    testWidgets('shows title when set', (tester) async {
      await tester.pumpWidget(makeCard(
        gem: makeGem(title: 'My Title', transcript: 'some text'),
      ));

      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('shows formatted date', (tester) async {
      await tester.pumpWidget(makeCard(
        gem: makeGem(savedAt: DateTime(2026, 3, 15)),
      ));

      expect(find.textContaining('Mar'), findsOneWidget);
      expect(find.textContaining('15'), findsOneWidget);
    });

    testWidgets('shows duration chip when durationSeconds set', (tester) async {
      await tester.pumpWidget(makeCard(
        gem: makeGem(durationSeconds: 90),
      ));

      expect(find.byKey(const Key('gem_duration')), findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);
    });

    testWidgets('duration chip absent when durationSeconds null',
        (tester) async {
      await tester.pumpWidget(makeCard(gem: makeGem()));

      expect(find.byKey(const Key('gem_duration')), findsNothing);
    });

    testWidgets('calls onTap when card tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(makeCard(
        gem: makeGem(),
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(GemCard));
      expect(tapped, isTrue);
    });

    testWidgets('calls onDelete when delete icon pressed', (tester) async {
      var deleted = false;
      await tester.pumpWidget(makeCard(
        gem: makeGem(),
        onDelete: () => deleted = true,
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, isTrue);
    });
  });
}

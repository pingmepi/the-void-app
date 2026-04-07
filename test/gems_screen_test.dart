import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_void_app/controllers/auth_controller.dart';
import 'package:the_void_app/controllers/gems_controller.dart';
import 'package:the_void_app/models/gem_note.dart';
import 'package:the_void_app/screens/gem_detail_screen.dart';
import 'package:the_void_app/screens/gems_screen.dart';
import 'package:the_void_app/screens/login_screen.dart';
import 'package:the_void_app/screens/void_screen.dart';
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

  // ─── GemDetailScreen ────────────────────────────────────────────────────

  group('GemDetailScreen', () {
    /// Helper: push GemDetailScreen with a pre-populated gem in the controller.
    Widget makeDetailScreen({
      required GemNote gem,
    }) {
      final fake = FakeStorageService();
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(fake),
          // Pre-populate the controller state with the gem
          gemsControllerProvider.overrideWith((ref) {
            final controller = GemsController(fake);
            // Directly set the state via saveGem after construction
            return controller;
          }),
        ],
        child: MaterialApp(
          home: _DetailScreenLoader(gem: gem),
        ),
      );
    }

    testWidgets('shows full transcript', (tester) async {
      final gem = makeGem(transcript: 'Full transcript text here');
      await tester.pumpWidget(makeDetailScreen(gem: gem));
      await tester.pumpAndSettle();

      expect(find.textContaining('Full transcript text here'), findsOneWidget);
    });

    testWidgets('shows title when set', (tester) async {
      final gem = makeGem(title: 'My Gem Title');
      await tester.pumpWidget(makeDetailScreen(gem: gem));
      await tester.pumpAndSettle();

      expect(find.text('My Gem Title'), findsOneWidget);
    });

    testWidgets('shows hint when no title', (tester) async {
      final gem = makeGem(title: null);
      await tester.pumpWidget(makeDetailScreen(gem: gem));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tap to name'), findsOneWidget);
    });

    testWidgets('tapping title area reveals TextField', (tester) async {
      final gem = makeGem(title: null);
      await tester.pumpWidget(makeDetailScreen(gem: gem));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gem_title_display')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final gem = makeGem();
      await tester.pumpWidget(makeDetailScreen(gem: gem));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete this gem?'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog leaves screen intact',
        (tester) async {
      final gem = makeGem();
      await tester.pumpWidget(makeDetailScreen(gem: gem));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      expect(find.byType(GemDetailScreen), findsOneWidget);
    });

    testWidgets('back button pops GemDetailScreen', (tester) async {
      final gem = makeGem();
      final fake = FakeStorageService();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(fake),
          gemsControllerProvider.overrideWith((ref) => GemsController(fake)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                // Save gem to the controller via the notifier
                final container = ProviderScope.containerOf(context);
                await container
                    .read(gemsControllerProvider.notifier)
                    .saveGem(transcript: gem.transcript);
                final gems = container.read(gemsControllerProvider);
                if (context.mounted && gems.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GemDetailScreen(gemId: gems.first.id),
                    ),
                  );
                }
              },
              child: const Text('Go'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(GemDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(GemDetailScreen), findsNothing);
    });
  });

  // ─── LoginScreen ──────────────────────────────────────────────────────────

  group('LoginScreen', () {
    testWidgets('shows Google and Apple sign-in buttons', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Google'), findsOneWidget);
      expect(find.textContaining('Apple'), findsOneWidget);
    });

    testWidgets('"Maybe later" button pops screen', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.textContaining('Maybe later'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  // ─── VoidScreen nav button ────────────────────────────────────────────────

  group('VoidScreen nav button', () {
    testWidgets('nav button visible on landing state', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sortedGemsProvider.overrideWithValue([]),
        ],
        child: const MaterialApp(home: VoidScreen()),
      ));
      await tester.pump();

      expect(find.byKey(const Key('gems_nav_button')), findsOneWidget);
    });

    testWidgets('shows gem count when gems > 0', (tester) async {
      final gems = [
        makeGem(id: '1'),
        makeGem(id: '2'),
        makeGem(id: '3'),
      ];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sortedGemsProvider.overrideWithValue(gems),
        ],
        child: const MaterialApp(home: VoidScreen()),
      ));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides count when 0 gems', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sortedGemsProvider.overrideWithValue([]),
        ],
        child: const MaterialApp(home: VoidScreen()),
      ));
      await tester.pump();

      // The nav button exists but no count text
      expect(find.byKey(const Key('gems_nav_button')), findsOneWidget);
      // No digit text within the button area
      expect(find.text('0'), findsNothing);
    });

    testWidgets('tapping nav button navigates to GemsScreen when logged in',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sortedGemsProvider.overrideWithValue([]),
          isLoggedInProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: VoidScreen()),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('gems_nav_button')));
      await tester.pumpAndSettle();

      expect(find.byType(GemsScreen), findsOneWidget);
    });

    testWidgets('tapping nav button navigates to LoginScreen when not logged in',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          sortedGemsProvider.overrideWithValue([]),
          isLoggedInProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: VoidScreen()),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('gems_nav_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

/// Helper widget that saves a gem to the controller, then shows GemDetailScreen.
class _DetailScreenLoader extends ConsumerStatefulWidget {
  const _DetailScreenLoader({required this.gem});
  final GemNote gem;

  @override
  ConsumerState<_DetailScreenLoader> createState() =>
      _DetailScreenLoaderState();
}

class _DetailScreenLoaderState extends ConsumerState<_DetailScreenLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadGem();
  }

  Future<void> _loadGem() async {
    await ref.read(gemsControllerProvider.notifier).saveGem(
          transcript: widget.gem.transcript,
          title: widget.gem.title,
          durationSeconds: widget.gem.durationSeconds,
        );
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final gems = ref.watch(gemsControllerProvider);
    if (gems.isEmpty) return const SizedBox.shrink();
    return GemDetailScreen(gemId: gems.first.id);
  }
}

// This is a basic Flutter widget test for The Void app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_void_app/main.dart';

void main() {
  testWidgets('The Void app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TheVoidApp()));

    // Verify that the landing screen tagline is present
    expect(find.text('LISTEN TO THE'), findsOneWidget);
    expect(find.text('what remains.'), findsOneWidget);
  });
}

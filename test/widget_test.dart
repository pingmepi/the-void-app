// This is a basic Flutter widget test for The Void app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_void_app/main.dart';

void main() {
  testWidgets('The Void app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TheVoidApp()));

    // Verify that the app title is present
    expect(find.text('The Void'), findsWidgets);
    expect(find.text('Ready'), findsOneWidget);
  });
}

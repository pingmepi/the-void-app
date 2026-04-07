// This is a basic Flutter widget test for The Void app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_void_app/main.dart';

void main() {
  testWidgets('The Void app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TheVoidApp()));
    await tester.pump();

    // Idle state shows the landing screen tagline and mic icon
    expect(find.text('LISTEN TO THE'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}

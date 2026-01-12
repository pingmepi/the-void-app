import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/void_screen.dart';
import 'controllers/app_lifecycle_controller.dart';

void main() {
  runApp(const ProviderScope(child: TheVoidApp()));
}

class TheVoidApp extends ConsumerWidget {
  const TheVoidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize app lifecycle monitoring
    ref.watch(appLifecycleProvider);

    return MaterialApp(
      title: 'The Void',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const VoidScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


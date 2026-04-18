import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'controllers/app_lifecycle_controller.dart';
import 'screens/void_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hard runtime guard — works in debug AND release builds.
  // assert() is compiled away in release; this is not.
  if (!AppConfig.isConfigured) {
    throw StateError(
      'Missing Supabase credentials. '
      'Build with --dart-define-from-file=.env.json '
      '(copy .env.json.example → .env.json and fill in your values).',
    );
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Pre-warm microphone permission on supported native platforms before the
  // user taps the mic button. On macOS some users have "ask every time" set —
  // requesting upfront means the dialog appears at launch (expected), not
  // mid-recording when the 10-second countdown is already running.
  // Web handles mic access natively via the browser getUserMedia prompt.
  // Linux is excluded: permission_handler has no Linux plugin registration.
  if (!kIsWeb &&
      (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
    await Permission.microphone.request();
  }

  runApp(const ProviderScope(child: TheVoidApp()));
}

/// App color constants - dark ethereal theme
class VoidColors {
  VoidColors._();

  // Background colors - deep navy/purple
  static const Color background = Color(0xFF0D0B14);
  static const Color backgroundLight = Color(0xFF151221);

  // Primary accent - ethereal green/teal
  static const Color accent = Color(0xFF7FFFD4); // Aquamarine
  static const Color accentDim = Color(0xFF4A9B8C);
  static const Color accentGlow = Color(0xFF00FF9D);

  // Text colors
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textFaded = Color(0xFF4A4A5E);
  static const Color textGhost = Color(0xFF2A2A3E);
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
          seedColor: VoidColors.accent,
          brightness: Brightness.dark,
          surface: VoidColors.background,
          primary: VoidColors.accent,
          onPrimary: VoidColors.background,
          onSurface: VoidColors.textPrimary,
          onSurfaceVariant: VoidColors.textSecondary,
        ),
        scaffoldBackgroundColor: VoidColors.background,
        fontFamily: 'serif',
      ),
      home: const VoidScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

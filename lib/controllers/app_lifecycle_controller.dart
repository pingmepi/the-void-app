import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'void_controller.dart';

/// Monitors app lifecycle and triggers privacy actions
/// When app is backgrounded, immediately wipes volatile data
class AppLifecycleController extends WidgetsBindingObserver {
  final Ref _ref;

  AppLifecycleController(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is backgrounded or closing - wipe memory immediately
        _wipeOnBackground();
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground
        break;
      case AppLifecycleState.inactive:
        // App is transitioning
        break;
      case AppLifecycleState.hidden:
        // App is hidden (for multi-window scenarios)
        _wipeOnBackground();
        break;
    }
  }

  /// Wipe all volatile data when app goes to background
  void _wipeOnBackground() {
    final controller = _ref.read(voidControllerProvider.notifier);

    // If there's an active session, void it immediately
    if (controller.currentSession != null) {
      controller.voidNote();
    }
  }

  /// Dispose and remove observer
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Provider to initialize app lifecycle monitoring
final appLifecycleProvider = Provider<AppLifecycleController>((ref) {
  final controller = AppLifecycleController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});


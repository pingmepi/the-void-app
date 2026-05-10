import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/void_state.dart';
import '../services/speech_service.dart';
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
        _onResume();
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

  /// Cancel or wipe volatile data when app goes to background.
  /// Mid-COUNTDOWN → cancel to IDLE (not VOIDED) per P0-3.
  /// Any other active session → void immediately.
  void _wipeOnBackground() {
    final controller = _ref.read(voidControllerProvider.notifier);
    final status = _ref.read(voidControllerProvider).status;

    if (status == VoidState.countdown) {
      controller.cancelCountdown();
    } else if (controller.currentSession != null) {
      controller.voidNote();
    }
  }

  /// Re-attempt speech initialization if the user returns from settings
  /// after installing an on-device model.
  Future<void> _onResume() async {
    final status = _ref.read(voidControllerProvider).status;
    if (status == VoidState.errorNoOfflineModel) {
      final speech = _ref.read(speechServiceProvider);
      speech.dispose();
      final reinitialized = await speech.initialize();
      if (reinitialized && speech.hasOnDeviceModel) {
        _ref.read(voidControllerProvider.notifier).reset();
      }
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


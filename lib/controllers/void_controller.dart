import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/void_state.dart';
import '../models/gem_note.dart';

/// Central state manager for the Void app
/// Manages: speech state, timer, transcript, and memory wipe
class VoidController extends StateNotifier<VoidState> {
  VoidController() : super(VoidState.idle) {
    _initializeCountdownTimer();
  }

  /// Current session data (volatile, gets wiped)
  VoidSession? _currentSession;
  
  /// Countdown timer
  Timer? _countdownTimer;
  
  /// Listeners for state changes
  final List<VoidStateListener> _listeners = [];

  /// Get current session
  VoidSession? get currentSession => _currentSession;

  /// Get current transcript
  String get transcript => _currentSession?.transcript ?? '';

  /// Get remaining countdown seconds
  int? get countdownSeconds => _currentSession?.countdownSeconds;

  /// Start listening for voice input
  void startListening() {
    if (state == VoidState.idle) {
      _currentSession = VoidSession();
      state = VoidState.listening;
      _notifyVoidListeners();
    }
  }

  /// Stop listening and start transcribing
  void stopListening() {
    if (state == VoidState.listening) {
      state = VoidState.transcribing;
      _notifyVoidListeners();
    }
  }

  /// Update transcript with new text
  void updateTranscript(String text) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(transcript: text);
      _notifyVoidListeners();
    }
  }

  /// Start the 60-second countdown to void
  void startCountdown() {
    if (state == VoidState.transcribing) {
      _currentSession = _currentSession!.copyWith(countdownSeconds: 60);
      state = VoidState.countdown;
      _notifyVoidListeners();
      _startCountdownTimer();
    }
  }

  /// Rescue the note before it's voided (save as gem)
  void rescueNote(String? title) {
    if (state == VoidState.countdown && _currentSession != null) {
      // This will be handled by GemsController
      // For now, just transition to saved state
      state = VoidState.saved;
      _notifyVoidListeners();
    }
  }

  /// Void the note (permanent deletion)
  void voidNote() {
    if (state == VoidState.countdown) {
      _wipeMemory();
      state = VoidState.voided;
      _notifyVoidListeners();

      // Reset to idle after a brief moment
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state == VoidState.voided) {
          state = VoidState.idle;
          _notifyVoidListeners();
        }
      });
    }
  }

  /// Wipe all volatile data (privacy feature)
  void _wipeMemory() {
    _currentSession?.wipe();
    _currentSession = null;
    _countdownTimer?.cancel();
  }

  /// Initialize countdown timer
  void _initializeCountdownTimer() {
    // Timer will be started when countdown begins
  }

  /// Start the countdown timer
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _currentSession!.countdownSeconds! > 0) {
        _currentSession = _currentSession!.copyWith(
          countdownSeconds: _currentSession!.countdownSeconds! - 1,
        );
        _notifyVoidListeners();
      } else {
        // Time's up - void the note
        timer.cancel();
        voidNote();
      }
    });
  }

  /// Register a custom listener for state changes
  void addVoidListener(VoidStateListener listener) {
    _listeners.add(listener);
  }

  /// Remove a custom listener
  void removeVoidListener(VoidStateListener listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of state change
  void _notifyVoidListeners() {
    for (var listener in _listeners) {
      listener(state, _currentSession);
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _countdownTimer?.cancel();
    _wipeMemory();
    super.dispose();
  }
}

/// Callback type for state changes
typedef VoidStateListener = void Function(VoidState state, VoidSession? session);

/// Riverpod provider for VoidController
final voidControllerProvider =
    StateNotifierProvider<VoidController, VoidState>((ref) {
  return VoidController();
});

/// Provider to access current session
final currentSessionProvider = Provider<VoidSession?>((ref) {
  final controller = ref.watch(voidControllerProvider.notifier);
  return controller.currentSession;
});

/// Provider to access current transcript
final transcriptProvider = Provider<String>((ref) {
  final controller = ref.watch(voidControllerProvider.notifier);
  return controller.transcript;
});

/// Provider to access countdown seconds
final countdownSecondsProvider = Provider<int?>((ref) {
  final controller = ref.watch(voidControllerProvider.notifier);
  return controller.countdownSeconds;
});


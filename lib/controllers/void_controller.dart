import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/void_state.dart';
import '../models/gem_note.dart';

/// Riverpod-facing state for [VoidController].
///
/// We intentionally keep the current [VoidSession] in the provider state so the
/// UI rebuilds when countdown seconds / transcript change.
class VoidControllerViewState {
  final VoidState status;
  final VoidSession? session;

  const VoidControllerViewState({
    required this.status,
    this.session,
  });

  VoidControllerViewState copyWith({
    VoidState? status,
    VoidSession? session,
    bool clearSession = false,
  }) {
    return VoidControllerViewState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
    );
  }
}

/// Central state manager for the Void app
/// Manages: speech state, timer, transcript, and memory wipe
class VoidController extends StateNotifier<VoidControllerViewState> {
  VoidController() : super(const VoidControllerViewState(status: VoidState.idle)) {
    _initializeCountdownTimer();
  }
  
  /// Countdown timer
  Timer? _countdownTimer;
  
  /// Listeners for state changes
  final List<VoidStateListener> _listeners = [];

  /// Get current session
  VoidSession? get currentSession => state.session;

  /// Get current transcript
  String get transcript => state.session?.transcript ?? '';

  /// Get remaining countdown seconds
  int? get countdownSeconds => state.session?.countdownSeconds;

  /// Start listening for voice input
  void startListening() {
    if (state.status == VoidState.idle) {
      final session = VoidSession();
      state = state.copyWith(status: VoidState.listening, session: session);
      _notifyVoidListeners();
    }
  }

  /// Stop listening and start transcribing
  void stopListening() {
    if (state.status == VoidState.listening) {
      state = state.copyWith(status: VoidState.transcribing);
      _notifyVoidListeners();
    }
  }

  /// Update transcript with new text
  void updateTranscript(String text) {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(session: session.copyWith(transcript: text));
    _notifyVoidListeners();
  }

  /// Start the 10-second countdown to void
  void startCountdown() {
    if (state.status != VoidState.transcribing) return;
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(
      status: VoidState.countdown,
      session: session.copyWith(countdownSeconds: 10),
    );
    _notifyVoidListeners();
    _startCountdownTimer();
  }

  /// Rescue the note before it's voided (save as gem)
  void rescueNote(String? title) {
    if (state.status == VoidState.countdown && state.session != null) {
      // This will be handled by GemsController
      // For now, just transition to saved state
      _countdownTimer?.cancel();
      state = state.copyWith(status: VoidState.saved);
      _notifyVoidListeners();
    }
  }

  /// Void the note (permanent deletion)
  void voidNote() {
    if (state.status == VoidState.countdown) {
      _wipeMemory();
      state = state.copyWith(status: VoidState.voided, clearSession: true);
      _notifyVoidListeners();

      // Reset to idle after a brief moment
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state.status == VoidState.voided) {
          state = state.copyWith(status: VoidState.idle);
          _notifyVoidListeners();
        }
      });
    }
  }

  /// Wipe all volatile data (privacy feature)
  void _wipeMemory() {
    _countdownTimer?.cancel();
    state = state.copyWith(clearSession: true);
  }

  /// Initialize countdown timer
  void _initializeCountdownTimer() {
    // Timer will be started when countdown begins
  }

  /// Start the countdown timer
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final session = state.session;
      final remaining = session?.countdownSeconds;

      // If we've left countdown (e.g., rescued), stop ticking.
      if (state.status != VoidState.countdown) {
        timer.cancel();
        return;
      }

      // Countdown should always have a session + remaining seconds.
      // If it doesn't, fail closed and void.
      if (remaining == null || remaining <= 1) {
        // Time's up - void the note.
        timer.cancel();
        voidNote();
        return;
      }

      state = state.copyWith(
        session: session!.copyWith(countdownSeconds: remaining - 1),
      );
      _notifyVoidListeners();
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
      listener(state.status, state.session);
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
    StateNotifierProvider<VoidController, VoidControllerViewState>((ref) {
  return VoidController();
});

/// Provider to access current session
final currentSessionProvider = Provider<VoidSession?>((ref) {
  return ref.watch(voidControllerProvider.select((s) => s.session));
});

/// Provider to access current transcript
final transcriptProvider = Provider<String>((ref) {
  return ref.watch(
    voidControllerProvider.select((s) => s.session?.transcript ?? ''),
  );
});

/// Provider to access countdown seconds
final countdownSecondsProvider = Provider<int?>((ref) {
  return ref.watch(
    voidControllerProvider.select((s) => s.session?.countdownSeconds),
  );
});


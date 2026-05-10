import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gem_note.dart';
import '../models/void_state.dart';

/// Riverpod-facing state for [VoidController].
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

/// Central state manager for the Void app.
/// Manages: speech state, countdown timer, transcript, audio data, memory wipe.
class VoidController extends StateNotifier<VoidControllerViewState> {
  VoidController()
      : super(const VoidControllerViewState(status: VoidState.idle));

  Timer? _countdownTimer;
  bool _countdownPaused = false;

  /// Listeners for state changes (legacy support)
  final List<VoidStateListener> _listeners = [];

  VoidSession? get currentSession => state.session;
  String get transcript => state.session?.transcript ?? '';
  int? get countdownSeconds => state.session?.countdownSeconds;

  /// Transition to LISTENING and create a fresh session.
  void startListening() {
    if (state.status == VoidState.idle) {
      state = state.copyWith(
        status: VoidState.listening,
        session: VoidSession(),
      );
      _notifyVoidListeners();
    }
  }

  /// Transition LISTENING → TRANSCRIBING.
  void stopListening() {
    if (state.status == VoidState.listening) {
      state = state.copyWith(status: VoidState.transcribing);
      _notifyVoidListeners();
    }
  }

  /// Append / replace transcript text from the speech engine.
  void updateTranscript(String text) {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(session: session.copyWith(transcript: text));
    _notifyVoidListeners();
  }

  /// Transition TRANSCRIBING → COUNTDOWN and start the 10-second timer.
  /// [audioBytes] and [audioMimeType] are stored in the session for later upload.
  void startCountdown({Uint8List? audioBytes, String? audioMimeType}) {
    if (state.status != VoidState.transcribing) return;
    final session = state.session;
    if (session == null) return;

    _countdownPaused = false;
    state = state.copyWith(
      status: VoidState.countdown,
      session: session.copyWith(
        countdownSeconds: 10,
        audioBytes: audioBytes,
        audioMimeType: audioMimeType,
      ),
    );
    _notifyVoidListeners();
    _startCountdownTimer();
  }

  /// Pause the countdown (e.g. while the auth sheet is open).
  /// The timer keeps ticking internally but seconds stop decrementing.
  void pauseCountdown() {
    _countdownPaused = true;
  }

  /// Resume a previously paused countdown.
  void resumeCountdown() {
    _countdownPaused = false;
  }

  /// Transition COUNTDOWN → SAVED.
  /// Actual gem persistence is handled by the caller (void_screen rescue button)
  /// which has access to GemsController via Ref.
  void rescueNote(String? title) {
    if (state.status == VoidState.countdown && state.session != null) {
      _countdownTimer?.cancel();
      _countdownPaused = false;
      state = state.copyWith(status: VoidState.saved);
      _notifyVoidListeners();
    }
  }

  /// Transition COUNTDOWN → VOIDED and wipe volatile data.
  void voidNote() {
    if (state.status == VoidState.countdown) {
      _wipeMemory();
      state = state.copyWith(status: VoidState.voided, clearSession: true);
      _notifyVoidListeners();
    }
  }

  /// Transition to ERROR_NO_OFFLINE_MODEL — shown when onDevice:true fails
  /// because no speech model is installed on the device.
  void signalNoOfflineModel() {
    _wipeMemory();
    state = state.copyWith(
      status: VoidState.errorNoOfflineModel,
      clearSession: true,
    );
    _notifyVoidListeners();
  }

  /// Cancel an active countdown and return to IDLE without voiding.
  /// Idempotent — safe to call from any non-COUNTDOWN state.
  void cancelCountdown() {
    if (state.status != VoidState.countdown) return;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownPaused = false;
    state = state.copyWith(status: VoidState.idle, clearSession: true);
    _notifyVoidListeners();
  }

  /// Reset to IDLE (called from result screen "Tap to continue").
  void reset() {
    _wipeMemory();
    state = state.copyWith(status: VoidState.idle, clearSession: true);
    _notifyVoidListeners();
  }

  void _wipeMemory() {
    _countdownTimer?.cancel();
    _countdownPaused = false;
    state = state.copyWith(clearSession: true);
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Don't tick while auth sheet is open
      if (_countdownPaused) return;

      final session = state.session;
      final remaining = session?.countdownSeconds;

      if (state.status != VoidState.countdown) {
        timer.cancel();
        return;
      }

      if (remaining == null || remaining <= 1) {
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

  void addVoidListener(VoidStateListener listener) => _listeners.add(listener);
  void removeVoidListener(VoidStateListener listener) =>
      _listeners.remove(listener);

  void _notifyVoidListeners() {
    for (final listener in _listeners) {
      listener(state.status, state.session);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _wipeMemory();
    super.dispose();
  }
}

typedef VoidStateListener = void Function(VoidState state, VoidSession? session);

final voidControllerProvider =
    StateNotifierProvider<VoidController, VoidControllerViewState>((ref) {
  return VoidController();
});

final currentSessionProvider = Provider<VoidSession?>((ref) {
  return ref.watch(voidControllerProvider.select((s) => s.session));
});

final transcriptProvider = Provider<String>((ref) {
  return ref.watch(
    voidControllerProvider.select((s) => s.session?.transcript ?? ''),
  );
});

final countdownSecondsProvider = Provider<int?>((ref) {
  return ref.watch(
    voidControllerProvider.select((s) => s.session?.countdownSeconds),
  );
});

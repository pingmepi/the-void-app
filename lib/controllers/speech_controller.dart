import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/speech_service.dart';
import 'void_controller.dart';

/// Controller that bridges SpeechService with VoidController
/// Handles the flow: tap → listen → transcribe → countdown
class SpeechController extends StateNotifier<SpeechControllerState> {
  final Ref _ref;
  final SpeechService _speechService;
  late final VoidController _voidController;
  
  SpeechController(this._ref, this._speechService) 
      : super(const SpeechControllerState()) {
    _voidController = _ref.read(voidControllerProvider.notifier);
    _setupCallbacks();
  }

  void _setupCallbacks() {
    // When transcript is updated
    _speechService.onTranscriptUpdate = (text, isFinal) {
      state = state.copyWith(transcript: text, isFinalResult: isFinal);
      _voidController.updateTranscript(text);
    };

    // When speech recognition stops (user stopped speaking)
    _speechService.onSpeechDone = () {
      if (state.transcript.isNotEmpty) {
        // Speech done with content - stop listening and start countdown
        _voidController.stopListening();
        _voidController.startCountdown();
      } else {
        // No speech detected - go back to idle
        _voidController.stopListening();
        _reset();
      }
    };

    // Handle errors
    _speechService.onError = (error) {
      state = state.copyWith(error: error);
    };

    // Status updates for debugging
    _speechService.onStatusChange = (status) {
      state = state.copyWith(status: status);
    };
  }

  /// Start the recording flow
  Future<void> startRecording() async {
    // Clear any previous state
    state = const SpeechControllerState(status: 'initializing');
    
    // Tell void controller we're starting
    _voidController.startListening();
    
    // Start speech recognition
    final success = await _speechService.startListening();
    
    if (!success) {
      state = state.copyWith(error: 'Failed to start speech recognition');
      _voidController.stopListening();
      _reset();
    } else {
      state = state.copyWith(status: 'listening');
    }
  }

  /// Manually stop recording (user taps stop)
  Future<void> stopRecording() async {
    await _speechService.stopListening();
    
    if (state.transcript.isNotEmpty) {
      _voidController.stopListening();
      _voidController.startCountdown();
    } else {
      _reset();
    }
  }

  /// Cancel recording (discard everything)
  Future<void> cancelRecording() async {
    await _speechService.cancelListening();
    _voidController.stopListening();
    _reset();
  }

  void _reset() {
    state = const SpeechControllerState();
  }

  @override
  void dispose() {
    _speechService.onTranscriptUpdate = null;
    _speechService.onSpeechDone = null;
    _speechService.onError = null;
    _speechService.onStatusChange = null;
    super.dispose();
  }
}

/// State for SpeechController
class SpeechControllerState {
  final String transcript;
  final bool isFinalResult;
  final String? error;
  final String status;

  const SpeechControllerState({
    this.transcript = '',
    this.isFinalResult = false,
    this.error,
    this.status = 'idle',
  });

  SpeechControllerState copyWith({
    String? transcript,
    bool? isFinalResult,
    String? error,
    String? status,
  }) {
    return SpeechControllerState(
      transcript: transcript ?? this.transcript,
      isFinalResult: isFinalResult ?? this.isFinalResult,
      error: error,
      status: status ?? this.status,
    );
  }
}

/// Provider for SpeechController
final speechControllerProvider = 
    StateNotifierProvider<SpeechController, SpeechControllerState>((ref) {
  final speechService = ref.watch(speechServiceProvider);
  return SpeechController(ref, speechService);
});


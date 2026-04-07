import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/recording_service.dart';
import '../services/speech_service.dart';
import 'void_controller.dart';

/// Bridges [SpeechService] + [RecordingService] with [VoidController].
/// Starts/stops both audio capture and speech recognition in parallel.
class SpeechController extends StateNotifier<SpeechControllerState> {
  final Ref _ref;
  final SpeechService _speechService;
  final RecordingService _recordingService;
  late final VoidController _voidController;

  SpeechController(this._ref, this._speechService, this._recordingService)
      : super(const SpeechControllerState()) {
    _voidController = _ref.read(voidControllerProvider.notifier);
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _speechService.onTranscriptUpdate = (text, isFinal) {
      state = state.copyWith(transcript: text, isFinalResult: isFinal);
      _voidController.updateTranscript(text);
    };

    _speechService.onSpeechDone = () async {
      if (state.transcript.isNotEmpty) {
        _voidController.stopListening();
        // Stop audio recording and capture bytes
        final audioBytes = await _recordingService.stopRecording();
        _voidController.startCountdown(
          audioBytes: audioBytes,
          audioMimeType:
              audioBytes != null ? _recordingService.mimeType : null,
        );
      } else {
        _voidController.stopListening();
        await _recordingService.cancelRecording();
        _reset();
      }
    };

    _speechService.onError = (error) {
      state = state.copyWith(error: error);
    };

    _speechService.onStatusChange = (status) {
      state = state.copyWith(status: status);
    };
  }

  /// Start both speech recognition and audio recording.
  Future<void> startRecording() async {
    state = const SpeechControllerState(status: 'initializing');
    _voidController.startListening();

    // Start both in parallel — audio failure is non-fatal
    final results = await Future.wait([
      _speechService.startListening(),
      _recordingService.startRecording(),
    ]);

    final speechStarted = results[0];
    if (!speechStarted) {
      state = state.copyWith(error: 'Failed to start speech recognition');
      await _recordingService.cancelRecording();
      _voidController.stopListening();
      _reset();
    } else {
      state = state.copyWith(status: 'listening');
    }
  }

  /// Manually stop recording (user taps stop button).
  Future<void> stopRecording() async {
    final currentTranscript = state.transcript;
    state = state.copyWith(status: 'stopping');

    // Stop speech first, then collect audio bytes
    final audioFuture = _recordingService.stopRecording();
    await _speechService.stopListening();
    final audioBytes = await audioFuture;

    if (currentTranscript.isNotEmpty) {
      _voidController.stopListening();
      _voidController.startCountdown(
        audioBytes: audioBytes,
        audioMimeType: audioBytes != null ? _recordingService.mimeType : null,
      );
    } else {
      _voidController.stopListening();
      _reset();
    }
  }

  /// Cancel and discard everything.
  Future<void> cancelRecording() async {
    await Future.wait([
      _speechService.cancelListening(),
      _recordingService.cancelRecording(),
    ]);
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

final speechControllerProvider =
    StateNotifierProvider<SpeechController, SpeechControllerState>((ref) {
  final speechService = ref.watch(speechServiceProvider);
  final recordingService = ref.watch(recordingServiceProvider);
  return SpeechController(ref, speechService, recordingService);
});

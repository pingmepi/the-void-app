import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service for speech-to-text operations
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isManualStop = false; // Track manual stops to prevent callback race

  /// Callback for transcript updates (called with each partial/final result)
  Function(String text, bool isFinal)? onTranscriptUpdate;

  /// Callback when speech recognition stops automatically (silence detection/timeout)
  /// NOT called when user manually stops
  Function()? onSpeechDone;

  /// Callback for errors
  Function(String)? onError;

  /// Callback for status changes
  Function(String)? onStatusChange;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // permission_handler doesn't support web; the browser handles mic
      // permission natively when speech_to_text calls getUserMedia.
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          onError?.call('Microphone permission denied');
          return false;
        }
      }

      // Initialize speech to text
      final available = await _speechToText.initialize(
        onError: (error) {
          onError?.call('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          onStatusChange?.call(status);
          // When status becomes 'done' or 'notListening', speech has stopped
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            // Only call onSpeechDone if it was automatic (not manual stop)
            if (!_isManualStop) {
              onSpeechDone?.call();
            }
            _isManualStop = false; // Reset flag
          }
        },
      );

      _isInitialized = available;
      return available;
    } catch (e) {
      onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<bool> startListening({String? localeId}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) return true;

    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          onTranscriptUpdate?.call(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(minutes: 2), // Max 2 minutes recording
        pauseFor: const Duration(seconds: 5),  // Stop after 5 seconds of silence (natural pauses)
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
        localeId: localeId ?? 'en_US',
      );
      return true;
    } catch (e) {
      onError?.call('Error starting speech recognition: $e');
      _isListening = false;
      return false;
    }
  }

  /// Stop listening (manual stop by user)
  /// This immediately stops speech recognition - user action takes priority
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isManualStop = true; // Flag to prevent onSpeechDone callback
    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      _isManualStop = false;
      onError?.call('Error stopping speech recognition: $e');
    }
  }

  /// Cancel listening (discard results)
  Future<void> cancelListening() async {
    if (!_isListening) return;

    _isManualStop = true; // Flag to prevent onSpeechDone callback
    try {
      await _speechToText.cancel();
      _isListening = false;
    } catch (e) {
      _isManualStop = false;
      onError?.call('Error canceling speech recognition: $e');
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Check if speech recognition is available on this device
  bool get isAvailable => _speechToText.isAvailable;

  /// Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      return await _speechToText.locales();
    } catch (e) {
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _isListening = false;
  }
}

/// Riverpod provider for SpeechService
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(() => service.dispose());
  return service;
});


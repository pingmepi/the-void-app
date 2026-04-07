import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Captures raw audio in parallel with [SpeechService] transcription.
///
/// On web    → records to blob via [MediaRecorder], fetches bytes via HTTP.
/// On native → writes AAC/M4A to a temp file, reads bytes on stop.
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _tempPath;
  bool _isRecording = false;

  /// MIME type for the recorded audio on the current platform.
  String get mimeType => kIsWeb ? 'audio/webm' : 'audio/mp4';

  String get _fileExtension => kIsWeb ? 'webm' : 'm4a';

  /// Start capturing audio. Returns false if permission is denied or an
  /// error occurs — the caller should treat this as a non-fatal failure
  /// (transcription will still work without audio).
  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return false;

      _tempPath = null;

      if (kIsWeb) {
        // Web: record to blob — stop() will return a blob:// URL
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: '',
        );
      } else {
        // Native: record to temp file
        final dir = await getTemporaryDirectory();
        _tempPath =
            '${dir.path}/void_${DateTime.now().millisecondsSinceEpoch}.$_fileExtension';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _tempPath!,
        );
      }

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('RecordingService: startRecording failed: $e');
      return false;
    }
  }

  /// Stop recording and return the captured audio as bytes.
  /// Returns null if recording wasn't started or capture failed.
  Future<Uint8List?> stopRecording() async {
    if (!_isRecording) return null;
    _isRecording = false;

    try {
      final result = await _recorder.stop();
      if (result == null) return null;

      if (kIsWeb) {
        // result is a blob:// URL on web — fetch the bytes
        final response = await http.get(Uri.parse(result));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        debugPrint('RecordingService: blob fetch failed: ${response.statusCode}');
        return null;
      } else {
        // result is a file path on native
        final file = File(result);
        final bytes = await file.readAsBytes();
        try {
          await file.delete();
        } catch (_) {}
        return bytes;
      }
    } catch (e) {
      debugPrint('RecordingService: stopRecording failed: $e');
      return null;
    }
  }

  /// Discard the current recording without returning data.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _isRecording = false;

    try {
      await _recorder.cancel();
    } catch (_) {}

    if (!kIsWeb && _tempPath != null) {
      try {
        await File(_tempPath!).delete();
      } catch (_) {}
      _tempPath = null;
    }
  }

  bool get isRecording => _isRecording;

  void dispose() {
    _recorder.dispose();
  }
}

/// Riverpod provider for [RecordingService].
final recordingServiceProvider = Provider<RecordingService>((ref) {
  final service = RecordingService();
  ref.onDispose(service.dispose);
  return service;
});

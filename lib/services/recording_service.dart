import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Captures raw audio in parallel with [SpeechService] transcription.
///
/// On web  → streams Opus/WebM chunks via [MediaRecorder] API.
/// On native → writes AAC/M4A to a temp file, reads bytes on stop.
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final List<Uint8List> _chunks = [];
  StreamSubscription<Uint8List>? _streamSub;
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

      _chunks.clear();
      _tempPath = null;

      if (kIsWeb) {
        // Web: stream chunks — no file system access needed
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
        _streamSub = stream.listen(
          (chunk) => _chunks.add(chunk),
          onError: (Object e) =>
              debugPrint('RecordingService: stream error: $e'),
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
      if (kIsWeb) {
        await _streamSub?.cancel();
        _streamSub = null;
        await _recorder.stop();

        if (_chunks.isEmpty) return null;
        final total = _chunks.fold(0, (sum, c) => sum + c.length);
        final combined = Uint8List(total);
        var offset = 0;
        for (final c in _chunks) {
          combined.setAll(offset, c);
          offset += c.length;
        }
        _chunks.clear();
        return combined;
      } else {
        final path = await _recorder.stop();
        if (path == null) return null;
        final bytes = await File(path).readAsBytes();
        // Clean up temp file
        try {
          await File(path).delete();
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
    _chunks.clear();

    await _streamSub?.cancel();
    _streamSub = null;

    try {
      await _recorder.cancel();
    } catch (_) {}

    if (_tempPath != null) {
      try {
        await File(_tempPath!).delete();
      } catch (_) {}
      _tempPath = null;
    }
  }

  bool get isRecording => _isRecording;

  void dispose() {
    _streamSub?.cancel();
    _recorder.dispose();
  }
}

/// Riverpod provider for [RecordingService].
final recordingServiceProvider = Provider<RecordingService>((ref) {
  final service = RecordingService();
  ref.onDispose(service.dispose);
  return service;
});

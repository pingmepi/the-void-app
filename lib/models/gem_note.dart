import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gem_note.freezed.dart';
part 'gem_note.g.dart';

/// A saved voice note (a "gem" rescued from the void).
///
/// Gems are the only notes that persist — they represent
/// intentionally saved thoughts that the user chose to keep.
@freezed
class GemNote with _$GemNote {
  const factory GemNote({
    /// Unique identifier for the gem
    required String id,

    /// The transcribed text content
    required String transcript,

    /// When the gem was saved
    required DateTime savedAt,

    /// Optional title (user can add later)
    String? title,

    /// Duration of the original recording in seconds
    int? durationSeconds,

    /// Tags for organization (optional feature)
    @Default([]) List<String> tags,

    /// Supabase auth user ID — null for local-only gems
    String? userId,

    /// Supabase Storage signed URL for the audio file.
    /// Null if audio capture failed or this is a local-only gem.
    String? audioUrl,
  }) = _GemNote;

  factory GemNote.fromJson(Map<String, dynamic> json) =>
      _$GemNoteFromJson(json);
}

/// State container for the current void session.
/// This is the volatile, in-memory-only state that gets wiped on background.
class VoidSession {
  /// The current transcript being built
  String transcript;

  /// When recording started
  final DateTime startedAt;

  /// Remaining seconds in countdown (null if not in countdown)
  int? countdownSeconds;

  /// Raw audio bytes captured in parallel with speech recognition.
  /// Null if audio capture failed or hasn't completed yet.
  Uint8List? audioBytes;

  /// MIME type of [audioBytes]: 'audio/webm' on web, 'audio/mp4' on native.
  String? audioMimeType;

  VoidSession({
    this.transcript = '',
    DateTime? startedAt,
    this.countdownSeconds,
    this.audioBytes,
    this.audioMimeType,
  }) : startedAt = startedAt ?? DateTime.now();

  /// Wipe all data — core privacy feature
  void wipe() {
    transcript = '';
    countdownSeconds = null;
    audioBytes = null;
    audioMimeType = null;
  }

  /// Create a copy with updated fields
  VoidSession copyWith({
    String? transcript,
    int? countdownSeconds,
    Uint8List? audioBytes,
    String? audioMimeType,
    bool clearAudio = false,
  }) {
    return VoidSession(
      transcript: transcript ?? this.transcript,
      startedAt: startedAt,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      audioBytes: clearAudio ? null : (audioBytes ?? this.audioBytes),
      audioMimeType: clearAudio ? null : (audioMimeType ?? this.audioMimeType),
    );
  }

  /// Calculate recording duration
  Duration get recordingDuration => DateTime.now().difference(startedAt);
}

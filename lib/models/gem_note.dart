import 'package:freezed_annotation/freezed_annotation.dart';

part 'gem_note.freezed.dart';
part 'gem_note.g.dart';

/// A saved voice note (a "gem" rescued from the void).
/// 
/// Gems are the only notes that persist - they represent
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
  }) = _GemNote;

  factory GemNote.fromJson(Map<String, dynamic> json) =>
      _$GemNoteFromJson(json);
}

/// State container for the current void session.
/// This is the volatile, in-memory-only state that gets wiped.
class VoidSession {
  /// The current transcript being built
  String transcript;
  
  /// When recording started
  final DateTime startedAt;
  
  /// Remaining seconds in countdown (null if not in countdown)
  int? countdownSeconds;

  VoidSession({
    this.transcript = '',
    DateTime? startedAt,
    this.countdownSeconds,
  }) : startedAt = startedAt ?? DateTime.now();

  /// Wipe all data - this is the core privacy feature
  void wipe() {
    transcript = '';
    countdownSeconds = null;
  }

  /// Create a copy with updated fields
  VoidSession copyWith({
    String? transcript,
    int? countdownSeconds,
  }) {
    return VoidSession(
      transcript: transcript ?? this.transcript,
      startedAt: startedAt,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }

  /// Calculate recording duration
  Duration get recordingDuration => DateTime.now().difference(startedAt);
}


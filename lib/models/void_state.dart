/// Represents the current state of the Void voice note lifecycle.
/// 
/// State Flow:
/// IDLE → LISTENING → TRANSCRIBING → COUNTDOWN → [VOIDED | SAVED]
enum VoidState {
  /// Initial state - waiting for user to start recording
  idle,
  
  /// Actively listening and detecting speech
  listening,
  
  /// Processing speech to text (brief transition state)
  transcribing,
  
  /// 60-second countdown before voiding
  countdown,
  
  /// Note has been permanently voided (memory wiped)
  voided,
  
  /// Note has been saved as a gem
  saved,
}

/// Extension methods for VoidState
extension VoidStateExtension on VoidState {
  /// Whether the state allows the transcript to be visible
  bool get isTranscriptVisible {
    return this == VoidState.listening ||
        this == VoidState.transcribing ||
        this == VoidState.countdown;
  }

  /// Whether we can rescue/save the note in this state
  bool get canRescue {
    return this == VoidState.countdown;
  }

  /// Whether voice recording is active
  bool get isRecording {
    return this == VoidState.listening;
  }

  /// Whether the countdown timer should be running
  bool get isCountdownActive {
    return this == VoidState.countdown;
  }

  /// Display name for the state
  String get displayName {
    switch (this) {
      case VoidState.idle:
        return 'Ready';
      case VoidState.listening:
        return 'Listening...';
      case VoidState.transcribing:
        return 'Processing...';
      case VoidState.countdown:
        return 'Dissolving...';
      case VoidState.voided:
        return 'Gone';
      case VoidState.saved:
        return 'Saved';
    }
  }
}


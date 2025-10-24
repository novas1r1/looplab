/// SoLoud equivalent of audioplayers PlayerState
enum SoLoudPlayerState {
  /// The player is stopped and ready to play
  stopped,
  
  /// The player is currently playing audio
  playing,
  
  /// The player is paused
  paused,
  
  /// The player has completed playback
  completed,
  
  /// The player has been disposed
  disposed,
}

/// Extension to convert between SoLoud playing state and PlayerState
extension SoLoudPlayerStateExtension on bool {
  SoLoudPlayerState toSoLoudPlayerState() {
    return this ? SoLoudPlayerState.playing : SoLoudPlayerState.paused;
  }
}

/// Extension to convert SoLoudPlayerState to bool
extension SoLoudPlayerStateToBool on SoLoudPlayerState {
  bool get isPlaying {
    return this == SoLoudPlayerState.playing;
  }
  
  bool get isPaused {
    return this == SoLoudPlayerState.paused;
  }
  
  bool get isStopped {
    return this == SoLoudPlayerState.stopped;
  }
  
  bool get isCompleted {
    return this == SoLoudPlayerState.completed;
  }
}



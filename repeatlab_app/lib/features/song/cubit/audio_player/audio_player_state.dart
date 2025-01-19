/* part of 'audio_player_cubit.dart';

class AudioPlayerState extends Equatable {
  final AudioPlayerStatus status;
  final PlayerState playerState;
  final Duration? position;
  final Duration? duration;
  final double speed;
  final Object? exception;

  const AudioPlayerState({
    this.status = AudioPlayerStatus.loading,
    this.playerState = PlayerState.stopped,
    this.position,
    this.duration,
    this.speed = 1.0,
    this.exception,
  });

  @override
  List<Object?> get props =>
      [status, playerState, position, duration, speed, exception];

  AudioPlayerState copyWith({
    AudioPlayerStatus? status,
    PlayerState? playerState,
    Duration? position,
    Duration? duration,
    double? speed,
    Object? exception,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      exception: exception ?? this.exception,
    );
  }
}

enum AudioPlayerStatus {
  loading,
  loaded,
  playError,
  fileNotFoundError,
}
 */

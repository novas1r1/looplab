import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// Shared contract for Repeatlab audio handlers regardless of playback engine.
abstract class RepeatlabAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  /// Load and start playing the provided song.
  Future<void> playSong(Song song);

  /// Current playback position.
  Future<Duration> get position;

  /// Stream of high-level playback states used by the UI.
  Stream<PlayerState>? get playerStateStream;

  /// Stream of playback positions.
  Stream<Duration>? get positionStream;

  /// Resume playback, honouring any active loop boundaries.
  Future<void> resume();

  /// Enable loop mode for a specific segment.
  Future<void> enableLoopMode(Loop loop);

  /// Disable the currently active loop, if any.
  Future<void> disableLoopMode();

  /// Seek forward by the specified number of seconds while respecting loop bounds.
  Future<void> forward(int seconds, Loop? loop);

  /// Seek backward by the specified number of seconds while respecting loop bounds.
  Future<void> back(int seconds, Loop? loop);

  /// Adjust playback speed.
  @override
  Future<void> setSpeed(double speed);

  /// Adjust playback pitch multiplier (1.0 = original pitch).
  ///
  /// Engines that do not support pitch shifting should throw [UnsupportedError].
  Future<void> setPitch(double pitch);

  /// Indicates whether the current engine supports independent pitch control.
  bool get supportsPitch;

  /// True if the handler is backed by `just_audio`.
  bool get usesJustAudio;
}

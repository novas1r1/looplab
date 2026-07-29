import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:repeatlab/data/services/video_player_handler.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

/// Bloc cubit for video songs.
///
/// Subclasses [SongCubit] so `BlocProvider<SongCubit>(create: ...)` resolves
/// for shared widgets that read `context.read<SongCubit>()`. All the loop /
/// speed / BPM / playback logic lives in the parent and works unchanged for
/// video because it talks to the [MediaPlayerHandler] interface; only the
/// init path differs.
class VideoSongCubit extends SongCubit {
  /// Holds the [VideoPlayerHandler] under its concrete type so widgets like
  /// [VideoPreview] can reach the underlying [Player] for attaching a
  /// [VideoController]. The parent's [audioHandler] still points to the same
  /// instance (typed as [MediaPlayerHandler]).
  late final VideoPlayerHandler _videoHandler;

  /// The underlying media_kit [Player]. The video preview widget attaches a
  /// [VideoController] to this for rendering frames.
  Player get player => _videoHandler.player;

  /// The [VideoController] is created eagerly in [initVideo] — before
  /// `player.open()` runs — so that media_kit's `isVideoControllerAttached`
  /// flag is set in time. Otherwise `player.open()` skips
  /// `waitForVideoControllerInitializationIfAttached`, libmpv loads the file
  /// with no video output, and the texture stays at id 0 / size 0×0 on
  /// iOS/macOS/Windows/Linux.
  late final VideoController videoController;

  /// Guards against double-initialization: `_videoHandler` and
  /// `videoController` are `late final`, so a second `initVideo` call would
  /// throw `LateInitializationError`. The flag lets the cubit no-op instead
  /// if init is accidentally re-entered (e.g. after a transient failure).
  bool _initialized = false;

  VideoSongCubit({
    required super.song,
    required super.songRepository,
    required super.localConfigRepository,
    required super.crashReportingRepository,
    super.hasPremium,
  });

  /// Construct a fresh [VideoPlayerHandler] and run the shared init body.
  ///
  /// Replacement for [SongCubit.initSong] for video songs — the audio version
  /// requires an [AudioPlayer], which we don't have for video.
  Future<void> initVideo() async {
    if (_initialized) return;
    _initialized = true;
    _videoHandler = VideoPlayerHandler();
    videoController = VideoController(_videoHandler.player);
    await initWithHandler(_videoHandler);
  }

  /// Unlike the audio handler (an app-lifetime singleton that only gets
  /// stopped), the video handler is created per page and owns a native libmpv
  /// player — it must be fully disposed here or every video page visit leaks
  /// a player instance and its stream subscriptions.
  @override
  Future<void> close() async {
    await super.close();
    if (_initialized) {
      await _videoHandler.close();
    }
  }
}

import 'package:media_kit/media_kit.dart';
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

  VideoSongCubit({
    required super.song,
    required super.songRepository,
    required super.localConfigRepository,
    required super.crashReportingRepository,
  });

  /// Construct a fresh [VideoPlayerHandler] and run the shared init body.
  ///
  /// Replacement for [SongCubit.initSong] for video songs — the audio version
  /// requires an [AudioPlayer], which we don't have for video.
  Future<void> initVideo() async {
    _videoHandler = VideoPlayerHandler();
    await initWithHandler(_videoHandler);
  }
}

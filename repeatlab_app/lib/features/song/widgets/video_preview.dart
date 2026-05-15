import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/cubit/video_song/video_song_cubit.dart';

/// Renders the video frame for a video song. Drop-in replacement for
/// `WaveFormSoLoud` on the [VideoSongView]. Pulls the [media_kit] `Player`
/// from the surrounding [VideoSongCubit] and attaches a [VideoController].
///
/// Aspect ratio is updated dynamically once the player reports the source's
/// dimensions; before that it falls back to 16:9 to avoid layout jumps.
class VideoPreview extends StatefulWidget {
  final Song song;

  const VideoPreview({super.key, required this.song});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late final VideoController _controller;

  double _aspectRatio = 16 / 9;
  StreamSubscription<int?>? _widthSubscription;
  StreamSubscription<int?>? _heightSubscription;
  int? _knownWidth;
  int? _knownHeight;

  @override
  void initState() {
    super.initState();
    // The BlocProvider in SongPage registers VideoSongCubit under the
    // SongCubit base type so shared widgets reading `context.read<SongCubit>()`
    // resolve to it. Cast back to the concrete type to reach the Player.
    // Safe: this widget is only ever built for video songs.
    final cubit = context.read<SongCubit>() as VideoSongCubit;
    _controller = VideoController(cubit.player);

    _widthSubscription = cubit.player.stream.width.listen((w) {
      if (w == null || w == 0) return;
      _knownWidth = w;
      _maybeUpdateAspect();
    });
    _heightSubscription = cubit.player.stream.height.listen((h) {
      if (h == null || h == 0) return;
      _knownHeight = h;
      _maybeUpdateAspect();
    });
  }

  void _maybeUpdateAspect() {
    final w = _knownWidth;
    final h = _knownHeight;
    if (w == null || h == null || h == 0) return;
    final next = w / h;
    if ((_aspectRatio - next).abs() < 0.001) return;
    if (!mounted) return;
    setState(() {
      _aspectRatio = next;
    });
  }

  @override
  void dispose() {
    _widthSubscription?.cancel();
    _heightSubscription?.cancel();
    // The underlying Player + its texture are owned by VideoSongCubit and
    // released in VideoPlayerHandler.close(). We only own the stream
    // subscriptions above.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: AppColors.surface,
          child: Video(
            controller: _controller,
            fit: BoxFit.contain,
            // Hide media_kit_video's built-in scrub bar; LoopTimeline +
            // SongController already cover playback control. The default
            // controls would also intercept taps we want passing through to
            // surrounding widgets.
            controls: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

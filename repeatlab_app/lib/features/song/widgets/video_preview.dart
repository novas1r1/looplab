import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion.dart';
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

  // Fraction of available height the video may occupy, per size mode. The
  // frame is centered horizontally so portrait videos shrink to fit instead of
  // dominating the screen. Landscape uses higher fractions (and a smaller
  // base — viewport minus app bar) so `large` can fill the visible area on
  // phones held sideways.
  static const Map<VideoSizeMode, double> _portraitFractions = {
    VideoSizeMode.small: 0.22,
    VideoSizeMode.medium: 0.40,
    VideoSizeMode.large: 0.65,
  };
  static const Map<VideoSizeMode, double> _landscapeFractions = {
    VideoSizeMode.small: 0.45,
    VideoSizeMode.medium: 0.75,
    VideoSizeMode.large: 1.0,
  };

  @override
  void initState() {
    super.initState();
    // The BlocProvider in SongPage registers VideoSongCubit under the
    // SongCubit base type so shared widgets reading `context.read<SongCubit>()`
    // resolve to it. Cast back to the concrete type to reach the player +
    // pre-attached controller. Safe: this widget is only ever built for video
    // songs. The controller is created in VideoSongCubit.initVideo() before
    // player.open() runs, so libmpv has a video output target ready.
    final cubit = context.read<SongCubit>() as VideoSongCubit;
    _controller = cubit.videoController;

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

  void _shrink(VideoSizeMode current) {
    final next = switch (current) {
      VideoSizeMode.large => VideoSizeMode.medium,
      VideoSizeMode.medium => VideoSizeMode.small,
      VideoSizeMode.small => VideoSizeMode.small,
    };
    context.read<SongCubit>().setVideoSizeMode(next);
  }

  void _grow(VideoSizeMode current) {
    final next = switch (current) {
      VideoSizeMode.small => VideoSizeMode.medium,
      VideoSizeMode.medium => VideoSizeMode.large,
      VideoSizeMode.large => VideoSizeMode.large,
    };
    context.read<SongCubit>().setVideoSizeMode(next);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    // In landscape, base the size on the space actually below the app bar so
    // `large` (1.0) fills the viewport instead of overflowing behind it.
    final availableHeight = isLandscape
        ? mediaQuery.size.height - mediaQuery.padding.top - kToolbarHeight
        : mediaQuery.size.height;
    final fractions = isLandscape ? _landscapeFractions : _portraitFractions;

    return BlocSelector<SongCubit, SongState, VideoSizeMode>(
      selector: (state) => state.song.videoSizeMode,
      builder: (context, mode) {
        final maxHeight = availableHeight * (fractions[mode] ?? 0.40);
        // Tween the height constraint so size-mode changes glide instead of
        // jumping. GPU texture scaling keeps this cheap.
        return TweenAnimationBuilder<double>(
          tween: Tween(end: maxHeight),
          duration: Motion.of(context, Motion.standard),
          curve: Motion.emphasized,
          builder: (context, animatedMaxHeight, child) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: animatedMaxHeight),
              child: child,
            ),
          ),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: Video(
                        controller: _controller,
                        // Hide media_kit_video's built-in scrub bar;
                        // LoopTimeline + SongController already cover
                        // playback control. The default controls would also
                        // intercept taps we want passing through to
                        // surrounding widgets.
                        controls: (_) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _SizeControls(
                      mode: mode,
                      onShrink: () => _shrink(mode),
                      onGrow: () => _grow(mode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SizeControls extends StatelessWidget {
  final VideoSizeMode mode;
  final VoidCallback onShrink;
  final VoidCallback onGrow;

  const _SizeControls({
    required this.mode,
    required this.onShrink,
    required this.onGrow,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Semi-transparent pill so the icons stay legible over both light and
        // dark video content.
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBtn(
            icon: Icons.remove,
            enabled: mode != VideoSizeMode.small,
            onTap: onShrink,
            tooltip: 'Shrink video',
          ),
          _IconBtn(
            icon: Icons.add,
            enabled: mode != VideoSizeMode.large,
            onTap: onGrow,
            tooltip: 'Enlarge video',
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: Colors.white,
      disabledColor: Colors.white38,
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }
}

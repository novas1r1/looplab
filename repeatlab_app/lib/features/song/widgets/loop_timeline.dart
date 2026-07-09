import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion_widgets.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/widgets/smooth_playhead.dart';

class LoopTimeline extends StatefulWidget {
  final void Function(Loop loop)? onLoopTap;
  final void Function() onSkipPrevious;
  final void Function() onSkipNext;
  final void Function(Duration position) onSeek;
  final Duration duration;
  final bool Function(Loop loop)? isLoopLocked;
  final void Function(Loop loop)? onLockedLoopTap;

  const LoopTimeline({
    super.key,
    this.onLoopTap,
    required this.onSkipPrevious,
    required this.onSkipNext,
    required this.onSeek,
    required this.duration,
    this.isLoopLocked,
    this.onLockedLoopTap,
  });

  @override
  State<LoopTimeline> createState() => _LoopTimelineState();
}

class _LoopTimelineState extends State<LoopTimeline>
    with SingleTickerProviderStateMixin {
  final _timelineKey = GlobalKey();
  final _shakeKey = GlobalKey<ShakeOnDeniedState>();

  /// Interpolates the coarse position stream so the 2px playhead glides at
  /// display rate instead of stepping. Consumer-side only.
  late final SmoothPlayhead _smoothPlayhead;

  /// Read by [_smoothPlayhead]; kept in sync with MediaQuery in
  /// didChangeDependencies.
  bool _disableAnimations = false;

  double get _timelineWidth {
    final RenderBox? box =
        _timelineKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final songCubit = context.read<SongCubit>();
    _smoothPlayhead = SmoothPlayhead(
      vsync: this,
      positionStream: songCubit.positionStream ?? const Stream.empty(),
      isPlaying: () => songCubit.state.playerState == PlayerState.playing,
      playbackRate: () => songCubit.state.speed,
      totalDuration: () => widget.duration,
      pixelsPerMs: () {
        final durationMs = _durationMs;
        if (durationMs == null) return 0;
        return _timelineWidth / durationMs;
      },
      disableAnimations: () => _disableAnimations,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _smoothPlayhead.dispose();
    super.dispose();
  }

  /// Song duration in ms, or `null` when unknown/zero (e.g. metadata failed
  /// to parse). Guards the position math below: dividing by zero would put
  /// NaN into [Positioned] and crash the layout.
  int? get _durationMs {
    final ms = widget.duration.inMilliseconds;
    return ms > 0 ? ms : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SongCubit, SongState, List<Loop>>(
      selector: (state) => state.song.loops,
      builder: (context, loops) {
        return Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                AppAnalytics.trackEvent(AppAnalytics.clickSkipPrevious);
                widget.onSkipPrevious();
              },
              icon: const Icon(Icons.skip_previous, size: 24),
            ),
            Expanded(
              child: GestureDetector(
                onTapDown: (details) =>
                    _handleTimelineInteraction(details.localPosition),
                onHorizontalDragUpdate: (details) =>
                    _handleTimelineInteraction(details.localPosition),
                child: ShakeOnDenied(
                  key: _shakeKey,
                  child: Container(
                    key: _timelineKey,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Own RepaintBoundary so the 60fps playhead movement
                        // never repaints the loop blocks behind it.
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: ValueListenableBuilder<Duration>(
                              valueListenable: _smoothPlayhead,
                              builder: (context, position, child) {
                                final durationMs = _durationMs;
                                if (durationMs == null) {
                                  return const SizedBox.shrink();
                                }
                                return Stack(
                                  children: [
                                    Positioned(
                                      left:
                                          (position.inMilliseconds /
                                              durationMs) *
                                          _timelineWidth,
                                      top: 0,
                                      bottom: 0,
                                      child: child!,
                                    ),
                                  ],
                                );
                              },
                              child: Container(
                                width: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        // Loop containers
                        ...loops.map(
                          (loop) {
                            final durationMs = _durationMs;
                            if (loop.start == null ||
                                loop.end == null ||
                                durationMs == null) {
                              return const SizedBox.shrink();
                            }

                            final startPosition =
                                loop.start!.inMilliseconds / durationMs;
                            final endPosition =
                                loop.end!.inMilliseconds / durationMs;

                            final isLocked =
                                widget.isLoopLocked?.call(loop) ?? false;

                            return Positioned(
                              left: startPosition * _timelineWidth,
                              width:
                                  (endPosition - startPosition) *
                                  _timelineWidth,
                              top: 8,
                              bottom: 8,
                              child: GestureDetector(
                                onTap: () {
                                  if (isLocked) {
                                    _shakeKey.currentState?.shake();
                                    widget.onLockedLoopTap?.call(loop);
                                  } else {
                                    widget.onLoopTap?.call(loop);
                                  }
                                },
                                child: Opacity(
                                  opacity: isLocked ? 0.4 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: loop.color.color.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: loop.color.color,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: isLocked
                                          ? const Icon(
                                              Icons.lock,
                                              size: 14,
                                              color: AppColors.onSurfaceVariant,
                                            )
                                          : Text(
                                              loop.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .onSurfaceVariant,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                AppAnalytics.trackEvent(AppAnalytics.clickSkipNext);
                widget.onSkipNext();
              },
              icon: const Icon(Icons.skip_next),
            ),
          ],
        );
      },
    );
  }

  void _handleTimelineInteraction(Offset localPosition) {
    final width = _timelineWidth;
    if (width <= 0) return;

    // Calculate position percentage (constrained between 0 and 1)
    final percentage = (localPosition.dx / width).clamp(0.0, 1.0);

    final songDuration = context.read<SongCubit>().state.song.duration;

    // Convert to duration
    final newPosition = Duration(
      milliseconds: (percentage * songDuration.inMilliseconds).round(),
    );

    widget.onSeek(newPosition);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

class LoopTimeline extends StatefulWidget {
  final void Function(Loop loop)? onLoopTap;
  final void Function() onPreviousLoop;
  final void Function() onNextLoop;
  final void Function(Duration position) onSeek;
  final Duration duration;

  const LoopTimeline({
    super.key,
    this.onLoopTap,
    required this.onPreviousLoop,
    required this.onNextLoop,
    required this.onSeek,
    required this.duration,
  });

  @override
  State<LoopTimeline> createState() => _LoopTimelineState();
}

class _LoopTimelineState extends State<LoopTimeline> {
  final _timelineKey = GlobalKey();

  double get _timelineWidth {
    final RenderBox? box = _timelineKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SongCubit, SongState, List<Loop>>(
      selector: (state) => state.song.loops,
      builder: (context, loops) {
        return Row(
          children: [
            IconButton(
              onPressed: loops.length > 1 ? widget.onPreviousLoop : null,
              icon: const Icon(Icons.skip_previous),
            ),
            Expanded(
              child: GestureDetector(
                onTapDown: (details) => _handleTimelineInteraction(details.localPosition),
                onHorizontalDragUpdate: (details) =>
                    _handleTimelineInteraction(details.localPosition),
                child: Container(
                  key: _timelineKey,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      StreamBuilder<Duration>(
                        stream: context.read<SongCubit>().positionStream,
                        initialData: Duration.zero,
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<Duration> snapshot,
                            ) {
                              if (snapshot.hasData) {
                                return Positioned(
                                  left:
                                      (snapshot.data!.inMilliseconds /
                                          widget.duration.inMilliseconds) *
                                      _timelineWidth,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                      ),

                      // Loop containers
                      ...loops.map(
                        (loop) {
                          if (loop.start == null || loop.end == null) {
                            return const SizedBox.shrink();
                          }

                          final startPosition =
                              loop.start!.inMilliseconds / widget.duration.inMilliseconds;
                          final endPosition =
                              loop.end!.inMilliseconds / widget.duration.inMilliseconds;

                          return Positioned(
                            left: startPosition * _timelineWidth,
                            width: (endPosition - startPosition) * _timelineWidth,
                            top: 8,
                            bottom: 8,
                            child: GestureDetector(
                              onTap: () => widget.onLoopTap?.call(loop),
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
                                  child: Text(
                                    loop.name,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
            IconButton(
              onPressed: loops.length > 1 ? widget.onNextLoop : null,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        );
      },
    );
  }

  void _handleTimelineInteraction(Offset localPosition) {
    // Calculate position percentage (constrained between 0 and 1)
    final percentage = (localPosition.dx / _timelineWidth).clamp(0.0, 1.0);

    final songDuration = context.read<SongCubit>().state.song.duration;

    // Convert to duration
    final newPosition = Duration(
      milliseconds: (percentage * songDuration.inMilliseconds).round(),
    );

    widget.onSeek(newPosition);
  }
}

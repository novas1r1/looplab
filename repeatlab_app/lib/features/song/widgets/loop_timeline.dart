import 'package:flutter/material.dart';
import 'package:repeatlab/data/models/loop.dart';

class LoopTimeline extends StatefulWidget {
  final List<Loop> loops;
  final Duration songDuration;
  final Duration currentPosition;

  final void Function(Loop loop)? onLoopTap;
  final void Function() onPreviousLoop;
  final void Function() onNextLoop;

  final bool hasMoreThan1Loop;

  final void Function(Duration position) onSeek;

  const LoopTimeline({
    super.key,
    required this.loops,
    required this.songDuration,
    required this.currentPosition,
    this.onLoopTap,
    required this.onPreviousLoop,
    required this.onNextLoop,
    required this.hasMoreThan1Loop,
    required this.onSeek,
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
    return Row(
      children: [
        IconButton(
          onPressed: widget.hasMoreThan1Loop ? widget.onPreviousLoop : null,
          icon: const Icon(Icons.skip_previous),
        ),
        Expanded(
          child: GestureDetector(
            onTapDown: (details) => _handleTimelineInteraction(details.localPosition),
            onHorizontalDragUpdate: (details) => _handleTimelineInteraction(details.localPosition),
            child: Container(
              key: _timelineKey,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Current position indicator
                  Positioned(
                    left: (widget.currentPosition.inMilliseconds /
                            widget.songDuration.inMilliseconds) *
                        _timelineWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Loop containers
                  ...widget.loops.map((loop) {
                    if (loop.start == null || loop.end == null) {
                      return const SizedBox.shrink();
                    }

                    final startPosition =
                        loop.start!.inMilliseconds / widget.songDuration.inMilliseconds;
                    final endPosition =
                        loop.end!.inMilliseconds / widget.songDuration.inMilliseconds;

                    return Positioned(
                      left: startPosition * _timelineWidth,
                      width: (endPosition - startPosition) * _timelineWidth,
                      top: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () => widget.onLoopTap?.call(loop),
                        child: Container(
                          decoration: BoxDecoration(
                            color: loop.color.color.withValues(alpha: 0.5),
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
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.hasMoreThan1Loop ? widget.onNextLoop : null,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }

  void _handleTimelineInteraction(Offset localPosition) {
    // Calculate position percentage (constrained between 0 and 1)
    final percentage = (localPosition.dx / _timelineWidth).clamp(0.0, 1.0);

    // Convert to duration
    final newPosition = Duration(
      milliseconds: (percentage * widget.songDuration.inMilliseconds).round(),
    );

    widget.onSeek(newPosition);
  }
}

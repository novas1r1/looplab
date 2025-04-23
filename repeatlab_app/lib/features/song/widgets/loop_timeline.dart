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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Previous loop button
        IconButton(
          onPressed: widget.hasMoreThan1Loop ? widget.onPreviousLoop : null,
          icon: const Icon(Icons.skip_previous),
        ),
        // Timeline container
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final RenderBox box = context.findRenderObject()! as RenderBox;
              final localPosition = details.localPosition;
              final timelineWidth = box.size.width;

              // Calculate position percentage (constrained between 0 and 1)
              final percentage = (localPosition.dx / timelineWidth).clamp(0.0, 1.0);

              // Convert to duration
              final newPosition = Duration(
                milliseconds: (percentage * widget.songDuration.inMilliseconds).round(),
              );

              widget.onSeek(newPosition);
            },
            child: Container(
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
                        (MediaQuery.of(context).size.width - 96), // Subtract space for buttons
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
                    final width =
                        MediaQuery.of(context).size.width - 96; // Subtract space for buttons

                    return Positioned(
                      left: startPosition * width,
                      width: (endPosition - startPosition) * width,
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
        // Next loop button
        IconButton(
          onPressed: widget.hasMoreThan1Loop ? widget.onNextLoop : null,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}

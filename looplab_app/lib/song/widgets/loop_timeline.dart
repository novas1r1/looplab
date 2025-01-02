import 'package:flutter/material.dart';
import 'package:looplab/models/loop.dart';

class LoopTimeline extends StatelessWidget {
  final List<Loop> loops;
  final Duration songDuration;
  final Duration currentPosition;
  final void Function(Loop loop)? onLoopTap;

  const LoopTimeline({
    super.key,
    required this.loops,
    required this.songDuration,
    required this.currentPosition,
    this.onLoopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Current position indicator
          Positioned(
            left:
                (currentPosition.inMilliseconds / songDuration.inMilliseconds) *
                    MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          // Loop containers
          ...loops.map((loop) {
            if (loop.start == null || loop.end == null) {
              return const SizedBox.shrink();
            }

            final startPosition =
                loop.start!.inMilliseconds / songDuration.inMilliseconds;
            final endPosition =
                loop.end!.inMilliseconds / songDuration.inMilliseconds;
            final width = MediaQuery.of(context).size.width;

            return Positioned(
              left: startPosition * width,
              width: (endPosition - startPosition) * width,
              top: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: () => onLoopTap?.call(loop),
                child: Container(
                  decoration: BoxDecoration(
                    color: loop.color.color.withOpacity(0.5),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
}

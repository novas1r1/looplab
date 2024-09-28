import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:looplab/models/loop.dart';

class WavePainter extends CustomPainter {
  /// Wave data given for the duration of the song.
  final Float32List data;

  /// Duration of the song.
  final Duration duration;

  /// Current position of the song.
  final Duration currentPosition;

  /// Loop start position of the song.
  final List<Loop> loops;

  const WavePainter({
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.loops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    final paintPlayed = Paint()
      ..color = Colors.blue.shade200
      ..strokeWidth = 1;

    final durationInMilliseconds = duration.inMilliseconds.toDouble();

    // Function to scale milliseconds to canvas width
    double scaleX(double milliseconds) {
      return (milliseconds / durationInMilliseconds) * size.width;
    }

    // paint loop start
    // if loops.isNotEmpty
    if (loops.isNotEmpty) {
      for (final loop in loops) {
        if (loop.start == null && loop.end == null) {
          continue;
        }

        if (loop.start != null) {
          final paintLoopStart = Paint()
            ..color = Colors.purple
            ..strokeWidth = 2;

          final xStart = scaleX(loop.start!.inMilliseconds.toDouble());
          canvas.drawLine(
            Offset(xStart, 0),
            Offset(xStart, size.height),
            paintLoopStart,
          );

          // add text to the top of the line with "loop.name Start"
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${loop.name} Start',
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 12,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(xStart + 4, 0));
        }

        if (loop.end != null) {
          // paint loop end
          final endPosition = loop.end;
          final paintLoopEnd = Paint()
            ..color = Colors.purple
            ..strokeWidth = 2;

          final xEnd = scaleX(endPosition!.inMilliseconds.toDouble());
          canvas.drawLine(
            Offset(xEnd, 0),
            Offset(xEnd, size.height),
            paintLoopEnd,
          );

          // add text to the top of the line with "loop.name End"
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${loop.name} End',
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 12,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(xEnd - textPainter.width - 4, size.height - 14));
        }
      }
    }

    final currentPositionInMilliseconds = currentPosition.inMilliseconds;
    // final durationInMilliseconds = duration.inMilliseconds;

    // Calculate the fraction of the song played
    final playedFraction = currentPositionInMilliseconds / durationInMilliseconds;
    final playedDataLength = (playedFraction * data.length).toInt();

    for (int i = 0; i < data.length; i++) {
      final barHeight = size.height * data[i] * 2;

      // Use yellow paint for the part that has been played
      if (i <= playedDataLength) {
        canvas.drawLine(
          Offset(i.toDouble(), (size.height - barHeight) / 2),
          Offset(i.toDouble(), (size.height + barHeight) / 2),
          paintPlayed,
        );
      } else {
        // Use white paint for the remaining part
        canvas.drawLine(
          Offset(i.toDouble(), (size.height - barHeight) / 2),
          Offset(i.toDouble(), (size.height + barHeight) / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }
}

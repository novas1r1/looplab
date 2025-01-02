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

  final Color colorPlayed;
  final Color colorUnplayed;

  const WavePainter({
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.loops,
    required this.colorPlayed,
    required this.colorUnplayed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorUnplayed
      ..strokeWidth = 1;

    final paintPlayed = Paint()
      ..color = colorPlayed
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
            ..color = loop.color.color
            ..strokeWidth = 2;

          final xStart = scaleX(loop.start!.inMilliseconds.toDouble());
          canvas.drawLine(
            Offset(xStart, 0),
            Offset(xStart, size.height),
            paintLoopStart,
          );

          // also draw horizontal line at the top and the bottom of the line to the right
          canvas.drawLine(
            Offset(xStart, 1),
            Offset(xStart + 10, 1),
            paintLoopStart,
          );

          canvas.drawLine(
            Offset(xStart, size.height - 1),
            Offset(xStart + 10, size.height - 1),
            paintLoopStart,
          );

          // add text to the top of the line with "loop.name Start"
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${loop.name} Start',
              style: TextStyle(
                color: loop.color.color,
                fontSize: 10,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(xStart + 4, 2));
        }

        if (loop.end != null) {
          // paint loop end
          final endPosition = loop.end;
          final paintLoopEnd = Paint()
            ..color = loop.color.color
            ..strokeWidth = 2;

          final xEnd = scaleX(endPosition!.inMilliseconds.toDouble());
          canvas.drawLine(
            Offset(xEnd, 0),
            Offset(xEnd, size.height),
            paintLoopEnd,
          );

          // also draw horizontal line at the top and the bottom of the line to the left
          canvas.drawLine(
            Offset(xEnd, 1),
            Offset(xEnd - 10, 1),
            paintLoopEnd,
          );

          canvas.drawLine(
            Offset(xEnd, size.height - 1),
            Offset(xEnd - 10, size.height - 1),
            paintLoopEnd,
          );

          // add text to the top of the line with "loop.name End"
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${loop.name} End',
              style: TextStyle(
                color: loop.color.color,
                fontSize: 10,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(xEnd - textPainter.width - 4, size.height - 16),
          );
        }
      }
    }

    final currentPositionInMilliseconds = currentPosition.inMilliseconds;
    // final durationInMilliseconds = duration.inMilliseconds;

    // Calculate the fraction of the song played
    final playedFraction =
        currentPositionInMilliseconds / durationInMilliseconds;
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

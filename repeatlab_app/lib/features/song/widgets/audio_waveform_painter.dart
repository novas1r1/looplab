import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:repeatlab/data/models/loop.dart';

class AudioWaveformPainter extends CustomPainter {
  final Color waveColor;
  final Waveform waveform;
  final Duration start;
  final Duration duration;
  final Duration currentPosition;
  final List<Loop> loops;
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final double zoomScale;
  final String startText;
  final String endText;

  const AudioWaveformPainter({
    required this.waveColor,
    required this.waveform,
    required this.start,
    required this.duration,
    required this.currentPosition,
    required this.loops,
    required this.scale,
    required this.strokeWidth,
    required this.pixelsPerStep,
    required this.zoomScale,
    required this.startText,
    required this.endText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth;

    final paintPlayed = Paint()
      ..color = waveColor
      ..strokeWidth = strokeWidth;

    final durationInMilliseconds = duration.inMilliseconds.toDouble();

    // Function to scale milliseconds to canvas width
    double scaleX(double milliseconds) {
      return (milliseconds / durationInMilliseconds) * size.width;
    }

    // Paint loop markers
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

          // Draw horizontal lines at top and bottom
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

          // Add start text
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${loop.name} $startText',
              style: TextStyle(
                color: loop.color.color,
                fontSize: 10,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(xStart + 4, 4));
        }

        if (loop.end != null) {
          final paintLoopEnd = Paint()
            ..color = loop.color.color
            ..strokeWidth = 2;

          final xEnd = scaleX(loop.end!.inMilliseconds.toDouble());
          canvas.drawLine(
            Offset(xEnd, 0),
            Offset(xEnd, size.height),
            paintLoopEnd,
          );

          // Draw horizontal lines at top and bottom
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

          // Add end text
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${loop.name} $endText',
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
    final playedFraction = currentPositionInMilliseconds / durationInMilliseconds;
    final playedDataLength = (playedFraction * waveform.length).toInt();

    // Draw waveform
    for (int i = 0; i < waveform.length; i++) {
      final barHeight = size.height * waveform[i] * scale;
      final x = i * pixelsPerStep * zoomScale;
      final centerY = size.height / 2;
      final topY = centerY - (barHeight / 2);
      final bottomY = centerY + (barHeight / 2);

      if (i <= playedDataLength) {
        canvas.drawLine(
          Offset(x, topY),
          Offset(x, bottomY),
          paintPlayed,
        );
      } else {
        canvas.drawLine(
          Offset(x, topY),
          Offset(x, bottomY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return waveColor != oldDelegate.waveColor ||
        waveform != oldDelegate.waveform ||
        start != oldDelegate.start ||
        duration != oldDelegate.duration ||
        currentPosition != oldDelegate.currentPosition ||
        loops != oldDelegate.loops ||
        scale != oldDelegate.scale ||
        strokeWidth != oldDelegate.strokeWidth ||
        pixelsPerStep != oldDelegate.pixelsPerStep ||
        zoomScale != oldDelegate.zoomScale;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:repeatlab/data/models/loop.dart';

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
  final double zoomScale;

  final String startText;
  final String endText;

  // Cache for precomputed waveform paths keyed by data length, zoomScale and
  // height. This avoids rebuilding thousands of line segments every frame.
  static final Map<String, Path> _waveformCache = {};

  const WavePainter({
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.loops,
    required this.colorPlayed,
    required this.colorUnplayed,
    required this.startText,
    required this.endText,
    this.zoomScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final durationInMilliseconds = duration.inMilliseconds.toDouble();

    // -------------------------------------------------------------------
    // Draw waveform (cached path) once, then overlay "played" colour using a
    // clip rect. This removes the expensive per-frame loop over every sample.
    // -------------------------------------------------------------------

    final barSpacing = zoomScale; // Same calculation as before

    final cacheKey = '${data.length}_${barSpacing}_${size.height}';

    Path waveformPath;
    if (_waveformCache.containsKey(cacheKey)) {
      waveformPath = _waveformCache[cacheKey]!;
    } else {
      waveformPath = Path();

      for (int i = 0; i < data.length; i++) {
        final barHeight = size.height * data[i] * 2;
        final x = i * barSpacing;

        waveformPath.moveTo(x, (size.height - barHeight) / 2);
        waveformPath.lineTo(x, (size.height + barHeight) / 2);
      }

      _waveformCache[cacheKey] = waveformPath;
    }

    // Played vs unplayed paints
    final paintUnplayed = Paint()
      ..color = colorUnplayed
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final paintPlayed = Paint()
      ..color = colorPlayed
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw entire waveform with unplayed colour
    canvas.drawPath(waveformPath, paintUnplayed);

    // Calculate played width based on current position
    final currentPositionInMilliseconds = currentPosition.inMilliseconds
        .toDouble();
    final playedFraction =
        currentPositionInMilliseconds / durationInMilliseconds;
    final playedWidth = playedFraction * (data.length * barSpacing);

    // Overlay played part using clip rect
    if (playedWidth > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, playedWidth, size.height));
      canvas.drawPath(waveformPath, paintPlayed);
      canvas.restore();
    }

    // Draw loops on top
    if (loops.isNotEmpty) {
      _paintLoops(canvas, size, durationInMilliseconds);
    }

    // Finished repaint
    return;
  }

  void _paintLoops(
    Canvas canvas,
    Size size,
    double durationInMilliseconds,
  ) {
    // Function to scale milliseconds to canvas width
    double scaleX(double milliseconds) {
      return (milliseconds / durationInMilliseconds) * size.width;
    }

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

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return data != oldDelegate.data ||
        duration != oldDelegate.duration ||
        currentPosition != oldDelegate.currentPosition ||
        !listEquals(loops, oldDelegate.loops) ||
        colorPlayed != oldDelegate.colorPlayed ||
        colorUnplayed != oldDelegate.colorUnplayed ||
        zoomScale != oldDelegate.zoomScale;
  }
}

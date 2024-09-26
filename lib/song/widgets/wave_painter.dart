import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  /// Wave data given for the duration of the song.
  final Float32List data;

  /// Duration of the song.
  final Duration duration;

  /// Current position of the song.
  final Duration currentPosition;

  /// Loop start position of the song.
  final Duration? loopStartPosition;

  /// Loop end position of the song.
  final Duration? loopEndPosition;

  const WavePainter({
    required this.data,
    required this.duration,
    required this.currentPosition,
    this.loopStartPosition,
    this.loopEndPosition,
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
    if (loopStartPosition != null) {
      final paintLoopStart = Paint()
        ..color = Colors.purple
        ..strokeWidth = 2;

      final x = scaleX(loopStartPosition!.inMilliseconds.toDouble());
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paintLoopStart,
      );
    }

    // paint loop end
    if (loopEndPosition != null) {
      final paintLoopEnd = Paint()
        ..color = Colors.purple
        ..strokeWidth = 2;

      final x = scaleX(loopEndPosition!.inMilliseconds.toDouble());
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paintLoopEnd,
      );
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

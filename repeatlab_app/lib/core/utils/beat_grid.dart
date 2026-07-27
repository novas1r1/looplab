// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:math' as math;

/// Pure beat-grid math for metronome alignment.
///
/// Everything here works in *song time* (milliseconds into the recording),
/// which is speed-independent: the beat period derives from the song's
/// original BPM, and positions come from the player's position (which also
/// advances in song time). Callers convert to wall-clock time by dividing
/// by the playback speed.
abstract final class BeatGrid {
  /// Beat period in song-time milliseconds for [originalBpm].
  static double beatPeriodMs(int originalBpm) => 60000.0 / originalBpm;

  /// Best-fit beat phase (0 <= result < [periodMs]) of the given tap
  /// positions, computed as a circular mean so taps straddling a beat
  /// boundary (e.g. 490 ms and 10 ms at a 500 ms period) average to the
  /// boundary instead of the meaningless linear middle.
  ///
  /// Returns null when [positionsMs] is empty. When the taps cancel out
  /// entirely (degenerate, e.g. two taps exactly half a period apart) the
  /// last tap's phase is used.
  static int? circularMeanPhaseMs(List<int> positionsMs, double periodMs) {
    if (positionsMs.isEmpty || periodMs <= 0) return null;

    var sumSin = 0.0;
    var sumCos = 0.0;
    for (final positionMs in positionsMs) {
      final angle = 2 * math.pi * (positionMs % periodMs) / periodMs;
      sumSin += math.sin(angle);
      sumCos += math.cos(angle);
    }

    double phase;
    if (sumSin.abs() < 1e-9 && sumCos.abs() < 1e-9) {
      phase = positionsMs.last % periodMs;
    } else {
      phase = math.atan2(sumSin, sumCos) / (2 * math.pi) * periodMs;
    }

    if (phase < 0) phase += periodMs;
    return phase.round() % periodMs.round();
  }

  /// Song-time milliseconds from [positionMs] until the next beat of the
  /// grid `anchorMs + n * periodMs`. Returns 0 when the position sits
  /// exactly on a beat.
  static double songMsToNextBeat({
    required int positionMs,
    required int anchorMs,
    required double periodMs,
  }) {
    final phase =
        ((positionMs - anchorMs) % periodMs + periodMs) % periodMs;
    return (periodMs - phase) % periodMs;
  }
}

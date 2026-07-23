import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/core/utils/beat_grid.dart';

void main() {
  group('BeatGrid', () {
    group('beatPeriodMs', () {
      test('derives the song-time beat period from the original BPM', () {
        expect(BeatGrid.beatPeriodMs(120), 500.0);
        expect(BeatGrid.beatPeriodMs(60), 1000.0);
      });
    });

    group('circularMeanPhaseMs', () {
      test('returns null for empty taps or invalid period', () {
        expect(BeatGrid.circularMeanPhaseMs([], 500), isNull);
        expect(BeatGrid.circularMeanPhaseMs([100], 0), isNull);
      });

      test('averages taps on consecutive beats to their common phase', () {
        expect(
          BeatGrid.circularMeanPhaseMs([10100, 10600, 11100], 500),
          100,
        );
      });

      test('averages jittered taps to the central phase', () {
        // Phases 90, 100, 110 around beats at phase 100.
        expect(
          BeatGrid.circularMeanPhaseMs([1090, 1600, 2110], 500),
          100,
        );
      });

      test('handles taps straddling the beat boundary circularly', () {
        // Phases 490 and 10 must average to 0/500 (the boundary), not to
        // the linear middle 250.
        expect(
          BeatGrid.circularMeanPhaseMs([490, 1010], 500),
          0,
        );
      });

      test('falls back to the last tap when taps cancel out', () {
        // Two taps exactly half a period apart have no circular mean.
        expect(
          BeatGrid.circularMeanPhaseMs([100, 350], 500),
          350,
        );
      });
    });

    group('songMsToNextBeat', () {
      test('returns the distance to the next grid beat', () {
        expect(
          BeatGrid.songMsToNextBeat(
            positionMs: 10300,
            anchorMs: 100,
            periodMs: 500,
          ),
          300.0,
        );
      });

      test('returns 0 exactly on a beat', () {
        expect(
          BeatGrid.songMsToNextBeat(
            positionMs: 10100,
            anchorMs: 100,
            periodMs: 500,
          ),
          0.0,
        );
      });

      test('handles positions before the anchor', () {
        expect(
          BeatGrid.songMsToNextBeat(
            positionMs: 0,
            anchorMs: 700,
            periodMs: 500,
          ),
          200.0,
        );
      });
    });
  });
}

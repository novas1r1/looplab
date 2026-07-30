import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/features/pitch_control/util/concert_pitch.dart';

void main() {
  group('concertPitchHz', () {
    test('no fine tune is concert A440', () {
      expect(concertPitchHz(0), closeTo(440.0, 0.0001));
    });

    test('the range ends land a quarter tone either side', () {
      expect(concertPitchHz(50), closeTo(452.89, 0.01));
      expect(concertPitchHz(-50), closeTo(427.47, 0.01));
    });

    test('matches the design reference of +18 ct', () {
      // The Figma "fine tune engaged" state shows A ~ 445 Hz at +18 ct.
      expect(concertPitchHz(18), closeTo(444.6, 0.1));
    });

    test('is strictly monotonic across the range', () {
      var previous = concertPitchHz(-50);
      for (var cents = -49; cents <= 50; cents++) {
        final current = concertPitchHz(cents);
        expect(current, greaterThan(previous));
        previous = current;
      }
    });

    test('one decimal still distinguishes adjacent cents', () {
      // 1 Hz is ~3.9 cents at A440, so whole-hertz rounding would collapse
      // several cent values onto the same reading. Guards the display format.
      final low = concertPitchHz(10).toStringAsFixed(1);
      final high = concertPitchHz(11).toStringAsFixed(1);
      expect(low, isNot(high));
    });
  });
}

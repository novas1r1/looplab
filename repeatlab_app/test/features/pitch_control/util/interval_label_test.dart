import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/features/pitch_control/util/interval_label.dart';
import 'package:repeatlab/l10n/arb/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('intervalLabel', () {
    test('zero is the original pitch, with no direction', () {
      expect(intervalLabel(l10n, 0), 'Original pitch');
    });

    test('names the common transpositions the way players say them', () {
      expect(intervalLabel(l10n, -1), 'half step down');
      expect(intervalLabel(l10n, -2), 'whole step down');
      expect(intervalLabel(l10n, -3), 'minor 3rd down');
      expect(intervalLabel(l10n, -5), '4th down');
      expect(intervalLabel(l10n, -7), '5th down');
      expect(intervalLabel(l10n, -12), 'octave down');

      expect(intervalLabel(l10n, 1), 'half step up');
      expect(intervalLabel(l10n, 2), 'whole step up');
      expect(intervalLabel(l10n, 4), 'major 3rd up');
      expect(intervalLabel(l10n, 6), 'tritone up');
      expect(intervalLabel(l10n, 7), '5th up');
      expect(intervalLabel(l10n, 12), 'octave up');
    });

    test('covers every value the pitch control offers', () {
      for (var semitones = -12; semitones <= 12; semitones++) {
        expect(
          intervalLabel(l10n, semitones),
          isNotEmpty,
          reason: 'no label for $semitones semitones',
        );
      }
    });

    test('is symmetric in magnitude, differing only in direction', () {
      for (var semitones = 1; semitones <= 12; semitones++) {
        final up = intervalLabel(l10n, semitones);
        final down = intervalLabel(l10n, -semitones);
        expect(up, isNot(down));
        expect(up, endsWith('up'));
        expect(down, endsWith('down'));
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/core/utils/musical_key.dart';

void main() {
  group('MusicalKey.parseTagBpm', () {
    test('parses plain and decimal values', () {
      expect(MusicalKey.parseTagBpm('128'), 128);
      expect(MusicalKey.parseTagBpm('128.00'), 128);
      expect(MusicalKey.parseTagBpm(' 95 '), 95);
      expect(MusicalKey.parseTagBpm('89.7'), 90);
    });

    test('rejects missing, unparseable, and out-of-range values', () {
      expect(MusicalKey.parseTagBpm(null), isNull);
      expect(MusicalKey.parseTagBpm(''), isNull);
      expect(MusicalKey.parseTagBpm('fast'), isNull);
      expect(MusicalKey.parseTagBpm('0'), isNull);
      expect(MusicalKey.parseTagBpm('5'), isNull);
      expect(MusicalKey.parseTagBpm('999'), isNull);
    });
  });

  group('MusicalKey.normalizeTagKey', () {
    test('normalizes valid keys', () {
      expect(MusicalKey.normalizeTagKey('Am'), 'Am');
      expect(MusicalKey.normalizeTagKey('F#'), 'F#');
      expect(MusicalKey.normalizeTagKey('bbm'), 'Bbm');
      expect(MusicalKey.normalizeTagKey(' c '), 'C');
      expect(MusicalKey.normalizeTagKey('G♯m'), 'G#m');
      expect(MusicalKey.normalizeTagKey('Ebmin'), 'Ebm');
    });

    test('rejects off-key, Camelot codes, and garbage', () {
      expect(MusicalKey.normalizeTagKey(null), isNull);
      expect(MusicalKey.normalizeTagKey('o'), isNull);
      expect(MusicalKey.normalizeTagKey('8A'), isNull);
      expect(MusicalKey.normalizeTagKey('H'), isNull);
      expect(MusicalKey.normalizeTagKey('C major'), isNull);
    });
  });

  group('MusicalKey.allKeys / canonicalize / displayLabel', () {
    test('allKeys holds 24 canonical keys, majors then minors', () {
      expect(MusicalKey.allKeys, hasLength(24));
      expect(MusicalKey.allKeys.first, 'C');
      expect(MusicalKey.allKeys[12], 'Cm');
      expect(MusicalKey.allKeys.toSet(), hasLength(24));
      // Every canonical key round-trips through canonicalize
      for (final key in MusicalKey.allKeys) {
        expect(MusicalKey.canonicalize(key), key);
      }
    });

    test('canonicalize maps flat spellings to sharp names', () {
      expect(MusicalKey.canonicalize('Bbm'), 'A#m');
      expect(MusicalKey.canonicalize('Gb'), 'F#');
      expect(MusicalKey.canonicalize('garbage'), isNull);
    });

    test('displayLabel shows glyphs and enharmonic pairs', () {
      expect(MusicalKey.displayLabel('C'), 'C');
      expect(MusicalKey.displayLabel('Am'), 'Am');
      expect(MusicalKey.displayLabel('C#'), 'C♯ / D♭');
      expect(MusicalKey.displayLabel('A#m'), 'A♯m / B♭m');
      expect(MusicalKey.displayLabel('Bbm'), 'A♯m / B♭m');
      expect(MusicalKey.displayLabel('8A'), '8A');
    });

    test('conventionalLabel spells the 12 major keys as musicians write them', () {
      expect(
        MusicalKey.sameModeKeys('C')!.map(MusicalKey.conventionalLabel).toList(),
        ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'],
      );
    });

    test('conventionalLabel spells the 12 minor keys as musicians write them', () {
      // Differs from the major set at three pitch classes: minor prefers the
      // sharp spelling for C♯m and G♯m, where major prefers D♭ and A♭.
      expect(
        MusicalKey.sameModeKeys('Am')!
            .map(MusicalKey.conventionalLabel)
            .toList(),
        [
          'Cm',
          'C♯m',
          'Dm',
          'E♭m',
          'Em',
          'Fm',
          'F♯m',
          'Gm',
          'G♯m',
          'Am',
          'B♭m',
          'Bm',
        ],
      );
    });

    test('conventionalLabel never produces an unwritable key', () {
      // A mode-blind "prefer sharps" helper would emit D♯ (9 accidentals),
      // G♯ (8) and A♯ (10) major — keys nobody writes or reads.
      final majors = MusicalKey.sameModeKeys('C')!
          .map(MusicalKey.conventionalLabel)
          .toList();
      expect(majors, isNot(contains('D♯')));
      expect(majors, isNot(contains('G♯')));
      expect(majors, isNot(contains('A♯')));
      // And the minor set must not invent D♭m, which is written C♯m.
      final minors = MusicalKey.sameModeKeys('Am')!
          .map(MusicalKey.conventionalLabel)
          .toList();
      expect(minors, isNot(contains('D♭m')));
    });

    test('conventionalLabel accepts flat input and unknown values', () {
      expect(MusicalKey.conventionalLabel('Bbm'), 'B♭m');
      expect(MusicalKey.conventionalLabel('Gb'), 'F♯');
      expect(MusicalKey.conventionalLabel('8A'), '8A');
    });
  });

  group('MusicalKey.signedOffset / sameModeKeys', () {
    test('picks the shorter transposition direction', () {
      expect(MusicalKey.signedOffset('Am', 'Cm'), 3);
      expect(MusicalKey.signedOffset('C', 'B'), -1);
      expect(MusicalKey.signedOffset('C', 'C'), 0);
      expect(MusicalKey.signedOffset('G', 'C'), 5);
      expect(MusicalKey.signedOffset('C', 'G'), -5);
      expect(MusicalKey.signedOffset('Bbm', 'A#m'), 0);
    });

    test('the tritone resolves downward from either side', () {
      // Equidistant either way, so the tie-break is a choice: down, because
      // an upward shift thins the low end of a full mix.
      expect(MusicalKey.signedOffset('C', 'F#'), -6);
      expect(MusicalKey.signedOffset('F#', 'C'), -6);
      expect(MusicalKey.signedOffset('Em', 'A#m'), -6);
    });

    test('round-trips through transpose', () {
      for (final from in MusicalKey.allKeys) {
        for (final to in MusicalKey.sameModeKeys(from)!) {
          final offset = MusicalKey.signedOffset(from, to)!;
          expect(offset, inInclusiveRange(-6, 5));
          expect(MusicalKey.transpose(from, offset), to);
        }
      }
    });

    test('rejects mode mismatches and garbage', () {
      expect(MusicalKey.signedOffset('Am', 'C'), isNull);
      expect(MusicalKey.signedOffset('C', 'Am'), isNull);
      expect(MusicalKey.signedOffset('8A', 'C'), isNull);
    });

    test('sameModeKeys returns the 12 keys of the matching mode', () {
      expect(MusicalKey.sameModeKeys('C'), MusicalKey.allKeys.sublist(0, 12));
      expect(MusicalKey.sameModeKeys('Bbm'), MusicalKey.allKeys.sublist(12));
      expect(MusicalKey.sameModeKeys('8A'), isNull);
    });
  });

  group('MusicalKey.transpose', () {
    test('transposes up and down with wrap-around', () {
      expect(MusicalKey.transpose('Am', 3), 'Cm');
      expect(MusicalKey.transpose('C', 12), 'C');
      expect(MusicalKey.transpose('C', -12), 'C');
      expect(MusicalKey.transpose('B', 1), 'C');
      expect(MusicalKey.transpose('C', -1), 'B');
      expect(MusicalKey.transpose('F#', 2), 'G#');
      expect(MusicalKey.transpose('Bbm', -2), 'G#m');
      expect(MusicalKey.transpose('E', 7), 'B');
    });

    test('returns null for unparseable keys', () {
      expect(MusicalKey.transpose('o', 3), isNull);
      expect(MusicalKey.transpose('8A', 3), isNull);
    });
  });
}

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
  });

  group('MusicalKey.signedOffset / sameModeKeys', () {
    test('picks the shorter transposition direction', () {
      expect(MusicalKey.signedOffset('Am', 'Cm'), 3);
      expect(MusicalKey.signedOffset('C', 'B'), -1);
      expect(MusicalKey.signedOffset('C', 'F#'), 6);
      expect(MusicalKey.signedOffset('C', 'C'), 0);
      expect(MusicalKey.signedOffset('G', 'C'), 5);
      expect(MusicalKey.signedOffset('C', 'G'), -5);
      expect(MusicalKey.signedOffset('Bbm', 'A#m'), 0);
    });

    test('round-trips through transpose', () {
      for (final from in MusicalKey.allKeys) {
        for (final to in MusicalKey.sameModeKeys(from)!) {
          final offset = MusicalKey.signedOffset(from, to)!;
          expect(offset, inInclusiveRange(-5, 6));
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

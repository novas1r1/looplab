// ignore_for_file: avoid_classes_with_only_static_members

/// Helpers for musical key (Tonart) tags and pitch-shift transposition.
///
/// Keys follow the ID3v2 TKEY convention: a note letter A-G, an optional
/// `#`/`b` accidental, and an optional `m` suffix for minor — e.g. "C",
/// "F#", "Bbm". Anything else (including the TKEY "o" for off-key and
/// Camelot codes like "8A" written by some DJ tools) is left untouched.
abstract final class MusicalKey {
  static const List<String> _sharpNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
  ];

  static const Map<String, int> _noteIndex = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  static final RegExp _keyPattern = RegExp(r'^([A-Ga-g])([#b♯♭]?)(m|min)?$');

  /// All 24 keys in canonical (sharp-name) form: 12 major then 12 minor.
  /// These are the values offered by the key dropdown and stored on [Song].
  static final List<String> allKeys = [
    ..._sharpNames,
    ..._sharpNames.map((n) => '${n}m'),
  ];

  /// Maps any recognizable key spelling to its canonical sharp-name form
  /// ("Bbm" → "A#m", "F#" → "F#"). Null when not a recognizable key.
  static String? canonicalize(String key) => transpose(key, 0);

  /// The 12 canonical keys sharing [key]'s mode (major or minor) — the valid
  /// transposition targets, since pitch shifting never changes the mode.
  /// Null when [key] is not a recognizable key.
  static List<String>? sameModeKeys(String key) {
    final canonical = canonicalize(key);
    if (canonical == null) return null;
    final minor = canonical.endsWith('m');
    return minor ? allKeys.sublist(12) : allKeys.sublist(0, 12);
  }

  /// Semitone offset that transposes [from] into [to], picking the shorter
  /// direction (range −5..+6): ("Am", "Cm") → 3, ("C", "B") → −1. Null when
  /// either key is unrecognizable or the modes differ (a pitch shift cannot
  /// turn a major key into a minor one).
  static int? signedOffset(String from, String to) {
    final fromMatch = _keyPattern.firstMatch(from.trim());
    final toMatch = _keyPattern.firstMatch(to.trim());
    if (fromMatch == null || toMatch == null) return null;
    if ((fromMatch.group(3) != null) != (toMatch.group(3) != null)) return null;

    var offset = (_indexOf(toMatch) - _indexOf(fromMatch)) % 12;
    if (offset < 0) offset += 12;
    if (offset > 6) offset -= 12;
    return offset;
  }

  static int _indexOf(RegExpMatch match) {
    final index = _noteIndex[match.group(1)!.toUpperCase()]!;
    return index +
        switch (match.group(2)) {
          '#' || '♯' => 1,
          'b' || '♭' => -1,
          _ => 0,
        };
  }

  /// Human-friendly label with proper glyphs and both enharmonic spellings:
  /// "C#" → "C♯ / D♭", "A#m" → "A♯m / B♭m", "C" → "C". Falls back to the
  /// raw value for unrecognizable keys.
  static String displayLabel(String key) {
    const flatEquivalents = {
      'C#': 'D♭',
      'D#': 'E♭',
      'F#': 'G♭',
      'G#': 'A♭',
      'A#': 'B♭',
    };

    final match = _keyPattern.firstMatch(key.trim());
    if (match == null) return key;

    final minor = match.group(3) != null ? 'm' : '';
    final canonical = canonicalize(key)!;
    final note = minor.isEmpty
        ? canonical
        : canonical.substring(0, canonical.length - 1);

    final sharpLabel = '${note.replaceAll('#', '♯')}$minor';
    final flat = flatEquivalents[note];
    if (flat == null) return sharpLabel;
    return '$sharpLabel / $flat$minor';
  }

  /// Parses a raw TBPM tag value ("128", "128.00", " 95 ") into a usable
  /// BPM, or null when missing, unparseable, or outside the range the speed
  /// controls support.
  static int? parseTagBpm(String? raw, {int min = 20, int max = 400}) {
    if (raw == null) return null;
    final value = double.tryParse(raw.trim());
    if (value == null) return null;
    final bpm = value.round();
    if (bpm < min || bpm > max) return null;
    return bpm;
  }

  /// Normalizes a raw TKEY tag value to canonical form ("f# m" is not valid
  /// TKEY, but be lenient about case and whitespace: "bbm" → "Bbm").
  /// Returns null when missing or not a recognizable key.
  static String? normalizeTagKey(String? raw) {
    if (raw == null) return null;
    final match = _keyPattern.firstMatch(raw.trim());
    if (match == null) return null;

    final letter = match.group(1)!.toUpperCase();
    final accidental = switch (match.group(2)) {
      '♯' => '#',
      '♭' => 'b',
      final a => a ?? '',
    };
    final minor = match.group(3) != null ? 'm' : '';
    return '$letter$accidental$minor';
  }

  /// Transposes [key] by [semitones], e.g. ("Am", 3) → "Cm". Output uses
  /// sharp names. Returns null when [key] is not a recognizable key.
  static String? transpose(String key, int semitones) {
    final match = _keyPattern.firstMatch(key.trim());
    if (match == null) return null;

    var index = _noteIndex[match.group(1)!.toUpperCase()]!;
    index += switch (match.group(2)) {
      '#' || '♯' => 1,
      'b' || '♭' => -1,
      _ => 0,
    };

    final transposed = (index + semitones) % 12;
    final name = _sharpNames[(transposed + 12) % 12];
    final minor = match.group(3) != null ? 'm' : '';
    return '$name$minor';
  }
}

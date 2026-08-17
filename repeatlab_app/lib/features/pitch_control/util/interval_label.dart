import 'package:repeatlab/l10n/arb/app_localizations.dart';

/// Names a transposition the way a musician would say it — "whole step down",
/// "5th up", "octave down" — instead of counting semitones.
///
/// Players think in intervals, not in semitone counts, and naming the interval
/// quietly teaches the relationship to users who never learned the theory.
/// Handles the full −12..+12 range the pitch control offers.
String intervalLabel(AppLocalizations l10n, int semitones) {
  if (semitones == 0) return l10n.intervalUnison;

  final magnitude = _magnitudeLabel(l10n, semitones.abs());
  return semitones < 0 ? l10n.intervalDown(magnitude) : l10n.intervalUp(magnitude);
}

String _magnitudeLabel(AppLocalizations l10n, int semitones) => switch (semitones) {
  1 => l10n.intervalHalfStep,
  2 => l10n.intervalWholeStep,
  3 => l10n.intervalMinorThird,
  4 => l10n.intervalMajorThird,
  5 => l10n.intervalFourth,
  6 => l10n.intervalTritone,
  7 => l10n.intervalFifth,
  8 => l10n.intervalMinorSixth,
  9 => l10n.intervalMajorSixth,
  10 => l10n.intervalMinorSeventh,
  11 => l10n.intervalMajorSeventh,
  _ => l10n.intervalOctave,
};

import 'dart:math';

/// Concert pitch that playback sits at once [cents] of fine tune are applied,
/// assuming the recording itself is at A=440.
///
/// Takes the fine tune **only**, never the semitone transposition: including
/// it would report "A ≈ 220 Hz" at −12 semitones, which is true but useless as
/// a tuning target. The point of this number is to tell a player what to set
/// their tuner to, and a transposed song is still played against a normally
/// tuned instrument.
///
/// Render with one decimal — 1 Hz is roughly 3.9 cents at A440, so rounding to
/// whole hertz throws away most of the ±50 cent resolution.
double concertPitchHz(int cents) => 440 * pow(2, cents / 1200).toDouble();

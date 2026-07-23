// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:repeatlab/core/utils/beat_grid.dart';

/// Renders a metronome click track as a 16-bit mono PCM WAV covering the
/// whole song, with clicks placed on the song's beat grid
/// `anchor + offset + n * beatPeriod(bpm)`.
///
/// Everything works in *song time*: the rendered track is mixed with the
/// song into one file, so playback-speed and pitch changes apply to both
/// equally and the clicks can never drift — the core of the "baked click
/// track" metronome design (docs/plans/2026-07-23-metronome-track-design.md).
///
/// The click is a short sine burst with an exponential decay rather than a
/// sharp tick: soft transients survive the time-stretcher at extreme
/// slowdowns much better.
abstract final class ClickTrackRenderer {
  static const int sampleRate = 44100;

  /// Bump when the synthesis changes so cached mixes regenerate.
  static const int version = 1;

  static const double _accentFreqHz = 1600;
  static const double _beatFreqHz = 1050;
  static const double _subdivisionFreqHz = 800;

  static const double _accentGain = 1.0;
  static const double _beatGain = 0.8;
  static const double _subdivisionGain = 0.45;

  /// Nominal click length; shortened when pulses are packed tighter so
  /// clicks never overlap (e.g. 400 BPM sixteenths).
  static const double _clickMs = 45;

  /// Renders the click track. [anchorMs]/[offsetMs] shift the grid in song
  /// time; without a tap-to-align anchor the grid starts at the file start.
  /// [beatsPerBar] places the accent, [pulsesPerBeat] adds subdivision
  /// clicks between beats (1 = quarters only).
  static Uint8List renderWav({
    required int durationMs,
    required int bpm,
    int? anchorMs,
    int offsetMs = 0,
    int beatsPerBar = 4,
    int pulsesPerBeat = 1,
  }) {
    if (durationMs <= 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be positive');
    }
    if (bpm <= 0) {
      throw ArgumentError.value(bpm, 'bpm', 'must be positive');
    }
    final beats = beatsPerBar < 1 ? 1 : beatsPerBar;
    final pulses = pulsesPerBeat.clamp(1, 8);

    final periodMs = BeatGrid.beatPeriodMs(bpm);
    final baseMs = (anchorMs ?? 0) + offsetMs;
    final pulseGapMs = periodMs / pulses;
    final clickMs = math.min(_clickMs, pulseGapMs * 0.8);
    final clickSamples = (clickMs * sampleRate / 1000).round();

    final totalSamples = (durationMs * sampleRate / 1000).round();
    final samples = Int16List(totalSamples);

    // Beat indices n with anchor + offset + n*period inside [0, duration).
    final nStart = ((0 - baseMs) / periodMs).ceil();
    final nEnd = ((durationMs - baseMs) / periodMs).floor();

    for (var n = nStart; n <= nEnd; n++) {
      final beatMs = baseMs + n * periodMs;
      final isAccent = ((n % beats) + beats) % beats == 0;
      _addClick(
        samples,
        startMs: beatMs,
        freqHz: isAccent ? _accentFreqHz : _beatFreqHz,
        gain: isAccent ? _accentGain : _beatGain,
        clickSamples: clickSamples,
      );
      for (var k = 1; k < pulses; k++) {
        final subMs = beatMs + k * pulseGapMs;
        if (subMs >= durationMs) break;
        _addClick(
          samples,
          startMs: subMs,
          freqHz: _subdivisionFreqHz,
          gain: _subdivisionGain,
          clickSamples: clickSamples,
        );
      }
    }

    return _wrapWav(samples);
  }

  static void _addClick(
    Int16List samples, {
    required double startMs,
    required double freqHz,
    required double gain,
    required int clickSamples,
  }) {
    final start = (startMs * sampleRate / 1000).round();
    if (start >= samples.length) return;

    // 1 ms linear attack avoids a DC pop; exponential decay afterwards.
    const attackSamples = sampleRate ~/ 1000;
    final tau = clickSamples / 5.0;
    const peak = 0.85 * 32767;

    final end = math.min(start + clickSamples, samples.length);
    for (var i = math.max(0, -start); i < end - start; i++) {
      final attack = i < attackSamples ? i / attackSamples : 1.0;
      final envelope = attack * math.exp(-i / tau);
      final value =
          peak * gain * envelope * math.sin(2 * math.pi * freqHz * i / sampleRate);
      final mixed = samples[start + i] + value.round();
      samples[start + i] = mixed.clamp(-32768, 32767);
    }
  }

  static Uint8List _wrapWav(Int16List samples) {
    const headerBytes = 44;
    final dataBytes = samples.length * 2;
    final bytes = ByteData(headerBytes + dataBytes);

    void writeAscii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataBytes, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // fmt chunk size
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    writeAscii(36, 'data');
    bytes.setUint32(40, dataBytes, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(headerBytes + i * 2, samples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}

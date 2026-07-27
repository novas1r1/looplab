import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/core/utils/click_track_renderer.dart';

void main() {
  const sampleRate = ClickTrackRenderer.sampleRate;

  // PCM samples start after the 44-byte WAV header.
  Int16List samplesOf(Uint8List wav) => Int16List.sublistView(wav, 44);

  /// Peak absolute amplitude in the window [fromMs, toMs).
  int peakIn(Int16List samples, double fromMs, double toMs) {
    final from = (fromMs * sampleRate / 1000).round();
    final to = (toMs * sampleRate / 1000).round().clamp(0, samples.length);
    var peak = 0;
    for (var i = from; i < to; i++) {
      final v = samples[i].abs();
      if (v > peak) peak = v;
    }
    return peak;
  }

  group('ClickTrackRenderer', () {
    test('writes a valid 16-bit mono WAV header', () {
      final wav = ClickTrackRenderer.renderWav(durationMs: 1000, bpm: 120);
      final data = ByteData.sublistView(wav);

      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(data.getUint16(22, Endian.little), 1); // mono
      expect(data.getUint32(24, Endian.little), sampleRate);
      expect(data.getUint16(34, Endian.little), 16); // bits per sample

      const expectedSamples = sampleRate; // 1 s
      expect(data.getUint32(40, Endian.little), expectedSamples * 2);
      expect(wav.length, 44 + expectedSamples * 2);
    });

    test('places clicks on the beat grid and silence between them', () {
      // 120 BPM → beats at 0, 500, 1000, 1500 ms.
      final wav = ClickTrackRenderer.renderWav(durationMs: 2000, bpm: 120);
      final samples = samplesOf(wav);

      expect(peakIn(samples, 0, 50), greaterThan(1000));
      expect(peakIn(samples, 500, 550), greaterThan(1000));
      expect(peakIn(samples, 1500, 1550), greaterThan(1000));
      // Between clicks (well past the 45 ms click): silence.
      expect(peakIn(samples, 200, 450), 0);
      expect(peakIn(samples, 700, 950), 0);
    });

    test('anchor and offset shift the grid in song time', () {
      final wav = ClickTrackRenderer.renderWav(
        durationMs: 2000,
        bpm: 120,
        anchorMs: 100,
        offsetMs: 25,
      );
      final samples = samplesOf(wav);

      // Grid at 125 + n*500 → clicks at 125, 625; silence before the first.
      expect(peakIn(samples, 0, 120), 0);
      expect(peakIn(samples, 125, 175), greaterThan(1000));
      expect(peakIn(samples, 625, 675), greaterThan(1000));
    });

    test('the bar downbeat is accented louder than other beats', () {
      final wav = ClickTrackRenderer.renderWav(durationMs: 2500, bpm: 120);
      final samples = samplesOf(wav);

      final downbeat = peakIn(samples, 0, 50); // n=0 → accent in 4/4
      final beatTwo = peakIn(samples, 500, 550);
      final nextDownbeat = peakIn(samples, 2000, 2050); // n=4 → accent again

      expect(downbeat, greaterThan(beatTwo));
      expect((downbeat - nextDownbeat).abs(), lessThan(downbeat * 0.1));
    });

    test('subdivision adds quieter pulses between beats', () {
      final wav = ClickTrackRenderer.renderWav(
        durationMs: 1000,
        bpm: 120,
        pulsesPerBeat: 2,
      );
      final samples = samplesOf(wav);

      final beat = peakIn(samples, 500, 550);
      final sub = peakIn(samples, 250, 300);
      expect(sub, greaterThan(500));
      expect(sub, lessThan(beat));
    });

    test('no subdivision pulses without subdivision', () {
      final wav = ClickTrackRenderer.renderWav(durationMs: 1000, bpm: 120);
      final samples = samplesOf(wav);
      expect(peakIn(samples, 250, 300), 0);
    });

    test('rejects invalid input', () {
      expect(
        () => ClickTrackRenderer.renderWav(durationMs: 0, bpm: 120),
        throwsArgumentError,
      );
      expect(
        () => ClickTrackRenderer.renderWav(durationMs: 1000, bpm: 0),
        throwsArgumentError,
      );
    });

    test('clicks never overlap at extreme tempo and subdivision', () {
      // 400 BPM sixteenths → 37.5 ms between pulses; the click must shrink.
      final wav = ClickTrackRenderer.renderWav(
        durationMs: 1000,
        bpm: 400,
        pulsesPerBeat: 4,
      );
      final samples = samplesOf(wav);
      // No sample may clip even where envelopes could have summed.
      var maxAbs = 0;
      for (final s in samples) {
        if (s.abs() > maxAbs) maxAbs = s.abs();
      }
      expect(maxAbs, lessThanOrEqualTo((0.85 * 32767).ceil()));
    });
  });
}

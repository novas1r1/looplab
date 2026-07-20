// Explicit values in tests beat implicit helper defaults.
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:precise_metronome/precise_metronome.dart' as pm;
import 'package:repeatlab/data/services/song_metronome.dart';

class MockMetronome extends Mock implements pm.Metronome {}

void main() {
  late MockMetronome mockMetronome;
  late SongMetronome songMetronome;

  setUpAll(() {
    registerFallbackValue(pm.TimeSignature(4, 4));
    registerFallbackValue(pm.Subdivision.none);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockMetronome = MockMetronome();
    songMetronome = SongMetronome(metronome: mockMetronome);

    when(() => mockMetronome.init()).thenAnswer((_) async {});
    when(() => mockMetronome.isPlaying).thenReturn(false);
    when(() => mockMetronome.start(initialDelay: any(named: 'initialDelay')))
        .thenAnswer((_) async {});
    when(() => mockMetronome.stop()).thenAnswer((_) async {});
    when(() => mockMetronome.setTempo(any())).thenAnswer((_) async {});
    when(() => mockMetronome.setTimeSignature(any())).thenAnswer((_) async {});
    when(() => mockMetronome.setSubdivision(any())).thenAnswer((_) async {});
    when(() => mockMetronome.setVolume(any())).thenAnswer((_) async {});
    when(() => mockMetronome.nudge(any())).thenAnswer((_) async {});
    when(() => mockMetronome.dispose()).thenAnswer((_) async {});
  });

  Future<void> startAligned({
    int bpm = 120,
    int offsetMs = 0,
    int pulsesPerBeat = 1,
  }) {
    return songMetronome.startAligned(
      bpm: bpm,
      offsetMs: offsetMs,
      beatsPerBar: 4,
      beatUnit: 4,
      pulsesPerBeat: pulsesPerBeat,
      volume: 0.5,
    );
  }

  group('SongMetronome', () {
    group('startAligned', () {
      test('initializes lazily and applies full config before starting',
          () async {
        await startAligned(bpm: 120);

        verifyInOrder([
          () => mockMetronome.init(),
          () => mockMetronome.setTempo(120),
          () => mockMetronome.setTimeSignature(pm.TimeSignature(4, 4)),
          () => mockMetronome.setSubdivision(pm.Subdivision.none),
          () => mockMetronome.setVolume(0.5),
          () => mockMetronome.start(initialDelay: Duration.zero),
        ]);
      });

      test('init happens only once across calls', () async {
        await startAligned();
        await startAligned();

        verify(() => mockMetronome.init()).called(1);
      });

      test('stops a running metronome before restarting', () async {
        when(() => mockMetronome.isPlaying).thenReturn(true);

        await startAligned();

        verifyInOrder([
          () => mockMetronome.stop(),
          () => mockMetronome.start(
                initialDelay: any(named: 'initialDelay'),
              ),
        ]);
      });

      test('normalizes the offset into one beat period', () async {
        // 120 BPM → 500 ms beat period; 1250 ms ≡ 250 ms.
        await startAligned(bpm: 120, offsetMs: 1250);

        verify(
          () => mockMetronome.start(
            initialDelay: const Duration(milliseconds: 250),
          ),
        ).called(1);
      });

      test('normalizes negative offsets phase-equivalently', () async {
        // -100 ms at 120 BPM ≡ +400 ms.
        await startAligned(bpm: 120, offsetMs: -100);

        verify(
          () => mockMetronome.start(
            initialDelay: const Duration(milliseconds: 400),
          ),
        ).called(1);
      });

      test('clamps the tempo to the supported native range', () async {
        await startAligned(bpm: 500);

        verify(() => mockMetronome.setTempo(400)).called(1);
      });

      test('maps pulsesPerBeat to the package subdivision', () async {
        await startAligned(pulsesPerBeat: 3);

        verify(() => mockMetronome.setSubdivision(pm.Subdivision.triplet))
            .called(1);
      });
    });

    group('before init', () {
      test('live setters are no-ops so unsupported platforms never touch the '
          'plugin', () async {
        await songMetronome.setTempo(120);
        await songMetronome.setVolume(0.5);
        await songMetronome.setTimeSignature(3, 4);
        await songMetronome.setSubdivision(2);
        await songMetronome.nudge(const Duration(milliseconds: 25));
        await songMetronome.stop();
        await songMetronome.dispose();

        verifyZeroInteractions(mockMetronome);
      });
    });

    group('after init', () {
      setUp(() async {
        await songMetronome.ensureInit();
        clearInteractions(mockMetronome);
      });

      test('setTempo clamps into the native range', () async {
        await songMetronome.setTempo(10);
        verify(() => mockMetronome.setTempo(20)).called(1);

        await songMetronome.setTempo(240);
        verify(() => mockMetronome.setTempo(240)).called(1);
      });

      test('nudge forwards the delta', () async {
        await songMetronome.nudge(const Duration(milliseconds: -25));

        verify(
          () => mockMetronome.nudge(const Duration(milliseconds: -25)),
        ).called(1);
      });

      test('stop only forwards while playing', () async {
        await songMetronome.stop();
        verifyNever(() => mockMetronome.stop());

        when(() => mockMetronome.isPlaying).thenReturn(true);
        await songMetronome.stop();
        verify(() => mockMetronome.stop()).called(1);
      });

      test('dispose forwards and makes the wrapper inert', () async {
        await songMetronome.dispose();
        verify(() => mockMetronome.dispose()).called(1);

        await songMetronome.setTempo(120);
        verifyNever(() => mockMetronome.setTempo(any()));
      });
    });
  });
}

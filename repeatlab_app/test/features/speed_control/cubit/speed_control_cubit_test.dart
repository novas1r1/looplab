import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/speed_control/cubit/speed_control_cubit.dart';

void main() {
  const testSong = Song(
    id: 'test-song-1',
    title: 'Test Song',
    artist: 'Test Artist',
    fileName: 'test.mp3',
    duration: Duration(minutes: 3),
    bpm: 120,
  );

  group('SpeedControlCubit', () {
    late SpeedControlCubit cubit;

    setUp(() {
      cubit = SpeedControlCubit(song: testSong);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.tempoMode, TempoMode.multiplier);
      expect(cubit.state.speedMultiplier, 1.0);
      expect(cubit.state.originalBpm, isNull);
      expect(cubit.state.currentBpm, isNull);
      expect(cubit.state.minBpm, isNull);
      expect(cubit.state.maxBpm, isNull);
    });

    group('setTempoMode', () {
      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with bpm tempo mode',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setTempoMode(TempoMode.bpm),
        expect: () => [
          isA<SpeedControlState>().having(
            (s) => s.tempoMode,
            'tempoMode',
            TempoMode.bpm,
          ),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with multiplier tempo mode',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(tempoMode: TempoMode.bpm),
        act: (cubit) => cubit.setTempoMode(TempoMode.multiplier),
        expect: () => [
          isA<SpeedControlState>().having(
            (s) => s.tempoMode,
            'tempoMode',
            TempoMode.multiplier,
          ),
        ],
      );
    });

    group('setSpeedMultiplier', () {
      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with updated speed multiplier',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setSpeedMultiplier(0.75),
        expect: () => [
          isA<SpeedControlState>().having(
            (s) => s.speedMultiplier,
            'speedMultiplier',
            0.75,
          ),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with speed multiplier 2.0',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setSpeedMultiplier(2.0),
        expect: () => [
          isA<SpeedControlState>().having(
            (s) => s.speedMultiplier,
            'speedMultiplier',
            2.0,
          ),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with speed multiplier 0.5',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setSpeedMultiplier(0.5),
        expect: () => [
          isA<SpeedControlState>().having(
            (s) => s.speedMultiplier,
            'speedMultiplier',
            0.5,
          ),
        ],
      );
    });

    group('setOriginalBpm', () {
      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with originalBpm, currentBpm, minBpm, and maxBpm when bpm is set',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setOriginalBpm(120),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.originalBpm, 'originalBpm', 120)
              .having((s) => s.currentBpm, 'currentBpm', 120)
              .having((s) => s.minBpm, 'minBpm', 60) // 120 * 0.5
              .having((s) => s.maxBpm, 'maxBpm', 240), // 120 * 2.0
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'calculates minBpm clamped to 1 for very low original bpm',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setOriginalBpm(1),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.originalBpm, 'originalBpm', 1)
              .having((s) => s.currentBpm, 'currentBpm', 1)
              .having((s) => s.minBpm, 'minBpm', 1) // clamped to 1
              .having((s) => s.maxBpm, 'maxBpm', 2), // 1 * 2.0
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'calculates maxBpm clamped to 400 for high original bpm',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setOriginalBpm(250),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.originalBpm, 'originalBpm', 250)
              .having((s) => s.currentBpm, 'currentBpm', 250)
              .having((s) => s.minBpm, 'minBpm', 125) // 250 * 0.5
              .having((s) => s.maxBpm, 'maxBpm', 400), // clamped to 400
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with null values when bpm is null',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          originalBpm: 120,
          currentBpm: 120,
          minBpm: 60,
          maxBpm: 240,
        ),
        act: (cubit) => cubit.setOriginalBpm(null),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.originalBpm, 'originalBpm', isNull)
              .having((s) => s.currentBpm, 'currentBpm', isNull)
              .having((s) => s.minBpm, 'minBpm', isNull)
              .having((s) => s.maxBpm, 'maxBpm', isNull),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'handles edge case bpm of 200',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) => cubit.setOriginalBpm(200),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.originalBpm, 'originalBpm', 200)
              .having((s) => s.currentBpm, 'currentBpm', 200)
              .having((s) => s.minBpm, 'minBpm', 100) // 200 * 0.5
              .having((s) => s.maxBpm, 'maxBpm', 400), // 200 * 2.0, clamped to 400
        ],
      );
    });

    group('setCurrentBpm', () {
      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with updated current bpm',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          originalBpm: 120,
          currentBpm: 120,
          minBpm: 60,
          maxBpm: 240,
        ),
        act: (cubit) => cubit.setCurrentBpm(140),
        expect: () => [
          isA<SpeedControlState>().having((s) => s.currentBpm, 'currentBpm', 140),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with min bpm value',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          originalBpm: 120,
          currentBpm: 120,
          minBpm: 60,
          maxBpm: 240,
        ),
        act: (cubit) => cubit.setCurrentBpm(60),
        expect: () => [
          isA<SpeedControlState>().having((s) => s.currentBpm, 'currentBpm', 60),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'emits state with max bpm value',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          originalBpm: 120,
          currentBpm: 120,
          minBpm: 60,
          maxBpm: 240,
        ),
        act: (cubit) => cubit.setCurrentBpm(240),
        expect: () => [
          isA<SpeedControlState>().having((s) => s.currentBpm, 'currentBpm', 240),
        ],
      );
    });

    group('resetSpeed', () {
      blocTest<SpeedControlCubit, SpeedControlState>(
        'resets speed multiplier to 1.0 and preserves original bpm values',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          speedMultiplier: 1.5,
          originalBpm: 120,
          currentBpm: 150,
          minBpm: 60,
          maxBpm: 240,
        ),
        act: (cubit) => cubit.resetSpeed(),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.speedMultiplier, 'speedMultiplier', 1.0)
              .having((s) => s.originalBpm, 'originalBpm', 120)
              .having((s) => s.currentBpm, 'currentBpm', 120)
              .having((s) => s.minBpm, 'minBpm', 60)
              .having((s) => s.maxBpm, 'maxBpm', 240),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'resets to null bpm values when original bpm is null',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          speedMultiplier: 0.75,
        ),
        act: (cubit) => cubit.resetSpeed(),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.speedMultiplier, 'speedMultiplier', 1.0)
              .having((s) => s.originalBpm, 'originalBpm', isNull)
              .having((s) => s.currentBpm, 'currentBpm', isNull)
              .having((s) => s.minBpm, 'minBpm', isNull)
              .having((s) => s.maxBpm, 'maxBpm', isNull),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'recalculates min and max bpm from original bpm',
        build: () => SpeedControlCubit(song: testSong),
        seed: () => const SpeedControlState(
          speedMultiplier: 2.0,
          originalBpm: 100,
          currentBpm: 180,
          minBpm: 50,
          maxBpm: 200,
        ),
        act: (cubit) => cubit.resetSpeed(),
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.speedMultiplier, 'speedMultiplier', 1.0)
              .having((s) => s.originalBpm, 'originalBpm', 100)
              .having((s) => s.currentBpm, 'currentBpm', 100)
              .having((s) => s.minBpm, 'minBpm', 50)
              .having((s) => s.maxBpm, 'maxBpm', 200),
        ],
      );
    });

    group('combined operations', () {
      blocTest<SpeedControlCubit, SpeedControlState>(
        'handles setting original bpm then changing current bpm',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) {
          cubit.setOriginalBpm(120);
          cubit.setCurrentBpm(90);
        },
        expect: () => [
          isA<SpeedControlState>()
              .having((s) => s.originalBpm, 'originalBpm', 120)
              .having((s) => s.currentBpm, 'currentBpm', 120),
          isA<SpeedControlState>().having((s) => s.currentBpm, 'currentBpm', 90),
        ],
      );

      blocTest<SpeedControlCubit, SpeedControlState>(
        'handles mode change and multiplier change',
        build: () => SpeedControlCubit(song: testSong),
        act: (cubit) {
          cubit.setTempoMode(TempoMode.bpm);
          cubit.setSpeedMultiplier(1.25);
        },
        expect: () => [
          isA<SpeedControlState>().having(
            (s) => s.tempoMode,
            'tempoMode',
            TempoMode.bpm,
          ),
          isA<SpeedControlState>().having(
            (s) => s.speedMultiplier,
            'speedMultiplier',
            1.25,
          ),
        ],
      );
    });
  });
}

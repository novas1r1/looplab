import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';

import '../../helpers/mock_data.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/docs';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAudioPlayer audioPlayer;
  late StreamController<PlayerState> playerStateController;
  late StreamController<Duration> positionController;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DeviceFileSource('fake.mp3'));
    registerFallbackValue(ReleaseMode.stop);
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  setUp(() {
    audioPlayer = _MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast();
    positionController = StreamController<Duration>.broadcast();

    when(
      () => audioPlayer.onPlayerStateChanged,
    ).thenAnswer((_) => playerStateController.stream);
    when(
      () => audioPlayer.onPositionChanged,
    ).thenAnswer((_) => positionController.stream);
    when(
      () => audioPlayer.getCurrentPosition(),
    ).thenAnswer((_) async => Duration.zero);
    when(
      () => audioPlayer.getDuration(),
    ).thenAnswer((_) async => Duration.zero);
    when(() => audioPlayer.seek(any<Duration>())).thenAnswer((_) async {});
    when(() => audioPlayer.pause()).thenAnswer((_) async {});
    when(() => audioPlayer.stop()).thenAnswer((_) async {});
    when(() => audioPlayer.resume()).thenAnswer((_) async {});
    when(() => audioPlayer.dispose()).thenAnswer((_) async {});
    when(() => audioPlayer.play(any<Source>())).thenAnswer((_) async {});
    when(() => audioPlayer.setSource(any<Source>())).thenAnswer((_) async {});
    when(() => audioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => audioPlayer.setPlaybackRate(any())).thenAnswer((_) async {});
    when(() => audioPlayer.setPitchShift(any())).thenAnswer((_) async {});
    when(
      () => audioPlayer.setClickTrack(
        enabled: any(named: 'enabled'),
        bpm: any(named: 'bpm'),
        anchorMs: any(named: 'anchorMs'),
        offsetMs: any(named: 'offsetMs'),
        beatsPerBar: any(named: 'beatsPerBar'),
        pulsesPerBeat: any(named: 'pulsesPerBeat'),
        volume: any(named: 'volume'),
      ),
    ).thenAnswer((_) async {});
    when(() => audioPlayer.state).thenReturn(PlayerState.stopped);
  });

  tearDown(() async {
    await playerStateController.close();
    await positionController.close();
  });

  group('setNativeClickTrack', () {
    test('forwards the full config to the player', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.setNativeClickTrack(
        enabled: true,
        bpm: 120,
        anchorMs: 130,
        offsetMs: 25,
        beatsPerBar: 3,
        pulsesPerBeat: 2,
        volume: 0.6,
      );

      verify(
        () => audioPlayer.setClickTrack(
          enabled: true,
          bpm: 120,
          anchorMs: 130,
          offsetMs: 25,
          beatsPerBar: 3,
          pulsesPerBeat: 2,
          volume: 0.6,
        ),
      ).called(1);
    });

    test('playSong clears the native click grid for the new song', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.playSong(MockData.songMedium, autoStart: false);

      verify(
        () => audioPlayer.setClickTrack(
          enabled: false,
          bpm: any(named: 'bpm'),
          anchorMs: any(named: 'anchorMs'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).called(1);
    });

    test('playSong survives platforms without a native click track', () async {
      when(
        () => audioPlayer.setClickTrack(
          enabled: any(named: 'enabled'),
          bpm: any(named: 'bpm'),
          anchorMs: any(named: 'anchorMs'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).thenAnswer(
        (_) async => throw UnsupportedError('not on this platform'),
      );
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.playSong(MockData.songMedium, autoStart: false);

      verify(() => audioPlayer.setSource(any())).called(1);
    });
  });

  group('swapSourceFile', () {
    test('preserves position, speed, pitch and resumes when playing',
        () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      when(() => audioPlayer.state).thenReturn(PlayerState.playing);
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 42));
      when(() => audioPlayer.setPlaybackRate(any())).thenAnswer((_) async {});
      await handler.setSpeed(1.5);

      await handler.swapSourceFile('/tmp/mix.m4a');

      final source =
          verify(() => audioPlayer.setSource(captureAny())).captured.last
              as DeviceFileSource;
      expect(source.path, '/tmp/mix.m4a');
      verify(() => audioPlayer.setPlaybackRate(1.5)).called(greaterThan(0));
      verify(() => audioPlayer.seek(const Duration(seconds: 42))).called(1);
      verify(() => audioPlayer.resume()).called(1);
    });

    test('stays paused when the player was not playing', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      when(() => audioPlayer.state).thenReturn(PlayerState.paused);
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 10));

      await handler.swapSourceFile('/tmp/mix.m4a');

      verify(() => audioPlayer.seek(const Duration(seconds: 10))).called(1);
      verifyNever(() => audioPlayer.resume());
    });
  });

  test(
    'seek clamps to media item duration when platform duration unavailable',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      handler.mediaItem.add(
        const MediaItem(
          id: 'song-1',
          title: 'Example Song',
          duration: Duration(seconds: 5),
        ),
      );

      when(() => audioPlayer.getDuration()).thenAnswer((_) async => null);
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 1));

      final recorded = <Duration>[];
      when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
        invocation,
      ) async {
        recorded.add(invocation.positionalArguments.first as Duration);
      });

      await handler.seek(const Duration(seconds: 10));

      expect(recorded, [const Duration(seconds: 5)]);
    },
  );

  test(
    'seek serializes consecutive calls and executes them in order',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      when(
        () => audioPlayer.getDuration(),
      ).thenAnswer((_) async => const Duration(seconds: 30));

      var positionCall = 0;
      when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async {
        positionCall++;

        if (positionCall == 1) {
          return Duration.zero;
        }

        return const Duration(milliseconds: 600);
      });

      final callLog = <Duration>[];
      final firstSeekCompleter = Completer<void>();
      final secondSeekCompleter = Completer<void>();

      when(() => audioPlayer.seek(any<Duration>())).thenAnswer((invocation) {
        final duration = invocation.positionalArguments.first as Duration;
        callLog.add(duration);

        if (callLog.length == 1) {
          return firstSeekCompleter.future;
        }

        return secondSeekCompleter.future;
      });

      final firstSeek = handler.seek(const Duration(milliseconds: 500));
      final secondSeek = handler.seek(const Duration(seconds: 1));

      await Future<void>.delayed(Duration.zero);
      expect(callLog, [const Duration(milliseconds: 500)]);

      firstSeekCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      expect(callLog, [
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
      ]);

      secondSeekCompleter.complete();
      await Future.wait([firstSeek, secondSeek]);

      expect(callLog, [
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
      ]);
    },
  );

  test('seek reloads source when player completed previously', () async {
    final handler = RepeatlabAudioplayersServiceHandler(
      audioPlayer: audioPlayer,
    );
    addTearDown(handler.close);

    handler.debugSetCurrentSource(DeviceFileSource('sample.mp3'));

    when(() => audioPlayer.state).thenReturn(PlayerState.completed);
    when(
      () => audioPlayer.getDuration(),
    ).thenAnswer((_) async => const Duration(seconds: 20));
    when(
      () => audioPlayer.getCurrentPosition(),
    ).thenAnswer((_) async => Duration.zero);

    await handler.seek(const Duration(seconds: 3));

    verify(() => audioPlayer.setSource(any<Source>())).called(1);
    verify(() => audioPlayer.setPlaybackRate(any())).called(1);
    verify(() => audioPlayer.seek(const Duration(seconds: 3))).called(1);
  });

  test('loop mode restarts playback when position passes loop end', () async {
    final handler = RepeatlabAudioplayersServiceHandler(
      audioPlayer: audioPlayer,
    );
    addTearDown(handler.close);

    when(() => audioPlayer.state).thenReturn(PlayerState.playing);

    final seekCalls = <Duration>[];
    when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
      invocation,
    ) async {
      seekCalls.add(invocation.positionalArguments.first as Duration);
    });

    const loop = Loop(
      id: 1,
      name: 'Loop 1',
      songId: 'song-1',
      color: LoopColor.green,
      start: Duration(seconds: 2),
      end: Duration(seconds: 4),
    );

    await handler.enableLoopMode(loop);

    // Allow initial bounds enforcement to run before asserting streaming behaviour.
    await Future<void>.delayed(Duration.zero);
    seekCalls.clear();

    positionController.add(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    expect(seekCalls, [const Duration(seconds: 2)]);
  });

  test(
    'loop mode does not restart while paused so the loop end stays editable',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      // Paused: the user is dragging the playhead to set a new loop end.
      when(() => audioPlayer.state).thenReturn(PlayerState.paused);

      final seekCalls = <Duration>[];
      when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
        invocation,
      ) async {
        seekCalls.add(invocation.positionalArguments.first as Duration);
      });

      const loop = Loop(
        id: 1,
        name: 'Loop 1',
        songId: 'song-1',
        color: LoopColor.green,
        start: Duration(seconds: 2),
        end: Duration(seconds: 4),
      );

      await handler.enableLoopMode(loop);
      await Future<void>.delayed(Duration.zero);
      seekCalls.clear();

      // Dragging the playhead past the loop end emits a position update. While
      // paused it must NOT snap back to start — otherwise the playhead can never
      // be parked past the end to set a new one.
      positionController.add(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      expect(seekCalls, isEmpty);
    },
  );

  test(
    'enabling a loop while paused does not force the playhead into bounds',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      // Paused with the playhead sitting at the freshly-set loop end — this is
      // exactly the setLoopEnd re-sync path. It must not yank back to start.
      when(() => audioPlayer.state).thenReturn(PlayerState.paused);
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 4));

      final seekCalls = <Duration>[];
      when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
        invocation,
      ) async {
        seekCalls.add(invocation.positionalArguments.first as Duration);
      });

      const loop = Loop(
        id: 1,
        name: 'Loop 1',
        songId: 'song-1',
        color: LoopColor.green,
        start: Duration(seconds: 2),
        end: Duration(seconds: 4),
      );

      await handler.enableLoopMode(loop);
      await Future<void>.delayed(Duration.zero);

      expect(seekCalls, isEmpty);
    },
  );

  test('loop mode resumes wrapping once playback restarts', () async {
    final handler = RepeatlabAudioplayersServiceHandler(
      audioPlayer: audioPlayer,
    );
    addTearDown(handler.close);

    when(() => audioPlayer.state).thenReturn(PlayerState.paused);

    final seekCalls = <Duration>[];
    when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
      invocation,
    ) async {
      seekCalls.add(invocation.positionalArguments.first as Duration);
    });

    const loop = Loop(
      id: 1,
      name: 'Loop 1',
      songId: 'song-1',
      color: LoopColor.green,
      start: Duration(seconds: 2),
      end: Duration(seconds: 4),
    );

    await handler.enableLoopMode(loop);
    await Future<void>.delayed(Duration.zero);
    seekCalls.clear();

    // Guard is state-based, not permanent: crossing the end while paused is
    // ignored, but the same event while playing wraps back to the loop start.
    positionController.add(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);
    expect(seekCalls, isEmpty);

    when(() => audioPlayer.state).thenReturn(PlayerState.playing);
    positionController.add(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);
    expect(seekCalls, [const Duration(seconds: 2)]);
  });

  test('setPitchSemitones clamps and sends the semitone multiplier', () async {
    final handler = RepeatlabAudioplayersServiceHandler(
      audioPlayer: audioPlayer,
    );
    addTearDown(handler.close);

    final sent = <double>[];
    when(() => audioPlayer.setPitchShift(any())).thenAnswer((invocation) async {
      sent.add(invocation.positionalArguments.first as double);
    });

    expect(await handler.setPitchSemitones(12), isTrue);
    expect(await handler.setPitchSemitones(-12), isTrue);
    expect(await handler.setPitchSemitones(0), isTrue);
    expect(await handler.setPitchSemitones(30), isTrue); // clamps to +12
    expect(handler.currentPitchSemitones, 12);

    expect(sent, hasLength(4));
    expect(sent[0], closeTo(2.0, 0.0001));
    expect(sent[1], closeTo(0.5, 0.0001));
    expect(sent[2], closeTo(1.0, 0.0001));
    expect(sent[3], closeTo(2.0, 0.0001));
  });

  test(
    'setPitchSemitones returns false and keeps state when platform throws',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.setPitchSemitones(5);
      expect(handler.currentPitchSemitones, 5);

      when(
        () => audioPlayer.setPitchShift(any()),
      ).thenThrow(UnsupportedError('not supported'));

      expect(await handler.setPitchSemitones(-3), isFalse);
      expect(handler.currentPitchSemitones, 5);
    },
  );

  test(
    'seek reload after completion reapplies pitch alongside speed',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      handler.debugSetCurrentSource(DeviceFileSource('sample.mp3'));
      await handler.setPitchSemitones(7);

      when(() => audioPlayer.state).thenReturn(PlayerState.completed);
      when(
        () => audioPlayer.getDuration(),
      ).thenAnswer((_) async => const Duration(seconds: 20));
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => Duration.zero);

      final sent = <double>[];
      when(() => audioPlayer.setPitchShift(any())).thenAnswer((
        invocation,
      ) async {
        sent.add(invocation.positionalArguments.first as double);
      });

      await handler.seek(const Duration(seconds: 3));

      verify(() => audioPlayer.setSource(any<Source>())).called(1);
      expect(sent, hasLength(1));
      expect(sent.single, closeTo(1.4983, 0.001)); // 2^(7/12)
    },
  );

  test('playSong resets pitch to 0', () async {
    final handler = RepeatlabAudioplayersServiceHandler(
      audioPlayer: audioPlayer,
    );
    addTearDown(handler.close);

    await handler.setPitchSemitones(4);
    expect(handler.currentPitchSemitones, 4);

    final sent = <double>[];
    when(() => audioPlayer.setPitchShift(any())).thenAnswer((invocation) async {
      sent.add(invocation.positionalArguments.first as double);
    });

    await handler.playSong(
      const Song(
        id: 'song-1',
        title: 'Example Song',
        artist: 'Artist',
        fileName: 'sample.mp3',
        duration: Duration(seconds: 30),
      ),
      autoStart: false,
    );

    expect(handler.currentPitchSemitones, 0);
    expect(sent.single, closeTo(1.0, 0.0001));
  });

  test(
    'setSpeed normalizes invalid values before delegating to player',
    () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.setSpeed(double.nan);
      await handler.setSpeed(-1);
      await handler.setSpeed(0.1);
      await handler.setSpeed(3.5);

      verifyInOrder([
        () => audioPlayer.setPlaybackRate(1.0),
        () => audioPlayer.setPlaybackRate(1.0),
        () => audioPlayer.setPlaybackRate(0.5),
        () => audioPlayer.setPlaybackRate(2.0),
      ]);
    },
  );
}

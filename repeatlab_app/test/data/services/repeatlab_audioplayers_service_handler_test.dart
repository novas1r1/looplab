import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
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
  late StreamController<Duration> loopWrapController;

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
    loopWrapController = StreamController<Duration>.broadcast();

    when(
      () => audioPlayer.onPlayerStateChanged,
    ).thenAnswer((_) => playerStateController.stream);
    when(
      () => audioPlayer.onPositionChanged,
    ).thenAnswer((_) => positionController.stream);
    when(
      () => audioPlayer.onLoopWrap,
    ).thenAnswer((_) => loopWrapController.stream);
    // Default to a platform without the native loop region so the existing
    // tests exercise the Dart fallback path; native-path tests re-stub this.
    // MissingPluginException is what a real iOS device produces: the darwin
    // plugin answers unknown methods with FlutterMethodNotImplemented.
    when(
      () => audioPlayer.setLoopRegion(
        enabled: any(named: 'enabled'),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer(
      (_) async => throw MissingPluginException('setLoopRegion'),
    );
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
    await loopWrapController.close();
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

  group('forward/back with an active loop', () {
    const loop = Loop(
      id: 1,
      name: 'Loop 1',
      songId: 'song-1',
      color: LoopColor.green,
      start: Duration(seconds: 20),
      end: Duration(seconds: 30),
    );

    late List<Duration> seekCalls;

    setUp(() {
      seekCalls = <Duration>[];
      when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
        invocation,
      ) async {
        seekCalls.add(invocation.positionalArguments.first as Duration);
      });
      when(
        () => audioPlayer.getDuration(),
      ).thenAnswer((_) async => const Duration(minutes: 3));
    });

    test('clamps to the loop bounds while playing', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      when(() => audioPlayer.state).thenReturn(PlayerState.playing);
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 25));

      await handler.forward(10, loop);
      expect(seekCalls, [loop.end]);

      seekCalls.clear();
      await handler.back(10, loop);
      expect(seekCalls, [loop.start]);
    });

    test('skips past the loop bounds while paused', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      // Paused: skipping is how the user parks the playhead outside the loop
      // to set a new start/end, so the bounds must not clamp it.
      when(() => audioPlayer.state).thenReturn(PlayerState.paused);
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 25));

      await handler.forward(10, loop);
      expect(seekCalls, [const Duration(seconds: 35)]);

      seekCalls.clear();
      await handler.back(10, loop);
      expect(seekCalls, [const Duration(seconds: 15)]);
    });

    test('paused skipping still clamps to the track bounds', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      when(() => audioPlayer.state).thenReturn(PlayerState.paused);
      when(
        () => audioPlayer.getDuration(),
      ).thenAnswer((_) async => const Duration(seconds: 30));
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 25));

      await handler.forward(10, loop);
      expect(seekCalls, [const Duration(seconds: 30)]);

      seekCalls.clear();
      when(
        () => audioPlayer.getCurrentPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 5));

      await handler.back(10, loop);
      expect(seekCalls, [Duration.zero]);
    });
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

  group('predictive loop wrap', () {
    const loop = Loop(
      id: 1,
      name: 'Loop 1',
      songId: 'song-1',
      color: LoopColor.green,
      start: Duration(seconds: 2),
      end: Duration(seconds: 4),
    );

    test('wrap seek is issued at the loop boundary, not after it', () {
      fakeAsync((async) {
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        // The playhead reports 3.5 s — 500 ms before the loop end.
        positionController.add(const Duration(milliseconds: 3500));
        async.flushMicrotasks();

        // Just before the boundary nothing has fired yet.
        async.elapse(const Duration(milliseconds: 450));
        expect(seekCalls, isEmpty);

        // At the boundary the wrap is issued without waiting for a position
        // update to report that the end was already passed.
        async.elapse(const Duration(milliseconds: 60));
        expect(seekCalls, [const Duration(seconds: 2)]);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('wrap timer scales with playback speed', () {
      fakeAsync((async) {
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.setSpeed(2.0);
        async.flushMicrotasks();
        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        // 1 s of song remains, but at 2× speed the boundary arrives in 500 ms.
        positionController.add(const Duration(seconds: 3));
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 450));
        expect(seekCalls, isEmpty);

        async.elapse(const Duration(milliseconds: 60));
        expect(seekCalls, [const Duration(seconds: 2)]);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('pausing cancels the scheduled wrap', () {
      fakeAsync((async) {
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();

        positionController.add(const Duration(milliseconds: 3500));
        async.flushMicrotasks();
        seekCalls.clear();

        when(() => audioPlayer.state).thenReturn(PlayerState.paused);
        handler.pause();
        async.flushMicrotasks();

        // Long past the would-be boundary: the scheduled wrap must not fire.
        async.elapse(const Duration(seconds: 3));
        expect(seekCalls, isEmpty);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('loop wrap skips the duration/position round trips', () async {
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      when(() => audioPlayer.state).thenReturn(PlayerState.playing);

      var positionCalls = 0;
      when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async {
        positionCalls++;
        return Duration.zero;
      });
      var durationCalls = 0;
      when(() => audioPlayer.getDuration()).thenAnswer((_) async {
        durationCalls++;
        return const Duration(seconds: 30);
      });

      final seekCalls = <Duration>[];
      when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
        invocation,
      ) async {
        seekCalls.add(invocation.positionalArguments.first as Duration);
      });

      await handler.enableLoopMode(loop);
      await Future<void>.delayed(Duration.zero);
      seekCalls.clear();
      final positionCallsBeforeWrap = positionCalls;
      final durationCallsBeforeWrap = durationCalls;

      positionController.add(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      expect(seekCalls, [const Duration(seconds: 2)]);
      expect(positionCalls, positionCallsBeforeWrap);
      expect(durationCalls, durationCallsBeforeWrap);
    });
  });

  group('native loop region', () {
    const loop = Loop(
      id: 1,
      name: 'Loop 1',
      songId: 'song-1',
      color: LoopColor.green,
      start: Duration(seconds: 2),
      end: Duration(seconds: 4),
    );

    void stubNativeLoopRegionSupported() {
      when(
        () => audioPlayer.setLoopRegion(
          enabled: any(named: 'enabled'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async {});
    }

    test('enableLoopMode hands the loop bounds to the platform', () async {
      stubNativeLoopRegionSupported();
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.enableLoopMode(loop);

      verify(
        () => audioPlayer.setLoopRegion(
          enabled: true,
          start: const Duration(seconds: 2),
          end: const Duration(seconds: 4),
        ),
      ).called(1);
    });

    test('Dart wrap machinery stands down while native is active', () {
      fakeAsync((async) {
        stubNativeLoopRegionSupported();
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        // A position update just before the boundary must not arm the
        // predictive timer, and crossing the boundary must not wrap from
        // Dart — the engine owns the wrap now.
        positionController.add(const Duration(milliseconds: 3500));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        expect(seekCalls, isEmpty);

        positionController.add(const Duration(milliseconds: 4050));
        async.flushMicrotasks();
        expect(seekCalls, isEmpty);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('native wraps surface on seekEvents for the metronome', () async {
      stubNativeLoopRegionSupported();
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      final seekEvents = <Duration>[];
      final subscription = handler.seekEvents.listen(seekEvents.add);
      addTearDown(subscription.cancel);

      loopWrapController.add(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);

      expect(seekEvents, [const Duration(seconds: 2)]);
    });

    test('watchdog wraps in Dart when the playhead runs well past the end',
        () {
      fakeAsync((async) {
        stubNativeLoopRegionSupported();
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);
        // A user seek jumped past the loop end; native messages don't fire
        // on seeks over the boundary, so the playhead keeps running.
        when(
          () => audioPlayer.getCurrentPosition(),
        ).thenAnswer((_) async => const Duration(milliseconds: 4300));

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        // Next 200 ms watchdog tick sees position >= end + margin.
        async.elapse(const Duration(milliseconds: 250));
        async.flushMicrotasks();
        expect(seekCalls, [const Duration(seconds: 2)]);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('watchdog tolerates positions within the native wrap margin', () {
      fakeAsync((async) {
        stubNativeLoopRegionSupported();
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);
        // Just past the end: a native wrap may still be in flight — the
        // watchdog must not race it into a double seek.
        when(
          () => audioPlayer.getCurrentPosition(),
        ).thenAnswer((_) async => const Duration(milliseconds: 4100));

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        async.elapse(const Duration(milliseconds: 450));
        async.flushMicrotasks();
        expect(seekCalls, isEmpty);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('disableLoopMode clears the native region', () async {
      stubNativeLoopRegionSupported();
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.enableLoopMode(loop);
      await handler.disableLoopMode();

      verify(
        () => audioPlayer.setLoopRegion(
          enabled: false,
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(1);
    });

    test('playSong clears the native region for the new song', () async {
      stubNativeLoopRegionSupported();
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.playSong(MockData.songMedium, autoStart: false);

      verify(
        () => audioPlayer.setLoopRegion(
          enabled: false,
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(1);
    });

    test('unsupported platforms keep the Dart predictive wrap', () {
      fakeAsync((async) {
        // Default stub throws MissingPluginException — the real iOS case.
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        positionController.add(const Duration(milliseconds: 3500));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 510));
        expect(seekCalls, [const Duration(seconds: 2)]);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('interface-default UnsupportedError also falls back to Dart', () {
      fakeAsync((async) {
        when(
          () => audioPlayer.setLoopRegion(
            enabled: any(named: 'enabled'),
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer(
          (_) async => throw UnsupportedError('not on this platform'),
        );
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        final seekCalls = <Duration>[];
        when(() => audioPlayer.seek(any<Duration>())).thenAnswer((
          invocation,
        ) async {
          seekCalls.add(invocation.positionalArguments.first as Duration);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        seekCalls.clear();

        positionController.add(const Duration(milliseconds: 3500));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 510));
        expect(seekCalls, [const Duration(seconds: 2)]);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('playSong survives a missing native loop region plugin', () async {
      // Default stub throws MissingPluginException (iOS): song loading must
      // not fail because the loop-region clear is rejected.
      final handler = RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
      );
      addTearDown(handler.close);

      await handler.playSong(MockData.songMedium, autoStart: false);

      verify(() => audioPlayer.setSource(any())).called(1);
    });
  });

  group('suspendBackgroundPolling', () {
    const loop = Loop(
      id: 1,
      name: 'Loop 1',
      songId: 'song-1',
      color: LoopColor.green,
      start: Duration(seconds: 2),
      end: Duration(seconds: 4),
    );

    test('stops the loop poll so no position queries fire anymore', () {
      fakeAsync((async) {
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        var positionQueries = 0;
        when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async {
          positionQueries++;
          return const Duration(seconds: 3);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();

        positionQueries = 0;
        async.elapse(const Duration(seconds: 1));
        expect(positionQueries, greaterThan(0));

        handler.suspendBackgroundPolling();
        positionQueries = 0;
        async.elapse(const Duration(seconds: 5));
        expect(positionQueries, 0);

        handler.close();
        async.flushMicrotasks();
      });
    });

    test('play() re-arms the loop poll after a suspension', () {
      fakeAsync((async) {
        final handler = RepeatlabAudioplayersServiceHandler(
          audioPlayer: audioPlayer,
        );

        when(() => audioPlayer.state).thenReturn(PlayerState.playing);

        var positionQueries = 0;
        when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async {
          positionQueries++;
          return const Duration(seconds: 3);
        });

        handler.enableLoopMode(loop);
        async.flushMicrotasks();
        handler.suspendBackgroundPolling();

        handler.play();
        async.flushMicrotasks();

        positionQueries = 0;
        async.elapse(const Duration(seconds: 1));
        expect(positionQueries, greaterThan(0));

        handler.close();
        async.flushMicrotasks();
      });
    });
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

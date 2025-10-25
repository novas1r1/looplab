import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAudioPlayer audioPlayer;
  late StreamController<PlayerState> playerStateController;
  late StreamController<Duration> positionController;

  setUpAll(() {
    registerFallbackValue(const Duration());
    registerFallbackValue(DeviceFileSource('fake.mp3'));
    registerFallbackValue(ReleaseMode.stop);
  });

  setUp(() {
    audioPlayer = _MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast();
    positionController = StreamController<Duration>.broadcast();

    when(() => audioPlayer.onPlayerStateChanged).thenAnswer((_) => playerStateController.stream);
    when(() => audioPlayer.onPositionChanged).thenAnswer((_) => positionController.stream);
    when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async => Duration.zero);
    when(() => audioPlayer.getDuration()).thenAnswer((_) async => Duration.zero);
    when(() => audioPlayer.seek(any<Duration>())).thenAnswer((_) async {});
    when(() => audioPlayer.pause()).thenAnswer((_) async {});
    when(() => audioPlayer.stop()).thenAnswer((_) async {});
    when(() => audioPlayer.resume()).thenAnswer((_) async {});
    when(() => audioPlayer.dispose()).thenAnswer((_) async {});
    when(() => audioPlayer.play(any<Source>())).thenAnswer((_) async {});
    when(() => audioPlayer.setSource(any<Source>())).thenAnswer((_) async {});
    when(() => audioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => audioPlayer.setPlaybackRate(any())).thenAnswer((_) async {});
    when(() => audioPlayer.state).thenReturn(PlayerState.stopped);
  });

  tearDown(() async {
    await playerStateController.close();
    await positionController.close();
  });

  test('seek clamps to media item duration when platform duration unavailable', () async {
    final handler = RepeatlabAudioplayersServiceHandler(audioPlayer: audioPlayer);
    addTearDown(handler.close);

    handler.mediaItem.add(
      const MediaItem(
        id: 'song-1',
        title: 'Example Song',
        duration: Duration(seconds: 5),
      ),
    );

    when(() => audioPlayer.getDuration()).thenAnswer((_) async => null);
    when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async => const Duration(seconds: 1));

    final recorded = <Duration>[];
    when(() => audioPlayer.seek(any<Duration>())).thenAnswer((invocation) async {
      recorded.add(invocation.positionalArguments.first as Duration);
    });

    await handler.seek(const Duration(seconds: 10));

    expect(recorded, [const Duration(seconds: 5)]);
  });

  test('seek serializes consecutive calls and executes them in order', () async {
    final handler = RepeatlabAudioplayersServiceHandler(audioPlayer: audioPlayer);
    addTearDown(handler.close);

    when(() => audioPlayer.getDuration()).thenAnswer((_) async => const Duration(seconds: 30));

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
    expect(callLog, [const Duration(milliseconds: 500), const Duration(seconds: 1)]);

    secondSeekCompleter.complete();
    await Future.wait([firstSeek, secondSeek]);

    expect(callLog, [const Duration(milliseconds: 500), const Duration(seconds: 1)]);
  });

  test('seek reloads source when player completed previously', () async {
    final handler = RepeatlabAudioplayersServiceHandler(audioPlayer: audioPlayer);
    addTearDown(handler.close);

    handler.debugSetCurrentSource(DeviceFileSource('sample.mp3'));

    when(() => audioPlayer.state).thenReturn(PlayerState.completed);
    when(() => audioPlayer.getDuration()).thenAnswer((_) async => const Duration(seconds: 20));
    when(() => audioPlayer.getCurrentPosition()).thenAnswer((_) async => Duration.zero);

    await handler.seek(const Duration(seconds: 3));

    verify(() => audioPlayer.setSource(any<Source>())).called(1);
    verify(() => audioPlayer.setPlaybackRate(any())).called(1);
    verify(() => audioPlayer.seek(const Duration(seconds: 3))).called(1);
  });
}

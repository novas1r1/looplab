import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

class AudioPlayerService {
  // final audioplayers.AudioPlayer audioPlayer;
  final AudioPlayer justAudioPlayer;

  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration?>? durationSubscription;

  AudioPlayerService({
    // required this.audioPlayer,
    required this.justAudioPlayer,
  });

  Duration get position => justAudioPlayer.position;
  Duration? get duration => justAudioPlayer.duration;
  PlayerState? get playerState => justAudioPlayer.playerState;

  Future<void> init(Song song) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final path = await song.path;
    final audioSource = AudioSource.uri(
      Uri.file(path),
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
      ),
    );
    await justAudioPlayer.setAudioSource(audioSource);

    await justAudioPlayer.setSpeed(1.0);
    // await justAudioPlayer.pause();

    playerStateSubscription = justAudioPlayer.playerStateStream.listen((playerState) {
      // TODO: Implement player state
    });

    positionSubscription = justAudioPlayer.positionStream.listen((position) {
      // TODO: Implement position
    });

    durationSubscription = justAudioPlayer.durationStream.listen((duration) {
      // TODO: Implement duration
    });
  }

  Future<void> play() async {
    await justAudioPlayer.play();
  }

  Future<void> playLoop(Loop loop) async {
    await justAudioPlayer.seek(loop.start);
    await justAudioPlayer.play();
  }

  Future<void> pause() async {
    await justAudioPlayer.pause();
  }

  Future<void> stop() async {
    await justAudioPlayer.stop();
  }

  Future<void> setSpeed(double speed) async {
    await justAudioPlayer.setSpeed(speed);
  }

  Future<void> seek(Duration position) async {
    await justAudioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await justAudioPlayer.setVolume(volume);
  }

  Future<void> setLoop(bool loop) async {
    // await justAudioPlayer.setLoop(loop);
    // TODO: Implement loop
  }

  Future<void> dispose() async {
    await playerStateSubscription?.cancel();
    await positionSubscription?.cancel();
    await durationSubscription?.cancel();

    await justAudioPlayer.dispose();
  }
}

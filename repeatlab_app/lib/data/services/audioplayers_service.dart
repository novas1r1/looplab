import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioPlayersService {
  final AudioPlayer audioPlayer;

  /// AudioPlayer subscriptions
  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration>? durationSubscription;

  AudioPlayersService({required this.audioPlayer});
}

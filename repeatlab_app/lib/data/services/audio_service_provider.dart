import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeatlab/data/services/repeatlab_audio_service_handler.dart';

/// Provider for the audio service
class AudioServiceProvider {
  static RepeatlabAudioServiceHandler? _audioHandler;

  final AudioPlayer audioPlayer;

  const AudioServiceProvider({required this.audioPlayer});

  /// Initialize the audio service
  static Future<RepeatlabAudioServiceHandler> init(AudioPlayer audioPlayer) async {
    if (_audioHandler != null) {
      return _audioHandler!;
    }

    _audioHandler = await AudioService.init<RepeatlabAudioServiceHandler>(
      builder: () => RepeatlabAudioServiceHandler(audioPlayer: audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.repeatlab.audio',
        androidNotificationChannelName: 'RepeatLab Audio Playback',
        androidNotificationOngoing: true,
      ),
    );

    return _audioHandler!;
  }
}

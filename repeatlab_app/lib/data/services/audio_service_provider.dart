/* import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';

/// Provider for the audio service
class AudioServiceProvider {
  static RepeatlabAudioplayersServiceHandler? _audioHandler;

  final AudioPlayer audioPlayer;

  const AudioServiceProvider({required this.audioPlayer});

  /// Initialize the audio service
  static Future<RepeatlabAudioplayersServiceHandler> init(AudioPlayer audioPlayer) async {
    if (_audioHandler != null) {
      return _audioHandler!;
    }

    _audioHandler = await AudioService.init<RepeatlabAudioplayersServiceHandler>(
      builder: () => RepeatlabAudioplayersServiceHandler(audioPlayer: audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.repeatlab.audio',
        androidNotificationChannelName: 'RepeatLab Audio Playback',
      ),
    );

    return _audioHandler!;
  }
}
 */

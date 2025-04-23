import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:repeatlab/data/services/audio_service_handler.dart';

/// Provider for the audio service
class AudioServiceProvider {
  static RepeatLabAudioHandler? _audioHandler;

  final AudioPlayer audioPlayer;

  const AudioServiceProvider({required this.audioPlayer});

  /// Initialize the audio service
  static Future<RepeatLabAudioHandler> init(AudioPlayer audioPlayer) async {
    if (_audioHandler != null) {
      return _audioHandler!;
    }

    _audioHandler = await AudioService.init<RepeatLabAudioHandler>(
      builder: () => RepeatLabAudioHandler(audioPlayer: audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.repeatlab.audio',
        androidNotificationChannelName: 'RepeatLab Audio Playback',
      ),
    );

    return _audioHandler!;
  }

  /// Get the audio handler instance
  static RepeatLabAudioHandler? get audioHandler => _audioHandler;
}

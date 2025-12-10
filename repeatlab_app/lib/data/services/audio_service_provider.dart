import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';
import 'package:repeatlab/data/services/rubber_band_service.dart';

/// Provider for the audio service
class AudioServiceProvider {
  static RepeatlabAudioplayersServiceHandler? _audioHandler;
  static RubberBandService? _rubberBandService;

  final AudioPlayer audioPlayer;

  const AudioServiceProvider({required this.audioPlayer});

  /// Initialize the audio service with Rubber Band support
  static Future<RepeatlabAudioplayersServiceHandler> init(AudioPlayer audioPlayer) async {
    if (_audioHandler != null) {
      return _audioHandler!;
    }

    // Initialize Rubber Band service
    _rubberBandService = RubberBandService();
    await _rubberBandService!.init();

    _audioHandler = await AudioService.init<RepeatlabAudioplayersServiceHandler>(
      builder: () => RepeatlabAudioplayersServiceHandler(
        audioPlayer: audioPlayer,
        rubberBandService: _rubberBandService,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.repeatlab.channel.audio',
        androidNotificationChannelName: 'RepeatLab Audio Playback',
        androidNotificationIcon: 'mipmap/launcher_icon',
      ),
    );

    return _audioHandler!;
  }

  /// Get the Rubber Band service instance
  static RubberBandService? get rubberBandService => _rubberBandService;
}

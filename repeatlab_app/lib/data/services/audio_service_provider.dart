import 'package:audio_service/audio_service.dart';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:repeatlab/data/services/repeatlab_audio_handler.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';
import 'package:repeatlab/data/services/repeatlab_just_audio_service_handler.dart';

enum AudioBackend {
  justAudio,
  audioplayers,
}

/// Provider for the audio service
class AudioServiceProvider {
  static RepeatlabAudioHandler? _audioHandler;
  static AudioBackend? _activeBackend;

  /// Initialize the audio service, preferring the supplied backend but falling back to
  /// the legacy audioplayers implementation when necessary.
  static Future<RepeatlabAudioHandler> init({AudioBackend preferred = AudioBackend.audioplayers}) async {
    if (_audioHandler != null && _activeBackend == preferred) {
      return _audioHandler!;
    }

    // Tear down any previous handler when switching backends.
    if (_audioHandler != null && _activeBackend != preferred) {
      try {
        await _audioHandler?.stop();
        final handler = _audioHandler;
        if (handler is RepeatlabAudioplayersServiceHandler) {
          await handler.close();
        } else if (handler is RepeatlabJustAudioServiceHandler) {
          await handler.close();
        }
      } catch (error, stackTrace) {
        log('Error while disposing previous audio handler', error: error, stackTrace: stackTrace);
      } finally {
        _audioHandler = null;
        _activeBackend = null;
      }
    }

    if (preferred == AudioBackend.justAudio) {
      try {
        final handler = await AudioService.init<RepeatlabJustAudioServiceHandler>(
          builder: () => RepeatlabJustAudioServiceHandler(audioPlayer: ja.AudioPlayer()),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.repeatlab.channel.audio',
            androidNotificationChannelName: 'RepeatLab Audio Playback',
            androidNotificationIcon: 'mipmap/launcher_icon',
          ),
        );
        _audioHandler = handler;
        _activeBackend = AudioBackend.justAudio;
        return handler;
      } catch (error, stackTrace) {
        log('Failed to initialize just_audio backend, falling back to audioplayers',
            error: error, stackTrace: stackTrace);
      }
    }

    final fallbackHandler = await AudioService.init<RepeatlabAudioplayersServiceHandler>(
      builder: () => RepeatlabAudioplayersServiceHandler(audioPlayer: ap.AudioPlayer()),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.repeatlab.channel.audio',
        androidNotificationChannelName: 'RepeatLab Audio Playback',
        androidNotificationIcon: 'mipmap/launcher_icon',
      ),
    );

    _audioHandler = fallbackHandler;
    _activeBackend = AudioBackend.audioplayers;
    return fallbackHandler;
  }
}

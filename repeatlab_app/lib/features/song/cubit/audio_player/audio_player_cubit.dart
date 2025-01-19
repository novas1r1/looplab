/* import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:drumbitious/data/repositories/repositories.dart';
import 'package:drumbitious_api/drumbitious_api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

part 'audio_player_state.dart';

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final AudioPlayer audioPlayer;
  final Song song;
  final CrashReportingRepository crashReportingRepository;
  final FileRepository fileRepository;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  AudioPlayerCubit({
    required this.audioPlayer,
    required this.exerciseAudio,
    required this.crashReportingRepository,
    required this.fileRepository,
  }) : super(const AudioPlayerState()) {
    _playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((event) {
      maybeEmit(state.copyWith(playerState: event));
    });

    _positionSubscription = audioPlayer.onPositionChanged.listen((event) {
      maybeEmit(state.copyWith(position: event));
    });

    _durationSubscription = audioPlayer.onDurationChanged.listen((event) {
      maybeEmit(state.copyWith(duration: event));
    });
  }

  // Release audioplayer on dispose
  @override
  Future<void> close() async {
    await audioPlayer.stop();
    // await audioPlayer.dispose();

    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.close();
  }

  Future<void> play() async {
    emit(state.copyWith(status: AudioPlayerStatus.loading));

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/${exerciseAudio.getFileName()}';

      await audioPlayer.play(DeviceFileSource(filePath));
      emit(state.copyWith(status: AudioPlayerStatus.loaded));
    } catch (ex, stackTrace) {
      crashReportingRepository.reportCrash(ex, stackTrace: stackTrace);
      emit(state.copyWith(status: AudioPlayerStatus.playError, exception: ex));
    }
  }

  Future<void> changeSpeed(double speed) async {
    await audioPlayer.setPlaybackRate(speed);
    emit(state.copyWith(speed: speed));
  }

  /// Pause
  Future<void> pause() async {
    await audioPlayer.pause();
  }

  /// Resume
  Future<void> resume() async {
    await audioPlayer.resume();
  }

  /// Stop
  Future<void> stop() async {
    await audioPlayer.stop();
  }

  /// Restart
  Future<void> restart() async {
    await audioPlayer.stop();
    await play();
  }

  /// Dispose
  Future<void> dispose() async {
    await audioPlayer.stop();
    await audioPlayer.dispose();
  }

  /*  Future<void> checkIfFileExists(ExerciseAudio exerciseAudio) async {
    try {
      final file =
          await fileRepository.getFileFromPath(exerciseAudio.localPath);

      if (file != null) {
        emit(state.copyWith(status: AudioPlayerStatus.loaded));
      } else {
        crashReportingRepository.reportCrash(
          Exception(
            'File ${exerciseAudio.getFileName()} path: ${exerciseAudio.localPath} not found',
          ),
        );
        emit(
          state.copyWith(
            status: AudioPlayerStatus.fileNotFoundError,
            exception: Exception(
              'File ${exerciseAudio.getFileName()} not found',
            ),
          ),
        );
      }
    } catch (ex, stacktrace) {
      crashReportingRepository.reportCrash(ex, stackTrace: stacktrace);
      emit(
        state.copyWith(
          status: AudioPlayerStatus.fileNotFoundError,
          exception: ex,
        ),
      );
    }
  } */

  Future<void> seek(Duration duration) async {
    await audioPlayer.seek(duration);
    emit(state.copyWith(position: duration));
  }
}
 */

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/recording_repository.dart';
import 'package:uuid/uuid.dart';

part 'recording_cubit.mapper.dart';
part 'recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  final String songId;
  final RecordingRepository recordingRepository;
  final CrashReportingRepository crashReportingRepository;

  Timer? _countdownTimer;
  AudioRecorder? _recorder;

  RecordingCubit({
    required this.songId,
    required this.recordingRepository,
    required this.crashReportingRepository,
  }) : super(const RecordingState());

  Future<void> loadLayers() async {
    try {
      final layers = await recordingRepository.getLayersForSong(songId);
      emit(state.copyWith(layers: layers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(state.copyWith(
        status: RecordingStatus.error,
        error: 'Failed to load recording layers: $ex',
      ));
    }
  }

  /// Start the recording countdown. When countdown finishes,
  /// calls [onCountdownComplete] so the caller can start playback,
  /// then begins recording.
  Future<void> startRecording({
    required Duration startPosition,
    required Duration? stopPosition,
    required Future<void> Function() onCountdownComplete,
  }) async {
    // Check microphone permission
    _recorder = AudioRecorder();
    final hasPermission = await _recorder!.hasPermission();

    if (!hasPermission) {
      emit(state.copyWith(status: RecordingStatus.permissionDenied));
      return;
    }

    // Start countdown
    emit(state.copyWith(
      status: RecordingStatus.countdown,
      countdownValue: 3,
    ));

    _countdownTimer?.cancel();
    var count = 3;

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        count--;
        if (count > 0) {
          emit(state.copyWith(countdownValue: count));
        } else {
          timer.cancel();
          await onCountdownComplete();
          await _beginRecording(startPosition, stopPosition);
        }
      },
    );
  }

  Future<void> _beginRecording(
    Duration startPosition,
    Duration? stopPosition,
  ) async {
    try {
      final layerId = const Uuid().v4();
      final appDir = await getApplicationDocumentsDirectory();
      final recordingDir = Directory('${appDir.path}/recordings/$songId');
      if (!await recordingDir.exists()) {
        await recordingDir.create(recursive: true);
      }
      final filePath = '${recordingDir.path}/$layerId.wav';

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          numChannels: 1,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      emit(state.copyWith(
        status: RecordingStatus.recording,
        activeLayerId: layerId,
        countdownValue: null,
      ));

      dev.log('Recording started: $filePath', name: 'RecordingCubit');
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(state.copyWith(
        status: RecordingStatus.error,
        error: 'Failed to start recording: $ex',
        countdownValue: null,
      ));
    }
  }

  Future<void> stopRecording({
    required Duration startPosition,
  }) async {
    if (state.status != RecordingStatus.recording) return;

    emit(state.copyWith(status: RecordingStatus.saving));

    try {
      final path = await _recorder!.stop();
      if (path == null) {
        emit(state.copyWith(
          status: RecordingStatus.error,
          error: 'Recording failed - no file produced',
        ));
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        emit(state.copyWith(
          status: RecordingStatus.error,
          error: 'Recording file not found',
        ));
        return;
      }

      // Calculate recording duration from file
      // WAV at 44100Hz, 16-bit, mono: 88200 bytes per second + 44 byte header
      final fileSize = await file.length();
      final durationMs = ((fileSize - 44) / 88200 * 1000).round();
      final duration = Duration(milliseconds: durationMs);

      final layer = RecordingLayer(
        id: state.activeLayerId!,
        songId: songId,
        filePath: path,
        startPosition: startPosition,
        duration: duration,
        createdAt: DateTime.now(),
      );

      await recordingRepository.addLayer(layer);

      emit(state.copyWith(
        status: RecordingStatus.idle,
        layers: [...state.layers, layer],
        activeLayerId: null,
      ));

      dev.log('Recording saved: $path (${duration.inSeconds}s)',
          name: 'RecordingCubit');
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(state.copyWith(
        status: RecordingStatus.error,
        error: 'Failed to save recording: $ex',
        activeLayerId: null,
      ));
    }
  }

  void cancelRecording() {
    _countdownTimer?.cancel();
    _recorder?.stop();
    _recorder?.dispose();
    emit(state.copyWith(
      status: RecordingStatus.idle,
      countdownValue: null,
      activeLayerId: null,
    ));
  }

  Future<void> toggleMute(RecordingLayer layer) async {
    final updated = layer.copyWith(isMuted: !layer.isMuted);
    try {
      await recordingRepository.updateLayer(updated);
      final updatedLayers =
          state.layers.map((l) => l.id == layer.id ? updated : l).toList();
      emit(state.copyWith(layers: updatedLayers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  Future<void> setVolume(RecordingLayer layer, double volume) async {
    final updated = layer.copyWith(volume: volume.clamp(0.0, 1.0));
    try {
      await recordingRepository.updateLayer(updated);
      final updatedLayers =
          state.layers.map((l) => l.id == layer.id ? updated : l).toList();
      emit(state.copyWith(layers: updatedLayers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  Future<void> deleteLayer(RecordingLayer layer) async {
    try {
      await recordingRepository.deleteLayer(layer);
      final updatedLayers =
          state.layers.where((l) => l.id != layer.id).toList();
      emit(state.copyWith(layers: updatedLayers));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _recorder?.dispose();
    return super.close();
  }
}

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

part 'wave_form_cubit.mapper.dart';
part 'wave_form_state.dart';

class WaveFormCubit extends Cubit<WaveFormState> {
  final Song song;
  final SoLoud soloud;

  final SongCubit songCubit;
  final CrashReportingRepository crashReportingRepository;

  // Add static cache map
  static final Map<String, Float32List> _waveformCache = {};

  StreamSubscription<List<Loop>>? _loopsSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  WaveFormCubit({
    required this.soloud,
    required this.song,
    required this.songCubit,
    required this.crashReportingRepository,
  }) : super(WaveFormState(duration: song.duration, loops: song.loops)) {
    _positionSubscription = songCubit.positionStream?.listen((position) {
      emit(state.copyWith(currentPosition: position));
    });

    _loopsSubscription = songCubit.loopsStreamController?.stream.listen((loops) {
      emit(state.copyWith(loops: loops));
    });
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _loopsSubscription?.cancel();
    return super.close();
  }

  Future<void> getWaveformData(Song song) async {
    emit(state.copyWith(status: WaveFormStateStatus.loading));

    try {
      final path = await song.path;
      final duration = song.duration;

      // Check cache first
      Float32List? waveformData = _waveformCache[path];

      if (waveformData == null) {
        log('NO CACHE AVAILABLE FOR $path');
        // Only read bytes and generate waveform if not cached
        final file = File(path);

        final bytes = await file.readAsBytes();

        // Calculate number of samples based on duration
        // Use ~100ms per sample (10 samples per second) as a good balance
        // between detail and performance
        final effectiveDuration = duration.inMilliseconds > 0
            ? duration
            : const Duration(minutes: 3); // Default to 3 minutes if duration is zero

        final numSamples = _calculateOptimalSampleCount(effectiveDuration);

        waveformData = await soloud.readSamplesFromMem(
          bytes,
          numSamples,
          // average: true, // Average samples to smooth out the waveform
        );
        // Store in cache
        _waveformCache[path] = waveformData;
      }

      emit(
        state.copyWith(
          status: WaveFormStateStatus.loaded,
          waveformData: waveformData,
        ),
      );
    } on Exception catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: WaveFormStateStatus.error,
          error: ex,
        ),
      );
    }
  }

  Future<void> changePosition(Duration position) async {
    songCubit.seekSong(position);
  }

  Future<void> pauseSong() async {
    songCubit.pauseSong();
  }

  /// Calculate optimal number of samples for waveform visualization
  ///
  /// Uses ~100ms per sample (10 samples per second) as a good balance
  /// between detail and performance. Ensures reasonable bounds:
  /// - Minimum: 100 samples (for very short audio)
  /// - Maximum: 5000 samples (for very long audio to maintain performance)
  int _calculateOptimalSampleCount(Duration duration) {
    // Target 10 samples per second (100ms per sample)
    const targetSamplesPerSecond = 1.5;
    final calculatedSamples = (duration.inMilliseconds / 100).round() * targetSamplesPerSecond;

    // Apply bounds for reasonable visualization
    const minSamples = 100; // Minimum samples for very short audio
    const maxSamples = 5000; // Maximum samples to maintain performance

    log('duration: ${duration.inSeconds}, calculatedSamples: $calculatedSamples');

    return calculatedSamples.clamp(minSamples, maxSamples).toInt();
  }
}

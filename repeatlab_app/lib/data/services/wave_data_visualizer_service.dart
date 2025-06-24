import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

class WaveDataVisualizerService {
  final SoLoud soloud;

  // Add static cache map
  static final Map<String, Float32List> _waveformCache = {};

  WaveDataVisualizerService({required this.soloud});

  Future<Float32List> getWaveformData(String path, Duration duration) async {
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
        average: true, // Average samples to smooth out the waveform
      );
      // Store in cache
      _waveformCache[path] = waveformData;
    }

    return waveformData;
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

  /// Implement different approach from docs
  /// https://docs.page/alnitak/flutter_soloud_docs/visualization/audio_data
}

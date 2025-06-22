import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

class WaveDataVisualizerService {
  final SoLoud soloud;

  // Add static cache map
  static final Map<String, Float32List> _waveformCache = {};

  WaveDataVisualizerService({required this.soloud});

  Future<Float32List> getWaveformData(String path) async {
    // Check cache first
    Float32List? waveformData = _waveformCache[path];

    if (waveformData == null) {
      log('NO CACHE AVAILABLE FOR $path');
      // Only read bytes and generate waveform if not cached
      final file = File(path);

      final bytes = await file.readAsBytes();
      waveformData = await soloud.readSamplesFromMem(
        bytes,
        300 * 10,
        // average: true,
      );
      // Store in cache
      _waveformCache[path] = waveformData;
    }

    return waveformData;
  }

  /// Implement different approach from docs
  /// https://docs.page/alnitak/flutter_soloud_docs/visualization/audio_data
}

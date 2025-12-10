import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for Rubber Band audio processing.
/// Provides pitch-preserving time-stretching capabilities.
class RubberBandService {
  static const _channel = MethodChannel('com.repeatlab.rubberband');

  /// Cache directory for processed audio files
  String? _cacheDir;

  /// In-memory cache of processed file paths
  /// Key format: {songId}_{speed}_{pitch}
  final Map<String, String> _pathCache = {};

  /// Initialize the service and create cache directory
  Future<void> init() async {
    final appCacheDir = await getApplicationCacheDirectory();
    _cacheDir = p.join(appCacheDir.path, 'rubberband');

    final cacheDir = Directory(_cacheDir!);
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
      log('RubberBandService: Created cache directory: $_cacheDir');
    }
  }

  /// Process an audio file with Rubber Band time-stretching.
  ///
  /// Returns the path to the processed file (from cache if available).
  ///
  /// [inputPath] - Path to the input audio file (WAV format recommended)
  /// [songId] - Unique identifier for the song (used for caching)
  /// [speed] - Speed multiplier (0.5 = half speed, 1.0 = original, 2.0 = double)
  /// [pitch] - Pitch scale (1.0 = original, 2.0 = one octave up)
  ///
  /// Throws [RubberBandException] if processing fails.
  Future<String> processFile({
    required String inputPath,
    required String songId,
    required double speed,
    double pitch = 1.0,
  }) async {
    if (_cacheDir == null) {
      await init();
    }

    // Normalize speed and pitch to avoid floating point precision issues
    final normalizedSpeed = _normalizeValue(speed);
    final normalizedPitch = _normalizeValue(pitch);

    // Check if we already have this processed file
    final cacheKey = _getCacheKey(songId, normalizedSpeed, normalizedPitch);
    final cachedPath = await _getCachedFile(cacheKey);
    if (cachedPath != null) {
      log('RubberBandService: Using cached file for $cacheKey');
      return cachedPath;
    }

    // Generate output path
    final outputPath = _getOutputPath(cacheKey);

    log(
      'RubberBandService: Processing $inputPath -> $outputPath '
      '(speed=$normalizedSpeed, pitch=$normalizedPitch)',
    );

    try {
      final result = await _channel.invokeMethod<String>('processFile', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'speed': normalizedSpeed,
        'pitch': normalizedPitch,
      });

      if (result == null || result.isEmpty) {
        throw RubberBandException('Processing returned empty result');
      }

      // Cache the result
      _pathCache[cacheKey] = result;
      log('RubberBandService: Processing complete: $result');

      return result;
    } on PlatformException catch (e) {
      log('RubberBandService: Platform error: ${e.message}');
      throw RubberBandException(e.message ?? 'Unknown platform error');
    } catch (e) {
      log('RubberBandService: Error: $e');
      throw RubberBandException(e.toString());
    }
  }

  /// Check if a processed file exists for the given parameters.
  Future<bool> hasProcessedFile({
    required String songId,
    required double speed,
    double pitch = 1.0,
  }) async {
    final normalizedSpeed = _normalizeValue(speed);
    final normalizedPitch = _normalizeValue(pitch);
    final cacheKey = _getCacheKey(songId, normalizedSpeed, normalizedPitch);

    return await _getCachedFile(cacheKey) != null;
  }

  /// Clear cached files for a specific song.
  Future<void> clearCacheForSong(String songId) async {
    if (_cacheDir == null) return;

    final cacheDir = Directory(_cacheDir!);
    if (!cacheDir.existsSync()) return;

    // Remove from memory cache
    _pathCache.removeWhere((key, _) => key.startsWith('${songId}_'));

    // Remove files from disk
    try {
      await for (final file in cacheDir.list()) {
        if (file is File && p.basename(file.path).startsWith('${songId}_')) {
          await file.delete();
          log('RubberBandService: Deleted cached file: ${file.path}');
        }
      }
    } catch (e) {
      log('RubberBandService: Error clearing cache for $songId: $e');
    }
  }

  /// Clear all cached files.
  Future<void> clearAllCache() async {
    if (_cacheDir == null) return;

    _pathCache.clear();

    final cacheDir = Directory(_cacheDir!);
    if (cacheDir.existsSync()) {
      try {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
        log('RubberBandService: Cleared all cache');
      } catch (e) {
        log('RubberBandService: Error clearing cache: $e');
      }
    }
  }

  /// Get the Rubber Band library version.
  Future<String> getVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getVersion');
      return version ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get total cache size in bytes.
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;

    final cacheDir = Directory(_cacheDir!);
    if (!cacheDir.existsSync()) return 0;

    var totalSize = 0;
    try {
      await for (final file in cacheDir.list()) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      log('RubberBandService: Error calculating cache size: $e');
    }

    return totalSize;
  }

  String _getCacheKey(String songId, double speed, double pitch) {
    // Use underscore-separated format for safe filenames
    return '${songId}_${speed.toStringAsFixed(2)}_${pitch.toStringAsFixed(2)}';
  }

  String _getOutputPath(String cacheKey) {
    return p.join(_cacheDir!, '$cacheKey.wav');
  }

  Future<String?> _getCachedFile(String cacheKey) async {
    // Check memory cache first
    if (_pathCache.containsKey(cacheKey)) {
      final path = _pathCache[cacheKey]!;
      if (File(path).existsSync()) {
        return path;
      }
      // File was deleted, remove from cache
      _pathCache.remove(cacheKey);
    }

    // Check disk cache
    final path = _getOutputPath(cacheKey);
    if (File(path).existsSync()) {
      _pathCache[cacheKey] = path;
      return path;
    }

    return null;
  }

  double _normalizeValue(double value) {
    // Round to 2 decimal places to avoid floating point precision issues
    return double.parse(value.toStringAsFixed(2));
  }
}

/// Exception thrown when Rubber Band processing fails.
class RubberBandException implements Exception {
  final String message;

  RubberBandException(this.message);

  @override
  String toString() => 'RubberBandException: $message';
}


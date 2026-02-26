import 'dart:developer' as dev;

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/models/recording_layer.dart';

/// Manages playback of recording layers via SoLoud.
/// Each layer gets its own SoLoud source handle for independent volume/mute.
class RecordingPlaybackService {
  final SoLoud _soloud;

  /// Maps layer ID to loaded SoLoud source
  final Map<String, AudioSource> _sources = {};

  /// Maps layer ID to active sound handle
  final Map<String, SoundHandle> _handles = {};

  RecordingPlaybackService({required SoLoud soloud}) : _soloud = soloud;

  /// Load a recording layer file into SoLoud.
  Future<void> loadLayer(RecordingLayer layer) async {
    if (_sources.containsKey(layer.id)) return;

    try {
      final source = await _soloud.loadFile(layer.filePath);
      _sources[layer.id] = source;
      dev.log('Loaded recording layer: ${layer.id}',
          name: 'RecordingPlayback');
    } catch (ex) {
      dev.log('Failed to load layer ${layer.id}: $ex',
          name: 'RecordingPlayback');
      rethrow;
    }
  }

  /// Play a layer at a specific position within the song.
  /// [songPosition] is the current playback position in the song.
  /// The layer will be seeked to the correct offset.
  Future<void> playLayer(RecordingLayer layer, Duration songPosition) async {
    final source = _sources[layer.id];
    if (source == null) return;
    if (layer.isMuted) return;

    // Calculate where in the recording we should be
    final offset = songPosition - layer.startPosition;
    if (offset < Duration.zero || offset > layer.duration) return;

    try {
      final handle = await _soloud.play(
        source,
        volume: layer.volume,
        paused: true,
      );
      _soloud.seek(handle, offset);
      _soloud.setPause(handle, false);
      _handles[layer.id] = handle;
    } catch (ex) {
      dev.log('Failed to play layer ${layer.id}: $ex',
          name: 'RecordingPlayback');
    }
  }

  /// Start all loaded, unmuted layers at the correct offsets.
  Future<void> playAllLayers(
    List<RecordingLayer> layers,
    Duration songPosition,
  ) async {
    stopAll();
    for (final layer in layers) {
      if (!layer.isMuted) {
        await playLayer(layer, songPosition);
      }
    }
  }

  /// Stop a specific layer.
  void stopLayer(String layerId) {
    final handle = _handles.remove(layerId);
    if (handle != null) {
      try {
        _soloud.stop(handle);
      } catch (_) {}
    }
  }

  /// Stop all playing layers.
  void stopAll() {
    for (final entry in _handles.entries) {
      try {
        _soloud.stop(entry.value);
      } catch (_) {}
    }
    _handles.clear();
  }

  /// Update volume for a specific layer.
  void setLayerVolume(String layerId, double volume) {
    final handle = _handles[layerId];
    if (handle != null) {
      try {
        _soloud.setVolume(handle, volume);
      } catch (_) {}
    }
  }

  /// Mute/unmute a layer.
  void setLayerMute(String layerId, bool isMuted) {
    final handle = _handles[layerId];
    if (handle != null) {
      try {
        _soloud.setPause(handle, isMuted);
      } catch (_) {}
    }
  }

  /// Unload a layer source (when layer is deleted).
  Future<void> unloadLayer(String layerId) async {
    stopLayer(layerId);
    final source = _sources.remove(layerId);
    if (source != null) {
      await _soloud.disposeSource(source);
    }
  }

  /// Dispose all sources.
  Future<void> dispose() async {
    stopAll();
    for (final source in _sources.values) {
      await _soloud.disposeSource(source);
    }
    _sources.clear();
  }
}

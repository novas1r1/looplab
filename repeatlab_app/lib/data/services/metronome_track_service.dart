import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns the legacy baked-mix cache directory
/// (`<appSupport>/metronome_mixes/<songId>/`).
///
/// The metronome now runs natively inside the playback pipeline on every
/// supported platform, so mixes are never created anymore — this service
/// only deletes what earlier app versions cached.
class MetronomeTrackService {
  MetronomeTrackService({
    Future<Directory> Function()? cacheDirProvider,
  }) : _cacheDirProvider = cacheDirProvider ?? _defaultCacheDir;

  final Future<Directory> Function() _cacheDirProvider;

  static Future<Directory> _defaultCacheDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'metronome_mixes'));
  }

  /// Removes the entire mix cache. Called once at startup: the native
  /// in-pipeline metronome replaced the baked track everywhere, so cached
  /// full-song mixes from earlier versions are dead weight.
  Future<void> clearAll() async {
    final cacheRoot = await _cacheDirProvider();
    if (cacheRoot.existsSync()) {
      await cacheRoot.delete(recursive: true);
    }
  }

  /// Removes all cached mixes for a song (e.g. when the song is deleted).
  Future<void> clearForSong(String songId) async {
    final cacheRoot = await _cacheDirProvider();
    final songDir = Directory(p.join(cacheRoot.path, songId));
    if (songDir.existsSync()) {
      try {
        await songDir.delete(recursive: true);
      } catch (e) {
        log('Failed to delete ${songDir.path}: $e', name: 'MetronomeTrackService');
      }
    }
  }
}

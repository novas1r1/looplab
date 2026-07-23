import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/core/utils/click_track_renderer.dart';

/// Everything that shapes the rendered click track. Two equal configs mix
/// to the same file, which is what the cache is keyed on.
class ClickTrackConfig {
  const ClickTrackConfig({
    required this.durationMs,
    required this.bpm,
    required this.anchorMs,
    required this.offsetMs,
    required this.beatsPerBar,
    required this.beatUnit,
    required this.pulsesPerBeat,
    required this.volume,
  });

  final int durationMs;

  /// The song's *original* BPM — playback speed does not change the grid,
  /// because speed is applied by the player to the mixed stream.
  final int bpm;
  final int? anchorMs;
  final int offsetMs;
  final int beatsPerBar;
  final int beatUnit;
  final int pulsesPerBeat;

  /// Click gain relative to the song (0.0..1.0).
  final double volume;

  String cacheKey(String songFileName) {
    final material = [
      'v${ClickTrackRenderer.version}',
      songFileName,
      durationMs,
      bpm,
      anchorMs ?? 'none',
      offsetMs,
      beatsPerBar,
      beatUnit,
      pulsesPerBeat,
      volume.toStringAsFixed(2),
    ].join('|');
    return sha1.convert(utf8.encode(material)).toString();
  }
}

/// Runs an ffmpeg command line, returning true on success. Injectable so
/// tests never touch the ffmpeg_kit plugin.
typedef FfmpegCommandRunner = Future<bool> Function(String command);

/// Renders a click track for a song and mixes it with the song file into a
/// single cached audio file (via ffmpeg). Playing that file through the
/// normal pipeline keeps the clicks sample-locked to the music across
/// loops, seeks and speed changes — see
/// docs/plans/2026-07-23-metronome-track-design.md.
///
/// Cache layout: `<appSupport>/metronome_mixes/<songId>/<configHash>.m4a`,
/// with only the most recent mix kept per song.
class MetronomeTrackService {
  MetronomeTrackService({
    FfmpegCommandRunner? runFfmpeg,
    Future<Directory> Function()? cacheDirProvider,
  })  : _runFfmpeg = runFfmpeg ?? _defaultRunFfmpeg,
        _cacheDirProvider = cacheDirProvider ?? _defaultCacheDir;

  final FfmpegCommandRunner _runFfmpeg;
  final Future<Directory> Function() _cacheDirProvider;

  static Future<bool> _defaultRunFfmpeg(String command) async {
    final session = await FFmpegKit.execute(command);
    return ReturnCode.isSuccess(await session.getReturnCode());
  }

  static Future<Directory> _defaultCacheDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'metronome_mixes'));
  }

  /// Returns the path of the mixed song+click file for [config], mixing it
  /// now if it is not cached yet. Throws on render/mix failure.
  Future<String> ensureMixedTrack({
    required String songId,
    required String songPath,
    required ClickTrackConfig config,
  }) async {
    final cacheRoot = await _cacheDirProvider();
    final songDir = Directory(p.join(cacheRoot.path, songId));
    await songDir.create(recursive: true);

    final key = config.cacheKey(p.basename(songPath));
    final mixedFile = File(p.join(songDir.path, '$key.m4a'));
    if (mixedFile.existsSync()) return mixedFile.path;

    final clickFile = File(p.join(songDir.path, '$key.click.wav'));
    try {
      final wav = ClickTrackRenderer.renderWav(
        durationMs: config.durationMs,
        bpm: config.bpm,
        anchorMs: config.anchorMs,
        offsetMs: config.offsetMs,
        beatsPerBar: config.beatsPerBar,
        pulsesPerBeat: config.pulsesPerBeat,
      );
      await clickFile.writeAsBytes(wav, flush: true);

      final command = _mixCommand(
        songPath: songPath,
        clickPath: clickFile.path,
        outputPath: mixedFile.path,
        clickVolume: config.volume,
      );
      log('Mixing click track: $command', name: 'MetronomeTrackService');

      final success = await _runFfmpeg(command);
      if (!success || !mixedFile.existsSync()) {
        throw Exception('ffmpeg mix failed for $songPath');
      }

      _evictOtherMixes(songDir, keep: mixedFile.path);
      return mixedFile.path;
    } catch (_) {
      // Never leave a half-written mix behind — it would be served as a
      // cache hit on the next attempt.
      _deleteQuietly(mixedFile);
      rethrow;
    } finally {
      _deleteQuietly(clickFile);
    }
  }

  /// Removes all cached mixes for a song (e.g. when the song is deleted).
  Future<void> clearForSong(String songId) async {
    final cacheRoot = await _cacheDirProvider();
    final songDir = Directory(p.join(cacheRoot.path, songId));
    if (songDir.existsSync()) {
      await songDir.delete(recursive: true);
    }
  }

  /// One mix per song: settings changes replace, never accumulate.
  void _evictOtherMixes(Directory songDir, {required String keep}) {
    for (final entity in songDir.listSync()) {
      if (entity is File && entity.path != keep) {
        _deleteQuietly(entity);
      }
    }
  }

  void _deleteQuietly(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      log('Failed to delete ${file.path}: $e', name: 'MetronomeTrackService');
    }
  }

  /// Song at unity gain, click scaled by [clickVolume]; `normalize=0` keeps
  /// amix from halving both, and the limiter absorbs the summed peaks so
  /// the AAC encode doesn't clip.
  static String _mixCommand({
    required String songPath,
    required String clickPath,
    required String outputPath,
    required double clickVolume,
  }) {
    final gain = clickVolume.clamp(0.0, 1.0).toStringAsFixed(3);
    const stereo44k =
        'aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo';
    const mix = '[song][click]amix=inputs=2:duration=first'
        ':dropout_transition=0:normalize=0,alimiter=limit=0.97[out]';
    final filter = [
      '[0:a]$stereo44k[song]',
      '[1:a]volume=$gain,$stereo44k[click]',
      mix,
    ].join(';');
    return '-y -i "$songPath" -i "$clickPath" '
        '-filter_complex "$filter" '
        '-map "[out]" -c:a aac -b:a 192k "$outputPath"';
  }
}

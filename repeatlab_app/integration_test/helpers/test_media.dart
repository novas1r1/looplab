// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Test media helpers.
///
/// `assets/test/` ships one tiny (~1 s, 64×64 / mono) clip per import format
/// the app offers in its pickers — see `assets/test/README.md` for how they
/// were generated. [bundledAudioFormats] / [bundledVideoFormats] must be kept in
/// sync with `FileRepository._audioPickerExtensions` and
/// `SongRepository.videoPickerExtensions*`.
///
/// Audio can additionally be **synthesised at runtime** as a short silent
/// 16-bit PCM WAV ([silentWavBytes]) for flows that just need "some audio
/// file" without touching the bundle.
abstract final class TestMedia {
  /// Audio formats with a bundled `assets/test/test_audio.<ext>` clip.
  static const bundledAudioFormats = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'wma',
    'opus',
    'aiff',
  ];

  /// Video formats with a bundled `assets/test/test_video.<ext>` clip.
  static const bundledVideoFormats = [
    'mp4',
    'mov',
    'm4v',
    'mkv',
    'webm',
    'avi',
  ];

  static String bundledAudioAsset(String ext) => 'assets/test/test_audio.$ext';
  static String bundledVideoAsset(String ext) => 'assets/test/test_video.$ext';

  /// Builds a valid silent mono 16-bit PCM WAV of [seconds] length at 8 kHz.
  static Uint8List silentWavBytes({int seconds = 2, int sampleRate = 8000}) {
    final numSamples = seconds * sampleRate;
    const bitsPerSample = 16;
    const channels = 1;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = numSamples * blockAlign;

    final builder = BytesBuilder();
    void writeString(String s) => builder.add(s.codeUnits);
    void writeUint32(int v) {
      final b = ByteData(4)..setUint32(0, v, Endian.little);
      builder.add(b.buffer.asUint8List());
    }

    void writeUint16(int v) {
      final b = ByteData(2)..setUint16(0, v, Endian.little);
      builder.add(b.buffer.asUint8List());
    }

    // RIFF header
    writeString('RIFF');
    writeUint32(36 + dataSize);
    writeString('WAVE');
    // fmt chunk
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1); // PCM
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(blockAlign);
    writeUint16(bitsPerSample);
    // data chunk (silence → all zeros)
    writeString('data');
    writeUint32(dataSize);
    builder.add(Uint8List(dataSize));

    return builder.toBytes();
  }

  /// Writes a synthesised silent WAV of [seconds] length to a temp file and
  /// returns it. Journeys that play, seek and set loop points want a longer
  /// clip than the 2 s default.
  static Future<File> writeSilentWavToTemp({
    String name = 'e2e_audio.wav',
    int seconds = 2,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(silentWavBytes(seconds: seconds), flush: true);
    return file;
  }

  /// Copies the bundled asset at [asset] to a temp file named [name] (the
  /// picker fake hands the app this path, so its extension is what the import
  /// pipeline sees) and returns it. Throws if the asset is not in the bundle —
  /// a missing clip is a harness bug, not something to skip past.
  static Future<File> writeBundledAssetToTemp(
    String asset, {
    required String name,
  }) async {
    final data = await rootBundle.load(asset);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }

  /// The bundled audio clip for [ext] as a temp file named
  /// [bundledAudioTempName] — the stem carries the format so several formats
  /// can be imported side by side without colliding (also after the app's
  /// `<stem>.wav` conversion).
  static Future<File> writeBundledAudioToTemp(String ext) =>
      writeBundledAssetToTemp(
        bundledAudioAsset(ext),
        name: bundledAudioTempName(ext),
      );

  static String bundledAudioTempName(String ext) => 'e2e_audio_$ext.$ext';

  /// The bundled video clip for [ext] as a temp file (`e2e_video_<ext>.<ext>`).
  static Future<File> writeBundledVideoToTemp({String ext = 'mp4'}) =>
      writeBundledAssetToTemp(
        bundledVideoAsset(ext),
        name: 'e2e_video_$ext.$ext',
      );
}

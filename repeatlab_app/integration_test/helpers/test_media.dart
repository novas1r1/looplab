// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Test media helpers.
///
/// Audio is **synthesised at runtime** as a short silent 16-bit PCM WAV — WAV is
/// natively supported by SoLoud, so no binary asset needs to be committed and
/// the add-audio flow is fully self-contained.
///
/// Video cannot be synthesised (media_kit probes a real container for a non-zero
/// duration), so the add-video flow consumes a committed asset. Drop a short
/// (~5 s) clip at `assets/test/test_video.mp4` and declare `- assets/test/` under
/// `flutter: assets:` in `pubspec.yaml` to enable it; until then the video flow
/// skips itself with an explanatory message.
abstract final class TestMedia {
  static const bundledVideoAsset = 'assets/test/test_video.mp4';

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

  /// Writes a synthesised silent WAV to a temp file and returns it.
  static Future<File> writeSilentWavToTemp({String name = 'e2e_audio.wav'}) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(silentWavBytes(), flush: true);
    return file;
  }

  /// Copies the bundled test video asset to a temp file, or returns `null` if
  /// the asset has not been added to the bundle yet (see class doc).
  static Future<File?> writeBundledVideoToTemp({
    String name = 'e2e_video.mp4',
  }) async {
    try {
      final data = await rootBundle.load(bundledVideoAsset);
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, name));
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }
}

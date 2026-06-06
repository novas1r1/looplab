import 'package:dart_mappable/dart_mappable.dart';

part 'backup_manifest.mapper.dart';

@MappableClass()
class BackupManifest with BackupManifestMappable {
  /// Bump when the on-disk backup format changes in a way existing importers
  /// can't handle. Older versions are accepted with migrations; newer versions
  /// are rejected.
  ///
  /// Version history:
  /// * v1 — initial format. Songs lack `mediaType`; decoded as audio.
  /// * v2 — adds `mediaType` to `Song`. The `audioFiles` map name is kept
  ///   for backward compat; it now stores any media file (audio or video).
  ///   v1 backups still import: missing `mediaType` defaults to `audio`.
  ///
  /// Note: the format also evolved within v2. Early v2 exports (1.7.x–2.0.1)
  /// included a per-file `sha256` hash on each [BackupFileInfo] entry and
  /// verified it on decode. From 2.0.2 onwards the hash is no longer written
  /// and verification is skipped — zip CRC32 already covers accidental
  /// corruption, and removing the hash enables streaming export for large
  /// (video-sized) libraries. Old exports still import: the field is now
  /// optional on the model.
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String appVersion;
  final String exportedAt;
  final int songCount;
  final Map<String, BackupFileInfo> audioFiles;

  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.songCount,
    required this.audioFiles,
  });
}

@MappableClass()
class BackupFileInfo with BackupFileInfoMappable {
  /// SHA-256 of the audio bytes — populated by exports from 1.7.x–2.0.1,
  /// omitted from 2.0.2 onwards. Decoders no longer verify it; the field is
  /// retained on the model so older backups still deserialize without error.
  final String? sha256;
  final int size;

  const BackupFileInfo({
    required this.size,
    this.sha256,
  });
}

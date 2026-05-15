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
  final String sha256;
  final int size;

  const BackupFileInfo({
    required this.sha256,
    required this.size,
  });
}

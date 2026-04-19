/// Thrown when the backup archive is missing required parts or is malformed.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Thrown when the backup was produced by a newer app version than the one
/// attempting to import it.
class BackupSchemaVersionException implements Exception {
  final int backupVersion;
  final int supportedVersion;

  const BackupSchemaVersionException({
    required this.backupVersion,
    required this.supportedVersion,
  });

  @override
  String toString() =>
      'BackupSchemaVersionException: backup is v$backupVersion, '
      'app supports up to v$supportedVersion';
}

/// Thrown when an audio file's content hash doesn't match the manifest — the
/// archive is either corrupted or was tampered with.
class BackupHashMismatchException implements Exception {
  final String fileName;
  const BackupHashMismatchException(this.fileName);

  @override
  String toString() =>
      'BackupHashMismatchException: hash mismatch for "$fileName"';
}

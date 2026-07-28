/// Process-wide flag marking whether a backup export or import is currently
/// reading/writing song media files. [SongRepository]'s file-deletion paths
/// (`deleteSong`, `clearDb`, `sweepOrphanedFiles`) check [isActive] and skip
/// deleting files while a transfer is in flight, so they never race
/// `BackupRepository` over the same files — see RL-31 / RL-369.
///
/// Deliberately a single global flag, not a generalized lock/queue: the
/// sweep is a best-effort one-time pass (safe to simply skip a run) and
/// `deleteSong`/`clearDb` still remove the DB record regardless, so a
/// skipped file delete just becomes eligible for the next startup sweep.
class BackupActivityGuard {
  BackupActivityGuard._();

  static bool _isActive = false;

  static bool get isActive => _isActive;

  /// Runs [action] with the guard held for its duration, clearing it even if
  /// [action] throws.
  static Future<T> run<T>(Future<T> Function() action) async {
    _isActive = true;
    try {
      return await action();
    } finally {
      _isActive = false;
    }
  }

  /// Test-only escape hatch to force the flag back to inactive if a test
  /// fails mid-[run] and leaves it set.
  static void reset() {
    _isActive = false;
  }
}

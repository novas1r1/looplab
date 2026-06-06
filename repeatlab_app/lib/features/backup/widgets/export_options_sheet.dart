import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Lets the user choose what to include in a `.rlbackup` export before the
/// repository actually starts writing. Returns the chosen
/// [BackupExportOptions] when the user confirms, or `null` if they cancel
/// (or dismiss by tapping outside).
///
/// All three checkboxes default to on — "give me everything" is the common
/// path, the picker is here for the cases where someone wants to slim down
/// a video-heavy backup or do a clean re-import on another device.
Future<BackupExportOptions?> showBackupExportOptionsSheet(
  BuildContext context,
) {
  return showModalBottomSheet<BackupExportOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    builder: (_) => const _BackupExportOptionsSheet(),
  );
}

class _BackupExportOptionsSheet extends StatefulWidget {
  const _BackupExportOptionsSheet();

  @override
  State<_BackupExportOptionsSheet> createState() =>
      _BackupExportOptionsSheetState();
}

class _BackupExportOptionsSheetState extends State<_BackupExportOptionsSheet> {
  bool _audios = true;
  bool _videos = true;
  bool _loopsAndSettings = true;

  BackupExportOptions get _current => BackupExportOptions(
    includeAudioSongs: _audios,
    includeVideoSongs: _videos,
    includeLoopsAndSettings: _loopsAndSettings,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canExport = _current.hasAnyMedia;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.backupExportSheetTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _audios,
              onChanged: (v) => setState(() => _audios = v ?? false),
              title: Text(l10n.backupExportOptionAudios),
              subtitle: Text(l10n.backupExportOptionAudiosSubtitle),
              secondary: const Icon(Icons.audiotrack),
            ),
            CheckboxListTile(
              value: _videos,
              onChanged: (v) => setState(() => _videos = v ?? false),
              title: Text(l10n.backupExportOptionVideos),
              subtitle: Text(l10n.backupExportOptionVideosSubtitle),
              secondary: const Icon(Icons.movie),
            ),
            CheckboxListTile(
              value: _loopsAndSettings,
              onChanged: (v) =>
                  setState(() => _loopsAndSettings = v ?? false),
              title: Text(l10n.backupExportOptionLoopsAndSettings),
              subtitle: Text(l10n.backupExportOptionLoopsAndSettingsSubtitle),
              secondary: const Icon(Icons.tune),
            ),
            if (!canExport)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.backupExportSheetNoMediaSelected,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.backupExportSheetCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canExport
                          ? () => Navigator.of(context).pop(_current)
                          : null,
                      child: Text(l10n.backupExportSheetExport),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

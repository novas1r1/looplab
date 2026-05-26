import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/snackbar_helper.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/song/cubit/song_exporter/song_exporter_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

class ExportLoopBottomUp extends StatefulWidget {
  final Loop loop;
  final Song song;

  const ExportLoopBottomUp({
    super.key,
    required this.loop,
    required this.song,
  });

  @override
  State<ExportLoopBottomUp> createState() => _ExportLoopBottomUpState();
}

class _ExportLoopBottomUpState extends State<ExportLoopBottomUp> {
  static const List<int> _sampleRateOptions = [44100, 48000];

  AudioExportFormat _selectedFormat = AudioExportFormat.wav;
  int _selectedSampleRate = 44100;

  bool _isExportDialogVisible = false;
  bool _isHandlingSave = false;
  BuildContext? _exportDialogContext;

  @override
  void dispose() {
    _dismissExportProgressDialog();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SongExporterCubit, SongExporterState>(
      listener: (context, state) async {
        if (state.status == SongExporterStatus.exporting) {
          _showExportProgressDialog();
        } else {
          _dismissExportProgressDialog();
        }

        switch (state.status) {
          case SongExporterStatus.awaitingSave:
            await _handlePendingSave(state);
          case SongExporterStatus.exportSuccess:
            AppAnalytics.trackEvent(
              AppAnalytics.exportLoopSuccess,
              data: {
                'format': state.format?.name ?? _selectedFormat.name,
                'sampleRateHz': _selectedSampleRate,
              },
            );
            final fileName = state.exportedFilePath != null
                ? p.basename(state.exportedFilePath!)
                : state.suggestedFileName ?? widget.loop.name;
            SnackbarHelper.showSuccess(
              context,
              context.l10n.loopExportSuccessWithPath(fileName),
            );
            context.read<SongExporterCubit>().reset();
            if (mounted) {
              Navigator.of(context).pop();
            }
          case SongExporterStatus.exportCanceled:
            AppAnalytics.trackEvent(AppAnalytics.exportLoopCanceled);
            SnackbarHelper.showInfo(
              context,
              context.l10n.loopExportCanceled,
            );
            context.read<SongExporterCubit>().reset();
          case SongExporterStatus.exportError:
            if (state.errorMessage == null) {
              break;
            }
            AppAnalytics.trackEvent(
              AppAnalytics.exportLoopError,
              data: {'reason': state.errorMessage},
            );
            final message =
                state.errorMessage == SongExporterCubit.invalidLoopRangeErrorKey
                ? context.l10n.loopExportValidationError
                : context.l10n.loopExportError(state.errorMessage!);

            SnackbarHelper.showError(context, message);
            context.read<SongExporterCubit>().reset();
          default:
            break;
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.loopExportDialogTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(context.l10n.loopExportDialogDescription),
              const SizedBox(height: 12),
              Text(
                context.l10n.loopExportFormatLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<AudioExportFormat>(
                groupValue: _selectedFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFormat = value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<AudioExportFormat>(
                      contentPadding: EdgeInsets.zero,
                      value: AudioExportFormat.wav,
                      title: Text(
                        context.l10n.loopExportFormatWav,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.loopExportSampleRateLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              DropdownButton<int>(
                value: _selectedSampleRate,
                isExpanded: true,
                items: _sampleRateOptions
                    .map(
                      (rate) => DropdownMenuItem<int>(
                        value: rate,
                        child: Text(_formatSampleRate(rate)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSampleRate = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onExportLoop,
                      child: Text(context.l10n.loopExportConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onExportLoop() {
    final exporterCubit = context.read<SongExporterCubit>();

    if (exporterCubit.state.status == SongExporterStatus.exporting) {
      return;
    }

    AppAnalytics.trackEvent(
      AppAnalytics.clickExportLoop,
      data: {
        'format': _selectedFormat.name,
        'sampleRateHz': _selectedSampleRate,
      },
    );

    exporterCubit.exportLoop(
      song: widget.song,
      loop: widget.loop,
      format: _selectedFormat,
      sampleRateHz: _selectedSampleRate,
    );
  }

  Future<void> _handlePendingSave(SongExporterState state) async {
    if (_isHandlingSave) {
      return;
    }

    final bytes = state.pendingBytes;
    if (bytes == null) {
      context.read<SongExporterCubit>().completePendingSave(null);
      return;
    }

    _isHandlingSave = true;
    try {
      // TODO: extract this and use file picker wrapper
      final savedPath = await FilePicker.saveFile(
        dialogTitle: context.l10n.loopExportPickLocation,
        fileName:
            state.suggestedFileName ??
            '${_sanitizeFileName(widget.song.title)}.${state.format?.fileExtension ?? _selectedFormat.fileExtension}',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [
          (state.format ?? _selectedFormat).fileExtension,
        ],
      );

      if (!mounted) {
        return;
      }

      context.read<SongExporterCubit>().completePendingSave(savedPath);
    } finally {
      _isHandlingSave = false;
    }
  }

  String _formatSampleRate(int sampleRate) {
    final value = sampleRate / 1000;
    return sampleRate % 1000 == 0
        ? '${value.toStringAsFixed(0)} kHz'
        : '${value.toStringAsFixed(1)} kHz';
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'loop' : sanitized;
  }

  void _showExportProgressDialog() {
    if (_isExportDialogVisible || !mounted) {
      return;
    }

    _isExportDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _exportDialogContext = dialogContext;
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(context.l10n.loopExportInProgress),
              ),
            ],
          ),
        );
      },
    );
  }

  void _dismissExportProgressDialog() {
    if (!_isExportDialogVisible) {
      return;
    }

    if (_exportDialogContext != null) {
      try {
        Navigator.of(_exportDialogContext!).pop();
      } catch (_) {
        // The dialog might already be dismissed.
      }
      _exportDialogContext = null;
    }

    _isExportDialogVisible = false;
  }
}

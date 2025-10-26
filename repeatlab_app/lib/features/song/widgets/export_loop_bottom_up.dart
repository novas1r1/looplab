import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  AudioExportFormat _lastExportFormat = AudioExportFormat.mp3;

  int _lastSampleRateHz = 44100;
  int _lastMp3BitrateKbps = 192;

  final TextEditingController _titleController = TextEditingController();

  String? _startError;
  String? _endError;

  static const List<int> _mp3BitrateOptions = [128, 192, 256, 320];
  static const List<int> _sampleRateOptions = [44100, 48000];

  bool _isExportDialogVisible = false;
  BuildContext? _exportDialogContext;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.loop.name;
  }

  @override
  void dispose() {
    _dismissExportProgressDialog();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SongExporterCubit, SongExporterState>(
      listener: (context, state) {
        if (state.status == SongExporterStatus.exporting) {
          _showExportProgressDialog();
        } else {
          _dismissExportProgressDialog();
        }
      },
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    icon: const Icon(
                      Icons.close,
                    ),
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
                groupValue: _lastExportFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _lastExportFormat = value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: AudioExportFormat.wav,

                      title: Text(
                        context.l10n.loopExportFormatWav,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: AudioExportFormat.mp3,
                      title: Text(
                        context.l10n.loopExportFormatMp3,
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
                value: _lastSampleRateHz,
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
                    setState(() => _lastSampleRateHz = value);
                  }
                },
              ),
              if (_lastExportFormat == AudioExportFormat.mp3) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.loopExportBitrateLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                DropdownButton<int>(
                  value: _lastMp3BitrateKbps,
                  isExpanded: true,
                  items: _mp3BitrateOptions
                      .map(
                        (rate) => DropdownMenuItem<int>(
                          value: rate,
                          child: Text('$rate kbps'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _lastMp3BitrateKbps = value);
                    }
                  },
                ),
              ],
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
                      onPressed: () => _onExportLoop(),
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

  Future<void> _onExportLoop() async {
    final exporterCubit = context.read<SongExporterCubit>();

    if (exporterCubit.state.status == SongExporterStatus.exporting) {
      return;
    }

    if (_startError != null || _endError != null) {
      SnackbarHelper.showError(context, context.l10n.loopExportValidationError);
      return;
    }

    final loopStart = widget.loop.start ?? Duration.zero;
    final loopEnd = widget.loop.end ?? widget.song.duration;

    if (loopEnd <= loopStart) {
      setState(() {
        _startError = context.l10n.startCannotBeAfterEnd;
        _endError = context.l10n.endCannotBeBeforeStart;
      });
      SnackbarHelper.showError(context, context.l10n.loopExportValidationError);
      return;
    }

    final inputPath = await widget.song.path;

    if (!mounted) {
      return;
    }

    final suggestedFileName = _buildSuggestedFileName(
      songTitle: widget.song.title,
      loopName: widget.loop.name,
      format: _lastExportFormat,
      sampleRateHz: _lastSampleRateHz,
      bitrateKbps: _lastExportFormat == AudioExportFormat.mp3 ? _lastMp3BitrateKbps : null,
    );

    String outputPath;
    bool promptForDestinationAfterExport = false;

    final tempDirectory = await getTemporaryDirectory();
    outputPath = p.join(tempDirectory.path, suggestedFileName);
    promptForDestinationAfterExport = true;

    await exporterCubit.exportLoop(
      inputPath: inputPath,
      outputPath: outputPath,
      startTime: loopStart,
      duration: loopEnd - loopStart,
      format: _lastExportFormat,
      sampleRateHz: _lastSampleRateHz,
      bitrateKbps: _lastExportFormat == AudioExportFormat.mp3 ? _lastMp3BitrateKbps : null,
    );

    if (!mounted || !promptForDestinationAfterExport) {
      return;
    }

    final exporterState = exporterCubit.state;
    if (exporterState.status != SongExporterStatus.exportSuccess) {
      return;
    }

    final tempFile = File(outputPath);
    if (!await tempFile.exists()) {
      exporterCubit.reset();
      return;
    }

    try {
      final fileBytes = await tempFile.readAsBytes();
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: context.l10n.loopExportPickLocation,
        fileName: suggestedFileName,
        bytes: fileBytes,
        type: FileType.custom,
        allowedExtensions: [_lastExportFormat.fileExtension],
      );

      if (!mounted) {
        return;
      }

      if (savedPath != null) {
        final fileName = p.basename(savedPath);
        SnackbarHelper.showSuccess(
          context,
          context.l10n.loopExportSuccessWithPath(fileName),
        );
      } else {
        SnackbarHelper.showInfo(
          context,
          context.l10n.loopExportCanceled,
        );
      }
    } finally {
      await tempFile.delete().catchError((_) {});
      exporterCubit.reset();
    }
  }

  String _buildSuggestedFileName({
    required String songTitle,
    required String loopName,
    required AudioExportFormat format,
    required int sampleRateHz,
    required int? bitrateKbps,
  }) {
    final sanitizedSong = _sanitizeFileName(songTitle);
    final sanitizedLoop = _sanitizeFileName(
      loopName.isNotEmpty ? loopName : context.l10n.loopExportFallbackName,
    );

    return '$sanitizedSong-$sanitizedLoop-${sampleRateHz}Hz-${bitrateKbps}kbps.${format.fileExtension}';
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'loop' : sanitized;
  }

  String _formatSampleRate(int sampleRate) {
    final value = sampleRate / 1000;
    return sampleRate % 1000 == 0
        ? '${value.toStringAsFixed(0)} kHz'
        : '${value.toStringAsFixed(1)} kHz';
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

class _LoopExportOptions {
  final AudioExportFormat format;
  final int sampleRateHz;
  final int? bitrateKbps;

  const _LoopExportOptions({
    required this.format,
    required this.sampleRateHz,
    this.bitrateKbps,
  });
}

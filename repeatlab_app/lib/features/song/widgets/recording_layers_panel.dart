import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';
import 'package:repeatlab/features/song/widgets/recording_layer_tile.dart';
import 'package:repeatlab/l10n/l10n.dart';

class RecordingLayersPanel extends StatelessWidget {
  const RecordingLayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecordingCubit, RecordingState, List<RecordingLayer>>(
      selector: (state) => state.layers,
      builder: (context, layers) {
        if (layers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            AutoSizeText(
              context.l10n.recordings,
              minFontSize: 16,
              maxFontSize: 24,
              style: context.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...layers.map(
              (layer) => RecordingLayerTile(
                key: ValueKey(layer.id),
                layer: layer,
                onToggleMute: () =>
                    context.read<RecordingCubit>().toggleMute(layer),
                onVolumeChanged: (volume) =>
                    context.read<RecordingCubit>().setVolume(layer, volume),
                onDelete: () => _onDeleteLayer(context, layer),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDeleteLayer(
    BuildContext context,
    RecordingLayer layer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        title: Text(context.l10n.deleteRecording),
        content: Text(context.l10n.deleteRecordingConfirmation),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: AppColors.onError),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            label: Text(context.l10n.delete),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<RecordingCubit>().deleteLayer(layer);
    }
  }
}

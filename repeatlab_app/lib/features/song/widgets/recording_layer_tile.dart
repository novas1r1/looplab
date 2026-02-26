import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:repeatlab/l10n/l10n.dart';

class RecordingLayerTile extends StatelessWidget {
  final RecordingLayer layer;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onDelete;

  const RecordingLayerTile({
    super.key,
    required this.layer,
    required this.onToggleMute,
    required this.onVolumeChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: layer.isMuted ? Colors.grey : AppColors.primaryContainer,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.mic,
                size: 16,
                color: layer.isMuted ? Colors.grey : Colors.red,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  layer.label ?? context.l10n.record,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: layer.isMuted ? Colors.grey : null,
                  ),
                ),
              ),
              Text(
                layer.startPosition.toFormattedString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Text(' - '),
              Text(
                (layer.startPosition + layer.duration).toFormattedString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleMute,
                  icon: Icon(
                    layer.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.volume_down, size: 16),
                Expanded(
                  child: Slider(
                    value: layer.volume,
                    onChanged: onVolumeChanged,
                  ),
                ),
                const Icon(Icons.volume_up, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

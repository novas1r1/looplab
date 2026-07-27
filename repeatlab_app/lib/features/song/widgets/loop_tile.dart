import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/cubit/song_exporter/song_exporter_cubit.dart';
import 'package:repeatlab/features/song/widgets/edit_loop_bottom_up.dart';
import 'package:repeatlab/features/song/widgets/export_loop_bottom_up.dart';
import 'package:repeatlab/l10n/l10n.dart';

class LoopTile extends StatefulWidget {
  final int index;
  final Loop loop;
  // final Duration songDuration;
  final bool isSelected;
  final bool isLocked;
  // final bool isPaused;

  final Function(Loop) onTap;
  final Function(Loop) onDelete;
  final Function(Loop) onPlay;
  final Function(Loop) onPause;
  final Function(Loop) onUpdate;
  final VoidCallback? onLockedTap;

  const LoopTile({
    super.key,
    required this.index,
    required this.loop,
    // required this.songDuration,
    required this.isSelected,
    this.isLocked = false,
    // required this.isPaused,
    required this.onTap,
    required this.onDelete,
    required this.onPlay,
    required this.onPause,
    required this.onUpdate,
    this.onLockedTap,
  });

  @override
  State<LoopTile> createState() => _LoopTileState();
}

class _LoopTileState extends State<LoopTile> {
  @override
  Widget build(BuildContext context) {
    const color = AppColors.primaryContainer;
    final isLocked = widget.isLocked;

    final content = Container(
      decoration: BoxDecoration(
        color: widget.isSelected ? color.withValues(alpha: 0.2) : null,
        border: Border.all(
          color: widget.isSelected ? color : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => isLocked ? widget.onLockedTap?.call() : widget.onTap(widget.loop),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        color: widget.loop.color.color,
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.loop.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock, size: 16, color: AppColors.iconDisabled),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    key: Key('song.loop.export.${widget.loop.id}'),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => isLocked ? widget.onLockedTap?.call() : _onExportLoop(),
                    icon: const AppIcon(iconName: 'ic_export'),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    key: Key('song.loop.edit.${widget.loop.id}'),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => isLocked ? widget.onLockedTap?.call() : _onEditLoop(),
                    icon: const AppIcon(iconName: 'ic_edit'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.start,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.loop.color.color,
                    ),
                  ),
                  Text(
                    context.l10n.end,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.loop.color.color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.loop.start?.toFormattedString() ?? '-',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    widget.loop.end?.toFormattedString() ?? '-',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isLocked) {
      return Opacity(opacity: 0.45, child: content);
    }
    return content;
  }

  Future<void> _onEditLoop() async {
    AppAnalytics.trackEvent(AppAnalytics.clickEditLoop);
    AppAnalytics.trackEvent(AppAnalytics.viewEditLoopDialog);

    final songDuration = context.read<SongCubit>().state.song.duration;

    final updatedLoop = await showModalBottomSheet<Loop?>(
      context: context,
      builder: (context) => EditLoopBottomUp(
        loop: widget.loop,
        songDuration: songDuration,
        onDelete: (loop) => widget.onDelete(widget.loop),
      ),
    );

    if (updatedLoop != null) {
      widget.onUpdate(updatedLoop);
    }
  }

  Future<void> _onExportLoop() async {
    AppAnalytics.trackEvent(AppAnalytics.viewExportLoopDialog);

    final exporterCubit = context.read<SongExporterCubit>();
    final songCubit = context.read<SongCubit>();

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: exporterCubit,
          ),
          BlocProvider.value(
            value: songCubit,
          ),
        ],
        child: ExportLoopBottomUp(
          loop: widget.loop,
          song: songCubit.state.song,
        ),
      ),
    );
  }
}

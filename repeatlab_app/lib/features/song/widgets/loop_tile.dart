import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/core/ui/motion_widgets.dart';
import 'package:repeatlab/core/ui/widgets/app_bottom_sheet.dart';
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
  final _shakeKey = GlobalKey<ShakeOnDeniedState>();

  void _onLockedTap() {
    _shakeKey.currentState?.shake();
    widget.onLockedTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primaryContainer;
    final isLocked = widget.isLocked;

    // AnimatedContainer glides the selection highlight (border + tint)
    // instead of snapping.
    final content = AnimatedContainer(
      duration: Motion.of(context, Motion.standard),
      curve: Motion.emphasized,
      decoration: BoxDecoration(
        color: widget.isSelected
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0),
        border: Border.all(
          color: widget.isSelected ? color : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => isLocked ? _onLockedTap() : widget.onTap(widget.loop),
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
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
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
                    onPressed: () =>
                        isLocked ? _onLockedTap() : _onExportLoop(),
                    icon: const Icon(Icons.upload_file, size: 20),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    key: Key('song.loop.edit.${widget.loop.id}'),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => isLocked ? _onLockedTap() : _onEditLoop(),
                    icon: const Icon(Icons.more_vert, size: 20),
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

    // New loops fade in on mount (paired with the auto-scroll on loop-add);
    // the locked dim animates so a premium unlock brightens tiles smoothly.
    return EntranceSlideFade(
      duration: const Duration(milliseconds: 200),
      offsetY: 8,
      child: ShakeOnDenied(
        key: _shakeKey,
        child: AnimatedOpacity(
          opacity: isLocked ? 0.45 : 1,
          duration: Motion.of(context, Motion.standard),
          child: content,
        ),
      ),
    );
  }

  Future<void> _onEditLoop() async {
    AppAnalytics.trackEvent(AppAnalytics.clickEditLoop);
    AppAnalytics.trackEvent(AppAnalytics.viewEditLoopDialog);

    final songDuration = context.read<SongCubit>().state.song.duration;

    final updatedLoop = await AppBottomSheet.show<Loop?>(
      context,
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

    await AppBottomSheet.show<void>(
      context,
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

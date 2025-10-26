import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  // final bool isPaused;

  final Function(Loop) onTap;
  final Function(Loop) onDelete;
  final Function(Loop) onPlay;
  final Function(Loop) onPause;
  final Function(Loop) onUpdate;

  const LoopTile({
    super.key,
    required this.index,
    required this.loop,
    // required this.songDuration,
    required this.isSelected,
    // required this.isPaused,
    required this.onTap,
    required this.onDelete,
    required this.onPlay,
    required this.onPause,
    required this.onUpdate,
  });

  @override
  State<LoopTile> createState() => _LoopTileState();
}

class _LoopTileState extends State<LoopTile> {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;

    return Container(
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
        onTap: () => widget.onTap(widget.loop),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 16),
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
                    ],
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _onExportLoop(),
                    icon: const Icon(Icons.upload_file, size: 20),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _onEditLoop(),
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
  }

  Future<void> _onEditLoop() async {
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
    final songDuration = context.read<SongCubit>().state.song.duration;

    final exporterCubit = context.read<SongExporterCubit>();
    final songCubit = context.read<SongCubit>();

    final updatedLoop = await showModalBottomSheet<Loop?>(
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

    if (updatedLoop != null) {
      widget.onUpdate(updatedLoop);
    }
  }
}

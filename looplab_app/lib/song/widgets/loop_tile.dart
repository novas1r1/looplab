import 'package:flutter/material.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/models/loop.dart';
import 'package:looplab/song/widgets/edit_loop_bottom_up.dart';

class LoopTile extends StatefulWidget {
  final int index;
  final Loop loop;
  final bool isSelected;
  final bool isPaused;

  final Function(Loop) onTap;
  final Function(Loop) onDelete;
  final Function(Loop) onPlay;
  final Function(Loop) onPause;
  final Function(Loop) onUpdate;
  final Function() onSetLoopStart;
  final Function() onSetLoopEnd;

  const LoopTile({
    super.key,
    required this.index,
    required this.loop,
    required this.isSelected,
    required this.isPaused,
    required this.onTap,
    required this.onDelete,
    required this.onPlay,
    required this.onPause,
    required this.onUpdate,
    required this.onSetLoopStart,
    required this.onSetLoopEnd,
  });

  @override
  State<LoopTile> createState() => _LoopTileState();
}

class _LoopTileState extends State<LoopTile> {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;

    return Ink(
      decoration: BoxDecoration(
        color: widget.isSelected ? color.withOpacity(0.2) : null,
        border: Border.all(
          color: widget.isSelected ? color : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onTap(widget.loop),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                    IconButton(
                      onPressed: () => _onEditLoop(),
                      icon: const Icon(Icons.more_vert, size: 20),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.loop.start?.toFormattedString() ?? '-'),
                      Text(widget.loop.end?.toFormattedString() ?? '-'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEditLoop() async {
    final updatedLoop = await showModalBottomSheet<Loop?>(
      context: context,
      builder: (context) => EditLoopBottomUp(
        loop: widget.loop,
        onDelete: (loop) => widget.onDelete(widget.loop),
      ),
    );

    if (updatedLoop != null) {
      widget.onUpdate(updatedLoop);
    }
  }
}

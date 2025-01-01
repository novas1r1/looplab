import 'package:flutter/material.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/models/loop.dart';

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
  });

  @override
  State<LoopTile> createState() => _LoopTileState();
}

class _LoopTileState extends State<LoopTile> {
  final _titleController = TextEditingController();

  String? _loopTitle;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loopTitle = widget.loop.name;
    _titleController.text = widget.loop.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate a unique color for each loop based on its ID
    final color = widget.loop.color.color;

    return Container(
      decoration: BoxDecoration(
        color: widget.isSelected ? color.withOpacity(0.2) : null,
        border: Border.all(
          color: widget.isSelected ? color : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        selectedColor: Theme.of(context).colorScheme.primary,
        selected: widget.isSelected,
        onTap: () => widget.onTap(widget.loop),
        contentPadding: EdgeInsets.zero,
        leading: IconButton(
          onPressed: () =>
              widget.isPaused ? widget.onPlay(widget.loop) : widget.onPause(widget.loop),
          icon: Icon(
            widget.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: color,
          ),
        ),
        title: Row(
          children: [
            if (_isEditing)
              Expanded(
                child: TextField(
                  controller: _titleController,
                  onSubmitted: (value) => setState(() {
                    _loopTitle = value;
                    _isEditing = false;
                    widget.onUpdate(widget.loop.copyWith(name: _loopTitle));
                  }),
                ),
              ),
            if (!_isEditing) Text(widget.loop.name),
            IconButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: const Icon(Icons.edit, size: 20),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.loop.start?.toFormattedString() ?? '00:00'),
                ElevatedButton(
                  onPressed: () => widget.onDelete(widget.loop),
                  child: const Text('set start'),
                ),
              ],
            ),
            Column(
              children: [
                Text(widget.loop.end?.toFormattedString() ?? '00:00'),
                ElevatedButton(
                  onPressed: () => widget.onDelete(widget.loop),
                  child: const Text('set end'),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => widget.onDelete(widget.loop),
          icon: const Icon(Icons.delete),
        ),
      ),
    );
  }
}

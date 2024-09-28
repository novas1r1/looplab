import 'package:flutter/material.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/models/loop.dart';

class LoopTile extends StatefulWidget {
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
    return ListTile(
      selectedColor: Theme.of(context).colorScheme.primary,
      selected: widget.isSelected,
      onTap: () => widget.onTap(widget.loop),
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        onPressed: () => widget.isPaused ? widget.onPlay(widget.loop) : widget.onPause(widget.loop),
        icon: Icon(
          widget.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
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
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.loop.start?.toFormattedString() ?? '00:00'),
          Text(widget.loop.end?.toFormattedString() ?? '00:00'),
        ],
      ),
      trailing: IconButton(
        onPressed: () => widget.onDelete(widget.loop),
        icon: const Icon(Icons.delete),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/models/loop.dart';

class EditLoopBottomUp extends StatefulWidget {
  final Loop loop;
  final void Function(Loop loop) onDelete;

  const EditLoopBottomUp({
    super.key,
    required this.loop,
    required this.onDelete,
  });

  @override
  State<EditLoopBottomUp> createState() => _EditLoopBottomUpState();
}

class _EditLoopBottomUpState extends State<EditLoopBottomUp> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  String? _startError;
  String? _endError;

  late Loop _updatedLoop;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.loop.name;
    _startController.text =
        widget.loop.start?.toFormattedStringMinutesSecondsMilliseconds() ?? '-';
    _endController.text =
        widget.loop.end?.toFormattedStringMinutesSecondsMilliseconds() ?? '-';

    _updatedLoop = widget.loop;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 1.0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Loop',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _updatedLoop),
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Loop Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updatedLoop = _updatedLoop.copyWith(name: value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<LoopColor>(
                  value: _updatedLoop.color,
                  items: LoopColor.values.map((color) {
                    return DropdownMenuItem<LoopColor>(
                      value: color,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (LoopColor? newColor) {
                    if (newColor != null) {
                      setState(() {
                        _updatedLoop = _updatedLoop.copyWith(color: newColor);
                      });
                    }
                  },
                ),
                /*  GestureDetector(
                  onTap: () => _showColorPicker(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _updatedLoop.color.color,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                  ),
                ), */
              ],
            ),
            const SizedBox(height: 16),

            // Time controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: InputDecoration(
                      labelText: 'Start Time (mm:ss:ms)',
                      errorText: _startError,
                      border: const OutlineInputBorder(),
                      /* suffixIcon: IconButton(
                        icon: const Icon(Icons.start),
                        onPressed: widget.onSetLoopStart,
                      ), */
                    ),
                    onChanged: (value) => _validateAndUpdateTimes(value, null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: InputDecoration(
                      labelText: 'End Time (mm:ss:ms)',
                      errorText: _endError,
                      border: const OutlineInputBorder(),
                      /* suffixIcon: IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: widget.onSetLoopEnd,
                      ), */
                    ),
                    onChanged: (value) => _validateAndUpdateTimes(null, value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onDelete(widget.loop);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _updatedLoop),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Duration? _parseDuration(String value) {
    if (value.isEmpty) return null;

    final parts = value.split(':');
    if (parts.length != 3) return null;

    try {
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      final milliseconds = int.parse(parts[2]);

      if (seconds >= 60) return null;

      return Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } catch (e) {
      return null;
    }
  }

  void _validateAndUpdateTimes(String? startStr, String? endStr) {
    setState(() {
      _startError = null;
      _endError = null;

      final start =
          startStr != null ? _parseDuration(startStr) : widget.loop.start;
      final end = endStr != null ? _parseDuration(endStr) : widget.loop.end;

      if (startStr != null && start == null) {
        _startError = 'Invalid format (mm:ss:ms)';
        return;
      }

      if (endStr != null && end == null) {
        _endError = 'Invalid format (mm:ss:ms)';
        return;
      }

      if (start != null && end != null) {
        if (start > end) {
          _startError = 'Start cannot be after end';
          _endError = 'End cannot be before start';
          return;
        }
      }

      // Update the loop if validation passes
      if ((startStr != null && start != null) ||
          (endStr != null && end != null)) {
        _updatedLoop = _updatedLoop.copyWith(
          start: start ?? widget.loop.start,
          end: end ?? widget.loop.end,
        );
      }
    });
  }
}

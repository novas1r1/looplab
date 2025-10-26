import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/l10n/l10n.dart';

class EditLoopBottomUp extends StatefulWidget {
  final Loop loop;
  final Duration songDuration;
  final void Function(Loop loop) onDelete;

  const EditLoopBottomUp({
    super.key,
    required this.loop,
    required this.songDuration,
    required this.onDelete,
  });

  @override
  State<EditLoopBottomUp> createState() => _EditLoopBottomUpState();
}

class _EditLoopBottomUpState extends State<EditLoopBottomUp> {
  final TextEditingController _titleController = TextEditingController();

  // Start time controllers
  final TextEditingController _startHoursController = TextEditingController();
  final TextEditingController _startMinutesController = TextEditingController();
  final TextEditingController _startSecondsController = TextEditingController();
  final TextEditingController _startMillisecondsController = TextEditingController();

  // End time controllers
  final TextEditingController _endHoursController = TextEditingController();
  final TextEditingController _endMinutesController = TextEditingController();
  final TextEditingController _endSecondsController = TextEditingController();
  final TextEditingController _endMillisecondsController = TextEditingController();

  String? _startError;
  String? _endError;

  late Loop _updatedLoop;
  bool get _showHours => widget.songDuration.inMinutes > 60;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.loop.name;
    _initializeTimeControllers();
    _updatedLoop = widget.loop;
  }

  void _initializeTimeControllers() {
    // Initialize start time controllers
    if (widget.loop.start != null) {
      _startHoursController.text = widget.loop.start!.inHours.toString();
      _startMinutesController.text = (widget.loop.start!.inMinutes % 60).toString().padLeft(2, '0');
      _startSecondsController.text = (widget.loop.start!.inSeconds % 60).toString().padLeft(2, '0');
      _startMillisecondsController.text = (widget.loop.start!.inMilliseconds % 1000)
          .toString()
          .padLeft(3, '0');
    } else {
      _startHoursController.text = '0';
      _startMinutesController.text = '00';
      _startSecondsController.text = '00';
      _startMillisecondsController.text = '000';
    }

    // Initialize end time controllers
    if (widget.loop.end != null) {
      _endHoursController.text = widget.loop.end!.inHours.toString();
      _endMinutesController.text = (widget.loop.end!.inMinutes % 60).toString().padLeft(2, '0');
      _endSecondsController.text = (widget.loop.end!.inSeconds % 60).toString().padLeft(2, '0');
      _endMillisecondsController.text = (widget.loop.end!.inMilliseconds % 1000).toString().padLeft(
        3,
        '0',
      );
    } else {
      _endHoursController.text = '0';
      _endMinutesController.text = '00';
      _endSecondsController.text = '00';
      _endMillisecondsController.text = '000';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startHoursController.dispose();
    _startMinutesController.dispose();
    _startSecondsController.dispose();
    _startMillisecondsController.dispose();
    _endHoursController.dispose();
    _endMinutesController.dispose();
    _endSecondsController.dispose();
    _endMillisecondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 1.0,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.editLoop,
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
                      decoration: InputDecoration(
                        labelText: context.l10n.loopName,
                        border: const OutlineInputBorder(),
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
                          _updatedLoop = _updatedLoop.copyWith(
                            color: newColor,
                          );
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

              // Start time controls
              Text(
                context.l10n.startTime,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildTimeInputRow(
                hoursController: _startHoursController,
                minutesController: _startMinutesController,
                secondsController: _startSecondsController,
                millisecondsController: _startMillisecondsController,
                errorText: _startError,
                onChanged: () => _validateAndUpdateTimes(context, true, false),
              ),
              const SizedBox(height: 16),

              // End time controls
              Text(
                context.l10n.endTime,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildTimeInputRow(
                hoursController: _endHoursController,
                minutesController: _endMinutesController,
                secondsController: _endSecondsController,
                millisecondsController: _endMillisecondsController,
                errorText: _endError,
                onChanged: () => _validateAndUpdateTimes(context, false, true),
              ),
              const SizedBox(height: 16),

              // Delete button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onDelete(widget.loop);
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                      label: Text(context.l10n.delete),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _updatedLoop),
                      icon: const Icon(Icons.save),
                      label: Text(context.l10n.save),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
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

  Widget _buildTimeInputRow({
    required TextEditingController hoursController,
    required TextEditingController minutesController,
    required TextEditingController secondsController,
    required TextEditingController millisecondsController,
    String? errorText,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_showHours) ...[
              Expanded(
                child: TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.hours,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Text(':', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.minutes,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Text(':', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.seconds,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Text('.', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: millisecondsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.milliseconds,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Duration? _parseTimeInputs({
    required TextEditingController hoursController,
    required TextEditingController minutesController,
    required TextEditingController secondsController,
    required TextEditingController millisecondsController,
  }) {
    try {
      final hours = int.tryParse(hoursController.text) ?? 0;
      final minutes = int.tryParse(minutesController.text) ?? 0;
      final seconds = int.tryParse(secondsController.text) ?? 0;
      final milliseconds = int.tryParse(millisecondsController.text) ?? 0;

      // Validate ranges
      if (minutes >= 60 || seconds >= 60 || milliseconds >= 1000) {
        return null;
      }

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } catch (e) {
      return null;
    }
  }

  void _validateAndUpdateTimes(
    BuildContext context,
    bool isStartTime,
    bool isEndTime,
  ) {
    setState(() {
      _startError = null;
      _endError = null;

      Duration? start;
      Duration? end;

      if (isStartTime) {
        start = _parseTimeInputs(
          hoursController: _startHoursController,
          minutesController: _startMinutesController,
          secondsController: _startSecondsController,
          millisecondsController: _startMillisecondsController,
        );
        if (start == null) {
          _startError = context.l10n.invalidFormat;
          return;
        }
      } else {
        start = widget.loop.start;
      }

      if (isEndTime) {
        end = _parseTimeInputs(
          hoursController: _endHoursController,
          minutesController: _endMinutesController,
          secondsController: _endSecondsController,
          millisecondsController: _endMillisecondsController,
        );
        if (end == null) {
          _endError = context.l10n.invalidFormat;
          return;
        }
      } else {
        end = widget.loop.end;
      }

      if (start != null && end != null) {
        if (start > end) {
          _startError = context.l10n.startCannotBeAfterEnd;
          _endError = context.l10n.endCannotBeBeforeStart;
          return;
        }
      }

      // Update the loop if validation passes
      if (isStartTime || isEndTime) {
        _updatedLoop = _updatedLoop.copyWith(
          start: start ?? widget.loop.start,
          end: end ?? widget.loop.end,
        );
      }
    });
  }
}

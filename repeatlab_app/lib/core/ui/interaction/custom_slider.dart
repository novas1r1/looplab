import 'package:flutter/material.dart';

class CustomSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(double) onChanged;
  final Function(double)? onChangeEnd;

  const CustomSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primaryContainer,
      inactiveColor: Theme.of(context).colorScheme.secondary,
      onChangeEnd: onChangeEnd,
    );
  }
}

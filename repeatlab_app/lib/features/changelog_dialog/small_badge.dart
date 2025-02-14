import 'package:flutter/material.dart';

class SmallBadge extends StatelessWidget {
  final String? text;

  const SmallBadge({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text!,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}

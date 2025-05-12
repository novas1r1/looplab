import 'package:flutter/material.dart';
import 'package:repeatlab/l10n/l10n.dart';

class TutorialItem extends StatelessWidget {
  final String title;
  final String? content;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isLast;

  const TutorialItem({
    required this.title,
    this.content,
    this.onPrevious,
    this.onNext,
    this.isLast = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (content != null) ...[
          const SizedBox(height: 8),
          Text(
            content!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            if (onPrevious != null)
              ElevatedButton(
                onPressed: () => onPrevious?.call(),
                child: const Icon(Icons.chevron_left),
              ),
            const Spacer(),
            if (onNext != null && !isLast)
              ElevatedButton(
                onPressed: () => onNext?.call(),
                child: const Icon(Icons.chevron_right),
              ),
            if (onNext != null && isLast)
              ElevatedButton(
                onPressed: () => onNext?.call(),
                child: Text(context.l10n.finish),
              ),
          ],
        ),
      ],
    );
  }
}

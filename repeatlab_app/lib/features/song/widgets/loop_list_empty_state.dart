import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/l10n/l10n.dart';

class LoopListEmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const LoopListEmptyState({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('song.loops.empty'),
      child: GestureDetector(
        onTap: onTap,
        // Without this the gaps between/around the text lines don't register
        // taps, which makes the whole block feel unreliable to hit.
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.noLoopsCreatedYet,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.tapToCreateFirstLoop,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

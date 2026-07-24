import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';

/// Big centred value with a caption, flanked by − / + step buttons. Shared by
/// the BPM-set speed control and the semitone pitch control, matching the
/// practice-controls design. Passing null for a callback disables that button.
class ControlStepper extends StatelessWidget {
  const ControlStepper({
    super.key,
    required this.value,
    required this.subtitle,
    this.onDecrement,
    this.onIncrement,
    this.decrementKey,
    this.incrementKey,
    this.valueColor,
    this.onValueTap,
  });

  /// The large number shown in the centre, e.g. "120" or "+3".
  final String value;

  /// Caption under the value, e.g. "BPM · 1.00×" or "Semitones · A♯".
  final String subtitle;

  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final Key? decrementKey;
  final Key? incrementKey;

  /// Colour of the big value. Defaults to [AppColors.onSurface].
  final Color? valueColor;

  /// Optional tap on the value/caption block (e.g. to edit the original BPM).
  final VoidCallback? onValueTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          key: decrementKey,
          iconName: 'ic_minus_circle',
          onPressed: onDecrement,
        ),
        Expanded(
          child: GestureDetector(
            onTap: onValueTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: context.displaySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: valueColor ?? AppColors.onSurface,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _StepButton(
          key: incrementKey,
          iconName: 'ic_plus_circle',
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({super.key, required this.iconName, this.onPressed});

  final String iconName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: AppIcon(
          iconName: iconName,
          iconSize: 30,
          containerSize: 30,
          color: onPressed == null ? AppColors.iconDisabled : AppColors.iconDefault,
        ),
      ),
    );
  }
}

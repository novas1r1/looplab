import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:repeatlab/core/ui/app_colors.dart';

/// One segment of a [PillToggle].
class PillSegment {
  const PillSegment({
    required this.label,
    this.key,
    this.minFontSize = 12,
    this.maxFontSize = 20,
  });

  final String label;

  /// Optional key placed on the tappable segment (used by widget tests).
  final Key? key;
  final double minFontSize;
  final double maxFontSize;
}

/// Rounded segmented control matching the practice-controls design: a subtle
/// track with the selected segment filled in the accent colour. Replaces the
/// bordered [ToggleButtons] look used previously.
///
/// When [expand] is true the segments share the available width equally (used
/// for the Tempo/Pitch tab selector); otherwise each segment sizes to its
/// content (used for the ×|BPM and Semitone|Key mode toggles).
class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.expand = false,
    this.height = 36,
  });

  final List<PillSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            if (expand)
              Expanded(child: _segment(i))
            else
              _segment(i),
        ],
      ),
    );
  }

  Widget _segment(int index) {
    final segment = segments[index];
    final isSelected = index == selectedIndex;

    return GestureDetector(
      key: segment.key,
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AutoSizeText(
          segment.label,
          maxLines: 1,
          minFontSize: segment.minFontSize,
          maxFontSize: segment.maxFontSize,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.onPrimaryContainer
                : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

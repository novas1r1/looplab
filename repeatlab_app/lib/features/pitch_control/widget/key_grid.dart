import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';

/// A 4x3 grid of musical keys, one tap per key.
///
/// Presentation only — it holds no cubit and knows nothing about pitch, so it
/// serves both the transposition grid (with offset badges) and the set-song-key
/// picker (without).
///
/// Built from plain rows rather than a [GridView]: a lazy viewport buys nothing
/// for twelve fixed cells, and it cannot report intrinsic dimensions, which
/// breaks the moment the grid is placed inside an [AlertDialog].
class KeyGrid extends StatelessWidget {
  const KeyGrid({
    super.key,
    required this.keys,
    required this.onSelected,
    this.selectedKey,
    this.badgeBuilder,
  });

  /// Canonical keys to show, in grid order. Rendered via
  /// [MusicalKey.conventionalLabel].
  final List<String> keys;

  /// Canonical key to highlight, if any.
  final String? selectedKey;

  /// Small caption under each key (e.g. a signed semitone offset). Return null
  /// for a given key to omit its badge; pass null entirely for a grid with no
  /// badge row at all.
  final String? Function(String key)? badgeBuilder;

  final ValueChanged<String> onSelected;

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      for (var i = 0; i < keys.length; i += _columns)
        keys.sublist(i, (i + _columns).clamp(0, keys.length)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        for (final row in rows)
          Row(
            spacing: 6,
            children: [
              for (final key in row)
                Expanded(
                  child: _KeyGridCell(
                    musicalKey: key,
                    badge: badgeBuilder?.call(key),
                    isSelected: key == selectedKey,
                    onTap: () => onSelected(key),
                  ),
                ),
              // Keep the last row's cells the same width as the rest when the
              // key count is not a multiple of the column count.
              for (var i = row.length; i < _columns; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
      ],
    );
  }
}

class _KeyGridCell extends StatelessWidget {
  const _KeyGridCell({
    required this.musicalKey,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final String musicalKey;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurface;

    return Material(
      color: isSelected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('song.pitch.key.$musicalKey'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: badge == null ? 44 : 52,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MusicalKey.conventionalLabel(musicalKey),
                maxLines: 1,
                style: context.titleMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badge != null)
                Text(
                  badge!,
                  maxLines: 1,
                  style: context.labelSmall.copyWith(
                    color: isSelected
                        ? foreground
                        : AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

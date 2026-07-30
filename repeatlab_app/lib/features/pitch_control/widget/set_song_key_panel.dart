import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/pill_toggle.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/pitch_control/widget/key_grid.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Picks a song's own musical key: a major/minor toggle plus 12 keys.
///
/// Split this way because mode is a property of the song, not of the choice —
/// asking for it separately turns one 24-item list into two small decisions.
///
/// Holds no cubit and performs no writes; it reports the canonical key through
/// [onKeySelected], so it serves both the empty state and the edit dialog.
class SetSongKeyPanel extends StatefulWidget {
  const SetSongKeyPanel({
    super.key,
    required this.onKeySelected,
    this.initialKey,
    this.showIntro = true,
  });

  /// Pre-selected key in canonical form, when editing an existing value.
  final String? initialKey;

  /// Whether to show the explanatory sentence. Off inside the edit dialog,
  /// where the title already says what is being changed.
  final bool showIntro;

  /// Fires with the canonical key ("A#m") whenever the selection changes.
  final ValueChanged<String> onKeySelected;

  @override
  State<SetSongKeyPanel> createState() => _SetSongKeyPanelState();
}

class _SetSongKeyPanelState extends State<SetSongKeyPanel> {
  late bool _isMinor = widget.initialKey?.endsWith('m') ?? false;
  late String? _selectedKey = widget.initialKey == null
      ? null
      : MusicalKey.canonicalize(widget.initialKey!);

  @override
  Widget build(BuildContext context) {
    final keys = MusicalKey.allKeys.sublist(
      _isMinor ? 12 : 0,
      _isMinor ? 24 : 12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (widget.showIntro)
          AutoSizeText(
            context.l10n.setSongKeyIntro,
            minFontSize: 12,
            maxFontSize: 20,
            style: context.labelLarge.copyWith(fontStyle: FontStyle.italic),
          ),
        Row(
          children: [
            Text(
              context.l10n.keyQuality,
              style: context.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            PillToggle(
              key: const Key('song.pitch.keyQuality'),
              selectedIndex: _isMinor ? 1 : 0,
              onChanged: _onChangeQuality,
              segments: [
                PillSegment(
                  label: context.l10n.keyQualityMajor,
                  key: const Key('song.pitch.keyQuality.major'),
                ),
                PillSegment(
                  label: context.l10n.keyQualityMinor,
                  key: const Key('song.pitch.keyQuality.minor'),
                ),
              ],
            ),
          ],
        ),
        KeyGrid(
          keys: keys,
          selectedKey: _selectedKey,
          onSelected: (key) {
            setState(() => _selectedKey = key);
            widget.onKeySelected(key);
          },
        ),
      ],
    );
  }

  void _onChangeQuality(int index) {
    final isMinor = index == 1;
    if (isMinor == _isMinor) return;

    setState(() {
      _isMinor = isMinor;
      // Carry the chosen root across the switch (C -> Cm), so flipping the
      // toggle after picking does not silently drop the selection.
      final selected = _selectedKey;
      if (selected != null) {
        _selectedKey = isMinor
            ? '${selected}m'
            : selected.substring(0, selected.length - 1);
      }
    });

    final selected = _selectedKey;
    if (selected != null) widget.onKeySelected(selected);
  }
}

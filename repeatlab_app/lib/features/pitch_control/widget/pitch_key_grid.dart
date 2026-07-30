import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/pitch_control/widget/key_grid.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// The 12 keys a song can be transposed into, each badged with what that move
/// costs in semitones.
///
/// The badge is the point: a dropdown hides the trade-off, while the grid makes
/// "this record is in E♭, tapping E costs +1 and gives me open chords" a
/// one-glance decision. Pianists especially think in key names, not semitone
/// counts, and cannot retune their instrument at all.
class PitchKeyGrid extends StatefulWidget {
  const PitchKeyGrid({
    super.key,
    required this.originalKey,
    required this.pitchSemitones,
  });

  /// The song's original key, canonical form. Required — the grid is only
  /// meaningful relative to a known reference.
  final String originalKey;

  /// Current transposition, used to highlight the active key and to badge it
  /// with the value actually applied.
  final int pitchSemitones;

  @override
  State<PitchKeyGrid> createState() => _PitchKeyGridState();
}

class _PitchKeyGridState extends State<PitchKeyGrid> {
  bool _paywallShowing = false;

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;
    final keys = MusicalKey.sameModeKeys(widget.originalKey);
    if (keys == null) return const SizedBox.shrink();

    final currentKey =
        MusicalKey.transpose(widget.originalKey, widget.pitchSemitones);

    final grid = KeyGrid(
      keys: keys,
      selectedKey: currentKey,
      badgeBuilder: _badgeFor,
      onSelected: (key) => _onSelect(context, key),
    );

    if (hasPremium) return grid;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _showPremiumDialog(context),
      child: AbsorbPointer(child: grid),
    );
  }

  String? _badgeFor(String key) {
    final canonicalOriginal = MusicalKey.canonicalize(widget.originalKey);
    if (key == canonicalOriginal) return context.l10n.keyOriginalBadge;

    // The selected cell is badged with the offset actually stored on the song,
    // not with a freshly derived one. A song saved at +6 before the tritone
    // tie-break flipped keeps that value, and deriving the badge would then
    // claim −6 while playback still sits at +6.
    final isSelected =
        key == MusicalKey.transpose(widget.originalKey, widget.pitchSemitones);
    final offset = isSelected
        ? widget.pitchSemitones
        : MusicalKey.signedOffset(widget.originalKey, key);
    if (offset == null) return null;

    return offset > 0 ? '+$offset' : '−${-offset}';
  }

  void _onSelect(BuildContext context, String key) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickUpdatePitch,
      data: {
        'semitones': MusicalKey.signedOffset(widget.originalKey, key),
        'source': 'key_mode',
      },
    );
    context.read<SongCubit>().setPitchByTargetKey(key);
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    if (_paywallShowing) return;
    _paywallShowing = true;

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_pitch',
      );
    } finally {
      if (mounted) {
        _paywallShowing = false;
      }
    }
  }
}

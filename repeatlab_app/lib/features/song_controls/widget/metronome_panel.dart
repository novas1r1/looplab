import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Everything the panel needs from [SongState], selected once in [build].
typedef _PanelData = ({
  bool isEnabled,
  double volume,
  MetronomeSubdivision subdivision,
  int? currentBpm,
  int offsetMs,
  int beatsPerBar,
  int beatUnit,
  bool isPlaying,
  bool hasAnchor,
  int tapCount,
  bool isGenerating,
});

/// Metronome section shown at the bottom of the Tempo tab (below a divider).
///
/// Staged by sync state so each control only appears once it can do what it
/// claims (docs/plans/2026-07-23-metronome-track-design.md):
///
/// * Off: a compact row with the on/off switch.
/// * On, not synced: volume plus a single "Sync to song" call to action —
///   the click is a uniform tick because without a beat anchor "beat 1" is
///   unknown and an accent would land on a random beat.
/// * On, synced (anchor set via tap-along): the time signature appears and
///   the downbeat accent turns on, with the power-user controls
///   (subdivision, re-tap, ½-beat, ±ms nudge, reset) behind a gear toggle.
///
/// Clicks only play while the song plays; tempo follows `currentBpm`.
class MetronomePanel extends StatefulWidget {
  const MetronomePanel({super.key});

  @override
  State<MetronomePanel> createState() => _MetronomePanelState();
}

class _MetronomePanelState extends State<MetronomePanel> {
  static const _nudgeStepMs = 25;

  /// Time signatures offered in the dropdown, as beatsPerBar/beatUnit.
  static const _timeSignatures = [
    (2, 4),
    (3, 4),
    (4, 4),
    (5, 4),
    (6, 8),
    (7, 8),
    (12, 8),
  ];

  // Local state for smooth volume slider interaction (same pattern as the
  // speed slider).
  double? _draggedVolume;
  bool _paywallShowing = false;
  bool _advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    return BlocSelector<SongCubit, SongState, _PanelData>(
      selector: (state) => (
        isEnabled: state.isMetronomeEnabled,
        volume: state.metronomeVolume,
        subdivision: state.metronomeSubdivision,
        currentBpm: state.currentBpm,
        offsetMs: state.song.metronomeOffsetMs,
        beatsPerBar: state.song.metronomeBeatsPerBar,
        beatUnit: state.song.metronomeBeatUnit,
        isPlaying: state.playerState == PlayerState.playing,
        hasAnchor: state.song.metronomeBeatAnchorMs != null,
        tapCount: state.metronomeTapCount,
        isGenerating: state.isMetronomeGenerating,
      ),
      builder: (context, data) {
        final hasBpm = data.currentBpm != null && data.currentBpm! > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 24, color: AppColors.outlineVariant),
            _header(context, data, hasBpm: hasBpm),
            if (data.isEnabled && hasBpm) ...[
              const SizedBox(height: 12),
              _volumeRow(context, data),
              if (!data.hasAnchor)
                _syncSection(context, data, hasPremium: hasPremium)
              else ...[
                const SizedBox(height: 8),
                _timeSignatureRow(context, data, hasPremium: hasPremium),
                _advancedSection(context, data, hasPremium: hasPremium),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    _PanelData data, {
    required bool hasBpm,
  }) {
    // Not synced: just the tempo — the click is a plain tick, so showing a
    // time signature here would promise a downbeat that doesn't exist yet.
    final status = data.isEnabled && hasBpm
        ? data.hasAnchor
              ? '${data.currentBpm} BPM · ${data.beatsPerBar}/${data.beatUnit} ✓'
              : '${data.currentBpm} BPM'
        : context.l10n.off;

    return Row(
      children: [
        Text(
          context.l10n.metronome,
          style: context.titleMedium.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status,
            style: context.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        if (data.isGenerating)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                key: Key('song.metronome.generating'),
                strokeWidth: 2,
                color: AppColors.secondaryFixed,
              ),
            ),
          ),
        if (data.isEnabled && hasBpm && data.hasAnchor) ...[
          _advancedButton(context),
          const SizedBox(width: 4),
        ],
        CupertinoSwitch(
          key: const Key('song.metronome.toggle'),
          thumbIcon: WidgetStateProperty.all(
            const Icon(Icons.graphic_eq_rounded),
          ),
          activeTrackColor: AppColors.primaryContainer,
          inactiveTrackColor: AppColors.secondaryContainer,
          value: data.isEnabled && hasBpm,
          onChanged: (_) => _onToggle(context, hasBpm: hasBpm),
        ),
      ],
    );
  }

  /// Gear toggle for the advanced controls, shown beside the on/off switch
  /// once the song is synced (the advanced tools all refine an existing
  /// alignment, so they stay hidden before that).
  Widget _advancedButton(BuildContext context) {
    return IconButton(
      key: const Key('song.metronome.advancedToggle'),
      visualDensity: VisualDensity.compact,
      onPressed: () => setState(() => _advancedExpanded = !_advancedExpanded),
      icon: Icon(
        _advancedExpanded ? Icons.settings_rounded : Icons.settings_outlined,
        size: 20,
        color: _advancedExpanded ? AppColors.primary : AppColors.secondaryFixed,
      ),
      tooltip: context.l10n.metronomeAdvanced,
    );
  }

  /// The single next step while unsynced: a "Sync to song" button with one
  /// line explaining why the click may be off the beat and how to fix it.
  /// Pressing it while paused starts playback (you tap along to what you
  /// hear); while playing every press records a tap of the alignment
  /// capture.
  Widget _syncSection(
    BuildContext context,
    _PanelData data, {
    required bool hasPremium,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _premiumGate(
          hasPremium: hasPremium,
          child: OutlinedButton.icon(
            key: const Key('song.metronome.syncToSong'),
            onPressed: () => _onSyncPressed(context, data),
            icon: const Icon(Icons.touch_app_rounded, size: 18),
            label: Text(
              data.tapCount > 0
                  ? context.l10n.metronomeKeepTapping(data.tapCount)
                  : context.l10n.metronomeSyncToSong,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.metronomeSyncHint,
          style: context.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _timeSignatureRow(
    BuildContext context,
    _PanelData data, {
    required bool hasPremium,
  }) {
    return Row(
      children: [
        Text(
          context.l10n.metronomeTimeSignature,
          style: context.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const Spacer(),
        _premiumGate(
          hasPremium: hasPremium,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<(int, int)>(
                key: const Key('song.metronome.timeSignature'),
                value:
                    _timeSignatures.contains(
                      (data.beatsPerBar, data.beatUnit),
                    )
                    ? (data.beatsPerBar, data.beatUnit)
                    : (4, 4),
                dropdownColor: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.secondaryFixed,
                ),
                style: context.labelLarge.copyWith(
                  color: AppColors.secondaryFixed,
                ),
                items: [
                  for (final (beats, unit) in _timeSignatures)
                    DropdownMenuItem(
                      value: (beats, unit),
                      child: Text('$beats/$unit'),
                    ),
                ],
                onChanged: (value) => _onTimeSignature(context, value),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _volumeRow(BuildContext context, _PanelData data) {
    final volume = _draggedVolume ?? data.volume;

    return Row(
      children: [
        const Icon(
          Icons.volume_up_rounded,
          size: 20,
          color: AppColors.secondaryFixed,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${(volume * 100).round()}',
            style: context.labelLarge.copyWith(color: AppColors.onSurface),
          ),
        ),
        Expanded(
          child: CustomSlider(
            value: volume,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) {
              setState(() => _draggedVolume = value);
              context.read<SongCubit>().setMetronomeVolume(value);
            },
            onChangeEnd: (value) {
              setState(() => _draggedVolume = null);
              context.read<SongCubit>().setMetronomeVolume(
                value,
                persist: true,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Gear-toggled "advanced" block, only reachable once synced: subdivision,
  /// re-tap + half-beat, the ±ms nudge (all premium-gated) and a reset back
  /// to the plain unsynced click.
  Widget _advancedSection(
    BuildContext context,
    _PanelData data, {
    required bool hasPremium,
  }) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 180),
      crossFadeState: _advancedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Column(
        spacing: 8,
        children: [
          const SizedBox(height: 4),
          _subdivisionRow(context, data, hasPremium: hasPremium),
          _alignmentRow(context, data, hasPremium: hasPremium),
          _nudgeRow(context, data, hasPremium: hasPremium),
          _resetSyncRow(context),
        ],
      ),
    );
  }

  Widget _subdivisionRow(
    BuildContext context,
    _PanelData data, {
    required bool hasPremium,
  }) {
    return Row(
      children: [
        Text(
          context.l10n.metronomeSubdivision,
          style: context.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const Spacer(),
        _premiumGate(
          hasPremium: hasPremium,
          child: SizedBox(
            height: 36,
            child: ToggleButtons(
              key: const Key('song.metronome.subdivision'),
              borderRadius: BorderRadius.circular(10),
              selectedColor: AppColors.onPrimaryContainer,
              color: AppColors.secondary,
              fillColor: AppColors.primaryContainer,
              disabledColor: AppColors.secondary,
              isSelected: [
                for (final s in MetronomeSubdivision.values) s == data.subdivision,
              ],
              onPressed: (index) => _onSubdivision(
                context,
                MetronomeSubdivision.values[index],
              ),
              children: const [
                Text('♩', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('♪', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('³', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('♬', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _alignmentRow(
    BuildContext context,
    _PanelData data, {
    required bool hasPremium,
  }) {
    return _premiumGate(
      hasPremium: hasPremium,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('song.metronome.tapBeat'),
              onPressed: data.isPlaying ? () => _onTapBeat(context, data.tapCount) : null,
              icon: Icon(
                data.hasAnchor && data.tapCount == 0
                    ? Icons.check_circle_outline_rounded
                    : Icons.touch_app_rounded,
                size: 18,
              ),
              label: Text(
                data.tapCount > 0
                    ? '${context.l10n.metronomeTapBeat} (${data.tapCount})'
                    : context.l10n.metronomeTapBeat,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nudgeRow(
    BuildContext context,
    _PanelData data, {
    required bool hasPremium,
  }) {
    return _premiumGate(
      hasPremium: hasPremium,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.metronomeNudge,
            style: context.labelLarge.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('song.metronome.nudgeEarlier'),
            onPressed: () => _onNudge(context, -_nudgeStepMs),
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.secondaryFixed,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              context.l10n.metronomeOffsetMs(data.offsetMs),
              textAlign: TextAlign.center,
              style: context.labelLarge.copyWith(
                color: AppColors.secondaryFixed,
              ),
            ),
          ),
          IconButton(
            key: const Key('song.metronome.nudgeLater'),
            onPressed: () => _onNudge(context, _nudgeStepMs),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.secondaryFixed,
            ),
          ),
        ],
      ),
    );
  }

  /// Escape hatch back to the plain unsynced click. Not premium-gated —
  /// clearing an alignment must always be possible.
  Widget _resetSyncRow(BuildContext context) {
    return TextButton.icon(
      key: const Key('song.metronome.resetSync'),
      onPressed: () => _onResetSync(context),
      icon: const Icon(
        Icons.restart_alt_rounded,
        size: 18,
        color: AppColors.secondary,
      ),
      label: Text(
        context.l10n.metronomeResetSync,
        style: context.labelLarge.copyWith(color: AppColors.secondary),
      ),
    );
  }

  /// Free users see the control but any touch opens the paywall — the same
  /// Listener+AbsorbPointer pattern as the speed/pitch controls.
  Widget _premiumGate({required bool hasPremium, required Widget child}) {
    if (hasPremium) return child;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _showPremiumDialog(context),
      child: AbsorbPointer(child: child),
    );
  }

  void _onToggle(BuildContext context, {required bool hasBpm}) {
    // The metronome needs a tempo to click against; guide the user to set the
    // song's BPM first instead of silently doing nothing.
    if (!hasBpm) {
      _showSetBpmDialog(context);
      return;
    }
    AppAnalytics.trackEvent(AppAnalytics.clickMetronomeToggle);
    context.read<SongCubit>().toggleMetronome();
  }

  Future<void> _showSetBpmDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('song.metronome.setBpmDialog'),
        backgroundColor: AppColors.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              dialogContext,
            ).colorScheme.outlineVariant.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        title: Text(dialogContext.l10n.metronome),
        content: Text(dialogContext.l10n.metronomeSetBpmFirst),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.close),
          ),
        ],
      ),
    );
  }

  void _onSyncPressed(BuildContext context, _PanelData data) {
    // Taps only make sense against audible playback: the first press on a
    // paused song starts it, then every press is a tap of the capture.
    if (!data.isPlaying) {
      AppAnalytics.trackEvent(AppAnalytics.clickMetronomeSyncToSong);
      context.read<SongCubit>().togglePlaySong();
      return;
    }
    _onTapBeat(context, data.tapCount);
  }

  void _onTimeSignature(BuildContext context, (int, int)? value) {
    if (value == null) return;
    AppAnalytics.trackEvent(
      AppAnalytics.clickMetronomeTimeSignature,
      data: {'time_signature': '${value.$1}/${value.$2}'},
    );
    context.read<SongCubit>().setMetronomeTimeSignature(value.$1, value.$2);
  }

  void _onSubdivision(BuildContext context, MetronomeSubdivision subdivision) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickMetronomeSubdivision,
      data: {'subdivision': subdivision.name},
    );
    context.read<SongCubit>().setMetronomeSubdivision(subdivision);
  }

  void _onTapBeat(BuildContext context, int tapCount) {
    // Track only the first tap of a capture, not every beat tapped.
    if (tapCount == 0) {
      AppAnalytics.trackEvent(AppAnalytics.clickMetronomeTapBeat);
    }
    context.read<SongCubit>().tapMetronomeBeat();
  }

  void _onHalfBeat(BuildContext context) {
    AppAnalytics.trackEvent(AppAnalytics.clickMetronomeHalfBeat);
    context.read<SongCubit>().flipMetronomeHalfBeat();
  }

  void _onNudge(BuildContext context, int deltaMs) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickMetronomeNudge,
      data: {'delta_ms': deltaMs},
    );
    context.read<SongCubit>().nudgeMetronome(deltaMs);
  }

  void _onResetSync(BuildContext context) {
    AppAnalytics.trackEvent(AppAnalytics.clickMetronomeResetSync);
    // Collapse the gear section — everything in it needs an anchor, and the
    // panel returns to the sync call to action.
    setState(() => _advancedExpanded = false);
    context.read<SongCubit>().resetMetronomeOffset();
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    if (_paywallShowing) return;
    _paywallShowing = true;

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_metronome',
      );
    } finally {
      if (mounted) {
        _paywallShowing = false;
      }
    }
  }
}

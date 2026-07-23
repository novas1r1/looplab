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

/// Metronome section shown at the bottom of the Tempo tab (below a divider).
///
/// Off: a compact row with a button that enables + expands it. On: current
/// tempo, beat indicator, time signature and volume, with the power-user
/// controls (subdivision, tap-align, ±ms nudge) tucked behind a gear toggle.
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

    return BlocSelector<
      SongCubit,
      SongState,
      ({
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
      })
    >(
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
              _timeSignatureRow(context, data),
              const SizedBox(height: 8),
              _volumeRow(context, data),
              _advancedSection(context, data, hasPremium: hasPremium),
            ],
          ],
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    ({
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
    }) data, {
    required bool hasBpm,
  }) {
    final status = data.isEnabled && hasBpm
        ? '${data.currentBpm} BPM · ${data.beatsPerBar}/${data.beatUnit}'
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
        if (data.isEnabled && hasBpm)
          CupertinoSwitch(
            key: const Key('song.metronome.toggle'),
            value: data.isEnabled,
            activeTrackColor: AppColors.primaryContainer,
            onChanged: (_) => _onToggle(context),
          )
        else
          _enableButton(context, enabled: hasBpm),
      ],
    );
  }

  /// Compact "turn on" affordance shown when the metronome is off. Disabled
  /// until a BPM exists (the BPM entry sits directly above in the same tab).
  Widget _enableButton(BuildContext context, {required bool enabled}) {
    return Material(
      color: enabled
          ? AppColors.surfaceContainerHigh
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: const Key('song.metronome.toggle'),
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? () => _onToggle(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(
            Icons.graphic_eq_rounded,
            size: 18,
            color: enabled ? AppColors.secondaryFixed : AppColors.outline,
          ),
        ),
      ),
    );
  }

  Widget _timeSignatureRow(
    BuildContext context,
    ({
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
    }) data,
  ) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

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
                value: _timeSignatures.contains(
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

  Widget _volumeRow(
    BuildContext context,
    ({
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
    }) data,
  ) {
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

  /// Gear-toggled "advanced" block: subdivision, tap-align + half-beat, and the
  /// ±ms nudge — all premium-gated, all hidden by default so the section
  /// matches the design at a glance.
  Widget _advancedSection(
    BuildContext context,
    ({
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
    }) data, {
    required bool hasPremium,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: const Key('song.metronome.advancedToggle'),
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                setState(() => _advancedExpanded = !_advancedExpanded),
            icon: Icon(
              _advancedExpanded
                  ? Icons.settings_rounded
                  : Icons.settings_outlined,
              size: 20,
              color: _advancedExpanded
                  ? AppColors.primary
                  : AppColors.secondaryFixed,
            ),
            tooltip: context.l10n.metronomeAdvanced,
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _advancedExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            spacing: 8,
            children: [
              _subdivisionRow(context, data, hasPremium: hasPremium),
              _alignmentRow(context, data, hasPremium: hasPremium),
              _nudgeRow(context, data, hasPremium: hasPremium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subdivisionRow(
    BuildContext context,
    ({
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
    }) data, {
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
                for (final s in MetronomeSubdivision.values)
                  s == data.subdivision,
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
    ({
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
    }) data, {
    required bool hasPremium,
  }) {
    return _premiumGate(
      hasPremium: hasPremium,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('song.metronome.tapBeat'),
              onPressed: data.isPlaying
                  ? () => _onTapBeat(context, data.tapCount)
                  : null,
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
          const SizedBox(width: 8),
          Tooltip(
            message: context.l10n.metronomeShiftHalfBeat,
            child: OutlinedButton(
              key: const Key('song.metronome.halfBeat'),
              onPressed: () => _onHalfBeat(context),
              child: const Text('½'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nudgeRow(
    BuildContext context,
    ({
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
    }) data, {
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

  void _onToggle(BuildContext context) {
    AppAnalytics.trackEvent(AppAnalytics.clickMetronomeToggle);
    context.read<SongCubit>().toggleMetronome();
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

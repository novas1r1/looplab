import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Everything the panel needs from [SongState], selected once in
/// [_MetronomePanelState.build].
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
});

/// Note icon for a subdivision, used both in the header indicator and the
/// advanced picker.
String _subdivisionIcon(MetronomeSubdivision subdivision) {
  return switch (subdivision) {
    MetronomeSubdivision.none => 'ic_note_quarter',
    MetronomeSubdivision.eighths => 'ic_note_eighth',
    MetronomeSubdivision.triplets => 'ic_note_triplet',
    MetronomeSubdivision.sixteenths => 'ic_note_sixteenth',
  };
}

/// Records a tap of the beat-alignment capture, shared by the sync call to
/// action and the advanced re-tap button.
void _tapBeat(BuildContext context, int tapCount) {
  // Track only the first tap of a capture, not every beat tapped.
  if (tapCount == 0) {
    AppAnalytics.trackEvent(AppAnalytics.clickMetronomeTapBeat);
  }
  context.read<SongCubit>().tapMetronomeBeat();
}

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
      ),
      builder: (context, data) {
        final hasBpm = data.currentBpm != null && data.currentBpm! > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 16, color: AppColors.outlineVariant),
            _Header(
              data: data,
              hasBpm: hasBpm,
              advancedExpanded: _advancedExpanded,
              onAdvancedToggle: () => setState(() => _advancedExpanded = !_advancedExpanded),
            ),
            if (data.isEnabled && hasBpm) ...[
              if (!data.hasAnchor)
                _SyncSection(
                  data: data,
                  hasPremium: hasPremium,
                  onShowPaywall: _showPremiumDialog,
                )
              else ...[
                const SizedBox(height: 8),
                _AdvancedSection(
                  data: data,
                  hasPremium: hasPremium,
                  expanded: _advancedExpanded,
                  onShowPaywall: _showPremiumDialog,
                  onResetSync: _onResetSync,
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  void _onResetSync() {
    AppAnalytics.trackEvent(AppAnalytics.clickMetronomeResetSync);
    // Collapse the gear section — everything in it needs an anchor, and the
    // panel returns to the sync call to action.
    setState(() => _advancedExpanded = false);
    context.read<SongCubit>().resetMetronomeOffset();
  }

  Future<void> _showPremiumDialog() async {
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

/// Title row: name, status (tempo, time signature, subdivision), gear toggle
/// and the on/off switch.
class _Header extends StatelessWidget {
  const _Header({
    required this.data,
    required this.hasBpm,
    required this.advancedExpanded,
    required this.onAdvancedToggle,
  });

  final _PanelData data;
  final bool hasBpm;
  final bool advancedExpanded;
  final VoidCallback onAdvancedToggle;

  @override
  Widget build(BuildContext context) {
    // Not synced: just the tempo — the click is a plain tick, so showing a
    // time signature here would promise a downbeat that doesn't exist yet.
    final isSynced = data.isEnabled && hasBpm && data.hasAnchor;
    final status = data.isEnabled && hasBpm
        ? isSynced
              ? '${data.currentBpm} BPM · ${data.beatsPerBar}/${data.beatUnit} ·'
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
          child: Row(
            children: [
              Flexible(
                child: Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: context.labelMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              // Subdivision is picked behind the gear toggle, so surface the
              // active one here — otherwise a non-quarter click pattern has
              // no visible cause while the advanced section is collapsed.
              if (isSynced) ...[
                const SizedBox(width: 4),
                AppIcon(
                  key: const Key('song.metronome.subdivisionIndicator'),
                  iconName: _subdivisionIcon(data.subdivision),
                  containerSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        if (isSynced) ...[
          _AdvancedButton(
            expanded: advancedExpanded,
            onPressed: onAdvancedToggle,
          ),
          const SizedBox(width: 4),
        ],
        CupertinoSwitch(
          key: const Key('song.metronome.toggle'),
          thumbIcon: WidgetStateProperty.all(
            const Icon(Icons.graphic_eq_rounded),
          ),
          activeTrackColor: AppColors.primaryContainer,
          inactiveTrackColor: AppColors.onSecondaryFixed,
          value: data.isEnabled && hasBpm,
          onChanged: (_) => _onToggle(context),
        ),
      ],
    );
  }

  void _onToggle(BuildContext context) {
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
}

/// Gear toggle for the advanced controls, shown beside the on/off switch
/// once the song is synced (the advanced tools all refine an existing
/// alignment, so they stay hidden before that).
class _AdvancedButton extends StatelessWidget {
  const _AdvancedButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('song.metronome.advancedToggle'),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: AppIcon(
        iconName: 'ic_settings',
        iconSize: 20,
        containerSize: 24,
        color: expanded ? AppColors.iconActive : AppColors.iconDefault,
      ),
      tooltip: context.l10n.metronomeAdvanced,
    );
  }
}

/// Volume slider. Stateful only for the drag-in-progress value, so slider
/// interaction stays smooth without rebuilding the whole panel (same pattern
/// as the speed slider).
class _VolumeRow extends StatefulWidget {
  const _VolumeRow({required this.volume});

  final double volume;

  @override
  State<_VolumeRow> createState() => _VolumeRowState();
}

class _VolumeRowState extends State<_VolumeRow> {
  double? _draggedVolume;

  @override
  Widget build(BuildContext context) {
    final volume = _draggedVolume ?? widget.volume;

    return Row(
      children: [
        const AppIcon(
          iconName: 'ic_sound',
          iconSize: 20,
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
}

/// The single next step while unsynced: a "Sync to song" button with one
/// line explaining why the click may be off the beat and how to fix it.
/// Pressing it while paused starts playback (you tap along to what you
/// hear); while playing every press records a tap of the alignment
/// capture.
class _SyncSection extends StatelessWidget {
  const _SyncSection({
    required this.data,
    required this.hasPremium,
    required this.onShowPaywall,
  });

  final _PanelData data;
  final bool hasPremium;
  final VoidCallback onShowPaywall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _PremiumGate(
          hasPremium: hasPremium,
          onLockedTap: onShowPaywall,
          child: OutlinedButton.icon(
            key: const Key('song.metronome.syncToSong'),
            onPressed: () => _onSyncPressed(context),
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

  void _onSyncPressed(BuildContext context) {
    // Taps only make sense against audible playback: the first press on a
    // paused song starts it, then every press is a tap of the capture.
    if (!data.isPlaying) {
      AppAnalytics.trackEvent(AppAnalytics.clickMetronomeSyncToSong);
      context.read<SongCubit>().togglePlaySong();
      return;
    }
    _tapBeat(context, data.tapCount);
  }
}

/// Label + dropdown for the song's time signature.
class _TimeSignatureRow extends StatelessWidget {
  const _TimeSignatureRow({
    required this.data,
    required this.hasPremium,
    required this.onShowPaywall,
  });

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

  final _PanelData data;
  final bool hasPremium;
  final VoidCallback onShowPaywall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.l10n.metronomeTimeSignature,
          style: context.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const Spacer(),
        _PremiumGate(
          hasPremium: hasPremium,
          onLockedTap: onShowPaywall,
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
                  color: AppColors.iconDefault,
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

  void _onTimeSignature(BuildContext context, (int, int)? value) {
    if (value == null) return;
    AppAnalytics.trackEvent(
      AppAnalytics.clickMetronomeTimeSignature,
      data: {'time_signature': '${value.$1}/${value.$2}'},
    );
    context.read<SongCubit>().setMetronomeTimeSignature(value.$1, value.$2);
  }
}

/// Gear-toggled "advanced" block, only reachable once synced: subdivision,
/// re-tap + half-beat, the ±ms nudge (all premium-gated) and a reset back
/// to the plain unsynced click.
class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.data,
    required this.hasPremium,
    required this.expanded,
    required this.onShowPaywall,
    required this.onResetSync,
  });

  final _PanelData data;
  final bool hasPremium;
  final bool expanded;
  final VoidCallback onShowPaywall;
  final VoidCallback onResetSync;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 180),
      crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Column(
        spacing: 8,
        children: [
          _TimeSignatureRow(
            data: data,
            hasPremium: hasPremium,
            onShowPaywall: onShowPaywall,
          ),
          _SubdivisionRow(
            data: data,
            hasPremium: hasPremium,
            onShowPaywall: onShowPaywall,
          ),
          _AlignmentRow(
            data: data,
            hasPremium: hasPremium,
            onShowPaywall: onShowPaywall,
          ),
          _VolumeRow(volume: data.volume),
          _NudgeRow(
            data: data,
            hasPremium: hasPremium,
            onShowPaywall: onShowPaywall,
            onResetSync: onResetSync,
          ),
        ],
      ),
    );
  }
}

/// Label + note-icon toggle buttons picking the click subdivision.
class _SubdivisionRow extends StatelessWidget {
  const _SubdivisionRow({
    required this.data,
    required this.hasPremium,
    required this.onShowPaywall,
  });

  final _PanelData data;
  final bool hasPremium;
  final VoidCallback onShowPaywall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.l10n.metronomeSubdivision,
          style: context.labelLarge.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const Spacer(),
        _PremiumGate(
          hasPremium: hasPremium,
          onLockedTap: onShowPaywall,
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
              children: [
                // ToggleButtons' selectedColor only reaches real Icons via
                // IconTheme; the SVG-based AppIcon needs its tint set
                // explicitly.
                for (final s in MetronomeSubdivision.values)
                  AppIcon(
                    iconName: _subdivisionIcon(s),
                    iconSize: 24,
                    containerSize: 24,
                    color: s == data.subdivision
                        ? AppColors.onPrimaryContainer
                        : AppColors.iconDefault,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onSubdivision(BuildContext context, MetronomeSubdivision subdivision) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickMetronomeSubdivision,
      data: {'subdivision': subdivision.name},
    );
    context.read<SongCubit>().setMetronomeSubdivision(subdivision);
  }
}

/// Re-tap button to redo the beat-alignment capture, enabled while playing.
class _AlignmentRow extends StatelessWidget {
  const _AlignmentRow({
    required this.data,
    required this.hasPremium,
    required this.onShowPaywall,
  });

  final _PanelData data;
  final bool hasPremium;
  final VoidCallback onShowPaywall;

  @override
  Widget build(BuildContext context) {
    return _PremiumGate(
      hasPremium: hasPremium,
      onLockedTap: onShowPaywall,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('song.metronome.tapBeat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: BorderSide(
                  color: data.isPlaying ? AppColors.primaryContainer : AppColors.iconDisabled,
                ),
              ),
              onPressed: data.isPlaying ? () => _tapBeat(context, data.tapCount) : null,
              icon: AppIcon(
                iconName: 'ic_touch',
                iconSize: 18,
                color: data.isPlaying ? AppColors.primaryContainer : AppColors.iconDisabled,
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
}

/// ±ms offset nudge plus the reset-sync escape hatch.
class _NudgeRow extends StatelessWidget {
  const _NudgeRow({
    required this.data,
    required this.hasPremium,
    required this.onShowPaywall,
    required this.onResetSync,
  });

  static const _nudgeStepMs = 25;

  final _PanelData data;
  final bool hasPremium;
  final VoidCallback onShowPaywall;
  final VoidCallback onResetSync;

  @override
  Widget build(BuildContext context) {
    // The reset link sits outside the premium gate — clearing an alignment
    // must always be possible.
    return Row(
      children: [
        _PremiumGate(
          hasPremium: hasPremium,
          onLockedTap: onShowPaywall,
          child: Row(
            children: [
              Text(
                context.l10n.metronomeNudge,
                style: context.labelLarge.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('song.metronome.nudgeEarlier'),
                onPressed: () => _onNudge(context, -_nudgeStepMs),
                icon: const AppIcon(
                  iconName: 'ic_minus_circle',
                  iconSize: 18,
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
                icon: const AppIcon(
                  iconName: 'ic_plus_circle',
                  iconSize: 18,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _ResetSyncButton(onTap: onResetSync),
      ],
    );
  }

  void _onNudge(BuildContext context, int deltaMs) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickMetronomeNudge,
      data: {'delta_ms': deltaMs},
    );
    context.read<SongCubit>().nudgeMetronome(deltaMs);
  }
}

/// Escape hatch back to the plain unsynced click, styled like the song BPM
/// "Edit" text link.
class _ResetSyncButton extends StatelessWidget {
  const _ResetSyncButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('song.metronome.resetSync'),
      onTap: onTap,
      child: Text(
        context.l10n.metronomeResetSync,
        style: context.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

/// Free users see the control but any touch opens the paywall — the same
/// Listener+AbsorbPointer pattern as the speed/pitch controls.
class _PremiumGate extends StatelessWidget {
  const _PremiumGate({
    required this.hasPremium,
    required this.onLockedTap,
    required this.child,
  });

  final bool hasPremium;
  final VoidCallback onLockedTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (hasPremium) return child;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onLockedTap(),
      child: AbsorbPointer(child: child),
    );
  }
}

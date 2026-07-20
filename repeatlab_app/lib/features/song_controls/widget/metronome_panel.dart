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

/// Metronome tab of the SongControlsCard.
///
/// Free: on/off toggle + volume. Premium: time signature, subdivision and
/// the ±ms nudge that aligns the click grid with the song. Clicks only play
/// while the song plays; tempo follows `currentBpm` (originalBpm × speed).
/// When no BPM is set the panel shows a prompt that jumps to the Speed tab's
/// BPM mode instead of the controls.
class MetronomePanel extends StatefulWidget {
  /// Switches the parent card to the Speed tab (used by the "set BPM first"
  /// prompt so the user lands directly on the BPM entry UI).
  final VoidCallback onRequestSpeedTab;

  const MetronomePanel({super.key, required this.onRequestSpeedTab});

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
      ),
      builder: (context, data) {
        if (data.currentBpm == null) {
          return _buildSetBpmPrompt(context);
        }

        return Column(
          spacing: 8,
          children: [
            // On/off + current BPM
            Row(
              children: [
                CupertinoSwitch(
                  key: const Key('song.metronome.toggle'),
                  value: data.isEnabled,
                  activeTrackColor: AppColors.primaryContainer,
                  onChanged: (_) => _onToggle(context),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${data.currentBpm} BPM',
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            // Volume
            Row(
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.secondaryFixed,
                ),
                Expanded(
                  child: CustomSlider(
                    value: _draggedVolume ?? data.volume,
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
            ),
            // Premium extras: time signature + subdivision, nudge
            _premiumGate(
              hasPremium: hasPremium,
              child: Row(
                children: [
                  DropdownButton<(int, int)>(
                    key: const Key('song.metronome.timeSignature'),
                    value: _timeSignatures.contains(
                      (data.beatsPerBar, data.beatUnit),
                    )
                        ? (data.beatsPerBar, data.beatUnit)
                        : (4, 4),
                    dropdownColor: AppColors.secondaryContainer,
                    style: context.labelLarge.copyWith(
                      color: AppColors.secondaryFixed,
                    ),
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final (beats, unit) in _timeSignatures)
                        DropdownMenuItem(
                          value: (beats, unit),
                          child: Text('$beats/$unit'),
                        ),
                    ],
                    onChanged: (value) => _onTimeSignature(context, value),
                  ),
                  const Spacer(),
                  SizedBox(
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
                ],
              ),
            ),
            _premiumGate(
              hasPremium: hasPremium,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.metronomeNudge,
                    style: context.labelLarge.copyWith(
                      color: AppColors.secondary,
                    ),
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildSetBpmPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8).copyWith(left: 0),
      child: Column(
        spacing: 8,
        children: [
          Text(
            context.l10n.metronomeSetBpmFirst,
            style: context.labelLarge.copyWith(color: AppColors.secondary),
          ),
          OutlinedButton(
            key: const Key('song.metronome.goToBpm'),
            onPressed: () {
              context.read<SongCubit>().setTempoMode(TempoMode.bpm);
              widget.onRequestSpeedTab();
            },
            child: Text(context.l10n.metronomeGoToBpm),
          ),
        ],
      ),
    );
  }

  /// Free users see the control but any touch opens the paywall — the same
  /// Listener+AbsorbPointer pattern as the speed/pitch sliders.
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

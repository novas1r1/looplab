import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/speed_control/cubit/speed_control_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

class SpeedControlBpmMode extends StatefulWidget {
  final void Function(int?) onOriginalBpmChanged;
  final void Function(int?) onSpeedBpmChanged;

  const SpeedControlBpmMode({
    required this.onOriginalBpmChanged,
    required this.onSpeedBpmChanged,
  });

  @override
  State<SpeedControlBpmMode> createState() => _SpeedControlBpmModeState();
}

class _SpeedControlBpmModeState extends State<SpeedControlBpmMode> {
  final _originalBpmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    final originalBpm = context.watch<SpeedControlCubit>().state.originalBpm;
    final currentBpm = context.watch<SpeedControlCubit>().state.currentBpm;
    final minBpm = context.watch<SpeedControlCubit>().state.minBpm;
    final maxBpm = context.watch<SpeedControlCubit>().state.maxBpm;

    // if original bpm is not set, show a button to set it
    if (originalBpm == null) {
      return Padding(
        padding: const EdgeInsets.all(16).copyWith(top: 0),
        child: Column(
          spacing: 8,
          children: [
            Text(
              context.l10n.hereYouCanSetTheOriginalBpmOfTheAudioFile,
              style: context.labelLarge.copyWith(fontStyle: FontStyle.italic),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _originalBpmController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: context.l10n.enterSongBpm,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<SpeedControlCubit>().setOriginalBpm(
                      int.tryParse(_originalBpmController.text),
                    );
                    widget.onOriginalBpmChanged(int.tryParse(_originalBpmController.text));
                  },
                  child: Text(context.l10n.setBpm),
                ),
                TextButton(
                  onPressed: _showTapBpmDialog,
                  child: Text(context.l10n.tapBpm),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  // TODO
                  // setState(() {
                  //   _originalBpmController.text = _originalBpm?.toString() ?? '';
                  //   _originalBpm = null;
                  // });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.originalBpm,
                        style: context.bodySmall.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        originalBpm.toString(),
                        style: context.titleMedium.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.currentBpm,
                      style: context.bodySmall.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      currentBpm.toString(),
                      style: context.titleMedium.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (minBpm != null && maxBpm != null && currentBpm != null)
            Row(
              children: [
                // min bpm
                Text(minBpm.toString(), style: context.labelLarge),
                // slider
                Expanded(
                  child: CustomSlider(
                    value: currentBpm.toDouble(),
                    min: minBpm.toDouble(),
                    max: maxBpm.toDouble(),
                    divisions: maxBpm - minBpm,
                    onChanged: (value) {
                      // check if premium user, if not, show a dialog to upgrade
                      if (!hasPremium) {
                        _showPremiumDialog(context);
                        return;
                      } else {
                        context.read<SpeedControlCubit>().setCurrentBpm(value.round());
                        widget.onSpeedBpmChanged(value.round());
                      }
                    },
                  ),
                ),
                // max bpm
                Text(maxBpm.toString(), style: context.labelLarge),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    AppAnalytics.trackEvent(
      AppAnalytics.viewPremiumScreen,
      data: {
        'from': 'speed_control_bpm',
      },
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }

  Future<void> _showTapBpmDialog() async {
    final cubit = context.read<SpeedControlCubit>();

    await showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: BpmTapDialog(
          onOriginalBpmChanged: widget.onOriginalBpmChanged,
        ),
      ),
    );
  }
}

class BpmTapDialog extends StatefulWidget {
  final void Function(int?) onOriginalBpmChanged;

  const BpmTapDialog({
    required this.onOriginalBpmChanged,
  });

  @override
  BpmTapDialogState createState() => BpmTapDialogState();
}

class BpmTapDialogState extends State<BpmTapDialog> {
  final List<DateTime> _tapTimes = [];
  int? _calculatedBpm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tapBpm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.tapTheButtonBelowInRhythmWithYourMusicToDetectTheBpm,
          ),
          const SizedBox(height: 24),
          if (_calculatedBpm != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.detectedBpm,
                    style: context.labelMedium.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_calculatedBpm',
                    style: context.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.l10n.tapAtLeast2TimesToDetectBpm,
                style: context.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed: () {
                _tapTimes.add(DateTime.now());
                _calculateBpmFromTaps();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: const CircleBorder(),
                elevation: 4,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tap,
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${context.l10n.taps}: ${_tapTimes.length}',
            style: context.bodySmall,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            _resetTapBpm();
            Navigator.of(context).pop();
          },
          child: Text(context.l10n.cancel),
        ),
        PrimaryButton(
          text: context.l10n.useBpm,
          onPressed: _calculatedBpm != null
              ? () {
                  // Update the text field with the calculated BPM
                  context.read<SpeedControlCubit>().setOriginalBpm(_calculatedBpm);
                  widget.onOriginalBpmChanged(_calculatedBpm);

                  AppAnalytics.trackEvent(
                    AppAnalytics.clickUseTappedBpm,
                    data: {'bpm': _calculatedBpm},
                  );

                  Navigator.of(context).pop();
                }
              : null,
        ),
      ],
    );
  }

  void _calculateBpmFromTaps() {
    if (_tapTimes.length < 2) return;

    // Keep only the last 8 taps for more accurate measurement
    if (_tapTimes.length > 8) {
      _tapTimes.removeAt(0);
    }

    // Calculate intervals between consecutive taps
    final intervals = <int>[];
    for (int i = 1; i < _tapTimes.length; i++) {
      final interval = _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      intervals.add(interval);
    }

    if (intervals.isEmpty) return;

    // Calculate average interval
    final averageInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Convert to BPM: 60000ms per minute / average interval in ms
    final bpm = (60000 / averageInterval).round();

    // Only accept reasonable BPM values (40-200)
    if (bpm >= 40 && bpm <= 200) {
      setState(() {
        _calculatedBpm = bpm;
      });
    }
  }

  void _resetTapBpm() {
    setState(() {
      _tapTimes.clear();
      _calculatedBpm = null;
    });
  }
}

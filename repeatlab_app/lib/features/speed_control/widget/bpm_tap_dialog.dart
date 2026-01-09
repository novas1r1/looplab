import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Dialog for tapping to detect BPM
class BpmTapDialog extends StatefulWidget {
  const BpmTapDialog({super.key});

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
          Text(context.l10n.tapTheButtonBelowInRhythmWithYourMusicToDetectTheBpm),
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
                  context.read<SongCubit>().setOriginalBpm(_calculatedBpm);

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

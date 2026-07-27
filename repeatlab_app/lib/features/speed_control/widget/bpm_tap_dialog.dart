import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Dialog for tapping to detect BPM. A large circular pad shows the live
/// detected tempo; Reset / Use commit or clear it.
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
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.tapTempo,
            style: context.titleLarge.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.bpmTapHint,
            textAlign: TextAlign.center,
            style: context.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _tapPad(context),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('song.bpmTap.cancel'),
            onPressed: () {
              _resetTapBpm();
              Navigator.of(context).pop();
            },
            child: Text(
              context.l10n.cancel,
              style: context.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          key: const Key('song.bpmTap.reset'),
          onPressed: _resetTapBpm,
          child: Text(context.l10n.reset),
        ),
        FilledButton(
          key: const Key('song.bpmTap.use'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
          ),
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
          child: Text(
            _calculatedBpm != null
                ? context.l10n.useBpmValue(_calculatedBpm!)
                : context.l10n.useBpm,
          ),
        ),
      ],
    );
  }

  Widget _tapPad(BuildContext context) {
    return GestureDetector(
      key: const Key('song.bpmTap.pad'),
      onTap: () {
        _tapTimes.add(DateTime.now());
        _calculateBpmFromTaps();
      },
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryContainer.withAlpha(31),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _calculatedBpm?.toString() ?? '—',
              style: context.displaySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.bpmTapUnit,
              style: context.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateBpmFromTaps() {
    if (_tapTimes.length < 2) {
      setState(() {});
      return;
    }

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
    final averageInterval =
        intervals.reduce((a, b) => a + b) / intervals.length;

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

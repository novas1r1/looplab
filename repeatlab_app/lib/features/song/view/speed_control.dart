import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

enum _TempoMode { multiplier, bpm }

class SpeedControl extends StatefulWidget {
  const SpeedControl({super.key});

  @override
  State<SpeedControl> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<SpeedControl> {
  _TempoMode _mode = _TempoMode.multiplier;

  @override
  Widget build(BuildContext context) {
    final song = context.select((SongCubit cubit) => cubit.state.song);
    final speed = context.select((SongCubit cubit) => cubit.state.speed);

    final originalBpm = song.bpm;

    final sliderMin = _mode == _TempoMode.multiplier ? 0.5 : (originalBpm ?? 60) * 0.5;
    final sliderMax = _mode == _TempoMode.multiplier ? 2.0 : (originalBpm ?? 60) * 2.0;

    final sliderValue = _mode == _TempoMode.multiplier ? speed : (originalBpm ?? 60) * speed;

    final sliderLabel = _mode == _TempoMode.multiplier
        ? '${speed.toStringAsFixed(1)}x'
        : '${sliderValue.round()} BPM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(right: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Toggle between multiplier and bpm modes.
          ToggleButtons(
            isSelected: [
              _mode == _TempoMode.multiplier,
              _mode == _TempoMode.bpm,
            ],
            onPressed: (index) => _onSelectMode(index, context, originalBpm),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
            children: const [
              Text('x'),
              Text('BPM'),
            ],
          ),
          const SizedBox(width: 12),
          if (_mode == _TempoMode.bpm)
            Row(
              children: [
                Text(sliderLabel),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _onTapLabel(context, originalBpm),
                  child: const Icon(Icons.edit, size: 16),
                ),
              ],
            ),
          Expanded(
            child: Slider(
              value: sliderValue.clamp(sliderMin, sliderMax),
              min: sliderMin,
              max: sliderMax,
              divisions: _mode == _TempoMode.multiplier ? 15 : null,
              label: sliderLabel,
              onChanged: (val) => _onUpdate(context, val, originalBpm),
            ),
          ),
          Text(sliderLabel),
          if (_mode == _TempoMode.multiplier)
            IconButton(
              onPressed: () => _onReset(context),
              icon: const Icon(Icons.refresh),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }

  Future<void> _onSelectMode(int index, BuildContext context, int? originalBpm) async {
    final selectedMode = index == 0 ? _TempoMode.multiplier : _TempoMode.bpm;

    if (selectedMode == _TempoMode.bpm && originalBpm == null) {
      final bpm = await _promptForBpm(context, originalBpm);
      if (bpm == null) return; // User cancelled.

      await context.read<SongCubit>().updateBpm(bpm);
    }

    setState(() => _mode = selectedMode);
  }

  Future<int?> _promptForBpm(BuildContext context, int? originalBpm) async {
    final controller = TextEditingController();
    controller.text = originalBpm?.toString() ?? '';

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.enterSongBpm),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.enterSongBpmHint),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(hintText: context.l10n.enterSongBpmHint),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.pop<int>(context, value);
                }
              },
              child: Text(context.l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onUpdate(BuildContext context, double rawValue, int? originalBpm) async {
    double newSpeed;

    if (_mode == _TempoMode.multiplier) {
      newSpeed = rawValue;
    } else {
      // rawValue is BPM here.
      if (originalBpm == null || originalBpm == 0) return;
      newSpeed = rawValue / originalBpm;
    }

    _onUpdateSpeed(context, newSpeed);
  }

  Future<void> _onUpdateSpeed(BuildContext context, double newSpeed) async {
    AppAnalytics.trackEvent(AppAnalytics.clickUpdateSpeed, data: {'speed': newSpeed});

    final hasPurchased = context.read<PremiumSubscriptionCubit>().hasPremium;

    if (!context.mounted) return;

    if (hasPurchased) {
      context.read<SongCubit>().updateSpeed(newSpeed);
    } else {
      AppAnalytics.trackEvent(AppAnalytics.showPaywallSongSpeed);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
    }
  }

  Future<void> _onTapLabel(BuildContext context, int? originalBpm) async {
    if (_mode != _TempoMode.bpm) return;

    final bpm = await _promptForBpm(context, originalBpm);
    if (bpm == null) return;

    // Update song BPM only if it changed.
    if (originalBpm != bpm) {
      await context.read<SongCubit>().updateBpm(bpm);
    }
  }

  void _onReset(BuildContext context) {
    context.read<SongCubit>().updateSpeed(1.0);
  }
}

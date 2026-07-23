import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/widget/control_stepper.dart';
import 'package:repeatlab/features/speed_control/widget/bpm_tap_dialog.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// BPM mode for speed control. Reads state from SongCubit.
class SpeedControlBpmMode extends StatefulWidget {
  const SpeedControlBpmMode({super.key});

  @override
  State<SpeedControlBpmMode> createState() => _SpeedControlBpmModeState();
}

class _SpeedControlBpmModeState extends State<SpeedControlBpmMode> {
  final _originalBpmController = TextEditingController();
  bool _paywallShowing = false;

  @override
  void dispose() {
    _originalBpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    return BlocSelector<
      SongCubit,
      SongState,
      ({
        int? originalBpm,
        int? currentBpm,
        int? minBpm,
        int? maxBpm,
        double speed,
      })
    >(
      selector: (state) => (
        originalBpm: state.originalBpm,
        currentBpm: state.currentBpm,
        minBpm: state.minBpm,
        maxBpm: state.maxBpm,
        speed: state.speed,
      ),
      builder: (context, data) {
        if (data.originalBpm == null) {
          return _buildNotSet(context);
        }
        return _buildSet(context, data, hasPremium: hasPremium);
      },
    );
  }

  /// Original BPM unknown: a short hint, a compact numeric field to type it in,
  /// and the Tap Tempo pad as the prominent alternative.
  Widget _buildNotSet(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Text(
          context.l10n.setSongTempoHint,
          textAlign: TextAlign.center,
          style: context.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Row(
          children: [
            Expanded(child: _compactBpmField(context)),
            const SizedBox(width: 8),
            _tapTempoButton(context),
          ],
        ),
      ],
    );
  }

  Widget _compactBpmField(BuildContext context) {
    return TextField(
      key: const Key('song.speed.bpmOriginal'),
      controller: _originalBpmController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _onSetOriginalBpm(context),
      style: context.titleMedium.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        hintText: context.l10n.enterSongBpm,
        hintStyle: context.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          key: const Key('song.speed.bpmSet'),
          onPressed: () => _onSetOriginalBpm(context),
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _tapTempoButton(BuildContext context) {
    return FilledButton.icon(
      key: const Key('song.speed.tapTempo'),
      onPressed: () => _showTapBpmDialog(context),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.touch_app_rounded, size: 20),
      label: Text(context.l10n.tapTempo),
    );
  }

  /// Original BPM known: stepper for the current BPM, a slider over the
  /// supported range, and a reference row to the song's own BPM.
  Widget _buildSet(
    BuildContext context,
    ({
      int? originalBpm,
      int? currentBpm,
      int? minBpm,
      int? maxBpm,
      double speed,
    }) data, {
    required bool hasPremium,
  }) {
    final originalBpm = data.originalBpm!;
    final currentBpm = data.currentBpm ?? originalBpm;
    final minBpm = data.minBpm ?? (originalBpm * 0.5).round();
    final maxBpm = data.maxBpm ?? (originalBpm * 2.0).round();

    return Column(
      spacing: 8,
      children: [
        ControlStepper(
          value: '$currentBpm',
          subtitle: 'BPM · ${data.speed.toStringAsFixed(2)}×',
          decrementKey: const Key('song.speed.bpmMinus'),
          incrementKey: const Key('song.speed.bpmPlus'),
          onDecrement: currentBpm > minBpm
              ? () => _onStepBpm(context, currentBpm - 1, hasPremium: hasPremium)
              : null,
          onIncrement: currentBpm < maxBpm
              ? () => _onStepBpm(context, currentBpm + 1, hasPremium: hasPremium)
              : null,
        ),
        Row(
          children: [
            Text('$minBpm', style: context.labelLarge),
            Expanded(
              child: hasPremium
                  ? _slider(context, currentBpm, minBpm, maxBpm)
                  : Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => _showPremiumDialog(context),
                      child: AbsorbPointer(
                        child: _slider(context, currentBpm, minBpm, maxBpm),
                      ),
                    ),
            ),
            Text('$maxBpm', style: context.labelLarge),
          ],
        ),
        _songBpmRow(context, originalBpm),
      ],
    );
  }

  Widget _slider(
    BuildContext context,
    int currentBpm,
    int minBpm,
    int maxBpm,
  ) {
    return CustomSlider(
      value: currentBpm.toDouble().clamp(minBpm.toDouble(), maxBpm.toDouble()),
      min: minBpm.toDouble(),
      max: maxBpm.toDouble(),
      divisions: (maxBpm - minBpm).clamp(1, 10000),
      onChanged: (value) {
        AppAnalytics.trackEvent(
          AppAnalytics.clickUpdateBpm,
          data: {'bpm': value.round()},
        );
        context.read<SongCubit>().setSpeedByBpm(value.round());
      },
    );
  }

  Widget _songBpmRow(BuildContext context, int originalBpm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.music_note_rounded,
          size: 16,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n.songBpmValue(originalBpm),
          style: context.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          key: const Key('song.speed.editBpm'),
          onTap: () => _onEditBpm(context, originalBpm),
          child: Text(
            context.l10n.edit,
            style: context.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Returns to the set-or-tap entry so the original BPM can be re-entered or
  /// re-tapped. The field is pre-filled with the current value; clearing the
  /// original BPM is what surfaces that empty view again.
  void _onEditBpm(BuildContext context, int currentBpm) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickSetOriginalBpm,
      data: {'source': 'edit'},
    );
    final text = '$currentBpm';
    _originalBpmController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    context.read<SongCubit>().setOriginalBpm(null);
  }

  void _onStepBpm(BuildContext context, int bpm, {required bool hasPremium}) {
    if (!hasPremium) {
      _showPremiumDialog(context);
      return;
    }
    AppAnalytics.trackEvent(
      AppAnalytics.clickUpdateBpm,
      data: {'bpm': bpm},
    );
    context.read<SongCubit>().setSpeedByBpm(bpm);
  }

  void _onSetOriginalBpm(BuildContext context) {
    final bpm = int.tryParse(_originalBpmController.text);
    if (bpm != null && bpm > 0) {
      AppAnalytics.trackEvent(
        AppAnalytics.clickSetOriginalBpm,
        data: {'bpm': bpm, 'source': 'manual_input'},
      );
      context.read<SongCubit>().setOriginalBpm(bpm);
      _originalBpmController.clear();
    }
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    if (_paywallShowing) return;
    _paywallShowing = true;

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_speed',
      );
    } finally {
      if (mounted) {
        _paywallShowing = false;
      }
    }
  }

  Future<void> _showTapBpmDialog(BuildContext context) async {
    final cubit = context.read<SongCubit>();

    AppAnalytics.trackEvent(AppAnalytics.viewTapBpmDialog);

    await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const BpmTapDialog(),
      ),
    );
  }
}

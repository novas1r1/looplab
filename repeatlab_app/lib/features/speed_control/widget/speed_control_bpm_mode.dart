import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
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
      })
    >(
      selector: (state) => (
        originalBpm: state.originalBpm,
        currentBpm: state.currentBpm,
        minBpm: state.minBpm,
        maxBpm: state.maxBpm,
      ),
      builder: (context, data) {
        final originalBpm = data.originalBpm;
        final currentBpm = data.currentBpm;
        final minBpm = data.minBpm;
        final maxBpm = data.maxBpm;

        // If original BPM is not set, show input to set it
        if (originalBpm == null) {
          return Column(
            spacing: 8,
            children: [
              AutoSizeText(
                context.l10n.hereYouCanSetTheOriginalBpmOfTheAudioFile,
                minFontSize: 12,
                maxFontSize: 20,
                style: context.labelLarge.copyWith(fontStyle: FontStyle.italic),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _originalBpmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: context.l10n.enterSongBpm,
                        hintStyle: context.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _onSetOriginalBpm(context),
                    child: AutoSizeText(
                      context.l10n.setBpm,
                      minFontSize: 12,
                      maxFontSize: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showTapBpmDialog(context),
                    child: AutoSizeText(
                      context.l10n.tapBpm,
                      minFontSize: 12,
                      maxFontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8).copyWith(right: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Original BPM tile - tappable to edit
                  GestureDetector(
                    onTap: () =>
                        _showEditOriginalBpmDialog(context, originalBpm),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AutoSizeText(
                                context.l10n.originalBpm,
                                minFontSize: 14,
                                maxFontSize: 24,
                                style: context.bodySmall.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: AppColors.onPrimaryContainer.withAlpha(
                                  180,
                                ),
                              ),
                            ],
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
                  // Current BPM tile - read-only
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          context.l10n.currentBpm,
                          minFontSize: 14,
                          maxFontSize: 24,
                          style: context.bodySmall.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          currentBpm?.toString() ?? '-',
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
                    // Min BPM label
                    Text(minBpm.toString(), style: context.labelLarge),
                    // BPM slider
                    Expanded(
                      child: hasPremium
                          ? CustomSlider(
                              value: currentBpm.toDouble().clamp(
                                minBpm.toDouble(),
                                maxBpm.toDouble(),
                              ),
                              min: minBpm.toDouble(),
                              max: maxBpm.toDouble(),
                              divisions: maxBpm - minBpm,
                              onChanged: (value) {
                                AppAnalytics.trackEvent(
                                  AppAnalytics.clickUpdateBpm,
                                  data: {'bpm': value.round()},
                                );
                                context.read<SongCubit>().setSpeedByBpm(
                                  value.round(),
                                );
                              },
                            )
                          : Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) => _showPremiumDialog(context),
                              child: AbsorbPointer(
                                child: CustomSlider(
                                  value: currentBpm.toDouble().clamp(
                                    minBpm.toDouble(),
                                    maxBpm.toDouble(),
                                  ),
                                  min: minBpm.toDouble(),
                                  max: maxBpm.toDouble(),
                                  divisions: maxBpm - minBpm,
                                  onChanged: (_) {},
                                ),
                              ),
                            ),
                    ),
                    // Max BPM label
                    Text(maxBpm.toString(), style: context.labelLarge),
                  ],
                ),
            ],
          ),
        );
      },
    );
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

    AppAnalytics.trackEvent(
      AppAnalytics.showPaywallSongSpeed,
      data: {'from': 'speed_control_bpm'},
    );

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall();
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

  Future<void> _showEditOriginalBpmDialog(
    BuildContext context,
    int currentOriginalBpm,
  ) async {
    final cubit = context.read<SongCubit>();

    AppAnalytics.trackEvent(AppAnalytics.viewEditOriginalBpmDialog);

    await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: EditOriginalBpmDialog(currentOriginalBpm: currentOriginalBpm),
      ),
    );
  }
}

/// Dialog for editing the original BPM value
class EditOriginalBpmDialog extends StatefulWidget {
  const EditOriginalBpmDialog({
    required this.currentOriginalBpm,
    super.key,
  });

  final int currentOriginalBpm;

  @override
  State<EditOriginalBpmDialog> createState() => _EditOriginalBpmDialogState();
}

class _EditOriginalBpmDialogState extends State<EditOriginalBpmDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentOriginalBpm.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.originalBpm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.enterSongBpm,
              hintStyle: context.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Option to clear BPM
          TextButton(
            onPressed: () {
              AppAnalytics.trackEvent(
                AppAnalytics.clickSetOriginalBpm,
                data: {'source': 'reset'},
              );
              Navigator.of(context).pop();
              context.read<SongCubit>().setOriginalBpm(null);
            },
            child: Text(
              context.l10n.reset,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        PrimaryButton(
          text: context.l10n.setBpm,
          onPressed: () {
            final bpm = int.tryParse(_controller.text);
            if (bpm != null && bpm > 0) {
              AppAnalytics.trackEvent(
                AppAnalytics.clickSetOriginalBpm,
                data: {'bpm': bpm, 'source': 'edit_dialog'},
              );
              context.read<SongCubit>().setOriginalBpm(bpm);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

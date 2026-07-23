import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Key mode for pitch control (mirrors [SpeedControlBpmMode]).
/// Reads state from SongCubit.
class PitchControlKeyMode extends StatefulWidget {
  const PitchControlKeyMode({super.key});

  @override
  State<PitchControlKeyMode> createState() => _PitchControlKeyModeState();
}

class _PitchControlKeyModeState extends State<PitchControlKeyMode> {
  bool _paywallShowing = false;

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    return BlocSelector<SongCubit, SongState,
        ({String? musicalKey, int pitchSemitones})>(
      selector: (state) => (
        musicalKey: state.song.musicalKey,
        pitchSemitones: state.pitchSemitones,
      ),
      builder: (context, data) {
        final originalKey = data.musicalKey;

        // If the original key is not set, show a picker to set it
        if (originalKey == null) {
          return Column(
            spacing: 8,
            children: [
              AutoSizeText(
                context.l10n.hereYouCanSetTheOriginalKeyOfTheAudioFile,
                minFontSize: 12,
                maxFontSize: 20,
                style: context.labelLarge.copyWith(fontStyle: FontStyle.italic),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DropdownButtonFormField<String>(
                  key: const Key('song.pitch.keyOriginal'),
                  decoration: InputDecoration(
                    labelText: context.l10n.originalKey,
                  ),
                  items: MusicalKey.allKeys
                      .map(
                        (key) => DropdownMenuItem(
                          value: key,
                          child: Text(MusicalKey.displayLabel(key)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _onSetOriginalKey(context, value),
                ),
              ),
            ],
          );
        }

        final currentKey =
            MusicalKey.transpose(originalKey, data.pitchSemitones) ??
                originalKey;
        final targetKeys = MusicalKey.sameModeKeys(originalKey);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8).copyWith(right: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Original key tile - tappable to edit
                  GestureDetector(
                    onTap: () => _showEditOriginalKeyDialog(
                      context,
                      originalKey,
                    ),
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
                                context.l10n.originalKey,
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
                            MusicalKey.displayLabel(originalKey),
                            style: context.titleMedium.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Current key tile - read-only, shows the shift
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
                          context.l10n.currentKey,
                          minFontSize: 14,
                          maxFontSize: 24,
                          style: context.bodySmall.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          _formatCurrentKey(currentKey, data.pitchSemitones),
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
              if (targetKeys != null)
                hasPremium
                    ? _buildTargetKeyPicker(context, currentKey, targetKeys)
                    : Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) => _showPremiumDialog(context),
                        child: AbsorbPointer(
                          child: _buildTargetKeyPicker(
                            context,
                            currentKey,
                            targetKeys,
                          ),
                        ),
                      ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetKeyPicker(
    BuildContext context,
    String currentKey,
    List<String> targetKeys,
  ) {
    return DropdownButtonFormField<String>(
      key: const Key('song.pitch.keyTarget'),
      initialValue: currentKey,
      decoration: InputDecoration(
        labelText: context.l10n.editSongKey,
      ),
      items: targetKeys
          .map(
            (key) => DropdownMenuItem(
              value: key,
              child: Text(MusicalKey.displayLabel(key)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        final cubit = context.read<SongCubit>();
        final originalKey = cubit.state.song.musicalKey;
        if (originalKey == null) return;
        AppAnalytics.trackEvent(
          AppAnalytics.clickUpdatePitch,
          data: {
            'semitones': MusicalKey.signedOffset(originalKey, value),
            'source': 'key_mode',
          },
        );
        cubit.setPitchByTargetKey(value);
      },
    );
  }

  /// "Cm (+3)" — key plus the semitone offset that produced it.
  String _formatCurrentKey(String currentKey, int pitchSemitones) {
    if (pitchSemitones == 0) return currentKey;
    final sign = pitchSemitones > 0 ? '+' : '−';
    return '$currentKey ($sign${pitchSemitones.abs()})';
  }

  void _onSetOriginalKey(BuildContext context, String? key) {
    if (key == null) return;
    AppAnalytics.trackEvent(
      AppAnalytics.clickSetOriginalKey,
      data: {'key': key, 'source': 'key_mode'},
    );
    context.read<SongCubit>().setOriginalKey(key);
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    if (_paywallShowing) return;
    _paywallShowing = true;

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_pitch',
      );
    } finally {
      if (mounted) {
        _paywallShowing = false;
      }
    }
  }

  Future<void> _showEditOriginalKeyDialog(
    BuildContext context,
    String currentOriginalKey,
  ) async {
    final cubit = context.read<SongCubit>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: EditOriginalKeyDialog(currentOriginalKey: currentOriginalKey),
      ),
    );
  }
}

/// Dialog for editing the original key
class EditOriginalKeyDialog extends StatefulWidget {
  const EditOriginalKeyDialog({
    required this.currentOriginalKey,
    super.key,
  });

  final String currentOriginalKey;

  @override
  State<EditOriginalKeyDialog> createState() => _EditOriginalKeyDialogState();
}

class _EditOriginalKeyDialogState extends State<EditOriginalKeyDialog> {
  late String _selectedKey;

  @override
  void initState() {
    super.initState();
    _selectedKey =
        MusicalKey.canonicalize(widget.currentOriginalKey) ??
            MusicalKey.allKeys.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.originalKey),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedKey,
            items: MusicalKey.allKeys
                .map(
                  (key) => DropdownMenuItem(
                    value: key,
                    child: Text(MusicalKey.displayLabel(key)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedKey = value);
              }
            },
          ),
          const SizedBox(height: 16),
          // Option to clear the key
          TextButton(
            onPressed: () {
              AppAnalytics.trackEvent(
                AppAnalytics.clickSetOriginalKey,
                data: {'source': 'reset'},
              );
              Navigator.of(context).pop();
              context.read<SongCubit>().setOriginalKey(null);
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
            AppAnalytics.trackEvent(
              AppAnalytics.clickSetOriginalKey,
              data: {'key': _selectedKey, 'source': 'edit_dialog'},
            );
            context.read<SongCubit>().setOriginalKey(_selectedKey);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

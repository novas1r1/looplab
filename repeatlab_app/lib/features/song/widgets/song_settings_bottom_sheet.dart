import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';
import 'package:wiredash/wiredash.dart';

/// A beautiful bottom sheet for song settings and actions.
class SongSettingsBottomSheet extends StatelessWidget {
  final VoidCallback onDeleteSong;
  final VoidCallback onEditSong;

  const SongSettingsBottomSheet({
    super.key,
    required this.onDeleteSong,
    required this.onEditSong,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDeleteSong,
    required VoidCallback onEditSong,
  }) {
    final songCubit = context.read<SongCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: songCubit,
        child: SongSettingsBottomSheet(
          onDeleteSong: onDeleteSong,
          onEditSong: onEditSong,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppIcon(
                      iconName: 'ic_settings',
                      iconSize: 20,
                      containerSize: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    context.l10n.songSettings,
                    style: context.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Playback Settings Section
              _SectionHeader(
                iconName: 'ic_play_circle',
                title: context.l10n.playbackSettings,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  // Full Song Repeat
                  BlocSelector<SongCubit, SongState, bool>(
                    selector: (state) => state.isFullSongRepeatEnabled,
                    builder: (context, isFullSongRepeatEnabled) {
                      return _SettingsTile(
                        iconName: 'ic_repeat',
                        iconColor: isFullSongRepeatEnabled
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        title: context.l10n.repeatFullSong,
                        value: isFullSongRepeatEnabled,
                        onChanged: (newValue) {
                          AppAnalytics.trackEvent(
                            AppAnalytics.clickToggleFullSongRepeat,
                            data: {'enabled': newValue},
                          );
                          context.read<SongCubit>().toggleFullSongRepeat();
                        },
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  // Auto-play on Loop Select
                  BlocSelector<SongCubit, SongState, bool>(
                    selector: (state) => state.isAutoPlayEnabled,
                    builder: (context, isAutoPlayEnabled) {
                      return _SettingsTile(
                        iconName: 'ic_play',
                        iconColor: isAutoPlayEnabled
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        title: context.l10n.autoPlayOnLoopSelect,
                        subtitle: context.l10n.autoPlayOnLoopSelectDescription,
                        value: isAutoPlayEnabled,
                        onChanged: (newValue) {
                          AppAnalytics.trackEvent(
                            AppAnalytics.clickToggleAutoPlay,
                            data: {'enabled': newValue},
                          );
                          context.read<SongCubit>().toggleAutoPlay();
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Actions Section
              _SectionHeader(
                iconName: 'ic_touch',
                title: context.l10n.actions,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _ActionTile(
                    iconName: 'ic_edit',
                    title: context.l10n.editSong,
                    onTap: () {
                      Navigator.pop(context);
                      onEditSong();
                    },
                  ),
                  const _SettingsDivider(),
                  _ActionTile(
                    iconName: 'ic_feedback',
                    title: context.l10n.reportBugAndFeedback,
                    onTap: () {
                      AppAnalytics.trackEvent(AppAnalytics.clickReportBug);
                      AppAnalytics.trackEvent(AppAnalytics.viewFeedback);
                      Navigator.pop(context);
                      Wiredash.of(context).show(inheritMaterialTheme: true);
                    },
                  ),
                  const _SettingsDivider(),
                  _ActionTile(
                    iconName: 'ic_delete',
                    title: context.l10n.deleteSong,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      onDeleteSong();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String iconName;
  final String title;

  const _SectionHeader({
    required this.iconName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // AppIcon(
        //   iconName: iconName,
        //   iconSize: 18,
        //   color: AppColors.primary,
        // ),
        // const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: context.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String iconName;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.iconName,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.onSurfaceVariant).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                iconName: iconName,
                color: iconColor ?? AppColors.onSurfaceVariant,
                iconSize: 20,
                containerSize: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primaryContainer,
              inactiveTrackColor: AppColors.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String iconName;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.iconName,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                iconName: iconName,
                iconSize: 20,
                containerSize: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: context.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: AppColors.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

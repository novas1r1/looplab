import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:repeatlab/app/router.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/song/view/song_page.dart';
import 'package:repeatlab/l10n/l10n.dart';

class HomeTile extends StatelessWidget {
  final Song song;

  const HomeTile({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.3,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _onDeleteSong(context),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.danger.shade200,
            icon: Icons.delete,
            label: context.l10n.delete,
            padding: const EdgeInsets.all(8),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
      child: Card(
        color: AppColors.inversePrimary.withValues(alpha: 0.7),
        elevation: 2,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/waveform.png'),
              fit: BoxFit.cover,
              opacity: 0.2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            dense: true,
            visualDensity: VisualDensity.compact,
            minLeadingWidth: 36,
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIcon(
                iconName: song.mediaType == MediaType.video ? 'ic_video' : 'ic_audio',
                iconSize: 20,
                color: AppColors.onPrimary,
              ),
            ),
            onTap: () => _onTapSong(context, song),
            title: Text(
              song.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              song.artist,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MetaChip(
                  child: Text(
                    song.duration.toFormattedStringWithoutMilliseconds(),
                    style: const TextStyle(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _MetaChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        iconName: 'ic_infinity',
                        iconSize: 18,
                        containerSize: 18,
                        color: AppColors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${song.loops.length}',
                        style: const TextStyle(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTapSong(BuildContext context, Song song) {
    AppAnalytics.trackEvent(AppAnalytics.clickOpenSong);

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRouter.song),
        builder: (context) => SongPage(song: song),
      ),
    );
  }

  void _onDeleteSong(BuildContext context) {
    AppAnalytics.trackEvent(AppAnalytics.clickDeleteSong);

    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.deleteSong),
          content: Text(context.l10n.deleteSongConfirmation(song.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AllSongsCubit>().deleteSong(song);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final Widget child;

  const _MetaChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

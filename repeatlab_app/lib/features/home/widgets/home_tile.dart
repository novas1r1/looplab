import 'package:flutter/material.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/song/view/song_page.dart';

class HomeTile extends StatelessWidget {
  final Song song;

  const HomeTile({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.7),
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
            vertical: 16,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${song.loops.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
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
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              song.duration.toFormattedStringWithoutMilliseconds(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
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
      MaterialPageRoute(builder: (context) => SongPage(song: song)),
    );
  }
}

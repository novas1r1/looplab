import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/core/utils/snackbar_helper.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/changelog_dialog/changelog_dialog.dart';
import 'package:repeatlab/features/changelog_dialog/cubits/changelog_dialog_cubit.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/widgets/custom_drawer.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';
import 'package:repeatlab/l10n/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    AppAnalytics.trackEvent(AppAnalytics.viewHome);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChangelogDialogCubit>().checkChangelogDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final songCount = context.watch<AllSongsCubit>().state.songs.length;

    return BlocListener<ChangelogDialogCubit, ChangelogDialogState>(
      listener: (context, state) {
        _displayChangelogDialog(state, context);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        drawer: const CustomDrawer(),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            'RepeatLab',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.read<AllSongsCubit>().loadSongs(),
              icon: const Icon(Icons.refresh),
            ),
            if (kDebugMode)
              IconButton(
                onPressed: () => _onClearDb(context),
                icon: const Icon(Icons.delete),
              ),
            if (kDebugMode)
              IconButton(
                onPressed: () => _onClearSharedPrefs(context),
                icon: const Icon(Icons.delete_forever),
              ),
          ],
        ),
        body: BlocConsumer<AllSongsCubit, AllSongsState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == AllSongsStatus.error) {
              final format = state.errorMessage;
              if (format != null) {
                AppAnalytics.trackEvent(
                  AppAnalytics.songAddUnsupportedFormat,
                  data: {'format': format},
                );
                // errorMessage contains the unsupported format extension
                SnackbarHelper.showError(
                  context,
                  context.l10n.unsupportedAudioFormatError(
                    format,
                    SongRepository.supportedFormatsLabel,
                  ),
                );
              } else {
                AppAnalytics.trackEvent(AppAnalytics.songAddError);
                SnackbarHelper.showError(context, context.l10n.songAddError);
              }
            } else if (state.status == AllSongsStatus.errorVideoFormat) {
              final format = state.errorMessage ?? '';
              AppAnalytics.trackEvent(
                AppAnalytics.songAddUnsupportedFormat,
                data: {'format': format, 'kind': 'video'},
              );
              SnackbarHelper.showError(
                context,
                context.l10n.unsupportedVideoFormatError(
                  format,
                  SongRepository.supportedVideoFormatsLabel,
                ),
              );
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case AllSongsStatus.loading:
                return const Center(child: Loading());
              case AllSongsStatus.initial:
              case AllSongsStatus.loaded:
              case AllSongsStatus.error:
              case AllSongsStatus.errorVideoFormat:
                if (state.songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.noSongsFound,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.tapToAddSong,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                  itemCount: state.songs.length,
                  onReorder: (int oldIndex, int newIndex) {
                    context.read<AllSongsCubit>().reorderSongs(
                      oldIndex,
                      newIndex,
                    );
                  },
                  onReorderEnd: (_) {
                    AppAnalytics.trackEvent(AppAnalytics.reorderSongs);
                  },
                  proxyDecorator:
                      (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                  itemBuilder: (context, index) {
                    final song = state.songs[index];
                    return Padding(
                      key: ValueKey(song.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HomeTile(song: song),
                    );
                  },
                );
            }
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'addMedia',
          onPressed: () => _showAddMediaSheet(context, songCount),
          icon: const Icon(Icons.add),
          label: Text(
            context.l10n.addSong,
            style: context.bodyLargeDarkBold,
          ),
        ),
      ),
    );
  }

  /// Show a bottom sheet that lets the user choose between adding an audio
  /// file or a video file. Both flows share the same rate-app prompt.
  Future<void> _showAddMediaSheet(
    BuildContext context,
    int numberOfSongs,
  ) async {
    AppAnalytics.trackEvent(AppAnalytics.clickAddSong);

    final choice = await showModalBottomSheet<_AddMediaChoice>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: Text(context.l10n.addSong),
                subtitle: const Text(SongRepository.supportedFormatsLabel),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AddMediaChoice.audio),
              ),
              ListTile(
                leading: const Icon(Icons.movie),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.addVideo),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        context.l10n.betaLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  SongRepository.supportedVideoFormatsLabel,
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AddMediaChoice.video),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;

    await _promptRateAppIfDue(context, numberOfSongs);
    if (!context.mounted) return;

    switch (choice) {
      case _AddMediaChoice.audio:
        context.read<AllSongsCubit>().addSong();
      case _AddMediaChoice.video:
        context.read<AllSongsCubit>().addVideo();
    }
  }

  /// Show the rate-app dialog if the user has 2+ songs and hasn't rated yet.
  /// Shared between audio and video add flows.
  Future<void> _promptRateAppIfDue(
    BuildContext context,
    int numberOfSongs,
  ) async {
    final hasRatedAlready = context.read<LocalConfigRepository>().hasRatedApp;
    if (numberOfSongs >= 2 && !hasRatedAlready) {
      await DialogHelper.displayRateAppDialog(context);
    }
  }

  Future<void> _onClearDb(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickClearDb);
    await context.read<AllSongsCubit>().clearDb();
  }

  void _onClearSharedPrefs(BuildContext context) {
    context.read<LocalConfigRepository>().clear();
  }

  Future<void> _displayChangelogDialog(
    ChangelogDialogState state,
    BuildContext context,
  ) async {
    if (!state.shouldShowDialog) return;

    AppAnalytics.trackEvent(AppAnalytics.viewChangelogDialog);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => const ChangelogDialog(),
    );

    if (!context.mounted) return;
    context.read<ChangelogDialogCubit>().setChangelogDialogSeen();
  }
}

/// User choice from the add-media bottom sheet.
enum _AddMediaChoice { audio, video }

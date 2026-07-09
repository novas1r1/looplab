import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/core/ui/motion_widgets.dart';
import 'package:repeatlab/core/ui/widgets/app_bottom_sheet.dart';
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

  /// The song list staggers in once, on the first loaded frame. Rebuilds,
  /// reorders, and later loads render instantly.
  bool _didAnimateList = false;

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
    final allSongsState = context.watch<AllSongsCubit>().state;
    final songCount = allSongsState.songs.length;
    // Block a second import while one is running (or the list is loading);
    // large videos can take a while to copy and probe.
    final isBusy =
        allSongsState.status == AllSongsStatus.loading ||
        allSongsState.status == AllSongsStatus.importing;

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
            key: const Key('home.drawer'),
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
              AppAnalytics.trackEvent(AppAnalytics.songAddError);
              SnackbarHelper.showError(context, context.l10n.songAddError);
            } else if (state.status == AllSongsStatus.errorAudioFormat) {
              // errorMessage contains the unsupported format extension
              final format = state.errorMessage ?? '';
              AppAnalytics.trackEvent(
                AppAnalytics.songAddUnsupportedFormat,
                data: {'format': format},
              );
              SnackbarHelper.showError(
                context,
                context.l10n.unsupportedAudioFormatError(
                  format,
                  SongRepository.supportedFormatsLabel,
                ),
              );
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
            } else if (state.status == AllSongsStatus.errorImportInProgress) {
              SnackbarHelper.showError(
                context,
                context.l10n.importAlreadyRunningError,
              );
            }
          },
          builder: (context, state) =>
              FadeThroughSwitcher(child: _buildBody(context, state)),
        ),
        floatingActionButton: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: Motion.of(context, Motion.slow),
          curve: Motion.pop,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: scale.clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: FloatingActionButton.extended(
            key: const Key('home.fab'),
            heroTag: 'addMedia',
            onPressed: isBusy
                ? null
                : () => _showAddMediaSheet(context, songCount),
            backgroundColor: isBusy ? Theme.of(context).disabledColor : null,
            icon: AnimatedOpacity(
              opacity: isBusy ? 0.55 : 1,
              duration: Motion.of(context, Motion.fast),
              child: const Icon(Icons.add),
            ),
            label: AnimatedOpacity(
              opacity: isBusy ? 0.55 : 1,
              duration: Motion.of(context, Motion.fast),
              child: Text(
                context.l10n.addSong,
                style: context.bodyLargeDarkBold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AllSongsState state) {
    switch (state.status) {
      case AllSongsStatus.loading:
        return const Center(
          key: Key('home.loading'),
          child: Loading(),
        );
      case AllSongsStatus.importing:
        return Center(
          key: const Key('home.importing'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Loading(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  context.l10n.importingMedia,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (state.importCurrent != null && state.importTotal != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.importingMediaProgress(
                    state.importCurrent!,
                    state.importTotal!,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case AllSongsStatus.initial:
      case AllSongsStatus.loaded:
      case AllSongsStatus.error:
      case AllSongsStatus.errorAudioFormat:
      case AllSongsStatus.errorVideoFormat:
      case AllSongsStatus.errorImportInProgress:
        if (state.songs.isEmpty) {
          return Center(
            key: const Key('home.empty'),
            child: EntranceSlideFade(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1),
                    duration: Motion.of(context, Motion.slow),
                    curve: Motion.pop,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Icon(
                      Icons.music_note,
                      size: 64,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.noSongsFound,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.tapToAddSong,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final animateEntrance = !_didAnimateList;
        if (animateEntrance) {
          // Flip without setState: future rebuilds simply skip the stagger.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _didAnimateList = true;
          });
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
          itemCount: state.songs.length,
          onReorderItem: (int oldIndex, int newIndex) {
            context.read<AllSongsCubit>().reorderSongs(
              oldIndex,
              newIndex,
            );
          },
          onReorderEnd: (_) =>
              AppAnalytics.trackEvent(AppAnalytics.reorderSongs),
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
                return Material(
                  color: Colors.transparent,
                  child: child,
                );
              },
          itemBuilder: (context, index) => EntranceSlideFade(
            key: ValueKey(state.songs[index].id),
            enabled: animateEntrance,
            delay: Duration(milliseconds: 40 * math.min(index, 8)),
            child: HomeTile(
              song: state.songs[index],
            ),
          ),
        );
    }
  }

  /// Show a bottom sheet that lets the user choose between adding an audio
  /// file or a video file. Both flows share the same rate-app prompt.
  Future<void> _showAddMediaSheet(
    BuildContext context,
    int numberOfSongs,
  ) async {
    AppAnalytics.trackEvent(AppAnalytics.clickAddSong);

    final choice = await AppBottomSheet.show<_AddMediaChoice>(
      context,
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
                key: const Key('home.addAudio'),
                leading: const Icon(Icons.audiotrack),
                title: Text(context.l10n.addSong),
                subtitle: const Text(SongRepository.supportedFormatsLabel),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AddMediaChoice.audio),
              ),
              ListTile(
                key: const Key('home.addVideo'),
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
                subtitle: Text(
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

    await AppBottomSheet.show<void>(
      context,
      isScrollControlled: true,
      builder: (context) => const ChangelogDialog(),
    );

    if (!context.mounted) return;
    context.read<ChangelogDialogCubit>().setChangelogDialogSeen();
  }
}

/// User choice from the add-media bottom sheet.
enum _AddMediaChoice { audio, video }

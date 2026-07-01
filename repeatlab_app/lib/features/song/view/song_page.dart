import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/snackbar_helper.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/cubit/song_exporter/song_exporter_cubit.dart';
import 'package:repeatlab/features/song/cubit/video_song/video_song_cubit.dart';
import 'package:repeatlab/features/song/view/song_controller.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';
import 'package:repeatlab/features/song/widgets/loop_timeline.dart';
import 'package:repeatlab/features/song/widgets/song_settings_bottom_sheet.dart';
import 'package:repeatlab/features/song/widgets/tutorial_item.dart';
import 'package:repeatlab/features/song/widgets/video_preview.dart';
import 'package:repeatlab/features/song/widgets/wave_form_soloud.dart';
import 'package:repeatlab/l10n/l10n.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class SongPage extends StatelessWidget {
  final Song song;

  const SongPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final isVideo = song.mediaType == MediaType.video;

    return MultiBlocProvider(
      providers: [
        // For video, provide a VideoSongCubit under the SongCubit type so all
        // shared widgets reading `context.read<SongCubit>()` resolve to it.
        // The video cubit shares state shape + methods via inheritance.
        if (isVideo)
          BlocProvider<SongCubit>(
            create: (context) => VideoSongCubit(
              songRepository: context.read<SongRepository>(),
              localConfigRepository: context.read<LocalConfigRepository>(),
              crashReportingRepository: context
                  .read<CrashReportingRepository>(),
              song: song,
            )..initVideo(),
          )
        else
          BlocProvider<SongCubit>(
            create: (context) => SongCubit(
              songRepository: context.read<SongRepository>(),
              localConfigRepository: context.read<LocalConfigRepository>(),
              crashReportingRepository: context
                  .read<CrashReportingRepository>(),
              song: song,
            )..initSong(AudioPlayer()),
          ),
        BlocProvider(
          create: (context) => SongExporterCubit(
            crashReportingRepository: context.read<CrashReportingRepository>(),
          ),
        ),
      ],
      child: _SongView(song: song),
    );
  }
}

class _SongView extends StatefulWidget {
  final Song song;

  const _SongView({required this.song});

  @override
  State<_SongView> createState() => _SongViewState();
}

class _SongViewState extends State<_SongView> with WidgetsBindingObserver {
  // final Duration _currentPlayerPosition = Duration.zero;

  final _loopListController = ScrollController();

  late TutorialCoachMark tutorialCoachMark;

  /// Tutorial keys
  GlobalKey tutorialKeyWaveform = GlobalKey();
  GlobalKey tutorialKeySongController = GlobalKey();
  GlobalKey tutorialKeyLoopTimeline = GlobalKey();
  GlobalKey tutorialKeyLoopStart = GlobalKey();
  GlobalKey tutorialKeyLoopEnd = GlobalKey();
  GlobalKey tutorialKeyLoopActivate = GlobalKey();
  GlobalKey tutorialKeyLoopAdd = GlobalKey();

  bool get _isVideo => widget.song.mediaType == MediaType.video;

  @override
  void initState() {
    super.initState();
    AppAnalytics.trackEvent(AppAnalytics.viewSong);
    // Video has no background-playback story (no audio_service integration);
    // observe lifecycle so we can pause when the app is backgrounded.
    if (_isVideo) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    // context.read<SongCubit>().close();
    if (_isVideo) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _loopListController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideo) return;
    // Only react to states that mean the user can't see the video:
    //   * paused — true backgrounding (mobile)
    //   * hidden — window minimized (desktop)
    // NOT inactive — that fires on transient focus changes (e.g. clicking
    // a button on Windows, control-center swipe on iOS) while the app is
    // still visible; pausing on it would defeat user-initiated playback.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      context.read<SongCubit>().pauseSong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SongCubit, SongState>(
          listener: (context, state) {
            if (state.status == SongStatus.loadSuccess) {
              createTutorial(context);

              if (!state.isTutorialCompleted) {
                showTutorial();
              }
            } else if (state.status == SongStatus.error) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error ?? 'Unknown error')),
              );
            } else if (state.status == SongStatus.speedChangeFailed) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              SnackbarHelper.showError(
                context,
                context.l10n.speedChangeFailed,
              );
            } else if (state.status == SongStatus.songDeleted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if (state.status == SongStatus.loopAdded) {
              // scroll down in looplist
              _loopListController.animateTo(
                _loopListController.position.maxScrollExtent + 100,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );

              SnackbarHelper.showSuccess(context, context.l10n.loopAdded);
            } else if (state.status == SongStatus.loopModeToggled) {
              if (state.isLoopModeEnabled) {
                SnackbarHelper.showSuccess(
                  context,
                  context.l10n.loopModeEnabled,
                );
              } else {
                SnackbarHelper.showSuccess(
                  context,
                  context.l10n.loopModeDisabled,
                );
              }
            }
          },
        ),
      ],
      child: BlocSelector<SongCubit, SongState, SongStatus>(
        selector: (state) => state.status,
        builder: (context, status) {
          switch (status) {
            case SongStatus.loading:
              return const Scaffold(body: Center(child: Loading()));
            case SongStatus.loadError:
              return Scaffold(
                appBar: AppBar(
                  title: BlocSelector<SongCubit, SongState, String>(
                    selector: (state) => state.song.title,
                    builder: (context, title) {
                      return AutoSizeText(
                        title,
                        minFontSize: 20,
                        maxFontSize: 24,
                        maxLines: 2,
                      );
                    },
                  ),
                ),
                body: Center(
                  child: Text(
                    'Error loading song: ${context.read<SongCubit>().state.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            default:
              return Scaffold(
                appBar: AppBar(
                  title: BlocSelector<SongCubit, SongState, String>(
                    selector: (state) => state.song.title,
                    builder: (context, title) {
                      return Text(title);
                    },
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        AppAnalytics.trackEvent(AppAnalytics.clickHelp);
                        showTutorial();
                      },
                      icon: const Icon(Icons.help_outline),
                    ),
                    // Settings button - opens bottom sheet
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => SongSettingsBottomSheet.show(
                        context,
                        onDeleteSong: () => _onTapDeleteSong(context),
                        onEditSong: () => _showEditSongDialog(context),
                      ),
                    ),
                  ],
                ),
                resizeToAvoidBottomInset: true,
                body: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (_isVideo)
                            VideoPreview(
                              key: tutorialKeyWaveform,
                              song: widget.song,
                            )
                          else
                            WaveFormSoLoud(
                              key: tutorialKeyWaveform,
                              song: widget.song,
                            ),
                          const SizedBox(height: 8),
                          BlocSelector<
                            PremiumSubscriptionCubit,
                            PremiumSubscriptionState,
                            bool
                          >(
                            selector: (state) =>
                                state.hasWeeklySubscription ||
                                state.hasYearlySubscription ||
                                state.hasLifetimePurchase,
                            builder: (context, hasPremium) {
                              return LoopTimeline(
                                key: tutorialKeyLoopTimeline,
                                onLoopTap: (loop) =>
                                    context.read<SongCubit>().selectLoop(loop),
                                onSkipPrevious: () => context
                                    .read<SongCubit>()
                                    .skipToPreviousOrRestart(),
                                onSkipNext: () =>
                                    context.read<SongCubit>().skipToNextLoop(),
                                onSeek: (position) => context
                                    .read<SongCubit>()
                                    .seekSong(position),
                                duration: widget.song.duration,
                                isLoopLocked: (loop) {
                                  if (hasPremium) return false;
                                  final loops = context
                                      .read<SongCubit>()
                                      .state
                                      .song
                                      .loops;
                                  if (loops.isEmpty) return false;
                                  return loop.id != loops.first.id;
                                },
                                onLockedLoopTap: (_) => _presentLoopPaywall(
                                  context,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SongController(
                            key: tutorialKeySongController,
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AutoSizeText(
                                context.l10n.loops,
                                minFontSize: 16,
                                maxFontSize: 24,
                                style: context.headlineSmall,
                              ),
                              Row(
                                children: [
                                  AutoSizeText(
                                    context.l10n.loopMode,
                                    minFontSize: 20,
                                    maxFontSize: 24,
                                    style: context.bodySmall,
                                  ),
                                  BlocSelector<SongCubit, SongState, bool>(
                                    selector: (state) =>
                                        state.isLoopModeEnabled,
                                    builder: (context, isLoopModeEnabled) {
                                      return CupertinoSwitch(
                                        key: tutorialKeyLoopActivate,
                                        thumbIcon:
                                            WidgetStateProperty.resolveWith<
                                              Icon?
                                            >((
                                              Set<WidgetState> states,
                                            ) {
                                              if (states.contains(
                                                WidgetState.disabled,
                                              )) {
                                                return const Icon(Icons.close);
                                              }
                                              return const Icon(
                                                Icons.loop_rounded,
                                              );
                                            }),
                                        activeTrackColor:
                                            AppColors.primaryContainer,
                                        inactiveTrackColor:
                                            AppColors.secondaryContainer,
                                        value: isLoopModeEnabled,
                                        onChanged: (value) =>
                                            _onToggleLoopMode(context),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  key: tutorialKeyLoopStart,
                                  onPressed: () => _onSetLoopStart(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: AutoSizeText(
                                    context.l10n.setLoopStart,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    minFontSize: 12,
                                    maxFontSize: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    BlocSelector<SongCubit, SongState, Loop?>(
                                      selector: (state) => state.activeLoop,
                                      builder: (context, activeLoop) {
                                        return ElevatedButton(
                                          key: tutorialKeyLoopEnd,
                                          onPressed: (activeLoop != null)
                                              ? () => _onSetLoopEnd(context)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            minimumSize: const Size(0, 36),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: AutoSizeText(
                                            context.l10n.setLoopEnd,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            minFontSize: 12,
                                            maxFontSize: 24,
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return BlocSelector<
                              SongCubit,
                              SongState,
                              List<Loop>
                            >(
                              selector: (state) => state.song.loops,
                              builder: (context, loops) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  child:
                                      BlocSelector<
                                        PremiumSubscriptionCubit,
                                        PremiumSubscriptionState,
                                        bool
                                      >(
                                        selector: (state) =>
                                            state.hasWeeklySubscription ||
                                            state.hasYearlySubscription ||
                                            state.hasLifetimePurchase,
                                        builder: (context, hasPremium) {
                                          Widget buildItem(int index) =>
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                key: ValueKey(loops[index].id),
                                                child: LoopTile(
                                                  index: index,
                                                  loop: loops[index],
                                                  isSelected:
                                                      loops[index] ==
                                                      context
                                                          .read<SongCubit>()
                                                          .state
                                                          .activeLoop,
                                                  isLocked:
                                                      !hasPremium && index > 0,
                                                  onTap: (loop) => context
                                                      .read<SongCubit>()
                                                      .selectLoop(loop),
                                                  onDelete: (loop) {
                                                    AppAnalytics.trackEvent(
                                                      AppAnalytics
                                                          .clickDeleteLoop,
                                                    );
                                                    context
                                                        .read<SongCubit>()
                                                        .deleteLoop(loop);
                                                  },
                                                  onPlay: (loop) {
                                                    AppAnalytics.trackEvent(
                                                      AppAnalytics
                                                          .clickPlayLoop,
                                                    );
                                                    context
                                                        .read<SongCubit>()
                                                        .togglePlayLoop(loop);
                                                  },
                                                  onPause: (loop) {
                                                    AppAnalytics.trackEvent(
                                                      AppAnalytics
                                                          .clickStopLoop,
                                                    );
                                                    context
                                                        .read<SongCubit>()
                                                        .pauseLoop();
                                                  },
                                                  onUpdate: (loop) {
                                                    AppAnalytics.trackEvent(
                                                      AppAnalytics
                                                          .clickUpdateLoop,
                                                    );
                                                    context
                                                        .read<SongCubit>()
                                                        .updateLoop(loop);
                                                  },
                                                  onLockedTap: () =>
                                                      _presentLoopPaywall(
                                                        context,
                                                      ),
                                                ),
                                              );

                                          if (!hasPremium) {
                                            // Drag-to-reorder is a premium
                                            // feature — non-premium users only
                                            // have access to loop #0 anyway,
                                            // so reordering is meaningless.
                                            return ListView.builder(
                                              controller: _loopListController,
                                              padding: const EdgeInsets.only(
                                                bottom: 174,
                                              ),
                                              itemBuilder: (context, index) =>
                                                  buildItem(index),
                                              itemCount: loops.length,
                                            );
                                          }

                                          return ReorderableListView.builder(
                                            onReorder: (oldIndex, newIndex) {
                                              // ReorderableListView reports an
                                              // insertion index that is offset
                                              // by one when moving an item down.
                                              var targetIndex = newIndex;
                                              if (oldIndex < targetIndex) {
                                                targetIndex -= 1;
                                              }

                                              AppAnalytics.trackEvent(
                                                AppAnalytics.clickReorderLoops,
                                              );

                                              final List<Loop> newLoops =
                                                  List<Loop>.from(loops);
                                              final Loop item = newLoops
                                                  .removeAt(oldIndex);
                                              newLoops.insert(targetIndex, item);

                                              for (
                                                var i = 0;
                                                i < newLoops.length;
                                                i++
                                              ) {
                                                newLoops[i] = newLoops[i]
                                                    .copyWith(orderNumber: i);
                                              }

                                              context
                                                  .read<SongCubit>()
                                                  .updateLoopOrder(newLoops);
                                            },
                                            scrollController:
                                                _loopListController,
                                            padding: const EdgeInsets.only(
                                              bottom: 174,
                                            ),
                                            itemBuilder: (context, index) =>
                                                buildItem(index),
                                            itemCount: loops.length,
                                          );
                                        },
                                      ),
                                );
                              },
                            );
                          },
                          childCount: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => _onAddLoop(context),
                  icon: const Icon(Icons.add),
                  label: Text(
                    context.l10n.addLoop,
                    style: context.bodyLargeDarkBold,
                  ),
                  key: tutorialKeyLoopAdd,
                  extendedPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
          }
        },
      ),
    );
  }

  Future<void> _onTapDeleteSong(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickDeleteSong);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        elevation: 24, // Adds a more prominent shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        title: Text(context.l10n.deleteSongLoops),
        content: Text(
          context.l10n.deleteSongLoopsDescription,
        ),

        actions: [
          ElevatedButton.icon(
            icon: const Icon(
              Icons.delete,
              color: AppColors.onError,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            label: Text(context.l10n.delete),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );

    if (result != null && result && context.mounted) {
      context.read<SongCubit>().deleteSong();
      Navigator.of(context).pop();
    }
  }

  Future<void> _showEditSongDialog(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickEditSong);
    final songCubit = context.read<SongCubit>();
    final currentSong = songCubit.state.song;

    final result = await showDialog<({String title, String artist, int? bpm})>(
      context: context,
      builder: (dialogContext) {
        final titleController = TextEditingController(text: currentSong.title);
        final artistController = TextEditingController(
          text: currentSong.artist,
        );
        final bpmController = TextEditingController(
          text: currentSong.bpm?.toString() ?? '',
        );

        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              elevation: 24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              title: Text(dialogContext.l10n.editSong),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: dialogContext.l10n.editSongTitle,
                        errorText: titleController.text.trim().isEmpty
                            ? dialogContext.l10n.editSongTitleRequired
                            : null,
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: artistController,
                      decoration: InputDecoration(
                        labelText: dialogContext.l10n.editSongArtist,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bpmController,
                      decoration: const InputDecoration(
                        labelText: 'BPM',
                        hintText: '120',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimaryContainer,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dialogContext.l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () {
                          final bpmText = bpmController.text.trim();
                          final bpm = bpmText.isEmpty
                              ? null
                              : int.tryParse(bpmText);
                          Navigator.of(dialogContext).pop((
                            title: titleController.text.trim(),
                            artist: artistController.text.trim(),
                            bpm: bpm,
                          ));
                        },
                  child: Text(dialogContext.l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && context.mounted) {
      songCubit.updateSongDetails(
        title: result.title,
        artist: result.artist,
        bpm: result.bpm,
      );
    }
  }

  Future<void> _onSetLoopStart(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickSetLoopStart);

    final activeLoop = context.read<SongCubit>().state.activeLoop;

    if (activeLoop == null) {
      // check if user has premium
      final premiumSubscriptionCubit = context.read<PremiumSubscriptionCubit>();

      if (!context.mounted) return;

      if (premiumSubscriptionCubit.hasPremium ||
          context.read<SongCubit>().state.song.loops.isEmpty) {
        context.read<SongCubit>().addLoop();

        if (context.mounted) {
          context.read<SongCubit>().setLoopStart();
        }
      } else {
        await context.read<PremiumSubscriptionCubit>().presentPaywall(
          source: 'song_loops',
        );
      }
    } else {
      final loopEnd = activeLoop.end;
      if (loopEnd != null) {
        final currentPosition = await context.read<SongCubit>().position;
        if (currentPosition >= loopEnd && context.mounted) {
          SnackbarHelper.showError(
            context,
            context.l10n.startPositionMustBeBeforeEndPosition,
          );
          return;
        }
      }

      if (!context.mounted) return;

      context.read<SongCubit>().setLoopStart();
    }
  }

  Future<void> _onSetLoopEnd(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickSetLoopEnd);

    final activeLoop = context.read<SongCubit>().state.activeLoop;

    if (activeLoop == null) {
      SnackbarHelper.showError(context, context.l10n.pleaseSelectLoop);
      return;
    }

    final currentPosition = await context.read<SongCubit>().position;

    final loopStart = activeLoop.start;

    if (!context.mounted) return;

    // if active loop was set and current position is after start, set end
    if (loopStart != null && currentPosition > loopStart) {
      context.read<SongCubit>().setLoopEnd();
      // if active loop was set and current position is before start, show error
    } else if (loopStart != null && currentPosition < loopStart) {
      SnackbarHelper.showError(
        context,
        context.l10n.endPositionMustBeAfterStartPosition,
      );
    } else {
      // No start position set yet, so it's safe to set end
      context.read<SongCubit>().setLoopEnd();
    }
  }

  void createTutorial(BuildContext context) {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(context),
      colorShadow: AppColors.primaryContainer,
      opacityShadow: 0.95,
      onFinish: () => context.read<SongCubit>().updateTutorialCompleted(),
      onClickTarget: (target) {},
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
      onSkip: () {
        AppAnalytics.trackEvent(AppAnalytics.clickSkipTutorial);
        context.read<SongCubit>().updateTutorialCompleted();
        return true;
      },
    );
  }

  List<TargetFocus> _createTargets(BuildContext context) {
    final List<TargetFocus> targets = [
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "Waveform",
        keyTarget: tutorialKeyWaveform,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            builder: (context, controller) => TutorialItem(
              title: context.l10n.tutorialNavigateThroughSong,
              content: context.l10n.tutorialNavigateThroughSongDescription,
              onNext: () => controller.next(),
            ),
          ),
        ],
      ),
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "SongController",
        keyTarget: tutorialKeySongController,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            builder: (context, controller) => Center(
              child: TutorialItem(
                title: context.l10n.tutorialPlayAndPauseSong,
                content: context.l10n.tutorialPlayAndPauseSongDescription,
                onNext: () => controller.next(),
                onPrevious: () => controller.previous(),
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "LoopTimeline",
        keyTarget: tutorialKeyLoopTimeline,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            builder: (context, controller) => TutorialItem(
              title: context.l10n.tutorialJumpToLoop,
              content: context.l10n.tutorialJumpToLoopDescription,
              onNext: () => controller.next(),
              onPrevious: () => controller.previous(),
            ),
          ),
        ],
      ),
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "LoopStart",
        keyTarget: tutorialKeyLoopStart,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => TutorialItem(
              title: context.l10n.tutorialSetLoopStart,
              content: context.l10n.tutorialSetLoopStartDescription,
              onNext: () => controller.next(),
              onPrevious: () => controller.previous(),
            ),
          ),
        ],
      ),
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "LoopEnd",
        keyTarget: tutorialKeyLoopEnd,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => TutorialItem(
              title: context.l10n.tutorialSetLoopEnd,
              content: context.l10n.tutorialSetLoopEndDescription,
              onNext: () => controller.next(),
              onPrevious: () => controller.previous(),
            ),
          ),
        ],
      ),
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "LoopActivate",
        keyTarget: tutorialKeyLoopActivate,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => TutorialItem(
              title: context.l10n.tutorialActivateLoop,
              content: context.l10n.tutorialActivateLoopDescription,
              onNext: () => controller.next(),
              onPrevious: () => controller.previous(),
            ),
          ),
        ],
      ),
      TargetFocus(
        alignSkip: Alignment.topRight,
        identify: "LoopAdd",
        keyTarget: tutorialKeyLoopAdd,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => TutorialItem(
              title: context.l10n.tutorialAddLoop,
              content: context.l10n.tutorialAddLoopDescription,
              onNext: () => controller.next(),
              onPrevious: () => controller.previous(),
              isLast: true,
            ),
          ),
        ],
      ),
    ];

    return targets;
  }

  void showTutorial() {
    AppAnalytics.trackEvent(AppAnalytics.clickShowTutorial);
    tutorialCoachMark.show(context: context);
  }

  Future<void> _presentLoopPaywall(BuildContext context) async {
    await context.read<PremiumSubscriptionCubit>().presentPaywall(
      source: 'song_loops',
    );
  }

  /// If user already has added one loop, show paywall if not already purchased
  Future<void> _onAddLoop(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickAddLoop);

    final premiumSubscriptionCubit = context.read<PremiumSubscriptionCubit>();

    if (!context.mounted) return;

    if (premiumSubscriptionCubit.hasPremium ||
        context.read<SongCubit>().state.song.loops.isEmpty) {
      context.read<SongCubit>().addLoop();
    } else {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_loops',
      );
    }
  }

  Future<void> _onToggleLoopMode(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickToggleLoopMode);

    final state = context.read<SongCubit>().state;

    if (state.activeLoop != null) {
      context.read<SongCubit>().toggleLoopMode();
    } else {
      // if only one loop exists, select it
      if (state.song.loops.length == 1) {
        await context.read<SongCubit>().selectLoop(state.song.loops.first);
      } else {
        SnackbarHelper.showError(context, context.l10n.pleaseSelectLoop);
      }
    }
  }
}

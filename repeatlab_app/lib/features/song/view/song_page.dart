import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/core/utils/snackbar_helper.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/song/cubit/song_cubit.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';
import 'package:repeatlab/features/song/widgets/loop_timeline.dart';
import 'package:repeatlab/features/song/widgets/tutorial_item.dart';
import 'package:repeatlab/features/song/widgets/wave_form_soloud.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wiredash/wiredash.dart';

class SongPage extends StatelessWidget {
  final Song song;

  const SongPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SongCubit(
        songRepository: context.read<SongRepository>(),
        localConfigRepository: context.read<LocalConfigRepository>(),
        crashReportingRepository: context.read<CrashReportingRepository>(),
        soloud: SoLoud.instance,
        song: song,
      )..initSong(),
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

class _SongViewState extends State<_SongView> {
  Duration _currentPlayerPosition = Duration.zero;

  StreamSubscription<Duration>? _positionSubscription;

  final ScrollController _loopListController = ScrollController();

  late TutorialCoachMark tutorialCoachMark;

  /// Tutorial keys
  GlobalKey tutorialKeyWaveform = GlobalKey();
  GlobalKey tutorialKeySongController = GlobalKey();
  GlobalKey tutorialKeyLoopTimeline = GlobalKey();
  GlobalKey tutorialKeyLoopStart = GlobalKey();
  GlobalKey tutorialKeyLoopEnd = GlobalKey();
  GlobalKey tutorialKeyLoopActivate = GlobalKey();
  GlobalKey tutorialKeyLoopAdd = GlobalKey();

  @override
  void initState() {
    super.initState();

    _positionSubscription =
        context.read<SongCubit>().positionStream.listen((position) {
      setState(() {
        _currentPlayerPosition = position;
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _loopListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SongCubit, SongState>(
      listener: (context, state) {
        if (state.status == SongStatus.loadSuccess) {
          createTutorial(context);

          if (!state.isTutorialCompleted) {
            showTutorial();
          }
        } else if (state.status == SongStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Unknown error')),
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
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case SongStatus.loading:
            return const Scaffold(body: Center(child: Loading()));
          case SongStatus.loadError:
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.song.title),
              ),
              body: Center(
                child: Text(
                  'Error loading song: ${state.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          case SongStatus.loadSuccess:
          case SongStatus.songDeleted:
          case SongStatus.error:
          case SongStatus.loopAdded:
          case SongStatus.updated:
          case SongStatus.loopDeleted:
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.song.title),
                actions: [
                  IconButton(
                    onPressed: () => showTutorial(),
                    icon: const Icon(Icons.help_outline),
                  ),
                  // add pop up menu
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.feedback),
                            SizedBox(width: 8),
                            Text('Report Bug & Feedback'),
                          ],
                        ),
                        onTap: () => Wiredash.of(context)
                            .show(inheritMaterialTheme: true),
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete Song'),
                          ],
                        ),
                        onTap: () => _onTapDeleteSong(context),
                      ),
                    ],
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => context.read<SongCubit>().addLoop(),
                icon: const Icon(Icons.add),
                label: const Text('Add Loop'),
                key: tutorialKeyLoopAdd,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (state.data != null)
                      WaveFormSoLoud(
                        key: tutorialKeyWaveform,
                        data: state.data!,
                        duration: state.song.duration,
                        currentPosition: _currentPlayerPosition,
                        onStartDrag: () =>
                            context.read<SongCubit>().pauseSong(),
                        onPositionChanged: (position) =>
                            context.read<SongCubit>().updatePosition(position),
                        loops: state.song.loops,
                      ),
                    const SizedBox(height: 8),
                    LoopTimeline(
                      key: tutorialKeyLoopTimeline,
                      loops: state.song.loops,
                      songDuration: state.song.duration,
                      currentPosition: _currentPlayerPosition,
                      onLoopTap: (loop) =>
                          context.read<SongCubit>().playLoop(loop),
                      onPreviousLoop: () =>
                          context.read<SongCubit>().previousLoop(),
                      onNextLoop: () => context.read<SongCubit>().nextLoop(),
                      hasMoreThan1Loop: state.song.loops.length > 1,
                      onSeek: (position) =>
                          context.read<SongCubit>().updatePosition(position),
                    ),
                    const SizedBox(height: 12),
                    _SongController(
                      key: tutorialKeySongController,
                      currentPlayerPosition: _currentPlayerPosition,
                      isLoopModeEnabled: state.isLoopModeEnabled,
                      activeLoop: state.activeLoop,
                      songDuration: state.song.duration,
                    ),
                    const Divider(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Loops',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          key: tutorialKeyLoopStart,
                          onPressed: (state.activeLoop != null)
                              ? () =>
                                  _onSetLoopStart(context, state.activeLoop!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const FittedBox(child: Text('Set Loop Start')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: tutorialKeyLoopEnd,
                          onPressed: (state.activeLoop != null)
                              ? () => _onSetLoopEnd(context, state.activeLoop!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const FittedBox(child: Text('Set Loop End')),
                        ),
                        const Spacer(),
                        CupertinoSwitch(
                          key: tutorialKeyLoopActivate,
                          thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.disabled)) {
                              return const Icon(Icons.close);
                            }
                            return const Icon(Icons.loop_rounded);
                          }),
                          activeTrackColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          value: state.isLoopModeEnabled,
                          onChanged: (state.activeLoop != null)
                              ? (value) =>
                                  context.read<SongCubit>().toggleLoopMode()
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: _loopListController,
                        separatorBuilder: (context, index) => const SizedBox(
                          height: 8,
                        ),
                        itemBuilder: (context, index) => LoopTile(
                          index: index,
                          loop: state.song.loops[index],
                          isSelected:
                              state.song.loops[index] == state.activeLoop,
                          isPaused: context.read<SongCubit>().isPaused,
                          onTap: (loop) =>
                              context.read<SongCubit>().selectLoop(loop),
                          onDelete: (loop) =>
                              context.read<SongCubit>().deleteLoop(loop),
                          onPlay: (loop) =>
                              context.read<SongCubit>().playLoop(loop),
                          onPause: (loop) =>
                              context.read<SongCubit>().pauseLoop(loop),
                          onUpdate: (loop) =>
                              context.read<SongCubit>().updateLoop(loop),
                        ),
                        itemCount: state.song.loops.length,
                      ),
                    ),
                    const SizedBox(height: 58),
                  ],
                ),
              ),
            );
        }
      },
    );
  }

  Future<void> _onTapDeleteSong(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 24, // Adds a more prominent shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        title: const Text('Delete Song & Loops'),
        content: const Text(
          "Are you sure you want to delete this song and all attached loops? This can't be undone.",
        ),
        actions: [
          ElevatedButton.icon(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            label: const Text('Delete'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && result && context.mounted) {
      context.read<SongCubit>().deleteSong();
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSetLoopStart(BuildContext context, Loop activeLoop) async {
    if (activeLoop.end != null &&
        context.read<SongCubit>().currentPosition < activeLoop.end!) {
      context.read<SongCubit>().setLoopStart();
    } else if (activeLoop.end != null) {
      SnackbarHelper.showError(
        context,
        'Start position must be before end position.',
      );
    } else {
      // No end position set yet, so it's safe to set start
      context.read<SongCubit>().setLoopStart();
    }
  }

  Future<void> _onSetLoopEnd(BuildContext context, Loop activeLoop) async {
    if (activeLoop.start != null &&
        context.read<SongCubit>().currentPosition > activeLoop.start!) {
      context.read<SongCubit>().setLoopEnd();
    } else if (activeLoop.start != null) {
      SnackbarHelper.showError(
        context,
        'End position must be after start position.',
      );
    } else {
      // No start position set yet, so it's safe to set end
      context.read<SongCubit>().setLoopEnd();
    }
  }

  void createTutorial(BuildContext context) {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(context),
      colorShadow: Theme.of(context).colorScheme.primaryContainer,
      opacityShadow: 0.95,
      onFinish: () => context.read<SongCubit>().updateTutorialCompleted(),
      onClickTarget: (target) {},
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
      onSkip: () {
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
              title: "Navigate through the song with dragging and dropping",
              content:
                  "Use your fingers to drag and drop the whole song to the left or right",
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
                title: "Play and pause the whole song or an activted loop",
                content:
                    "Use your fingers to drag and drop the whole song to the left or right",
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
              title: "See and jump to loops",
              content:
                  "Your loops will be displayed here. You can jump to them by tapping on them.",
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
            builder: (context, controller) => TutorialItem(
              title: "Set the start position of the loop",
              content:
                  "Use your fingers to drag and drop the whole song to the left or right",
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
            builder: (context, controller) => TutorialItem(
              title: "Set the end position of the loop",
              content:
                  "Use your fingers to drag and drop the whole song to the left or right",
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
            builder: (context, controller) => TutorialItem(
              title: "Activate the loop mode for selected loop",
              content:
                  "If you want to play the loop, you have to activate the loop mode. If it's disabled, the whole song will be played.",
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
              title: "Add a new loop",
              content:
                  "You can add a new loop and activate it by tapping on it.",
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
    tutorialCoachMark.show(context: context);
  }
}

class _SongController extends StatelessWidget {
  final Duration currentPlayerPosition;
  final Duration songDuration;
  final bool isLoopModeEnabled;
  final Loop? activeLoop;

  const _SongController({
    required this.currentPlayerPosition,
    required this.isLoopModeEnabled,
    required this.activeLoop,
    required this.songDuration,
    required super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currentPlayerPosition.toFormattedString(),
          ),
          // back 10sec
          IconButton(
            onPressed: () => context.read<SongCubit>().back(10),
            icon: const Icon(Icons.replay_10_rounded),
          ),
          IconButton(
            iconSize: 36,
            onPressed: () {
              if (context.read<SongCubit>().isPaused) {
                if (isLoopModeEnabled == true) {
                  context.read<SongCubit>().resumeLoop(activeLoop!);
                } else {
                  context.read<SongCubit>().resumeSong();
                }
              } else {
                if (isLoopModeEnabled == true) {
                  context.read<SongCubit>().pauseLoop(activeLoop!);
                } else {
                  context.read<SongCubit>().pauseSong();
                }
              }
            },
            icon: Icon(
              context.read<SongCubit>().isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
          ),
          IconButton(
            onPressed: () => context.read<SongCubit>().forward(10),
            icon: const Icon(Icons.forward_10_rounded),
          ),
          Text(songDuration.toFormattedString()),
        ],
      ),
    );
  }
}

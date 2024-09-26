import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/models/loop.dart';
import 'package:looplab/models/song.dart';
import 'package:looplab/song/widgets/wave_form_soloud.dart';
import 'package:uuid/uuid.dart';

class SongPage extends StatefulWidget {
  final Song song;

  const SongPage({
    super.key,
    required this.song,
  });

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  late PlayerController _playerController;
  late StreamSubscription<PlayerState> _subscription;
  late StreamSubscription<int> _positionSubscription;

  Duration _currentPlayerPosition = Duration.zero;

  bool _isLoading = true;

  final List<Loop> _loops = [];
  Loop? _currentLoop;

  Uint8List? _bytes;

  Float32List? _data;
  Float32List? _playedData;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _playerController = PlayerController();

    _subscription = _playerController.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.initialized:
          log('PlayerState.initialized');
        case PlayerState.playing:
          log('PlayerState.playing');
        case PlayerState.paused:
          log('PlayerState.paused');
        case PlayerState.stopped:
          log('PlayerState.stopped');
      }

      setState(() {});
    });

    _positionSubscription =
        _playerController.onCurrentDurationChanged.listen((currentPosition) {
      setState(
        () {
          _currentPlayerPosition = Duration(milliseconds: currentPosition);

          /* _playedData = await SoLoud.instance.readSamplesFromMem(
            _bytes!,
            200 * 5,
            endTime: _currentPlayerPosition.inSeconds.toDouble(),
            average: true,
          ); */
        },
      );
    });

    try {
      await _playerController.preparePlayer(
        path: widget.song.path,
        volume: 1.0,
        noOfSamples: 200,
      );

      final f = File(widget.song.path);
      _bytes = f.readAsBytesSync();

      if (_bytes == null) {
        return;
      }

      final data = await SoLoud.instance.readSamplesFromMem(
        _bytes!,
        200 * 10,
      );

      setState(() {
        _isLoading = false;
        _data = data;
      });
    } catch (e) {
      print('Error initializing player: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    _subscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Artist: ${widget.song.artist}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                /* AudioFileWaveforms(
                  size: Size(MediaQuery.sizeOf(context).width - 32, 100.0),
                  playerController: _playerController,
                  playerWaveStyle: const PlayerWaveStyle(
                    liveWaveColor: Colors.blueAccent,
                    spacing: 6,
                  ),
                ), */
                if (_data != null)
                  WaveFormSoLoud(
                    data: _data!,
                    duration: widget.song.duration,
                    currentPosition: _currentPlayerPosition,
                    onPositionChanged: (position) =>
                        setState(() => _currentPlayerPosition = position),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_currentPlayerPosition.toFormattedString()),
                    Text(widget.song.duration.toFormattedString()),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _onPreviousLoop(),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    IconButton(
                      onPressed: () => _onPlay(),
                      icon: Icon(
                        !_playerController.playerState.isPlaying
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _onNextLoop(),
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _onSetLoopStart(),
                      child: const Text('Set Loop Start'),
                    ),
                    ElevatedButton(
                      onPressed: () => _onSetLoopEnd(),
                      child: const Text('Set Loop End'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: _loops
                      .map(
                        (loop) => ListTile(
                          selectedColor: Colors.blue,
                          selected: loop == _currentLoop,
                          onTap: () => _onSelectLoop(loop),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.loop),
                          title: Text(loop.name),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Duration(microseconds: loop.microsecondStart)
                                    .toFormattedString(),
                              ),
                              Text(
                                Duration(microseconds: loop.microsecondEnd)
                                    .toFormattedString(),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }

  void _onPreviousLoop() {}

  void _onPlay() {
    if (_playerController.playerState.isPlaying) {
      _playerController.pausePlayer();
    } else if (_playerController.playerState.isStopped) {
      _playerController.seekTo(_currentPlayerPosition.inMilliseconds);
    } else {
      _playerController.startPlayer(finishMode: FinishMode.pause);
    }
    setState(() {});
  }

  void _onNextLoop() {}

  void _onSetLoopStart() {
    _playerController.pausePlayer();

    final loop = Loop(
      id: const Uuid().v4(),
      name: 'Loop ${_loops.length + 1}',
      songId: widget.song.id,
      microsecondStart: _currentPlayerPosition.inMicroseconds,
      microsecondEnd: _currentPlayerPosition.inMicroseconds,
    );

    _loops.add(loop);

    setState(() => _currentLoop = loop);
  }

  void _onSetLoopEnd() {
    _playerController.pausePlayer();

    if (_currentLoop == null) {
      return;
    }

    final updatedLoop = _currentLoop!.copyWith(
      microsecondEnd: _currentPlayerPosition.inMicroseconds,
    );

    setState(() => _currentLoop = updatedLoop);

    // update the loop in the list
    _loops[_loops.indexOf(_currentLoop!)] = updatedLoop;

    // get current position
  }

  void _onSelectLoop(Loop loop) {
    setState(() => _currentLoop = loop);
  }
}

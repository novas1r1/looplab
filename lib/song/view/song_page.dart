import 'dart:async';
import 'dart:io';

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
  AudioSource? _source;
  SoundHandle? _handle;

  Duration _currentPlayerPosition = Duration.zero;

  bool _isLoading = true;

  final _loops = <Loop>[];
  Loop? _currentLoop;

  Uint8List? _bytes;

  Float32List? _data;
  Float32List? _playedData;

  Timer? _positionTimer;

  Duration? _startPosition;
  Duration? _endPosition;

  bool _loopActive = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final soloud = SoLoud.instance;

    _source = await soloud.loadFile(widget.song.path);
    _handle = await soloud.play(_source!);

    // Start the position timer
    _startPositionTimer();

    try {
      final file = File(widget.song.path);
      _bytes = file.readAsBytesSync();

      if (_bytes == null) {
        return;
      }

      final data = await soloud.readSamplesFromMem(
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

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_handle != null) {
        final position = SoLoud.instance.getPosition(_handle!);
        setState(() {
          _currentPlayerPosition = position;
        });

        // if loop is active, check if the current position is greater than the end position
        if (_loopActive && _endPosition != null) {
          if (position >= _endPosition!) {
            SoLoud.instance.setPause(_handle!, true);
            SoLoud.instance.seek(_handle!, _startPosition!);
            SoLoud.instance.setPause(_handle!, false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();

    if (_handle != null) {
      SoLoud.instance.stop(_handle!);
      SoLoud.instance.disposeSource(_source!);
    }
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
                if (_data != null)
                  WaveFormSoLoud(
                    data: _data!,
                    duration: widget.song.duration,
                    currentPosition: _currentPlayerPosition,
                    onStartDrag: () => SoLoud.instance.setPause(_handle!, true),
                    onPositionChanged: (position) => setState(() {
                      // stop the sound
                      _currentPlayerPosition = position;
                      SoLoud.instance.seek(_handle!, position);
                    }),
                    loopStartPosition: _startPosition,
                    loopEndPosition: _endPosition,
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
                        SoLoud.instance.getPause(_handle!)
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
                          leading: IconButton(
                            onPressed: () => _setAndPlayLoop(loop),
                            icon: const Icon(Icons.loop),
                          ),
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

  Future<void> _onPlay() async {
    if (_handle != null) {
      if (SoLoud.instance.getPause(_handle!)) {
        SoLoud.instance.setPause(_handle!, false);
      } else {
        SoLoud.instance.setPause(_handle!, true);
      }
    } else {
      _handle = await SoLoud.instance.play(_source!);
    }

    setState(() {});
  }

  void _onNextLoop() {}

  void _onSetLoopStart() {
    Loop? loop = _currentLoop;

    // if loop is null, create a new one
    if (_currentLoop == null) {
      loop = Loop(
        id: const Uuid().v4(),
        name: 'Loop ${_loops.length + 1}',
        songId: widget.song.id,
        microsecondStart: _currentPlayerPosition.inMicroseconds,
        microsecondEnd: _currentPlayerPosition.inMicroseconds,
      );

      _loops.add(loop);
      setState(() => _currentLoop = loop);
    } else {
      final updatedLoop = _currentLoop!.copyWith(
        microsecondStart: _currentPlayerPosition.inMicroseconds,
      );

      setState(() => _currentLoop = updatedLoop);

      final currentLoopIndex =
          _loops.indexWhere((loop) => loop.id == _currentLoop?.id);

      if (currentLoopIndex == -1) return;

      // update the loop in the list
      setState(() {
        _loops[currentLoopIndex] = updatedLoop;
        _startPosition = Duration(microseconds: updatedLoop.microsecondStart);
      });
    }
  }

  void _onSetLoopEnd() {
    if (_currentLoop == null) return;

    final updatedLoop = _currentLoop!.copyWith(
      microsecondEnd: _currentPlayerPosition.inMicroseconds,
    );

    setState(() => _currentLoop = updatedLoop);

    final currentLoopIndex =
        _loops.indexWhere((loop) => loop.id == _currentLoop?.id);

    if (currentLoopIndex == -1) return;

    // update the loop in the list
    setState(() {
      _loops[currentLoopIndex] = updatedLoop;
      _endPosition = Duration(microseconds: updatedLoop.microsecondEnd);
    });

    // get current position
  }

  void _onSelectLoop(Loop loop) {
    setState(() => _currentLoop = loop);
  }

  void _setAndPlayLoop(Loop loop) {
    SoLoud.instance.setPause(_handle!, true);

    final startPositionDuration = Duration(microseconds: loop.microsecondStart);

    // seek start
    if (_handle == null) return;

    SoLoud.instance.seek(_handle!, startPositionDuration);
    SoLoud.instance.setPause(_handle!, false);

    // scroll to position
    setState(() {
      _currentPlayerPosition = startPositionDuration;
      _loopActive = true;
    });
  }
}

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:looplab/models/song.dart';

class SongPage extends StatefulWidget {
  final Song song;

  const SongPage({super.key, required this.song});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  late PlayerController _playerController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _playerController = PlayerController();

    try {
      await _playerController.preparePlayer(
        path: widget.song.path,
        volume: 1.0,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing player: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Artist: ${widget.song.artist}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width, 100.0),
                    playerController: _playerController,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: const PlayerWaveStyle(
                      liveWaveColor: Colors.blueAccent,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_playerController.playerState.isPlaying) {
                          _playerController.pausePlayer();
                        } else {
                          _playerController.startPlayer();
                        }
                        setState(() {});
                      },
                      child: Text(
                        _playerController.playerState.isPlaying
                            ? 'Pause'
                            : 'Play',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

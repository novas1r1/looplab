import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/widgets/audio_waveform_widget.dart';

class AudioWave extends StatelessWidget {
  const AudioWave({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 150.0,
        width: double.maxFinite,
        child: BlocBuilder<SongCubit, SongState>(
          builder: (context, state) {
            if (state.error != null) {
              return Center(child: Text('Error: ${state.error}'));
            }
            final progress = state.waveformProgress?.progress ?? 0.0;
            final waveform = state.waveformProgress?.waveform;
            if (waveform == null) {
              return Center(child: Text('${(100 * progress).toInt()}%'));
            }
            return AudioWaveformWidget(
              waveform: waveform,
              start: Duration.zero,
              duration: waveform.duration,
              currentPosition:
                  Duration(milliseconds: (progress * waveform.duration.inMilliseconds).toInt()),
              onPositionChanged: (position) {
                // Handle position change
              },
              onStartDrag: () {
                // Handle drag start
              },
              loops: state.song.loops,
              strokeWidth: 1.0,
              pixelsPerStep: 5.0,
            );
          },
        ),
      ),
    );
  }
}

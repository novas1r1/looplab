import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';

class RecordingCountdownOverlay extends StatelessWidget {
  const RecordingCountdownOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecordingCubit, RecordingState, int?>(
      selector: (state) =>
          state.status == RecordingStatus.countdown
              ? state.countdownValue
              : null,
      builder: (context, countdownValue) {
        if (countdownValue == null) return const SizedBox.shrink();

        return ColoredBox(
          color: Colors.black54,
          child: Center(
            child: Text(
              '$countdownValue',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 96,
              ),
            ),
          ),
        );
      },
    );
  }
}

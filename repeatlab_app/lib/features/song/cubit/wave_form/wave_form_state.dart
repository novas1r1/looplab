part of 'wave_form_cubit.dart';

@MappableClass()
class WaveFormState with WaveFormStateMappable {
  final WaveFormStateStatus status;

  final Float32List? waveformData;
  final double waveformWidth;
  final double screenWidth;

  final Duration duration;
  final Duration currentPosition;

  final List<Loop> loops;

  final Exception? error;

  const WaveFormState({
    this.status = WaveFormStateStatus.loading,
    this.waveformData,
    this.duration = Duration.zero,
    this.currentPosition = Duration.zero,
    this.waveformWidth = 0.0,
    this.screenWidth = 0.0,
    this.loops = const [],
    this.error,
  });
}

enum WaveFormStateStatus {
  loading,
  loaded,
  updated,
  error,
}

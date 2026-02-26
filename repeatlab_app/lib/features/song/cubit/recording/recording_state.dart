part of 'recording_cubit.dart';

@MappableEnum()
enum RecordingStatus {
  idle,
  permissionDenied,
  countdown,
  recording,
  saving,
  error,
}

@MappableClass()
class RecordingState with RecordingStateMappable {
  final RecordingStatus status;
  final List<RecordingLayer> layers;
  final int? countdownValue;
  final String? activeLayerId;
  final Duration? currentRecordingDuration;
  final String? error;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.layers = const [],
    this.countdownValue,
    this.activeLayerId,
    this.currentRecordingDuration,
    this.error,
  });
}

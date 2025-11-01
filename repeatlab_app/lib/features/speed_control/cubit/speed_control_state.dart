part of 'speed_control_cubit.dart';

@MappableClass()
class SpeedControlState with SpeedControlStateMappable {
  final TempoMode tempoMode;
  final double speedMultiplier;

  final int? originalBpm;
  final int? currentBpm;

  // max 0.5 from original bpm
  final int? minBpm;

  // max 2.0 from original bpm
  final int? maxBpm;

  const SpeedControlState({
    this.tempoMode = TempoMode.multiplier,
    this.speedMultiplier = 1.0,
    this.originalBpm,
    this.currentBpm,
    this.minBpm,
    this.maxBpm,
  });
}

enum TempoMode { multiplier, bpm }

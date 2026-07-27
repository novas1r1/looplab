import 'package:precise_metronome/precise_metronome.dart' as pm;

/// Thin lifecycle wrapper around the `precise_metronome` plugin.
///
/// Keeps the native plugin out of `SongCubit` so cubit tests can mock this
/// class, and centralizes clamping/unit conversion. All timing runs on the
/// native side (AVAudioEngine / Oboe) — never drive clicks from the app's
/// throttled position stream.
///
/// Subdivision is passed as `pulsesPerBeat` (1 = quarter, 2 = eighths,
/// 3 = triplets, 4 = sixteenths) so this layer does not depend on the
/// feature-level `MetronomeSubdivision` enum.
class SongMetronome {
  SongMetronome({pm.Metronome? metronome})
    : _metronome = metronome ?? pm.Metronome();

  final pm.Metronome _metronome;
  bool _initialized = false;

  /// The tempo range the native engine accepts.
  static const int minBpm = 20;
  static const int maxBpm = 400;

  bool get isRunning => _initialized && _metronome.isPlaying;

  /// Lazily initializes the native engine. Safe to call repeatedly.
  Future<void> ensureInit() async {
    if (_initialized) return;
    await _metronome.init();
    _initialized = true;
  }

  /// (Re)starts the metronome with the full configuration applied.
  ///
  /// [offsetMs] shifts the click grid relative to "now" and is normalized
  /// into one beat period, so negative nudges and offsets larger than a
  /// beat are phase-equivalent.
  Future<void> startAligned({
    required int bpm,
    required int offsetMs,
    required int beatsPerBar,
    required int beatUnit,
    required int pulsesPerBeat,
    required double volume,
  }) async {
    await ensureInit();
    if (_metronome.isPlaying) {
      await _metronome.stop();
    }
    final clampedBpm = bpm.clamp(minBpm, maxBpm).toDouble();
    await _metronome.setTempo(clampedBpm);
    await _metronome.setTimeSignature(pm.TimeSignature(beatsPerBar, beatUnit));
    await _metronome.setSubdivision(_subdivisionFromPulses(pulsesPerBeat));
    await _metronome.setVolume(volume.clamp(0.0, 1.0));

    final beatPeriodMs = (60000 / clampedBpm).round();
    final delayMs = ((offsetMs % beatPeriodMs) + beatPeriodMs) % beatPeriodMs;
    await _metronome.start(initialDelay: Duration(milliseconds: delayMs));
  }

  Future<void> stop() async {
    if (!_initialized || !_metronome.isPlaying) return;
    await _metronome.stop();
  }

  /// Live tempo change; phase-preserving on the native side.
  Future<void> setTempo(int bpm) async {
    if (!_initialized) return;
    await _metronome.setTempo(bpm.clamp(minBpm, maxBpm).toDouble());
  }

  Future<void> setVolume(double volume) async {
    if (!_initialized) return;
    await _metronome.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setTimeSignature(int beatsPerBar, int beatUnit) async {
    if (!_initialized) return;
    await _metronome.setTimeSignature(pm.TimeSignature(beatsPerBar, beatUnit));
  }

  Future<void> setSubdivision(int pulsesPerBeat) async {
    if (!_initialized) return;
    await _metronome.setSubdivision(_subdivisionFromPulses(pulsesPerBeat));
  }

  /// Shifts the click grid by [delta] while running (no-op when stopped).
  Future<void> nudge(Duration delta) async {
    if (!_initialized) return;
    await _metronome.nudge(delta);
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
    await _metronome.dispose();
  }

  static pm.Subdivision _subdivisionFromPulses(int pulsesPerBeat) {
    switch (pulsesPerBeat) {
      case 2:
        return pm.Subdivision.duple;
      case 3:
        return pm.Subdivision.triplet;
      case 4:
        return pm.Subdivision.quadruple;
      default:
        return pm.Subdivision.none;
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Interpolates the coarse audio position (raw ticks arrive every 50–250 ms)
/// into a smooth ~60 fps playhead position.
///
/// Strictly consumer-side: it wraps an existing position source and never
/// talks back to the player. Between raw ticks it predicts
/// `base + elapsed × rate`; each raw tick silently rebases the prediction.
/// A raw tick that deviates more than [seekSnapThreshold] from the prediction
/// is treated as a seek/loop-jump and snaps immediately.
///
/// The ticker runs only while [isPlaying] returns true (zero idle cost, never
/// runs in tests where nothing plays) and is created from the host `State`'s
/// [TickerProvider] so `TickerMode` mutes it offstage.
class SmoothPlayhead extends ChangeNotifier
    implements ValueListenable<Duration> {
  /// Raw deviation beyond which a tick is treated as a seek and snaps.
  static const seekSnapThreshold = Duration(milliseconds: 300);

  final bool Function() isPlaying;
  final double Function() playbackRate;
  final Duration Function() totalDuration;

  /// Visible pixels per millisecond of audio. When provided, listeners are
  /// only notified when the prediction crosses a pixel boundary, capping
  /// repaints at actual visible movement.
  final double Function()? pixelsPerMs;

  /// When true (reduce motion), raw positions pass through unsmoothed.
  final bool Function() disableAnimations;

  final ValueListenable<Duration>? _positionListenable;
  StreamSubscription<Duration>? _streamSubscription;
  late final Ticker _ticker;

  Duration _value;
  Duration _basePosition;
  Duration _baseElapsed = Duration.zero;
  Duration _lastElapsed = Duration.zero;
  int? _lastNotifiedPixel;

  SmoothPlayhead({
    required TickerProvider vsync,
    required this.isPlaying,
    required this.playbackRate,
    required this.totalDuration,
    this.pixelsPerMs,
    this.disableAnimations = _never,
    ValueListenable<Duration>? positionListenable,
    Stream<Duration>? positionStream,
  }) : assert(
         positionListenable != null || positionStream != null,
         'Provide a positionListenable or a positionStream',
       ),
       _positionListenable = positionListenable,
       _value = positionListenable?.value ?? Duration.zero,
       _basePosition = positionListenable?.value ?? Duration.zero {
    _ticker = vsync.createTicker(_onTick);
    _positionListenable?.addListener(_onListenableTick);
    _streamSubscription = positionStream?.listen(_onRawPosition);
  }

  static bool _never() => false;

  @override
  Duration get value => _value;

  void _onListenableTick() => _onRawPosition(_positionListenable!.value);

  void _onRawPosition(Duration raw) {
    if (disableAnimations() || !isPlaying()) {
      // Paused (or reduce motion): pass raw through, no prediction.
      _stopTicker();
      _basePosition = raw;
      _baseElapsed = _lastElapsed;
      _setValue(raw, force: true);
      return;
    }

    final deviation = (raw - _predict()).abs();
    _basePosition = raw;
    _baseElapsed = _lastElapsed;
    if (deviation > seekSnapThreshold) {
      // Seek or loop jump: snap immediately (backwards allowed).
      _setValue(raw, force: true);
    }
    // Otherwise rebase silently — the prediction error over one raw interval
    // is a few ms, invisible at any zoom level.
    _startTickerIfNeeded();
  }

  void _onTick(Duration elapsed) {
    _lastElapsed = elapsed;
    if (!isPlaying()) {
      _stopTicker();
      return;
    }
    _setValue(_predict());
  }

  Duration _predict() {
    final dt = _lastElapsed - _baseElapsed;
    var predicted =
        _basePosition +
        Duration(
          microseconds: (dt.inMicroseconds * playbackRate()).round(),
        );
    final total = totalDuration();
    if (total > Duration.zero && predicted > total) predicted = total;
    if (predicted < Duration.zero) predicted = Duration.zero;
    // Monotonic between raw rebases so clock jitter never renders backwards
    // (seeks bypass this via the force-snap path).
    if (predicted < _value) predicted = _value;
    return predicted;
  }

  void _setValue(Duration next, {bool force = false}) {
    _value = next;
    final ppm = pixelsPerMs?.call();
    if (ppm != null && ppm > 0) {
      final pixel = (next.inMilliseconds * ppm).round();
      if (!force && pixel == _lastNotifiedPixel) return;
      _lastNotifiedPixel = pixel;
    }
    notifyListeners();
  }

  void _startTickerIfNeeded() {
    if (_ticker.isActive) return;
    _baseElapsed = Duration.zero;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _positionListenable?.removeListener(_onListenableTick);
    _streamSubscription?.cancel();
    super.dispose();
  }
}

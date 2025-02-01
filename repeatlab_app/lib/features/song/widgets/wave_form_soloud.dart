import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/paywall/cubits/paywall_cubit.dart';
import 'package:repeatlab/features/song/widgets/wave_painter.dart';

// https://github.com/alnitak/flutter_soloud/blob/feat_waveform/example/lib/wave_data/wave_data.dart
class WaveFormSoLoud extends StatefulWidget {
  final Float32List data;
  final Duration duration;
  final Duration currentPosition;
  final void Function(Duration duration) onPositionChanged;
  final VoidCallback onStartDrag;

  final List<Loop> loops;

  const WaveFormSoLoud({
    super.key,
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.onPositionChanged,
    required this.onStartDrag,
    required this.loops,
  });

  @override
  State<WaveFormSoLoud> createState() => _WaveFormSoLoudState();
}

class _WaveFormSoLoudState extends State<WaveFormSoLoud> {
  late ScrollController _scrollController;

  double _zoomScale = 1.0;

  static const double minZoom = 0.25;
  static const double maxZoom = 5.0;
  static const double zoomStep = 0.25;

  bool _showZoomSlider = false;
  Timer? _zoomSliderTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _zoomSliderTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WaveFormSoLoud oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentPosition != oldWidget.currentPosition) {
      _updateScrollPosition();
    }
  }

  void _updateScrollPosition() {
    _scrollController.jumpTo(
      (widget.currentPosition.inMilliseconds / widget.duration.inMilliseconds) *
          widget.data.length.toDouble() *
          _zoomScale,
    );
  }

  void _zoomIn() {
    AppAnalytics.trackEvent(AppAnalytics.clickZoomIn, data: {'zoom_scale': _zoomScale});
    if (_zoomScale >= maxZoom) return;

    // Calculate the center position before zooming
    final centerPosition = _scrollController.position.pixels / _zoomScale;

    setState(() {
      _zoomScale = (_zoomScale + zoomStep).clamp(minZoom, maxZoom);
    });

    // Maintain the same center position after zooming
    _scrollController.jumpTo(centerPosition * _zoomScale);
  }

  void _zoomOut() {
    if (_zoomScale <= minZoom) return;

    // Calculate the center position before zooming
    final centerPosition = _scrollController.position.pixels / _zoomScale;

    setState(() {
      _zoomScale = (_zoomScale - zoomStep).clamp(minZoom, maxZoom);
    });

    // Maintain the same center position after zooming
    _scrollController.jumpTo(centerPosition * _zoomScale);
  }

  void _showZoomControls() {
    setState(() {
      _showZoomSlider = true;
    });

    _resetZoomTimer();
  }

  void _resetZoomTimer() {
    _zoomSliderTimer?.cancel();
    _zoomSliderTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _showZoomSlider = false;
      });
    });
  }

  void _updateZoom(double value) {
    AppAnalytics.trackEvent(AppAnalytics.clickUpdateZoom, data: {'zoom_scale': value});

    // Calculate the center position before zooming
    final centerPosition = _scrollController.position.pixels / _zoomScale;

    setState(() {
      _zoomScale = value;
    });

    // Maintain the same center position after zooming
    _scrollController.jumpTo(centerPosition * _zoomScale);

    _resetZoomTimer(); // Reset timer when user adjusts the slider
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final waveformWidth = widget.data.length.toDouble() * _zoomScale;

    return SizedBox(
      height: 132,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              // should NOT bounce
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // add padding to the left so it starts at the center
              padding: EdgeInsets.symmetric(horizontal: (width / 2) - 16),
              child: GestureDetector(
                onHorizontalDragStart: (details) => widget.onStartDrag(),
                onHorizontalDragUpdate: (details) {
                  // Update scroll position based on drag
                  final newScrollPosition = _scrollController.position.pixels - details.delta.dx;
                  _scrollController.jumpTo(
                    newScrollPosition.clamp(
                      0,
                      waveformWidth,
                    ),
                  );
                },
                onHorizontalDragEnd: (details) {
                  // Update position
                  final scrollPercentage = _scrollController.position.pixels / waveformWidth;
                  widget.onPositionChanged(
                    Duration(
                      milliseconds: (scrollPercentage * widget.duration.inMilliseconds).toInt(),
                    ),
                  );
                },
                child: SizedBox(
                  width: waveformWidth,
                  child: CustomPaint(
                    painter: WavePainter(
                      data: widget.data,
                      duration: widget.duration,
                      currentPosition: widget.currentPosition,
                      loops: widget.loops,
                      colorPlayed: Theme.of(context).colorScheme.primaryFixedDim,
                      colorUnplayed: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      zoomScale: _zoomScale,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // a vertical line at the center
          Positioned(
            left: (width / 2) - 16,
            bottom: 0,
            top: 0,
            child: Container(
              width: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          // Zoom controls
          Positioned(
            right: 8,
            top: 0,
            child: GestureDetector(
              onTap: _zoomScale < maxZoom ? () => _onZoomIn(context) : null,
              child: Icon(
                Icons.zoom_in,
                size: 24,
                color: _zoomScale < maxZoom ? Colors.white : Colors.grey,
              ),
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            top: 0,
            child: AnimatedOpacity(
              opacity: _showZoomSlider ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showZoomSlider,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackShape: const RectangularSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _zoomScale,
                    min: minZoom,
                    max: maxZoom,
                    onChanged: _updateZoom,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            child: GestureDetector(
              onTap: _zoomScale > minZoom ? () => _onZoomOut(context) : null,
              child: Icon(
                Icons.zoom_out,
                size: 24,
                color: _zoomScale > minZoom ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onZoomOut(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickZoomOut, data: {'zoom_scale': _zoomScale});

    final paywallCubit = context.read<PaywallCubit>();
    // check if user has premium subscription
    if (await paywallCubit.hasUserPurched()) {
      _zoomOut();
      _showZoomControls();
    } else {
      if (!context.mounted) return;
      context.read<PaywallCubit>().showPaywallIfNeeded();
    }
  }

  Future<void> _onZoomIn(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickZoomIn, data: {'zoom_scale': _zoomScale});

    final paywallCubit = context.read<PaywallCubit>();
    if (await paywallCubit.hasUserPurched()) {
      _zoomIn();
      _showZoomControls();
    } else {
      if (!context.mounted) return;
      context.read<PaywallCubit>().showPaywallIfNeeded();
    }
  }
}

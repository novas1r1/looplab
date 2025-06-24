/* import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';

// https://github.com/alnitak/flutter_soloud/blob/feat_waveform/example/lib/wave_data/wave_data.dart
class WaveFormSoLoud extends StatefulWidget {
  final Float32List data;
  final Duration duration;
  final Duration currentPosition;
  final void Function(Duration duration) onPositionChanged;
  final VoidCallback onStartDrag;

  final List<Loop> loops;
  final String startText;
  final String endText;

  const WaveFormSoLoud({
    super.key,
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.onPositionChanged,
    required this.onStartDrag,
    required this.loops,
    required this.startText,
    required this.endText,
  });

  @override
  State<WaveFormSoLoud> createState() => _WaveFormSoLoudState();
}

class _WaveFormSoLoudState extends State<WaveFormSoLoud> {
  static const double minZoom = 0.25;
  static const double maxZoom = 5.0;
  static const double zoomStep = 0.25;

  late ScrollController _scrollController;

  bool _isDragging = false;

  double _zoomScale = 1.0;
  bool _showZoomSlider = false;
  Timer? _zoomSliderTimer;

  ui.Image? _waveformImage;
  int? _lastDataHash;
  double? _lastZoomScale;
  Size? _lastSize;
  bool _imageDirty = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _zoomSliderTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WaveFormSoLoud oldWidget) {
    if (widget.currentPosition != oldWidget.currentPosition && !_isDragging) {
      _updateScrollPosition();
    }
    // Mark image dirty if data, zoom, or size changes
    if (widget.data.hashCode != _lastDataHash || _zoomScale != _lastZoomScale) {
      _imageDirty = true;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final waveformWidth = widget.data.length.toDouble() * _zoomScale;
    const height = 132.0;

    // Re-render waveform image if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_imageDirty ||
          _waveformImage == null ||
          _lastSize?.width != waveformWidth ||
          _lastSize?.height != height) {
        final img = await _renderWaveformImage(Size(waveformWidth, height));
        if (mounted) {
          setState(() {
            _waveformImage = img;
            _lastDataHash = widget.data.hashCode;
            _lastZoomScale = _zoomScale;
            _lastSize = Size(waveformWidth, height);
            _imageDirty = false;
          });
        }
      }
    });

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerDown: (details) => _handleDragStart(
                DragStartDetails(
                  globalPosition: details.position,
                  localPosition: details.localPosition,
                ),
              ),
              onPointerMove: (details) => _handleDragUpdate(
                DragUpdateDetails(
                  globalPosition: details.position,
                  localPosition: details.localPosition,
                  delta: details.delta,
                ),
              ),
              onPointerUp: (details) => _handleDragEnd(DragEndDetails()),
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: (width / 2) - 16),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  GestureDetector(
                    onHorizontalDragStart: _handleDragStart,
                    onHorizontalDragUpdate: _handleDragUpdate,
                    onHorizontalDragEnd: _handleDragEnd,
                    child: SizedBox(
                      width: waveformWidth,
                      height: height,
                      child: Stack(
                        children: [
                          if (_waveformImage != null)
                            RawImage(
                              image: _waveformImage,
                              fit: BoxFit.fill,
                            ),
                          // Played overlay
                          if (_waveformImage != null)
                            ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: _playedFraction(),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primaryFixedDim,
                                    BlendMode.srcATop,
                                  ),
                                  child: RawImage(
                                    image: _waveformImage,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          // Loop markers and labels overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _LoopMarkerPainter(
                                  loops: widget.loops,
                                  duration: widget.duration,
                                  zoomScale: _zoomScale,
                                  startText: widget.startText,
                                  endText: widget.endText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Center line
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

    final hasPurchased = context.read<PremiumSubscriptionCubit>().hasPremium;
    // check if user has premium subscription
    if (hasPurchased) {
      _zoomOut();
      _showZoomControls();
    } else {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PremiumScreen(),
        ),
      );
    }
  }

  void _handleDragStart(DragStartDetails details) {
    widget.onStartDrag();
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final newScrollPosition = _scrollController.position.pixels - details.delta.dx;
    final maxScroll = widget.data.length.toDouble() * _zoomScale;

    _scrollController.jumpTo(newScrollPosition.clamp(0, maxScroll));

    // Calculate and update position immediately instead of using debounce
    final scrollPercentage = _scrollController.position.pixels / maxScroll;
    final newPosition = Duration(
      milliseconds: (scrollPercentage * widget.duration.inMilliseconds).round(),
    );
    widget.onPositionChanged(newPosition);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    final maxScroll = widget.data.length.toDouble() * _zoomScale;
    final scrollPercentage = _scrollController.position.pixels / maxScroll;

    final finalPosition = Duration(
      milliseconds: (scrollPercentage * widget.duration.inMilliseconds).round(),
    );
    widget.onPositionChanged(finalPosition);
  }

  Future<void> _onZoomIn(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickZoomIn, data: {'zoom_scale': _zoomScale});

    final premiumSubscriptionCubit = context.read<PremiumSubscriptionCubit>();
    if (premiumSubscriptionCubit.hasPremium) {
      _zoomIn();
      _showZoomControls();
    } else {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PremiumScreen(),
        ),
      );
    }
  }

  void _updateScrollPosition() {
    final maxScroll = widget.data.length.toDouble() * _zoomScale;
    final scrollPercentage = widget.currentPosition.inMilliseconds / widget.duration.inMilliseconds;

    final target = scrollPercentage * maxScroll;

    // Avoid calling jumpTo for sub-pixel changes – this eliminates a lot of
    // unnecessary layout / paint work and reduces jank significantly.
    if (_scrollController.hasClients && (target - _scrollController.position.pixels).abs() < 2.0) {
      return;
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(target);
    }
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
    final centerPosition = _scrollController.position.pixels / _zoomScale;

    setState(() {
      _zoomScale = value;
    });

    // Maintain the same center position after zooming
    _scrollController.jumpTo(centerPosition * _zoomScale);

    _resetZoomTimer(); // Reset timer when user adjusts the slider
  }

  void _onScroll() {
    if (!_isDragging) return;

    final maxScroll = widget.data.length.toDouble() * _zoomScale;
    final scrollPercentage = _scrollController.position.pixels / maxScroll;

    final newPosition = Duration(
      milliseconds: (scrollPercentage * widget.duration.inMilliseconds).round(),
    );
    widget.onPositionChanged(newPosition);
  }

  double _playedFraction() {
    final durationMs = widget.duration.inMilliseconds.toDouble();
    final posMs = widget.currentPosition.inMilliseconds.toDouble();
    if (durationMs == 0) return 0;
    return (posMs / durationMs).clamp(0.0, 1.0);
  }

  Future<ui.Image> _renderWaveformImage(Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final barSpacing = _zoomScale;
    final paint = Paint()
      ..color = const Color(0xff00696e)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < widget.data.length; i++) {
      final barHeight = size.height * widget.data[i] * 2;
      final x = i * barSpacing;
      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        paint,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(size.width.ceil(), size.height.ceil());
  }
}

class _LoopMarkerPainter extends CustomPainter {
  final List<Loop> loops;
  final Duration duration;
  final double zoomScale;
  final String startText;
  final String endText;

  _LoopMarkerPainter({
    required this.loops,
    required this.duration,
    required this.zoomScale,
    required this.startText,
    required this.endText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final durationMs = duration.inMilliseconds.toDouble();
    double scaleX(double ms) => (ms / durationMs) * size.width;

    for (final loop in loops) {
      if (loop.start == null && loop.end == null) continue;

      if (loop.start != null) {
        final paintLoopStart = Paint()
          ..color = loop.color.color
          ..strokeWidth = 2;
        final xStart = scaleX(loop.start!.inMilliseconds.toDouble());
        canvas.drawLine(Offset(xStart, 0), Offset(xStart, size.height), paintLoopStart);
        canvas.drawLine(Offset(xStart, 1), Offset(xStart + 10, 1), paintLoopStart);
        canvas.drawLine(
          Offset(xStart, size.height - 1),
          Offset(xStart + 10, size.height - 1),
          paintLoopStart,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${loop.name} $startText',
            style: TextStyle(color: loop.color.color, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xStart + 4, 4));
      }
      if (loop.end != null) {
        final paintLoopEnd = Paint()
          ..color = loop.color.color
          ..strokeWidth = 2;
        final xEnd = scaleX(loop.end!.inMilliseconds.toDouble());
        canvas.drawLine(Offset(xEnd, 0), Offset(xEnd, size.height), paintLoopEnd);
        canvas.drawLine(Offset(xEnd, 1), Offset(xEnd - 10, 1), paintLoopEnd);
        canvas.drawLine(
          Offset(xEnd, size.height - 1),
          Offset(xEnd - 10, size.height - 1),
          paintLoopEnd,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${loop.name} $endText',
            style: TextStyle(color: loop.color.color, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xEnd - textPainter.width - 4, size.height - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoopMarkerPainter oldDelegate) {
    return loops != oldDelegate.loops ||
        duration != oldDelegate.duration ||
        zoomScale != oldDelegate.zoomScale;
  }
}
 */

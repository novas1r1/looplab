import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/wave_data_visualizer_service.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/widgets/wave_painter.dart';
import 'package:repeatlab/l10n/l10n.dart';

class WaveFormSoLoud extends StatefulWidget {
  final Song song;
  final void Function(Duration duration) onPositionChanged;
  final VoidCallback onStartDrag;

  const WaveFormSoLoud({
    super.key,
    required this.song,
    required this.onPositionChanged,
    required this.onStartDrag,
  });

  @override
  State<WaveFormSoLoud> createState() => _WaveFormSoLoudState();
}

class _WaveFormSoLoudState extends State<WaveFormSoLoud> {
  late WaveDataVisualizerService waveDataVisualizerService;

  @override
  void initState() {
    super.initState();
    waveDataVisualizerService = WaveDataVisualizerService(soloud: SoLoud.instance);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Float32List>(
      future: waveDataVisualizerService.getWaveformData(widget.song),
      initialData: Float32List(0),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
          return StreamBuilder(
            stream: context.read<SongCubit>().positionStream,
            initialData: Duration.zero,
            builder: (context, streamSnapshot) {
              if (streamSnapshot.hasData) {
                return _WaveFormSoLoudView(
                  data: snapshot.data!,
                  duration: widget.song.duration,
                  currentPosition: streamSnapshot.data!,
                  onPositionChanged: widget.onPositionChanged,
                  onStartDrag: widget.onStartDrag,
                );
              }

              return const SizedBox.shrink();
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

// https://github.com/alnitak/flutter_soloud/blob/feat_waveform/example/lib/wave_data/wave_data.dart
class _WaveFormSoLoudView extends StatefulWidget {
  final Float32List data;
  final Duration duration;
  final Duration currentPosition;
  final void Function(Duration duration) onPositionChanged;
  final VoidCallback onStartDrag;

  const _WaveFormSoLoudView({
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.onPositionChanged,
    required this.onStartDrag,
  });

  @override
  State<_WaveFormSoLoudView> createState() => _WaveFormSoLoudViewState();
}

class _WaveFormSoLoudViewState extends State<_WaveFormSoLoudView> {
  static const double minZoom = 0.25;
  static const double maxZoom = 5.0;
  static const double zoomStep = 0.25;

  late ScrollController _scrollController;

  bool _isDragging = false;
  double? _screenWidth;
  bool _widthInitialized = false;

  double _zoomScale = 1.0;
  bool _showZoomSlider = false;
  Timer? _zoomSliderTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Alternative approach: Get screen width once in didChangeDependencies
    if (!_widthInitialized) {
      _screenWidth = MediaQuery.sizeOf(context).width;
      _widthInitialized = true;
    }
  }

  @override
  void dispose() {
    _zoomSliderTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _WaveFormSoLoudView oldWidget) {
    if (widget.currentPosition != oldWidget.currentPosition && !_isDragging) {
      _updateScrollPosition();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final width = _screenWidth ?? MediaQuery.sizeOf(context).width; // Use stored width or fallback
    final waveformWidth = widget.data.length.toDouble() * _zoomScale;

    return SizedBox(
      height: 132,
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
                    child: BlocBuilder<SongCubit, SongState>(
                      buildWhen: (previous, current) => previous.song.loops != current.song.loops,
                      builder: (context, state) {
                        return SizedBox(
                          width: waveformWidth,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              // willChange: true,
                              // isComplex: true,
                              painter: WavePainter(
                                data: widget.data,
                                duration: widget.duration,
                                currentPosition: widget.currentPosition,
                                loops: state.song.loops,
                                colorPlayed: Theme.of(context).colorScheme.primaryFixedDim,
                                // colorUnplayed: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                colorUnplayed: const Color(0xff00696e),
                                zoomScale: _zoomScale,
                                startText: context.l10n.start,
                                endText: context.l10n.end,
                              ),
                            ),
                          ),
                        );
                      },
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
}

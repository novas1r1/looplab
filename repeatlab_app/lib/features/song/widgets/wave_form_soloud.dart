import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/cubit/wave_form/wave_form_cubit.dart';
import 'package:repeatlab/features/song/widgets/wave_painter.dart';
import 'package:repeatlab/l10n/l10n.dart';

class WaveFormSoLoud extends StatelessWidget {
  final Song song;

  const WaveFormSoLoud({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return BlocProvider(
      create: (context) => WaveFormCubit(
        soloud: SoLoud.instance,
        songCubit: context.read<SongCubit>(),
        song: song,
        crashReportingRepository: context.read<CrashReportingRepository>(),
      )..getWaveformData(song),
      child: _WaveFormSoLoudView(width: width),
    );
  }
}

class _WaveFormSoLoudView extends StatefulWidget {
  final double width;

  const _WaveFormSoLoudView({
    required this.width,
  });

  @override
  State<_WaveFormSoLoudView> createState() => _WaveFormSoLoudViewState();
}

class _WaveFormSoLoudViewState extends State<_WaveFormSoLoudView> {
  static const double minZoom = 0.25;
  static const double maxZoom = 5.0;
  static const double zoomStep = 0.25;

  final ScrollController _scrollController = ScrollController();

  bool _isDragging = false;
  double _zoomScale = 1.0;

  bool _showZoomSlider = false;
  Timer? _zoomSliderTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _zoomSliderTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /*   @override
  void didUpdateWidget(covariant _WaveFormSoLoudView oldWidget) {
    if (widget.currentPosition != oldWidget.currentPosition && !_isDragging) {
      _updateScrollPosition();
    }

    super.didUpdateWidget(oldWidget);
  } */

  @override
  Widget build(BuildContext context) {
    final waveFormCubit = context.read<WaveFormCubit>();
    final positionNotifier = waveFormCubit.playbackPositionNotifier;

    return BlocBuilder<WaveFormCubit, WaveFormState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.waveformData != current.waveformData ||
          previous.duration != current.duration ||
          previous.loops != current.loops,
      builder: (context, state) {
        switch (state.status) {
          case WaveFormStateStatus.loading:
            return const SizedBox(
              height: 132,
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Waveform...'),
                  ],
                ),
              ),
            );
          case WaveFormStateStatus.error:
            return const SizedBox(
              height: 132,
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error, size: 48, color: AppColors.danger),
                    SizedBox(height: 16),
                    Text('Error loading waveform'),
                  ],
                ),
              ),
            );
          case WaveFormStateStatus.loaded:
          case WaveFormStateStatus.updated:
            final waveformWidth =
                (state.waveformData?.length.toDouble() ?? 0.0) * _zoomScale;

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
                        state,
                      ),
                      onPointerUp: (details) =>
                          _handleDragEnd(DragEndDetails(), state),
                      child: ListView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: (widget.width / 2) - 16,
                        ),
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          if (state.waveformData != null)
                            GestureDetector(
                              onHorizontalDragStart: _handleDragStart,
                              onHorizontalDragUpdate: (details) =>
                                  _handleDragUpdate(
                                    details,
                                    state,
                                  ),
                              onHorizontalDragEnd: (details) =>
                                  _handleDragEnd(details, state),
                              child: SizedBox(
                                width: waveformWidth,
                                child: RepaintBoundary(
                                  child: ValueListenableBuilder<Duration>(
                                    valueListenable: positionNotifier,
                                    builder: (_, position, _) {
                                      if (!_isDragging) {
                                        _updateScrollPositionFor(
                                          position,
                                          state,
                                        );
                                      }

                                      return CustomPaint(
                                        painter: WavePainter(
                                          data: state.waveformData!,
                                          duration: state.duration,
                                          currentPosition: position,
                                          loops: state.loops,
                                          colorPlayed: Theme.of(
                                            context,
                                          ).colorScheme.primaryFixedDim,
                                          colorUnplayed: const Color(
                                            0xff00696e,
                                          ),
                                          zoomScale: _zoomScale,
                                          startText: context.l10n.start,
                                          endText: context.l10n.end,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Center line
                  Positioned(
                    left: (widget.width / 2) - 16,
                    bottom: 0,
                    top: 0,
                    child: Container(
                      width: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  // Zoom controls
                  Positioned(
                    right: 8,
                    top: 0,
                    child: GestureDetector(
                      onTap: _zoomScale < maxZoom
                          ? () => _onZoomIn(context)
                          : null,
                      child: Icon(
                        Icons.zoom_in,
                        size: 24,
                        color: _zoomScale < maxZoom
                            ? Colors.white
                            : Colors.grey,
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
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
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
                      onTap: _zoomScale > minZoom
                          ? () => _onZoomOut(context)
                          : null,
                      child: Icon(
                        Icons.zoom_out,
                        size: 24,
                        color: _zoomScale > minZoom
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  Future<void> _onZoomOut(BuildContext context) async {
    AppAnalytics.trackEvent(
      AppAnalytics.clickZoomOut,
      data: {'zoom_scale': _zoomScale},
    );

    final hasPurchased = context.read<PremiumSubscriptionCubit>().hasPremium;
    // check if user has premium subscription
    if (hasPurchased) {
      _zoomOut();
      _showZoomControls();
    } else {
      if (!context.mounted) return;
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'waveform_zoom',
      );
    }
  }

  void _handleDragStart(DragStartDetails details) {
    context.read<WaveFormCubit>().pauseSong();
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, WaveFormState state) {
    if (!_isDragging) return;

    final maxScroll =
        (state.waveformData?.length.toDouble() ?? 0.0) * _zoomScale;
    if (maxScroll <= 0 || !_scrollController.hasClients) {
      return;
    }

    final newScrollPosition =
        _scrollController.position.pixels - details.delta.dx;

    _scrollController.jumpTo(newScrollPosition.clamp(0, maxScroll));

    // Calculate and update position immediately instead of using debounce
    final scrollPercentage = _scrollController.position.pixels / maxScroll;
    final newPosition = Duration(
      milliseconds: (scrollPercentage * state.duration.inMilliseconds).round(),
    );
    context.read<WaveFormCubit>().changePosition(newPosition);
  }

  void _handleDragEnd(DragEndDetails details, WaveFormState state) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
    });

    final maxScroll =
        (state.waveformData?.length.toDouble() ?? 0.0) * _zoomScale;
    if (maxScroll <= 0 || !_scrollController.hasClients) {
      return;
    }

    final scrollPercentage = _scrollController.position.pixels / maxScroll;

    final finalPosition = Duration(
      milliseconds: (scrollPercentage * state.duration.inMilliseconds).round(),
    );
    context.read<WaveFormCubit>().changePosition(finalPosition);
  }

  Future<void> _onZoomIn(BuildContext context) async {
    AppAnalytics.trackEvent(
      AppAnalytics.clickZoomIn,
      data: {'zoom_scale': _zoomScale},
    );

    final premiumSubscriptionCubit = context.read<PremiumSubscriptionCubit>();
    if (premiumSubscriptionCubit.hasPremium) {
      _zoomIn();
      _showZoomControls();
    } else {
      if (!context.mounted) return;
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'waveform_zoom',
      );
    }
  }

  /* void _updateScrollPosition() {
    final state = context.read<WaveFormCubit>().state;
    _updateScrollPositionFor(state.currentPosition, state);
  } */

  void _updateScrollPositionFor(Duration position, WaveFormState state) {
    if (!_scrollController.hasClients) return;

    final waveformLength = state.waveformData?.length ?? 0;
    if (waveformLength <= 0) return;

    final totalMilliseconds = state.duration.inMilliseconds;
    if (totalMilliseconds <= 0) return;

    final maxScroll = waveformLength.toDouble() * _zoomScale;
    if (maxScroll <= 0) return;

    final clampedPositionMs = position.inMilliseconds
        .clamp(0, totalMilliseconds)
        .toDouble();
    final target = (clampedPositionMs / totalMilliseconds) * maxScroll;

    if ((_scrollController.position.pixels - target).abs() < 1.0) {
      return;
    }

    try {
      _scrollController.jumpTo(target.clamp(0.0, maxScroll));
    } catch (e) {
      developer.log('Error jumping to position: $e', name: 'WaveFormSoLoud');
    }
  }

  void _zoomIn() {
    if (_zoomScale >= maxZoom) return;

    AppAnalytics.trackEvent(
      AppAnalytics.clickZoomIn,
      data: {'zoom_scale': _zoomScale},
    );

    // Calculate the center position before zooming
    final centerPosition = _scrollController.hasClients
        ? _scrollController.position.pixels / _zoomScale
        : 0.0;

    setState(() {
      _zoomScale = (_zoomScale + zoomStep).clamp(minZoom, maxZoom);
    });

    // Maintain the same center position after zooming
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(centerPosition * _zoomScale);
    }
  }

  void _zoomOut() {
    if (_zoomScale <= minZoom) return;

    AppAnalytics.trackEvent(
      AppAnalytics.clickZoomOut,
      data: {'zoom_scale': _zoomScale},
    );

    // Calculate the center position before zooming
    final centerPosition = _scrollController.hasClients
        ? _scrollController.position.pixels / _zoomScale
        : 0.0;

    setState(() {
      _zoomScale = (_zoomScale - zoomStep).clamp(minZoom, maxZoom);
    });

    // Maintain the same center position after zooming
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(centerPosition * _zoomScale);
    }
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
    final centerPosition = _scrollController.hasClients
        ? _scrollController.position.pixels / _zoomScale
        : 0.0;

    setState(() {
      _zoomScale = value;
    });

    // Maintain the same center position after zooming
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(centerPosition * _zoomScale);
    }

    _resetZoomTimer(); // Reset timer when user adjusts the slider
  }

  void _onScroll() {
    if (!_isDragging) return;

    final state = context.read<WaveFormCubit>().state;

    final maxScroll =
        (state.waveformData?.length.toDouble() ?? 0.0) * _zoomScale;
    if (maxScroll <= 0 || !_scrollController.hasClients) {
      return;
    }
    final scrollPercentage = _scrollController.position.pixels / maxScroll;

    final newPosition = Duration(
      milliseconds: (scrollPercentage * state.duration.inMilliseconds).round(),
    );

    context.read<WaveFormCubit>().changePosition(newPosition);
  }
}

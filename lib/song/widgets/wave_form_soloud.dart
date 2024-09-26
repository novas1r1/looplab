import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:looplab/song/widgets/wave_painter.dart';

// https://github.com/alnitak/flutter_soloud/blob/feat_waveform/example/lib/wave_data/wave_data.dart
class WaveFormSoLoud extends StatefulWidget {
  final Float32List data;
  final Duration duration;
  final Duration currentPosition;
  final void Function(Duration duration) onPositionChanged;
  final VoidCallback onStartDrag;

  final Duration? loopStartPosition;
  final Duration? loopEndPosition;

  const WaveFormSoLoud({
    super.key,
    required this.data,
    required this.duration,
    required this.currentPosition,
    required this.onPositionChanged,
    required this.onStartDrag,
    this.loopStartPosition,
    this.loopEndPosition,
  });

  @override
  State<WaveFormSoLoud> createState() => _WaveFormSoLoudState();
}

class _WaveFormSoLoudState extends State<WaveFormSoLoud> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
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
          widget.data.length.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 100,
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
                  final newScrollPosition =
                      _scrollController.position.pixels - details.delta.dx;
                  _scrollController.jumpTo(
                    newScrollPosition.clamp(
                      0,
                      widget.data.length.toDouble(),
                    ),
                  );
                },
                onHorizontalDragEnd: (details) {
                  // Update position
                  final scrollPercentage =
                      _scrollController.position.pixels / widget.data.length;
                  widget.onPositionChanged(
                    Duration(
                      milliseconds:
                          (scrollPercentage * widget.duration.inMilliseconds)
                              .toInt(),
                    ),
                  );
                },
                child: SizedBox(
                  width: widget.data.length.toDouble(),
                  child: CustomPaint(
                    painter: WavePainter(
                      data: widget.data,
                      duration: widget.duration,
                      currentPosition: widget.currentPosition,
                      loopStartPosition: widget.loopStartPosition,
                      loopEndPosition: widget.loopEndPosition,
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
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}

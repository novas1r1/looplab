import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';

/// Row of dots — one per beat in the bar — with a highlight that steps through
/// them at the current tempo while the metronome is running. Purely a tempo-
/// driven visual (not sample-accurate to the audio click); it conveys the
/// time signature and gives the running metronome a heartbeat.
class MetronomeBeatDots extends StatefulWidget {
  const MetronomeBeatDots({
    super.key,
    required this.beatsPerBar,
    required this.bpm,
    required this.isRunning,
  });

  final int beatsPerBar;
  final int bpm;

  /// When false the dots are shown dim and static (metronome off or paused).
  final bool isRunning;

  @override
  State<MetronomeBeatDots> createState() => _MetronomeBeatDotsState();
}

class _MetronomeBeatDotsState extends State<MetronomeBeatDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _barDuration());
    _syncAnimation();
  }

  @override
  void didUpdateWidget(MetronomeBeatDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm ||
        oldWidget.beatsPerBar != widget.beatsPerBar) {
      _controller.duration = _barDuration();
    }
    if (oldWidget.isRunning != widget.isRunning ||
        oldWidget.bpm != widget.bpm ||
        oldWidget.beatsPerBar != widget.beatsPerBar) {
      _syncAnimation();
    }
  }

  Duration _barDuration() {
    final bpm = widget.bpm <= 0 ? 120 : widget.bpm;
    final beats = widget.beatsPerBar <= 0 ? 4 : widget.beatsPerBar;
    return Duration(milliseconds: (beats * 60000 / bpm).round());
  }

  void _syncAnimation() {
    if (widget.isRunning) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beats = widget.beatsPerBar <= 0 ? 4 : widget.beatsPerBar;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeBeat = widget.isRunning
            ? (_controller.value * beats).floor().clamp(0, beats - 1)
            : -1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < beats; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _Dot(
                  isDownbeat: i == 0,
                  isActive: i == activeBeat,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isDownbeat, required this.isActive});

  final bool isDownbeat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final size = isDownbeat ? 16.0 : 12.0;
    final Color color;
    if (isActive) {
      color = AppColors.primary;
    } else if (isDownbeat) {
      color = AppColors.secondary;
    } else {
      color = AppColors.outlineVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

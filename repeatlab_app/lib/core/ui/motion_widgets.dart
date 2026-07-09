import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/motion.dart';

/// Fade-through transition between coarse UI states (loading → loaded →
/// empty/error). Swaps when the [child]'s key or runtimeType changes.
class FadeThroughSwitcher extends StatelessWidget {
  final Widget child;

  const FadeThroughSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: Motion.of(context, Motion.standard),
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Scales its child down slightly while pressed, giving tactile feedback
/// without interfering with the child's own gesture handling.
class PressableScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && widget.enabled) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: Motion.of(context, Motion.xfast),
        curve: Motion.enter,
        child: widget.child,
      ),
    );
  }
}

/// One-shot mount animation: fades in while sliding up. Finite by design so
/// golden tests settle. Set [enabled] to false to render the end state
/// immediately (e.g. list rebuilds that must not re-stagger).
class EntranceSlideFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final bool enabled;

  const EntranceSlideFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.standard,
    this.offsetY = 16,
    this.enabled = true,
  });

  @override
  State<EntranceSlideFade> createState() => _EntranceSlideFadeState();
}

class _EntranceSlideFadeState extends State<EntranceSlideFade> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _started = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _started = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _started ? 1 : 0),
      duration: Motion.of(context, widget.duration),
      curve: Motion.enter,
      child: widget.child,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: child,
          ),
        );
      },
    );
  }
}

/// Shakes its child horizontally when [ShakeOnDeniedState.shake] is called.
/// Used for denied/locked interactions (premium gates) — motion says "no"
/// without flashing red.
class ShakeOnDenied extends StatefulWidget {
  final Widget child;

  const ShakeOnDenied({super.key, required this.child});

  @override
  State<ShakeOnDenied> createState() => ShakeOnDeniedState();
}

class ShakeOnDeniedState extends State<ShakeOnDenied>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  void shake() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // Decaying sine: three swings that fade out.
        final dx = math.sin(t * math.pi * 6) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// A small "What's new" speech bubble that floats just below the gift icon in
/// the home app bar, gently bobbing up and down to draw attention to an unseen
/// changelog. Tapping it opens the changelog.
class WhatsNewBubble extends StatefulWidget {
  const WhatsNewBubble({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<WhatsNewBubble> createState() => _WhatsNewBubbleState();
}

class _WhatsNewBubbleState extends State<WhatsNewBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _bob = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bob.value),
        child: child,
      ),
      child: GestureDetector(
        key: const Key('home.whatsNewBubble'),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pointer, offset from the right so it sits under the gift icon.
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: CustomPaint(
                size: Size(16, 8),
                painter: _BubblePointerPainter(color: AppColors.primary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.whatsNew,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the little upward-pointing triangle that connects the bubble to the
/// gift icon above it.
class _BubblePointerPainter extends CustomPainter {
  const _BubblePointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePointerPainter oldDelegate) => oldDelegate.color != color;
}

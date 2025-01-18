import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final String semanticLabel;

  const SvgIcon({
    super.key,
    required this.name,
    this.size = 24,
    this.color = Colors.white,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Semantics(
        label: semanticLabel,
        child: SvgPicture.asset(
          'assets/icons/$name.svg',
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}

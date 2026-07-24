import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:repeatlab/core/ui/app_colors.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.iconName,
    this.color = AppColors.iconDefault,
    this.iconSize = 16,
    this.containerSize = 20,
  });

  final String iconName;
  final Color? color;
  final double iconSize;
  final double containerSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/$iconName.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        ),
      ),
    );
  }
}

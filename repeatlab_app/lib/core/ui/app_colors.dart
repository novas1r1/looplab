import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light ColorScheme
  static const lightPrimary = Color.fromARGB(255, 0, 21, 22);
  static const lightSurfaceTint = Color(0xff00696e);
  static const lightOnPrimary = Color(0xffffffff);
  static const lightPrimaryContainer = Color(0xff27b9c2);
  static const lightOnPrimaryContainer = Color(0xff002224);
  static const lightSecondary = Color(0xff262b33);
  static const lightOnSecondary = Color(0xffffffff);
  static const lightSecondaryContainer = Color(0xff484d55);
  static const lightOnSecondaryContainer = Color(0xffe6eaf4);
  static const lightTertiary = Color(0xff006c45);
  static const lightOnTertiary = Color(0xffffffff);
  static const lightTertiaryContainer = Color(0xff49e59f);
  static const lightOnTertiaryContainer = Color(0xff004329);
  static const lightError = Color(0xffa40018);
  static const lightOnError = Color(0xffffffff);
  static const lightErrorContainer = Color(0xffdb3236);
  static const lightOnErrorContainer = Color(0xffffffff);
  static const lightSurface = Color(0xfffdf8f8);
  static const lightOnSurface = Color(0xff1c1b1b);
  static const lightOnSurfaceVariant = Color(0xff444748);
  static const lightOutline = Color(0xff747878);
  static const lightOutlineVariant = Color(0xffc4c7c7);
  static const lightShadow = Color(0xff000000);
  static const lightScrim = Color(0xff000000);
  static const lightInverseSurface = Color(0xff313030);
  static const lightInversePrimary = Color(0xff55d8e1);
  static const lightPrimaryFixed = Color(0xff75f5fd);
  static const lightOnPrimaryFixed = Color(0xff002022);
  static const lightPrimaryFixedDim = Color(0xff55d8e1);
  static const lightOnPrimaryFixedVariant = Color(0xff004f53);
  static const lightSecondaryFixed = Color(0xffdee2ed);
  static const lightOnSecondaryFixed = Color(0xff171c23);
  static const lightSecondaryFixedDim = Color(0xffc2c7d0);
  static const lightOnSecondaryFixedVariant = Color(0xff42474f);
  static const lightTertiaryFixed = Color(0xff65fdb5);
  static const lightOnTertiaryFixed = Color(0xff002112);
  static const lightTertiaryFixedDim = Color(0xff42e09a);
  static const lightOnTertiaryFixedVariant = Color(0xff005233);
  static const lightSurfaceDim = Color(0xffddd9d8);
  static const lightSurfaceBright = Color(0xfffdf8f8);
  static const lightSurfaceContainerLowest = Color(0xffffffff);
  static const lightSurfaceContainerLow = Color(0xfff7f3f2);
  static const lightSurfaceContainer = Color(0xfff1edec);
  static const lightSurfaceContainerHigh = Color(0xffebe7e6);
  static const lightSurfaceContainerHighest = Color(0xffe5e2e1);

  // Dark ColorScheme
  static const darkPrimary = Color(0xff55d8e1);
  static const darkSurfaceTint = Color(0xff55d8e1);
  static const darkOnPrimary = Color(0xff003739);
  static const darkPrimaryContainer = Color(0xff00a3ab);
  static const darkOnPrimaryContainer = Color(0xff000000);
  static const darkSecondary = Color(0xffc2c7d0);
  static const darkOnSecondary = Color(0xff2c3138);
  static const darkSecondaryContainer = Color(0xff30353d);
  static const darkOnSecondaryContainer = Color(0xffc0c4ce);
  static const darkTertiary = Color(0xff79ffbc);
  static const darkOnTertiary = Color(0xff003822);
  static const darkTertiaryContainer = Color(0xff33d591);
  static const darkOnTertiaryContainer = Color(0xff003721);
  static const darkError = Color(0xffffb3ae);
  static const darkOnError = Color(0xff68000b);
  static const darkErrorContainer = Color(0xffdb3236);
  static const darkOnErrorContainer = Color(0xffffffff);
  static const darkSurface = Color(0xff141313);
  static const darkOnSurface = Color(0xffe5e2e1);
  static const darkOnSurfaceVariant = Color(0xffc4c7c7);
  static const darkOutline = Color(0xff8e9192);
  static const darkOutlineVariant = Color(0xff444748);
  static const darkShadow = Color(0xff000000);
  static const darkScrim = Color(0xff000000);
  static const darkInverseSurface = Color(0xffe5e2e1);
  static const darkInversePrimary = Color(0xff00696e);
  static const darkPrimaryFixed = Color(0xff75f5fd);
  static const darkOnPrimaryFixed = Color(0xff002022);
  static const darkPrimaryFixedDim = Color(0xff55d8e1);
  static const darkOnPrimaryFixedVariant = Color(0xff004f53);
  static const darkSecondaryFixed = Color(0xffdee2ed);
  static const darkOnSecondaryFixed = Color(0xff171c23);
  static const darkSecondaryFixedDim = Color(0xffc2c7d0);
  static const darkOnSecondaryFixedVariant = Color(0xff42474f);
  static const darkTertiaryFixed = Color(0xff65fdb5);
  static const darkOnTertiaryFixed = Color(0xff002112);
  static const darkTertiaryFixedDim = Color(0xff42e09a);
  static const darkOnTertiaryFixedVariant = Color(0xff005233);
  static const darkSurfaceDim = Color(0xff141313);
  static const darkSurfaceBright = Color(0xff3a3939);
  static const darkSurfaceContainerLowest = Color(0xff0e0e0e);
  static const darkSurfaceContainerLow = Color(0xff1c1b1b);
  static const darkSurfaceContainer = Color(0xff201f1f);
  static const darkSurfaceContainerHigh = Color(0xff2b2a2a);
  static const darkSurfaceContainerHighest = Color(0xff353434);

  // current colors
  // Dark ColorScheme
  static const primary = Color(0xff55d8e1);
  static const surfaceTint = Color(0xff55d8e1);
  static const onPrimary = Color(0xff003739);
  static const primaryContainer = Color(0xff00a3ab);
  static const onPrimaryContainer = Color(0xff000000);
  static const secondary = Color(0xffc2c7d0);
  static const onSecondary = Color(0xff2c3138);
  static const secondaryContainer = Color(0xff30353d);
  static const onSecondaryContainer = Color(0xffc0c4ce);
  static const tertiary = Color(0xff79ffbc);
  static const onTertiary = Color(0xff003822);
  static const tertiaryContainer = Color(0xff33d591);
  static const onTertiaryContainer = Color(0xff003721);
  static const error = Color(0xffffb3ae);
  static const onError = Color(0xff68000b);
  static const errorContainer = Color(0xffdb3236);
  static const onErrorContainer = Color(0xffffffff);
  static const surface = Color(0xff141313);
  static const onSurface = Color(0xffe5e2e1);
  static const onSurfaceVariant = Color(0xffc4c7c7);
  static const outline = Color(0xff8e9192);
  static const outlineVariant = Color(0xff444748);
  static const shadow = Color(0xff000000);
  static const scrim = Color(0xff000000);
  static const inverseSurface = Color(0xffe5e2e1);
  static const inversePrimary = Color(0xff00696e);
  static const primaryFixed = Color(0xff75f5fd);
  static const onPrimaryFixed = Color(0xff002022);
  static const primaryFixedDim = Color(0xff55d8e1);
  static const onPrimaryFixedVariant = Color(0xff004f53);
  static const secondaryFixed = Color(0xffdee2ed);
  static const onSecondaryFixed = Color(0xff171c23);
  static const secondaryFixedDim = Color(0xffc2c7d0);
  static const onSecondaryFixedVariant = Color(0xff42474f);
  static const tertiaryFixed = Color(0xff65fdb5);
  static const onTertiaryFixed = Color(0xff002112);
  static const tertiaryFixedDim = Color(0xff42e09a);
  static const onTertiaryFixedVariant = Color(0xff005233);
  static const surfaceDim = Color(0xff141313);
  static const surfaceBright = Color(0xff3a3939);
  static const surfaceContainerLowest = Color(0xff0e0e0e);
  static const surfaceContainerLow = Color(0xff1c1b1b);
  static const surfaceContainer = Color(0xff201f1f);
  static const surfaceContainerHigh = Color(0xff2b2a2a);
  static const surfaceContainerHighest = Color(0xff353434);

  static const danger = Colors.red;

  /// Amber for caveats — something still works, but with a trade-off worth
  /// naming (e.g. a large pitch shift that will sound artificial). Distinct
  /// from [error], which is for things that actually failed.
  static const warning = Color(0xffffd08a);

  // Semantic icon colors. Every icon should use one of these instead of a
  // raw scheme color, so the app-wide icon look can be changed in one place.
  // Exceptions: decorative accents (onboarding heroes, rating stars) and
  // icons overlaid on video content, which are brightness-independent.
  static const iconDefault = secondaryFixed;
  static const iconDisabled = outline;
  static const iconActive = primary;
}

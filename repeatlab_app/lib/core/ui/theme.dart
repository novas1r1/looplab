import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  ThemeData light() {
    return theme(lightScheme());
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromARGB(255, 0, 21, 22),
      surfaceTint: Color(0xff00696e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff27b9c2),
      onPrimaryContainer: Color(0xff002224),
      secondary: Color(0xff262b33),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff484d55),
      onSecondaryContainer: Color(0xffe6eaf4),
      tertiary: Color(0xff006c45),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff49e59f),
      onTertiaryContainer: Color(0xff004329),
      error: Color(0xffa40018),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffdb3236),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8f8),
      onSurface: Color(0xff1c1b1b),
      onSurfaceVariant: Color(0xff444748),
      outline: Color(0xff747878),
      outlineVariant: Color(0xffc4c7c7),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xff55d8e1),
      primaryFixed: Color(0xff75f5fd),
      onPrimaryFixed: Color(0xff002022),
      primaryFixedDim: Color(0xff55d8e1),
      onPrimaryFixedVariant: Color(0xff004f53),
      secondaryFixed: Color(0xffdee2ed),
      onSecondaryFixed: Color(0xff171c23),
      secondaryFixedDim: Color(0xffc2c7d0),
      onSecondaryFixedVariant: Color(0xff42474f),
      tertiaryFixed: Color(0xff65fdb5),
      onTertiaryFixed: Color(0xff002112),
      tertiaryFixedDim: Color(0xff42e09a),
      onTertiaryFixedVariant: Color(0xff005233),
      surfaceDim: Color(0xffddd9d8),
      surfaceBright: Color(0xfffdf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e6),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    // Same neutral as AppColors.iconDefault (secondaryFixed is identical in
    // both schemes), so themed Icons match the explicitly colored AppIcons.
    iconTheme: IconThemeData(color: colorScheme.secondaryFixed),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: colorScheme.secondaryFixed),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  List<ExtendedColor> get extendedColors => [];

  /*static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff004b4f),
      surfaceTint: Color(0xff00696e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff008188),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff262b33),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff484d55),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff004d30),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff008656),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff8b0012),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffdb3236),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8f8),
      onSurface: Color(0xff1c1b1b),
      onSurfaceVariant: Color(0xff404344),
      outline: Color(0xff5c6060),
      outlineVariant: Color(0xff787b7c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xff55d8e1),
      primaryFixed: Color(0xff008188),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff00666b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff70757e),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff575c65),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff008656),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff006a43),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffddd9d8),
      surfaceBright: Color(0xfffdf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e6),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff002729),
      surfaceTint: Color(0xff00696e),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff004b4f),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1d232a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff3e434b),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff002817),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff004d30),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4d0006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8b0012),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8f8),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff212425),
      outline: Color(0xff404344),
      outlineVariant: Color(0xff404344),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffa9faff),
      primaryFixed: Color(0xff004b4f),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003235),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff3e434b),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff282d35),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff004d30),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff00341f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffddd9d8),
      surfaceBright: Color(0xfffdf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e6),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }*/

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff55d8e1),
      surfaceTint: Color(0xff55d8e1),
      onPrimary: Color(0xff003739),
      primaryContainer: Color(0xff00a3ab),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc2c7d0),
      onSecondary: Color(0xff2c3138),
      secondaryContainer: Color(0xff30353d),
      onSecondaryContainer: Color(0xffc0c4ce),
      tertiary: Color(0xff79ffbc),
      onTertiary: Color(0xff003822),
      tertiaryContainer: Color(0xff33d591),
      onTertiaryContainer: Color(0xff003721),
      error: Color(0xffffb3ae),
      onError: Color(0xff68000b),
      errorContainer: Color(0xffdb3236),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xff141313),
      onSurface: Color(0xffe5e2e1),
      onSurfaceVariant: Color(0xffc4c7c7),
      outline: Color(0xff8e9192),
      outlineVariant: Color(0xff444748),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff00696e),
      primaryFixed: Color(0xff75f5fd),
      onPrimaryFixed: Color(0xff002022),
      primaryFixedDim: Color(0xff55d8e1),
      onPrimaryFixedVariant: Color(0xff004f53),
      secondaryFixed: Color(0xffdee2ed),
      onSecondaryFixed: Color(0xff171c23),
      secondaryFixedDim: Color(0xffc2c7d0),
      onSecondaryFixedVariant: Color(0xff42474f),
      tertiaryFixed: Color(0xff65fdb5),
      onTertiaryFixed: Color(0xff002112),
      tertiaryFixedDim: Color(0xff42e09a),
      onTertiaryFixedVariant: Color(0xff005233),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff3a3939),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2b2a2a),
      surfaceContainerHighest: Color(0xff353434),
    );
  }

  /*static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff5adde5),
      surfaceTint: Color(0xff55d8e1),
      onPrimary: Color(0xff001a1c),
      primaryContainer: Color(0xff00a3ab),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc6cbd5),
      onSecondary: Color(0xff12171e),
      secondaryContainer: Color(0xff8c919a),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xff79ffbc),
      onTertiary: Color(0xff00341f),
      tertiaryContainer: Color(0xff33d591),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffb9b4),
      onError: Color(0xff370003),
      errorContainer: Color(0xffff5352),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141313),
      onSurface: Color(0xfffefaf9),
      onSurfaceVariant: Color(0xffc8cbcc),
      outline: Color(0xffa0a3a4),
      outlineVariant: Color(0xff808484),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff005054),
      primaryFixed: Color(0xff75f5fd),
      onPrimaryFixed: Color(0xff001416),
      primaryFixedDim: Color(0xff55d8e1),
      onPrimaryFixedVariant: Color(0xff003d40),
      secondaryFixed: Color(0xffdee2ed),
      onSecondaryFixed: Color(0xff0c1118),
      secondaryFixedDim: Color(0xffc2c7d0),
      onSecondaryFixedVariant: Color(0xff31363e),
      tertiaryFixed: Color(0xff65fdb5),
      onTertiaryFixed: Color(0xff00150a),
      tertiaryFixedDim: Color(0xff42e09a),
      onTertiaryFixedVariant: Color(0xff003f26),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff3a3939),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2b2a2a),
      surfaceContainerHighest: Color(0xff353434),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffedfeff),
      surfaceTint: Color(0xff55d8e1),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff5adde5),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfffafaff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffc6cbd5),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffeefff1),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff48e49e),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffb9b4),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xfff9fbfb),
      outline: Color(0xffc8cbcc),
      outlineVariant: Color(0xffc8cbcc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff003032),
      primaryFixed: Color(0xff8bf8ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff5adde5),
      onPrimaryFixedVariant: Color(0xff001a1c),
      secondaryFixed: Color(0xffe3e7f1),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffc6cbd5),
      onSecondaryFixedVariant: Color(0xff12171e),
      tertiaryFixed: Color(0xff7effbd),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff48e49e),
      onTertiaryFixedVariant: Color(0xff001b0e),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff3a3939),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2b2a2a),
      surfaceContainerHighest: Color(0xff353434),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }*/
}

class ExtendedColor {
  final Color seed;
  final Color value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The two palettes the app ships with.
///
/// Values are held in [CookColors] rather than being read from a BuildContext,
/// because roughly 170 call sites across the screens reference them directly.
/// [CookTheme.build] swaps them whenever MaterialApp rebuilds for a theme change,
/// so every widget re-reads the active set. The alternative, threading a palette
/// through every constructor, is a much larger change for the same result in a
/// single-theme app.
class CookPalette {
  const CookPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.orange,
    required this.orangeSoft,
    required this.orangeDeep,
    required this.orangeGlow,
    required this.white,
    required this.text,
    required this.muted,
    required this.muted2,
    required this.line,
    required this.gradient,
    required this.overlay,
    required this.statusBarIcons,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color orange;
  final Color orangeSoft;
  final Color orangeDeep;
  final Color orangeGlow;

  /// The colour used for solid fills that must stay legible on the accent,
  /// such as the primary button. It is near black in light mode and in dark mode.
  final Color white;
  final Color text;
  final Color muted;
  final Color muted2;
  final Color line;
  final LinearGradient gradient;
  final SystemUiOverlayStyle overlay;
  final Brightness statusBarIcons;
}

const CookPalette _darkPalette = CookPalette(
  bg: Color(0xFF0E0C0A),
  surface: Color(0xFF17140F),
  surface2: Color(0xFF201B15),
  surface3: Color(0xFF2A231B),
  orange: Color(0xFFFF8A3D),
  orangeSoft: Color(0xFFFFB37A),
  orangeDeep: Color(0xFFE2641A),
  orangeGlow: Color(0x38FF8A3D),
  white: Color(0xFFFFFFFF),
  text: Color(0xFFF6F1EA),
  muted: Color(0xFFA89E93),
  muted2: Color(0xFF7C736A),
  line: Color(0x14FFFFFF),
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF120F0C), Color(0xFF0E0C0A), Color(0xFF0A0806)],
    stops: [0.0, 0.55, 1.0],
  ),
  overlay: SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0E0C0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ),
  statusBarIcons: Brightness.light,
);

/// A warm light palette rather than a grey one, so the food photography and the
/// orange accent stay the loudest things on screen.
const CookPalette _lightPalette = CookPalette(
  bg: Color(0xFFFBF7F2),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF4EDE4),
  surface3: Color(0xFFEAE0D3),
  orange: Color(0xFFD9540B),
  orangeSoft: Color(0xFFB8480A),
  orangeDeep: Color(0xFFA93E06),
  orangeGlow: Color(0x1FD9540B),
  white: Color(0xFF17120D),
  text: Color(0xFF241C14),
  muted: Color(0xFF6B5E51),
  muted2: Color(0xFF8E8175),
  line: Color(0x1F241C14),
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFDFB), Color(0xFFFBF7F2), Color(0xFFF6EFE6)],
    stops: [0.0, 0.55, 1.0],
  ),
  overlay: SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFFBF7F2),
    systemNavigationBarIconBrightness: Brightness.dark,
  ),
  statusBarIcons: Brightness.dark,
);

/// Design tokens ported from the CookSmart HTML/CSS design, in two themes.
class CookColors {
  static Color bg = _darkPalette.bg;
  static Color surface = _darkPalette.surface;
  static Color surface2 = _darkPalette.surface2;
  static Color surface3 = _darkPalette.surface3;

  static Color orange = _darkPalette.orange;
  static Color orangeSoft = _darkPalette.orangeSoft;
  static Color orangeDeep = _darkPalette.orangeDeep;
  static Color orangeGlow = _darkPalette.orangeGlow;

  static Color white = _darkPalette.white;
  static Color text = _darkPalette.text;
  static Color muted = _darkPalette.muted;
  static Color muted2 = _darkPalette.muted2;

  static Color line = _darkPalette.line;

  /// Swaps in a palette. Called from the MaterialApp builder, which rebuilds on
  /// every theme change, so nothing is left painted in the old colours.
  static void apply(Brightness brightness) {
    final p =
        brightness == Brightness.dark ? _darkPalette : _lightPalette;
    bg = p.bg;
    surface = p.surface;
    surface2 = p.surface2;
    surface3 = p.surface3;
    orange = p.orange;
    orangeSoft = p.orangeSoft;
    orangeDeep = p.orangeDeep;
    orangeGlow = p.orangeGlow;
    white = p.white;
    text = p.text;
    muted = p.muted;
    muted2 = p.muted2;
    line = p.line;
  }

  static CookPalette paletteFor(Brightness brightness) =>
      brightness == Brightness.dark ? _darkPalette : _lightPalette;
}

class CookRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
}

class CookTheme {
  static const double tabHeight = 68;

  /// Horizontal page margin used by every screen.
  static const double gutter = 20;

  /// Kept for callers that want the system chrome in the default dark look.
  static SystemUiOverlayStyle get systemOverlay => _darkPalette.overlay;

  /// App-wide gradient wash used behind every screen.
  static LinearGradient get backgroundGradient => CookColors.paletteFor(
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
      ).gradient;

  static ThemeData build(Brightness brightness) {
    CookColors.apply(brightness);
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: Color(0xFFFF8A3D),
            onPrimary: Color(0xFF1C1108),
            secondary: Color(0xFFFFB37A),
            onSecondary: Color(0xFF1C1108),
            surface: Color(0xFF0E0C0A),
            onSurface: Color(0xFFF6F1EA),
            error: Color(0xFFE2641A),
            onError: Colors.white,
          )
        : const ColorScheme.light(
            primary: Color(0xFFD9540B),
            onPrimary: Colors.white,
            secondary: Color(0xFFB8480A),
            onSecondary: Colors.white,
            surface: Color(0xFFFBF7F2),
            onSurface: Color(0xFF241C14),
            error: Color(0xFFB3261E),
            onError: Colors.white,
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: CookColors.bg,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: CookColors.text,
        displayColor: CookColors.text,
      ),
      dividerColor: CookColors.line,
      iconTheme: IconThemeData(color: CookColors.text, size: 20),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFFF6F1EA) : const Color(0xFF241C14),
        contentTextStyle: TextStyle(
          color: dark ? const Color(0xFF14110D) : const Color(0xFFFBF7F2),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
      ),
    );
  }
}

TextStyle cookText({
  double? size,
  FontWeight? weight,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: color,
    );
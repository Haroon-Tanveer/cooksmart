import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens ported 1:1 from the CookSmart HTML/CSS design.
class CookColors {
  static const bg = Color(0xFF0E0C0A);
  static const surface = Color(0xFF17140F);
  static const surface2 = Color(0xFF201B15);
  static const surface3 = Color(0xFF2A231B);

  static const orange = Color(0xFFFF8A3D);
  static const orangeSoft = Color(0xFFFFB37A);
  static const orangeDeep = Color(0xFFE2641A);
  static const orangeGlow = Color(0x38FF8A3D);

  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFFF6F1EA);
  static const muted = Color(0xFFA89E93);
  static const muted2 = Color(0xFF7C736A);

  static const line = Color(0x14FFFFFF);
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

  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0E0C0A),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// App-wide gradient wash used behind every screen.
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF120F0C), Color(0xFF0E0C0A), Color(0xFF0A0806)],
    stops: [0.0, 0.55, 1.0],
  );

  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: CookColors.orange,
      onPrimary: Color(0xFF1C1108),
      secondary: CookColors.orangeSoft,
      onSecondary: Color(0xFF1C1108),
      surface: CookColors.bg,
      onSurface: CookColors.text,
      error: Color(0xFFE2641A),
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
      iconTheme: const IconThemeData(color: CookColors.text, size: 20),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: CookColors.white,
        contentTextStyle: TextStyle(
          color: Color(0xFF14110D),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
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

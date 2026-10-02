import 'package:cooksmart/main.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:cooksmart/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app ships two palettes. These guard that switching actually repaints the
/// UI, not just the ThemeData.
void main() {
  Brightness brightnessOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Navigator))).brightness;

  testWidgets('light and dark repaint the surfaces', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    await state.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    final lightBg = CookColors.bg;
    expect(brightnessOf(tester), Brightness.light);

    await state.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);

    // The palette really changed, rather than only the ThemeData.
    expect(CookColors.bg, isNot(lightBg));
    expect(CookColors.bg, const Color(0xFF0E0C0A));
    expect(lightBg, const Color(0xFFFBF7F2), reason: 'light mode uses a warm cream');

    await state.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(CookColors.bg, lightBg);
  });

  testWidgets('both themes keep the text readable on the surface', (tester) async {
    // Guards against a palette where the body text is invisible on its own card.
    // Dark text must be much darker than the surface it sits on, and the
    // accent must stay readable against both.
    final light = CookColors.paletteFor(Brightness.light);
    final dark = CookColors.paletteFor(Brightness.dark);
    expect(light.text.computeLuminance(), lessThan(light.surface.computeLuminance()),
        reason: 'dark text on a light surface');
    expect(dark.text.computeLuminance(), greaterThan(dark.surface.computeLuminance()),
        reason: 'pale text on a dark surface');
    expect(light.muted.computeLuminance(), lessThan(light.surface.computeLuminance()),
        reason: 'secondary text must stay visible on the light surface');
    expect(dark.muted.computeLuminance(), greaterThan(dark.surface.computeLuminance()),
        reason: 'secondary text must stay visible on the dark surface');
  });

  testWidgets('the theme choice survives a restart', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final first = AppState();
    await first.init();
    expect(first.themeMode, ThemeMode.system, reason: 'follows the phone by default');
    await first.setThemeMode(ThemeMode.light);

    final second = AppState();
    await second.init();
    expect(second.themeMode, ThemeMode.light);
  });
}
import 'package:cooksmart/main.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('switching to Arabic flips the whole app right to left', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    TextDirection direction() =>
        Directionality.of(tester.element(find.byType(Navigator)));

    expect(find.text('Home'), findsOneWidget);
    expect(direction(), TextDirection.ltr);

    await state.setLocale(const Locale('ar'));
    await tester.pumpAndSettle();

    // MaterialApp has to rebuild for the direction to flip at all.
    expect(direction(), TextDirection.rtl);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('Home'), findsNothing, reason: 'the English label is gone');

    await state.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(direction(), TextDirection.ltr);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the chosen language survives a restart', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final first = AppState();
    await first.init();
    await first.setLocale(const Locale('ar'));

    // A fresh state reading the same storage, as after closing and reopening.
    final second = AppState();
    await second.init();
    expect(second.locale?.languageCode, 'ar');
  });
}

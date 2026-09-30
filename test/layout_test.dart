import 'package:cooksmart/data/recipes.dart';
import 'package:cooksmart/main.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:cooksmart/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

/// Small phone, common phone, and a deliberately cramped width. Padding that
/// only works on one of these is a bug, not a style choice.
const List<Size> kViewports = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(430, 932),
];

Future<void> pumpAt(WidgetTester tester, AppState state, Size size, {double textScale = 1}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: CookSmartApp(state: state),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fails the test on any layout error, most importantly a RenderFlex overflow.
void expectNoLayoutError(WidgetTester tester, String where) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout error on $where: $error');
}

/// Scrolls the whole scrollable to the bottom and back, so off-screen widgets
/// are laid out too.
Future<void> scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('home lays out on every viewport and text scale', (tester) async {
    for (final size in kViewports) {
      for (final scale in <double>[1, 1.3]) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await pumpAt(tester, liveTestState(), size, textScale: scale);
        expectNoLayoutError(tester, 'home $size @$scale');
        await scrollThrough(tester);
        expectNoLayoutError(tester, 'home scrolled $size.width @$scale');
      }
    }
  });

  testWidgets('create screen lays out empty, filled, and with dish ideas',
      (tester) async {
    for (final size in kViewports) {
      for (final scale in <double>[1, 1.3]) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final state = liveTestState();
        await pumpAt(tester, state, size, textScale: scale);
        state.go(CookScreen.ingredients);
        await tester.pumpAndSettle();
        expectNoLayoutError(tester, 'create empty $size.width @$scale');

        // A full row of chips is the worst case for the input field.
        for (final item in <String>[
          'chicken',
          'rice',
          'garlic',
          'tomatoes',
          'red onion',
          'potatoes',
          'olive oil',
        ]) {
          state.addIngredient(item);
        }
        state.addListener(() {});
        await state.refreshDishIdeas();
        await tester.pumpAndSettle();
        await scrollThrough(tester);
        expectNoLayoutError(tester, 'create full $size.width @$scale');
      }
    }
  });

  testWidgets('library result lays out with long ingredient text', (tester) async {
    for (final size in kViewports) {
      for (final scale in <double>[1, 1.3]) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final state = AppState();
        await pumpAt(tester, state, size, textScale: scale);
        state.openLibraryRecipe(kRecipes[4]); // the longest ingredient list
        await tester.pumpAndSettle();
        expectNoLayoutError(tester, 'library result $size.width @$scale');
        await scrollThrough(tester);
        expectNoLayoutError(tester, 'library result scrolled $size.width @$scale');
      }
    }
  });

  testWidgets('live result lays out with a photo and with a photo pending',
      (tester) async {
    for (final size in kViewports) {
      for (final scale in <double>[1, 1.3]) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final state = liveTestState();
        await pumpAt(tester, state, size, textScale: scale);
        state.addIngredient('chicken');
        await state.generate();
        await tester.pumpAndSettle();
        expectNoLayoutError(tester, 'live result $size.width @$scale');
        await scrollThrough(tester);
        expectNoLayoutError(tester, 'live result scrolled $size.width @$scale');
      }
    }
  });

  testWidgets('saved screen lays out when empty and when full', (tester) async {
    for (final size in kViewports) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final empty = liveTestState();
      await pumpAt(tester, empty, size);
      empty.go(CookScreen.saved);
      await tester.pumpAndSettle();
      expectNoLayoutError(tester, 'saved empty $size.width');

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final full = liveTestState();
      for (final recipe in kRecipes.take(6)) {
        full.openLibraryRecipe(recipe);
        full.toggleSave();
      }
      await pumpAt(tester, full, size);
      full.go(CookScreen.saved);
      await tester.pumpAndSettle();
      expectNoLayoutError(tester, 'saved full $size.width');
      await scrollThrough(tester);
      expectNoLayoutError(tester, 'saved full scrolled $size.width');
    }
  });

  testWidgets('settings sheet lays out on a small screen with large text',
      (tester) async {
    for (final size in kViewports) {
      for (final scale in <double>[1, 1.3]) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final state = liveTestState();
        await pumpAt(tester, state, size, textScale: scale);
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsSheet), findsOneWidget);
        expectNoLayoutError(tester, 'settings $size.width @$scale');

        // The keyboard lifting the sheet is the tightest vertical case.
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        addTearDown(tester.view.reset);
        await tester.pumpAndSettle();
        expectNoLayoutError(tester, 'settings with keyboard $size.width @$scale');

        // Close it, or the next iteration taps the gear through the open sheet.
        Navigator.of(tester.element(find.byType(SettingsSheet))).pop();
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('landscape width does not break the result screen', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = liveTestState();
    await pumpAt(tester, state, const Size(740, 360));
    state.addIngredient('chicken');
    await state.generate();
    await tester.pumpAndSettle();
    expectNoLayoutError(tester, 'landscape result');
    await scrollThrough(tester);
    expectNoLayoutError(tester, 'landscape result scrolled');
  });
}

import 'package:cooksmart/main.dart';
import 'package:cooksmart/screens/privacy_screen.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the privacy policy opens from settings', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(CookSmartApp(state: AppState()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Live AI'), findsOneWidget);

    // The sheet's own context is defunct once popped, so this used to throw
    // instead of opening the page.
    // The sheet has grown with the theme picker, so the row may sit below the
    // fold on a short screen.
    await tester.scrollUntilVisible(
      find.text('Privacy policy'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text('Your data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

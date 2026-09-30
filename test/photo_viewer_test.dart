import 'package:cooksmart/data/recipes.dart';
import 'package:cooksmart/main.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:cooksmart/widgets/photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> openRecipe(WidgetTester tester, String id) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();
    state.openLibraryRecipe(findLibraryRecipe(id)!);
    await tester.pumpAndSettle();
  }

  testWidgets('holding on a recipe photo opens it full screen', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await openRecipe(tester, 'banana-pancakes');
    expect(find.byType(PhotoViewer), findsNothing);

    // A press-and-hold, not a tap, is what opens the full-screen photo.
    await tester.longPress(find.byType(PageView));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoViewer), findsOneWidget);
    // More than one photo, so the viewer shows a position counter.
    expect(find.text('1 of 3'), findsOneWidget);

    // Swiping inside the viewer moves to the next photo.
    await tester.drag(find.byType(PageView).last, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);

    // Tapping closes it, as it would in a photo app.
    await tester.tapAt(tester.getCenter(find.byType(PhotoViewer)));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('a single-photo recipe still opens on hold', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Found rather than hard-coded, because galleries are added over time and a
    // named recipe may have gained a second photo.
    final recipe = kRecipes.firstWhere(
      (r) => r.images.length == 1,
      orElse: () => throw StateError('expected a recipe with exactly one photo'),
    );
    await openRecipe(tester, recipe.id);
    expect(find.byType(PageView), findsNothing,
        reason: 'one photo means no pager on the card');

    await tester.longPress(find.byType(Opacity).first);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
  });
}

import 'package:cooksmart/data/recipes.dart';
import 'package:cooksmart/main.dart';
import 'package:cooksmart/state/app_state.dart';
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

  testWidgets('a multi-image recipe swipes between its own photos', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final recipe = findLibraryRecipe('banana-pancakes')!;
    expect(recipe.images.length, greaterThan(1),
        reason: 'this recipe is the multi-image fixture');

    await openRecipe(tester, 'banana-pancakes');

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('1'), findsNothing); // no counter, just dots

    // The first page shows the primary asset.
    String firstPageAsset() {
      final images = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => i.image)
          .whereType<AssetImage>()
          .toList();
      return images.isEmpty ? '' : images.first.assetName;
    }

    expect(firstPageAsset(), 'assets/recipes/banana-pancakes.jpg');

    // Drag the card leftwards, the way a thumb swipes.
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(firstPageAsset(), recipe.images[1],
        reason: 'swiping left should show the second photo of the same dish');
  });

  testWidgets('a single-image recipe offers nothing to swipe', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final recipe = kRecipes.firstWhere(
      (r) => r.images.isNotEmpty && r.images.length == 1,
    );
    await openRecipe(tester, recipe.id);

    expect(find.byType(PageView), findsNothing,
        reason: 'one photo means no pager and no dots to explain');
  });
}

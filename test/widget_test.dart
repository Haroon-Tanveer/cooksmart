import 'dart:io';

import 'support.dart';

import 'package:cooksmart/data/recipe_engine.dart';
import 'package:cooksmart/data/recipes.dart';
import 'package:cooksmart/main.dart';
import 'package:cooksmart/models/recipe.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:cooksmart/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Drags the page in [delta] steps until [finder] matches anything.
///
/// A single fixed drag depends on the page height, which changes whenever the
/// layout is adjusted, so it silently scrolls past the thing it is looking for.
Future<void> scrollUntilFound(WidgetTester tester, Finder finder, double delta) async {
  for (var i = 0; i < 10; i++) {
    await tester.drag(find.byType(ListView).first, Offset(0, delta));
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  test('generator ranks the recipe that matches the ingredients', () {
    final recipe = generateRecipe(<String>['chicken', 'potato', 'onion', 'lemon']);
    expect(recipe, isNotNull);
    expect(recipe!.id, 'sheet-pan-chicken');
    expect(recipe.have, contains('chicken'));
    expect(recipe.missing, isNotEmpty);
    expect(recipe.matchLabel, contains('match'));
  });

  test('generator returns null without ingredients', () {
    expect(generateRecipe(<String>[]), isNull);
  });

  test('library filters by category, search and quick tag', () {
    final state = AppState();

    state.setCategory('dessert');
    // A recipe reaches the dessert filter either as its own category or as a
    // second one, so a baklava shows under both Dessert and Turkish.
    expect(
      state.filteredRecipes.every(
        (r) => r.category == 'dessert' || r.alsoCategories.contains('dessert'),
      ),
      isTrue,
    );
    expect(state.filteredRecipes, isNotEmpty);


    state.setCategory('quick');
    expect(state.filteredRecipes.every((r) => r.time <= 20), isTrue);

    state.resetFilters();
    state.setSearch('shrimp');
    expect(state.filteredRecipes.single.id, 'garlic-butter-shrimp');
  });

  test('save and remove round-trips through state', () {
    final state = AppState();
    state.openLibraryRecipe(kRecipes.first);

    expect(state.toggleSave(), isTrue);
    expect(state.saved, hasLength(1));
    expect(state.toggleSave(), isFalse);
    expect(state.saved, isEmpty);
  });

  testWidgets('the result hero lines its chip, emoji and text up on one gutter',
      (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    final recipe = kRecipes.firstWhere((r) => r.id == 'baklava');
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    state.openLibraryRecipe(recipe);
    await tester.pumpAndSettle();

    // The chip, the emoji and the body copy must all start at the same x, and
    // none of them may touch the card edge.
    final chip = tester.getTopLeft(
      find
          .ancestor(
            of: find.text('From the library'),
            matching: find.byType(Container),
          )
          .first,
    );
    final emoji = tester.getTopLeft(find.text(recipe.emoji));
    final desc = tester.getTopLeft(find.text(recipe.desc));

    expect(chip.dx, closeTo(desc.dx, 0.5), reason: 'chip must align with the copy');
    expect(emoji.dx, closeTo(desc.dx, 0.5), reason: 'emoji must align with the copy');
    expect(desc.dx, greaterThanOrEqualTo(16), reason: 'the gutter must not collapse');
  });

  testWidgets('navigates across all four screens', (tester) async {

    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(CookSmartApp(state: liveTestState()));
    await tester.pumpAndSettle();

    // Screen 1: home
    expect(find.text('Saved recipes'), findsNothing);
    expect(find.textContaining('what\'s cooking?'), findsOneWidget);

    // Screen 2: ingredients via tab
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('What\'s in your kitchen?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'chicken');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('chicken'), findsWidgets);

    // Screen 3: generated result
    await tester.scrollUntilVisible(
      find.text('Generate Recipe'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Recipe'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    // The live title, not the library recipe, proves the Groq path was used.
    expect(find.text('Groq Sheet Pan Chicken'), findsWidgets);

    // Save it, then open the saved grid
    await tester.scrollUntilVisible(
      find.text('Save Recipe'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Recipe'));
    await tester.pumpAndSettle();
    // let the confirmation toast auto-dismiss so it can't swallow the next tap
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    expect(find.text('Saved recipes'), findsOneWidget);
    expect(find.text('1 recipe kept for later, ready whenever you are.'), findsOneWidget);

    // Screen 4 -> back to result via the card
    await tester.tap(find.text('Groq Sheet Pan Chicken').last);
    await tester.pumpAndSettle();
    expect(find.text('Groq Sheet Pan Chicken'), findsWidgets);

    // Small scrolls until the header is on screen: a fixed drag can overshoot
    // once the page height changes, and overshooting hides it again.
    await scrollUntilFound(tester, find.text('METHOD · 5 STEPS'), -240);
    expect(find.text('METHOD · 5 STEPS'), findsOneWidget);

    // Back button returns to the tab we came from
    await scrollUntilFound(tester, find.byIcon(Icons.chevron_left_rounded), 240);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Saved recipes'), findsOneWidget);
  });


  testWidgets('suggests dish names from Groq and cooks the tapped one', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(CookSmartApp(state: liveTestState()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Dish ideas from Groq'), findsOneWidget);

    // No ideas yet, so the row asks the endpoint for some.
    await tester.scrollUntilVisible(
      find.text('Suggest dishes'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Suggest dishes'));
    await tester.pumpAndSettle();
    expect(find.text('Miso Ramen'), findsOneWidget);

    // Tapping a suggested name cooks that dish, even with no ingredients typed.
    await tester.scrollUntilVisible(
      find.text('Charred Corn Tacos'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Charred Corn Tacos'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Groq Sheet Pan Chicken'), findsWidgets);
    // No ingredients were typed, so no bogus match score is shown.
    expect(find.text('Groq’s pick'), findsOneWidget);
    expect(find.text('from your idea'), findsOneWidget);
  });

  testWidgets('opens the settings sheet and tests the endpoint', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = liveTestState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    // Regression: the sheet used to read CookScope in initState, which Flutter
    // rejects because an inherited-widget dependency cannot be registered there.
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Live AI'), findsOneWidget);
    expect(find.text('Test connection'), findsOneWidget);

    // The endpoint field is seeded from the state.
    final field = tester.widget<TextField>(
      find.descendant(of: find.byType(SettingsSheet), matching: find.byType(TextField)),
    );
    expect(field.controller!.text, 'http://groq.test');

    // The probe reports a working endpoint.
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(find.text('Connected to the AI service'), findsOneWidget);

    // Preset chips rewrite the stored endpoint and the field.
    await tester.tap(find.text('Offline mock :8788'));
    await tester.pumpAndSettle();
    expect(state.config.baseUrl, 'http://10.0.2.2:8788');
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: find.byType(SettingsSheet), matching: find.byType(TextField)),
          )
          .controller!
          .text,
      'http://10.0.2.2:8788',
    );

    // Live AI can be switched off, which hands the app back to the offline engine.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(state.config.liveEnabled, isFalse);
  });

  testWidgets('save state survives a rebuild from storage', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    state.openLibraryRecipe(kRecipes[1]);
    state.toggleSave();
    await state.init();

    expect(state.saved.single.id, kRecipes[1].id);
    expect(state.saved.single.ingredients, isNotEmpty);
  });

  test('every library photo is real, loaded, and claimed by a recipe', () async {
    expect(kRecipes.length, greaterThanOrEqualTo(85));

    final problems = <String>[];
    final claimed = <String>{};
    var withGallery = 0;
    for (final recipe in kRecipes) {
      final gallery = recipe.images;
      if (gallery.isEmpty) continue;
      if (gallery.length > 1) withGallery++;
      // The first entry is the primary photo, the rest are the swipeable extras.
      if (!gallery.first.endsWith('/${recipe.id}.jpg')) {
        problems.add('${recipe.name}: primary photo ${gallery.first} is not named after ${recipe.id}');
      }
      for (final asset in gallery) {
        claimed.add(asset);
        try {
          final data = await rootBundle.load(asset);
          if (data.lengthInBytes < 1000) {
            problems.add('${recipe.name}: $asset is only ${data.lengthInBytes} bytes');
          }
        } catch (_) {
          problems.add('${recipe.name}: $asset is not in the bundle');
        }
        if (!asset.contains('/${recipe.id}')) {
          problems.add('${recipe.name}: $asset does not belong to this recipe');
        }
      }
      // Extras must not repeat the primary, or swiping shows the same picture.
      if (gallery.toSet().length != gallery.length) {
        problems.add('${recipe.name}: gallery has a duplicate image');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
    // Not every dish is photographable, and a contact-sheet review of every
    // image removed the ones that were not actually the dish. This floor stops
    // the illustrated share drifting much lower than that.
    expect(claimed.length, greaterThanOrEqualTo(150),
        reason: 'the library should stay substantially illustrated');
    expect(withGallery, greaterThanOrEqualTo(15),
        reason: 'the swipeable galleries should not be left with nothing to swipe');

    // No file may sit in the assets folder unused: that means a recipe was
    // renamed or deleted and its photo would be shipped for nothing.
    final dir = Directory('assets/recipes');
    final onDisk = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.path.replaceAll('\\', '/'))
        .where((p) => p.endsWith('.jpg'))
        .toSet();
    expect(
      onDisk.difference(claimed),
      isEmpty,
      reason: 'photos on disk that no recipe uses: ${onDisk.difference(claimed).join(', ')}',
    );
  });

  test('every library recipe is priced and has steps a beginner can follow', () {

    expect(kRecipes, isNotEmpty);
    for (final recipe in kRecipes) {
      expect(recipe.ingredients, isNotEmpty, reason: '${recipe.name} has no ingredients');
      for (final item in recipe.ingredients) {
        expect(
          item.calories,
          isNotNull,
          reason: '${recipe.name}: "${item.name} ${item.qty}" has no calorie figure',
        );
      }
      expect(recipe.totalCalories, isNotNull, reason: '${recipe.name} has no total');
      expect(recipe.caloriesPerServing, isNotNull, reason: '${recipe.name} has no per serving');
      expect(
        recipe.steps.length,
        greaterThanOrEqualTo(3),
        reason: '${recipe.name} needs at least 3 steps, has ${recipe.steps.length}',
      );

      for (final step in recipe.steps) {
        expect(step.trim(), isNotEmpty, reason: '${recipe.name} has an empty step');
      }
    }
  });

  test('recipe json round-trip preserves all fields', () {
    final r = generateRecipe(<String>['rice', 'eggs'])!;
    final copy = Recipe.fromJson(r.toJson());
    expect(copy.id, r.id);
    expect(copy.name, r.name);
    expect(copy.steps.length, r.steps.length);
    expect(copy.ingredients.length, r.ingredients.length);
    expect(copy.match, r.match);
    expect(copy.calories, r.calories);
    expect(copy.ingredients.first.calories, r.ingredients.first.calories);
  });
  testWidgets('a library recipe keeps its photo through copyWith', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    final recipe = findLibraryRecipe('baklava')!;
    expect(recipe.imageAsset, isNotNull);

    // Opening and saving both go through copyWith, which used to drop the
    // bundled photo and leave the hero with nothing to show.
    state.openLibraryRecipe(recipe);
    expect(state.result!.imageAsset, recipe.imageAsset);
    state.toggleSave();
    expect(state.saved.first.imageAsset, recipe.imageAsset);
  });

  testWidgets('the result hero draws the bundled photo behind the content',
      (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    state.openLibraryRecipe(findLibraryRecipe('baklava')!);
    await tester.pumpAndSettle();

    // The photo is dimmed behind the text rather than shown in a band above it.
    // With a multi-image recipe the dimmed layer is the pager, not a static one.
    expect(find.byType(PageView), findsOneWidget);
    final dimmed = find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.4);
    expect(dimmed, findsWidgets);

    final images = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is AssetImage)
        .map((i) => (i.image as AssetImage).assetName)
        .toList();
    expect(images, contains('assets/recipes/baklava.jpg'));
  });

  testWidgets('a recipe with no photo still shows the plain gradient', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await tester.pumpWidget(CookSmartApp(state: state));
    await tester.pumpAndSettle();

    final noPhoto = kRecipes.firstWhere((r) => r.imageAsset == null);
    state.openLibraryRecipe(noPhoto);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.4),
      findsNothing,
    );
  });
}


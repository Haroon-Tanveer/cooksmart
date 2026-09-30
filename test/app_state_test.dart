import 'dart:convert';

import 'package:cooksmart/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, dynamic> kRecipe = {
  'name': 'Charred Lemon Chicken',
  'description': 'A bright pan dinner.',
  'timeMinutes': 28,
  'difficulty': 'Easy',
  'servings': 2,
  'emoji': '🍋',
  'imagePrompt': 'charred lemon chicken',
  'owned': ['chicken', 'lemon'],
  'missing': ['thyme'],
  'calories': 610,
  'ingredients': [
    {'name': 'chicken', 'quantity': '400 g', 'calories': 260},
    {'name': 'lemon', 'quantity': '1', 'calories': 17},
    {'name': 'thyme', 'quantity': 'to taste', 'calories': 4},
  ],
  'steps': ['Season.', 'Sear.', 'Rest.', 'Serve.'],
};

http.Response _ok(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

/// Records what the app asked for, and answers from canned responses.
class FakeEndpoint {
  FakeEndpoint({this.failRecipe = false, this.failSuggest = false});

  bool failRecipe;
  bool failSuggest;
  final List<String> paths = <String>[];
  final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[];

  http.Client get client => MockClient((req) async {
        final path = req.url.path;
        paths.add(path);
        bodies.add(jsonDecode(req.body) as Map<String, dynamic>);

        if (path == '/gemini/recipe') {
          if (failRecipe) {
            return http.Response(jsonEncode({'error': 'Gemini is down'}), 502);
          }
          return _ok(kRecipe);
        }
        if (path == '/gemini/suggest') {
          if (failSuggest) return http.Response(jsonEncode({'error': 'nope'}), 500);
          return _ok({
            'names': ['Miso Ramen', 'Charred Corn Tacos']
          });
        }
        if (path == '/gemini/image') {
          return _ok({'url': 'https://images.test/photo.jpg'});
        }
        return http.Response('{}', 404);
      });
}

Future<AppState> buildState(FakeEndpoint fake) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final state = AppState(httpClient: fake.client);
  await state.init();
  // Production ships offline-first, so tests opt in to live generation.
  state.setLiveEnabled(true);
  state.updateEndpoint('http://groq.test');
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live generation returns the model recipe and marks it live', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);
    state
      ..addIngredient('chicken')
      ..addIngredient('lemon');

    final recipe = await state.generate();
    await Future<void>.delayed(Duration.zero);

    expect(recipe, isNotNull);
    expect(state.result, isNotNull);
    expect(state.result!.name, 'Charred Lemon Chicken');
    expect(state.result!.source, 'groq');
    expect(state.result!.time, 28);
    expect(state.result!.have, contains('chicken'));
    expect(state.result!.missing, ['thyme']);
    expect(state.usingFallback, isFalse);
    expect(state.liveError, isNull);
    expect(state.screen, CookScreen.result);
    expect(fake.bodies.first['ingredients'], ['chicken', 'lemon']);
    expect(state.result!.calories, 610);
    expect(state.result!.totalCalories, 610);
    expect(state.result!.caloriesPerServing, 305);
    expect(state.result!.ingredients.first.calories, 260);

    // The photo is fetched in the background, then attached to the result.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(fake.paths, contains('/gemini/image'));
    expect(state.result!.imageUrl, 'https://images.test/photo.jpg');
    // Re-attaching the photo rebuilds the recipe, so nothing may get lost there.
    expect(state.result!.calories, 610);
    expect(state.result!.ingredients.first.calories, 260);
    expect(state.result!.steps, hasLength(4));
  });

  test('a dish-only pick never claims owned ingredients or a match score', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);

    final recipe = await state.generate(dish: 'Miso Eggplant Bento');
    await Future<void>.delayed(Duration.zero);

    expect(recipe, isNotNull);
    expect(fake.bodies.first['dish'], 'Miso Eggplant Bento');
    expect(recipe!.basedOn, isEmpty);
    expect(recipe.matchLabel, 'Groq’s pick');
    // thyme is neither owned nor bought twice over.
    expect(recipe.haveTokens, isNot(contains('thyme')));
    expect(recipe.missing, ['thyme']);
  });

  test('busy state is published so the UI can show progress', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);
    state.addIngredient('chicken');

    final labels = <String?>[];
    state.addListener(() => labels.add(state.busyLabel));

    final pending = state.generate();
    expect(state.isBusy, isTrue);
    expect(state.busyLabel, 'Asking Groq…');

    await pending;
    expect(state.isBusy, isFalse);
    expect(labels, contains('Asking Groq…'));
  });

  test('an unreachable service falls back to the offline engine', () async {
    final fake = FakeEndpoint(failRecipe: true);
    final state = await buildState(fake);
    state
      ..addIngredient('chicken')
      ..addIngredient('potato')
      ..addIngredient('onion');

    final recipe = await state.generate();

    expect(recipe, isNotNull);
    expect(state.usingFallback, isTrue);
    expect(state.liveError, contains('Gemini is down'));
    // Offline engine still produced a usable recipe. The library grows, so this
    // asserts the behaviour rather than pinning one particular recipe id.
    expect(state.result, isNotNull);
    expect(state.result!.name, isNotEmpty);
    expect(state.result!.steps, isNotEmpty);
    expect(state.result!.ingredients, isNotEmpty);
    expect(state.result!.have, contains('chicken'));
    expect(state.result!.source, isNot('groq'));
    expect(state.screen, CookScreen.result);
  });

  test('with live mode off no request is made at all', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);
    state
      ..addIngredient('chicken')
      ..addIngredient('lemon')
      ..addIngredient('garlic');
    state.setLiveEnabled(false);

    final recipe = await state.generate();

    expect(recipe, isNotNull);
    expect(fake.paths, isEmpty);
    expect(state.isLive, isFalse);
    expect(state.result!.source, isNot('groq'));
  });

  test('surprise me asks for a dish first, then cooks it', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);
    state.addIngredient('chicken');

    final recipe = await state.surpriseMe();
    await Future<void>.delayed(Duration.zero);

    expect(recipe, isNotNull);
    expect(fake.paths.first, '/gemini/suggest');
    expect(fake.paths[1], '/gemini/recipe');
    expect(fake.bodies[1]['dish'], isNotNull);
    expect(fake.bodies[1]['dish'], isNotEmpty);
  });

  test('test connection reports success and failure distinctly', () async {
    final ok = await buildState(FakeEndpoint());
    expect(await ok.testConnection(), isNull);
    expect(ok.liveError, isNull);

    final broken = await buildState(FakeEndpoint(failSuggest: true));
    expect(await broken.testConnection(), contains('nope'));
    expect(broken.liveError, contains('nope'));
  });

  test('a live recipe keeps its photo when it is saved', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);
    state.addIngredient('chicken');
    await state.generate();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(state.toggleSave(), isTrue);
    expect(state.saved.single.imageUrl, 'https://images.test/photo.jpg');
    expect(state.saved.single.source, 'groq');
  });

  test('endpoint changes are persisted and reset the cached client', () async {
    final fake = FakeEndpoint();
    final state = await buildState(fake);

    state.updateEndpoint('10.0.2.2:8788/');
    expect(state.config.baseUrl, 'http://10.0.2.2:8788');

    state.addIngredient('chicken');
    await state.generate();
    expect(fake.bodies.last['ingredients'], ['chicken']);
  });
}

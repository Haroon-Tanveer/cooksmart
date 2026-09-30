import 'dart:convert';

import 'package:cooksmart/models/recipe.dart';
import 'package:cooksmart/services/groq_config.dart';
import 'package:cooksmart/services/groq_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const Map<String, dynamic> kRecipePayload = {
  'name': 'Charred Lemon Chicken',
  'description': 'A bright pan dinner.',
  'timeMinutes': 28,
  'difficulty': 'medium',
  'servings': 2,
  'emoji': '🍋🍋',
  'imagePrompt': 'charred lemon chicken',
  'owned': ['chicken', 'lemon'],
  'missing': ['olive oil'],
  'calories': 640,
  'ingredients': [
    {'name': 'Chicken', 'quantity': '400 g', 'calories': 260},
    'garlic, 3 cloves',
    {'name': 'butter'},
  ],
  'steps': [
    'Season the chicken.',
    {'text': 'Sear until golden.'},
  ],
};

void main() {
  group('GroqRecipe parsing', () {
    test('normalises messy model output', () {
      final recipe = GroqRecipe.fromJson(kRecipePayload);

      expect(recipe.name, 'Charred Lemon Chicken');
      expect(recipe.timeMinutes, 28);
      expect(recipe.difficulty, 'Medium');
      expect(recipe.servings, 2);
      // A doubled emoji must be trimmed to one glyph so cards stay tidy.
      expect(recipe.emoji, '🍋');
      expect(recipe.owned, ['chicken', 'lemon']);
      expect(recipe.missing, ['olive oil']);
    });

    test('accepts ingredients as objects or as "name, quantity" strings', () {
      final recipe = GroqRecipe.fromJson(kRecipePayload);
      expect(recipe.ingredients, hasLength(3));
      expect(recipe.ingredients[0].name, 'chicken');
      expect(recipe.ingredients[0].qty, '400 g');
      expect(recipe.ingredients[1].name, 'garlic');
      expect(recipe.ingredients[1].qty, '3 cloves');
      expect(recipe.ingredients[2].qty, 'to taste');
    });

    test('accepts steps as strings or as objects', () {
      final recipe = GroqRecipe.fromJson(kRecipePayload);
      expect(recipe.steps, ['Season the chicken.', 'Sear until golden.']);
    });

    test('reads calories per ingredient and for the whole dish', () {
      final recipe = GroqRecipe.fromJson(kRecipePayload);
      expect(recipe.calories, 640);
      expect(recipe.ingredients[0].calories, 260);
      // Lines the model left unpriced stay unknown rather than claiming zero.
      expect(recipe.ingredients[1].calories, isNull);
      expect(recipe.ingredients[2].calories, isNull);
    });

    test('survives a nearly empty payload', () {
      final recipe = GroqRecipe.fromJson(<String, dynamic>{});
      expect(recipe.name, 'Chef’s pick');
      expect(recipe.difficulty, 'Easy');
      expect(recipe.emoji, '🍽');
      expect(recipe.ingredients, isEmpty);
      expect(recipe.steps, isEmpty);
      expect(recipe.calories, isNull);
    });
  });

  group('GroqService', () {
    test('posts ingredients and parses the recipe', () async {
      late Map<String, dynamic> sent;
      final service = GroqService(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          expect(req.url.path, '/gemini/recipe');
          return json(kRecipePayload);
        }),
      );

      final recipe =
          await service.generateRecipe(ingredients: ['Chicken', ' lemon '], servings: 4);

      expect(sent['ingredients'], ['chicken', 'lemon']);
      expect(sent['servings'], 4);
      expect(sent.containsKey('dish'), isFalse);
      expect(recipe.name, 'Charred Lemon Chicken');
    });

    test('sends the dish hint for Surprise me', () async {
      late Map<String, dynamic> sent;
      final service = GroqService(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          return json(kRecipePayload);
        }),
      );

      await service.generateRecipe(ingredients: const [], dish: '  Miso Ramen ');
      expect(sent['dish'], 'Miso Ramen');
    });

    test('refuses to call the API without ingredients or a dish', () async {
      var called = false;
      final service = GroqService(
        baseUrl: 'http://example.test',
        client: MockClient((_) async {
          called = true;
          return json(kRecipePayload);
        }),
      );

      await expectLater(service.generateRecipe(ingredients: const []), throwsA(isA<GroqException>()));
      expect(called, isFalse);
    });

    test('reads dish suggestions', () async {
      final service = GroqService(
        baseUrl: 'http://example.test',
        client: MockClient((req) async {
          expect(req.url.path, '/gemini/suggest');
          return json({
            'names': ['Miso Ramen', 'Za\'atar Flatbread', '  ']
          });
        }),
      );

      final names = await service.suggestDishes(query: 'noodles', count: 3);
      expect(names, ['Miso Ramen', "Za'atar Flatbread"]);
    });

    test('turns a proxy error body into a readable message', () async {
      final service = GroqService(
        baseUrl: 'http://example.test',
        client: MockClient((_) async => json({'error': 'GROQ_API_KEY is not set'}, 503)),
      );

      await expectLater(
        service.suggestDishes(),
        throwsA(isA<GroqException>()
            .having((e) => e.message, 'message', contains('GROQ_API_KEY'))
            .having((e) => e.statusCode, 'statusCode', 503)),
      );
    });

    test('explains an unreachable host instead of leaking a socket error', () async {
      final service = GroqService(
        baseUrl: 'http://example.test',
        client: MockClient((_) async => throw const SocketFailure()),
      );

      await expectLater(
        service.suggestDishes(),
        throwsA(isA<GroqException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
      );
    });

    test('resolves proxy-relative image paths against the endpoint', () async {
      final service = GroqService(
        baseUrl: 'http://10.0.2.2:8788/',
        client: MockClient((_) async => json({'url': '/image/mock-x.png'})),
      );

      final url = await service.generateImageUrl('a bowl of soup');
      expect(url, 'http://10.0.2.2:8788/image/mock-x.png');
    });

    test('passes absolute image URLs straight through', () async {
      final service = GroqService(
        baseUrl: 'http://10.0.2.2:8787',
        client: MockClient((_) async => json({'url': 'https://imgen.x.ai/abc.jpg'})),
      );

      expect(await service.generateImageUrl('x'), 'https://imgen.x.ai/abc.jpg');
    });
  });

  group('GroqConfig', () {
    test('normalises user typed endpoints', () {
      expect(GroqConfig.normalise('10.0.2.2:8787'), 'http://10.0.2.2:8787');
      expect(GroqConfig.normalise(' http://host:1/ '), 'http://host:1');
      expect(GroqConfig.normalise('https://api.example.com/v1/'), 'https://api.example.com/v1');
      expect(GroqConfig.normalise('   '), '');
    });

    test('live requires both an enabled flag and an endpoint', () {
      const off = GroqConfig(baseUrl: 'http://x', liveEnabled: false);
      const on = GroqConfig(baseUrl: 'http://x', liveEnabled: true);
      const empty = GroqConfig(baseUrl: '', liveEnabled: true);
      expect(off.isLive, isFalse);
      expect(on.isLive, isTrue);
      expect(empty.isLive, isFalse);
    });

    test('round-trips through json for storage', () {
      const config = GroqConfig(baseUrl: 'http://10.0.2.2:8788', liveEnabled: true);
      final restored = GroqConfig.fromJson(config.toJson());
      expect(restored.baseUrl, config.baseUrl);
      expect(restored.liveEnabled, isTrue);
    });
  });

  group('Recipe', () {
    test('keeps image fields through a json round trip', () {
      final recipe = Recipe(
        id: 'groq-1',
        name: 'Live Dish',
        emoji: '🍜',
        artStart: 0xFF1A120C,
        artEnd: 0xFF080706,
        desc: 'desc',
        category: 'dinner',
        time: 20,
        difficulty: 'Easy',
        servings: 2,
        ingredients: const [Ingredient('noodles', '200 g')],
        steps: const ['Boil.'],
        imageUrl: 'https://example.test/a.jpg',
        imagePath: '/data/a.jpg',
        imagePrompt: 'a bowl of noodles',
        source: 'groq',
      );

      final restored = Recipe.fromJson(recipe.toJson());
      expect(restored.imageUrl, recipe.imageUrl);
      expect(restored.imagePath, recipe.imagePath);
      expect(restored.imagePrompt, recipe.imagePrompt);
      expect(restored.source, 'groq');
      expect(restored.isLive, isTrue);
    });

    test('a library recipe is not marked live and survives without image fields', () {
      final restored = Recipe.fromJson(<String, dynamic>{
        'id': 'garlic-butter-shrimp',
        'name': 'Garlic Butter Shrimp',
        'artStart': 1,
        'artEnd': 2,
      });
      expect(restored.isLive, isFalse);
      expect(restored.imageUrl, isNull);
      expect(restored.source, 'library');
    });
  });
}

/// Stands in for a transport-level failure.
class SocketFailure implements Exception {
  const SocketFailure();
  @override
  String toString() => 'SocketException: connection refused';
}

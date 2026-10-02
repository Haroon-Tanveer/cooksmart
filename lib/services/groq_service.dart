import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

/// The provider, and which models to try in order.
class AiProvider {
  const AiProvider._();

  /// Groq's public OpenAI-compatible endpoint.
  static const String groqEndpoint = 'https://api.groq.com/openai/v1';

  /// Models to try, in order.
  ///
  /// The Canopylabs Orpheus models look ideal for a bilingual recipe app, but
  /// Groq gates them behind a separate terms acceptance, so they are not usable
  /// from a key alone. Qwen is first because it returns clean, parseable JSON in
  /// well under a second; gpt-oss is the fallback.
  static const List<String> groqModels = <String>[
    'qwen/qwen3.8-27b',
    'openai/gpt-oss-120b',
    'qwen/qwen3-32b',
  ];

  /// Compiled in with `--dart-define=GROQ_API_KEY=...`. Empty by default.
  static const String groqKey = String.fromEnvironment('GROQ_API_KEY');

  /// True when the build talks to Groq directly rather than through a proxy.
  static const bool hasKey = groqKey != '';

  /// The instructions that make the model answer with a usable recipe.
  static const String recipeSystem = '''
You are the head chef inside CookSmart, a recipe app that cooks whatever the user already has.
Reply with ONE JSON object and nothing else. No markdown, no prose, no code fences.
Use plain ASCII characters only. Never use an en dash, an em dash or curly quotes.
Schema:
{
  "name": "string, dish name under 42 chars",
  "description": "string, one or two sentences, appetising, under 180 chars",
  "timeMinutes": number,
  "difficulty": "Easy" | "Medium" | "Hard",
  "servings": number,
  "emoji": "a single food emoji",
  "imagePrompt": "the dish name, used to find a photograph",
  "owned": ["ingredients the user already has, lowercase, from their list only"],
  "missing": ["ingredients they must buy, lowercase"],
  "calories": number,
  "caloriesPerServing": number,
  "ingredients": [{"name": "lowercase ingredient", "quantity": "e.g. 200 g, 2 tbsp", "calories": number}],
  "steps": ["imperative cooking steps, 5 to 7 of them, each under 220 chars"]
}
Use every ingredient the user listed somewhere in the recipe. Invent sensible extras only when a dish
truly needs them, and put those in missing. Quantities must be realistic. Calories are kilocalories for
the quantity as written, so the calories on every ingredient line must add up to the total calories you
report. Give the per-serving figure too. Every step must be actionable: name the heat level, the pan or
oven temperature, and how long to cook, so a beginner can follow it without guessing.''';

  static const String suggestSystem = '''
You are the sous chef of CookSmart, suggesting what to cook next.
Reply with ONE JSON object and nothing else, no code fences: { "names": ["dish name", ...] }
Use plain ASCII characters only. Never use an en dash, an em dash or curly quotes.
Rules: give real, appealing, specific dishes from around the world. No duplicates, no numbering,
under 34 characters each.''';
}

/// Error from the AI service, carrying the HTTP status when there was one.
class GroqException implements Exception {
  GroqException(this.message, {this.statusCode, this.isNetworkError = false});

  final String message;
  final int? statusCode;

  /// True when the request never reached the provider, so a retry may well work.
  final bool isNetworkError;

  @override
  String toString() => message;
}

/// A recipe as the model returned it, before any tidying.
class GroqRecipe {
  const GroqRecipe({
    required this.name,
    required this.description,
    required this.timeMinutes,
    required this.difficulty,
    required this.servings,
    required this.emoji,
    required this.imagePrompt,
    required this.owned,
    required this.missing,
    required this.ingredients,
    required this.steps,
    this.calories,
  });

  factory GroqRecipe.fromJson(Map<String, dynamic> json) {
    return GroqRecipe(
      name: _str(json['name'], 'Chef’s pick'),
      description: _str(json['description']),
      timeMinutes: _num(json['timeMinutes'], 30),
      difficulty: _difficulty(json['difficulty']),
      servings: _num(json['servings'], 2),
      emoji: _firstGlyph(_str(json['emoji'], '🍽')),
      imagePrompt: _str(json['imagePrompt'], _str(json['name'], 'a home cooked dish')),
      owned: _strings(json['owned']),
      missing: _strings(json['missing']),
      calories: _optionalNum(json['calories']),
      ingredients: _ingredients(json['ingredients']),
      steps: _steps(json['steps']),
    );
  }

  final String name;
  final String description;
  final int timeMinutes;
  final String difficulty;
  final int servings;
  final String emoji;
  final String imagePrompt;
  final List<String> owned;
  final List<String> missing;
  final List<Ingredient> ingredients;
  final List<String> steps;

  /// Energy of the whole dish as the model reported it. When the model stays
  /// silent the app sums the ingredient figures instead.
  final int? calories;

  static String _str(Object? v, [String fallback = '']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static int _num(Object? v, int fallback) {
    if (v is num) return v.round().clamp(1, 9999);
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  static int? _optionalNum(Object? v) {
    if (v is num && v.isFinite) return v.round().clamp(0, 99999);
    return int.tryParse(v?.toString() ?? '');
  }

  /// The model writes "medium" as readily as "Medium", so the casing is fixed
  /// here rather than letting it reach the UI.
  static String _difficulty(Object? v) {
    final s = _str(v).toLowerCase();
    for (final level in const <String>['easy', 'medium', 'hard']) {
      if (s.startsWith(level)) {
        return '${level[0].toUpperCase()}${level.substring(1)}';
      }
    }
    return 'Easy';
  }

  /// Keeps one emoji glyph. Models sometimes double them, and a card showing
  /// two lemons in a circle looks like a mistake.
  static String _firstGlyph(String value) {
    final s = value.trim();
    if (s.isEmpty) return s;
    // Walk one grapheme, honouring surrogate pairs, then stop if what follows
    // is the same glyph again.
    final first = s.length > 1 &&
            s.codeUnitAt(0) >= 0xD800 &&
            s.codeUnitAt(0) <= 0xDBFF
        ? s.substring(0, 2)
        : s.substring(0, 1);
    if (s.length > first.length && s.substring(first.length).startsWith(first)) {
      return first;
    }
    return first;
  }

  static List<String> _strings(Object? v) {
    if (v is! List) return const <String>[];
    return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Accepts plain strings and `{"step": "..."}` / `{"text": "..."}` objects.
  static List<String> _steps(Object? v) {
    if (v is! List) return const <String>[];
    final out = <String>[];
    for (final item in v) {
      if (item is Map) {
        final text = _str(item['step'], _str(item['text'], _str(item['instruction'])));
        if (text.isNotEmpty) out.add(text);
      } else {
        final text = _str(item);
        if (text.isNotEmpty) out.add(text);
      }
    }
    return out;
  }

  /// Accepts `"2 cloves"` as well as `{"name": "garlic", "quantity": "2 cloves"}`.
  static List<Ingredient> _ingredients(Object? v) {
    if (v is! List) return const <Ingredient>[];
    final out = <Ingredient>[];
    for (final item in v) {
      if (item is Map) {
        final name = _str(item['name']);
        if (name.isEmpty) continue;
        out.add(Ingredient(
          name.toLowerCase(),
          _str(item['quantity'], 'to taste'),
          calories: _optionalNum(item['calories']),
        ));
      } else {
        final text = _str(item);
        if (text.isEmpty) continue;
        final parts = text.split(RegExp(r'\s*[,–—-]\s*'));
        out.add(Ingredient(
          parts.first.trim().toLowerCase(),
          parts.length > 1 ? parts.sublist(1).join(', ') : 'to taste',
        ));
      }
    }
    return out;
  }
}

/// Client for the CookSmart AI features.
///
/// When the build carries a Groq key the app calls Groq directly, so there is no
/// server to run. Otherwise it talks to a proxy, which is how a build without a
/// key stays usable offline.
class GroqService {
  GroqService({required this.baseUrl, this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;

  /// Set when calling Groq directly; null when going through a proxy.
  final String? apiKey;
  final http.Client _client;

  bool get _direct => apiKey != null && apiKey!.isNotEmpty;

  static const Duration _chatTimeout = Duration(seconds: 60);


  /// Sends a chat completion and returns the JSON object inside it.
  ///
  /// Calling the provider directly is one OpenAI-shaped request. Going through a
  /// proxy instead uses the small per-route payloads the proxy exposes, which
  /// keeps the offline build and the test fakes working unchanged.
  Future<Map<String, dynamic>> _chat(
    String kind,
    String system,
    String user, {
    required Map<String, dynamic> proxyBody,
  }) async {
    if (!_direct) {
      return _send('/groq/$kind', proxyBody, timeout: _chatTimeout);
    }

    final body = <String, dynamic>{
      'model': AiProvider.groqModels.first,
      'stream': false,
      'temperature': 0.7,
      'max_tokens': 4000,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': system},
        <String, String>{'role': 'user', 'content': user},
      ],
    };

    final decoded = await _send(_chatPath, body, timeout: _chatTimeout);
    // Groq answers in the OpenAI shape, so the JSON is a step further down. A
    // proxy answers with the recipe already at the top level.
    if (decoded.containsKey('choices')) return _unwrap(decoded);
    return decoded;
  }

  static const String _chatPath = '/chat/completions';

  /// Pulls the JSON object out of a completion, whatever wrapper it is in.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> decoded) {
    String? text;
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = (choices.first as Map?)?['message'];
      if (message is Map) text = message['content']?.toString();
    }
    text ??= decoded['content']?.toString();
    if (text == null) {
      final candidates = decoded['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final parts = ((candidates.first as Map?)?['content'] as Map?)?['parts'];
        if (parts is List) {
          text = parts
              .map((p) => (p as Map?)?['text']?.toString() ?? '')
              .join();
        }
      }
    }
    if (text == null || text.trim().isEmpty) {
      throw GroqException('The AI service returned an empty reply.');
    }
    return _extractJson(text);
  }

  /// Finds the first balanced JSON object in a model reply.
  static Map<String, dynamic> _extractJson(String text) {
    final cleaned = text.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '');
    final start = cleaned.indexOf('{');
    if (start == -1) {
      throw GroqException('The AI service did not return a recipe.');
    }
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < cleaned.length; i++) {
      final ch = cleaned[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          return jsonDecode(cleaned.substring(start, i + 1)) as Map<String, dynamic>;
        }
      }
    }
    throw GroqException('The AI service sent an incomplete recipe. Try again.');
  }

  Future<Map<String, dynamic>> _send(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = _chatTimeout,
  }) async {
    // Live generation is on by default now, so a build made without a key would
    // otherwise fail on every recipe with a bare connection error. Saying what is
    // missing is far more useful than a timeout.
    if (!_direct && baseUrl.trim().isEmpty) {
      throw GroqException(
        'This build has no AI key. Rebuild with '
        '--dart-define=GROQ_API_KEY=... to generate recipes with Groq.',
      );
    }
    // The conditional belongs outside the string: inside it, the ? and : would
    // end up in the URL as literal characters.
    final uri = Uri.parse(
      _direct ? '${AiProvider.groqEndpoint}$path' : '$baseUrl$path',
    );
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_direct) headers['Authorization'] = 'Bearer $apiKey';

    late http.Response res;
    try {
      res = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);
    } catch (_) {
      throw GroqException(
        _direct
            ? 'Could not reach Groq. Check your connection.'
            : 'Could not reach the AI service at $baseUrl.',
        isNetworkError: true,
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw GroqException(
        'The AI service returned an unexpected response (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode != 200) {
      final error = decoded['error'];
      final message = error is Map
          ? error['message']?.toString()
          : error?.toString();
      throw GroqException(
        message ?? 'The AI service returned an error (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    return decoded;
  }

  /// Builds a recipe around whatever the cook already has.
  ///
  /// [dish] steers the result when the cook picked an idea rather than a
  /// pantry, which is what "Surprise me" does on the Create screen.
  Future<GroqRecipe> generateRecipe({
    required List<String> ingredients,
    int? servings,
    String? dish,
  }) async {
    final clean = ingredients.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
    if (clean.isEmpty && (dish == null || dish.trim().isEmpty)) {
      throw GroqException('Add at least one ingredient first.');
    }

    final brief = <String>[];
    if (clean.isNotEmpty) brief.add('The cook has: ${clean.join(", ")}.');
    if (servings != null) brief.add('Cook for $servings people.');
    brief.add(
      dish == null || dish.trim().isEmpty
          ? 'Build the single best recipe for exactly those ingredients.'
          : 'They want to cook "${dish.trim()}" - make that the dish, still using everything they have.',
    );

    final proxyBody = <String, dynamic>{'ingredients': clean};
    if (servings != null) proxyBody['servings'] = servings;
    if (dish != null && dish.trim().isNotEmpty) proxyBody['dish'] = dish.trim();

    final json = await _chat(
      'recipe',
      AiProvider.recipeSystem,
      brief.join('\n'),
      proxyBody: proxyBody,
    );
    final recipe = GroqRecipe.fromJson(json);
    if (recipe.ingredients.isEmpty || recipe.steps.isEmpty) {
      throw GroqException('The AI service sent an incomplete recipe. Try again.');
    }
    return recipe;
  }

  /// Dish ideas for the Create screen.
  Future<List<String>> suggestDishes({String? query, int count = 6}) async {
    final n = count.clamp(1, 12);
    final ask = query == null || query.trim().isEmpty
        ? 'Suggest $n dinner dishes for an adventurous home cook.'
        : 'Suggest $n dishes that use or pair with "${query.trim()}".';
    final json = await _chat(
      'suggest',
      AiProvider.suggestSystem,
      ask,
      proxyBody: <String, dynamic>{
        'count': n,
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );
    final names = (json['names'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(n)
            .toList() ??
        const <String>[];
    if (names.isEmpty) throw GroqException('No suggestions came back. Try again.');
    return names;
  }

  /// Finds a photograph for the finished recipe.
  ///
  /// [prompt] is the dish name the model suggested, which is usually the most
  /// searchable form; [dish] is the recipe's own name and is tried second.
  ///
  /// With a proxy the lookup goes through it, so the image is fetched once and
  /// cached on the server. Calling the provider directly, the app asks the free
  /// photo API itself.
  Future<String> generateImageUrl(String prompt, {String? dish}) async {
    final first = prompt.trim();
    final second = dish?.trim() ?? '';
    if (first.isEmpty && second.isEmpty) {
      throw GroqException('Nothing to illustrate.');
    }

    if (!_direct) {
      final json = await _send(
        '/groq/image',
        <String, dynamic>{
          'prompt': first.isEmpty ? second : first,
          if (second.isNotEmpty) 'dish': second,
        },
        timeout: const Duration(seconds: 30),
      );
      final url = json['url']?.toString().trim() ?? '';
      if (url.isEmpty) {
        throw GroqException('The AI service returned no image.');
      }
      // A proxy serves its own cached files under /image, so a relative path
      // has to be resolved against the proxy rather than treated as final.
      return absolute(url);
    }

    for (final candidate in <String>[first, second]) {
      if (candidate.isEmpty) continue;
      final url = await _theMealDb(candidate);
      if (url != null) return url;
    }
    throw GroqException('No photograph of that dish is available yet.');
  }

  /// Grok is asked to name the dish, then the free photo API is queried for it.
  Future<String> photoForRecipe(GroqRecipe recipe) =>
      generateImageUrl(recipe.imagePrompt, dish: recipe.name);

  /// Finds a photograph for [dish] by looking it up on TheMealDB.
  ///
  /// Neither provider is asked to generate an image, which is billed per image;
  /// a real photograph of the dish is both cheaper and more convincing.
  Future<String> photoFor(String dish) => generateImageUrl(dish);

  /// Resolves a proxy-relative path (`/image/x.jpg`) against the endpoint.
  String absolute(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = Uri.parse(baseUrl);
    return '${base.scheme}://${base.authority}${url.startsWith('/') ? url : '/$url'}';
  }

  Future<String?> _theMealDb(String query) async {
    final uri = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/search.php'
      '?s=${Uri.encodeComponent(query)}',
    );
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final meals = decoded['meals'] as List?;
      if (meals == null || meals.isEmpty) return null;
      final thumb = (meals.first as Map)['strMealThumb']?.toString() ?? '';
      return thumb.isEmpty ? null : thumb;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();

  @visibleForTesting
  static GroqService withClient(String baseUrl, http.Client client) =>
      GroqService(baseUrl: baseUrl, client: client);
}

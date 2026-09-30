import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

/// A failure the UI can explain to the user in one line.
class GroqException implements Exception {
  GroqException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isAuthError =>
      statusCode == 401 || statusCode == 403 || message.toLowerCase().contains('api key');

  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}

/// A recipe as it comes back from the model, before it is adapted to the app.
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

  factory GroqRecipe.fromJson(Map<String, dynamic> json) {
    return GroqRecipe(
      name: _str(json['name'], 'Chef’s pick'),
      description: _str(json['description']),
      timeMinutes: _num(json['timeMinutes'], 30),
      difficulty: _difficulty(json['difficulty']),
      servings: _num(json['servings'], 2),
      emoji: _emoji(json['emoji']),
      imagePrompt: _str(json['imagePrompt'], _str(json['name'])),
      owned: _strList(json['owned']),
      missing: _strList(json['missing']),
      ingredients: _ingredients(json['ingredients']),
      steps: _steps(json['steps']),
      calories: _optionalNum(json['calories']),
    );
  }

  static String _str(Object? v, [String fallback = '']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static int _num(Object? v, int fallback) {
    if (v is num) return v.round().clamp(1, 9999);
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  /// Like [_num] but keeps "the model did not say" distinct from zero.
  static int? _optionalNum(Object? v) {
    if (v is num && v.isFinite) return v.round().clamp(0, 99999);
    return int.tryParse(v?.toString() ?? '');
  }

  static String _difficulty(Object? v) {
    final s = v?.toString().trim().toLowerCase() ?? '';
    if (s.startsWith('e')) return 'Easy';
    if (s.startsWith('m')) return 'Medium';
    if (s.startsWith('h')) return 'Hard';
    return 'Easy';
  }

  static String _emoji(Object? v) {
    final s = v?.toString().trim() ?? '';
    // Keep it to a single glyph so cards never render two dishes.
    if (s.isEmpty) return '🍽';
    final first = String.fromCharCodes(s.runes.take(1));
    return first;
  }

  static List<String> _strList(Object? v) {
    if (v is! List) return const <String>[];
    return v
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
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
}

/// Thin client for the CookSmart Gemini proxy.
///
/// Requests are short-lived and non-streaming: recipe generation is one call,
/// and a streaming UI would add a parsing surface for no user-visible gain.
class GroqService {
  GroqService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const Duration _chatTimeout = Duration(seconds: 90);
  static const Duration _imageTimeout = Duration(seconds: 120);

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = _chatTimeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on GroqException {
      rethrow;
    } catch (e) {
      throw GroqException('Could not reach the Gemini proxy at $baseUrl.');
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
      throw GroqException(
        (decoded['error']?.toString() ?? 'The AI service returned an error.'),
        statusCode: res.statusCode,
      );
    }
    return decoded;
  }

  /// Builds a recipe around whatever the cook already has.
  ///
  /// [dish] steers the result when the cook picked an idea rather than a
  /// pantry, e.g. "Surprise me" on the Create screen.
  Future<GroqRecipe> generateRecipe({
    required List<String> ingredients,
    int? servings,
    String? dish,
  }) async {
    final clean = ingredients.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
    if (clean.isEmpty && (dish == null || dish.trim().isEmpty)) {
      throw GroqException('Add at least one ingredient first.');
    }
    final dishHint = (dish == null || dish.trim().isEmpty) ? null : dish.trim();
    final payload = <String, dynamic>{'ingredients': clean};
    if (servings != null) payload['servings'] = servings;
    if (dishHint != null) payload['dish'] = dishHint;
    final json = await _post('/gemini/recipe', payload);
    return GroqRecipe.fromJson(json);
  }

  /// Dish-name suggestions, optionally steered by a query.
  Future<List<String>> suggestDishes({String? query, int count = 6}) async {
    final payload = <String, dynamic>{'count': count};
    final clean = query?.trim();
    if (clean != null && clean.isNotEmpty) payload['query'] = clean;
    final json = await _post('/gemini/suggest', payload);
    final names = (json['names'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    if (names.isEmpty) {
      throw GroqException('The AI service returned no suggestions.');
    }
    return names;
  }

  /// Fetches a food photo for [dish] and returns an absolute URL.
  ///
  /// Gemini image generation is billed per image, so the proxy looks up a real
  /// photograph of the dish and sends back its URL. [prompt] is used as the
  /// fallback search term when there is no dish name.
  Future<String> generateImageUrl(String prompt, {String? dish}) async {
    if (prompt.trim().isEmpty) {
      throw GroqException('Nothing to illustrate.');
    }
    final name = dish?.trim() ?? '';
    final json = await _post(
      '/gemini/image',
      {
        'prompt': prompt.trim(),
        if (name.isNotEmpty) 'dish': name,
      },
      timeout: _imageTimeout,
    );
    final url = json['url']?.toString().trim() ?? '';
    if (url.isEmpty) {
      throw GroqException('The AI service returned no image.');
    }
    return absolute(url);
  }

  /// Resolves proxy-relative paths (`/image/x.jpg`) against the configured host.
  String absolute(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = Uri.parse(baseUrl);
    return '${base.scheme}://${base.authority}${url.startsWith('/') ? url : '/$url'}';
  }

  void dispose() => _client.close();

  @visibleForTesting
  static GroqService withClient(String baseUrl, http.Client client) =>
      GroqService(baseUrl: baseUrl, client: client);
}

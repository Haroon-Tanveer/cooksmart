import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/recipe_engine.dart';
import '../data/recipes.dart';
import '../models/recipe.dart';
import '../services/groq_config.dart';
import '../services/groq_service.dart';
import '../services/image_cache.dart';

const String _savedKey = 'cooksmart.saved.v1';
const String _groqKey = 'cooksmart.groq.v1';
const String _localeKey = 'cooksmart.locale.v1';
const String _themeKey = 'cooksmart.theme.v1';

enum CookScreen { home, ingredients, result, saved }

/// Single source of truth shared by all four screens.
class AppState extends ChangeNotifier {
  /// Both the live service and the image cache share [httpClient] so tests can
  /// stub every network call with one mock.
  factory AppState({http.Client? httpClient, ImageCacheService? images}) {
    return AppState._(
      httpClient: httpClient,
      images: images ?? ImageCacheService(client: httpClient),
    );
  }

  AppState._({required this.httpClient, required this._images});

  final http.Client? httpClient;

  CookScreen _screen = CookScreen.home;
  CookScreen get screen => _screen;

  CookScreen _lastTab = CookScreen.home;
  CookScreen get lastTab => _lastTab;

  String _activeCategory = 'all';
  String get activeCategory => _activeCategory;

  /// Null means "follow the device language", which is what most people want.
  Locale? _locale;

  /// The language the app is shown in, or null to follow the device.
  Locale? get locale => _locale;

  /// Switches the app language, or returns to following the device with [null].
  Future<void> setLocale(Locale? value) async {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    await _prefs?.setString(_localeKey, value?.languageCode ?? '');
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Light, dark, or follow the phone's setting.
  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    await _prefs?.setString(_themeKey, value.name);
  }

  String _search = '';
  String get search => _search;

  final List<String> _ingredients = <String>[];
  List<String> get ingredients => List.unmodifiable(_ingredients);
  bool get canGenerate => _ingredients.isNotEmpty;

  Recipe? _result;
  Recipe? get result => _result;

  final List<Recipe> _saved = <Recipe>[];
  List<Recipe> get saved => List.unmodifiable(_saved);
  bool isSaved(Recipe r) => _saved.any((s) => s.id == r.id);

  final Set<String> _checked = <String>{};
  final Set<String> _stepsDone = <String>{};

  /* ---------------- live service ---------------- */

  GroqConfig _config = GroqConfig(
    baseUrl: GroqConfig.defaultBaseUrl,
    liveEnabled: GroqConfig.defaultLiveEnabled,
  );
  GroqConfig get config => _config;

  bool get isLive => _config.isLive;
  String? get liveError => _config.lastError;

  /// True while a request is in flight, so buttons can show progress.
  bool _busy = false;
  bool get isBusy => _busy;
  String? _busyLabel;
  String? get busyLabel => _busyLabel;

  /// True when the last live attempt failed and the offline engine took over.
  bool _usingFallback = false;
  bool get usingFallback => _usingFallback;

  List<String> _dishIdeas = const <String>[];
  List<String> get dishIdeas => List.unmodifiable(_dishIdeas);

  GroqService? _groq;
  final ImageCacheService _images;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_savedKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _saved
          ..clear()
          ..addAll(decoded.map((e) => Recipe.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (e) {
        debugPrint('CookSmart: could not read saved recipes ($e)');
      }
    }

  final rawConfig = _prefs?.getString(_groqKey);
  if (rawConfig != null && rawConfig.isNotEmpty) {
    try {
      _config = GroqConfig.fromJson(
        jsonDecode(rawConfig) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('CookSmart: could not read AI settings ($e)');
    }
  }

  // An empty string means the user never chose, so follow the device.
  final savedLocale = _prefs?.getString(_localeKey) ?? '';
  _locale = savedLocale.isEmpty ? null : Locale(savedLocale);

  // A missing value means "follow the phone", which is the sensible default.
  final savedTheme = _prefs?.getString(_themeKey);
  _themeMode = ThemeMode.values.firstWhere(
    (m) => m.name == savedTheme,
    orElse: () => ThemeMode.system,
  );

    notifyListeners();
  }

  /* ---------------- settings ---------------- */

  void updateEndpoint(String raw) {
    _config = _config.copyWith(
      baseUrl: GroqConfig.normalise(raw),
      clearError: true,
    );
    _resetService();
    _persistConfig();
    notifyListeners();
  }

  void setLiveEnabled(bool enabled) {
    _config = _config.copyWith(liveEnabled: enabled, clearError: true);
    _usingFallback = false;
    _persistConfig();
    notifyListeners();
  }

  void useMockEndpoint() => updateEndpoint(GroqConfig.emulatorMockUrl);

  void useProxyEndpoint() => updateEndpoint(GroqConfig.emulatorProxyUrl);

  void _persistConfig() {
    _prefs?.setString(_groqKey, jsonEncode(_config.toJson()));
  }

  GroqService get _service {
    return _groq ??= GroqService(
      baseUrl: _config.baseUrl,
      // Null unless the build carries a key, which is what makes the client call
      // Groq directly instead of a proxy.
      apiKey: AiProvider.hasKey ? AiProvider.groqKey : null,
      client: httpClient,
    );
  }

  /// Drops the cached client so the next call picks up a new endpoint.
  void _resetService() {
    _groq?.dispose();
    _groq = null;
  }

  void _setBusy(String? label) {
    _busy = label != null;
    _busyLabel = label;
    notifyListeners();
  }

  void _recordError(GroqException e) {
    _config = _config.copyWith(lastError: e.message);
    _persistConfig();
  }

  void clearLiveError() {
    if (_config.lastError == null) return;
    _config = _config.copyWith(clearError: true);
    _persistConfig();
    notifyListeners();
  }

  /* ---------------- navigation ---------------- */

  void go(CookScreen next) {
    if (next != CookScreen.result) _lastTab = next;
    _screen = next;
    notifyListeners();
  }

  void goBack() => go(_lastTab);

  /* ---------------- home filters ---------------- */

  void setCategory(String id) {
    _activeCategory = id;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void resetFilters() {
    _activeCategory = 'all';
    _search = '';
    notifyListeners();
  }

  bool matchesFilters(Recipe recipe) {
    if (_activeCategory == 'quick' && recipe.time > 20) return false;
    if (_activeCategory != 'all' &&
        _activeCategory != 'quick' &&
        recipe.category != _activeCategory &&
        !recipe.alsoCategories.contains(_activeCategory)) {
      return false;
    }
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = <String>[
      recipe.name,
      recipe.desc,
      ...recipe.ingredients.map((i) => i.name),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  List<Recipe> get filteredRecipes =>
      kRecipes.where(matchesFilters).toList(growable: false);

  bool get isFiltering => _search.trim().isNotEmpty || _activeCategory != 'all';

  /* ---------------- ingredients ---------------- */

  bool addIngredient(String raw) {
    final value = raw.trim().replaceAll(',', '').toLowerCase();
    if (value.isEmpty) return false;
    if (_ingredients.contains(value)) return false;
    _ingredients.add(value);
    notifyListeners();
    return true;
  }

  void removeIngredient(String value) {
    if (_ingredients.remove(value)) notifyListeners();
  }

  void clearIngredients() {
    if (_ingredients.isEmpty) return;
    _ingredients.clear();
    notifyListeners();
  }

  /// Generates a recipe from the cook's ingredients.
  ///
  /// Prefers the live service; if it is unreachable or errors, the offline
  /// engine still returns a recipe so the user is never left at a dead end, and
  /// [usingFallback] records why.
  Future<Recipe?> generate({String? dish}) async {
    if (_ingredients.isEmpty && (dish == null || dish.trim().isEmpty)) return null;

    if (_config.isLive) {
      _setBusy('Asking Groq…');
      try {
        final grok = await _service
            .generateRecipe(ingredients: _ingredients, dish: dish)
            .timeout(const Duration(seconds: 95));
        final recipe = _recipeFromGroq(grok, dishHint: dish);
        _usingFallback = false;
        _config = _config.copyWith(clearError: true);
        _setBusy(null);
        _showRecipe(recipe);
        unawaited(_attachImage(recipe));
        return recipe;
      } on GroqException catch (e) {
        _recordError(e);
        _usingFallback = true;
      } catch (e) {
        _recordError(GroqException('The AI service did not respond in time.'));
        _usingFallback = true;
      } finally {
        _setBusy(null);
      }
    }

    final local = generateRecipe(_ingredients);
    if (local != null) _showRecipe(local);
    return local;
  }

  /// "Surprise me": asks the live service for a dish idea, then cooks it.
  Future<Recipe?> surpriseMe() async {
    if (!_config.isLive) return generate();
    _setBusy('Picking a dish…');
    String? dish;
    try {
      final ideas = await _service.suggestDishes(count: 1);
      dish = ideas.first;
    } on GroqException catch (e) {
      _recordError(e);
      _usingFallback = true;
      _setBusy(null);
      return generate();
    }
    _setBusy('Asking Groq…');
    try {
      final grok = await _service
          .generateRecipe(ingredients: _ingredients, dish: dish)
          .timeout(const Duration(seconds: 95));
      final recipe = _recipeFromGroq(grok, dishHint: dish);
      _usingFallback = false;
      _config = _config.copyWith(clearError: true);
      _showRecipe(recipe);
      unawaited(_attachImage(recipe));
      return recipe;
    } on GroqException catch (e) {
      _recordError(e);
      _usingFallback = true;
      return generate();
    } finally {
      _setBusy(null);
    }
  }

  /// Probes the configured endpoint and returns null on success, or the reason
  /// it failed. Used by the settings sheet so setup is verifiable in-app.
  Future<String?> testConnection() async {
    if (!_config.isLive) return 'Live AI is switched off.';
    _setBusy('Testing…');
    try {
      final ideas = await _service
          .suggestDishes(count: 1)
          .timeout(const Duration(seconds: 25));
      debugPrint('CookSmart: endpoint ok, sample idea "${ideas.first}"');
      _config = _config.copyWith(clearError: true);
      _persistConfig();
      return null;
    } on GroqException catch (e) {
      _recordError(e);
      return e.message;
    } catch (_) {
      return 'The endpoint did not respond in time.';
    } finally {
      _setBusy(null);
    }
  }

  void _showRecipe(Recipe recipe) {
    _result = recipe;
    _checked.clear();
    _stepsDone.clear();
    go(CookScreen.result);
  }

  Recipe _recipeFromGroq(GroqRecipe grok, {String? dishHint}) {
    final owned = grok.owned.isEmpty && dishHint == null
        ? List<String>.from(_ingredients)
        : grok.owned;
    // Never list the same item as both owned and missing, whatever the model says.
    final ownedKeys = owned.map((e) => e.trim().toLowerCase()).toSet();
    final missing = grok.missing
        .where((e) => !ownedKeys.contains(e.trim().toLowerCase()))
        .toList();
    final matched = owned.length;
    final total = grok.ingredients.isEmpty ? matched : grok.ingredients.length;
    final pct = (matched * 70 / (total == 0 ? 1 : total) + 30).round().clamp(20, 100);
    final ideaOnly = _ingredients.isEmpty;

    return Recipe(
      id: 'groq-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: grok.name,
      emoji: grok.emoji,
      artStart: 0xFF4A2A12,
      artEnd: 0xFF1D1610,
      desc: grok.description.isEmpty
          ? 'Built by Groq from what you had in the kitchen.'
          : grok.description,
      category: 'dinner',
      time: grok.timeMinutes,
      difficulty: grok.difficulty,
      servings: grok.servings,
      ingredients: grok.ingredients,
      steps: grok.steps,
      // A match score is meaningless when the cook never listed ingredients.
      match: ideaOnly ? 100 : pct,
      matchLabel: ideaOnly ? 'Groq’s pick' : '$pct% match',
      basedOn: List<String>.from(_ingredients),
      have: owned,
      missing: missing,
      imagePrompt: grok.imagePrompt,
      source: 'groq',
      calories: grok.calories,
    );
  }

  /// Fetches the dish photo in the background so the result appears instantly.
  Future<void> _attachImage(Recipe recipe) async {
    if (!_config.isLive) return;
    try {
      final url = await _service.generateImageUrl(
        recipe.imagePrompt ?? recipe.name,
        dish: recipe.name,
      );
      final file = await _images.fetch(url);
      final patched = recipe.copyWith(imageUrl: url, imagePath: file?.path);
      if (_result?.id == recipe.id) {
        _result = patched;
        notifyListeners();
      }
      if (_saved.any((s) => s.id == recipe.id)) {
        final index = _saved.indexWhere((s) => s.id == recipe.id);
        _saved[index] = patched;
        _persistSaved();
      }
    } on GroqException catch (e) {
      debugPrint('CookSmart: image generation failed: ${e.message}');
    } catch (e) {
      debugPrint('CookSmart: image generation error: $e');
    }
  }

  /// Refetches the photo for the current result.
  Future<void> retryImage() async {
    final recipe = _result;
    if (recipe == null || recipe.imagePrompt == null) return;
    _setBusy('Finding the photo…');
    try {
      await _attachImage(recipe.copyWith(imageUrl: null, imagePath: null));
    } finally {
      _setBusy(null);
    }
  }

  /// Asks the live service for dish names to offer as one-tap suggestions.
  Future<void> refreshDishIdeas({String? query}) async {
    if (!_config.isLive) {
      _dishIdeas = List<String>.from(kDishIdeas);
      notifyListeners();
      return;
    }
    _setBusy('Thinking of dishes…');
    try {
      _dishIdeas = await _service.suggestDishes(query: query, count: 6);
      _config = _config.copyWith(clearError: true);
    } on GroqException catch (e) {
      _recordError(e);
      _dishIdeas = List<String>.from(kDishIdeas);
    } catch (_) {
      _dishIdeas = List<String>.from(kDishIdeas);
    } finally {
      _setBusy(null);
    }
  }

  /* ---------------- result interactions ---------------- */

  void openLibraryRecipe(Recipe recipe) {
    _result = recipe.copyWith(
      match: recipe.match ?? 100,
      matchLabel: recipe.matchLabel ?? 'From the library',
      basedOn: recipe.basedOn.isNotEmpty
          ? recipe.basedOn
          : recipe.ingredients.map((i) => i.name).toList(),
      have: recipe.ingredients.map((i) => i.name).toList(),
      missing: const <String>[],
    );
    _checked.clear();
    _stepsDone.clear();
    go(CookScreen.result);
  }

  void openSavedRecipe(Recipe recipe) {
    _result = recipe.copyWith(have: recipe.basedOn);
    _checked.clear();
    _stepsDone.clear();
    go(CookScreen.result);
  }

  void toggleIngredient(String name) {
    final key = '${_result?.id}::$name';
    if (!_checked.remove(key)) _checked.add(key);
    notifyListeners();
  }

  void toggleStep(int index) {
    final key = '${_result?.id}::s$index';
    if (!_stepsDone.remove(key)) _stepsDone.add(key);
    notifyListeners();
  }

  bool isIngredientChecked(String name) =>
      _checked.contains('${_result?.id}::$name');

  bool isStepDone(int index) => _stepsDone.contains('${_result?.id}::s$index');

  bool toggleSave() {
    final r = _result;
    if (r == null) return false;
    final index = _saved.indexWhere((s) => s.id == r.id);
    final nowSaved = index == -1;
    if (nowSaved) {
      _saved.insert(0, r.copyWith(savedAt: DateTime.now().millisecondsSinceEpoch));
    } else {
      _saved.removeAt(index);
    }
    _persistSaved();
    notifyListeners();
    return nowSaved;
  }

  void removeSaved(String id) {
    final index = _saved.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _saved.removeAt(index);
    _persistSaved();
    notifyListeners();
  }

  void clearSaved() {
    if (_saved.isEmpty) return;
    _saved.clear();
    _persistSaved();
    notifyListeners();
  }

  void _persistSaved() {
    final json = jsonEncode(_saved.map((r) => r.toJson()).toList());
    _prefs?.setString(_savedKey, json);
  }

  @override
  void dispose() {
    _groq?.dispose();
    _images.dispose();
    super.dispose();
  }
}

/// Fire-and-forget helper so background image work does not need an await.
void unawaited(Future<void> future) {
  future.catchError((Object e) => debugPrint('CookSmart: background task failed: $e'));
}

/// Minimal InheritedNotifier so screens can read [AppState] without extra packages.
class CookScope extends InheritedNotifier<AppState> {
  const CookScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CookScope>();
    assert(scope != null, 'CookScope not found in the widget tree');
    return scope!.notifier!;
  }
}

import 'package:flutter/material.dart';

class Ingredient {
  const Ingredient(this.name, this.qty, {this.calories});

  final String name;
  final String qty;

  /// Energy of this line as listed, in kilocalories. Null when unknown, so the
  /// UI can stay quiet instead of claiming a precise-looking zero.
  final int? calories;

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        if (calories != null) 'calories': calories,
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        json['name'] as String? ?? '',
        json['qty'] as String? ?? '',
        calories: (json['calories'] as num?)?.round(),
      );
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.artStart,
    required this.artEnd,
    required this.desc,
    required this.category,
    required this.time,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
    required this.steps,
    this.match,
    this.matchLabel,
    this.basedOn = const <String>[],
    this.have = const <String>[],
    this.missing = const <String>[],
    this.savedAt,
    this.imageUrl,
    this.imagePath,
    this.imagePrompt,
    this.source = 'library',
    this.calories,
    this.imageAsset,
    this.extraImages = const <String>[],
    this.alsoCategories = const <String>[],
  });

  final String id;
  final String name;
  final String emoji;
  final int artStart;
  final int artEnd;
  final String desc;
  final String category;
  final int time;
  final String difficulty;
  final int servings;
  final List<Ingredient> ingredients;
  final List<String> steps;

  final int? match;
  final String? matchLabel;
  final List<String> basedOn;
  final List<String> have;
  final List<String> missing;
  final int? savedAt;

  /// Remote photo of the finished dish, produced by the image model.
  final String? imageUrl;

  /// Absolute path of the cached copy, so saved recipes keep their photo.
  final String? imagePath;

  /// Prompt used to generate [imageUrl], kept so the photo can be retried.
  final String? imagePrompt;

  /// `library`, `local` (offline engine) or `Groq`/`mock` (live service).
  final String source;

  /// Energy of the whole dish in kilocalories. Library recipes leave this null
  /// and get it from their ingredient lines, so the two can never drift apart.
  final int? calories;

  /// Bundled photograph, e.g. `assets/recipes/baklava.jpg`. Library recipes ship
  /// with a real picture, so they look right with no network and no proxy.
  final String? imageAsset;

  /// Further photographs of this same dish, shown as a swipeable gallery.
  /// Only files that genuinely name the dish are added here; a related but
  /// different dish does not belong in this recipe's gallery.
  final List<String> extraImages;

  /// Every photograph for this recipe, in the order they should be swiped.
  List<String> get images => <String>[
        if (imageAsset != null && imageAsset!.isNotEmpty) imageAsset!,
        ...extraImages.where((p) => p != imageAsset && p.isNotEmpty),
      ];

  /// Extra filters this recipe should also appear under, so a baklava shows up
  /// under both Arabian and Dessert rather than only its home cuisine.
  final List<String> alsoCategories;

  bool get isLive => source == 'groq' || source == 'mock';

  bool get isGenerated => id.startsWith('gen-') || isLive;

  /// Energy of the finished dish, summed from the ingredients when the source
  /// did not state a total. Null when no ingredient carries a figure.
  int? get totalCalories {
    if (calories != null) return calories;
    final known =
        ingredients.where((i) => i.calories != null).map((i) => i.calories!).toList();
    if (known.isEmpty) return null;
    return known.fold<int>(0, (a, b) => a + b);
  }

  /// Energy for one serving, rounded to something a person would read.
  int? get caloriesPerServing {
    final total = totalCalories;
    if (total == null || servings < 1) return null;
    return (total / servings).round();
  }

  /// Ingredients the cook actually has.
  ///
  /// Library recipes list everything they need, so an empty [have] means "all of
  /// them". A generated recipe with an empty [have] instead falls back to
  /// "everything except what it asked the cook to buy", so the two never clash.
  List<String> get haveTokens {
    if (have.isNotEmpty) return have;
    final names = ingredients.map((i) => i.name).toList();
    if (!isGenerated) return names;
    final notOwned = missing.map((m) => m.trim().toLowerCase()).toSet();
    return names.where((n) => !notOwned.contains(n.trim().toLowerCase())).toList();
  }

  LinearGradient get art => LinearGradient(
        begin: const Alignment(-0.5, -0.9),
        end: const Alignment(0.6, 0.9),
        colors: [Color(artStart), Color(artEnd)],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'artStart': artStart,
        'artEnd': artEnd,
        'desc': desc,
        'category': category,
        'time': time,
        'difficulty': difficulty,
        'servings': servings,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps,
        'match': match,
        'matchLabel': matchLabel,
        'basedOn': basedOn,
        'have': have,
        'missing': missing,
        'savedAt': savedAt,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'imagePrompt': imagePrompt,
        'source': source,
        'calories': calories,
        'imageAsset': imageAsset,
        'extraImages': extraImages,
        'alsoCategories': alsoCategories,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🍽',
        artStart: json['artStart'] as int? ?? 0xFF3A2A1C,
        artEnd: json['artEnd'] as int? ?? 0xFF1A1610,
        desc: json['desc'] as String? ?? '',
        category: json['category'] as String? ?? 'dinner',
        time: json['time'] as int? ?? 0,
        difficulty: json['difficulty'] as String? ?? 'Easy',
        servings: json['servings'] as int? ?? 2,
        ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
            .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        steps: (json['steps'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        match: json['match'] as int?,
        matchLabel: json['matchLabel'] as String?,
        basedOn: (json['basedOn'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        have: (json['have'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        missing: (json['missing'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        savedAt: json['savedAt'] as int?,
        imageUrl: json['imageUrl'] as String?,
        imagePath: json['imagePath'] as String?,
        imagePrompt: json['imagePrompt'] as String?,
        source: json['source'] as String? ?? 'library',
        calories: (json['calories'] as num?)?.round(),
        imageAsset: json['imageAsset'] as String?,
        extraImages: (json['extraImages'] as List?)?.cast<String>() ?? const <String>[],
        alsoCategories: (json['alsoCategories'] as List?)?.cast<String>() ?? const <String>[],
      );

  Recipe copyWith({
    int? match,
    String? matchLabel,
    List<String>? basedOn,
    List<String>? have,
    List<String>? missing,
    int? savedAt,
    String? imageUrl,
    String? imagePath,
    String? imagePrompt,
    String? source,
    int? calories,
    String? imageAsset,
    List<String>? extraImages,
    List<String>? alsoCategories,
  }) =>
      Recipe(
        id: id,
        name: name,
        emoji: emoji,
        artStart: artStart,
        artEnd: artEnd,
        desc: desc,
        category: category,
        time: time,
        difficulty: difficulty,
        servings: servings,
        ingredients: ingredients,
        steps: steps,
        match: match ?? this.match,
        matchLabel: matchLabel ?? this.matchLabel,
        basedOn: basedOn ?? this.basedOn,
        have: have ?? this.have,
        missing: missing ?? this.missing,
        savedAt: savedAt ?? this.savedAt,
        imageUrl: imageUrl ?? this.imageUrl,
        imagePath: imagePath ?? this.imagePath,
        imagePrompt: imagePrompt ?? this.imagePrompt,
        source: source ?? this.source,
        calories: calories ?? this.calories,
        imageAsset: imageAsset ?? this.imageAsset,
        extraImages: extraImages ?? this.extraImages,
        alsoCategories: alsoCategories ?? this.alsoCategories,
      );
}

class FoodCategory {
  const FoodCategory(this.id, this.name, this.icon);

  final String id;
  final String name;
  final String icon;
}

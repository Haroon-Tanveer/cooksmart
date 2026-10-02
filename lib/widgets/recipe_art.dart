import 'dart:io';

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme.dart';

/// Dish artwork: the generated photo when there is one, otherwise the brand
/// gradient with the recipe's emoji. Never shows a broken image — a failed
/// download simply falls back to the gradient.
class RecipeArt extends StatelessWidget {
  const RecipeArt({
    super.key,
    required this.recipe,
    this.emojiSize = 30,
    this.fit = BoxFit.cover,
    this.overlay = true,
    this.showEmoji = true,
  });

  final Recipe recipe;
  final double emojiSize;
  final BoxFit fit;

  /// Whether to darken the bottom of the photo. The home hero supplies its own
  /// scrim, so it turns this off.
  final bool overlay;

  /// Whether to draw the emoji over the gradient. Backdrop uses turn it off,
  /// since the card lays its own emoji out above the image.
  final bool showEmoji;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(gradient: recipe.art),
          child: Center(
            child: showEmoji
                ? Text(recipe.emoji, style: TextStyle(fontSize: emojiSize))
                : const SizedBox.shrink(),
          ),
        ),
        if (_source != null)
          Image(
            image: _source!,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
        // Keeps the emoji legible if a photo is bright or mostly empty.
        if (_source != null && overlay)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00000000), Color(0x59000000)],
                  stops: <double>[0.55, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }

  ImageProvider? get _source {
    final path = recipe.imagePath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    final url = recipe.imageUrl;
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return NetworkImage(url);
    }
    final asset = recipe.imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return AssetImage(asset);
    }
    return null;
  }
}

/// Artwork sized for the home hero, with a taller crop.
class RecipeHeroArt extends StatelessWidget {
  const RecipeHeroArt({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RecipeArt(recipe: recipe, emojiSize: 46),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x14000000), Color(0xCC000000)],
              stops: <double>[0.25, 1.0],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(recipe.emoji, style: const TextStyle(fontSize: 52)),
              SizedBox(height: 6),
              Text(
                'made by ${recipe.isLive ? 'groq' : 'CookSmart'}',
                style: cookText(
                  size: 11,
                  weight: FontWeight.w700,
                  color: CookColors.orangeSoft,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

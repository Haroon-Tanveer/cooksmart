import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/recipe_art.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CookScope.of(context);
    final recipe = state.result;

    if (recipe == null) {
      return CookBackground(
        child: ListView(
          padding: cookPagePadding(context),
          children: <Widget>[
            const _AppBar(title: 'Recipe'),
            Text(
              'No recipe yet',
              style: cookText(
                size: 24,
                weight: FontWeight.w800,
                color: CookColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Open the Create tab, add a few ingredients, and we'll cook something up for you.",
              style: cookText(size: 14, color: CookColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Add ingredients',
              onPressed: () => state.go(CookScreen.ingredients),
            ),
          ],
        ),
      );
    }

    final saved = state.isSaved(recipe);

    return CookBackground(
      child: ListView(
        padding: cookPagePadding(context),
        children: <Widget>[
          _AppBar(
            title: 'Recipe',
            onBack: state.goBack,
            actionLabel: 'Saved',
            onAction: () => state.go(CookScreen.saved),
          ),
          _ResultHero(recipe: recipe, state: state),
          SectionHeader(text: 'Ingredients · ${recipe.ingredients.length}'),
          ...recipe.ingredients.map((ing) {
            final owned = recipe.haveTokens.contains(ing.name);
            final done = state.isIngredientChecked(ing.name);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _IngredientRow(
                name: ing.name,
                qty: ing.qty,
                owned: owned,
                done: done,
                calories: ing.calories,
                onTap: () => state.toggleIngredient(ing.name),
              ),
            );
          }),
          if (recipe.missing.isNotEmpty) ...<Widget>[
            const SectionHeader(text: 'You may need to buy'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.missing
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CookColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: CookColors.line),
                      ),
                      child: Text(
                        m,
                        style: cookText(size: 13, color: CookColors.muted),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SectionHeader(text: 'Method · ${recipe.steps.length} steps'),
          ...List<Widget>.generate(recipe.steps.length, (i) {
            final done = state.isStepDone(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Step(
                index: i,
                text: recipe.steps[i],
                done: done,
                onTap: () => state.toggleStep(i),
              ),
            );
          }),
          const SizedBox(height: 12),
          PrimaryButton(
            label: saved ? 'Saved to your recipes' : 'Save Recipe',
            icon: saved ? Icons.check_rounded : Icons.star_rounded,
            saved: saved,
            onPressed: () {
              final nowSaved = state.toggleSave();
              showCookToast(
                context,
                nowSaved ? 'Recipe saved' : 'Removed from saved',
              );
            },
          ),
          const SizedBox(height: 10),
          GhostButton(
            label: 'Try with other ingredients',
            onPressed: () => state.go(CookScreen.ingredients),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.title,
    this.onBack,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final VoidCallback? onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      child: Row(
        children: <Widget>[
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CookColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: CookColors.line),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: CookColors.white,
                ),
              ),
            )
          else
            const SizedBox(width: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: cookText(
                size: 17,
                weight: FontWeight.w700,
                color: CookColors.white,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: cookText(
                  size: 14,
                  weight: FontWeight.w600,
                  color: CookColors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, required this.child});

  /// Asset paths for this dish, first one first.
  final List<String> images;

  /// Builds the art for one asset, so the caller keeps control of how it is
  /// painted rather than the gallery guessing.
  final Widget Function(String asset) child;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.length < 2) {
      // Nothing to swipe, so no gesture arena and no dots to explain.
      return images.isEmpty
          ? const SizedBox.shrink()
          : widget.child(images.first);
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView.builder(
          controller: _controller,
          // The card sits inside a vertical scroll view, so the page view only
          // wins once the finger is clearly travelling sideways.
          physics: const ClampingScrollPhysics(),
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => widget.child(images[i]),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: _Dots(count: images.length, index: _index),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Container(
            width: i == index ? 14 : 5,
            height: 5,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: i == index ? CookColors.orange : CookColors.muted2,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
      ],
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.recipe, required this.state});

  final Recipe recipe;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final based = recipe.basedOn.length;
    final hasPhoto =
        (recipe.imagePath != null && recipe.imagePath!.isNotEmpty) ||
        (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty);
    // Library recipes ship a bundled picture, so it sits behind the whole card
    // rather than in a band above it. Recipes with nothing to show keep the
    // plain gradient and the emoji.
    final asset = recipe.imageAsset;
    final hasBackdrop = !hasPhoto && asset != null && asset.isNotEmpty;
    final gallery = recipe.images;
    // With a backdrop there is nothing interactive in the card's text, so a
    // pager on top can own every swipe, and a long press opens the photo full
    // screen the way holding a picture in a photo app does.
    final galleryActive = hasBackdrop && gallery.length > 1;
    final longPressSources = <String>[
      if (hasPhoto) recipe.imageUrl ?? recipe.imagePath! else ...gallery,
    ].where((s) => s.isNotEmpty).toList();
    final imageArea = GestureDetector(
      onLongPress: longPressSources.isEmpty
          ? null
          : () => PhotoViewer.show(context, sources: longPressSources),
      child: galleryActive
          ? _Gallery(
              images: gallery,
              child: (image) => Opacity(
                opacity: 0.4,
                child: RecipeArt(
                  // The gallery paints a specific asset, so the card no longer
                  // asks the art widget to pick one.
                  recipe: recipe.copyWith(
                    imageAsset: image,
                    extraImages: const <String>[],
                  ),
                  showEmoji: false,
                  overlay: false,
                ),
              ),
            )
          : Opacity(
              opacity: 0.4,
              child: RecipeArt(
                recipe: recipe,
                showEmoji: false,
                overlay: false,
              ),
            ),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CookRadius.lg),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF3B2211), Color(0xFF1A140E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x3DFF8A3D)),
      ),
      child: Stack(
        children: <Widget>[
          if (hasPhoto)
            SizedBox(
              height: 168,
              width: double.infinity,
              child: GestureDetector(
                onLongPress: longPressSources.isEmpty
                    ? null
                    : () =>
                          PhotoViewer.show(context, sources: longPressSources),
                child: RecipeHeroArt(recipe: recipe),
              ),
            )
          else if (hasBackdrop)
            Positioned.fill(child: imageArea),
          if (hasBackdrop)
            // A scrim over the picture rather than a flatter one behind it, so
            // the chip, title and the muted stat labels all keep their contrast
            // no matter how bright the dish is.
            //
            // IgnorePointer matters here: a DecoratedBox hit-tests by default,
            // so without it the scrim would sit on top of the photo and swallow
            // every swipe and long press meant for it.
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xB31A120B),
                        Color(0xCC120C07),
                        Color(0xE60E0906),
                      ],
                      stops: <double>[0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          IgnorePointer(
            // A backdrop card holds no buttons, so the photo area below owns
            // every touch. The live-recipe variant does have a control, and it
            // has no backdrop, so it keeps its pointer events.
            ignoring: hasBackdrop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (hasPhoto)
                  const SizedBox(height: 168)
                else ...<Widget>[
                  const SizedBox(height: 20),
                  // Same 20px gutter as the description below, so the chip and
                  // the title line up with the rest of the card.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: CookColors.orange,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  recipe.matchLabel ?? 'From the library',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: cookText(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF1C1108),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                based == 0
                                    ? 'from your idea'
                                    : 'from $based ingredient${based == 1 ? '' : 's'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: cookText(
                                  size: 12,
                                  color: CookColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              recipe.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: cookText(
                                  size: 25,
                                  weight: FontWeight.w800,
                                  color: CookColors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (hasPhoto) ...<Widget>[
                        Text(
                          recipe.name,
                          style: cookText(
                            size: 25,
                            weight: FontWeight.w800,
                            color: CookColors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (recipe.desc.isNotEmpty)
                        Text(
                          recipe.desc,
                          style: cookText(
                            size: 13.5,
                            color: CookColors.muted,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: <Widget>[
                          _Stat('◷ ${recipe.time} min', 'Time'),
                          _Stat(recipe.difficulty, 'Difficulty'),
                          _Stat('${recipe.servings}', 'Servings'),
                          if (recipe.totalCalories != null)
                            _Stat(
                              '${recipe.totalCalories} kcal',
                              recipe.caloriesPerServing != null
                                  ? 'Total · ${recipe.caloriesPerServing}/serving'
                                  : 'Total',
                            ),
                        ],
                      ),
                      if (recipe.isLive || hasPhoto) ...<Widget>[
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Icon(
                              recipe.isLive
                                  ? Icons.auto_awesome_rounded
                                  : Icons.image_outlined,
                              size: 13,
                              color: CookColors.orangeSoft,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hasPhoto
                                    ? 'Recipe by Groq · photo from TheMealDB'
                                    : 'Looking up a photo…',
                                style: cookText(
                                  size: 11,
                                  color: CookColors.muted,
                                ),
                              ),
                            ),
                            if (recipe.isLive && hasPhoto)
                              GestureDetector(
                                onTap: () {
                                  state.retryImage();
                                  showCookToast(
                                    context,
                                    'Looking for another photo…',
                                  );
                                },
                                child: Text(
                                  'Change photo',
                                  style: cookText(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: CookColors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cookText(
            size: 14,
            weight: FontWeight.w700,
            color: CookColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cookText(
            size: 11,
            color: CookColors.muted2,
            letterSpacing: 0.88,
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.name,
    required this.qty,
    required this.owned,
    required this.done,
    required this.onTap,
    this.calories,
  });

  final String name;
  final String qty;
  final bool owned;
  final bool done;
  final VoidCallback onTap;

  /// Energy of this line, or null when the source gave no figure.
  final int? calories;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CookRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CookColors.surface,
            borderRadius: BorderRadius.circular(CookRadius.sm),
            border: Border.all(
              color: owned ? const Color(0x38FF8A3D) : CookColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? CookColors.orange : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done || owned
                        ? CookColors.orange
                        : CookColors.muted2,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Color(0xFF14110D),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: <Widget>[
                    Text(
                      name,
                      style: cookText(
                        size: 14,
                        color: done ? CookColors.muted2 : CookColors.text,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (owned)
                      Text(
                        'in your kitchen',
                        style: cookText(
                          size: 10,
                          color: CookColors.orangeSoft,
                          letterSpacing: 0.04,
                        ),
                      ),
                    Text(
                      '· $qty',
                      style: cookText(size: 14, color: CookColors.muted2),
                    ),
                    if (calories != null)
                      Text(
                        '· $calories kcal',
                        style: cookText(
                          size: 12,
                          weight: FontWeight.w600,
                          color: done ? CookColors.muted2 : CookColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.text,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? CookColors.orange : const Color(0x21FF8A3D),
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? CookColors.orange : const Color(0x4DFF8A3D),
              ),
            ),
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF1C1108),
                  )
                : Text(
                    '${index + 1}',
                    style: cookText(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: CookColors.orangeSoft,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: cookText(
                  size: 14,
                  height: 1.55,
                  color: done ? CookColors.muted2 : CookColors.text,
                  decoration: done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

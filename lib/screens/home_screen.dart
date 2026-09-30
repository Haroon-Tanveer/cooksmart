import 'package:flutter/material.dart';

import '../data/recipes.dart';
import '../models/recipe.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/recipe_art.dart';
import '../widgets/settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = CookScope.of(context);
    final featured = kRecipes.first;
    final rail = kRecipes.skip(1).take(6).toList();
    final filtered = state.filteredRecipes;

    return CookBackground(
      child: ListView(
        padding: cookPagePadding(context),
        children: <Widget>[
          const _Greeting(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Turn what you already have into something worth eating.',
                  style: cookText(size: 14, color: CookColors.muted),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => SettingsSheet.show(context),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CookColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: CookColors.line),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: CookColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SearchField(
            controller: _searchController,
            onChanged: state.setSearch,
          ),
          const SizedBox(height: 20),
          _HeroCard(
            recipe: featured,
            onTap: () => state.openLibraryRecipe(featured),
          ),
          Eyebrow(
            text: 'Food categories',
          ),
          _CategoryGrid(
            active: state.activeCategory,
            onSelect: state.setCategory,
          ),
          Eyebrow(
            text: 'Featured',
            trailing: GestureDetector(
              onTap: () => state.go(CookScreen.ingredients),
              child: Text(
                'Use my kitchen',
                style: cookText(
                  size: 13,
                  weight: FontWeight.w700,
                  color: CookColors.orange,
                ),
              ),
            ),
          ),
          SizedBox(
            height: featuredRailHeight(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 4),
              itemCount: rail.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final r = rail[index];
                return FeaturedCard(recipe: r, onTap: () => state.openLibraryRecipe(r));
              },
            ),
          ),
          SectionHeader(
            text: state.isFiltering ? 'Results' : 'All recipes',
            count: filtered.length,
          ),
          if (filtered.isEmpty)
            EmptyState(
              icon: true,
              title: 'Nothing matches',
              message: 'Try a different search term, or reset the filters to see everything.',
              actionLabel: 'Reset filters',
              onAction: () {
                _searchController.clear();
                state.resetFilters();
              },
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: recipeTileExtent(context),
              ),
              itemBuilder: (context, index) {
                final r = filtered[index];
                return RecipeTile(recipe: r, onTap: () => state.openLibraryRecipe(r));
              },
            ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: 'Hey chef, ',
              style: cookText(size: 26, weight: FontWeight.w800, color: CookColors.white),
            ),
            TextSpan(
              text: "what's cooking?",
              style: cookText(size: 26, weight: FontWeight.w800, color: CookColors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CookRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CookRadius.lg),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF3A2110), Color(0xFF1D150E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x40FF8A3D)),
          ),
          child: Stack(
            children: <Widget>[
              // The real photograph sits behind the copy, dimmed enough that the
              // text keeps its contrast. The glow still shows through for
              // recipes with no photo.
              if (recipe.imageAsset != null || recipe.imageUrl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CookRadius.lg),
                      child: Opacity(
                        opacity: 0.5,
                        child: RecipeArt(
                          recipe: recipe,
                          showEmoji: false,
                          overlay: false,
                        ),

                    ),
                  ),
                ),
              const Positioned(
                top: -34,
                right: -34,
                child: _HeroGlow(),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: CookColors.orange,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'RECIPE OF THE DAY',
                        style: cookText(
                          size: 11,
                          weight: FontWeight.w800,
                          color: const Color(0xFF24150A),
                          letterSpacing: 0.88,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recipe.name,
                      style: cookText(size: 21, weight: FontWeight.w800, color: CookColors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.desc,
                      style: cookText(size: 13, color: CookColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    // Wrap, not Row: on a narrow phone the three facts flow onto
                    // a second line instead of overflowing the card.
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: <Widget>[
                        _HeroMeta('◷ ${recipe.time} min'),
                        _HeroMeta(recipe.difficulty),
                        _HeroMeta('Serves ${recipe.servings}'),
                      ],
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

class _HeroMeta extends StatelessWidget {
  const _HeroMeta(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: cookText(size: 12, weight: FontWeight.w600, color: CookColors.orangeSoft),
      );
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              const Color(0x38FF8A3D),
              const Color(0x00FF8A3D),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.active, required this.onSelect});

  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 86,
      ),
      itemBuilder: (context, index) {
        final c = kCategories[index];
        final isActive = c.id == active;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(c.id),
            borderRadius: BorderRadius.circular(CookRadius.sm),
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? const Color(0x1AFF8A3D) : CookColors.surface,
                borderRadius: BorderRadius.circular(CookRadius.sm),
                border: Border.all(
                  color: isActive ? CookColors.orange : CookColors.line,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? CookColors.orange : CookColors.surface3,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(c.icon, style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cookText(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: isActive ? CookColors.white : CookColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

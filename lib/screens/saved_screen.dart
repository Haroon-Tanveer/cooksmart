import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CookScope.of(context);
    final list = state.saved;

    return CookBackground(
      child: ListView(
        padding: cookPagePadding(context),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'Saved recipes',
              style: cookText(size: 24, weight: FontWeight.w800, color: CookColors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              list.isEmpty
                  ? 'Nothing saved yet. Generate a recipe and tap Save to keep it here.'
                  : '${list.length} recipe${list.length == 1 ? '' : 's'} kept for later, ready whenever you are.',
              style: cookText(size: 14, color: CookColors.muted, height: 1.45),
            ),
          ),
          if (list.isEmpty)
            EmptyState(
              glyph: '📬',
              title: L.of(context).noSavedTitle,
              message: 'Add the ingredients you have and we\'ll turn them into something you will want to cook again.',
              actionLabel: 'Create a recipe',
              onAction: () => state.go(CookScreen.ingredients),
            )
          else ...<Widget>[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: recipeTileExtent(context),
              ),
              itemBuilder: (context, index) {
                final r = list[index];
                return RecipeTile(
                  recipe: r,
                  onTap: () => state.openSavedRecipe(r),
                  onRemove: () {
                    state.removeSaved(r.id);
                    showCookToast(context, L.of(context).remove);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            GhostButton(
              label: 'Clear all saved',
              onPressed: () {
                state.clearSaved();
                showCookToast(context, 'Saved list cleared');
              },
            ),
          ],
        ],
      ),
    );
  }
}

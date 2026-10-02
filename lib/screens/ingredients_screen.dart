import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../data/recipes.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/settings_sheet.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final state = CookScope.of(context);
    if (state.addIngredient(raw)) {
      _controller.clear();
    } else if (raw.trim().isNotEmpty) {
      _controller.clear();
      _toast('Already in the list');
    }
    _focus.requestFocus();
  }

  void _toast(String message) => showCookToast(context, message);

  Future<void> _generate() async {
    final state = CookScope.of(context);
    if (_controller.text.trim().isNotEmpty) {
      _commit(_controller.text);
    }
    if (!state.canGenerate) {
      _toast('Add at least one ingredient');
      return;
    }
    FocusScope.of(context).unfocus();
    await state.generate();
  }

  Future<void> _surprise() async {
    final state = CookScope.of(context);
    if (_controller.text.trim().isNotEmpty) {
      _commit(_controller.text);
    }
    FocusScope.of(context).unfocus();
    final recipe = await state.surpriseMe();
    if (!mounted) return;
    if (recipe == null) _toast('Add at least one ingredient');
  }

  Future<void> _pickDish(String dish) async {
    final state = CookScope.of(context);
    if (_controller.text.trim().isNotEmpty) {
      _commit(_controller.text);
    }
    FocusScope.of(context).unfocus();
    final recipe = await state.generate(dish: dish);
    if (!mounted) return;
    if (recipe == null) _toast('Add at least one ingredient');
  }

  @override
  Widget build(BuildContext context) {
    final state = CookScope.of(context);
    final l10n = L.of(context);
    final list = state.ingredients;

    return CookBackground(
      child: ListView(
        padding: cookPagePadding(context),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              "What's in your kitchen?",
              style: cookText(size: 24, weight: FontWeight.w800, color: CookColors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Type what you have and we'll build a recipe around it, flagging the few "
              'things you may still need.',
              style: cookText(size: 14, color: CookColors.muted, height: 1.45),
            ),
          ),
          _ChipField(
            controller: _controller,
            focusNode: _focus,
            items: list,
            hint: list.isEmpty
                ? 'e.g. chicken, rice, garlic'
                : 'Add another…',
            onSubmit: _commit,
            onRemove: (value) {
              state.removeIngredient(value);
              _toast('$value removed');
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSuggestions
                .map(
                  (s) => GestureDetector(
                    onTap: () => _commit(s),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: CookColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: CookColors.line),
                      ),
                      child: Text(
                        '+ $s',
                        style: cookText(size: 13, color: CookColors.muted),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (state.isLive && !state.isBusy) ...<Widget>[
            const SizedBox(height: 18),
            _IdeaRow(
              ideas: state.dishIdeas,
              onPick: _pickDish,
              onRefresh: () => state.refreshDishIdeas(),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CookRadius.md),
              border: Border.all(color: CookColors.line),
              gradient: LinearGradient(
                colors: <Color>[Color(0x1FFFA25C), Color(0x00FF8A3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: CookColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.tipTitle, style: cookText(size: 14, weight: FontWeight.w700, color: CookColors.white)),
                SizedBox(height: 6),
                Text(
                  'Press Enter or a comma after each ingredient. Include staples like oil, '
                  'onion, and salt — they count toward your match score.',
                  style: cookText(size: 12.5, color: CookColors.muted, height: 1.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (state.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x14FF8A3D),
                borderRadius: BorderRadius.circular(CookRadius.sm),
                border: Border.all(color: const Color(0x2EFF8A3D)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.auto_awesome_rounded, size: 15, color: CookColors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.usingFallback
                          ? 'AI unreachable — using the offline engine'
                          : 'Groq writes the recipe, the photo comes from TheMealDB',
                      style: cookText(
                        size: 12,
                        color: state.usingFallback ? CookColors.muted : CookColors.orangeSoft,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => SettingsSheet.show(context),
                    child: Text(
                      'Settings',
                      style: cookText(size: 12, weight: FontWeight.w700, color: CookColors.orange),
                    ),
                  ),
                ],
              ),
            ),
          if (state.isLive) const SizedBox(height: 10),
          if (state.isBusy)
            PrimaryButton(label: state.busyLabel ?? l10n.generating, enabled: false)
          else
            PrimaryButton(
              label: 'Generate Recipe',
              enabled: state.canGenerate,
              onPressed: _generate,
            ),
          if (!state.isBusy && state.isLive) ...<Widget>[
            const SizedBox(height: 10),
            GhostButton(label: 'Surprise me', onPressed: _surprise),
          ],
          if (state.canGenerate && !state.isBusy) ...<Widget>[
            const SizedBox(height: 10),
            GhostButton(
              label: 'Clear all',
              onPressed: () {
                _controller.clear();
                state.clearIngredients();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _IdeaRow extends StatelessWidget {
  const _IdeaRow({required this.ideas, required this.onPick, required this.onRefresh});

  final List<String> ideas;
  final ValueChanged<String> onPick;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_rounded, size: 14, color: CookColors.orange),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Dish ideas from Groq',
                style: cookText(size: 12, weight: FontWeight.w700, color: CookColors.muted),
              ),
            ),
            GestureDetector(
              onTap: onRefresh,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.refresh_rounded, size: 16, color: CookColors.muted2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ideas.isEmpty)
          GhostButton(label: 'Suggest dishes', onPressed: onRefresh)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ideas
                .map(
                  (dish) => GestureDetector(
                    onTap: () => onPick(dish),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0x14FF8A3D),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Color(0x2EFF8A3D)),
                      ),
                      child: Text(
                        dish,
                        style: cookText(
                          size: 13,
                          weight: FontWeight.w600,
                          color: CookColors.orangeSoft,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ChipField extends StatelessWidget {
  const _ChipField({
    required this.controller,
    required this.focusNode,
    required this.items,
    required this.hint,
    required this.onSubmit,
    required this.onRemove,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> items;
  final String hint;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CookColors.surface2,
        borderRadius: BorderRadius.circular(CookRadius.md),
        border: Border.all(color: CookColors.line),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ...items.map(
            (item) => Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: const Color(0x24FF8A3D),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Color(0x59FF8A3D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    item,
                    style: cookText(size: 13, weight: FontWeight.w600, color: CookColors.orangeSoft),
                  ),
                  const SizedBox(width: 7),
                  GestureDetector(
                    onTap: () => onRemove(item),
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0x33FF8A3D),
                        shape: BoxShape.circle,
                      ),
                      child: Text('×',
                          style: TextStyle(fontSize: 12, color: CookColors.orangeSoft, height: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 140),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: cookText(size: 16, color: CookColors.white),
              cursorColor: CookColors.orange,
              textInputAction: TextInputAction.done,
              onSubmitted: onSubmit,
              onChanged: (value) {
                final trimmed = value.trimRight();
                if (trimmed.endsWith(',')) {
                  onSubmit(trimmed.substring(0, trimmed.length - 1));
                }
              },
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: cookText(size: 16, color: CookColors.muted2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

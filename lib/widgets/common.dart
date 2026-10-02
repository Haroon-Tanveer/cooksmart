import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme.dart';
import 'recipe_art.dart';

/// Page background: the dark wash with warm orange glow, as in the design.
class CookBackground extends StatelessWidget {
  const CookBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CookTheme.backgroundGradient,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: -170,
            right: -110,
            child: _Glow(size: 340, color: Color(0x24FF8A3D)),
          ),
          const Positioned(
            bottom: -150,
            left: -130,
            child: _Glow(size: 300, color: Color(0x12FF8A3D)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase section label, with an optional trailing action.
class Eyebrow extends StatelessWidget {
  const Eyebrow({super.key, required this.text, this.trailing, this.onTrailingTap});

  final String text;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: cookText(
                size: 12,
                weight: FontWeight.w700,
                color: CookColors.muted2,
                letterSpacing: 1.68,
              ),
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              behavior: HitTestBehavior.opaque,
              child: trailing,
            ),
        ],
      ),
    );
  }
}

/// Rounded surface used for cards, rows and the search field.
class CookSurface extends StatelessWidget {
  const CookSurface({
    super.key,
    required this.child,
this.radius = CookRadius.md,
      this.color,
      this.borderColor,
      this.padding = EdgeInsets.zero,
      this.onTap,
    });

    final Widget child;
    final double radius;

    /// Null means "use the current palette". These cannot be const defaults
    /// because the palette is swapped when the theme changes.
    final Color? color;
    final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: color ?? CookColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? CookColors.line, width: 1),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search recipes or ingredients',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return CookSurface(
      radius: 100,
      color: CookColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, color: CookColors.orange, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: cookText(size: 15, color: CookColors.white),
              cursorColor: CookColors.orange,
              cursorWidth: 1.6,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: cookText(size: 15, color: CookColors.muted2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary orange action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.saved = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    final isGhost = saved || !active;

    final style = saved
        ? cookText(size: 15, weight: FontWeight.w700, color: CookColors.orangeSoft)
        : cookText(
            size: 15,
            weight: FontWeight.w700,
            color: active ? Color(0xFF1C1108) : CookColors.muted2,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onPressed : null,
        borderRadius: BorderRadius.circular(CookRadius.md),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CookRadius.md),
            gradient: isGhost ? null : LinearGradient(
              colors: <Color>[CookColors.orange, CookColors.orangeDeep],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            color: isGhost ? CookColors.surface2 : null,
            border: isGhost ? Border.all(color: CookColors.line) : null,
            boxShadow: active && !saved
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x42FF8A3D),
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 17, color: style.color),
                const SizedBox(width: 9),
              ],
              // Flexible so a long label ellipsises on a narrow phone instead
              // of pushing the row past the button's own padding.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(CookRadius.md),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CookColors.surface2,
            borderRadius: BorderRadius.circular(CookRadius.md),
            border: Border.all(color: CookColors.line),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: cookText(size: 15, weight: FontWeight.w700, color: CookColors.text),
          ),
        ),
      ),
    );
  }
}

/// Height of a [RecipeTile] grid cell.
///
/// The artwork band is a fixed 88px, but the text under it grows with the
/// system font size. Deriving the cell height from the active scale keeps a
/// two-line title from spilling out of the cell on a large-font device.
double recipeTileExtent(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(0.9, 1.3);
  return 88 + 86 * scale;
}

/// Height of the horizontal featured rail, which holds a [FeaturedCard].
double featuredRailHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(0.9, 1.3);
  return 96 + 104 * scale;
}

/// Two-column grid card used on the saved and explore grids.
class RecipeTile extends StatelessWidget {
  const RecipeTile({super.key, required this.recipe, this.onTap, this.onRemove});

  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CookRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: CookColors.surface,
            borderRadius: BorderRadius.circular(CookRadius.md),
            border: Border.all(color: CookColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: RecipeArt(recipe: recipe)),
                    if (onRemove != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color(0xA60A0806),
                              shape: BoxShape.circle,
                              border: Border.all(color: CookColors.line),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 13, color: CookColors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: cookText(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: CookColors.white,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '◷ ${recipe.time} min · ${recipe.difficulty}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cookText(size: 11, color: CookColors.muted2),
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

/// Compact card for the horizontal featured rail.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CookRadius.md),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: CookColors.surface,
            borderRadius: BorderRadius.circular(CookRadius.md),
            border: Border.all(color: CookColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 96,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(gradient: recipe.art),
                child: RecipeArt(recipe: recipe, emojiSize: 34),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: cookText(
                        size: 14,
                        weight: FontWeight.w700,
                        color: CookColors.white,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '◷ ${recipe.time} min · ${recipe.difficulty}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cookText(size: 11.5, color: CookColors.muted2),
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

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.glyph = '',
    this.actionLabel,
    this.onAction,
    this.icon = false,
  });

  final String glyph;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CookRadius.lg),
        border: Border.all(color: const Color(0x22FFFFFF)),
        color: const Color(0x04FFFFFF),
      ),
      child: Column(
        children: <Widget>[
          if (icon)
            Icon(Icons.ramen_dining_rounded, size: 40, color: CookColors.muted2)
          else
            Text(glyph, style: TextStyle(fontSize: 40)),          const SizedBox(height: 14),
          Text(title, style: cookText(size: 17, weight: FontWeight.w700, color: CookColors.white)),
          SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: cookText(size: 13.5, color: CookColors.muted, height: 1.5),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: PrimaryButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}

/// Page padding that keeps content clear of the status bar.
/// The Scaffold reserves the tab bar, so only the leading inset is needed here.
EdgeInsets cookPagePadding(BuildContext context, {double top = 4}) {
  return const EdgeInsets.fromLTRB(
    CookTheme.gutter,
    4,
    CookTheme.gutter,
    24,
  );
}

/// White pill toast that floats above the tab bar, as in the design.
void showCookToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 84),
      ),
    );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.text, this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cookText(
                size: 12,
                weight: FontWeight.w800,
                color: CookColors.muted2,
                letterSpacing: 1.68,
              ),
            ),
          ),
          if (count != null) ...<Widget>[
            SizedBox(width: 8),
            Text('$count', style: cookText(size: 12, color: CookColors.muted2)),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/ingredients_screen.dart';
import 'screens/result_screen.dart';
import 'screens/saved_screen.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(CookTheme.systemOverlay);
  runApp(const CookSmartApp());
}

class CookSmartApp extends StatefulWidget {
  const CookSmartApp({super.key, this.state});

  /// Injected by tests so live calls can be stubbed without a server.
  final AppState? state;

  @override
  State<CookSmartApp> createState() => _CookSmartAppState();
}

class _CookSmartAppState extends State<CookSmartApp> {
  late final AppState _state = widget.state ?? AppState();

  /// Light, dark, or follow the phone. Rebuilds only when the mode changes.
  ThemeMode get _themeMode => _state.themeMode;

  @override
  void initState() {
    super.initState();
    _state.init().then((_) {
      if (!mounted) return;
      // The saved language is only known after the first read of storage, so
      // MaterialApp needs one rebuild to pick it up.
      setState(() {});
    });
    _state.addListener(_onStateChanged);
  }

  /// MaterialApp reads the locale and the theme mode, so switching either has to
  /// rebuild it. Nothing else it shows depends on the state.
  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CookScope(
      state: _state,
      child: MaterialApp(
        onGenerateTitle: (context) => L.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: CookTheme.build(Brightness.light),
        darkTheme: CookTheme.build(Brightness.dark),
        // Resolved from the state so the choice in settings survives a restart,
        // and so both themes are built once here rather than on every rebuild.
        themeMode: _themeMode,
        // Arabic is right to left, so the locale has to be declared for
        // Material to flip the whole app's direction.
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        locale: _state.locale,
        home: const _AppShell(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          // The builder runs after Material has resolved the theme, so this is
          // where the active palette is known. Applying it in CookTheme.build
          // would mean the last of the two calls always won.
          final brightness = Theme.of(context).brightness;
          CookColors.apply(brightness);
          SystemChrome.setSystemUIOverlayStyle(
            CookColors.paletteFor(brightness).overlay,
          );
          return MediaQuery(
            data: media.copyWith(
              // Respect the system font size, but cap it: the dense rows this
              // design relies on stop being readable well past 1.3x.
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

/// Root shell: the four screens plus the persistent bottom tab bar,
/// matching the HTML design where the tab bar stays visible on the result screen.
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final state = CookScope.of(context);
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    final topInset = MediaQuery.paddingOf(context).top;

    final shell = AnnotatedRegion<SystemUiOverlayStyle>(
      value: CookTheme.systemOverlay,
      child: Scaffold(
        backgroundColor: CookColors.bg,
        bottomNavigationBar: _TabBar(
          active: state.lastTab,
          onSelect: (screen) => state.go(screen),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<CookScreen>(state.screen),
              child: _screenFor(state.screen),
            ),
          ),
        ),
      ),
    );

    if (isMobile) return shell;

    // Desktop / web: keep the mobile device frame from the design.
    return Scaffold(
      backgroundColor: const Color(0xFF050403),
      body: Center(
        child: Container(
          width: 430,
          height: 880,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color(0x17FFFFFF)),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0xB3000000), blurRadius: 90, offset: Offset(0, 30)),
            ],
          ),
          child: shell,
        ),
      ),
    );
  }

  Widget _screenFor(CookScreen screen) {
    switch (screen) {
      case CookScreen.home:
        return const HomeScreen();
      case CookScreen.ingredients:
        return const IngredientsScreen();
      case CookScreen.result:
        return const ResultScreen();
      case CookScreen.saved:
        return const SavedScreen();
    }
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.active, required this.onSelect});

  final CookScreen active;
  final ValueChanged<CookScreen> onSelect;

  static const List<(CookScreen, IconData, String)> _tabs =
      <(CookScreen, IconData, String)>[
    // The third element is a key into the localisations, resolved in build.
    (CookScreen.home, Icons.home_outlined, 'tabHome'),
    (CookScreen.ingredients, Icons.checklist_rounded, 'tabCreate'),
    (CookScreen.saved, Icons.star_outline_rounded, 'tabSaved'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = L.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: CookTheme.tabHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? 6 : 0),
      decoration: BoxDecoration(
        color: Color(0xFA0E0C0A),
        border: Border(top: BorderSide(color: CookColors.line)),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final isActive = tab.$1 == active;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(tab.$1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    tab.$2,
                    size: 21,
                    color: isActive ? CookColors.orange : CookColors.muted2,
                  ),
                  SizedBox(height: 3),
                    Text(
                      switch (tab.$3) {
                        'tabCreate' => l10n.tabCreate,
                        'tabSaved' => l10n.tabSaved,
                        _ => l10n.tabHome,
                      },
                      style: cookText(

                      size: 10.5,
                      weight: FontWeight.w600,
                      color: isActive ? CookColors.orange : CookColors.muted2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

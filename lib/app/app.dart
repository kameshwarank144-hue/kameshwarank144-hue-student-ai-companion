// lib/app/app.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

// ---------------------------------------------------------------------
// 2. Root App
// ---------------------------------------------------------------------

/// The root widget of Student AI Companion.
///
/// Configures system UI (edge-to-edge, transparent status/navigation
/// bars), Material 3 theming, GoRouter navigation, clamped text
/// scaling, a global tap-to-dismiss-keyboard gesture, app lifecycle
/// observation, and a subtle premium background overlay.
class StudentAiCompanionApp extends ConsumerWidget {
  const StudentAiCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _configureSystemUi(context);

    return MaterialApp.router(
      title: 'Student AI Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      scrollBehavior: _AppScrollBehavior(),
      locale: const Locale('en'),
      supportedLocales: const <Locale>[
        Locale('en'),
      ],
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        final TextScaler clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: _AppLifecycleHandler(
              child: _AppBackground(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // 3. System UI Configuration
  // ---------------------------------------------------------------------

  /// Configures a transparent, edge-to-edge system UI with icon
  /// brightness matched to the current platform theme.
  void _configureSystemUi(BuildContext context) {
    final Brightness platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final bool isDark = platformBrightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

// ---------------------------------------------------------------------
// 4. App Builder
// ---------------------------------------------------------------------
//
// The builder wrapper itself lives inline inside `StudentAiCompanionApp
// .build` above (see `builder:`), composing, in order:
// GestureDetector -> MediaQuery -> _AppLifecycleHandler -> _AppBackground
// -> routed child.

// ---------------------------------------------------------------------
// 5. Scroll Behavior
// ---------------------------------------------------------------------

/// A custom scroll behavior supporting touch, mouse, stylus, and
/// trackpad input, with the default Android overscroll glow removed for
/// a cleaner, more premium feel.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

// ---------------------------------------------------------------------
// 6. Lifecycle Handler
// ---------------------------------------------------------------------

/// Observes app lifecycle transitions (resumed/inactive/paused/
/// detached) so future work — notification refresh, overlay
/// reconnection, AI session restoration, sync scheduling — has a single
/// place to hook into.
class _AppLifecycleHandler extends StatefulWidget {
  const _AppLifecycleHandler({required this.child});

  final Widget child;

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[APP] resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('[APP] inactive');
        break;
      case AppLifecycleState.paused:
        debugPrint('[APP] paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('[APP] detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[APP] hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------
// 7. Premium Background
// ---------------------------------------------------------------------

/// Wraps [child] with a subtle, theme-aware dark-to-transparent gradient
/// overlay for a premium feel, without intercepting touch input or
/// adding meaningful rebuild cost.
class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: <Widget>[
        Positioned.fill(child: child),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  (isDark ? Colors.black : Colors.white).withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// lib/app/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// -----------------------------------------------------------------------
// Global router
// -----------------------------------------------------------------------
// A single, app-wide GoRouter instance. Each route below currently points
// to a temporary placeholder screen (defined further down in this file)
// since the real feature screens have not been built yet. Once a feature
// screen exists, its builder here can be swapped to import and render the
// real widget without changing the route structure.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Student AI Companion',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Onboarding',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Sign In',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Home',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/timetable',
      name: 'timetable',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Timetable',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/attendance',
      name: 'attendance',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Attendance',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/todo',
      name: 'todo',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'To-Do',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/ai-chat',
      name: 'aiChat',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'AI Chat',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/study-mode',
      name: 'studyMode',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Study Mode',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          _buildTransitionPage(
        state: state,
        child: const _PlaceholderScreen(
          title: 'Settings',
          subtitle: 'This feature is coming soon.',
        ),
      ),
    ),
  ],
  // Fallback screen shown for any path that doesn't match a route above.
  errorBuilder: (BuildContext context, GoRouterState state) {
    return const _PlaceholderScreen(
      title: 'Page Not Found',
      subtitle: 'This feature is coming soon.',
    );
  },
);

// -----------------------------------------------------------------------
// Shared page transition
// -----------------------------------------------------------------------
// Builds a CustomTransitionPage that combines a fade with a subtle
// upward slide, giving every route change a smooth, premium feel
// without needing per-route animation logic.
CustomTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final Animation<Offset> slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------
// Placeholder screen
// -----------------------------------------------------------------------
// A single reusable placeholder used by every route until its real
// feature screen is implemented. Displays a modern gradient background,
// the route's title, and a short "coming soon" subtitle.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[
                    const Color(0xFF0B0B12),
                    const Color(0xFF17172A),
                    scheme.primary.withOpacity(0.25),
                  ]
                : <Color>[
                    const Color(0xFFF6F6FB),
                    const Color(0xFFEDEBFF),
                    scheme.primary.withOpacity(0.12),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[
                          scheme.primary,
                          scheme.tertiary,
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


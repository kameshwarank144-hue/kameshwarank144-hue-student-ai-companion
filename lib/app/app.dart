// lib/app/app.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root application widget.
///
/// Configures Material 3 theming (light + dark, system-driven) and a
/// temporary [GoRouter] instance pointing at a placeholder home screen.
/// This will later be replaced by `app/router/app_router.dart` and
/// `app/theme/app_theme.dart` once those files exist.
class StudentAiCompanionApp extends ConsumerWidget {
  const StudentAiCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Student AI Companion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routerConfig: _router,
    );
  }
}

// ---------------------------------------------------------------------------
// Temporary router
// ---------------------------------------------------------------------------

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const _HomePlaceholderScreen();
      },
    ),
  ],
);

// ---------------------------------------------------------------------------
// Color palette
// ---------------------------------------------------------------------------
// A futuristic, premium palette: deep indigo-violet primary (inspired by
// OpenAI's cool neutrals + Nothing's high-contrast accents + Apple's
// restrained surfaces), paired with a warm coral secondary for warmth in
// an otherwise cool, tech-forward system.

const Color _seedPrimary = Color(0xFF5B5FEF); // indigo-violet
const Color _seedSecondary = Color(0xFFFF7A59); // warm coral
const Color _seedTertiary = Color(0xFF2FE6C8); // aqua glow accent

const Color _lightBackground = Color(0xFFF6F6FB);
const Color _lightSurface = Color(0xFFFFFFFF);

const Color _darkBackground = Color(0xFF0B0B12); // near-AMOLED black
const Color _darkSurface = Color(0xFF14141F);

final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seedPrimary,
  brightness: Brightness.light,
  secondary: _seedSecondary,
  tertiary: _seedTertiary,
  surface: _lightSurface,
);

final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seedPrimary,
  brightness: Brightness.dark,
  secondary: _seedSecondary,
  tertiary: _seedTertiary,
  surface: _darkSurface,
);

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _lightColorScheme,
  scaffoldBackgroundColor: _lightBackground,
  fontFamily: 'Poppins',
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _darkColorScheme,
  scaffoldBackgroundColor: _darkBackground,
  fontFamily: 'Poppins',
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

// ---------------------------------------------------------------------------
// Placeholder home screen
// ---------------------------------------------------------------------------

class _HomePlaceholderScreen extends StatelessWidget {
  const _HomePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

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
                    scheme.primary.withValues(alpha: 0.25),
                  ]
                : <Color>[
                    const Color(0xFFF6F6FB),
                    const Color(0xFFEDEBFF),
                    scheme.primary.withValues(alpha: 0.12),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GreetingHeader(scheme: scheme),
                const SizedBox(height: 28),
                const Center(child: _GlowingOrb()),
                const SizedBox(height: 28),
                _GlassCard(
                  isDark: isDark,
                  child: _AttendancePreview(scheme: scheme),
                ),
                const SizedBox(height: 16),
                _GlassCard(
                  isDark: isDark,
                  child: _TodayClassPreview(scheme: scheme),
                ),
                const SizedBox(height: 16),
                _GlassCard(
                  isDark: isDark,
                  child: _MotivationalQuote(scheme: scheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Good Evening ðŸ‘‹',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your AI companion is getting ready...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}

/// A soft, glassmorphic container used across the home screen's preview
/// cards.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A gently pulsing, glowing orb representing the AI companion. This is a
/// lightweight placeholder for the eventual Rive-driven orb widget.
class _GlowingOrb extends StatefulWidget {
  const _GlowingOrb();

  @override
  State<_GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<_GlowingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double scale = 1.0 + (_controller.value * 0.06);
        final double glow = 20 + (_controller.value * 24);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  scheme.primary,
                  scheme.tertiary,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.5),
                  blurRadius: glow,
                  spreadRadius: glow / 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttendancePreview extends StatelessWidget {
  const _AttendancePreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: 0.0,
                  strokeWidth: 5,
                ),
              ),
              Text(
                '--%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Attendance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sync your timetable to see your attendance here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayClassPreview extends StatelessWidget {
  const _TodayClassPreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Today's Classes",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No classes added yet. Set up your timetable to get started.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MotivationalQuote extends StatelessWidget {
  const _MotivationalQuote({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.format_quote_rounded,
          color: scheme.secondary,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          'Small progress every day becomes big success.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
        ),
      ],
    );
  }
}

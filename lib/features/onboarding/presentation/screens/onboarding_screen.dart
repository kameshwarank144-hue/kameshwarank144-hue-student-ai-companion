// lib/features/onboarding/presentation/screens/onboarding_screen.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/premium_button.dart';

// ---------------------------------------------------------------------
// 2. Page Model
// ---------------------------------------------------------------------

/// Immutable content for a single onboarding page.
class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
    required this.gradient,
    required this.chips,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final IconData icon;
  final List<Color> gradient;
  final List<String> chips;
}

// ---------------------------------------------------------------------
// 3. Page Data
// ---------------------------------------------------------------------

const List<_OnboardingPageData> _kOnboardingPages = <_OnboardingPageData>[
  _OnboardingPageData(
    title: 'Nova AI is here for you ðŸ’™',
    subtitle: 'Your caring AI companion that reminds you about classes, '
        'assignments, attendance, water, sleep, and study sessions.',
    assetPath: 'assets/svg/onboarding/ai_companion.svg',
    icon: Icons.auto_awesome_rounded,
    gradient: <Color>[Color(0xFF7C4DFF), Color(0xFF5B4DFF)],
    chips: <String>['AI Chat', 'Voice Assistant', 'Smart Advice'],
  ),
  _OnboardingPageData(
    title: 'Never miss a class again ðŸ“š',
    subtitle: 'Smart timetable reminders, night-before alerts, lab '
        'preparation, and attendance protection powered by Nova AI.',
    assetPath: 'assets/svg/onboarding/timetable.svg',
    icon: Icons.calendar_month_rounded,
    gradient: <Color>[Color(0xFF5B8CFF), Color(0xFF00E5FF)],
    chips: <String>['Night Alerts', 'Attendance', 'Lab Reminders'],
  ),
  _OnboardingPageData(
    title: 'Focus better, stress less ðŸŽ¯',
    subtitle: 'Pomodoro timers, screen-time insights, study streaks, '
        'water reminders, and healthy productivity habits in one place.',
    assetPath: 'assets/svg/onboarding/study_mode.svg',
    icon: Icons.timer_rounded,
    gradient: <Color>[Color(0xFF00E5FF), Color(0xFF4ADE80)],
    chips: <String>['Pomodoro', 'Focus Mode', 'Screen Time'],
  ),
  _OnboardingPageData(
    title: 'Your future deserves consistency âœ¨',
    subtitle: 'Track attendance, tasks, GPA goals, expenses, health, and '
        'daily progress while Nova AI encourages you every step of the '
        'way.',
    assetPath: 'assets/svg/onboarding/analytics.svg',
    icon: Icons.insights_rounded,
    gradient: <Color>[Color(0xFFEC4899), Color(0xFF7C4DFF)],
    chips: <String>['GPA Goals', 'Analytics', 'Daily Progress'],
  ),
];

// ---------------------------------------------------------------------
// 4. Onboarding Screen
// ---------------------------------------------------------------------

/// A premium, futuristic onboarding experience introducing Nova AI as a
/// living companion rather than a standard productivity app tour.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _kOnboardingPages.length - 1;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.go(RouteNames.signIn);
  }

  void _onContinue() {
    if (_isLastPage) {
      context.go(RouteNames.signIn);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _OnboardingPageData activePage = _kOnboardingPages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Stack(
        children: <Widget>[
          _AnimatedBackground(gradient: activePage.gradient),
          SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _kOnboardingPages.length,
                    onPageChanged: (int index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return _OnboardingPageView(page: _kOnboardingPages[index]);
                    },
                  ),
                ),
                _BottomControls(
                  currentPage: _currentPage,
                  pageCount: _kOnboardingPages.length,
                  isLastPage: _isLastPage,
                  onSkip: _onSkip,
                  onContinue: _onContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The scrollable content for a single onboarding page.
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          _IllustrationCard(page: page),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              page.title,
              key: ValueKey<String>(page.title),
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.68),
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: page.chips
                .map((String label) => _FeatureChip(label: label, color: page.gradient.first))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 5. Background
// ---------------------------------------------------------------------

/// A living, futuristic gradient background with blurred glowing orbs
/// that gently drift, tinted to match the active onboarding page.
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B1020), Color(0xFF121A2F)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            _GlowOrb(
              alignment: const Alignment(-1.1, -0.9),
              color: gradient.first,
              size: 260,
            ),
            _GlowOrb(
              alignment: const Alignment(1.2, 0.8),
              color: gradient.last,
              size: 300,
            ),
            _GlowOrb(
              alignment: const Alignment(0.9, -1.1),
              color: gradient.last.withOpacity(0.6),
              size: 180,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single soft, blurred, gently drifting glow circle.
class _GlowOrb extends StatefulWidget {
  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double drift = _controller.value * 16;
        return Align(
          alignment: widget.alignment,
          child: Transform.translate(
            offset: Offset(drift, -drift),
            child: child,
          ),
        );
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 6. Illustration Card
// ---------------------------------------------------------------------

/// A frosted-glass illustration frame (built on [GlassCard]) with a
/// floating glow badge above it and the SVG artwork centered inside â€”
/// falling back to [page]'s icon if the asset fails to load.
class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(page.title),
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.scale(scale: value, child: child);
      },
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _FloatingBadge(color: page.gradient.first),
            GlassCard(
              width: double.infinity,
              height: 240,
              borderRadius: 36,
              blur: 20,
              opacity: 0.08,
              borderOpacity: 0.16,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SvgPicture.asset(
                  page.assetPath,
                  height: 150,
                  placeholderBuilder: (BuildContext context) {
                    return Icon(
                      page.icon,
                      size: 96,
                      color: Colors.white.withOpacity(0.85),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small, continuously floating glowing badge positioned above the
/// illustration frame.
class _FloatingBadge extends StatefulWidget {
  const _FloatingBadge({required this.color});

  final Color color;

  @override
  State<_FloatingBadge> createState() => _FloatingBadgeState();
}

class _FloatingBadgeState extends State<_FloatingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Align(
          alignment: const Alignment(0, -1.15),
          child: Transform.translate(
            offset: Offset(0, -_controller.value * 6),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 18,
                    spreadRadius: 2,
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

// ---------------------------------------------------------------------
// 7. Feature Chip
// ---------------------------------------------------------------------

/// A small glass pill highlighting one feature of the current page.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 8. Page Indicator
// ---------------------------------------------------------------------

/// Animated dash-style dots showing the current page position.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (int index) {
        final bool isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------
// 9. Bottom Controls
// ---------------------------------------------------------------------

/// The skip button, page indicator, and primary continue/get-started
/// button anchored to the bottom of the onboarding screen.
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.onSkip,
    required this.onContinue,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PageIndicator(currentPage: currentPage, pageCount: pageCount),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              SizedBox(
                height: 48,
                child: Semantics(
                  button: true,
                  label: 'Skip onboarding',
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: Semantics(
                  button: true,
                  label: isLastPage ? 'Get started' : 'Continue',
                  child: PremiumButton.primary(
                    label: isLastPage ? 'Get Started' : 'Continue',
                    icon: isLastPage ? Icons.arrow_forward_rounded : null,
                    onPressed: onContinue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


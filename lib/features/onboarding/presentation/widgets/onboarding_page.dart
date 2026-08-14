// lib/features/onboarding/presentation/widgets/onboarding_page.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/widgets/glass_card.dart';

// ---------------------------------------------------------------------
// 2. OnboardingPage
// ---------------------------------------------------------------------

/// A reusable, premium onboarding page for Student AI Companion,
/// designed to feel like a living, futuristic AI companion introduction
/// card rather than a standard onboarding slide.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
    required this.gradient,
    required this.features,
    this.isActive = false,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final IconData icon;
  final List<Color> gradient;
  final List<String> features;

  /// Whether this page is the currently visible/focused page. Drives
  /// the illustration's scale/glow and the text's opacity.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double illustrationHeight = (screenHeight * 0.4).clamp(240.0, 340.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            _IllustrationSection(
              assetPath: assetPath,
              icon: icon,
              gradient: gradient,
              isActive: isActive,
              height: illustrationHeight,
            ),
            const SizedBox(height: 28),
            Semantics(
              label: '$title features',
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: features
                    .take(3)
                    .map((String feature) => _FeatureChip(
                          label: feature,
                          color: gradient.first,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 300),
              child: Semantics(
                header: true,
                label: title,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.55,
              duration: const Duration(milliseconds: 300),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.68),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3. Illustration Section
// ---------------------------------------------------------------------

/// The large hero illustration card: a glassmorphism frame with
/// floating gradient glow behind an SVG illustration (or a gradient
/// icon fallback), animating its scale and glow strength with
/// [isActive].
class _IllustrationSection extends StatelessWidget {
  const _IllustrationSection({
    required this.assetPath,
    required this.icon,
    required this.gradient,
    required this.isActive,
    required this.height,
  });

  final String assetPath;
  final IconData icon;
  final List<Color> gradient;
  final bool isActive;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _GlowLayer(
              color: const Color(0xFF00E5FF),
              alignment: const Alignment(-0.8, -0.7),
              isActive: isActive,
            ),
            _GlowLayer(
              color: const Color(0xFF7C4DFF),
              alignment: const Alignment(0.85, 0.75),
              isActive: isActive,
            ),
            Semantics(
              label: 'Onboarding illustration',
              image: true,
              child: GlassCard(
                width: double.infinity,
                height: height,
                borderRadius: 36,
                blur: 22,
                opacity: 0.08,
                borderOpacity: 0.18,
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: _FloatingArt(
                    assetPath: assetPath,
                    icon: icon,
                    gradient: gradient,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft, heavily blurred decorative glow circle behind the
/// illustration frame.
class _GlowLayer extends StatelessWidget {
  const _GlowLayer({
    required this.color,
    required this.alignment,
    required this.isActive,
  });

  final Color color;
  final Alignment alignment;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 180,
        height: 180,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(isActive ? 0.32 : 0.16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The SVG illustration (with a gradient-icon fallback), gently
/// floating up and down using a self-looping [TweenAnimationBuilder].
class _FloatingArt extends StatefulWidget {
  const _FloatingArt({
    required this.assetPath,
    required this.icon,
    required this.gradient,
  });

  final String assetPath;
  final IconData icon;
  final List<Color> gradient;

  @override
  State<_FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<_FloatingArt> {
  bool _floatUp = false;

  @override
  void initState() {
    super.initState();
    // Kicks off the first leg of the continuous float loop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _floatUp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _floatUp ? 0 : 8, end: _floatUp ? 8 : 0),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() => _floatUp = !_floatUp);
      },
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(
          offset: Offset(0, value - 4),
          child: child,
        );
      },
      child: SvgPicture.asset(
        widget.assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (BuildContext context) => _FallbackIcon(
          icon: widget.icon,
          gradient: widget.gradient,
        ),
      ),
    );
  }
}

/// A large circular gradient container shown when the SVG asset fails
/// to load.
class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.icon, required this.gradient});

  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gradient.first.withOpacity(0.45),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 64, color: Colors.white),
    );
  }
}

// ---------------------------------------------------------------------
// 4. Feature Chips
// ---------------------------------------------------------------------

/// A compact, glassmorphism pill highlighting a single onboarding
/// feature.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.bolt_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


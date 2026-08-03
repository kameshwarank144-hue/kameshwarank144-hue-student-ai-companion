// lib/core/widgets/glass_card.dart

import 'dart:ui';

import 'package:flutter/material.dart';

/// A reusable, production-ready glassmorphism card.
///
/// Provides a premium frosted-glass surface in the spirit of Apple
/// VisionOS, Nothing OS, OpenAI interfaces, and modern iOS frosted cards.
/// Combines a blurred backdrop, translucent fill, soft border, layered
/// shadows, and an optional subtle gradient overlay, with built-in tap
/// support via [InkWell] when [onTap] is provided.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 28,
    this.blur = 20,
    this.opacity = 0.10,
    this.borderOpacity = 0.18,
    this.gradient,
    this.onTap,
  });

  /// The content displayed inside the card.
  final Widget child;

  /// Interior padding around [child].
  final EdgeInsetsGeometry padding;

  /// Exterior margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Fixed width of the card. If null, sizes to its content/parent.
  final double? width;

  /// Fixed height of the card. If null, sizes to its content/parent.
  final double? height;

  /// Corner radius applied to the card and its blur clip.
  final double borderRadius;

  /// Sigma value for the backdrop blur effect.
  final double blur;

  /// Opacity of the translucent white background fill.
  final double opacity;

  /// Opacity of the soft glass border.
  final double borderOpacity;

  /// Optional gradient overlay. Defaults to a subtle diagonal gradient
  /// when not provided.
  final Gradient? gradient;

  /// Optional tap callback. When provided, the card becomes interactive
  /// with a ripple effect while preserving its rounded corners.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    final Gradient effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withOpacity(0.14),
            Colors.white.withOpacity(0.06),
          ],
        );

    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        gradient: effectiveGradient,
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withOpacity(borderOpacity),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );

    final Widget blurredCard = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    final Widget card = SizedBox(
      width: width,
      height: height,
      child: blurredCard,
    );

    if (onTap == null) {
      return Container(margin: margin, child: card);
    }

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: Colors.white.withOpacity(0.12),
              highlightColor: Colors.white.withOpacity(0.06),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  gradient: effectiveGradient,
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withOpacity(borderOpacity),
                    width: 1.2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Demo
// -----------------------------------------------------------------------

/// A small preview widget showcasing [GlassCard] on a dark gradient
/// background, useful for quickly verifying the glassmorphism effect.
class GlassCardDemo extends StatelessWidget {
  const GlassCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF050816),
              Color(0xFF10102A),
              Color(0xFF1B1040),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                width: double.infinity,
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFF7C4DFF),
                            Color(0xFF00E5FF),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AI Companion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your emotional assistant is ready to help you study smarter.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// lib/core/widgets/app_loading_indicator.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------

/// The visual style an [AppLoadingIndicator] should render.
enum AppLoadingType {
  orb,
  dots,
  ring,
  pulse,
  wave,
  shimmer,
}

// ---------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------

/// A premium, futuristic loading experience used throughout Student AI
/// Companion — for app startup, authentication, AI thinking states,
/// data sync, PDF analysis, attendance calculations, task saving, study
/// session preparation, and cloud backup/restore.
///
/// Supports six visual variants ([AppLoadingType]) and can render inline,
/// full-screen, or as a blurred modal overlay.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.type = AppLoadingType.orb,
    this.message,
    this.size = 88,
    this.color,
    this.showMessage = true,
    this.fullScreen = false,
    this.overlay = false,
    this.backgroundColor,
  });

  /// Which loader variant to render.
  final AppLoadingType type;

  /// Overrides the default message for [type].
  final String? message;

  /// Base size of the loader animation, in logical pixels.
  final double size;

  /// Overrides the default accent color.
  final Color? color;

  /// Whether to display the message text beneath the loader.
  final bool showMessage;

  /// When true, the loader fills the entire screen with a dark
  /// translucent background.
  final bool fullScreen;

  /// When true, the loader renders as a blurred modal overlay that
  /// blocks interaction with the underlying UI.
  final bool overlay;

  /// Background color used in [fullScreen] / [overlay] modes.
  final Color? backgroundColor;

  /// Convenience constructor for a full-screen loading state.
  static Widget fullscreen({
    Key? key,
    AppLoadingType type = AppLoadingType.orb,
    String? message,
    double size = 88,
    Color? color,
    bool showMessage = true,
    Color? backgroundColor,
  }) {
    return AppLoadingIndicator(
      key: key,
      type: type,
      message: message,
      size: size,
      color: color,
      showMessage: showMessage,
      fullScreen: true,
      backgroundColor: backgroundColor,
    );
  }

  /// Convenience constructor for a blocking modal overlay loading state,
  /// typically placed inside a [Stack] over existing screen content.
  static Widget overlay({
    Key? key,
    AppLoadingType type = AppLoadingType.orb,
    String? message,
    double size = 88,
    Color? color,
    bool showMessage = true,
    Color? backgroundColor,
  }) {
    return AppLoadingIndicator(
      key: key,
      type: type,
      message: message,
      size: size,
      color: color,
      showMessage: showMessage,
      overlay: true,
      backgroundColor: backgroundColor,
    );
  }

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const List<Color> _defaultPalette = <Color>[
    Color(0xFF7C4DFF),
    Color(0xFF5B8CFF),
    Color(0xFF00E5FF),
  ];

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _durationForType());

    if (widget.type == AppLoadingType.orb) {
      _controller.repeat(reverse: true);
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AppLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _controller.duration = _durationForType();
      if (widget.type == AppLoadingType.orb) {
        _controller.repeat(reverse: true);
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _durationForType() {
    switch (widget.type) {
      case AppLoadingType.orb:
        return const Duration(milliseconds: 2200);
      case AppLoadingType.dots:
        return const Duration(milliseconds: 1200);
      case AppLoadingType.ring:
        return const Duration(milliseconds: 1400);
      case AppLoadingType.pulse:
        return const Duration(milliseconds: 1800);
      case AppLoadingType.wave:
        return const Duration(milliseconds: 900);
      case AppLoadingType.shimmer:
        return const Duration(milliseconds: 1500);
    }
  }

  // ---------------------------------------------------------------------
  // Defaults
  // ---------------------------------------------------------------------

  String _defaultMessage() {
    switch (widget.type) {
      case AppLoadingType.orb:
        return 'Preparing your AI companion...';
      case AppLoadingType.dots:
        return 'Loading...';
      case AppLoadingType.ring:
        return 'Please wait...';
      case AppLoadingType.pulse:
        return 'Syncing your data...';
      case AppLoadingType.wave:
        return 'Nova AI is thinking...';
      case AppLoadingType.shimmer:
        return 'Fetching your dashboard...';
    }
  }

  Color _effectiveColor() {
    return widget.color ?? _defaultPalette.first;
  }

  List<Color> _palette() {
    if (widget.color == null) return _defaultPalette;
    final Color base = widget.color!;
    return <Color>[
      base,
      Color.lerp(base, Colors.white, 0.25) ?? base,
      Color.lerp(base, Colors.cyanAccent, 0.35) ?? base,
    ];
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildLoader(),
        if (widget.showMessage) ...<Widget>[
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              widget.message ?? _defaultMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.overlay) {
      return _buildFullScreenWrapper(content, isOverlay: true);
    }

    if (widget.fullScreen) {
      return _buildFullScreenWrapper(content, isOverlay: false);
    }

    return Center(child: content);
  }

  // ---------------------------------------------------------------------
  // Full Screen Helpers
  // ---------------------------------------------------------------------

  Widget _buildFullScreenWrapper(Widget content, {required bool isOverlay}) {
    final Color background =
        widget.backgroundColor ?? Colors.black.withOpacity(isOverlay ? 0.55 : 0.85);

    final Widget blurredBackdrop = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: background,
        alignment: Alignment.center,
        child: content,
      ),
    );

    if (!isOverlay) {
      return SizedBox.expand(child: blurredBackdrop);
    }

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: SizedBox.expand(child: blurredBackdrop),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Loader Variants
  // ---------------------------------------------------------------------

  Widget _buildLoader() {
    switch (widget.type) {
      case AppLoadingType.orb:
        return _buildOrbLoader();
      case AppLoadingType.dots:
        return _buildDotsLoader();
      case AppLoadingType.ring:
        return _buildRingLoader();
      case AppLoadingType.pulse:
        return _buildPulseLoader();
      case AppLoadingType.wave:
        return _buildWaveLoader();
      case AppLoadingType.shimmer:
        return _buildShimmerLoader();
    }
  }

  /// A glowing, breathing orb with multi-layer gradients and a floating
  /// soft glow — inspired by the app's AI companion orb.
  Widget _buildOrbLoader() {
    final List<Color> colors = _palette();

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double glow = 0.35 + (t * 0.35);
        final double scale = 1.0 + (t * 0.08);

        return SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: widget.size * 1.6,
                height: widget.size * 1.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.first.withOpacity(glow * 0.6),
                      blurRadius: 44,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.first.withOpacity(glow),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: const Alignment(-0.4, -0.5),
                    child: Container(
                      width: widget.size * 0.3,
                      height: widget.size * 0.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Three bouncing dots with sequential scale and opacity, staggered via
  /// a shared controller and a sine-based bump curve.
  Widget _buildDotsLoader() {
    final Color color = _effectiveColor();
    final double dotSize = widget.size * 0.16;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final double phase = index / 3;
            final double t = (_controller.value + phase) % 1.0;
            final double bump = sin(pi * t).abs();
            final double scale = 0.6 + (bump * 0.6);
            final double opacity = 0.4 + (bump * 0.6);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: dotSize * 0.4),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// A gradient-tinted circular progress ring with a rounded stroke cap,
  /// rotating continuously via its own indeterminate animation.
  Widget _buildRingLoader() {
    final List<Color> colors = _palette();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return SweepGradient(colors: colors).createShader(bounds);
        },
        child: CircularProgressIndicator(
          strokeWidth: widget.size * 0.09,
          strokeCap: StrokeCap.round,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          backgroundColor: Colors.white.withOpacity(0.08),
        ),
      ),
    );
  }

  /// Three expanding concentric circles that fade outward, looping
  /// continuously for a soft "syncing" feel.
  Widget _buildPulseLoader() {
    final Color color = _effectiveColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          width: widget.size * 1.6,
          height: widget.size * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: List<Widget>.generate(3, (int index) {
              final double phase = index / 3;
              final double t = (_controller.value + phase) % 1.0;
              final double scale = 0.5 + (t * 1.0);
              final double opacity = (1.0 - t).clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            })
              ..add(Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )),
          ),
        );
      },
    );
  }

  /// Five animated bars with staggered, sine-driven heights, resembling
  /// an audio-reactive voice-assistant waveform.
  Widget _buildWaveLoader() {
    final Color color = _effectiveColor();
    final double barWidth = widget.size * 0.08;
    final double maxBarHeight = widget.size * 0.7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          height: maxBarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(5, (int index) {
              final double phase = index / 5;
              final double t = (_controller.value + phase) % 1.0;
              final double heightFactor =
                  0.25 + (sin(pi * t).abs() * 0.75);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: barWidth * 0.35),
                child: Container(
                  width: barWidth,
                  height: maxBarHeight * heightFactor,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  /// Skeleton-style placeholder blocks with a moving shimmer highlight,
  /// suited to previewing dashboard/content layouts while data loads.
  Widget _buildShimmerLoader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double sweep = _controller.value;

        return SizedBox(
          width: widget.size * 2.2,
          child: Column(
            children: List<Widget>.generate(3, (int index) {
              final double widthFactor = index == 2 ? 0.6 : 1.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildShimmerBar(
                  width: widget.size * 2.2 * widthFactor,
                  sweep: sweep,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBar({required double width, required double sweep}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: 14,
        color: Colors.white.withOpacity(0.08),
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            final double dx = (sweep * 2 - 1) * bounds.width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.0),
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ).createShader(bounds.shift(Offset(dx, 0)));
          },
          blendMode: BlendMode.srcATop,
          child: Container(color: Colors.white.withOpacity(0.06)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing every [AppLoadingType] on a dark
/// futuristic background.
class AppLoadingIndicatorDemo extends StatelessWidget {
  const AppLoadingIndicatorDemo({super.key});

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Premium Loading Indicators',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Smooth loading experiences make the app feel intelligent, alive, and trustworthy.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildDemoEntry(
                  label: 'Orb Loader',
                  child: const AppLoadingIndicator(
                    type: AppLoadingType.orb,
                    message: 'Preparing your AI companion...',
                  ),
                ),
                _buildDemoEntry(
                  label: 'Dots Loader',
                  child: const AppLoadingIndicator(
                    type: AppLoadingType.dots,
                    message: 'Saving your task...',
                  ),
                ),
                _buildDemoEntry(
                  label: 'Ring Loader',
                  child: const AppLoadingIndicator(
                    type: AppLoadingType.ring,
                    message: 'Calculating attendance...',
                  ),
                ),
                _buildDemoEntry(
                  label: 'Pulse Loader',
                  child: const AppLoadingIndicator(
                    type: AppLoadingType.pulse,
                    message: 'Syncing your data...',
                  ),
                ),
                _buildDemoEntry(
                  label: 'Wave Loader',
                  child: const AppLoadingIndicator(
                    type: AppLoadingType.wave,
                    message: 'Nova AI is thinking...',
                  ),
                ),
                _buildDemoEntry(
                  label: 'Shimmer Loader',
                  child: const AppLoadingIndicator(
                    type: AppLoadingType.shimmer,
                    message: 'Fetching your dashboard...',
                    showMessage: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoEntry({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 14),
          Center(child: child),
        ],
      ),
    );
  }
}

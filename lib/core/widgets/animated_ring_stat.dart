// lib/core/widgets/animated_ring_stat.dart

import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------

/// A premium, animated circular progress ring used throughout Student AI
/// Companion for stats such as attendance percentage, study progress,
/// water intake, focus timer completion, screen time health, GPA target
/// progress, and habit streaks.
///
/// Renders a gradient progress arc over a soft translucent background
/// ring with a subtle outer glow, animating from 0 to [value] with an
/// [Curves.easeOutCubic] curve, in the spirit of Apple Activity Rings.
class AnimatedRingStat extends StatefulWidget {
  const AnimatedRingStat({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    this.unit = '%',
    this.size = 120,
    this.strokeWidth = 12,
    this.duration = const Duration(milliseconds: 1200),
    this.gradientColors,
    this.backgroundColor,
    this.icon,
    this.showValue = true,
    this.showPercentage = false,
    this.animate = true,
    this.onTap,
  });

  /// Current value represented by the ring.
  final double value;

  /// The maximum possible value, used to compute progress (value/maxValue).
  final double maxValue;

  /// Label displayed beneath the main value (e.g. "Attendance").
  final String label;

  /// Unit suffix appended to the formatted value (e.g. "%", "h", "cups").
  /// When empty, no unit is shown.
  final String unit;

  /// Overall diameter of the ring, in logical pixels.
  final double size;

  /// Width of the ring stroke.
  final double strokeWidth;

  /// Duration of the fill animation.
  final Duration duration;

  /// Custom gradient colors for the progress arc. Defaults to a
  /// purple → indigo → cyan gradient when not provided.
  final List<Color>? gradientColors;

  /// Custom background ring color. Defaults to a soft translucent white.
  final Color? backgroundColor;

  /// Optional icon shown above the main value.
  final IconData? icon;

  /// Whether to render the center value/label content at all.
  final bool showValue;

  /// When true, the main value is formatted as a rounded percentage of
  /// [maxValue] instead of the raw [value].
  final bool showPercentage;

  /// Whether the fill animation should run. When false, the ring renders
  /// directly at its target progress.
  final bool animate;

  /// Optional tap callback. When provided, tapping the ring triggers a
  /// soft scale-down feedback animation.
  final VoidCallback? onTap;

  static const List<Color> _defaultGradient = <Color>[
    Color(0xFF7C4DFF),
    Color(0xFF5B8CFF),
    Color(0xFF00E5FF),
  ];

  @override
  State<AnimatedRingStat> createState() => _AnimatedRingStatState();
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

class _AnimatedRingStatState extends State<AnimatedRingStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: _progress(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedRingStat oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool targetChanged = oldWidget.value != widget.value ||
        oldWidget.maxValue != widget.maxValue;

    if (targetChanged) {
      final double previousProgress = _animation.value;

      _animation = Tween<double>(
        begin: previousProgress,
        end: _progress(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      if (widget.animate) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  double _progress() {
    if (widget.maxValue <= 0) return 0.0;
    return (widget.value / widget.maxValue).clamp(0.0, 1.0);
  }

  String _formattedValue() {
    if (widget.showPercentage) {
      final int percent = (widget.value / widget.maxValue * 100).round();
      return '$percent%';
    }

    final String base = widget.value.toStringAsFixed(0);
    if (widget.unit.isEmpty) return base;
    return '$base${widget.unit == '%' ? widget.unit : ' ${widget.unit}'}';
  }

  List<Color> _effectiveGradient() {
    return widget.gradientColors ?? AnimatedRingStat._defaultGradient;
  }

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = pressed);
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient = _effectiveGradient();
    final Color background =
        widget.backgroundColor ?? Colors.white.withOpacity(0.08);

    final Widget ring = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: gradient.first.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RingPainter(
                progress: _animation.value,
                strokeWidth: widget.strokeWidth,
                gradientColors: gradient,
                backgroundColor: background,
              ),
              child: widget.showValue
                  ? _buildCenterContent(context)
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );

    final Widget interactive = GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: ring,
      ),
    );

    return interactive;
  }

  Widget _buildCenterContent(BuildContext context) {
    final double iconSize = widget.size * 0.18;
    final double valueFontSize = widget.size * 0.16;
    final double labelFontSize = widget.size * 0.10;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(
              widget.icon,
              size: iconSize,
              color: Colors.white.withOpacity(0.85),
            ),
            SizedBox(height: widget.size * 0.04),
          ],
          Text(
            _formattedValue(),
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          SizedBox(height: widget.size * 0.02),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Custom Painter
// ---------------------------------------------------------------------

/// Paints the background ring and the animated gradient progress arc for
/// [AnimatedRingStat].
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    // Background ring.
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return;

    // Animated progress arc.
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    final double sweepAngle = 2 * pi * progress;

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: 2 * pi,
        transform: const GradientRotation(-pi / 2),
        colors: gradientColors,
        stops: List<double>.generate(
          gradientColors.length,
          (int index) => index / (gradientColors.length - 1),
        ),
      ).createShader(arcRect);

    canvas.drawArc(
      arcRect,
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing [AnimatedRingStat] in a responsive,
/// dashboard-style grid on a dark futuristic background.
class AnimatedRingStatDemo extends StatelessWidget {
  const AnimatedRingStatDemo({super.key});

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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "Today's Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Small progress every day becomes big success.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1,
                    children: const <Widget>[
                      Center(
                        child: AnimatedRingStat(
                          value: 86,
                          maxValue: 100,
                          label: 'Attendance',
                          icon: Icons.school_rounded,
                        ),
                      ),
                      Center(
                        child: AnimatedRingStat(
                          value: 3,
                          maxValue: 5,
                          label: 'Focus Time',
                          unit: 'h',
                          icon: Icons.timer_rounded,
                        ),
                      ),
                      Center(
                        child: AnimatedRingStat(
                          value: 6,
                          maxValue: 8,
                          label: 'Water Intake',
                          unit: 'cups',
                          icon: Icons.water_drop_rounded,
                        ),
                      ),
                      Center(
                        child: AnimatedRingStat(
                          value: 72,
                          maxValue: 100,
                          label: 'Screen Balance',
                          icon: Icons.phone_android_rounded,
                        ),
                      ),
                    ],
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


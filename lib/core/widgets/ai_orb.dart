// lib/core/widgets/ai_orb.dart

import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Mood enum
// ---------------------------------------------------------------------

/// Emotional states the AI companion orb can express.
enum AiOrbMood {
  idle,
  happy,
  thinking,
  listening,
  speaking,
  sleeping,
  excited,
  sad,
}

/// A living, breathing representation of the AI companion.
///
/// Used as the home-screen assistant, the floating overlay companion, a
/// voice-listening indicator, a thinking indicator, and a study
/// encouragement presence. Renders a soft, glassy, multi-layer glow orb
/// with an optional minimal face, and reacts to [mood] with distinct
/// motion and color behaviors.
class AiOrb extends StatefulWidget {
  const AiOrb({
    super.key,
    this.size = 96,
    this.mood = AiOrbMood.idle,
    this.showGlow = true,
    this.showFace = true,
    this.animate = true,
    this.onTap,
  });

  /// Diameter of the orb's core.
  final double size;

  /// Current emotional state of the companion.
  final AiOrbMood mood;

  /// Whether to render the layered glow behind the orb.
  final bool showGlow;

  /// Whether to render the minimal face (eyes + mouth).
  final bool showFace;

  /// Whether mood animations should run. When false, the orb renders
  /// statically at its resting state.
  final bool animate;

  /// Optional tap callback. When provided, tapping the orb triggers a
  /// soft scale-down feedback animation.
  final VoidCallback? onTap;

  @override
  State<AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<AiOrb> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDurationForMood(widget.mood),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _blinkAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        weight: 88,
        tween: ConstantTween<double>(1.0),
      ),
      TweenSequenceItem<double>(
        weight: 6,
        tween: Tween<double>(begin: 1.0, end: 0.08)
            .chain(CurveTween(curve: Curves.easeIn)),
      ),
      TweenSequenceItem<double>(
        weight: 6,
        tween: Tween<double>(begin: 0.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
      ),
    ]).animate(_blinkController);

    _applyAnimationState();
  }

  @override
  void didUpdateWidget(covariant AiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _pulseController.duration = _pulseDurationForMood(widget.mood);
    }
    if (oldWidget.animate != widget.animate) {
      _applyAnimationState();
    } else if (oldWidget.mood != widget.mood && widget.animate) {
      _applyAnimationState();
    }
  }

  void _applyAnimationState() {
    if (!widget.animate) {
      _pulseController.stop();
      _rotationController.stop();
      _waveController.stop();
      _blinkController.stop();
      return;
    }

    _pulseController.repeat(reverse: true);
    _blinkController.repeat();

    if (widget.mood == AiOrbMood.thinking) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    if (widget.mood == AiOrbMood.listening) {
      _waveController.repeat();
    } else {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Mood-driven timing
  // ---------------------------------------------------------------------

  Duration _pulseDurationForMood(AiOrbMood mood) {
    switch (mood) {
      case AiOrbMood.excited:
        return const Duration(milliseconds: 900);
      case AiOrbMood.speaking:
        return const Duration(milliseconds: 650);
      case AiOrbMood.happy:
        return const Duration(milliseconds: 1400);
      case AiOrbMood.listening:
        return const Duration(milliseconds: 1600);
      case AiOrbMood.thinking:
        return const Duration(milliseconds: 2000);
      case AiOrbMood.sleeping:
        return const Duration(milliseconds: 3200);
      case AiOrbMood.sad:
        return const Duration(milliseconds: 2600);
      case AiOrbMood.idle:
        return const Duration(milliseconds: 2200);
    }
  }

  // ---------------------------------------------------------------------
  // Mood-driven colors
  // ---------------------------------------------------------------------

  Color _primaryColor(AiOrbMood mood) {
    switch (mood) {
      case AiOrbMood.idle:
        return const Color(0xFF7C4DFF);
      case AiOrbMood.happy:
        return const Color(0xFF00E5FF);
      case AiOrbMood.thinking:
        return const Color(0xFF6A3DFF);
      case AiOrbMood.listening:
        return const Color(0xFF00E5FF);
      case AiOrbMood.speaking:
        return const Color(0xFF7C4DFF);
      case AiOrbMood.sleeping:
        return const Color(0xFF3A3F6B);
      case AiOrbMood.excited:
        return const Color(0xFFFF7AD5);
      case AiOrbMood.sad:
        return const Color(0xFF5B6478);
    }
  }

  Color _secondaryColor(AiOrbMood mood) {
    switch (mood) {
      case AiOrbMood.idle:
        return const Color(0xFF00E5FF);
      case AiOrbMood.happy:
        return const Color(0xFF5BFFDA);
      case AiOrbMood.thinking:
        return const Color(0xFF00C2FF);
      case AiOrbMood.listening:
        return const Color(0xFF7C4DFF);
      case AiOrbMood.speaking:
        return const Color(0xFF00E5FF);
      case AiOrbMood.sleeping:
        return const Color(0xFF1B1E3A);
      case AiOrbMood.excited:
        return const Color(0xFF7C4DFF);
      case AiOrbMood.sad:
        return const Color(0xFF3A3F52);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double stageSize = widget.size * 2.4;

    final Widget orb = SizedBox(
      width: stageSize,
      height: stageSize,
      child: AnimatedBuilder(
        animation: Listenable.merge(
          <Listenable>[_pulseController, _rotationController, _waveController],
        ),
        builder: (BuildContext context, Widget? child) {
          final double pulseValue =
              widget.animate ? _pulseController.value : 0.5;
          final double breath = _breathScale(pulseValue);
          final double floatOffset = _floatOffset(pulseValue);
          final Color primary = _primaryColor(widget.mood);
          final Color secondary = _secondaryColor(widget.mood);

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (widget.showGlow)
                  _buildGlowLayer(
                    size: widget.size * 2.1,
                    color: primary,
                    blur: 60,
                    opacity: _glowOpacity(pulseValue) * 0.5,
                  ),
                if (widget.showGlow)
                  _buildGlowLayer(
                    size: widget.size * 1.6,
                    color: secondary,
                    blur: 34,
                    opacity: _glowOpacity(pulseValue) * 0.6,
                  ),
                if (widget.mood == AiOrbMood.listening)
                  ..._buildPulseWaves(primary),
                if (widget.mood == AiOrbMood.thinking)
                  Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: _buildPulseRing(
                      size: widget.size * 1.3,
                      color: secondary,
                    ),
                  ),
                Transform.scale(
                  scale: breath,
                  child: _buildCoreOrb(primary, secondary),
                ),
              ],
            ),
          );
        },
      ),
    );

    final Widget interactiveOrb = GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: orb,
      ),
    );

    return AnimatedOpacity(
      opacity: widget.mood == AiOrbMood.sleeping ? 0.75 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: interactiveOrb,
    );
  }

  void _setPressed(bool pressed) {
    setState(() => _isPressed = pressed);
  }

  // ---------------------------------------------------------------------
  // Motion helpers
  // ---------------------------------------------------------------------

  double _breathScale(double pulseValue) {
    switch (widget.mood) {
      case AiOrbMood.happy:
        return 1.0 + (pulseValue * 0.10);
      case AiOrbMood.excited:
        return 1.0 + (pulseValue * 0.14);
      case AiOrbMood.speaking:
        return 1.0 + (pulseValue * 0.08);
      case AiOrbMood.sleeping:
        return 1.0 + (pulseValue * 0.02);
      case AiOrbMood.sad:
        return 1.0 - (pulseValue * 0.02);
      case AiOrbMood.listening:
        return 1.0 + (pulseValue * 0.05);
      case AiOrbMood.thinking:
        return 1.0 + (pulseValue * 0.03);
      case AiOrbMood.idle:
        return 1.0 + (pulseValue * 0.05);
    }
  }

  double _floatOffset(double pulseValue) {
    switch (widget.mood) {
      case AiOrbMood.sleeping:
        return pulseValue * 4;
      case AiOrbMood.sad:
        return 4 + (pulseValue * 2);
      case AiOrbMood.excited:
        return -(pulseValue * 4);
      default:
        return -(pulseValue * 2);
    }
  }

  double _glowOpacity(double pulseValue) {
    switch (widget.mood) {
      case AiOrbMood.sleeping:
        return 0.15 + (pulseValue * 0.10);
      case AiOrbMood.sad:
        return 0.25 + (pulseValue * 0.10);
      case AiOrbMood.excited:
        return 0.55 + (pulseValue * 0.35);
      case AiOrbMood.listening:
        return 0.50 + (pulseValue * 0.30);
      default:
        return 0.35 + (pulseValue * 0.25);
    }
  }

  // ---------------------------------------------------------------------
  // Layer builders
  // ---------------------------------------------------------------------

  Widget _buildGlowLayer({
    required double size,
    required Color color,
    required double blur,
    required double opacity,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withOpacity(opacity.clamp(0.0, 1.0)),
            blurRadius: blur,
            spreadRadius: blur / 6,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2.5,
        ),
      ),
    );
  }

  List<Widget> _buildPulseWaves(Color color) {
    return List<Widget>.generate(3, (int index) {
      final double phase = (index / 3);
      final double t = (_waveController.value + phase) % 1.0;
      final double scale = 0.7 + (t * 0.9);
      final double opacity = (1.0 - t).clamp(0.0, 1.0);

      return Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size * 1.2,
            height: widget.size * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 1.6,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCoreOrb(Color primary, Color secondary) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[primary, Color.lerp(primary, secondary, 0.5)!, secondary],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primary.withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Inner highlight for a soft glass-like sheen.
          Align(
            alignment: const Alignment(-0.4, -0.5),
            child: Container(
              width: widget.size * 0.35,
              height: widget.size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ),
          if (widget.showFace) _buildFace(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Face
  // ---------------------------------------------------------------------

  Widget _buildFace() {
    final double eyeSize = widget.size * 0.11;
    final double eyeGap = widget.size * 0.22;

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (BuildContext context, Widget? child) {
        final double openness =
            widget.mood == AiOrbMood.sleeping ? 0.08 : _blinkAnimation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildEye(eyeSize, openness),
                SizedBox(width: eyeGap),
                _buildEye(eyeSize, openness),
              ],
            ),
            SizedBox(height: widget.size * 0.10),
            _buildMouth(),
          ],
        );
      },
    );
  }

  Widget _buildEye(double eyeSize, double openness) {
    return Container(
      width: eyeSize,
      height: eyeSize * openness.clamp(0.08, 1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(eyeSize),
      ),
    );
  }

  Widget _buildMouth() {
    final double mouthWidth = widget.size * 0.28;

    switch (widget.mood) {
      case AiOrbMood.happy:
      case AiOrbMood.excited:
        return CustomPaint(
          size: Size(mouthWidth, mouthWidth * 0.5),
          painter: _SmilePainter(color: Colors.white),
        );
      case AiOrbMood.thinking:
        return Container(
          width: mouthWidth * 0.5,
          height: 2.5,
          color: Colors.white.withOpacity(0.8),
        );
      case AiOrbMood.listening:
        return Container(
          width: mouthWidth * 0.22,
          height: mouthWidth * 0.22,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
        );
      case AiOrbMood.speaking:
        return TweenAnimationBuilder<double>(
          key: ValueKey<AiOrbMood>(widget.mood),
          tween: Tween<double>(begin: 0.3, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          builder: (BuildContext context, double value, Widget? child) {
            return Container(
              width: mouthWidth * 0.4,
              height: (mouthWidth * 0.35) * value,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        );
      case AiOrbMood.sleeping:
        return Container(
          width: mouthWidth * 0.35,
          height: 2,
          color: Colors.white.withOpacity(0.6),
        );
      case AiOrbMood.sad:
        return CustomPaint(
          size: Size(mouthWidth, mouthWidth * 0.4),
          painter: _SmilePainter(color: Colors.white70, inverted: true),
        );
      case AiOrbMood.idle:
        return Container(
          width: mouthWidth * 0.45,
          height: 2.5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(4),
          ),
        );
    }
  }
}

/// Paints a minimal curved smile (or, when [inverted] is true, a gentle
/// downward curve for a sad expression).
class _SmilePainter extends CustomPainter {
  const _SmilePainter({required this.color, this.inverted = false});

  final Color color;
  final bool inverted;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    final double startY = inverted ? 0 : size.height;
    final double controlY = inverted ? size.height : 0;
    final double endY = inverted ? 0 : size.height;

    path.moveTo(0, startY);
    path.quadraticBezierTo(size.width / 2, controlY, size.width, endY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SmilePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.inverted != inverted;
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing [AiOrb] across every [AiOrbMood], with
/// buttons to switch moods live.
class AiOrbDemo extends StatefulWidget {
  const AiOrbDemo({super.key});

  @override
  State<AiOrbDemo> createState() => _AiOrbDemoState();
}

class _AiOrbDemoState extends State<AiOrbDemo> {
  AiOrbMood _mood = AiOrbMood.idle;

  static const Map<AiOrbMood, String> _moodLabels = <AiOrbMood, String>{
    AiOrbMood.idle: 'Idle',
    AiOrbMood.happy: 'Happy',
    AiOrbMood.thinking: 'Thinking',
    AiOrbMood.listening: 'Listening',
    AiOrbMood.speaking: 'Speaking',
    AiOrbMood.sleeping: 'Sleeping',
    AiOrbMood.excited: 'Excited',
    AiOrbMood.sad: 'Sad',
  };

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
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: AiOrb(size: 140, mood: _mood),
                ),
              ),
              Text(
                'Your emotional AI companion is always here for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _moodLabels.entries.map((
                    MapEntry<AiOrbMood, String> entry,
                  ) {
                    final bool selected = entry.key == _mood;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => setState(() => _mood = entry.key),
                      selectedColor: const Color(0xFF7C4DFF),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}


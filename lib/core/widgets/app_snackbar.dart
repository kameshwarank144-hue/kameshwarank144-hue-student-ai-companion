// lib/core/widgets/app_snackbar.dart

import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------

/// The semantic type of an [AppSnackbar] message, controlling its accent
/// color and icon.
enum AppSnackbarType {
  success,
  error,
  warning,
  info,
  ai,
}

// ---------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------

/// A premium, glassmorphism replacement for Flutter's default
/// [SnackBar], used throughout Student AI Companion for feedback
/// messages, status updates, and AI companion notes.
///
/// Contains static methods only — call [AppSnackbar.show] directly, or
/// use one of the convenience shorthands ([success], [error], [warning],
/// [info], [ai]).
class AppSnackbar {
  AppSnackbar._();

  /// Displays a floating, glassmorphism snackbar with the given
  /// [message], optional [title], [type]-driven styling, and optional
  /// [action] button.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: _buildContent(
          context,
          message: message,
          title: title,
          type: type,
          action: action,
        ),
      ),
    );
  }

  /// Shows a success message with a green accent.
  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.success);
  }

  /// Shows an error message with a coral red accent.
  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.error);
  }

  /// Shows a warning message with an amber accent.
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.warning);
  }

  /// Shows an informational message with a cyan accent.
  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.info);
  }

  /// Shows an encouraging AI companion message, automatically prefixed
  /// with a friendly "Nova AI •" tone marker when not already present.
  static void ai(BuildContext context, String message) {
    final String prefixed =
        message.startsWith('Nova AI') ? message : 'Nova AI • $message';

    show(context, message: prefixed, type: AppSnackbarType.ai);
  }

  // ---------------------------------------------------------------------
  // Snackbar Builder
  // ---------------------------------------------------------------------

  static Widget _buildContent(
    BuildContext context, {
    required String message,
    String? title,
    required AppSnackbarType type,
    SnackBarAction? action,
  }) {
    final Color accent = _accentColor(type);

    return _AnimatedSnackbarEntrance(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildIcon(type, accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (title != null) ...<Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: action.onPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      action.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  static Color _accentColor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return const Color(0xFF34D399); // Green
      case AppSnackbarType.error:
        return const Color(0xFFFF6B5B); // Coral red
      case AppSnackbarType.warning:
        return const Color(0xFFFBBF24); // Amber
      case AppSnackbarType.info:
        return const Color(0xFF00E5FF); // Cyan
      case AppSnackbarType.ai:
        return const Color(0xFF7C4DFF); // Purple (paired with cyan)
    }
  }

  static IconData _icon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_rounded;
      case AppSnackbarType.error:
        return Icons.error_rounded;
      case AppSnackbarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackbarType.info:
        return Icons.info_rounded;
      case AppSnackbarType.ai:
        return Icons.auto_awesome_rounded;
    }
  }

  static Widget _buildIcon(AppSnackbarType type, Color accent) {
    final Gradient? gradient = type == AppSnackbarType.ai
        ? const LinearGradient(
            colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
          )
        : null;

    return _GlowIcon(
      icon: _icon(type),
      color: accent,
      gradient: gradient,
    );
  }
}

// ---------------------------------------------------------------------
// Entrance animation wrapper
// ---------------------------------------------------------------------

/// Fades, slides up, and gently scales its [child] in when first built,
/// giving [AppSnackbar] a softer entrance than the default SnackBar
/// transition.
class _AnimatedSnackbarEntrance extends StatefulWidget {
  const _AnimatedSnackbarEntrance({required this.child});

  final Widget child;

  @override
  State<_AnimatedSnackbarEntrance> createState() =>
      _AnimatedSnackbarEntranceState();
}

class _AnimatedSnackbarEntranceState extends State<_AnimatedSnackbarEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _visible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------
// Glowing icon
// ---------------------------------------------------------------------

/// A small circular container with a soft, gently pulsing glow behind
/// the type icon.
class _GlowIcon extends StatefulWidget {
  const _GlowIcon({required this.icon, required this.color, this.gradient});

  final IconData icon;
  final Color color;
  final Gradient? gradient;

  @override
  State<_GlowIcon> createState() => _GlowIconState();
}

class _GlowIconState extends State<_GlowIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
        final double glow = 0.35 + (_controller.value * 0.25);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.gradient == null
                ? widget.color.withOpacity(0.16)
                : null,
            gradient: widget.gradient,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.color.withOpacity(glow),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.gradient == null ? widget.color : Colors.white,
            size: 18,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing every [AppSnackbarType] via [AppSnackbar]
/// on a dark futuristic background.
class AppSnackbarDemo extends StatelessWidget {
  const AppSnackbarDemo({super.key});

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
                  'Premium App Snackbars',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Beautiful feedback messages make the app feel alive, helpful, and emotionally intelligent.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () => AppSnackbar.success(
                        context,
                        'Task saved successfully!',
                      ),
                      child: const Text('Show Success'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppSnackbar.error(
                        context,
                        'Something went wrong. Please try again.',
                      ),
                      child: const Text('Show Error'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppSnackbar.warning(
                        context,
                        'Your attendance is close to the minimum limit.',
                      ),
                      child: const Text('Show Warning'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppSnackbar.info(
                        context,
                        'Your timetable was synced.',
                      ),
                      child: const Text('Show Info'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppSnackbar.ai(
                        context,
                        "Don't forget tomorrow's DBMS lab 👋",
                      ),
                      child: const Text('Show AI Message'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


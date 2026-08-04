// lib/core/widgets/empty_state_illustration.dart

import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------

/// The context an [EmptyStateIllustration] is being shown for, used to
/// pick sensible default copy, an icon, and an accent color.
enum EmptyStateType {
  tasks,
  timetable,
  attendance,
  notes,
  reminders,
  study,
  chat,
  expenses,
  analytics,
  generic,
}

// ---------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------

/// A premium, friendly, glassmorphism-inspired empty state used whenever
/// a screen in Student AI Companion has no data yet — no tasks, no
/// timetable, no attendance records, no notes, no reminders, no study
/// sessions, no AI conversations, no expenses, or no analytics.
///
/// Renders a soft animated illustration (a floating glowing orb with
/// gently fading particles) built entirely from Flutter widgets, plus a
/// title, subtitle, and optional action button.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    this.type = EmptyStateType.generic,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showOrb = true,
    this.compact = false,
  });

  /// The context this empty state represents. Drives the default title,
  /// subtitle, icon, and accent color.
  final EmptyStateType type;

  /// Overrides the default title for [type].
  final String? title;

  /// Overrides the default subtitle for [type].
  final String? subtitle;

  /// Label for an optional call-to-action button.
  final String? actionLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  /// Whether to render the animated glowing orb illustration.
  final bool showOrb;

  /// When true, renders a smaller, horizontal layout suited to embedded
  /// cards and dashboard sections rather than a full-page empty state.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(compact ? 16 : 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: compact ? _buildCompactLayout() : _buildNormalLayout(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Defaults
  // ---------------------------------------------------------------------

  String _defaultTitle() {
    switch (type) {
      case EmptyStateType.tasks:
        return 'No tasks yet';
      case EmptyStateType.timetable:
        return 'Your timetable is empty';
      case EmptyStateType.attendance:
        return 'No attendance data';
      case EmptyStateType.notes:
        return 'No notes uploaded';
      case EmptyStateType.reminders:
        return 'No reminders set';
      case EmptyStateType.study:
        return 'Ready to focus?';
      case EmptyStateType.chat:
        return 'Start a conversation';
      case EmptyStateType.expenses:
        return 'No expenses logged';
      case EmptyStateType.analytics:
        return 'No analytics yet';
      case EmptyStateType.generic:
        return 'Nothing here yet';
    }
  }

  String _defaultSubtitle() {
    switch (type) {
      case EmptyStateType.tasks:
        return 'Add your first task and let your AI companion help you stay organized.';
      case EmptyStateType.timetable:
        return 'Import or create your semester schedule to receive smart reminders.';
      case EmptyStateType.attendance:
        return "Start tracking your classes and we'll calculate your attendance automatically.";
      case EmptyStateType.notes:
        return 'Upload PDFs, class notes, or study material and let AI summarize them for you.';
      case EmptyStateType.reminders:
        return "We'll gently nudge you for classes, medicine, water, and more once set.";
      case EmptyStateType.study:
        return 'Start a Pomodoro session and grow your productivity streak one step at a time.';
      case EmptyStateType.chat:
        return 'Ask Nova AI anything about your college life, studies, or productivity.';
      case EmptyStateType.expenses:
        return 'Log your first expense to start understanding your spending habits.';
      case EmptyStateType.analytics:
        return 'Keep using the app and your personal insights will start appearing here.';
      case EmptyStateType.generic:
        return 'Your AI companion is ready whenever you are ✨';
    }
  }

  Color _accentColor() {
    switch (type) {
      case EmptyStateType.tasks:
        return const Color(0xFF7C4DFF); // Purple
      case EmptyStateType.timetable:
        return const Color(0xFF6C63FF); // Indigo
      case EmptyStateType.attendance:
        return const Color(0xFF00E5FF); // Cyan
      case EmptyStateType.notes:
        return const Color(0xFF3B82F6); // Blue
      case EmptyStateType.reminders:
        return const Color(0xFFFF9142); // Orange
      case EmptyStateType.study:
        return const Color(0xFF4ADE80); // Green
      case EmptyStateType.chat:
        return const Color(0xFF7C4DFF); // Purple (+ Cyan secondary)
      case EmptyStateType.expenses:
        return const Color(0xFF10B981); // Emerald
      case EmptyStateType.analytics:
        return const Color(0xFFEC4899); // Pink
      case EmptyStateType.generic:
        return const Color(0xFF6C63FF); // Indigo
    }
  }

  Color _secondaryAccentColor() {
    if (type == EmptyStateType.chat) {
      return const Color(0xFF00E5FF); // Cyan pairing for chat
    }
    return _accentColor().withOpacity(0.6);
  }

  IconData _iconForType() {
    switch (type) {
      case EmptyStateType.tasks:
        return Icons.checklist_rounded;
      case EmptyStateType.timetable:
        return Icons.calendar_month_rounded;
      case EmptyStateType.attendance:
        return Icons.fact_check_rounded;
      case EmptyStateType.notes:
        return Icons.description_rounded;
      case EmptyStateType.reminders:
        return Icons.notifications_active_rounded;
      case EmptyStateType.study:
        return Icons.timer_rounded;
      case EmptyStateType.chat:
        return Icons.auto_awesome_rounded;
      case EmptyStateType.expenses:
        return Icons.account_balance_wallet_rounded;
      case EmptyStateType.analytics:
        return Icons.insights_rounded;
      case EmptyStateType.generic:
        return Icons.star_rounded;
    }
  }

  // ---------------------------------------------------------------------
  // Illustration
  // ---------------------------------------------------------------------

  Widget _buildIllustration({required double size}) {
    return _EmptyStateOrb(
      size: size,
      icon: _iconForType(),
      primaryColor: _accentColor(),
      secondaryColor: _secondaryAccentColor(),
    );
  }

  // ---------------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------------

  Widget _buildNormalLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showOrb) ...<Widget>[
          _buildIllustration(size: 120),
          const SizedBox(height: 24),
        ],
        Text(
          title ?? _defaultTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle ?? _defaultSubtitle(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (actionLabel != null) ...<Widget>[
          const SizedBox(height: 20),
          _buildActionButton(),
        ],
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: <Widget>[
        if (showOrb) ...<Widget>[
          _buildIllustration(size: 56),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title ?? _defaultTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle ?? _defaultSubtitle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null) ...<Widget>[
          const SizedBox(width: 12),
          _buildActionButton(compact: true),
        ],
      ],
    );
  }

  Widget _buildActionButton({bool compact = false}) {
    return GestureDetector(
      onTap: onAction,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          actionLabel!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Animated orb illustration
// ---------------------------------------------------------------------

/// A softly floating, pulsing, particle-surrounded orb used as the core
/// visual for [EmptyStateIllustration]. Built entirely from Flutter
/// primitives with implicit animations — no external SVG assets.
class _EmptyStateOrb extends StatefulWidget {
  const _EmptyStateOrb({
    required this.size,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double size;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  State<_EmptyStateOrb> createState() => _EmptyStateOrbState();
}

class _EmptyStateOrbState extends State<_EmptyStateOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double stageSize = widget.size * 1.9;

    return SizedBox(
      width: stageSize,
      height: stageSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = _controller.value;
          final double floatOffset = -(t * 8);
          final double glowOpacity = 0.35 + (t * 0.25);
          final double particleOpacityA = (0.9 - t).clamp(0.0, 1.0);
          final double particleOpacityB = t.clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Soft outer circular gradient glow.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (BuildContext context, double scale, Widget? _) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 1.7,
                      height: widget.size * 1.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            widget.primaryColor.withOpacity(glowOpacity * 0.4),
                            widget.primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Tiny floating particles.
              _buildParticle(
                alignment: const Alignment(-0.9, -0.7),
                opacity: particleOpacityA,
                color: widget.secondaryColor,
              ),
              _buildParticle(
                alignment: const Alignment(0.85, -0.4),
                opacity: particleOpacityB,
                color: widget.primaryColor,
              ),
              _buildParticle(
                alignment: const Alignment(-0.75, 0.8),
                opacity: particleOpacityB,
                color: widget.primaryColor,
              ),
              _buildParticle(
                alignment: const Alignment(0.9, 0.75),
                opacity: particleOpacityA,
                color: widget.secondaryColor,
              ),

              // Floating glowing core orb.
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: AnimatedScale(
                  scale: 1.0 + (t * 0.04),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          widget.primaryColor,
                          widget.secondaryColor,
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(glowOpacity),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: Colors.white.withOpacity(0.9),
                        size: widget.size * 0.36,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticle({
    required Alignment alignment,
    required double opacity,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 400),
        child: Container(
          width: widget.size * 0.06,
          height: widget.size * 0.06,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing [EmptyStateIllustration] across several
/// [EmptyStateType] values on a dark futuristic background.
class EmptyStateIllustrationDemo extends StatelessWidget {
  const EmptyStateIllustrationDemo({super.key});

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
                  'Premium Empty States',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Beautiful empty experiences make the app feel alive even before the user adds data.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                EmptyStateIllustration(
                  type: EmptyStateType.tasks,
                  actionLabel: 'Add Task',
                  onAction: () {},
                ),
                const SizedBox(height: 20),
                EmptyStateIllustration(
                  type: EmptyStateType.timetable,
                  actionLabel: 'Create Timetable',
                  onAction: () {},
                ),
                const SizedBox(height: 20),
                EmptyStateIllustration(
                  type: EmptyStateType.attendance,
                  actionLabel: 'Start Tracking',
                  onAction: () {},
                ),
                const SizedBox(height: 20),
                EmptyStateIllustration(
                  type: EmptyStateType.notes,
                  actionLabel: 'Upload Notes',
                  onAction: () {},
                ),
                const SizedBox(height: 20),
                EmptyStateIllustration(
                  type: EmptyStateType.study,
                  actionLabel: 'Start Focus Session',
                  onAction: () {},
                ),
                const SizedBox(height: 20),
                EmptyStateIllustration(
                  type: EmptyStateType.chat,
                  actionLabel: 'Ask Nova AI',
                  onAction: () {},
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


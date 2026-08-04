// lib/core/widgets/timeline_card.dart

import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------

/// An immutable event displayed on a [TimelineCard].
///
/// Used for today's classes, upcoming exams, assignment deadlines, study
/// sessions, reminder notifications, AI-generated schedule suggestions,
/// and general productivity timeline entries.
class TimelineEvent {
  const TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  /// The event's primary label (e.g. "Digital Electronics").
  final String title;

  /// Supporting detail shown beneath the title (e.g. "Room 302 • Prof. Arun").
  final String subtitle;

  /// The event's scheduled date and time.
  final DateTime time;

  /// Icon shown inside the event's glowing marker.
  final IconData icon;

  /// Accent color for the event's marker, glow, and highlights.
  final Color color;

  /// Whether the event has already passed / been completed.
  final bool isCompleted;

  /// Whether the event is happening right now.
  final bool isCurrent;
}

// ---------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------

/// A premium, glassmorphism timeline card used throughout Student AI
/// Companion to present chronological events in a soft, animated,
/// student-friendly layout inspired by Apple Calendar, Notion, and
/// Nothing OS.
class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.title,
    required this.events,
    this.showDate = true,
    this.showProgress = true,
    this.onEventTap,
  });

  /// The timeline's heading (e.g. "Today's Schedule").
  final String title;

  /// The chronological events to display, in order.
  final List<TimelineEvent> events;

  /// Whether to show today's date beneath the title.
  final bool showDate;

  /// Whether to show a "completed / total" progress summary.
  final bool showProgress;

  /// Called with the tapped event when an event row is pressed.
  final ValueChanged<TimelineEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    final int completedCount =
        events.where((TimelineEvent event) => event.isCompleted).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(context, completedCount),
              const SizedBox(height: 18),
              if (events.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: List<Widget>.generate(events.length, (int index) {
                    final bool isLast = index == events.length - 1;
                    return _buildTimelineItem(events[index], isLast);
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, int completedCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showDate) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showProgress && events.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Text(
              '$completedCount / ${events.length} completed',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Timeline Item
  // ---------------------------------------------------------------------

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    final Widget row = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              children: <Widget>[
                _EventMarker(event: event),
                if (!isLast) Expanded(child: _buildConnector(event)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22, top: 2),
                child: AnimatedOpacity(
                  opacity: event.isCompleted ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(event.isCurrent ? 12 : 0),
                    decoration: BoxDecoration(
                      color: event.isCurrent
                          ? event.color.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: event.isCurrent
                          ? Border.all(
                              color: event.color.withOpacity(0.25),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: event.isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        decoration: event.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  if (event.isCurrent) ...<Widget>[
                                    const SizedBox(width: 8),
                                    _PulseDot(color: event.color),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(event.time),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget scaled = AnimatedScale(
      scale: event.isCurrent ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: row,
    );

    if (onEventTap == null) return scaled;

    return GestureDetector(
      onTap: () => onEventTap!(event),
      child: scaled,
    );
  }

  Widget _buildConnector(TimelineEvent event) {
    return Container(
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: event.isCompleted
            ? Colors.white.withOpacity(0.25)
            : Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No events today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enjoy your free time and stay productive ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------

  String _formatTime(DateTime time) {
    final int hour24 = time.hour;
    final int hour12 =
        hour24 % 12 == 0 ? 12 : hour24 % 12;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = hour24 >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ---------------------------------------------------------------------
// Event marker
// ---------------------------------------------------------------------

/// The circular glowing icon marker shown to the left of each event.
/// Renders a checkmark overlay for completed events and a brighter glow
/// with slight scale emphasis for the current event.
class _EventMarker extends StatelessWidget {
  const _EventMarker({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final double size = event.isCurrent ? 40 : 34;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: event.isCompleted
            ? Colors.white.withOpacity(0.08)
            : event.color.withOpacity(0.18),
        border: Border.all(
          color: event.isCompleted
              ? Colors.white.withOpacity(0.2)
              : event.color.withOpacity(0.5),
          width: 1.4,
        ),
        boxShadow: event.isCurrent
            ? <BoxShadow>[
                BoxShadow(
                  color: event.color.withOpacity(0.5),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: event.isCompleted
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey<String>('completed'),
                color: Colors.white.withOpacity(0.8),
                size: 18,
              )
            : Icon(
                event.icon,
                key: ValueKey<IconData>(event.icon),
                color: event.color,
                size: 18,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Pulse indicator
// ---------------------------------------------------------------------

/// A small, continuously pulsing dot used to draw attention to the
/// currently active timeline event.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
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
        final double scale = 0.8 + (_controller.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.color.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing [TimelineCard] with a sample "Today's
/// Schedule" timeline on a dark futuristic background.
class TimelineCardDemo extends StatelessWidget {
  const TimelineCardDemo({super.key});

  DateTime _timeToday(int hour, int minute) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final List<TimelineEvent> events = <TimelineEvent>[
      TimelineEvent(
        title: 'Digital Electronics',
        subtitle: 'Room 302 • Prof. Arun',
        time: _timeToday(8, 30),
        icon: Icons.school_rounded,
        color: const Color(0xFF7C4DFF),
        isCurrent: true,
      ),
      TimelineEvent(
        title: 'DBMS Lab',
        subtitle: 'Lab Block B',
        time: _timeToday(11, 0),
        icon: Icons.computer_rounded,
        color: const Color(0xFF00E5FF),
      ),
      TimelineEvent(
        title: 'Project Discussion',
        subtitle: 'Team meeting • Mini Project',
        time: _timeToday(14, 0),
        icon: Icons.groups_rounded,
        color: const Color(0xFF5B8CFF),
      ),
      TimelineEvent(
        title: 'Study Session',
        subtitle: 'AI & Data Structures Revision',
        time: _timeToday(19, 0),
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF4ADE80),
      ),
      TimelineEvent(
        title: 'Sleep Reminder',
        subtitle: "Prepare for tomorrow's classes",
        time: _timeToday(22, 30),
        icon: Icons.nightlight_round,
        color: const Color(0xFFFBBF24),
      ),
    ];

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: TimelineCard(
                  title: "Today's Schedule",
                  events: events,
                  onEventTap: (TimelineEvent event) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// lib/core/utils/logger.dart

// ---------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

// ---------------------------------------------------------------------
// LogCategory Enum
// ---------------------------------------------------------------------

/// The functional area a log entry belongs to, used to tag and filter
/// output across the app.
enum LogCategory {
  app,
  auth,
  timetable,
  attendance,
  todo,
  reminders,
  study,
  ai,
  network,
  database,
  overlay,
  analytics,
  notification,
  storage,
  health,
  settings,
}

extension LogCategoryX on LogCategory {
  String get label {
    switch (this) {
      case LogCategory.app:
        return 'APP';
      case LogCategory.auth:
        return 'AUTH';
      case LogCategory.timetable:
        return 'TIMETABLE';
      case LogCategory.attendance:
        return 'ATTENDANCE';
      case LogCategory.todo:
        return 'TODO';
      case LogCategory.reminders:
        return 'REMINDERS';
      case LogCategory.study:
        return 'STUDY';
      case LogCategory.ai:
        return 'AI';
      case LogCategory.network:
        return 'NETWORK';
      case LogCategory.database:
        return 'DATABASE';
      case LogCategory.overlay:
        return 'OVERLAY';
      case LogCategory.analytics:
        return 'ANALYTICS';
      case LogCategory.notification:
        return 'NOTIFICATION';
      case LogCategory.storage:
        return 'STORAGE';
      case LogCategory.health:
        return 'HEALTH';
      case LogCategory.settings:
        return 'SETTINGS';
    }
  }
}

// ---------------------------------------------------------------------
// AppLogger
// ---------------------------------------------------------------------

/// Centralized, structured logging for Student AI Companion.
///
/// Covers app lifecycle, authentication, timetable, attendance, todo,
/// reminders, AI chat, networking, database, overlay, and general
/// diagnostics — pretty and verbose in debug mode, minimal and safe in
/// release builds. Never throws, even if the underlying logger or JSON
/// encoding fails.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.warning : Level.trace,
  );

  // ---------------------------------------------------------------------
  // Generic Internal Logger
  // ---------------------------------------------------------------------

  static void _log(
    Level level,
    LogCategory category,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    try {
      final StringBuffer buffer = StringBuffer('[${category.label}] $message');

      if (data != null && data.isNotEmpty) {
        buffer.write('\n${prettyJson(data)}');
      }

      _logger.log(level, buffer.toString(), error: error, stackTrace: stackTrace);
    } catch (_) {
      // Logging must never crash the app.
    }
  }

  // ---------------------------------------------------------------------
  // Public Logging Methods
  // ---------------------------------------------------------------------

  static void trace(LogCategory category, String message, {Map<String, dynamic>? data}) {
    _log(Level.trace, category, message, data: data);
  }

  static void debug(LogCategory category, String message, {Map<String, dynamic>? data}) {
    _log(Level.debug, category, message, data: data);
  }

  static void info(LogCategory category, String message, {Map<String, dynamic>? data}) {
    _log(Level.info, category, message, data: data);
  }

  static void warning(LogCategory category, String message, {Map<String, dynamic>? data}) {
    _log(Level.warning, category, message, data: data);
  }

  static void error(
    LogCategory category,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(Level.error, category, message, error: error, stackTrace: stackTrace, data: data);
  }

  static void fatal(
    LogCategory category,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(Level.fatal, category, message, error: error, stackTrace: stackTrace, data: data);
  }

  // ---------------------------------------------------------------------
  // Feature Convenience Methods
  // ---------------------------------------------------------------------

  // -- Authentication ------------------------------------------------------

  static void authSignIn(String email) {
    info(LogCategory.auth, 'Signed in', data: <String, dynamic>{'email': email});
  }

  static void authSignOut() {
    info(LogCategory.auth, 'Signed out');
  }

  static void authFailure(String email, dynamic error) {
    AppLogger.error(
      LogCategory.auth,
      'Authentication failed',
      error: error,
      data: <String, dynamic>{'email': email},
    );
  }

  // -- Timetable -------------------------------------------------------------

  static void timetableAdded(String subject) {
    info(LogCategory.timetable, 'Timetable entry added', data: <String, dynamic>{'subject': subject});
  }

  static void timetableUpdated(String subject) {
    info(LogCategory.timetable, 'Timetable entry updated', data: <String, dynamic>{'subject': subject});
  }

  static void timetableDeleted(String subject) {
    info(LogCategory.timetable, 'Timetable entry deleted', data: <String, dynamic>{'subject': subject});
  }

  // -- Attendance --------------------------------------------------------------

  static void attendanceUpdated(String subject, double percentage) {
    info(
      LogCategory.attendance,
      'Attendance updated',
      data: <String, dynamic>{'subject': subject, 'percentage': percentage},
    );
  }

  // -- Todo ------------------------------------------------------------------

  static void taskCreated(String title) {
    info(LogCategory.todo, 'Task created', data: <String, dynamic>{'title': title});
  }

  static void taskCompleted(String title) {
    info(LogCategory.todo, 'Task completed', data: <String, dynamic>{'title': title});
  }

  static void taskDeleted(String title) {
    info(LogCategory.todo, 'Task deleted', data: <String, dynamic>{'title': title});
  }

  // -- AI ----------------------------------------------------------------------

  static void aiMessageSent(String preview) {
    info(
      LogCategory.ai,
      'Sending message to Nova AI',
      data: <String, dynamic>{'preview': truncate(preview, maxLength: 120)},
    );
  }

  static void aiResponseReceived(int length) {
    info(LogCategory.ai, 'Received Nova AI response', data: <String, dynamic>{'length': length});
  }

  static void aiFailure(dynamic error) {
    AppLogger.error(LogCategory.ai, 'Nova AI request failed', error: error);
  }

  // -- Network -------------------------------------------------------------------

  static void networkRequest(String method, String path) {
    debug(LogCategory.network, 'Request started', data: <String, dynamic>{'method': method, 'path': path});
  }

  static void networkResponse(int statusCode, String path) {
    info(
      LogCategory.network,
      'Response received',
      data: <String, dynamic>{'statusCode': statusCode, 'path': path},
    );
  }

  static void networkFailure(String path, dynamic error) {
    AppLogger.error(
      LogCategory.network,
      'Request failed',
      error: error,
      data: <String, dynamic>{'path': path},
    );
  }

  // -- Database ----------------------------------------------------------------

  static void databaseOpened(String database) {
    info(LogCategory.database, 'Database opened', data: <String, dynamic>{'database': database});
  }

  static void databaseWrite(String collection) {
    debug(LogCategory.database, 'Write', data: <String, dynamic>{'collection': collection});
  }

  static void databaseRead(String collection) {
    debug(LogCategory.database, 'Read', data: <String, dynamic>{'collection': collection});
  }

  static void databaseFailure(dynamic error) {
    AppLogger.error(LogCategory.database, 'Database operation failed', error: error);
  }

  // -- Overlay -------------------------------------------------------------------

  static void overlayOpened() {
    info(LogCategory.overlay, 'Floating AI orb opened');
  }

  static void overlayClosed() {
    info(LogCategory.overlay, 'Floating AI orb closed');
  }

  static void overlayVoiceTriggered() {
    info(LogCategory.overlay, 'Voice mode triggered from overlay');
  }

  // ---------------------------------------------------------------------
  // JSON Helpers
  // ---------------------------------------------------------------------

  /// Pretty-prints [value] as indented JSON. Falls back to
  /// `value.toString()` (or a generic placeholder) if encoding fails.
  static String prettyJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      try {
        return value.toString();
      } catch (_) {
        return '<unencodable value>';
      }
    }
  }

  // ---------------------------------------------------------------------
  // Text Truncation
  // ---------------------------------------------------------------------

  /// Truncates [text] to [maxLength] characters, appending
  /// "... (truncated)" when it was cut short. Useful for AI messages and
  /// API response previews.
  static String truncate(String text, {int maxLength = 300}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (truncated)';
  }
}

// ---------------------------------------------------------------------
// LogTimer
// ---------------------------------------------------------------------

/// A lightweight timer for measuring and logging the duration of an
/// operation, e.g.:
///
/// ```dart
/// final timer = LogTimer(LogCategory.network, 'Fetch timetable');
/// await fetchTimetable();
/// timer.stop();
/// ```
class LogTimer {
  LogTimer(this.category, this.operation) : _startedAt = DateTime.now();

  final LogCategory category;
  final String operation;
  final DateTime _startedAt;

  /// Logs an info message with the elapsed time since this timer was
  /// created, e.g. "[NETWORK] Fetch timetable completed in 142ms".
  void stop({Map<String, dynamic>? data}) {
    final int elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
    AppLogger.info(
      category,
      '$operation completed in ${elapsedMs}ms',
      data: data,
    );
  }
}

// ---------------------------------------------------------------------
// BuildLogger
// ---------------------------------------------------------------------

/// Wraps [child] and logs a trace message every time it rebuilds, in
/// debug mode only — useful for diagnosing unnecessary rebuilds.
class BuildLogger extends StatelessWidget {
  const BuildLogger({super.key, required this.name, required this.child});

  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      AppLogger.trace(LogCategory.app, 'Rebuilt: $name');
    }
    return child;
  }
}

// ---------------------------------------------------------------------
// LoggerDemoScreen
// ---------------------------------------------------------------------

/// A preview dashboard exercising [AppLogger] on a dark futuristic
/// background.
class LoggerDemoScreen extends StatefulWidget {
  const LoggerDemoScreen({super.key});

  @override
  State<LoggerDemoScreen> createState() => _LoggerDemoScreenState();
}

class _LoggerDemoScreenState extends State<LoggerDemoScreen> {
  String _lastAction = 'No actions logged yet — check the debug console too.';

  void _run(String label, VoidCallback action) {
    action();
    setState(() => _lastAction = label);
  }

  Future<void> _runPerformanceTest() async {
    final LogTimer timer = LogTimer(LogCategory.network, 'Simulated fetch');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    timer.stop(data: <String, dynamic>{'simulated': true});
    if (!mounted) return;
    setState(() => _lastAction = 'Performance test logged (~500ms)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B1020), Color(0xFF121A2F)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Nova AI Logging System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Centralized structured logging for networking, AI '
                  'conversations, timetable operations, attendance '
                  'tracking, reminders, database actions, overlay events, '
                  'and production diagnostics.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildConsoleCard(),
                const SizedBox(height: 24),
                _buildSection('Generic Logs', <Widget>[
                  _button('Trace', () => AppLogger.trace(LogCategory.app, 'Trace log example')),
                  _button('Debug', () => AppLogger.debug(LogCategory.app, 'Debug log example')),
                  _button('Info', () => AppLogger.info(LogCategory.app, 'Info log example')),
                  _button('Warning', () => AppLogger.warning(LogCategory.app, 'Warning log example')),
                  _button('Error', () => AppLogger.error(LogCategory.app, 'Error log example', error: 'demo error')),
                  _button('Fatal', () => AppLogger.fatal(LogCategory.app, 'Fatal log example', error: 'demo fatal')),
                ]),
                _buildSection('Feature Logs', <Widget>[
                  _button('Simulate Sign In', () => AppLogger.authSignIn('student@college.edu')),
                  _button('Add Timetable Entry', () => AppLogger.timetableAdded('Digital Electronics')),
                  _button('Complete Task', () => AppLogger.taskCompleted('Finish DBMS assignment')),
                  _button('Send AI Message', () {
                    AppLogger.aiMessageSent("Remind me about tomorrow's lab");
                    AppLogger.aiResponseReceived(128);
                  }),
                  _button('Trigger Network Error', () => AppLogger.networkFailure('/chat/completions', 'Connection timed out')),
                  _button('Trigger Database Error', () => AppLogger.databaseFailure('Isar write failed')),
                  _button('Open Overlay', AppLogger.overlayOpened),
                ]),
                _buildSection('Performance Test', <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _lastAction = 'Running performance test…');
                      _runPerformanceTest();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Run 500ms Timer Test', style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Last Action',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lastAction,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: buttons),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: () => _run(label, onPressed),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}


// lib/core/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Central notification manager for Student AI Companion.
///
/// Handles instant notifications, scheduled reminders, daily repeating
/// reminders, AI companion messages, timetable reminders, attendance
/// warnings, study session reminders, and wellness (water/sleep)
/// reminders. Every message is written to feel human, friendly, and
/// encouraging rather than robotic.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------------------
  // Channel identifiers
  // ---------------------------------------------------------------------

  static const String _reminderChannelId = 'student_reminders';
  static const String _reminderChannelName = 'Student Reminders';
  static const String _reminderChannelDescription =
      'Class, assignment, exam, and study reminders';

  static const String _aiChannelId = 'ai_companion';
  static const String _aiChannelName = 'AI Companion';
  static const String _aiChannelDescription =
      'Personalized messages from Nova AI';

  static const String _wellnessChannelId = 'wellness_reminders';
  static const String _wellnessChannelName = 'Wellness Reminders';
  static const String _wellnessChannelDescription =
      'Water, sleep, and health reminders';

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Initializes the timezone database, configures platform notification
  /// settings, and registers all Android notification channels. Must be
  /// called once before any other method on this service.
  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(initSettings);
      await _createNotificationChannels();
    } catch (error) {
      debugPrint('NotificationService.initialize failed: $error');
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        _reminderChannelName,
        description: _reminderChannelDescription,
        importance: Importance.max,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _aiChannelId,
        _aiChannelName,
        description: _aiChannelDescription,
        importance: Importance.max,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _wellnessChannelId,
        _wellnessChannelName,
        description: _wellnessChannelDescription,
        importance: Importance.max,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Instant Notifications
  // ---------------------------------------------------------------------

  /// Shows an instant "Student Reminders" notification.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(id, title, body, _reminderDetails());
    } catch (error) {
      debugPrint('NotificationService.showInstantNotification failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Scheduled Notifications
  // ---------------------------------------------------------------------

  /// Schedules a one-off "Student Reminders" notification at
  /// [scheduledAt], converted into the local timezone.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    try {
      final tz.TZDateTime scheduled = tz.TZDateTime.from(scheduledAt, tz.local);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('NotificationService.scheduleNotification failed: $error');
    }
  }

  /// Schedules a "Student Reminders" notification that repeats every day
  /// at [time]. If [time] has already passed today, the first occurrence
  /// is automatically scheduled for tomorrow.
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      final tz.TZDateTime scheduled = _nextInstanceOfTime(time);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (error) {
      debugPrint('NotificationService.scheduleDailyReminder failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // AI Companion Notifications
  // ---------------------------------------------------------------------

  /// Shows an instant AI companion message from "Nova AI ðŸ’™" on the
  /// dedicated AI companion channel. Example bodies:
  /// - "Don't forget tomorrow's DBMS lab ðŸ‘‹"
  /// - "You've been studying consistently today. Great job âœ¨"
  /// - "Take a short break and drink some water ðŸ’§"
  /// - "Sleep early. Tomorrow's classes are important ðŸŒ™"
  Future<void> showAiMessage({required String body}) async {
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Nova AI ðŸ’™',
        body,
        _aiDetails(),
      );
    } catch (error) {
      debugPrint('NotificationService.showAiMessage failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Timetable Helpers
  // ---------------------------------------------------------------------

  /// Schedules an evening "night-before" reminder for tomorrow's class,
  /// e.g. "Tomorrow you have Digital Electronics at 8:30 AM. Room 302 â€¢
  /// Keep your notebook and ID card ready ðŸ“š".
  Future<void> scheduleTomorrowClassReminder({
    required String subject,
    required TimeOfDay classTime,
    String? room,
  }) async {
    try {
      final String formattedTime = _formatTimeOfDay(classTime);
      final StringBuffer body = StringBuffer(
        'Tomorrow you have $subject at $formattedTime.',
      );

      if (room != null && room.trim().isNotEmpty) {
        body.write('\n\n$room â€¢ Keep your notebook and ID card ready ðŸ“š');
      } else {
        body.write('\n\nKeep your notebook and ID card ready ðŸ“š');
      }

      // The night-before nudge fires at 8:00 PM, either tonight or
      // tomorrow evening if that time has already passed today.
      final tz.TZDateTime scheduled =
          _nextInstanceOfTime(const TimeOfDay(hour: 20, minute: 0));

      await _plugin.zonedSchedule(
        subject.hashCode.remainder(100000),
        'Class Reminder ðŸ“š',
        body.toString(),
        scheduled,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint(
        'NotificationService.scheduleTomorrowClassReminder failed: $error',
      );
    }
  }

  /// Schedules a one-off study session reminder at [time], e.g.
  /// "It's time for your study session ðŸ“– / Topic: Data Structures
  /// Revision / Small focused sessions create big results."
  Future<void> scheduleStudyReminder({
    required DateTime time,
    String? topic,
  }) async {
    try {
      final StringBuffer body = StringBuffer("It's time for your study session ðŸ“–");

      if (topic != null && topic.trim().isNotEmpty) {
        body.write('\n\nTopic: $topic');
      }

      body.write('\n\nSmall focused sessions create big results.');

      final tz.TZDateTime scheduled = tz.TZDateTime.from(time, tz.local);

      await _plugin.zonedSchedule(
        time.hashCode.remainder(100000),
        'Study Time ðŸ“–',
        body.toString(),
        scheduled,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('NotificationService.scheduleStudyReminder failed: $error');
    }
  }

  /// Shows an attendance warning, e.g. "Your attendance is 78%. / Try
  /// not to miss tomorrow's classes so we can stay above the safe limit
  /// ðŸ“Š".
  Future<void> showAttendanceWarning({required double percentage}) async {
    try {
      final String rounded = percentage.round().toString();
      final String body =
          'Your attendance is $rounded%.\n\nTry not to miss tomorrow\'s '
          'classes so we can stay above the safe limit ðŸ“Š';

      await _plugin.show(
        'attendance_warning'.hashCode.remainder(100000),
        'Attendance Check-In',
        body,
        _reminderDetails(),
      );
    } catch (error) {
      debugPrint('NotificationService.showAttendanceWarning failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Wellness Helpers
  // ---------------------------------------------------------------------

  /// Schedules a daily water reminder at [time] on the Wellness channel.
  Future<void> scheduleWaterReminder({required TimeOfDay time}) async {
    try {
      final tz.TZDateTime scheduled = _nextInstanceOfTime(time);

      await _plugin.zonedSchedule(
        'water_reminder'.hashCode.remainder(100000),
        'Hydration Check ðŸ’§',
        'Take a short break and drink some water ðŸ’§',
        scheduled,
        _wellnessDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (error) {
      debugPrint('NotificationService.scheduleWaterReminder failed: $error');
    }
  }

  /// Schedules a daily sleep reminder at [time] on the Wellness channel.
  Future<void> scheduleSleepReminder({required TimeOfDay time}) async {
    try {
      final tz.TZDateTime scheduled = _nextInstanceOfTime(time);

      await _plugin.zonedSchedule(
        'sleep_reminder'.hashCode.remainder(100000),
        'Good Night ðŸŒ™',
        "Sleep early. Tomorrow's classes are important ðŸŒ™",
        scheduled,
        _wellnessDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (error) {
      debugPrint('NotificationService.scheduleSleepReminder failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------

  /// Cancels a single scheduled or displayed notification by [id].
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (error) {
      debugPrint('NotificationService.cancel failed: $error');
    }
  }

  /// Cancels every scheduled and displayed notification.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('NotificationService.cancelAll failed: $error');
    }
  }

  NotificationDetails _reminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  NotificationDetails _aiDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _aiChannelId,
        _aiChannelName,
        channelDescription: _aiChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  NotificationDetails _wellnessDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _wellnessChannelId,
        _wellnessChannelName,
        channelDescription: _wellnessChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  /// Computes the next occurrence of [time] in the local timezone. If
  /// that time has already passed today, returns the same time tomorrow.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Formats a [TimeOfDay] as a 12-hour clock string (e.g. "08:30 AM"),
  /// without relying on any external formatting package.
  String _formatTimeOfDay(TimeOfDay time) {
    final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen exercising every [NotificationService] method on a
/// dark futuristic background.
class NotificationServiceDemo extends StatelessWidget {
  const NotificationServiceDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService service = NotificationService.instance;

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
                  'Notification Service Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Human-friendly reminders make the AI companion feel '
                  "caring, helpful, and always present in the student's "
                  'daily life.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: service.initialize,
                      child: const Text('Initialize Service'),
                    ),
                    ElevatedButton(
                      onPressed: () => service.showInstantNotification(
                        id: 1,
                        title: 'Student Reminder',
                        body: 'Your DBMS assignment is due tomorrow.',
                      ),
                      child: const Text('Show Instant Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => service.showAiMessage(
                        body:
                            "You've been studying consistently today. Great job âœ¨",
                      ),
                      child: const Text('Show AI Message'),
                    ),
                    ElevatedButton(
                      onPressed: () => service.scheduleNotification(
                        id: 2,
                        title: 'Quick Reminder',
                        body: 'This notification was scheduled 10 seconds ago.',
                        scheduledAt:
                            DateTime.now().add(const Duration(seconds: 10)),
                      ),
                      child: const Text('Schedule 10-Second Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => service.scheduleWaterReminder(
                        time: const TimeOfDay(hour: 16, minute: 0),
                      ),
                      child: const Text('Schedule Water Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => service.scheduleSleepReminder(
                        time: const TimeOfDay(hour: 22, minute: 30),
                      ),
                      child: const Text('Schedule Sleep Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => service.showAttendanceWarning(
                        percentage: 78,
                      ),
                      child: const Text('Show Attendance Warning'),
                    ),
                    ElevatedButton(
                      onPressed: service.cancelAll,
                      child: const Text('Cancel All Notifications'),
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


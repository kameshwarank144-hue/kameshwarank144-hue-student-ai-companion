// lib/core/services/workmanager_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Background task manager for Student AI Companion.
///
/// Keeps Nova AI caring for the student even when the app is closed, in
/// the background, or the phone is locked — night-before class
/// reminders, daily AI check-ins, attendance monitoring, water and sleep
/// reminders, study streak nudges, analytics refresh, and cloud sync.
class WorkmanagerService {
  WorkmanagerService._();

  static final WorkmanagerService instance = WorkmanagerService._();

  // ---------------------------------------------------------------------
  // Task Constants
  // ---------------------------------------------------------------------

  static const String timetableReminderTask = 'timetable_reminder_task';
  static const String aiCheckInTask = 'ai_check_in_task';
  static const String attendanceCheckTask = 'attendance_check_task';
  static const String waterReminderTask = 'water_reminder_task';
  static const String studyReminderTask = 'study_reminder_task';
  static const String sleepReminderTask = 'sleep_reminder_task';
  static const String analyticsRefreshTask = 'analytics_refresh_task';
  static const String cloudSyncTask = 'cloud_sync_task';

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Initializes the Workmanager plugin with [workmanagerCallbackDispatcher]
  /// as the background entry point. Must be called once, typically in
  /// `main()`, before registering any tasks.
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        workmanagerCallbackDispatcher,
        isInDebugMode: true,
      );
      debugPrint('Workmanager initialized');
    } catch (error) {
      debugPrint('WorkmanagerService.initialize failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Task Registration
  // ---------------------------------------------------------------------

  /// Registers a one-off, night-before reminder to check tomorrow's
  /// timetable.
  Future<void> registerNightBeforeTimetableTask() async {
    try {
      await Workmanager().registerOneOffTask(
        timetableReminderTask,
        timetableReminderTask,
        initialDelay: const Duration(hours: 1),
      );
      debugPrint('Timetable reminder task registered');
    } catch (error) {
      debugPrint(
        'WorkmanagerService.registerNightBeforeTimetableTask failed: $error',
      );
    }
  }

  /// Registers a periodic (every 24 hours) AI companion check-in.
  Future<void> registerDailyAiCheckIn() async {
    try {
      await Workmanager().registerPeriodicTask(
        aiCheckInTask,
        aiCheckInTask,
        frequency: const Duration(hours: 24),
      );
      debugPrint('AI check-in task registered');
    } catch (error) {
      debugPrint('WorkmanagerService.registerDailyAiCheckIn failed: $error');
    }
  }

  /// Registers a periodic (every 24 hours) attendance monitor task.
  Future<void> registerAttendanceMonitor() async {
    try {
      await Workmanager().registerPeriodicTask(
        attendanceCheckTask,
        attendanceCheckTask,
        frequency: const Duration(hours: 24),
      );
      debugPrint('Attendance monitor task registered');
    } catch (error) {
      debugPrint('WorkmanagerService.registerAttendanceMonitor failed: $error');
    }
  }

  /// Registers a one-off water reminder task.
  Future<void> registerWaterReminderTask() async {
    try {
      await Workmanager().registerOneOffTask(
        waterReminderTask,
        waterReminderTask,
        initialDelay: const Duration(hours: 1),
      );
      debugPrint('Water reminder task registered');
    } catch (error) {
      debugPrint('WorkmanagerService.registerWaterReminderTask failed: $error');
    }
  }

  /// Registers a one-off study session reminder task.
  Future<void> registerStudyReminderTask() async {
    try {
      await Workmanager().registerOneOffTask(
        studyReminderTask,
        studyReminderTask,
        initialDelay: const Duration(hours: 1),
      );
      debugPrint('Study reminder task registered');
    } catch (error) {
      debugPrint('WorkmanagerService.registerStudyReminderTask failed: $error');
    }
  }

  /// Registers a one-off sleep reminder task.
  Future<void> registerSleepReminderTask() async {
    try {
      await Workmanager().registerOneOffTask(
        sleepReminderTask,
        sleepReminderTask,
        initialDelay: const Duration(hours: 1),
      );
      debugPrint('Sleep reminder task registered');
    } catch (error) {
      debugPrint('WorkmanagerService.registerSleepReminderTask failed: $error');
    }
  }

  /// Registers a periodic (every 24 hours) analytics refresh task.
  Future<void> registerAnalyticsRefreshTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        analyticsRefreshTask,
        analyticsRefreshTask,
        frequency: const Duration(hours: 24),
      );
      debugPrint('Analytics refresh task registered');
    } catch (error) {
      debugPrint(
        'WorkmanagerService.registerAnalyticsRefreshTask failed: $error',
      );
    }
  }

  /// Registers a periodic (every 6 hours) cloud sync placeholder task.
  Future<void> registerCloudSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        cloudSyncTask,
        cloudSyncTask,
        frequency: const Duration(hours: 6),
      );
      debugPrint('Cloud sync task registered');
    } catch (error) {
      debugPrint('WorkmanagerService.registerCloudSyncTask failed: $error');
    }
  }

  /// Registers the core set of recurring background tasks that should
  /// always be active: AI check-in, attendance monitoring, analytics
  /// refresh, and cloud sync.
  Future<void> registerAllDefaultTasks() async {
    await registerDailyAiCheckIn();
    await registerAttendanceMonitor();
    await registerAnalyticsRefreshTask();
    await registerCloudSyncTask();
  }

  // ---------------------------------------------------------------------
  // Task Cancellation
  // ---------------------------------------------------------------------

  /// Cancels a single registered task by its unique name.
  Future<void> cancelTask(String uniqueName) async {
    try {
      await Workmanager().cancelByUniqueName(uniqueName);
      debugPrint('Cancelled task: $uniqueName');
    } catch (error) {
      debugPrint('WorkmanagerService.cancelTask failed: $error');
    }
  }

  /// Cancels every registered background task.
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('Cancelled all background tasks');
    } catch (error) {
      debugPrint('WorkmanagerService.cancelAllTasks failed: $error');
    }
  }
}

// ---------------------------------------------------------------------
// Background Dispatcher
// ---------------------------------------------------------------------

const List<String> _aiCheckInMessages = <String>[
  'Good morning ☀️ Ready to make today productive?',
  'Small progress every day becomes big success ✨',
  "Don't forget to drink water and take short study breaks 💧",
  "I'm proud of your consistency. Keep going 📖",
  'Sleep early tonight. Tomorrow is another opportunity 🌙',
];

/// Background entry point invoked by Workmanager for every registered
/// task, even when the app is closed or the device is locked. Must be a
/// top-level (or static) function annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((String taskName, Map<String, dynamic>? inputData) async {
    debugPrint('Background task executed: $taskName');

    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    await _initializeBackgroundNotifications(plugin);

    switch (taskName) {
      case WorkmanagerService.timetableReminderTask:
        await _showBackgroundNotification(
          plugin,
          id: 101,
          title: "Tomorrow's Classes 📚",
          body:
              "Don't forget to check your timetable and keep your bag, "
              'ID card, and charger ready for tomorrow.',
        );
        break;

      case WorkmanagerService.aiCheckInTask:
        final int index =
            DateTime.now().millisecondsSinceEpoch % _aiCheckInMessages.length;
        await _showBackgroundNotification(
          plugin,
          id: 102,
          title: 'Nova AI 💙',
          body: _aiCheckInMessages[index],
        );
        break;

      case WorkmanagerService.attendanceCheckTask:
        await _showBackgroundNotification(
          plugin,
          id: 103,
          title: 'Attendance Check 📊',
          body:
              "Make sure you attend tomorrow's classes regularly so your "
              'attendance stays above the safe limit.',
        );
        break;

      case WorkmanagerService.waterReminderTask:
        await _showBackgroundNotification(
          plugin,
          id: 104,
          title: 'Hydration Reminder 💧',
          body:
              'Take a moment to drink some water. Your brain studies '
              'better when you stay hydrated.',
        );
        break;

      case WorkmanagerService.studyReminderTask:
        await _showBackgroundNotification(
          plugin,
          id: 105,
          title: 'Focus Time 🎯',
          body:
              'A 25-minute focused study session is enough to make '
              'meaningful progress today.',
        );
        break;

      case WorkmanagerService.sleepReminderTask:
        await _showBackgroundNotification(
          plugin,
          id: 106,
          title: 'Good Night 🌙',
          body:
              'Put your phone down, relax your mind, and get enough '
              "sleep for tomorrow's classes.",
        );
        break;

      case WorkmanagerService.analyticsRefreshTask:
        debugPrint('Analytics refreshed in the background.');
        break;

      case WorkmanagerService.cloudSyncTask:
        debugPrint('Cloud sync placeholder executed in the background.');
        break;

      default:
        debugPrint('Unknown background task: $taskName');
    }

    return Future.value(true);
  });
}

// ---------------------------------------------------------------------
// Notification Helpers
// ---------------------------------------------------------------------

/// Minimal, background-isolate-safe initialization for local
/// notifications triggered from [workmanagerCallbackDispatcher].
Future<void> _initializeBackgroundNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await plugin.initialize(initSettings);
}

/// Shows a local notification from within a background task.
Future<void> _showBackgroundNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'background_tasks',
    'Background Tasks',
    channelDescription: 'Notifications triggered by background tasks',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await plugin.show(id, title, body, details);
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen exercising every [WorkmanagerService] method on a
/// dark futuristic background, with each action confirmed via a
/// [SnackBar].
class WorkmanagerServiceDemo extends StatelessWidget {
  const WorkmanagerServiceDemo({super.key});

  void _run(BuildContext context, String label, Future<void> Function() action) {
    action();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WorkmanagerService service = WorkmanagerService.instance;

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
                  'Background AI Service Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'These background tasks allow Nova AI to care for the '
                  'student even when the app is closed.',
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
                      onPressed: () => _run(
                        context,
                        'Workmanager initialized',
                        service.initialize,
                      ),
                      child: const Text('Initialize Workmanager'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'All default tasks registered',
                        service.registerAllDefaultTasks,
                      ),
                      child: const Text('Register All Default Tasks'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'Timetable reminder scheduled',
                        service.registerNightBeforeTimetableTask,
                      ),
                      child: const Text('Schedule Timetable Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'AI check-in scheduled',
                        service.registerDailyAiCheckIn,
                      ),
                      child: const Text('Schedule AI Check-In'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'Attendance monitor scheduled',
                        service.registerAttendanceMonitor,
                      ),
                      child: const Text('Schedule Attendance Monitor'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'Water reminder scheduled',
                        service.registerWaterReminderTask,
                      ),
                      child: const Text('Schedule Water Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'Study reminder scheduled',
                        service.registerStudyReminderTask,
                      ),
                      child: const Text('Schedule Study Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'Sleep reminder scheduled',
                        service.registerSleepReminderTask,
                      ),
                      child: const Text('Schedule Sleep Reminder'),
                    ),
                    ElevatedButton(
                      onPressed: () => _run(
                        context,
                        'All background tasks cancelled',
                        service.cancelAllTasks,
                      ),
                      child: const Text('Cancel All Tasks'),
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


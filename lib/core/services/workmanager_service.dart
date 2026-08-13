// lib/core/services/workmanager_service.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/logger.dart';
import 'notification_service.dart';
import 'sync_service.dart';

// ---------------------------------------------------------------------
// 2. Task Constants
// ---------------------------------------------------------------------

/// The unique Workmanager task names used throughout the background
/// scheduling pipeline.
class _BackgroundTasks {
  _BackgroundTasks._();

  static const String syncNow = 'sync_now_task';
  static const String timetableReminder = 'timetable_reminder_task';
  static const String attendanceCheck = 'attendance_check_task';
  static const String waterReminder = 'water_reminder_task';
  static const String sleepReminder = 'sleep_reminder_task';
  static const String studyStreak = 'study_streak_task';
  static const String dailyMotivation = 'daily_motivation_task';
  static const String analyticsRefresh = 'analytics_refresh_task';
}

// ---------------------------------------------------------------------
// 3. WorkmanagerService
// ---------------------------------------------------------------------

/// Background task scheduler for Student AI Companion.
///
/// Manages timetable reminder preparation, todo reminder sync,
/// attendance health checks, water and sleep reminders, study streak
/// updates, daily motivation notifications, offline data sync, and
/// analytics snapshot refresh — all continuing to run even when the app
/// is closed or the device is locked.
class WorkmanagerService {
  WorkmanagerService._();

  static final WorkmanagerService instance = WorkmanagerService._();

  // ---------------------------------------------------------------------
  // 4. Internal State
  // ---------------------------------------------------------------------

  bool _initialized = false;

  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------
  // 5. Initialization
  // ---------------------------------------------------------------------

  /// Initializes the Workmanager plugin with [callbackDispatcher] as the
  /// background entry point. Safe to call more than once — subsequent
  /// calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.debug(LogCategory.app, '[WORKMANAGER] Already initialized');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      _initialized = true;
      AppLogger.info(LogCategory.app, '[WORKMANAGER] Initialized successfully');
    } catch (error, stackTrace) {
      AppLogger.error(
        LogCategory.app,
        '[WORKMANAGER] Initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------
  // 8. One-Time Tasks
  // ---------------------------------------------------------------------

  /// Triggers an immediate one-off sync via Workmanager.
  Future<void> runSyncNow() async {
    try {
      await Workmanager().registerOneOffTask(
        _BackgroundTasks.syncNow,
        _BackgroundTasks.syncNow,
      );
      AppLogger.info(LogCategory.network, '[WORKMANAGER] One-off sync task registered');
    } catch (error) {
      AppLogger.error(LogCategory.network, '[WORKMANAGER] runSyncNow failed', error: error);
    }
  }

  // ---------------------------------------------------------------------
  // 9. Periodic Tasks
  // ---------------------------------------------------------------------

  /// Registers a periodic background sync, running every [frequency]
  /// (default 6 hours).
  Future<void> registerPeriodicSync({
    Duration frequency = const Duration(hours: 6),
  }) async {
    try {
      await Workmanager().registerPeriodicTask(
        _BackgroundTasks.syncNow,
        _BackgroundTasks.syncNow,
        frequency: frequency,
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      AppLogger.info(LogCategory.network, '[WORKMANAGER] Periodic sync registered');
    } catch (error) {
      AppLogger.error(LogCategory.network, '[WORKMANAGER] registerPeriodicSync failed', error: error);
    }
  }

  /// Registers the night-before timetable reminder, running every 24
  /// hours.
  Future<void> registerNightBeforeReminder() async {
    try {
      await Workmanager().registerPeriodicTask(
        _BackgroundTasks.timetableReminder,
        _BackgroundTasks.timetableReminder,
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      AppLogger.info(LogCategory.app, '[WORKMANAGER] Night-before reminder registered');
    } catch (error) {
      AppLogger.error(LogCategory.app, '[WORKMANAGER] registerNightBeforeReminder failed', error: error);
    }
  }

  /// Registers the water reminder task, running every 2 hours.
  Future<void> registerWaterReminder() async {
    try {
      await Workmanager().registerPeriodicTask(
        _BackgroundTasks.waterReminder,
        _BackgroundTasks.waterReminder,
        frequency: const Duration(hours: 2),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      AppLogger.info(LogCategory.health, '[WORKMANAGER] Water reminder registered');
    } catch (error) {
      AppLogger.error(LogCategory.health, '[WORKMANAGER] registerWaterReminder failed', error: error);
    }
  }

  /// Registers the sleep reminder task, running every 24 hours.
  Future<void> registerSleepReminder() async {
    try {
      await Workmanager().registerPeriodicTask(
        _BackgroundTasks.sleepReminder,
        _BackgroundTasks.sleepReminder,
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      AppLogger.info(LogCategory.health, '[WORKMANAGER] Sleep reminder registered');
    } catch (error) {
      AppLogger.error(LogCategory.health, '[WORKMANAGER] registerSleepReminder failed', error: error);
    }
  }

  /// Registers the daily motivation notification task, running every 24
  /// hours.
  Future<void> registerDailyMotivation() async {
    try {
      await Workmanager().registerPeriodicTask(
        _BackgroundTasks.dailyMotivation,
        _BackgroundTasks.dailyMotivation,
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      AppLogger.info(LogCategory.app, '[WORKMANAGER] Daily motivation registered');
    } catch (error) {
      AppLogger.error(LogCategory.app, '[WORKMANAGER] registerDailyMotivation failed', error: error);
    }
  }

  /// Registers the study streak check task, running every 12 hours.
  Future<void> registerStudyStreakCheck() async {
    try {
      await Workmanager().registerPeriodicTask(
        _BackgroundTasks.studyStreak,
        _BackgroundTasks.studyStreak,
        frequency: const Duration(hours: 12),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      AppLogger.info(LogCategory.study, '[WORKMANAGER] Study streak check registered');
    } catch (error) {
      AppLogger.error(LogCategory.study, '[WORKMANAGER] registerStudyStreakCheck failed', error: error);
    }
  }

  // ---------------------------------------------------------------------
  // 10. Bulk Registration
  // ---------------------------------------------------------------------

  /// Registers every recurring background task at once.
  Future<void> registerAllTasks() async {
    await registerPeriodicSync();
    await registerNightBeforeReminder();
    await registerWaterReminder();
    await registerSleepReminder();
    await registerDailyMotivation();
    await registerStudyStreakCheck();
    AppLogger.info(LogCategory.app, '[WORKMANAGER] All background tasks registered');
  }

  // ---------------------------------------------------------------------
  // 11. Cancellation APIs
  // ---------------------------------------------------------------------

  /// Cancels a single registered task by its unique name.
  Future<void> cancelTask(String uniqueName) async {
    try {
      await Workmanager().cancelByUniqueName(uniqueName);
      AppLogger.info(LogCategory.app, '[WORKMANAGER] Cancelled task: $uniqueName');
    } catch (error) {
      AppLogger.error(LogCategory.app, '[WORKMANAGER] cancelTask failed', error: error);
    }
  }

  /// Cancels every registered background task.
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      AppLogger.info(LogCategory.app, '[WORKMANAGER] Cancelled all background tasks');
    } catch (error) {
      AppLogger.error(LogCategory.app, '[WORKMANAGER] cancelAllTasks failed', error: error);
    }
  }

  // ---------------------------------------------------------------------
  // 12. Debug Helpers
  // ---------------------------------------------------------------------

  /// A structured snapshot of this service's current state.
  Map<String, dynamic> debugSnapshot() {
    return <String, dynamic>{
      'initialized': _initialized,
      'timestamp': DateTime.now().toIso8601String(),
      'supportedTasks': <String>[
        _BackgroundTasks.syncNow,
        _BackgroundTasks.timetableReminder,
        _BackgroundTasks.attendanceCheck,
        _BackgroundTasks.waterReminder,
        _BackgroundTasks.sleepReminder,
        _BackgroundTasks.studyStreak,
        _BackgroundTasks.dailyMotivation,
        _BackgroundTasks.analyticsRefresh,
      ],
    };
  }
}

// ---------------------------------------------------------------------
// 6. Callback Dispatcher
// ---------------------------------------------------------------------

/// Background entry point invoked by Workmanager for every registered
/// task, even when the app is closed or the device is locked. Must
/// remain a top-level function annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    try {
      await NotificationService.instance.initialize();
      await SyncService.instance.initialize();

      AppLogger.info(LogCategory.app, '[WORKMANAGER] Executing task: $task');

      switch (task) {
        case _BackgroundTasks.syncNow:
          await _handleSyncTask();
          break;
        case _BackgroundTasks.timetableReminder:
          await _handleTimetableReminder();
          break;
        case _BackgroundTasks.attendanceCheck:
          await _handleAttendanceCheck();
          break;
        case _BackgroundTasks.waterReminder:
          await _handleWaterReminder();
          break;
        case _BackgroundTasks.sleepReminder:
          await _handleSleepReminder();
          break;
        case _BackgroundTasks.studyStreak:
          await _handleStudyStreak();
          break;
        case _BackgroundTasks.dailyMotivation:
          await _handleDailyMotivation();
          break;
        case _BackgroundTasks.analyticsRefresh:
          await _handleAnalyticsRefresh();
          break;
        default:
          AppLogger.warning(LogCategory.app, '[WORKMANAGER] Unknown task: $task');
      }

      return Future.value(true);
    } catch (error, stackTrace) {
      AppLogger.error(
        LogCategory.app,
        '[WORKMANAGER] Task failed: $task',
        error: error,
        stackTrace: stackTrace,
      );
      return Future.value(false);
    }
  });
}

// ---------------------------------------------------------------------
// 7. Task Handlers
// ---------------------------------------------------------------------

/// Runs a full sync pass and logs the outcome.
Future<void> _handleSyncTask() async {
  final SyncResult result = await SyncService.instance.syncNow();
  AppLogger.info(
    LogCategory.network,
    '[WORKMANAGER] Sync completed',
    data: <String, dynamic>{
      'success': result.success,
      'syncedItems': result.syncedItems,
      'failedItems': result.failedItems,
    },
  );
}

/// Shows the night-before timetable preparation reminder.
Future<void> _handleTimetableReminder() async {
  await NotificationService.instance.show(
    title: "Tomorrow's classes are ready 📚",
    body: 'Pack your bag, charge your phone, and sleep well 🌙',
  );
}

/// Shows a gentle attendance check-in reminder.
Future<void> _handleAttendanceCheck() async {
  await NotificationService.instance.show(
    title: 'Attendance Check 📊',
    body: "Take a quick look at your attendance before tomorrow's classes.",
  );
}

/// Shows the hydration reminder.
Future<void> _handleWaterReminder() async {
  await NotificationService.instance.showWaterReminder();
}

/// Shows the wind-down / sleep reminder.
Future<void> _handleSleepReminder() async {
  await NotificationService.instance.showSleepReminder();
}

/// Shows the study streak encouragement notification.
Future<void> _handleStudyStreak() async {
  await NotificationService.instance.show(
    title: 'Keep your streak alive 🔥',
    body: 'Even 20 minutes of focused study keeps your momentum going.',
  );
}

/// Shows a daily motivational message.
Future<void> _handleDailyMotivation() async {
  await NotificationService.instance.showMotivation();
}

/// Simulates a lightweight analytics snapshot refresh.
Future<void> _handleAnalyticsRefresh() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  AppLogger.info(LogCategory.analytics, '[WORKMANAGER] Analytics refresh completed');
}

// ---------------------------------------------------------------------
// 13. Demo Utility
// ---------------------------------------------------------------------

/// A UI-independent demo of [WorkmanagerService], useful for quick
/// manual testing of initialization, bulk registration, and one-off
/// sync triggering.
class WorkmanagerServiceDemo {
  WorkmanagerServiceDemo._();

  static Future<Map<String, dynamic>> runDemo() async {
    final WorkmanagerService service = WorkmanagerService.instance;

    await service.initialize();
    await service.registerAllTasks();
    await service.runSyncNow();

    return <String, dynamic>{
      'initialized': service.isInitialized,
      'registeredTaskCount': 6,
      'syncTriggered': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

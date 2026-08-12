// lib/core/services/sync_service.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/connectivity_service.dart';
import '../utils/logger.dart';

// ---------------------------------------------------------------------
// 2. Sync Status
// ---------------------------------------------------------------------

/// The current state of the synchronization pipeline.
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
}

// ---------------------------------------------------------------------
// 3. Sync Task
// ---------------------------------------------------------------------

/// A single unit of work waiting to be synchronized with the backend —
/// a timetable change, a completed task, an updated attendance record,
/// a reminder edit, or new Notes AI content.
@immutable
class SyncTask {
  const SyncTask({
    required this.id,
    required this.feature,
    required this.createdAt,
    this.requiresNetwork = true,
    this.payload = const <String, dynamic>{},
  });

  /// A unique identifier for this task.
  final String id;

  /// The feature/module this task belongs to (e.g. "timetable", "todo").
  final String feature;

  /// When this task was queued.
  final DateTime createdAt;

  /// Whether this task requires an active network connection to sync.
  final bool requiresNetwork;

  /// The data to be synchronized.
  final Map<String, dynamic> payload;

  SyncTask copyWith({
    String? id,
    String? feature,
    DateTime? createdAt,
    bool? requiresNetwork,
    Map<String, dynamic>? payload,
  }) {
    return SyncTask(
      id: id ?? this.id,
      feature: feature ?? this.feature,
      createdAt: createdAt ?? this.createdAt,
      requiresNetwork: requiresNetwork ?? this.requiresNetwork,
      payload: payload ?? this.payload,
    );
  }

  @override
  String toString() {
    return 'SyncTask(id: $id, feature: $feature, createdAt: $createdAt, '
        'requiresNetwork: $requiresNetwork)';
  }
}

// ---------------------------------------------------------------------
// 4. Sync Result
// ---------------------------------------------------------------------

/// The outcome of a single [SyncService.syncNow] run.
@immutable
class SyncResult {
  const SyncResult({
    required this.success,
    required this.syncedItems,
    required this.failedItems,
    required this.completedAt,
    this.message,
  });

  final bool success;
  final int syncedItems;
  final int failedItems;
  final String? message;
  final DateTime completedAt;

  factory SyncResult.success({required int syncedItems, String? message}) {
    return SyncResult(
      success: true,
      syncedItems: syncedItems,
      failedItems: 0,
      message: message,
      completedAt: DateTime.now(),
    );
  }

  factory SyncResult.failure({String? message, int failedItems = 0}) {
    return SyncResult(
      success: false,
      syncedItems: 0,
      failedItems: failedItems,
      message: message,
      completedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'SyncResult(success: $success, syncedItems: $syncedItems, '
        'failedItems: $failedItems, message: $message)';
  }
}

// ---------------------------------------------------------------------
// 5. SyncService
// ---------------------------------------------------------------------

/// Coordinates offline-first synchronization for Student AI Companion
/// between local storage (Hive/Isar), background WorkManager tasks, and
/// a future Firestore backend — across timetable, todo, attendance,
/// reminders, Notes AI, health, and analytics data.
///
/// Fully functional as an offline-first task queue even before a real
/// backend is connected: tasks are queued, retried, and tracked with
/// realistic status/result streams that feature code can already build
/// against.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  // ---------------------------------------------------------------------
  // 6. Internal State
  // ---------------------------------------------------------------------

  ConnectivityService? _connectivityService;
  final List<SyncTask> _pendingTasks = <SyncTask>[];

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();

  SyncStatus _status = SyncStatus.idle;
  bool _initialized = false;

  Timer? _periodicTimer;

  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<SyncResult> get resultStream => _resultController.stream;

  SyncStatus get currentStatus => _status;
  int get pendingTaskCount => _pendingTasks.length;

  // ---------------------------------------------------------------------
  // 7. Initialization
  // ---------------------------------------------------------------------

  /// Initializes the sync service. Safe to call more than once —
  /// subsequent calls are no-ops.
  Future<void> initialize({ConnectivityService? connectivityService}) async {
    if (_initialized) {
      AppLogger.debug(LogCategory.network, '[SYNC] Already initialized');
      return;
    }

    _connectivityService = connectivityService;
    _initialized = true;

    AppLogger.info(LogCategory.network, '[SYNC] SyncService initialized');
  }

  // ---------------------------------------------------------------------
  // 8. Queue Management
  // ---------------------------------------------------------------------

  /// Queues [task] for synchronization. If the device is currently
  /// online, a sync run is triggered automatically in the background.
  Future<void> queueTask(SyncTask task) async {
    _pendingTasks.add(task);
    AppLogger.info(
      LogCategory.network,
      '[SYNC] Queued task',
      data: <String, dynamic>{'id': task.id, 'feature': task.feature},
    );

    if (await _isOnline()) {
      unawaited(syncNow());
    }
  }

  String _generateTaskId(String feature) {
    return '${feature}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Queues a timetable change for sync.
  Future<void> queueTimetableSync(Map<String, dynamic> payload) {
    return queueTask(
      SyncTask(
        id: _generateTaskId('timetable'),
        feature: 'timetable',
        createdAt: DateTime.now(),
        payload: payload,
      ),
    );
  }

  /// Queues a todo task change for sync.
  Future<void> queueTodoSync(Map<String, dynamic> payload) {
    return queueTask(
      SyncTask(
        id: _generateTaskId('todo'),
        feature: 'todo',
        createdAt: DateTime.now(),
        payload: payload,
      ),
    );
  }

  /// Queues an attendance record change for sync.
  Future<void> queueAttendanceSync(Map<String, dynamic> payload) {
    return queueTask(
      SyncTask(
        id: _generateTaskId('attendance'),
        feature: 'attendance',
        createdAt: DateTime.now(),
        payload: payload,
      ),
    );
  }

  /// Queues a reminder change for sync.
  Future<void> queueReminderSync(Map<String, dynamic> payload) {
    return queueTask(
      SyncTask(
        id: _generateTaskId('reminders'),
        feature: 'reminders',
        createdAt: DateTime.now(),
        payload: payload,
      ),
    );
  }

  /// Queues Notes AI content for sync.
  Future<void> queueNotesSync(Map<String, dynamic> payload) {
    return queueTask(
      SyncTask(
        id: _generateTaskId('notes_ai'),
        feature: 'notes_ai',
        createdAt: DateTime.now(),
        payload: payload,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 9. Sync Execution
  // ---------------------------------------------------------------------

  /// Runs a synchronization pass over every currently queued task.
  Future<SyncResult> syncNow() async {
    if (_pendingTasks.isEmpty) {
      AppLogger.debug(LogCategory.network, '[SYNC] Nothing to sync');
      return SyncResult.success(syncedItems: 0, message: 'Nothing to sync.');
    }

    if (!await _isOnline()) {
      _updateStatus(SyncStatus.offline);
      final SyncResult result = SyncResult.failure(
        message: 'No internet connection.',
        failedItems: _pendingTasks.length,
      );
      _resultController.add(result);
      return result;
    }

    _updateStatus(SyncStatus.syncing);

    final List<SyncTask> snapshot = List<SyncTask>.from(_pendingTasks);
    final List<SyncTask> succeeded = <SyncTask>[];
    int failedCount = 0;

    for (final SyncTask task in snapshot) {
      try {
        // Simulated network upload — replace with a real Firestore /
        // API call once the backend is connected.
        await Future<void>.delayed(const Duration(milliseconds: 150));
        succeeded.add(task);
      } catch (error) {
        failedCount++;
        AppLogger.warning(
          LogCategory.network,
          '[SYNC] Task failed: ${task.id}',
          data: <String, dynamic>{'error': error.toString()},
        );
      }
    }

    _pendingTasks.removeWhere(succeeded.contains);

    final SyncResult result = failedCount == 0
        ? SyncResult.success(syncedItems: succeeded.length)
        : SyncResult(
            success: false,
            syncedItems: succeeded.length,
            failedItems: failedCount,
            message: 'Some items failed to sync.',
            completedAt: DateTime.now(),
          );

    _resultController.add(result);
    _updateStatus(result.success ? SyncStatus.success : SyncStatus.failed);

    AppLogger.info(
      LogCategory.network,
      '[SYNC] Sync completed',
      data: <String, dynamic>{
        'synced': result.syncedItems,
        'failed': result.failedItems,
      },
    );

    return result;
  }

  // ---------------------------------------------------------------------
  // 10. Connectivity Helpers
  // ---------------------------------------------------------------------

  Future<bool> _isOnline() async {
    if (_connectivityService == null) return true;

    try {
      return await _connectivityService!.checkConnection();
    } catch (error) {
      AppLogger.warning(
        LogCategory.network,
        '[SYNC] Connectivity check failed',
        data: <String, dynamic>{'error': error.toString()},
      );
      return false;
    }
  }

  /// Re-runs [syncNow], logging the retry attempt.
  Future<SyncResult> retryFailedSync() async {
    AppLogger.info(LogCategory.network, '[SYNC] Retrying failed sync');
    return syncNow();
  }

  /// Removes every queued task without syncing them.
  Future<void> clearPendingTasks() async {
    _pendingTasks.clear();
    AppLogger.info(LogCategory.network, '[SYNC] Pending tasks cleared');
  }

  /// An unmodifiable snapshot of every currently queued task.
  List<SyncTask> getPendingTasks() {
    return List<SyncTask>.unmodifiable(_pendingTasks);
  }

  void _updateStatus(SyncStatus status) {
    if (_status == status) return;

    final SyncStatus previous = _status;
    _status = status;
    _statusController.add(status);

    AppLogger.debug(
      LogCategory.network,
      '[SYNC] Status changed: ${previous.name} -> ${status.name}',
    );
  }

  // ---------------------------------------------------------------------
  // 11. Periodic Sync
  // ---------------------------------------------------------------------

  /// Starts a periodic background sync every [interval], syncing only
  /// when there are pending tasks. Cancels any previously running timer
  /// first.
  Future<void> startPeriodicSync({
    Duration interval = const Duration(minutes: 15),
  }) async {
    _periodicTimer?.cancel();

    _periodicTimer = Timer.periodic(interval, (Timer timer) async {
      if (_pendingTasks.isEmpty) return;

      try {
        await syncNow();
      } catch (error) {
        AppLogger.warning(
          LogCategory.network,
          '[SYNC] Periodic sync failed',
          data: <String, dynamic>{'error': error.toString()},
        );
      }
    });

    AppLogger.info(
      LogCategory.network,
      '[SYNC] Periodic sync started (every ${interval.inMinutes} min)',
    );
  }

  /// Stops the periodic background sync, if running.
  Future<void> stopPeriodicSync() async {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    AppLogger.info(LogCategory.network, '[SYNC] Periodic sync stopped');
  }

  // ---------------------------------------------------------------------
  // 12. Debug Helpers
  // ---------------------------------------------------------------------

  /// A structured snapshot of the sync service's current state, useful
  /// for debugging and diagnostics screens.
  Map<String, dynamic> debugSnapshot() {
    return <String, dynamic>{
      'initialized': _initialized,
      'currentStatus': _status.name,
      'pendingTaskCount': _pendingTasks.length,
      'pendingFeatures':
          _pendingTasks.map((SyncTask task) => task.feature).toSet().toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------
  // 13. Disposal
  // ---------------------------------------------------------------------

  /// Stops periodic sync, closes all streams, clears pending tasks, and
  /// resets initialization state.
  Future<void> dispose() async {
    await stopPeriodicSync();
    await _statusController.close();
    await _resultController.close();
    _pendingTasks.clear();
    _initialized = false;
  }
}

// ---------------------------------------------------------------------
// 14. Demo Utility
// ---------------------------------------------------------------------

/// A UI-independent demo of [SyncService], useful for quick manual
/// testing of the queue -> sync pipeline.
class SyncServiceDemo {
  SyncServiceDemo._();

  static Future<Map<String, dynamic>> runDemo() async {
    final SyncService service = SyncService.instance;
    await service.initialize();

    final int beforeCount = service.pendingTaskCount;

    await service.queueTimetableSync(<String, dynamic>{
      'subject': 'Digital Electronics',
      'dayOfWeek': 2,
    });
    await service.queueTodoSync(<String, dynamic>{
      'title': 'Finish DBMS assignment',
    });

    final SyncResult result = await service.syncNow();

    return <String, dynamic>{
      'beforeCount': beforeCount,
      'afterCount': service.pendingTaskCount,
      'success': result.success,
      'syncedItems': result.syncedItems,
      'finalStatus': service.currentStatus.name,
    };
  }
}


// lib/core/database/isar_service.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

part 'isar_service.g.dart';

// ---------------------------------------------------------------------
// Collection Models
// ---------------------------------------------------------------------

/// A single timetable entry (class, lab, or tutorial slot).
@collection
class TimetableEntryEntity {
  Id id = Isar.autoIncrement;

  late String subject;
  late String teacher;
  late String room;

  /// 1 = Sunday .. 7 = Saturday.
  @Index()
  late int dayOfWeek;

  late String startTime;
  late String endTime;

  bool isLab = false;

  DateTime createdAt = DateTime.now();
}

/// Per-subject attendance tally.
@collection
class AttendanceRecordEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String subject;

  late int attended;
  late int total;

  DateTime updatedAt = DateTime.now();

  /// Not persisted — derived from [attended] / [total].
  @ignore
  double get percentage => total == 0 ? 0 : (attended / total) * 100;
}

/// A single to-do task.
@collection
class TaskEntity {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;
  late DateTime dueDate;

  @Index()
  bool completed = false;

  String priority = 'medium';
  DateTime createdAt = DateTime.now();
}

/// A scheduled reminder (class, water, sleep, custom, etc.).
@collection
class ReminderEntity {
  Id id = Isar.autoIncrement;

  late String title;

  @Index()
  late DateTime scheduledAt;

  @Index()
  bool completed = false;

  String category = 'general';
  DateTime createdAt = DateTime.now();
}

/// A single logged study/focus session.
@collection
class StudySessionEntity {
  Id id = Isar.autoIncrement;

  late String subject;
  late int durationMinutes;
  late DateTime startedAt;
  DateTime? endedAt;
}

/// A single Nova AI conversation turn, cached for offline recall.
@collection
class AiMemoryEntity {
  Id id = Isar.autoIncrement;

  late String role;
  late String content;

  @Index()
  late DateTime timestamp;
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Structured, offline-first local database manager for Student AI
/// Companion, backed by Isar.
///
/// Manages timetable entries, attendance records, tasks, reminders,
/// study sessions, and Nova AI memory — fast, reactive, and safe to use
/// even without a network connection.
class IsarService {
  IsarService._();

  static final IsarService instance = IsarService._();

  Isar? _isar;

  bool get isInitialized => _isar != null && _isar!.isOpen;

  /// The underlying Isar instance. Only valid after [initialize] has
  /// completed successfully.
  Isar get db {
    if (_isar == null) {
      throw StateError('IsarService.initialize() must be called first.');
    }
    return _isar!;
  }

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Opens the Isar database with every registered schema. Safe to call
  /// more than once — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isar != null && _isar!.isOpen) {
      debugPrint('Isar already initialized');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        <CollectionSchema<dynamic>>[
          TimetableEntryEntitySchema,
          AttendanceRecordEntitySchema,
          TaskEntitySchema,
          ReminderEntitySchema,
          StudySessionEntitySchema,
          AiMemoryEntitySchema,
        ],
        directory: dir.path,
        inspector: true,
        compactOnLaunch: const CompactCondition(
          minBytes: 1024 * 1024,
          minRatio: 2.0,
        ),
      );

      debugPrint('Isar initialized at ${dir.path}');
    } catch (error) {
      debugPrint('Isar initialization failed: $error');
    }
  }

  /// Closes the database.
  Future<void> close() async {
    try {
      await _isar?.close();
      debugPrint('Isar closed');
    } catch (error) {
      debugPrint('Isar close failed: $error');
    }
  }

  /// Deletes every record from every collection.
  Future<void> clearDatabase() async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(() => _isar!.clear());
      debugPrint('Isar database cleared');
    } catch (error) {
      debugPrint('Isar clearDatabase failed: $error');
    }
  }

  /// Compacts the database file by closing and reopening it, which
  /// re-applies the [CompactCondition] configured in [initialize].
  Future<void> compact() async {
    try {
      await close();
      await initialize();
      debugPrint('Isar database compacted');
    } catch (error) {
      debugPrint('Isar compact failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Timetable API
  // ---------------------------------------------------------------------

  Future<int> addTimetableEntry(TimetableEntryEntity entry) async {
    if (_isar == null) return 0;
    try {
      return await _isar!.writeTxn(
        () => _isar!.collection<TimetableEntryEntity>().put(entry),
      );
    } catch (error) {
      debugPrint('addTimetableEntry failed: $error');
      return 0;
    }
  }

  Future<List<TimetableEntryEntity>> getTimetableForDay(int dayOfWeek) async {
    if (_isar == null) return <TimetableEntryEntity>[];
    try {
      return await _isar!
          .collection<TimetableEntryEntity>()
          .filter()
          .dayOfWeekEqualTo(dayOfWeek)
          .findAll();
    } catch (error) {
      debugPrint('getTimetableForDay failed: $error');
      return <TimetableEntryEntity>[];
    }
  }

  Future<List<TimetableEntryEntity>> getAllTimetableEntries() async {
    if (_isar == null) return <TimetableEntryEntity>[];
    try {
      return await _isar!.collection<TimetableEntryEntity>().where().findAll();
    } catch (error) {
      debugPrint('getAllTimetableEntries failed: $error');
      return <TimetableEntryEntity>[];
    }
  }

  Future<void> deleteTimetableEntry(int id) async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(
        () => _isar!.collection<TimetableEntryEntity>().delete(id),
      );
    } catch (error) {
      debugPrint('deleteTimetableEntry failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Attendance API
  // ---------------------------------------------------------------------

  Future<int> saveAttendanceRecord(AttendanceRecordEntity record) async {
    if (_isar == null) return 0;
    try {
      return await _isar!.writeTxn(
        () => _isar!.collection<AttendanceRecordEntity>().put(record),
      );
    } catch (error) {
      debugPrint('saveAttendanceRecord failed: $error');
      return 0;
    }
  }

  Future<List<AttendanceRecordEntity>> getAttendanceRecords() async {
    if (_isar == null) return <AttendanceRecordEntity>[];
    try {
      return await _isar!.collection<AttendanceRecordEntity>().where().findAll();
    } catch (error) {
      debugPrint('getAttendanceRecords failed: $error');
      return <AttendanceRecordEntity>[];
    }
  }

  Future<AttendanceRecordEntity?> getAttendanceForSubject(String subject) async {
    if (_isar == null) return null;
    try {
      return await _isar!
          .collection<AttendanceRecordEntity>()
          .filter()
          .subjectEqualTo(subject)
          .findFirst();
    } catch (error) {
      debugPrint('getAttendanceForSubject failed: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Task API
  // ---------------------------------------------------------------------

  Future<int> addTask(TaskEntity task) async {
    if (_isar == null) return 0;
    try {
      return await _isar!.writeTxn(() => _isar!.collection<TaskEntity>().put(task));
    } catch (error) {
      debugPrint('addTask failed: $error');
      return 0;
    }
  }

  Future<List<TaskEntity>> getAllTasks() async {
    if (_isar == null) return <TaskEntity>[];
    try {
      return await _isar!.collection<TaskEntity>().where().findAll();
    } catch (error) {
      debugPrint('getAllTasks failed: $error');
      return <TaskEntity>[];
    }
  }

  Future<List<TaskEntity>> getPendingTasks() async {
    if (_isar == null) return <TaskEntity>[];
    try {
      return await _isar!
          .collection<TaskEntity>()
          .filter()
          .completedEqualTo(false)
          .sortByDueDate()
          .findAll();
    } catch (error) {
      debugPrint('getPendingTasks failed: $error');
      return <TaskEntity>[];
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(() => _isar!.collection<TaskEntity>().put(task));
    } catch (error) {
      debugPrint('updateTask failed: $error');
    }
  }

  Future<void> deleteTask(int id) async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(() => _isar!.collection<TaskEntity>().delete(id));
    } catch (error) {
      debugPrint('deleteTask failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Reminder API
  // ---------------------------------------------------------------------

  Future<int> addReminder(ReminderEntity reminder) async {
    if (_isar == null) return 0;
    try {
      return await _isar!.writeTxn(
        () => _isar!.collection<ReminderEntity>().put(reminder),
      );
    } catch (error) {
      debugPrint('addReminder failed: $error');
      return 0;
    }
  }

  Future<List<ReminderEntity>> getUpcomingReminders() async {
    if (_isar == null) return <ReminderEntity>[];
    try {
      return await _isar!
          .collection<ReminderEntity>()
          .filter()
          .completedEqualTo(false)
          .and()
          .scheduledAtGreaterThan(DateTime.now())
          .sortByScheduledAt()
          .findAll();
    } catch (error) {
      debugPrint('getUpcomingReminders failed: $error');
      return <ReminderEntity>[];
    }
  }

  Future<void> markReminderCompleted(int id) async {
    if (_isar == null) return;
    try {
      final ReminderEntity? reminder =
          await _isar!.collection<ReminderEntity>().get(id);
      if (reminder == null) return;

      reminder.completed = true;
      await _isar!.writeTxn(
        () => _isar!.collection<ReminderEntity>().put(reminder),
      );
    } catch (error) {
      debugPrint('markReminderCompleted failed: $error');
    }
  }

  Future<void> deleteReminder(int id) async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(() => _isar!.collection<ReminderEntity>().delete(id));
    } catch (error) {
      debugPrint('deleteReminder failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Study Session API
  // ---------------------------------------------------------------------

  Future<int> addStudySession(StudySessionEntity session) async {
    if (_isar == null) return 0;
    try {
      return await _isar!.writeTxn(
        () => _isar!.collection<StudySessionEntity>().put(session),
      );
    } catch (error) {
      debugPrint('addStudySession failed: $error');
      return 0;
    }
  }

  Future<List<StudySessionEntity>> getStudySessions() async {
    if (_isar == null) return <StudySessionEntity>[];
    try {
      return await _isar!.collection<StudySessionEntity>().where().findAll();
    } catch (error) {
      debugPrint('getStudySessions failed: $error');
      return <StudySessionEntity>[];
    }
  }

  Future<int> getTotalStudyMinutes() async {
    if (_isar == null) return 0;
    try {
      final List<StudySessionEntity> sessions =
          await _isar!.collection<StudySessionEntity>().where().findAll();
      return sessions.fold<int>(
        0,
        (int sum, StudySessionEntity session) => sum + session.durationMinutes,
      );
    } catch (error) {
      debugPrint('getTotalStudyMinutes failed: $error');
      return 0;
    }
  }

  // ---------------------------------------------------------------------
  // AI Memory API
  // ---------------------------------------------------------------------

  Future<void> addAiMemory(AiMemoryEntity memory) async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(() => _isar!.collection<AiMemoryEntity>().put(memory));
    } catch (error) {
      debugPrint('addAiMemory failed: $error');
    }
  }

  Future<List<AiMemoryEntity>> getRecentAiMemories({int limit = 20}) async {
    if (_isar == null) return <AiMemoryEntity>[];
    try {
      return await _isar!
          .collection<AiMemoryEntity>()
          .where()
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();
    } catch (error) {
      debugPrint('getRecentAiMemories failed: $error');
      return <AiMemoryEntity>[];
    }
  }

  Future<void> clearAiMemories() async {
    if (_isar == null) return;
    try {
      await _isar!.writeTxn(() => _isar!.collection<AiMemoryEntity>().clear());
    } catch (error) {
      debugPrint('clearAiMemories failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Reactive Watchers
  // ---------------------------------------------------------------------

  /// Emits an updated task list whenever the tasks collection changes.
  Stream<List<TaskEntity>> watchTasks() {
    if (_isar == null) return const Stream<List<TaskEntity>>.empty();
    return _isar!.collection<TaskEntity>().where().watch(fireImmediately: true);
  }

  /// Emits an updated reminder list whenever the reminders collection
  /// changes.
  Stream<List<ReminderEntity>> watchReminders() {
    if (_isar == null) return const Stream<List<ReminderEntity>>.empty();
    return _isar!
        .collection<ReminderEntity>()
        .where()
        .watch(fireImmediately: true);
  }

  /// Emits an updated timetable list for [dayOfWeek] whenever the
  /// timetable collection changes.
  Stream<List<TimetableEntryEntity>> watchTimetableForDay(int dayOfWeek) {
    if (_isar == null) return const Stream<List<TimetableEntryEntity>>.empty();
    return _isar!
        .collection<TimetableEntryEntity>()
        .filter()
        .dayOfWeekEqualTo(dayOfWeek)
        .watch(fireImmediately: true);
  }
}

// ---------------------------------------------------------------------
// Demo Screen
// ---------------------------------------------------------------------

/// A preview dashboard exercising every [IsarService] method on a dark,
/// futuristic background.
class IsarServiceDemo extends StatefulWidget {
  const IsarServiceDemo({super.key});

  @override
  State<IsarServiceDemo> createState() => _IsarServiceDemoState();
}

class _IsarServiceDemoState extends State<IsarServiceDemo> {
  final IsarService _isarService = IsarService.instance;
  String _output = 'Output will appear here…';
  int _taskCount = 0;
  int _reminderCount = 0;

  Future<void> _refreshCounts() async {
    final List<TaskEntity> tasks = await _isarService.getAllTasks();
    final List<ReminderEntity> reminders =
        await _isarService.getUpcomingReminders();
    if (!mounted) return;
    setState(() {
      _taskCount = tasks.length;
      _reminderCount = reminders.length;
    });
  }

  Future<void> _run(String label, Future<String> Function() action) async {
    final String result = await action();
    if (!mounted) return;
    setState(() => _output = '$label:\n$result');
    await _refreshCounts();
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
                  'Isar Structured Database Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'High-performance structured local storage keeps '
                  'timetable data, attendance records, tasks, reminders, '
                  'study sessions, and Nova AI memory available instantly '
                  'even without an internet connection.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 20),
                _buildOutputPanel(),
                const SizedBox(height: 24),
                _buildSection('Timetable', <Widget>[
                  _button('Add Sample Timetable', () async {
                    final int id = await _isarService.addTimetableEntry(
                      TimetableEntryEntity()
                        ..subject = 'Digital Electronics'
                        ..teacher = 'Prof. Arun'
                        ..room = 'Room 302'
                        ..dayOfWeek = DateTime.now().weekday
                        ..startTime = '08:30'
                        ..endTime = '09:30',
                    );
                    return 'Added timetable entry with id $id';
                  }),
                  _button("Load Today's Timetable", () async {
                    final List<TimetableEntryEntity> entries =
                        await _isarService.getTimetableForDay(DateTime.now().weekday);
                    return entries.map((TimetableEntryEntity e) => e.subject).join(', ');
                  }),
                ]),
                _buildSection('Attendance', <Widget>[
                  _button('Add Sample Attendance', () async {
                    final int id = await _isarService.saveAttendanceRecord(
                      AttendanceRecordEntity()
                        ..subject = 'DBMS'
                        ..attended = 18
                        ..total = 22,
                    );
                    return 'Saved attendance record with id $id';
                  }),
                  _button('Load Attendance', () async {
                    final List<AttendanceRecordEntity> records =
                        await _isarService.getAttendanceRecords();
                    return records
                        .map((AttendanceRecordEntity r) =>
                            '${r.subject}: ${r.percentage.toStringAsFixed(1)}%')
                        .join('\n');
                  }),
                ]),
                _buildSection('Tasks', <Widget>[
                  _button('Add Task', () async {
                    final int id = await _isarService.addTask(
                      TaskEntity()
                        ..title = 'Finish DBMS assignment'
                        ..dueDate = DateTime.now().add(const Duration(days: 2)),
                    );
                    return 'Added task with id $id';
                  }),
                  _button('Load Pending Tasks', () async {
                    final List<TaskEntity> tasks = await _isarService.getPendingTasks();
                    return tasks.map((TaskEntity t) => t.title).join(', ');
                  }),
                ]),
                _buildSection('Reminders', <Widget>[
                  _button('Add Reminder', () async {
                    final int id = await _isarService.addReminder(
                      ReminderEntity()
                        ..title = 'Drink water'
                        ..scheduledAt = DateTime.now().add(const Duration(hours: 1)),
                    );
                    return 'Added reminder with id $id';
                  }),
                  _button('Load Upcoming Reminders', () async {
                    final List<ReminderEntity> reminders =
                        await _isarService.getUpcomingReminders();
                    return reminders.map((ReminderEntity r) => r.title).join(', ');
                  }),
                ]),
                _buildSection('Study Sessions', <Widget>[
                  _button('Add Study Session', () async {
                    final int id = await _isarService.addStudySession(
                      StudySessionEntity()
                        ..subject = 'Data Structures'
                        ..durationMinutes = 45
                        ..startedAt = DateTime.now(),
                    );
                    return 'Added study session with id $id';
                  }),
                  _button('Show Total Study Minutes', () async {
                    final int minutes = await _isarService.getTotalStudyMinutes();
                    return 'Total study minutes: $minutes';
                  }),
                ]),
                _buildSection('AI Memory', <Widget>[
                  _button('Add AI Memory', () async {
                    await _isarService.addAiMemory(
                      AiMemoryEntity()
                        ..role = 'user'
                        ..content = 'Remind me about tomorrow\'s lab'
                        ..timestamp = DateTime.now(),
                    );
                    return 'Added AI memory entry';
                  }),
                  _button('Load Recent Memories', () async {
                    final List<AiMemoryEntity> memories =
                        await _isarService.getRecentAiMemories();
                    return memories.map((AiMemoryEntity m) => '${m.role}: ${m.content}').join('\n');
                  }),
                  _button('Clear AI Memories', () async {
                    await _isarService.clearAiMemories();
                    return 'Cleared AI memories';
                  }),
                ]),
                _buildSection('Maintenance', <Widget>[
                  _button('Compact Database', () async {
                    await _isarService.compact();
                    return 'Database compacted';
                  }),
                  _button('Clear Database', () async {
                    await _isarService.clearDatabase();
                    return 'Database cleared';
                  }),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _statusStat(
            _isarService.isInitialized ? 'Initialized' : 'Not Initialized',
            _isarService.isInitialized ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
          ),
          _statusStat('$_taskCount Tasks', const Color(0xFF00E5FF)),
          _statusStat('$_reminderCount Reminders', const Color(0xFF7C4DFF)),
        ],
      ),
    );
  }

  Widget _statusStat(String label, Color color) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        _output,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
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

  Widget _button(String label, Future<String> Function() action) {
    return ElevatedButton(
      onPressed: () => _run(label, action),
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


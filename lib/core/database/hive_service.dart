// lib/core/database/hive_service.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ---------------------------------------------------------------------
// Box Names
// ---------------------------------------------------------------------

/// Central offline storage manager for Student AI Companion, backed by
/// Hive. Provides a simple, scalable key-value API plus strongly typed
/// convenience methods for settings, theme, onboarding, user profile,
/// water tracking, study stats, AI conversation cache, timetable cache,
/// and attendance cache — all working fully offline.
class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  static const String settingsBox = 'settings_box';
  static const String userBox = 'user_box';
  static const String timetableBox = 'timetable_box';
  static const String attendanceBox = 'attendance_box';
  static const String tasksBox = 'tasks_box';
  static const String remindersBox = 'reminders_box';
  static const String aiMemoryBox = 'ai_memory_box';
  static const String studyBox = 'study_box';
  static const String healthBox = 'health_box';
  static const String analyticsBox = 'analytics_box';

  static const List<String> _allBoxNames = <String>[
    settingsBox,
    userBox,
    timetableBox,
    attendanceBox,
    tasksBox,
    remindersBox,
    aiMemoryBox,
    studyBox,
    healthBox,
    analyticsBox,
  ];

  // ---------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// The number of boxes managed by this service.
  int get boxCount => _allBoxNames.length;

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Initializes Hive and opens every predefined box. Safe to call more
  /// than once — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Hive already initialized');
      return;
    }

    try {
      await Hive.initFlutter();

      for (final String name in _allBoxNames) {
        await Hive.openBox(name);
        debugPrint('Opened Hive box: $name');
      }

      _isInitialized = true;
      debugPrint('Hive initialized');
    } catch (error) {
      debugPrint('Hive error: $error');
    }
  }

  /// Clears every key from every managed box, without closing them.
  Future<void> clearAll() async {
    try {
      for (final String name in _allBoxNames) {
        final Box box = await _box(name);
        await box.clear();
      }
      debugPrint('Cleared all Hive data');
    } catch (error) {
      debugPrint('Hive error: $error');
    }
  }

  /// Closes every managed box, releasing file handles.
  Future<void> close() async {
    try {
      await Hive.close();
      _isInitialized = false;
      debugPrint('Hive closed');
    } catch (error) {
      debugPrint('Hive error: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Generic Storage API
  // ---------------------------------------------------------------------

  /// Opens (or returns the already-open) box named [name].
  Future<Box> openBox(String name) => _box(name);

  /// Stores [value] under [key] in the box named [boxName].
  Future<void> put(String boxName, String key, dynamic value) async {
    try {
      final Box box = await _box(boxName);
      await box.put(key, value);
      debugPrint('Saved key: $key');
    } catch (error) {
      debugPrint('Hive error: $error');
    }
  }

  /// Retrieves the value stored under [key] in [boxName], cast to [T].
  /// Returns null if the key doesn't exist or the value can't be cast.
  Future<T?> get<T>(String boxName, String key) async {
    try {
      final Box box = await _box(boxName);
      final dynamic value = box.get(key);
      if (value is T) return value;
      return null;
    } catch (error) {
      debugPrint('Hive error: $error');
      return null;
    }
  }

  /// Deletes the value stored under [key] in [boxName].
  Future<void> delete(String boxName, String key) async {
    try {
      final Box box = await _box(boxName);
      await box.delete(key);
      debugPrint('Deleted key: $key');
    } catch (error) {
      debugPrint('Hive error: $error');
    }
  }

  /// Clears every key from a single box named [boxName].
  Future<void> clearBox(String boxName) async {
    try {
      final Box box = await _box(boxName);
      await box.clear();
      debugPrint('Cleared box: $boxName');
    } catch (error) {
      debugPrint('Hive error: $error');
    }
  }

  /// Whether [boxName] contains a value for [key].
  Future<bool> contains(String boxName, String key) async {
    try {
      final Box box = await _box(boxName);
      return box.containsKey(key);
    } catch (error) {
      debugPrint('Hive error: $error');
      return false;
    }
  }

  /// Returns every value currently stored in [boxName].
  Future<List<dynamic>> getAllValues(String boxName) async {
    try {
      final Box box = await _box(boxName);
      return box.values.toList();
    } catch (error) {
      debugPrint('Hive error: $error');
      return <dynamic>[];
    }
  }

  /// Returns every key currently stored in [boxName].
  Future<List<String>> getAllKeys(String boxName) async {
    try {
      final Box box = await _box(boxName);
      return box.keys.map((dynamic key) => key.toString()).toList();
    } catch (error) {
      debugPrint('Hive error: $error');
      return <String>[];
    }
  }

  // ---------------------------------------------------------------------
  // Convenience APIs
  // ---------------------------------------------------------------------

  // -- Theme preferences ---------------------------------------------

  static const String _themeModeKey = 'theme_mode';

  Future<void> saveThemeMode(String mode) {
    return put(settingsBox, _themeModeKey, mode);
  }

  Future<String> getThemeMode() async {
    final String? mode = await get<String>(settingsBox, _themeModeKey);
    return mode ?? 'system';
  }

  // -- Onboarding -------------------------------------------------------

  static const String _onboardingCompletedKey = 'onboarding_completed';

  Future<void> setOnboardingCompleted(bool value) {
    return put(settingsBox, _onboardingCompletedKey, value);
  }

  Future<bool> isOnboardingCompleted() async {
    final bool? completed =
        await get<bool>(settingsBox, _onboardingCompletedKey);
    return completed ?? false;
  }

  // -- User profile -----------------------------------------------------

  static const String _userNameKey = 'user_name';
  static const String _semesterKey = 'semester';

  Future<void> saveUserName(String name) {
    return put(userBox, _userNameKey, name);
  }

  Future<String?> getUserName() {
    return get<String>(userBox, _userNameKey);
  }

  Future<void> saveSemester(int semester) {
    return put(userBox, _semesterKey, semester);
  }

  Future<int> getSemester() async {
    final int? semester = await get<int>(userBox, _semesterKey);
    return semester ?? 1;
  }

  // -- Water tracker ------------------------------------------------------

  static const String _todayWaterKey = 'today_water_ml';

  Future<void> saveTodayWaterMl(int ml) {
    return put(healthBox, _todayWaterKey, ml);
  }

  Future<int> getTodayWaterMl() async {
    final int? ml = await get<int>(healthBox, _todayWaterKey);
    return ml ?? 0;
  }

  // -- Study stats --------------------------------------------------------

  static const String _studyMinutesKey = 'study_minutes';

  Future<void> saveStudyMinutes(int minutes) {
    return put(studyBox, _studyMinutesKey, minutes);
  }

  Future<int> getStudyMinutes() async {
    final int? minutes = await get<int>(studyBox, _studyMinutesKey);
    return minutes ?? 0;
  }

  // ---------------------------------------------------------------------
  // Cache Helpers
  // ---------------------------------------------------------------------

  static const String _aiConversationKey = 'ai_conversation';
  static const String _timetableCacheKey = 'timetable_cache';
  static const String _attendanceCacheKey = 'attendance_cache';

  /// Caches the current AI conversation as a list of plain maps, ready
  /// to be restored into `AiChatMessage` objects later.
  Future<void> saveAiConversation(List<Map<String, dynamic>> messages) {
    return put(aiMemoryBox, _aiConversationKey, messages);
  }

  /// Returns the cached AI conversation, or an empty list if none exists.
  Future<List<Map<String, dynamic>>> getAiConversation() async {
    try {
      final Box box = await _box(aiMemoryBox);
      final dynamic raw = box.get(_aiConversationKey);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((Map entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
      return <Map<String, dynamic>>[];
    } catch (error) {
      debugPrint('Hive error: $error');
      return <Map<String, dynamic>>[];
    }
  }

  /// Caches timetable entries as a list of plain maps.
  Future<void> saveTimetableCache(List<Map<String, dynamic>> entries) {
    return put(timetableBox, _timetableCacheKey, entries);
  }

  /// Returns the cached timetable entries, or an empty list if none exists.
  Future<List<Map<String, dynamic>>> getTimetableCache() async {
    try {
      final Box box = await _box(timetableBox);
      final dynamic raw = box.get(_timetableCacheKey);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((Map entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
      return <Map<String, dynamic>>[];
    } catch (error) {
      debugPrint('Hive error: $error');
      return <Map<String, dynamic>>[];
    }
  }

  /// Caches attendance summary data as a plain map.
  Future<void> saveAttendanceCache(Map<String, dynamic> data) {
    return put(attendanceBox, _attendanceCacheKey, data);
  }

  /// Returns the cached attendance data, or an empty map if none exists.
  Future<Map<String, dynamic>> getAttendanceCache() async {
    try {
      final Box box = await _box(attendanceBox);
      final dynamic raw = box.get(_attendanceCacheKey);
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return <String, dynamic>{};
    } catch (error) {
      debugPrint('Hive error: $error');
      return <String, dynamic>{};
    }
  }

  // ---------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------

  /// Ensures the box named [name] is open and returns it, opening it on
  /// demand if it wasn't already.
  Future<Box> _box(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    return Hive.openBox(name);
  }
}

// ---------------------------------------------------------------------
// Demo Screen
// ---------------------------------------------------------------------

/// A preview dashboard exercising every [HiveService] method on a dark,
/// futuristic background.
class HiveServiceDemo extends StatefulWidget {
  const HiveServiceDemo({super.key});

  @override
  State<HiveServiceDemo> createState() => _HiveServiceDemoState();
}

class _HiveServiceDemoState extends State<HiveServiceDemo> {
  final HiveService _hive = HiveService.instance;
  String _output = 'Output will appear here…';

  Future<void> _run(String label, Future<String> Function() action) async {
    final String result = await action();
    if (!mounted) return;
    setState(() => _output = '$label:\n$result');
  }

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
                  'Offline Storage Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nova AI keeps your tasks, timetable, attendance, study '
                  'progress, and personal preferences safely available '
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
                _buildButtons(),
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
            _hive.isInitialized ? 'Initialized' : 'Not Initialized',
            _hive.isInitialized ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
          ),
          _statusStat('${_hive.boxCount} Boxes', const Color(0xFF00E5FF)),
          _statusStat('Offline Ready', const Color(0xFF7C4DFF)),
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

  Widget _buildButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _button('Initialize Hive', () async {
          await _hive.initialize();
          setState(() {});
          return 'Hive initialized: ${_hive.isInitialized}';
        }),
        _button('Save Theme', () async {
          await _hive.saveThemeMode('dark');
          return 'Saved theme mode: dark';
        }),
        _button('Read Theme', () async {
          return 'Theme mode: ${await _hive.getThemeMode()}';
        }),
        _button('Save User Name', () async {
          await _hive.saveUserName('Kamesh');
          return 'Saved user name: Kamesh';
        }),
        _button('Read User Name', () async {
          return 'User name: ${await _hive.getUserName() ?? 'Not set'}';
        }),
        _button('Save Semester', () async {
          await _hive.saveSemester(3);
          return 'Saved semester: 3';
        }),
        _button('Read Semester', () async {
          return 'Semester: ${await _hive.getSemester()}';
        }),
        _button('Save Water Intake', () async {
          await _hive.saveTodayWaterMl(1500);
          return 'Saved water intake: 1500 ml';
        }),
        _button('Read Water Intake', () async {
          return 'Water intake: ${await _hive.getTodayWaterMl()} ml';
        }),
        _button('Save Study Minutes', () async {
          await _hive.saveStudyMinutes(90);
          return 'Saved study minutes: 90';
        }),
        _button('Read Study Minutes', () async {
          return 'Study minutes: ${await _hive.getStudyMinutes()}';
        }),
        _button('Save AI Conversation', () async {
          await _hive.saveAiConversation(<Map<String, dynamic>>[
            <String, dynamic>{'role': 'user', 'content': 'Hi Nova'},
            <String, dynamic>{'role': 'assistant', 'content': 'Hey 👋'},
          ]);
          return 'Saved AI conversation (2 messages)';
        }),
        _button('Read AI Conversation', () async {
          final List<Map<String, dynamic>> convo =
              await _hive.getAiConversation();
          return 'AI conversation: $convo';
        }),
        _button('Clear Settings Box', () async {
          await _hive.clearBox(HiveService.settingsBox);
          return 'Cleared settings box';
        }),
        _button('Clear All Data', () async {
          await _hive.clearAll();
          return 'Cleared all Hive data';
        }),
      ],
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


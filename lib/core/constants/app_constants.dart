// lib/core/constants/app_constants.dart

import 'package:flutter/material.dart';

/// Centralized application configuration and constant registry for
/// Student AI Companion. Holds every reusable app-wide constant so no
/// magic numbers or hardcoded strings are scattered through the codebase.
class AppConstants {
  AppConstants._();

  // -----------------------------------------------------------------
  // App Identity
  // -----------------------------------------------------------------

  static const String appName = 'Student AI Companion';
  static const String appTagline =
      'Your emotional AI companion for student life';

  static const String packageName = 'com.studentai.companion';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // -----------------------------------------------------------------
  // Animation Durations
  // -----------------------------------------------------------------

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 450);
  static const Duration orbPulse = Duration(milliseconds: 1800);

  // -----------------------------------------------------------------
  // UI Defaults
  // -----------------------------------------------------------------

  static const double defaultBlur = 18;
  static const double glassOpacity = 0.12;
  static const double cardElevation = 0;
  static const double maxContentWidth = 560;
  static const double bottomNavHeight = 72;
  static const double orbSize = 74;

  // -----------------------------------------------------------------
  // Attendance Rules
  // -----------------------------------------------------------------

  static const double minimumAttendance = 75.0;
  static const double warningAttendance = 80.0;
  static const double excellentAttendance = 90.0;

  // -----------------------------------------------------------------
  // Pomodoro Defaults
  // -----------------------------------------------------------------

  static const int pomodoroFocusMinutes = 25;
  static const int pomodoroShortBreakMinutes = 5;
  static const int pomodoroLongBreakMinutes = 15;
  static const int pomodoroSessionsBeforeLongBreak = 4;

  // -----------------------------------------------------------------
  // Hydration Defaults
  // -----------------------------------------------------------------

  static const int dailyWaterGoalMl = 3000;
  static const int waterCupSizeMl = 250;

  // -----------------------------------------------------------------
  // Screen Time Guidance
  // -----------------------------------------------------------------

  static const int healthyScreenTimeMinutes = 180;
  static const int warningScreenTimeMinutes = 300;

  // -----------------------------------------------------------------
  // AI Companion Defaults
  // -----------------------------------------------------------------

  static const String defaultAiName = 'Nova';

  static const double aiMotherWeight = 0.4;
  static const double aiFriendWeight = 0.3;
  static const double aiMentorWeight = 0.2;
  static const double aiFunnyWeight = 0.1;

  // -----------------------------------------------------------------
  // Notification Channels
  // -----------------------------------------------------------------

  static const String reminderChannelId = 'student_reminders';
  static const String reminderChannelName = 'Student Reminders';
  static const String reminderChannelDescription =
      'Reminders for classes, tasks, exams, and study sessions';

  static const String aiChannelId = 'ai_companion';
  static const String aiChannelName = 'AI Companion Messages';
  static const String aiChannelDescription =
      'Encouraging and personalized AI companion messages';

  // -----------------------------------------------------------------
  // Storage Keys
  // -----------------------------------------------------------------

  static const String hiveSettingsBox = 'settings_box';
  static const String hiveUserBox = 'user_box';
  static const String hiveTasksBox = 'tasks_box';
  static const String hiveAttendanceBox = 'attendance_box';
  static const String hiveTimetableBox = 'timetable_box';
  static const String hiveRemindersBox = 'reminders_box';
  static const String hiveStudyBox = 'study_box';

  static const String prefsThemeMode = 'theme_mode';
  static const String prefsOnboardingCompleted = 'onboarding_completed';
  static const String prefsAiPersonality = 'ai_personality';

  // -----------------------------------------------------------------
  // API Configuration Placeholders
  // -----------------------------------------------------------------

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // -----------------------------------------------------------------
  // Layout Breakpoints
  // -----------------------------------------------------------------

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // -----------------------------------------------------------------
  // Feature Flags
  // -----------------------------------------------------------------

  static const bool enableVoiceAssistant = true;
  static const bool enableOverlayOrb = true;
  static const bool enableAiChat = true;
  static const bool enableNotesAi = true;
  static const bool enableCloudSync = true;

  // -----------------------------------------------------------------
  // Motivational Fallback Quotes
  // -----------------------------------------------------------------

  static const List<String> fallbackQuotes = <String>[
    'Small progress every day becomes big success.',
    'Consistency beats intensity.',
    'Your future self will thank you for studying today.',
    'Focus on progress, not perfection.',
    'One productive hour is better than ten distracted hours.',
  ];
}


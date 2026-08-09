// lib/app/router/route_names.dart

/// Centralized route registry for Student AI Companion.
///
/// All navigable paths in the app are defined here as constants so no
/// route string is ever hardcoded elsewhere in the codebase.
class RouteNames {
  RouteNames._();

  // ---------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------

  static const splash = '/';
  static const onboarding = '/onboarding';

  // ---------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------

  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const profileSetup = '/auth/profile-setup';

  // ---------------------------------------------------------------------
  // Main Navigation
  // ---------------------------------------------------------------------

  static const home = '/home';

  // ---------------------------------------------------------------------
  // Student Productivity
  // ---------------------------------------------------------------------

  static const timetable = '/timetable';
  static const timetableDay = '/timetable/day';
  static const timetableEdit = '/timetable/edit';

  static const attendance = '/attendance';
  static const attendanceSubject = '/attendance/subject';

  static const todo = '/todo';

  static const reminders = '/reminders';

  static const screenTime = '/screen-time';

  static const studyMode = '/study-mode';

  static const gpaCalculator = '/gpa-calculator';

  static const expenseTracker = '/expense-tracker';

  static const health = '/health';

  static const analytics = '/analytics';

  // ---------------------------------------------------------------------
  // AI & Study Tools
  // ---------------------------------------------------------------------

  static const aiChat = '/ai-chat';

  static const notesAi = '/notes-ai';
  static const flashcards = '/notes-ai/flashcards';
  static const quiz = '/notes-ai/quiz';
  static const mindmap = '/notes-ai/mindmap';

  static const overlayAssistant = '/overlay-assistant';

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  static const settings = '/settings';
  static const notificationPreferences = '/settings/notifications';
  static const aiPersonality = '/settings/ai-personality';
  static const dataExport = '/settings/data-export';

  // ---------------------------------------------------------------------
  // Route Groups
  // ---------------------------------------------------------------------

  static const authRoutes = <String>[
    signIn,
    signUp,
    profileSetup,
  ];

  static const studentTools = <String>[
    timetable,
    timetableDay,
    timetableEdit,
    attendance,
    attendanceSubject,
    todo,
    reminders,
    screenTime,
    studyMode,
    gpaCalculator,
    expenseTracker,
    health,
    analytics,
  ];

  static const aiRoutes = <String>[
    aiChat,
    notesAi,
    flashcards,
    quiz,
    mindmap,
    overlayAssistant,
  ];

  static const settingsRoutes = <String>[
    settings,
    notificationPreferences,
    aiPersonality,
    dataExport,
  ];

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// True for sign-in, sign-up, and profile setup.
  static bool isAuthRoute(String route) {
    return authRoutes.contains(route);
  }

  /// True for every route except splash, onboarding, and auth routes —
  /// i.e. the routes that require a signed-in user.
  static bool isProtectedRoute(String route) {
    if (route == splash || route == onboarding) return false;
    if (isAuthRoute(route)) return false;
    return true;
  }

  /// True for AI chat, Notes AI, flashcards, quiz, and mindmap routes.
  static bool isAiRoute(String route) {
    return aiRoutes.contains(route);
  }

  // ---------------------------------------------------------------------
  // Initial Route
  // ---------------------------------------------------------------------

  static const initialRoute = splash;
}

